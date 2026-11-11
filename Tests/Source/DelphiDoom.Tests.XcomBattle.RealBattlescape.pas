{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - BattlescapeGame     }
{  and its steps against the real BattlescapeGame of OpenXcom (with a real     }
{  Game, Map and Camera: Tools\Verifica\176\battle\bgame.cpp)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealBattlescape;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.ZLib, System.RegularExpressions,
  System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.SaveLink,
  DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding, DelphiDoom.XcomBattle.Options,
  DelphiDoom.XcomBattle.View.Intf, DelphiDoom.XcomBattle.View.Null, DelphiDoom.XcomBattle.ExplosionState,
  DelphiDoom.XcomBattle.BattlescapeGame, DelphiDoom.Tests.XcomBattle.RealBattle, DelphiDoom.Tests.XcomMod.RealData;

type
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealBattlescape = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FVoxels: TArray<Word>;
    class function DataFolder: string; static;
    class function FindUp(const ARelative: string; AFolder: Boolean): string; static;
    class function ReadBytes(const APath: string): TBytes; static;
    class function ReadString(const APath: string): string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function Normalize(const AText: string): string; static;
    class function CollapseTrace(const AText: string): string; static;
    function RunScenario(const AFolder: string): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLoStessoStatoDelVeroBattlescapeGameDopoGliOrdini;
  end;

implementation

{ TTestXcomRealBattlescape }

class function TTestXcomRealBattlescape.FindUp(const ARelative: string; AFolder: Boolean): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 8 do
  begin
    Result := LFolder + ARelative;
    if (AFolder and DirectoryExists(Result)) or (not AFolder and FileExists(Result)) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TTestXcomRealBattlescape.DataFolder: string;
var
  LFolder: string;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_BG');
  if LFolder <> '' then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LFolder := FindUp('Tests\Data\XcomBattle\bg', True);
  if LFolder <> '' then
    LFolder := IncludeTrailingPathDelimiter(LFolder);
  Result := LFolder;
end;

class function TTestXcomRealBattlescape.ReadBytes(const APath: string): TBytes;
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

class function TTestXcomRealBattlescape.ReadString(const APath: string): string;
begin
  Result := TEncoding.UTF8.GetString(ReadBytes(APath));
end;

class function TTestXcomRealBattlescape.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := ReadBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TTestXcomRealBattlescape.Normalize(const AText: string): string;
begin
  // an empty list that yaml-cpp wrote as a block is the same list that the parser gives back in flow style
  Result := TRegEx.Replace(AText.Replace(#13#10, #10).TrimRight([#10]), ':\n\s+\[\]', ': []');
end;

class function TTestXcomRealBattlescape.CollapseTrace(const AText: string): string;
var
  LLines: TStringList;
  LLine: string;
  LPrevious: string;
begin
  // the real game ticks an animation until it is over: what is compared is the sequence of different steps
  Result := '';
  LPrevious := #0;
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LLine in LLines do
    begin
      if LLine = '' then
        Continue;
      if LLine = LPrevious then
        Continue;
      LPrevious := LLine;
      Result := Result + LLine + #10;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestXcomRealBattlescape.SetupFixture;
var
  LPath: string;
  LBytes: TBytes;
  LIndex: Integer;
begin
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
    LPath := FindUp('Reference\_dati\xcom_tftd\TFTD\TERRAIN\LOFTEMPS.DAT', False);
    if LPath <> '' then
    begin
      LBytes := TFile.ReadAllBytes(LPath);
      SetLength(FVoxels, Length(LBytes) div 2);
      for LIndex := 0 to High(FVoxels) do
        FVoxels[LIndex] := Word(LBytes[LIndex * 2]) or (Word(LBytes[LIndex * 2 + 1]) shl 8);
    end;
  end;
end;

procedure TTestXcomRealBattlescape.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

function TTestXcomRealBattlescape.RunScenario(const AFolder: string): string;
var
  LFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LContext: TXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
  LEngine: TXcomTileEngine;
  LEngineRef: IInterface;
  LPathfinding: TXcomPathfinding;
  LPathfindingRef: IInterface;
  LView: IXcomBattleView;
  LBattlescape: TXcomBattlescapeGame;
  LScript: TStringList;
  LStep: Integer;
  LOrder: string;
  LWords: TArray<string>;
  LTrace: string;
  LExpected: string;
  LActualYaml: string;
  LFailures: string;
  LGuard: Integer;
  LItem: TXcomBattleItem;
  LId: Integer;
  LPosition: TXcomPosition;
  LUnit: TXcomBattleUnit;
  LCandidate: TXcomBattleUnit;
  LName: string;
  LSeed: string;
  LParts: TArray<string>;
  LOrder2: TArray<Integer>;

  function FindUnit(AId: Integer): TXcomBattleUnit;
  var
    LOther: TXcomBattleUnit;
  begin
    Result := nil;
    for LOther in LBattle.Units do
      if LOther.Id = AId then
        Exit(LOther);
  end;

  procedure RunStates;
  begin
    LGuard := 3000;
    while LBattlescape.IsBusy and (LGuard > 0) do
    begin
      LTrace := LTrace + LBattlescape.FrontStateName + #10;
      LBattlescape.HandleState;
      Dec(LGuard);
    end;
    if LGuard <= 0 then
      LTrace := LTrace + 'GUARD' + #10;
  end;

  procedure Settle;
  var
    LCount: Integer;
  begin
    RunStates;
    LCount := 0;
    while (LBattle.Side = FACTION_PLAYER) and (LCount < 100) do
    begin
      LBattlescape.Think;
      if not LBattlescape.IsBusy then
        Break;
      RunStates;
      Inc(LCount);
    end;
  end;

begin
  LFailures := '';
  LName := ExtractFileName(ExcludeTrailingPathDelimiter(AFolder));
  LFile := TYamlFactory.CreateParser.LoadAll(ReadText(AFolder + 'start.sav'));
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  LScript := TStringList.Create;
  try
    LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
    LContext := TXcomBattleContext.Create(LRandom, False, False, FRuleset.Constants.FireDamageRange[0],
      FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange, 0);
    LBattle := TXcomBattleSaveLink.LoadBattle(LGame, FRuleset, LContext);
    try
      LEngine := TXcomTileEngine.Create(LBattle, LContext, FVoxels);
      LEngineRef := LEngine;
      LBattle.TileEngine := LEngine;
      LPathfinding := TXcomPathfinding.Create(LBattle);
      LPathfindingRef := LPathfinding;
      LBattle.Pathfinder := LPathfinding;
      LEngine.CalculateSunShading;
      LEngine.CalculateTerrainLighting;
      LEngine.CalculateUnitLighting;
      LEngine.RecalculateFov;
      LScript.Text := ReadString(AFolder + 'start.txt');
      LSeed := Trim(LScript.Values['seed']);
      LRandom.SetSeed(StrToUInt64(LSeed));
      LParts := Trim(LScript.Values['tileorder']).Split([',']);
      SetLength(LOrder2, Length(LParts));
      for LStep := 0 to High(LParts) do
        LOrder2[LStep] := StrToInt(LParts[LStep]);
      LEngine.SetDetonationOrder(LOrder2);
      if Normalize(string(TYamlFactory.Dump(LBattle.Save))) <> Normalize(ReadString(AFolder + 'start.yml')) then
        LFailures := LFailures + LName + ': the battle at the start differs' + sLineBreak;
      LView := TXcomBattleNullView.Create;
      LBattlescape := TXcomBattlescapeGame.Create(LBattle, LEngine, LPathfinding, FRuleset,
        TXcomBattleOptions.Default, LView, LGame.Difficulty);
      try
        LBattlescape.MissionCount := LGame.MissionStatistics.Count;
        LScript.Text := ReadString(AFolder + 'script.txt');
        for LStep := 0 to LScript.Count - 1 do
        begin
          LOrder := LScript[LStep];
          if Trim(LOrder) = '' then
            Continue;
          LWords := LOrder.Split([' ']);
          LTrace := '# ' + LOrder + #10;
          try
            if LWords[0] = 'select' then
              LBattle.SelectedUnit := FindUnit(StrToInt(LWords[1]))
            else if LWords[0] = 'placegrenade' then
            begin
              LPosition := TXcomPosition.Make(StrToInt(LWords[1]), StrToInt(LWords[2]), StrToInt(LWords[3]));
              LId := LBattle.CurrentItemId;
              LItem := TXcomBattleItem.Create(FRuleset.Items.Find(LWords[4]), LId);
              LBattle.CurrentItemId := LId;
              LItem.FuseTimer := StrToInt(LWords[5]);
              LItem.PreviousOwner := FindUnit(StrToInt(LWords[6]));
              LBattle.TileAt(LPosition).AddItem(LItem, FRuleset.Inventories.Find('STR_GROUND'));
              LBattle.AddItem(LItem);
            end
            else if LWords[0] = 'explode' then
            begin
              LPosition := TXcomPosition.Make(StrToInt(LWords[1]), StrToInt(LWords[2]), StrToInt(LWords[3]));
              LId := LBattle.CurrentItemId;
              LItem := TXcomBattleItem.Create(FRuleset.Items.Find(LWords[4]), LId);
              LBattle.CurrentItemId := LId;
              LBattle.OwnItem(LItem);
              LUnit := FindUnit(StrToInt(LWords[5]));
              if LWords[6] = '1' then
                LBattlescape.StatePushBack(TXcomExplosionState.Create(LBattlescape,
                  TXcomPosition.Make(LPosition.X * 16 + 8, LPosition.Y * 16 + 8, LPosition.Z * 24 + 10), LItem, LUnit,
                  LBattle.TileAt(LPosition)))
              else
                LBattlescape.StatePushBack(TXcomExplosionState.Create(LBattlescape,
                  TXcomPosition.Make(LPosition.X * 16 + 8, LPosition.Y * 16 + 8, LPosition.Z * 24 + 10), LItem, LUnit,
                  nil));
            end
            else if LWords[0] = 'endturn' then
            begin
              LBattlescape.EndTurnRequested := True;
              LBattlescape.StatePushBack(nil);
            end;
            Settle;
          except
            on E: Exception do
              LTrace := LTrace + 'EXCEPTION ' + E.ClassName + ': ' + E.Message + #10;
          end;
          LTrace := LTrace + Format('seed=%s side=%d turn=%d', [UIntToStr(LRandom.Seed), LBattle.Side, LBattle.Turn]) + #10;
          LExpected := ReadString(AFolder + Format('step%.3d.txt', [LStep]));
          if CollapseTrace(LTrace) <> CollapseTrace(LExpected) then
            LFailures := LFailures + Format('%s step %d (%s): trace%s   expected %s%s   actual   %s%s',
              [LName, LStep, LOrder, sLineBreak, sLineBreak, StringReplace(CollapseTrace(LExpected), #10, ' | ', [rfReplaceAll]),
              sLineBreak, StringReplace(CollapseTrace(LTrace), #10, ' | ', [rfReplaceAll])]) + sLineBreak;
          LActualYaml := Normalize(string(TYamlFactory.Dump(LBattle.Save)));
          if LActualYaml <> Normalize(ReadString(AFolder + Format('step%.3d.yml', [LStep]))) then
          begin
            LFailures := LFailures + Format('%s step %d (%s): the battle differs', [LName, LStep, LOrder]) + sLineBreak;
            if GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS') <> '' then
              TFile.WriteAllText(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS')) +
                Format('%s.step%.3d.yml', [LName, LStep]), LActualYaml);
          end;
        end;
      finally
        LBattlescape.Free;
        LView := nil;
      end;
    finally
      LBattle.Free;
    end;
  finally
    LScript.Free;
    LGame.Free;
  end;
  Result := LFailures;
end;

procedure TTestXcomRealBattlescape.DovrebbeDareLoStessoStatoDelVeroBattlescapeGameDopoGliOrdini;
var
  LFolder: string;
  LScenario: string;
  LCount: Integer;
  LFailed: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) or (Length(FVoxels) = 0) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LScenario in TDirectory.GetDirectories(LFolder) do
  begin
    LFailed := LFailed + RunScenario(IncludeTrailingPathDelimiter(LScenario));
    Inc(LCount);
  end;
  TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('Scenari confrontati: %d', [LCount]));
  Assert.IsTrue(LCount > 0, 'Nessuno scenario');
  Assert.AreEqual('', LFailed, 'Battaglie diverse dal vero BattlescapeGame');
end;

end.
