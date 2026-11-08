{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the doors - the making of the doors                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.DoorSpawner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Door.Types,
  DelphiDoom.Thinkers.Door.Intf, DelphiDoom.Tests.Thinkers.DoorFakes,
  DelphiDoom.Tests.Thinkers.DoorRunner;

type
  TOldTagged = reference to procedure(var door: TDoorState; AKind: TDoorKind;
    ACeilingHeight: Integer; const host: TFakeDoorHost);
  TOldManual = reference to function(var door: TDoorState; ASpecial: Integer;
    const host: TFakeDoorHost): Boolean;
  TOldRetrigger = reference to function(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
    out AAction: TDoorRetrigger): Boolean;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersDoorSpawner = class(TObject)
  private
    FRig: TDoorTestRig;
    FSpawner: IDoorSpawner;
    procedure UseSpawner(AGame: TDoorGame; AFlavor: TDoorFlavor);
    function Input(ASpeed, ATopWait: Integer): TDoorSpawnInput;
    procedure CheckTaggedSameAsOldCode(AGame: TDoorGame; AFlavor: TDoorFlavor;
      const AKinds: array of TDoorKind; ASpeed, ATopWait: Integer; const AOld: TOldTagged);
    procedure CheckManualSameAsOldCode(AGame: TDoorGame; AFlavor: TDoorFlavor; ASpeed,
      ATopWait: Integer; const AOld: TOldManual);
    procedure CheckRetriggerSameAsOldCode(AGame: TDoorGame; const AOld: TOldRetrigger);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNonSuonareSeLaPortaNonSiMuove;
    [Test]
    procedure DovrebbeSuonareSeLaPortaSiMuove;
    [Test]
    procedure DovrebbeQuadruplicareLaVelocitaDellePorteRapide;
    [Test]
    procedure DovrebbeTenereIlPavimentoNellAttesaDiUnaPortaDivisa;
    [Test]
    procedure DovrebbeConvertireLAttesaDellePortePerScriptInTic;
    [Test]
    procedure DovrebbeSuonareSempreNellePortePerScript;
    [Test]
    procedure DovrebbeCancellareLoSpecialDelleAperture;
    [Test]
    procedure DovrebbeNonCancellareLoSpecialDelleRichiusure;
    [Test]
    procedure DovrebbeUsareLaVelocitaDellaLineaPerScript;
    [Test]
    procedure DovrebbeRiaprireUnaPortaCheScende;
    [Test]
    procedure DovrebbeChiudereUnaPortaCheSaleSoloPerIlGiocatore;
    [Test]
    procedure DovrebbeNonToccareUnaPortaConUnaAperturaAMano;
    [Test]
    procedure DovrebbeDareLeAttesePerLePorteCheSiMuovonoDaSole;
    [Test]
    procedure DovrebbeDareEccezioneSeMancaUnServizio;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelVecchioCodiceDellePortePerScript;
    [Test]
    procedure DovrebbeFareLePorteAMancoDelVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeFareLePorteAMancoDelVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeFareLePorteAMancoDelVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeFareLePorteAMancoDellePortePerScript;
    [Test]
    procedure DovrebbeRichiamareLePorteCometeIlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeRichiamareLePorteCometeIlVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeRichiamareLePorteCometeIlVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeDareLePorteCheSiMuovonoDaSoleCometeIlVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Thinkers.Door.Profiles, DelphiDoom.Thinkers.Door.Factory,
  DelphiDoom.Tests.Thinkers.OldDoors;

const
  FRACUNIT = 65536;
  VDOORSPEED = 2 * FRACUNIT;
  VDOORWAIT = 150;
  SOME_SECTOR: Pointer = nil;

{ TTestThinkersDoorSpawner }

procedure TTestThinkersDoorSpawner.Setup;
begin
  FRig := TDoorTestRig.Create;
  FSpawner := nil;
end;

procedure TTestThinkersDoorSpawner.TearDown;
begin
  FSpawner := nil;
  FreeAndNil(FRig);
end;

procedure TTestThinkersDoorSpawner.UseSpawner(AGame: TDoorGame; AFlavor: TDoorFlavor);
begin
  FSpawner := TDoorFactory.CreateSpawner(TDoorProfiles.ForGame(AGame, AFlavor),
    FRig.Host as IDoorSounds, FRig.Host as IDoorSectorQueries);
end;

function TTestThinkersDoorSpawner.Input(ASpeed, ATopWait: Integer): TDoorSpawnInput;
begin
  Result := Default(TDoorSpawnInput);
  Result.Speed := ASpeed;
  Result.TopWait := ATopWait;
end;

procedure TTestThinkersDoorSpawner.DovrebbeNonSuonareSeLaPortaNonSiMuove;
var
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  FRig.Host.LowestCeiling := 128 * FRACUNIT;
  // the door already is at the height of its top
  LState := FSpawner.SpawnTagged(SOME_SECTOR, 124 * FRACUNIT, TDoorKind.Normal,
    Input(VDOORSPEED, VDOORWAIT));
  Assert.AreEqual('', Trim(FRig.Events.Text));
  Assert.AreEqual(124 * FRACUNIT, LState.TopHeight);
  Assert.AreEqual(1, LState.Direction);
end;

procedure TTestThinkersDoorSpawner.DovrebbeSuonareSeLaPortaSiMuove;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  FRig.Host.LowestCeiling := 128 * FRACUNIT;
  FSpawner.SpawnTagged(SOME_SECTOR, 0, TDoorKind.Normal, Input(VDOORSPEED, VDOORWAIT));
  Assert.AreEqual('play Open', Trim(FRig.Events.Text));
end;

procedure TTestThinkersDoorSpawner.DovrebbeQuadruplicareLaVelocitaDellePorteRapide;
var
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  LState := FSpawner.SpawnTagged(SOME_SECTOR, 0, TDoorKind.BlazeRaise,
    Input(VDOORSPEED, VDOORWAIT));
  Assert.AreEqual(4 * VDOORSPEED, LState.Speed);
  LState := FSpawner.SpawnTagged(SOME_SECTOR, 0, TDoorKind.Normal, Input(VDOORSPEED, VDOORWAIT));
  Assert.AreEqual(VDOORSPEED, LState.Speed);
end;

procedure TTestThinkersDoorSpawner.DovrebbeTenereIlPavimentoNellAttesaDiUnaPortaDivisa;
var
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Strife, TDoorFlavor.Classic);
  FRig.Host.LowestCeiling := 128 * FRACUNIT;
  FRig.Host.LowestFloor := 8 * FRACUNIT;
  FRig.Host.HighestFloor := 32 * FRACUNIT;

  LState := FSpawner.SpawnTagged(SOME_SECTOR, 0, TDoorKind.SplitOpen, Input(VDOORSPEED, VDOORWAIT));
  Assert.AreEqual(-2, LState.Direction);
  Assert.AreEqual(FRACUNIT, LState.Speed);
  Assert.AreEqual(8 * FRACUNIT, LState.TopWait, 'lowest floor');

  LState := FSpawner.SpawnTagged(SOME_SECTOR, 0, TDoorKind.SplitRaiseNearest,
    Input(VDOORSPEED, VDOORWAIT));
  Assert.AreEqual(32 * FRACUNIT, LState.TopWait, 'highest floor');
