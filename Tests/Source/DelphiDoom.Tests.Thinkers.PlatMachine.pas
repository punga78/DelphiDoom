{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the classic platforms                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlatMachine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Platform.Types, DelphiDoom.Thinkers.Platform.Intf,
  DelphiDoom.Tests.Thinkers.PlatFakes, DelphiDoom.Tests.Thinkers.OldPlats;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersPlatMachine = class(TObject)
  private
    FWorld: TFakePlatWorld;
    FSector: TFakePlatSector;
    function CreateMachine(AGame: TPlatGame; const ARandom: IGameRandom): IPlatMachine;
    procedure CheckParity(AGame: TPlatGame; const AKinds: TPlatKinds);
    procedure Configure(AGame: TPlatGame; AKind: TPlatKind; var AState: TPlatState;
      const ARandom: IGameRandom);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeConfigurareUnaPiattaformaPerpetua;
    [Test]
    procedure DovrebbeConfigurareLAscensoreLentoDiStrife;
    [Test]
    procedure DovrebbeConfigurareLAscensoreCheSaleDiStrife;
    [Test]
    procedure DovrebbeConfigurareIlToggleSenzaSuono;
    [Test]
    procedure DovrebbePartireDalPavimentoDelSettoreInDoomEStrife;
    [Test]
    procedure DovrebbeLasciareLowComeEraInHeretic;
    [Test]
    procedure DovrebbeCambiareImmagineESpecialDellaSalitaAlPiuVicino;
    [Test]
    procedure DovrebbeUsareUnSoloNumeroCasualeNelLaPiattaformaPerpetua;
    [Test]
    procedure DovrebbeMettereIlToggleInStasiAllaFineDellaCorsa;
    [Test]
    procedure DovrebbeRimuovereLaSalitaIndipendenteAllaFineDellaSalita;
    [Test]
    procedure DovrebbeRimuovereAlFondoSoloNelMotoreModerno;
    [Test]
    procedure DovrebbeRimuovereAlFondoSempreInStrife;
    [Test]
    procedure DovrebbeInvertireIlToggleRiattivatoSoloInDoom;
    [Test]
    procedure DovrebbeFermareEPortareInStasi;
    [Test]
    procedure DovrebbeFarScendereLaPiattaformaSeSchiacciataSenzaCrush;
    [Test]
    procedure DovrebbeSuonareLaPietraOgniOttoTic;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnServizioManca;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceDoom;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceHeretic;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceStrife;
  end;

implementation

uses
  DelphiDoom.MathCore.Factory, DelphiDoom.Thinkers.Platform.Factory,
  DelphiDoom.Tests.Thinkers.Fakes;

const
  FRACUNIT = 65536;

function ToState(const APlat: TOldPlat): TPlatState;
begin
  Result.Speed := APlat.Speed;
  Result.Low := APlat.Low;
  Result.High := APlat.High;
  Result.Wait := APlat.Wait;
  Result.Count := APlat.Count;
  Result.Status := APlat.Status;
  Result.OldStatus := APlat.OldStatus;
  Result.Crush := APlat.Crush;
  Result.Tag := APlat.Tag;
end;

function PresetPlat(ASector: TFakePlatSector; AKind: TPlatKind): TOldPlat;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Sector := ASector;
  Result.Kind := AKind;
  Result.Low := 12345;
  Result.High := 23456;
  Result.Speed := 3;
  Result.Wait := 7;
  Result.Count := 9;
  Result.Status := TPlatStatus.Waiting;
  Result.OldStatus := TPlatStatus.Waiting;
  Result.Tag := 42;
end;

{ TTestThinkersPlatMachine }

procedure TTestThinkersPlatMachine.Setup;
begin
  FWorld := TFakePlatWorld.Create;
  FSector := FWorld.AddSector(0, 128 * FRACUNIT);
end;

procedure TTestThinkersPlatMachine.TearDown;
begin
  FreeAndNil(FWorld);
end;

function TTestThinkersPlatMachine.CreateMachine(AGame: TPlatGame;
  const ARandom: IGameRandom): IPlatMachine;
begin
  Result := TPlatFactory.CreateMachine(AGame, FWorld, FWorld, ARandom);
end;

procedure TTestThinkersPlatMachine.Configure(AGame: TPlatGame; AKind: TPlatKind;
  var AState: TPlatState; const ARandom: IGameRandom);
begin
  CreateMachine(AGame, ARandom).Configure(FSector, AKind, 5, 24, AState);
end;

procedure TTestThinkersPlatMachine.DovrebbeConfigurareUnaPiattaformaPerpetua;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.LowestSurrounding := -32 * FRACUNIT;
  FSector.HighestSurrounding := 48 * FRACUNIT;
  Configure(TPlatGame.Doom, TPlatKind.PerpetualRaise, LState, CreateTestRandom(0));
  Assert.AreEqual(FRACUNIT, LState.Speed);
  Assert.AreEqual(-32 * FRACUNIT, LState.Low);
  Assert.AreEqual(48 * FRACUNIT, LState.High);
  Assert.AreEqual(105, LState.Wait);
  Assert.AreEqual('sound start', FWorld.Events[0]);
end;

procedure TTestThinkersPlatMachine.DovrebbeConfigurareLAscensoreLentoDiStrife;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  Configure(TPlatGame.Strife, TPlatKind.SlowDownWaitUpStay, LState, CreateTestRandom(0));
  Assert.AreEqual(FRACUNIT, LState.Speed);
  Assert.AreEqual(35 * 30, LState.Wait);
  Assert.IsTrue(LState.Status = TPlatStatus.Down);
  Assert.AreEqual(0, LState.High);
end;

procedure TTestThinkersPlatMachine.DovrebbeConfigurareLAscensoreCheSaleDiStrife;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.NextHigher := 24 * FRACUNIT;
  Configure(TPlatGame.Strife, TPlatKind.UpWaitDownStay, LState, CreateTestRandom(0));
  Assert.AreEqual(4 * FRACUNIT, LState.Speed);
  Assert.AreEqual(24 * FRACUNIT, LState.High);
  Assert.AreEqual(0, LState.Low);
  Assert.IsTrue(LState.Status = TPlatStatus.Up);
end;

procedure TTestThinkersPlatMachine.DovrebbeConfigurareIlToggleSenzaSuono;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  Configure(TPlatGame.Doom, TPlatKind.ToggleUpDown, LState, CreateTestRandom(0));
  Assert.IsTrue(LState.Crush);
  Assert.AreEqual(128 * FRACUNIT, LState.Low);
  Assert.AreEqual(0, LState.High);
  Assert.IsTrue(LState.Status = TPlatStatus.Down);
  Assert.AreEqual(0, FWorld.Events.Count);
end;

procedure TTestThinkersPlatMachine.DovrebbePartireDalPavimentoDelSettoreInDoomEStrife;
var
  LState: TPlatState;
begin
  // a kind that sets no low position leaves the one that the game starts with
  FillChar(LState, SizeOf(LState), 0);
  FSector.FloorHeight := 40 * FRACUNIT;
  Configure(TPlatGame.Doom, TPlatKind.RaiseAndChange, LState, CreateTestRandom(0));
  Assert.AreEqual(40 * FRACUNIT, LState.Low);
  FillChar(LState, SizeOf(LState), 0);
  Configure(TPlatGame.Strife, TPlatKind.RaiseAndChange, LState, CreateTestRandom(0));
  Assert.AreEqual(40 * FRACUNIT, LState.Low);
end;

procedure TTestThinkersPlatMachine.DovrebbeLasciareLowComeEraInHeretic;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.Low := 777;
  FSector.FloorHeight := 40 * FRACUNIT;
  Configure(TPlatGame.Heretic, TPlatKind.RaiseAndChange, LState, CreateTestRandom(0));
  Assert.AreEqual(777, LState.Low);
end;

procedure TTestThinkersPlatMachine.DovrebbeCambiareImmagineESpecialDellaSalitaAlPiuVicino;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.Special := 9;
  Configure(TPlatGame.Doom, TPlatKind.RaiseToNearestAndChange, LState, CreateTestRandom(0));
  Assert.AreEqual(5, FSector.FloorPicture);
  Assert.AreEqual(0, FSector.Special);
  Assert.AreEqual(FRACUNIT div 2, LState.Speed);
  Assert.AreEqual(0, LState.Wait);
end;

procedure TTestThinkersPlatMachine.DovrebbeUsareUnSoloNumeroCasualeNelLaPiattaformaPerpetua;
var
  LState: TPlatState;
  LRandom: IGameRandom;
begin
  FillChar(LState, SizeOf(LState), 0);
  LRandom := CreateTestRandom(20);
  Configure(TPlatGame.Doom, TPlatKind.PerpetualRaise, LState, LRandom);
  Assert.AreEqual(21, LRandom.PlayIndex);
  FillChar(LState, SizeOf(LState), 0);
  LRandom := CreateTestRandom(20);
  Configure(TPlatGame.Doom, TPlatKind.DownWaitUpStay, LState, LRandom);
  Assert.AreEqual(20, LRandom.PlayIndex);
end;

procedure TTestThinkersPlatMachine.DovrebbeMettereIlToggleInStasiAllaFineDellaCorsa;
var
  LState: TPlatState;
  LMachine: IPlatMachine;
begin
  LMachine := CreateMachine(TPlatGame.Doom, CreateTestRandom(0));
  FillChar(LState, SizeOf(LState), 0);
  LMachine.Configure(FSector, TPlatKind.ToggleUpDown, 0, 0, LState);
  LState.Low := -FRACUNIT;
  LState.Speed := 8 * FRACUNIT;
  FWorld.Events.Clear;
  LMachine.Tick(nil, FSector, TPlatKind.ToggleUpDown, LState);
  Assert.IsTrue(LState.Status = TPlatStatus.InStasis);
  Assert.IsTrue(LState.OldStatus = TPlatStatus.Down);
  Assert.AreEqual(1, FWorld.Events.Count, 'only the move, no sound');
  Assert.AreEqual(0, FWorld.RemoveCount);
end;

procedure TTestThinkersPlatMachine.DovrebbeRimuovereLaSalitaIndipendenteAllaFineDellaSalita;
var
  LState: TPlatState;
  LMachine: IPlatMachine;
begin
  LMachine := CreateMachine(TPlatGame.Doom, CreateTestRandom(0));
  FillChar(LState, SizeOf(LState), 0);
  LMachine.Configure(FSector, TPlatKind.RaiseAndChange, 1, 8, LState);
  FWorld.LevelTime := 1;
  FWorld.Events.Clear;
  LMachine.Tick(nil, FSector, TPlatKind.RaiseAndChange, LState);
  Assert.AreEqual(0, FWorld.RemoveCount);
  LState.Speed := 100 * FRACUNIT;
  LMachine.Tick(nil, FSector, TPlatKind.RaiseAndChange, LState);
  Assert.AreEqual(1, FWorld.RemoveCount);
  Assert.IsTrue(LState.Status = TPlatStatus.Waiting);
end;

procedure TTestThinkersPlatMachine.DovrebbeRimuovereAlFondoSoloNelMotoreModerno;
var
  LState: TPlatState;
  LMachine: IPlatMachine;
begin
  LMachine := CreateMachine(TPlatGame.Doom, CreateTestRandom(0));
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Down;
  LState.Low := -FRACUNIT;
  LState.Speed := 8 * FRACUNIT;
  FWorld.ModernEngine := False;
  LMachine.Tick(nil, FSector, TPlatKind.RaiseAndChange, LState);
  Assert.AreEqual(0, FWorld.RemoveCount, 'old engine versions keep the platform');
  LState.Status := TPlatStatus.Down;
  FSector.FloorHeight := 0;
  FWorld.ModernEngine := True;
  LMachine.Tick(nil, FSector, TPlatKind.RaiseAndChange, LState);
  Assert.AreEqual(1, FWorld.RemoveCount);
end;

procedure TTestThinkersPlatMachine.DovrebbeRimuovereAlFondoSempreInStrife;
var
  LState: TPlatState;
  LMachine: IPlatMachine;
begin
  LMachine := CreateMachine(TPlatGame.Strife, CreateTestRandom(0));
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Down;
  LState.Low := -FRACUNIT;
  LState.Speed := 8 * FRACUNIT;
  FWorld.ModernEngine := False;
  LMachine.Tick(nil, FSector, TPlatKind.UpWaitDownStay, LState);
  Assert.AreEqual(1, FWorld.RemoveCount);
end;

procedure TTestThinkersPlatMachine.DovrebbeInvertireIlToggleRiattivatoSoloInDoom;
var
  LDoom, LStrife, LHeretic: IPlatMachine;
begin
  LDoom := CreateMachine(TPlatGame.Doom, CreateTestRandom(0));
  LStrife := CreateMachine(TPlatGame.Strife, CreateTestRandom(0));
  LHeretic := CreateMachine(TPlatGame.Heretic, CreateTestRandom(0));
  Assert.IsTrue(LDoom.WakeUpStatus(TPlatKind.ToggleUpDown, TPlatStatus.Up) = TPlatStatus.Down);
  Assert.IsTrue(LDoom.WakeUpStatus(TPlatKind.ToggleUpDown, TPlatStatus.Down) = TPlatStatus.Up);
  Assert.IsTrue(LDoom.WakeUpStatus(TPlatKind.PerpetualRaise, TPlatStatus.Up) = TPlatStatus.Up);
  Assert.IsTrue(LStrife.WakeUpStatus(TPlatKind.ToggleUpDown, TPlatStatus.Up) = TPlatStatus.Up,
    'the defect of Strife is kept');
  Assert.IsTrue(LHeretic.WakeUpStatus(TPlatKind.PerpetualRaise, TPlatStatus.Down) = TPlatStatus.Down);
  Assert.IsTrue(LDoom.IsToggle(TPlatKind.ToggleUpDown));
  Assert.IsFalse(LHeretic.IsToggle(TPlatKind.ToggleUpDown));
end;

procedure TTestThinkersPlatMachine.DovrebbeFermareEPortareInStasi;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Waiting;
  CreateMachine(TPlatGame.Doom, CreateTestRandom(0)).Pause(LState);
  Assert.IsTrue(LState.Status = TPlatStatus.InStasis);
  Assert.IsTrue(LState.OldStatus = TPlatStatus.Waiting);
end;

procedure TTestThinkersPlatMachine.DovrebbeFarScendereLaPiattaformaSeSchiacciataSenzaCrush;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Up;
  LState.High := 64 * FRACUNIT;
  LState.Speed := FRACUNIT;
  LState.Wait := 35;
  FWorld.BlockHeight := 0;
  CreateMachine(TPlatGame.Doom, CreateTestRandom(0)).Tick(nil, FSector, TPlatKind.DownWaitUpStay,
    LState);
  Assert.IsTrue(LState.Status = TPlatStatus.Down);
  Assert.AreEqual(35, LState.Count);
  Assert.AreEqual('sound start', FWorld.Events[1]);
end;

procedure TTestThinkersPlatMachine.DovrebbeSuonareLaPietraOgniOttoTic;
var
  LState: TPlatState;
  LMachine: IPlatMachine;
begin
  LMachine := CreateMachine(TPlatGame.Doom, CreateTestRandom(0));
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Up;
  LState.High := 64 * FRACUNIT;
  LState.Speed := FRACUNIT;
  FWorld.LevelTime := 8;
  LMachine.Tick(nil, FSector, TPlatKind.RaiseAndChange, LState);
  Assert.AreEqual('sound move', FWorld.Events[1]);
  FWorld.Events.Clear;
  FWorld.LevelTime := 9;
  LMachine.Tick(nil, FSector, TPlatKind.RaiseAndChange, LState);
  Assert.AreEqual(1, FWorld.Events.Count);
end;

procedure TTestThinkersPlatMachine.DovrebbeSollevareEccezioneSeUnServizioManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TPlatFactory.CreateMachine(TPlatGame.Doom, nil, FWorld, CreateTestRandom(0));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TPlatFactory.CreateMachine(TPlatGame.Doom, FWorld, nil, CreateTestRandom(0));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TPlatFactory.CreateMachine(TPlatGame.Doom, FWorld, FWorld, nil);
    end, EArgumentNilException);
