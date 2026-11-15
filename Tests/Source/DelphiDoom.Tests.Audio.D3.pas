{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D sound of Doom 3 (DUnitX)                        }
{                                                                              }
{  Portal spatialization, channel volume and speaker mixing of snd_world.cpp,  }
{  snd_emitter.cpp and Simd_Generic.cpp. The values are worked out by hand     }
{  from the text of the C++ (the sound world needs OpenAL and the renderer, so }
{  it cannot be compiled alone); the world is a fake with a few portals.       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.D3;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Decl.Sound.Types, DelphiDoom.Audio.D3.Types,
  DelphiDoom.Audio.D3.Intf, DelphiDoom.Audio.D3.PortalSpatializer, DelphiDoom.Audio.D3.ChannelGain,
  DelphiDoom.Audio.D3.SpeakerMixer;

type
  /// <summary>Areas by the x of the point (0..99 is area 0, 100..199 is area 1, ...) and portals given by the test</summary>
  TFakePortalWorld = class(TInterfacedObject, ID3PortalWorld)
  strict private
    FPortals: TList<TD3ExitPortal>;
    FAreaWidth: Single;
  public
    constructor Create(AAreaWidth: Single);
    destructor Destroy; override;
    /// <summary>A square portal between two areas, in the plane x = X, with the half size given</summary>
    procedure AddPortal(AFirst, ASecond: Integer; AX, AHalf: Single; ABlocking: Integer = 0);
    function PointInArea(const APoint: TIdVec3): Integer;
    function NumPortalsInArea(AArea: Integer): Integer;
    function GetPortal(AArea, AIndex: Integer): TD3ExitPortal;
  end;

  [TestFixture]
  [Category('audio')]
  TTestD3PortalSpatializer = class(TObject)
  strict private
    FWorld: TFakePortalWorld;
    FWorldIntf: ID3PortalWorld;
    function Spatializer: TD3PortalSpatializer;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeUsareLaPosizioneRealeNellaStessaArea;
    [Test]
    procedure DovrebbeDireNonSiSenteOltreLaPortata;
    [Test]
    procedure DovrebbeTrovareIlPuntoSulPortale;
    [Test]
    procedure DovrebbeSpostareIlPuntoDentroIBordiDelPortale;
    [Test]
    procedure DovrebbeAggiungereLaDistanzaDellaPortaChiusa;
    [Test]
    procedure DovrebbeNonSentireSenzaUnaViaAperta;
    [Test]
    procedure DovrebbeNonEntrareDueVolteNellaStessaArea;
    [Test]
    procedure DovrebbeFermarsiDopoDieciPortali;
    [Test]
    procedure DovrebbeUsareLaDistanzaRettaSenzaMondoOSenzaAscoltatore;
    [Test]
    procedure DovrebbeRicordareLUltimaAreaValidaFuoriDalMondo;
    [Test]
    procedure DovrebbeUsareIlCentroSeIlRaggioNonTagliaIlPiano;
  end;

  [TestFixture]
  [Category('audio')]
  TTestD3ChannelGain = class(TObject)
  strict private
    FCalculator: TD3ChannelGainCalculator;
    FInput: TD3ChannelInput;
    FState: TD3ChannelState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeConvertireIDecibelInScala;
    [Test]
    procedure DovrebbeDareIlVolumePienoDentroLaDistanzaMinima;
    [Test]
    procedure DovrebbeAttenuareLinearmenteOQuadraticamente;
    [Test]
    procedure DovrebbeTacereOltreLaDistanzaMassima;
    [Test]
    procedure DovrebbeDareLeOrecchieDiUnSuonoASinistra;
    [Test]
    procedure DovrebbeRidurreLaSpazializzazioneDentroLaDistanzaMinima;
    [Test]
    procedure DovrebbeDareASeiAltoparlanti;
    [Test]
    procedure DovrebbeDareTuttiGliAltoparlantiAUnSuonoGlobale;
    [Test]
    procedure DovrebbeApplicareLaMascheraEIlLimite;
    [Test]
    procedure DovrebbeGestireISuoniPrivati;
    [Test]
    procedure DovrebbeNonAggiungereNullaSotto1Su32768;
    [Test]
    procedure DovrebbeUsareIlVolumeDelLeadinEIFade;
    [Test]
    procedure DovrebbeSaltareIlBipDiDefaultSeSpento;
    [Test]
    procedure DovrebbeAvereLeStesseBandiereDelloShader;
  end;

  [TestFixture]
  [Category('audio')]
  TTestD3SpeakerMixer = class(TObject)
  public
    [Test]
    procedure DovrebbeMixareUnMonoSuDueAltoparlantiConVolumeCostante;
    [Test]
    procedure DovrebbeFareLaRampaTraIVolumi;
    [Test]
    procedure DovrebbeMixareUnoStereoSuDueAltoparlanti;
    [Test]
    procedure DovrebbeMixareUnMonoSuSeiAltoparlanti;
    [Test]
    procedure DovrebbeMixareUnoStereoSuSeiAltoparlantiConLaTabellaDelC;
    [Test]
    procedure DovrebbeSommareSenzaCancellareIlBuffer;
    [Test]
    procedure DovrebbeLimitareECtroncareIn16Bit;
  end;

implementation

{ TFakePortalWorld }

constructor TFakePortalWorld.Create(AAreaWidth: Single);
begin
  inherited Create;
  FPortals := TList<TD3ExitPortal>.Create;
  FAreaWidth := AAreaWidth;
end;

destructor TFakePortalWorld.Destroy;
begin
  FPortals.Free;
  inherited Destroy;
end;

procedure TFakePortalWorld.AddPortal(AFirst, ASecond: Integer; AX, AHalf: Single; ABlocking: Integer);
var
  LPortal: TD3ExitPortal;
begin
  LPortal.Areas[0] := AFirst;
  LPortal.Areas[1] := ASecond;
  LPortal.BlockingBits := ABlocking;
  SetLength(LPortal.Points, 4);
  LPortal.Points[0] := TIdVec3.Create(AX, -AHalf, -AHalf);
  LPortal.Points[1] := TIdVec3.Create(AX, AHalf, -AHalf);
  LPortal.Points[2] := TIdVec3.Create(AX, AHalf, AHalf);
  LPortal.Points[3] := TIdVec3.Create(AX, -AHalf, AHalf);
  FPortals.Add(LPortal);
end;

function TFakePortalWorld.PointInArea(const APoint: TIdVec3): Integer;
begin
  if (APoint.X < 0) or (APoint.X >= FAreaWidth * 20) then
    Result := -1
  else
    Result := Trunc(APoint.X / FAreaWidth);
end;

function TFakePortalWorld.NumPortalsInArea(AArea: Integer): Integer;
var
  LPortal: TD3ExitPortal;
begin
  Result := 0;
  for LPortal in FPortals do
    if (LPortal.Areas[0] = AArea) or (LPortal.Areas[1] = AArea) then
      Inc(Result);
end;

function TFakePortalWorld.GetPortal(AArea, AIndex: Integer): TD3ExitPortal;
var
  LPortal: TD3ExitPortal;
  LCount: Integer;
begin
  LCount := 0;
  for LPortal in FPortals do
    if (LPortal.Areas[0] = AArea) or (LPortal.Areas[1] = AArea) then
    begin
      if LCount = AIndex then
        Exit(LPortal);
      Inc(LCount);
    end;
  raise Exception.Create('portal');
end;

{ TTestD3PortalSpatializer }

procedure TTestD3PortalSpatializer.Setup;
begin
  FWorld := TFakePortalWorld.Create(100);
  FWorldIntf := FWorld;
end;

function TTestD3PortalSpatializer.Spatializer: TD3PortalSpatializer;
begin
  Result := TD3PortalSpatializer.Create(FWorldIntf, TD3SoundCvars.Defaults);
end;

procedure TTestD3PortalSpatializer.DovrebbeUsareLaPosizioneRealeNellaStessaArea;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(10, 0, 0), 0);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(60, 0, 0), 20);
    LSpatializer.Spatialize(LEmitter);
    // 50 units are 1.27 meters
    Assert.AreEqual(1.27, Double(LEmitter.RealDistance), 0.02);
    Assert.AreEqual(Double(LEmitter.RealDistance), Double(LEmitter.Distance), 0.00001);
    Assert.AreEqual(60.0, Double(LEmitter.SpatializedOrigin.X), 0.0001);
    Assert.AreEqual(0, LEmitter.LastValidPortalArea);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeDireNonSiSenteOltreLaPortata;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(0, 0, 0), 0);
    // 1000 units are 25.4 meters
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(1000, 0, 0), 10);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(25.4, Double(LEmitter.Distance), 0.3);
    Assert.IsTrue(LEmitter.Distance >= LEmitter.MaxDistance);
    Assert.AreEqual(-1, LEmitter.LastValidPortalArea);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeTrovareIlPuntoSulPortale;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  FWorld.AddPortal(0, 1, 100, 30);
  LSpatializer := Spatializer;
  try
    // the listener in area 0, the sound in area 1 at x = 150 (the portal is at x = 100)
    LSpatializer.SetListener(TIdVec3.Create(20, 0, 0), 0);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(150, 0, 0), 20);
    LSpatializer.Spatialize(LEmitter);
    // virtual origin on the portal: 50 to the portal and 80 from it to the listener: 130 units
    Assert.AreEqual(100.0, Double(LEmitter.SpatializedOrigin.X), 0.001);
    Assert.AreEqual(0.0, Double(LEmitter.SpatializedOrigin.Y), 0.001);
    Assert.AreEqual(130 * 0.0254, Double(LEmitter.Distance), 0.04);
    Assert.AreEqual(130 * 0.0254, Double(LEmitter.RealDistance), 0.04);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeSpostareIlPuntoDentroIBordiDelPortale;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  FWorld.AddPortal(0, 1, 100, 10);
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(0, 0, 0), 0);
    // the straight line to the listener crosses the plane of the portal at y = 40: outside the opening of +-10,
    // so the point slides in to the edge
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(150, 60, 0), 40);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(100.0, Double(LEmitter.SpatializedOrigin.X), 0.01);
    Assert.AreEqual(10.0, Double(LEmitter.SpatializedOrigin.Y), 0.01);
    Assert.AreEqual(0.0, Double(LEmitter.SpatializedOrigin.Z), 0.01);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeAggiungereLaDistanzaDellaPortaChiusa;
