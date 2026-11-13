{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the particle and fx declarations                       }
{                                                                              }
{  Through the real manager over files in memory, and the classes alone for    }
{  the calculation of the particles.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Effects;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Particle.Types,
  DelphiDoom.Decl.Particle.Intf, DelphiDoom.Decl.Fx.Intf, DelphiDoom.Tests.Decl.Support;

type
  /// <summary>The manager with the standard types and the folders of the game that read particles and effects</summary>
  TEffectsKit = class
  strict private
    FKit: TDeclKit;
  public
    constructor Create(const AParticles, AEffects: AnsiString);
    destructor Destroy; override;
    function Particle(const AName: AnsiString): IDeclParticle;
    function Fx(const AName: AnsiString): IDeclFx;
    property Kit: TDeclKit read FKit;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclParticle = class
  strict private
    FEffects: TEffectsKit;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereLeParticelleDalGestore;
    [Test]
    procedure DovrebbeDareLeDimensioniDelleParticelle;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeManca;
    [Test]
    procedure DovrebbeFarFallireUnoStageFuoriIntervallo;
    [Test]
    procedure DovrebbeRiscrivereIlTestoComeLEditor;
    [Test]
    procedure DovrebbeRileggereIlTestoRiscritto;
    [Test]
    procedure DovrebbeNonScrivereLaFrazioneDelleSfere;
    [Test]
    procedure DovrebbeSostituireIlFileConSave;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleDelleParole;
    [Test]
    procedure DovrebbeScrivereTuttiICampiDiUnoStage;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestParticleGenerator = class
  strict private
    FLog: IInterface;
    FLogObject: TStringList;
    function Stage: TParticleStage;
    function Generator: IParticleGenerator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeValutareUnParametroLineare;
    [Test]
    procedure DovrebbeIntegrareUnParametroLineare;
    [Test]
    procedure DovrebbeDireCheUnaTabellaNonSiIntegra;
    [Test]
    procedure DovrebbeContareIQuadDiUnaParticella;
    [Test]
    procedure DovrebbeUccidereUnaParticellaSvanita;
    [Test]
    procedure DovrebbeRaddoppiareLeParticelleAnimate;
    [Test]
    procedure DovrebbeUsareLaGravitaDelMondo;
    [Test]
    procedure DovrebbeDareLeStesseParticelleConLoStessoSeme;
    [Test]
    procedure DovrebbeCalcolareIBoundsConLEspansione;
    [Test]
    procedure DovrebbeRifiutareUnGeneratoreSenzaFabbrica;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclFx = class
  strict private
    FEffects: TEffectsKit;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereGliEffettiDalGestore;
    [Test]
    procedure DovrebbeLeggereIlGiunto;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeManca;
    [Test]
    procedure DovrebbeFarFallireUnEventoFuoriIntervallo;
    [Test]
    procedure DovrebbeScrivereLaListaEIlContenuto;
    [Test]
    procedure DovrebbeCercareIMaterialiEISuoniChePrecarica;
    [Test]
    procedure DovrebbeTenereIlGiuntoDopoFreeData;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Random, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Fx.Types, DelphiDoom.Decl.Particle, DelphiDoom.Decl.Particle.Generator,
  DelphiDoom.Decl.Particle.Registration, DelphiDoom.Decl.Fx, DelphiDoom.Geometry.Bounds, DelphiDoom.Decl.Table,
  DelphiDoom.Tests.Scanner.IdFakes;

const
  PARTICLES =
    'particle small'#10'{'#10#9'depthHack 2'#10#9'{'#10#9#9'material textures/spark'#10#9#9'count 12'#10 +
    #9#9'time 2'#10#9#9'speed 10 to 20'#10#9#9'gravity 0'#10#9'}'#10'}'#10 +
    'particle two'#10'{'#10#9'{'#10#9#9'count 5'#10#9#9'time 1'#10#9'}'#10#9'{'#10#9#9'count 6'#10#9#9'time 3'#10#9'}'#10'}'#10 +
    'particle everything'#10'{'#10#9'{'#10#9#9'count 3'#10#9#9'time 2'#10#9#9'timeOffset 0.5'#10#9#9'deadTime 1'#10#9#9'animationFrames 4'#10 +
    #9#9'animationRate 8'#10#9#9'orientation aimed 2 0.4'#10#9#9'direction outward 0.25'#10#9#9'customPath helix 1 2 3 4 5'#10 +
    #9#9'entityColor 1'#10#9#9'rotation 10 to 30'#10#9#9'angle 15'#10#9#9'gravity world 3'#10#9'}'#10'}'#10 +
    'particle Shouty'#10'{'#10#9'{'#10#9#9'COUNT 7'#10#9#9'Time 1'#10#9#9'DISTRIBUTION SPHERE 4 4 4 0.5'#10#9'}'#10'}'#10;
  EFFECTS =
    'fx boom'#10'{'#10#9'bindto "body"'#10#9'{'#10#9#9'sound "sounds/boom"'#10#9#9'delay 0.5'#10#9'}'#10 +
    #9'{'#10#9#9'light "lights/flash", 1, 1, 0.5, 100'#10#9#9'duration 2'#10#9'}'#10#9'{'#10#9#9'decal "decals/burn"'#10 +
    #9'}'#10#9'{'#10#9#9'launch "debris"'#10#9'}'#10'}'#10;

{ TEffectsKit }

constructor TEffectsKit.Create(const AParticles, AEffects: AnsiString);
begin
  inherited Create;
  FKit := TDeclKit.Create;
  FKit.Source.Add('particles/test.prt', AParticles);
  FKit.Source.Add('fx/test.fx', AEffects);
  FKit.Start(True, True);
  // the game registers these folders (Game_local.cpp), not the manager
  FKit.Manager.GetRegistry.RegisterDeclFolder('particles', '.prt', DECL_PARTICLE);
  FKit.Manager.GetRegistry.RegisterDeclFolder('fx', '.fx', DECL_FX);
end;

destructor TEffectsKit.Destroy;
begin
  FKit.Free;
  inherited Destroy;
end;

function TEffectsKit.Particle(const AName: AnsiString): IDeclParticle;
begin
  Supports(FKit.Manager.FindType(DECL_PARTICLE, AName), IDeclParticle, Result);
end;

function TEffectsKit.Fx(const AName: AnsiString): IDeclFx;
begin
  Supports(FKit.Manager.FindType(DECL_FX, AName), IDeclFx, Result);
end;

{ TTestDeclParticle }

procedure TTestDeclParticle.Setup;
begin
  FEffects := TEffectsKit.Create(PARTICLES, EFFECTS);
end;

procedure TTestDeclParticle.TearDown;
begin
  FreeAndNil(FEffects);
end;

procedure TTestDeclParticle.DovrebbeLeggereLeParticelleDalGestore;
var
  LParticle: IDeclParticle;
begin
  LParticle := FEffects.Particle('small');
  Assert.IsNotNull(LParticle);
  Assert.AreEqual(1, LParticle.GetNumStages);
  Assert.AreEqual(Single(2.0), LParticle.GetDepthHack);
  Assert.AreEqual(12, LParticle.GetStage(0).TotalParticles);
  Assert.AreEqual('textures/spark', string(LParticle.GetStage(0).Material.GetName));
  Assert.AreEqual(2, FEffects.Particle('two').GetNumStages);
end;

procedure TTestDeclParticle.DovrebbeDareLeDimensioniDelleParticelle;
var
  LBounds: TGeoBounds;
begin
  LBounds := FEffects.Particle('small').GetBounds;
  // the box of the origins, grown by the size of the quad and 8
  Assert.IsTrue(LBounds.GetVolume > 0.1);
  Assert.IsTrue(LBounds.Mins.X < -8);
  Assert.IsTrue(LBounds.Maxs.X > 8);
  Assert.AreEqual(Single(1500), Single(FEffects.Particle('small').GetStage(0).CycleMsec - 500));
end;

procedure TTestDeclParticle.DovrebbeUsareLaDefinizioneDiDefaultSeManca;
var
  LParticle: IDeclParticle;
begin
  LParticle := FEffects.Particle('nobody');
  Assert.AreEqual(1, LParticle.GetNumStages);
  Assert.AreEqual(20, LParticle.GetStage(0).TotalParticles);
  Assert.AreEqual(Single(1.0), LParticle.GetStage(0).ParticleLife);
  Assert.AreEqual('_default', string(LParticle.GetStage(0).Material.GetName));
end;

procedure TTestDeclParticle.DovrebbeFarFallireUnoStageFuoriIntervallo;
var
  LParticle: IDeclParticle;
begin
  LParticle := FEffects.Particle('small');
  Assert.WillRaise(procedure var LIgnored: TParticleStage; begin LIgnored := LParticle.GetStage(1); end, EDeclParticleException);
  Assert.WillRaise(procedure var LIgnored: TParticleStage; begin LIgnored := LParticle.GetStage(-1); end, EDeclParticleException);
end;

procedure TTestDeclParticle.DovrebbeRiscrivereIlTestoComeLEditor;
var
  LWriter: IDeclParticleWriter;
  LText: string;
begin
  Supports(FEffects.Kit.Manager.FindType(DECL_PARTICLE, 'small'), IDeclParticleWriter, LWriter);
  LText := string(LWriter.RebuildTextSource);
  Assert.IsTrue(LText.Contains('Generated by the Particle Editor'));
  Assert.IsTrue(LText.Contains('particle small {'#10));
  // the depth hack is written as the file class writes a plain float
  Assert.IsTrue(LText.Contains(#9'depthHack'#9'2'#10));
  Assert.IsTrue(LText.Contains(#9#9'count'#9#9#9#9'12'#10));
  Assert.IsTrue(LText.Contains(#9#9'material'#9#9#9'textures/spark'#10));
  Assert.IsTrue(LText.Contains(#9#9'speed'#9#9#9#9' "10.000"  to "20.000"'#10));
  Assert.IsTrue(LText.EndsWith('}'));
end;

procedure TTestDeclParticle.DovrebbeRileggereIlTestoRiscritto;
var
  LWriter: IDeclParticleWriter;
  LText: AnsiString;
  LKit: TEffectsKit;
  LAgain: IDeclParticle;
begin
  Supports(FEffects.Kit.Manager.FindType(DECL_PARTICLE, 'two'), IDeclParticleWriter, LWriter);
  LText := LWriter.RebuildTextSource;
  LKit := TEffectsKit.Create(LText, '');
  try
    LAgain := LKit.Particle('two');
    Assert.AreEqual(2, LAgain.GetNumStages);
    Assert.AreEqual(5, LAgain.GetStage(0).TotalParticles);
    Assert.AreEqual(Single(3.0), LAgain.GetStage(1).ParticleLife);
  finally
    LKit.Free;
  end;
end;

procedure TTestDeclParticle.DovrebbeNonScrivereLaFrazioneDelleSfere;
var
  LWriter: IDeclParticleWriter;
  LParticle: IDeclParticle;
begin
  LParticle := FEffects.Particle('Shouty');
  // the parser reads the ring fraction (4th parameter), the writer of the original drops it
  Assert.AreEqual(Single(0.5), LParticle.GetStage(0).DistributionParms[3]);
  Supports(FEffects.Kit.Manager.FindType(DECL_PARTICLE, 'Shouty'), IDeclParticleWriter, LWriter);
  Assert.IsTrue(string(LWriter.RebuildTextSource).Contains(
    'distribution'#9#9'sphere 4.000 4.000 4.000 '#10));
end;

procedure TTestDeclParticle.DovrebbeSostituireIlFileConSave;
var
  LWriter: IDeclParticleWriter;
  LFileText: AnsiString;
  LTimestamp: Int64;
begin
  Supports(FEffects.Kit.Manager.FindType(DECL_PARTICLE, 'small'), IDeclParticleWriter, LWriter);
  Assert.IsTrue(LWriter.Save);
  Assert.IsTrue(FEffects.Kit.Source.TryReadFile('particles/test.prt', LFileText, LTimestamp));
  Assert.IsTrue(string(LFileText).Contains('Generated by the Particle Editor'));
end;

procedure TTestDeclParticle.DovrebbeIgnorareLeMaiuscoleDelleParole;
var
  LParticle: IDeclParticle;
begin
  LParticle := FEffects.Particle('Shouty');
  Assert.AreEqual(7, LParticle.GetStage(0).TotalParticles);
  Assert.AreEqual(Ord(TParticleDistribution.Sphere), Ord(LParticle.GetStage(0).DistributionType));
end;

procedure TTestDeclParticle.DovrebbeScrivereTuttiICampiDiUnoStage;
var
  LWriter: IDeclParticleWriter;
  LText: string;
begin
  Supports(FEffects.Kit.Manager.FindType(DECL_PARTICLE, 'everything'), IDeclParticleWriter, LWriter);
  LText := string(LWriter.RebuildTextSource);
  Assert.IsTrue(LText.Contains(#9#9'animationFrames '#9'4'#10));
  Assert.IsTrue(LText.Contains(#9#9'animationRate '#9#9'8.000'#10));
  Assert.IsTrue(LText.Contains(#9#9'timeOffset'#9#9#9'0.500'#10));
  Assert.IsTrue(LText.Contains(#9#9'deadTime'#9#9#9'1.000'#10));
  Assert.IsTrue(LText.Contains(#9#9'orientation'#9#9#9'aimed 2.000 0.400 '#10));
  Assert.IsTrue(LText.Contains(#9#9'direction'#9#9#9'outward "0.250" '#10));
  Assert.IsTrue(LText.Contains(#9#9'customPath helix 1.000 2.000 3.000 4.000 5.000 '#10));
  Assert.IsTrue(LText.Contains(#9#9'entityColor'#9#9#9'1'#10));
  Assert.IsTrue(LText.Contains(#9#9'rotation'#9#9#9#9' "10.000"  to "30.000"'#10));
  Assert.IsTrue(LText.Contains(#9#9'angle'#9#9#9#9'15.000'#10));
  Assert.IsTrue(LText.Contains(#9#9'gravity '#9#9#9'world 3.000'#10));
end;

{ TTestParticleGenerator }

procedure TTestParticleGenerator.Setup;
begin
  FLogObject := TStringList.Create;
  FLog := TFakeIdLibLog.Create(FLogObject);
end;

procedure TTestParticleGenerator.TearDown;
begin
  FLog := nil;
  FreeAndNil(FLogObject);
end;

function TTestParticleGenerator.Generator: IParticleGenerator;
begin
  Result := TParticleGenerator.Create(FLog as IIdLibLog);
end;

function TTestParticleGenerator.Stage: TParticleStage;
begin
  Result := TParticleStage.Create;
  Result.SetDefault(nil);
  Result.CycleMsec := 1500;
end;

procedure TTestParticleGenerator.DovrebbeValutareUnParametroLineare;
var
  LParm: TParticleParm;
begin
  LParm := TParticleParm.Create;
  LParm.FromValue := 2;
  LParm.ToValue := 6;
  Assert.AreEqual(Single(2), LParm.Eval(0));
  Assert.AreEqual(Single(4), LParm.Eval(0.5));
  Assert.AreEqual(Single(6), LParm.Eval(1));
end;

procedure TTestParticleGenerator.DovrebbeIntegrareUnParametroLineare;
var
  LParm: TParticleParm;
begin
  LParm := TParticleParm.Create;
  LParm.FromValue := 2;
  LParm.ToValue := 6;
  // ( from + frac * ( to - from ) * 0.5 ) * frac
  Assert.AreEqual(Single(1.5), LParm.Integrate(0.5, nil));
  Assert.AreEqual(Single(4), LParm.Integrate(1, nil));
end;

procedure TTestParticleGenerator.DovrebbeDireCheUnaTabellaNonSiIntegra;
var
  LKit: TDeclKit;
  LParm: TParticleParm;
  LTable: IDeclTable;
begin
  LKit := TDeclKit.Create;
  try
    LKit.Source.Add('x.t', '');
    LKit.Start;
    Supports(LKit.Manager.FindType(DECL_TABLE, 'ramp', True), IDeclTable, LTable);
    LParm := TParticleParm.Create;
    LParm.Table := LTable;
    Assert.AreEqual(Single(0), LParm.Integrate(0.5, FLog as IIdLibLog));
    Assert.IsTrue(FLogObject.Text.Contains('can''t integrate tables'));
    // without a log it is silent and still 0
    Assert.AreEqual(Single(0), LParm.Integrate(0.5, nil));
    // Eval reads the table at the position
    Assert.AreEqual(LTable.TableLookup(0.25), LParm.Eval(0.25));
  finally
    LKit.Free;
  end;
end;

procedure TTestParticleGenerator.DovrebbeContareIQuadDiUnaParticella;
var
  LStage: TParticleStage;
begin
  LStage := Stage;
  Assert.AreEqual(1, Generator.NumQuadsPerParticle(LStage));
  LStage.Orientation := TParticleOrientation.Aimed;
  LStage.OrientationParms[0] := 2;
  Assert.AreEqual(3, Generator.NumQuadsPerParticle(LStage));
  LStage.AnimationFrames := 4;
  Assert.AreEqual(6, Generator.NumQuadsPerParticle(LStage));
end;

procedure TTestParticleGenerator.DovrebbeUccidereUnaParticellaSvanita;
var
  LStage: TParticleStage;
  LGen: TParticleGen;
  LVerts: TArray<TParticleVertex>;
begin
  LStage := Stage;
  LGen := TParticleGen.Create(TIdRandom.Create(1));
  LGen.Frac := 0;
  // frac 0 with a fade in: the colour is all zero
  Assert.AreEqual(0, Generator.CreateParticle(LStage, LGen, LVerts));
  LGen.Frac := 0.5;
  Assert.AreEqual(4, Generator.CreateParticle(LStage, LGen, LVerts));
  Assert.AreEqual(255, Integer(LVerts[0].Color[0]));
end;

procedure TTestParticleGenerator.DovrebbeRaddoppiareLeParticelleAnimate;
var
  LStage: TParticleStage;
  LGen: TParticleGen;
  LVerts: TArray<TParticleVertex>;
begin
  LStage := Stage;
  LStage.AnimationFrames := 4;
  LGen := TParticleGen.Create(TIdRandom.Create(1));
  LGen.Frac := 0.5;
  LGen.Age := 0.75;
  Assert.AreEqual(8, Generator.CreateParticle(LStage, LGen, LVerts));
  // the two quads are one frame apart and their colours share the whole
  Assert.AreEqual(Single(0.25), Single(LVerts[4].St[0] - LVerts[0].St[0]));
  Assert.IsTrue(Integer(LVerts[0].Color[0]) + Integer(LVerts[4].Color[0]) in [253..255]);
end;

procedure TTestParticleGenerator.DovrebbeUsareLaGravitaDelMondo;
var
  LStage: TParticleStage;
  LGen: TParticleGen;
  LOrigin, LWorld: TIdVec3;
begin
  LStage := Stage;
  LStage.Speed.FromValue := 0;
  LStage.Speed.ToValue := 0;
  LStage.Gravity := 2;
  LStage.DistributionParms[0] := 0;
  LStage.DistributionParms[1] := 0;
  LStage.DistributionParms[2] := 0;
  LGen := TParticleGen.Create(TIdRandom.Create(1));
  LGen.Age := 2;
  LOrigin.Zero;
  Generator.ParticleOrigin(LStage, LGen, LOrigin);
  // z -= gravity * age * age
  Assert.AreEqual(Single(-8), LOrigin.Z);
  LStage.WorldGravity := True;
  LWorld.Zero;
  Generator.ParticleOrigin(LStage, LGen, LWorld);
  // with the identity axis the world gravity is the same
  Assert.AreEqual(Single(-8), LWorld.Z);
end;

procedure TTestParticleGenerator.DovrebbeDareLeStesseParticelleConLoStessoSeme;
var
  LStage: TParticleStage;
  LFirst, LSecond: TParticleGen;
  LVertsA, LVertsB: TArray<TParticleVertex>;
begin
  LStage := Stage;
  LFirst := TParticleGen.Create(TIdRandom.Create(9));
  LFirst.Frac := 0.5;
  LFirst.Age := 0.75;
  LSecond := LFirst;
  Generator.CreateParticle(LStage, LFirst, LVertsA);
  Generator.CreateParticle(LStage, LSecond, LVertsB);
  Assert.AreEqual(LVertsA[2].Xyz.X, LVertsB[2].Xyz.X);
  Assert.AreEqual(LFirst.Random.GetSeed, LSecond.Random.GetSeed);
end;

procedure TTestParticleGenerator.DovrebbeCalcolareIBoundsConLEspansione;
var
  LStage: TParticleStage;
  LPlain, LExpanded: Single;
begin
  LStage := Stage;
  Generator.CalculateStageBounds(LStage);
  LPlain := LStage.Bounds.Maxs.X - LStage.Bounds.Mins.X;
  LStage.BoundsExpansion := 10;
  Generator.CalculateStageBounds(LStage);
  LExpanded := LStage.Bounds.Maxs.X - LStage.Bounds.Mins.X;
  Assert.AreEqual(Single(20), LExpanded - LPlain, Single(0.01));
  // a stage that lives no time has no points: the bounds are only the grown, cleared box
  LStage.ParticleLife := 0;
  Generator.CalculateStageBounds(LStage);
  Assert.IsTrue(LStage.Bounds.IsCleared or (LStage.Bounds.GetVolume <= 0));
end;

procedure TTestParticleGenerator.DovrebbeRifiutareUnGeneratoreSenzaFabbrica;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    TDeclParticle.Create(nil).Free;
  except
    on EDeclParticleException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

{ TTestDeclFx }

procedure TTestDeclFx.Setup;
begin
  FEffects := TEffectsKit.Create(PARTICLES, EFFECTS);
end;

procedure TTestDeclFx.TearDown;
begin
  FreeAndNil(FEffects);
end;

procedure TTestDeclFx.DovrebbeLeggereGliEffettiDalGestore;
var
  LFx: IDeclFx;
begin
  LFx := FEffects.Fx('boom');
  Assert.IsNotNull(LFx);
  Assert.AreEqual(4, LFx.GetNumEvents);
  Assert.AreEqual(FX_SOUND, LFx.GetEvent(0).ActionType);
  Assert.AreEqual('sounds/boom', string(LFx.GetEvent(0).Data));
  Assert.AreEqual(Single(0.5), LFx.GetEvent(0).Delay);
  Assert.AreEqual(FX_LIGHT, LFx.GetEvent(1).ActionType);
  Assert.AreEqual(Single(100), LFx.GetEvent(1).LightRadius);
  Assert.AreEqual(Single(0.5), LFx.GetEvent(1).LightColor.Z);
  Assert.AreEqual(FX_DECAL, LFx.GetEvent(2).ActionType);
  Assert.AreEqual(Single(0), LFx.GetEvent(0).Duration);
end;

procedure TTestDeclFx.DovrebbeLeggereIlGiunto;
begin
  Assert.AreEqual('body', string(FEffects.Fx('boom').GetJoint));
end;

procedure TTestDeclFx.DovrebbeUsareLaDefinizioneDiDefaultSeManca;
var
  LFx: IDeclFx;
begin
  LFx := FEffects.Fx('nobody');
  Assert.AreEqual(1, LFx.GetNumEvents);
  Assert.AreEqual(FX_MODEL, LFx.GetEvent(0).ActionType);
  Assert.AreEqual('_default', string(LFx.GetEvent(0).Data));
  Assert.AreEqual(Single(5), LFx.GetEvent(0).Duration);
end;

procedure TTestDeclFx.DovrebbeFarFallireUnEventoFuoriIntervallo;
var
  LIgnored: TFxAction;
  LRaised: Boolean;
  LFx: IDeclFx;
begin
  LFx := FEffects.Fx('boom');
  LRaised := False;
  try
    LIgnored := LFx.GetEvent(4);
  except
    on EDeclFxException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  LRaised := False;
  try
    LIgnored := LFx.GetEvent(-1);
  except
    on EDeclFxException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestDeclFx.DovrebbeScrivereLaListaEIlContenuto;
var
  LDecl: IDecl;
  LStart: Integer;
begin
  LDecl := FEffects.Kit.Manager.FindType(DECL_FX, 'boom');
  LStart := FEffects.Kit.Lines.Count;
  LDecl.List;
  LDecl.Print;
  Assert.AreEqual('P: boom, 4 stages\n', FEffects.Kit.Lines[LStart]);
  Assert.AreEqual('P: 4 events\n', FEffects.Kit.Lines[LStart + 1]);
  Assert.AreEqual('P: FX_SOUND sounds/boom\n', FEffects.Kit.Lines[LStart + 2]);
  Assert.AreEqual('P: FX_LIGHT lights/flash\n', FEffects.Kit.Lines[LStart + 3]);
  Assert.AreEqual('P: FX_DECAL decals/burn\n', FEffects.Kit.Lines[LStart + 4]);
  Assert.AreEqual('P: FX_LAUNCH debris\n', FEffects.Kit.Lines[LStart + 5]);
end;

procedure TTestDeclFx.DovrebbeCercareIMaterialiEISuoniChePrecarica;
var
  LNumber: Integer;
begin
  FEffects.Fx('boom');
  // the actions named a sound, a light material, a decal and an entity def: all of them were found (and made)
  LNumber := FEffects.Kit.Manager.GetNumDecls(DECL_SOUND);
  Assert.IsTrue(LNumber >= 1);
  Assert.IsNotNull(FEffects.Kit.Manager.FindType(DECL_ENTITYDEF, 'debris', False));
  Assert.IsNotNull(FEffects.Kit.Manager.FindType(DECL_MATERIAL, 'lights/flash', False));
  Assert.IsNotNull(FEffects.Kit.Manager.FindType(DECL_MATERIAL, 'decals/burn', False));
end;

procedure TTestDeclFx.DovrebbeTenereIlGiuntoDopoFreeData;
var
  LDecl: IDecl;
begin
  LDecl := FEffects.Kit.Manager.FindType(DECL_FX, 'boom');
  LDecl.Invalidate;
  // the original clears the events and not the joint
  Assert.AreEqual('body', string(FEffects.Fx('boom').GetJoint));
  Assert.AreEqual(4, FEffects.Fx('boom').GetNumEvents);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclParticle);
  TDUnitX.RegisterTestFixture(TTestParticleGenerator);
  TDUnitX.RegisterTestFixture(TTestDeclFx);

end.