end;

procedure TTestThinkersPlatMachine.CheckParity(AGame: TPlatGame; const AKinds: TPlatKinds);
var
  LKind: TPlatKind;
  LSeed, LTic: Integer;
  LOldWorld, LNewWorld: TFakePlatWorld;
  LOldSector, LNewSector: TFakePlatSector;
  LOldRandom, LNewRandom: IGameRandom;
  LOld: TOldPlat;
  LNew: TPlatState;
  LMachine: IPlatMachine;
  LWhere: string;
begin
  for LKind := Low(TPlatKind) to High(TPlatKind) do
  begin
    if not (LKind in AKinds) then
      Continue;
    for LSeed := 0 to 5 do
    begin
      LOldWorld := TFakePlatWorld.Create;
      LNewWorld := TFakePlatWorld.Create;
      try
        LOldSector := LOldWorld.AddSector(0, 128 * FRACUNIT);
        LNewSector := LNewWorld.AddSector(0, 128 * FRACUNIT);
        LOldSector.LowestSurrounding := -(16 + LSeed * 8) * FRACUNIT;
        LNewSector.LowestSurrounding := LOldSector.LowestSurrounding;
        LOldSector.HighestSurrounding := (40 + LSeed * 5) * FRACUNIT;
        LNewSector.HighestSurrounding := LOldSector.HighestSurrounding;
        // some platforms meet a block on the way up and are crushed
        if LSeed mod 2 = 1 then
        begin
          LOldWorld.BlockHeight := (20 + LSeed) * FRACUNIT;
          LNewWorld.BlockHeight := LOldWorld.BlockHeight;
        end;
        LOldWorld.ModernEngine := LSeed <> 3;
        LNewWorld.ModernEngine := LOldWorld.ModernEngine;
        LOldRandom := CreateTestRandom(LSeed * 37);
        LNewRandom := CreateTestRandom(LSeed * 37);
        LMachine := TPlatFactory.CreateMachine(AGame, LNewWorld, LNewWorld, LNewRandom);

        LOld := PresetPlat(LOldSector, LKind);
        if LKind = TPlatKind.GenericLift then
        begin
          // the generalized platforms are made by their own code: the state is given
          LOld.Status := TPlatStatus.Down;
          LOld.Low := -64 * FRACUNIT;
          LOld.High := 0;
          LOld.Speed := 2 * FRACUNIT;
          LOld.Wait := 70;
        end
        else
          case AGame of
            TPlatGame.Doom:
              OldDoomSetup(LOldWorld, LOldRandom, LOld, LOldSector, 5, 24);
            TPlatGame.Heretic:
              OldHereticSetup(LOldWorld, LOldRandom, LOld, LOldSector, 5, 24);
            TPlatGame.Strife:
              OldStrifeSetup(LOldWorld, LOldRandom, LOld, LOldSector, 5, 24);
          end;
        LNew := ToState(PresetPlat(LNewSector, LKind));
        if LKind = TPlatKind.GenericLift then
          LNew := ToState(LOld)
        else
          LMachine.Configure(LNewSector, LKind, 5, 24, LNew);

        LWhere := Format('game %d kind %d seed %d', [Ord(AGame), Ord(LKind), LSeed]);
        Assert.AreEqual(LOld.Speed, LNew.Speed, LWhere + ' setup speed');
        Assert.AreEqual(LOld.Low, LNew.Low, LWhere + ' setup low');
        Assert.AreEqual(LOld.High, LNew.High, LWhere + ' setup high');
        Assert.AreEqual(LOld.Wait, LNew.Wait, LWhere + ' setup wait');
        Assert.AreEqual(Ord(LOld.Status), Ord(LNew.Status), LWhere + ' setup status');
        Assert.AreEqual(LOld.Crush, LNew.Crush, LWhere + ' setup crush');
        Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, LWhere + ' setup random');
        Assert.AreEqual(LOldWorld.Events.Text, LNewWorld.Events.Text, LWhere + ' setup events');
        Assert.AreEqual(LOldSector.FloorPicture, LNewSector.FloorPicture, LWhere + ' picture');

        for LTic := 1 to 900 do
        begin
          LOldWorld.LevelTime := LTic;
          LNewWorld.LevelTime := LTic;
          if LTic = 300 then
          begin
            // stopped and woken up again
            LOld.OldStatus := LOld.Status;
            LOld.Status := TPlatStatus.InStasis;
            LMachine.Pause(LNew);
          end
          else if LTic = 340 then
          begin
            if AGame = TPlatGame.Doom then
              OldDoomWakeUp(LOld)
            else
              OldPlainWakeUp(LOld);
            if LNew.Status = TPlatStatus.InStasis then
              LNew.Status := LMachine.WakeUpStatus(LKind, LNew.OldStatus);
          end;
          case AGame of
            TPlatGame.Doom:
              OldDoomPlatRaise(LOldWorld, LOld);
            TPlatGame.Heretic:
              OldHereticPlatRaise(LOldWorld, LOld);
            TPlatGame.Strife:
              OldStrifePlatRaise(LOldWorld, LOld);
          end;
          LMachine.Tick(nil, LNewSector, LKind, LNew);
          LWhere := Format('game %d kind %d seed %d tic %d', [Ord(AGame), Ord(LKind), LSeed, LTic]);
          Assert.AreEqual(Ord(LOld.Status), Ord(LNew.Status), LWhere + ' status');
          Assert.AreEqual(Ord(LOld.OldStatus), Ord(LNew.OldStatus), LWhere + ' old status');
          Assert.AreEqual(LOld.Count, LNew.Count, LWhere + ' count');
          Assert.AreEqual(LOld.Crush, LNew.Crush, LWhere + ' crush');
          Assert.AreEqual(LOldSector.FloorHeight, LNewSector.FloorHeight, LWhere + ' floor');
          Assert.AreEqual(LOldWorld.Events.Count, LNewWorld.Events.Count, LWhere + ' events');
          Assert.AreEqual(LOldWorld.RemoveCount, LNewWorld.RemoveCount, LWhere + ' removals');
        end;
        Assert.AreEqual(LOldWorld.Events.Text, LNewWorld.Events.Text, LWhere + ' all events');
        Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, LWhere + ' random');
      finally
        // the machine holds the world through interfaces that do not count: let it go first
        LMachine := nil;
        LNewWorld.Free;
        LOldWorld.Free;
      end;
    end;
  end;