end;

procedure TTestThinkersDoorSpawner.DovrebbeConvertireLAttesaDellePortePerScriptInTic;
var
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Hexen, TDoorFlavor.Udmf);
  LState := FSpawner.SpawnTagged(SOME_SECTOR, 0, TDoorKind.UdmfCloseWaitThenOpen, Input(0, 16));
  Assert.AreEqual(16 * 35 div 8, LState.TopWait);
  LState := FSpawner.SpawnTagged(SOME_SECTOR, 0, TDoorKind.UdmfClose30ThenOpen, Input(0, 16));
  Assert.AreEqual(16, LState.TopWait, 'the other kinds keep the wait');
end;

procedure TTestThinkersDoorSpawner.DovrebbeSuonareSempreNellePortePerScript;
begin
  UseSpawner(TDoorGame.Hexen, TDoorFlavor.Udmf);
  FRig.Host.LowestCeiling := 128 * FRACUNIT;
  // the door is where its top is, and still the scripted doors make their sound
  FSpawner.SpawnTagged(SOME_SECTOR, 124 * FRACUNIT, TDoorKind.UdmfNormal, Input(0, 0));
  Assert.AreEqual('play Open', Trim(FRig.Events.Text));
end;

procedure TTestThinkersDoorSpawner.DovrebbeCancellareLoSpecialDelleAperture;
var
  LConsume: Boolean;
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  LState := FSpawner.SpawnManual(SOME_SECTOR, 31, Input(VDOORSPEED, VDOORWAIT), LConsume);
  Assert.IsTrue(LConsume);
  Assert.AreEqual(Ord(TDoorKind.Open), Ord(LState.Kind));
  LState := FSpawner.SpawnManual(SOME_SECTOR, 118, Input(VDOORSPEED, VDOORWAIT), LConsume);
  Assert.IsTrue(LConsume);
  Assert.AreEqual(Ord(TDoorKind.BlazeOpen), Ord(LState.Kind));
  Assert.AreEqual(4 * VDOORSPEED, LState.Speed);
