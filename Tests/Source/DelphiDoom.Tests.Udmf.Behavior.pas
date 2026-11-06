{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UDMF library - scanner, numbers and the games       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.Behavior;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf,
  DelphiDoom.Udmf.Games, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.Tests.Udmf.Sounds;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfBehavior = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    FSounds: TFakeSounds;
    FSoundsIntf: IUdmfSoundResolver;
    function Convert(AGame: TUdmfGame; const AText: string): IUdmfConvertedMap;
    function Lump(const AMap: IUdmfConvertedMap; const AName: string): TBytes;
    function Int16At(const ABytes: TBytes; AOffset: Integer): Integer;
    function Int32At(const ABytes: TBytes; AOffset: Integer): Integer;
    function Warnings: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    // scanner and preprocessor
    [Test]
    procedure TestScannerSplitsOnSpacesAndBracesAndCommas;
    [Test]
    procedure TestScannerKeepsTheTextInQuotes;
    [Test]
    procedure TestScannerSkipsLineCommentsAndDropsALoneSlash;
    [Test]
    procedure TestScannerCutsAWordAt1023Characters;
    [Test]
    procedure TestPreprocessorMakesBlocksAndRemovesCommentsAndSemicolons;
    [Test]
    procedure TestPreprocessorLeavesTheEndOfABlockCommentBehind;

    // numbers and names
    [Test]
    [TestCase('decimal', '123,123,True')]
    [TestCase('negative', '-45,-45,True')]
    [TestCase('plus', '+7,7,True')]
    [TestCase('dollar', '$1F,31,True')]
    [TestCase('zero x', '0x20,32,True')]
    [TestCase('zero X', '0XfF,255,True')]
    [TestCase('empty', ',0,False')]
    [TestCase('letters', 'abc,0,False')]
    [TestCase('float', '1.5,0,False')]
    [TestCase('too big', '2147483648,0,False')]
    [TestCase('minus alone', '-,0,False')]
    procedure TestTryParseInteger(const AText: string; AExpected: Integer; AOk: Boolean);
    [Test]
    [TestCase('plain', '1.5,150,True')]
    [TestCase('exponent', '1e2,10000,True')]
    [TestCase('leading point', '.5,50,True')]
    [TestCase('negative', '-2.25,-225,True')]
    [TestCase('hexadecimal', '0x20,0,False')]
    [TestCase('letters', 'abc,0,False')]
    [TestCase('nan', 'nan,0,False')]
    procedure TestTryParseFloat(const AText: string; AExpectedTimes100: Integer; AOk: Boolean);
    [Test]
    procedure TestNamesAreCutAtEightCharacters;
    [Test]
    procedure TestOnlyTheLettersAToZGoToCapitals;

    // sizes of the records
    [Test]
    [TestCase('doom', 'Doom,10,52,14,56,30,36,4,20,26,132')]
    [TestCase('heretic', 'Heretic,10,52,14,56,30,36,4,20,26,116')]
    [TestCase('hexen', 'Hexen,20,28,16,32,30,36,4,20,26,112')]
    [TestCase('strife', 'Strife,10,52,14,56,30,36,4,20,26,132')]
    procedure TestRecordSizesOfTheGames(const AGame: string; AThing, AExtraThing, ALine, AExtraLine,
      ASide, AExtraSide, AVertex, AExtraVertex, ASector, AExtraSector: Integer);
    [Test]
    [TestCase('doom', 'Doom')]
    [TestCase('heretic', 'Heretic')]
    [TestCase('hexen', 'Hexen')]
    [TestCase('strife', 'Strife')]
    procedure TestTheLumpsHaveTheSizeOfTheRecordsTimesTheirNumber(const AGame: string);

    // the converter
    [Test]
    procedure TestLumpsAreInTheOrderOfAMapAndCarryBehaviorAndScripts;
    [Test]
    procedure TestTheNameOfTheMapIsInCapitalLetters;
    [Test]
    procedure TestNamespaceIsWrittenOneByteForCharacter;
    [Test]
    procedure TestTheLastNamespaceIsTheOneOfTheMap;
    [Test]
    procedure TestNamespaceOfTheGameDoesNotTranslate;
    [Test]
    procedure TestOtherNamespaceTranslates;
    [Test]
    procedure TestNothingIsKeptBetweenMaps;
    [Test]
    procedure TestEmptyTextGivesAnEmptyMap;
    [Test]
    procedure TestUnknownKeyIsLeftOutAndItsValueIsReadAsAKey;
    [Test]
    procedure TestAnUnfinishedBlockEndsWithTheText;
    [Test]
    procedure TestAWordInsteadOfTheBraceIsTold;

    // things
    [Test]
    procedure TestSingleTakesAwayTheDefaultBitOfTheThings;
    [Test]
    procedure TestAFalseFlagNeverTakesABitAway;
    [Test]
    procedure TestSkillBitsOfThings;
    [Test]
    procedure TestHexenThingBitsAndRecord;
    [Test]
    procedure TestVanillaThingSpecialIsTranslated;
    [Test]
    procedure TestOnlyStrifeKnowsStrifeAlly;

    // lines
    [Test]
    procedure TestVanillaLineIdIsTheTagAndStartsAtMinusOne;
    [Test]
    procedure TestHexenLineIdIsTheSpecial121WithTheIdAsFirstArgument;
    [Test]
    procedure TestHexenLineKeysAreAppliedInTheOrderOfTheText;
    [Test]
    procedure TestSidesOver32768AreMinusOne;
    [Test]
    procedure TestFlagsOfOtherGamesAreNotKnown;
    [Test]
    procedure TestMoreIdsOfTheLines;

    // sectors and sides
    [Test]
    procedure TestSoundOfTheSectorsOnlyWhereTheGameHasIt;
    [Test]
    procedure TestPanningOfTheSectorsOnlyWhereTheGameHasIt;
    [Test]
    procedure TestLongNamesAreCutAndTold;
    [Test]
    procedure TestSideTextureDefaultsAreADash;
  end;

implementation

uses
  DelphiDoom.Udmf.Scanner, DelphiDoom.Udmf.Preprocessor, DelphiDoom.Udmf.Text,
  DelphiDoom.Udmf.Factory, DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory;

{ TTestUdmfBehavior }

procedure TTestUdmfBehavior.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
  FSounds := TFakeSounds.Create;
  FSoundsIntf := FSounds;
end;

procedure TTestUdmfBehavior.TearDown;
begin
  FSoundsIntf := nil;
  FSounds := nil;
  FSink := nil;
  FRecorder := nil;
end;

function TTestUdmfBehavior.Convert(AGame: TUdmfGame; const AText: string): IUdmfConvertedMap;
begin
  Result := TUdmfFactory.CreateConverter(AGame, FSoundsIntf,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil)).Convert(AText);
