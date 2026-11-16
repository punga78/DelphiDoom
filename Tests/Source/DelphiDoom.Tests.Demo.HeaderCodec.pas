{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the header of a demo                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Demo.HeaderCodec;

{$POINTERMATH ON}

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Demo.Types,
  DelphiDoom.Demo.Profiles,
  DelphiDoom.Demo.HeaderCodec;

type
  [TestFixture]
  [Category('demo')]
  TTestDemoHeaderCodec = class
  strict private
    procedure CompareRead(const AGame: Integer; const AProfile: TDemoHeaderProfile);
    procedure CompareWrite(const AGame: Integer; const AProfile: TDemoHeaderProfile);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereComeIlVecchioCodiceDiDoomPerOgniVersione;
    [Test]
    procedure DovrebbeLeggereComeIlVecchioCodiceDiHereticPerOgniVersione;
    [Test]
    procedure DovrebbeLeggereComeIlVecchioCodiceDiHexenPerOgniVersione;
    [Test]
    procedure DovrebbeLeggereComeIlVecchioCodiceDiStrifePerOgniVersione;
    [Test]
    procedure DovrebbeScrivereComeIlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeScrivereComeIlVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeScrivereComeIlVecchioCodiceDiHexen;
    [Test]
    procedure DovrebbeScrivereComeIlVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeRiconoscereLaFirmaEIlNumeroDiVersione;
    [Test]
    procedure DovrebbeLeggereUnaDemoSenzaFirmaDallaPrimaPosizione;
    [Test]
    procedure DovrebbeAvereLeFirmeDeiQuattroGiochi;
    [Test]
    procedure DovrebbeRileggereCioCheHaScritto;
  end;

implementation

uses
  System.SysUtils;

const
  GAME_DOOM = 0;
  GAME_HERETIC = 1;
  GAME_HEXEN = 2;
  GAME_STRIFE = 3;
  MAX_PLAYERS = 8;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..65535] of Byte;

var
  // The globals the old code of the four games read and wrote
  demo_p: PByteArray;
  demoversion: Byte;
  olddemo: Boolean;
  gameskill: Integer;
  gameepisode: Integer;
  gamemap: Integer;
  deathmatch: Integer;
  respawnparm: Boolean;
  fastparm: Boolean;
  nomonsters: Boolean;
  compatibilitymode: Boolean;
  spawnrandommonsters: Boolean;
  dogs: Integer;
  dog_jumping: Integer;
  consoleplayer: Integer;
  playeringame: array[0..MAX_PLAYERS - 1] of Boolean;
  systemrandomseed: Integer; // -1: M_SetSystemRandomSeed was not called
  MAXPLAYERS: Integer;
  VERSION: Byte;