end;

procedure TTestThinkersDoorSpawner.DovrebbeNonCancellareLoSpecialDelleRichiusure;
var
  LConsume: Boolean;
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  LState := FSpawner.SpawnManual(SOME_SECTOR, 1, Input(VDOORSPEED, VDOORWAIT), LConsume);
  Assert.IsFalse(LConsume);
  Assert.AreEqual(Ord(TDoorKind.Normal), Ord(LState.Kind));
  Assert.AreEqual(1, LState.Direction);
end;

procedure TTestThinkersDoorSpawner.DovrebbeUsareLaVelocitaDellaLineaPerScript;
var
  LConsume: Boolean;
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Hexen, TDoorFlavor.Udmf);
  LState := FSpawner.SpawnManual(SOME_SECTOR, 11, Input(3 * FRACUNIT div 8, 70), LConsume);
  Assert.IsTrue(LConsume);
  Assert.AreEqual(Ord(TDoorKind.UdmfOpen), Ord(LState.Kind));
  Assert.AreEqual(3 * FRACUNIT div 8, LState.Speed);
  Assert.AreEqual(70, LState.TopWait);
end;

procedure TTestThinkersDoorSpawner.DovrebbeRiaprireUnaPortaCheScende;
var
  LAction: TDoorRetrigger;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  Assert.IsTrue(FSpawner.Retrigger(1, -1, False, LAction));
  Assert.AreEqual(Ord(TDoorRetrigger.GoUp), Ord(LAction), 'even a monster reopens it');
end;

procedure TTestThinkersDoorSpawner.DovrebbeChiudereUnaPortaCheSaleSoloPerIlGiocatore;
var
  LAction: TDoorRetrigger;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  Assert.IsTrue(FSpawner.Retrigger(26, 1, True, LAction));
  Assert.AreEqual(Ord(TDoorRetrigger.GoDown), Ord(LAction), 'the player');
  Assert.IsTrue(FSpawner.Retrigger(26, 1, False, LAction));
  Assert.AreEqual(Ord(TDoorRetrigger.Ignore), Ord(LAction), 'a monster never closes doors');
end;

procedure TTestThinkersDoorSpawner.DovrebbeNonToccareUnaPortaConUnaAperturaAMano;
var
  LAction: TDoorRetrigger;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  Assert.IsFalse(FSpawner.Retrigger(31, 1, True, LAction), 'the engine makes a new door');
  UseSpawner(TDoorGame.Hexen, TDoorFlavor.Udmf);
  Assert.IsFalse(FSpawner.Retrigger(12, 1, True, LAction), 'scripted doors are never reused');
end;

procedure TTestThinkersDoorSpawner.DovrebbeDareLeAttesePerLePorteCheSiMuovonoDaSole;
var
  LState: TDoorState;
begin
  UseSpawner(TDoorGame.Doom, TDoorFlavor.Classic);
  FRig.Host.LowestCeiling := 100 * FRACUNIT;

  LState := FSpawner.CloseInThirtySeconds;
  Assert.AreEqual(0, LState.Direction);
  Assert.AreEqual(30 * 35, LState.TopCountdown);
  Assert.AreEqual(Ord(TDoorKind.Normal), Ord(LState.Kind));

  LState := FSpawner.RaiseInFiveMinutes(SOME_SECTOR);
  Assert.AreEqual(2, LState.Direction);
  Assert.AreEqual(5 * 60 * 35, LState.TopCountdown);
  Assert.AreEqual(96 * FRACUNIT, LState.TopHeight);
  Assert.AreEqual(VDOORWAIT, LState.TopWait);
  Assert.AreEqual(Ord(TDoorKind.RaiseIn5Mins), Ord(LState.Kind));