end;

function TTestUdmfBehavior.Lump(const AMap: IUdmfConvertedMap; const AName: string): TBytes;
var
  LLump: TUdmfLump;
begin
  for LLump in AMap.GetLumps('MAP01', nil, nil) do
    if LLump.Name = AName then
      Exit(LLump.Data);
  Result := nil;
  Assert.Fail('no lump ' + AName);
end;

function TTestUdmfBehavior.Int16At(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := SmallInt(ABytes[AOffset] or (ABytes[AOffset + 1] shl 8));
end;

function TTestUdmfBehavior.Int32At(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := Integer(Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8) or
    (Cardinal(ABytes[AOffset + 2]) shl 16) or (Cardinal(ABytes[AOffset + 3]) shl 24));
end;

function TTestUdmfBehavior.Warnings: string;
begin
  Result := FRecorder.TextOf(TLogChannel.ErrorFile);
end;

procedure TTestUdmfBehavior.TestScannerSplitsOnSpacesAndBracesAndCommas;
var
  LScanner: TUdmfScanner;
  LWords: string;
begin
  LScanner := TUdmfScanner.Create('one two{three}(four),five'#13#10'six');
  try
    LWords := '';
    while LScanner.GetString do
      LWords := LWords + LScanner.Value + '|';
  finally
    LScanner.Free;
  end;
  Assert.AreEqual('one|two|three|four|five|six|', LWords);
end;

procedure TTestUdmfBehavior.TestScannerKeepsTheTextInQuotes;
var
  LScanner: TUdmfScanner;
begin
  LScanner := TUdmfScanner.Create('name "with spaces, braces { } and // slashes" end');
  try
    Assert.IsTrue(LScanner.GetString);
    Assert.AreEqual('name', LScanner.Value);
    Assert.IsTrue(LScanner.GetString);
    Assert.AreEqual('with spaces, braces { } and // slashes', LScanner.Value);
    Assert.IsTrue(LScanner.GetString);
    Assert.AreEqual('end', LScanner.Value);
    Assert.IsFalse(LScanner.GetString);
  finally
    LScanner.Free;
  end;
end;

procedure TTestUdmfBehavior.TestScannerSkipsLineCommentsAndDropsALoneSlash;
var
  LScanner: TUdmfScanner;
  LWords: string;
begin
  LScanner := TUdmfScanner.Create('a // hidden words'#13#10'b / c d//e'#13#10'f');
  try
    LWords := '';
    while LScanner.GetString do
      LWords := LWords + LScanner.Value + '|';
  finally
    LScanner.Free;
  end;
  // the lone slash is gone, and d stops at the //
  Assert.AreEqual('a|b|c|d|f|', LWords);
end;

procedure TTestUdmfBehavior.TestScannerCutsAWordAt1023Characters;
var
  LScanner: TUdmfScanner;
begin
  LScanner := TUdmfScanner.Create(StringOfChar('x', 1500) + ' next');
  try
    Assert.IsTrue(LScanner.GetString);
    Assert.AreEqual(1023, Length(LScanner.Value));
    // the rest of the word is the next word
    Assert.IsTrue(LScanner.GetString);
    Assert.AreEqual(StringOfChar('x', 477), LScanner.Value);
  finally
    LScanner.Free;
  end;
end;

procedure TTestUdmfBehavior.TestPreprocessorMakesBlocksAndRemovesCommentsAndSemicolons;
var
  LText: string;
begin
  LText := TUdmfPreprocessor.Process('thing // zero'#13#10'{'#13#10'x = 1.5; // here'#13#10'}'#13#10);
  Assert.IsTrue(Pos('_BEGINBLOCK', LText) > 0);
  Assert.IsTrue(Pos('_ENDBLOCK', LText) > 0);
  Assert.AreEqual(0, Pos('zero', LText));
  Assert.AreEqual(0, Pos('here', LText));
  Assert.AreEqual(0, Pos(';', LText));
  Assert.AreEqual(0, Pos('=', LText));
  Assert.AreEqual(0, Pos('{', LText));
  Assert.AreEqual(0, Pos('}', LText));
  Assert.IsTrue(Pos('x   1.5', LText) > 0);
end;
procedure TTestUdmfBehavior.TestPreprocessorLeavesTheEndOfABlockCommentBehind;
var
  LText: string;
begin
  // a defect of the old code that was kept: the star and the slash stay in the text
  LText := TUdmfPreprocessor.Process('a /* hidden */ b');
  Assert.IsTrue(Pos('*/', LText) > 0);
  Assert.IsTrue(Pos('hidden', LText) = 0);
end;

procedure TTestUdmfBehavior.TestTryParseInteger(const AText: string; AExpected: Integer; AOk: Boolean);
var
  LValue: Integer;
begin
  Assert.AreEqual(AOk, TUdmfText.TryParseInteger(AText, LValue), AText);
  if AOk then
    Assert.AreEqual(AExpected, LValue, AText);
end;

procedure TTestUdmfBehavior.TestTryParseFloat(const AText: string; AExpectedTimes100: Integer; AOk: Boolean);
var
  LValue: Single;
begin
  Assert.AreEqual(AOk, TUdmfText.TryParseFloat(AText, LValue), AText);
  if AOk then
    Assert.AreEqual(AExpectedTimes100, Integer(Round(LValue * 100)), AText);
end;

procedure TTestUdmfBehavior.TestNamesAreCutAtEightCharacters;
var
  LName: TUdmfName8;
  LText: string;
  LIndex: Integer;
begin
  LName := TUdmfText.ToName8('ABCDEFGHIJ');
  LText := '';
  for LIndex := 0 to 7 do
    LText := LText + Char(LName[LIndex]);
  Assert.AreEqual('ABCDEFGH', LText);
  LName := TUdmfText.ToName8('AB');
  Assert.AreEqual(Integer(Ord('B')), Integer(Ord(LName[1])));
  Assert.AreEqual(0, Integer(Ord(LName[2])));
  Assert.AreEqual(0, Integer(Ord(LName[7])));
end;
procedure TTestUdmfBehavior.TestOnlyTheLettersAToZGoToCapitals;
begin
  Assert.AreEqual('ABC_12 {}', TUdmfText.ToUpper('abC_12 {}'));
end;

procedure TTestUdmfBehavior.TestRecordSizesOfTheGames(const AGame: string; AThing, AExtraThing, ALine,
  AExtraLine, ASide, AExtraSide, AVertex, AExtraVertex, ASector, AExtraSector: Integer);
var
  LGame: TUdmfGame;
  LProfile: IUdmfProfile;
begin
  Assert.IsTrue(TUdmfGames.TryFromName(AGame, LGame));
  LProfile := TUdmfGames.CreateProfile(LGame, FSoundsIntf);
  Assert.AreEqual(AThing, LProfile.Things.BaseSize);
  Assert.AreEqual(AExtraThing, LProfile.Things.ExtraSize);
  Assert.AreEqual(ALine, LProfile.Lines.BaseSize);
  Assert.AreEqual(AExtraLine, LProfile.Lines.ExtraSize);
  Assert.AreEqual(ASide, LProfile.Sides.BaseSize);
  Assert.AreEqual(AExtraSide, LProfile.Sides.ExtraSize);
  Assert.AreEqual(AVertex, LProfile.Vertexes.BaseSize);
  Assert.AreEqual(AExtraVertex, LProfile.Vertexes.ExtraSize);
  Assert.AreEqual(ASector, LProfile.Sectors.BaseSize);
  Assert.AreEqual(AExtraSector, LProfile.Sectors.ExtraSize);
end;

procedure TTestUdmfBehavior.TestTheLumpsHaveTheSizeOfTheRecordsTimesTheirNumber(const AGame: string);
var
  LGame: TUdmfGame;
  LProfile: IUdmfProfile;
  LMap: IUdmfConvertedMap;
  LText: string;
begin
  Assert.IsTrue(TUdmfGames.TryFromName(AGame, LGame));
  LProfile := TUdmfGames.CreateProfile(LGame, FSoundsIntf);
  LText := 'namespace = "' + AGame + '";'#10 +
    'thing { x = 1; } thing { x = 2; } thing { x = 3; }'#10 +
    'linedef { v1 = 1; } linedef { v1 = 2; }'#10 +
    'sidedef { sector = 1; } sidedef { sector = 2; } sidedef { sector = 3; } sidedef { sector = 4; }'#10 +
    'vertex { x = 1; } vertex { x = 2; } vertex { x = 3; } vertex { x = 4; } vertex { x = 5; }'#10 +
    'sector { } sector { }'#10;
  LMap := Convert(LGame, LText);
  Assert.AreEqual(3 * LProfile.Things.BaseSize, Length(Lump(LMap, 'THINGS')));
  Assert.AreEqual(3 * LProfile.Things.ExtraSize, Length(LMap.ExtraThings));
  Assert.AreEqual(2 * LProfile.Lines.BaseSize, Length(Lump(LMap, 'LINEDEFS')));
  Assert.AreEqual(2 * LProfile.Lines.ExtraSize, Length(LMap.ExtraLines));
  Assert.AreEqual(4 * LProfile.Sides.BaseSize, Length(Lump(LMap, 'SIDEDEFS')));
  Assert.AreEqual(4 * LProfile.Sides.ExtraSize, Length(LMap.ExtraSides));
  Assert.AreEqual(5 * LProfile.Vertexes.BaseSize, Length(Lump(LMap, 'VERTEXES')));
  Assert.AreEqual(5 * LProfile.Vertexes.ExtraSize, Length(LMap.ExtraVertexes));
  Assert.AreEqual(2 * LProfile.Sectors.BaseSize, Length(Lump(LMap, 'SECTORS')));
  Assert.AreEqual(2 * LProfile.Sectors.ExtraSize, Length(LMap.ExtraSectors));
  Assert.AreEqual(3, LMap.ThingCount);
  Assert.AreEqual(2, LMap.LineCount);
  Assert.AreEqual(4, LMap.SideCount);
  Assert.AreEqual(5, LMap.VertexCount);
  Assert.AreEqual(2, LMap.SectorCount);
end;

procedure TTestUdmfBehavior.TestLumpsAreInTheOrderOfAMapAndCarryBehaviorAndScripts;
var
  LLumps: TArray<TUdmfLump>;
  LNames: string;
  LLump: TUdmfLump;
begin
  LLumps := Convert(TUdmfGame.Doom, 'namespace = "doom";').GetLumps('MAP07',
    TBytes.Create(1, 2, 3), TBytes.Create(9, 8));
  LNames := '';
  for LLump in LLumps do
    LNames := LNames + LLump.Name + ' ';
  Assert.AreEqual('MAP07 THINGS LINEDEFS SIDEDEFS VERTEXES SEGS SSECTORS NODES SECTORS REJECT ' +
    'BLOCKMAP BEHAVIOR SCRIPTS THINGS2 SECTORS2 VERTEX2 LINEDEF2 SIDEDEF2 NSPACE ', LNames);
  Assert.AreEqual(3, Length(LLumps[11].Data));
  Assert.AreEqual(2, Length(LLumps[12].Data));
  Assert.AreEqual(0, Length(LLumps[5].Data));
end;

procedure TTestUdmfBehavior.TestTheNameOfTheMapIsInCapitalLetters;
begin
  Assert.AreEqual('E1M2', Convert(TUdmfGame.Doom, '').GetLumps('e1m2', nil, nil)[0].Name);
end;

procedure TTestUdmfBehavior.TestNamespaceIsWrittenOneByteForCharacter;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Doom, 'namespace = "doom";'), 'NSPACE');
  Assert.AreEqual(4, Length(LData));
  Assert.AreEqual(Integer(Ord('D')), Integer(LData[0]));
  Assert.AreEqual(Integer(Ord('O')), Integer(LData[1]));
  Assert.AreEqual(Integer(Ord('O')), Integer(LData[2]));
  Assert.AreEqual(Integer(Ord('M')), Integer(LData[3]));
end;

procedure TTestUdmfBehavior.TestTheLastNamespaceIsTheOneOfTheMap;
var
  LMap: IUdmfConvertedMap;
begin
  LMap := Convert(TUdmfGame.Doom, 'namespace = "doom"; namespace = "ZDoomTranslated";');
  Assert.AreEqual('ZDOOMTRANSLATED', LMap.Namespace);
  Assert.IsFalse(LMap.LineTranslate);
end;

procedure TTestUdmfBehavior.TestNamespaceOfTheGameDoesNotTranslate;
var
  LMap: IUdmfConvertedMap;
begin
  LMap := Convert(TUdmfGame.Heretic, 'namespace = "Heretic";');
  Assert.IsFalse(LMap.LineTranslate);
  Assert.AreEqual('', Warnings);
  LMap := Convert(TUdmfGame.Heretic, 'namespace = "DelphiHeretic";');
  Assert.IsTrue(LMap.LineTranslate);
  Assert.AreEqual('', Warnings);
end;

procedure TTestUdmfBehavior.TestOtherNamespaceTranslates;
var
  LMap: IUdmfConvertedMap;
begin
  LMap := Convert(TUdmfGame.Doom, 'namespace = "strange";');
  Assert.IsTrue(LMap.LineTranslate);
  Assert.IsTrue(Pos('Unknown namespace "strange"', Warnings) > 0);
end;

procedure TTestUdmfBehavior.TestNothingIsKeptBetweenMaps;
var
  LConverter: IUdmfConverter;
  LFirst: IUdmfConvertedMap;
  LSecond: IUdmfConvertedMap;
begin
  LConverter := TUdmfFactory.CreateConverter(TUdmfGame.Doom, FSoundsIntf, nil);
  LFirst := LConverter.Convert('namespace = "zdoomtranslated"; thing { x = 5; } sector { }');
  LSecond := LConverter.Convert('thing { x = 7; }');
  Assert.AreEqual(1, LFirst.SectorCount);
  Assert.AreEqual(0, LSecond.SectorCount);
  Assert.AreEqual('', LSecond.Namespace);
  Assert.AreEqual(1, LSecond.ThingCount);
end;

procedure TTestUdmfBehavior.TestEmptyTextGivesAnEmptyMap;
var
  LMap: IUdmfConvertedMap;
begin
  LMap := Convert(TUdmfGame.Doom, '');
  Assert.AreEqual(0, LMap.ThingCount + LMap.LineCount + LMap.SideCount + LMap.VertexCount + LMap.SectorCount);
  Assert.AreEqual(0, Length(Lump(LMap, 'THINGS')));
end;

procedure TTestUdmfBehavior.TestUnknownKeyIsLeftOutAndItsValueIsReadAsAKey;
var
  LData: TBytes;
begin
  // foo is not a key; its value 12 is not either; x is, and gets 5
  LData := Lump(Convert(TUdmfGame.Doom, 'vertex { foo = 12; x = 5; y = 6; }'), 'VERTEXES');
  Assert.AreEqual(5, Int16At(LData, 0));
  Assert.AreEqual(6, Int16At(LData, 2));
end;

procedure TTestUdmfBehavior.TestAnUnfinishedBlockEndsWithTheText;
var
  LMap: IUdmfConvertedMap;
begin
  // the old code did not come out of this
  LMap := Convert(TUdmfGame.Doom, 'thing { x = 1; y = 2;');
  Assert.AreEqual(1, LMap.ThingCount);
  Assert.AreEqual(1, Int16At(Lump(LMap, 'THINGS'), 0));
end;

procedure TTestUdmfBehavior.TestAWordInsteadOfTheBraceIsTold;
begin
  Convert(TUdmfGame.Doom, 'thing x = 1; }');
  Assert.IsTrue(Pos('Unexpected token "X" in thing definition', Warnings) > 0);
end;

procedure TTestUdmfBehavior.TestSingleTakesAwayTheDefaultBitOfTheThings;
var
  LData: TBytes;
begin
  // options are 16 (not in single player) until single is true
  LData := Lump(Convert(TUdmfGame.Doom, 'thing { x = 1; } thing { single = true; }'), 'THINGS');
  Assert.AreEqual(16, Int16At(LData, 8));
  Assert.AreEqual(0, Int16At(LData, 18));
end;

procedure TTestUdmfBehavior.TestAFalseFlagNeverTakesABitAway;
var
  LData: TBytes;
begin
  // as the old code: only true does something
  LData := Lump(Convert(TUdmfGame.Doom, 'thing { coop = true; coop = false; }'), 'THINGS');
  Assert.AreEqual(16 or 32, Int16At(LData, 8));
end;

procedure TTestUdmfBehavior.TestSkillBitsOfThings;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Doom, 'thing { skill1 = true; skill3 = true; skill5 = true; ambush = true; dm = true; }'),
    'THINGS');
  Assert.AreEqual(16 or 1 or 2 or 4 or 8 or 64, Int16At(LData, 8));
