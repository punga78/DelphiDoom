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
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.EquipmentLayoutItem,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomSave.ItemContainer,
  DelphiDoom.XcomSave.Vehicle, DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.Production;

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

  /// <summary>An item, facility and craft weapon rule in one: a type and two numbers</summary>
  TXcomFakeTypeRule = class(TInterfacedObject, IXcomItemRule, IXcomFacilityRule, IXcomCraftWeaponRule)
  strict private
    FType: string;
    FAmmoMax: Integer;
    FRearmRate: Integer;
  public
    constructor Create(const AType: string; AAmmoMax: Integer = 0; ARearmRate: Integer = 0);
    function ItemType: string;
    function FacilityType: string;
    function WeaponType: string;
    function AmmoMax: Integer;
    function RearmRate: Integer;
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
    procedure RunItemContainer(const ANode: IYamlNode);
    procedure RunVehicle(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunCraftWeapon(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunBaseFacility(const AParts: TArray<string>; const ANode: IYamlNode);
    procedure RunProduction(const AParts: TArray<string>; const ANode: IYamlNode);
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

{ TXcomFakeTypeRule }

constructor TXcomFakeTypeRule.Create(const AType: string; AAmmoMax, ARearmRate: Integer);
begin
  inherited Create;
  FType := AType;
  FAmmoMax := AAmmoMax;
  FRearmRate := ARearmRate;
end;

function TXcomFakeTypeRule.ItemType: string;
begin
  Result := FType;
end;

function TXcomFakeTypeRule.FacilityType: string;
begin
  Result := FType;
end;

function TXcomFakeTypeRule.WeaponType: string;
begin
  Result := FType;
end;

function TXcomFakeTypeRule.AmmoMax: Integer;
begin
  Result := FAmmoMax;
end;

function TXcomFakeTypeRule.RearmRate: Integer;
begin
  Result := FRearmRate;
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

procedure TXcomSaveObjectScenario.RunItemContainer(const ANode: IYamlNode);
var
  LContainer: TXcomItemContainer;

  procedure Dump;
  var
    LText: string;
    LIndex: Integer;
  begin
    LText := '';
    for LIndex := 0 to LContainer.Contents.Count - 1 do
      LText := LText + LContainer.Contents.Key(LIndex) + '=' + IntToStr(LContainer.Contents.Value(LIndex)) + ';';
    FOutput.Add(Format('c %s total=%d', [LText, LContainer.TotalQuantity]));
  end;

begin
  LContainer := TXcomItemContainer.Create;
  try
    LContainer.Load(ANode);
    Dump;
    Emit(LContainer.Save);
    LContainer.AddItem('STR_RIFLE', 3);
    LContainer.AddItem('', 9);
    LContainer.AddItem('NEW', -2);
    Dump;
    LContainer.RemoveItem('STR_RIFLE', 2);
    LContainer.RemoveItem('NEW', 5);
    LContainer.RemoveItem('nothing', 1);
    LContainer.RemoveItem('AAA', 100000);
    Dump;
    FOutput.Add(Format('get %d %d %d', [LContainer.GetItem('STR_RIFLE'), LContainer.GetItem(''),
      LContainer.GetItem('zzz')]));
    Emit(LContainer.Save);
  finally
    LContainer.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunVehicle(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LVehicle: TXcomVehicle;
begin
  LVehicle := TXcomVehicle.Create(TXcomFakeTypeRule.Create(AParts[1]), StrToInt(AParts[2]), StrToInt(AParts[3]));
  try
    LVehicle.Load(ANode);
    FOutput.Add(Format('v %d %d', [LVehicle.Ammo, LVehicle.Size]));
    Emit(LVehicle.Save);
    LVehicle.SetAmmo(7);
    FOutput.Add(Format('after %d', [LVehicle.Ammo]));
  finally
    LVehicle.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunCraftWeapon(const AParts: TArray<string>; const ANode: IYamlNode);
const
  Clips: array[0..3] of Integer = (0, 1, 2, 5);
  Available: array[0..3] of Integer = (0, 3, 100, 1);
var
  LWeapon: TXcomCraftWeapon;
  LIndex, LUsed, LAfterFirst: Integer;
  LFirst, LSecond: Boolean;
begin
  LWeapon := TXcomCraftWeapon.Create(TXcomFakeTypeRule.Create(AParts[1], StrToInt(AParts[2]), StrToInt(AParts[3])),
    StrToInt(AParts[4]));
  try
    LWeapon.Load(ANode);
    FOutput.Add(Format('w %d %d', [LWeapon.Ammo, BoolInt(LWeapon.Rearming)]));
    Emit(LWeapon.Save);
    for LIndex := 0 to 3 do
    begin
      LUsed := LWeapon.Rearm(Available[LIndex], Clips[LIndex]);
      FOutput.Add(Format('rearm clip=%d avail=%d -> used=%d ammo=%d rearming=%d', [Clips[LIndex], Available[LIndex],
        LUsed, LWeapon.Ammo, BoolInt(LWeapon.Rearming)]));
    end;
    LFirst := LWeapon.SetAmmo(-4);
    LAfterFirst := LWeapon.Ammo;
    LSecond := LWeapon.SetAmmo(1000000);
    FOutput.Add(Format('set %d %d set %d %d', [BoolInt(LFirst), LAfterFirst, BoolInt(LSecond), LWeapon.Ammo]));
    LWeapon.Rearming := True;
    Emit(LWeapon.Save);
  finally
    LWeapon.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunBaseFacility(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LFacility: TXcomBaseFacility;
begin
  LFacility := TXcomBaseFacility.Create(TXcomFakeTypeRule.Create(AParts[1]));
  try
    LFacility.Load(ANode);
    FOutput.Add(Format('f %d %d %d', [LFacility.X, LFacility.Y, LFacility.BuildTime]));
    Emit(LFacility.Save);
    LFacility.Build;
    LFacility.X := 3;
    LFacility.Y := 4;
    FOutput.Add(Format('after %d %d %d', [LFacility.X, LFacility.Y, LFacility.BuildTime]));
  finally
    LFacility.Free;
  end;
end;

procedure TXcomSaveObjectScenario.RunProduction(const AParts: TArray<string>; const ANode: IYamlNode);
var
  LRules: TXcomRuleManufacture;
  LProduction: TXcomProduction;
  LCost: Integer;
  LFund: Int64;
  LFunds: TArray<Int64>;
  LText: string;
begin
  LCost := StrToInt(AParts[3]);
  LRules := TXcomRuleManufacture.Create(AParts[1]);
  try
    LRules.Load(TYamlFactory.CreateParser.Load(YamlStringToText('time: ' + AParts[2] + #10 + 'cost: ' + AParts[3] +
      #10)), 1);
    LProduction := TXcomProduction.Create(LRules, StrToInt(AParts[4]));
    try
      LProduction.Load(ANode);
      FOutput.Add(Format('p %d %d %d %d %d', [LProduction.AssignedEngineers, LProduction.TimeSpent,
        LProduction.AmountTotal, BoolInt(LProduction.InfiniteAmount), BoolInt(LProduction.SellItems)]));
      Emit(LProduction.Save);
      FOutput.Add(Format('produced=%d', [LProduction.AmountProduced]));
      LFunds := [0, LCost, Int64(LCost) - 1, -5, 5000000000];
      LText := '';
      for LFund in LFunds do
        LText := LText + IntToStr(BoolInt(LProduction.HaveEnoughMoneyForOneMoreUnit(LFund))) + ',';
      FOutput.Add('money=' + LText);
    finally
      LProduction.Free;
    end;
  finally
    LRules.Free;
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
      RunEquip(LNode)
    else if LParts[0] = 'itemcontainer' then
      RunItemContainer(LNode)
    else if LParts[0] = 'vehicle' then
      RunVehicle(LParts, LNode)
    else if LParts[0] = 'craftweapon' then
      RunCraftWeapon(LParts, LNode)
    else if LParts[0] = 'basefacility' then
      RunBaseFacility(LParts, LNode)
    else if LParts[0] = 'production' then
      RunProduction(LParts, LNode);
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
