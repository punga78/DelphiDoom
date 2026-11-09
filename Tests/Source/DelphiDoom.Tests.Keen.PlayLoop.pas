{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the loop of the frames of a level    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.PlayLoop;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.StateTypes, DelphiDoom.Tests.Keen.GameWorld;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenPlayLoop = class(TObject)
  strict private
    FWorld: TKeenTestWorld;
    function Actor(AState: Integer; ATileX, ATileY: Integer): PKeenObject;
    procedure SetPlayer(AX, AY: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCalcolareILimitiDelleAttivita;
    [Test]
    procedure DovrebbeNonPortareILimitiSottoZero;
    [Test]
    procedure DovrebbeLeggereIlControlloEAbbassareIPulsantiTenuti;
    [Test]
    procedure DovrebbeSvegliareUnAttoreCheEntraNellaVista;
    [Test]
    procedure DovrebbeLasciareDormireUnAttoreFuoriDallaVista;
    [Test]
    procedure DovrebbeFarGirareUnAttoreSveglio;
    [Test]
    procedure DovrebbeFarDormireUnAttoreLontano;
    [Test]
    procedure DovrebbeNonFarDormireSeIlCasoDiceDiNo;
    [Test]
    procedure DovrebbeTogliereUnAttoreRimovibileLontano;
    [Test]
    procedure DovrebbeNonFarDormireUnAttoreCheNonDormeMai;
    [Test]
    procedure DovrebbeChiamareIlContattoDiDueAttoriCheSiToccano;
    [Test]
    procedure DovrebbeNonChiamareIlContattoSeNonSiToccano;
    [Test]
    procedure DovrebbeNonChiamareIlContattoDiUnoDorme;
    [Test]
    procedure DovrebbeFermareIContattiDiUnAttoreTolto;
    [Test]
    procedure DovrebbeChiamareLaReazioneSoloUnaVolta;
    [Test]
    procedure DovrebbeFinireIlLivelloSeKeenEsceDallaMappa;
    [Test]
    procedure DovrebbeUccidereKeenSeCadeDallaMappa;
    [Test]
    procedure DovrebbeUccidereKeenUnaSolaVolta;
    [Test]
    procedure DovrebbeSeguireKeenAdEst;
    [Test]
    procedure DovrebbeSeguireKeenAOvest;
    [Test]
    procedure DovrebbeSeguireKeenInAltoEInBasso;
    [Test]
    procedure DovrebbeNonScorrereSeKeenEAlCentro;
    [Test]
    procedure DovrebbeDareUnaVitaAi20000Punti;
    [Test]
    procedure DovrebbeRaddoppiareIlProssimoPuntegggio;
    [TestCase('2 tic, tempo pari', '10,2')]
    [TestCase('2 tic, tempo dispari', '11,2')]
    [TestCase('5 tic', '12,5')]
    [TestCase('6 tic, dispari', '33,6')]
    procedure DovrebbeCalcolareLaGravitaDelFrame(ATime, ATics: Integer);
    [Test]
    procedure DovrebbeLimitareLaVelocitaDiCaduta;
    [Test]
    procedure DovrebbeFareIFrameFinoAllaFineDelLivello;
    [Test]
    procedure DovrebbeFermarsiSeSiCaricaUnaPartita;
    [Test]
    procedure DovrebbeChiamareCheckKeysAOgniFrame;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.PlayLoop, DelphiDoom.Keen.Intf, DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.AudioIds;

const
  S_IDLE = 0;
  S_PLAIN = 1;
  ACTION_CONTACT = 3;
  ACTION_REACT = 4;

  SHAPE_TILE = KEEN_STARTSPRITES + 1;

function St(const AName: string; AContact, AReact: Word): TKeenStateDef;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Name := AName;
  Result.LeftShape := SHAPE_TILE;
  Result.RightShape := SHAPE_TILE;
  Result.Progress := kpStep;
  Result.TicTime := 4;
  Result.Contact := AContact;
  Result.React := AReact;
  Result.NextState := 0;
end;

{ TTestKeenPlayLoop }

procedure TTestKeenPlayLoop.Setup;
begin
  FWorld := TKeenTestWorld.Create(80, 60, [St('idle', ACTION_CONTACT, ACTION_REACT), St('plain', 0, 0)]);
  FWorld.ShowAt(20, 20);
  FWorld.Refresh.Refresh;
  // the player and the score box: no shapes, no reactions
  FWorld.Objects.Player^.State := S_PLAIN;
  FWorld.Objects.Player^.ObClass := kcKeen;
  FWorld.Objects.Player^.Active := kaAllways;
  FWorld.Objects.ScoreObj^.State := S_PLAIN;
  FWorld.Objects.ScoreObj^.Active := kaAllways;
  SetPlayer(24 * 256, 25 * 256);
end;

procedure TTestKeenPlayLoop.TearDown;
begin
  FWorld.Free;
end;

function TTestKeenPlayLoop.Actor(AState: Integer; ATileX, ATileY: Integer): PKeenObject;
begin
  Result := FWorld.AddActor(SHAPE_TILE, AState, 0, 0);
  Result^.X := Word(ATileX * 256);
  Result^.Y := Word(ATileY * 256);
  Result^.ObClass := kcBrocco;
  Result^.NeedToClip := False;
  FWorld.Mover.ClipToWalls(Result);
  Result^.NeedToReact := False;
end;

procedure TTestKeenPlayLoop.SetPlayer(AX, AY: Integer);
var
  LPlayer: PKeenObject;
begin
  LPlayer := FWorld.Objects.Player;
  LPlayer^.ShapeNum := SHAPE_TILE;
  LPlayer^.XDir := 1;
  LPlayer^.NeedToClip := False;
  LPlayer^.X := Word(AX);
  LPlayer^.Y := Word(AY);
  FWorld.Mover.ClipToWalls(LPlayer);
  LPlayer^.NeedToReact := False;
end;

procedure TTestKeenPlayLoop.DovrebbeCalcolareILimitiDelleAttivita;
begin
  // the view is at the tile (20, 20): 21 x 14 tiles
  Assert.AreEqual(20 + 20, FWorld.PlayLoop.OriginXTileMax);
  Assert.AreEqual(20 + 13, FWorld.PlayLoop.OriginYTileMax);
  Assert.AreEqual(10, FWorld.PlayLoop.InactivateLeft);
  Assert.AreEqual(40 + 10, FWorld.PlayLoop.InactivateRight);
  Assert.AreEqual(10, FWorld.PlayLoop.InactivateTop);
  Assert.AreEqual(33 + 10, FWorld.PlayLoop.InactivateBottom);
end;

procedure TTestKeenPlayLoop.DovrebbeNonPortareILimitiSottoZero;
begin
  FWorld.ShowAt(2, 2);
  Assert.AreEqual(0, FWorld.PlayLoop.InactivateLeft);
  Assert.AreEqual(0, FWorld.PlayLoop.InactivateTop);
end;

procedure TTestKeenPlayLoop.DovrebbeLeggereIlControlloEAbbassareIPulsantiTenuti;
begin
  FWorld.PlayLoop.Button0Held := True;
  FWorld.PlayLoop.Button1Held := True;
  FWorld.Input.KeyService(KEEN_SC_CONTROL);
  FWorld.PlayLoop.RunFrame;
  // the control is held: the "held" flag stays; the alt is not: it goes down
  Assert.IsTrue(FWorld.PlayLoop.Control.Button0);
  Assert.IsTrue(FWorld.PlayLoop.Button0Held);
  Assert.IsFalse(FWorld.PlayLoop.Button1Held);
  FWorld.Input.KeyService(KEEN_SC_CONTROL or $80);
  FWorld.PlayLoop.RunFrame;
  Assert.IsFalse(FWorld.PlayLoop.Button0Held);
end;

procedure TTestKeenPlayLoop.DovrebbeSvegliareUnAttoreCheEntraNellaVista;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_PLAIN, 30, 25);
  LObject^.Active := kaNo;
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(Ord(kaYes), Ord(LObject^.Active));
end;

procedure TTestKeenPlayLoop.DovrebbeLasciareDormireUnAttoreFuoriDallaVista;
var
  LObject: PKeenObject;
begin
  // the tile 41 is past the view (the last is 40)
  LObject := Actor(S_PLAIN, 42, 25);
  LObject^.Active := kaNo;
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(Ord(kaNo), Ord(LObject^.Active));
  // and its state is not run: no call
  Assert.AreEqual(0, FWorld.ActionsFake.Calls.Count);
end;

procedure TTestKeenPlayLoop.DovrebbeFarGirareUnAttoreSveglio;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_PLAIN, 30, 25);
  LObject^.TicCount := 0;
  FWorld.PlayLoop.RunFrame;
  // the state took the tics of the frame
  Assert.AreEqual(FWorld.Refresh.Tics, Integer(LObject^.TicCount) + 0);
