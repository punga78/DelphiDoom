{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a game written to a file and read back            }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SaveGame and LoadGame of kd_demo.c                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GameSaver;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.UserTypes,
  DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf;

type
  /// <summary>
  ///   What a saved game has after the header of the user manager, in the layout of the original: the state of
  ///   the game (gametype, 60 bytes), the three planes of the map each as a 16 bit length and RLEW data with the
  ///   tag $ABCD, and the actors from the player on (objtype, 76 bytes each).
  ///   A file of the original program cannot be read: its actors have the address of their state in the data
  ///   segment of that program, here the field has the number of the state plus 1. The rest is the same
  /// </summary>
  TKeenGameSaver = class
  strict private
    FPlay: IKeenPlayState;
    FObjects: IKeenObjectList;
    FStates: IKeenStateTable;
    FLevel: IKeenLevelSetup;
    class function ToRecord(const AObject: TKeenObject; AHasNext: Boolean): TKeenSaveObject; static;
    procedure FromRecord(const ARecord: TKeenSaveObject; AObject: PKeenObject);
  public
    constructor Create(const APlay: IKeenPlayState; const AObjects: IKeenObjectList; const AStates: IKeenStateTable;
      const ALevel: IKeenLevelSetup);
    /// <summary>gametype as the file has it</summary>
    class function EncodeGameState(const AState: TKeenGameState): TKeenSaveGameState; static;
    class function DecodeGameState(const ARecord: TKeenSaveGameState): TKeenGameState; static;
    /// <summary>SaveGame; false if the stream refuses the bytes or no level is being played</summary>
    function Save(AStream: TStream): Boolean;
    /// <summary>
    ///   LoadGame: the state, the level of its map set up again, the planes and the actors. False if the data end
    ///   too soon or are not the ones of a game (a map or a state that does not exist, bad RLEW data)
    /// </summary>
    function Load(AStream: TStream): Boolean;
  end;

implementation

uses
  DelphiDoom.Keen.Rlew;

{ TKeenGameSaver }

constructor TKeenGameSaver.Create(const APlay: IKeenPlayState; const AObjects: IKeenObjectList;
  const AStates: IKeenStateTable; const ALevel: IKeenLevelSetup);
begin
  inherited Create;
  if not Assigned(APlay) then
    raise EArgumentNilException.Create('APlay');
  if not Assigned(AObjects) then
    raise EArgumentNilException.Create('AObjects');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(ALevel) then
    raise EArgumentNilException.Create('ALevel');
  FPlay := APlay;
  FObjects := AObjects;
  FStates := AStates;
  FLevel := ALevel;
end;

class function TKeenGameSaver.EncodeGameState(const AState: TKeenGameState): TKeenSaveGameState;
var
  LIndex: Integer;
begin
  Result.WorldX := AState.WorldX;
  Result.WorldY := AState.WorldY;
  for LIndex := 0 to KEEN_GAMELEVELS - 1 do
    Result.LevelDone[LIndex] := Ord(AState.LevelDone[LIndex]);
  Result.Score := AState.Score;
  Result.NextExtra := AState.NextExtra;
  Result.FlowerPowers := AState.FlowerPowers;
  Result.BoobusBombs := AState.BoobusBombs;
  Result.BombsThisLevel := AState.BombsThisLevel;
  Result.Keys := AState.Keys;
  Result.MapOn := AState.MapOn;
  Result.Lives := AState.Lives;
  Result.Difficulty := AState.Difficulty;
end;

class function TKeenGameSaver.DecodeGameState(const ARecord: TKeenSaveGameState): TKeenGameState;
var
  LIndex: Integer;
begin
  Result.WorldX := ARecord.WorldX;
  Result.WorldY := ARecord.WorldY;
  for LIndex := 0 to KEEN_GAMELEVELS - 1 do
    Result.LevelDone[LIndex] := ARecord.LevelDone[LIndex] <> 0;
  Result.Score := ARecord.Score;
  Result.NextExtra := ARecord.NextExtra;
  Result.FlowerPowers := ARecord.FlowerPowers;
  Result.BoobusBombs := ARecord.BoobusBombs;
  Result.BombsThisLevel := ARecord.BombsThisLevel;
  Result.Keys := ARecord.Keys;
  Result.MapOn := ARecord.MapOn;
  Result.Lives := ARecord.Lives;
  Result.Difficulty := ARecord.Difficulty;
end;

