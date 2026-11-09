{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a kill of a soldier (BattleUnitKills) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.BattleUnitKills;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.UnitEnums,
  DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>
  ///   The record of a unit that a soldier killed, stunned, panicked or mind controlled. Status, faction, side
  ///   and body part are kept as the integers of the saved game (any integer can be in a file: the string
  ///   functions answer an error text for a value outside the enumeration, as the C++ does). Not ported:
  ///   getUnitName (needs Language) and setUnitStats (needs BattleUnit)
  /// </summary>
  TXcomBattleUnitKills = class
  strict private
    FName: string;
    FUnitType: string;
    FRank: string;
    FRace: string;
    FWeapon: string;
    FWeaponAmmo: string;
    FFaction: Integer;
    FStatus: Integer;
    FMission: Integer;
    FTurn: Integer;
    FId: Integer;
    FSide: Integer;
    FBodyPart: Integer;
  public
    constructor Create; overload;
    /// <summary>Makes the record from a YAML node; the status, faction, side and body part are required</summary>
    constructor Create(const ANode: IYamlNode); overload;
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    property Name: string read FName write FName;
    property UnitType: string read FUnitType write FUnitType;
    property Rank: string read FRank write FRank;
    property Race: string read FRace write FRace;
    property Weapon: string read FWeapon write FWeapon;
    property WeaponAmmo: string read FWeaponAmmo write FWeaponAmmo;
    property Faction: Integer read FFaction write FFaction;
    property Status: Integer read FStatus write FStatus;
    property Mission: Integer read FMission write FMission;
    property Turn: Integer read FTurn write FTurn;
    property Id: Integer read FId write FId;
    property Side: Integer read FSide write FSide;
    property BodyPart: Integer read FBodyPart write FBodyPart;
    /// <summary>makeTurnUnique: the turn counts the missions too (it stays divisible by 3)</summary>
    function MakeTurnUnique: Integer;
    function HostileTurn: Boolean;
    procedure SetTurn(AUnitTurn, AUnitFaction: Integer);
    function KillStatusString: string;
    function UnitStatusString: string;
    function UnitFactionString: string;
    function UnitSideString: string;
    function UnitBodyPartString: string;
  end;

implementation

{ TXcomBattleUnitKills }

constructor TXcomBattleUnitKills.Create;
begin
  inherited Create;
  FFaction := XcomFactionHostile;
  FStatus := XcomStatusIgnoreMe;
  FSide := XcomSideFront;
  FBodyPart := XcomBodyPartHead;
end;

constructor TXcomBattleUnitKills.Create(const ANode: IYamlNode);
begin
  Create;
  Load(ANode);
end;

procedure TXcomBattleUnitKills.Load(const ANode: IYamlNode);
var
  LField: IYamlNode;
begin
  LField := TXcomNodeReader.Field(ANode, 'name');
  if LField.IsDefined then
    FName := TXcomNodeReader.TextOf(LField);
  FUnitType := TXcomNodeReader.ReadString(ANode, 'type', FUnitType);
  FRank := TXcomNodeReader.ReadString(ANode, 'rank', FRank);
  FRace := TXcomNodeReader.ReadString(ANode, 'race', FRace);
  FWeapon := TXcomNodeReader.ReadString(ANode, 'weapon', FWeapon);
  FWeaponAmmo := TXcomNodeReader.ReadString(ANode, 'weaponAmmo', FWeaponAmmo);
  FStatus := TXcomNodeReader.Field(ANode, 'status').AsInteger;
  FFaction := TXcomNodeReader.Field(ANode, 'faction').AsInteger;
  FMission := TXcomNodeReader.ReadInteger(ANode, 'mission', FMission);
  FTurn := TXcomNodeReader.ReadInteger(ANode, 'turn', FTurn);
  FSide := TXcomNodeReader.Field(ANode, 'side').AsInteger;
  FBodyPart := TXcomNodeReader.Field(ANode, 'bodypart').AsInteger;
  FId := TXcomNodeReader.ReadInteger(ANode, 'id', FId);
end;

function TXcomBattleUnitKills.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  if FName <> '' then
    TXcomNodeWriter.SetString(Result, 'name', FName);
  if FUnitType <> '' then
    TXcomNodeWriter.SetString(Result, 'type', FUnitType);
  TXcomNodeWriter.SetString(Result, 'rank', FRank);
  TXcomNodeWriter.SetString(Result, 'race', FRace);
  TXcomNodeWriter.SetString(Result, 'weapon', FWeapon);
  TXcomNodeWriter.SetString(Result, 'weaponAmmo', FWeaponAmmo);
  TXcomNodeWriter.SetInteger(Result, 'status', FStatus);
  TXcomNodeWriter.SetInteger(Result, 'faction', FFaction);
  TXcomNodeWriter.SetInteger(Result, 'mission', FMission);
  TXcomNodeWriter.SetInteger(Result, 'turn', FTurn);
  TXcomNodeWriter.SetInteger(Result, 'side', FSide);
  TXcomNodeWriter.SetInteger(Result, 'bodypart', FBodyPart);
  TXcomNodeWriter.SetInteger(Result, 'id', FId);
end;

function TXcomBattleUnitKills.MakeTurnUnique: Integer;
begin
  // maintains divisibility by 3 as well
  Inc(FTurn, FMission * 300);
  Result := FTurn;
end;

function TXcomBattleUnitKills.HostileTurn: Boolean;
begin
  // the C++ remainder keeps the sign of the dividend, like mod
  Result := (FTurn - 1) mod 3 = 0;
end;

procedure TXcomBattleUnitKills.SetTurn(AUnitTurn, AUnitFaction: Integer);
begin
  FTurn := AUnitTurn * 3 + AUnitFaction;
end;

function TXcomBattleUnitKills.KillStatusString: string;
begin
  case FStatus of
    XcomStatusDead:
      Result := 'STR_KILLED';
    XcomStatusUnconscious:
      Result := 'STR_STUNNED';
    XcomStatusPanicking:
      Result := 'STR_PANICKED';
    XcomStatusTurning:
      Result := 'STR_MINDCONTROLLED';
  else
    Result := 'status error';
  end;
end;

function TXcomBattleUnitKills.UnitStatusString: string;
begin
  case FStatus of
    XcomStatusDead:
      Result := 'STATUS_DEAD';
    XcomStatusUnconscious:
      Result := 'STATUS_UNCONSCIOUS';
    XcomStatusPanicking:
      Result := 'STATUS_PANICKING';
    XcomStatusTurning:
      Result := 'STATUS_TURNING';
  else
    Result := 'status error';
  end;
end;

function TXcomBattleUnitKills.UnitFactionString: string;
begin
  case FFaction of
    XcomFactionPlayer:
      Result := 'FACTION_PLAYER';
    XcomFactionHostile:
      Result := 'FACTION_HOSTILE';
    XcomFactionNeutral:
      Result := 'FACTION_NEUTRAL';
  else
    Result := 'faction error';
  end;
end;

function TXcomBattleUnitKills.UnitSideString: string;
begin
  case FSide of
    XcomSideFront:
      Result := 'SIDE_FRONT';
    XcomSideLeft:
      Result := 'SIDE_LEFT';
    XcomSideRight:
      Result := 'SIDE_RIGHT';
    XcomSideRear:
      Result := 'SIDE_REAR';
    XcomSideUnder:
      Result := 'SIDE_UNDER';
  else
    Result := 'side error';
  end;
end;

function TXcomBattleUnitKills.UnitBodyPartString: string;
begin
  case FBodyPart of
    XcomBodyPartHead:
      Result := 'BODYPART_HEAD';
    XcomBodyPartTorso:
      Result := 'BODYPART_TORSO';
    XcomBodyPartRightArm:
      Result := 'BODYPART_RIGHTARM';
    XcomBodyPartLeftArm:
      Result := 'BODYPART_LEFTARM';
    XcomBodyPartRightLeg:
      Result := 'BODYPART_RIGHTLEG';
    XcomBodyPartLeftLeg:
      Result := 'BODYPART_LEFTLEG';
  else
    Result := 'body part error';
  end;
end;

end.