end;

procedure TTestKeenPlayLoop.DovrebbeFarDormireUnAttoreLontano;
var
  LObject: PKeenObject;
begin
  // the number that comes out of the table is 0 (the index 255 goes to 0): less than the tics
  FWorld.Random.Initialize(True, 255);
  LObject := Actor(S_PLAIN, 70, 25);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(Ord(kaNo), Ord(LObject^.Active));
  Assert.AreEqual(0, Integer(LObject^.Sprite));
end;

procedure TTestKeenPlayLoop.DovrebbeNonFarDormireSeIlCasoDiceDiNo;
var
  LObject: PKeenObject;
begin
  // the next number is 8: not less than the tics of a frame (at most 6): it stays awake this time
  FWorld.Random.Initialize(False, 0);
  LObject := Actor(S_PLAIN, 70, 25);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(Ord(kaYes), Ord(LObject^.Active));
end;

procedure TTestKeenPlayLoop.DovrebbeTogliereUnAttoreRimovibileLontano;
var
  LObject: PKeenObject;
  LCount: Integer;
begin
  LObject := Actor(S_PLAIN, 70, 25);
  LObject^.Active := kaRemovable;
  LCount := FWorld.Objects.Count;
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(LCount - 1, FWorld.Objects.Count);
end;

procedure TTestKeenPlayLoop.DovrebbeNonFarDormireUnAttoreCheNonDormeMai;
var
  LObject: PKeenObject;
