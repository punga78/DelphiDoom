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
  System.SysUtils, System.Math, System.Classes, System.IOUtils, System.ZLib, System.RegularExpressions,
  System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.SaveLink,
  DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding, DelphiDoom.XcomBattle.Options,
  DelphiDoom.XcomBattle.View.Intf, DelphiDoom.XcomBattle.View.Null, DelphiDoom.XcomBattle.ExplosionState,
  DelphiDoom.XcomBattle.BattlescapeGame, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.AIThinker,
  DelphiDoom.XcomBattle.ReactionFire, DelphiDoom.XcomBattle.UnitTurnState, DelphiDoom.Tests.XcomBattle.RealBattle,
  DelphiDoom.Tests.XcomMod.RealData, DelphiDoom.XcomMod.RuleInterface, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomBattlescape.Sprites.Intf, DelphiDoom.XcomBattlescape.ModSprites, DelphiDoom.XcomBattlescape.Map,
  DelphiDoom.XcomBattlescape.MapView;

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
    FMapsCompared: Integer;
    FCompareMaps: Boolean;
    class function DataFolder: string; static;
    class function FindUp(const ARelative: string; AFolder: Boolean): string; static;
    class function ReadBytes(const APath: string): TBytes; static;
    class function MapFiles(const AFolder: string): TArray<string>; static;
    class function HasMaps(const AFolder: string): Boolean; static;
    class function ReadString(const APath: string): string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function Normalize(const AText: string): string; static;
    class function CompareMap(const AExpected: TBytes; const AActual: TXcomSurface): string; static;
    class function CollapseTrace(const AText: string): string; static;
    class function FirstDifference(const AExpected, AActual: string): string; static;
    function RunScenario(const AFolder: string): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLoStessoStatoDelVeroBattlescapeGameDopoGliOrdini;
    [Test]
    procedure DovrebbeDisegnareLaMappaComeIlVeroMapDraw;
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

class function TTestXcomRealBattlescape.MapFiles(const AFolder: string): TArray<string>;
var
  LList: TList<string>;
  LFile: string;
begin
  // stepNNN.map or stepNNN.map.gz (a plain .map is ignored by git: it is the extension of the linker maps)
  LList := TList<string>.Create;
  try
    for LFile in TDirectory.GetFiles(AFolder, 'step*.map*') do
      if LFile.EndsWith('.map') then
        LList.Add(LFile)
      else if LFile.EndsWith('.map.gz') then
        LList.Add(Copy(LFile, 1, Length(LFile) - 3));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TTestXcomRealBattlescape.HasMaps(const AFolder: string): Boolean;
begin
  Result := Length(MapFiles(AFolder)) > 0;
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

class function TTestXcomRealBattlescape.CompareMap(const AExpected: TBytes; const AActual: TXcomSurface): string;
var
  LWidth: Integer;
  LHeight: Integer;
  LActual: TBytes;
  LIndex: Integer;
  LDifferent: Integer;
  LFirst: Integer;
begin
  // the file of the harness: width and height (32 bit) and the indexes of the colors
  LWidth := PInteger(@AExpected[0])^;
  LHeight := PInteger(@AExpected[4])^;
  if (LWidth <> AActual.Width) or (LHeight <> AActual.Height) then
    Exit(Format('size %dx%d expected %dx%d', [AActual.Width, AActual.Height, LWidth, LHeight]));
  LActual := AActual.Pixels;
  LDifferent := 0;
  LFirst := -1;
  for LIndex := 0 to LWidth * LHeight - 1 do
    if AExpected[8 + LIndex] <> LActual[LIndex] then
    begin
      Inc(LDifferent);
      if LFirst < 0 then
        LFirst := LIndex;
    end;
  if LDifferent = 0 then
    Result := ''
  else
    Result := Format('%d pixels differ, first at (%d,%d) expected %d actual %d', [LDifferent, LFirst mod LWidth,
      LFirst div LWidth, AExpected[8 + LFirst], LActual[LFirst]]);
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

class function TTestXcomRealBattlescape.FirstDifference(const AExpected, AActual: string): string;
var
  LExpected: TArray<string>;
  LActual: TArray<string>;
  LIndex: Integer;
  LLeft: string;
  LRight: string;
