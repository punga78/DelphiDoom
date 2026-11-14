{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - types of the game model                           }
{                                                                              }
{  Port of war1 (acoto87/war1), war_enums.h, war_math.h, war_entities.h and    }
{  war_units.h, (c) 2019 Alejandro Coto Gutierrez, zlib License (see           }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Types;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types;

const
  /// <summary>MAX_ENTITIES_COUNT of war.h: slot 0 is never used, ids are kept in 16 bits</summary>
  WAR_MODEL_MAX_ENTITIES = 1024;
  /// <summary>MAX_STATES_PER_TYPE of war_entities.h</summary>
  WAR_MODEL_MAX_STATES_PER_TYPE = 512;
  /// <summary>WAR_STATE_STACK_DEPTH of war.h</summary>
  WAR_MODEL_STATE_STACK_DEPTH = 4;
  /// <summary>The waypoints of a move or patrol state (the array of WarStateMove)</summary>
  WAR_MODEL_MAX_WAYPOINTS = 64;
  /// <summary>FRAMES_PER_SECONDS of war.h</summary>
  WAR_MODEL_FRAMES_PER_SECOND = 60;
  /// <summary>MOVE_EPSILON of war.h</summary>
  WAR_MODEL_MOVE_EPSILON = 0.5;
  /// <summary>NEAR_ENEMY_RADIUS of war.h: tiles</summary>
  WAR_MODEL_NEAR_ENEMY_RADIUS = 5;
  /// <summary>UNIT_MAX_CARRY_GOLD and UNIT_MAX_CARRY_WOOD of war.h</summary>
  WAR_MODEL_MAX_CARRY = 100;
  /// <summary>The player of the corpses (the neutral one)</summary>
  WAR_MODEL_CORPSE_PLAYER = 4;

  /// <summary>NEAR_CATAPULT_RADIUS of war.h: tiles of the splash of a catapult</summary>
  WAR_MODEL_NEAR_CATAPULT_RADIUS = 2;
  /// <summary>NEAR_RAIN_OF_FIRE_RADIUS of war.h: tiles of the splash of a rain of fire</summary>
  WAR_MODEL_NEAR_RAIN_OF_FIRE_RADIUS = 1;
  /// <summary>RAIN_OF_FIRE_PROJECTILE_DAMAGE of war.h</summary>
  WAR_MODEL_RAIN_OF_FIRE_DAMAGE = 10;
  /// <summary>GOD_MODE_MIN_DAMAGE of war_units.h</summary>
  WAR_MODEL_GOD_MODE_MIN_DAMAGE = 255;
  /// <summary>The pixels of a tile of the map (MEGA_TILE_WIDTH)</summary>
  WAR_MODEL_MEGA_TILE = 16;
  /// <summary>POISON_CLOUD_DAMAGE of war.h: what a poison cloud takes each second from who stands in it</summary>
  WAR_MODEL_POISON_CLOUD_DAMAGE = 10;
  /// <summary>MAX_SELECTED_ENTITIES_COUNT and MAX_SELECTION_GROUPS of war.h</summary>
  WAR_MODEL_MAX_SELECTED = 32;
  WAR_MODEL_SELECTION_GROUPS = 9;

  // The animations of war_animations.c (the name of the original: littleDamage, hugeDamage, collapse, explosion_x_y,
  // spell_x_y, poison_cloud_x_y)
  WAR_ANIMATION_NONE = 0;
  WAR_ANIMATION_LITTLE_DAMAGE = 1;
  WAR_ANIMATION_HUGE_DAMAGE = 2;
  WAR_ANIMATION_COLLAPSE = 3;
  WAR_ANIMATION_EXPLOSION = 4;
  WAR_ANIMATION_RAIN_OF_FIRE_EXPLOSION = 5;
  WAR_ANIMATION_SPELL = 6;
  WAR_ANIMATION_POISON_CLOUD = 7;

  // WarSpriteAnimationStatus
  WAR_ANIM_NOT_STARTED = 0;
  WAR_ANIM_RUNNING = 1;
  WAR_ANIM_FINISHED = 2;

  // WarUnitActionStepType
  WAR_ACTION_STEP_NONE = 0;
  WAR_ACTION_STEP_FRAME = 1;
  WAR_ACTION_STEP_WAIT = 2;
  WAR_ACTION_STEP_ATTACK = 3;
  WAR_ACTION_STEP_SOUND_SWORD = 4;
  WAR_ACTION_STEP_SOUND_FIST = 5;
  WAR_ACTION_STEP_SOUND_FIREBALL = 6;
  WAR_ACTION_STEP_SOUND_CHOPPING = 7;
  WAR_ACTION_STEP_SOUND_CATAPULT = 8;
  WAR_ACTION_STEP_SOUND_ARROW = 9;
  WAR_ACTION_STEP_SOUND_LIGHTNING = 10;

  // WarProjectileType
  WAR_PROJECTILE_ARROW = 0;
  WAR_PROJECTILE_CATAPULT = 1;
  WAR_PROJECTILE_FIREBALL = 2;
  WAR_PROJECTILE_FIREBALL_2 = 3;
  WAR_PROJECTILE_WATER_ELEMENTAL = 4;
  WAR_PROJECTILE_RAIN_OF_FIRE = 5;
  WAR_PROJECTILE_TYPE_COUNT = 6;

  // WarEntityType
  WAR_ENTITY_NONE = 0;
  WAR_ENTITY_IMAGE = 1;
  WAR_ENTITY_UNIT = 2;
  WAR_ENTITY_ROAD = 3;
  WAR_ENTITY_WALL = 4;
  WAR_ENTITY_RUIN = 5;
  WAR_ENTITY_FOREST = 6;
  WAR_ENTITY_TEXT = 7;
  WAR_ENTITY_RECT = 8;
  WAR_ENTITY_BUTTON = 9;
  WAR_ENTITY_CURSOR = 10;
  WAR_ENTITY_AUDIO = 11;
  WAR_ENTITY_PROJECTILE = 12;
  WAR_ENTITY_RAIN_OF_FIRE = 13;
  WAR_ENTITY_POISON_CLOUD = 14;
  WAR_ENTITY_SIGHT = 15;
  WAR_ENTITY_MINIMAP = 16;
  WAR_ENTITY_ANIMATION = 17;
  WAR_ENTITY_TYPE_COUNT = 18;

  // WarDirection
  WAR_DIRECTION_NORTH = 0;
  WAR_DIRECTION_NORTH_EAST = 1;
  WAR_DIRECTION_EAST = 2;
  WAR_DIRECTION_SOUTH_EAST = 3;
  WAR_DIRECTION_SOUTH = 4;
  WAR_DIRECTION_SOUTH_WEST = 5;
  WAR_DIRECTION_WEST = 6;
  WAR_DIRECTION_NORTH_WEST = 7;
  WAR_DIRECTION_COUNT = 8;

  // WarUnitActionType (the animation the unit plays)
  WAR_ACTION_NONE = -1;
  WAR_ACTION_IDLE = 0;
  WAR_ACTION_WALK = 1;
  WAR_ACTION_ATTACK = 2;
  WAR_ACTION_DEATH = 3;
  WAR_ACTION_HARVEST = 4;
  WAR_ACTION_REPAIR = 5;
  WAR_ACTION_BUILD = 6;
  WAR_ACTION_TYPE_COUNT = 7;

  // WarUnitActionStatus
  WAR_ACTION_NOT_STARTED = 0;
  WAR_ACTION_RUNNING = 1;
  WAR_ACTION_FINISHED = 2;

  // WarStateType: the order of the original (it is also the order in which the states update)
  WAR_STATE_NONE = -1;
  WAR_STATE_IDLE = 0;
  WAR_STATE_MOVE = 1;
  WAR_STATE_PATROL = 2;
  WAR_STATE_FOLLOW = 3;
  WAR_STATE_ATTACK = 4;
  WAR_STATE_GOLD = 5;
  WAR_STATE_MINING = 6;
  WAR_STATE_WOOD = 7;
  WAR_STATE_CHOPPING = 8;
  WAR_STATE_DELIVER = 9;
  WAR_STATE_DEATH = 10;
  WAR_STATE_COLLAPSE = 11;
  WAR_STATE_TRAIN = 12;
  WAR_STATE_UPGRADE = 13;
  WAR_STATE_BUILD = 14;
  WAR_STATE_REPAIR = 15;
  WAR_STATE_REPAIRING = 16;
  WAR_STATE_CAST = 17;
  WAR_STATE_WAIT = 18;
  WAR_STATE_COUNT = 19;

  // WarStateOp
  WAR_OP_NONE = 0;
  WAR_OP_PUSH = 1;
  WAR_OP_POP = 2;
  WAR_OP_REPLACE = 3;
  WAR_OP_RESET = 4;

  // WarStateResult
  WAR_RESULT_NONE = 0;
  WAR_RESULT_SUCCESS = 1;
  WAR_RESULT_CANCELLED = 2;
  WAR_RESULT_TARGET_INVALID = 3;
  WAR_RESULT_TARGET_HIDDEN = 4;
  WAR_RESULT_BLOCKED = 5;
  WAR_RESULT_NO_PATH = 6;
  WAR_RESULT_NO_RESOURCE = 7;
  WAR_RESULT_NO_DESTINATION = 8;
  WAR_RESULT_INTERRUPTED = 9;
  WAR_RESULT_CONTAINER_DESTROYED = 10;

  // WarTransitionCause: a higher cause replaces a lower one
  WAR_CAUSE_NONE = 0;
  WAR_CAUSE_INITIALIZATION = 10;
  WAR_CAUSE_COMPLETION = 20;
  WAR_CAUSE_AUTONOMOUS = 30;
  WAR_CAUSE_AI_ORDER = 40;
  WAR_CAUSE_PLAYER_ORDER = 50;
  WAR_CAUSE_STATUS = 60;
  WAR_CAUSE_SCRIPT = 70;
  WAR_CAUSE_LIFECYCLE = 80;

  // WarInterruptKind (bit masks)
  WAR_INTERRUPT_PLAYER_ORDER = 1;
  WAR_INTERRUPT_AI_ORDER = 2;
  WAR_INTERRUPT_AUTONOMOUS = 4;
  WAR_INTERRUPT_STATUS = 8;
  WAR_INTERRUPT_SCRIPT = 16;
  WAR_INTERRUPT_LIFECYCLE = 32;
  WAR_INTERRUPT_ALL = 63;

  // WarStateExitReason
  WAR_EXIT_COMPLETED = 0;
  WAR_EXIT_CANCELLED = 1;
  WAR_EXIT_REPLACED = 2;
  WAR_EXIT_RESET_BY_COMMAND = 3;
  WAR_EXIT_TARGET_INVALID = 4;
  WAR_EXIT_ENTITY_DIED = 5;
  WAR_EXIT_CONTAINER_DESTROYED = 6;
  WAR_EXIT_REMOVED = 7;
  WAR_EXIT_FAILED = 8;

  // WarStatePauseReason and WarStateResumeReason
  WAR_PAUSE_CHILD_PUSHED = 0;
  WAR_RESUME_CHILD_SUCCESS = 0;
  WAR_RESUME_CHILD_FAILURE = 1;

  // WarUpgradeType
  WAR_UPGRADE_ARROWS = 0;
  WAR_UPGRADE_SPEARS = 1;
  WAR_UPGRADE_SWORDS = 2;
  WAR_UPGRADE_AXES = 3;
  WAR_UPGRADE_HORSES = 4;
  WAR_UPGRADE_WOLVES = 5;
  WAR_UPGRADE_SCORPIONS = 6;
  WAR_UPGRADE_SPIDERS = 7;
  WAR_UPGRADE_RAIN_OF_FIRE = 8;
  WAR_UPGRADE_POISON_CLOUD = 9;
  WAR_UPGRADE_WATER_ELEMENTAL = 10;
  WAR_UPGRADE_DAEMON = 11;
  WAR_UPGRADE_HEALING = 12;
  WAR_UPGRADE_RAISE_DEAD = 13;
  WAR_UPGRADE_FAR_SIGHT = 14;
  WAR_UPGRADE_DARK_VISION = 15;
  WAR_UPGRADE_INVISIBILITY = 16;
  WAR_UPGRADE_UNHOLY_ARMOR = 17;
  WAR_UPGRADE_SHIELD = 18;
  WAR_UPGRADE_COUNT = 19;

  // WarSpellType
  WAR_SPELL_HEALING = 0;
  WAR_SPELL_FAR_SIGHT = 1;
  WAR_SPELL_INVISIBILITY = 2;
  WAR_SPELL_RAIN_OF_FIRE = 3;
  WAR_SPELL_POISON_CLOUD = 4;
  WAR_SPELL_RAISE_DEAD = 5;
  WAR_SPELL_DARK_VISION = 6;
  WAR_SPELL_UNHOLY_ARMOR = 7;
  WAR_SUMMON_SPIDER = 8;
  WAR_SUMMON_SCORPION = 9;
  WAR_SUMMON_DAEMON = 10;
  WAR_SUMMON_WATER_ELEMENTAL = 11;
  WAR_SPELL_COUNT = 12;

type
  /// <summary>vec2 of war_math.h: pixels of the map, 32 bit floats as in the original</summary>
  TWarVec2 = record
    X: Single;
    Y: Single;
  end;

  /// <summary>WarStateRef: a state of the storage by type, slot and generation (a freed slot makes old references invalid)</summary>
  TWarStateRef = record
    StateType: Integer;
    Index: Integer;
    Generation: Cardinal;
  end;

  /// <summary>WarTransitionRequest: the change of the stack of states that an entity asked for and that waits for the next tic</summary>
  TWarTransitionRequest = record
    StateRef: TWarStateRef;
    CancellationTargetRef: TWarStateRef;
    Operation: Integer;
    Result: Integer;
    Cause: Integer;
    Sequence: UInt64;
    Cancellation: Boolean;
  end;

  PWarTransitionRequest = ^TWarTransitionRequest;

  /// <summary>WarUnitAction: the state of one animation of a unit (the steps are the business of the actions, not done yet)</summary>
  TWarUnitAction = record
    Status: Integer;
    Scale: Single;
    WaitEndGameTime: Double;
    StepIndex: Integer;
    LastActionStep: Integer;
    LastSoundStep: Integer;
  end;

  /// <summary>
  ///   WarUnitComponent: everything that a unit, a building, a gold mine or a corpse has. The position in tiles is
  ///   the one of the creation (the original never updates it: the current tile is read from the transform)
  /// </summary>
  TWarUnitComponent = record
    UnitType: Integer;
    Direction: Integer;
    TileX: Integer;
    TileY: Integer;
    SizeX: Integer;
    SizeY: Integer;
    Player: Byte;
    ResourceKind: TWarResourceKind;
    Amount: Integer;
    Building: Boolean;
    BuildPercent: Single;
    MaxHp: Integer;
    Hp: Integer;
    MaxMana: Integer;
    Mana: Integer;
    Armor: Integer;
    Range: Integer;
    MinDamage: Integer;
    RndDamage: Integer;
    Decay: Integer;
    Invisible: Boolean;
    Invulnerable: Boolean;
    HasBeenSeen: Boolean;
    /// <summary>Index of the array of speeds of the unit (the upgrades of horses and wolves raise it)</summary>
    Speed: Integer;
    ActionType: Integer;
    Actions: array[0..WAR_ACTION_TYPE_COUNT - 1] of TWarUnitAction;
    ManaTime: Single;
    InvisibilityTime: Single;
    InvulnerabilityTime: Single;
    LastAttackSoundGameTime: Double;
  end;

  /// <summary>
  ///   WarProjectileComponent: an arrow, a fireball or a catapult stone that flies from where it was shot to where its
  ///   target was; the position is the transform of the entity. FrameIndex and FlipX are what the sprite component and
  ///   the scale of the transform of the original get from the direction and the distance already flown
  /// </summary>
  TWarProjectileComponent = record
    ProjectileType: Integer;
    SourceEntityId: Word;
    TargetEntityId: Word;
    Origin: TWarVec2;
    Target: TWarVec2;
    /// <summary>Pixels per second</summary>
    Speed: Integer;
    FrameIndex: Integer;
    FlipX: Boolean;
  end;

  /// <summary>
  ///   WarSpriteAnimation, as far as the model needs it: which animation it is (the name of the original), how long a
  ///   frame lasts, how many frames it has and how far it has gone (0..1). The sprite, the offset and the scale are the
  ///   business of whoever draws: Position is the point given to the wanim_create* of the original (the centre of the
  ///   effect; zero for the animations of a building)
  /// </summary>
  TWarAnimation = record
    Kind: Byte;
    Loop: Boolean;
    Status: Byte;
    FramesCount: Integer;
    FrameDelay: Single;
    AnimTime: Single;
    LoopTime: Single;
    LoopDelay: Single;
    Position: TWarVec2;
  end;

  PWarAnimation = ^TWarAnimation;

  /// <summary>WarStateMachineComponent: the stack of states (the last is the active one) and the request that waits</summary>
  TWarStateMachineComponent = record
    Stack: array[0..WAR_MODEL_STATE_STACK_DEPTH - 1] of TWarStateRef;
    Depth: Byte;
    Pending: TWarTransitionRequest;
    NextTransitionSequence: UInt64;
  end;

  /// <summary>
  ///   WarEntity with its components. The original keeps the components in dense arrays and the entity holds their
  ///   indexes; here the components that the model uses (transform, unit, state machine) are in the slot of the entity:
  ///   the order of the slots is the one of the original, which is what the order of the updates depends on
  /// </summary>
  TWarEntity = record
    /// <summary>0 means that the slot is free</summary>
    Id: Word;
    EntityType: Word;
    HasTransform: Boolean;
    HasUnit: Boolean;
    HasStateMachine: Boolean;
    HasProjectile: Boolean;
    /// <summary>WarAnimationsComponent: every unit has one; an entity of an effect (explosion, spell) gets one</summary>
    HasAnimations: Boolean;
    /// <summary>WarSightComponent (far sight, dark vision): SpellTile is the tile that is seen, SpellTime the seconds left</summary>
    HasSight: Boolean;
    /// <summary>WarPoisonCloudComponent: SpellTile, SpellTime and the seconds left to the next damage</summary>
    HasPoisonCloud: Boolean;
    SpellTile: TWarVec2;
    SpellTime: Single;
    SpellDamageTime: Single;
    /// <summary>
    ///   The list of the animations (the first AnimationCount items; the array only grows). It is the only managed field
    ///   of the record: an entity is never copied or cleared as raw memory
    /// </summary>
    AnimationCount: Integer;
    Animations: TArray<TWarAnimation>;
    /// <summary>
    ///   The sprite component, as far as the model needs it: whether the entity has one (a building under construction
    ///   swaps it), whether it is enabled, how many frames the image has and the frame that is shown. The image itself
    ///   is the business of whoever draws
    /// </summary>
    HasSprite: Boolean;
    SpriteEnabled: Boolean;
    /// <summary>
    ///   WarSpriteComponent.resourceIndex: the image shown (the one of the unit type, or the one a worker that carries gold
    ///   or wood has); 0 when the entity has no sprite
    /// </summary>
    SpriteResource: Integer;
    SpriteFrames: Integer;
    SpriteFrame: Integer;
    /// <summary>WarTransformComponent.scale.x: -1 when the unit looks to the west (the frames of the east are mirrored)</summary>
    ScaleX: Single;
    /// <summary>WarTransformComponent.position: the top left corner of the unit, in pixels of the map</summary>
    Position: TWarVec2;
    UnitData: TWarUnitComponent;
    StateMachine: TWarStateMachineComponent;
    Projectile: TWarProjectileComponent;
  end;

  PWarEntity = ^TWarEntity;
  PWarProjectileComponent = ^TWarProjectileComponent;
  PWarUnitComponent = ^TWarUnitComponent;
  PWarStateMachineComponent = ^TWarStateMachineComponent;

  PWarUpgradeState = ^TWarUpgradeState;

  /// <summary>The clock of the model, given from outside: the game time of the original context</summary>
  TWarGameClock = record
    /// <summary>gameTime: seconds</summary>
    GameTime: Double;
    /// <summary>gameDeltaTime: seconds of this tic</summary>
    DeltaTime: Single;
    /// <summary>globalSpeed (1 normal)</summary>
    GlobalSpeed: Single;
    /// <summary>settings.gameSpeed: 0 slowest, 2 normal, 4 fastest</summary>
    GameSpeed: Integer;
  end;

  /// <summary>The messages that the original flashes on the status bar</summary>
  TWarStatusMessage = (wsmNotEnoughGold, wsmNotEnoughLumber, wsmNotEnoughMana, wsmNotEnoughFood, wsmCantBuildThere);

resourcestring
  SWarModelEntityPoolFull = 'The entity pool is full (%d entities)';
  SWarModelNoUnitStats = 'The unit type %d has no statistics in the database';
  SWarModelNoBuildingStats = 'The building type %d has no statistics in the database';
  SWarModelNoUpgradeStats = 'The upgrade type %d has no statistics in the database';
  SWarModelNoSpellStats = 'The spell type %d has no statistics in the database';
  SWarModelNoUnitData = 'The unit type %d has no size in the tables of the game';
  SWarModelBadState = 'The state type %d does not exist';
  SWarModelNoUpgradeLeft = 'The upgrade %d is at its maximum level';
  SWarModelBadPlayer = 'The player %d does not exist';
  SWarModelBadEntity = 'The slot %d does not hold a unit';
  SWarModelNotRegistered = 'The model needs %s';
  SWarModelTooManyAnimations = 'The entity %d has too many animations';
  SWarModelSelectionGone = 'The selected entity %d does not exist any more';
  SWarModelBadCommand = 'The command %d is not known';
  SWarModelBadSelection = 'The command %d needs %s';
  SWarModelBadGroup = 'The selection group %d does not exist';
  SWarModelNoWallPiece = 'The wall has no piece at %d, %d';

implementation

end.
