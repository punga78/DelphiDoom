{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the parser of the VOXELDEF lump                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.DefinitionParser;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   The old SC_DoParseVoxelDefinition without the engine: the words VOXELDEF (a voxel with
  ///   its offset, scale, flags, spins, and the sprite it replaces), STATE (a state that shows a
  ///   voxel with a frame) and the short form "SPRITE voxel [options]" go to a sink in the order
  ///   they are written. The states and the sprites of the game are asked to a lookup. The
  ///   problems are warnings, never exceptions. The scale is not less than 0.01.
  /// </summary>
  TVoxelDefinitionParser = class(TInterfacedObject, IVoxelDefinitionParser)
  strict private
    FLookup: IVoxelDefinitionLookup;
    FLog: ILog;
    FScanner: TScriptScanner;
    FSink: IVoxelDefinitionSink;
    FItem: TVoxelDefinitionItem;
    FState: TVoxelDefinitionState;
    FVoxelPending: Boolean;
    FStatePending: Boolean;
    class function TokenIndex(const AToken: string): Integer; static;
    class function NewItem: TVoxelDefinitionItem; static;
    procedure Warn(const AFormat: string; const AArguments: array of const);
    /// <summary>One of the options of a voxel (offset, scale, clipped, angle, spins); false if the word is not one</summary>
    function ReadOption(const ATokenIndex: Integer): Boolean;
    procedure AddStates(const AStates: TArray<Integer>; const AVoxelIndex: Integer);
    /// <summary>The word VOXELDEF; true if the text ends there and the parse is over</summary>
    function ParseVoxel: Boolean;
    function ParseState: Boolean;
    procedure ParseSpriteShortcut(const AToken: string);
  public
    constructor Create(const ALookup: IVoxelDefinitionLookup; const ALog: ILog);
    procedure Parse(const AText: string; const ASink: IVoxelDefinitionSink);
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

const
  TOKEN_VOXELDEF = 0;
  TOKEN_STATE = 1;
  TOKEN_OFFSET = 2;
  TOKEN_SCALE = 3;
  TOKEN_FRAME = 4;
  TOKEN_VOXEL = 5;
  TOKEN_REPLACE = 6;
  TOKEN_SPRITE = 7;
  TOKEN_CLIPPED = 8;
  TOKEN_ANGLEOFFSET = 9;
  TOKEN_DROPPEDSPIN = 10;
  TOKEN_PLACEDSPIN = 11;
  TOKEN_SPIN = 12;

  // the words of each token, in the order of the numbers above
  TOKEN_WORDS: array[0..12] of array[0..2] of string = (
    ('VOXELDEF', 'VOXELDEFINITION', ''),
    ('STATE', '', ''),
    ('OFFSET', '', ''),
    ('SCALE', '', ''),
    ('FRAME', '', ''),
    ('VOXEL', '', ''),
    ('REPLACE', 'REPLACES', 'REPLACING'),
    ('SPRITE', '', ''),
    ('CLIPPED', '', ''),
    ('ANGLEOFFSET', '', ''),
    ('DROPPEDSPIN', '', ''),
    ('PLACEDSPIN', '', ''),
    ('SPIN', '', '')
  );

{ TVoxelDefinitionParser }

constructor TVoxelDefinitionParser.Create(const ALookup: IVoxelDefinitionLookup; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALookup) then
    raise EArgumentNilException.Create('ALookup');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLookup := ALookup;
  FLog := ALog;
end;

class function TVoxelDefinitionParser.TokenIndex(const AToken: string): Integer;
var
  LIndex, LWord: Integer;
begin
  for LIndex := 0 to High(TOKEN_WORDS) do
    for LWord := 0 to High(TOKEN_WORDS[LIndex]) do
      if (TOKEN_WORDS[LIndex][LWord] <> '') and (TOKEN_WORDS[LIndex][LWord] = AToken) then
        Exit(LIndex);
  Result := -1;
end;

class function TVoxelDefinitionParser.NewItem: TVoxelDefinitionItem;
begin
  Result.Name := '';
  Result.Offset := 0.0;
  Result.Scale := 1.0;
  Result.AngleOffset := 0;
  Result.DroppedSpin := 0;
  Result.PlacedSpin := 0;
  Result.Flags := 0;
end;

procedure TVoxelDefinitionParser.Warn(const AFormat: string; const AArguments: array of const);
begin
  FLog.Warning(Format(AFormat, AArguments));
end;

function TVoxelDefinitionParser.ReadOption(const ATokenIndex: Integer): Boolean;
begin
  Result := True;
  case ATokenIndex of
    TOKEN_OFFSET:
      begin
        FScanner.MustGetFloat;
        FItem.Offset := FScanner.AsFloat;
      end;
    TOKEN_SCALE:
      begin
        FScanner.MustGetFloat;
        FItem.Scale := FScanner.AsFloat;
        if FItem.Scale < 0.01 then
          FItem.Scale := 0.01;
      end;
    TOKEN_CLIPPED:
      FItem.Flags := FItem.Flags or VOXEL_FLAG_CLIPPED;
    TOKEN_ANGLEOFFSET:
      begin
        FScanner.MustGetInteger;
        FItem.AngleOffset := FScanner.AsInteger;
      end;
    TOKEN_DROPPEDSPIN:
      begin
        FScanner.MustGetInteger;
        FItem.DroppedSpin := FScanner.AsInteger;
      end;
    TOKEN_PLACEDSPIN:
      begin
        FScanner.MustGetInteger;
        FItem.PlacedSpin := FScanner.AsInteger;
      end;
    TOKEN_SPIN:
      begin
        FScanner.MustGetInteger;
        FItem.DroppedSpin := FScanner.AsInteger;
        FItem.PlacedSpin := FScanner.AsInteger;
      end;
  else
    Result := False;
  end;
end;

procedure TVoxelDefinitionParser.AddStates(const AStates: TArray<Integer>; const AVoxelIndex: Integer);
var
  LIndex: Integer;
  LState: TVoxelDefinitionState;
begin
  for LIndex := 0 to High(AStates) do
  begin
    LState.VoxelIndex := AVoxelIndex;
    LState.Frame := 0;
    LState.State := AStates[LIndex];
    FSink.AddState(LState);
  end;
end;

function TVoxelDefinitionParser.ParseVoxel: Boolean;
var
  LToken: Integer;
  LSpriteName: string;
  LStates: TArray<Integer>;
  LVoxelIndex: Integer;
begin
  Result := False;
  FVoxelPending := True;
  FItem := NewItem;
  if not FScanner.GetString then
  begin
    Warn(SVoxelDefTokenExpected, [FScanner.Line]);
    Exit(True);
  end;
  FItem.Name := TScannerStrings.UpperAscii(FScanner.AsString);

  while FScanner.GetString do
  begin
    LToken := TokenIndex(TScannerStrings.UpperAscii(FScanner.AsString));
    if ReadOption(LToken) then
      Continue;
    if LToken = TOKEN_REPLACE then
    begin
      if not FScanner.GetString then
      begin
        Warn(SVoxelDefTokenExpected, [FScanner.Line]);
        Break;
      end;
      if TokenIndex(TScannerStrings.UpperAscii(FScanner.AsString)) <> TOKEN_SPRITE then
      begin
        Warn(SVoxelDefSpriteExpected, [FScanner.Line]);
        Break;
      end;
      FScanner.MustGetString;
      LSpriteName := FScanner.AsString;
      FSink.CheckSprite(LSpriteName, FItem.Name);
      LStates := FLookup.FindStatesOfSprite(LSpriteName);
      LVoxelIndex := FSink.AddVoxel(FItem);
      FVoxelPending := False;
      if Length(LStates) > 0 then
        AddStates(LStates, LVoxelIndex)
      else
        Warn(SVoxelDefSpriteNotFound, [LSpriteName, FScanner.Line]);
    end
    else
    begin
      FSink.AddVoxel(FItem);
      FVoxelPending := False;
      FScanner.UnGet;
      Break;
    end;
  end;
end;

function TVoxelDefinitionParser.ParseState: Boolean;
var
  LToken: Integer;
begin
  Result := False;
  FStatePending := True;
  FState.VoxelIndex := 0;
  FState.Frame := 0;
  FState.State := 0;
  FItem.Offset := 0.0;
  FItem.Scale := 1.0;
  FItem.AngleOffset := 0;
  FItem.DroppedSpin := 0;
  FItem.PlacedSpin := 0;
  FState.VoxelIndex := -1;
  if not FScanner.GetString then
  begin
    Warn(SVoxelDefTokenExpected, [FScanner.Line]);
    Exit(True);
  end;
  FState.State := FLookup.FindState(TScannerStrings.UpperAscii(FScanner.AsString));
  if FState.State < 0 then
  begin
    Warn(SVoxelDefUnknownState, [FScanner.AsString, FScanner.Line]);
    FState.State := 0; // S_NULL
  end;

  while FScanner.GetString do
  begin
    LToken := TokenIndex(TScannerStrings.UpperAscii(FScanner.AsString));
    case LToken of
      TOKEN_VOXEL:
        begin
          FScanner.MustGetString;
          FItem.Name := TScannerStrings.UpperAscii(FScanner.AsString);
          FItem.Offset := 0.0;
          FItem.Scale := 1.0;
          FItem.AngleOffset := 0;
          FItem.Flags := 0;
          FState.VoxelIndex := FSink.AddVoxel(FItem);
        end;
      TOKEN_FRAME:
        begin
          FScanner.MustGetInteger;
          FState.Frame := FScanner.AsInteger;
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

procedure TVoxelDefinitionParser.ParseSpriteShortcut(const AToken: string);
var
  LSpriteName: string;
  LStates: TArray<Integer>;
  LVoxelIndex: Integer;
begin
  LSpriteName := FScanner.AsString;
  FVoxelPending := False;
  LStates := FLookup.FindStatesOfSprite(LSpriteName);
  if Length(LStates) = 0 then
  begin
    Warn(SVoxelDefUnknownToken, [AToken, FScanner.Line]);
    Exit;
  end;

  FScanner.MustGetString;
  FItem := NewItem;
  FItem.Name := FScanner.AsString;

  FVoxelPending := True;
  while FScanner.GetString do
  begin
    if ReadOption(TokenIndex(TScannerStrings.UpperAscii(FScanner.AsString))) then
      Continue;
    LVoxelIndex := FSink.AddVoxel(FItem);
    FVoxelPending := False;
    AddStates(LStates, LVoxelIndex);
    FScanner.UnGet;
    Break;
  end;
  if FVoxelPending then
  begin
    LVoxelIndex := FSink.AddVoxel(FItem);
    FVoxelPending := False;
    AddStates(LStates, LVoxelIndex);
  end;
end;

procedure TVoxelDefinitionParser.Parse(const AText: string; const ASink: IVoxelDefinitionSink);
var
  LToken: string;
begin
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  FSink := ASink;
  FItem := NewItem;
  FState.VoxelIndex := 0;
  FState.Frame := 0;
  FState.State := 0;
  FVoxelPending := False;
  FStatePending := False;
  FScanner := TScriptScanner.Create(AText, FLog);
  try
    FScanner.AddIgnoreToken('=');
    while FScanner.GetString do
    begin
      LToken := TScannerStrings.UpperAscii(FScanner.AsString);
      case TokenIndex(LToken) of
        TOKEN_VOXELDEF:
          if ParseVoxel then
            Break;
        TOKEN_STATE:
          if ParseState then
            Break;
      else
        ParseSpriteShortcut(LToken);
      end;
    end;

    if FVoxelPending then
      FSink.AddVoxel(FItem);
    if FStatePending then
      FSink.AddState(FState);
  finally
    FreeAndNil(FScanner);
    FSink := nil;
  end;
end;

end.