class function TKeenGameSaver.ToRecord(const AObject: TKeenObject; AHasNext: Boolean): TKeenSaveObject;
begin
  Result.ObClass := Ord(AObject.ObClass);
  Result.Active := Ord(AObject.Active);
  Result.NeedToReact := Ord(AObject.NeedToReact);
  Result.NeedToClip := Ord(AObject.NeedToClip);
  Result.NoThink := AObject.NoThink;
  Result.X := AObject.X;
  Result.Y := AObject.Y;
  Result.XDir := AObject.XDir;
  Result.YDir := AObject.YDir;
  Result.XMove := AObject.XMove;
  Result.YMove := AObject.YMove;
  Result.XSpeed := AObject.XSpeed;
  Result.YSpeed := AObject.YSpeed;
  Result.TicCount := AObject.TicCount;
  Result.TicAdjust := AObject.TicAdjust;
  // the C writes the address of the state; a state number plus 1 keeps 0 for "no state"
  Result.State := Word(AObject.State + 1);
  Result.ShapeNum := AObject.ShapeNum;
  Result.Left := AObject.Left;
  Result.Top := AObject.Top;
  Result.Right := AObject.Right;
  Result.Bottom := AObject.Bottom;
  Result.MidX := AObject.MidX;
  Result.TileLeft := AObject.TileLeft;
  Result.TileTop := AObject.TileTop;
  Result.TileRight := AObject.TileRight;
  Result.TileBottom := AObject.TileBottom;
  Result.TileMidX := AObject.TileMidX;
  Result.HitNorth := AObject.HitNorth;
  Result.HitEast := AObject.HitEast;
  Result.HitSouth := AObject.HitSouth;
  Result.HitWest := AObject.HitWest;
  Result.Temp1 := AObject.Temp1;
  Result.Temp2 := AObject.Temp2;
  Result.Temp3 := AObject.Temp3;
  Result.Temp4 := AObject.Temp4;
  Result.Sprite := KEEN_SAVE_NIL;
  Result.Next := Ord(AHasNext);
  Result.Prev := KEEN_SAVE_NIL;
end;

procedure TKeenGameSaver.FromRecord(const ARecord: TKeenSaveObject; AObject: PKeenObject);
begin
  if (Integer(ARecord.ObClass) > Ord(High(TKeenClass))) or (Integer(ARecord.Active) > Ord(High(TKeenActive))) then
    raise EKeenDataException.CreateFmt(SKeenSaveTruncated, ['an actor of a kind that does not exist']);
  if Integer(ARecord.State) > FStates.Count then
    raise EKeenDataException.CreateFmt(SKeenSaveBadState, [Integer(ARecord.State) - 1]);
  // the place in the list (Slot, Next, Prev) is the one of the list, as the C keeps its links
  AObject^.ObClass := TKeenClass(ARecord.ObClass);
  AObject^.Active := TKeenActive(ARecord.Active);
  AObject^.NeedToClip := ARecord.NeedToClip <> 0;
  AObject^.NoThink := ARecord.NoThink;
  AObject^.X := ARecord.X;
  AObject^.Y := ARecord.Y;
  AObject^.XDir := ARecord.XDir;
  AObject^.YDir := ARecord.YDir;
  AObject^.XMove := ARecord.XMove;
  AObject^.YMove := ARecord.YMove;
  AObject^.XSpeed := ARecord.XSpeed;
  AObject^.YSpeed := ARecord.YSpeed;
  AObject^.TicCount := ARecord.TicCount;
  AObject^.TicAdjust := ARecord.TicAdjust;
  AObject^.State := SmallInt(Integer(ARecord.State) - 1);
  AObject^.ShapeNum := ARecord.ShapeNum;
  AObject^.Left := ARecord.Left;
  AObject^.Top := ARecord.Top;
  AObject^.Right := ARecord.Right;
  AObject^.Bottom := ARecord.Bottom;
  AObject^.MidX := ARecord.MidX;
  AObject^.TileLeft := ARecord.TileLeft;
  AObject^.TileTop := ARecord.TileTop;
  AObject^.TileRight := ARecord.TileRight;
  AObject^.TileBottom := ARecord.TileBottom;
  AObject^.TileMidX := ARecord.TileMidX;
  AObject^.HitNorth := ARecord.HitNorth;
  AObject^.HitEast := ARecord.HitEast;
  AObject^.HitSouth := ARecord.HitSouth;
  AObject^.HitWest := ARecord.HitWest;
  AObject^.Temp1 := ARecord.Temp1;
  AObject^.Temp2 := ARecord.Temp2;
  AObject^.Temp3 := ARecord.Temp3;
  AObject^.Temp4 := ARecord.Temp4;
  // every actor draws itself again
  AObject^.NeedToReact := True;
  AObject^.Sprite := 0;
