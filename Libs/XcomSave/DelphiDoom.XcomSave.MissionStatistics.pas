{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - what happened in a mission             }
{  (MissionStatistics)                                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.MissionStatistics;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.GameTime;

type
  /// <summary>The wounds of a mission: the number of wounds and how many soldiers had them (a pair of injuryList)</summary>
  TXcomInjury = record
    Wounds: Integer;
    Soldiers: Integer;
  end;

  /// <summary>
  ///   The record of a mission for the diaries of the soldiers (MissionStatistics). The default values are
  ///   those of the default constructor; the C++ constructor from a node leaves them uninitialized
  /// </summary>
  TXcomMissionStatistics = class
  strict private
    FId: Integer;
    FMarkerName: string;
    FMarkerId: Integer;
    FTime: TXcomGameTime;
    FRegion: string;
    FCountry: string;
    FType: string;
    FUfo: string;
    FSuccess: Boolean;
    FRating: string;
    FScore: Integer;
    FAlienRace: string;
    FDaylight: Integer;
    FInjuryList: TArray<TXcomInjury>;
    FValiantCrux: Boolean;
    FLootValue: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>load: the injury list is a map of ints (a bad entry is EYamlBadConversion; a node of another kind keeps the list)</summary>
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Id: Integer read FId write FId;
    property MarkerName: string read FMarkerName write FMarkerName;
    property MarkerId: Integer read FMarkerId write FMarkerId;
    property Time: TXcomGameTime read FTime;
    property Region: string read FRegion write FRegion;
    property Country: string read FCountry write FCountry;
    property MissionType: string read FType write FType;
    property Ufo: string read FUfo write FUfo;
    property Success: Boolean read FSuccess write FSuccess;
    property Rating: string read FRating write FRating;
    property Score: Integer read FScore write FScore;
    property AlienRace: string read FAlienRace write FAlienRace;
    property Daylight: Integer read FDaylight write FDaylight;
    property InjuryList: TArray<TXcomInjury> read FInjuryList write FInjuryList;
    property ValiantCrux: Boolean read FValiantCrux write FValiantCrux;
    property LootValue: Integer read FLootValue write FLootValue;
    /// <summary>isAlienBase</summary>
    function IsAlienBase: Boolean;
    function IsBaseDefense: Boolean;
    function IsUfoMission: Boolean;
    /// <summary>getLocationString: the region when the country is unknown, otherwise the country</summary>
    function LocationString: string;
  end;

implementation

{ TXcomMissionStatistics }

constructor TXcomMissionStatistics.Create;
begin
  inherited Create;
  FTime := TXcomGameTime.Create(0, 0, 0, 0, 0, 0, 0);
  FRegion := 'STR_REGION_UNKNOWN';
  FCountry := 'STR_UNKNOWN';
  FUfo := 'NO_UFO';
  FAlienRace := 'STR_UNKNOWN';
end;

destructor TXcomMissionStatistics.Destroy;
begin
  FTime.Free;
  inherited Destroy;
end;

procedure TXcomMissionStatistics.Load(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LPairs: TArray<TYamlPair>;
  LIndex: Integer;
  LList: TArray<TXcomInjury>;
begin
  FId := TXcomNodeReader.ReadInteger(ANode, 'id', FId);
  FMarkerName := TXcomNodeReader.ReadString(ANode, 'markerName', FMarkerName);
  FMarkerId := TXcomNodeReader.ReadInteger(ANode, 'markerId', FMarkerId);
  FTime.Load(TXcomNodeReader.Field(ANode, 'time'));
  FRegion := TXcomNodeReader.ReadString(ANode, 'region', FRegion);
  FCountry := TXcomNodeReader.ReadString(ANode, 'country', FCountry);
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FUfo := TXcomNodeReader.ReadString(ANode, 'ufo', FUfo);
  FSuccess := TXcomNodeReader.ReadBoolean(ANode, 'success', FSuccess);
  FScore := TXcomNodeReader.ReadInteger(ANode, 'score', FScore);
  FRating := TXcomNodeReader.ReadString(ANode, 'rating', FRating);
  FAlienRace := TXcomNodeReader.ReadString(ANode, 'alienRace', FAlienRace);
  FDaylight := TXcomNodeReader.ReadInteger(ANode, 'daylight', FDaylight);
  LField := TXcomNodeReader.Field(ANode, 'injuryList');
  if LField.IsDefined and LField.IsMap then
  begin
    LPairs := LField.Pairs;
    SetLength(LList, Length(LPairs));
    for LIndex := 0 to High(LPairs) do
    begin
      LList[LIndex].Wounds := LPairs[LIndex].Key.AsInteger;
      LList[LIndex].Soldiers := LPairs[LIndex].Value.AsInteger;
    end;
    // std::map<int, int>: ordered by key, the last value of a repeated key wins
    TArray.Sort<TXcomInjury>(LList, TComparer<TXcomInjury>.Construct(
      function(const ALeft, ARight: TXcomInjury): Integer begin Result := ALeft.Wounds - ARight.Wounds; end));
    FInjuryList := LList;
  end;
  FValiantCrux := TXcomNodeReader.ReadBoolean(ANode, 'valiantCrux', FValiantCrux);
  FLootValue := TXcomNodeReader.ReadInteger(ANode, 'lootValue', FLootValue);
end;

function TXcomMissionStatistics.Save: IYamlNode;
var
  LInjuries: IYamlNode;
  LInjury: TXcomInjury;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'id', FId);
  if FMarkerName <> '' then
  begin
    TXcomNodeWriter.SetString(Result, 'markerName', FMarkerName);
    TXcomNodeWriter.SetInteger(Result, 'markerId', FMarkerId);
  end;
  TXcomNodeWriter.SetNode(Result, 'time', FTime.Save);
  TXcomNodeWriter.SetString(Result, 'region', FRegion);
  TXcomNodeWriter.SetString(Result, 'country', FCountry);
  TXcomNodeWriter.SetString(Result, 'type', FType);
  TXcomNodeWriter.SetString(Result, 'ufo', FUfo);
  TXcomNodeWriter.SetBoolean(Result, 'success', FSuccess);
  TXcomNodeWriter.SetInteger(Result, 'score', FScore);
  TXcomNodeWriter.SetString(Result, 'rating', FRating);
  TXcomNodeWriter.SetString(Result, 'alienRace', FAlienRace);
  TXcomNodeWriter.SetInteger(Result, 'daylight', FDaylight);
  LInjuries := TXcomNodeWriter.NewEmptyMap;
  for LInjury in FInjuryList do
    TXcomNodeWriter.SetInteger(LInjuries, IntToStr(LInjury.Wounds), LInjury.Soldiers);
  TXcomNodeWriter.SetNode(Result, 'injuryList', LInjuries);
  if FValiantCrux then
    TXcomNodeWriter.SetBoolean(Result, 'valiantCrux', True);
  if FLootValue <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'lootValue', FLootValue);
end;

function TXcomMissionStatistics.IsAlienBase: Boolean;
begin
  Result := (Pos('STR_ALIEN_BASE', FType) > 0) or (Pos('STR_ALIEN_COLONY', FType) > 0);
end;

function TXcomMissionStatistics.IsBaseDefense: Boolean;
begin
  Result := FType = 'STR_BASE_DEFENSE';
end;

function TXcomMissionStatistics.IsUfoMission: Boolean;
begin
  Result := FUfo <> 'NO_UFO';
end;

function TXcomMissionStatistics.LocationString: string;
begin
  if FCountry = 'STR_UNKNOWN' then
    Result := FRegion
  else
    Result := FCountry;
end;

end.
