{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - behaviours of the classes         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.Behavior;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf,
  DelphiDoom.Video.Intf;

type
  /// <summary>Descriptions: each test says what the class "dovrebbe" do, in its name and comment</summary>
  [TestFixture]
  [Category('palette')]
  TTestPaletteBehavior = class(TObject)
  public
    // --- the matcher
    [Test]
    procedure TestMatcherTakesTheExactColorAtOnce;
    [Test]
    procedure TestMatcherTakesTheFirstOfTwoEqualDistances;
    [Test]
    procedure TestMatcherFallsBackToZeroWhenEverythingIsFar;
    [Test]
    procedure TestMatcherRejectsARangeOutsideThePalette;
    [Test]
    procedure TestApproximateIndexKeepsTheFirstOfTheEquals;
    [Test]
    procedure TestApproximateIndexRejectsABadRange;
    // --- the profiles and the builder (with a fake matcher)
    [Test]
    procedure TestProfilesDescribeTheNumberOfPalettes;
    [Test]
    procedure TestBuilderCopiesTheBasePaletteFirst;
    [Test]
    procedure TestBuilderScalesAPaletteOfSixBits;
    [Test]
    procedure TestBuilderLeavesAPaletteOfEightBitsAlone;
    [Test]
    procedure TestBuilderDoesNotTouchItsInput;
    [Test]
    procedure TestBuilderRejectsAShortPalette;
    [Test]
    procedure TestBuilderWithoutColormapGivesNone;
    [Test]
    procedure TestBuilderAsksTheMatcherForEveryEntryOfTheColormap;
    [Test]
    procedure TestBuilderLeavesTheBlackRowAtZero;
    [Test]
    procedure TestHexenShadesTheLastColorAsTheFirst;
    [Test]
    procedure TestDoomShadesTheLastColorAsItself;
    [Test]
    procedure TestRadiationShiftOfDoomStaysInTheByte;
    // --- translation tables
    [Test]
    procedure TestTranslationAsksTheMatcherForEveryColorOfTheTargetPalette;
    [Test]
    procedure TestTranslationRejectsAShortTargetPalette;
    [Test]
    procedure TestIdentityTableChangesNothing;
    [Test]
    procedure TestDoomPlayerTablesMapTheGreenRamp;
    [Test]
    procedure TestHereticPlayerTablesChangeNothing;
    [Test]
    procedure TestStrifePlayerTablesWrapUnderZero;
    [Test]
    procedure TestStrifeRunningColorsGrowWithTheIndex;
    // --- gamma
    [Test]
    procedure TestGammaHasFiveLevels;
    [Test]
    procedure TestGammaRejectsAMissingLevel;
    [Test]
    procedure TestGammaGivesACopy;
    // --- colormaps
    [Test]
    procedure TestReplaceZerosDoesNotChangeTheInput;
    [Test]
    procedure TestExpandRepeatsTheLastRow;
    [Test]
    procedure TestExpandKeepsAColormapThatIsBigEnough;
    [Test]
    procedure TestExpandRejectsLessThanARow;
    [Test]
    procedure TestRowColorsRejectsAMissingRow;
    [Test]
    procedure TestFogBecomesBlackWhereTheColormapIsBlack;
    [Test]
    procedure TestFogLongerThanTheColormapIsRejected;
    // --- light tables
    [Test]
    procedure TestScaleLightRejectsAViewWithoutWidth;
    [Test]
    procedure TestZLightStaysInsideTheColormaps;
    [Test]
    procedure TestBrighterLevelsUseLowerColormaps;
    [Test]
    procedure TestHiResLightStaysInsideTheFixedUnit;
    // --- names
    [Test]
    procedure TestNamesFindTheRegionsWithAndWithoutPrefix;
    [Test]
    procedure TestNamesStripThePrefixesOneAfterTheOther;
    [Test]
    procedure TestNamesGiveNewSlotsAfterTheRegions;
    [Test]
    procedure TestLumpCandidatesForAPlainName;
    [Test]
    procedure TestLumpCandidatesForAPrefixedName;
    [Test]
    procedure TestBloodIdAcceptsNumbersAndNames;
    [Test]
    procedure TestBloodIdOfAnUnknownNameIsZero;
    [Test]
    procedure TestBloodNameOfRedIsEmpty;
    [Test]
    procedure TestBloodRegionOfRedIsNone;
    // --- precalc and the others
    [Test]
    procedure TestPrecalcRejectsAMissingChannel;
    [Test]
    procedure TestLightIndexIsClamped;
    [Test]
    procedure TestAddClampSaturates;
    [Test]
    procedure TestBufferFixerKeepsTheFirstPixel;
    [Test]
    procedure TestBufferFixerRejectsAnEndOutsideTheBuffer;
    [Test]
    procedure TestUnpackerUsesAGammaThatChangesNothing;
    [Test]
    procedure TestUnpackerRejectsAShortPalette;
    [Test]
    procedure TestFactoryCreatesEveryService;
  end;

implementation

uses
  DelphiDoom.Palette.Profiles, DelphiDoom.Palette.Factory, DelphiDoom.Tests.Palette.Fakes,
  DelphiDoom.Tests.Palette.Fixtures;

function FlatPalette(AValue: Byte): TBytes;
begin
  SetLength(Result, PALETTE_BYTE_COUNT);
  FillChar(Result[0], PALETTE_BYTE_COUNT, AValue);
end;

{ TTestPaletteBehavior }

procedure TTestPaletteBehavior.TestMatcherTakesTheExactColorAtOnce;
var
  LPalette: TBytes;
begin
  LPalette := FlatPalette(200);
  LPalette[3 * 5] := 10;
  LPalette[3 * 5 + 1] := 20;
  LPalette[3 * 5 + 2] := 30;
  Assert.AreEqual(5, Integer(TPaletteFactory.CreateColorMatcher.BestColor(10, 20, 30, LPalette, 0, 255)));
end;

procedure TTestPaletteBehavior.TestMatcherTakesTheFirstOfTwoEqualDistances;
var
  LPalette: TBytes;
begin
  LPalette := FlatPalette(100);
  Assert.AreEqual(0, Integer(TPaletteFactory.CreateColorMatcher.BestColor(90, 90, 90, LPalette, 0, 255)));
  Assert.AreEqual(7, Integer(TPaletteFactory.CreateColorMatcher.BestColor(90, 90, 90, LPalette, 7, 255)));
end;

procedure TTestPaletteBehavior.TestMatcherFallsBackToZeroWhenEverythingIsFar;
var
  LPalette: TBytes;
begin
  // the black (1, 1, 1) against a palette of white: farther than twice its own length, so 0
  LPalette := FlatPalette(255);
  Assert.AreEqual(0, Integer(TPaletteFactory.CreateColorMatcher.BestColor(1, 1, 1, LPalette, 3, 255)));
end;

procedure TTestPaletteBehavior.TestMatcherRejectsARangeOutsideThePalette;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateColorMatcher.BestColor(0, 0, 0, FlatPalette(0), 0, 256);
    end, EPaletteException);
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateColorMatcher.BestColor(0, 0, 0, FlatPalette(0), 10, 5);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestApproximateIndexKeepsTheFirstOfTheEquals;
var
  LColors: TArray<Cardinal>;
  LIndex: Integer;