end;

function TKeenGameSaver.Save(AStream: TStream): Boolean;
var
  LState: TKeenSaveGameState;
  LMap: IKeenWorkingMap;
  LPlane: Integer;
  LCompressed: TBytes;
  LLength: Word;
  LObject: PKeenObject;
  LNext: PKeenObject;
  LRecord: TKeenSaveObject;
begin
  LMap := FLevel.Map;
  if not Assigned(LMap) then
    Exit(False);
  try
    LState := EncodeGameState(FPlay.GameState^);
    AStream.WriteBuffer(LState, SizeOf(LState));
    for LPlane := 0 to 2 do
    begin
      LCompressed := TKeenRlew.Compress(LMap.Planes[LPlane], KEEN_SAVE_RLEW_TAG);
      // the length is a 16 bit number, as in the file of the original
      if Length(LCompressed) > $FFFF then
        Exit(False);
      LLength := Word(Length(LCompressed));
      AStream.WriteBuffer(LLength, SizeOf(LLength));
      if LLength > 0 then
        AStream.WriteBuffer(LCompressed[0], LLength);
    end;
    LObject := FObjects.Player;
    while Assigned(LObject) do
    begin
      LNext := FObjects.NextOf(LObject);
      LRecord := ToRecord(LObject^, Assigned(LNext));
      AStream.WriteBuffer(LRecord, SizeOf(LRecord));
      LObject := LNext;
    end;
    Result := True;
  except
    // a stream that does not take the bytes is a disk that is full: the control panel says so
    on E: EStreamError do
      Result := False;
  end;
end;

function TKeenGameSaver.Load(AStream: TStream): Boolean;
var
  LState: TKeenSaveGameState;
  LMap: IKeenWorkingMap;
  LPlane: Integer;
  LLength: Word;
  LCompressed: TBytes;
  LExpanded: TBytes;
  LWords: TArray<Word>;
  LIndex: Integer;
  LRecord: TKeenSaveObject;
  LObject: PKeenObject;
  LRlew: IKeenRlew;
begin
  try
    AStream.ReadBuffer(LState, SizeOf(LState));
    if (LState.MapOn < 0) or (LState.MapOn >= KEEN_GAMELEVELS) then
      raise EKeenDataException.CreateFmt(SKeenSaveBadMap, [Integer(LState.MapOn)]);
    FPlay.GameState^ := DecodeGameState(LState);
    // the level of the map as it is at its start, then what the file has of it
    FLevel.SetupGameLevel(False);
    LMap := FLevel.Map;
    LRlew := TKeenRlew.Create;
    for LPlane := 0 to 2 do
    begin
      AStream.ReadBuffer(LLength, SizeOf(LLength));
      SetLength(LCompressed, LLength);
      if LLength > 0 then
        AStream.ReadBuffer(LCompressed[0], LLength);
      LWords := LMap.Planes[LPlane];
      // the C gives the compressed length as the length to expand, so only the first part of each plane comes
      // back and the rest is the map at its start: here the whole plane is expanded
      LExpanded := LRlew.Expand(LCompressed, 0, Length(LWords) * 2, KEEN_SAVE_RLEW_TAG);
      for LIndex := 0 to High(LWords) do
        LWords[LIndex] := Word(LExpanded[LIndex * 2]) or (Word(LExpanded[LIndex * 2 + 1]) shl 8);
    end;
    // the actors: the player, the score box and the others as they follow (at least the first two are there)
    FObjects.Init;
    AStream.ReadBuffer(LRecord, SizeOf(LRecord));
    FromRecord(LRecord, FObjects.Player);
    LObject := FObjects.ScoreObj;
    while True do
    begin
      AStream.ReadBuffer(LRecord, SizeOf(LRecord));
      FromRecord(LRecord, LObject);
      if LRecord.Next = KEEN_SAVE_NIL then
        Break;
      LObject := FObjects.GetNewObj(False);
    end;
    // force the score, the flower power and the lives of the score box to be drawn again
    LObject := FObjects.ScoreObj;
    LObject^.Temp1 := -1;
    LObject^.Temp2 := -1;
    LObject^.Temp3 := -1;
    LObject^.Temp4 := -1;
    Result := True;
  except
    // the file ends too soon or is not a game: the control panel shows "File is Incomplete" and the game is
    // abandoned, as with a read that fails in the original
    on E: EStreamError do
      Result := False;
    on E: EKeenException do
      Result := False;
  end;
end;

end.
