{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UMAPINFO library - behaviours of the classes      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.Behavior;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.MapInfo.Types,
  DelphiDoom.MapInfo.Intf, DelphiDoom.Tests.MapInfo.Fakes;

type
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoBehavior = class(TObject)
  private
    FEpisodes: TFakeEpisodes;
    FEpisodesIntf: IMapEpisodeSink;
    FLog: TFakeLog;
    FLogIntf: ILog;
    function ParseDoom(const AText: string): TArray<TMapInfoEntry>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestPreparerSeparatesTheBlocksAndDropsTheCommas;
    [Test]
    procedure TestPreparerKeepsWhatIsBetweenQuotes;
    [Test]
    procedure TestPreparerDropsTheComments;
    [Test]
    procedure TestIntertextKeepsTheLastCharacter;
    [Test]
    procedure TestIntertextClearIsKept;
    [Test]
    procedure TestIntertextLongerThanTheOldRecordIsKept;
    [Test]
    procedure TestParTimeIsInTics;
    [Test]
    procedure TestEpisodeWithoutSinkIsAnUnknownProperty;
    [Test]
    procedure TestMusicOfAMissingLumpIsForgotten;
    [Test]
    procedure TestBossActionClearThenAddKeepsOnlyTheNewOne;
    [Test]
    procedure TestParserNeedsTheServices;
    [Test]
    procedure TestTaggedRuleTakesTagsAndExits;
    [Test]
    procedure TestOpenRuleTakesEverything;
    [Test]
    procedure TestCatalogReplacesAMapOfTheSameName;
    [Test]
    procedure TestCatalogMergesWithTheDefaultAtTheSamePosition;
    [Test]
    procedure TestCatalogDoesNotMergeTheNextSecret;
    [Test]
    procedure TestClearMapsKeepsTheDefaults;
    [Test]
    procedure TestIndexOfMapFindsByName;
    [Test]
    procedure TestLoaderJoinsTheWadLumpsAndFiltersEachText;
    [Test]
    procedure TestMergerKeepsWhatTheNewerOneDoesNotSay;
  end;

implementation

uses
  DelphiDoom.MapInfo.Factory, DelphiDoom.MapInfo.TextPreparer, DelphiDoom.MapInfo.Merger,
  DelphiDoom.Tests.MapInfo.Corpus;

{ TTestMapInfoBehavior }

procedure TTestMapInfoBehavior.Setup;
begin
  FEpisodes := TFakeEpisodes.Create;
  FEpisodesIntf := FEpisodes;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
end;

procedure TTestMapInfoBehavior.TearDown;
begin
  FLogIntf := nil;
  FEpisodesIntf := nil;
end;

function TTestMapInfoBehavior.ParseDoom(const AText: string): TArray<TMapInfoEntry>;
begin
  Result := TMapInfoFactory.CreateParser(
    TMapInfoCorpus.ServicesOf(TMapInfoGame.Doom, FEpisodesIntf), FLogIntf).Parse(AText);
end;

procedure TTestMapInfoBehavior.TestPreparerSeparatesTheBlocksAndDropsTheCommas;
var
  LText: string;
begin
  LText := TMapInfoTextPreparer.Prepare('map MAP01 {a=1, 2}');
  // the last character is the line feed that was added, and it is not read
  Assert.AreEqual('map MAP01 '#13#10'_BEGINBLOCK'#13#10'a = 1 2'#13#10'_ENDBLOCK'#13#10#13, LText);
end;

procedure TTestMapInfoBehavior.TestPreparerKeepsWhatIsBetweenQuotes;
begin
  Assert.AreEqual('x = "a, {b} = c//d"'#13, TMapInfoTextPreparer.Prepare('x="a, {b} = c//d"'));
end;

procedure TTestMapInfoBehavior.TestPreparerDropsTheComments;
begin
  // the last character is the line feed that was added, and it is not read
  Assert.AreEqual('a '#13#10'b'#13, TMapInfoTextPreparer.Prepare('a // x'#13#10'b'));
  // a defect of the old code, kept: the end of a block comment stays in the text
  Assert.AreEqual('a */ b'#13, TMapInfoTextPreparer.Prepare('a /* y */ b'));
end;

procedure TTestMapInfoBehavior.TestIntertextKeepsTheLastCharacter;
var
  LEntries: TArray<TMapInfoEntry>;
begin
  LEntries := ParseDoom('map MAP01 { intertext = "You have won." }');
  Assert.AreEqual('You have won.', LEntries[0].InterText);
end;

procedure TTestMapInfoBehavior.TestIntertextClearIsKept;
var
  LEntries: TArray<TMapInfoEntry>;
begin
  LEntries := ParseDoom('map MAP01 { intertext = clear intertextsecret = clear }');
  Assert.AreEqual('-', LEntries[0].InterText);
  Assert.AreEqual('-', LEntries[0].InterTextSecret);
end;

procedure TTestMapInfoBehavior.TestIntertextLongerThanTheOldRecordIsKept;
var
  LEntries: TArray<TMapInfoEntry>;
  LLong: string;
begin
  // a word of the scanner is at most 1023 characters: the text is three lines
  LLong := '"' + StringOfChar('x', 500) + '"';
  LEntries := ParseDoom('map MAP01 { intertext = ' + LLong + ', ' + LLong + ', ' + LLong + ' }');
  Assert.AreEqual(3 * 500 + 2 * 2, Length(LEntries[0].InterText));
end;

procedure TTestMapInfoBehavior.TestParTimeIsInTics;
var
  LEntries: TArray<TMapInfoEntry>;
begin
  LEntries := ParseDoom('map MAP01 { partime = 30 }');
  Assert.AreEqual(30 * MAPINFO_TICRATE, LEntries[0].ParTime);
end;

procedure TTestMapInfoBehavior.TestEpisodeWithoutSinkIsAnUnknownProperty;
var
  LServices: TMapInfoServices;
  LEntries: TArray<TMapInfoEntry>;
begin
  LServices := TMapInfoCorpus.ServicesOf(TMapInfoGame.Strife, nil);
  LEntries := TMapInfoFactory.CreateParser(LServices, FLogIntf).Parse(
    'map MAP01 {'#13#10'episode = "M_EPI1", "Text", "k"'#13#10'levelname = "X"'#13#10'}');
  Assert.AreEqual('X', LEntries[0].LevelName);
  Assert.AreEqual('', FLog.Warnings);
end;

procedure TTestMapInfoBehavior.TestMusicOfAMissingLumpIsForgotten;
var
  LEntries: TArray<TMapInfoEntry>;
begin
  LEntries := ParseDoom('map MAP01 { music = "NOLUMP" }');
  Assert.AreEqual('', LEntries[0].Music);
  Assert.AreEqual(0, LEntries[0].MusicNumber);
end;

procedure TTestMapInfoBehavior.TestBossActionClearThenAddKeepsOnlyTheNewOne;
var
  LEntries: TArray<TMapInfoEntry>;
begin
  LEntries := ParseDoom('map MAP01 { bossaction = ZombieMan, 11, 0 bossaction = clear bossaction = Cyberdemon, 52, 0 }');
  Assert.AreEqual(1, Length(LEntries[0].BossActions));
  Assert.AreEqual(2, LEntries[0].BossActions[0].ActorType);
  Assert.IsFalse(LEntries[0].BossActionsCleared);
end;

procedure TTestMapInfoBehavior.TestParserNeedsTheServices;
var
  LServices: TMapInfoServices;
begin
  LServices := Default(TMapInfoServices);
  Assert.WillRaise(
    procedure
    begin
      TMapInfoFactory.CreateParser(LServices, nil);
    end, EArgumentNilException);
end;

procedure TTestMapInfoBehavior.TestTaggedRuleTakesTagsAndExits;
var
  LRule: IMapBossActionRule;
begin
  LRule := TMapInfoFactory.CreateTaggedBossActionRule(TArray<Integer>.Create(11, 124));
  Assert.IsTrue(LRule.IsAccepted(108, 5), 'a tag');
  Assert.IsTrue(LRule.IsAccepted(124, 0), 'an exit without a tag');
  Assert.IsFalse(LRule.IsAccepted(108, 0), 'no tag and not an exit');
  Assert.IsFalse(LRule.IsAccepted(105, 0), 'the exit of another game');
end;

procedure TTestMapInfoBehavior.TestOpenRuleTakesEverything;
begin
  Assert.IsTrue(TMapInfoFactory.CreateOpenBossActionRule.IsAccepted(1, 0));
end;

procedure TTestMapInfoBehavior.TestCatalogReplacesAMapOfTheSameName;
var
  LCatalog: IMapInfoCatalog;
  LEntry: TMapInfoEntry;
begin
  LCatalog := TMapInfoFactory.CreateCatalog(TFakeGame.Create);
  LEntry := Default(TMapInfoEntry);
  LEntry.MapName := 'MAP01';
  LEntry.LevelName := 'First';
  LEntry.ParTime := 70;
  LCatalog.AddParsed(LEntry, False);
  LEntry.LevelName := 'Second';
  LEntry.ParTime := 0;
  LCatalog.AddParsed(LEntry, False);
  Assert.AreEqual(1, LCatalog.MapCount);
  Assert.AreEqual('Second', LCatalog.GetMap(0).LevelName);
  Assert.AreEqual(0, LCatalog.GetMap(0).ParTime, 'a replaced map is not merged with the old one');
end;

procedure TTestMapInfoBehavior.TestCatalogMergesWithTheDefaultAtTheSamePosition;
var
  LCatalog: IMapInfoCatalog;
  LEntry: TMapInfoEntry;
begin
  LCatalog := TMapInfoFactory.CreateCatalog(TFakeGame.Create);
  LEntry := Default(TMapInfoEntry);
  LEntry.MapName := 'MAP01';
  LEntry.LevelName := 'Default one';
  LEntry.ParTime := 35;
  LCatalog.AddParsed(LEntry, True);
  LEntry := Default(TMapInfoEntry);
  LEntry.MapName := 'MAP09';
  LEntry.NextMap := 'MAP10';
  LCatalog.AddParsed(LEntry, False);
  Assert.AreEqual('MAP09', LCatalog.GetMap(0).MapName);
  Assert.AreEqual('Default one', LCatalog.GetMap(0).LevelName, 'the default of position 0');
  Assert.AreEqual(35, LCatalog.GetMap(0).ParTime);
  Assert.AreEqual('MAP10', LCatalog.GetMap(0).NextMap);
end;

procedure TTestMapInfoBehavior.TestCatalogDoesNotMergeTheNextSecret;
var
  LCatalog: IMapInfoCatalog;
  LEntry: TMapInfoEntry;
begin
  LCatalog := TMapInfoFactory.CreateCatalog(TFakeGame.Create);
  LEntry := Default(TMapInfoEntry);
  LEntry.MapName := 'MAP01';
  LEntry.NextSecret := 'MAP31';
  LCatalog.AddParsed(LEntry, True);
  LEntry.NextSecret := '';
  LCatalog.AddParsed(LEntry, False);
  Assert.AreEqual('', LCatalog.GetMap(0).NextSecret, 'as in the old UpdateMapEntry');
end;

procedure TTestMapInfoBehavior.TestClearMapsKeepsTheDefaults;
var
  LCatalog: IMapInfoCatalog;
  LEntry: TMapInfoEntry;
begin
  LCatalog := TMapInfoFactory.CreateCatalog(TFakeGame.Create);
  LEntry := Default(TMapInfoEntry);
  LEntry.MapName := 'MAP01';
  LCatalog.AddParsed(LEntry, True);
  LCatalog.AddParsed(LEntry, False);
  LCatalog.ClearMaps;
  Assert.AreEqual(0, LCatalog.MapCount);
  Assert.AreEqual(1, LCatalog.DefaultCount);
  LCatalog.ClearDefaults;
  Assert.AreEqual(0, LCatalog.DefaultCount);
end;

procedure TTestMapInfoBehavior.TestIndexOfMapFindsByName;
var
  LCatalog: IMapInfoCatalog;
  LEntry: TMapInfoEntry;
begin
  LCatalog := TMapInfoFactory.CreateCatalog(TFakeGame.Create);
  LEntry := Default(TMapInfoEntry);
  LEntry.MapName := 'MAP01';
  LCatalog.AddParsed(LEntry, False);
  LEntry.MapName := 'MAP02';
  LCatalog.AddParsed(LEntry, False);
  Assert.AreEqual(1, LCatalog.IndexOfMap('MAP02'));
  Assert.AreEqual(-1, LCatalog.IndexOfMap('MAP03'));
  Assert.AreEqual(-1, LCatalog.IndexOfDefault('MAP01'));
end;

procedure TTestMapInfoBehavior.TestLoaderJoinsTheWadLumpsAndFiltersEachText;
var
  LSource: TFakeTextSource;
  LSourceIntf: IMapInfoTextSource;
  LFilter: TFakeFilter;
  LFilterIntf: IMapInfoTextFilter;
  LCatalog: IMapInfoCatalog;
  LServices: TMapInfoServices;
begin
  LSource := TFakeTextSource.Create;
  LSourceIntf := LSource;
  LFilter := TFakeFilter.Create;
  LFilterIntf := LFilter;
  LSource.AddLump('UMAPINFO', 'map MAP01 { levelname = "A" }');
  LSource.AddLump('UMAPINFO', 'map MAP02 { levelname = "B" }');
  LSource.AddPak('umapinfo.txt','map MAP03 { levelname = "C" }');
  LServices := TMapInfoCorpus.ServicesOf(TMapInfoGame.Doom, FEpisodesIntf);
  LCatalog := TMapInfoFactory.CreateCatalog(LServices.Music);
  TMapInfoFactory.CreateLoader(LSourceIntf, LFilterIntf,
    TMapInfoFactory.CreateParser(LServices, FLogIntf), LCatalog).Load('umapinfo', False);
  Assert.AreEqual(3, LCatalog.MapCount);
  Assert.AreEqual(2, LFilter.Calls, 'one text for the lumps and one for the entry of the file');
end;

procedure TTestMapInfoBehavior.TestMergerKeepsWhatTheNewerOneDoesNotSay;
var
  LTarget: TMapInfoEntry;
  LNewer: TMapInfoEntry;
begin
  LTarget := Default(TMapInfoEntry);
  LTarget.LevelName := 'Old';
  LTarget.Lightning := True;
  LTarget.ParTime := 35;
  LNewer := Default(TMapInfoEntry);
  LNewer.NoJump := True;
  TMapInfoMerger.Update(LTarget, LNewer, TFakeGame.Create);
  Assert.AreEqual('Old', LTarget.LevelName);
  Assert.IsTrue(LTarget.Lightning);
  Assert.IsTrue(LTarget.NoJump);
  Assert.AreEqual(35, LTarget.ParTime);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMapInfoBehavior);

end.