end;

procedure TTestUdmfBehavior.TestHexenThingBitsAndRecord;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Hexen, 'thing { x = 10; y = 20; angle = 90; type = 7; class1 = true; dormant = true; ' +
    'special = 80; arg0 = 1; arg4 = 5; }'), 'THINGS');
  Assert.AreEqual(0, Int16At(LData, 0)); // the id is not written to the record
  Assert.AreEqual(10, Int16At(LData, 2));
  Assert.AreEqual(20, Int16At(LData, 4));
  Assert.AreEqual(90, Int16At(LData, 8));
  Assert.AreEqual(7, Int16At(LData, 10));
  Assert.AreEqual(32 or 16, Int16At(LData, 12));
  Assert.AreEqual(80, Integer(LData[14]));
  Assert.AreEqual(1, Integer(LData[15]));
  Assert.AreEqual(5, Integer(LData[19]));
end;

procedure TTestUdmfBehavior.TestVanillaThingSpecialIsTranslated;
var
  LExtra: TBytes;
  LText: string;
begin
  // the specials of the other format are moved: 1..300 go up by 700, 300..1000 come down by 300
  LText := 'thing { special = 5; } thing { special = 300; } thing { special = 500; } ' +
    'thing { special = 1029; } thing { special = 2000; }';
  LExtra := Convert(TUdmfGame.Doom, 'namespace = "other";' + LText).ExtraThings;
  Assert.AreEqual(705, Int32At(LExtra, 52 * 0 + 28));
  Assert.AreEqual(1000, Int32At(LExtra, 52 * 1 + 28));
  Assert.AreEqual(200, Int32At(LExtra, 52 * 2 + 28));
  Assert.AreEqual(705 or 1024, Int32At(LExtra, 52 * 3 + 28));
  Assert.AreEqual(676 or 1024, Int32At(LExtra, 52 * 4 + 28));
  // with the namespace of the game nothing moves
  LExtra := Convert(TUdmfGame.Doom, 'namespace = "doom";' + LText).ExtraThings;
  Assert.AreEqual(5, Int32At(LExtra, 52 * 0 + 28));
  Assert.AreEqual(2000, Int32At(LExtra, 52 * 4 + 28));
