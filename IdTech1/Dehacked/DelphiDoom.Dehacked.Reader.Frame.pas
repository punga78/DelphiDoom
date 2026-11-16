{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Frame                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Frame;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.FieldReader, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   Frame n, Frame NEW n (a state after the ones the game has) or Frame name (the engine finds
  ///   the state by its name), and the fields of the frame
  /// </summary>
  TDehackedFrameReader = class(TDehackedReaderBase)
  private
    FFields: TDehackedFieldReader;
  public
    /// <param name="AFields">The reader owns it</param>
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog; AFields: TDehackedFieldReader);
    destructor Destroy; override;
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedFrameReader }

constructor TDehackedFrameReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  AFields: TDehackedFieldReader);
begin
  inherited Create(AKeywords, ALog);
  FFields := AFields;
end;

destructor TDehackedFrameReader.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

function TDehackedFrameReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LWord, LNumberText: string;
  LReference: TDehackedReference;
  LNumber: Integer;
begin
  Result := nil;
  LWord := TDehackedStrings.FirstWordChar(ARest);
  if LWord = '' then
  begin
    Warn('DEH_Parse(): State number unspecified after %s keyword'#13#10, [AKeyword]);
    Exit;
  end;

  LReference := Default(TDehackedReference);
  if (LWord = 'NEW') or (LWord = 'NEWFRAME') or (LWord = 'NEWSTATE') then
  begin
    LNumberText := TDehackedStrings.SecondWord(ARest);
    LNumber := TDehackedStrings.ToInteger(LNumberText, -1);
    if LNumberText = '' then
    begin
      Warn('DEH_Parse(): New state number unspecified after %s keyword'#13#10,
        [TDehackedStrings.FirstWordChar(ARest)]);
      Exit;
    end;
    if LNumber < 0 then
    begin
      Warn('DEH_Parse(): Wrong new state number = %s'#13#10, [LNumberText]);
      Exit;
    end;
    LReference.IsNew := True;
    LReference.Number := LNumber;
  end
  else
  begin
    // a number, or the name of a state: the engine finds it
    LReference.Number := TDehackedStrings.ToInteger(LWord, -1);
    if LReference.Number < 0 then
      LReference.Name := ARest;
  end;

  Result := CreateSection(dskFrame, AKeyword, ARest, ASource);
  Result.Reference := LReference;
  FFields.Read(ASource, Result, LReference.Number);
end;

end.