var
  LClosed: TD3EmitterSpace;
  LSpatializer: TD3PortalSpatializer;
begin
  FWorld.AddPortal(0, 1, 100, 30, D3_PS_BLOCK_VIEW);
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(20, 0, 0), 0);
    LClosed := TD3EmitterSpace.Init(TIdVec3.Create(150, 0, 0), 20);
    LSpatializer.Spatialize(LClosed);
    // 130 units and 150 for the door
    Assert.AreEqual((130 + 150) * 0.0254, Double(LClosed.Distance), 0.07);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeNonSentireSenzaUnaViaAperta;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  // areas 0 and 2 with nothing between them
  FWorld.AddPortal(1, 2, 200, 30);
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(20, 0, 0), 0);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(250, 0, 0), 20);
    LSpatializer.Spatialize(LEmitter);
    // the distance stays the largest range of the emitter
    Assert.AreEqual(20.0, Double(LEmitter.Distance), 0.001);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeNonEntrareDueVolteNellaStessaArea;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  // a loop of areas 1 - 2 - 3 - 1 and the way to the listener only through 3 - 0
  FWorld.AddPortal(1, 2, 200, 30);
  FWorld.AddPortal(2, 3, 300, 30);
  FWorld.AddPortal(3, 1, 150, 30);
  FWorld.AddPortal(3, 0, 100, 30);
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(20, 0, 0), 0);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(250, 0, 0), 30);
    LSpatializer.Spatialize(LEmitter);
    Assert.IsTrue(LEmitter.Distance < 30);
    Assert.IsTrue(LEmitter.Distance > 0);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeFermarsiDopoDieciPortali;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
  LIndex: Integer;
