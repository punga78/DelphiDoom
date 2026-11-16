{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the parser of the MODELDEF lump             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Definition.Parser;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Models.Definition.Types,
  DelphiDoom.Models.Definition.Intf;

type
  /// <summary>
  ///   The old SC_DoParseModelDefinition without the engine: the words MODELDEF (a model with its
  ///   offset, scale, merged files and function) and STATE (a state that shows a model with a
  ///   texture, a range of frames and a transparency) go to a sink in the order they are written.
  ///   The states of the game are asked to a lookup. The problems are warnings, never exceptions.
  /// </summary>
  /// <remarks>
  ///   Defect of the old parser that is kept so that the result is the same: YOFFSET sets the
  ///   X offset. The model named by a STATE word is always given to the sink with the default
  ///   offset and scale.
  /// </remarks>
  TModelDefinitionParser = class(TInterfacedObject, IModelDefinitionParser)
  strict private
    FLookup: IModelDefinitionLookup;
    FLog: ILog;
    FScanner: TScriptScanner;
    FSink: IModelDefinitionSink;
    FItem: TModelDefinitionItem;
    FState: TModelDefinitionState;
    FModelPending: Boolean;
    FStatePending: Boolean;
    class function TokenIndex(const AToken: string): Integer; static;
    class procedure ResetItem(var AItem: TModelDefinitionItem); static;
    procedure Warn(const AFormat: string; const AArguments: array of const);
    /// <summary>The word MODELDEF; true if the text ends there and the parse is over</summary>
    function ParseModel: Boolean;
    /// <summary>The word STATE; true if the text ends there and the parse is over</summary>
    function ParseState: Boolean;
  public
    constructor Create(const ALookup: IModelDefinitionLookup; const ALog: ILog);
    procedure Parse(const AText: string; const ASink: IModelDefinitionSink);
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

const
  TOKEN_MODELDEF = 0;
  TOKEN_STATE = 1;
  TOKEN_OFFSET = 2;
  TOKEN_SCALE = 3;
  TOKEN_TEXTURE = 4;
  TOKEN_FRAME = 5;
  TOKEN_ENDFRAME = 6;
  TOKEN_MODEL = 7;
  TOKEN_FRAMEMERGE = 8;
  TOKEN_TRANSPARENCY = 9;
  TOKEN_XOFFSET = 10;
  TOKEN_YOFFSET = 11;
  TOKEN_XSCALE = 12;
  TOKEN_YSCALE = 13;
  TOKEN_ZSCALE = 14;
  TOKEN_PROC = 15;

  // the words of each token, in the order of the numbers above
  TOKEN_WORDS: array[0..15] of array[0..2] of string = (
    ('MODELDEF', 'MODELDEFINITION', ''),
    ('STATE', '', ''),
    ('OFFSET', 'ZOFFSET', 'OFFSETZ'),
    ('SCALE', '', ''),
    ('TEXTURE', '', ''),
    ('FRAME', 'FRAME1', 'STARTFRAME'),
    ('FRAME2', 'ENDFRAME', 'NEXTFRAME'),
    ('MODEL', '', ''),
    ('FRAMEMERGE', '', ''),
    ('TRANSPARENCY', '', ''),
    ('XOFFSET', 'OFFSETX', ''),
    ('YOFFSET', 'OFFSETY', ''),
    ('XSCALE', 'SCALEX', ''),
    ('YSCALE', 'SCALEY', ''),
    ('ZSCALE', 'SCALEZ', ''),
    ('PROC', '', '')
  );

{ TModelDefinitionParser }

constructor TModelDefinitionParser.Create(const ALookup: IModelDefinitionLookup; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALookup) then
    raise EArgumentNilException.Create('ALookup');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLookup := ALookup;
  FLog := ALog;
end;

class function TModelDefinitionParser.TokenIndex(const AToken: string): Integer;
var
  LIndex, LWord: Integer;
begin
  for LIndex := 0 to High(TOKEN_WORDS) do
    for LWord := 0 to High(TOKEN_WORDS[LIndex]) do
      if (TOKEN_WORDS[LIndex][LWord] <> '') and (TOKEN_WORDS[LIndex][LWord] = AToken) then
        Exit(LIndex);
  Result := -1;
end;

class procedure TModelDefinitionParser.ResetItem(var AItem: TModelDefinitionItem);
begin
  AItem.Proc := '';
  AItem.XOffset := 0.0;
  AItem.YOffset := 0.0;
  AItem.ZOffset := 0.0;
  AItem.XScale := 1.0;
  AItem.YScale := 1.0;
  AItem.ZScale := 1.0;
end;

procedure TModelDefinitionParser.Warn(const AFormat: string; const AArguments: array of const);
begin
  FLog.Warning(Format(AFormat, AArguments));
end;

function TModelDefinitionParser.ParseModel: Boolean;
var
  LToken: Integer;
begin
  Result := False;
  FModelPending := True;
  FItem.Name := '';
  ResetItem(FItem);
  SetLength(FItem.FrameMerge, 0);
  if not FScanner.GetString then
  begin
    Warn(SModelDefTokenExpected, [FScanner.Line]);
    Exit(True);
  end;
  FItem.Name := TScannerStrings.UpperAscii(FScanner.AsString);

  while FScanner.GetString do
  begin
    LToken := TokenIndex(TScannerStrings.UpperAscii(FScanner.AsString));
    case LToken of
      TOKEN_OFFSET:
        begin
          FScanner.MustGetFloat;
          FItem.ZOffset := FScanner.AsFloat;
        end;
      TOKEN_XOFFSET:
        begin
          FScanner.MustGetFloat;
          FItem.XOffset := FScanner.AsFloat;
        end;
      TOKEN_YOFFSET:
        begin
          FScanner.MustGetFloat;
          // the old parser wrote the Y offset in the X offset: kept
          FItem.XOffset := FScanner.AsFloat;
        end;
      TOKEN_SCALE:
        begin
          FScanner.MustGetFloat;
          FItem.XScale := FScanner.AsFloat;
          FItem.YScale := FScanner.AsFloat;
          FItem.ZScale := FScanner.AsFloat;
        end;
      TOKEN_XSCALE:
        begin
          FScanner.MustGetFloat;
          FItem.XScale := FScanner.AsFloat;
        end;
      TOKEN_YSCALE:
        begin
          FScanner.MustGetFloat;
          FItem.YScale := FScanner.AsFloat;
        end;
      TOKEN_ZSCALE:
        begin
          FScanner.MustGetFloat;
          FItem.ZScale := FScanner.AsFloat;
        end;
      TOKEN_FRAMEMERGE:
        begin
          FScanner.MustGetString;
          SetLength(FItem.FrameMerge, Length(FItem.FrameMerge) + 1);
          FItem.FrameMerge[High(FItem.FrameMerge)] := TScannerStrings.UpperAscii(FScanner.AsString);
        end;
      TOKEN_PROC:
        begin
          FScanner.MustGetString;
          FItem.Proc := FScanner.AsString;
        end;
    else
      begin
        FSink.AddModel(FItem);
        FModelPending := False;
        FScanner.UnGet;
        Break;
      end;
    end;
  end;
end;

function TModelDefinitionParser.ParseState: Boolean;
var
  LToken: Integer;
begin
  Result := False;
  FStatePending := True;
  FState.ModelIndex := -1;
  FState.Texture := -1;
  FState.StartFrame := -1;
  FState.EndFrame := -1;
  FState.NextFrame := -1;
  FState.State := 0;
  FState.Transparency := 1.0;
  ResetItem(FItem);
  SetLength(FItem.FrameMerge, 0);
  if not FScanner.GetString then
  begin
    Warn(SModelDefTokenExpected, [FScanner.Line]);
    Exit(True);
  end;
  FState.State := FLookup.FindState(TScannerStrings.UpperAscii(FScanner.AsString));
  if FState.State < 0 then
  begin
    Warn(SModelDefUnknownState, [FScanner.AsString, FScanner.Line]);
    FState.State := 0; // S_NULL
  end;

  while FScanner.GetString do
  begin
    LToken := TokenIndex(TScannerStrings.UpperAscii(FScanner.AsString));
    case LToken of
      TOKEN_MODEL:
        begin
          FScanner.MustGetString;
          FItem.Name := TScannerStrings.UpperAscii(FScanner.AsString);
          ResetItem(FItem);
          FState.ModelIndex := FSink.AddModel(FItem);
        end;
      TOKEN_TEXTURE:
        begin
          FScanner.MustGetString;
          FState.Texture := FSink.AddTexture(TScannerStrings.UpperAscii(FScanner.AsString));
        end;
      TOKEN_FRAME:
        begin
          FScanner.MustGetInteger;
          FState.StartFrame := FScanner.AsInteger;
          if FState.EndFrame < 0 then
            FState.EndFrame := FState.StartFrame;
        end;
      TOKEN_ENDFRAME:
        begin
          FScanner.MustGetInteger;
          FState.EndFrame := FScanner.AsInteger;
        end;
      TOKEN_TRANSPARENCY:
        begin
          FScanner.MustGetFloat;
          FState.Transparency := FScanner.AsFloat;
        end;
    else
      begin
        FSink.AddState(FState);
        FStatePending := False;
        FScanner.UnGet;
        Break;
      end;
    end;
  end;
end;

procedure TModelDefinitionParser.Parse(const AText: string; const ASink: IModelDefinitionSink);
var
  LToken: string;
begin
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  FSink := ASink;
  FItem.Name := '';
  ResetItem(FItem);
  SetLength(FItem.FrameMerge, 0);
  FState.ModelIndex := -1;
  FState.Texture := -1;
  FState.StartFrame := -1;
  FState.EndFrame := -1;
  FState.NextFrame := -1;
  FState.State := 0;
  FState.Transparency := 1.0;
  FModelPending := False;
  FStatePending := False;
  FScanner := TScriptScanner.Create(AText, FLog);
  try
    while FScanner.GetString do
    begin
      LToken := TScannerStrings.UpperAscii(FScanner.AsString);
      case TokenIndex(LToken) of
        TOKEN_MODELDEF:
          if ParseModel then
            Break;
        TOKEN_STATE:
          if ParseState then
            Break;
      else
        Warn(SModelDefUnknownToken, [LToken, FScanner.Line]);
      end;
    end;

    if FModelPending then
      FSink.AddModel(FItem);
    if FStatePending then
      FSink.AddState(FState);
  finally
    FreeAndNil(FScanner);
    FSink := nil;
  end;
end;

end.
