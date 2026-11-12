{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - a game written to a file and    }
{  read back                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.GameSaver;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.GameSaver,
  DelphiDoom.Tests.Keen.GameWorld;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenGameSaver = class(TObject)
  strict private
    FWorld: TKeenTestWorld;
    FPlay: IKeenPlayState;
    FLevel: IKeenLevelSetup;
    FSaver: TKeenGameSaver;
    procedure FillGame;
    function SavedBytes: TBytes;
    function LoadBytes(const ABytes: TBytes): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure LoStatoDelGiocoDovrebbeAvereIlFormatoDellOriginale;
    [Test]
    procedure IlFileDovrebbeAvereStatoPianiEAttori;
    [Test]
    procedure DovrebbeRileggereLoStatoIPianiEGliAttori;
    [Test]
    procedure DovrebbeRicaricareTuttoIlPianoENonSoloLInizio;
    [Test]
    procedure GliAttoriRilettiDovrebberoRidisegnarsi;
    [Test]
    procedure LaScatolaDeiPuntiDovrebbeEssereRidisegnataDopoIlCaricamento;
    [Test]
    procedure UnFileTroncatoDovrebbeDareFalso;
    [Test]
    procedure UnaMappaCheNonEsisteDovrebbeDareFalso;
    [Test]
    procedure UnoStatoCheNonEsisteDovrebbeDareFalso;
    [Test]
    procedure SenzaLivelloNonDovrebbeSalvare;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.PlayState, DelphiDoom.Keen.StateTable;

const
  MAP_WIDTH = 24;
  MAP_HEIGHT = 20;

type
  /// <summary>A level that is always the same map; setting it up puts the planes back as they were at the start</summary>
  TFakeLevel = class(TInterfacedObject, IKeenLevelSetup)
  strict private
    FMap: IKeenWorkingMap;
    FHasMap: Boolean;
  public
    Setups: Integer;
    constructor Create(const AMap: IKeenWorkingMap; AHasMap: Boolean);
    class procedure Fresh(const AMap: IKeenWorkingMap); static;
    function GetMap: IKeenWorkingMap;
    procedure SetupGameLevel(ALoadNow: Boolean);
    procedure HookFadeIn;
    procedure CenterViewOnPlayer;
  end;

{ TFakeLevel }

constructor TFakeLevel.Create(const AMap: IKeenWorkingMap; AHasMap: Boolean);
begin
  inherited Create;
  FMap := AMap;
  FHasMap := AHasMap;
end;

class procedure TFakeLevel.Fresh(const AMap: IKeenWorkingMap);
var
  LPlane: Integer;
  LIndex: Integer;
  LWords: TArray<Word>;
begin
  for LPlane := 0 to 2 do
  begin
    LWords := AMap.Planes[LPlane];
    for LIndex := 0 to High(LWords) do
      LWords[LIndex] := Word(1000 * LPlane + 7);
  end;
end;

function TFakeLevel.GetMap: IKeenWorkingMap;
begin
  if FHasMap then
    Result := FMap
  else
    Result := nil;
end;

procedure TFakeLevel.SetupGameLevel(ALoadNow: Boolean);
begin
  Inc(Setups);
  Fresh(FMap);
end;

procedure TFakeLevel.HookFadeIn;
begin
end;

procedure TFakeLevel.CenterViewOnPlayer;
begin
end;

{ TTestKeenGameSaver }

procedure TTestKeenGameSaver.Setup;
begin
  FWorld := TKeenTestWorld.Create(MAP_WIDTH, MAP_HEIGHT, KEEN_STATES);
  FPlay := TKeenPlayState.Create(FWorld.Events);
  FLevel := TFakeLevel.Create(FWorld.Map, True);
  FSaver := TKeenGameSaver.Create(FPlay, FWorld.Objects, FWorld.States, FLevel);
end;

procedure TTestKeenGameSaver.TearDown;
begin
  FSaver.Free;
  FLevel := nil;
  FPlay := nil;
  FWorld.Free;
end;

procedure TTestKeenGameSaver.FillGame;
var
  LState: PKeenGameState;
  LIndex: Integer;
  LObject: PKeenObject;
  LPlane: Integer;
  LWords: TArray<Word>;
begin
  LState := FPlay.GameState;
  LState^.WorldX := $1234;
  LState^.WorldY := $5678;
  LState^.LevelDone[3] := True;
  LState^.LevelDone[16] := True;
  LState^.Score := 123456;
  LState^.NextExtra := 160000;
  LState^.FlowerPowers := 7;
  LState^.BoobusBombs := 5;
  LState^.BombsThisLevel := 2;
  LState^.Keys := 1;
  LState^.MapOn := 4;
  LState^.Lives := 6;
  LState^.Difficulty := 2;
  // the planes: runs, single words and the tag of the compression
  for LPlane := 0 to 2 do
  begin
    LWords := FWorld.Map.Planes[LPlane];
    for LIndex := 0 to High(LWords) do
      if LIndex mod 50 < 40 then
        LWords[LIndex] := Word(LPlane + 1)
      else if LIndex mod 50 = 45 then
        LWords[LIndex] := KEEN_SAVE_RLEW_TAG
      else
        LWords[LIndex] := Word(LIndex * 7 + LPlane);
  end;
  // the player, the score box and two more actors
  FWorld.Objects.Init;
  LObject := FWorld.Objects.Player;
  LObject^.ObClass := kcKeen;
  LObject^.Active := kaYes;
  LObject^.X := 4000;
  LObject^.Y := 3000;
  LObject^.XDir := -1;
  LObject^.YSpeed := -40;
  LObject^.State := 5;
  LObject^.ShapeNum := 80;
  LObject^.Temp1 := 11;
  LObject^.Temp4 := -3;
  LObject^.HitNorth := 1;
  LObject := FWorld.Objects.ScoreObj;
  LObject^.ObClass := kcInert;
  LObject^.Active := kaAllways;
  LObject^.State := 2;
  LObject^.Temp1 := 99;
  LObject := FWorld.Objects.GetNewObj(False);
  LObject^.ObClass := kcTater;
  LObject^.Active := kaNo;
  LObject^.X := 9000;
  LObject^.TileLeft := 35;
  LObject^.NoThink := 3;
  LObject^.State := 100;
  LObject^.NeedToClip := True;
  LObject := FWorld.Objects.GetNewObj(False);
  LObject^.ObClass := kcShot;
  LObject^.Active := kaRemovable;
  LObject^.State := -1;
  LObject^.Bottom := 777;
end;

function TTestKeenGameSaver.SavedBytes: TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    Assert.IsTrue(FSaver.Save(LStream));
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

function TTestKeenGameSaver.LoadBytes(const ABytes: TBytes): Boolean;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create(ABytes);
  try
    Result := FSaver.Load(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TTestKeenGameSaver.LoStatoDelGiocoDovrebbeAvereIlFormatoDellOriginale;
var
  LState: TKeenGameState;
  LRecord: TKeenSaveGameState;
  LBytes: array[0..59] of Byte;
  LBack: TKeenGameState;
begin
  LState := Default(TKeenGameState);
  LState.WorldX := $0102;
  LState.WorldY := $0304;
  LState.LevelDone[1] := True;
  LState.Score := $0A0B0C0D;
  LState.NextExtra := 20000;
  LState.FlowerPowers := 3;
  LState.BoobusBombs := 12;
  LState.BombsThisLevel := 1;
  LState.Keys := 2;
  LState.MapOn := 5;
  LState.Lives := -1;
  LState.Difficulty := 3;
  LRecord := TKeenGameSaver.EncodeGameState(LState);
  Move(LRecord, LBytes, SizeOf(LBytes));
  // worldx, worldy, 17 booleans of 16 bits, score and nextextra (32 bits), seven ints of 16 bits
  Assert.AreEqual(2, Integer(LBytes[0]));
  Assert.AreEqual(1, Integer(LBytes[1]));
  Assert.AreEqual(0, Integer(LBytes[4]), 'leveldone[0]');
  Assert.AreEqual(1, Integer(LBytes[6]), 'leveldone[1]');
  Assert.AreEqual($0D, Integer(LBytes[38]), 'the score starts after 4 + 34 bytes');
  Assert.AreEqual($0A, Integer(LBytes[41]));
  Assert.AreEqual(3, Integer(LBytes[46]), 'flowerpowers');
  Assert.AreEqual(12, Integer(LBytes[48]));
  Assert.AreEqual(5, Integer(LBytes[54]), 'mapon');
  Assert.AreEqual($FF, Integer(LBytes[56]), 'lives');
  Assert.AreEqual(3, Integer(LBytes[58]), 'difficulty');
  LBack := TKeenGameSaver.DecodeGameState(LRecord);
  Assert.AreEqual(-1, Integer(LBack.Lives));
  Assert.IsTrue(LBack.LevelDone[1]);
  Assert.IsFalse(LBack.LevelDone[2]);
  Assert.AreEqual($0A0B0C0D, LBack.Score);
end;

procedure TTestKeenGameSaver.IlFileDovrebbeAvereStatoPianiEAttori;
var
  LBytes: TBytes;
  LPosition: Integer;
  LPlane: Integer;
  LLength: Integer;
begin
  FillGame;
  LBytes := SavedBytes;
  // the state, three planes each with its 16 bit length, four actors of 76 bytes
  LPosition := 60;
  for LPlane := 0 to 2 do
  begin
    LLength := LBytes[LPosition] or (LBytes[LPosition + 1] shl 8);
    Assert.IsTrue(LLength > 0);
    Assert.IsTrue(LLength < MAP_WIDTH * MAP_HEIGHT * 2, 'the plane is compressed');
    Inc(LPosition, 2 + LLength);
  end;
  Assert.AreEqual(LPosition + 4 * 76, Length(LBytes));
  // the first actor is the player: its class, then "active"
  Assert.AreEqual(Ord(kcKeen), Integer(LBytes[LPosition]));
  Assert.AreEqual(Ord(kaYes), Integer(LBytes[LPosition + 2]));
  // the state is at 30: the number of the state plus 1
  Assert.AreEqual(6, Integer(LBytes[LPosition + 30]));
  // "next" is at 72: another actor follows, but not the last one
  Assert.AreEqual(1, Integer(LBytes[LPosition + 72]));
  Assert.AreEqual(0, Integer(LBytes[LPosition + 3 * 76 + 72]));
  // the last actor has no state: 0, the nil of the C
  Assert.AreEqual(0, Integer(LBytes[LPosition + 3 * 76 + 30]));
end;

procedure TTestKeenGameSaver.DovrebbeRileggereLoStatoIPianiEGliAttori;
var
  LBytes: TBytes;
  LExpected: array[0..2] of TArray<Word>;
  LPlane: Integer;
  LIndex: Integer;
  LObject: PKeenObject;
  LState: PKeenGameState;
begin
  FillGame;
  for LPlane := 0 to 2 do
    LExpected[LPlane] := Copy(FWorld.Map.Planes[LPlane]);
  LBytes := SavedBytes;
  // another game in memory
  FPlay.GameState^ := Default(TKeenGameState);
  FWorld.Objects.Init;
  TFakeLevel.Fresh(FWorld.Map);
  Assert.IsTrue(LoadBytes(LBytes));
  Assert.AreEqual(1, (FLevel as TFakeLevel).Setups, 'the level of the saved map is set up before its planes are read');
  LState := FPlay.GameState;
  Assert.AreEqual($1234, Integer(LState^.WorldX));
  Assert.AreEqual(123456, LState^.Score);
  Assert.AreEqual(160000, LState^.NextExtra);
  Assert.AreEqual(7, Integer(LState^.FlowerPowers));
  Assert.AreEqual(5, Integer(LState^.BoobusBombs));
  Assert.AreEqual(2, Integer(LState^.BombsThisLevel));
  Assert.AreEqual(1, Integer(LState^.Keys));
  Assert.AreEqual(4, Integer(LState^.MapOn));
  Assert.AreEqual(6, Integer(LState^.Lives));
  Assert.AreEqual(2, Integer(LState^.Difficulty));
  Assert.IsTrue(LState^.LevelDone[3]);
  Assert.IsTrue(LState^.LevelDone[16]);
  Assert.IsFalse(LState^.LevelDone[4]);
  for LPlane := 0 to 2 do
    for LIndex := 0 to High(LExpected[LPlane]) do
      Assert.AreEqual(Integer(LExpected[LPlane][LIndex]), Integer(FWorld.Map.Planes[LPlane][LIndex]),
        Format('plane %d word %d', [LPlane, LIndex]));
  Assert.AreEqual(4, FWorld.Objects.Count);
  LObject := FWorld.Objects.Player;
  Assert.AreEqual(Ord(kcKeen), Ord(LObject^.ObClass));
  Assert.AreEqual(4000, Integer(LObject^.X));
  Assert.AreEqual(-1, Integer(LObject^.XDir));
  Assert.AreEqual(-40, Integer(LObject^.YSpeed));
  Assert.AreEqual(5, Integer(LObject^.State));
  Assert.AreEqual(80, Integer(LObject^.ShapeNum));
  Assert.AreEqual(11, Integer(LObject^.Temp1));
  Assert.AreEqual(-3, Integer(LObject^.Temp4));
  Assert.AreEqual(1, Integer(LObject^.HitNorth));
  LObject := FWorld.Objects.NextOf(FWorld.Objects.ScoreObj);
  Assert.AreEqual(Ord(kcTater), Ord(LObject^.ObClass));
  Assert.AreEqual(Ord(kaNo), Ord(LObject^.Active));
  Assert.AreEqual(9000, Integer(LObject^.X));
  Assert.AreEqual(35, Integer(LObject^.TileLeft));
  Assert.AreEqual(3, Integer(LObject^.NoThink));
  Assert.AreEqual(100, Integer(LObject^.State));
  Assert.IsTrue(LObject^.NeedToClip);
  LObject := FWorld.Objects.NextOf(LObject);
  Assert.AreEqual(Ord(kcShot), Ord(LObject^.ObClass));
  Assert.AreEqual(Ord(kaRemovable), Ord(LObject^.Active));
  Assert.AreEqual(-1, Integer(LObject^.State));
  Assert.AreEqual(777, Integer(LObject^.Bottom));
  Assert.IsFalse(Assigned(FWorld.Objects.NextOf(LObject)));
end;

procedure TTestKeenGameSaver.DovrebbeRicaricareTuttoIlPianoENonSoloLInizio;
var
  LBytes: TBytes;
  LLast: Integer;
begin
  // the C expands only as many bytes as the compressed plane has, so the end of each plane stays as the level
  // starts; here the whole plane comes back
  FillGame;
  LLast := MAP_WIDTH * MAP_HEIGHT - 1;
  FWorld.Map.Planes[1][LLast] := 4321;
  LBytes := SavedBytes;
  TFakeLevel.Fresh(FWorld.Map);
  Assert.IsTrue(LoadBytes(LBytes));
  Assert.AreEqual(4321, Integer(FWorld.Map.Planes[1][LLast]));
end;

procedure TTestKeenGameSaver.GliAttoriRilettiDovrebberoRidisegnarsi;
var
  LBytes: TBytes;
  LObject: PKeenObject;
begin
  FillGame;
  LObject := FWorld.Objects.Player;
  LObject^.NeedToReact := False;
  LObject^.Sprite := 5;
  LBytes := SavedBytes;
  Assert.IsTrue(LoadBytes(LBytes));
  LObject := FWorld.Objects.First;
  while Assigned(LObject) do
  begin
    Assert.IsTrue(LObject^.NeedToReact);
    Assert.AreEqual(0, LObject^.Sprite, 'the sprite of the refresh manager is not kept');
    LObject := FWorld.Objects.NextOf(LObject);
  end;
end;

procedure TTestKeenGameSaver.LaScatolaDeiPuntiDovrebbeEssereRidisegnataDopoIlCaricamento;
var
  LBytes: TBytes;
  LScore: PKeenObject;
begin
  FillGame;
  LBytes := SavedBytes;
  Assert.IsTrue(LoadBytes(LBytes));
  LScore := FWorld.Objects.ScoreObj;
  Assert.AreEqual(-1, Integer(LScore^.Temp1));
  Assert.AreEqual(-1, Integer(LScore^.Temp2));
  Assert.AreEqual(-1, Integer(LScore^.Temp3));
  Assert.AreEqual(-1, Integer(LScore^.Temp4));
end;

procedure TTestKeenGameSaver.UnFileTroncatoDovrebbeDareFalso;
var
  LBytes: TBytes;
  LLength: Integer;
begin
  FillGame;
  LBytes := SavedBytes;
  // cut in the state, in a plane, in an actor
  for LLength in TArray<Integer>.Create(0, 30, 61, 100, Length(LBytes) - 80, Length(LBytes) - 1) do
    Assert.IsFalse(LoadBytes(Copy(LBytes, 0, LLength)), 'cut at ' + IntToStr(LLength));
  Assert.IsTrue(LoadBytes(LBytes));
end;

procedure TTestKeenGameSaver.UnaMappaCheNonEsisteDovrebbeDareFalso;
var
  LBytes: TBytes;
begin
  FillGame;
  LBytes := SavedBytes;
  // mapon is at 54
  LBytes[54] := 200;
  Assert.IsFalse(LoadBytes(LBytes));
  Assert.AreEqual(0, (FLevel as TFakeLevel).Setups, 'nothing is set up for a map that does not exist');
end;

procedure TTestKeenGameSaver.UnoStatoCheNonEsisteDovrebbeDareFalso;
var
  LBytes: TBytes;
  LFirstActor: Integer;
begin
  FillGame;
  LBytes := SavedBytes;
  LFirstActor := Length(LBytes) - 4 * 76;
  // the address of a state of the original program, as a file of the original has
  LBytes[LFirstActor + 30] := $34;
  LBytes[LFirstActor + 31] := $12;
  Assert.IsFalse(LoadBytes(LBytes));
end;

procedure TTestKeenGameSaver.SenzaLivelloNonDovrebbeSalvare;
var
  LSaver: TKeenGameSaver;
  LStream: TBytesStream;
begin
  LSaver := TKeenGameSaver.Create(FPlay, FWorld.Objects, FWorld.States, TFakeLevel.Create(FWorld.Map, False));
  LStream := TBytesStream.Create;
  try
    Assert.IsFalse(LSaver.Save(LStream));
    Assert.AreEqual(Int64(0), LStream.Size);
  finally
    LStream.Free;
    LSaver.Free;
  end;
end;

procedure TTestKeenGameSaver.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(procedure begin TKeenGameSaver.Create(nil, FWorld.Objects, FWorld.States, FLevel).Free; end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenGameSaver.Create(FPlay, nil, FWorld.States, FLevel).Free; end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenGameSaver.Create(FPlay, FWorld.Objects, nil, FLevel).Free; end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenGameSaver.Create(FPlay, FWorld.Objects, FWorld.States, nil).Free; end,
    EArgumentNilException);
end;

end.