begin
  // a corridor of 12 areas: the sound in area 11 is 11 portals away; MAX_PORTAL_TRACE_DEPTH stops at 10
  for LIndex := 0 to 10 do
    FWorld.AddPortal(LIndex, LIndex + 1, (LIndex + 1) * 100, 30);
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(20, 0, 0), 0);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(1150, 0, 0), 100);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(100.0, Double(LEmitter.Distance), 0.01);
    // one portal less is reached
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(1050, 0, 0), 100);
    LSpatializer.Spatialize(LEmitter);
    Assert.IsTrue(LEmitter.Distance < 100);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeUsareLaDistanzaRettaSenzaMondoOSenzaAscoltatore;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  LSpatializer := TD3PortalSpatializer.Create(nil, TD3SoundCvars.Defaults);
  try
    LSpatializer.SetListener(TIdVec3.Create(0, 0, 0), 5);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(100, 0, 0), 20);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(2.54, Double(LEmitter.Distance), 0.03);
    Assert.AreEqual(100.0, Double(LEmitter.SpatializedOrigin.X), 0.001);
    // a listener outside the world: the distance stays the largest range, in Doom units
    LSpatializer.SetListener(TIdVec3.Create(0, 0, 0), -1);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(100, 0, 0), 20);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(20 * 39.3700787, Double(LEmitter.Distance), 0.01);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeRicordareLUltimaAreaValidaFuoriDalMondo;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  FWorld.AddPortal(0, 1, 100, 30);
  LSpatializer := Spatializer;
  try
    LSpatializer.SetListener(TIdVec3.Create(20, 0, 0), 0);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(-10, 0, 0), 20);
    LSpatializer.Spatialize(LEmitter);
    // outside the world and never inside: the straight distance
    Assert.AreEqual(30 * 0.0254, Double(LEmitter.Distance), 0.01);
    Assert.AreEqual(-1, LEmitter.LastValidPortalArea);
    // inside area 1 once, then out of the world: it counts as area 1
    LEmitter.Origin := TIdVec3.Create(150, 0, 0);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(1, LEmitter.LastValidPortalArea);
    LEmitter.Origin := TIdVec3.Create(-5, 0, 0);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(1, LEmitter.LastValidPortalArea);
  finally
    LSpatializer.Free;
  end;