function intval(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

procedure M_SetSystemRandomSeed(const ASeed: Integer);
begin
  systemrandomseed := ASeed;
end;

function M_GetSystemRandomSeed: Integer;
begin
  Result := 77;
end;

procedure ResetGlobals;
var
  LIndex: Integer;
begin
  gameskill := 0;
  gameepisode := 0;
  gamemap := 0;
  deathmatch := 0;
  respawnparm := False;
  fastparm := False;
  nomonsters := False;
  compatibilitymode := False;
  spawnrandommonsters := False;
  dogs := 0;
  dog_jumping := 0;
  consoleplayer := 0;
  for LIndex := 0 to MAX_PLAYERS - 1 do
    playeringame[LIndex] := False;
  systemrandomseed := -1;
end;

// ---------------------------------------------------------------------------
// The old code, copied as it was: the part of G_DoPlayDemo that follows the
// version byte (demo_p is on it) and G_BeginRecording, one per game
// ---------------------------------------------------------------------------

procedure OldDoom_ReadBody;
var
  i: Integer;
begin
  demo_p := @demo_p[1];

  gameskill := demo_p[0];
  demo_p := @demo_p[1];

  gameepisode := demo_p[0];
  demo_p := @demo_p[1];

  gamemap := demo_p[0];
  demo_p := @demo_p[1];

  deathmatch := demo_p[0];
  demo_p := @demo_p[1];

  respawnparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  fastparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  nomonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  if olddemo then
    compatibilitymode := true // force old compatibility mode
  else
  begin
    compatibilitymode := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;

  M_SetSystemRandomSeed(0);
  if demoversion >= 114 then
  begin
    spawnrandommonsters := demo_p[0] <> 0;
    demo_p := @demo_p[1];
    if demoversion >= 120 then
    begin
      M_SetSystemRandomSeed(demo_p[0]);
      demo_p := @demo_p[1];
    end;
  end
  else
  begin
    spawnrandommonsters := false;
  end;

  if demoversion >= 205 then
  begin
    dogs := demo_p[0];
    demo_p := @demo_p[1];
    dog_jumping := demo_p[0];
    demo_p := @demo_p[1];
  end
  else
  begin
    dogs := 0;
    dog_jumping := 0;
  end;

  consoleplayer := demo_p[0];
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;
end;

procedure OldHeretic_ReadBody;
var
  i: Integer;
begin
  demo_p := @demo_p[1];

  gameskill := demo_p[0];
  demo_p := @demo_p[1];

  gameepisode := demo_p[0];
  demo_p := @demo_p[1];

  gamemap := demo_p[0];
  demo_p := @demo_p[1];

  deathmatch := demo_p[0];
  demo_p := @demo_p[1];

  respawnparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  fastparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  nomonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  compatibilitymode := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  spawnrandommonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];
  if demoversion >= 113 then
  begin
    M_SetSystemRandomSeed(demo_p[0]);
    demo_p := @demo_p[1];
  end;

  consoleplayer := demo_p[0];
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;
end;

procedure OldHexen_ReadBody;
var
  i: Integer;
begin
  demo_p := @demo_p[1];

  gameskill := demo_p[0];
  demo_p := @demo_p[1];

  gameepisode := demo_p[0];
  demo_p := @demo_p[1];

  gamemap := demo_p[0];
  demo_p := @demo_p[1];

  deathmatch := demo_p[0];
  demo_p := @demo_p[1];

  respawnparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  fastparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  nomonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  compatibilitymode := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  spawnrandommonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];
  if demoversion >= 207 then
  begin
    M_SetSystemRandomSeed(demo_p[0]);
    demo_p := @demo_p[1];
  end
  else
    M_SetSystemRandomSeed(0);

  consoleplayer := demo_p[0];
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;
end;

procedure OldStrife_ReadBody;
var
  i: Integer;
begin
  demo_p := @demo_p[1];

  gameskill := demo_p[0];
  demo_p := @demo_p[1];

  gamemap := demo_p[0];
  demo_p := @demo_p[1];

  deathmatch := demo_p[0];
  demo_p := @demo_p[1];

  respawnparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  fastparm := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  nomonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  compatibilitymode := demo_p[0] <> 0;
  demo_p := @demo_p[1];

  spawnrandommonsters := demo_p[0] <> 0;
  demo_p := @demo_p[1];
  M_SetSystemRandomSeed(demo_p[0]);
  demo_p := @demo_p[1];

  consoleplayer := demo_p[0];
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[i] := demo_p[0] <> 0;
    demo_p := @demo_p[1];
  end;
end;

procedure OldDoom_BeginRecording(const ADemoHeader: Integer);
var
  i: Integer;
