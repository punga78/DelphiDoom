{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sound that a situation of the game plays      }
{                                                                              }
{  Port of wa_playAttackSound, wa_playDudeSelectionSound and                   }
{  wa_playBuildingSelectionSound of war_audio.c, war1 (acoto87/war1), (c) 2019  }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).      }
{  This is an altered version, not the original.                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sound.Picker;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Types, DelphiDoom.War.Sound.Intf;

type
  /// <summary>
  ///   Looks at a situation (the step of an attack, the unit that was selected, the state of a building) and
  ///   returns the sound that the original plays, taking the random number from the injected generator: the
  ///   same generator and the same calls give the same sounds. A range is picked as randomi(First, Last + 1) =
  ///   First + Below(Last + 1 - First)
  /// </summary>
  TWarSoundPicker = class(TInterfacedObject, IWarSoundPicker)
  strict private
    FTable: IWarSoundTable;
    FRandom: IWarRandom;
    function Resolve(const AChoice: TWarSoundChoice): Integer;
    class function HpPercent(AHp, AMaxHp: Integer): Integer; static;
  public
    constructor Create(const ATable: IWarSoundTable; const ARandom: IWarRandom);
    function Pick(AEvent: TWarSoundEvent; ARace: TWarRace): Integer;
    function AttackSound(AStep: TWarActionStep): Integer;
    function DudeSelectionSound(ARace: TWarRace; AIsTheOnlySelected: Boolean): Integer;
    function BuildingSelectionSound(const ABuilding: TWarBuildingSoundState): Integer;
    function DeathSound(AUnitType: Integer; ARace: TWarRace): Integer;
    function BriefingSound(ARace: TWarRace; AMission: Integer): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Sound.Ids;

const
  /// <summary>The percent of life under which a building crackles (hpPercent &lt;= 33)</summary>
  BURNING_PERCENT = 33;

{ TWarSoundPicker }

constructor TWarSoundPicker.Create(const ATable: IWarSoundTable; const ARandom: IWarRandom);
begin
  inherited Create;
  if not Assigned(ATable) or not Assigned(ARandom) then
    raise EWarException.Create('The table and the random generator of the sound picker cannot be nil');
  FTable := ATable;
  FRandom := ARandom;
end;

function TWarSoundPicker.Resolve(const AChoice: TWarSoundChoice): Integer;
begin
  if AChoice.IsNone then
    Result := WAR_SND_NONE
  else if AChoice.IsRandom then
    Result := AChoice.First + FRandom.Below(AChoice.Last + 1 - AChoice.First)
  else
    Result := AChoice.First;
end;

class function TWarSoundPicker.HpPercent(AHp, AMaxHp: Integer): Integer;
var
  LFraction: Single;
  LPercent: Single;
begin
  // PERCENTABI(a, b) = (s32)(((f32)a / b) * 100); a building without life points is not burning (the original divides by 0)
  if AMaxHp <= 0 then
    Exit(100);
  LFraction := AHp / AMaxHp;
  LPercent := LFraction * 100;
  Result := Trunc(LPercent);
end;

function TWarSoundPicker.Pick(AEvent: TWarSoundEvent; ARace: TWarRace): Integer;
begin
  Result := Resolve(FTable.Choice(AEvent, ARace));
end;

function TWarSoundPicker.AttackSound(AStep: TWarActionStep): Integer;
begin
  case AStep of
    wasSoundSword: Result := Pick(wseAttackSword, wraNeutral);
    wasSoundFist: Result := Pick(wseAttackFist, wraNeutral);
    wasSoundFireball: Result := Pick(wseAttackFireball, wraNeutral);
    wasSoundCatapult: Result := Pick(wseAttackCatapult, wraNeutral);
    wasSoundArrow: Result := Pick(wseAttackArrow, wraNeutral);
  else
    // the original logs a warning and plays nothing
    Result := WAR_SND_NONE;
  end;
end;

function TWarSoundPicker.DudeSelectionSound(ARace: TWarRace; AIsTheOnlySelected: Boolean): Integer;
begin
  if AIsTheOnlySelected then
    Result := Pick(wseAnnoyed, ARace)
  else
    Result := Pick(wseSelected, ARace);
end;

function TWarSoundPicker.BuildingSelectionSound(const ABuilding: TWarBuildingSoundState): Integer;
begin
  if ABuilding.UnderConstruction then
    Exit(Pick(wseBuildingConstruction, wraNeutral));
  if HpPercent(ABuilding.Hp, ABuilding.MaxHp) <= BURNING_PERCENT then
    Exit(Pick(wseBuildingBurning, wraNeutral));
  case ABuilding.UnitType of
    WAR_UNIT_CHURCH: Result := Pick(wseChurchOrTemple, wraHumans);
    WAR_UNIT_TEMPLE: Result := Pick(wseChurchOrTemple, wraOrcs);
    WAR_UNIT_STABLE: Result := Pick(wseStableOrKennel, wraHumans);
    WAR_UNIT_KENNEL: Result := Pick(wseStableOrKennel, wraOrcs);
    WAR_UNIT_BLACKSMITH_HUMANS, WAR_UNIT_BLACKSMITH_ORCS: Result := Pick(wseBlacksmith, wraNeutral);
  else
    Result := Pick(wseBuildingGeneric, wraNeutral);
  end;
end;

function TWarSoundPicker.DeathSound(AUnitType: Integer; ARace: TWarRace): Integer;
begin
  case AUnitType of
    WAR_UNIT_SCORPION, WAR_UNIT_SPIDER: Result := Pick(wseSpiderOrScorpionDeath, wraNeutral);
    WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS: Result := Pick(wseCollapse, wraNeutral);
  else
    Result := Pick(wseUnitDeath, ARace);
  end;
end;

function TWarSoundPicker.BriefingSound(ARace: TWarRace; AMission: Integer): Integer;
begin
  Result := WAR_SND_NONE;
  if (AMission < 1) or (AMission > 12) then
    Exit;
  if ARace = wraHumans then
    Result := WAR_SND_CAMPAIGNS_HUMAN_INTRO_FIRST + AMission - 1
  else if ARace = wraOrcs then
    Result := WAR_SND_CAMPAIGNS_ORC_INTRO_FIRST + AMission - 1;
end;

end.