end;

procedure TTestD3PortalSpatializer.DovrebbeUsareIlCentroSeIlRaggioNonTagliaIlPiano;
var
  LSpatializer: TD3PortalSpatializer;
  LEmitter: TD3EmitterSpace;
begin
  FWorld.AddPortal(0, 1, 100, 30);
  LSpatializer := Spatializer;
  try
    // the listener at the same x as the portal plane: the ray from the sound is parallel to it, so the virtual
    // origin is the centre of the portal
    LSpatializer.SetListener(TIdVec3.Create(100, 50, 0), 0);
    LEmitter := TD3EmitterSpace.Init(TIdVec3.Create(100, 0, 0), 40);
    LSpatializer.Spatialize(LEmitter);
    Assert.AreEqual(100.0, Double(LEmitter.SpatializedOrigin.X), 0.001);
    Assert.AreEqual(0.0, Double(LEmitter.SpatializedOrigin.Y), 0.001);
    Assert.AreEqual(50 * 0.0254, Double(LEmitter.Distance), 0.02);
  finally
    LSpatializer.Free;
  end;
end;

{ TTestD3ChannelGain }

procedure TTestD3ChannelGain.Setup;
begin
  FCalculator := TD3ChannelGainCalculator.Create(TD3SoundCvars.Defaults);
  FInput := Default(TD3ChannelInput);
  FInput.MinDistance := 2;
  FInput.MaxDistance := 10;
  FInput.SampleChannels := 1;
  FInput.SampleLength44kHz := 1000;
  FInput.Current44kHz := 5000;
  FInput.Trigger44kHzTime := 0;
  FInput.ListenerPrivateId := 0;
  FInput.EmitterListenerId := 1;
  FInput.NumSpeakers := 2;
  FInput.ListenerAxis := TIdMat3.Identity;
  FInput.NumSpeakers := 2;
  FState := Default(TD3ChannelState);
end;

procedure TTestD3ChannelGain.TearDown;
begin
  FCalculator.Free;
end;

procedure TTestD3ChannelGain.DovrebbeConvertireIDecibelInScala;
begin
  Assert.AreEqual(1.0, Double(FCalculator.DbToScale(0)), 0);
  Assert.AreEqual(0.0, Double(FCalculator.DbToScale(-60)), 0);
  Assert.AreEqual(0.0, Double(FCalculator.DbToScale(-100)), 0);
  // 6 dB is a doubling (the table is in steps of a tenth of a decibel)
  Assert.AreEqual(2.0, Double(FCalculator.DbToScale(6)), 0.0001);
  Assert.AreEqual(0.5, Double(FCalculator.DbToScale(-6)), 0.0001);
  // from 60 dB on it is computed
  Assert.AreEqual(1024.0, Double(FCalculator.DbToScale(60)), 0.001);
  Assert.AreEqual(4096.0, Double(FCalculator.DbToScale(72)), 0.01);
end;

procedure TTestD3ChannelGain.DovrebbeDareIlVolumePienoDentroLaDistanzaMinima;
var
  LGain: TD3ChannelGain;
begin
  FInput.RealDistance := 1;
  FInput.Distance := 1;
  FInput.EmitterOrigin := TIdVec3.Create(39.37, 0, 0);
  FInput.SpatializedOrigin := FInput.EmitterOrigin;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsTrue(LGain.Audible);
  Assert.AreEqual(1.0, Double(LGain.Volume), 0.0001);
  Assert.AreEqual(1.0, Double(FState.LastVolume), 0.0001);
end;

procedure TTestD3ChannelGain.DovrebbeAttenuareLinearmenteOQuadraticamente;
var
  LGain: TD3ChannelGain;
  LCvars: TD3SoundCvars;
  LLinear: TD3ChannelGainCalculator;
