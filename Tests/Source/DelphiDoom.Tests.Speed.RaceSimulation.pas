{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedRaceSimulation and of the pieces of Speed32      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.RaceSimulation;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.GameData.Intf;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedRaceSimulation = class(TObject)
  strict private
    FLines: TStringList;
    function ThingBytes(const AValues: array of SmallInt): TBytes;
    function CircuitWad(APointCount: Integer; AWithStars: Boolean): IGameWadComposer;
    function FindShareware: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFarFinireUnaGaraSuUnCircuitoFatto;
    [Test]
    procedure DovrebbeDireQuanteAutoHannoFinito;
    [Test]
    procedure DovrebbeFermarsiAlNumeroMassimoDiTic;
    [Test]
    procedure DovrebbeDareFalsoSeIlLivelloNonCe;
    [Test]
    procedure DovrebbeDareFalsoSeIlLivelloNonHaIlPercorso;
    [Test]
    procedure DovrebbeDareFalsoSenzaPosizioniDiPartenza;
    [Test]
    procedure DovrebbeLimitareLeAutoAlleposizioniDiPartenza;
    [Test]
    procedure DovrebbeFareUnaGaraSuLaPistaVeraDellaVersioneShareware;
    [Test]
    procedure DovrebbeRifiutareOggettiNil;
    [Test]
    procedure DovrebbeDareGliAngoliDellaGeometria;
    [Test]
    procedure DovrebbeDareLaDistanzaApprossimataDallaVista;
    [Test]
    procedure DovrebbeContareGliEffettiEDareLaDurataDeiSuoni;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Intf, DelphiDoom.MathCore.Factory,
  DelphiDoom.GameData.Factory, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf,
  DelphiDoom.Speed.RaceSimulation, DelphiDoom.Speed.Sim.Geometry, DelphiDoom.Speed.Sim.Effects,
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf, DelphiDoom.Speed.Factory, DelphiDoom.Speed.Composition;

{ TTestSpeedRaceSimulation }

procedure TTestSpeedRaceSimulation.Setup;
begin
  FLines := TStringList.Create;
end;

procedure TTestSpeedRaceSimulation.TearDown;
begin
  FLines.Free;
end;

function TTestSpeedRaceSimulation.ThingBytes(const AValues: array of SmallInt): TBytes;
begin
  SetLength(Result, Length(AValues) * SizeOf(SmallInt));
  Move(AValues[0], Result[0], Length(Result));
end;

function TTestSpeedRaceSimulation.CircuitWad(APointCount: Integer; AWithStars: Boolean): IGameWadComposer;
var
  LThings: array of SmallInt;
  LPath: TBytes;
  LIndex, LAngle: Integer;
  LRadians: Double;
  LSpeed: Integer;
begin
  Result := TGameDataFactory.CreateWadComposer;
  Result.AddMarker('E1M1');
  SetLength(LThings, 0);
  SetLength(LPath, APointCount * 16);
  FillChar(LPath[0], Length(LPath), 0);
  for LIndex := 0 to APointCount - 1 do
  begin
    LRadians := 2 * Pi * LIndex / APointCount;
    LAngle := (LIndex * (360 div APointCount) + 90) mod 360;
    LAngle := LAngle - LAngle mod 45;
    SetLength(LThings, Length(LThings) + 5);
    LThings[High(LThings) - 4] := Round(2000 + 1200 * Cos(LRadians));
    LThings[High(LThings) - 3] := Round(2000 + 1200 * Sin(LRadians));
    LThings[High(LThings) - 2] := LAngle;
    LThings[High(LThings) - 1] := 512;
    LThings[High(LThings)] := 7;
    LSpeed := 150 * 10240;
    Move(LSpeed, LPath[LIndex * 16 + 12], 4);
  end;
  if AWithStars then
    for LIndex := 0 to 2 do
    begin
      SetLength(LThings, Length(LThings) + 5);
      LThings[High(LThings) - 4] := Round(2000 + 1200 * Cos(-0.15 - LIndex * 0.04));
      LThings[High(LThings) - 3] := Round(2000 + 1200 * Sin(-0.15 - LIndex * 0.04));
      LThings[High(LThings) - 2] := 45;
      LThings[High(LThings) - 1] := 241;
      LThings[High(LThings)] := 7;
    end;
  Result.AddLump('THINGS', ThingBytes(LThings));
  Result.AddLump('LINEDEFS', nil);
  Result.AddLump('PATH', LPath);
end;

function TTestSpeedRaceSimulation.FindShareware: string;
var
  LRoot: string;
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  LCandidates := [TPath.Combine(LRoot, 'bin\Speed\SPEEDH.JCL'), TPath.Combine(LRoot, 'Reference\_dati\speed\SPEEDH.JCL'),
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\Reference\_dati\speed\SPEEDH.JCL'))];
  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

procedure TTestSpeedRaceSimulation.DovrebbeFarFinireUnaGaraSuUnCircuitoFatto;
var
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
begin
  LOptions.Level := 1;
  LOptions.Laps := 1;
  LOptions.CarCount := 3;
  LOptions.MaxTics := 30000;
  LSimulation := TSpeedRaceSimulation.Create(CircuitWad(8, True), TMathCoreFactory.CreateGameRandom);
  try
    Assert.IsTrue(LSimulation.Run(LOptions, FLines), FLines.Text);
  finally
    LSimulation.Free;
  end;
  Assert.IsTrue(Pos('E1M1: 8 points of the path, 3 starting positions', FLines.Text) > 0);
end;

procedure TTestSpeedRaceSimulation.DovrebbeDireQuanteAutoHannoFinito;
var
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
begin
  LOptions.Level := 1;
  LOptions.Laps := 1;
  LOptions.CarCount := 2;
  LOptions.MaxTics := 30000;
  LSimulation := TSpeedRaceSimulation.Create(CircuitWad(8, True), TMathCoreFactory.CreateGameRandom);
  try
    LSimulation.Run(LOptions, FLines);
  finally
    LSimulation.Free;
  end;
  Assert.IsTrue(Pos('2 of 2 cars completed 1 laps', FLines.Text) > 0, FLines.Text);
end;

procedure TTestSpeedRaceSimulation.DovrebbeFermarsiAlNumeroMassimoDiTic;
var
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
begin
  LOptions.Level := 1;
  LOptions.Laps := 1;
  LOptions.CarCount := 2;
  LOptions.MaxTics := 200;
  LSimulation := TSpeedRaceSimulation.Create(CircuitWad(8, True), TMathCoreFactory.CreateGameRandom);
  try
    Assert.IsFalse(LSimulation.Run(LOptions, FLines));
  finally
    LSimulation.Free;
  end;
  Assert.IsTrue(Pos('0 of 2 cars completed 1 laps after 200 tics', FLines.Text) > 0, FLines.Text);
end;

procedure TTestSpeedRaceSimulation.DovrebbeDareFalsoSeIlLivelloNonCe;
var
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
begin
  LOptions.Level := 5;
  LOptions.Laps := 1;
  LOptions.CarCount := 2;
  LOptions.MaxTics := 100;
  LSimulation := TSpeedRaceSimulation.Create(CircuitWad(8, True), TMathCoreFactory.CreateGameRandom);
  try
    Assert.IsFalse(LSimulation.Run(LOptions, FLines));
  finally
    LSimulation.Free;
  end;
  Assert.IsTrue(Pos('The level E1M5 is not in the data', FLines.Text) > 0);
end;

procedure TTestSpeedRaceSimulation.DovrebbeDareFalsoSeIlLivelloNonHaIlPercorso;
var
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
  LWad: IGameWadComposer;
begin
  LWad := TGameDataFactory.CreateWadComposer;
  LWad.AddMarker('E1M1');
  LWad.AddLump('THINGS', ThingBytes([1, 2, 3, 4, 5]));
  LOptions.Level := 1;
  LOptions.Laps := 1;
  LOptions.CarCount := 2;
  LOptions.MaxTics := 100;
  LSimulation := TSpeedRaceSimulation.Create(LWad, TMathCoreFactory.CreateGameRandom);
  try
    Assert.IsFalse(LSimulation.Run(LOptions, FLines));
  finally
    LSimulation.Free;
  end;
  Assert.IsTrue(Pos('has no THINGS or no PATH lump', FLines.Text) > 0);
end;

procedure TTestSpeedRaceSimulation.DovrebbeDareFalsoSenzaPosizioniDiPartenza;
var
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
begin
  LOptions.Level := 1;
  LOptions.Laps := 1;
  LOptions.CarCount := 2;
  LOptions.MaxTics := 100;
  LSimulation := TSpeedRaceSimulation.Create(CircuitWad(8, False), TMathCoreFactory.CreateGameRandom);
  try
    Assert.IsFalse(LSimulation.Run(LOptions, FLines));
  finally
    LSimulation.Free;
  end;
  Assert.IsTrue(Pos('Nothing to race on', FLines.Text) > 0);
end;

procedure TTestSpeedRaceSimulation.DovrebbeLimitareLeAutoAlleposizioniDiPartenza;
var
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
begin
  LOptions.Level := 1;
  LOptions.Laps := 1;
  LOptions.CarCount := 10;
  LOptions.MaxTics := 30000;
  LSimulation := TSpeedRaceSimulation.Create(CircuitWad(8, True), TMathCoreFactory.CreateGameRandom);
  try
    LSimulation.Run(LOptions, FLines);
  finally
    LSimulation.Free;
  end;
  Assert.IsTrue(Pos('3 cars, 1 laps', FLines.Text) > 0, FLines.Text);
end;

procedure TTestSpeedRaceSimulation.DovrebbeFareUnaGaraSuLaPistaVeraDellaVersioneShareware;
var
  LPath: string;
  LPak: TArray<TSpeedPakEntry>;
  LWad: IGameWadComposer;
  LSimulation: TSpeedRaceSimulation;
  LOptions: TSpeedRaceOptions;
begin
  LPath := FindShareware;
  if LPath = '' then
  begin
    Assert.Pass('SPEEDH.JCL is not there');
    Exit;
  end;
  LWad := TSpeedComposition.TranslateGame(LPath, TSpeedComposition.CreateConsoleLog, LPak);
  Assert.IsTrue(Length(LPak) > 0);
  LOptions.Level := 1;
  LOptions.Laps := 1;
  LOptions.CarCount := 8;
  LOptions.MaxTics := 20000;
  LSimulation := TSpeedRaceSimulation.Create(LWad, TMathCoreFactory.CreateGameRandom);
  try
    Assert.IsTrue(LSimulation.Run(LOptions, FLines), FLines.Text);
  finally
    LSimulation.Free;
  end;
  // The first track has 88 points of the path and a lap of 30 to 45 seconds
  Assert.IsTrue(Pos('E1M1: 88 points of the path, 19 starting positions', FLines.Text) > 0, FLines.Text);
  Assert.IsTrue(Pos('8 of 8 cars completed 1 laps', FLines.Text) > 0, FLines.Text);
end;

procedure TTestSpeedRaceSimulation.DovrebbeRifiutareOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedRaceSimulation.Create(nil, TMathCoreFactory.CreateGameRandom);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TSpeedRaceSimulation.Create(TGameDataFactory.CreateWadComposer, nil);
    end, EArgumentNilException);
end;

procedure TTestSpeedRaceSimulation.DovrebbeDareGliAngoliDellaGeometria;
var
  LGeometry: IRacingGeometry;
begin
  LGeometry := TSpeedSimGeometry.Create;
  Assert.AreEqual(Cardinal(0), LGeometry.PointToAngle(0, 0, 100, 0));
  Assert.AreEqual(Cardinal(ANG90), LGeometry.PointToAngle(0, 0, 0, 100));
  Assert.AreEqual(Cardinal(ANG180), LGeometry.PointToAngle(0, 0, -100, 0));
  Assert.AreEqual(Cardinal(ANG270), LGeometry.PointToAngle(0, 0, 0, -100));
end;

procedure TTestSpeedRaceSimulation.DovrebbeDareLaDistanzaApprossimataDallaVista;
var
  LGeometry: TSpeedSimGeometry;
  LReference: IRacingGeometry;
begin
  LGeometry := TSpeedSimGeometry.Create;
  LReference := LGeometry;
  LGeometry.ViewX := 100;
  LGeometry.ViewY := 200;
  Assert.AreEqual(0, LReference.ApproximateDistanceFromView(100, 200));
  Assert.AreEqual(100, LReference.ApproximateDistanceFromView(200, 200));
  // 30 and 40: 70 less half of the smaller one
  Assert.AreEqual(55, LReference.ApproximateDistanceFromView(130, 240));
end;

procedure TTestSpeedRaceSimulation.DovrebbeContareGliEffettiEDareLaDurataDeiSuoni;
var
  LEffects: TSpeedSimEffects;
  LReference: IRacingEffects;
begin
  LEffects := TSpeedSimEffects.Create;
  LReference := LEffects;
  LReference.SpawnParticle(TRacingParticleKind.Spark, 0, 0, 0, 0, 0);
  Assert.IsTrue(LReference.PlayEngineSound(True, 3) > 0);
  Assert.IsTrue(LReference.PlayBrakeSound(0, 0, 0) > 0);
  Assert.AreEqual(1, LEffects.Particles);
  Assert.AreEqual(1, LEffects.EngineSounds);
  Assert.AreEqual(1, LEffects.BrakeSounds);
end;

end.