begin
  SetLength(LColors, 256);
  for LIndex := 0 to 255 do
    LColors[LIndex] := $101010;
  Assert.AreEqual(2, TPaletteFactory.CreateColorMatcher.FindApproximateIndex(LColors, $000000, 2, 255));
  LColors[9] := $000000;
  Assert.AreEqual(9, TPaletteFactory.CreateColorMatcher.FindApproximateIndex(LColors, $000000, 1, 255));
end;

procedure TTestPaletteBehavior.TestApproximateIndexRejectsABadRange;
var
  LColors: TArray<Cardinal>;
begin
  SetLength(LColors, 10);
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateColorMatcher.FindApproximateIndex(LColors, 0, 0, 10);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestProfilesDescribeTheNumberOfPalettes;
begin
  Assert.AreEqual(14, TPaletteProfiles.Doom.PaletteCount);
  Assert.AreEqual(13, Length(TPaletteProfiles.Doom.Shifts));
  Assert.AreEqual(28, TPaletteProfiles.Hexen.PaletteCount);
  Assert.AreEqual(27, Length(TPaletteProfiles.Hexen.Shifts));
  Assert.IsTrue(TPaletteProfiles.Doom.InvertedGrayRow);
  Assert.IsFalse(TPaletteProfiles.Hexen.InvertedGrayRow);
end;

