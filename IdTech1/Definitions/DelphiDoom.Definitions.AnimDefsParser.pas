{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the parser of ANIMDEFS                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.AnimDefsParser;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf;

type
  /// <summary>
  ///   P_InitFTAnims of the old engine without the engine: the animations of the text, as
  ///   a model. The words that are not understood are warnings and the reading goes on as
  ///   the old code did (a number that is missing keeps the previous one)
  /// </summary>
  TAnimDefsParser = class(TInterfacedObject, IDefAnimDefsParser)
  private
    FCatalog: IDefAnimNameCatalog;
    FLog: ILog;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const ACatalog: IDefAnimNameCatalog; const ALog: ILog);
    function Parse(const AText: string): TArray<TDefAnimation>;
  end;

implementation

uses
  DelphiDoom.Scanner.Scanner, DelphiDoom.Scanner.Text;

const
  SCI_FLAT = 'flat';
  SCI_TEXTURE = 'texture';
  SCI_PIC = 'pic';
  SCI_TICS = 'tics';
  SCI_RAND = 'rand';

resourcestring
  STooManyAnimations = 'P_InitFTAnims(): too many AnimDefs (%d).';
  STooManyFrames = 'P_InitFTAnims(): too many FrameDefs (%d).';
  SFewFrames = 'P_InitFTAnims(): AnimDef has framecount < 2.';

{ TAnimDefsParser }

constructor TAnimDefsParser.Create(const ACatalog: IDefAnimNameCatalog; const ALog: ILog);
begin
  inherited Create;
  FCatalog := ACatalog;
  FLog := ALog;
end;

function TAnimDefsParser.Parse(const AText: string): TArray<TDefAnimation>;
var
  LScanner: TScriptScanner;
  LAnimations: TArray<TDefAnimation>;
  LCurrent: TDefAnimation;
  LFrame: TDefAnimFrame;
  LFrames: TArray<TDefAnimFrame>;
  LOffsets: TArray<Integer>;
  LSlotKind: TDefAnimKind;
  LFrameCount: Integer;
  LStartFrame: Integer;
  LRandomBase: Integer;
  LIgnore: Boolean;
  LDone: Boolean;
begin
  LAnimations := nil;
  LFrameCount := 0;
  // the old engine kept the kind in the slot of the animation: a slot that was not used
  // yet is a flat, and a slot of an animation that was ignored is used again
  LSlotKind := TDefAnimKind.Flat;
  LScanner := TScriptScanner.Create(TScannerText.RemoveLineQuotes(AText), FLog);
  try
    while LScanner.GetString do
    begin
      if Length(LAnimations) = DEFINITIONS_MAX_ANIMATIONS then
        raise EDefinitionsException.CreateFmt(STooManyAnimations, [Length(LAnimations)]);

      if LScanner.Compare(SCI_FLAT) then
        LSlotKind := TDefAnimKind.Flat
      else if LScanner.Compare(SCI_TEXTURE) then
        LSlotKind := TDefAnimKind.Texture
      else
        LScanner.Warn('P_InitFTAnims(): Unknown animation type: %s'#13#10, [LScanner.AsString]);

      LScanner.MustGetString; // the name
      LCurrent.Kind := LSlotKind;
      LCurrent.Name := LScanner.AsString;
      if LSlotKind = TDefAnimKind.Flat then
        LIgnore := not FCatalog.HasFlat(LCurrent.Name)
      else
        LIgnore := not FCatalog.HasTexture(LCurrent.Name);

      LFrames := nil;
      LOffsets := nil;
      if not LIgnore then
      begin
        SetLength(LOffsets, 1);
        LOffsets[0] := 0;
      end;
      LStartFrame := LFrameCount;
      LDone := False;
      while not LDone do
      begin
        if LScanner.GetString then
        begin
          if LScanner.Compare(SCI_PIC) then
          begin
            if LFrameCount = DEFINITIONS_MAX_FRAMES then
              raise EDefinitionsException.CreateFmt(STooManyFrames, [LFrameCount]);

            LScanner.MustGetInteger;
            LFrame.PicNumber := LScanner.AsInteger;
            LFrame.Tics := 0;
            LFrame.IsRandom := False;
            LFrame.RandomMax := 0;
            if not LIgnore then
            begin
              SetLength(LOffsets, Length(LOffsets) + 1);
              LOffsets[High(LOffsets)] := LScanner.AsInteger - 1;
            end;

            LScanner.MustGetString;
            if LScanner.Compare(SCI_TICS) then
            begin
              LScanner.MustGetInteger;
              if not LIgnore then
              begin
                LFrame.Tics := LScanner.AsInteger;
                SetLength(LFrames, Length(LFrames) + 1);
                LFrames[High(LFrames)] := LFrame;
                Inc(LFrameCount);
              end;
            end
            else if LScanner.Compare(SCI_RAND) then
            begin
              LScanner.MustGetInteger;
              LRandomBase := LScanner.AsInteger;
              LScanner.MustGetInteger;
              if not LIgnore then
              begin
                LFrame.IsRandom := True;
                LFrame.Tics := LRandomBase;
                LFrame.RandomMax := LScanner.AsInteger;
                SetLength(LFrames, Length(LFrames) + 1);
                LFrames[High(LFrames)] := LFrame;
                Inc(LFrameCount);
              end;
            end
            else
              LScanner.Warn('P_InitFTAnims(): Unknown animation type: %s'#13#10, [LScanner.AsString]);
          end
          else
          begin
            LScanner.UnGet;
            LDone := True;
          end;
        end
        else
          LDone := True;
      end;
      if not LIgnore and (LFrameCount - LStartFrame < 2) then
        raise EDefinitionsException.Create(SFewFrames);
      if not LIgnore then
      begin
        LCurrent.Frames := LFrames;
        LCurrent.AnimatedOffsets := LOffsets;
        SetLength(LAnimations, Length(LAnimations) + 1);
        LAnimations[High(LAnimations)] := LCurrent;
        LSlotKind := TDefAnimKind.Flat;
      end;
    end;
  finally
    LScanner.Free;
  end;
  Result := LAnimations;
end;

end.