end;

procedure TTestThinkersDoorSpawner.DovrebbeDareEccezioneSeMancaUnServizio;
var
  LRig: TDoorTestRig;
begin
  LRig := TDoorTestRig.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        TDoorFactory.CreateSpawner(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic),
          nil, LRig.Host);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TDoorFactory.CreateSpawner(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic),
          LRig.Host, nil);
      end, EArgumentNilException);
  finally
    LRig.Free;
  end;
end;

procedure TTestThinkersDoorSpawner.CheckTaggedSameAsOldCode(AGame: TDoorGame;
  AFlavor: TDoorFlavor; const AKinds: array of TDoorKind; ASpeed, ATopWait: Integer;
  const AOld: TOldTagged);
var
  LKindIndex, LCase: Integer;
  LSeed: Cardinal;
  LOldRig, LNewRig: TDoorTestRig;
  LSpawner: IDoorSpawner;
  LOld, LNew: TDoorState;
  LCeiling, LLowestCeiling: Integer;
begin
  for LKindIndex := 0 to High(AKinds) do
    for LCase := 0 to 5 do
    begin
      LSeed := Cardinal(LKindIndex * 389 + LCase * 29 + 3);
      LOldRig := TDoorTestRig.Create;
      LNewRig := TDoorTestRig.Create;
      try
        LLowestCeiling := (Integer(NextTestNumber(LSeed) mod 150) + 50) * FRACUNIT;
        LOldRig.Host.LowestCeiling := LLowestCeiling;
        LNewRig.Host.LowestCeiling := LLowestCeiling;
        LOldRig.Host.LowestFloor := Integer(NextTestNumber(LSeed) mod 40) * FRACUNIT;
        LNewRig.Host.LowestFloor := LOldRig.Host.LowestFloor;
        LOldRig.Host.HighestFloor := Integer(NextTestNumber(LSeed) mod 40) * FRACUNIT + 41 * FRACUNIT;
        LNewRig.Host.HighestFloor := LOldRig.Host.HighestFloor;
        // half of the cases have the ceiling where the top of the door will be
        if LCase mod 2 = 0 then
          LCeiling := LLowestCeiling - 4 * FRACUNIT
        else
          LCeiling := Integer(NextTestNumber(LSeed) mod 200) * FRACUNIT;

        LSpawner := TDoorFactory.CreateSpawner(TDoorProfiles.ForGame(AGame, AFlavor),
          LNewRig.Host as IDoorSounds, LNewRig.Host as IDoorSectorQueries);
        LOld := Default(TDoorState);
        AOld(LOld, AKinds[LKindIndex], LCeiling, LOldRig.Host);
        LNew := LSpawner.SpawnTagged(SOME_SECTOR, LCeiling, AKinds[LKindIndex],
          Input(ASpeed, ATopWait));

        Assert.AreEqual(DoorStateToText(LOld), DoorStateToText(LNew),
          Format('state, kind %d case %d', [Ord(AKinds[LKindIndex]), LCase]));
        Assert.AreEqual(LOldRig.Events.Text, LNewRig.Events.Text,
          Format('calls, kind %d case %d', [Ord(AKinds[LKindIndex]), LCase]));
      finally
        LSpawner := nil;
        LOldRig.Free;
        LNewRig.Free;
      end;
    end;
end;

procedure TTestThinkersDoorSpawner.CheckManualSameAsOldCode(AGame: TDoorGame;
  AFlavor: TDoorFlavor; ASpeed, ATopWait: Integer; const AOld: TOldManual);
var
  LSpecial: Integer;
  LOldRig, LNewRig: TDoorTestRig;
  LSpawner: IDoorSpawner;
  LOld, LNew: TDoorState;
  LOldConsume, LNewConsume: Boolean;