begin
  PInteger(demo_p)^ := ADemoHeader;
  demo_p := @demo_p[4];

  demo_p[0] := VERSION;
  demo_p := @demo_p[1];

  demo_p[0] := Ord(gameskill);
  demo_p := @demo_p[1];

  demo_p[0] := gameepisode;
  demo_p := @demo_p[1];

  demo_p[0] := gamemap;
  demo_p := @demo_p[1];

  demo_p[0] := deathmatch;
  demo_p := @demo_p[1];

  demo_p[0] := intval(respawnparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(fastparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(nomonsters);
  demo_p := @demo_p[1];

  demo_p[0] := intval(compatibilitymode);
  demo_p := @demo_p[1];

  demo_p[0] := intval(spawnrandommonsters);
  demo_p := @demo_p[1];

  demo_p[0] := M_GetSystemRandomSeed;
  demo_p := @demo_p[1];

  // Version 205 - Dogs
  demo_p[0] := dogs;
  demo_p := @demo_p[1];

  demo_p[0] := dog_jumping;
  demo_p := @demo_p[1];

  demo_p[0] := consoleplayer;
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    demo_p[0] := intval(playeringame[i]);
    demo_p := @demo_p[1];
  end;
end;

// Heretic and Hexen: the same bytes, the magic is the only difference
procedure OldHeretic_BeginRecording(const ADemoHeader: Integer);
var
  i: Integer;
begin
  PInteger(demo_p)^ := ADemoHeader;
  demo_p := @demo_p[4];

  demo_p[0] := VERSION;
  demo_p := @demo_p[1];

  demo_p[0] := Ord(gameskill);
  demo_p := @demo_p[1];

  demo_p[0] := gameepisode;
  demo_p := @demo_p[1];

  demo_p[0] := gamemap;
  demo_p := @demo_p[1];

  demo_p[0] := deathmatch;
  demo_p := @demo_p[1];

  demo_p[0] := intval(respawnparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(fastparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(nomonsters);
  demo_p := @demo_p[1];

  demo_p[0] := intval(compatibilitymode);
  demo_p := @demo_p[1];

  demo_p[0] := intval(spawnrandommonsters);
  demo_p := @demo_p[1];

  demo_p[0] := M_GetSystemRandomSeed;
  demo_p := @demo_p[1];

  demo_p[0] := consoleplayer;
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    demo_p[0] := intval(playeringame[i]);
    demo_p := @demo_p[1];
  end;
end;

procedure OldStrife_BeginRecording(const ADemoHeader: Integer);
var
  i: Integer;
begin
  PInteger(demo_p)^ := ADemoHeader;
  demo_p := @demo_p[4];

  demo_p[0] := VERSION;
  demo_p := @demo_p[1];

  demo_p[0] := Ord(gameskill);
  demo_p := @demo_p[1];

  demo_p[0] := gamemap;
  demo_p := @demo_p[1];

  demo_p[0] := deathmatch;
  demo_p := @demo_p[1];

  demo_p[0] := intval(respawnparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(fastparm);
  demo_p := @demo_p[1];

  demo_p[0] := intval(nomonsters);
  demo_p := @demo_p[1];

  demo_p[0] := intval(compatibilitymode);
  demo_p := @demo_p[1];

  demo_p[0] := intval(spawnrandommonsters);
  demo_p := @demo_p[1];

  demo_p[0] := M_GetSystemRandomSeed;
  demo_p := @demo_p[1];

  demo_p[0] := consoleplayer;
  demo_p := @demo_p[1];

  for i := 0 to MAXPLAYERS - 1 do
  begin
    demo_p[0] := intval(playeringame[i]);
    demo_p := @demo_p[1];
  end;
end;

procedure RunOldRead(const AGame: Integer);
begin
  case AGame of
    GAME_DOOM: OldDoom_ReadBody;
    GAME_HERETIC: OldHeretic_ReadBody;
    GAME_HEXEN: OldHexen_ReadBody;
  else
    OldStrife_ReadBody;
  end;
end;

procedure RunOldWrite(const AGame: Integer; const AMagic: Integer);
begin
  case AGame of
    GAME_DOOM: OldDoom_BeginRecording(AMagic);
    GAME_STRIFE: OldStrife_BeginRecording(AMagic);
  else
    OldHeretic_BeginRecording(AMagic);
  end;
end;

procedure FillRandom(var ABuffer: array of Byte);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ABuffer) do
    ABuffer[LIndex] := Random(256);
end;

{ TTestDemoHeaderCodec }

procedure TTestDemoHeaderCodec.Setup;
begin
  RandSeed := 245;
  MAXPLAYERS := 4;
  VERSION := 207;
end;

procedure TTestDemoHeaderCodec.CompareRead(const AGame: Integer;
  const AProfile: TDemoHeaderProfile);
var
  LBuffer: array[0..63] of Byte;
  LVersion: Integer;
  LRepeat: Integer;
  LOld: Integer;
  LPosition: PByte;
  LHeader: TDemoHeader;
  LIndex: Integer;
  LExpectedSeed: Integer;
  LContext: string;
begin
  for LVersion := 0 to 255 do
    for LOld := 0 to Ord(AGame = GAME_DOOM) do
      for LRepeat := 1 to 6 do
      begin
        FillRandom(LBuffer);
        LBuffer[0] := LVersion;
        LContext := Format('game %d version %d old %d', [AGame, LVersion, LOld]);

        ResetGlobals;
        demo_p := @LBuffer[0];
        demoversion := LVersion;
        olddemo := LOld = 1;
        RunOldRead(AGame);

        LPosition := @LBuffer[0];
        TDemoHeaderCodec.Read(LPosition, AProfile, LOld = 1, LHeader);

        Assert.AreEqual<NativeInt>(NativeInt(demo_p) - NativeInt(@LBuffer[0]),
          NativeInt(LPosition) - NativeInt(@LBuffer[0]), 'bytes read, ' + LContext);
        Assert.AreEqual(gameskill, Integer(LHeader.Skill), 'skill, ' + LContext);
        if AProfile.HasEpisode then
          Assert.AreEqual(gameepisode, Integer(LHeader.Episode), 'episode, ' + LContext);
        Assert.AreEqual(gamemap, Integer(LHeader.Map), 'map, ' + LContext);
        Assert.AreEqual(deathmatch, Integer(LHeader.Deathmatch), 'deathmatch, ' + LContext);
        Assert.AreEqual(respawnparm, LHeader.Respawn, 'respawn, ' + LContext);
        Assert.AreEqual(fastparm, LHeader.Fast, 'fast, ' + LContext);
        Assert.AreEqual(nomonsters, LHeader.NoMonsters, 'nomonsters, ' + LContext);
        if LOld = 0 then
          Assert.AreEqual(compatibilitymode, LHeader.Compatibility, 'compatibility, ' + LContext)
        else
          Assert.IsFalse(LHeader.Compatibility, 'an old demo has no byte, ' + LContext);
        Assert.AreEqual(spawnrandommonsters, LHeader.SpawnRandomMonsters, 'spawn, ' + LContext);
        Assert.AreEqual(dogs, Integer(LHeader.Dogs), 'dogs, ' + LContext);
        Assert.AreEqual(dog_jumping, Integer(LHeader.DogJumping), 'dog jumping, ' + LContext);
        Assert.AreEqual(consoleplayer, Integer(LHeader.ConsolePlayer), 'console, ' + LContext);
        for LIndex := 0 to MAXPLAYERS - 1 do
          Assert.AreEqual(playeringame[LIndex], LHeader.PlayersInGame[LIndex],
            'player ' + IntToStr(LIndex) + ', ' + LContext);

        // What the caller does with the seed: Doom and Hexen reset it to zero when the
        // header has none, Heretic leaves it alone, Strife always has it
        if LHeader.HasSeed then
          LExpectedSeed := LHeader.Seed
        else if AGame in [GAME_DOOM, GAME_HEXEN] then
          LExpectedSeed := 0
        else
          LExpectedSeed := -1;
        Assert.AreEqual(systemrandomseed, LExpectedSeed, 'seed, ' + LContext);
      end;
end;

procedure TTestDemoHeaderCodec.CompareWrite(const AGame: Integer;
  const AProfile: TDemoHeaderProfile);
var
  LOldBytes: array[0..63] of Byte;
  LNewBytes: array[0..63] of Byte;
  LRepeat: Integer;
  LHeader: TDemoHeader;
  LIndex: Integer;
  LPosition: PByte;
begin
  for LRepeat := 1 to 300 do
  begin
    LHeader := Default(TDemoHeader);
    LHeader.Version := VERSION;
    LHeader.Skill := Random(5);
    LHeader.Episode := Random(5);
    LHeader.Map := Random(40);
    LHeader.Deathmatch := Random(3);
    LHeader.Respawn := Random(2) = 1;
    LHeader.Fast := Random(2) = 1;
    LHeader.NoMonsters := Random(2) = 1;
    LHeader.Compatibility := Random(2) = 1;
    LHeader.SpawnRandomMonsters := Random(2) = 1;
    LHeader.Seed := 77;
    LHeader.Dogs := Random(8);
    LHeader.DogJumping := Random(2);
    LHeader.ConsolePlayer := Random(4);
    for LIndex := 0 to MAXPLAYERS - 1 do
      LHeader.PlayersInGame[LIndex] := Random(2) = 1;

    gameskill := LHeader.Skill;
    gameepisode := LHeader.Episode;
    gamemap := LHeader.Map;
    deathmatch := LHeader.Deathmatch;
    respawnparm := LHeader.Respawn;
    fastparm := LHeader.Fast;
    nomonsters := LHeader.NoMonsters;
    compatibilitymode := LHeader.Compatibility;
    spawnrandommonsters := LHeader.SpawnRandomMonsters;
    dogs := LHeader.Dogs;
    dog_jumping := LHeader.DogJumping;
    consoleplayer := LHeader.ConsolePlayer;
    for LIndex := 0 to MAXPLAYERS - 1 do
      playeringame[LIndex] := LHeader.PlayersInGame[LIndex];

    FillChar(LOldBytes, SizeOf(LOldBytes), $EE);
    FillChar(LNewBytes, SizeOf(LNewBytes), $EE);

    demo_p := @LOldBytes[0];
    RunOldWrite(AGame, Integer(AProfile.Magic));

    LPosition := @LNewBytes[0];
    TDemoHeaderCodec.Write(LPosition, AProfile, LHeader);

    Assert.AreEqual<NativeInt>(NativeInt(demo_p) - NativeInt(@LOldBytes[0]),
      NativeInt(LPosition) - NativeInt(@LNewBytes[0]), 'bytes written');
    Assert.IsTrue(CompareMem(@LOldBytes[0], @LNewBytes[0], SizeOf(LOldBytes)), 'the bytes of the header');
  end;
end;

procedure TTestDemoHeaderCodec.DovrebbeLeggereComeIlVecchioCodiceDiDoomPerOgniVersione;
begin
  CompareRead(GAME_DOOM, TDemoProfiles.Doom(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeLeggereComeIlVecchioCodiceDiHereticPerOgniVersione;
begin
  CompareRead(GAME_HERETIC, TDemoProfiles.Heretic(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeLeggereComeIlVecchioCodiceDiHexenPerOgniVersione;
begin
  MAXPLAYERS := 8;
  CompareRead(GAME_HEXEN, TDemoProfiles.Hexen(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeLeggereComeIlVecchioCodiceDiStrifePerOgniVersione;
begin
  CompareRead(GAME_STRIFE, TDemoProfiles.Strife(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeScrivereComeIlVecchioCodiceDiDoom;
begin
  CompareWrite(GAME_DOOM, TDemoProfiles.Doom(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeScrivereComeIlVecchioCodiceDiHeretic;
begin
  CompareWrite(GAME_HERETIC, TDemoProfiles.Heretic(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeScrivereComeIlVecchioCodiceDiHexen;
begin
  MAXPLAYERS := 8;
  CompareWrite(GAME_HEXEN, TDemoProfiles.Hexen(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeScrivereComeIlVecchioCodiceDiStrife;
begin
  CompareWrite(GAME_STRIFE, TDemoProfiles.Strife(MAXPLAYERS));
end;

procedure TTestDemoHeaderCodec.DovrebbeRiconoscereLaFirmaEIlNumeroDiVersione;
var
  LBytes: array[0..7] of Byte;
  LPosition: PByte;
  LVersion: Byte;
begin
  PCardinal(@LBytes[0])^ := $4F4D4544;
  LBytes[4] := 207;
  LPosition := @LBytes[0];
  Assert.IsTrue(TDemoHeaderCodec.ReadVersion(LPosition, $4F4D4544, LVersion));
  Assert.AreEqual<Integer>(207, LVersion);
  Assert.AreEqual<NativeInt>(4, NativeInt(LPosition) - NativeInt(@LBytes[0]));
end;

procedure TTestDemoHeaderCodec.DovrebbeLeggereUnaDemoSenzaFirmaDallaPrimaPosizione;
var
  LBytes: array[0..7] of Byte;
  LPosition: PByte;
  LVersion: Byte;
begin
  FillChar(LBytes, SizeOf(LBytes), 0);
  LBytes[0] := 110;
  LPosition := @LBytes[0];
  Assert.IsFalse(TDemoHeaderCodec.ReadVersion(LPosition, $4F4D4544, LVersion));
  Assert.AreEqual<Integer>(110, LVersion);
  Assert.AreEqual<NativeInt>(0, NativeInt(LPosition) - NativeInt(@LBytes[0]));
end;

procedure TTestDemoHeaderCodec.DovrebbeAvereLeFirmeDeiQuattroGiochi;
begin
  Assert.AreEqual<Cardinal>($4F4D4544, TDemoProfiles.Doom(4).Magic);
  Assert.AreEqual<Cardinal>($4D454448, TDemoProfiles.Heretic(4).Magic);
  Assert.AreEqual<Cardinal>($4D454458, TDemoProfiles.Hexen(8).Magic);
  Assert.AreEqual<Cardinal>($4F4D4544, TDemoProfiles.Strife(4).Magic);
  Assert.IsFalse(TDemoProfiles.Strife(4).HasEpisode);
  Assert.IsFalse(TDemoProfiles.Heretic(4).HasDogs);
end;

procedure TTestDemoHeaderCodec.DovrebbeRileggereCioCheHaScritto;
var
  LBytes: array[0..63] of Byte;
  LProfile: TDemoHeaderProfile;
  LWritten: TDemoHeader;
  LRead: TDemoHeader;
  LPosition: PByte;
  LVersion: Byte;
begin
  LProfile := TDemoProfiles.Doom(4);
  LWritten := Default(TDemoHeader);
  LWritten.Version := 207;
  LWritten.Skill := 3;
  LWritten.Episode := 2;
  LWritten.Map := 7;
  LWritten.Fast := True;
  LWritten.SpawnRandomMonsters := True;
  LWritten.Seed := 9;
  LWritten.Dogs := 2;
  LWritten.PlayersInGame[0] := True;
  LWritten.PlayersInGame[2] := True;

  LPosition := @LBytes[0];
  TDemoHeaderCodec.Write(LPosition, LProfile, LWritten);

  LPosition := @LBytes[0];
  Assert.IsTrue(TDemoHeaderCodec.ReadVersion(LPosition, LProfile.Magic, LVersion));
  TDemoHeaderCodec.Read(LPosition, LProfile, False, LRead);
  Assert.AreEqual<Integer>(207, LRead.Version);
  Assert.AreEqual<Integer>(3, LRead.Skill);
  Assert.AreEqual<Integer>(2, LRead.Episode);
  Assert.AreEqual<Integer>(7, LRead.Map);
  Assert.IsTrue(LRead.Fast);
  Assert.IsFalse(LRead.Respawn);
  Assert.IsTrue(LRead.SpawnRandomMonsters);
  Assert.IsTrue(LRead.HasSeed);
  Assert.AreEqual<Integer>(9, LRead.Seed);
  Assert.AreEqual<Integer>(2, LRead.Dogs);
  Assert.IsTrue(LRead.PlayersInGame[0]);
  Assert.IsFalse(LRead.PlayersInGame[1]);
  Assert.IsTrue(LRead.PlayersInGame[2]);
end;

end.