end;

procedure TTestUdmfBehavior.TestOnlyStrifeKnowsStrifeAlly;
var
  LText: string;
begin
  LText := 'thing { strifeally = true; }';
  Assert.AreEqual(16 or 64, Int16At(Lump(Convert(TUdmfGame.Strife, LText), 'THINGS'), 8));
  Assert.AreEqual(16, Int16At(Lump(Convert(TUdmfGame.Doom, LText), 'THINGS'), 8));
  Assert.AreEqual(16, Int16At(Lump(Convert(TUdmfGame.Heretic, LText), 'THINGS'), 8));
end;

procedure TTestUdmfBehavior.TestVanillaLineIdIsTheTagAndStartsAtMinusOne;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Doom, 'linedef { v1 = 1; } linedef { id = 9; }'), 'LINEDEFS');
  Assert.AreEqual(-1, Int16At(LData, 8));
  Assert.AreEqual(9, Int16At(LData, 14 + 8));
  Assert.AreEqual(-1, Int16At(LData, 10));
  Assert.AreEqual(-1, Int16At(LData, 12));
end;

procedure TTestUdmfBehavior.TestHexenLineIdIsTheSpecial121WithTheIdAsFirstArgument;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Hexen, 'linedef { id = 9; }'), 'LINEDEFS');
  Assert.AreEqual(121, Integer(LData[6]));
  Assert.AreEqual(9, Integer(LData[7]));
