{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the statistics of a unit in a battle  }
{  (BattleUnitStatistics)                                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.BattleUnitStatistics;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomSave.UnitEnums, DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.NodeIteration,
  DelphiDoom.XcomSave.UnitStats, DelphiDoom.XcomSave.BattleUnitKills;

type
  /// <summary>
  ///   What a unit did in a battle (shots, hits, kills, medals earned...). The kills are owned by this object.
  ///   The delta of the stats is only used while debriefing and is not saved
  /// </summary>
  TXcomBattleUnitStatistics = class
  strict private
    FWasUnconscious: Boolean;
    FShotAtCounter: Integer;
    FHitCounter: Integer;
    FShotByFriendlyCounter: Integer;
    FShotFriendlyCounter: Integer;
    FLoneSurvivor: Boolean;
    FIronMan: Boolean;
    FLongDistanceHitCounter: Integer;
    FLowAccuracyHitCounter: Integer;
    FShotsFiredCounter: Integer;
    FShotsLandedCounter: Integer;
    FKills: TObjectList<TXcomBattleUnitKills>;
    FDaysWounded: Integer;
    FKIA: Boolean;
    FNikeCross: Boolean;
    FMercyCross: Boolean;
    FWoundsHealed: Integer;
    FDelta: TXcomUnitStats;
    FAppliedStimulant: Integer;
    FAppliedPainKill: Integer;
    FRevivedSoldier: Integer;
    FRevivedHostile: Integer;
    FRevivedNeutral: Integer;
    FMIA: Boolean;
    FMartyr: Integer;
    FSlaveKills: Integer;
  public
    constructor Create; overload;
    constructor Create(const ANode: IYamlNode); overload;
    destructor Destroy; override;
    /// <summary>Loads the statistics; the kills of the node are added to the ones already here</summary>
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    /// <summary>duplicateEntry: a kill with this status and unit id is already in the list</summary>
    function DuplicateEntry(AStatus, AId: Integer): Boolean;
    /// <summary>hasFriendlyFired: one of the kills is of the player's faction</summary>
    function HasFriendlyFired: Boolean;
    property WasUnconscious: Boolean read FWasUnconscious write FWasUnconscious;
    property ShotAtCounter: Integer read FShotAtCounter write FShotAtCounter;
    property HitCounter: Integer read FHitCounter write FHitCounter;
    property ShotByFriendlyCounter: Integer read FShotByFriendlyCounter write FShotByFriendlyCounter;
    property ShotFriendlyCounter: Integer read FShotFriendlyCounter write FShotFriendlyCounter;
    property LoneSurvivor: Boolean read FLoneSurvivor write FLoneSurvivor;
    property IronMan: Boolean read FIronMan write FIronMan;
    property LongDistanceHitCounter: Integer read FLongDistanceHitCounter write FLongDistanceHitCounter;
    property LowAccuracyHitCounter: Integer read FLowAccuracyHitCounter write FLowAccuracyHitCounter;
    property ShotsFiredCounter: Integer read FShotsFiredCounter write FShotsFiredCounter;
    property ShotsLandedCounter: Integer read FShotsLandedCounter write FShotsLandedCounter;
    /// <summary>The kills, owned by the statistics</summary>
    property Kills: TObjectList<TXcomBattleUnitKills> read FKills;
    property DaysWounded: Integer read FDaysWounded write FDaysWounded;
    property KIA: Boolean read FKIA write FKIA;
    property NikeCross: Boolean read FNikeCross write FNikeCross;
    property MercyCross: Boolean read FMercyCross write FMercyCross;
    property WoundsHealed: Integer read FWoundsHealed write FWoundsHealed;
    property Delta: TXcomUnitStats read FDelta write FDelta;
    property AppliedStimulant: Integer read FAppliedStimulant write FAppliedStimulant;
    property AppliedPainKill: Integer read FAppliedPainKill write FAppliedPainKill;
    property RevivedSoldier: Integer read FRevivedSoldier write FRevivedSoldier;
    property RevivedHostile: Integer read FRevivedHostile write FRevivedHostile;
    property RevivedNeutral: Integer read FRevivedNeutral write FRevivedNeutral;
    property MIA: Boolean read FMIA write FMIA;
    property Martyr: Integer read FMartyr write FMartyr;
    property SlaveKills: Integer read FSlaveKills write FSlaveKills;
  end;

implementation

{ TXcomBattleUnitStatistics }

constructor TXcomBattleUnitStatistics.Create;
begin
  inherited Create;
  FKills := TObjectList<TXcomBattleUnitKills>.Create(True);
end;

constructor TXcomBattleUnitStatistics.Create(const ANode: IYamlNode);
begin
  Create;
  Load(ANode);
end;

destructor TXcomBattleUnitStatistics.Destroy;
begin
  FKills.Free;
  inherited Destroy;
end;

procedure TXcomBattleUnitStatistics.Load(const ANode: IYamlNode);
var
  LField, LElement: IYamlNode;
begin
  FWasUnconscious := TXcomNodeReader.ReadBoolean(ANode, 'wasUnconcious', FWasUnconscious);
  LField := TXcomNodeReader.Field(ANode, 'kills');
  if LField.IsDefined then
    for LElement in TXcomNodeIteration.Elements(LField) do
      FKills.Add(TXcomBattleUnitKills.Create(LElement));
  FShotAtCounter := TXcomNodeReader.ReadInteger(ANode, 'shotAtCounter', FShotAtCounter);
  FHitCounter := TXcomNodeReader.ReadInteger(ANode, 'hitCounter', FHitCounter);
  FShotByFriendlyCounter := TXcomNodeReader.ReadInteger(ANode, 'shotByFriendlyCounter', FShotByFriendlyCounter);
  FShotFriendlyCounter := TXcomNodeReader.ReadInteger(ANode, 'shotFriendlyCounter', FShotFriendlyCounter);
  FLoneSurvivor := TXcomNodeReader.ReadBoolean(ANode, 'loneSurvivor', FLoneSurvivor);
  FIronMan := TXcomNodeReader.ReadBoolean(ANode, 'ironMan', FIronMan);
  FLongDistanceHitCounter := TXcomNodeReader.ReadInteger(ANode, 'longDistanceHitCounter', FLongDistanceHitCounter);
  FLowAccuracyHitCounter := TXcomNodeReader.ReadInteger(ANode, 'lowAccuracyHitCounter', FLowAccuracyHitCounter);
  FShotsFiredCounter := TXcomNodeReader.ReadInteger(ANode, 'shotsFiredCounter', FShotsFiredCounter);
  FShotsLandedCounter := TXcomNodeReader.ReadInteger(ANode, 'shotsLandedCounter', FShotsLandedCounter);
  FNikeCross := TXcomNodeReader.ReadBoolean(ANode, 'nikeCross', FNikeCross);
  FMercyCross := TXcomNodeReader.ReadBoolean(ANode, 'mercyCross', FMercyCross);
  FWoundsHealed := TXcomNodeReader.ReadInteger(ANode, 'woundsHealed', FWoundsHealed);
  FAppliedStimulant := TXcomNodeReader.ReadInteger(ANode, 'appliedStimulant', FAppliedStimulant);
  FAppliedPainKill := TXcomNodeReader.ReadInteger(ANode, 'appliedPainKill', FAppliedPainKill);
  FRevivedSoldier := TXcomNodeReader.ReadInteger(ANode, 'revivedSoldier', FRevivedSoldier);
  FRevivedHostile := TXcomNodeReader.ReadInteger(ANode, 'revivedHostile', FRevivedHostile);
  FRevivedNeutral := TXcomNodeReader.ReadInteger(ANode, 'revivedNeutral', FRevivedNeutral);
  FMartyr := TXcomNodeReader.ReadInteger(ANode, 'martyr', FMartyr);
  FSlaveKills := TXcomNodeReader.ReadInteger(ANode, 'slaveKills', FSlaveKills);
end;

function TXcomBattleUnitStatistics.Save: IYamlNode;
var
  LKills: IYamlNode;
  LKill: TXcomBattleUnitKills;

  procedure PutInteger(const AKey: string; AValue: Integer);
  begin
    if AValue <> 0 then
      TXcomNodeWriter.SetInteger(Result, AKey, AValue);
  end;

  procedure PutBoolean(const AKey: string; AValue: Boolean);
  begin
    if AValue then
      TXcomNodeWriter.SetBoolean(Result, AKey, AValue);
  end;

begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetBoolean(Result, 'wasUnconcious', FWasUnconscious);
  if FKills.Count > 0 then
  begin
    LKills := TXcomNodeWriter.NewSequence;
    for LKill in FKills do
      LKills.Add(LKill.Save);
    TXcomNodeWriter.SetNode(Result, 'kills', LKills);
  end;
  PutInteger('shotAtCounter', FShotAtCounter);
  PutInteger('hitCounter', FHitCounter);
  PutInteger('shotByFriendlyCounter', FShotByFriendlyCounter);
  PutInteger('shotFriendlyCounter', FShotFriendlyCounter);
  PutBoolean('loneSurvivor', FLoneSurvivor);
  PutBoolean('ironMan', FIronMan);
  PutInteger('longDistanceHitCounter', FLongDistanceHitCounter);
  PutInteger('lowAccuracyHitCounter', FLowAccuracyHitCounter);
  PutInteger('shotsFiredCounter', FShotsFiredCounter);
  PutInteger('shotsLandedCounter', FShotsLandedCounter);
  PutBoolean('nikeCross', FNikeCross);
  PutBoolean('mercyCross', FMercyCross);
  PutInteger('woundsHealed', FWoundsHealed);
  PutInteger('appliedStimulant', FAppliedStimulant);
  PutInteger('appliedPainKill', FAppliedPainKill);
  PutInteger('revivedSoldier', FRevivedSoldier);
  PutInteger('revivedHostile', FRevivedHostile);
  PutInteger('revivedNeutral', FRevivedNeutral);
  PutInteger('martyr', FMartyr);
  PutInteger('slaveKills', FSlaveKills);
end;

function TXcomBattleUnitStatistics.DuplicateEntry(AStatus, AId: Integer): Boolean;
var
  LKill: TXcomBattleUnitKills;
begin
  for LKill in FKills do
    if (LKill.Id = AId) and (LKill.Status = AStatus) then
      Exit(True);
  Result := False;
end;

function TXcomBattleUnitStatistics.HasFriendlyFired: Boolean;
var
  LKill: TXcomBattleUnitKills;
begin
  for LKill in FKills do
    if LKill.Faction = XcomFactionPlayer then
      Exit(True);
  Result := False;
end;

end.
