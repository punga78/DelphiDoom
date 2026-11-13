{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sounds of each event                          }
{                                                                              }
{  Port of the wa_create* calls of war1 (acoto87/war1), (c) 2019 Alejandro      }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sound.Table;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Types, DelphiDoom.War.Sound.Intf;

type
  /// <summary>
  ///   The table: for each event the sound, or the range the original picks from. The values are the ones of the
  ///   calls of the original (Tools\Verifica\198\war_sound_ref.c prints them from its code and Tests\Data\War has
  ///   the result)
  /// </summary>
  TWarSoundTable = class(TInterfacedObject, IWarSoundTable)
  strict private
    function Human(AEvent: TWarSoundEvent): TWarSoundChoice;
    function Orc(AEvent: TWarSoundEvent): TWarSoundChoice;
  public
    function Choice(AEvent: TWarSoundEvent; ARace: TWarRace): TWarSoundChoice;
    function RandomRanges: TArray<TWarSoundChoice>;
  end;

implementation

uses
  DelphiDoom.War.Sound.Ids;

{ TWarSoundTable }

function TWarSoundTable.Human(AEvent: TWarSoundEvent): TWarSoundChoice;
begin
  case AEvent of
    wseSelected: Result := TWarSoundChoice.Range(WAR_SND_HUMAN_SELECTED_FIRST, WAR_SND_HUMAN_SELECTED_LAST);
    wseAnnoyed: Result := TWarSoundChoice.Range(WAR_SND_HUMAN_ANNOYED_FIRST, WAR_SND_HUMAN_ANNOYED_LAST);
    wseAcknowledgement:
      Result := TWarSoundChoice.Range(WAR_SND_HUMAN_ACKNOWLEDGEMENT_FIRST, WAR_SND_HUMAN_ACKNOWLEDGEMENT_LAST);
    wseChurchOrTemple: Result := TWarSoundChoice.Fixed(WAR_SND_HUMAN_CHURCH);
    wseStableOrKennel: Result := TWarSoundChoice.Fixed(WAR_SND_HUMAN_STABLE);
    wseUnitDeath: Result := TWarSoundChoice.Fixed(WAR_SND_HUMAN_DEAD);
    wseWorkComplete: Result := TWarSoundChoice.Fixed(WAR_SND_HUMAN_WORK_COMPLETE);
    wseUnitReady: Result := TWarSoundChoice.Fixed(WAR_SND_HUMAN_READY);
    wseVictory: Result := TWarSoundChoice.Range(WAR_SND_HUMAN_VICTORY_FIRST, WAR_SND_HUMAN_VICTORY_LAST);
    wseDefeat: Result := TWarSoundChoice.Fixed(WAR_SND_HUMAN_DEFEAT);
  else
    Result := TWarSoundChoice.None;
  end;
end;

function TWarSoundTable.Orc(AEvent: TWarSoundEvent): TWarSoundChoice;
begin
  case AEvent of
    wseSelected: Result := TWarSoundChoice.Range(WAR_SND_ORC_SELECTED_FIRST, WAR_SND_ORC_SELECTED_LAST);
    wseAnnoyed: Result := TWarSoundChoice.Range(WAR_SND_ORC_ANNOYED_FIRST, WAR_SND_ORC_ANNOYED_LAST);
    wseAcknowledgement:
      Result := TWarSoundChoice.Range(WAR_SND_ORC_ACKNOWLEDGEMENT_FIRST, WAR_SND_ORC_ACKNOWLEDGEMENT_LAST);
    wseChurchOrTemple: Result := TWarSoundChoice.Fixed(WAR_SND_ORC_TEMPLE);
    wseStableOrKennel: Result := TWarSoundChoice.Fixed(WAR_SND_ORC_KENNEL);
    wseUnitDeath: Result := TWarSoundChoice.Fixed(WAR_SND_ORC_DEAD);
    wseWorkComplete: Result := TWarSoundChoice.Fixed(WAR_SND_ORC_WORK_COMPLETE);
    wseUnitReady: Result := TWarSoundChoice.Fixed(WAR_SND_ORC_READY);
    wseVictory: Result := TWarSoundChoice.Range(WAR_SND_ORC_VICTORY_FIRST, WAR_SND_ORC_VICTORY_LAST);
    wseDefeat: Result := TWarSoundChoice.Fixed(WAR_SND_ORC_DEFEAT);
  else
    Result := TWarSoundChoice.None;
  end;