end;

procedure TTestUdmfBehavior.TestHexenLineKeysAreAppliedInTheOrderOfTheText;
var
  LData: TBytes;
begin
  // the id writes the special and the first argument: what comes after it wins
  LData := Lump(Convert(TUdmfGame.Hexen, 'linedef { special = 5; arg0 = 7; id = 9; } ' +
    'linedef { id = 9; special = 5; arg0 = 7; }'), 'LINEDEFS');
  Assert.AreEqual(121, Integer(LData[6]));
  Assert.AreEqual(9, Integer(LData[7]));
  Assert.AreEqual(5, Integer(LData[16 + 6]));
  Assert.AreEqual(7, Integer(LData[16 + 7]));
end;

procedure TTestUdmfBehavior.TestSidesOver32768AreMinusOne;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Doom, 'linedef { sidefront = 32769; sideback = 32767; }'), 'LINEDEFS');
  Assert.AreEqual(-1, Int16At(LData, 10));
  Assert.AreEqual(32767, Int16At(LData, 12));
end;

procedure TTestUdmfBehavior.TestFlagsOfOtherGamesAreNotKnown;
var
  LText: string;
begin
  LText := 'linedef { passuse = true; blocklandmonsters = true; blockfloaters = true; jumpover = true; }';
  // Doom: passuse 512 and blocklandmonsters 4096
  Assert.AreEqual(512 or 4096, Int16At(Lump(Convert(TUdmfGame.Doom, LText), 'LINEDEFS'), 4));
  // Heretic: blocklandmonsters 2048, no passuse
  Assert.AreEqual(2048, Int16At(Lump(Convert(TUdmfGame.Heretic, LText), 'LINEDEFS'), 4));
  // Hexen: none of them
  Assert.AreEqual(0, Int16At(Lump(Convert(TUdmfGame.Hexen, LText), 'LINEDEFS'), 4));
  // Strife: passuse 8192, blockfloaters 1024, jumpover 512
  Assert.AreEqual(8192 or 1024 or 512, Int16At(Lump(Convert(TUdmfGame.Strife, LText), 'LINEDEFS'), 4));