begin
  FWorld.Random.Initialize(True, 255);
  LObject := Actor(S_PLAIN, 70, 25);
  LObject^.Active := kaAllways;
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(Ord(kaAllways), Ord(LObject^.Active));
end;

procedure TTestKeenPlayLoop.DovrebbeChiamareIlContattoDiDueAttoriCheSiToccano;
var
  LFirst: PKeenObject;
  LSecond: PKeenObject;
begin
  LFirst := Actor(S_IDLE, 28, 25);
  LSecond := Actor(S_IDLE, 28, 25);
  LSecond^.X := LSecond^.X + 100;
  FWorld.Mover.ClipToWalls(LSecond);
  FWorld.PlayLoop.RunFrame;
  // the first one's function first, then the second one's, each with the other
  Assert.IsTrue(FWorld.ActionsFake.Calls.IndexOf(Format('contact %d %d %d', [ACTION_CONTACT, LFirst^.Slot, LSecond^.Slot])) >= 0);
  Assert.IsTrue(FWorld.ActionsFake.Calls.IndexOf(Format('contact %d %d %d', [ACTION_CONTACT, LSecond^.Slot, LFirst^.Slot])) >
    FWorld.ActionsFake.Calls.IndexOf(Format('contact %d %d %d', [ACTION_CONTACT, LFirst^.Slot, LSecond^.Slot])));
end;

procedure TTestKeenPlayLoop.DovrebbeNonChiamareIlContattoSeNonSiToccano;
var
  LFirst: PKeenObject;
  LSecond: PKeenObject;
  LIndex: Integer;
