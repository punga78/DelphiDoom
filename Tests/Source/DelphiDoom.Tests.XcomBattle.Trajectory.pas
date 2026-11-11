{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the action, the     }
{  range of a throw and the reading of a trajectory                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.Trajectory;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.Trajectory,
  DelphiDoom.XcomBattle.ThrowRange;

type
  [TestFixture]
  [Category('xcom-battle')]
  TTestXcomTrajectory = class(TObject)
  strict private
    FPath: TList<TXcomPosition>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLimitareLIndiceAgliEstremiDalPrincipio;
    [Test]
    procedure DovrebbeContareDallaFineConLOffsetDelLascio;
    [Test]
    procedure DovrebbeRifiutareUnaTraiettoriaVuota;
  end;

  [TestFixture]
  [Category('xcom-battle')]
  TTestXcomThrowRange = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnaDistanzaPiuLungaConPiuForza;
    [Test]
    procedure DovrebbeDareUnaDistanzaPiuCortaConUnOggettoPiuPesante;
    [Test]
    procedure DovrebbeRifiutareUnaForzaZero;
    [Test]
    procedure DovrebbeFermarsiAQuattromilaVoxel;
  end;

  [TestFixture]
  [Category('xcom-battle')]
  TTestXcomBattleAction = class(TObject)
  public
    [Test]
    procedure DovrebbePartireSenzaAzioneNeBersaglio;
    [Test]
    procedure DovrebbeCopiareTuttiICampiConAssign;
  end;

implementation

{ TTestXcomTrajectory }

procedure TTestXcomTrajectory.Setup;
var
  LIndex: Integer;
begin
  FPath := TList<TXcomPosition>.Create;
  for LIndex := 0 to 4 do
    FPath.Add(TXcomPosition.Make(LIndex, LIndex * 2, LIndex * 3));
end;

procedure TTestXcomTrajectory.TearDown;
begin
  FPath.Free;
end;

procedure TTestXcomTrajectory.DovrebbeLimitareLIndiceAgliEstremiDalPrincipio;
begin
  Assert.IsTrue(TXcomTrajectory.PositionFromStart(FPath, -7) = FPath[0]);
  Assert.IsTrue(TXcomTrajectory.PositionFromStart(FPath, 2) = FPath[2]);
  Assert.IsTrue(TXcomTrajectory.PositionFromStart(FPath, 99) = FPath[4]);
end;

procedure TTestXcomTrajectory.DovrebbeContareDallaFineConLOffsetDelLascio;
begin
  Assert.IsTrue(TXcomTrajectory.PositionFromEnd(FPath, 0) = FPath[4]);
  Assert.IsTrue(TXcomTrajectory.PositionFromEnd(FPath, ITEM_DROP_VOXEL_OFFSET) = FPath[2]);
  Assert.IsTrue(TXcomTrajectory.PositionFromEnd(FPath, -40) = FPath[0]);
end;

procedure TTestXcomTrajectory.DovrebbeRifiutareUnaTraiettoriaVuota;
begin
  FPath.Clear;
  Assert.WillRaise(
    procedure
    begin
      TXcomTrajectory.PositionFromStart(FPath, 0);
    end, EXcomBattleException);
end;

{ TTestXcomThrowRange }

procedure TTestXcomThrowRange.DovrebbeDareUnaDistanzaPiuLungaConPiuForza;
begin
  Assert.IsTrue(TXcomThrowRange.MaxThrowDistance(3, 60, 0) > TXcomThrowRange.MaxThrowDistance(3, 20, 0));
end;

procedure TTestXcomThrowRange.DovrebbeDareUnaDistanzaPiuCortaConUnOggettoPiuPesante;
begin
  Assert.IsTrue(TXcomThrowRange.MaxThrowDistance(30, 40, 0) < TXcomThrowRange.MaxThrowDistance(3, 40, 0));
end;

procedure TTestXcomThrowRange.DovrebbeRifiutareUnaForzaZero;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomThrowRange.MaxThrowDistance(3, 0, 0);
    end, EXcomBattleException);
end;

procedure TTestXcomThrowRange.DovrebbeFermarsiAQuattromilaVoxel;
begin
  // a weight of 0 never loses the lift: the loop of the C++ ends at 4000 "just in case"
  Assert.AreEqual(4000, TXcomThrowRange.MaxThrowDistance(0, 50, 100000));
end;

{ TTestXcomBattleAction }

procedure TTestXcomBattleAction.DovrebbePartireSenzaAzioneNeBersaglio;
var
  LAction: TXcomBattleAction;
begin
  LAction := TXcomBattleAction.Create;
  try
    Assert.AreEqual(BA_NONE, LAction.ActionType);
    Assert.IsNull(LAction.Actor);
    Assert.AreEqual(-1, LAction.CameraPosition.Z);
    Assert.AreEqual(-1, LAction.FinalFacing);
    Assert.AreEqual(0, LAction.Waypoints.Count);
  finally
    LAction.Free;
  end;
end;

procedure TTestXcomBattleAction.DovrebbeCopiareTuttiICampiConAssign;
var
  LSource: TXcomBattleAction;
  LCopy: TXcomBattleAction;
begin
  LSource := TXcomBattleAction.Create;
  LCopy := TXcomBattleAction.Create;
  try
    LSource.ActionType := BA_LAUNCH;
    LSource.Target := TXcomPosition.Make(3, 4, 1);
    LSource.TimeUnits := 17;
    LSource.ResultText := 'STR_NO_LINE_OF_FIRE';
    LSource.AutoShotCounter := 2;
    LSource.Waypoints.Add(TXcomPosition.Make(1, 1, 0));
    LSource.Waypoints.Add(TXcomPosition.Make(2, 2, 0));
    LCopy.Waypoints.Add(TXcomPosition.Make(9, 9, 9));
    LCopy.Assign(LSource);
    Assert.AreEqual(BA_LAUNCH, LCopy.ActionType);
    Assert.IsTrue(LCopy.Target = LSource.Target);
    Assert.AreEqual(17, LCopy.TimeUnits);
    Assert.AreEqual('STR_NO_LINE_OF_FIRE', LCopy.ResultText);
    Assert.AreEqual(2, LCopy.AutoShotCounter);
    Assert.AreEqual(2, LCopy.Waypoints.Count);
    LSource.Waypoints.Clear;
    Assert.AreEqual(2, LCopy.Waypoints.Count, 'La copia ha una lista sua');
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomTrajectory);
  TDUnitX.RegisterTestFixture(TTestXcomThrowRange);
  TDUnitX.RegisterTestFixture(TTestXcomBattleAction);

end.
