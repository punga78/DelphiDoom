{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - the scenarios of parity   }
{  of the second family of objects                                              }
{                                                                              }
{  objects.corpus.txt has cases (a header line with the kind of object and its  }
{  arguments, then a YAML node; cases separated by "%%%%"); objects.golden.txt  }
{  is what the real OpenXcom classes (Waypoint, AlienBase, MissionSite, Node,   }
{  EquipmentLayoutItem, ...), linked from the objects of a real build with the  }
{  real yaml-cpp, printed for them. The harness is Tools\Verifica\176\save\     }
{  objharness.cpp                                                               }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.ObjectScenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.Yaml.Convert, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSave.Rules.Intf,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.AlienBase,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.EquipmentLayoutItem;

type
  /// <summary>A deployment rule with the three values the harness gives to the real AlienDeployment</summary>
  TXcomFakeDeployment = class(TInterfacedObject, IXcomDeploymentRule)
  strict private
    FType: string;
    FMarkerName: string;
    FMarkerIcon: Integer;
  public
    constructor Create(const AType, AMarkerName: string; AMarkerIcon: Integer);
    function DeploymentType: string;
    function MarkerName: string;
    function MarkerIcon: Integer;
  end;

  /// <summary>A mission rule with a type</summary>
  TXcomFakeMission = class(TInterfacedObject, IXcomMissionRule)
  strict private
    FType: string;
  public
    constructor Create(const AType: string);
    function MissionType: string;
  end;

  /// <summary>Runs the cases of the corpus with the Pascal classes and writes the lines of the golden file</summary>
  TXcomSaveObjectScenario = class
  strict private
    FOutput: TStringList;
    function Escape(const AText: string): string;
    function Bits(AValue: Double): string;
    function FromBits(const AParts: TArray<string>; AIndex: Integer): Double;
    function General10(AValue: Double): string;
    procedure Emit(const ANode: IYamlNode);
    procedure TargetOps(const ATarget: TXcomTarget; const AParts: TArray<string>; AFirst: Integer);
    procedure RunCase(const AHeader: string; const ABody: TYamlText);
    procedure RunWaypoint(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunAlienBase(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunMissionSite(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunNode(const ANode: IYamlNode);
    procedure RunEquip(const ANode: IYamlNode);
  public
    constructor Create;
    destructor Destroy; override;
    function Run(const ACorpus: TBytes): TStringList;
  end;

implementation

function BoolInt(AValue: Boolean): Integer;
begin
  Result := Ord(AValue);
end;

{ TXcomFakeDeployment }

constructor TXcomFakeDeployment.Create(const AType, AMarkerName: string; AMarkerIcon: Integer);
begin
  inherited Create;
  FType := AType;
  FMarkerName := AMarkerName;
  FMarkerIcon := AMarkerIcon;
end;

function TXcomFakeDeployment.DeploymentType: string;
begin
  Result := FType;
end;

function TXcomFakeDeployment.MarkerName: string;
begin
  Result := FMarkerName;
end;

function TXcomFakeDeployment.MarkerIcon: Integer;
begin
  Result := FMarkerIcon;
end;

{ TXcomFakeMission }

constructor TXcomFakeMission.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
end;

function TXcomFakeMission.MissionType: string;
begin
  Result := FType;
end;

{ TXcomSaveObjectScenario }

constructor TXcomSaveObjectScenario.Create;
begin
  inherited Create;
  FOutput := TStringList.Create;
end;

destructor TXcomSaveObjectScenario.Destroy;
begin
  FOutput.Free;
  inherited Destroy;
end;

function TXcomSaveObjectScenario.Escape(const AText: string): string;
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

function TXcomSaveObjectScenario.Bits(AValue: Double): string;
begin
  Result := IntToHex(PInt64(@AValue)^, 16);
end;

function TXcomSaveObjectScenario.FromBits(const AParts: TArray<string>; AIndex: Integer): Double;
var
  LBits: Int64;
begin
  // a missing argument is 0 (strtoull of an empty text)
  if AIndex > High(AParts) then
    Exit(0.0);
  LBits := StrToInt64('$' + AParts[AIndex]);
  Result := PDouble(@LBits)^;
end;

function TXcomSaveObjectScenario.General10(AValue: Double): string;
begin
  Result := YamlTextToString(TYamlConvert.FormatGeneral(AValue, 10));
end;

procedure TXcomSaveObjectScenario.Emit(const ANode: IYamlNode);
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
    if LLines[High(LLines)] = '' then
      SetLength(LLines, Length(LLines) - 1);
    for LLine in LLines do
      FOutput.Add('| ' + Escape(LLine));
  end;
  FOutput.Add('|.');
end;

procedure TXcomSaveObjectScenario.TargetOps(const ATarget: TXcomTarget; const AParts: TArray<string>;
  AFirst: Integer);
begin
  FOutput.Add(Format('ll %s %s id=%d', [Bits(ATarget.Longitude), Bits(ATarget.Latitude), ATarget.Id]));
  Emit(ATarget.Save);
  Emit(ATarget.SaveId);
  ATarget.SetLongitude(FromBits(AParts, AFirst));
  ATarget.SetLatitude(FromBits(AParts, AFirst + 1));
  FOutput.Add(Format('set %s %s', [Bits(ATarget.Longitude), Bits(ATarget.Latitude)]));
  FOutput.Add('dist=' + General10(ATarget.Distance(FromBits(AParts, AFirst + 2), FromBits(AParts, AFirst + 3))));
  FOutput.Add('self=' + General10(ATarget.Distance(ATarget.Longitude, ATarget.Latitude)));
  FOutput.Add(Format('marker=%s id=%d', [Escape(ATarget.MarkerName), ATarget.MarkerId]));
end;

procedure TXcomSaveObjectScenario.RunWaypoint(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LWaypoint: TXcomWaypoint;
begin
  LWaypoint := TXcomWaypoint.Create;
  try
    LWaypoint.Load(ANode);
    TargetOps(LWaypoint, AParts, 1);
    FOutput.Add(Format('type=%s marker=%d', [LWaypoint.TargetType, LWaypoint.Marker]));
  finally
    LWaypoint.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunAlienBase(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LBase: TXcomAlienBase;
begin
  LBase := TXcomAlienBase.Create(TXcomFakeDeployment.Create(AParts[3], AParts[1], StrToInt(AParts[2])));
  try
    LBase.Load(ANode);
    FOutput.Add(Format('race=%s battle=%d disc=%d', [Escape(LBase.AlienRace), BoolInt(LBase.InBattlescape),
      BoolInt(LBase.Discovered)]));
    Emit(LBase.Save);
    Emit(LBase.SaveId);
    FOutput.Add(Format('type=%s marker=%d', [LBase.TargetType, LBase.Marker]));
    LBase.Discovered := True;
    FOutput.Add(Format('marker=%d', [LBase.Marker]));
    TargetOps(LBase, AParts, 4);
  finally
    LBase.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunMissionSite(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LSite: TXcomMissionSite;
begin
  LSite := TXcomMissionSite.Create(TXcomFakeMission.Create(AParts[4]),
    TXcomFakeDeployment.Create(AParts[3], AParts[1], StrToInt(AParts[2])));
  try
    LSite.Load(ANode);
    FOutput.Add(Format('tex=%d secs=%u race=%s battle=%d det=%d', [LSite.Texture, LSite.SecondsRemaining,
      Escape(LSite.AlienRace), BoolInt(LSite.InBattlescape), BoolInt(LSite.Detected)]));
    Emit(LSite.Save);
    Emit(LSite.SaveId);
    FOutput.Add(Format('type=%s marker=%d', [LSite.TargetType, LSite.Marker]));
    LSite.Detected := True;
    FOutput.Add(Format('marker=%d', [LSite.Marker]));
    LSite.City := 'STR_CITY';
    FOutput.Add('city=' + LSite.City);
  finally
    LSite.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunNode(const ANode: IYamlNode);
var
  LNode: TXcomNode;
  LLinks: string;
  LLink: Integer;
begin
  LNode := TXcomNode.Create;
  try
    LNode.Load(ANode);
    FOutput.Add(Format('n %d %d,%d,%d %d %d %d %d %d alloc=%d dummy=%d target=%d', [LNode.Id, LNode.Position.X,
      LNode.Position.Y, LNode.Position.Z, LNode.NodeType, LNode.Rank, LNode.Flags, LNode.Reserved, LNode.Priority,
      BoolInt(LNode.Allocated), BoolInt(LNode.Dummy), BoolInt(LNode.IsTarget)]));
    LLinks := '[';
    for LLink in LNode.Links do
      LLinks := LLinks + IntToStr(LLink) + ',';
    FOutput.Add('links=' + LLinks + ']');
    Emit(LNode.Save);
    LNode.Allocate;
    FOutput.Add(Format('alloc=%d', [BoolInt(LNode.Allocated)]));
    LNode.Deallocate;
    FOutput.Add(Format('alloc=%d', [BoolInt(LNode.Allocated)]));
  finally
    LNode.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunEquip(const ANode: IYamlNode);
var
  LItem: TXcomEquipmentLayoutItem;
begin
  LItem := TXcomEquipmentLayoutItem.Create(ANode);
  try
    FOutput.Add(Format('e %s %s %d %d %s %d', [Escape(LItem.ItemType), Escape(LItem.Slot), LItem.SlotX, LItem.SlotY,
      Escape(LItem.AmmoItem), LItem.FuseTimer]));
    Emit(LItem.Save);
  finally
    LItem.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunCase(const AHeader: string; const ABody: TYamlText);
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
    if LParts[0] = 'waypoint' then
      RunWaypoint(LParts, LNode)
    else if LParts[0] = 'alienbase' then
      RunAlienBase(LParts, LNode)
    else if LParts[0] = 'missionsite' then
      RunMissionSite(LParts, LNode)
    else if LParts[0] = 'node' then
      RunNode(LNode)
    else if LParts[0] = 'equip' then
      RunEquip(LNode);
  except
    on E: EYamlException do
      FOutput.Add('YAML_ERR ' + Escape(YamlTextToString(E.Msg)));
  end;
end;

function TXcomSaveObjectScenario.Run(const ACorpus: TBytes): TStringList;
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
