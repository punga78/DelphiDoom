{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the commands of the spells                        }
{                                                                              }
{  Port of war1 (acoto87/war1), wcmd_executeSummonCommand and the              }
{  wcmd_execute*Command of the spells of war_commands.c, (c) 2019 Alejandro    }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Spells;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Commands.Family;

type
  /// <summary>
  ///   The spells as orders: the summons happen at once (no cast state), the others put the casters of the selection in
  ///   the cast state. Conjurers and warlocks summon, rain fire and poison; clerics and necrolytes heal, see far, make
  ///   invisible, give the unholy armor and raise the dead. Defects of the original kept: the caster is not asked to
  ///   belong to who gives the order (a selected enemy conjurer obeys), nor to be of the race of the spell (a conjurer
  ///   casts a poison cloud if told to), nor whether the spell has been researched (that is the business of the
  ///   buttons); a summon spends all the mana it can, one unit for each payment, and always ends with "not enough mana"
  /// </summary>
  TWarSpellCommands = class(TWarCommandFamily)
  strict private
    function CastAll(AClerics: Boolean; ASpellType: Integer; ATargetSlot: Integer; const ATarget: TWarVec2;
      ANotOnSelf: Boolean): Boolean;
    function DudeOrNone(ASlot: Integer): Boolean;
  public
    /// <summary>
    ///   wcmd_executeSummonCommand: ASpellType is WAR_SUMMON_*. A full pool stops the summon (the original would crash).
    ///   True if a unit was summoned
    /// </summary>
    function Summon(ASpellType: Integer): Boolean;
    /// <summary>wcmd_executeRainOfFireCommand and wcmd_executePoisonCloudCommand</summary>
    function RainOfFire(const ATarget: TWarVec2): Boolean;
    function PoisonCloud(const ATarget: TWarVec2): Boolean;
    /// <summary>wcmd_executeHealingCommand: nothing if the target is not a dude; a unit does not heal itself</summary>
    function Healing(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
    /// <summary>wcmd_executeInvisiblityCommand and wcmd_executeUnholyArmorCommand</summary>
    function Invisibility(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
    function UnholyArmor(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
    /// <summary>wcmd_executeRaiseDeadCommand</summary>
    function RaiseDead(const ATarget: TWarVec2): Boolean;
    /// <summary>wcmd_executeSightCommand: far sight for a human caster, dark vision for the others</summary>
    function Sight(const ATarget: TWarVec2): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Stats.Types,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.State.Cast, DelphiDoom.War.Model.Animations, DelphiDoom.War.Model.Commands.Types;

{ TWarSpellCommands }

function TWarSpellCommands.DudeOrNone(ASlot: Integer): Boolean;
begin
  Result := (ASlot <> 0) and Context.Pool.Slots[ASlot]^.HasUnit and
    TWarUnitClassifier.IsDude(Context.Pool.Slots[ASlot]^.UnitData.UnitType);
end;

function TWarSpellCommands.CastAll(AClerics: Boolean; ASpellType: Integer; ATargetSlot: Integer;
  const ATarget: TWarVec2; ANotOnSelf: Boolean): Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LIsCaster: Boolean;
  LSpell: Integer;
  LTargetId: Word;
begin
  Result := False;
  LTargetId := 0;
  if ATargetSlot <> 0 then
    LTargetId := Context.Pool.Slots[ATargetSlot]^.Id;
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    LEntity := Context.Pool.Slots[LSlot];
    if not LEntity^.HasUnit then
      Continue;
    if AClerics then
      LIsCaster := TWarUnitClassifier.IsClericOrNecrolyte(LEntity^.UnitData.UnitType)
    else
      LIsCaster := TWarUnitClassifier.IsConjurerOrWarlock(LEntity^.UnitData.UnitType);
    if not (LIsCaster and CanOrder(LSlot)) then
      Continue;
    if ANotOnSelf and (LSlot = ATargetSlot) then
      Continue;
    LSpell := ASpellType;
    // the sight is far sight for the humans and dark vision for the orcs
    if (LSpell = WAR_SPELL_FAR_SIGHT) and (TWarUnitClassifier.RaceOf(LEntity^.UnitData.UnitType) <> wraHumans) then
      LSpell := WAR_SPELL_DARK_VISION;
    Order(LSlot, TWarCastState.CreateState(Machine, LSlot, LSpell, LTargetId, ATarget));
    Result := True;
  end;
end;

function TWarSpellCommands.Summon(ASpellType: Integer): Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LStats: TWarSpellStats;
  LTile: TWarVec2;
  LSpawnX: Integer;
  LSpawnY: Integer;
  LSummoned: Integer;
  LUnit: PWarEntity;
begin
  Result := False;
  LStats := Context.Database.GetSpellStats(ASpellType);
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    LEntity := Context.Pool.Slots[LSlot];
    if not (LEntity^.HasUnit and TWarUnitClassifier.IsConjurerOrWarlock(LEntity^.UnitData.UnitType) and
      CanOrder(LSlot)) then
      Continue;
    // a unit that summons is not invisible any more
    LEntity^.UnitData.Invisible := False;
    LEntity^.UnitData.InvisibilityTime := 0;
    while Context.Combat.DecreaseMana(LSlot, LStats.ManaCost) do
    begin
      LTile := TWarUnitGeometry.CenterTile(LEntity);
      Context.Probe.FindEmptyTile(Trunc(LTile.X), Trunc(LTile.Y), LSpawnX, LSpawnY);
      LSummoned := Context.Entities.CreateUnit(LStats.MappedUnit, LSpawnX, LSpawnY, LEntity^.UnitData.Player, wrkNone,
        0, True);
      if LSummoned = 0 then
        Break;
      Context.Entities.SetInitialIdle(LSummoned);
      LUnit := Context.Pool.Slots[LSummoned];
      // the tile is taken at once, so that the next summoned unit of this order gets another one
      Context.Occupancy.SetStaticEntity(LSpawnX, LSpawnY, LUnit^.UnitData.SizeX, LUnit^.UnitData.SizeY, LUnit^.Id);
      TWarAnimations.SpawnSpellEffect(Context, TWarModelMath.TileToMap(TWarModelMath.Vec(LSpawnX, LSpawnY), True));
      Result := True;
    end;
  end;
  if Result then
    Context.ConstructionHost.PlaySound(WAR_SOUND_NORMAL_SPELL);
end;

function TWarSpellCommands.RainOfFire(const ATarget: TWarVec2): Boolean;
begin
  Result := CastAll(False, WAR_SPELL_RAIN_OF_FIRE, 0, ATarget, False);
end;

function TWarSpellCommands.PoisonCloud(const ATarget: TWarVec2): Boolean;
begin
  Result := CastAll(False, WAR_SPELL_POISON_CLOUD, 0, ATarget, False);
end;

function TWarSpellCommands.Healing(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
begin
  Result := DudeOrNone(ATargetSlot) and CastAll(True, WAR_SPELL_HEALING, ATargetSlot, ATarget, True);
end;

function TWarSpellCommands.Invisibility(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
begin
  Result := DudeOrNone(ATargetSlot) and CastAll(True, WAR_SPELL_INVISIBILITY, ATargetSlot, ATarget, False);
end;

function TWarSpellCommands.UnholyArmor(ATargetSlot: Integer; const ATarget: TWarVec2): Boolean;
begin
  Result := DudeOrNone(ATargetSlot) and CastAll(True, WAR_SPELL_UNHOLY_ARMOR, ATargetSlot, ATarget, False);
end;

function TWarSpellCommands.RaiseDead(const ATarget: TWarVec2): Boolean;
begin
  Result := CastAll(True, WAR_SPELL_RAISE_DEAD, 0, ATarget, False);
end;

function TWarSpellCommands.Sight(const ATarget: TWarVec2): Boolean;
begin
  Result := CastAll(True, WAR_SPELL_FAR_SIGHT, 0, ATarget, False);
end;

end.
