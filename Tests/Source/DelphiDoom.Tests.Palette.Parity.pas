{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - parity with the old code          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   The files Tests\Data\Palette\*.golden.txt were written by the old functions of v_palettes.pas,
  ///   v_video.pas, r_main.pas, r_data.pas, r_precalc.pas, r_draw.pas and r_translations.pas,
  ///   copied as they are in a throwaway program (see README.md in that folder), on the
  ///   inputs of TPaletteFixtures and, for the *_real files, on the lumps of the commercial
  ///   WADs of bin\ (those tests are skipped when the WAD is missing). Each line is a key and the
  ///   fingerprint of a table (or a short text): the library has to give the same
  /// </summary>
  [TestFixture]
  [Category('palette')]
  TTestPaletteParity = class(TObject)
  strict private
    FGolden: TDictionary<string, string>;
    FHexen: TDictionary<string, string>;
    FMatcher: IColorMatcher;
    class function DataPath(const AFileName: string): string; static;
    class function Load(const AFileName: string): TDictionary<string, string>; static;
    procedure Check(AGolden: TDictionary<string, string>; const AKey, AActual: string);
    procedure CheckBuild(AGolden: TDictionary<string, string>; const AProfile: TPaletteProfile);
    procedure CheckReal(const AFile, AGame, AFolder, AWad: string; const AProfile: TPaletteProfile);
    class function Fixture(AIndex: Integer): TBytes; static;
    class function FixtureName(AIndex: Integer): string; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestBuildDoomProfileSameAsOld;
    [Test]
    procedure TestBuildHexenProfileSameAsOld;
    [Test]
    procedure TestTranslationBuilderSameAsOld;
    [Test]
    procedure TestBestColorSameAsOld;
    [Test]
    procedure TestApproximateIndexSameAsOld;
    [Test]
    procedure TestUnpackSameAsOld;
    [Test]
    procedure TestBufferFixerSameAsOld;
    [Test]
    procedure TestColormapPreparationSameAsOld;
    [Test]
    procedure TestFogPreparationSameAsOld;
    [Test]
    procedure TestLightTablesSameAsOld;
    [Test]
    procedure TestGammaSameAsOld;
    [Test]
    procedure TestPrecalcSameAsOld;
    [Test]
    procedure TestPlayerTranslationsSameAsOld;
    [Test]
    procedure TestTranslationNamesSameAsOld;
    [Test]
    procedure TestRealDoomWadSameAsOld;
    [Test]
    procedure TestRealHereticWadSameAsOld;
    [Test]
    procedure TestRealStrifeWadSameAsOld;
    [Test]
    procedure TestRealHexenWadSameAsOld;
  end;

implementation

uses
  DelphiDoom.Palette.Profiles, DelphiDoom.Palette.Factory, DelphiDoom.Palette.TranslationBlood,
  DelphiDoom.Video.Factory,
  DelphiDoom.Tests.Palette.Digest, DelphiDoom.Tests.Palette.Fixtures;

const
  FIXTURE_COUNT = 4;

{ TTestPaletteParity }

class function TTestPaletteParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Palette\' + AFileName));
end;

class function TTestPaletteParity.Load(const AFileName: string): TDictionary<string, string>;
var
  LLines: TStringList;
  LIndex: Integer;
  LSeparator: Integer;
begin
  Result := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(DataPath(AFileName));
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LSeparator := Pos('=', LLines[LIndex]);
      if LSeparator > 1 then
        Result.Add(Copy(LLines[LIndex], 1, LSeparator - 1), Copy(LLines[LIndex], LSeparator + 1, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

class function TTestPaletteParity.Fixture(AIndex: Integer): TBytes;
begin
  case AIndex of
    0: Result := TPaletteFixtures.Palette8(11);
    1: Result := TPaletteFixtures.Palette8(22);
    2: Result := TPaletteFixtures.Palette6(33);
  else
    Result := TPaletteFixtures.PaletteWithRamp(44);
  end;
end;

class function TTestPaletteParity.FixtureName(AIndex: Integer): string;
begin
  case AIndex of
    0: Result := 'p8a';
    1: Result := 'p8b';
    2: Result := 'p6';
  else
    Result := 'ramp';
  end;
end;

procedure TTestPaletteParity.Setup;
begin
  FGolden := Load('palette.golden.txt');
  FHexen := Load('palette_hexen.golden.txt');
  FMatcher := TPaletteFactory.CreateColorMatcher;
end;

procedure TTestPaletteParity.TearDown;
begin
  FGolden.Free;
  FHexen.Free;
  FMatcher := nil;
end;

procedure TTestPaletteParity.Check(AGolden: TDictionary<string, string>; const AKey, AActual: string);
var
  LExpected: string;
begin
  Assert.IsTrue(AGolden.TryGetValue(AKey, LExpected), 'chiave assente nel golden: ' + AKey);
  Assert.AreEqual(LExpected, AActual, AKey);
end;

procedure TTestPaletteParity.CheckBuild(AGolden: TDictionary<string, string>;
  const AProfile: TPaletteProfile);
var
  LIndex: Integer;
  LSet: TPaletteSet;
  LPrefix: string;
begin
  for LIndex := 0 to FIXTURE_COUNT - 1 do
  begin
    LPrefix := 'build.' + FixtureName(LIndex);
    LSet := TPaletteFactory.CreatePaletteBuilder(FMatcher, AProfile).Build(Fixture(LIndex), True, True);
    Check(AGolden, LPrefix + '.base', TPaletteDigest.OfBytes(LSet.BasePalette));
    Check(AGolden, LPrefix + '.playpal', TPaletteDigest.OfBytes(LSet.Playpal));
    Check(AGolden, LPrefix + '.colormap', TPaletteDigest.OfBytes(LSet.Colormap));
    Check(AGolden, LPrefix + '.fogmap', TPaletteDigest.OfBytes(LSet.Fogmap));
  end;
end;

procedure TTestPaletteParity.TestBuildDoomProfileSameAsOld;
begin
  CheckBuild(FGolden, TPaletteProfiles.Doom);
end;

procedure TTestPaletteParity.TestBuildHexenProfileSameAsOld;
begin
  CheckBuild(FHexen, TPaletteProfiles.Hexen);
end;

procedure TTestPaletteParity.TestTranslationBuilderSameAsOld;
var
  LBuilder: ITranslationBuilder;
  A: Integer;
  B: Integer;
begin
  LBuilder := TPaletteFactory.CreateTranslationBuilder(FMatcher);
  for A := 0 to FIXTURE_COUNT - 1 do
    for B := 0 to FIXTURE_COUNT - 1 do
      Check(FGolden, 'translate.' + FixtureName(A) + '.' + FixtureName(B),
        TPaletteDigest.OfBytes(LBuilder.Build(Fixture(A), Fixture(B))));
end;

procedure TTestPaletteParity.TestBestColorSameAsOld;
const
  LOWS: array[0..3] of Integer = (0, 16, 0, 100);
  HIGHS: array[0..3] of Integer = (255, 239, 0, 100);
var
  LIndex: Integer;
  K: Integer;
  R: Integer;
  G: Integer;
  B: Integer;
  LPalette: TBytes;
  LBytes: TBytes;
begin
  for LIndex := 0 to FIXTURE_COUNT - 1 do
  begin
    LPalette := Fixture(LIndex);
    for K := 0 to High(LOWS) do
    begin
      LBytes := nil;
      for R := 0 to 5 do
        for G := 0 to 5 do
          for B := 0 to 5 do
          begin
            SetLength(LBytes, Length(LBytes) + 1);
            LBytes[High(LBytes)] := FMatcher.BestColor(R * 51, G * 51, B * 51, LPalette, LOWS[K], HIGHS[K]);
          end;
      Check(FGolden, Format('best.%s.%d-%d', [FixtureName(LIndex), LOWS[K], HIGHS[K]]),
        TPaletteDigest.OfBytes(LBytes));
    end;
  end;
end;

procedure TTestPaletteParity.TestApproximateIndexSameAsOld;
const
  LOWS: array[0..2] of Integer = (1, 0, 16);
  HIGHS: array[0..2] of Integer = (255, 255, 200);
var
  LIndex: Integer;
  K: Integer;
  P: Integer;
  LColors: TArray<Cardinal>;
  LProbe: TArray<Cardinal>;
  LInts: TArray<Integer>;
begin
  LProbe := TPaletteFixtures.ProbeColors;
  for LIndex := 0 to FIXTURE_COUNT - 1 do
  begin
    LColors := TPaletteFixtures.PackedColors(Fixture(LIndex));
    LInts := nil;
    for K := 0 to High(LOWS) do
      for P := 0 to High(LProbe) do
      begin
        SetLength(LInts, Length(LInts) + 1);
        LInts[High(LInts)] := FMatcher.FindApproximateIndex(LColors, LProbe[P], LOWS[K], HIGHS[K]);
      end;
    Check(FGolden, 'approx.' + FixtureName(LIndex), TPaletteDigest.OfIntegers(LInts));
  end;
end;

procedure TTestPaletteParity.TestUnpackSameAsOld;
var
  LUnpacker: IPaletteUnpacker;
  LIndex: Integer;
begin
  LUnpacker := TPaletteFactory.CreatePaletteUnpacker(TVideoFactory.CreatePaletteConverter);
  for LIndex := 0 to FIXTURE_COUNT - 1 do
    Check(FGolden, 'unpack.' + FixtureName(LIndex), TPaletteDigest.OfCardinals(LUnpacker.Unpack(Fixture(LIndex))));
end;

procedure TTestPaletteParity.TestBufferFixerSameAsOld;
const
  FROMS: array[0..4] of Integer = (0, 5, 0, 10, 1);
  TOS: array[0..4] of Integer = (99, 50, 0, 10, 99);
var
  K: Integer;
  LBuffer: TBytes;
  LFixer: IPaletteBufferFixer;
begin
  LFixer := TPaletteFactory.CreateBufferFixer;
  for K := 0 to High(FROMS) do
  begin
    LBuffer := TPaletteFixtures.RandomBytes(55, 100, $FF);
    LFixer.Fix(LBuffer, FROMS[K], TOS[K]);
    Check(FGolden, Format('fixbuf.%d-%d', [FROMS[K], TOS[K]]), TPaletteDigest.OfBytes(LBuffer));
  end;
end;

procedure TTestPaletteParity.TestColormapPreparationSameAsOld;
const
  LENGTHS: array[0..5] of Integer = (256, 300, 1792, 8192, 8200, 8714);
  BLACK = 186;
var
  LPreparer: IColormapPreparer;
  LSource: TBytes;
  LColors: TArray<Cardinal>;
  K: Integer;
  LName: string;
  LMap: TBytes;
  LCount: Integer;
begin
  LPreparer := TPaletteFactory.CreateColormapPreparer;
  LSource := TPaletteFixtures.Colormap(66, 40);
  LColors := TPaletteFixtures.PackedColors(Fixture(0));
  for K := 0 to High(LENGTHS) do
  begin
    LName := IntToStr(LENGTHS[K]);
    LMap := LPreparer.ReplaceZeros(Copy(LSource, 0, LENGTHS[K]), BLACK);
    Check(FGolden, 'colormap.zeros.' + LName, TPaletteDigest.OfBytes(LMap));
    LMap := LPreparer.ExpandRows(LMap, COLORMAP_MIN_ROWS, LCount);
    Check(FGolden, 'colormap.expand.' + LName, TPaletteDigest.OfBytes(LMap));
    Check(FGolden, 'colormap.expand.' + LName + '.count', IntToStr(LCount));
    Check(FGolden, 'colormap.row0.' + LName, TPaletteDigest.OfCardinals(LPreparer.RowColors(LMap, 0, LColors)));
    if Length(LMap) >= 33 * 256 then
      Check(FGolden, 'colormap.row32.' + LName, TPaletteDigest.OfCardinals(LPreparer.RowColors(LMap, 32, LColors)));
  end;
end;

procedure TTestPaletteParity.TestFogPreparationSameAsOld;
const
  BLACK = 186;
var
  LPreparer: IColormapPreparer;
  LColors: TArray<Cardinal>;
  LColormap: TBytes;
  LFog: TBytes;
  LData: TFogMapData;
  F: Integer;
begin
  LPreparer := TPaletteFactory.CreateColormapPreparer;
  LColors := TPaletteFixtures.PackedColors(Fixture(0));
  LColormap := LPreparer.ReplaceZeros(TPaletteFixtures.Colormap(77, 34), BLACK);
  for F := 0 to 1 do
  begin
    LFog := TPaletteFixtures.Colormap(88, 34);
    if F = 1 then
      LFog := Copy(LFog, 0, 20 * 256);
    LData := LPreparer.PrepareFog(LFog, LColormap, BLACK, LColors);
    Check(FGolden, 'fog.' + IntToStr(F) + '.indexes', TPaletteDigest.OfBytes(LData.Indexes));
    Check(FGolden, 'fog.' + IntToStr(F) + '.colors', TPaletteDigest.OfCardinals(LData.Colors));
  end;
end;

procedure TTestPaletteParity.TestLightTablesSameAsOld;
const
  VIEWS: array[0..4, 0..1] of Integer = ((320, 320), (200, 320), (640, 640), (1024, 1280), (96, 320));
var
  LCalculator: ILightTableCalculator;
  LConfig: TLightTableConfig;
  LZ: TArray<Integer>;
  LHi: TArray<Integer>;
  K: Integer;
begin
  LCalculator := TPaletteFactory.CreateLightTableCalculator;
  LConfig := TLightTableConfig.Default;
  LZ := LCalculator.ZLight(LConfig);
  Check(FGolden, 'light.z', TPaletteDigest.OfIntegers(LZ));
  Check(FGolden, 'light.z.sample', Format('%d,%d,%d,%d', [LZ[0], LZ[127], LZ[15 * 128], LZ[15 * 128 + 127]]));
  LHi := LCalculator.HiResZLight(LConfig);
  Check(FGolden, 'light.hires', TPaletteDigest.OfIntegers(LHi));
  Check(FGolden, 'light.hires.sample',
    Format('%d,%d,%d,%d', [LHi[0], LHi[8191], LHi[15 * 8192], LHi[15 * 8192 + 8191]]));
  for K := 0 to High(VIEWS) do
    Check(FGolden, Format('light.scale.%d.%d', [VIEWS[K, 0], VIEWS[K, 1]]),
      TPaletteDigest.OfIntegers(LCalculator.ScaleLight(LConfig, VIEWS[K, 0], VIEWS[K, 1])));
end;

procedure TTestPaletteParity.TestGammaSameAsOld;
var
  LGamma: IGammaTables;
  K: Integer;
begin
  LGamma := TPaletteFactory.CreateGammaTables;
  for K := 0 to 4 do
    Check(FGolden, 'gamma.' + IntToStr(K), TPaletteDigest.OfBytes(LGamma.Table(K)));
end;

procedure TTestPaletteParity.TestPrecalcSameAsOld;
const
  PROBES: array[0..9] of Integer = (0, 255, 256, 65535, 65536, 70000, 1 shl 20, -1, -65536, MaxInt);
var
  LTables: IPrecalcTables;
  K: Integer;
begin
  LTables := TPaletteFactory.CreatePrecalcTables;
  for K := 0 to 2 do
  begin
    Check(FGolden, 'precalc.mul.' + IntToStr(K), TPaletteDigest.OfIntegers(LTables.Multiply(K)));
    Check(FGolden, 'precalc.fog.' + IntToStr(K), TPaletteDigest.OfIntegers(LTables.Fog(K)));
  end;
  Check(FGolden, 'precalc.tolong', TPaletteDigest.OfCardinals(LTables.ByteToLong));
  Check(FGolden, 'precalc.toword', TPaletteDigest.OfCardinals(LTables.ByteToWord));
  Check(FGolden, 'precalc.ic', TPaletteDigest.OfCardinals(LTables.InverseColor));
  for K := 0 to 3 do
    Check(FGolden, 'precalc.avg.' + IntToStr(K), TPaletteDigest.OfCardinals(LTables.Average(K)));
  Check(FGolden, 'precalc.add', TPaletteDigest.OfBytes(LTables.AddClamp));
  for K := 0 to High(PROBES) do
    Check(FGolden, 'precalc.lightindex.' + IntToStr(K), IntToStr(LTables.LightIndex(PROBES[K])));
end;

procedure TTestPaletteParity.TestPlayerTranslationsSameAsOld;
begin
  Check(FGolden, 'player.doom', TPaletteDigest.OfBytes(TPaletteFactory.CreateDoomPlayerTranslations.Build));
  Check(FGolden, 'player.heretic', TPaletteDigest.OfBytes(TPaletteFactory.CreateHereticPlayerTranslations.Build));
  Check(FGolden, 'player.strife', TPaletteDigest.OfBytes(TPaletteFactory.CreateStrifePlayerTranslations.Build));
end;

procedure TTestPaletteParity.TestTranslationNamesSameAsOld;
var
  LNames: ITranslationNames;
  LProbe: TArray<string>;
  K: Integer;
  LKey: string;
  LSlot: Integer;
  LNew: string;
  LCandidates: string;
  LCandidate: string;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  LProbe := TPaletteFixtures.ProbeNames;
  for K := 0 to High(LProbe) do
  begin
    LSlot := LNames.FindSlot(LProbe[K], LKey);
    LNew := '0';
    // as the harness: a name with FOO "loads" and gets a new slot
    if (LSlot < 0) and (Pos('FOO', UpperCase(LProbe[K])) > 0) then
    begin
      LSlot := LNames.AddSlot(LKey);
      LNew := '1';
    end;
    Check(FGolden, 'names.find.' + IntToStr(K), Format('%d|%s|%s', [LSlot, LKey, LNew]));
    LCandidates := '';
    for LCandidate in LNames.LumpCandidates(LProbe[K]) do
      LCandidates := LCandidates + '|' + LCandidate;
    Check(FGolden, 'names.cand.' + IntToStr(K), LCandidates);
    Check(FGolden, 'names.bloodid.' + IntToStr(K), IntToStr(TTranslationBlood.IdForName(LProbe[K])));
  end;
  for K := -1 to 10 do
  begin
    Check(FGolden, 'names.bloodname.' + IntToStr(K), TTranslationBlood.NameOf(K));
    Check(FGolden, 'names.bloodregion.' + IntToStr(K), IntToStr(TTranslationBlood.Region(K)));
  end;
end;

procedure TTestPaletteParity.CheckReal(const AFile, AGame, AFolder, AWad: string;
  const AProfile: TPaletteProfile);
var
  LGolden: TDictionary<string, string>;
  LPath: string;
  LPlaypal: TBytes;
  LColormap: TBytes;
  LFogLump: TBytes;
  LSet: TPaletteSet;
  LPrefix: string;
  LColors: TArray<Cardinal>;
  LBlack: Integer;
  LPreparer: IColormapPreparer;
  LFog: TFogMapData;
begin
  LPath := TPaletteFixtures.WadPath(AFolder, AWad);
  if not TPaletteFixtures.ReadLump(LPath, 'PLAYPAL', LPlaypal) then
  begin
    Assert.Pass('WAD mancante, test saltato: ' + LPath);
    Exit;
  end;
  LGolden := Load(AFile);
  try
    LPrefix := 'real.' + AGame;
    Check(LGolden, LPrefix + '.playpal.in', TPaletteDigest.OfBytes(Copy(LPlaypal, 0, 768)));
    LSet := TPaletteFactory.CreatePaletteBuilder(FMatcher, AProfile).Build(LPlaypal, True, True);
    Check(LGolden, LPrefix + '.base', TPaletteDigest.OfBytes(LSet.BasePalette));
    Check(LGolden, LPrefix + '.playpal', TPaletteDigest.OfBytes(LSet.Playpal));
    Check(LGolden, LPrefix + '.colormap', TPaletteDigest.OfBytes(LSet.Colormap));
    Check(LGolden, LPrefix + '.fogmap', TPaletteDigest.OfBytes(LSet.Fogmap));

    LColors := TPaletteFixtures.PackedColors(LPlaypal);
    LBlack := FMatcher.FindApproximateIndex(LColors, $0, 1, 255);
    Check(LGolden, LPrefix + '.black', IntToStr(LBlack));
    Check(LGolden, LPrefix + '.red', IntToStr(FMatcher.FindApproximateIndex(LColors, $FF0000, 1, 255)));
    Check(LGolden, LPrefix + '.unpack', TPaletteDigest.OfCardinals(LColors));
    LPreparer := TPaletteFactory.CreateColormapPreparer;
    if TPaletteFixtures.ReadLump(LPath, 'COLORMAP', LColormap) then
    begin
      LColormap := LPreparer.ReplaceZeros(LColormap, Byte(LBlack));
      Check(LGolden, LPrefix + '.lump.colormap', TPaletteDigest.OfBytes(LColormap));
      if Length(LColormap) >= 33 * 256 then
        Check(LGolden, LPrefix + '.lump.inverse',
          TPaletteDigest.OfCardinals(LPreparer.RowColors(LColormap, 32, LColors)));
      if TPaletteFixtures.ReadLump(LPath, 'FOGMAP', LFogLump) and (Length(LFogLump) <= Length(LColormap)) then
      begin
        LFog := LPreparer.PrepareFog(LFogLump, LColormap, Byte(LBlack), LColors);
        Check(LGolden, LPrefix + '.lump.fog', TPaletteDigest.OfBytes(LFog.Indexes));
        Check(LGolden, LPrefix + '.lump.fogcolors', TPaletteDigest.OfCardinals(LFog.Colors));
      end;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestPaletteParity.TestRealDoomWadSameAsOld;
begin
  CheckReal('palette_real.golden.txt', 'doom', 'Doom', 'DOOM1.WAD', TPaletteProfiles.Doom);
end;

procedure TTestPaletteParity.TestRealHereticWadSameAsOld;
begin
  CheckReal('palette_real.golden.txt', 'heretic', 'Heretic', 'HERETIC1.WAD', TPaletteProfiles.Doom);
end;

procedure TTestPaletteParity.TestRealStrifeWadSameAsOld;
begin
  CheckReal('palette_real.golden.txt', 'strife', 'Strife', 'STRIFE0.WAD', TPaletteProfiles.Doom);
end;

procedure TTestPaletteParity.TestRealHexenWadSameAsOld;
begin
  CheckReal('palette_hexen_real.golden.txt', 'hexen', 'Hexen', 'HEXEN.WAD', TPaletteProfiles.Hexen);
end;

end.
