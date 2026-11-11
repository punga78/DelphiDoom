{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a mission of the aliens (AlienMission) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.AlienMission;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.TargetLookup.Intf,
  DelphiDoom.XcomSave.Types;

type
  /// <summary>
  ///   A mission that the aliens carry out: the waves of UFOs that it sends, the region and race, the countdown
  ///   to the next wave (AlienMission). The rules belong to the ruleset. Not ported: think, spawnUfo,
  ///   ufoReachedWaypoint, ufoLifting, spawnAlienBase and the choice of the landing point: they need the
  ///   game, the globe and the lists of the saved game (UFOs, bases, countries)
  /// </summary>
  TXcomAlienMission = class
  strict private
    FRule: TXcomRuleAlienMission;
    FRegion: string;
    FRace: string;
    FNextWave: Cardinal;
    FNextUfoCounter: Cardinal;
    FSpawnCountdown: Cardinal;
    FLiveUfos: Cardinal;
    FUniqueId: Integer;
    FMissionSiteZone: Integer;
    FBase: TXcomTarget;
  public
    constructor Create(const ARule: TXcomRuleAlienMission);
    /// <summary>
    ///   load: the alien base is looked up by id and marker name (the old format is just the id of an
    ///   "STR_ALIEN_BASE"); one that is not there is EXcomSaveException (corrupted save)
    /// </summary>
    procedure Load(const ANode: IYamlNode; const ATargets: IXcomTargetLookup);
    function Save: IYamlNode;
    property Rule: TXcomRuleAlienMission read FRule;
    property Region: string read FRegion;
    property Race: string read FRace write FRace;
    property NextWave: Cardinal read FNextWave;
    property NextUfoCounter: Cardinal read FNextUfoCounter write FNextUfoCounter;
    property SpawnCountdown: Cardinal read FSpawnCountdown write FSpawnCountdown;
    property LiveUfos: Cardinal read FLiveUfos;
    property MissionSiteZone: Integer read FMissionSiteZone write FMissionSiteZone;
    /// <summary>getAlienBase / setAlienBase: a reference (not owned)</summary>
    property AlienBase: TXcomTarget read FBase write FBase;
    /// <summary>isOver: infiltrations never end; the others when every wave was sent and no UFO is left</summary>
    function IsOver: Boolean;
    /// <summary>start: at the first wave; with no initial count the delay is random around the timer of the wave</summary>
    procedure Start(AInitialCount: Cardinal; const ARandom: IXcomRandom);
    /// <summary>setWaveCountdown: ignored when the mission is over</summary>
    procedure SetWaveCountdown(AMinutes: Cardinal);
    /// <summary>setId: only once (a second call is EXcomSaveException; the C++ asserts)</summary>
    procedure SetId(AId: Integer);
    /// <summary>getId: a mission with no id is EXcomSaveException (the C++ asserts)</summary>
    function Id: Integer;
    /// <summary>setRegion: the region that the rule of the region says the missions go to, or the region itself</summary>
    procedure SetRegion(const ARegion: string; const ARegionRule: TXcomRuleRegion);
    procedure IncreaseLiveUfos;
    procedure DecreaseLiveUfos;
    /// <summary>ufoShotDown: the next wave is delayed when the UFO was brought down</summary>
    procedure UfoShotDown(AUfoCrashedOrDestroyed: Boolean; const ARandom: IXcomRandom);
    /// <summary>Advances the wave counter (what spawnUfo does when it sends a UFO of the wave)</summary>
    procedure NextWaveStep;
  end;

implementation

{ TXcomAlienMission }

constructor TXcomAlienMission.Create(const ARule: TXcomRuleAlienMission);
begin
  inherited Create;
  FRule := ARule;
  FMissionSiteZone := -1;
end;

procedure TXcomAlienMission.Load(const ANode: IYamlNode; const ATargets: IXcomTargetLookup);
var
  LField, LType: IYamlNode;
  LId: Integer;
  LMarker: string;
begin
  FRegion := TXcomNodeReader.ReadString(ANode, 'region', FRegion);
  FRace := TXcomNodeReader.ReadString(ANode, 'race', FRace);
  FNextWave := TXcomNodeReader.ReadSize(ANode, 'nextWave', FNextWave);
  FNextUfoCounter := TXcomNodeReader.ReadSize(ANode, 'nextUfoCounter', FNextUfoCounter);
  FSpawnCountdown := TXcomNodeReader.ReadSize(ANode, 'spawnCountdown', FSpawnCountdown);
  FLiveUfos := TXcomNodeReader.ReadSize(ANode, 'liveUfos', FLiveUfos);
  FUniqueId := TXcomNodeReader.ReadInteger(ANode, 'uniqueID', FUniqueId);
  LField := TXcomNodeReader.Field(ANode, 'alienBase');
  if LField.IsDefined then
  begin
    LMarker := 'STR_ALIEN_BASE';
    // as<int>(-1): a map does not convert and gives -1, the new format
    LId := -1;
    if LField.IsScalar then
      LId := LField.AsInteger(-1);
    if LId = -1 then
    begin
      LType := TXcomNodeReader.Field(LField, 'type');
      if not LType.IsDefined or not TXcomNodeReader.Field(LField, 'id').IsDefined then
        raise TXcomNodeReader.BadConversion(LField);
      LId := TXcomNodeReader.Field(LField, 'id').AsInteger;
      LMarker := TXcomNodeReader.TextOf(LType);
    end;
    FBase := ATargets.FindAlienBase(LId, LMarker);
    if not Assigned(FBase) then
      raise EXcomSaveException.Create('Corrupted save: Invalid base for mission.');
  end;
  FMissionSiteZone := TXcomNodeReader.ReadInteger(ANode, 'missionSiteZone', FMissionSiteZone);
end;

function TXcomAlienMission.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetString(Result, 'type', FRule.MissionType);
  TXcomNodeWriter.SetString(Result, 'region', FRegion);
  TXcomNodeWriter.SetString(Result, 'race', FRace);
  TXcomNodeWriter.SetString(Result, 'nextWave', UIntToStr(FNextWave));
  TXcomNodeWriter.SetString(Result, 'nextUfoCounter', UIntToStr(FNextUfoCounter));
  TXcomNodeWriter.SetString(Result, 'spawnCountdown', UIntToStr(FSpawnCountdown));
  TXcomNodeWriter.SetString(Result, 'liveUfos', UIntToStr(FLiveUfos));
  TXcomNodeWriter.SetInteger(Result, 'uniqueID', FUniqueId);
  if Assigned(FBase) then
    TXcomNodeWriter.SetNode(Result, 'alienBase', FBase.SaveId);
  TXcomNodeWriter.SetInteger(Result, 'missionSiteZone', FMissionSiteZone);
end;

function TXcomAlienMission.IsOver: Boolean;
begin
  if FRule.Objective = TXcomRuleAlienMission.OBJECTIVE_INFILTRATION then
    Exit(False);
  Result := (FNextWave = Cardinal(FRule.WaveCount)) and (FLiveUfos = 0);
end;

procedure TXcomAlienMission.Start(AInitialCount: Cardinal; const ARandom: IXcomRandom);
var
  LSpawnTimer: Cardinal;
begin
  FNextWave := 0;
  FNextUfoCounter := 0;
  FLiveUfos := 0;
  if AInitialCount = 0 then
  begin
    if FRule.WaveCount = 0 then
      raise EXcomSaveException.Create('Xcom: the mission has no waves');
    LSpawnTimer := FRule.Waves[0].SpawnTimer div 30;
    FSpawnCountdown := (LSpawnTimer div 2 + Cardinal(ARandom.Generate(0, Integer(LSpawnTimer)))) * 30;
  end
  else
    FSpawnCountdown := AInitialCount;
end;

procedure TXcomAlienMission.SetWaveCountdown(AMinutes: Cardinal);
begin
  if (AMinutes = 0) or (AMinutes mod 30 <> 0) then
    raise EXcomSaveException.Create('Xcom: the wave countdown must be a multiple of 30 minutes');
  if IsOver then
    Exit;
  FSpawnCountdown := AMinutes;
end;

procedure TXcomAlienMission.SetId(AId: Integer);
begin
  if FUniqueId <> 0 then
    raise EXcomSaveException.Create('Xcom: reassigning the id of a mission');
  FUniqueId := AId;
end;

function TXcomAlienMission.Id: Integer;
begin
  if FUniqueId = 0 then
    raise EXcomSaveException.Create('Xcom: uninitialized mission');
  Result := FUniqueId;
end;

procedure TXcomAlienMission.SetRegion(const ARegion: string; const ARegionRule: TXcomRuleRegion);
begin
  if ARegionRule.MissionRegion <> '' then
    FRegion := ARegionRule.MissionRegion
  else
    FRegion := ARegion;
end;

procedure TXcomAlienMission.IncreaseLiveUfos;
begin
  Inc(FLiveUfos);
end;

procedure TXcomAlienMission.DecreaseLiveUfos;
begin
  Dec(FLiveUfos);
end;

procedure TXcomAlienMission.UfoShotDown(AUfoCrashedOrDestroyed: Boolean; const ARandom: IXcomRandom);
begin
  if not AUfoCrashedOrDestroyed then
    raise EXcomSaveException.Create('Xcom: the UFO was not brought down');
  if FNextWave <> Cardinal(FRule.WaveCount) then
    Inc(FSpawnCountdown, 30 * Cardinal(ARandom.Generate(0, 400) + 48));
end;

procedure TXcomAlienMission.NextWaveStep;
begin
  Inc(FNextWave);
end;

end.