procedure TTestPaletteBehavior.TestBuilderCopiesTheBasePaletteFirst;
var
  LSet: TPaletteSet;
  LBase: TBytes;
begin
  LBase := TPaletteFixtures.PaletteWithRamp(1);
  LSet := TPaletteFactory.CreatePaletteBuilder(TFakeColorMatcher.Create(0), TPaletteProfiles.Doom)
    .Build(LBase, False, False);
  Assert.AreEqual(14 * 768, Length(LSet.Playpal));
  Assert.IsTrue(CompareMem(@LBase[0], @LSet.Playpal[0], 768));
end;

procedure TTestPaletteBehavior.TestBuilderScalesAPaletteOfSixBits;
var
  LBase: TBytes;
  LSet: TPaletteSet;
begin
  LBase := TPaletteFixtures.Palette6(5);
  LSet := TPaletteFactory.CreatePaletteBuilder(TFakeColorMatcher.Create(0), TPaletteProfiles.Doom)
    .Build(LBase, False, False);
  Assert.AreEqual(Integer(LBase[10]) * 4, Integer(LSet.BasePalette[10]));
  Assert.AreEqual(Integer(LBase[767]) * 4, Integer(LSet.Playpal[767]));
end;

procedure TTestPaletteBehavior.TestBuilderLeavesAPaletteOfEightBitsAlone;
var
  LBase: TBytes;
  LSet: TPaletteSet;
begin
  LBase := FlatPalette(64);
  LSet := TPaletteFactory.CreatePaletteBuilder(TFakeColorMatcher.Create(0), TPaletteProfiles.Doom)
    .Build(LBase, False, False);
  Assert.AreEqual(64, Integer(LSet.BasePalette[10]));
end;

procedure TTestPaletteBehavior.TestBuilderDoesNotTouchItsInput;
var
  LBase: TBytes;
  LCopy: TBytes;
begin
  LBase := TPaletteFixtures.Palette6(5);
  LCopy := Copy(LBase);
  TPaletteFactory.CreatePaletteBuilder(TFakeColorMatcher.Create(0), TPaletteProfiles.Doom)
    .Build(LBase, False, False);
  Assert.IsTrue(CompareMem(@LBase[0], @LCopy[0], 768));
end;

procedure TTestPaletteBehavior.TestBuilderRejectsAShortPalette;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreatePaletteBuilder(TFakeColorMatcher.Create(0), TPaletteProfiles.Doom)
        .Build(TBytes.Create(1, 2, 3), True, True);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestBuilderWithoutColormapGivesNone;
var
  LSet: TPaletteSet;
  LMatcher: TFakeColorMatcher;
  LIntf: IColorMatcher;
begin
  LMatcher := TFakeColorMatcher.Create(0);
  LIntf := LMatcher;
  LSet := TPaletteFactory.CreatePaletteBuilder(LIntf, TPaletteProfiles.Doom)
    .Build(TPaletteFixtures.Palette8(1), False, False);
  Assert.AreEqual(0, Length(LSet.Colormap));
  Assert.AreEqual(0, Length(LSet.Fogmap));
  Assert.AreEqual(0, LMatcher.Calls.Count);
end;

procedure TTestPaletteBehavior.TestBuilderAsksTheMatcherForEveryEntryOfTheColormap;
var
  LSet: TPaletteSet;
  LMatcher: TFakeColorMatcher;
  LIntf: IColorMatcher;
begin
  LMatcher := TFakeColorMatcher.Create(77);
  LIntf := LMatcher;
  LSet := TPaletteFactory.CreatePaletteBuilder(LIntf, TPaletteProfiles.Doom)
    .Build(TPaletteFixtures.Palette8(1), True, False);
  // 32 lights and the gray row: 33 rows of 256 questions, the 34th row is not asked
  Assert.AreEqual(33 * 256, LMatcher.Calls.Count);
  Assert.AreEqual(34 * 256, Length(LSet.Colormap));
  Assert.AreEqual(77, Integer(LSet.Colormap[0]));
  Assert.AreEqual(77, Integer(LSet.Colormap[32 * 256 + 255]));
  Assert.AreEqual(0, LMatcher.Calls[0].Low);
  Assert.AreEqual(255, LMatcher.Calls[0].High);
end;

procedure TTestPaletteBehavior.TestBuilderLeavesTheBlackRowAtZero;
var
  LSet: TPaletteSet;
  LIndex: Integer;
