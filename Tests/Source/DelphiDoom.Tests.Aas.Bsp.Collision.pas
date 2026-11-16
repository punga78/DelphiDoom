{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the BSP of the bots on the collision  }
{  model of IdTech4\Collision (the synthetic map q3world0.bsp)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Bsp.Collision;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DUnitX.Exceptions, DelphiDoom.MathCore.Types, DelphiDoom.Collision.Q3.Intf,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Bsp.Intf;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasCollisionAdapters = class
  strict private
    FModel: IQ3CollisionModel;
    FWorld: IAasBspWorld;
    FModels: IAasBspModels;
    FMins, FMaxs: TQ3Vec3;
    function Center: TQ3Vec3;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareIlContenutoDiUnPuntoComeIlModello;
    [Test]
    procedure DovrebbeFareLaTraceDelMondoConEConoSenzaScatola;
    [Test]
    procedure DovrebbeDareLaStringaDelleEntitaDelModello;
    [Test]
    procedure DovrebbeDareLeDimensioniDelModelloELaRaggioSeRuotato;
    [Test]
    procedure DovrebbeVedereUnPuntoDaSeStesso;
    [Test]
    procedure DovrebbeNonCollidereConUnEntita;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Collision.Q3.Factory, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.Move.CollisionWorld, DelphiDoom.Aas.Bsp.CollisionModels;

function V(const AX, AY, AZ: Single): TVec3;
begin
  Result[0] := AX;
  Result[1] := AY;
  Result[2] := AZ;
end;

{ TTestAasCollisionAdapters }

procedure TTestAasCollisionAdapters.Setup;
var
  LPath: string;
  LHandle: Integer;
begin
  LPath := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Collision\q3world0.bsp');
  if not TFile.Exists(LPath) then
    raise ETestIgnored.Create('q3world0.bsp non c''e'': prova ignorata');
  FModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, TFile.ReadAllBytes(LPath), 'test.bsp',
    TQ3CollisionFactory.CreatePatchBuilder);
  FWorld := TAasCollisionWorld.Create(FModel);
  FModels := TAasCollisionModels.Create(FModel);
  LHandle := FModel.InlineModel(0);
  FModel.ModelBounds(LHandle, FMins, FMaxs);
end;

procedure TTestAasCollisionAdapters.TearDown;
begin
  FModels := nil;
  FWorld := nil;
  FModel := nil;
end;

function TTestAasCollisionAdapters.Center: TQ3Vec3;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    Result[LIndex] := (FMins[LIndex] + FMaxs[LIndex]) / 2;
end;

procedure TTestAasCollisionAdapters.DovrebbeDareIlContenutoDiUnPuntoComeIlModello;
var
  LPoint: TQ3Vec3;
begin
  LPoint := Center;
  Assert.AreEqual(FModel.PointContents(LPoint, 0), FWorld.PointContents(TVec3(LPoint)));
  LPoint[0] := FMaxs[0] + 5000;
  Assert.AreEqual(FModel.PointContents(LPoint, 0), FWorld.PointContents(TVec3(LPoint)));
end;

procedure TTestAasCollisionAdapters.DovrebbeFareLaTraceDelMondoConEConoSenzaScatola;
var
  LStart, LEnd, LZero: TQ3Vec3;
  LMine: TAasBspTrace;
  LTheirs: TQ3Trace;
  LBoxMins, LBoxMaxs: TVec3;
