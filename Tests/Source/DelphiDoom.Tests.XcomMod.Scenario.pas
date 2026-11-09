{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - the scenarios of parity      }
{                                                                              }
{  rules.corpus.txt is a list of cases (a header line with the kind of rule and  }
{  its arguments, then a YAML node, cases separated by "%%%%"); rules.golden.txt }
{  is what the real OpenXcom rule classes (RuleInventory, RuleCountry,          }
{  RuleRegion, RuleResearch, RuleManufacture, AlienRace, UfoTrajectory, RNG,    }
{  WeightedOptions), linked with the real yaml-cpp, printed for them            }
{  (harness outside the repository, Tools\Verifica\176\mod has its source)      }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.Scenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleInventory,
  DelphiDoom.XcomMod.RuleCountry, DelphiDoom.XcomMod.RuleRegion, DelphiDoom.XcomMod.RuleResearch,
  DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomMod.AlienRace, DelphiDoom.XcomMod.UfoTrajectory;

type
  /// <summary>Runs the cases of the corpus with the Pascal classes and writes the lines of the golden file</summary>
  TXcomRuleScenario = class
  strict private
    FOutput: TStringList;
    procedure Line(const AText: string);
    function Escape(const AText: string): string;
    function Bits(AValue: Double): string;
    function StrVec(const AValues: TArray<string>): string;
    function StrMap(const AMap: TXcomStringMap<Integer>): string;
    procedure RunCase(const AHeader: string; const ABody: TYamlText);
    procedure RunInventory(const AId: string; const ANode: IYamlNode);
    procedure RunCountry(const AType: string; const ANode: IYamlNode);
    procedure RunRegion(const AType: string; const ANode: IYamlNode);
    procedure RunResearch(const AName, AOrder: string; const ANode: IYamlNode);
    procedure RunManufacture(const AName, AOrder: string; const ANode: IYamlNode);
    procedure RunRace(const AId: string; const ANode: IYamlNode);
    procedure RunTrajectory(const AId: string; const ANode: IYamlNode);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The corpus is the bytes of the file (LF line ends)</summary>
    function Run(const ACorpus: TBytes): TStringList;
  end;

implementation

{ TXcomRuleScenario }

constructor TXcomRuleScenario.Create;
begin
  inherited Create;
  FOutput := TStringList.Create;
end;

destructor TXcomRuleScenario.Destroy;
begin
  FOutput.Free;
  inherited Destroy;
end;

procedure TXcomRuleScenario.Line(const AText: string);
begin
  FOutput.Add(AText);
end;

function TXcomRuleScenario.Escape(const AText: string): string;
var
  LBytes: TBytes;
  LByte: Byte;