begin
  FInput.RealDistance := 6;
  FInput.Distance := 6;
  FInput.EmitterOrigin := TIdVec3.Create(236, 0, 0);
  FInput.SpatializedOrigin := FInput.EmitterOrigin;
  // frac = 1 - (6 - 2) / (10 - 2) = 0.5; squared 0.25
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(0.25, Double(LGain.Volume), 0.0001);
  LCvars := TD3SoundCvars.Defaults;
  LCvars.QuadraticFalloff := False;
  LLinear := TD3ChannelGainCalculator.Create(LCvars);
  try
    FState := Default(TD3ChannelState);
    LGain := LLinear.Calculate(FInput, FState);
    Assert.AreEqual(0.5, Double(LGain.Volume), 0.0001);
  finally
    LLinear.Free;
  end;
end;

procedure TTestD3ChannelGain.DovrebbeTacereOltreLaDistanzaMassima;
var
  LGain: TD3ChannelGain;
begin
  FInput.RealDistance := 10;
  FInput.Distance := 10;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsFalse(LGain.Audible);
  // nothing before either: the last volume is not touched
  Assert.AreEqual(0.0, Double(FState.LastVolume), 0);
end;

procedure TTestD3ChannelGain.DovrebbeDareLeOrecchieDiUnSuonoASinistra;
var
  LGain: TD3ChannelGain;
begin
  // the sound 2 meters (the minimum distance: no bias) along +y of the listener (axis identity): dot = 1; left (1.1 + 1) / 2.1 = 1 and right 0.0476
  // which the minimum volume of 0.25 raises
  FInput.RealDistance := 2;
  FInput.Distance := 2;
  FInput.EmitterOrigin := TIdVec3.Create(0, 78.74015748, 0);
  FInput.SpatializedOrigin := FInput.EmitterOrigin;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(1.0, Double(LGain.Ears[0]), 0.0001);
  Assert.AreEqual(0.25, Double(LGain.Ears[1]), 0.0001);
  Assert.AreEqual(0.0, Double(LGain.Ears[2]), 0);
  // a later block leaves the last volumes alone; the very first one starts at the volumes it will have
  Assert.AreEqual(0.0, Double(FState.LastV[1]), 0);
  FInput.Current44kHz := FInput.Trigger44kHzTime;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(0.25, Double(FState.LastV[1]), 0.0001);
end;

procedure TTestD3ChannelGain.DovrebbeRidurreLaSpazializzazioneDentroLaDistanzaMinima;
var
  LNear: TD3ChannelGain;
  LFar: TD3ChannelGain;
  LState2: TD3ChannelState;
begin
  FInput.EmitterOrigin := TIdVec3.Create(0, 0.3937007874, 0);
  FInput.SpatializedOrigin := FInput.EmitterOrigin;
  // at 0.01 m of a minimum of 2: spatialize 0.005, the bias goes to s_spatializationDecay = 2:
  // left = 2.1 / (1 + 1.1 + 0.9 * 0.995) = 0.701
  FInput.RealDistance := 0.01;
  FInput.Distance := 0.01;
  LNear := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(0.701, Double(LNear.Ears[0]), 0.002);
  FInput.RealDistance := 2;
  FInput.Distance := 2;
  LState2 := Default(TD3ChannelState);
  LFar := FCalculator.Calculate(FInput, LState2);
  Assert.IsTrue(LFar.Ears[0] > LNear.Ears[0]);
end;

procedure TTestD3ChannelGain.DovrebbeDareASeiAltoparlanti;
var
  LGain: TD3ChannelGain;
begin
  FInput.NumSpeakers := 6;
  FInput.RealDistance := 1;
  FInput.Distance := 1;
  // straight ahead (+x of the axis): front left and right 0.707, center 1, rears (0.8 - 0.707) / 1.8 = 0.0517
  FInput.EmitterOrigin := TIdVec3.Create(39.37007874, 0, 0);
  FInput.SpatializedOrigin := FInput.EmitterOrigin;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual((0.8 + 0.707) / 1.8, Double(LGain.Ears[0]), 0.001);
  Assert.AreEqual((0.8 + 0.707) / 1.8, Double(LGain.Ears[1]), 0.001);
  Assert.AreEqual((0.8 + 0.707) / 1.8, Double(LGain.Ears[2]), 0.001);
  // the subwoofer is the fraction of the cvar
  Assert.AreEqual(0.75, Double(LGain.Ears[3]), 0.0001);
  Assert.AreEqual((0.8 - 0.707) / 1.8, Double(LGain.Ears[4]), 0.001);
