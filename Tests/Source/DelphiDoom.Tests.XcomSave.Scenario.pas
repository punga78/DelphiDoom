{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - the scenarios of parity   }
{                                                                              }
{  save.corpus.txt has cases (a header line with the kind of object and its      }
{  arguments, then a YAML node; cases separated by "%%%%"); save.golden.txt is   }
{  what the real OpenXcom GameTime, Country, Region, ResearchProject and         }
{  SerializationHelper, linked with the real yaml-cpp, printed for them: the     }
{  state after load, the YAML that save() gives (written by the yaml-cpp         }
{  Emitter) and what the objects do afterwards. The source of the harness is in  }
{  Tools\Verifica\176\save                                                       }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Scenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleCountry, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomSave.GameTime, DelphiDoom.XcomSave.Country,
  DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.ResearchProject, DelphiDoom.XcomSave.Serialization;

type
  /// <summary>Runs the cases of the corpus with the Pascal classes and writes the lines of the golden file</summary>
  TXcomSaveScenario = class
  strict private
    FOutput: TStringList;
    function Escape(const AText: string): string;
    function Bits(AValue: Double): string;
    function Vector(const AValues: TArray<Integer>): string;
    procedure Emit(const ANode: IYamlNode);
    procedure RunCase(const AHeader: string; const ABody: TYamlText);
    procedure RunGameTime(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunCountry(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunRegion(const ANode: IYamlNode);
    procedure RunProject(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunBinary(const AParts: TArray<string>);
  public
    constructor Create;
    destructor Destroy; override;
    function Run(const ACorpus: TBytes): TStringList;
  end;

implementation

{ TXcomSaveScenario }

constructor TXcomSaveScenario.Create;
begin
  inherited Create;
  FOutput := TStringList.Create;
end;

destructor TXcomSaveScenario.Destroy;
begin
  FOutput.Free;
  inherited Destroy;
end;

function TXcomSaveScenario.Escape(const AText: string): string;
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

function TXcomSaveScenario.Bits(AValue: Double): string;
begin
  Result := IntToHex(PInt64(@AValue)^, 16);
end;

function TXcomSaveScenario.Vector(const AValues: TArray<Integer>): string;
var
  LValue: Integer;
begin
  Result := '[';
  for LValue in AValues do
    Result := Result + IntToStr(LValue) + ',';
  Result := Result + ']';
end;

procedure TXcomSaveScenario.Emit(const ANode: IYamlNode);
var
  LEmitter: IYamlEmitter;
  LText: string;
  LLines: TArray<string>;
  LLine: string;
begin
  LEmitter := TYamlFactory.CreateEmitter;
  LEmitter.WriteNode(ANode);
  if LEmitter.Good then
    FOutput.Add('EMIT good')
  else
    FOutput.Add('EMIT bad:' + Escape(YamlTextToString(LEmitter.LastError)));
  LText := YamlTextToString(LEmitter.Text);
  if LText <> '' then
  begin
    LLines := LText.Split([#10]);
    // getline does not give the empty piece after the last line end
    if LLines[High(LLines)] = '' then
      SetLength(LLines, Length(LLines) - 1);
    for LLine in LLines do
      FOutput.Add('| ' + Escape(LLine));
  end;
  FOutput.Add('|.');
end;

procedure TXcomSaveScenario.RunGameTime(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LTime: TXcomGameTime;
  LTrigger: string;
  LIndex: Integer;
begin
  LTime := TXcomGameTime.Create(StrToInt(AParts[1]), StrToInt(AParts[2]), StrToInt(AParts[3]), StrToInt(AParts[4]),
    StrToInt(AParts[5]), StrToInt(AParts[6]), StrToInt(AParts[7]));
  try
    LTime.Load(ANode);
    FOutput.Add(Format('t %d %d %d %d %d %d %d', [LTime.Weekday, LTime.Day, LTime.Month, LTime.Year, LTime.Hour,
      LTime.Minute, LTime.Second]));
    Emit(LTime.Save);
    if (LTime.Month >= 1) and (LTime.Month <= 12) then
    begin
      FOutput.Add('daylight=' + Bits(LTime.Daylight));
      if (LTime.Weekday >= 1) and (LTime.Weekday <= 7) then
        FOutput.Add('wd=' + LTime.WeekdayString);
      FOutput.Add('mo=' + LTime.MonthString);
      LTrigger := '';
      for LIndex := 0 to 39 do
      begin
        if (LTime.Month < 1) or (LTime.Month > 12) then
          Break;
        LTrigger := LTrigger + IntToStr(Ord(LTime.Advance));
      end;
      FOutput.Add(Format('adv=%s -> %d %d %d %d %d %d %d', [LTrigger, LTime.Weekday, LTime.Day, LTime.Month,
        LTime.Year, LTime.Hour, LTime.Minute, LTime.Second]));
    end;
  finally
    LTime.Free;
  end;
end;

procedure TXcomSaveScenario.RunCountry(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LRules: TXcomRuleCountry;
  LCountry: TXcomCountry;
  LRandom: IXcomRandom;
  LGenerate: Boolean;
  LMonth: Integer;
begin
  LGenerate := AParts[1] = 'gen';
  LRules := TXcomRuleCountry.Create('STR_COUNTRY');
  try
    LRules.Load(TYamlFactory.CreateParser.Load(YamlStringToText('fundingBase: 7' + #10 + 'fundingCap: 100' + #10)));
    LRandom := TXcomRandom.Create(4242);
    LCountry := TXcomCountry.Create(LRules, LGenerate, LRandom);
    try
      FOutput.Add('init ' + Vector(LCountry.Funding));
      LCountry.Load(ANode);
      FOutput.Add(Format('c %s %s %s %d %d', [Vector(LCountry.Funding), Vector(LCountry.ActivityXcom),
        Vector(LCountry.ActivityAlien), Ord(LCountry.Pact), Ord(LCountry.NewPact)]));
      Emit(LCountry.Save);
      if (Length(LCountry.Funding) > 0) and (Length(LCountry.ActivityXcom) > 0) and
        (Length(LCountry.ActivityAlien) > 0) then
      begin
        LRandom.SetSeed(99);
        for LMonth := 0 to 3 do
        begin
          LCountry.NewMonth(((LMonth + 1) * 137 mod 600) * 3, (LMonth + 1) * 311 mod 900, LMonth * 7, LRandom);
          FOutput.Add(Format('month %d sat=%d %s %s %s %d %d', [LMonth, LCountry.Satisfaction,
            Vector(LCountry.Funding), Vector(LCountry.ActivityXcom), Vector(LCountry.ActivityAlien),
            Ord(LCountry.Pact), Ord(LCountry.NewPact)]));
        end;
        Emit(LCountry.Save);
      end;
    finally
      LCountry.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TXcomSaveScenario.RunRegion(const ANode: IYamlNode);
var
  LRules: TXcomRuleRegion;
  LRegion: TXcomRegion;
  LMonth: Integer;
begin
  LRules := TXcomRuleRegion.Create('STR_REGION');
  try
    LRegion := TXcomRegion.Create(LRules);
    try
      LRegion.Load(ANode);
      FOutput.Add(Format('r %s %s', [Vector(LRegion.ActivityXcom), Vector(LRegion.ActivityAlien)]));
      Emit(LRegion.Save);
      if (Length(LRegion.ActivityXcom) > 0) and (Length(LRegion.ActivityAlien) > 0) then
      begin
        LRegion.AddActivityXcom(5);
        LRegion.AddActivityAlien(-3);
        for LMonth := 0 to 13 do
          LRegion.NewMonth;
        FOutput.Add(Format('r2 %s %s', [Vector(LRegion.ActivityXcom), Vector(LRegion.ActivityAlien)]));
      end;
    finally
      LRegion.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TXcomSaveScenario.RunProject(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LRules: TXcomRuleResearch;
  LProject: TXcomResearchProject;
  LCost: Integer;
  LFinished: Boolean;
begin
  LCost := StrToInt(AParts[1]);
  LRules := TXcomRuleResearch.Create('STR_TOPIC');
  try
    LRules.Load(TYamlFactory.CreateParser.Load(YamlStringToText('cost: ' + IntToStr(LCost) + #10)), 1);
    LProject := TXcomResearchProject.Create(LRules, LCost);
    try
      LProject.Assigned := StrToInt(AParts[2]);
      LProject.Load(ANode);
      FOutput.Add(Format('p %d %d %d', [LProject.Assigned, LProject.Spent, LProject.Cost]));
      Emit(LProject.Save);
      FOutput.Add('progress=' + LProject.ResearchProgress);
      LFinished := LProject.Step;
      FOutput.Add(Format('step=%d spent=%d finished=%d', [Ord(LFinished), LProject.Spent,
        Ord(LProject.IsFinished)]));
    finally
      LProject.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TXcomSaveScenario.RunBinary(const AParts: TArray<string>);
var
  LValue, LSize, LIndex: Integer;
  LBuffer: TBytes;
  LHex, LText: string;
  LDoubles: array[0..8] of Double;
  LThird, LSeventh: Double;
begin
  LValue := StrToInt(AParts[1]);
  LSize := StrToInt(AParts[2]);
  if ((LSize = 1) and (LValue >= 256)) or ((LSize = 2) and (LValue >= 65536)) then
  begin
    FOutput.Add('skip');
    Exit;
  end;
  SetLength(LBuffer, 8);
  FillChar(LBuffer[0], 8, 0);
  TXcomSerialization.SerializeInt(LBuffer, 0, Byte(LSize), LValue);
  LHex := '';
  for LIndex := 0 to 3 do
    LHex := LHex + IntToHex(LBuffer[LIndex], 2);
  FOutput.Add(Format('bytes=%s back=%d', [LHex, TXcomSerialization.UnserializeInt(LBuffer, 0, Byte(LSize))]));
  LThird := 1.0;
  LThird := LThird / 3.0;
  LSeventh := LValue;
  LSeventh := LSeventh / 7.0;
  LDoubles[0] := 0.0;
  LDoubles[1] := 1.0;
  LDoubles[2] := -1.5;
  LDoubles[3] := 3.14159265358979;
  LDoubles[4] := 1E-7;
  LDoubles[5] := 123456789.123456789;
  LDoubles[6] := 1E21;
  LDoubles[7] := LThird;
  LDoubles[8] := LSeventh;
  LText := '';
  for LIndex := 0 to High(LDoubles) do
    LText := LText + TXcomSerialization.SerializeDouble(LDoubles[LIndex]) + ';';
  FOutput.Add('doubles=' + LText);
end;

procedure TXcomSaveScenario.RunCase(const AHeader: string; const ABody: TYamlText);
var
  LParts: TArray<string>;
  LNode: IYamlNode;
begin
  LParts := AHeader.Split([' ']);
  try
    LNode := TYamlFactory.CreateParser.Load(ABody);
  except
    on EYamlException do
    begin
      FOutput.Add('PARSE_ERR');
      Exit;
    end;
  end;
  try
    if LParts[0] = 'gametime' then
      RunGameTime(LParts, LNode)
    else if LParts[0] = 'country' then
      RunCountry(LParts, LNode)
    else if LParts[0] = 'region' then
      RunRegion(LNode)
    else if LParts[0] = 'project' then
      RunProject(LParts, LNode)
    else if LParts[0] = 'binary' then
      RunBinary(LParts);
  except
    on E: EYamlException do
      FOutput.Add('YAML_ERR ' + Escape(YamlTextToString(E.Msg)));
  end;
end;

function TXcomSaveScenario.Run(const ACorpus: TBytes): TStringList;
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
  LText := TEncoding.UTF8.GetString(ACorpus);
  LLines := LText.Split([#10]);
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