begin
  for LSpecial := 0 to 260 do
  begin
    LOldRig := TDoorTestRig.Create;
    LNewRig := TDoorTestRig.Create;
    try
      LOldRig.Host.LowestCeiling := (LSpecial + 60) * FRACUNIT;
      LNewRig.Host.LowestCeiling := (LSpecial + 60) * FRACUNIT;
      LSpawner := TDoorFactory.CreateSpawner(TDoorProfiles.ForGame(AGame, AFlavor),
        LNewRig.Host as IDoorSounds, LNewRig.Host as IDoorSectorQueries);
      LOld := Default(TDoorState);
      LOldConsume := AOld(LOld, LSpecial, LOldRig.Host);
      LNew := LSpawner.SpawnManual(SOME_SECTOR, LSpecial, Input(ASpeed, ATopWait), LNewConsume);

      Assert.AreEqual(DoorStateToText(LOld), DoorStateToText(LNew),
        Format('state, special %d', [LSpecial]));
      Assert.AreEqual(LOldRig.Events.Text, LNewRig.Events.Text,
        Format('calls, special %d', [LSpecial]));
      Assert.AreEqual(LOldConsume, LNewConsume, Format('special cleared, special %d', [LSpecial]));
    finally
      LSpawner := nil;
      LOldRig.Free;
      LNewRig.Free;
    end;
  end;
end;

procedure TTestThinkersDoorSpawner.CheckRetriggerSameAsOldCode(AGame: TDoorGame;
  const AOld: TOldRetrigger);
var
  LSpecial, LDirection, LPlayer: Integer;
  LRig: TDoorTestRig;
  LSpawner: IDoorSpawner;
  LOldAction, LNewAction: TDoorRetrigger;
  LOldHandled, LNewHandled: Boolean;
begin
  LRig := TDoorTestRig.Create;
  try
    LSpawner := TDoorFactory.CreateSpawner(TDoorProfiles.ForGame(AGame, TDoorFlavor.Classic),
      LRig.Host as IDoorSounds, LRig.Host as IDoorSectorQueries);
    for LSpecial := 0 to 260 do
      for LDirection := -1 to 1 do
        for LPlayer := 0 to 1 do
        begin
          LOldHandled := AOld(LSpecial, LDirection, LPlayer = 1, LOldAction);
          LNewHandled := LSpawner.Retrigger(LSpecial, LDirection, LPlayer = 1, LNewAction);
          Assert.AreEqual(LOldHandled, LNewHandled,
            Format('handled, special %d direction %d', [LSpecial, LDirection]));
          Assert.AreEqual(Ord(LOldAction), Ord(LNewAction),
            Format('action, special %d direction %d player %d', [LSpecial, LDirection, LPlayer]));
        end;
  finally
    LSpawner := nil;
    LRig.Free;
  end;
end;