begin
  LExpected := AExpected.Split([#10]);
  LActual := AActual.Split([#10]);
  for LIndex := 0 to Max(High(LExpected), High(LActual)) do
  begin
    if LIndex <= High(LExpected) then
      LLeft := LExpected[LIndex]
    else
      LLeft := '(end)';
    if LIndex <= High(LActual) then
      LRight := LActual[LIndex]
    else
      LRight := '(end)';
    if LLeft <> LRight then
      Exit(Format('line %d expected [%s] actual [%s]', [LIndex, LLeft, LRight]));
  end;
  Result := 'no difference';
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
  LThinker: TXcomAIThinker;
  LConfig: TXcomAIConfig;
  LNames: TArray<string>;
  LDiscovered: Integer;
  LAction: TXcomBattleAction;
  LTarget: TXcomPosition;
  LStep2: Integer;
  LTicks: Integer;
  LX: Integer;
  LY: Integer;
  LCount: Integer;
  LOldTile: TXcomTile;
  LMap: TXcomBattleMap;
  LSprites: IXcomBattleSprites;
  LMapFile: string;
  LMapBytes: TBytes;
  LDumpMap: Boolean;
  LMapDiff: string;
  LMapDrawn: Boolean;
  LMapUnits: string;
  LTraceList: TStringList;
  LPair: TPair<Integer, Integer>;

  function EnsureMap: TXcomBattleMap;
  var
    LSettings: TXcomBattleMapSettings;
    LElement: TXcomInterfaceElement;
    LFirst: string;
    LHeader: TBytes;
  begin
    if not Assigned(LMap) then
    begin
      LSprites := TXcomModSprites.Create(FData.CreateFiles);
      // the size of the map is the one of the screen of the real game: the header of the first dump
      LSettings.Width := 640;
      LSettings.Height := 400;
      for LFirst in MapFiles(AFolder) do
      begin
        LHeader := ReadBytes(LFirst);
        LSettings.Width := PInteger(@LHeader[0])^;
        LSettings.Height := PInteger(@LHeader[4])^;
        Break;
      end;
      FRuleset.Interfaces.Find('battlescape').Elements.TryGetValue('icons', LElement);
      LSettings.IconWidth := LElement.W;
      LSettings.IconHeight := LElement.H;
      LSettings.SmokeOffset := FRuleset.Constants.SmokeOffset;
      LSettings.UnderwaterSmokeOffset := FRuleset.Constants.UnderwaterSmokeOffset;
      LMap := TXcomBattleMap.Create(LBattle, LSprites, LSettings);
    end;
    Result := LMap;
  end;

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
      LTrace := LTrace + LBattlescape.FrontStateName + '@' + UIntToStr(LRandom.Seed) + #10;
      LBattlescape.HandleState;
      Inc(LTicks);
      // the animation timer of the game runs about every third tick of the steps (UFO doors open with it)
      if LTicks mod 3 = 0 then
        if Assigned(LMap) then
          LMap.Animate(False)
        else
          LBattlescape.AnimateTiles;
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
  LMap := nil;
  LDumpMap := False;
  LTicks := 0;
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
      // a scenario with maps has the map, which the game talks to (camera, cursor, the drawings of the units)
      if HasMaps(AFolder) then
        LView := TXcomBattleMapView.Create(EnsureMap, LView);
      LBattlescape := TXcomBattlescapeGame.Create(LBattle, LEngine, LPathfinding, FRuleset,
        TXcomBattleOptions.Default, LView, LGame.Difficulty);
      LConfig.DifficultyCoefficient := FRuleset.Settings.DifficultyCoefficient[LGame.Difficulty];
      LConfig.TurnUseGrenade := FRuleset.Settings.TurnAIUseGrenade;
      LConfig.TurnUseBlaster := FRuleset.Settings.TurnAIUseBlaster;
      LConfig.ExplosionHeight := 0;
      LThinker := TXcomAIThinker.Create(LBattle, LEngine, LPathfinding, LConfig);
      SetLength(LNames, LGame.Discovered.Count);
      for LDiscovered := 0 to LGame.Discovered.Count - 1 do
        LNames[LDiscovered] := LGame.Discovered[LDiscovered].Name;
      try
        LBattlescape.ReactionFire := TXcomReactionFire.Create(LBattlescape, LThinker,
          TXcomReactionFire.ResearchOf(LNames));
        LBattlescape.MissionCount := LGame.MissionStatistics.Count;
        LBattlescape.AIThinker := LThinker;
        // BattlescapeState::init: the units are drawn for the first time
        if Assigned(LMap) then
          LMap.CacheUnits;
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
            else if (LWords[0] = 'walk') or (LWords[0] = 'shoot') or (LWords[0] = 'throw') or (LWords[0] = 'kneel') or
              (LWords[0] = 'turn') then
            begin
              // what the player does with the mouse: select a soldier, choose the action, click on the map
              LUnit := FindUnit(StrToInt(LWords[1]));
              LBattle.SelectedUnit := LUnit;
              LAction := LBattlescape.CurrentAction;
              LAction.Targeting := False;
              LAction.ActionType := BA_NONE;
              LAction.Actor := LUnit;
              LAction.Weapon := nil;
              LAction.Waypoints.Clear;
              LAction.AutoShotCounter := 0;
              LStep2 := 2;
              if LWords[0] = 'shoot' then
              begin
                LAction.ActionType := StrToInt(LWords[2]);
                Inc(LStep2);
                LAction.Weapon := LUnit.GetMainHandWeapon;
              end
              else if LWords[0] = 'throw' then
              begin
                LAction.ActionType := BA_THROW;
                LAction.Weapon := LUnit.GetGrenadeFromBelt;
                if Assigned(LAction.Weapon) then
                  LAction.Weapon.FuseTimer := 0;
              end;
              if (LWords[0] = 'shoot') or (LWords[0] = 'throw') then
              begin
                if Assigned(LAction.Weapon) then
                  LAction.TimeUnits := LUnit.GetActionTus(LAction.ActionType, LAction.Weapon)
                else
                  LAction.TimeUnits := 0;
                LAction.Targeting := Assigned(LAction.Weapon);
              end;
              if LWords[0] = 'kneel' then
                LBattlescape.Kneel(LUnit)
              else if LWords[0] = 'turn' then
              begin
                LAction.Target := TXcomPosition.Make(StrToInt(LWords[2]), StrToInt(LWords[3]), StrToInt(LWords[4]));
                LBattlescape.StatePushBack(TXcomUnitTurnState.Create(LBattlescape, LAction));
              end
              else if ((LWords[0] <> 'shoot') or Assigned(LAction.Weapon)) and
                ((LWords[0] <> 'throw') or Assigned(LAction.Weapon)) then
              begin
                LTarget := TXcomPosition.Make(StrToInt(LWords[LStep2]), StrToInt(LWords[LStep2 + 1]),
                  StrToInt(LWords[LStep2 + 2]));
                LBattlescape.PrimaryAction(LTarget);
              end;
            end
            else if LWords[0] = 'endturn' then
            begin
              LBattlescape.EndTurnRequested := True;
              LBattlescape.StatePushBack(nil);
            end
            else if LWords[0] = 'place' then
            begin
              // a unit is put on a free tile (the old tiles are emptied first)
              LUnit := FindUnit(StrToInt(LWords[1]));
              LPosition := TXcomPosition.Make(StrToInt(LWords[2]), StrToInt(LWords[3]), StrToInt(LWords[4]));
              if Assigned(LUnit) and LBattle.SetUnitPosition(LUnit, LPosition, True) then
              begin
                for LX := LUnit.Armor.Size - 1 downto 0 do
                  for LY := LUnit.Armor.Size - 1 downto 0 do
                  begin
                    LOldTile := LBattle.TileAt(LUnit.Position + TXcomPosition.Make(LX, LY, 0));
                    if Assigned(LOldTile) and (LOldTile.CurrentUnit = LUnit) then
                      LOldTile.SetUnit(nil);
                  end;
                LBattle.SetUnitPosition(LUnit, LPosition, False);
                LEngine.RecalculateFov;
              end
              else
                LTrace := LTrace + 'PLACEFAILED' + #10;
            end
            else if LWords[0] = 'melee' then
            begin
              // the menu of the actions for a hit, then handleNonTargetAction
              LUnit := FindUnit(StrToInt(LWords[1]));
              if Assigned(LUnit) then
              begin
                LBattle.SelectedUnit := LUnit;
                LAction := LBattlescape.CurrentAction;
                LAction.Targeting := False;
                LAction.Actor := LUnit;
                LAction.Weapon := LUnit.GetMeleeWeapon;
                LAction.Waypoints.Clear;
                LAction.ResultText := '';
                LAction.ActionType := BA_HIT;
                if Assigned(LAction.Weapon) then
                begin
                  LAction.TimeUnits := LUnit.GetActionTus(BA_HIT, LAction.Weapon);
                  if not LBattle.IsItemUsable(LAction.Weapon) then
                    LAction.ResultText := 'STR_UNUSABLE'
                  else if LAction.TimeUnits > LUnit.TimeUnits then
                    LAction.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS'
                  else if LEngine.ValidMeleeRange(LUnit.Position, LUnit.Direction, LUnit, nil, LTarget) then
                    LAction.Target := LTarget
                  else
                    LAction.ResultText := 'STR_THERE_IS_NO_ONE_THERE';
                  if LAction.ResultText <> '' then
                    LAction.ActionType := BA_NONE;
                  LBattlescape.HandleNonTargetAction;
                end
                else
                  LTrace := LTrace + 'NOWEAPON' + #10;
              end;
            end
            else if LWords[0] = 'psi' then
            begin
              // the psi button, then a click on the target
              LUnit := FindUnit(StrToInt(LWords[1]));
              if Assigned(LUnit) and Assigned(LUnit.GetSpecialWeapon(TXcomRuleItem.BT_PSIAMP)) then
              begin
                LBattle.SelectedUnit := LUnit;
                LAction := LBattlescape.CurrentAction;
                LAction.Targeting := False;
                LAction.ActionType := BA_NONE;
                LAction.Actor := LUnit;
                LAction.Weapon := nil;
                LAction.Waypoints.Clear;
                LBattlescape.PsiButtonAction;
                LAction.ActionType := StrToInt(LWords[2]);
                LBattlescape.PrimaryAction(TXcomPosition.Make(StrToInt(LWords[3]), StrToInt(LWords[4]),
                  StrToInt(LWords[5])));
              end
              else
                LTrace := LTrace + 'NOPSI' + #10;
            end
            else if LWords[0] = 'setmorale' then
            begin
              LUnit := FindUnit(StrToInt(LWords[1]));
              if Assigned(LUnit) then
                LUnit.MoraleChange(StrToInt(LWords[2]) - LUnit.Morale);
            end
            else if LWords[0] = 'camera' then
              EnsureMap.Camera.CenterOnPosition(TXcomPosition.Make(StrToInt(LWords[1]), StrToInt(LWords[2]),
                StrToInt(LWords[3])), False)
            else if LWords[0] = 'viewlevel' then
              EnsureMap.Camera.SetViewLevel(StrToInt(LWords[1]))
            else if LWords[0] = 'dumpmap' then
              LDumpMap := True
            else if LWords[0] = 'init' then
              // BattlescapeState::init after the screen of the next turn
              LBattlescape.Init
            else if LWords[0] = 'aiturn' then
            begin
              // the other side plays: think() chooses the AI actions until it ends its turn
              LCount := 2000;
              while (LBattle.Side <> FACTION_PLAYER) and (LCount > 0) do
              begin
                LBattlescape.Think;
                RunStates;
                Dec(LCount);
              end;
              if LCount <= 0 then
                LTrace := LTrace + 'AIGUARD' + #10;
            end;
            if LWords[0] <> 'aiturn' then
              Settle;
          except
            on E: Exception do
              LTrace := LTrace + 'EXCEPTION ' + E.ClassName + ': ' + E.Message + #10;
          end;
          LTrace := LTrace + Format('seed=%s side=%d turn=%d', [UIntToStr(LRandom.Seed), LBattle.Side, LBattle.Turn]) + #10;
          LExpected := ReadString(AFolder + Format('step%.3d.txt', [LStep]));
          if CollapseTrace(LTrace) <> CollapseTrace(LExpected) then
          begin
            LFailures := LFailures + Format('%s step %d (%s): trace, %s', [LName, LStep, LOrder,
              FirstDifference(CollapseTrace(LExpected), CollapseTrace(LTrace))]) + sLineBreak;
            if GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS') <> '' then
            begin
              TFile.WriteAllText(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS')) +
                Format('%s.step%.3d.exp.txt', [LName, LStep]), CollapseTrace(LExpected));
              TFile.WriteAllText(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS')) +
                Format('%s.step%.3d.act.txt', [LName, LStep]), CollapseTrace(LTrace));
            end;
          end;
          if LDumpMap then
          begin
            // the map is drawn after the state of the battle was written, as the harness does
            LDumpMap := False;
            LMapFile := AFolder + Format('step%.3d.map', [LStep]);
            EnsureMap.CacheUnits;
            LMap.Invalidate;
            LMapDrawn := LMap.Draw;
            if not FCompareMaps then
              // the drawing has its own test: here it only has to happen, as in the game
              LMapDiff := ''
            else if LMapDrawn <> (FileExists(LMapFile) or FileExists(LMapFile + '.gz')) then
              LFailures := LFailures + Format('%s step %d: the map is drawn or not drawn differently', [LName, LStep]) +
                sLineBreak
            else if LMapDrawn then
            begin
              LMapBytes := ReadBytes(LMapFile);
              LMapDiff := CompareMap(LMapBytes, LMap.Surface);
              if LMapDiff <> '' then
              begin
                LFailures := LFailures + Format('%s step %d: map %s', [LName, LStep, LMapDiff]) + sLineBreak;
                if GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS') <> '' then
                begin
                  LMapUnits := '';
                  for LUnit in LBattle.Units do
                  begin
                    LMapUnits := LMapUnits + Format('%d f=%d pos=%d/%d/%d dir=%d st=%d routine=%d recolor=',
                      [LUnit.Id, LUnit.Faction, LUnit.Position.X, LUnit.Position.Y, LUnit.Position.Z, LUnit.Direction,
                      LUnit.Status, LUnit.Armor.DrawingRoutine]);
                    for LPair in LUnit.RecolorPairs do
                      LMapUnits := LMapUnits + Format('%d>%d,', [LPair.Key, LPair.Value]);
                    LMapUnits := LMapUnits + sLineBreak;
                  end;
                  TFile.WriteAllText(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS')) +
                    Format('%s.step%.3d.units', [LName, LStep]), LMapUnits);
                  LTraceList := TStringList.Create;
                  try
                    LMap.Trace := LTraceList;
                    LMap.Invalidate;
                    LMap.Draw;
                    LMap.Trace := nil;
                    LTraceList.SaveToFile(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS')) +
                      Format('%s.step%.3d.trace', [LName, LStep]));
                  finally
                    LTraceList.Free;
                  end;
                end;
                if GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS') <> '' then
                  TFile.WriteAllBytes(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS')) +
                    Format('%s.step%.3d.map', [LName, LStep]), LMap.Surface.Pixels);
              end;
              Inc(FMapsCompared);
            end;
          end;
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
        LMap.Free;
        LBattlescape.Free;
        LThinker.Free;
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
    // DELPHIDOOM_XCOMBATTLE_BG_ONLY=<name>: only the scenario with this folder name
    if (GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_BG_ONLY') <> '') and
      (ExtractFileName(LScenario) <> GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_BG_ONLY')) then
      Continue;
    LFailed := LFailed + RunScenario(IncludeTrailingPathDelimiter(LScenario));
    Inc(LCount);
  end;
  TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('Scenari confrontati: %d, mappe confrontate: %d',
    [LCount, FMapsCompared]));
  Assert.IsTrue(LCount > 0, 'Nessuno scenario');
  Assert.AreEqual('', LFailed, 'Battaglie diverse dal vero BattlescapeGame');
end;

procedure TTestXcomRealBattlescape.DovrebbeDisegnareLaMappaComeIlVeroMapDraw;
const
  // known differences of the drawing (scenario:step=most pixels): the list only shrinks, see CLAUDE.md of the library
  KNOWN_DIFFERENCES: array[0..0] of string = ('none:0=0');
var
  LFolder: string;
  LScenario: string;
  LCount: Integer;
  LFailed: string;
  LLine: string;
  LMatch: TMatch;
  LKnown: TDictionary<string, Integer>;
  LEntry: string;
  LKey: string;
  LLimit: Integer;
  LUnexpected: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) or (Length(FVoxels) = 0) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LKnown := TDictionary<string, Integer>.Create;
  try
    for LEntry in KNOWN_DIFFERENCES do
      LKnown.Add(Copy(LEntry, 1, Pos('=', LEntry) - 1), StrToInt(Copy(LEntry, Pos('=', LEntry) + 1, MaxInt)));
    FCompareMaps := True;
    LCount := 0;
    LFailed := '';
    for LScenario in TDirectory.GetDirectories(LFolder) do
    begin
      if (GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_BG_ONLY') <> '') and
        (ExtractFileName(LScenario) <> GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_BG_ONLY')) then
        Continue;
      if not HasMaps(IncludeTrailingPathDelimiter(LScenario)) then
        Continue;
      LFailed := LFailed + RunScenario(IncludeTrailingPathDelimiter(LScenario));
      Inc(LCount);
    end;
    FCompareMaps := False;
    LUnexpected := '';
    for LLine in LFailed.Split([sLineBreak]) do
    begin
      if LLine = '' then
        Continue;
      LMatch := TRegEx.Match(LLine, '^(\S+) step (\d+): map (\d+) pixels differ');
      if LMatch.Success then
      begin
        LKey := LMatch.Groups[1].Value + ':' + LMatch.Groups[2].Value;
        if LKnown.TryGetValue(LKey, LLimit) and (StrToInt(LMatch.Groups[3].Value) <= LLimit) then
          Continue;
      end;
      LUnexpected := LUnexpected + LLine + sLineBreak;
    end;
    TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('Scenari con mappe: %d, mappe confrontate: %d',
      [LCount, FMapsCompared]));
    Assert.IsTrue(LCount > 0, 'Nessuno scenario con mappe');
    Assert.AreEqual('', LUnexpected, 'Mappe diverse dal vero Map::draw');
  finally
    LKnown.Free;
  end;
end;

end.