begin
  LStart := Center;
  LEnd := LStart;
  LEnd[2] := FMins[2] - 100;
  FillChar(LZero, SizeOf(LZero), 0);
  // a point: no box
  LMine := FWorld.Trace(TVec3(LStart), nil, nil, TVec3(LEnd), -1, -1);
  LTheirs := FModel.BoxTrace(LStart, LEnd, LZero, LZero, 0, -1, False);
  Assert.AreEqual(Double(LTheirs.Fraction), Double(LMine.Fraction), 0.0);
  Assert.AreEqual(LTheirs.AllSolid, LMine.AllSolid);
  Assert.AreEqual(LTheirs.StartSolid, LMine.StartSolid);
  Assert.AreEqual(Double(LTheirs.EndPos[2]), Double(LMine.EndPos[2]), 0.0);
  Assert.AreEqual(LTheirs.Contents, LMine.Contents);
  // a box
  LBoxMins := V(-8, -8, -8);
  LBoxMaxs := V(8, 8, 8);
  LMine := FWorld.Trace(TVec3(LStart), @LBoxMins, @LBoxMaxs, TVec3(LEnd), -1, -1);
  LTheirs := FModel.BoxTrace(LStart, LEnd, TQ3Vec3(LBoxMins), TQ3Vec3(LBoxMaxs), 0, -1, False);
  Assert.AreEqual(Double(LTheirs.Fraction), Double(LMine.Fraction), 0.0);
  Assert.AreEqual(LTheirs.EntityNum, LMine.EntityNum);
end;

procedure TTestAasCollisionAdapters.DovrebbeDareLaStringaDelleEntitaDelModello;
begin
  Assert.AreEqual(string(FModel.EntityString), string(FModels.EntityData));
end;

procedure TTestAasCollisionAdapters.DovrebbeDareLeDimensioniDelModelloELaRaggioSeRuotato;
var
  LMins, LMaxs, LOrigin: TVec3;
begin
  FModels.ModelMinsMaxsOrigin(0, V(0, 0, 0), LMins, LMaxs, LOrigin);
  Assert.AreEqual(Double(FMins[0]), Double(LMins[0]), 0.0);
  Assert.AreEqual(Double(FMaxs[2]), Double(LMaxs[2]), 0.0);
  Assert.AreEqual(Double(0), Double(LOrigin[1]), 0.0);
  // rotated: the box is a cube of the radius
  FModels.ModelMinsMaxsOrigin(0, V(0, 45, 0), LMins, LMaxs, LOrigin);
  Assert.AreEqual(Double(-LMaxs[0]), Double(LMins[0]), 0.0);
  Assert.AreEqual(Double(LMaxs[0]), Double(LMaxs[1]), 0.0);
  Assert.AreEqual(Double(LMaxs[1]), Double(LMaxs[2]), 0.0);
  Assert.IsTrue(LMaxs[0] >= FMaxs[0]);
end;

procedure TTestAasCollisionAdapters.DovrebbeVedereUnPuntoDaSeStesso;
var
  LPoint: TQ3Vec3;
  LPass, LLeaf, LCluster: Integer;
  LMask: TBytes;
  LExpected: Boolean;
begin
  for LPass := 0 to 1 do
  begin
    LPoint := Center;
    if LPass = 1 then
      LPoint[0] := FMaxs[0] + 5000;
    LLeaf := FModel.PointLeafnum(LPoint);
    LCluster := FModel.LeafCluster(LLeaf);
    LMask := FModel.ClusterPVS(LCluster);
    LExpected := FModel.AreasConnected(FModel.LeafArea(LLeaf), FModel.LeafArea(LLeaf));
    if (Length(LMask) > 0) and (LCluster >= 0) and ((LMask[LCluster shr 3] and (1 shl (LCluster and 7))) = 0) then
      LExpected := False;
    Assert.AreEqual(LExpected, FModels.InPVS(TVec3(LPoint), TVec3(LPoint)));
  end;
end;

procedure TTestAasCollisionAdapters.DovrebbeNonCollidereConUnEntita;
var
  LTrace: TAasBspTrace;
begin
  LTrace := FModels.EntityTrace(V(0, 0, 0), nil, nil, V(10, 20, 30), 5, -1);
  Assert.AreEqual(Double(1), Double(LTrace.Fraction), 0.0);
  Assert.AreEqual(Double(30), Double(LTrace.EndPos[2]), 0.0);
  Assert.IsFalse(LTrace.StartSolid);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasCollisionAdapters);

end.