begin
  LSet := TPaletteFactory.CreatePaletteBuilder(TFakeColorMatcher.Create(77), TPaletteProfiles.Doom)
    .Build(TPaletteFixtures.Palette8(1), True, True);
  for LIndex := 0 to 255 do
  begin
    Assert.AreEqual(0, Integer(LSet.Colormap[33 * 256 + LIndex]));
    Assert.AreEqual(0, Integer(LSet.Fogmap[33 * 256 + LIndex]));
  end;
end;

procedure TTestPaletteBehavior.TestHexenShadesTheLastColorAsTheFirst;
var
  LMatcher: TFakeColorMatcher;
  LIntf: IColorMatcher;
  LPalette: TBytes;
begin
  LPalette := FlatPalette(200);
  LPalette[0] := 100;
  LPalette[1] := 100;
  LPalette[2] := 100;
  LMatcher := TFakeColorMatcher.Create(0);
  LIntf := LMatcher;
  TPaletteFactory.CreatePaletteBuilder(LIntf, TPaletteProfiles.Hexen).Build(LPalette, True, False);
  // light 0, color 255: the shade of 100, not of 200
  Assert.AreEqual(100, Integer(LMatcher.Calls[255].Red));
  Assert.AreEqual(200, Integer(LMatcher.Calls[254].Red));
end;

procedure TTestPaletteBehavior.TestDoomShadesTheLastColorAsItself;
var
  LMatcher: TFakeColorMatcher;
  LIntf: IColorMatcher;
  LPalette: TBytes;
begin
  LPalette := FlatPalette(200);
  LPalette[0] := 100;
  LMatcher := TFakeColorMatcher.Create(0);
  LIntf := LMatcher;
  TPaletteFactory.CreatePaletteBuilder(LIntf, TPaletteProfiles.Doom).Build(LPalette, True, False);
  Assert.AreEqual(200, Integer(LMatcher.Calls[255].Red));
end;

procedure TTestPaletteBehavior.TestRadiationShiftOfDoomStaysInTheByte;
var
  LSet: TPaletteSet;
  LIndex: Integer;
begin
  LSet := TPaletteFactory.CreatePaletteBuilder(TFakeColorMatcher.Create(0), TPaletteProfiles.Doom)
    .Build(FlatPalette(255), False, False);
  // 255 + ((256 - 255) * 1) div 8 = 255; red and blue go toward 0 by an eighth
  for LIndex := 0 to 255 do
  begin
    Assert.AreEqual(255 - 255 div 8, Integer(LSet.Playpal[13 * 768 + LIndex * 3]));
    Assert.AreEqual(255, Integer(LSet.Playpal[13 * 768 + LIndex * 3 + 1]));
  end;
end;

procedure TTestPaletteBehavior.TestTranslationAsksTheMatcherForEveryColorOfTheTargetPalette;
var
  LMatcher: TFakeColorMatcher;
  LIntf: IColorMatcher;
  LTarget: TBytes;
  LTable: TBytes;
begin
  LMatcher := TFakeColorMatcher.Create(9);
  LIntf := LMatcher;
  LTarget := TPaletteFixtures.Palette8(3);
  LTable := TPaletteFactory.CreateTranslationBuilder(LIntf).Build(TPaletteFixtures.Palette8(4), LTarget);
  Assert.AreEqual(256, Length(LTable));
  Assert.AreEqual(256, LMatcher.Calls.Count);
  Assert.AreEqual(Integer(LTarget[3 * 100 + 1]), Integer(LMatcher.Calls[100].Green));
  Assert.AreEqual(9, Integer(LTable[200]));
end;

procedure TTestPaletteBehavior.TestTranslationRejectsAShortTargetPalette;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateTranslationBuilder(TFakeColorMatcher.Create(0))
        .Build(FlatPalette(0), TBytes.Create(1, 2, 3));
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestIdentityTableChangesNothing;
var
  LTable: TBytes;
  LIndex: Integer;
begin
  LTable := TPaletteFactory.CreateTranslationBuilder(TFakeColorMatcher.Create(0)).Identity;
  Assert.AreEqual(256, Length(LTable));
  for LIndex := 0 to 255 do
    Assert.AreEqual(LIndex, Integer(LTable[LIndex]));
end;

procedure TTestPaletteBehavior.TestDoomPlayerTablesMapTheGreenRamp;
var
  LTables: TBytes;