end;

procedure TTestD3ChannelGain.DovrebbeDareTuttiGliAltoparlantiAUnSuonoGlobale;
var
  LGain: TD3ChannelGain;
  LIndex: Integer;
begin
  FInput.SoundShaderFlags := D3_SSF_GLOBAL;
  FInput.RealDistance := 500;
  FInput.Distance := 500;
  FInput.NumSpeakers := 6;
  LGain := FCalculator.Calculate(FInput, FState);
  // not affected by distance: s_globalFraction (0.8) everywhere and 0.75 on the subwoofer
  for LIndex := 0 to 5 do
    if LIndex = 3 then
      Assert.AreEqual(0.75, Double(LGain.Ears[LIndex]), 0.0001)
    else
      Assert.AreEqual(0.8, Double(LGain.Ears[LIndex]), 0.0001);
end;

procedure TTestD3ChannelGain.DovrebbeApplicareLaMascheraEIlLimite;
var
  LGain: TD3ChannelGain;
begin
  FInput.SoundShaderFlags := D3_SSF_GLOBAL;
  FInput.VolumeDb := 12;
  FInput.SpeakerMask := 1;
  LGain := FCalculator.Calculate(FInput, FState);
  // 12 dB is x4, times 0.8 is 3.2, cut to 1; the speakers that the mask does not name are silent
  Assert.AreEqual(1.0, Double(LGain.Ears[0]), 0);
  Assert.AreEqual(0.0, Double(LGain.Ears[1]), 0);
  FState := Default(TD3ChannelState);
  FInput.SoundShaderFlags := D3_SSF_GLOBAL or D3_SSF_UNCLAMPED;
  FInput.SpeakerMask := 0;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(3.2, Double(LGain.Ears[0]), 0.001);
  Assert.AreEqual(3.2, Double(LGain.Ears[1]), 0.001);
end;

procedure TTestD3ChannelGain.DovrebbeGestireISuoniPrivati;
var
  LGain: TD3ChannelGain;
begin
  FInput.SoundShaderFlags := D3_SSF_GLOBAL or D3_SSF_PRIVATE_SOUND;
  // the sound belongs to listener 1 and the listener is 0: silent
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsFalse(LGain.Audible);
  FInput.ListenerPrivateId := 1;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsTrue(LGain.Audible);
  // anti private: the opposite
  FInput.SoundShaderFlags := D3_SSF_GLOBAL or D3_SSF_ANTI_PRIVATE_SOUND;
  FState := Default(TD3ChannelState);
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsFalse(LGain.Audible);
end;

procedure TTestD3ChannelGain.DovrebbeNonAggiungereNullaSotto1Su32768;
var
  LGain: TD3ChannelGain;
begin
  FInput.SoundShaderFlags := D3_SSF_GLOBAL;
  FInput.VolumeDb := -59.9;
  // 2^(-9.98) = 0.00099; louder than 1/32768 (0.0000305): it adds
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsTrue(LGain.Audible);
  FInput.ClassFadeDb := -60;
  FState := Default(TD3ChannelState);
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsFalse(LGain.Audible);
  // unless it was audible in the block before: it fades out
  FState.LastVolume := 0.5;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsTrue(LGain.Audible);
  Assert.AreEqual(0.0, Double(LGain.Volume), 0);
end;

procedure TTestD3ChannelGain.DovrebbeUsareIlVolumeDelLeadinEIFade;
var
  LGain: TD3ChannelGain;
begin
  FInput.SoundShaderFlags := D3_SSF_GLOBAL or D3_SSF_UNCLAMPED;
  FInput.VolumeDb := 0;
  FInput.LeadinVolumeDb := 6;
  // the leadin is 1000 samples long and plays from the trigger
  FInput.Current44kHz := 500;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(2.0 * 0.8, Double(LGain.Ears[0]), 0.001);
  FInput.Current44kHz := 1500;
  FState := Default(TD3ChannelState);
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(0.8, Double(LGain.Ears[0]), 0.001);
  // the fades and the global volume multiply
  FInput.ChannelFadeDb := -6;
  FInput.ClassFadeDb := -6;
  FState := Default(TD3ChannelState);
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.AreEqual(0.25 * 0.8, Double(LGain.Ears[0]), 0.001);
end;

procedure TTestD3ChannelGain.DovrebbeSaltareIlBipDiDefaultSeSpento;
var
  LCvars: TD3SoundCvars;
  LCalculator: TD3ChannelGainCalculator;
  LGain: TD3ChannelGain;