begin
  LFirst := Actor(S_IDLE, 28, 25);
  LSecond := Actor(S_IDLE, 31, 25);
  FWorld.PlayLoop.RunFrame;
  for LIndex := 0 to FWorld.ActionsFake.Calls.Count - 1 do
    Assert.IsFalse(FWorld.ActionsFake.Calls[LIndex].StartsWith('contact'));
  Assert.IsNotNull(LFirst);
  Assert.IsNotNull(LSecond);
end;

procedure TTestKeenPlayLoop.DovrebbeNonChiamareIlContattoDiUnoDorme;
var
  LFirst: PKeenObject;
  LSecond: PKeenObject;
  LIndex: Integer;
begin
  LFirst := Actor(S_IDLE, 28, 25);
  LSecond := Actor(S_IDLE, 28, 25);
  LSecond^.Active := kaNo;
  // outside of the view it would wake up: put it out
  LSecond^.TileRight := 100;
  LSecond^.TileLeft := 100;
  LSecond^.Left := 100 * 256;
  LSecond^.Right := 100 * 256 + 255;
  FWorld.PlayLoop.RunFrame;
  for LIndex := 0 to FWorld.ActionsFake.Calls.Count - 1 do
    Assert.IsFalse(FWorld.ActionsFake.Calls[LIndex].StartsWith('contact'));
  Assert.IsNotNull(LFirst);
end;

procedure TTestKeenPlayLoop.DovrebbeFermareIContattiDiUnAttoreTolto;
var
  LFirst: PKeenObject;
  LSecond: PKeenObject;
  LThird: PKeenObject;
  LContacts: Integer;
  LIndex: Integer;
begin
  LFirst := Actor(S_IDLE, 28, 25);
  LSecond := Actor(S_IDLE, 28, 25);
  LThird := Actor(S_IDLE, 28, 25);
  // the contact removes the first actor: it has no more class, and the loop on it ends
  FWorld.ActionsFake.OnContact.Add(ACTION_CONTACT,
    procedure(AObject, AOther: PKeenObject)
    begin
      if AObject = LFirst then
        AObject^.ObClass := kcNothing;
    end);
  FWorld.PlayLoop.RunFrame;
  LContacts := 0;
  for LIndex := 0 to FWorld.ActionsFake.Calls.Count - 1 do
    if FWorld.ActionsFake.Calls[LIndex].StartsWith(Format('contact %d %d ', [ACTION_CONTACT, LFirst^.Slot])) then
      Inc(LContacts);
  // the first with the second only: the third was not reached
  Assert.AreEqual(1, LContacts);
  Assert.IsNotNull(LSecond);
  Assert.IsNotNull(LThird);
end;

procedure TTestKeenPlayLoop.DovrebbeChiamareLaReazioneSoloUnaVolta;
var
  LObject: PKeenObject;
  LReacts: Integer;
  LIndex: Integer;
begin
  LObject := Actor(S_IDLE, 28, 25);
  LObject^.NeedToReact := True;
  FWorld.PlayLoop.RunFrame;
  LReacts := 0;
  for LIndex := 0 to FWorld.ActionsFake.Calls.Count - 1 do
    if FWorld.ActionsFake.Calls[LIndex] = Format('react %d %d', [ACTION_REACT, LObject^.Slot]) then
      Inc(LReacts);
  Assert.AreEqual(1, LReacts);
  Assert.IsFalse(LObject^.NeedToReact);
end;

procedure TTestKeenPlayLoop.DovrebbeFinireIlLivelloSeKeenEsceDallaMappa;
begin
  // the left of the player is before the minimum of the origin (512)
  SetPlayer(100, 25 * 256);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(Ord(keLevelComplete), Ord(FWorld.PlayLoop.PlayState));
end;