begin
  LTables := TPaletteFactory.CreateDoomPlayerTranslations.Build;
  Assert.AreEqual(768, Length(LTables));
  Assert.AreEqual($60 + 3, Integer(LTables[$73]));
  Assert.AreEqual($40 + 3, Integer(LTables[256 + $73]));
  Assert.AreEqual($20 + 3, Integer(LTables[512 + $73]));
  Assert.AreEqual($6F, Integer(LTables[$6F]));
  Assert.AreEqual($80, Integer(LTables[$80]));
end;

procedure TTestPaletteBehavior.TestHereticPlayerTablesChangeNothing;
var
  LTables: TBytes;
  LIndex: Integer;
begin
  LTables := TPaletteFactory.CreateHereticPlayerTranslations.Build;
  Assert.AreEqual(3, TPaletteFactory.CreateHereticPlayerTranslations.TableCount);
  for LIndex := 0 to 767 do
    Assert.AreEqual(LIndex mod 256, Integer(LTables[LIndex]));
end;

procedure TTestPaletteBehavior.TestStrifePlayerTablesWrapUnderZero;
var
  LTables: TBytes;
begin
  LTables := TPaletteFactory.CreateStrifePlayerTranslations.Build;
  Assert.AreEqual(7 * 256, Length(LTables));
  // $80: (0 - 80) wraps to 176 in the second table, the first is 0 + 64
  Assert.AreEqual(64, Integer(LTables[$80]));
  Assert.AreEqual(176, Integer(LTables[256 + $80]));
  // $C0 and the last table: the fix of haleyjd turns 0 into 1
  Assert.AreEqual(1, Integer(LTables[6 * 256 + $C0]));
  Assert.AreEqual(5, Integer(LTables[6 * 256 + $C5]));
end;

procedure TTestPaletteBehavior.TestStrifeRunningColorsGrowWithTheIndex;
var
  LTables: TBytes;
begin
  LTables := TPaletteFactory.CreateStrifePlayerTranslations.Build;
  // $F7 takes col1 = $FA + $F7 wrapped; $20 takes col2 = $E0 + $20 wrapped
  Assert.AreEqual(($FA + $F7) and $FF, Integer(LTables[$F7]));
  Assert.AreEqual(($E0 + $20) and $FF, Integer(LTables[$20]));
end;

procedure TTestPaletteBehavior.TestGammaHasFiveLevels;
begin
  Assert.AreEqual(5, TPaletteFactory.CreateGammaTables.LevelCount);
  Assert.AreEqual(1, Integer(TPaletteFactory.CreateGammaTables.Table(0)[0]));
  Assert.AreEqual(255, Integer(TPaletteFactory.CreateGammaTables.Table(4)[255]));
  Assert.AreEqual(256, Length(TPaletteFactory.CreateGammaTables.Table(2)));
end;

procedure TTestPaletteBehavior.TestGammaRejectsAMissingLevel;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateGammaTables.Table(5);
    end, EPaletteException);
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateGammaTables.Table(-1);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestGammaGivesACopy;
var
  LGamma: IGammaTables;
  LFirst: TBytes;
begin
  LGamma := TPaletteFactory.CreateGammaTables;
  LFirst := LGamma.Table(1);
  LFirst[10] := 0;
  Assert.AreNotEqual(0, Integer(LGamma.Table(1)[10]));
end;

procedure TTestPaletteBehavior.TestReplaceZerosDoesNotChangeTheInput;
var
  LInput: TBytes;
  LOutput: TBytes;
begin
  LInput := TBytes.Create(0, 5, 0, 7);
  LOutput := TPaletteFactory.CreateColormapPreparer.ReplaceZeros(LInput, 99);
  Assert.AreEqual(0, Integer(LInput[0]));
  Assert.AreEqual(99, Integer(LOutput[0]));
  Assert.AreEqual(5, Integer(LOutput[1]));
  Assert.AreEqual(99, Integer(LOutput[2]));
end;

procedure TTestPaletteBehavior.TestExpandRepeatsTheLastRow;
var
  LInput: TBytes;
  LOutput: TBytes;
  LCount: Integer;