end;

procedure TTestUdmfBehavior.TestMoreIdsOfTheLines;
var
  LMap: IUdmfConvertedMap;
  LExtra: TBytes;
begin
  LMap := Convert(TUdmfGame.Hexen, 'linedef { id = 5; moreids = "6 7 300 12"; }');
  LExtra := LMap.ExtraLines;
  // the ids 5, 6, 7 and 12 are bits of the first byte and the second; 300 does not fit
  Assert.AreEqual((1 shl 5) or (1 shl 6) or (1 shl 7), Integer(LExtra[0]));
  Assert.AreEqual(1 shl 4, Integer(LExtra[1]));
end;

procedure TTestUdmfBehavior.TestSoundOfTheSectorsOnlyWhereTheGameHasIt;
var
  LExtra: TBytes;
begin
  // the fake gives 1000 times the length and the first letter: DSDOROPN is 8008 + ... = 8000 + 68
  LExtra := Convert(TUdmfGame.Doom, 'sector { sound = "dsdoropn"; }').ExtraSectors;
  Assert.AreEqual(8068, Int32At(LExtra, 12 + 16 + 24 + 4 + 32 + 32));
  Assert.AreEqual(1, FSounds.Calls);

  FSounds.Calls := 0;
  Convert(TUdmfGame.Hexen, 'sector { sound = "dsdoropn"; }');
  Assert.AreEqual(0, FSounds.Calls);
