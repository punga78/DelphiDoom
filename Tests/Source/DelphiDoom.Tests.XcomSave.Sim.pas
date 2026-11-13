{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom saved game library - the support of the  }
{  scenarios that run on the real saved games (load, change, save, compare     }
{  with what the real OpenXcom objects did: Tools\Verifica\176\save\simgen)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Sim;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.AnsiStrings, System.StrUtils, System.Generics.Collections, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomSave.ItemContainer,
  DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomMod.UfoTrajectory,
  DelphiDoom.Tests.XcomSave.RealSave, DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>
  ///   What a scenario test needs: the ruleset of the TFTD data, the saved games of realsave loaded as
  ///   SavedGame::load does, and the comparison of the text that the library writes with the one of the real code
  /// </summary>
  TXcomSim = class
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FSettings: IXcomSaveSettings;
    FInfo: TXcomSaveBriefInfo;
    class function ReadText(const APath: string): TYamlText; static;
    class function FindFolder(const ARelative: string): string; static;
    class function SameValue(const ALeft, ARight: string): Boolean; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>False without the data of TFTD (Reference\_dati): the scenarios then pass without comparing</summary>
    function Available: Boolean;
    property Ruleset: TXcomRuleset read FRuleset;
    property Rules: TXcomRulesetRules read FRules;
    property Settings: IXcomSaveSettings read FSettings;
    /// <summary>Whether every zone that a mission and its trajectories use exists, with areas, in the region (simgen RegionOk)</summary>
    function RegionOk(const ARule: TXcomRuleAlienMission; const ARegion: TXcomRuleRegion): Boolean;
    /// <summary>The golden folder of a library (Tests\Data\XcomSave\sim, ...)</summary>
    class function GoldenFolder(const ARelative: string): string; static;
    /// <summary>The saved games the C++ started from</summary>
    class function RealSaveFolder: string; static;
    /// <summary>Loads saveNN.sav of realsave; the caller frees the game</summary>
    function LoadSave(AIndex: Integer; const ARandom: IXcomRandom): TXcomSavedGame;
    /// <summary>SavedGame::save of the game, as text with LF</summary>
    function SaveText(const AGame: TXcomSavedGame; const ARandom: IXcomRandom): TYamlText;
    /// <summary>The text of a golden file with LF only (the C++ wrote CRLF)</summary>
    class function GoldenText(const APath: string): TYamlText; static;
    /// <summary>Equal texts, except the last bit of the speeds of the targets (x87)</summary>
    class function SameSave(const AExpected, AActual: TYamlText): Boolean; static;
    /// <summary>'' when SameSave, else the first line that differs (the message of a failure)</summary>
    class function SaveDifference(const AExpected, AActual: TYamlText): string; static;
    /// <summary>
    ///   SaveDifference of a golden file; when they differ the actual text is written next to the executable
    ///   (actual.sav) to look at it
    /// </summary>
    class function CompareSave(const AGoldenPath: string; const AActual: TYamlText): string; static;
    /// <summary>The first line that differs, for the message of a failure</summary>
    class function FirstDifference(const AExpected, AActual: string): string; static;
    /// <summary>
    ///   FirstDifference where the numbers of a field "key=number" of a line may differ by ATolerance (absolute,
    ///   in radians): the positions after hundreds of thousands of moves of the x87 of the C++ build
    /// </summary>
    class function FirstDifferenceTolerant(const AExpected, AActual: string; ATolerance: Double): string; static;
    /// <summary>
    ///   Like CompareSave, but the values of lon, lat and the speeds may differ by ATolerance (absolute)
    /// </summary>
    class function CompareSaveTolerant(const AGoldenPath: string; const AActual: TYamlText;
      ATolerance: Double): string; static;
    /// <summary>The storage of a base as the harness prints it: item=quantity; in the order of the names</summary>
    class function StorageText(const AItems: TXcomItemContainer): string; static;
  end;

implementation

function LineOrEnd(const ALines: TStringList; AIndex: Integer): string;
begin
  if AIndex < ALines.Count then
    Result := ALines[AIndex]
  else
    Result := '<end>';
end;

{ TXcomSim }

constructor TXcomSim.Create;
var
  LFile: TArray<IYamlNode>;
  LBrief, LItem: IYamlNode;
  LMods: TArray<string>;
begin
  inherited Create;
  FSettings := TXcomDefaultSettings.Create;
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder = '' then
    Exit;
  FRuleset := FData.Load;
  FRules := TXcomRulesetRules.Create(FRuleset);
  if RealSaveFolder = '' then
    Exit;
  LFile := TYamlFactory.CreateParser.LoadAll(GoldenText(RealSaveFolder + 'save00.sav'));
  LBrief := LFile[0];
  FInfo.Version := YamlTextToString(LBrief.Find(YamlStringToText('version')).AsString);
  FInfo.Engine := YamlTextToString(LBrief.Find(YamlStringToText('engine')).AsString);
  FInfo.Build := YamlTextToString(LBrief.Find(YamlStringToText('build')).AsString);
  SetLength(LMods, 0);
  for LItem in LBrief.Find(YamlStringToText('mods')).Items do
  begin
    SetLength(LMods, Length(LMods) + 1);
    LMods[High(LMods)] := YamlTextToString(LItem.AsString);
  end;
  FInfo.Mods := LMods;
end;

destructor TXcomSim.Destroy;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
  inherited Destroy;
end;

function TXcomSim.Available: Boolean;
begin
  Result := Assigned(FRuleset) and (RealSaveFolder <> '');
end;

function TXcomSim.RegionOk(const ARule: TXcomRuleAlienMission; const ARegion: TXcomRuleRegion): Boolean;
var
  LZones: TList<Cardinal>;
  LWave: TXcomMissionWave;
  LTrajectory: TXcomUfoTrajectory;
  LPoint: TXcomTrajectoryWaypoint;
  LZone: Cardinal;
begin
  Result := False;
  LZones := TList<Cardinal>.Create;
  try
    if ARule.SpawnZone >= 0 then
      LZones.Add(Cardinal(ARule.SpawnZone));
    for LWave in ARule.Waves do
    begin
      LTrajectory := FRuleset.UfoTrajectories.Find(LWave.Trajectory);
      if not Assigned(LTrajectory) then
        Exit;
      for LPoint in LTrajectory.Waypoints do
        LZones.Add(LPoint.Zone);
    end;
    LTrajectory := FRuleset.UfoTrajectories.Find(TXcomUfoTrajectory.RETALIATION_ASSAULT_RUN);
    if Assigned(LTrajectory) then
      for LPoint in LTrajectory.Waypoints do
        LZones.Add(LPoint.Zone);
    for LZone in LZones do
      if (LZone >= Cardinal(Length(ARegion.MissionZones))) or (Length(ARegion.MissionZones[LZone].Areas) = 0) then
        Exit;
    Result := True;
  finally
    LZones.Free;
  end;
end;

class function TXcomSim.FindFolder(const ARelative: string): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 7 do
  begin
    if DirectoryExists(LFolder + ARelative) then
      Exit(LFolder + ARelative + '\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TXcomSim.GoldenFolder(const ARelative: string): string;
begin
  Result := FindFolder('Tests\Data\' + ARelative);
end;

class function TXcomSim.RealSaveFolder: string;
begin
  Result := FindFolder('Tests\Data\XcomSave\realsave');
end;

class function TXcomSim.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TXcomSim.GoldenText(const APath: string): TYamlText;
begin
  Result := System.AnsiStrings.StringReplace(ReadText(APath), #13#10, #10, [rfReplaceAll]);
end;

function TXcomSim.LoadSave(AIndex: Integer; const ARandom: IXcomRandom): TXcomSavedGame;
var
  LFile: TArray<IYamlNode>;
begin
  LFile := TYamlFactory.CreateParser.LoadAll(GoldenText(RealSaveFolder + Format('save%.2d.sav', [AIndex])));
  Result := TXcomSavedGame.Create;
  try
    Result.Load(LFile, FRuleset, FRules, FSettings, False, ARandom);
  except
    Result.Free;
    raise;
  end;
end;

function TXcomSim.SaveText(const AGame: TXcomSavedGame; const ARandom: IXcomRandom): TYamlText;
begin
  Result := AGame.Save(FInfo, FSettings, ARandom);
end;

class function TXcomSim.SameValue(const ALeft, ARight: string): Boolean;
var
  LLeft, LRight: Double;
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Invariant;
  if not TryStrToFloat(Trim(Copy(ALeft, Pos(':', ALeft) + 1, MaxInt)), LLeft, LFormat) or
    not TryStrToFloat(Trim(Copy(ARight, Pos(':', ARight) + 1, MaxInt)), LRight, LFormat) then
    Exit(False);
  // the speeds come from a difference of terms that cancel when the UFO is near its destination: one ulp of
  // the x87 of the C++ build (extended intermediates) becomes a few thousand ulps of a speed of 1e-4 radians.
  // The positions (lon, lat, globeLon, globeLat) are a sum of such terms, and at 64 bit (SSE, no extended
  // intermediates) they differ from the x87 golden in the last bit or two: the same relative tolerance
  Result := Abs(LLeft - LRight) <= 1E-11 * Abs(LLeft);
end;

class function TXcomSim.SameSave(const AExpected, AActual: TYamlText): Boolean;
begin
  Result := SaveDifference(AExpected, AActual) = '';
end;

class function TXcomSim.SaveDifference(const AExpected, AActual: TYamlText): string;
const
  TOLERATED: array[0..6] of string = ('speedLon:', 'speedLat:', 'speedRadian:', 'lon:', 'lat:', 'globeLon:',
    'globeLat:');
var
  LExpected, LActual: TStringList;
  LIndex, LKey: Integer;
  LLine: string;
  LAccepted: Boolean;
begin
  Result := '';
  if AExpected = AActual then
    Exit;
  LExpected := TStringList.Create;
  LActual := TStringList.Create;
  try
    LExpected.Text := string(AExpected);
    LActual.Text := string(AActual);
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if (LIndex < LActual.Count) and (LExpected[LIndex] = LActual[LIndex]) then
        Continue;
      LAccepted := False;
      if LIndex < LActual.Count then
      begin
        LLine := Trim(LExpected[LIndex]);
        // the first key of a list item
        if LLine.StartsWith('- ') then
          LLine := Copy(LLine, 3, MaxInt);
        for LKey := 0 to High(TOLERATED) do
          if LLine.StartsWith(TOLERATED[LKey]) and SameValue(LExpected[LIndex], LActual[LIndex]) then
            LAccepted := True;
      end;
      if not LAccepted then
        Exit(Format('line %d: expected "%s" got "%s"', [LIndex + 1, LExpected[LIndex],
          LineOrEnd(LActual, LIndex)]));
    end;
    if LActual.Count > LExpected.Count then
      Result := Format('line %d: unexpected "%s"', [LExpected.Count + 1, LActual[LExpected.Count]]);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

class function TXcomSim.CompareSave(const AGoldenPath: string; const AActual: TYamlText): string;
var
  LBytes: TBytes;
begin
  Result := SaveDifference(GoldenText(AGoldenPath), AActual);
  if Result <> '' then
  begin
    SetLength(LBytes, Length(AActual));
    if Length(LBytes) > 0 then
      Move(AActual[1], LBytes[0], Length(LBytes));
    TFile.WriteAllBytes(ExtractFilePath(ParamStr(0)) + 'actual.sav', LBytes);
  end;
end;

class function TXcomSim.FirstDifferenceTolerant(const AExpected, AActual: string; ATolerance: Double): string;
var
  LExpected, LActual: TStringList;
  LIndex, LField: Integer;
  LLeft, LRight: TArray<string>;
  LSame: Boolean;
  LA, LB: Double;
  LKeyA, LKeyB: string;
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Invariant;
  LExpected := TStringList.Create;
  LActual := TStringList.Create;
  try
    LExpected.Text := AExpected;
    LActual.Text := AActual;
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if (LIndex < LActual.Count) and (LExpected[LIndex] = LActual[LIndex]) then
        Continue;
      LSame := False;
      if LIndex < LActual.Count then
      begin
        LLeft := LExpected[LIndex].Split(['|']);
        LRight := LActual[LIndex].Split(['|']);
        LSame := Length(LLeft) = Length(LRight);
        if LSame then
          for LField := 0 to High(LLeft) do
          begin
            if LLeft[LField] = LRight[LField] then
              Continue;
            LKeyA := Copy(LLeft[LField], 1, Pos('=', LLeft[LField]));
            LKeyB := Copy(LRight[LField], 1, Pos('=', LRight[LField]));
            if (LKeyA <> LKeyB) or (LKeyA = '') or
              not TryStrToFloat(Copy(LLeft[LField], Length(LKeyA) + 1, MaxInt), LA, LFormat) or
              not TryStrToFloat(Copy(LRight[LField], Length(LKeyB) + 1, MaxInt), LB, LFormat) or
              (Abs(LA - LB) > ATolerance) then
            begin
              LSame := False;
              Break;
            end;
          end;
      end;
      if not LSame then
        Exit(Format('line %d: expected "%s" got "%s"', [LIndex + 1, LExpected[LIndex],
          LineOrEnd(LActual, LIndex)]));
    end;
    if LActual.Count > LExpected.Count then
      Result := Format('line %d: unexpected "%s"', [LExpected.Count + 1, LActual[LExpected.Count]])
    else
      Result := '';
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

class function TXcomSim.CompareSaveTolerant(const AGoldenPath: string; const AActual: TYamlText;
  ATolerance: Double): string;
var
  LExpected, LActual: TStringList;
  LIndex, LKey: Integer;
  LLine, LKeyName: string;
  LA, LB: Double;
  LFormat: TFormatSettings;
  LAccepted: Boolean;
  LBytes: TBytes;
const
  TOLERATED: array[0..6] of string = ('lon:', 'lat:', 'speedLon:', 'speedLat:', 'speedRadian:', 'globeLon:',
    'globeLat:');
begin
  LFormat := TFormatSettings.Invariant;
  Result := '';
  LExpected := TStringList.Create;
  LActual := TStringList.Create;
  try
    LExpected.Text := string(GoldenText(AGoldenPath));
    LActual.Text := string(AActual);
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if (LIndex < LActual.Count) and (LExpected[LIndex] = LActual[LIndex]) then
        Continue;
      LAccepted := False;
      if LIndex < LActual.Count then
      begin
        LLine := Trim(LExpected[LIndex]);
        // the first key of a list item
        if LLine.StartsWith('- ') then
          LLine := Copy(LLine, 3, MaxInt);
        for LKey := 0 to High(TOLERATED) do
          if LLine.StartsWith(TOLERATED[LKey]) then
          begin
            LKeyName := TOLERATED[LKey];
            if TryStrToFloat(Trim(Copy(LExpected[LIndex], Pos(':', LExpected[LIndex]) + 1, MaxInt)), LA, LFormat) and
              TryStrToFloat(Trim(Copy(LActual[LIndex], Pos(':', LActual[LIndex]) + 1, MaxInt)), LB, LFormat) and
              (Abs(LA - LB) <= ATolerance) then
              LAccepted := True;
          end;
      end;
      if not LAccepted then
      begin
        Result := Format('line %d: expected "%s" got "%s"', [LIndex + 1, LExpected[LIndex],
          LineOrEnd(LActual, LIndex)]);
        Break;
      end;
    end;
    if (Result = '') and (LActual.Count > LExpected.Count) then
      Result := Format('line %d: unexpected "%s"', [LExpected.Count + 1, LActual[LExpected.Count]]);
    if Result <> '' then
    begin
      SetLength(LBytes, Length(AActual));
      if Length(LBytes) > 0 then
        Move(AActual[1], LBytes[0], Length(LBytes));
      TFile.WriteAllBytes(ExtractFilePath(ParamStr(0)) + 'actual.sav', LBytes);
    end;
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

class function TXcomSim.FirstDifference(const AExpected, AActual: string): string;
var
  LExpected, LActual: TStringList;
  LIndex: Integer;
begin
  LExpected := TStringList.Create;
  LActual := TStringList.Create;
  try
    LExpected.Text := AExpected;
    LActual.Text := AActual;
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if (LIndex >= LActual.Count) or (LExpected[LIndex] <> LActual[LIndex]) then
      begin
        Result := Format('line %d: expected "%s" got "%s"', [LIndex + 1, LExpected[LIndex],
          LineOrEnd(LActual, LIndex)]);
        Exit;
      end;
    end;
    if LActual.Count > LExpected.Count then
      Result := Format('line %d: unexpected "%s"', [LExpected.Count + 1, LActual[LExpected.Count]])
    else
      Result := '';
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

class function TXcomSim.StorageText(const AItems: TXcomItemContainer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to AItems.Contents.Count - 1 do
    Result := Result + AItems.Contents.Key(LIndex) + '=' + IntToStr(AItems.Contents.Value(LIndex)) + ';';
end;

end.