procedure TTestKeenPlayLoop.DovrebbeUccidereKeenSeCadeDallaMappa;
begin
  SetPlayer(24 * 256, 60 * 256 - 10);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(1, FWorld.EventsFake.KillCount);
  Assert.AreEqual(1, FWorld.EventsFake.GodModeCleared);
  Assert.IsTrue(FWorld.PlayLoop.Plummet);
end;

procedure TTestKeenPlayLoop.DovrebbeUccidereKeenUnaSolaVolta;
begin
  SetPlayer(24 * 256, 60 * 256 - 10);
  FWorld.PlayLoop.RunFrame;
  FWorld.PlayLoop.RunFrame;
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(1, FWorld.EventsFake.KillCount);
end;

procedure TTestKeenPlayLoop.DovrebbeSeguireKeenAdEst;
var
  LBefore: Integer;
begin
  LBefore := FWorld.Refresh.OriginXGlobal;
  // the east limit is 11 tiles from the origin
  SetPlayer(LBefore + 11 * 256 + 100, 25 * 256);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(LBefore + 100, FWorld.Refresh.OriginXGlobal);
  // the score box has to be drawn again when the view moves (its state has no react function, so the flag stays)
  Assert.IsTrue(FWorld.Objects.ScoreObj^.NeedToReact);
end;

procedure TTestKeenPlayLoop.DovrebbeSeguireKeenAOvest;
var
  LBefore: Integer;
begin
  LBefore := FWorld.Refresh.OriginXGlobal;
  // the west limit is 9 tiles from the origin
  SetPlayer(LBefore + 9 * 256 - 100, 25 * 256);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(LBefore - 100, FWorld.Refresh.OriginXGlobal);
end;

procedure TTestKeenPlayLoop.DovrebbeSeguireKeenInAltoEInBasso;
var
  LBefore: Integer;
begin
  LBefore := FWorld.Refresh.OriginYGlobal;
  SetPlayer(24 * 256, LBefore + 8 * 256 + 50);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(LBefore + 50, FWorld.Refresh.OriginYGlobal);
  LBefore := FWorld.Refresh.OriginYGlobal;
  SetPlayer(24 * 256, LBefore + 4 * 256 - 70);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(LBefore - 70, FWorld.Refresh.OriginYGlobal);
end;

procedure TTestKeenPlayLoop.DovrebbeNonScorrereSeKeenEAlCentro;
var
  LBefore: Integer;
begin
  LBefore := FWorld.Refresh.OriginXGlobal;
  SetPlayer(LBefore + 10 * 256, FWorld.Refresh.OriginYGlobal + 6 * 256);
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(LBefore, FWorld.Refresh.OriginXGlobal);
end;

procedure TTestKeenPlayLoop.DovrebbeDareUnaVitaAi20000Punti;
begin
  FWorld.PlayLoop.GameState^.NextExtra := 20000;
  FWorld.PlayLoop.GameState^.Lives := 3;
  FWorld.PlayLoop.GivePoints(19999);
  Assert.AreEqual(3, Integer(FWorld.PlayLoop.GameState^.Lives));
  Assert.AreEqual(0, FWorld.EventsFake.Sounds.Count);
  FWorld.PlayLoop.GivePoints(1);
  Assert.AreEqual(4, Integer(FWorld.PlayLoop.GameState^.Lives));
  Assert.AreEqual(1, FWorld.EventsFake.Sounds.Count);
  Assert.AreEqual(KEEN_SND_EXTRAKEENSND, FWorld.EventsFake.Sounds[0]);
  Assert.AreEqual(20000, FWorld.PlayLoop.GameState^.Score);
end;

procedure TTestKeenPlayLoop.DovrebbeRaddoppiareIlProssimoPuntegggio;
begin
  FWorld.PlayLoop.GameState^.NextExtra := 20000;
  FWorld.PlayLoop.GivePoints(20000);
  Assert.AreEqual(40000, FWorld.PlayLoop.GameState^.NextExtra);
  FWorld.PlayLoop.GivePoints(20000);
  Assert.AreEqual(80000, FWorld.PlayLoop.GameState^.NextExtra);