end;

function TWarSoundTable.Choice(AEvent: TWarSoundEvent; ARace: TWarRace): TWarSoundChoice;
begin
  case AEvent of
    wseAttackSword: Result := TWarSoundChoice.Range(WAR_SND_SWORD_ATTACK_FIRST, WAR_SND_SWORD_ATTACK_LAST);
    wseAttackFist: Result := TWarSoundChoice.Fixed(WAR_SND_FIST_ATTACK);
    wseAttackFireball: Result := TWarSoundChoice.Fixed(WAR_SND_FIREBALL);
    wseAttackCatapult: Result := TWarSoundChoice.Fixed(WAR_SND_CATAPULT_ROCK_FIRED);
    wseAttackArrow: Result := TWarSoundChoice.Fixed(WAR_SND_ARROW_SPEAR);
    wseBuildingConstruction: Result := TWarSoundChoice.Fixed(WAR_SND_BUILDING);
    wseBuildingBurning: Result := TWarSoundChoice.Fixed(WAR_SND_FIRE_CRACKLING);
    wseBlacksmith: Result := TWarSoundChoice.Fixed(WAR_SND_BLACKSMITH);
    wseBuildingGeneric, wseUiClick: Result := TWarSoundChoice.Fixed(WAR_SND_UI_CLICK);
    wseSpiderOrScorpionDeath: Result := TWarSoundChoice.Fixed(WAR_SND_DEAD_SPIDER_SCORPION);
    wseCollapse: Result := TWarSoundChoice.Range(WAR_SND_BUILDING_COLLAPSE_FIRST, WAR_SND_BUILDING_COLLAPSE_LAST);
    wseTreeChopping: Result := TWarSoundChoice.Range(WAR_SND_TREE_CHOPPING_FIRST, WAR_SND_TREE_CHOPPING_LAST);
    wseSpell: Result := TWarSoundChoice.Fixed(WAR_SND_NORMAL_SPELL);
    wseBuildRoad: Result := TWarSoundChoice.Fixed(WAR_SND_BUILD_ROAD);
    wseUiCancel: Result := TWarSoundChoice.Fixed(WAR_SND_UI_CANCEL);
    wseCatapultExplosion: Result := TWarSoundChoice.Fixed(WAR_SND_CATAPULT_FIRE_EXPLOSION);
    wseArrowHit: Result := TWarSoundChoice.Fixed(WAR_SND_ARROW_SPEAR_HIT);
  else
    // isHumanPlayer is the only test of the original: whatever is not human is read as an orc
    if ARace = wraHumans then
      Result := Human(AEvent)
    else
      Result := Orc(AEvent);
  end;
end;

function TWarSoundTable.RandomRanges: TArray<TWarSoundChoice>;
var
  LEvent: TWarSoundEvent;
  LRace: TWarRace;
  LChoice: TWarSoundChoice;
  LKnown: Boolean;
  LIndex: Integer;
begin
  Result := nil;
  for LEvent := Low(TWarSoundEvent) to High(TWarSoundEvent) do
    for LRace := wraHumans to wraOrcs do
    begin
      LChoice := Choice(LEvent, LRace);
      if not LChoice.IsRandom then
        Continue;
      LKnown := False;
      for LIndex := 0 to High(Result) do
        if (Result[LIndex].First = LChoice.First) and (Result[LIndex].Last = LChoice.Last) then
          LKnown := True;
      if not LKnown then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := LChoice;
      end;
    end;
end;

end.