procedure TTestThinkersDoorSpawner.DovrebbeDareGliStessiValoriDelVecchioCodiceDiDoom;
begin
  CheckTaggedSameAsOldCode(TDoorGame.Doom, TDoorFlavor.Classic,
    [TDoorKind.Normal, TDoorKind.Close30ThenOpen, TDoorKind.Close, TDoorKind.Open,
    TDoorKind.BlazeRaise, TDoorKind.BlazeOpen, TDoorKind.BlazeClose], VDOORSPEED, VDOORWAIT,
    procedure(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
      const host: TFakeDoorHost)
    begin
      OldDoomDoDoor(door, AKind, ACeilingHeight, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeDareGliStessiValoriDelVecchioCodiceDiHeretic;
begin
  CheckTaggedSameAsOldCode(TDoorGame.Heretic, TDoorFlavor.Classic,
    [TDoorKind.Normal, TDoorKind.Close30ThenOpen, TDoorKind.Close, TDoorKind.Open],
    3 * VDOORSPEED, VDOORWAIT,
    procedure(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
      const host: TFakeDoorHost)
    begin
      OldHereticDoDoor(door, AKind, 3 * VDOORSPEED, ACeilingHeight, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeDareGliStessiValoriDelVecchioCodiceDiStrife;
begin
  CheckTaggedSameAsOldCode(TDoorGame.Strife, TDoorFlavor.Classic,
    [TDoorKind.Normal, TDoorKind.Close30ThenOpen, TDoorKind.Close, TDoorKind.Open,
    TDoorKind.BlazeRaise, TDoorKind.BlazeOpen, TDoorKind.BlazeClose, TDoorKind.ShopClose,
    TDoorKind.SplitRaiseNearest, TDoorKind.SplitOpen], VDOORSPEED, VDOORWAIT,
    procedure(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
      const host: TFakeDoorHost)
    begin
      OldStrifeDoDoor(door, AKind, ACeilingHeight, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeDareGliStessiValoriDelVecchioCodiceDellePortePerScript;
begin
  CheckTaggedSameAsOldCode(TDoorGame.Hexen, TDoorFlavor.Udmf,
    [TDoorKind.UdmfNormal, TDoorKind.UdmfClose30ThenOpen, TDoorKind.UdmfClose,
    TDoorKind.UdmfOpen, TDoorKind.UdmfRaiseIn5Mins, TDoorKind.UdmfCloseWaitThenOpen],
    5 * FRACUNIT div 8, 24,
    procedure(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
      const host: TFakeDoorHost)
    begin
      OldUdmfDoDoor(door, AKind, 5 * FRACUNIT div 8, 24, ACeilingHeight, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeFareLePorteAMancoDelVecchioCodiceDiDoom;
begin
  CheckManualSameAsOldCode(TDoorGame.Doom, TDoorFlavor.Classic, VDOORSPEED, VDOORWAIT,
    function(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean
    begin
      Result := OldDoomManual(door, ASpecial, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeFareLePorteAMancoDelVecchioCodiceDiHeretic;
begin
  CheckManualSameAsOldCode(TDoorGame.Heretic, TDoorFlavor.Classic, VDOORSPEED, VDOORWAIT,
    function(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean
    begin
      Result := OldHereticManual(door, ASpecial, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeFareLePorteAMancoDelVecchioCodiceDiStrife;
begin
  CheckManualSameAsOldCode(TDoorGame.Strife, TDoorFlavor.Classic, VDOORSPEED, VDOORWAIT,
    function(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean
    begin
      Result := OldStrifeManual(door, ASpecial, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeFareLePorteAMancoDellePortePerScript;
begin
  CheckManualSameAsOldCode(TDoorGame.Hexen, TDoorFlavor.Udmf, 7 * FRACUNIT div 8, 33,
    function(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean
    begin
      Result := OldUdmfManual(door, ASpecial, 7 * FRACUNIT div 8, 33, host);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeRichiamareLePorteCometeIlVecchioCodiceDiDoom;
begin
  CheckRetriggerSameAsOldCode(TDoorGame.Doom,
    function(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
      out AAction: TDoorRetrigger): Boolean
    begin
      Result := OldDoomRetrigger(ASpecial, ADirection, AThingIsPlayer, AAction);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeRichiamareLePorteCometeIlVecchioCodiceDiHeretic;
begin
  CheckRetriggerSameAsOldCode(TDoorGame.Heretic,
    function(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
      out AAction: TDoorRetrigger): Boolean
    begin
      Result := OldHereticRetrigger(ASpecial, ADirection, AThingIsPlayer, AAction);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeRichiamareLePorteCometeIlVecchioCodiceDiStrife;
begin
  CheckRetriggerSameAsOldCode(TDoorGame.Strife,
    function(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
      out AAction: TDoorRetrigger): Boolean
    begin
      Result := OldStrifeRetrigger(ASpecial, ADirection, AThingIsPlayer, AAction);
    end);
end;

procedure TTestThinkersDoorSpawner.DovrebbeDareLePorteCheSiMuovonoDaSoleCometeIlVecchioCodice;
var
  LOld, LNew: TDoorState;
  LOldRig, LNewRig: TDoorTestRig;
  LSpawner: IDoorSpawner;
begin
  LOldRig := TDoorTestRig.Create;
  LNewRig := TDoorTestRig.Create;
  try
    LOldRig.Host.LowestCeiling := 144 * FRACUNIT;
    LNewRig.Host.LowestCeiling := 144 * FRACUNIT;
    LSpawner := TDoorFactory.CreateSpawner(TDoorProfiles.ForGame(TDoorGame.Doom, TDoorFlavor.Classic),
      LNewRig.Host as IDoorSounds, LNewRig.Host as IDoorSectorQueries);

    LOld := Default(TDoorState);
    OldCloseIn30(LOld);
    LNew := LSpawner.CloseInThirtySeconds;
    Assert.AreEqual(DoorStateToText(LOld), DoorStateToText(LNew), 'close in 30');

    LOld := Default(TDoorState);
    OldRaiseIn5Mins(LOld, LOldRig.Host);
    LNew := LSpawner.RaiseInFiveMinutes(SOME_SECTOR);
    Assert.AreEqual(DoorStateToText(LOld), DoorStateToText(LNew), 'raise in 5 minutes');
  finally
    LSpawner := nil;
    LOldRig.Free;
    LNewRig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersDoorSpawner);

end.