begin
  Result := '';
  LBytes := TEncoding.UTF8.GetBytes(AText);
  for LByte in LBytes do
    if LByte = Ord('\') then
      Result := Result + '\\'
    else if LByte = 10 then
      Result := Result + '\n'
    else if (LByte < 32) or (LByte >= 127) then
      Result := Result + '\x' + IntToHex(LByte, 2)
    else
      Result := Result + Char(LByte);
end;

function TXcomRuleScenario.Bits(AValue: Double): string;
begin
  Result := IntToHex(PInt64(@AValue)^, 16);
end;

function TXcomRuleScenario.StrVec(const AValues: TArray<string>): string;
var
  LValue: string;
begin
  Result := '[';
  for LValue in AValues do
    Result := Result + Escape(LValue) + '|';
  Result := Result + ']';
end;

function TXcomRuleScenario.StrMap(const AMap: TXcomStringMap<Integer>): string;
var
  LIndex: Integer;
begin
  Result := '{';
  for LIndex := 0 to AMap.Count - 1 do
    Result := Result + Escape(AMap.Key(LIndex)) + '=' + IntToStr(AMap.Value(LIndex)) + '|';
  Result := Result + '}';
end;

procedure TXcomRuleScenario.RunInventory(const AId: string; const ANode: IYamlNode);
var
  LRule, LOther: TXcomRuleInventory;
  LText: string;
  LSlot: TXcomRuleSlot;
  LX, LY: Integer;
begin
  LRule := TXcomRuleInventory.Create(AId);
  LOther := TXcomRuleInventory.Create('STR_ALPHA');
  try
    LRule.Load(ANode, 5);
    Line(Format('id=%s x=%d y=%d type=%d order=%d', [Escape(LRule.Id), LRule.X, LRule.Y, LRule.InventoryType,
      LRule.ListOrder]));
    LText := 'slots=';
    for LSlot in LRule.Slots do
      LText := LText + IntToStr(LSlot.X) + ',' + IntToStr(LSlot.Y) + ';';
    Line(LText);
    LText := 'inside=';
    LY := -4;
    while LY < 210 do
    begin
      LX := -4;
      while LX < 330 do
      begin
        if LRule.IsSlotInPosition(LX, LY) then
          LText := LText + '1'
        else
          LText := LText + '0';
        Inc(LX, 17);
      end;
      Inc(LY, 13);
    end;
    Line(LText);
    LOther.Load(TYamlFactory.CreateParser.Load(YamlStringToText('costs: {STR_ALPHA: 3, ' + AId + ': 4}')), 1);
    if LRule.HasCostFor(LOther.Id) then
      Line('cost=' + IntToStr(LRule.GetCost(LOther)))
    else
      Line('cost=undefined');
  finally
    LOther.Free;
    LRule.Free;
  end;
end;

procedure TXcomRuleScenario.RunCountry(const AType: string; const ANode: IYamlNode);
var
  LRule: TXcomRuleCountry;
  LRandom: IXcomRandom;
  LText: string;
  LIndex, LFirst, LSecond: Integer;
  LLongitude, LLatitude: Double;
begin
  LRule := TXcomRuleCountry.Create(AType);
  try
    LRule.Load(ANode);
    Line(Format('type=%s cap=%d lon=%s lat=%s', [Escape(LRule.CountryType), LRule.FundingCap,
      Bits(LRule.LabelLongitude), Bits(LRule.LabelLatitude)]));
    LRandom := TXcomRandom.Create(12345);
    if LRule.FundingBase * 2 - LRule.FundingBase + 1 = 0 then
      Line('funding=undefined')
    else
    begin
      LFirst := LRule.GenerateFunding(LRandom);
      LSecond := LRule.GenerateFunding(LRandom);
      Line(Format('funding=%d %d', [LFirst, LSecond]));
    end;
    LText := 'inside=';
    for LIndex := 0 to 59 do
    begin
      LLongitude := LIndex * 0.37;
      LLongitude := LLongitude - 0.5;
      LLatitude := LIndex * 0.53;
      LLatitude := LLatitude - 1.7;
      if LIndex mod 7 = 0 then
        LLatitude := 0;
      if LRule.IsInside(LLongitude, LLatitude) then
        LText := LText + '1'
      else
        LText := LText + '0';
    end;
    Line(LText);
  finally
    LRule.Free;
  end;
end;

procedure TXcomRuleScenario.RunRegion(const AType: string; const ANode: IYamlNode);
var
  LRule: TXcomRuleRegion;
  LRandom: IXcomRandom;
  LText, LName: string;
  LIndex, LZone, LArea: Integer;
  LLongitude, LLatitude: Double;
  LAreaRecord: TXcomMissionArea;
begin
  LRule := TXcomRuleRegion.Create(AType);
  try
    LRule.Load(ANode);
    Line(Format('type=%s cost=%d weight=%u mr=%s', [Escape(LRule.RegionType), LRule.BaseCost, LRule.Weight,
      Escape(LRule.MissionRegion)]));
    LText := 'inside=';
    for LIndex := 0 to 59 do
    begin
      LLongitude := LIndex * 0.37;
      LLongitude := LLongitude - 0.5;
      LLatitude := LIndex * 0.53;
      LLatitude := LLatitude - 1.7;
      if LRule.IsInside(LLongitude, LLatitude) then
        LText := LText + '1'
      else
        LText := LText + '0';
    end;
    Line(LText);
    Line('zones=' + IntToStr(Length(LRule.MissionZones)));
    LText := 'weights=';
    for LName in LRule.MissionWeights.Names do
      LText := LText + Escape(LName) + ';';
    Line(LText);
    LRandom := TXcomRandom.Create(99);
    LText := 'choose=';
    for LIndex := 0 to 3 do
      LText := LText + Escape(LRule.MissionWeights.Choose(LRandom)) + ';';
    Line(LText);
    for LZone := 0 to High(LRule.MissionZones) do
      for LArea := 0 to High(LRule.MissionZones[LZone].Areas) do
      begin
        LAreaRecord := LRule.MissionZones[LZone].Areas[LArea];
        Line(Format(' area %d %s %s %s %s name=%s', [LZone, Bits(LAreaRecord.LonMin), Bits(LAreaRecord.LonMax),
          Bits(LAreaRecord.LatMin), Bits(LAreaRecord.LatMax), Escape(LAreaRecord.Name)]));
      end;
    LRandom := TXcomRandom.Create(777);
    for LZone := 0 to High(LRule.MissionZones) do
    begin
      if Length(LRule.MissionZones[LZone].Areas) = 0 then
        Continue;
      LRule.GetRandomPoint(LZone, LRandom, LLongitude, LLatitude);
      Line(Format(' point %d %s %s', [LZone, Bits(LLongitude), Bits(LLatitude)]));
    end;
  finally
    LRule.Free;
  end;
end;

procedure TXcomRuleScenario.RunResearch(const AName, AOrder: string; const ANode: IYamlNode);
var
  LRule: TXcomRuleResearch;
begin
  LRule := TXcomRuleResearch.Create(AName);
  try
    LRule.Load(ANode, StrToIntDef(AOrder, 0));
    Line(Format('name=%s cost=%d points=%d order=%d need=%d destroy=%d lookup=%s cut=%s', [Escape(LRule.Name),
      LRule.Cost, LRule.Points, LRule.ListOrder, Ord(LRule.NeedItem), Ord(LRule.DestroyItem),
      Escape(LRule.Lookup), Escape(LRule.Cutscene)]));
    Line(Format('dep=%s unl=%s free=%s req=%s', [StrVec(LRule.Dependencies), StrVec(LRule.Unlocks),
      StrVec(LRule.GetOneFree), StrVec(LRule.Requirements)]));
  finally
    LRule.Free;
  end;
end;

procedure TXcomRuleScenario.RunManufacture(const AName, AOrder: string; const ANode: IYamlNode);
var
  LRule: TXcomRuleManufacture;
begin
  LRule := TXcomRuleManufacture.Create(AName);
  try
    LRule.Load(ANode, StrToIntDef(AOrder, 0));
    Line(Format('name=%s cat=%s space=%d time=%d cost=%d order=%d', [Escape(LRule.Name), Escape(LRule.Category),
      LRule.RequiredSpace, LRule.ManufactureTime, LRule.ManufactureCost, LRule.ListOrder]));
    Line(Format('req=%s items=%s produced=%s', [StrVec(LRule.Requirements), StrMap(LRule.RequiredItems),
      StrMap(LRule.ProducedItems)]));
  finally
    LRule.Free;
  end;
end;

procedure TXcomRuleScenario.RunRace(const AId: string; const ANode: IYamlNode);
var
  LRule: TXcomAlienRace;
begin
  LRule := TXcomAlienRace.Create(AId);
  try
    LRule.Load(ANode);
    Line(Format('id=%s members=%s', [Escape(LRule.Id), StrVec(LRule.Members)]));
  finally
    LRule.Free;
  end;
end;

procedure TXcomRuleScenario.RunTrajectory(const AId: string; const ANode: IYamlNode);
var
  LRule: TXcomUfoTrajectory;
  LIndex: Integer;
begin
  LRule := TXcomUfoTrajectory.Create(AId);
  try
    LRule.Load(ANode);
    Line(Format('id=%s timer=%u count=%u', [Escape(LRule.Id), LRule.GroundTimer, LRule.WaypointCount]));
    for LIndex := 0 to LRule.WaypointCount - 1 do
      Line(Format(' wp %u %u %u', [LRule.Waypoints[LIndex].Zone, LRule.Waypoints[LIndex].Altitude,
        LRule.Waypoints[LIndex].Speed]));
  finally
    LRule.Free;
  end;
end;

procedure TXcomRuleScenario.RunCase(const AHeader: string; const ABody: TYamlText);
var
  LParts: TArray<string>;
  LKind, LFirst, LSecond: string;
  LNode: IYamlNode;
begin
  LParts := AHeader.Split([' ']);
  LKind := LParts[0];
  LFirst := '';
  LSecond := '';
  if Length(LParts) > 1 then
    LFirst := LParts[1];
  if Length(LParts) > 2 then
    LSecond := LParts[2];
  try
    LNode := TYamlFactory.CreateParser.Load(ABody);
  except
    on EYamlException do
    begin
      Line('PARSE_ERR');
      Exit;
    end;
  end;
  try
    if LKind = 'inventory' then
      RunInventory(LFirst, LNode)
    else if LKind = 'country' then
      RunCountry(LFirst, LNode)
    else if LKind = 'region' then
      RunRegion(LFirst, LNode)
    else if LKind = 'research' then
      RunResearch(LFirst, LSecond, LNode)
    else if LKind = 'manufacture' then
      RunManufacture(LFirst, LSecond, LNode)
    else if LKind = 'race' then
      RunRace(LFirst, LNode)
    else if LKind = 'trajectory' then
      RunTrajectory(LFirst, LNode);
  except
    on E: EYamlException do
      Line('YAML_ERR ' + Escape(YamlTextToString(E.Msg)));
    on E: EXcomModException do
      Line('MOD_ERR ' + Escape(E.Message));
  end;
end;

function TXcomRuleScenario.Run(const ACorpus: TBytes): TStringList;
var
  LText, LLine, LHeader: string;
  LLines: TArray<string>;
  LBody: TYamlText;
  LCase: Integer;
  LInCase, LHaveHeader: Boolean;
  procedure Flush;
  begin
    if LInCase and LHaveHeader then
    begin
      FOutput.Add('#' + IntToStr(LCase) + ' ' + LHeader);
      RunCase(LHeader, LBody);
    end;
  end;
begin
  // the corpus is UTF-8 text with LF line ends
  LText := TEncoding.UTF8.GetString(ACorpus);
  LLines := LText.Split([#10]);
  // getline does not give the empty piece after the last line end
  if (Length(LLines) > 0) and (LLines[High(LLines)] = '') then
    SetLength(LLines, Length(LLines) - 1);
  LCase := -1;
  LInCase := False;
  LHaveHeader := False;
  for LLine in LLines do
  begin
    if LLine = '%%%%' then
    begin
      Flush;
      Inc(LCase);
      LInCase := True;
      LHaveHeader := False;
      LBody := '';
      Continue;
    end;
    if not LInCase then
      Continue;
    if not LHaveHeader then
    begin
      LHeader := LLine;
      LHaveHeader := True;
      Continue;
    end;
    LBody := LBody + YamlStringToText(LLine) + #10;
  end;
  Flush;
  Result := FOutput;
end;

end.
