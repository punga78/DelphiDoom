{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scripted platforms                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlatUdmfMachine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Platform.Types, DelphiDoom.Thinkers.Platform.Intf,
  DelphiDoom.Tests.Thinkers.PlatFakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersPlatUdmfMachine = class(TObject)
  private
    FWorld: TFakePlatWorld;
    FSector: TFakePlatSector;
    function CreateMachine(const ARandom: IGameRandom): IUdmfPlatMachine;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLaVelocitaInOttaviDiUnita;
    [Test]
    procedure DovrebbeUsareOttoUnitaDiLabbroSeNonLoDice;
    [Test]
    procedure DovrebbeUsareLaLabbroDellArgomento;
    [Test]
    procedure DovrebbeScendereDiUnValoreDato;
    [Test]
    procedure DovrebbeSalireDiUnValoreDato;
    [Test]
    procedure DovrebbeSalireAlPavimentoPiuVicino;
    [Test]
    procedure DovrebbeNonScendereSopraIlPavimento;
    [Test]
    procedure DovrebbeUsareUnNumeroCasualeSoloNellePerpetue;
    [Test]
    procedure DovrebbeAnnunciareLAvvio;
    [Test]
    procedure DovrebbeSuonareDopoAverRimossoInSalita;
    [Test]
    procedure DovrebbeSuonareDopoAverRimossoInDiscesaPrimaDelSuono;
    [Test]
    procedure DovrebbeRipartireQuandoIlConteggioFinisce;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnServizioManca;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Thinkers.Platform.Factory, DelphiDoom.Tests.Thinkers.Fakes,
  DelphiDoom.Tests.Thinkers.OldPlats;

const
  FRACUNIT = 65536;

{ TTestThinkersPlatUdmfMachine }

procedure TTestThinkersPlatUdmfMachine.Setup;
begin
  FWorld := TFakePlatWorld.Create;
  FSector := FWorld.AddSector(0, 128 * FRACUNIT);
end;

procedure TTestThinkersPlatUdmfMachine.TearDown;
begin
  FreeAndNil(FWorld);
end;

function TTestThinkersPlatUdmfMachine.CreateMachine(const ARandom: IGameRandom): IUdmfPlatMachine;
begin
  Result := TPlatFactory.CreateUdmfMachine(FWorld, FWorld, ARandom);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeDareLaVelocitaInOttaviDiUnita;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  CreateMachine(CreateTestRandom(0)).Configure(FSector, TUdmfPlatKind.UpWaitDownStay, 7, 16, 70, 0,
    LState);
  Assert.AreEqual(2 * FRACUNIT, LState.Speed);
  Assert.AreEqual(70, LState.Wait);
  Assert.AreEqual(7, LState.Tag);
  Assert.IsFalse(LState.Crush);
  Assert.IsTrue(LState.Status = TPlatStatus.Up);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeUsareOttoUnitaDiLabbroSeNonLoDice;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.LowestSurrounding := -40 * FRACUNIT;
  CreateMachine(CreateTestRandom(0)).Configure(FSector, TUdmfPlatKind.DownWaitUpStay, 1, 8, 35, 99,
    LState);
  Assert.AreEqual(-32 * FRACUNIT, LState.Low);
  Assert.AreEqual(0, LState.High);
  Assert.IsTrue(LState.Status = TPlatStatus.Down);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeUsareLaLabbroDellArgomento;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.LowestSurrounding := -40 * FRACUNIT;
  CreateMachine(CreateTestRandom(0)).Configure(FSector, TUdmfPlatKind.DownWaitUpStayLip, 1, 8, 35,
    5, LState);
  Assert.AreEqual(-35 * FRACUNIT, LState.Low);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeScendereDiUnValoreDato;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.FloorHeight := 100 * FRACUNIT;
  CreateMachine(CreateTestRandom(0)).Configure(FSector, TUdmfPlatKind.DownByValueWaitUpStay, 1, 8,
    35, 3, LState);
  Assert.AreEqual(76 * FRACUNIT, LState.Low);
  Assert.AreEqual(100 * FRACUNIT, LState.High);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeSalireDiUnValoreDato;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  CreateMachine(CreateTestRandom(0)).Configure(FSector, TUdmfPlatKind.UpByValueWaitDownStay, 1, 8,
    35, 3, LState);
  Assert.AreEqual(24 * FRACUNIT, LState.High);
  Assert.AreEqual(0, LState.Low);
  Assert.IsTrue(LState.Status = TPlatStatus.Up);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeSalireAlPavimentoPiuVicino;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.NextHigher := 16 * FRACUNIT;
  CreateMachine(CreateTestRandom(0)).Configure(FSector, TUdmfPlatKind.UpNearestWaitDownStay, 1, 8,
    35, 0, LState);
  Assert.AreEqual(16 * FRACUNIT, LState.High);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeNonScendereSopraIlPavimento;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  FSector.LowestSurrounding := 50 * FRACUNIT;
  CreateMachine(CreateTestRandom(0)).Configure(FSector, TUdmfPlatKind.DownWaitUpStay, 1, 8, 35, 0,
    LState);
  Assert.AreEqual(0, LState.Low, 'the low position is at most the floor');
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeUsareUnNumeroCasualeSoloNellePerpetue;
var
  LState: TPlatState;
  LRandom: IGameRandom;
begin
  FillChar(LState, SizeOf(LState), 0);
  LRandom := CreateTestRandom(10);
  CreateMachine(LRandom).Configure(FSector, TUdmfPlatKind.PerpetualRaise, 1, 8, 35, 0, LState);
  Assert.AreEqual(11, LRandom.PlayIndex);
  LRandom := CreateTestRandom(10);
  CreateMachine(LRandom).Configure(FSector, TUdmfPlatKind.PerpetualRaiseLip, 1, 8, 35, 4, LState);
  Assert.AreEqual(11, LRandom.PlayIndex);
  LRandom := CreateTestRandom(10);
  CreateMachine(LRandom).Configure(FSector, TUdmfPlatKind.UpWaitDownStay, 1, 8, 35, 0, LState);
  Assert.AreEqual(10, LRandom.PlayIndex);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeAnnunciareLAvvio;
begin
  CreateMachine(CreateTestRandom(0)).AnnounceStart(FSector);
  Assert.AreEqual(1, FWorld.Events.Count);
  Assert.AreEqual('sound start', FWorld.Events[0]);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeSuonareDopoAverRimossoInSalita;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Up;
  LState.High := FRACUNIT;
  LState.Speed := 8 * FRACUNIT;
  CreateMachine(CreateTestRandom(0)).Tick(nil, FSector, TUdmfPlatKind.DownWaitUpStay, LState);
  Assert.AreEqual('sound stop', FWorld.Events[1]);
  Assert.AreEqual('remove', FWorld.Events[2]);
  Assert.IsTrue(LState.Status = TPlatStatus.Waiting);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeSuonareDopoAverRimossoInDiscesaPrimaDelSuono;
var
  LState: TPlatState;
begin
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Down;
  LState.Low := -FRACUNIT;
  LState.Speed := 8 * FRACUNIT;
  CreateMachine(CreateTestRandom(0)).Tick(nil, FSector, TUdmfPlatKind.UpWaitDownStay, LState);
  Assert.AreEqual('remove', FWorld.Events[1]);
  Assert.AreEqual('sound stop', FWorld.Events[2]);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeRipartireQuandoIlConteggioFinisce;
var
  LState: TPlatState;
  LMachine: IUdmfPlatMachine;
begin
  LMachine := CreateMachine(CreateTestRandom(0));
  FillChar(LState, SizeOf(LState), 0);
  LState.Status := TPlatStatus.Waiting;
  LState.Count := 2;
  LState.Low := 0;
  LMachine.Tick(nil, FSector, TUdmfPlatKind.PerpetualRaise, LState);
  Assert.IsTrue(LState.Status = TPlatStatus.Waiting);
  Assert.AreEqual(1, LState.Count);
  LMachine.Tick(nil, FSector, TUdmfPlatKind.PerpetualRaise, LState);
  // the floor is at the low position: it goes up
  Assert.IsTrue(LState.Status = TPlatStatus.Up);
  Assert.AreEqual('sound start', FWorld.Events[0]);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeSollevareEccezioneSeUnServizioManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TPlatFactory.CreateUdmfMachine(nil, FWorld, CreateTestRandom(0));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TPlatFactory.CreateUdmfMachine(FWorld, nil, CreateTestRandom(0));
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TPlatFactory.CreateUdmfMachine(FWorld, FWorld, nil);
    end, EArgumentNilException);