begin
  LInput := TPaletteFixtures.RandomBytes(9, 3 * 256, $FF);
  LOutput := TPaletteFactory.CreateColormapPreparer.ExpandRows(LInput, 32, LCount);
  Assert.AreEqual(32, LCount);
  Assert.AreEqual(32 * 256, Length(LOutput));
  Assert.IsTrue(CompareMem(@LInput[0], @LOutput[0], 3 * 256));
  Assert.IsTrue(CompareMem(@LInput[2 * 256], @LOutput[31 * 256], 256));
end;

procedure TTestPaletteBehavior.TestExpandKeepsAColormapThatIsBigEnough;
var
  LInput: TBytes;
  LOutput: TBytes;
  LCount: Integer;
begin
  LInput := TPaletteFixtures.RandomBytes(9, 34 * 256 + 10, $FF);
  LOutput := TPaletteFactory.CreateColormapPreparer.ExpandRows(LInput, 32, LCount);
  Assert.AreEqual(34, LCount);
  Assert.AreEqual(Length(LInput), Length(LOutput));
end;

procedure TTestPaletteBehavior.TestExpandRejectsLessThanARow;
var
  LCount: Integer;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateColormapPreparer.ExpandRows(TBytes.Create(1, 2, 3), 32, LCount);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestRowColorsRejectsAMissingRow;
var
  LColors: TArray<Cardinal>;
begin
  SetLength(LColors, 256);
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateColormapPreparer.RowColors(TPaletteFixtures.RandomBytes(1, 256, $FF), 1, LColors);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestFogBecomesBlackWhereTheColormapIsBlack;
var
  LColors: TArray<Cardinal>;
  LData: TFogMapData;
  LIndex: Integer;
begin
  SetLength(LColors, 256);
  for LIndex := 0 to 255 do
    LColors[LIndex] := Cardinal(LIndex) * 1000;
  LData := TPaletteFactory.CreateColormapPreparer.PrepareFog(
    TBytes.Create(5, 0, 7, 8), TBytes.Create(1, 2, 9, 9), 9, LColors);
  Assert.AreEqual(5, Integer(LData.Indexes[0]));
  Assert.AreEqual(9, Integer(LData.Indexes[1]));
  Assert.AreEqual(9, Integer(LData.Indexes[2]));
  Assert.AreEqual(9, Integer(LData.Indexes[3]));
  Assert.AreEqual(9000, Integer(LData.Colors[2]));
end;

procedure TTestPaletteBehavior.TestFogLongerThanTheColormapIsRejected;
var
  LColors: TArray<Cardinal>;
begin
  SetLength(LColors, 256);
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateColormapPreparer.PrepareFog(TBytes.Create(1, 2, 3), TBytes.Create(1), 0, LColors);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestScaleLightRejectsAViewWithoutWidth;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateLightTableCalculator.ScaleLight(TLightTableConfig.Default, 0, 320);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestZLightStaysInsideTheColormaps;
var
  LTable: TArray<Integer>;
  LValue: Integer;
begin
  LTable := TPaletteFactory.CreateLightTableCalculator.ZLight(TLightTableConfig.Default);
  Assert.AreEqual(16 * 128, Length(LTable));
  for LValue in LTable do
  begin
    Assert.IsTrue(LValue >= 0);
    Assert.IsTrue(LValue < 32);
  end;
end;

procedure TTestPaletteBehavior.TestBrighterLevelsUseLowerColormaps;
var
  LTable: TArray<Integer>;
begin
  LTable := TPaletteFactory.CreateLightTableCalculator.ZLight(TLightTableConfig.Default);
  // the last light level is the brightest: its colormaps are never darker than the first level's
  Assert.IsTrue(LTable[15 * 128 + 64] <= LTable[0 * 128 + 64]);
end;

procedure TTestPaletteBehavior.TestHiResLightStaysInsideTheFixedUnit;
var
  LTable: TArray<Integer>;
  LValue: Integer;
begin
  LTable := TPaletteFactory.CreateLightTableCalculator.HiResZLight(TLightTableConfig.Default);
  Assert.AreEqual(16 * 8192, Length(LTable));
  for LValue in LTable do
  begin
    Assert.IsTrue(LValue >= 0);
    Assert.IsTrue(LValue < 65536);
  end;
end;

