{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - greed library: games of TGreedGame joined by a net in    }
{  memory                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.NetGame;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Net.Intf, DelphiDoom.Tests.Greed.GameFakes,
  DelphiDoom.Tests.Greed.NetFakes;

const
  NET_TABLE_MAX = 3;
  /// <summary>The tiles where the players 1 and 2 start in the fake map: north and east of player 0</summary>
  NET_START_1_X = 10;
  NET_START_1_Y = 9;
  NET_START_2_X = 14;
  NET_START_2_Y = 10;

type
  /// <summary>Some games around a net in memory: each has its own stand-ins and the same map</summary>
  TNetTable = class
  public
    Net: TFakeGreedNet;
    Count: Integer;
    Seats: array[0..NET_TABLE_MAX - 1] of TFakeGameSetup;
    Starts: array[0..NET_TABLE_MAX - 1] of IGreedNetStart;
    constructor Create(ACount: Integer);
    destructor Destroy; override;
    /// <summary>The games are made and joined to the net; each one loads the map (NewGame)</summary>
    procedure Sit;
    /// <summary>NetWaitStart on every game, a tic of the clock at a time. False if they do not start in ATics</summary>
    function WaitStart(ATics: Integer): Boolean;
    /// <summary>ATurns times: each game does two tics and a turn of its loop</summary>
    procedure Play(ATurns: Integer);
    function Link(ASeat: Integer): IGreedNetLink;
    /// <summary>A number that changes if anything of the games changes: players, clocks, sprites, messages</summary>
    function Fingerprint: Cardinal;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedNetGame = class
  private
    FTable: TNetTable;
    procedure Start(ACount: Integer);
    function NetPlayerSprites(ASeat: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure NonDovrebbeEssereInReteSenzaSessione;
    [Test]
    procedure DovrebbeRifiutareUnaSessioneNil;
    [Test]
    procedure DovrebbeMettereOgniGiocatoreSulSuoPuntoDiPartenza;
    [Test]
    procedure DovrebbePartireQuandoTuttiSiSonoTrovati;
    [Test]
    procedure DovrebbeScambiareINomiElaDifficoltaDelGiocatoreZero;
    [Test]
    procedure NonDovrebbePartireSeUnGiocatoreManca;
    [Test]
    procedure DovrebbeVedereLAltroGiocatoreDoveSiTrova;
    [Test]
    procedure DovrebbeSeguireLAltroGiocatoreCheCammina;
    [Test]
    procedure DovrebbeFerireLAltroConUnColpo;
    [Test]
    procedure DovrebbeContareLUccisioneESalutareIlMorto;
    [Test]
    procedure DovrebbeFarRinascereIlMortoInUnPuntoDiPartenza;
    [Test]
    procedure DovrebbeDareLeStesseImpronteDueVolte;
    [Test]
    procedure DovrebbeGiocareInTre;
    [Test]
    procedure DovrebbeFarSentireAgliAltriIlMessaggioScritto;
    [Test]
    procedure DovrebbeDireAgliAltriLaPausaELaRipresa;
    [Test]
    procedure DovrebbeSalutareQuandoIlGiocoFinisce;
    [Test]
    procedure DovrebbeFarComparireAgliAltriLaMinaPosata;
    [Test]
    procedure DovrebbeLasciareAlGiocatoreZeroIlBonus;
    [Test]
    procedure DovrebbeSopravvivereAiPacchettiPersi;
    [Test]
    procedure DovrebbeSopravvivereAiPacchettiFuoriOrdine;
    [Test]
    procedure NonDovrebbeFinireIlLivelloInRete;
    [Test]
    procedure DovrebbeFarComparireERaccogliereUnOggettoPerTutti;
    [Test]
    procedure DovrebbeLasciareLArmaSullaMappaPerGliAltri;
    [Test]
    procedure DovrebbeDareSoloLOggettoOttoDallaCassa;
    [Test]
    procedure DovrebbeFarRiempireLeAreeAlGiocatoreZero;
    [Test]
    procedure DovrebbeFermareLeAreeConIlJammerDiUnAltro;
    [Test]
    procedure DovrebbeMostrareGliAltriGiocatoriComeObiettivi;
    [Test]
    procedure DovrebbeDireAgliAltriLInterruttoreUsato;
    [Test]
    procedure DovrebbeAprireLaPortaAncheAgliAltri;
    [Test]
    procedure NonDovrebbeAccettareCodiciSegretiInRete;
    [Test]
    procedure DovrebbeMandareIlMessaggioScrittoAllaTastiera;
    [Test]
    procedure DovrebbeFarSentireAgliAltriLaCaduta;
    [Test]
    procedure DovrebbeScegliereGliOggettiDelleAreeDalleTabelleDiRete;
    [Test]
    procedure DovrebbeRaccogliereOgniTipoDiOggettoPerTutti;
    [Test]
    procedure DovrebbeDireAgliAltriGliInterruttoriDegliAscensori;
    [Test]
    procedure DovrebbeFarSentireAgliAltriIlGrilletto;
    [Test]
    procedure DovrebbeRaccogliereIlBonusPerTutti;
    [Test]
    procedure DovrebbeDireAgliAltriAnimeEGranata;
    [Test]
    procedure DovrebbeDireAgliAltriIColpiDiOgniArma;
    [Test]
    procedure DovrebbeSvegliareIMostriVicinoAUnGiocatoreQualsiasi;
    [Test]
    procedure NonDovrebbeFermareLOrologioPerIlMenuInRete;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Game, DelphiDoom.Greed.Net.Types,
  DelphiDoom.Greed.Net.Factory;

const
  HALF_TILE = 32 * GREED_FRACUNIT;
  NAMES: array[0..NET_TABLE_MAX - 1] of AnsiString = ('Ann', 'Bob', 'Cy');
  START_TICS = 1000;

{ TNetTable }

constructor TNetTable.Create(ACount: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  Count := ACount;
  Net := TFakeGreedNet.Create(ACount);
  for LIndex := 0 to ACount - 1 do
  begin
    Seats[LIndex] := TFakeGameSetup.Create;
    // S_NETPLAYER2 and S_NETPLAYER3: the starts of the players 1 and 2
    Seats[LIndex].Maps.Put(gpMapSprites, NET_START_1_X, NET_START_1_Y, GREED_S_NETPLAYER2);
    Seats[LIndex].Maps.Put(gpMapSprites, NET_START_2_X, NET_START_2_Y, GREED_S_NETPLAYER3);
  end;
end;

destructor TNetTable.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Count - 1 do
  begin
    Starts[LIndex] := nil;
    FreeAndNil(Seats[LIndex]);
  end;
  FreeAndNil(Net);
  inherited Destroy;
end;

procedure TNetTable.Sit;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Count - 1 do
  begin
    Seats[LIndex].CreateGame;
    Starts[LIndex] := TGreedNetFactory.Attach(Seats[LIndex].Game, Net.Endpoint(LIndex),
      TGreedNetConfig.Make(LIndex, Count, NAMES[LIndex]));
    // every player its character; the difficulty of the others is not the one of player 0
    Seats[LIndex].Game.NewGame(0, LIndex, 2 - Ord(LIndex > 0));
  end;
end;

function TNetTable.WaitStart(ATics: Integer): Boolean;
var
  LIndex, LTic, LStarted: Integer;
  LDone: array[0..NET_TABLE_MAX - 1] of Boolean;
begin
  LStarted := 0;
  for LIndex := 0 to Count - 1 do
  begin
    LDone[LIndex] := False;
    Starts[LIndex].BeginWaitStart;
  end;
  for LTic := 1 to ATics do
  begin
    for LIndex := 0 to Count - 1 do
      if not LDone[LIndex] then
      begin
        Inc(Seats[LIndex].Game.State.TimeCount);
        if Starts[LIndex].WaitStartStep then
        begin
          LDone[LIndex] := True;
          Inc(LStarted);
        end;
      end;
    if LStarted = Count then
      Exit(True);
  end;
  Result := False;
end;

procedure TNetTable.Play(ATurns: Integer);
var
  LTurn, LIndex: Integer;
begin
  for LTurn := 1 to ATurns do
    for LIndex := 0 to Count - 1 do
      Seats[LIndex].Play(1);
end;

function TNetTable.Link(ASeat: Integer): IGreedNetLink;
begin
  Result := Seats[ASeat].Game.State.Net;
end;

function TNetTable.Fingerprint: Cardinal;
var
  LSeat, LSprite, LPlayer: Integer;
  LState: TGreedGameState;
  LItem: PGreedSprite;

  procedure Mix(AValue: Integer);
  begin
    Result := (Result xor Cardinal(AValue)) * 16777619;
  end;

begin
  Result := 2166136261;
  for LSeat := 0 to Count - 1 do
  begin
    LState := Seats[LSeat].Game.State;
    Mix(LState.TimeCount);
    Mix(LState.Player.X);
    Mix(LState.Player.Y);
    Mix(LState.Player.Z);
    Mix(LState.Player.Angst);
    Mix(LState.Player.Shield);
    Mix(LState.Player.Score);
    Mix(LState.GoalItem);
    Mix(Seats[LSeat].Random.Offset);
    Mix(Seats[LSeat].View.Messages.Count);
    Mix(Seats[LSeat].Sound.Sounds.Count);
    for LPlayer := 0 to Count - 1 do
    begin
      Mix(LState.Player.Frags[LPlayer]);
      Mix(LState.Net.FragCount[LPlayer]);
      Mix(LState.Net.PlayerData[LPlayer].X);
      Mix(LState.Net.PlayerData[LPlayer].Y);
    end;
    LSprite := LState.Sprites.First;
    while LSprite <> GREED_POOL_NIL do
    begin
      LItem := PGreedSprite(LState.Sprites.Item(LSprite));
      Mix(LItem^.Kind);
      Mix(LItem^.X);
      Mix(LItem^.Y);
      Mix(LItem^.Z);
      Mix(LItem^.BasePic);
      LSprite := LState.Sprites.Next(LSprite);
    end;
  end;
end;

{ TTestGreedNetGame }

procedure TTestGreedNetGame.Setup;
begin
  FTable := nil;
end;

procedure TTestGreedNetGame.TearDown;
begin
  FreeAndNil(FTable);
end;

procedure TTestGreedNetGame.Start(ACount: Integer);
begin
  FTable := TNetTable.Create(ACount);
  FTable.Sit;
  Assert.IsTrue(FTable.WaitStart(START_TICS), 'the games start');
end;

function TTestGreedNetGame.NetPlayerSprites(ASeat: Integer): Integer;
begin
  Result := FTable.Seats[ASeat].SpritesOfKind(GREED_S_NETPLAYER);
end;

procedure TTestGreedNetGame.NonDovrebbeEssereInReteSenzaSessione;
var
  LSetup: TFakeGameSetup;
begin
  LSetup := TFakeGameSetup.Create;
  try
    LSetup.CreateGame;
    LSetup.Game.NewGame(0, 0, 2);
    LSetup.Play(5);
    Assert.IsFalse(LSetup.Game.State.NetMode);
    Assert.IsFalse(Assigned(LSetup.Game.State.Net));
    Assert.AreEqual(1, LSetup.Game.State.PlayerNum, 'playernum of a game of one player');
    Assert.AreEqual(1, LSetup.View.CountOf('MissionBriefing 0'), 'the briefing of a game of one player');
  finally
    LSetup.Free;
  end;
end;

procedure TTestGreedNetGame.DovrebbeRifiutareUnaSessioneNil;
var
  LSetup: TFakeGameSetup;
  LNet: TFakeGreedNet;
begin
  LSetup := TFakeGameSetup.Create;
  LNet := TFakeGreedNet.Create(2);
  try
    LSetup.CreateGame;
    Assert.WillRaise(
      procedure
      begin
        LSetup.Game.AttachNet(nil);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TGreedNetFactory.Attach(nil, LNet.Endpoint(0), TGreedNetConfig.Make(0, 2, 'x'));
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TGreedNetFactory.Attach(LSetup.Game, nil, TGreedNetConfig.Make(0, 2, 'x'));
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TGreedNetFactory.Attach(LSetup.Game, LNet.Endpoint(0), TGreedNetConfig.Make(2, 2, 'x'));
      end, EGreedNetException, 'player 2 of 2');
    Assert.IsFalse(LSetup.Game.State.NetMode, 'a session that was refused leaves the game as it was');
  finally
    LSetup.Free;
    LNet.Free;
  end;
end;

procedure TTestGreedNetGame.DovrebbeMettereOgniGiocatoreSulSuoPuntoDiPartenza;
var
  LState: TGreedGameState;
begin
  FTable := TNetTable.Create(3);
  FTable.Sit;
  LState := FTable.Seats[0].Game.State;
  Assert.IsTrue(LState.NetMode);
  Assert.AreEqual(0, LState.PlayerNum, 'the first player of a net game is 0');
  Assert.AreEqual(3, LState.NumPlayers);
  Assert.AreEqual(FAKE_START_X * GREED_FRACTILEUNIT + HALF_TILE, LState.Player.X);
  Assert.AreEqual(FAKE_START_Y * GREED_FRACTILEUNIT + HALF_TILE, LState.Player.Y);
  LState := FTable.Seats[1].Game.State;
  Assert.AreEqual(1, LState.PlayerNum);
  Assert.AreEqual(NET_START_1_X * GREED_FRACTILEUNIT + HALF_TILE, LState.Player.X);
  Assert.AreEqual(NET_START_1_Y * GREED_FRACTILEUNIT + HALF_TILE, LState.Player.Y);
  LState := FTable.Seats[2].Game.State;
  Assert.AreEqual(NET_START_2_X * GREED_FRACTILEUNIT + HALF_TILE, LState.Player.X);
  Assert.AreEqual(NET_START_2_Y * GREED_FRACTILEUNIT + HALF_TILE, LState.Player.Y);
  Assert.AreEqual(NET_START_2_X, LState.StartLocations[2][0], 'the start places are remembered for the respawn');
  Assert.AreEqual(0, FTable.Seats[1].View.CountOf('MissionBriefing 0'), 'no briefing in a net game');
end;

procedure TTestGreedNetGame.DovrebbePartireQuandoTuttiSiSonoTrovati;
begin
  Start(2);
  Assert.AreEqual(0, FTable.Seats[0].Game.State.TimeCount, 'the clock of the game starts when the wait ends');
  FTable.Play(1);
  Assert.AreEqual(1, NetPlayerSprites(0), 'player 0 has a sprite for player 1');
  Assert.AreEqual(1, NetPlayerSprites(1), 'player 1 has a sprite for player 0');
end;

procedure TTestGreedNetGame.DovrebbeScambiareINomiElaDifficoltaDelGiocatoreZero;
begin
  Start(3);
  Assert.AreEqual(AnsiString('Bob'), FTable.Link(0).NetName[1]);
  Assert.AreEqual(AnsiString('Cy'), FTable.Link(0).NetName[2]);
  Assert.AreEqual(AnsiString('Ann'), FTable.Link(2).NetName[0]);
  Assert.AreEqual(AnsiString('Cy'), FTable.Link(2).NetName[2]);
  Assert.AreEqual(2, FTable.Seats[1].Game.State.Player.Difficulty, 'the difficulty is the one of player 0');
  Assert.AreEqual(2, FTable.Seats[2].Game.State.Player.Difficulty);
end;

procedure TTestGreedNetGame.NonDovrebbePartireSeUnGiocatoreManca;
var
  LRaised: Boolean;
  LTic: Integer;
begin
  // a game of two with only one computer: nobody answers
  FTable := TNetTable.Create(2);
  FTable.Sit;
  FTable.Starts[0].BeginWaitStart;
  LRaised := False;
  try
    for LTic := 1 to GREED_NET_START_TIMEOUT + 2 do
    begin
      Inc(FTable.Seats[0].Game.State.TimeCount);
      if FTable.Starts[0].WaitStartStep then
        Break;
    end;
  except
    on E: EGreedNetException do
      LRaised := E.Message = SGreedNetTimeOut;
  end;
  Assert.IsTrue(LRaised, 'the time-out of ten minutes');
  Assert.IsTrue(FTable.Net.Pending(1) > 250, 'it called every two seconds');
end;

procedure TTestGreedNetGame.DovrebbeVedereLAltroGiocatoreDoveSiTrova;
var
  LOther: TGreedPlayerEvent;
  LSpot: Integer;
begin
  Start(2);
  FTable.Play(6);
  LOther := FTable.Link(0).PlayerData[1];
  Assert.AreEqual(FTable.Seats[1].Game.State.Player.X, LOther.X);
  Assert.AreEqual(FTable.Seats[1].Game.State.Player.Y, LOther.Y);
  Assert.AreEqual(1, LOther.CharType, 'the character of player 1');
  LSpot := NET_START_1_Y * GREED_MAP_SIZE + NET_START_1_X;
  Assert.AreEqual(GREED_SM_NETPLAYER, Integer(FTable.Seats[0].Game.World.GetValue(gpMapSprites, LSpot)),
    'the tile of the other player is marked for the shots');
  LOther := FTable.Link(1).PlayerData[0];
  Assert.AreEqual(FTable.Seats[0].Game.State.Player.X, LOther.X);
  Assert.AreEqual(0, LOther.CharType);
end;

procedure TTestGreedNetGame.DovrebbeSeguireLAltroGiocatoreCheCammina;
var
  LStartY: Integer;
begin
  Start(2);
  FTable.Play(4);
  LStartY := FTable.Seats[1].Game.State.Player.Y;
  FTable.Seats[1].Commands.Pressed := [gcNorth];
  FTable.Play(40);
  FTable.Seats[1].Commands.Pressed := [];
  FTable.Play(80);
  Assert.IsTrue(FTable.Seats[1].Game.State.Player.Y < LStartY - GREED_FRACTILEUNIT, 'player 1 walked north');
  Assert.AreEqual(FTable.Seats[1].Game.State.Player.Y, FTable.Link(0).PlayerData[1].Y,
    'player 0 knows where player 1 went');
  Assert.AreEqual(0, Integer(FTable.Seats[0].Game.World.GetValue(gpMapSprites,
    NET_START_1_Y * GREED_MAP_SIZE + NET_START_1_X)), 'the old tile is free again');
end;

procedure TTestGreedNetGame.DovrebbeFerireLAltroConUnColpo;
var
  LBefore, LShieldBefore: Integer;
begin
  // player 1 is on the tile north of player 0, which looks north
  Start(2);
  FTable.Play(4);
  LBefore := FTable.Seats[1].Game.State.Player.Angst;
  LShieldBefore := FTable.Seats[1].Game.State.Player.Shield;
  FTable.Seats[0].Commands.Pressed := [gcFire];
  FTable.Play(30);
  FTable.Seats[0].Commands.Pressed := [];
  FTable.Play(10);
  Assert.IsTrue((FTable.Seats[1].Game.State.Player.Angst < LBefore) or
    (FTable.Seats[1].Game.State.Player.Shield < LShieldBefore), 'the shot of player 0 hurts player 1');
  Assert.AreEqual(FTable.Seats[0].Game.State.Player.MaxAngst, FTable.Seats[0].Game.State.Player.Angst,
    'who shoots is not hurt by its own shots');
end;

procedure TTestGreedNetGame.DovrebbeContareLUccisioneESalutareIlMorto;
var
  LTurn: Integer;
begin
  Start(2);
  FTable.Play(4);
  // the second weapon shoots far: every hit pushes the other player away
  FTable.Seats[0].Commands.Pressed := [gcWeapon2];
  FTable.Play(60);
  FTable.Seats[0].Commands.Pressed := [gcFire];
  LTurn := 0;
  while (FTable.Seats[1].Game.State.Player.Angst > 0) and (LTurn < 3000) do
  begin
    // the shots must not end before the other player does
    FTable.Seats[0].Game.State.Player.Ammo[0] := 100;
    FTable.Seats[0].Game.State.Player.Ammo[1] := 100;
    FTable.Seats[0].Game.State.Player.Ammo[2] := 100;
    FTable.Play(1);
    Inc(LTurn);
  end;
  FTable.Seats[0].Commands.Pressed := [];
  Assert.AreEqual(0, FTable.Seats[1].Game.State.Player.Angst, 'player 1 dies of the shots of player 0');
  FTable.Play(3);
  Assert.AreEqual(1, FTable.Link(0).FragCount[0], 'the kill is counted where it was made');
  Assert.AreEqual(1, FTable.Link(1).FragCount[0], 'and where it was suffered');
  Assert.AreEqual(1, FTable.Seats[0].Game.State.Player.Frags[1]);
  Assert.IsTrue(FTable.Seats[0].View.Messages.IndexOf('Fragged Bob! 1 of 1') >= 0, 'the message of who killed');
  Assert.IsTrue(FTable.Seats[1].View.Messages.IndexOf('You were fragged by Ann!') >= 0, 'the message of who died');
  Assert.AreEqual(5000, FTable.Seats[0].Game.State.Player.Score, 'the score of a frag');
  Assert.AreEqual(1, FTable.Seats[0].Game.State.GoalItem, 'the goal shows the frags of player 0');
end;

procedure TTestGreedNetGame.DovrebbeFarRinascereIlMortoInUnPuntoDiPartenza;
var
  LState: TGreedGameState;
  LTileX, LTileY, LIndex: Integer;
  LAtStart: Boolean;
begin
  Start(2);
  FTable.Play(4);
  LState := FTable.Seats[1].Game.State;
  LState.Player.Angst := 0;
  LState.Net.Death(GREED_NET_NO_KILLER);
  FTable.Play(2);
  Assert.AreEqual(1, NetPlayerSprites(0), 'the sprite of the dead player stays as a corpse');
  // the restart command of a dead player: startover, that in a net game is respawnplayer
  LState.DeadRestart := True;
  FTable.Play(3);
  Assert.AreEqual(LState.Player.MaxAngst, LState.Player.Angst, 'alive again');
  Assert.AreEqual(1, FTable.Seats[1].Maps.Loads, 'the map is not loaded again');
  LTileX := LState.Player.X div GREED_FRACTILEUNIT;
  LTileY := LState.Player.Y div GREED_FRACTILEUNIT;
  LAtStart := False;
  for LIndex := 0 to GREED_MAXSTARTLOCATIONS - 1 do
    if (LState.StartLocations[LIndex][0] = LTileX) and (LState.StartLocations[LIndex][1] = LTileY) then
      LAtStart := True;
  Assert.IsTrue(LAtStart, 'at one of the start places');
  FTable.Play(3);
  Assert.AreEqual(LState.Player.X, FTable.Link(0).PlayerData[1].X, 'player 0 sees the new player');
  Assert.AreEqual(2, NetPlayerSprites(0), 'the corpse and the player that came back');
  Assert.IsTrue(FTable.Seats[0].View.Messages.IndexOf('Bob was killed.') >= 0);
end;

procedure TTestGreedNetGame.DovrebbeDareLeStesseImpronteDueVolte;
var
  LRun, LTurn: Integer;
  LPrints: array[0..1] of Cardinal;
begin
  for LRun := 0 to 1 do
  begin
    Start(2);
    for LTurn := 1 to 120 do
    begin
      // a little script: player 1 walks, player 0 shoots
      if LTurn = 10 then
        FTable.Seats[1].Commands.Pressed := [gcNorth];
      if LTurn = 30 then
        FTable.Seats[1].Commands.Pressed := [gcSouth];
      if LTurn = 40 then
        FTable.Seats[0].Commands.Pressed := [gcFire];
      if LTurn = 100 then
        FTable.Seats[0].Commands.Pressed := [];
      FTable.Play(1);
    end;
    LPrints[LRun] := FTable.Fingerprint;
    FreeAndNil(FTable);
  end;
  Assert.AreEqual(LPrints[0], LPrints[1], 'two games with the same commands are the same game');
end;

procedure TTestGreedNetGame.DovrebbeGiocareInTre;
begin
  Start(3);
  FTable.Play(8);
  Assert.AreEqual(2, NetPlayerSprites(0));
  Assert.AreEqual(2, NetPlayerSprites(1));
  Assert.AreEqual(2, NetPlayerSprites(2));
  Assert.AreEqual(FTable.Seats[2].Game.State.Player.X, FTable.Link(0).PlayerData[2].X);
  Assert.AreEqual(FTable.Seats[2].Game.State.Player.X, FTable.Link(1).PlayerData[2].X);
  Assert.AreEqual(FTable.Seats[0].Game.State.Player.Y, FTable.Link(2).PlayerData[0].Y);
end;

procedure TTestGreedNetGame.DovrebbeFarSentireAgliAltriIlMessaggioScritto;
begin
  Start(2);
  FTable.Play(2);
  FTable.Link(0).SendMessage('hello Bob');
  FTable.Play(1);
  Assert.IsTrue(FTable.Seats[1].View.Messages.IndexOf('Ann: hello Bob') >= 0);
  Assert.IsTrue(FTable.Seats[1].Sound.CountOf(GREED_SN_NEXUS) >= 1, 'a message is heard');
  Assert.AreEqual(-1, FTable.Seats[0].View.Messages.IndexOf('Ann: hello Bob'), 'who writes does not read itself');
end;

procedure TTestGreedNetGame.DovrebbeDireAgliAltriLaPausaELaRipresa;
begin
  Start(2);
  FTable.Play(2);
  FTable.Link(0).Pause;
  FTable.Seats[1].Play(1);
  Assert.IsTrue(FTable.Link(1).Paused, 'netpaused');
  Assert.IsTrue(FTable.Seats[1].View.CountOf('ShowPause') >= 1, 'the game of player 1 shows the pause');
  FTable.Link(0).UnPause;
  FTable.Seats[1].Play(1);
  Assert.IsFalse(FTable.Link(1).Paused);
  // the pause command of a player: pause and unpause go out around the pause screen
  FTable.Seats[1].Game.State.Paused := True;
  FTable.Seats[1].Play(1);
  FTable.Seats[0].Play(1);
  Assert.IsFalse(FTable.Link(0).Paused, 'the pause of player 1 has already ended');
end;

procedure TTestGreedNetGame.DovrebbeSalutareQuandoIlGiocoFinisce;
begin
  Start(2);
  FTable.Play(2);
  FTable.Seats[1].Game.State.QuitGame := True;
  FTable.Seats[1].Play(1);
  FTable.Seats[1].Play(1);
  FTable.Seats[0].Play(1);
  Assert.IsTrue(FTable.Seats[0].View.Messages.IndexOf('Bob has left the game!') >= 0);
  Assert.IsTrue(FTable.Seats[0].View.Messages.IndexOf('Bob was killed.') >= 0, 'who leaves dies first');
  Assert.AreEqual(0, FTable.Net.Pending(0), 'the goodbye is said once');
end;

procedure TTestGreedNetGame.DovrebbeFarComparireAgliAltriLaMinaPosata;
begin
  Start(2);
  FTable.Play(2);
  Assert.AreEqual(0, FTable.Seats[1].SpritesOfKind(GREED_S_PROXMINE));
  // the inventory of a new player has proximity mines: the use item command drops one
  FTable.Seats[0].Game.Inventory.Cursor := 4;
  FTable.Seats[0].Commands.Pressed := [gcUseItem];
  FTable.Play(3);
  FTable.Seats[0].Commands.Pressed := [];
  FTable.Play(1);
  Assert.IsTrue(FTable.Seats[0].SpritesOfKind(GREED_S_PROXMINE) >= 1, 'the mine of player 0');
  Assert.AreEqual(FTable.Seats[0].SpritesOfKind(GREED_S_PROXMINE), FTable.Seats[1].SpritesOfKind(GREED_S_PROXMINE),
    'player 1 has the same mines');
end;

procedure TTestGreedNetGame.DovrebbeLasciareAlGiocatoreZeroIlBonus;
var
  LHost, LGuest: TGreedGameState;
begin
  Start(2);
  LHost := FTable.Seats[0].Game.State;
  LGuest := FTable.Seats[1].Game.State;
  // the time of the bonus item has come for both
  LHost.BonusItem.Time := 0;
  LGuest.BonusItem.Time := 0;
  FTable.Play(2);
  Assert.IsTrue(LHost.BonusItem.Score > 0, 'player 0 places the bonus item');
  Assert.AreEqual(LHost.BonusItem.Score, LGuest.BonusItem.Score, 'player 1 gets it from player 0');
  Assert.AreEqual(LHost.BonusItem.TileX, LGuest.BonusItem.TileX);
  Assert.AreEqual(LHost.BonusItem.TileY, LGuest.BonusItem.TileY);
  Assert.AreEqual(LHost.BonusItem.Name, LGuest.BonusItem.Name);
  Assert.AreEqual(1, FTable.Seats[1].SpritesOfKind(GREED_S_BONUSITEM));
  Assert.IsTrue(FTable.Seats[1].View.Messages.IndexOf('Bonus item located!') >= 0);
end;

procedure TTestGreedNetGame.DovrebbeSopravvivereAiPacchettiPersi;
var
  LLost: Integer;
begin
  Start(2);
  FTable.Play(4);
  // nothing is sent again: what is lost is lost, and the next packet of the player says where it is
  FTable.Seats[1].Commands.Pressed := [gcNorth];
  FTable.Net.LoseNext(15);
  FTable.Play(30);
  LLost := FTable.Net.Lost;
  Assert.AreEqual(15, LLost);
  FTable.Seats[1].Commands.Pressed := [];
  FTable.Play(80);
  Assert.AreEqual(FTable.Seats[1].Game.State.Player.Y, FTable.Link(0).PlayerData[1].Y,
    'after the loss the position is the one of the last packet');
  Assert.IsTrue(FTable.Seats[1].Game.State.Player.Y < NET_START_1_Y * GREED_FRACTILEUNIT, 'player 1 walked');
  Assert.IsFalse(FTable.Seats[0].Game.QuitGame);
end;

procedure TTestGreedNetGame.DovrebbeSopravvivereAiPacchettiFuoriOrdine;
begin
  Start(2);
  FTable.Play(4);
  FTable.Seats[1].Commands.Pressed := [gcNorth];
  FTable.Net.HoldBack := True;
  FTable.Play(20);
  // the packets of twenty turns arrive all together, the last one first
  FTable.Net.HoldBack := False;
  FTable.Net.Release(True);
  FTable.Seats[1].Commands.Pressed := [];
  FTable.Play(80);
  Assert.AreEqual(FTable.Seats[1].Game.State.Player.Y, FTable.Link(0).PlayerData[1].Y,
    'the packets that follow put things right');
  Assert.IsTrue(FTable.Seats[1].Game.State.Player.Y < NET_START_1_Y * GREED_FRACTILEUNIT, 'player 1 walked');
  Assert.AreEqual(1, NetPlayerSprites(0));
end;

procedure TTestGreedNetGame.NonDovrebbeFinireIlLivelloInRete;
var
  LState: TGreedGameState;
begin
  Start(2);
  LState := FTable.Seats[0].Game.State;
  // in a game of one player a level without goals makes its exit at once
  LState.Player.LevelScore := 0;
  FTable.Play(3);
  Assert.IsFalse(LState.ExitExists, 'no exit in a net game');
  Assert.AreEqual(0, FTable.Seats[0].SpritesOfKind(GREED_S_EXIT));
end;

procedure TTestGreedNetGame.DovrebbeFarComparireERaccogliereUnOggettoPerTutti;
const
  ITEM_X = 20;
  ITEM_Y = 20;
var
  LSpot: Integer;
  LTaker, LOther: TGreedGameState;
begin
  Start(2);
  FTable.Play(2);
  LSpot := ITEM_Y * GREED_MAP_SIZE + ITEM_X;
  // a medical tube made in the game of player 0 (a spawn area, a monster that dies) is told to the others
  FTable.Seats[0].Game.Parts.SpawnerIntf.SpawnSprite(GREED_S_MEDPAK1, ITEM_X * GREED_FRACTILEUNIT + HALF_TILE,
    ITEM_Y * GREED_FRACTILEUNIT + HALF_TILE, 0, 0, 0, 0, False, 0);
  FTable.Play(1);
  Assert.AreEqual(1, FTable.Seats[1].SpritesOfKind(GREED_S_MEDPAK1), 'player 1 has the item too');
  Assert.AreEqual(GREED_SM_MEDPAK1, Integer(FTable.Seats[1].Game.World.GetValue(gpMapSprites, LSpot)));
  // player 1, hurt, picks it up
  LTaker := FTable.Seats[1].Game.State;
  LOther := FTable.Seats[0].Game.State;
  LTaker.Player.Angst := 100;
  FTable.Seats[1].Game.Parts.Items.CheckItems(ITEM_X, ITEM_Y, True, LTaker.Player.CharType);
  Assert.IsTrue(LTaker.Player.Angst > 100, 'who takes it is healed');
  FTable.Play(1);
  Assert.AreEqual(0, FTable.Seats[0].SpritesOfKind(GREED_S_MEDPAK1), 'the item is gone for player 0 too');
  Assert.AreEqual(0, Integer(FTable.Seats[0].Game.World.GetValue(gpMapSprites, LSpot)));
  Assert.AreEqual(LOther.Player.MaxAngst, LOther.Player.Angst, 'and player 0 gets nothing from it');
  Assert.IsTrue(FTable.Seats[0].Sound.CountOf(GREED_SN_PICKUP0 + LTaker.Player.CharType) >= 1,
    'player 0 hears the pickup of the character of player 1');
end;

procedure TTestGreedNetGame.DovrebbeLasciareLArmaSullaMappaPerGliAltri;
const
  ITEM_X = 20;
  ITEM_Y = 20;
  WEAPON = 2;
var
  LState: TGreedGameState;
  LSlot, LMessages: Integer;
begin
  Start(2);
  FTable.Play(2);
  LState := FTable.Seats[0].Game.State;
  FTable.Seats[0].Game.Parts.SpawnerIntf.SpawnSprite(GREED_S_WEAPON0 + WEAPON,
    ITEM_X * GREED_FRACTILEUNIT + HALF_TILE, ITEM_Y * GREED_FRACTILEUNIT + HALF_TILE, 0, 0, 0, 0, False, 0);
  LSlot := LState.Weapons[WEAPON].AmmoType + 2;
  Assert.AreEqual(-1, LState.Player.Weapons[LSlot]);
  FTable.Seats[0].Game.Parts.Items.CheckItems(ITEM_X, ITEM_Y, True, 0);
  Assert.AreEqual(WEAPON, LState.Player.Weapons[LSlot], 'the weapon is taken');
  Assert.AreEqual(1, FTable.Seats[0].SpritesOfKind(GREED_S_WEAPON0 + WEAPON), 'and stays on the map');
  Assert.IsTrue(FTable.Seats[0].View.Messages.IndexOf('Acquired new weapon!') >= 0);
  FTable.Play(1);
  Assert.IsTrue(FTable.Seats[1].Sound.CountOf(GREED_SN_WEAPPICKUP0) >= 1, 'the others hear it');
  // who has it already takes nothing more
  LMessages := FTable.Seats[0].View.Messages.Count;
  FTable.Seats[0].Game.Parts.Items.CheckItems(ITEM_X, ITEM_Y, True, 0);
  Assert.AreEqual(LMessages, FTable.Seats[0].View.Messages.Count);
end;

procedure TTestGreedNetGame.DovrebbeDareSoloLOggettoOttoDallaCassa;
const
  ITEM_X = 22;
  ITEM_Y = 20;
var
  LState: TGreedGameState;
  LBefore: Integer;
begin
  Start(2);
  FTable.Play(2);
  LState := FTable.Seats[0].Game.State;
  FTable.Seats[0].Game.Parts.SpawnerIntf.SpawnSprite(GREED_S_GOODIEBOX, ITEM_X * GREED_FRACTILEUNIT + HALF_TILE,
    ITEM_Y * GREED_FRACTILEUNIT + HALF_TILE, 0, 0, 0, 0, False, 0);
  LBefore := LState.Player.Inventory[10];
  FTable.Seats[0].Game.Parts.Items.CheckItems(ITEM_X, ITEM_Y, True, 0);
  Assert.IsTrue(LState.Player.Inventory[10] > LBefore, 'the item 8 of the table (the slot 10 of the inventory)');
  Assert.AreEqual(0, FTable.Seats[0].SpritesOfKind(GREED_S_GOODIEBOX));
end;

procedure TTestGreedNetGame.DovrebbeFarRiempireLeAreeAlGiocatoreZero;
var
  LSeat, LIndex, LKind: Integer;
  LArea: TGreedSpawnArea;
  LCounts: array[0..1] of Integer;
  LSprite: Integer;
  LState: TGreedGameState;
begin
  Start(2);
  FTable.Play(2);
  // the same three areas in both games: ammunition, health, the first monster
  for LSeat := 0 to 1 do
    for LIndex := 0 to 2 do
    begin
      LArea := Default(TGreedSpawnArea);
      LArea.MapSpot := 30 * GREED_MAP_SIZE + 30 + LIndex * 3;
      LArea.MapX := (30 + LIndex * 3) * GREED_FRACTILEUNIT + HALF_TILE;
      LArea.MapY := 30 * GREED_FRACTILEUNIT + HALF_TILE;
      if LIndex = 2 then
        LArea.Kind := 10
      else
        LArea.Kind := LIndex;
      FTable.Seats[LSeat].Game.World.SetSpawnArea(FTable.Seats[LSeat].Game.World.AddSpawnArea, LArea);
    end;
  FTable.Play(1);
  Assert.AreEqual(1, FTable.Seats[0].SpritesOfKind(GREED_S_MONSTER1), 'player 0 makes the monster');
  Assert.AreEqual(1, FTable.Seats[1].SpritesOfKind(GREED_S_MONSTER1), 'player 1 has it from player 0, once');
  for LSeat := 0 to 1 do
  begin
    LCounts[LSeat] := 0;
    LState := FTable.Seats[LSeat].Game.State;
    LSprite := LState.Sprites.First;
    while LSprite <> GREED_POOL_NIL do
    begin
      LKind := PGreedSprite(LState.Sprites.Item(LSprite))^.Kind;
      if (LKind >= GREED_S_MEDPAK1) and (LKind <= GREED_S_ISTEALER) then
        Inc(LCounts[LSeat]);
      LSprite := LState.Sprites.Next(LSprite);
    end;
  end;
  Assert.AreEqual(2, LCounts[0], 'the two items of the areas of player 0');
  Assert.AreEqual(2, LCounts[1], 'the same two for player 1');
  // an area that was filled waits (in a net game (9 - players) * 437 tics, then 7000 more at every look)
  LArea := FTable.Seats[0].Game.World.GetSpawnArea(0);
  Assert.IsTrue(LArea.Time > 7 * 437, 'the area waits');
end;

procedure TTestGreedNetGame.DovrebbeFermareLeAreeConIlJammerDiUnAltro;
var
  LArea: TGreedSpawnArea;
begin
  Start(2);
  FTable.Play(2);
  // the warp jammer of player 1 (the game of xGreed never sends it: the packet is made here)
  FTable.Net.Inject(1, 0, TBytes.Create(GREED_NET_EVENT_JAMMER, 0, 0, 0, 1, 0, 0, 0));
  FTable.Seats[0].Play(1);
  Assert.IsTrue(FTable.Link(0).WarpJammer);
  LArea := Default(TGreedSpawnArea);
  LArea.MapSpot := 30 * GREED_MAP_SIZE + 30;
  LArea.MapX := 30 * GREED_FRACTILEUNIT + HALF_TILE;
  LArea.MapY := 30 * GREED_FRACTILEUNIT + HALF_TILE;
  LArea.Kind := 10;
  FTable.Seats[0].Game.World.SetSpawnArea(FTable.Seats[0].Game.World.AddSpawnArea, LArea);
  FTable.Seats[0].Play(3);
  Assert.AreEqual(0, FTable.Seats[0].SpritesOfKind(GREED_S_MONSTER1), 'no monsters while the warps are jammed');
  // a minute later the areas work again
  FTable.Seats[0].Game.State.TimeCount := FTable.Link(0).WarpJamTime + 1;
  FTable.Seats[0].Play(1);
  Assert.AreEqual(1, FTable.Seats[0].SpritesOfKind(GREED_S_MONSTER1));
end;

procedure TTestGreedNetGame.DovrebbeMostrareGliAltriGiocatoriComeObiettivi;
var
  LState: TGreedGameState;
begin
  Start(3);
  FTable.Play(1);
  LState := FTable.Seats[0].Game.State;
  // no bonus item yet: the goals are the three players, 1 .. 3
  Assert.AreEqual(1, LState.GoalItem, 'the first goal after the map is loaded');
  LState.ToggleGoalItem := True;
  FTable.Seats[0].Play(1);
  Assert.AreEqual(2, LState.GoalItem);
  LState.ToggleGoalItem := True;
  FTable.Seats[0].Play(1);
  Assert.AreEqual(3, LState.GoalItem);
  LState.ToggleGoalItem := True;
  FTable.Seats[0].Play(1);
  Assert.AreEqual(1, LState.GoalItem, 'after the last player the first again');
  // with a bonus item the goal 0 is the bonus item
  LState.BonusItem.Score := 2000;
  LState.GoalItem := 3;
  LState.ToggleGoalItem := True;
  FTable.Seats[0].Play(1);
  Assert.AreEqual(0, LState.GoalItem);
end;

procedure TTestGreedNetGame.DovrebbeDireAgliAltriLInterruttoreUsato;
const
  ELEVATOR_SPOT = 20 * GREED_MAP_SIZE + 20;
  TRIGGER_X = 21;
  TRIGGER_Y = 20;
var
  LSeat, LIndex: Integer;
  LElevators: array[0..1] of Integer;
  LItem: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  Start(2);
  FTable.Play(2);
  // a secret elevator and its trigger on the tile next to it, in both games
  for LSeat := 0 to 1 do
  begin
    LIndex := FTable.Seats[LSeat].Game.State.Elevators.Add;
    LElevators[LSeat] := LIndex;
    LItem := FTable.Seats[LSeat].Game.State.Elevators.Item(LIndex);
    LItem^.Kind := getSecret;
    LItem^.MapSpot := ELEVATOR_SPOT;
    FTable.Seats[LSeat].Game.World.SetValue(gpMapSprites, TRIGGER_Y * GREED_MAP_SIZE + TRIGGER_X,
      GREED_SM_STRIGGER);
  end;
  // player 1 uses the trigger
  FTable.Seats[1].Game.Parts.Switches.CheckHere(True, TRIGGER_X * GREED_FRACTILEUNIT + HALF_TILE,
    TRIGGER_Y * GREED_FRACTILEUNIT + HALF_TILE, 0);
  Assert.IsTrue(FTable.Seats[1].Game.State.Elevators.Item(LElevators[1])^.Down, 'the elevator of player 1 starts');
  Assert.IsFalse(FTable.Seats[0].Game.State.Elevators.Item(LElevators[0])^.Down);
  FTable.Link(0).GetData;
  Assert.IsTrue(FTable.Seats[0].Game.State.Elevators.Item(LElevators[0])^.Down, 'and the one of player 0 with it');
  Assert.AreEqual(0, FTable.Net.Pending(1), 'who hears of a switch does not tell it again');
end;

procedure TTestGreedNetGame.DovrebbeAprireLaPortaAncheAgliAltri;
const
  DOOR_X = 10;
  DOOR_Y = 6;
var
  LSeat, LTurn: Integer;
  LDoor: TGreedDoor;
begin
  FTable := TNetTable.Create(2);
  // a door north of player 1 (the value 60 of mapsprites, or the 61 for the other orientation)
  for LSeat := 0 to 1 do
  begin
    FTable.Seats[LSeat].Maps.Put(gpMapSprites, DOOR_X, DOOR_Y, 60);
    FTable.Seats[LSeat].Maps.Put(gpMapSprites, DOOR_X, DOOR_Y - 1, 61);
  end;
  FTable.Sit;
  Assert.IsTrue(FTable.WaitStart(START_TICS));
  Assert.IsTrue(FTable.Seats[0].Game.World.DoorCount >= 1, 'the map has its doors');
  FTable.Seats[1].Commands.Pressed := [gcNorth];
  LTurn := 0;
  repeat
    FTable.Play(1);
    Inc(LTurn);
    LDoor := FTable.Seats[1].Game.World.GetDoor(0);
  until LDoor.Opening or LDoor.Open or (LTurn > 400);
  Assert.IsTrue(LDoor.Opening or LDoor.Open, 'player 1 walks into the door and it opens');
  FTable.Play(1);
  LDoor := FTable.Seats[0].Game.World.GetDoor(0);
  Assert.IsTrue(LDoor.Opening or LDoor.Open, 'the same door opens in the game of player 0');
end;

procedure TTestGreedNetGame.NonDovrebbeAccettareCodiciSegretiInRete;
var
  LState: TGreedGameState;
begin
  Start(2);
  LState := FTable.Seats[0].Game.State;
  LState.SecretBuf := 'god';
  FTable.Seats[0].Play(1);
  Assert.IsFalse(LState.GodMode);
  Assert.AreEqual('', LState.SecretBuf);
end;

procedure TTestGreedNetGame.DovrebbeMandareIlMessaggioScrittoAllaTastiera;
var
  LIndex: Integer;
  LFound: Boolean;
begin
  Start(2);
  FTable.Play(15);
  // the key of the message, then the text and Enter
  FTable.Seats[0].Commands.Pressed := [gcNetMessage];
  FTable.Play(2);
  FTable.Seats[0].Commands.Pressed := [];
  FTable.Seats[0].Commands.Typed := 'hi'#13;
  FTable.Play(10);
  LFound := False;
  for LIndex := 0 to FTable.Seats[1].View.Messages.Count - 1 do
    if FTable.Seats[1].View.Messages[LIndex].StartsWith('Ann: hi') then
      LFound := True;
  Assert.IsTrue(LFound, 'player 1 reads what player 0 typed');
end;

procedure TTestGreedNetGame.DovrebbeFarSentireAgliAltriLaCaduta;
begin
  Start(2);
  FTable.Play(2);
  FTable.Seats[0].Game.State.FallDamage := 1;
  FTable.Play(1);
  // the character of player 0 grunts in the game of player 1
  Assert.IsTrue(FTable.Seats[1].Sound.CountOf(GREED_SN_HIT0) >= 1);
end;

type
  TAreaLimit = record
    Below: Integer;
    Kind: Integer;
  end;

const
  // the lists of CheckSpawnAreas for a net game, from raven.pas: a number below the limit gives the kind
  NET_AMMO: array[0..11] of TAreaLimit = (
    (Below: 30; Kind: GREED_S_ENERGY), (Below: 60; Kind: GREED_S_BALLISTIC), (Below: 90; Kind: GREED_S_PLASMA),
    (Below: 98; Kind: GREED_S_IGRENADE), (Below: 102; Kind: GREED_S_IREVERSO), (Below: 112; Kind: GREED_S_IPROXMINE),
    (Below: 116; Kind: GREED_S_ITIMEMINE), (Below: 120; Kind: GREED_S_IDECOY),
    (Below: 134; Kind: GREED_S_IINSTAWALL), (Below: 138; Kind: GREED_S_IINVIS), (Below: 142; Kind: GREED_S_ISTEALER),
    (Below: MaxInt; Kind: GREED_S_IHOLO));
  NET_HEALTH: array[0..16] of TAreaLimit = (
    (Below: 15; Kind: GREED_S_MEDPAK1), (Below: 22; Kind: GREED_S_MEDPAK2), (Below: 30; Kind: GREED_S_MEDPAK3),
    (Below: 45; Kind: GREED_S_MEDPAK4), (Below: 60; Kind: GREED_S_SHIELD4), (Below: 67; Kind: GREED_S_SHIELD3),
    (Below: 75; Kind: GREED_S_SHIELD2), (Below: 90; Kind: GREED_S_SHIELD1), (Below: 96; Kind: GREED_S_IGRENADE),
    (Below: 98; Kind: GREED_S_IREVERSO), (Below: 102; Kind: GREED_S_IPROXMINE), (Below: 106; Kind: GREED_S_ITIMEMINE),
    (Below: 108; Kind: GREED_S_IDECOY), (Below: 110; Kind: GREED_S_IINSTAWALL), (Below: 112; Kind: GREED_S_IJAMMER),
    (Below: 114; Kind: GREED_S_ISTEALER), (Below: MaxInt; Kind: GREED_S_IHOLO));
  // the demo: after the ammunition (or the health) the same six for both kinds of area
  NET_DEMO_TAIL: array[0..5] of TAreaLimit = (
    (Below: 96; Kind: GREED_S_IGRENADE), (Below: 98; Kind: GREED_S_IREVERSO), (Below: 102; Kind: GREED_S_IPROXMINE),
    (Below: 106; Kind: GREED_S_ITIMEMINE), (Below: 108; Kind: GREED_S_IDECOY),
    (Below: MaxInt; Kind: GREED_S_IINSTAWALL));

function ExpectedAreaKind(ADemo: Boolean; AArea, ANumber: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  if ADemo and (ANumber >= 90) then
  begin
    for LIndex := Low(NET_DEMO_TAIL) to High(NET_DEMO_TAIL) do
      if ANumber < NET_DEMO_TAIL[LIndex].Below then
        Exit(NET_DEMO_TAIL[LIndex].Kind);
  end
  else if AArea = 0 then
  begin
    for LIndex := Low(NET_AMMO) to High(NET_AMMO) do
      if ANumber < NET_AMMO[LIndex].Below then
        Exit(NET_AMMO[LIndex].Kind);
  end
  else
    for LIndex := Low(NET_HEALTH) to High(NET_HEALTH) do
      if ANumber < NET_HEALTH[LIndex].Below then
        Exit(NET_HEALTH[LIndex].Kind);
end;

procedure TTestGreedNetGame.DovrebbeScegliereGliOggettiDelleAreeDalleTabelleDiRete;
const
  AREA_SPOT = 30 * GREED_MAP_SIZE + 30;
var
  LSeat: TFakeGameSetup;
  LState: TGreedGameState;
  LArea: TGreedSpawnArea;
  LAreaIndex, LAreaKind, LClock, LRandom, LModulus, LNumber, LSprite, LNext, LFound, LChecked: Integer;
  LDemo: Boolean;
  LItem: PGreedSprite;
begin
  Start(2);
  LSeat := FTable.Seats[0];
  LState := LSeat.Game.State;
  LAreaIndex := LSeat.Game.World.AddSpawnArea;
  LChecked := 0;
  for LDemo := False to True do
    for LAreaKind := 0 to 1 do
      for LClock := 0 to 149 do
      begin
        LState.Demo := LDemo;
        LSeat.Clock.Value := Cardinal(LClock);
        // the number of the area is (clock + the next random number) mod the length of its list
        LSeat.Random.Offset := 0;
        LRandom := LSeat.Random.Next;
        LSeat.Random.Offset := 0;
        if LDemo then
          LModulus := 110
        else if LAreaKind = 0 then
          LModulus := 146
        else
          LModulus := 116;
        LNumber := (LClock + LRandom) mod LModulus;
        LArea := Default(TGreedSpawnArea);
        LArea.MapSpot := AREA_SPOT;
        LArea.MapX := 30 * GREED_FRACTILEUNIT + HALF_TILE;
        LArea.MapY := 30 * GREED_FRACTILEUNIT + HALF_TILE;
        LArea.Kind := LAreaKind;
        LSeat.Game.World.SetSpawnArea(LAreaIndex, LArea);
        LState.TimeCount := 10;
        LSeat.Game.Parts.Level.CheckSpawnAreas;
        // what the area made: the item and the warp that brings it; both are taken away for the next turn
        LFound := 0;
        LSprite := LState.Sprites.First;
        while LSprite <> GREED_POOL_NIL do
        begin
          LNext := LState.Sprites.Next(LSprite);
          LItem := PGreedSprite(LState.Sprites.Item(LSprite));
          if (LItem^.Kind >= GREED_S_MEDPAK1) and (LItem^.Kind <= GREED_S_ISTEALER) then
          begin
            LFound := LItem^.Kind;
            LState.Sprites.Remove(LSprite);
          end
          else if LItem^.Kind = GREED_S_WARP then
            LState.Sprites.Remove(LSprite);
          LSprite := LNext;
        end;
        LSeat.Game.World.SetValue(gpMapSprites, AREA_SPOT, 0);
        if LFound <> ExpectedAreaKind(LDemo, LAreaKind, LNumber) then
          Assert.Fail(Format('demo %s, area %d, number %d: the item %d, the list of the original says %d',
            [BoolToStr(LDemo, True), LAreaKind, LNumber, LFound, ExpectedAreaKind(LDemo, LAreaKind, LNumber)]));
        Inc(LChecked);
      end;
  Assert.AreEqual(600, LChecked);
end;

procedure TTestGreedNetGame.DovrebbeRaccogliereOgniTipoDiOggettoPerTutti;
const
  KINDS: array[0..4] of Integer = (GREED_S_SHIELD1, GREED_S_ENERGY, GREED_S_IGRENADE, GREED_S_AMMOBOX,
    GREED_S_MEDBOX);
var
  LIndex, LSeat, LX, LY, LKind: Integer;
  LTaker: TGreedGameState;
begin
  Start(2);
  FTable.Play(2);
  LTaker := FTable.Seats[1].Game.State;
  for LIndex := Low(KINDS) to High(KINDS) do
  begin
    LKind := KINDS[LIndex];
    LX := 20 + LIndex * 2;
    LY := 22;
    if (LKind = GREED_S_AMMOBOX) or (LKind = GREED_S_MEDBOX) then
    begin
      // the boxes of the map are not told: each game has its own
      for LSeat := 0 to 1 do
        FTable.Seats[LSeat].Game.Parts.SpawnerIntf.SpawnSprite(LKind, LX * GREED_FRACTILEUNIT + HALF_TILE,
          LY * GREED_FRACTILEUNIT + HALF_TILE, 0, 0, 0, 0, False, 0);
    end
    else
    begin
      FTable.Seats[0].Game.Parts.SpawnerIntf.SpawnSprite(LKind, LX * GREED_FRACTILEUNIT + HALF_TILE,
        LY * GREED_FRACTILEUNIT + HALF_TILE, 0, 0, 0, 0, False, 0);
      FTable.Link(1).GetData;
    end;
    Assert.AreEqual(1, FTable.Seats[1].SpritesOfKind(LKind), Format('the item %d is in the game of player 1', [LKind]));
    // player 1 needs everything
    LTaker.Player.Angst := 100;
    LTaker.Player.Shield := 0;
    LTaker.Player.Ammo[0] := 0;
    LTaker.Player.Ammo[1] := 0;
    LTaker.Player.Ammo[2] := 0;
    FTable.Seats[1].Game.Parts.Items.CheckItems(LX, LY, True, LTaker.Player.CharType);
    Assert.AreEqual(0, FTable.Seats[1].SpritesOfKind(LKind), Format('player 1 takes the item %d', [LKind]));
    FTable.Link(0).GetData;
    Assert.AreEqual(0, FTable.Seats[0].SpritesOfKind(LKind), Format('the item %d is gone for player 0 too', [LKind]));
    Assert.AreEqual(0, Integer(FTable.Seats[0].Game.World.GetValue(gpMapSprites, LY * GREED_MAP_SIZE + LX)));
  end;
  Assert.AreEqual(0, FTable.Seats[0].Game.State.Player.Inventory[2] - 4, 'player 0 got no grenades from it');
end;

procedure TTestGreedNetGame.DovrebbeDireAgliAltriGliInterruttoriDegliAscensori;
const
  SWITCH_X = 26;
  SWITCH_Y = 25;
var
  LSeat, LPass, LSounds: Integer;
  LElevators: array[0..1] of Integer;
  LItem: TGreedLinkedPool<TGreedElevator>.PItem;
begin
  Start(2);
  FTable.Play(2);
  for LPass := 0 to 1 do
  begin
    for LSeat := 0 to 1 do
    begin
      LElevators[LSeat] := FTable.Seats[LSeat].Game.State.Elevators.Add;
      LItem := FTable.Seats[LSeat].Game.State.Elevators.Item(LElevators[LSeat]);
      LItem^.MapSpot := 25 * GREED_MAP_SIZE + 25;
      if LPass = 0 then
      begin
        LItem^.Kind := getSwitchDown;
        FTable.Seats[LSeat].Game.World.SetValue(gpMapSprites, SWITCH_Y * GREED_MAP_SIZE + SWITCH_X,
          GREED_SM_SWITCHDOWN);
      end
      else
      begin
        LItem^.Kind := getSwitchUp;
        FTable.Seats[LSeat].Game.World.SetValue(gpMapSprites, SWITCH_Y * GREED_MAP_SIZE + SWITCH_X,
          GREED_SM_SWITCHUP);
      end;
    end;
    LSounds := FTable.Seats[0].Sound.CountOf(GREED_SN_TRIGGER);
    // player 1 steps on the switch
    FTable.Seats[1].Game.Parts.Items.CheckItems(SWITCH_X, SWITCH_Y, True, 1);
    FTable.Link(0).GetData;
    LItem := FTable.Seats[0].Game.State.Elevators.Item(LElevators[0]);
    if LPass = 0 then
    begin
      Assert.IsTrue(LItem^.Down, 'the elevator of player 0 goes down with the one of player 1');
      Assert.IsTrue(FTable.Seats[0].Sound.CountOf(GREED_SN_TRIGGER) >= LSounds + 2,
        'the click of the first kind of switch is told twice');
    end
    else
      Assert.IsTrue(LItem^.Up, 'the elevator of player 0 goes up with the one of player 1');
    Assert.AreEqual(0, Integer(FTable.Seats[0].Game.World.GetValue(gpMapSprites,
      SWITCH_Y * GREED_MAP_SIZE + SWITCH_X)), 'the switch is used up for player 0 too');
  end;
end;

procedure TTestGreedNetGame.DovrebbeFarSentireAgliAltriIlGrilletto;
const
  TRIGGER_X = 33;
  TRIGGER_Y = 34;
begin
  Start(2);
  FTable.Play(2);
  // triggers[x][y] of the script: an event that nothing answers
  FTable.Seats[1].Game.State.Triggers[TRIGGER_X * GREED_MAP_SIZE + TRIGGER_Y] := 5;
  FTable.Seats[1].Game.Parts.Items.CheckWarps(TRIGGER_X * GREED_FRACTILEUNIT + HALF_TILE,
    TRIGGER_Y * GREED_FRACTILEUNIT + HALF_TILE);
  Assert.AreEqual(2, FTable.Seats[1].Sound.CountOf(GREED_SN_TRIGGER));
  FTable.Link(0).GetData;
  Assert.AreEqual(2, FTable.Seats[0].Sound.CountOf(GREED_SN_TRIGGER), 'player 0 hears the two clicks');
end;

procedure TTestGreedNetGame.DovrebbeRaccogliereIlBonusPerTutti;
var
  LHost, LGuest: TGreedGameState;
  LScore: Integer;
begin
  Start(2);
  LHost := FTable.Seats[0].Game.State;
  LGuest := FTable.Seats[1].Game.State;
  LHost.BonusItem.Time := 0;
  FTable.Play(2);
  LScore := LGuest.BonusItem.Score;
  Assert.IsTrue(LScore > 0);
  // player 1 walks on the bonus item
  FTable.Seats[1].Game.Parts.Items.CheckItems(LGuest.BonusItem.TileX, LGuest.BonusItem.TileY, True, 1);
  Assert.AreEqual(LScore, LGuest.Player.Score, 'the score of the bonus item');
  Assert.AreEqual(0, LGuest.BonusItem.Score);
  FTable.Link(0).GetData;
  Assert.AreEqual(0, LHost.BonusItem.Score, 'the bonus item is gone for player 0 too');
  Assert.AreEqual(0, FTable.Seats[0].SpritesOfKind(GREED_S_BONUSITEM));
  Assert.AreEqual(0, LHost.Player.Score, 'and player 0 gets nothing from it');
end;

procedure TTestGreedNetGame.DovrebbeDireAgliAltriAnimeEGranata;
var
  LState: TGreedGameState;
begin
  Start(2);
  FTable.Play(2);
  LState := FTable.Seats[0].Game.State;
  // the soul stealer: sixteen shots around the player, told with one packet
  FTable.Seats[0].Game.Inventory.Cursor := 12;
  LState.Player.Inventory[12] := 1;
  LState.UseItem := True;
  FTable.Seats[0].Play(1);
  Assert.AreEqual(0, LState.Player.Inventory[12]);
  FTable.Link(1).GetData;
  Assert.AreEqual(16, FTable.Seats[1].SpritesOfKind(GREED_S_SOULBULLET), 'the ring of the soul stealer');
  Assert.AreEqual(2, FTable.Seats[1].Sound.CountOf(GREED_SN_SOULSTEALER), 'heard twice, as who used it');
  // the grenade
  FTable.Seats[0].Game.Inventory.Cursor := 2;
  LState.UseItem := True;
  FTable.Seats[0].Play(2);
  FTable.Link(1).GetData;
  Assert.IsTrue(FTable.Seats[1].Sound.CountOf(GREED_SN_GRENADE) >= 1, 'the throw of the grenade is heard');
  Assert.IsTrue(FTable.Seats[1].SpritesOfKind(GREED_S_GRENADE) + FTable.Seats[1].SpritesOfKind(GREED_S_GRENADEBULLET) +
    FTable.Seats[1].SpritesOfKind(GREED_S_EXPLODE) >= 1, 'the grenade flies in the game of player 1');
end;

procedure TTestGreedNetGame.DovrebbeDireAgliAltriIColpiDiOgniArma;
const
  SPAWN_VALUE_OFFSET = 8;
  SOUND_EFFECT_OFFSET = 16;
  // weapon, the shot, how many are told, the sound that the others hear
  CASES: array[0..4, 0..3] of Integer = (
    (4, GREED_S_BULLET4, 5, GREED_SN_BULLET4),
    (9, GREED_S_BULLET9, 1, GREED_SN_BULLET1),
    (12, GREED_S_BULLET12, 2, GREED_SN_BULLET12),
    (17, GREED_S_BULLET17, 1, GREED_SN_BULLET1),
    (18, GREED_S_BULLET18, 1, GREED_SN_BULLET18));
var
  LState: TGreedGameState;
  LCase, LWeapon, LIndex, LSpawns, LSounds, LTurn: Integer;
  LSent: TArray<TBytes>;

  function NumberAt(const ABytes: TBytes; AOffset: Integer): Integer;
  begin
    Result := Integer(Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8) or
      (Cardinal(ABytes[AOffset + 2]) shl 16) or (Cardinal(ABytes[AOffset + 3]) shl 24));
  end;

begin
  Start(2);
  FTable.Play(2);
  LState := FTable.Seats[0].Game.State;
  for LCase := Low(CASES) to High(CASES) do
  begin
    LWeapon := CASES[LCase, 0];
    LState.Player.Weapons[0] := LWeapon;
    LState.Player.CurrentWeapon := 0;
    LState.Player.Ammo[0] := 100;
    LState.Player.Ammo[1] := 100;
    LState.Player.Ammo[2] := 100;
    FTable.Net.TakeSent(0);
    if (LWeapon = 4) or (LWeapon = 18) then
    begin
      // these two fire at the end of the animation of the weapon, that makes their sound when it starts
      LState.WeapMode := 1;
      LTurn := 0;
      repeat
        LState.WeapDelay := LState.TimeCount;
        FTable.Seats[0].Game.Parts.WeaponsIntf.AdvanceWeaponMode;
        Inc(LTurn);
      until (LState.WeapMode = 0) or (LTurn > 40);
      Assert.AreEqual(0, LState.WeapMode, 'the animation of the weapon ends');
    end
    else
      FTable.Seats[0].Game.Parts.WeaponsIntf.FireWeapon;
    LSent := FTable.Net.TakeSent(0);
    LSpawns := 0;
    LSounds := 0;
    for LIndex := 0 to High(LSent) do
      if (LSent[LIndex][0] = GREED_NET_EVENT_SPAWN) and (NumberAt(LSent[LIndex], SPAWN_VALUE_OFFSET) = CASES[LCase, 1]) then
        Inc(LSpawns)
      else if (LSent[LIndex][0] = GREED_NET_EVENT_SOUND) and
        (NumberAt(LSent[LIndex], SOUND_EFFECT_OFFSET) = CASES[LCase, 3]) then
        Inc(LSounds);
    Assert.AreEqual(CASES[LCase, 2], LSpawns, Format('the shots of the weapon %d that are told', [LWeapon]));
    Assert.IsTrue(LSounds >= 1, Format('the sound of the weapon %d that the others hear', [LWeapon]));
    LState.WeapMode := 0;
  end;
  // the ring of the green gun: twelve shots in the game of player 1 from one packet
  FTable.Link(1).GetData;
  Assert.AreEqual(12, FTable.Seats[1].SpritesOfKind(GREED_S_BULLET18));
end;

procedure TTestGreedNetGame.DovrebbeSvegliareIMostriVicinoAUnGiocatoreQualsiasi;
const
  // four tiles east of player 2, eight from player 0
  MONSTER_X = NET_START_2_X + 4;
  MONSTER_Y = NET_START_2_Y;
var
  LSeat, LSprite: Integer;
  LState: TGreedGameState;
  LAwake: Boolean;
begin
  Start(3);
  FTable.Play(3);
  // a sleeping monster in the game of player 0 only: its own player is too far to wake it
  FTable.Seats[0].Game.Parts.SpawnerIntf.SpawnSprite(GREED_S_MONSTER1, MONSTER_X * GREED_FRACTILEUNIT + HALF_TILE,
    MONSTER_Y * GREED_FRACTILEUNIT + HALF_TILE, 0, 0, 0, 0, False, 0);
  for LSeat := 0 to 2 do
    FTable.Seats[LSeat].Play(15);
  LState := FTable.Seats[0].Game.State;
  LAwake := False;
  LSprite := LState.Sprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    if PGreedSprite(LState.Sprites.Item(LSprite))^.Kind = GREED_S_MONSTER1 then
      LAwake := PGreedSprite(LState.Sprites.Item(LSprite))^.Active;
    LSprite := LState.Sprites.Next(LSprite);
  end;
  Assert.IsTrue(LAwake, 'the monster wakes up for the player of another computer');
  Assert.AreEqual(FTable.Link(0).PlayerData[2].X, LState.TargX, 'and its target is that player');
end;

procedure TTestGreedNetGame.NonDovrebbeFermareLOrologioPerIlMenuInRete;
var
  LState: TGreedGameState;
begin
  Start(2);
  FTable.Play(2);
  LState := FTable.Seats[0].Game.State;
  LState.ActivateMenu := True;
  FTable.Seats[0].Play(1);
  Assert.AreEqual(1, FTable.Seats[0].View.CountOf('ShowMenu'));
  Assert.IsFalse(LState.ActivateMenu);
  Assert.AreEqual(6, LState.TimeCount, 'the clock of the game went on');
end;

end.