end;

procedure TTestThinkersPlatMachine.DovrebbeDareGliStessiRisultatiDelVecchioCodiceDoom;
begin
  CheckParity(TPlatGame.Doom, [TPlatKind.PerpetualRaise, TPlatKind.DownWaitUpStay,
    TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange, TPlatKind.BlazeDownWaitUpStay,
    TPlatKind.GenericLift, TPlatKind.ToggleUpDown]);
end;

procedure TTestThinkersPlatMachine.DovrebbeDareGliStessiRisultatiDelVecchioCodiceHeretic;
begin
  CheckParity(TPlatGame.Heretic, [TPlatKind.PerpetualRaise, TPlatKind.DownWaitUpStay,
    TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange, TPlatKind.BlazeDownWaitUpStay]);
end;

procedure TTestThinkersPlatMachine.DovrebbeDareGliStessiRisultatiDelVecchioCodiceStrife;
begin
  CheckParity(TPlatGame.Strife, [TPlatKind.PerpetualRaise, TPlatKind.DownWaitUpStay,
    TPlatKind.SlowDownWaitUpStay, TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange,
    TPlatKind.BlazeDownWaitUpStay, TPlatKind.UpWaitDownStay, TPlatKind.GenericLift,
    TPlatKind.ToggleUpDown]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersPlatMachine);

end.
