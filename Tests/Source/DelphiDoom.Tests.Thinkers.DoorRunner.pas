{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the doors - one tic of a door                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.DoorRunner;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Thinkers.Door.Types, DelphiDoom.Thinkers.Door.Intf,
  DelphiDoom.Tests.Thinkers.DoorFakes, DelphiDoom.Tests.Thinkers.OldDoors;

type
  TOldTickProc = procedure(var door: TDoorState; AFloorHeight: Integer;
    const host: TFakeDoorHost; var outcome: TOldDoorOutcome);

  /// <summary>
  ///   A fake host whose lifetime is held by an interface variable (the runner takes it as
  ///   interfaces), with the list of lines that it writes
  /// </summary>
  TDoorTestRig = class
  strict private
    FHostRef: IDoorPlaneMover;
  public
    Events: TStringList;
    Host: TFakeDoorHost;
    constructor Create;
    destructor Destroy; override;
    function CreateRunner(AGame: TDoorGame; AFlavor: TDoorFlavor): IDoorRunner;
  end;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersDoorRunner = class(TObject)
  private
    FRig: TDoorTestRig;
    FRunner: IDoorRunner;
    function Tick(var AState: TDoorState; AFloorHeight: Integer = 0): TDoorTickOutcome;
    procedure UseRunner(AGame: TDoorGame; AFlavor: TDoorFlavor);
    procedure CheckSameAsOldCode(AGame: TDoorGame; AFlavor: TDoorFlavor;
      const AKinds: array of TDoorKind; AOld: TOldTickProc; ASplit: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeContareLaAttesaESCendereAlTermine;
    [Test]
    procedure DovrebbeSuonareLaChiusuraDellaPortaDoom;
    [Test]
    procedure DovrebbeSuonareLAperturaNellaAttesaDiHeretic;
    [Test]
    procedure DovrebbeRimuovereLaPortaAlPavimento;
    [Test]
    procedure DovrebbeSuonareLaChiusuraRapidaSoloInCompatibilita;
    [Test]
    procedure DovrebbeChiedereLeLuciSoloFuoriDallaCompatibilita;
    [Test]
    procedure DovrebbeNonChiedereLeLuciInHeretic;
    [Test]
    procedure DovrebbeTornareSuSeSchiacciaUnaPortaNormale;
    [Test]
    procedure DovrebbeNonTornareSuSeSchiacciaUnaPortaCheChiude;
    [Test]
    procedure DovrebbeAspettareDopoIlPavimentoPerUnaPortaCheRiapre;
    [Test]
    procedure DovrebbeAprireLaPortaDopoLaPrimaAttesa;
    [Test]
    procedure DovrebbeUsareLaVelocitaDelNegozioInStrife;
    [Test]
    procedure DovrebbeMuovereSoffittoEPavimentoInUnaPortaDivisa;
    [Test]
    procedure DovrebbeRimuovereLaPortaDivisaSoloSeArrivanoEntrambi;
    [Test]
    procedure DovrebbeIgnorareLaDirezioneDivisaFuoriDaStrife;
    [Test]
    procedure DovrebbeFermareIlSuonoAdOgniArrivoDelleStradePortePerScript;
    [Test]
    procedure DovrebbeFermareIlSuonoDiHereticSoloAllaRimozioneInSalita;
    [Test]
    procedure DovrebbeUsareLAttesaDellaPortaPerScriptCheRiapre;
    [Test]
    procedure DovrebbeDareEccezioneSeMancaUnServizio;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDelleDoorPerScript;
  end;

implementation

uses
  DelphiDoom.Thinkers.Door.Profiles, DelphiDoom.Thinkers.Door.Factory;

const
  SOME_SECTOR: Pointer = nil;

{ TDoorTestRig }

constructor TDoorTestRig.Create;
begin
  inherited Create;
  Events := TStringList.Create;
  Host := TFakeDoorHost.Create(Events);
  // the interface keeps the host alive for as long as the rig exists
  FHostRef := Host;
end;

destructor TDoorTestRig.Destroy;
begin
  FHostRef := nil;
  Events.Free;
  inherited Destroy;
end;

function TDoorTestRig.CreateRunner(AGame: TDoorGame; AFlavor: TDoorFlavor): IDoorRunner;
begin
  Result := TDoorFactory.CreateRunner(TDoorProfiles.ForGame(AGame, AFlavor), FHostRef,
    FHostRef as IDoorSounds, FHostRef as IDoorOptions);
end;

{ TTestThinkersDoorRunner }

procedure TTestThinkersDoorRunner.Setup;
begin
  FRig := TDoorTestRig.Create;
  FRunner := nil;
end;

procedure TTestThinkersDoorRunner.TearDown;
begin
  FRunner := nil;
  FreeAndNil(FRig);
end;

procedure TTestThinkersDoorRunner.UseRunner(AGame: TDoorGame; AFlavor: TDoorFlavor);
begin
  FRunner := FRig.CreateRunner(AGame, AFlavor);
end;

function TTestThinkersDoorRunner.Tick(var AState: TDoorState; AFloorHeight: Integer): TDoorTickOutcome;
begin
  Result := FRunner.Tick(AState, SOME_SECTOR, AFloorHeight);
end;

procedure TTestThinkersDoorRunner.DovrebbeContareLaAttesaESCendereAlTermine;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  LState := MakeDoorState(TDoorKind.Normal, 0, 0, 0, 150, 3);
  Tick(LState);
  Tick(LState);
  Assert.AreEqual(0, LState.Direction, 'still waiting');
  Assert.AreEqual(1, LState.TopCountdown);
  Tick(LState);
  Assert.AreEqual(-1, LState.Direction);
end;

procedure TTestThinkersDoorRunner.DovrebbeSuonareLaChiusuraDellaPortaDoom;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  LState := MakeDoorState(TDoorKind.Normal, 0, 0, 0, 150, 1);
  Tick(LState);
  Assert.AreEqual('play Close', Trim(FRig.Events.Text));
end;

procedure TTestThinkersDoorRunner.DovrebbeSuonareLAperturaNellaAttesaDiHeretic;
var
  LState: TDoorState;
begin
  // the door of Heretic that goes down after the wait says "open": as the original
  UseRunner(TDoorGame.Heretic, TDoorFlavor.Classic);
  LState := MakeDoorState(TDoorKind.Normal, 0, 0, 0, 150, 1);
  Tick(LState);
  Assert.AreEqual('play Open', Trim(FRig.Events.Text));
  Assert.AreEqual(-1, LState.Direction);
end;

procedure TTestThinkersDoorRunner.DovrebbeRimuovereLaPortaAlPavimento;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  FRig.Host.SetResults([TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.Normal, -1, 0, 131072, 150, 0);
  LOutcome := Tick(LState, 64 * 65536);
  Assert.IsTrue(LOutcome.Removed);
  Assert.AreEqual('move speed=131072 dest=4194304 crush=0 fc=1 dir=-1', Trim(FRig.Events.Text));
end;

procedure TTestThinkersDoorRunner.DovrebbeSuonareLaChiusuraRapidaSoloInCompatibilita;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);

  FRig.Host.Compatibility := False;
  FRig.Host.SetResults([TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.BlazeClose, -1, 0, 0, 150, 0);
  Tick(LState);
  Assert.IsTrue(Pos('play', FRig.Events.Text) = 0, 'no sound');

  FRig.Events.Clear;
  FRig.Host.Compatibility := True;
  FRig.Host.SetResults([TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.BlazeClose, -1, 0, 0, 150, 0);
  Tick(LState);
  Assert.IsTrue(Pos('play BlazeClose', FRig.Events.Text) > 0, 'sound');
end;

procedure TTestThinkersDoorRunner.DovrebbeChiedereLeLuciSoloFuoriDallaCompatibilita;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);

  FRig.Host.SetResults([TDoorPlaneResult.PastDest, TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.Normal, -1, 0, 0, 150, 0);
  LOutcome := Tick(LState);
  Assert.IsTrue(LOutcome.TurnLightsOff, 'down');
  LState := MakeDoorState(TDoorKind.Normal, 1, 0, 0, 150, 0);
  LOutcome := Tick(LState);
  Assert.IsTrue(LOutcome.TurnLightsOn, 'up');

  FRig.Host.Compatibility := True;
  FRig.Host.SetResults([TDoorPlaneResult.PastDest, TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.Normal, -1, 0, 0, 150, 0);
  LOutcome := Tick(LState);
  Assert.IsFalse(LOutcome.TurnLightsOff, 'down, compatibility');
  LState := MakeDoorState(TDoorKind.Normal, 1, 0, 0, 150, 0);
  LOutcome := Tick(LState);
  Assert.IsFalse(LOutcome.TurnLightsOn, 'up, compatibility');
end;

procedure TTestThinkersDoorRunner.DovrebbeNonChiedereLeLuciInHeretic;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  UseRunner(TDoorGame.Heretic, TDoorFlavor.Classic);
  FRig.Host.SetResults([TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.Normal, -1, 0, 0, 150, 0);
  LOutcome := Tick(LState);
  Assert.IsFalse(LOutcome.TurnLightsOff);
end;

procedure TTestThinkersDoorRunner.DovrebbeTornareSuSeSchiacciaUnaPortaNormale;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  FRig.Host.SetResults([TDoorPlaneResult.Crushed]);
  LState := MakeDoorState(TDoorKind.Normal, -1, 0, 0, 150, 0);
  Tick(LState);
  Assert.AreEqual(1, LState.Direction);
  Assert.IsTrue(Pos('play Open', FRig.Events.Text) > 0);
end;

procedure TTestThinkersDoorRunner.DovrebbeNonTornareSuSeSchiacciaUnaPortaCheChiude;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  FRig.Host.SetResults([TDoorPlaneResult.Crushed]);
  LState := MakeDoorState(TDoorKind.Close, -1, 0, 0, 150, 0);
  Tick(LState);
  Assert.AreEqual(-1, LState.Direction);
  Assert.IsTrue(Pos('play', FRig.Events.Text) = 0);
end;

procedure TTestThinkersDoorRunner.DovrebbeAspettareDopoIlPavimentoPerUnaPortaCheRiapre;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  FRig.Host.SetResults([TDoorPlaneResult.PastDest, TDoorPlaneResult.PastDest]);

  LState := MakeDoorState(TDoorKind.Close30ThenOpen, -1, 0, 0, 150, 0);
  LOutcome := Tick(LState);
  Assert.IsFalse(LOutcome.Removed);
  Assert.AreEqual(0, LState.Direction);
  Assert.AreEqual(35 * 30, LState.TopCountdown);

  LState := MakeDoorState(TDoorKind.GenCdO, -1, 0, 0, 77, 0);
  Tick(LState);
  Assert.AreEqual(0, LState.Direction);
  Assert.AreEqual(77, LState.TopCountdown, 'the wait of the door');
end;

procedure TTestThinkersDoorRunner.DovrebbeAprireLaPortaDopoLaPrimaAttesa;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  LState := MakeDoorState(TDoorKind.RaiseIn5Mins, 2, 0, 0, 150, 2);
  Tick(LState);
  Assert.AreEqual(2, LState.Direction, 'still waiting');
  LOutcome := Tick(LState);
  Assert.AreEqual(1, LState.Direction);
  Assert.AreEqual(Ord(TDoorKind.Normal), Ord(LState.Kind));
  Assert.IsTrue(LOutcome.KindChanged);
  Assert.AreEqual('play Open', Trim(FRig.Events.Text));
end;

procedure TTestThinkersDoorRunner.DovrebbeUsareLaVelocitaDelNegozioInStrife;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Strife, TDoorFlavor.Classic);
  LState := MakeDoorState(TDoorKind.ShopClose, 0, 0, 4 * 65536, 150, 1);
  Tick(LState);
  Assert.AreEqual(1, LState.Direction);
  Assert.AreEqual(2 * 65536, LState.Speed);
end;

procedure TTestThinkersDoorRunner.DovrebbeMuovereSoffittoEPavimentoInUnaPortaDivisa;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Strife, TDoorFlavor.Classic);
  LState := MakeDoorState(TDoorKind.SplitOpen, -2, 100 * 65536, 65536, 20 * 65536, 0);
  Tick(LState);
  Assert.AreEqual('move speed=65536 dest=6553600 crush=0 fc=1 dir=1' + sLineBreak +
    'move speed=65536 dest=1310720 crush=0 fc=0 dir=-1', Trim(FRig.Events.Text));
end;

procedure TTestThinkersDoorRunner.DovrebbeRimuovereLaPortaDivisaSoloSeArrivanoEntrambi;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  UseRunner(TDoorGame.Strife, TDoorFlavor.Classic);
  FRig.Host.SetResults([TDoorPlaneResult.PastDest, TDoorPlaneResult.Ok,
    TDoorPlaneResult.PastDest, TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.SplitOpen, -2, 0, 65536, 0, 0);
  LOutcome := Tick(LState);
  Assert.IsFalse(LOutcome.Removed, 'only the ceiling arrived');
  LOutcome := Tick(LState);
  Assert.IsTrue(LOutcome.Removed, 'both arrived');
end;

procedure TTestThinkersDoorRunner.DovrebbeIgnorareLaDirezioneDivisaFuoriDaStrife;
var
  LState: TDoorState;
  LOutcome: TDoorTickOutcome;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Classic);
  LState := MakeDoorState(TDoorKind.Normal, -2, 0, 65536, 0, 0);
  LOutcome := Tick(LState);
  Assert.IsFalse(LOutcome.Removed);
  Assert.AreEqual('', Trim(FRig.Events.Text), 'nothing moved');
end;

procedure TTestThinkersDoorRunner.DovrebbeFermareIlSuonoAdOgniArrivoDelleStradePortePerScript;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Hexen, TDoorFlavor.Udmf);
  FRig.Host.SetResults([TDoorPlaneResult.PastDest, TDoorPlaneResult.PastDest]);
  // a kind that the case of the old code does not name still stops the sound
  LState := MakeDoorState(TDoorKind.UdmfRaiseIn5Mins, 1, 0, 0, 150, 0);
  Tick(LState);
  Assert.IsTrue(Pos('stop', FRig.Events.Text) > 0, 'up');
  FRig.Events.Clear;
  LState := MakeDoorState(TDoorKind.UdmfRaiseIn5Mins, -1, 0, 0, 150, 0);
  Tick(LState);
  Assert.IsTrue(Pos('stop', FRig.Events.Text) > 0, 'down');
end;

procedure TTestThinkersDoorRunner.DovrebbeFermareIlSuonoDiHereticSoloAllaRimozioneInSalita;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Heretic, TDoorFlavor.Classic);
  FRig.Host.SetResults([TDoorPlaneResult.PastDest, TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.Normal, 1, 0, 0, 150, 0);
  Tick(LState);
  Assert.IsTrue(Pos('stop', FRig.Events.Text) = 0, 'the normal door waits at the top');
  LState := MakeDoorState(TDoorKind.Open, 1, 0, 0, 150, 0);
  Tick(LState);
  Assert.IsTrue(Pos('stop', FRig.Events.Text) > 0, 'the open door is removed');
end;

procedure TTestThinkersDoorRunner.DovrebbeUsareLAttesaDellaPortaPerScriptCheRiapre;
var
  LState: TDoorState;
begin
  UseRunner(TDoorGame.Doom, TDoorFlavor.Udmf);
  FRig.Host.SetResults([TDoorPlaneResult.PastDest]);
  LState := MakeDoorState(TDoorKind.UdmfCloseWaitThenOpen, -1, 0, 0, 88, 0);
  Tick(LState);
  Assert.AreEqual(0, LState.Direction);
  Assert.AreEqual(88, LState.TopCountdown);
end;

procedure TTestThinkersDoorRunner.DovrebbeDareEccezioneSeMancaUnServizio;
var
  LRig: TDoorTestRig;
begin
  LRig := TDoorTestRig.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        TDoorFactory.CreateRunner(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic),
          nil, LRig.Host, LRig.Host);
      end, EArgumentNilException);
  finally
    LRig.Free;
  end;
end;

procedure TTestThinkersDoorRunner.CheckSameAsOldCode(AGame: TDoorGame; AFlavor: TDoorFlavor;
  const AKinds: array of TDoorKind; AOld: TOldTickProc; ASplit: Boolean);
const
  DIRECTIONS: array[0..4] of Integer = (0, 2, -1, 1, -2);
var
  LKindIndex, LDirectionIndex, LSeedIndex, LTic, LIndex, LCompat, LLastDirection: Integer;
  LSeed: Cardinal;
  LOldRig, LNewRig: TDoorTestRig;
  LRunner: IDoorRunner;
  LResults: array[0..199] of TDoorPlaneResult;
  LOld, LNew: TDoorState;
  LOldOutcome: TOldDoorOutcome;
  LNewOutcome: TDoorTickOutcome;
  LFloor: Integer;
  LRandom: Cardinal;
begin
  if ASplit then
    LLastDirection := 4
  else
    LLastDirection := 3;
  for LKindIndex := 0 to High(AKinds) do
    for LDirectionIndex := 0 to LLastDirection do
      for LCompat := 0 to 1 do
        for LSeedIndex := 0 to 3 do
        begin
          LSeed := Cardinal(LKindIndex * 977 + LDirectionIndex * 131 + LSeedIndex * 17 + 5);
          // the same script of results for the old and the new code
          for LIndex := 0 to High(LResults) do
          begin
            LRandom := NextTestNumber(LSeed) mod 5;
            if LRandom < 2 then
              LResults[LIndex] := TDoorPlaneResult.Ok
            else if LRandom = 2 then
              LResults[LIndex] := TDoorPlaneResult.Crushed
            else
              LResults[LIndex] := TDoorPlaneResult.PastDest;
          end;
          LOldRig := TDoorTestRig.Create;
          LNewRig := TDoorTestRig.Create;
          try
            LOldRig.Host.Compatibility := LCompat = 1;
            LNewRig.Host.Compatibility := LCompat = 1;
            LOldRig.Host.SetResults(LResults);
            LNewRig.Host.SetResults(LResults);
            LRunner := LNewRig.CreateRunner(AGame, AFlavor);
            LFloor := Integer(NextTestNumber(LSeed) mod 100) * 65536;
            LOld := MakeDoorState(AKinds[LKindIndex], DIRECTIONS[LDirectionIndex],
              Integer(NextTestNumber(LSeed) mod 100) * 65536,
              Integer(NextTestNumber(LSeed) mod 6) * 65536,
              Integer(NextTestNumber(LSeed) mod 4) + 1,
              Integer(NextTestNumber(LSeed) mod 4) + 1);
            LNew := LOld;
            for LTic := 1 to 60 do
            begin
              LOldOutcome := Default(TOldDoorOutcome);
              AOld(LOld, LFloor, LOldRig.Host, LOldOutcome);
              LNewOutcome := LRunner.Tick(LNew, SOME_SECTOR, LFloor);
              Assert.AreEqual(DoorStateToText(LOld), DoorStateToText(LNew),
                Format('state, kind %d direction %d seed %d tic %d',
                [Ord(AKinds[LKindIndex]), DIRECTIONS[LDirectionIndex], LSeedIndex, LTic]));
              Assert.AreEqual(LOldRig.Events.Text, LNewRig.Events.Text,
                Format('calls, kind %d direction %d seed %d tic %d',
                [Ord(AKinds[LKindIndex]), DIRECTIONS[LDirectionIndex], LSeedIndex, LTic]));
              Assert.AreEqual(LOldOutcome.Removed, LNewOutcome.Removed, 'removed');
              Assert.AreEqual(LOldOutcome.LightsOff, LNewOutcome.TurnLightsOff, 'lights off');
              Assert.AreEqual(LOldOutcome.LightsOn, LNewOutcome.TurnLightsOn, 'lights on');
              LOldRig.Events.Clear;
              LNewRig.Events.Clear;
              if LOldOutcome.Removed then
                Break;
            end;
          finally
            LRunner := nil;
            LOldRig.Free;
            LNewRig.Free;
          end;
        end;
end;

procedure TTestThinkersDoorRunner.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiDoom;
begin
  CheckSameAsOldCode(TDoorGame.Doom, TDoorFlavor.Classic,
    [TDoorKind.Normal, TDoorKind.Close30ThenOpen, TDoorKind.Close, TDoorKind.Open,
    TDoorKind.RaiseIn5Mins, TDoorKind.BlazeRaise, TDoorKind.BlazeOpen, TDoorKind.BlazeClose,
    TDoorKind.GenRaise, TDoorKind.GenBlazeRaise, TDoorKind.GenOpen, TDoorKind.GenBlazeOpen,
    TDoorKind.GenClose, TDoorKind.GenBlazeClose, TDoorKind.GenCdO, TDoorKind.GenBlazeCdO],
    OldDoomTick, False);
end;

procedure TTestThinkersDoorRunner.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiHeretic;
begin
  CheckSameAsOldCode(TDoorGame.Heretic, TDoorFlavor.Classic,
    [TDoorKind.Normal, TDoorKind.Close30ThenOpen, TDoorKind.Close, TDoorKind.Open,
    TDoorKind.RaiseIn5Mins], OldHereticTick, False);
end;

procedure TTestThinkersDoorRunner.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDiStrife;
begin
  CheckSameAsOldCode(TDoorGame.Strife, TDoorFlavor.Classic,
    [TDoorKind.Normal, TDoorKind.Close30ThenOpen, TDoorKind.Close, TDoorKind.Open,
    TDoorKind.RaiseIn5Mins, TDoorKind.BlazeRaise, TDoorKind.BlazeOpen, TDoorKind.BlazeClose,
    TDoorKind.ShopClose, TDoorKind.SplitRaiseNearest, TDoorKind.SplitOpen, TDoorKind.GenRaise,
    TDoorKind.GenBlazeRaise, TDoorKind.GenOpen, TDoorKind.GenBlazeOpen, TDoorKind.GenClose,
    TDoorKind.GenBlazeClose, TDoorKind.GenCdO, TDoorKind.GenBlazeCdO],
    OldStrifeTick, True);
end;

procedure TTestThinkersDoorRunner.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDelleDoorPerScript;
begin
  CheckSameAsOldCode(TDoorGame.Doom, TDoorFlavor.Udmf,
    [TDoorKind.UdmfNormal, TDoorKind.UdmfClose30ThenOpen, TDoorKind.UdmfClose,
    TDoorKind.UdmfOpen, TDoorKind.UdmfRaiseIn5Mins, TDoorKind.UdmfCloseWaitThenOpen],
    OldUdmfTick, False);
  CheckSameAsOldCode(TDoorGame.Hexen, TDoorFlavor.Udmf,
    [TDoorKind.UdmfNormal, TDoorKind.UdmfClose30ThenOpen, TDoorKind.UdmfClose,
    TDoorKind.UdmfOpen, TDoorKind.UdmfRaiseIn5Mins, TDoorKind.UdmfCloseWaitThenOpen],
    OldUdmfTick, False);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersDoorRunner);

end.
