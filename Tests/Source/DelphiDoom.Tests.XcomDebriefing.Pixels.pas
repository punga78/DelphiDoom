{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom debriefing library - the pixels of the    }
{  screens against the real OpenXcom states (Tools\Verifica\176\battle\         }
{  debriefgen.cpp with DEBRIEF_PIXELS), with the real resources of TFTD         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomDebriefing.Pixels;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.ZLib, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.Xcom.Types,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>How many pixels of one kind of screen were compared and how many differ</summary>
  TXcomScreenTally = record
    Screens: Integer;
    Pixels: Int64;
    Different: Int64;
    FirstDifference: string;
  end;

  /// <summary>
  ///   The saved games of the end of a battle that the real OpenXcom evaluated and drew: the two pages of
  ///   DebriefingState, CannotReequipState, PromotionsState, ManageAlienContainmentState, CommendationState and
  ///   CommendationLateState are made by the library on the real resources of TFTD and every pixel is compared (in
  ///   RGB, through the palette of each side). Skipped without the data of the game
  /// </summary>
  [TestFixture]
  [Category('xcom-debriefing')]
  [Category('xcom-debriefing-real')]
  TTestXcomDebriefingPixels = class(TObject)
  strict private
    FWorld: TTestWorld;
    FRuleset: TXcomRuleset;
    FTallies: TDictionary<string, TXcomScreenTally>;
    class function FindUp(const ARelative: string): string; static;
    class function ReadBytes(const APath: string): TBytes; static;
    class function HasFile(const APath: string): Boolean; static;
    procedure Compare(const AKind, ACase: string; AState: TXcomState; const AExpected: TBytes);
    procedure CompareIfDumped(const AKind, ABasePath: string; AState: TXcomState);
    procedure RunCase(const APrePath, ATextPath, ABasePath: string);
    function Summary: string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDisegnareLeSchermateComeIlVeroOpenXcom;
  end;

implementation

uses
  DelphiDoom.Png.Provider, DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.XcomEngine.GameLoader.Intf,
  DelphiDoom.XcomEngine.ModGameLoader, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleCommendations,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomSave.SavedGameHolder, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.SaveLink, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.Names,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomDebriefing.Types, DelphiDoom.XcomDebriefing.Debriefing,
  DelphiDoom.XcomDebriefing.DebriefingState, DelphiDoom.XcomDebriefing.CannotReequipState,
  DelphiDoom.XcomDebriefing.PromotionsState, DelphiDoom.XcomDebriefing.ManageAlienContainmentState,
  DelphiDoom.XcomDebriefing.CommendationState, DelphiDoom.XcomDebriefing.CommendationLateState,
  DelphiDoom.Tests.XcomBattle.RealBattle;

type
  TStateSurfaces = class(TXcomState);

const
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;
  /// <summary>The two medals that the harness makes (AwardTestMedals of debriefgen.cpp)</summary>
  MEDAL_PLAIN = 'STR_NEW_RANK';
  MEDAL_NOUN = 'STR_SPACE_USED';

class function TTestXcomDebriefingPixels.FindUp(const ARelative: string): string;
var
  LFolder, LParent: string;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  while LFolder <> '' do
  begin
    if TDirectory.Exists(TPath.Combine(LFolder, ARelative)) then
      Exit(TPath.Combine(LFolder, ARelative));
    LParent := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
    if LParent = LFolder then
      Break;
    LFolder := LParent;
  end;
  Result := '';
end;

class function TTestXcomDebriefingPixels.HasFile(const APath: string): Boolean;
begin
  Result := FileExists(APath) or FileExists(APath + '.gz');
end;

class function TTestXcomDebriefingPixels.ReadBytes(const APath: string): TBytes;
var
  LSource: TFileStream;
  LDecompress: TZDecompressionStream;
  LTarget: TBytesStream;
begin
  if not FileExists(APath + '.gz') then
    Exit(TFile.ReadAllBytes(APath));
  LSource := TFileStream.Create(APath + '.gz', fmOpenRead or fmShareDenyWrite);
  try
    LDecompress := TZDecompressionStream.Create(LSource, 15 + 16);
    try
      LTarget := TBytesStream.Create;
      try
        LTarget.CopyFrom(LDecompress, 0);
        Result := Copy(LTarget.Bytes, 0, LTarget.Size);
      finally
        LTarget.Free;
      end;
    finally
      LDecompress.Free;
    end;
  finally
    LSource.Free;
  end;
end;

procedure TTestXcomDebriefingPixels.SetupFixture;
var
  LData: string;
  LSettings: TXcomLoaderSettings;
  LLoader: TXcomModGameLoader;
  LLoaderRef: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
begin
  FTallies := TDictionary<string, TXcomScreenTally>.Create;
  // the folder of the real program that the harness read: common, standard and the game in TFTD
  LData := FindUp('Reference\_dati\xcom_tftd\openxcom');
  if (LData = '') or not TDirectory.Exists(TPath.Combine(LData, 'TFTD')) then
    Exit;
  LSettings.DataFolder := LData;
  LSettings.GameFolder := TPath.Combine(LData, 'TFTD');
  LSettings.ModId := 'xcom2';
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLoaderRef := LLoader;
  LLoader.LoadRules := True;
  LLoaderRef.Load(LResources, LLanguage);
  FWorld := TTestWorld.Create;
  FWorld.Game.AdoptData(LResources, LLanguage);
  FRuleset := TXcomStrategy.Ruleset(FWorld.Game);
end;

procedure TTestXcomDebriefingPixels.TearDownFixture;
begin
  FWorld.Free;
  FTallies.Free;
end;

procedure TTestXcomDebriefingPixels.Compare(const AKind, ACase: string; AState: TXcomState; const AExpected: TBytes);
var
  LTarget: TXcomSurface;
  LWidget: TXcomWidget;
  LColors: array[0..255] of TXcomColor;
  LTally: TXcomScreenTally;
  LIndex, LX, LY, LWidth, LHeight, LPaletteAt: Integer;
  LMine, LTheirs: Byte;
  LBefore: Int64;
begin
  if not FTallies.TryGetValue(AKind, LTally) then
    LTally := Default(TXcomScreenTally);
  LWidth := PInteger(@AExpected[0])^;
  LHeight := PInteger(@AExpected[4])^;
  Assert.AreEqual(SCREEN_WIDTH, LWidth, ACase + AKind + ' width');
  Assert.AreEqual(SCREEN_HEIGHT, LHeight, ACase + AKind + ' height');
  LPaletteAt := 8 + LWidth * LHeight;
  // what the harness does after State::init: every surface drawn and blitted on a surface of the size of the screen
  for LIndex := 0 to 255 do
    LColors[LIndex] := AState.Palette^[LIndex];
  LTarget := TXcomSurface.Create(SCREEN_WIDTH, SCREEN_HEIGHT);
  try
    LTarget.SetColors(LColors);
    for LWidget in TStateSurfaces(AState).Surfaces do
    begin
      LWidget.Draw;
      LWidget.Blit(LTarget);
    end;
    Inc(LTally.Screens);
    LBefore := LTally.Different;
    for LY := 0 to LHeight - 1 do
      for LX := 0 to LWidth - 1 do
      begin
        LMine := LTarget.GetPixel(LX, LY);
        LTheirs := AExpected[8 + LY * LWidth + LX];
        Inc(LTally.Pixels);
        if (LColors[LMine].Red <> AExpected[LPaletteAt + LTheirs * 3]) or
          (LColors[LMine].Green <> AExpected[LPaletteAt + LTheirs * 3 + 1]) or
          (LColors[LMine].Blue <> AExpected[LPaletteAt + LTheirs * 3 + 2]) then
        begin
          Inc(LTally.Different);
          if LTally.FirstDifference = '' then
            LTally.FirstDifference := Format('%s (%d,%d) index %d instead of %d', [ACase, LX, LY, LMine, LTheirs]);
        end;
      end;
  finally
    LTarget.Free;
  end;
  // the screens that differ, one per line, to look for what they have in common
  if LTally.Different > LBefore then
    System.Writeln(Format('%s%s: %d different', [ACase, AKind, LTally.Different - LBefore]));
  FTallies.AddOrSetValue(AKind, LTally);
end;

procedure TTestXcomDebriefingPixels.CompareIfDumped(const AKind, ABasePath: string; AState: TXcomState);
begin
  // the state is made in any case (making it changes the soldiers as it does in the harness) and then freed
  try
    if HasFile(ABasePath + AKind) then
    begin
      AState.Init;
      Compare(AKind, ExtractFileName(ABasePath), AState, ReadBytes(ABasePath + AKind));
    end;
  finally
    AState.Free;
  end;
end;

procedure TTestXcomDebriefingPixels.RunCase(const APrePath, ATextPath, ABasePath: string);
var
  LFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRules: TXcomRulesetRules;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LContext: TXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
  LReport: TXcomDebriefingReport;
  LOptions: TXcomDebriefingOptions;
  LHost: TXcomStateHost;
  LDebriefing: TXcomDebriefingState;
  LAlive, LDead: TList<TXcomSoldier>;
  LPlain, LNoun: TXcomRuleCommendations;
  LCommendation: TXcomSoldierCommendation;
  LSoldier: TXcomSoldier;
  LIndex: Integer;
  LText: TStringList;
  LAborted: Boolean;
  LBytes: TBytes;
  LYaml: TYamlText;
begin
  LBytes := ReadBytes(APrePath);
  SetLength(LYaml, Length(LBytes));
  Move(LBytes[0], LYaml[1], Length(LBytes));
  LFile := TYamlFactory.CreateParser.LoadAll(LYaml);
  LText := TStringList.Create;
  try
    LText.Text := TEncoding.UTF8.GetString(ReadBytes(ATextPath));
    LAborted := Trim(LText.Values['aborted']) = '1';
  finally
    LText.Free;
  end;
  LHost := FWorld.Game;
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LRules := TXcomRulesetRules.Create(FRuleset);
  LGame := TXcomSavedGame.Create;
  // the session owns the saved game and the adapters of the rules from now on
  LHost.SetSession(TXcomSavedGameHolder.Create(LGame, LRules, LRandom));
  try
    LGame.Load(LFile, FRuleset, LRules, LSettings, False, LRandom);
    LContext := TXcomBattleContext.Create(LRandom);
    LBattle := TXcomBattleSaveLink.LoadBattle(LGame, FRuleset, LContext);
    try
      LBattle.Aborted := LAborted;
      LOptions := TXcomDebriefingOptions.Default;
      LOptions.CraftName :=
        function(ACraft: TXcomCraft): string
        begin
          Result := TXcomBaseNames.CraftName(ACraft, LHost.Language);
        end;
      LReport := TXcomDebriefing.Run(LGame, LBattle, FRuleset, LRules, LOptions, nil);
      try
        LDebriefing := TXcomDebriefingState.Create(LHost, LReport, nil);
        try
          // init pushes the message of the alien that died without containment: its palette is the one of the
          // pictures of the mod while the debriefing is drawn, as in the harness
          LDebriefing.Init;
          Compare('.pix', ExtractFileName(ABasePath), LDebriefing, ReadBytes(ABasePath + '.pix'));
          LDebriefing.ShowPage(True);
          Compare('.pix2', ExtractFileName(ABasePath), LDebriefing, ReadBytes(ABasePath + '.pix2'));
        finally
          LDebriefing.Free;
        end;
        if LReport.MissingItems.Count > 0 then
          CompareIfDumped('.cannot', ABasePath, TXcomCannotReequipState.Create(LHost, LReport.MissingItems));
        if LReport.Promotions then
          CompareIfDumped('.promo', ABasePath, TXcomPromotionsState.Create(LHost, LGame));
        if Assigned(LReport.Base) and not LReport.DestroyBase then
        begin
          CompareIfDumped('.contain', ABasePath,
            TXcomManageAlienContainmentState.Create(LHost, LReport.Base, LGame, FRuleset, ooBattlescape));
          // the medals of AwardTestMedals: the TFTD mods have none
          LPlain := TXcomRuleCommendations.Create;
          LNoun := TXcomRuleCommendations.Create;
          LAlive := TList<TXcomSoldier>.Create;
          LDead := TList<TXcomSoldier>.Create;
          try
            LPlain.Load(TTestWorld.Parse('description: A'#10'criteria:'#10'  totalKills: [1, 2, 2, 5]'#10'sprite: 0'#10));
            LNoun.Load(TTestWorld.Parse('description: B'#10'criteria:'#10'  totalMissions: [3, 3, 6]'#10'sprite: 1'#10));
            FRuleset.Commendations.SetValue(MEDAL_PLAIN, LPlain);
            FRuleset.Commendations.SetValue(MEDAL_NOUN, LNoun);
            for LIndex := 0 to LReport.Base.Soldiers.Count - 1 do
            begin
              if LIndex >= 3 then
                Break;
              LSoldier := LReport.Base.Soldiers[LIndex];
              case LIndex of
                0:
                  LSoldier.Diary.Commendations.Add(TXcomSoldierCommendation.Create(MEDAL_PLAIN, 'noNoun'));
                1:
                  begin
                    LCommendation := TXcomSoldierCommendation.Create(MEDAL_PLAIN, 'noNoun');
                    LCommendation.AddDecoration;
                    LCommendation.AddDecoration;
                    LSoldier.Diary.Commendations.Add(LCommendation);
                    LSoldier.Diary.Commendations.Add(TXcomSoldierCommendation.Create(MEDAL_NOUN, 'STR_AQUATOID'));
                  end;
                2:
                  begin
                    LSoldier.Diary.Commendations.Add(TXcomSoldierCommendation.Create(MEDAL_NOUN, 'STR_GILLMAN'));
                    LCommendation := TXcomSoldierCommendation.Create(MEDAL_NOUN, 'STR_AQUATOID');
                    LCommendation.AddDecoration;
                    LSoldier.Diary.Commendations.Add(LCommendation);
                  end;
              end;
              LAlive.Add(LSoldier);
            end;
            for LIndex := 0 to LGame.DeadSoldiers.Count - 1 do
            begin
              if LIndex >= 2 then
                Break;
              LSoldier := LGame.DeadSoldiers[LIndex];
              if LIndex = 0 then
              begin
                LCommendation := TXcomSoldierCommendation.Create(MEDAL_PLAIN, 'noNoun');
                LCommendation.AddDecoration;
                LSoldier.Diary.Commendations.Add(LCommendation);
                LSoldier.Diary.Commendations.Add(TXcomSoldierCommendation.Create(MEDAL_NOUN, 'STR_GILLMAN'));
              end;
              LDead.Add(LSoldier);
            end;
            if LDead.Count > 0 then
              CompareIfDumped('.commlate', ABasePath,
                TXcomCommendationLateState.Create(LHost, LDead, FRuleset.Commendations));
            if LAlive.Count > 0 then
              CompareIfDumped('.comm', ABasePath,
                TXcomCommendationState.Create(LHost, LAlive, FRuleset.Commendations));
          finally
            FRuleset.Commendations.Remove(MEDAL_PLAIN);
            FRuleset.Commendations.Remove(MEDAL_NOUN);
            LDead.Free;
            LAlive.Free;
            LNoun.Free;
            LPlain.Free;
          end;
        end;
      finally
        LReport.Free;
      end;
    finally
      LBattle.Free;
    end;
  finally
    LHost.SetSession(nil);
  end;
end;

function TTestXcomDebriefingPixels.Summary: string;
var
  LKinds: TArray<string>;
  LKind: string;
  LTally: TXcomScreenTally;
begin
  Result := '';
  LKinds := FTallies.Keys.ToArray;
  TArray.Sort<string>(LKinds);
  for LKind in LKinds do
  begin
    LTally := FTallies[LKind];
    Result := Result + Format('%s: %d screens, %d pixels, %d different', [LKind, LTally.Screens, LTally.Pixels,
      LTally.Different]);
    if LTally.FirstDifference <> '' then
      Result := Result + ' (first: ' + LTally.FirstDifference + ')';
    Result := Result + sLineBreak;
  end;
end;

procedure TTestXcomDebriefingPixels.DovrebbeDisegnareLeSchermateComeIlVeroOpenXcom;
var
  LFolder, LInputs, LPath, LBase, LName, LKind: string;
  LCount: Integer;
  LDifferent: Int64;
begin
  if not Assigned(FWorld) then
  begin
    Assert.Pass('Senza i dati di TFTD il confronto dei pixel non si fa');
    Exit;
  end;
  // DELPHIDOOM_XCOMDEBRIEF_PIXELS: a folder written by debriefgen (the dumps with their .pre.sav and .txt); otherwise
  // the dumps of the repository, whose saved games are the ones of the folder above
  LFolder := GetEnvironmentVariable('DELPHIDOOM_XCOMDEBRIEF_PIXELS');
  if LFolder <> '' then
  begin
    LFolder := IncludeTrailingPathDelimiter(LFolder);
    LInputs := LFolder;
  end
  else
  begin
    LInputs := FindUp('Tests\Data\XcomDebriefing');
    Assert.AreNotEqual('', LInputs, 'Tests\Data\XcomDebriefing');
    LInputs := IncludeTrailingPathDelimiter(LInputs);
    LFolder := LInputs + 'pixels\';
  end;
  LCount := 0;
  for LPath in TDirectory.GetFiles(LFolder, 'deb*.pix*') do
  begin
    LName := ExtractFileName(LPath);
    if not (LName.EndsWith('.pix') or LName.EndsWith('.pix.gz')) then
      Continue;
    LName := Copy(LName, 1, Pos('.pix', LName) - 1);
    LBase := LFolder + LName;
    RunCase(LInputs + LName + '.pre.sav', LInputs + LName + '.txt', LBase);
    Inc(LCount);
  end;
  System.Writeln(Format('debriefing pixels, %d cases', [LCount]));
  System.Writeln(Summary);
  Assert.IsTrue(LCount > 0, 'Nessun file deb*.pix trovato in ' + LFolder);
  LDifferent := 0;
  for LKind in FTallies.Keys do
    Inc(LDifferent, FTallies[LKind].Different);
  Assert.AreEqual(Int64(0), LDifferent, Summary);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomDebriefingPixels);

end.