begin
  FInput.SoundShaderFlags := D3_SSF_GLOBAL;
  FInput.SampleIsDefault := True;
  LGain := FCalculator.Calculate(FInput, FState);
  Assert.IsTrue(LGain.Audible);
  LCvars := TD3SoundCvars.Defaults;
  LCvars.PlayDefaultSound := False;
  LCalculator := TD3ChannelGainCalculator.Create(LCvars);
  try
    LGain := LCalculator.Calculate(FInput, FState);
    Assert.IsFalse(LGain.Audible);
  finally
    LCalculator.Free;
  end;
end;

procedure TTestD3ChannelGain.DovrebbeAvereLeStesseBandiereDelloShader;
begin
  Assert.AreEqual(SSF_PRIVATE_SOUND, D3_SSF_PRIVATE_SOUND);
  Assert.AreEqual(SSF_ANTI_PRIVATE_SOUND, D3_SSF_ANTI_PRIVATE_SOUND);
  Assert.AreEqual(SSF_NO_OCCLUSION, D3_SSF_NO_OCCLUSION);
  Assert.AreEqual(SSF_GLOBAL, D3_SSF_GLOBAL);
  Assert.AreEqual(SSF_OMNIDIRECTIONAL, D3_SSF_OMNIDIRECTIONAL);
  Assert.AreEqual(SSF_LOOPING, D3_SSF_LOOPING);
  Assert.AreEqual(SSF_UNCLAMPED, D3_SSF_UNCLAMPED);
end;

{ TTestD3SpeakerMixer }

procedure TTestD3SpeakerMixer.DovrebbeMixareUnMonoSuDueAltoparlantiConVolumeCostante;
var
  LMix: TArray<Single>;
  LSamples: TArray<Single>;
  LVolumes: TD3Ears;
  LIndex: Integer;
begin
  SetLength(LMix, D3_MIXBUFFER_SAMPLES * 2);
  SetLength(LSamples, D3_MIXBUFFER_SAMPLES);
  for LIndex := 0 to High(LSamples) do
    LSamples[LIndex] := LIndex;
  LVolumes := Default(TD3Ears);
  LVolumes[0] := 0.5;
  LVolumes[1] := 0.25;
  TD3SpeakerMixer.Mix(2, False, @LMix[0], @LSamples[0], LVolumes, LVolumes);
  Assert.AreEqual(100.0 * 0.5, Double(LMix[200]), 0);
  Assert.AreEqual(100.0 * 0.25, Double(LMix[201]), 0);
  Assert.AreEqual(4095.0 * 0.5, Double(LMix[8190]), 0);
end;

procedure TTestD3SpeakerMixer.DovrebbeFareLaRampaTraIVolumi;
var
  LMix: TArray<Single>;
  LSamples: TArray<Single>;
  LLast, LCurrent: TD3Ears;
  LIndex: Integer;
begin
  SetLength(LMix, D3_MIXBUFFER_SAMPLES * 2);
  SetLength(LSamples, D3_MIXBUFFER_SAMPLES);
  for LIndex := 0 to High(LSamples) do
    LSamples[LIndex] := 1;
  LLast := Default(TD3Ears);
  LCurrent := Default(TD3Ears);
  LCurrent[0] := 1;
  LLast[1] := 1;
  TD3SpeakerMixer.Mix(2, False, @LMix[0], @LSamples[0], LLast, LCurrent);
  // 4096 steps from the last to the current: the first sample at the last volume, the middle one at half
  Assert.AreEqual(0.0, Double(LMix[0]), 0);
  Assert.AreEqual(1.0, Double(LMix[1]), 0);
  Assert.AreEqual(0.5, Double(LMix[2048 * 2]), 0.001);
  Assert.AreEqual(0.5, Double(LMix[2048 * 2 + 1]), 0.001);
  Assert.IsTrue(LMix[4095 * 2] > 0.99);
end;

procedure TTestD3SpeakerMixer.DovrebbeMixareUnoStereoSuDueAltoparlanti;
var
  LMix: TArray<Single>;
  LSamples: TArray<Single>;
  LVolumes: TD3Ears;
begin
  SetLength(LMix, D3_MIXBUFFER_SAMPLES * 2);
  SetLength(LSamples, D3_MIXBUFFER_SAMPLES * 2);
  LSamples[10 * 2] := 8;
  LSamples[10 * 2 + 1] := 16;
  LVolumes := Default(TD3Ears);
  LVolumes[0] := 0.5;
  LVolumes[1] := 0.25;
  TD3SpeakerMixer.Mix(2, True, @LMix[0], @LSamples[0], LVolumes, LVolumes);
  Assert.AreEqual(4.0, Double(LMix[20]), 0);
  Assert.AreEqual(4.0, Double(LMix[21]), 0);