procedure TTestPaletteBehavior.TestNamesFindTheRegionsWithAndWithoutPrefix;
var
  LNames: ITranslationNames;
  LKey: string;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  Assert.AreEqual(REGION_RED, LNames.FindSlot('red', LKey));
  Assert.AreEqual(REGION_RED, LNames.FindSlot('CR_RED', LKey));
  Assert.AreEqual(REGION_RED, LNames.FindSlot('CRRED', LKey));
  Assert.AreEqual('RED', LKey);
  Assert.AreEqual(REGION_PURPL, LNames.FindSlot('purple', LKey));
  Assert.AreEqual(REGION_TRANS9, LNames.FindSlot('trans9', LKey));
  Assert.AreEqual(-1, LNames.FindSlot('mauve', LKey));
end;

procedure TTestPaletteBehavior.TestNamesStripThePrefixesOneAfterTheOther;
var
  LNames: ITranslationNames;
  LKey: string;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  // CR_ then CR: CR_CRFOO is looked up as FOO in the end, and that is the key to remember
  Assert.AreEqual(-1, LNames.FindSlot('CR_CRFOO', LKey));
  Assert.AreEqual('FOO', LKey);
end;

procedure TTestPaletteBehavior.TestNamesGiveNewSlotsAfterTheRegions;
var
  LNames: ITranslationNames;
  LKey: string;
  LSlot: Integer;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  Assert.AreEqual(-1, LNames.FindSlot('CR_MAUVE', LKey));
  LSlot := LNames.AddSlot(LKey);
  Assert.AreEqual(REGION_COUNT, LSlot);
  Assert.AreEqual(LSlot, LNames.FindSlot('CR_MAUVE', LKey));
  Assert.AreEqual(LSlot, LNames.FindSlot('mauve', LKey));
  Assert.AreEqual(REGION_COUNT + 1, LNames.AddSlot('OTHER'));
end;

procedure TTestPaletteBehavior.TestLumpCandidatesForAPlainName;
var
  LCandidates: TArray<string>;
begin
  LCandidates := TPaletteFactory.CreateTranslationNames.LumpCandidates('Foo');
  Assert.AreEqual(3, Length(LCandidates));
  Assert.AreEqual('Foo', LCandidates[0]);
  Assert.AreEqual('CRFoo', LCandidates[1]);
  Assert.AreEqual('CR_Foo', LCandidates[2]);
end;

procedure TTestPaletteBehavior.TestLumpCandidatesForAPrefixedName;
var
  LNames: ITranslationNames;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  Assert.AreEqual('CRFOO', LNames.LumpCandidates('CR_FOO')[1]);
  Assert.AreEqual(2, Length(LNames.LumpCandidates('CR_FOO')));
  Assert.AreEqual('CR_FOO', LNames.LumpCandidates('CRFOO')[1]);
  Assert.AreEqual(2, Length(LNames.LumpCandidates('crfoo')));
end;

procedure TTestPaletteBehavior.TestBloodIdAcceptsNumbersAndNames;
var
  LNames: ITranslationNames;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  Assert.AreEqual(3, LNames.BloodIdForName('3'));
  Assert.AreEqual(2, LNames.BloodIdForName('green'));
  Assert.AreEqual(2, LNames.BloodIdForName('CR_GREEN'));
  Assert.AreEqual(2, LNames.BloodIdForName('CRGREEN'));
  Assert.AreEqual(6, LNames.BloodIdForName('purple'));
  Assert.AreEqual(8, LNames.BloodIdForName('Orange'));
end;

procedure TTestPaletteBehavior.TestBloodIdOfAnUnknownNameIsZero;
var
  LNames: ITranslationNames;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  Assert.AreEqual(0, LNames.BloodIdForName('mauve'));
  Assert.AreEqual(0, LNames.BloodIdForName('9'));
  Assert.AreEqual(0, LNames.BloodIdForName('99999999999'));
  Assert.AreEqual(0, LNames.BloodIdForName(''));
end;

procedure TTestPaletteBehavior.TestBloodNameOfRedIsEmpty;
var
  LNames: ITranslationNames;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  Assert.AreEqual('', LNames.BloodName(0));
  Assert.AreEqual('GRAY', LNames.BloodName(1));
  Assert.AreEqual('ORANGE', LNames.BloodName(8));
  Assert.AreEqual('', LNames.BloodName(9));
end;

procedure TTestPaletteBehavior.TestBloodRegionOfRedIsNone;
var
  LNames: ITranslationNames;
begin
  LNames := TPaletteFactory.CreateTranslationNames;
  Assert.AreEqual(-1, LNames.BloodRegion(0));
  Assert.AreEqual(REGION_GRAY, LNames.BloodRegion(1));
  Assert.AreEqual(REGION_ORANGE, LNames.BloodRegion(8));
  Assert.AreEqual(-1, LNames.BloodRegion(9));