end;

procedure TTestThinkersPlatUdmfMachine.DovrebbeDareGliStessiRisultatiDelVecchioCodice;
var
  LKind: TUdmfPlatKind;
  LSeed, LTic: Integer;
  LOldWorld, LNewWorld: TFakePlatWorld;
  LOldSector, LNewSector: TFakePlatSector;
  LOldRandom, LNewRandom: IGameRandom;
  LOld: TOldPlat;
  LNew: TPlatState;
  LMachine: IUdmfPlatMachine;
  LArgs: array[0..3] of Integer;
  LWhere: string;
begin
  for LKind := Low(TUdmfPlatKind) to High(TUdmfPlatKind) do
    for LSeed := 0 to 5 do
    begin
      LOldWorld := TFakePlatWorld.Create;
      LNewWorld := TFakePlatWorld.Create;
      try
        LOldSector := LOldWorld.AddSector(8 * FRACUNIT, 128 * FRACUNIT);
        LNewSector := LNewWorld.AddSector(8 * FRACUNIT, 128 * FRACUNIT);
        LOldSector.LowestSurrounding := -(16 + LSeed * 8) * FRACUNIT;
        LNewSector.LowestSurrounding := LOldSector.LowestSurrounding;
        LOldSector.HighestSurrounding := (40 + LSeed * 5) * FRACUNIT;
        LNewSector.HighestSurrounding := LOldSector.HighestSurrounding;
        LOldSector.NextHigher := (20 + LSeed) * FRACUNIT;
        LNewSector.NextHigher := LOldSector.NextHigher;
        if LSeed mod 2 = 1 then
        begin
          LOldWorld.BlockHeight := (30 + LSeed) * FRACUNIT;
          LNewWorld.BlockHeight := LOldWorld.BlockHeight;
        end;
        LOldRandom := CreateTestRandom(LSeed * 29);
        LNewRandom := CreateTestRandom(LSeed * 29);
        LMachine := TPlatFactory.CreateUdmfMachine(LNewWorld, LNewWorld, LNewRandom);

        LArgs[0] := 10 + LSeed;
        LArgs[1] := 4 + LSeed * 4;
        LArgs[2] := 20 + LSeed * 10;
        LArgs[3] := LSeed * 2;

        FillChar(LOld, SizeOf(LOld), 0);
        LOld.Sector := LOldSector;
        LOld.UdmfKind := LKind;
        LOld.Low := 12345;
        LOld.High := 23456;
        LOld.Status := TPlatStatus.Waiting;
        OldUdmfSetup(LOldWorld, LOldRandom, LOld, LOldSector, LArgs);
        FillChar(LNew, SizeOf(LNew), 0);
        LNew.Low := 12345;
        LNew.High := 23456;
        LNew.Status := TPlatStatus.Waiting;
        LMachine.Configure(LNewSector, LKind, LArgs[0], LArgs[1], LArgs[2], LArgs[3], LNew);

        LWhere := Format('kind %d seed %d', [Ord(LKind), LSeed]);
        Assert.AreEqual(LOld.Speed, LNew.Speed, LWhere + ' speed');
        Assert.AreEqual(LOld.Low, LNew.Low, LWhere + ' low');
        Assert.AreEqual(LOld.High, LNew.High, LWhere + ' high');
        Assert.AreEqual(LOld.Wait, LNew.Wait, LWhere + ' wait');
        Assert.AreEqual(LOld.Tag, LNew.Tag, LWhere + ' tag');
        Assert.AreEqual(Ord(LOld.Status), Ord(LNew.Status), LWhere + ' status');
        Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, LWhere + ' random');

        for LTic := 1 to 900 do
        begin
          OldUdmfPlatRaise(LOldWorld, LOld);
          LMachine.Tick(nil, LNewSector, LKind, LNew);
          LWhere := Format('kind %d seed %d tic %d', [Ord(LKind), LSeed, LTic]);
          Assert.AreEqual(Ord(LOld.Status), Ord(LNew.Status), LWhere + ' status');
          Assert.AreEqual(LOld.Count, LNew.Count, LWhere + ' count');
          Assert.AreEqual(LOldSector.FloorHeight, LNewSector.FloorHeight, LWhere + ' floor');
          Assert.AreEqual(LOldWorld.Events.Count, LNewWorld.Events.Count, LWhere + ' events');
          Assert.AreEqual(LOldWorld.RemoveCount, LNewWorld.RemoveCount, LWhere + ' removals');
        end;
        Assert.AreEqual(LOldWorld.Events.Text, LNewWorld.Events.Text, LWhere + ' all events');
      finally
        // the machine holds the world through interfaces that do not count: let it go first
        LMachine := nil;
        LNewWorld.Free;
        LOldWorld.Free;
      end;
    end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersPlatUdmfMachine);

end.