end;

procedure TTestD3SpeakerMixer.DovrebbeMixareUnMonoSuSeiAltoparlanti;
var
  LMix: TArray<Single>;
  LSamples: TArray<Single>;
  LVolumes: TD3Ears;
  LSpeaker: Integer;
begin
  SetLength(LMix, D3_MIXBUFFER_SAMPLES * 6);
  SetLength(LSamples, D3_MIXBUFFER_SAMPLES);
  LSamples[7] := 2;
  for LSpeaker := 0 to 5 do
    LVolumes[LSpeaker] := (LSpeaker + 1) * 0.5;
  TD3SpeakerMixer.Mix(6, False, @LMix[0], @LSamples[0], LVolumes, LVolumes);
  for LSpeaker := 0 to 5 do
    Assert.AreEqual(2.0 * (LSpeaker + 1) * 0.5, Double(LMix[7 * 6 + LSpeaker]), 0);
end;

procedure TTestD3SpeakerMixer.DovrebbeMixareUnoStereoSuSeiAltoparlantiConLaTabellaDelC;
var
  LMix: TArray<Single>;
  LSamples: TArray<Single>;
  LVolumes: TD3Ears;
  LSpeaker: Integer;
begin
  SetLength(LMix, D3_MIXBUFFER_SAMPLES * 6);
  SetLength(LSamples, D3_MIXBUFFER_SAMPLES * 2);
  LSamples[3 * 2] := 10;
  LSamples[3 * 2 + 1] := 100;
  for LSpeaker := 0 to 5 do
    LVolumes[LSpeaker] := 1;
  TD3SpeakerMixer.Mix(6, True, @LMix[0], @LSamples[0], LVolumes, LVolumes);
  // left: 0, 2, 3, 4; right: 1, 5 (MixSoundSixSpeakerStereo)
  Assert.AreEqual(10.0, Double(LMix[18]), 0);
  Assert.AreEqual(100.0, Double(LMix[19]), 0);
  Assert.AreEqual(10.0, Double(LMix[20]), 0);
  Assert.AreEqual(10.0, Double(LMix[21]), 0);
  Assert.AreEqual(10.0, Double(LMix[22]), 0);
  Assert.AreEqual(100.0, Double(LMix[23]), 0);
end;

procedure TTestD3SpeakerMixer.DovrebbeSommareSenzaCancellareIlBuffer;
var
  LMix: TArray<Single>;
  LSamples: TArray<Single>;
  LVolumes: TD3Ears;
begin
  SetLength(LMix, D3_MIXBUFFER_SAMPLES * 2);
  SetLength(LSamples, D3_MIXBUFFER_SAMPLES);
  LSamples[0] := 3;
  LMix[0] := 100;
  LVolumes := Default(TD3Ears);
  LVolumes[0] := 1;
  TD3SpeakerMixer.Mix(2, False, @LMix[0], @LSamples[0], LVolumes, LVolumes);
  TD3SpeakerMixer.Mix(2, False, @LMix[0], @LSamples[0], LVolumes, LVolumes);
  Assert.AreEqual(106.0, Double(LMix[0]), 0);
end;

procedure TTestD3SpeakerMixer.DovrebbeLimitareECtroncareIn16Bit;
var
  LMix: array[0..7] of Single;
  LOut: array[0..7] of SmallInt;
begin
  LMix[0] := -40000;
  LMix[1] := -32768;
  LMix[2] := -1.9;
  LMix[3] := 0.9;
  LMix[4] := 1.9;
  LMix[5] := 32766.9;
  LMix[6] := 32767;
  LMix[7] := 99999;
  TD3SpeakerMixer.ToSamples(@LOut[0], @LMix[0], 8);
  Assert.AreEqual(-32768, Integer(LOut[0]));
  Assert.AreEqual(-32768, Integer(LOut[1]));
  Assert.AreEqual(-1, Integer(LOut[2]));
  Assert.AreEqual(0, Integer(LOut[3]));
  Assert.AreEqual(1, Integer(LOut[4]));
  Assert.AreEqual(32766, Integer(LOut[5]));
  Assert.AreEqual(32767, Integer(LOut[6]));
  Assert.AreEqual(32767, Integer(LOut[7]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3PortalSpatializer);
  TDUnitX.RegisterTestFixture(TTestD3ChannelGain);
  TDUnitX.RegisterTestFixture(TTestD3SpeakerMixer);

end.