end;

procedure TTestPaletteBehavior.TestPrecalcRejectsAMissingChannel;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreatePrecalcTables.Multiply(3);
    end, EPaletteException);
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreatePrecalcTables.Average(4);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestLightIndexIsClamped;
var
  LTables: IPrecalcTables;
begin
  LTables := TPaletteFactory.CreatePrecalcTables;
  Assert.AreEqual(0, LTables.LightIndex(0));
  Assert.AreEqual(1, LTables.LightIndex(256));
  Assert.AreEqual(255, LTables.LightIndex(70000));
  Assert.AreEqual(255, LTables.LightIndex(MaxInt));
end;

procedure TTestPaletteBehavior.TestAddClampSaturates;
var
  LTable: TBytes;
begin
  LTable := TPaletteFactory.CreatePrecalcTables.AddClamp;
  Assert.AreEqual(512, Length(LTable));
  Assert.AreEqual(255, Integer(LTable[255]));
  Assert.AreEqual(255, Integer(LTable[300]));
  Assert.AreEqual(100, Integer(LTable[100]));
end;

procedure TTestPaletteBehavior.TestBufferFixerKeepsTheFirstPixel;
var
  LBuffer: TBytes;
begin
  LBuffer := TBytes.Create(3, 3, 100, 250, 100);
  TPaletteFactory.CreateBufferFixer.Fix(LBuffer, 0, 4);
  Assert.AreEqual(3, Integer(LBuffer[0]));
  Assert.AreEqual(3, Integer(LBuffer[1]));
  Assert.AreEqual(100, Integer(LBuffer[2]));
  Assert.AreEqual(100, Integer(LBuffer[3]));
  Assert.AreEqual(100, Integer(LBuffer[4]));
end;

procedure TTestPaletteBehavior.TestBufferFixerRejectsAnEndOutsideTheBuffer;
var
  LBuffer: TBytes;
begin
  LBuffer := TBytes.Create(1, 2, 3);
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreateBufferFixer.Fix(LBuffer, 0, 3);
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestUnpackerUsesAGammaThatChangesNothing;
var
  LConverter: TFakePaletteConverter;
  LIntf: IPaletteConverter;
  LColors: TArray<Cardinal>;
  LIndex: Integer;
begin
  LConverter := TFakePaletteConverter.Create;
  LIntf := LConverter;
  LColors := TPaletteFactory.CreatePaletteUnpacker(LIntf).Unpack(FlatPalette(1));
  Assert.AreEqual(1, LConverter.CallCount);
  Assert.AreEqual(256, Length(LColors));
  Assert.AreEqual(3, Integer(LColors[255]));
  for LIndex := 0 to 255 do
    Assert.AreEqual(LIndex, Integer(LConverter.Gamma[LIndex]));
end;

procedure TTestPaletteBehavior.TestUnpackerRejectsAShortPalette;
begin
  Assert.WillRaise(
    procedure
    begin
      TPaletteFactory.CreatePaletteUnpacker(TFakePaletteConverter.Create).Unpack(TBytes.Create(1, 2, 3));
    end, EPaletteException);
end;

procedure TTestPaletteBehavior.TestFactoryCreatesEveryService;
var
  LMatcher: IColorMatcher;
begin
  LMatcher := TPaletteFactory.CreateColorMatcher;
  Assert.IsNotNull(LMatcher);
  Assert.IsNotNull(TPaletteFactory.CreatePaletteBuilder(LMatcher, TPaletteProfiles.Hexen));
  Assert.IsNotNull(TPaletteFactory.CreateTranslationBuilder(LMatcher));
  Assert.IsNotNull(TPaletteFactory.CreateDoomPlayerTranslations);
  Assert.IsNotNull(TPaletteFactory.CreateGammaTables);
  Assert.IsNotNull(TPaletteFactory.CreateColormapPreparer);
  Assert.IsNotNull(TPaletteFactory.CreateLightTableCalculator);
  Assert.IsNotNull(TPaletteFactory.CreateTranslationNames);
  Assert.IsNotNull(TPaletteFactory.CreatePrecalcTables);
  Assert.IsNotNull(TPaletteFactory.CreateBufferFixer);
end;

end.