end;

procedure TTestUdmfBehavior.TestPanningOfTheSectorsOnlyWhereTheGameHasIt;
var
  LDoom: TBytes;
  LHeretic: TBytes;
begin
  LDoom := Convert(TUdmfGame.Doom, 'sector { xpanningfloor = 1.0; }').ExtraSectors;
  LHeretic := Convert(TUdmfGame.Heretic, 'sector { xpanningfloor = 1.0; }').ExtraSectors;
  Assert.AreEqual(FRACUNIT, Int32At(LDoom, 12));
  // in Heretic the same bytes of the record are the rotation: nothing was written
  Assert.AreEqual(0, Int32At(LHeretic, 12));
  Assert.AreEqual(Length(LDoom) - 16, Length(LHeretic));
end;

procedure TTestUdmfBehavior.TestLongNamesAreCutAndTold;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Doom, 'sidedef { texturetop = "ABCDEFGHIJ"; }'), 'SIDEDEFS');
  Assert.AreEqual('ABCDEFGH', string(Char(LData[4]) + Char(LData[5]) + Char(LData[6]) + Char(LData[7]) +
    Char(LData[8]) + Char(LData[9]) + Char(LData[10]) + Char(LData[11])));
  Assert.IsTrue(Pos('"ABCDEFGHIJ" is longer than 8 characters', Warnings) > 0);
end;

procedure TTestUdmfBehavior.TestSideTextureDefaultsAreADash;
var
  LData: TBytes;
begin
  LData := Lump(Convert(TUdmfGame.Doom, 'sidedef { sector = 2; }'), 'SIDEDEFS');
  Assert.AreEqual(Integer(Ord('-')), Integer(LData[4]));
  Assert.AreEqual(0, Integer(LData[5]));
  Assert.AreEqual(Integer(Ord('-')), Integer(LData[12]));
  Assert.AreEqual(Integer(Ord('-')), Integer(LData[20]));
  Assert.AreEqual(2, Int16At(LData, 28));
end;

end.
