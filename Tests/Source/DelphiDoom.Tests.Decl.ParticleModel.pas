{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TParticleModelBuilder (idRenderModelPrt) (DUnitX)      }
{                                                                              }
{  The numbers are worked out from the text of Model_prt.cpp (no C++ oracle:   }
{  the model needs the renderer); CreateParticle has its own parity.           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.ParticleModel;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Particle.Types, DelphiDoom.Decl.Particle.Intf,
  DelphiDoom.Decl.Particle.ModelBuilder, DelphiDoom.Tests.Decl.Effects;

type
  [TestFixture]
  [Category('Decl')]
  TTestParticleModelBuilder = class
  strict private
    FKit: TEffectsKit;
    FBuilder: TParticleModelBuilder;
    function Count(const AName: AnsiString; const ATime: Integer; const AStopTime: Single = 0): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeContareLeParticelleVive;
    [Test]
    procedure DovrebbeFermareLeParticelleDopoIlTempoDiStop;
    [Test]
    procedure DovrebbeFarGirareLeParticelleUnSoloCiclo;
    [Test]
    procedure DovrebbeCostruireGliIndiciDeiQuad;
    [Test]
    procedure DovrebbeDareUnaSuperficiePerStageConMateriale;
    [Test]
    procedure DovrebbeNonDareNullaConSkipParticles;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoAlloStessoTempo;
  end;

implementation

uses
  DelphiDoom.Decl.Particle.Generator;

const
  PARTICLES =
    'particle loop'#10'{'#10#9'{'#10#9#9'material textures/spark'#10#9#9'count 4'#10#9#9'time 1'#10#9#9'cycles 0'#10 +
    #9#9'bunching 1'#10#9#9'fadeIn 0'#10#9#9'fadeOut 0'#10#9'}'#10'}'#10 +
    'particle once'#10'{'#10#9'{'#10#9#9'material textures/spark'#10#9#9'count 4'#10#9#9'time 1'#10#9#9'cycles 1'#10 +
    #9#9'bunching 1'#10#9#9'fadeIn 0'#10#9#9'fadeOut 0'#10#9'}'#10'}'#10 +
    'particle two'#10'{'#10#9'{'#10#9#9'material textures/a'#10#9#9'count 2'#10#9#9'time 1'#10#9#9'fadeIn 0'#10#9#9'fadeOut 0'#10#9'}'#10 +
    #9'{'#10#9#9'material textures/b'#10#9#9'count 3'#10#9#9'time 2'#10#9#9'fadeIn 0'#10#9#9'fadeOut 0'#10#9'}'#10'}'#10;

{ TTestParticleModelBuilder }

procedure TTestParticleModelBuilder.Setup;
begin
  FKit := TEffectsKit.Create(PARTICLES, '');
  FBuilder := TParticleModelBuilder.Create(TParticleGenerator.Create);
end;

procedure TTestParticleModelBuilder.TearDown;
begin
  FBuilder.Free;
  FKit.Free;
end;

function TTestParticleModelBuilder.Count(const AName: AnsiString; const ATime: Integer; const AStopTime: Single): Integer;
var
  LEntity: TParticleEntity;
  LSurfaces: TArray<TParticleSurface>;
begin
  LEntity := TParticleEntity.Identity;
  LEntity.ShaderParms[SHADERPARM_PARTICLE_STOPTIME] := AStopTime;
  LSurfaces := FBuilder.Instantiate(FKit.Particle(AName), ATime, LEntity, TParticleView.Identity);
  Result := Length(LSurfaces[0].Verts);
end;

procedure TTestParticleModelBuilder.DovrebbeContareLeParticelleVive;
begin
  // the particle i is born at 250 * i ms: at 0 only the first, at 600 the first three, at 1000 all
  Assert.AreEqual<Integer>(4, Count('loop', 0));
  Assert.AreEqual<Integer>(12, Count('loop', 600));
  Assert.AreEqual<Integer>(16, Count('loop', 1000));
end;

procedure TTestParticleModelBuilder.DovrebbeFermareLeParticelleDopoIlTempoDiStop;
begin
  // stop at 0.5 s: at 600 the particle at 100 ms of its life (time - life = 500) is not made
  Assert.AreEqual<Integer>(8, Count('loop', 600, 0.5));
end;

procedure TTestParticleModelBuilder.DovrebbeFarGirareLeParticelleUnSoloCiclo;
begin
  Assert.AreEqual<Integer>(12, Count('once', 1000));
  Assert.AreEqual<Integer>(0, Count('once', 5000));
end;

procedure TTestParticleModelBuilder.DovrebbeCostruireGliIndiciDeiQuad;
var
  LSurfaces: TArray<TParticleSurface>;
begin
  LSurfaces := FBuilder.Instantiate(FKit.Particle('loop'), 600, TParticleEntity.Identity, TParticleView.Identity);
  Assert.AreEqual<Integer>(18, Length(LSurfaces[0].Indexes));
  Assert.AreEqual<Integer>(0, LSurfaces[0].Indexes[0]);
  Assert.AreEqual<Integer>(2, LSurfaces[0].Indexes[1]);
  Assert.AreEqual<Integer>(3, LSurfaces[0].Indexes[2]);
  Assert.AreEqual<Integer>(0, LSurfaces[0].Indexes[3]);
  Assert.AreEqual<Integer>(3, LSurfaces[0].Indexes[4]);
  Assert.AreEqual<Integer>(1, LSurfaces[0].Indexes[5]);
  Assert.AreEqual<Integer>(4, LSurfaces[0].Indexes[6]);
end;

procedure TTestParticleModelBuilder.DovrebbeDareUnaSuperficiePerStageConMateriale;
var
  LSurfaces: TArray<TParticleSurface>;
begin
  LSurfaces := FBuilder.Instantiate(FKit.Particle('two'), 500, TParticleEntity.Identity, TParticleView.Identity);
  Assert.AreEqual<Integer>(2, Length(LSurfaces));
  Assert.AreEqual('textures/a', string(LSurfaces[0].MaterialName));
  Assert.AreEqual('textures/b', string(LSurfaces[1].MaterialName));
  Assert.AreEqual<Integer>(1, LSurfaces[1].StageNum);
end;

procedure TTestParticleModelBuilder.DovrebbeNonDareNullaConSkipParticles;
begin
  FBuilder.SkipParticles := True;
  Assert.AreEqual<Integer>(0, Length(FBuilder.Instantiate(FKit.Particle('loop'), 600, TParticleEntity.Identity,
    TParticleView.Identity)));
end;

procedure TTestParticleModelBuilder.DovrebbeDareLoStessoRisultatoAlloStessoTempo;
var
  LFirst, LSecond: TArray<TParticleSurface>;
  LIndex: Integer;
begin
  LFirst := FBuilder.Instantiate(FKit.Particle('loop'), 700, TParticleEntity.Identity, TParticleView.Identity);
  LSecond := FBuilder.Instantiate(FKit.Particle('loop'), 700, TParticleEntity.Identity, TParticleView.Identity);
  Assert.AreEqual<Integer>(Length(LFirst[0].Verts), Length(LSecond[0].Verts));
  for LIndex := 0 to High(LFirst[0].Verts) do
    Assert.AreEqual(LFirst[0].Verts[LIndex].Xyz.X, LSecond[0].Verts[LIndex].Xyz.X, 0.0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestParticleModelBuilder);

end.