end;

procedure TTestKeenPlayLoop.DovrebbeCalcolareLaGravitaDelFrame(ATime, ATics: Integer);
var
  LExpected: Integer;
  LSpeed: Integer;
  LIndex: Integer;
begin
  // a refresh at ATime, then another ATics later: the frame has ATics tics and ends at the last time count
  FWorld.Clock.TimeCount := ATime;
  FWorld.Refresh.Refresh;
  FWorld.Clock.TimeCount := FWorld.Refresh.LastTimeCount + ATics;
  FWorld.Refresh.Refresh;
  Assert.AreEqual(ATics, FWorld.Refresh.Tics);
  FWorld.PlayLoop.CalcSingleGravity;
  // by hand: the gravity adds 3 at each odd tic to a speed that stops at 80, and the sum is halved
  LExpected := 0;
  LSpeed := 0;
  for LIndex := FWorld.Refresh.LastTimeCount - FWorld.Refresh.Tics to FWorld.Refresh.LastTimeCount - 1 do
  begin
    if (LIndex and 1) <> 0 then
    begin
      Inc(LSpeed, 3);
      if LSpeed > 80 then
        LSpeed := 80;
    end;
    Inc(LExpected, LSpeed);
  end;
  Assert.AreEqual(LExpected div 2, FWorld.PlayLoop.SingleGravity);
end;

procedure TTestKeenPlayLoop.DovrebbeLimitareLaVelocitaDiCaduta;
begin
  // the numbers of the examples of the C: 2 tics ending on an even time (8, 9): 0 + 3 = 3, halved 1
  FWorld.Clock.TimeCount := 8;
  FWorld.Refresh.Refresh;
  FWorld.Clock.TimeCount := 10;
  FWorld.Refresh.Refresh;
  FWorld.PlayLoop.CalcSingleGravity;
  Assert.AreEqual(1, FWorld.PlayLoop.SingleGravity);
end;

procedure TTestKeenPlayLoop.DovrebbeFareIFrameFinoAllaFineDelLivello;
var
  LFrames: Integer;
begin
  LFrames := 0;
  FWorld.EventsFake.OnCheckKeys :=
    procedure
    begin
      Inc(LFrames);
      if LFrames = 4 then
        FWorld.PlayLoop.PlayState := keDied;
    end;
  FWorld.PlayLoop.Run;
  Assert.AreEqual(4, LFrames);
  Assert.AreEqual(Ord(keDied), Ord(FWorld.PlayLoop.PlayState));
  Assert.AreEqual(1, FWorld.EventsFake.BeginPlayCount);
end;

procedure TTestKeenPlayLoop.DovrebbeFermarsiSeSiCaricaUnaPartita;
var
  LFrames: Integer;
begin
  LFrames := 0;
  FWorld.EventsFake.OnCheckKeys :=
    procedure
    begin
      Inc(LFrames);
      if LFrames = 2 then
        FWorld.EventsFake.GameLoaded := True;
    end;
  FWorld.PlayLoop.Run;
  Assert.AreEqual(2, LFrames);
  Assert.AreEqual(Ord(keNotDone), Ord(FWorld.PlayLoop.PlayState));
end;

procedure TTestKeenPlayLoop.DovrebbeChiamareCheckKeysAOgniFrame;
begin
  FWorld.PlayLoop.RunFrame;
  FWorld.PlayLoop.RunFrame;
  Assert.AreEqual(2, FWorld.EventsFake.CheckKeysCount);
end;

procedure TTestKeenPlayLoop.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenPlayLoop.Create(nil, FWorld.Machine, FWorld.Mover, FWorld.States, FWorld.Actions, FWorld.Refresh,
        FWorld.Input, FWorld.Random, FWorld.Events);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenPlayLoop.Create(FWorld.Objects, FWorld.Machine, FWorld.Mover, FWorld.States, FWorld.Actions, FWorld.Refresh,
        FWorld.Input, nil, FWorld.Events);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenPlayLoop);

end.
