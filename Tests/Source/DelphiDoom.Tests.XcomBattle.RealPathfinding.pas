{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the paths that the  }
{  real Pathfinding of OpenXcom finds on maps of real MCD parts                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealPathfinding;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.Generics.Defaults,
  DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.MapDataLoader, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.McdPatch,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.Pathfinding, DelphiDoom.Tests.XcomMod.RealData;

type
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealPathfinding = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    function DataFolder: string;
    class function ReadText(const APath: string): TYamlText; static;
    function RunCase(const ABase: string): string;
    function Answer(const ABattle: TXcomSavedBattleGame; const APathfinding: TXcomPathfinding;
      const AQuestion: string): string;
    class function FindUnit(const ABattle: TXcomSavedBattleGame; AId: Integer): TXcomBattleUnit; static;
  protected
    /// <summary>The game of the cases: TFTD (mod xcom2) or UFO (mod xcom1)</summary>
    function IsUfo: Boolean; virtual;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeTrovareGliStessiPercorsiDelVeroOpenXcom;
  end;

  /// <summary>The same comparison on the terrains and the units of UFO (pathgen on the UFO data)</summary>
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealPathfindingUfo = class(TTestXcomRealPathfinding)
  protected
    function IsUfo: Boolean; override;
  end;

implementation

uses
  DelphiDoom.Tests.XcomBattle.GameData;

{ TTestXcomRealPathfindingUfo }

function TTestXcomRealPathfindingUfo.IsUfo: Boolean;
begin
  Result := True;
end;

function TTestXcomRealPathfinding.IsUfo: Boolean;
begin
  Result := False;
end;

{ TTestXcomRealPathfinding }

function TTestXcomRealPathfinding.DataFolder: string;
var
  LFolder: string;
  LLevel: Integer;
  LName: string;
begin
  // a folder of cases to look at (for example the exhaustive steps of a unit) instead of the committed ones
  LFolder := GetEnvironmentVariable(TXcomTestGame.FolderVariable('DELPHIDOOM_XCOMBATTLE_PATH', IsUfo));
  if LFolder <> '' then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LName := 'Tests\Data\XcomBattle\' + TXcomTestGame.ScenarioFolder('path', IsUfo);
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    if DirectoryExists(LFolder + LName) then
      Exit(LFolder + LName + '\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TTestXcomRealPathfinding.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

procedure TTestXcomRealPathfinding.SetupFixture;
begin
  FData := TXcomRealData.Create(TXcomTestGame.Golden(IsUfo));
  if FData.DataFolder <> '' then
    FRuleset := FData.Load;
end;

procedure TTestXcomRealPathfinding.TearDownFixture;
begin
  FRuleset.Free;
  FData.Free;
end;

class function TTestXcomRealPathfinding.FindUnit(const ABattle: TXcomSavedBattleGame; AId: Integer): TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in ABattle.Units do
    if LUnit.Id = AId then
      Exit(LUnit);
  raise Exception.CreateFmt('Unit %d not in the battle', [AId]);
end;

function TTestXcomRealPathfinding.Answer(const ABattle: TXcomSavedBattleGame;
  const APathfinding: TXcomPathfinding; const AQuestion: string): string;
var
  LParts: TArray<string>;
  LUnit: TXcomBattleUnit;
  LPath: TArray<Integer>;
  LStep: Integer;
  LEnd: TXcomPosition;
  LCost: Integer;
  LReach: TArray<Integer>;
  LSet: string;
  LValue: Integer;
  LMax: Integer;
begin
  LParts := AQuestion.Split([' ']);
  LUnit := FindUnit(ABattle, StrToInt(LParts[1]));
  Result := '';
  if LParts[0] = 'setunit' then
  begin
    APathfinding.SetUnit(LUnit);
    Result := AQuestion;
  end
  else if LParts[0] = 'calc' then
  begin
    LMax := StrToInt(LParts[5]);
    APathfinding.Calculate(LUnit, TXcomPosition.Make(StrToInt(LParts[2]), StrToInt(LParts[3]), StrToInt(LParts[4])),
      nil, LMax);
    LPath := APathfinding.Path;
    for LStep in LPath do
      Result := Result + IntToStr(LStep) + ',';
    Result := Format('%s %s = %s tu=%d', [LParts[0], Copy(AQuestion, Pos(' ', AQuestion) + 1,
      Pos('=', AQuestion) - Pos(' ', AQuestion) - 2), Result, APathfinding.TotalTuCost]);
  end
  else if LParts[0] = 'missile' then
  begin
    APathfinding.Calculate(LUnit, FindUnit(ABattle, StrToInt(LParts[2])).Position,
      FindUnit(ABattle, StrToInt(LParts[2])), -1);
    LPath := APathfinding.Path;
    for LStep in LPath do
      Result := Result + IntToStr(LStep) + ',';
    Result := Format('missile %s %s = %s tu=%d', [LParts[1], LParts[2], Result, APathfinding.TotalTuCost]);
  end
  else if LParts[0] = 'step' then
  begin
    LCost := APathfinding.GetTuCost(TXcomPosition.Make(StrToInt(LParts[2]), StrToInt(LParts[3]),
      StrToInt(LParts[4])), StrToInt(LParts[5]), LEnd, LUnit, nil, False);
    Result := Format('step %s %s %s %s %s = %d %d %d %d', [LParts[1], LParts[2], LParts[3], LParts[4], LParts[5],
      LCost, LEnd.X, LEnd.Y, LEnd.Z]);
  end
  else if LParts[0] = 'reach' then
  begin
    LReach := APathfinding.FindReachable(LUnit, StrToInt(LParts[2]));
    LSet := '';
    if Length(LReach) > 0 then
      LValue := LReach[0]
    else
      LValue := -1;
    TArray.Sort<Integer>(LReach);
    for LStep in LReach do
      LSet := LSet + IntToStr(LStep) + ',';
    // "first=tie": more tiles have the cost of the first one and std::sort does not say which comes first
    if Pos(' first=tie ', AQuestion) > 0 then
      Result := Format('reach %s %s = %d first=tie set=%s', [LParts[1], LParts[2], Length(LReach), LSet])
    else
      Result := Format('reach %s %s = %d first=%d set=%s', [LParts[1], LParts[2], Length(LReach), LValue, LSet]);
  end;
end;

function TTestXcomRealPathfinding.RunCase(const ABase: string): string;
var
  LBattle: TXcomSavedBattleGame;
  LContext: TXcomBattleContext;
  LLoader: TXcomMapDataLoader;
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
  LPathfinding: TXcomPathfinding;
  LPathfindingRef: IInterface;
  LLines: TStringList;
  LLine: string;
  LActual: string;
  LFailed: string;
begin
  LFailed := '';
  LContext := TXcomBattleContext.Create(TXcomRandom.Create(1));
  LBattle := TXcomSavedBattleGame.Create(LContext);
  LLines := TStringList.Create;
  try
    LBattle.Load(TYamlFactory.CreateParser.Load(ReadText(ABase + '.yml')), FRuleset, 0,
      function(AId: Integer): TXcomSoldier
      begin
        Result := nil;
      end);
    LLoader := TXcomMapDataLoader.Create(FRuleset.Files);
    try
      for LSet in LBattle.MapDataSets do
      begin
        if not FRuleset.McdPatches.TryGetValue(LSet.Name, LPatch) then
          LPatch := nil;
        LLoader.LoadData(LSet, LPatch);
      end;
    finally
      LLoader.Free;
    end;
    LBattle.ResolveMapData;
    LPathfinding := TXcomPathfinding.Create(LBattle);
    LPathfindingRef := LPathfinding;
    LBattle.Pathfinder := LPathfinding;
    LLines.LoadFromFile(ABase + '.txt', TEncoding.UTF8);
    for LLine in LLines do
    begin
      if LLine = '' then
        Continue;
      LActual := Answer(LBattle, LPathfinding, LLine);
      if LActual <> LLine then
        LFailed := LFailed + ExtractFileName(ABase) + ': ' + LLine + ' <> ' + LActual + sLineBreak;
    end;
  finally
    LLines.Free;
    LBattle.Free;
  end;
  Result := LFailed;
end;

procedure TTestXcomRealPathfinding.DovrebbeTrovareGliStessiPercorsiDelVeroOpenXcom;
var
  LFolder: string;
  LPath: string;
  LCount: Integer;
  LFailed: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or not Assigned(FRuleset) then
  begin
    TXcomTestSkip.Ignore('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'path*.txt') do
  begin
    LFailed := LFailed + RunCase(Copy(LPath, 1, Length(LPath) - 4));
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'Nessun file di percorsi');
  Assert.AreEqual('', LFailed, 'Percorsi diversi dal vero OpenXcom');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealPathfinding);
  TDUnitX.RegisterTestFixture(TTestXcomRealPathfindingUfo);

end.
