{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - tile, item and unit of the battle     }
{  (Tile, BattleItem, BattleUnit)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Model;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Convert,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapDataSet,
  DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.UnitStats,
  DelphiDoom.XcomMod.RulesetSettings, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.PositionCodec, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.BattleUnitStatistics,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf;

type
  TXcomBattleUnit = class;
  TXcomBattleItem = class;
  TXcomTile = class;

  /// <summary>
  ///   Tile::SerializationKey: how many bytes each field of a tile takes in the binary tile data of a saved
  ///   battle (the total includes the fields that are not named here)
  /// </summary>
  TXcomTileSerializationKey = record
    Index: Byte;
    MapDataSetId: Byte;
    MapDataId: Byte;
    Smoke: Byte;
    Fire: Byte;
    BoolFields: Byte;
    TotalBytes: Cardinal;
    /// <summary>Tile::serializationKey: 4, 2, 2, 1, 1, 1 and 4 + 8 + 8 + 3 bytes</summary>
    class function Current: TXcomTileSerializationKey; static;
  end;

  /// <summary>
  ///   An item of the battle: its rules, where it is (owner, tile, slot), ammo and fuse (BattleItem). The saved
  ///   battle owns the item; the unit, the tile and the weapon only refer to it
  /// </summary>
  TXcomBattleItem = class
  strict private
    FId: Integer;
    FRules: TXcomRuleItem;
    FOwner: TXcomBattleUnit;
    FPreviousOwner: TXcomBattleUnit;
    FUnit: TXcomBattleUnit;
    FTile: TXcomTile;
    FSlot: TXcomRuleInventory;
    FSlotX: Integer;
    FSlotY: Integer;
    FAmmoItem: TXcomBattleItem;
    FFuseTimer: Integer;
    FAmmoQuantity: Integer;
    FPainKiller: Integer;
    FHeal: Integer;
    FStimulant: Integer;
    FXcomProperty: Boolean;
    FDroppedOnAlienTurn: Boolean;
    FIsAmmo: Boolean;
  public
    /// <summary>
    ///   BattleItem(rules, int *id): takes AId as the id and adds one to it; a weapon that needs no ammo has
    ///   itself as ammo item. The rules may be nil (the C++ checks it)
    /// </summary>
    constructor Create(const ARules: TXcomRuleItem; var AId: Integer);
    /// <summary>load: the slot that the ruleset does not know is the ground</summary>
    procedure Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset);
    function Save: IYamlNode;
    /// <summary>getAmmoQuantity: 255 when the clip size is -1</summary>
    function AmmoQuantity: Integer;
    procedure SetAmmoQuantity(AValue: Integer);
    /// <summary>spendBullet: false when the clip is empty</summary>
    function SpendBullet: Boolean;
    /// <summary>setOwner: the old owner becomes the previous one</summary>
    procedure SetOwner(const AOwner: TXcomBattleUnit);
    /// <summary>moveToOwner: also moves it from the inventory of the previous owner to the one of the new</summary>
    procedure MoveToOwner(const AOwner: TXcomBattleUnit);
    /// <summary>occupiesSlot</summary>
    function OccupiesSlot(AX, AY: Integer; const AItem: TXcomBattleItem = nil): Boolean;
    /// <summary>needsAmmo: false for a weapon that is its own ammo</summary>
    function NeedsAmmo: Boolean;
    /// <summary>setAmmoItem: -2 when the ammo does not fit, -1 when the weapon already has ammo, else 0</summary>
    function SetAmmoItem(const AItem: TXcomBattleItem): Integer;
    /// <summary>convertToCorpse</summary>
    procedure ConvertToCorpse(const ARules: TXcomRuleItem);
    property Id: Integer read FId;
    property Rules: TXcomRuleItem read FRules;
    property Owner: TXcomBattleUnit read FOwner;
    property PreviousOwner: TXcomBattleUnit read FPreviousOwner write FPreviousOwner;
    /// <summary>getUnit: the unit of a corpse</summary>
    property CorpseUnit: TXcomBattleUnit read FUnit write FUnit;
    property Tile: TXcomTile read FTile write FTile;
    property Slot: TXcomRuleInventory read FSlot write FSlot;
    property SlotX: Integer read FSlotX write FSlotX;
    property SlotY: Integer read FSlotY write FSlotY;
    property AmmoItem: TXcomBattleItem read FAmmoItem;
    property FuseTimer: Integer read FFuseTimer write FFuseTimer;
    property HealQuantity: Integer read FHeal write FHeal;
    property PainKillerQuantity: Integer read FPainKiller write FPainKiller;
    property StimulantQuantity: Integer read FStimulant write FStimulant;
    property XcomProperty: Boolean read FXcomProperty write FXcomProperty;
    /// <summary>getTurnFlag: dropped on the turn of the aliens</summary>
    property TurnFlag: Boolean read FDroppedOnAlienTurn write FDroppedOnAlienTurn;
    property IsAmmo: Boolean read FIsAmmo write FIsAmmo;
  end;

  /// <summary>
  ///   The element of the map: four parts (floor, walls, object), the fire, the smoke, the light, the unit
  ///   and the items on it (Tile). The parts belong to their MapDataSet; the unit and the items belong to the
  ///   saved battle. The particles (a drawing effect) are not ported
  /// </summary>
  TXcomTile = class
  strict private
    FObjects: array[0..3] of TXcomMapData;
    FMapDataId: array[0..3] of Integer;
    FMapDataSetId: array[0..3] of Integer;
    FCurrentFrame: array[0..3] of Integer;
    FDiscovered: array[0..2] of Boolean;
    FLight: array[0..LIGHT_LAYERS - 1] of Integer;
    FLastLight: array[0..LIGHT_LAYERS - 1] of Integer;
    FSmoke: Integer;
    FFire: Integer;
    FExplosive: Integer;
    FExplosiveType: Integer;
    FPosition: TXcomPosition;
    FUnit: TXcomBattleUnit;
    FInventory: TList<TXcomBattleItem>;
    FAnimationOffset: Integer;
    FMarkerColor: Integer;
    FVisible: Integer;
    FPreview: Integer;
    FTuMarker: Integer;
    FOverlaps: Integer;
    FDanger: Boolean;
    FObstacle: Integer;
    FContext: IXcomBattleContext;
    function GetMapData(APart: Integer): TXcomMapData;
    function GetCurrentFrame(APart: Integer): Integer;
    procedure SetCurrentFrame(APart: Integer; AValue: Integer);
  public
    constructor Create(const APosition: TXcomPosition; const AContext: IXcomBattleContext);
    destructor Destroy; override;
    /// <summary>load of a tile in text; the animation offset (std::rand in the C++) is left at 0</summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>loadBinary: ABuffer is the data of the tile, starting at AOffset after the index</summary>
    procedure LoadBinary(const ABuffer: TBytes; AOffset: Integer; const AKey: TXcomTileSerializationKey);
    function Save: IYamlNode;
    /// <summary>saveBinary: appends the tile at AOffset, which moves past it</summary>
    procedure SaveBinary(var ABuffer: TBytes; var AOffset: Integer);
    /// <summary>setMapData</summary>
    procedure SetMapData(const AData: TXcomMapData; AMapDataId, AMapDataSetId, APart: Integer);
    /// <summary>getMapData(int*, int*, part)</summary>
    procedure GetMapDataIds(out AMapDataId, AMapDataSetId: Integer; APart: Integer);
    function IsVoid: Boolean;
    function GetTuCost(APart, AMovementType: Integer): Integer;
    function HasNoFloor(const ATileBelow: TXcomTile): Boolean;
    function IsBigWall: Boolean;
    function GetTerrainLevel: Integer;
    function GetFootstepSound(const ATileBelow: TXcomTile): Integer;
    /// <summary>openDoor: 0 normal door, 1 ufo door, 3 still opening, 4 not enough time units, -1 none</summary>
    function OpenDoor(APart: Integer; const AUnit: TXcomBattleUnit = nil; AReserve: Integer = BA_NONE): Integer;
    function IsUfoDoorOpen(APart: Integer): Boolean;
    function CloseUfoDoor: Integer;
    procedure SetDiscovered(AFlag: Boolean; APart: Integer);
    function IsDiscovered(APart: Integer): Boolean;
    procedure ResetLight(ALayer: Integer);
    procedure AddLight(ALight, ALayer: Integer);
    function GetShade: Integer;
    /// <summary>
    ///   destroy: AScorchedEarth is MapDataSet::getScorchedEarthTile (a static in the C++), used when the floor
    ///   of the lowest level is gone
    /// </summary>
    function DestroyPart(APart, AType: Integer; const AScorchedEarth: TXcomMapData): Boolean;
    function Damage(APart, APower, AType: Integer; const AScorchedEarth: TXcomMapData): Boolean;
    procedure SetExplosive(APower, ADamageType: Integer; AForce: Boolean = False);
    function GetFlammability: Integer; overload;
    function GetFuel: Integer; overload;
    function GetFlammability(APart: Integer): Integer; overload;
    function GetFuel(APart: Integer): Integer; overload;
    procedure Ignite(APower: Integer);
    procedure Animate;
    procedure SetUnit(const AUnit: TXcomBattleUnit; const ATileBelow: TXcomTile = nil);
    procedure SetFire(AFire: Integer);
    procedure AddSmoke(ASmoke: Integer);
    procedure SetSmoke(ASmoke: Integer);
    procedure AddItem(const AItem: TXcomBattleItem; const AGround: TXcomRuleInventory);
    procedure RemoveItem(const AItem: TXcomBattleItem);
    function GetTopItemSprite: Integer;
    procedure PrepareNewTurn(ASmokeDamage: Boolean);
    procedure SetVisible(AVisibility: Integer);
    procedure AddOverlap;
    procedure SetObstacle(APart: Integer);
    function GetObstacle(APart: Integer): Boolean;
    function IsObstacle: Boolean;
    procedure ResetObstacle;
    property MapData[APart: Integer]: TXcomMapData read GetMapData;
    /// <summary>
    ///   The frame of animation of a part (the sprite of the part is GetSprite(CurrentFrame)). It is writable only for
    ///   the tests: the timer of the real game that moves it is not deterministic.
    /// </summary>
    property CurrentFrame[APart: Integer]: Integer read GetCurrentFrame write SetCurrentFrame;
    property Position: TXcomPosition read FPosition;
    property CurrentUnit: TXcomBattleUnit read FUnit;
    property Inventory: TList<TXcomBattleItem> read FInventory;
    property Fire: Integer read FFire;
    property Smoke: Integer read FSmoke;
    property Explosive: Integer read FExplosive;
    property ExplosiveType: Integer read FExplosiveType;
    property AnimationOffset: Integer read FAnimationOffset;
    property MarkerColor: Integer read FMarkerColor write FMarkerColor;
    property Visible: Integer read FVisible;
    property Preview: Integer read FPreview write FPreview;
    property TuMarker: Integer read FTuMarker write FTuMarker;
    property Overlaps: Integer read FOverlaps;
    property Dangerous: Boolean read FDanger write FDanger;
  end;

  /// <summary>
  ///   A moving unit of the battle, soldier or alien or civilian (BattleUnit): position, direction, stats,
  ///   armor, wounds, morale, inventory, experience. The drawing cache and the sprite recolor of the C++ are
  ///   kept as data only; the AI module is an interface the saved battle gives
  /// </summary>
  TXcomBattleUnit = class
  strict private
    FFaction: Integer;
    FOriginalFaction: Integer;
    FKilledBy: Integer;
    FId: Integer;
    FPosition: TXcomPosition;
    FTile: TXcomTile;
    FLastPosition: TXcomPosition;
    FDirection: Integer;
    FToDirection: Integer;
    FDirectionTurret: Integer;
    FToDirectionTurret: Integer;
    FVerticalDirection: Integer;
    FDestination: TXcomPosition;
    FStatus: Integer;
    FWalkPhase: Integer;
    FFallPhase: Integer;
    FVisibleUnits: TList<TXcomBattleUnit>;
    FUnitsSpottedThisTurn: TList<TXcomBattleUnit>;
    FVisibleTiles: TList<TXcomTile>;
    FTimeUnits: Integer;
    FEnergy: Integer;
    FHealth: Integer;
    FMorale: Integer;
    FStunLevel: Integer;
    FKneeled: Boolean;
    FFloating: Boolean;
    FDontReselect: Boolean;
    FCurrentArmor: array[0..4] of Integer;
    FMaxArmor: array[0..4] of Integer;
    FFatalWounds: array[0..5] of Integer;
    FFire: Integer;
    FInventory: TList<TXcomBattleItem>;
    FSpecialWeapons: array[0..SPEC_WEAPON_MAX - 1] of TXcomBattleItem;
    FAI: IXcomUnitAI;
    FVisible: Boolean;
    FCacheInvalid: Boolean;
    FExpBravery: Integer;
    FExpReactions: Integer;
    FExpFiring: Integer;
    FExpThrowing: Integer;
    FExpPsiSkill: Integer;
    FExpPsiStrength: Integer;
    FExpMelee: Integer;
    FMotionPoints: Integer;
    FKills: Integer;
    FFaceDirection: Integer;
    FHitByFire: Boolean;
    FHitByAnything: Boolean;
    FMoraleRestored: Integer;
    FCharging: TXcomBattleUnit;
    FTurnsSinceSpotted: Integer;
    FSpawnUnit: string;
    FActiveHand: string;
    FStatistics: TXcomBattleUnitStatistics;
    FMurdererId: Integer;
    FMindControllerId: Integer;
    FFatalShotSide: Integer;
    FFatalShotBodyPart: Integer;
    FMurdererWeapon: string;
    FMurdererWeaponAmmo: string;
    FType: string;
    FRank: string;
    FRace: string;
    FName: string;
    FStats: TXcomUnitStats;
    FStandHeight: Integer;
    FKneelHeight: Integer;
    FFloatHeight: Integer;
    FDeathSound: TArray<Integer>;
    FValue: Integer;
    FAggroSound: Integer;
    FMoveSound: Integer;
    FIntelligence: Integer;
    FAggression: Integer;
    FSpecialAbility: Integer;
    FArmor: TXcomArmor;
    FGender: Integer;
    FGeoscapeSoldier: TXcomSoldier;
    FLoftempsSet: TArray<Integer>;
    FUnitRules: TXcomRuleUnit;
    FRankInt: Integer;
    FTurretType: Integer;
    FBreathFrame: Integer;
    FBreathing: Boolean;
    FHidingForTurn: Boolean;
    FFloorAbove: Boolean;
    FRespawn: Boolean;
    FMovementType: Integer;
    FRecolor: TArray<TPair<Integer, Integer>>;
    FCapturable: Boolean;
    FLastCover: TXcomPosition;
    FContext: IXcomBattleContext;
    procedure ResolveMovementType(ADepth: Integer);
    procedure SetRecolor(ABasicLook, AUtileLook, ARankLook: Integer);
    function ImproveStat(AExperience: Integer): Integer;
    procedure CommonInit;
  public
    /// <summary>BattleUnit(Soldier*, depth)</summary>
    constructor Create(const AContext: IXcomBattleContext; const ASoldier: TXcomSoldier; ADepth: Integer);
      overload;
    /// <summary>
    ///   BattleUnit(Unit*, faction, id, armor, adjustment, depth). The look of the sprite (std::rand in the C++,
    ///   cosmetic) is chosen by AColors: the three values basic, utile and rank
    /// </summary>
    constructor Create(const AContext: IXcomBattleContext; const AUnit: TXcomRuleUnit; AFaction, AId: Integer;
      const AArmor: TXcomArmor; const AAdjustment: TXcomStatAdjustment; ADepth: Integer;
      ABasicLook: Integer = 0; AUtileLook: Integer = 0; ARankLook: Integer = -1); overload;
    destructor Destroy; override;
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    procedure SetPosition(const APosition: TXcomPosition; AUpdateLastPosition: Boolean = True);
    procedure SetDirection(ADirection: Integer);
    procedure StartWalking(ADirection: Integer; const ADestination: TXcomPosition; const ATileBelow: TXcomTile;
      ACache: Boolean);
    procedure KeepWalking(const ATileBelow: TXcomTile; ACache: Boolean);
    function WalkingPhase: Integer;
    function DiagonalWalkingPhase: Integer;
    procedure LookAt(const APoint: TXcomPosition; ATurret: Boolean = False); overload;
    procedure LookAt(ADirection: Integer; AForce: Boolean = False); overload;
    procedure Turn(ATurret: Boolean = False);
    procedure AbortTurn;
    procedure Kneel(AKneeled: Boolean);
    procedure Aim(AAiming: Boolean);
    function DirectionTo(const APoint: TXcomPosition): Integer;
    /// <summary>damage: the damage done after the adjustments</summary>
    function Damage(const ARelative: TXcomPosition; APower, AType: Integer; AIgnoreArmor: Boolean = False)
      : Integer;
    procedure HealStun(APower: Integer);
    /// <summary>knockOut for a unit with no spawn unit: the stun level becomes the health</summary>
    procedure KnockOut;
    procedure StartFalling;
    procedure KeepFalling;
    function IsOut: Boolean;
    function GetActionTus(AActionType: Integer; const AItem: TXcomBattleItem): Integer; overload;
    function GetActionTus(AActionType: Integer; const AItem: TXcomRuleItem): Integer; overload;
    function SpendTimeUnits(ATimeUnits: Integer): Boolean;
    function SpendEnergy(ATimeUnits: Integer): Boolean;
    procedure SetTimeUnits(ATimeUnits: Integer);
    function AddToVisibleUnits(const AUnit: TXcomBattleUnit): Boolean;
    procedure ClearVisibleUnits;
    function AddToVisibleTiles(const ATile: TXcomTile): Boolean;
    procedure ClearVisibleTiles;
    function GetFiringAccuracy(AActionType: Integer; const AItem: TXcomBattleItem): Integer;
    function GetAccuracyModifier(const AItem: TXcomBattleItem = nil): Integer;
    function GetThrowingAccuracy: Double;
    procedure SetArmor(AArmor, ASide: Integer);
    function GetArmor(ASide: Integer): Integer;
    function GetMaxArmor(ASide: Integer): Integer;
    function GetFatalWounds: Integer;
    function GetFatalWound(APart: Integer): Integer;
    function GetReactionScore: Double;
    procedure PrepareNewTurn(AFullProcess: Boolean = True);
    procedure MoraleChange(AChange: Integer);
    procedure SetFire(AFire: Integer);
    procedure SetTile(const ATile: TXcomTile; const ATileBelow: TXcomTile = nil);
    function GetItem(const ASlot: TXcomRuleInventory; AX: Integer = 0; AY: Integer = 0): TXcomBattleItem;
      overload;
    function GetItem(const ASlot: string; AX: Integer = 0; AY: Integer = 0): TXcomBattleItem; overload;
    function GetMainHandWeapon(AQuickest: Boolean = True): TXcomBattleItem;
    function GetGrenadeFromBelt: TXcomBattleItem;
    function CheckAmmo: Boolean;
    function IsInExitArea(AType: Integer = 1): Boolean;
    function LiesInExitArea(const ATile: TXcomTile; AType: Integer = 1): Boolean;
    function GetHeight: Integer;
    procedure AddReactionExp;
    procedure AddFiringExp;
    procedure AddThrowingExp;
    procedure AddPsiSkillExp;
    procedure AddPsiStrengthExp;
    procedure AddMeleeExp;
    /// <summary>postMissionProcedures: the soldier of the saved game improves; true when promoted or improved</summary>
    function PostMissionProcedures(const ASoldier: TXcomSoldier; var AStatsDiff: TXcomUnitStats): Boolean;
    function GetMiniMapSpriteIndex: Integer;
    procedure Heal(APart, AWoundAmount, AHealthAmount: Integer);
    procedure PainKillers;
    procedure Stimulant(AEnergy, AStun: Integer);
    /// <summary>getName without a language: the name of a soldier, else the translated type or race</summary>
    function DisplayName(const ATranslate: TFunc<string, string>; ADebugAppendId: Boolean = False): string;
    function GetLoftemps(AEntry: Integer = 0): Integer;
    function DeathSounds: TArray<Integer>;
    function IsWoundable: Boolean;
    function IsFearable: Boolean;
    procedure AddKillCount;
    function GetActiveHand: string;
    procedure ConvertToFaction(AFaction: Integer);
    procedure Kill;
    procedure InstaKill;
    function GetCarriedWeight(const ADraggingItem: TXcomBattleItem = nil): Integer;
    procedure DeriveRank;
    function CheckViewSector(const APosition: TXcomPosition): Boolean;
    procedure AdjustStats(const AAdjustment: TXcomStatAdjustment);
    function HasInventory: Boolean;
    function IsSelectable(AFaction: Integer; ACheckReselect, ACheckInventory: Boolean): Boolean;
    function GetMeleeWeapon: TXcomBattleItem;
    procedure GoToTimeOut;
    /// <summary>
    ///   setSpecialWeapon: the weapons that are outside the inventory (melee, armor weapon, psi); AMake creates
    ///   the item (the saved battle owns it)
    /// </summary>
    procedure SetSpecialWeapon(const ARuleset: TXcomRuleset;
      const AMake: TFunc<TXcomRuleItem, TXcomBattleItem>);
    function GetSpecialWeapon(ABattleType: Integer): TXcomBattleItem;
    procedure RecoverTimeUnits;
    procedure SetFatalShotInfo(ASide, ABodyPart: Integer);
    procedure NerfFiringXp(ANewXp: Integer);
    procedure ResetHitState;
    /// <summary>toggleFireDamage: switches the "took fire damage this turn" flag</summary>
    procedure ToggleFireDamage;
    /// <summary>getVisible: a unit of the player is always visible, the others as the visible flag says</summary>
    function GetVisible: Boolean;
    /// <summary>
    ///   breathe: the bubbles of a unit under water. Now and then (more often with a low morale) a cycle of 16 frames
    ///   starts; a unit that walks or is out makes none. ARoll is RNG::seedless(0, 99): it only decides the look
    /// </summary>
    procedure Breathe(ARoll: Integer);
    /// <summary>getBreathFrame: 0 no bubbles, 1..16 the frame of BREATH-1.PCK plus one; -1 a unit that never breathes</summary>
    property BreathFrame: Integer read FBreathFrame;
    procedure FreePatrolTarget;
    property Id: Integer read FId;
    property Position: TXcomPosition read FPosition;
    property LastPosition: TXcomPosition read FLastPosition;
    property Destination: TXcomPosition read FDestination;
    property Direction: Integer read FDirection;
    property ToDirection: Integer read FToDirection;
    property TurretDirection: Integer read FDirectionTurret;
    property TurretToDirection: Integer read FToDirectionTurret;
    property VerticalDirection: Integer read FVerticalDirection;
    property FaceDirection: Integer read FFaceDirection write FFaceDirection;
    property Status: Integer read FStatus;
    property Faction: Integer read FFaction;
    property OriginalFaction: Integer read FOriginalFaction;
    property KilledBy: Integer read FKilledBy write FKilledBy;
    property TimeUnits: Integer read FTimeUnits;
    property Energy: Integer read FEnergy;
    property Health: Integer read FHealth;
    property Morale: Integer read FMorale;
    property StunLevel: Integer read FStunLevel;
    property IsKneeled: Boolean read FKneeled;
    property IsFloating: Boolean read FFloating;
    property Fire: Integer read FFire;
    property Inventory: TList<TXcomBattleItem> read FInventory;
    property VisibleUnits: TList<TXcomBattleUnit> read FVisibleUnits;
    property UnitsSpottedThisTurn: TList<TXcomBattleUnit> read FUnitsSpottedThisTurn;
    property VisibleTiles: TList<TXcomTile> read FVisibleTiles;
    property AI: IXcomUnitAI read FAI write FAI;
    property Visible: Boolean read FVisible write FVisible;
    property Tile: TXcomTile read FTile;
    property Armor: TXcomArmor read FArmor;
    property Stats: TXcomUnitStats read FStats write FStats;
    property StandHeight: Integer read FStandHeight;
    property KneelHeight: Integer read FKneelHeight;
    property FloatHeight: Integer read FFloatHeight;
    property Value: Integer read FValue;
    property MoveSound: Integer read FMoveSound;
    property AggroSound: Integer read FAggroSound;
    property Intelligence: Integer read FIntelligence;
    property Aggression: Integer read FAggression;
    property SpecialAbility: Integer read FSpecialAbility;
    property Respawn: Boolean read FRespawn write FRespawn;
    property RankString: string read FRank;
    property GeoscapeSoldier: TXcomSoldier read FGeoscapeSoldier;
    property UnitType: string read FType;
    property Race: string read FRace;
    property ActiveHandSlot: string read FActiveHand write FActiveHand;
    property SpawnUnit: string read FSpawnUnit write FSpawnUnit;
    property Charging: TXcomBattleUnit read FCharging write FCharging;
    property TurnsSinceSpotted: Integer read FTurnsSinceSpotted write FTurnsSinceSpotted;
    property RankInt: Integer read FRankInt write FRankInt;
    property TurretType: Integer read FTurretType write FTurretType;
    property MovementType: Integer read FMovementType;
    property IsHiding: Boolean read FHidingForTurn write FHidingForTurn;
    property Statistics: TXcomBattleUnitStatistics read FStatistics;
    property MurdererId: Integer read FMurdererId write FMurdererId;
    property MurdererWeapon: string read FMurdererWeapon write FMurdererWeapon;
    property MurdererWeaponAmmo: string read FMurdererWeaponAmmo write FMurdererWeaponAmmo;
    property MindControllerId: Integer read FMindControllerId write FMindControllerId;
    property FatalShotSide: Integer read FFatalShotSide;
    property FatalShotBodyPart: Integer read FFatalShotBodyPart;
    property FiringXp: Integer read FExpFiring;
    /// <summary>getHitState: the unit was hit by anything since the last reset</summary>
    property HitState: Boolean read FHitByAnything;
    property Capturable: Boolean read FCapturable;
    property UnitRules: TXcomRuleUnit read FUnitRules;
    property MotionPoints: Integer read FMotionPoints;
    property Gender: Integer read FGender;
    property Kills: Integer read FKills;
    property DontReselect: Boolean read FDontReselect write FDontReselect;
    property TookFireDamage: Boolean read FHitByFire;
    property FloorAbove: Boolean read FFloorAbove write FFloorAbove;
    property LastCover: TXcomPosition read FLastCover write FLastCover;
    property RecolorPairs: TArray<TPair<Integer, Integer>> read FRecolor;
    property CacheInvalid: Boolean read FCacheInvalid write FCacheInvalid;
    property ExpBravery: Integer read FExpBravery;
    property ExpReactions: Integer read FExpReactions;
    property ExpFiring: Integer read FExpFiring;
    property ExpThrowing: Integer read FExpThrowing;
    property ExpPsiSkill: Integer read FExpPsiSkill;
    property ExpPsiStrength: Integer read FExpPsiStrength;
    property ExpMelee: Integer read FExpMelee;
    /// <summary>getFallingPhase: the frame of the death animation</summary>
    property FallingPhase: Integer read FFallPhase;
  end;

implementation

const
  // the floating point constants of BattleUnit::directionTo (M_PI_4 is a double)
  PI_QUARTER: Double = 0.78539816339744830962;

{ TXcomTileSerializationKey }

class function TXcomTileSerializationKey.Current: TXcomTileSerializationKey;
begin
  Result.Index := 4;
  Result.MapDataSetId := 2;
  Result.MapDataId := 2;
  Result.Smoke := 1;
  Result.Fire := 1;
  Result.BoolFields := 1;
  Result.TotalBytes := 4 + 2 * 4 + 2 * 4 + 1 + 1 + 1;
end;

{ TXcomBattleItem }

constructor TXcomBattleItem.Create(const ARules: TXcomRuleItem; var AId: Integer);
begin
  inherited Create;
  FId := AId;
  FRules := ARules;
  FFuseTimer := -1;
  Inc(AId);
  if Assigned(FRules) then
  begin
    FAmmoQuantity := FRules.ClipSize;
    if FRules.BattleType = TXcomRuleItem.BT_MEDIKIT then
    begin
      FHeal := FRules.Heal;
      FPainKiller := FRules.PainKiller;
      FStimulant := FRules.Stimulant;
    end
    else if ((FRules.BattleType = TXcomRuleItem.BT_FIREARM) or (FRules.BattleType = TXcomRuleItem.BT_MELEE))
      and (Length(FRules.CompatibleAmmo) = 0) then
      FAmmoItem := Self;
  end;
end;

procedure TXcomBattleItem.Load(const ANode: IYamlNode; const ARuleset: TXcomRuleset);
var
  LSlotName: string;
  LSlot: TXcomRuleInventory;
begin
  LSlotName := TXcomNodeReader.ReadString(ANode, 'inventoryslot', 'NULL');
  if LSlotName <> 'NULL' then
  begin
    LSlot := ARuleset.Inventories.Find(LSlotName);
    if Assigned(LSlot) then
      FSlot := LSlot
    else
      FSlot := ARuleset.Inventories.Find('STR_GROUND');
  end;
  FSlotX := TXcomNodeReader.ReadInteger(ANode, 'inventoryX', FSlotX);
  FSlotY := TXcomNodeReader.ReadInteger(ANode, 'inventoryY', FSlotY);
  FAmmoQuantity := TXcomNodeReader.ReadInteger(ANode, 'ammoqty', FAmmoQuantity);
  FPainKiller := TXcomNodeReader.ReadInteger(ANode, 'painKiller', FPainKiller);
  FHeal := TXcomNodeReader.ReadInteger(ANode, 'heal', FHeal);
  FStimulant := TXcomNodeReader.ReadInteger(ANode, 'stimulant', FStimulant);
  FFuseTimer := TXcomNodeReader.ReadInteger(ANode, 'fuseTimer', FFuseTimer);
  FDroppedOnAlienTurn := TXcomNodeReader.ReadBoolean(ANode, 'droppedOnAlienTurn', FDroppedOnAlienTurn);
  FXcomProperty := TXcomNodeReader.ReadBoolean(ANode, 'XCOMProperty', FXcomProperty);
end;

function TXcomBattleItem.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'id', FId);
  TXcomNodeWriter.SetString(Result, 'type', FRules.ItemType);
  if Assigned(FOwner) then
    TXcomNodeWriter.SetInteger(Result, 'owner', FOwner.Id);
  if Assigned(FPreviousOwner) then
    TXcomNodeWriter.SetInteger(Result, 'previousOwner', FPreviousOwner.Id);
  if Assigned(FUnit) then
    TXcomNodeWriter.SetInteger(Result, 'unit', FUnit.Id);
  if Assigned(FSlot) then
    TXcomNodeWriter.SetString(Result, 'inventoryslot', FSlot.Id);
  TXcomNodeWriter.SetInteger(Result, 'inventoryX', FSlotX);
  TXcomNodeWriter.SetInteger(Result, 'inventoryY', FSlotY);
  if Assigned(FTile) then
    TXcomPositionCodec.Write(Result, 'position', FTile.Position);
  if FAmmoQuantity <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'ammoqty', FAmmoQuantity);
  if Assigned(FAmmoItem) then
    TXcomNodeWriter.SetInteger(Result, 'ammoItem', FAmmoItem.Id);
  if Assigned(FRules) and (FRules.BattleType = TXcomRuleItem.BT_MEDIKIT) then
  begin
    TXcomNodeWriter.SetInteger(Result, 'painKiller', FPainKiller);
    TXcomNodeWriter.SetInteger(Result, 'heal', FHeal);
    TXcomNodeWriter.SetInteger(Result, 'stimulant', FStimulant);
  end;
  if FFuseTimer <> -1 then
    TXcomNodeWriter.SetInteger(Result, 'fuseTimer', FFuseTimer);
  if FDroppedOnAlienTurn then
    TXcomNodeWriter.SetBoolean(Result, 'droppedOnAlienTurn', FDroppedOnAlienTurn);
  if FXcomProperty then
    TXcomNodeWriter.SetBoolean(Result, 'XCOMProperty', FXcomProperty);
end;

function TXcomBattleItem.AmmoQuantity: Integer;
begin
  if FRules.ClipSize = -1 then
    Exit(255);
  Result := FAmmoQuantity;
end;

procedure TXcomBattleItem.SetAmmoQuantity(AValue: Integer);
begin
  FAmmoQuantity := AValue;
end;

function TXcomBattleItem.SpendBullet: Boolean;
begin
  if FAmmoQuantity > 0 then
    Dec(FAmmoQuantity);
  Result := FAmmoQuantity <> 0;
end;

procedure TXcomBattleItem.SetOwner(const AOwner: TXcomBattleUnit);
begin
  FPreviousOwner := FOwner;
  FOwner := AOwner;
end;

procedure TXcomBattleItem.MoveToOwner(const AOwner: TXcomBattleUnit);
begin
  if Assigned(FOwner) then
    FPreviousOwner := FOwner
  else
    FPreviousOwner := AOwner;
  FOwner := AOwner;
  if Assigned(FPreviousOwner) then
    FPreviousOwner.Inventory.Remove(Self);
  if Assigned(FOwner) then
    FOwner.Inventory.Add(Self);
end;

function TXcomBattleItem.OccupiesSlot(AX, AY: Integer; const AItem: TXcomBattleItem): Boolean;
begin
  if AItem = Self then
    Exit(False);
  if FSlot.InventoryType = INV_HAND then
    Exit(True);
  if not Assigned(AItem) then
    Exit((AX >= FSlotX) and (AX < FSlotX + FRules.InventoryWidth) and (AY >= FSlotY) and
      (AY < FSlotY + FRules.InventoryHeight));
  Result := not ((AX >= FSlotX + FRules.InventoryWidth) or (AX + AItem.Rules.InventoryWidth <= FSlotX) or
    (AY >= FSlotY + FRules.InventoryHeight) or (AY + AItem.Rules.InventoryHeight <= FSlotY));
end;

function TXcomBattleItem.NeedsAmmo: Boolean;
begin
  Result := FAmmoItem <> Self;
end;

function TXcomBattleItem.SetAmmoItem(const AItem: TXcomBattleItem): Integer;
var
  LType: string;
begin
  if not NeedsAmmo then
    Exit(-2);
  if not Assigned(AItem) then
  begin
    if Assigned(FAmmoItem) then
      FAmmoItem.IsAmmo := False;
    FAmmoItem := nil;
    Exit(0);
  end;
  if Assigned(FAmmoItem) then
    Exit(-1);
  for LType in FRules.CompatibleAmmo do
    if LType = AItem.Rules.ItemType then
    begin
      FAmmoItem := AItem;
      AItem.IsAmmo := True;
      Exit(0);
    end;
  Result := -2;
end;

procedure TXcomBattleItem.ConvertToCorpse(const ARules: TXcomRuleItem);
begin
  if Assigned(FUnit) and (FRules.BattleType = TXcomRuleItem.BT_CORPSE) and
    (ARules.BattleType = TXcomRuleItem.BT_CORPSE) then
    FRules := ARules;
end;

{ TXcomTile }

constructor TXcomTile.Create(const APosition: TXcomPosition; const AContext: IXcomBattleContext);
var
  LIndex: Integer;
begin
  inherited Create;
  FPosition := APosition;
  FContext := AContext;
  FInventory := TList<TXcomBattleItem>.Create;
  FPreview := -1;
  FTuMarker := -1;
  for LIndex := 0 to 3 do
  begin
    FMapDataId[LIndex] := -1;
    FMapDataSetId[LIndex] := -1;
  end;
  for LIndex := 0 to LIGHT_LAYERS - 1 do
    FLastLight[LIndex] := -1;
end;

destructor TXcomTile.Destroy;
begin
  FInventory.Free;
  inherited Destroy;
end;

function TXcomTile.GetMapData(APart: Integer): TXcomMapData;
begin
  Result := FObjects[APart];
end;

function TXcomTile.GetCurrentFrame(APart: Integer): Integer;
begin
  Result := FCurrentFrame[APart];
end;

procedure TXcomTile.SetCurrentFrame(APart: Integer; AValue: Integer);
begin
  FCurrentFrame[APart] := AValue;
end;

procedure TXcomTile.Load(const ANode: IYamlNode);
var
  LIndex: Integer;
  LField: IYamlNode;
begin
  for LIndex := 0 to 3 do
  begin
    LField := TXcomNodeReader.Field(ANode, 'mapDataID');
    if LField.IsDefined and LField.IsSequence and (LField.Size > LIndex) then
      FMapDataId[LIndex] := LField.Items[LIndex].AsInteger(FMapDataId[LIndex]);
    LField := TXcomNodeReader.Field(ANode, 'mapDataSetID');
    if LField.IsDefined and LField.IsSequence and (LField.Size > LIndex) then
      FMapDataSetId[LIndex] := LField.Items[LIndex].AsInteger(FMapDataSetId[LIndex]);
  end;
  FFire := TXcomNodeReader.ReadInteger(ANode, 'fire', FFire);
  FSmoke := TXcomNodeReader.ReadInteger(ANode, 'smoke', FSmoke);
  LField := TXcomNodeReader.Field(ANode, 'discovered');
  if LField.IsDefined then
    for LIndex := 0 to 2 do
      FDiscovered[LIndex] := LField.Items[LIndex].AsBoolean;
  if TXcomNodeReader.Field(ANode, 'openDoorWest').IsDefined then
    FCurrentFrame[1] := 7;
  if TXcomNodeReader.Field(ANode, 'openDoorNorth').IsDefined then
    FCurrentFrame[2] := 7;
end;

procedure TXcomTile.LoadBinary(const ABuffer: TBytes; AOffset: Integer; const AKey: TXcomTileSerializationKey);
var
  LFlags: Integer;
  LIndex: Integer;

  function Next(ASize: Byte): Integer;
  begin
    case ASize of
      1:
        Result := ABuffer[AOffset];
      2:
        Result := SmallInt(Word(ABuffer[AOffset]) or (Word(ABuffer[AOffset + 1]) shl 8));
      4:
        Result := Integer(Cardinal(ABuffer[AOffset]) or (Cardinal(ABuffer[AOffset + 1]) shl 8) or
          (Cardinal(ABuffer[AOffset + 2]) shl 16) or (Cardinal(ABuffer[AOffset + 3]) shl 24));
    else
      raise EXcomBattleException.CreateFmt('Xcom: a tile field of %d bytes is not supported', [ASize]);
    end;
    Inc(AOffset, ASize);
  end;

begin
  for LIndex := 0 to 3 do
    FMapDataId[LIndex] := Next(AKey.MapDataId);
  for LIndex := 0 to 3 do
    FMapDataSetId[LIndex] := Next(AKey.MapDataSetId);
  FSmoke := Next(AKey.Smoke);
  FFire := Next(AKey.Fire);
  LFlags := Byte(Next(AKey.BoolFields));
  FDiscovered[0] := (LFlags and 1) <> 0;
  FDiscovered[1] := (LFlags and 2) <> 0;
  FDiscovered[2] := (LFlags and 4) <> 0;
  if (LFlags and 8) <> 0 then
    FCurrentFrame[1] := 7
  else
    FCurrentFrame[1] := 0;
  if (LFlags and $10) <> 0 then
    FCurrentFrame[2] := 7
  else
    FCurrentFrame[2] := 0;
end;

function TXcomTile.Save: IYamlNode;
var
  LIndex: Integer;
  LIds: TArray<Integer>;
  LSetIds: TArray<Integer>;
  LSequence: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomPositionCodec.Write(Result, 'position', FPosition);
  SetLength(LIds, 4);
  SetLength(LSetIds, 4);
  for LIndex := 0 to 3 do
  begin
    LIds[LIndex] := FMapDataId[LIndex];
    LSetIds[LIndex] := FMapDataSetId[LIndex];
  end;
  TXcomNodeWriter.SetIntegers(Result, 'mapDataID', LIds);
  TXcomNodeWriter.SetIntegers(Result, 'mapDataSetID', LSetIds);
  if FSmoke <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'smoke', FSmoke);
  if FFire <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'fire', FFire);
  if FDiscovered[0] or FDiscovered[1] or FDiscovered[2] then
  begin
    LSequence := TXcomNodeWriter.NewSequence;
    for LIndex := 0 to 2 do
      if FDiscovered[LIndex] then
        LSequence.Add(YamlStringToText('true'))
      else
        LSequence.Add(YamlStringToText('false'));
    TXcomNodeWriter.SetNode(Result, 'discovered', LSequence);
  end;
  if IsUfoDoorOpen(XCOM_PART_WESTWALL) then
    TXcomNodeWriter.SetBoolean(Result, 'openDoorWest', True);
  if IsUfoDoorOpen(XCOM_PART_NORTHWALL) then
    TXcomNodeWriter.SetBoolean(Result, 'openDoorNorth', True);
end;

procedure TXcomTile.SaveBinary(var ABuffer: TBytes; var AOffset: Integer);
var
  LKey: TXcomTileSerializationKey;
  LIndex: Integer;
  LFlags: Integer;

  procedure Put(ASize: Byte; AValue: Integer);
  begin
    ABuffer[AOffset] := Byte(AValue and $FF);
    if ASize >= 2 then
      ABuffer[AOffset + 1] := Byte((AValue shr 8) and $FF);
    if ASize >= 4 then
    begin
      ABuffer[AOffset + 2] := Byte((AValue shr 16) and $FF);
      ABuffer[AOffset + 3] := Byte((AValue shr 24) and $FF);
    end;
    Inc(AOffset, ASize);
  end;

begin
  LKey := TXcomTileSerializationKey.Current;
  for LIndex := 0 to 3 do
    Put(LKey.MapDataId, FMapDataId[LIndex]);
  for LIndex := 0 to 3 do
    Put(LKey.MapDataSetId, FMapDataSetId[LIndex]);
  Put(LKey.Smoke, FSmoke);
  Put(LKey.Fire, FFire);
  LFlags := 0;
  if FDiscovered[0] then
    Inc(LFlags, 1);
  if FDiscovered[1] then
    Inc(LFlags, 2);
  if FDiscovered[2] then
    Inc(LFlags, 4);
  if IsUfoDoorOpen(XCOM_PART_WESTWALL) then
    LFlags := LFlags or 8;
  if IsUfoDoorOpen(XCOM_PART_NORTHWALL) then
    LFlags := LFlags or $10;
  Put(LKey.BoolFields, LFlags);
end;

procedure TXcomTile.SetMapData(const AData: TXcomMapData; AMapDataId, AMapDataSetId, APart: Integer);
begin
  FObjects[APart] := AData;
  FMapDataId[APart] := AMapDataId;
  FMapDataSetId[APart] := AMapDataSetId;
end;

procedure TXcomTile.GetMapDataIds(out AMapDataId, AMapDataSetId: Integer; APart: Integer);
begin
  AMapDataId := FMapDataId[APart];
  AMapDataSetId := FMapDataSetId[APart];
end;

function TXcomTile.IsVoid: Boolean;
begin
  Result := not Assigned(FObjects[0]) and not Assigned(FObjects[1]) and not Assigned(FObjects[2]) and
    not Assigned(FObjects[3]) and (FSmoke = 0) and (FInventory.Count = 0);
end;

function TXcomTile.GetTuCost(APart, AMovementType: Integer): Integer;
begin
  if not Assigned(FObjects[APart]) then
    Exit(0);
  if FObjects[APart].IsUfoDoor and (FCurrentFrame[APart] > 1) then
    Exit(0);
  if (APart = XCOM_PART_OBJECT) and (FObjects[APart].BigWall >= 4) then
    Exit(0);
  Result := FObjects[APart].GetTuCost(AMovementType);
end;

function TXcomTile.HasNoFloor(const ATileBelow: TXcomTile): Boolean;
begin
  if Assigned(ATileBelow) and (ATileBelow.GetTerrainLevel = -24) then
    Exit(False);
  if Assigned(FObjects[XCOM_PART_FLOOR]) then
    Exit(FObjects[XCOM_PART_FLOOR].IsNoFloor);
  Result := True;
end;

function TXcomTile.IsBigWall: Boolean;
begin
  Result := Assigned(FObjects[XCOM_PART_OBJECT]) and (FObjects[XCOM_PART_OBJECT].BigWall <> 0);
end;

function TXcomTile.GetTerrainLevel: Integer;
begin
  Result := 0;
  if Assigned(FObjects[XCOM_PART_FLOOR]) then
    Result := FObjects[XCOM_PART_FLOOR].TerrainLevel;
  if Assigned(FObjects[XCOM_PART_OBJECT]) then
    Result := Min(FObjects[XCOM_PART_OBJECT].TerrainLevel, Result);
end;

function TXcomTile.GetFootstepSound(const ATileBelow: TXcomTile): Integer;
begin
  Result := -1;
  if Assigned(FObjects[XCOM_PART_FLOOR]) then
    Result := FObjects[XCOM_PART_FLOOR].FootstepSound;
  if Assigned(FObjects[XCOM_PART_OBJECT]) and (FObjects[XCOM_PART_OBJECT].BigWall <= 1) and
    (FObjects[XCOM_PART_OBJECT].FootstepSound > -1) then
    Result := FObjects[XCOM_PART_OBJECT].FootstepSound;
  if not Assigned(FObjects[XCOM_PART_FLOOR]) and not Assigned(FObjects[XCOM_PART_OBJECT]) and
    Assigned(ATileBelow) and (ATileBelow.GetTerrainLevel = -24) then
    Result := ATileBelow.MapData[XCOM_PART_OBJECT].FootstepSound;
end;

function TXcomTile.OpenDoor(APart: Integer; const AUnit: TXcomBattleUnit; AReserve: Integer): Integer;
var
  LSet: TXcomMapDataSet;
  LAlt: TXcomMapData;
begin
  if not Assigned(FObjects[APart]) then
    Exit(-1);
  if FObjects[APart].IsDoor then
  begin
    if Assigned(AUnit) and (AUnit.Armor.Size > 1) then
      Exit(-1);
    if Assigned(AUnit) and (AUnit.TimeUnits < FObjects[APart].GetTuCost(AUnit.MovementType) +
      AUnit.GetActionTus(AReserve, AUnit.GetMainHandWeapon(False))) then
      Exit(4);
    if Assigned(FUnit) and (FUnit <> AUnit) and (FUnit.Position <> FPosition) then
      Exit(-1);
    LSet := FObjects[APart].Dataset as TXcomMapDataSet;
    LAlt := LSet.GetObject(FObjects[APart].AltMcd);
    SetMapData(LAlt, FObjects[APart].AltMcd, FMapDataSetId[APart], LAlt.ObjectType);
    SetMapData(nil, -1, -1, APart);
    Exit(0);
  end;
  if FObjects[APart].IsUfoDoor and (FCurrentFrame[APart] = 0) then
  begin
    if Assigned(AUnit) and (AUnit.TimeUnits < FObjects[APart].GetTuCost(AUnit.MovementType) +
      AUnit.GetActionTus(AReserve, AUnit.GetMainHandWeapon(False))) then
      Exit(4);
    FCurrentFrame[APart] := 1;
    Exit(1);
  end;
  if FObjects[APart].IsUfoDoor and (FCurrentFrame[APart] <> 7) then
    Exit(3);
  Result := -1;
end;

function TXcomTile.IsUfoDoorOpen(APart: Integer): Boolean;
begin
  Result := Assigned(FObjects[APart]) and FObjects[APart].IsUfoDoor and (FCurrentFrame[APart] <> 0);
end;

function TXcomTile.CloseUfoDoor: Integer;
var
  LPart: Integer;
begin
  Result := 0;
  for LPart := XCOM_PART_FLOOR to XCOM_PART_NORTHWALL do
    if IsUfoDoorOpen(LPart) then
    begin
      FCurrentFrame[LPart] := 0;
      Result := 1;
    end;
end;

procedure TXcomTile.SetDiscovered(AFlag: Boolean; APart: Integer);
begin
  if FDiscovered[APart] <> AFlag then
  begin
    FDiscovered[APart] := AFlag;
    if (APart = 2) and AFlag then
    begin
      FDiscovered[0] := True;
      FDiscovered[1] := True;
    end;
    if Assigned(FUnit) then
      FUnit.CacheInvalid := True;
  end;
end;

function TXcomTile.IsDiscovered(APart: Integer): Boolean;
begin
  Result := FDiscovered[APart];
end;

procedure TXcomTile.ResetLight(ALayer: Integer);
begin
  FLight[ALayer] := 0;
  FLastLight[ALayer] := FLight[ALayer];
end;

procedure TXcomTile.AddLight(ALight, ALayer: Integer);
begin
  if FLight[ALayer] < ALight then
    FLight[ALayer] := ALight;
end;

function TXcomTile.GetShade: Integer;
var
  LLight: Integer;
  LLayer: Integer;
begin
  LLight := 0;
  for LLayer := 0 to LIGHT_LAYERS - 1 do
    if FLight[LLayer] > LLight then
      LLight := FLight[LLayer];
  Result := Max(0, 15 - LLight);
end;

function TXcomTile.DestroyPart(APart, AType: Integer; const AScorchedEarth: TXcomMapData): Boolean;
var
  LOriginal: TXcomMapData;
  LOriginalSetId: Integer;
  LDead: TXcomMapData;
begin
  Result := False;
  if Assigned(FObjects[APart]) then
  begin
    if FObjects[APart].IsGravLift then
      Exit(False);
    Result := FObjects[APart].SpecialType = AType;
    LOriginal := FObjects[APart];
    LOriginalSetId := FMapDataSetId[APart];
    SetMapData(nil, -1, -1, APart);
    if LOriginal.DieMcd <> 0 then
    begin
      LDead := (LOriginal.Dataset as TXcomMapDataSet).GetObject(LOriginal.DieMcd);
      SetMapData(LDead, LOriginal.DieMcd, LOriginalSetId, LDead.ObjectType);
    end;
    if LOriginal.Explosive <> 0 then
      SetExplosive(LOriginal.Explosive, LOriginal.ExplosiveType);
  end;
  if (APart = XCOM_PART_FLOOR) and (FPosition.Z = 0) and not Assigned(FObjects[XCOM_PART_FLOOR]) then
    SetMapData(AScorchedEarth, 1, 0, XCOM_PART_FLOOR);
end;

function TXcomTile.Damage(APart, APower, AType: Integer; const AScorchedEarth: TXcomMapData): Boolean;
begin
  Result := False;
  if APower >= FObjects[APart].Armor then
    Result := DestroyPart(APart, AType, AScorchedEarth);
end;

procedure TXcomTile.SetExplosive(APower, ADamageType: Integer; AForce: Boolean);
begin
  if AForce or (FExplosive < APower) then
  begin
    FExplosive := APower;
    FExplosiveType := ADamageType;
  end;
end;

function TXcomTile.GetFlammability: Integer;
var
  LIndex: Integer;
begin
  Result := 255;
  for LIndex := 0 to 3 do
    if Assigned(FObjects[LIndex]) and (FObjects[LIndex].Flammable < Result) then
      Result := FObjects[LIndex].Flammable;
end;

function TXcomTile.GetFuel: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 3 do
    if Assigned(FObjects[LIndex]) and (FObjects[LIndex].Fuel > Result) then
      Result := FObjects[LIndex].Fuel;
end;

function TXcomTile.GetFlammability(APart: Integer): Integer;
begin
  Result := FObjects[APart].Flammable;
end;

function TXcomTile.GetFuel(APart: Integer): Integer;
begin
  Result := FObjects[APart].Fuel;
end;

procedure TXcomTile.Ignite(APower: Integer);
begin
  if GetFlammability <> 255 then
  begin
    APower := APower - (GetFlammability div 10) + 15;
    if APower < 0 then
      APower := 0;
    if TXcomBattleRandom.Percent(FContext.Random, APower) and (GetFuel <> 0) then
      if FFire = 0 then
      begin
        FSmoke := 15 - EnsureRange(GetFlammability div 10, 1, 12);
        FOverlaps := 1;
        FFire := GetFuel + 1;
        FAnimationOffset := FContext.Random.Generate(0, 3);
      end;
  end;
end;

procedure TXcomTile.Animate;
var
  LIndex: Integer;
  LNewFrame: Integer;
begin
  for LIndex := 0 to 3 do
    if Assigned(FObjects[LIndex]) then
    begin
      if FObjects[LIndex].IsUfoDoor and ((FCurrentFrame[LIndex] = 0) or (FCurrentFrame[LIndex] = 7)) then
        Continue;
      LNewFrame := FCurrentFrame[LIndex] + 1;
      // START_POINT is the second special tile type
      if FObjects[LIndex].IsUfoDoor and (FObjects[LIndex].SpecialType = 1) and (LNewFrame = 3) then
        LNewFrame := 7;
      if LNewFrame = 8 then
        LNewFrame := 0;
      FCurrentFrame[LIndex] := LNewFrame;
    end;
end;

procedure TXcomTile.SetUnit(const AUnit: TXcomBattleUnit; const ATileBelow: TXcomTile);
begin
  if Assigned(AUnit) then
    AUnit.SetTile(Self, ATileBelow);
  FUnit := AUnit;
end;

procedure TXcomTile.SetFire(AFire: Integer);
begin
  FFire := AFire;
  FAnimationOffset := FContext.Random.Generate(0, 3);
end;

procedure TXcomTile.AddSmoke(ASmoke: Integer);
begin
  if FFire = 0 then
  begin
    if FOverlaps = 0 then
      FSmoke := EnsureRange(FSmoke + ASmoke, 1, 15)
    else
      Inc(FSmoke, ASmoke);
    FAnimationOffset := FContext.Random.Generate(0, 3);
    AddOverlap;
  end;
end;

procedure TXcomTile.SetSmoke(ASmoke: Integer);
begin
  FSmoke := ASmoke;
  FAnimationOffset := FContext.Random.Generate(0, 3);
end;

procedure TXcomTile.AddItem(const AItem: TXcomBattleItem; const AGround: TXcomRuleInventory);
begin
  AItem.Slot := AGround;
  FInventory.Add(AItem);
  AItem.Tile := Self;
end;

procedure TXcomTile.RemoveItem(const AItem: TXcomBattleItem);
begin
  FInventory.Remove(AItem);
  AItem.Tile := nil;
end;

function TXcomTile.GetTopItemSprite: Integer;
var
  LBiggestWeight: Integer;
  LItem: TXcomBattleItem;
begin
  LBiggestWeight := -1;
  Result := -1;
  for LItem in FInventory do
    if LItem.Rules.Weight > LBiggestWeight then
    begin
      LBiggestWeight := LItem.Rules.Weight;
      Result := LItem.Rules.FloorSprite;
    end;
end;

procedure TXcomTile.PrepareNewTurn(ASmokeDamage: Boolean);
var
  LModifier: Single;
  LBurn: Integer;
  LChance: Single;
begin
  if (FOverlaps <> 0) and (FSmoke <> 0) and (FFire = 0) then
    FSmoke := EnsureRange((FSmoke div FOverlaps) - 1, 0, 15);
  if (FSmoke <> 0) and Assigned(FUnit) and not FUnit.IsOut then
  begin
    if FFire <> 0 then
    begin
      if ((FUnit.Armor.Size = 1) or not FUnit.TookFireDamage) and (FUnit.SpecialAbility <> SPECAB_BURNFLOOR) and
        (FUnit.SpecialAbility <> SPECAB_BURN_AND_EXPLODE) then
      begin
        FUnit.ToggleFireDamage;
        FUnit.Damage(TXcomPosition.Make(0, 0, 0), FSmoke, TXcomRuleItem.DT_IN, True);
        LModifier := FUnit.Armor.DamageModifier[TXcomRuleItem.DT_IN];
        LChance := 40 * LModifier;
        if TXcomBattleRandom.Percent(FContext.Random, Trunc(LChance)) then
        begin
          LBurn := FContext.Random.Generate(0, Trunc(Single(5.0) * LModifier));
          if FUnit.Fire < LBurn then
            FUnit.SetFire(LBurn);
        end;
      end;
    end
    else if ASmokeDamage then
      if (FUnit.Armor.DamageModifier[TXcomRuleItem.DT_SMOKE] > 0.0) and (FUnit.Armor.Size = 1) then
        FUnit.Damage(TXcomPosition.Make(0, 0, 0), (FSmoke div 4) + 1, TXcomRuleItem.DT_SMOKE, True);
  end;
  FOverlaps := 0;
end;

procedure TXcomTile.SetVisible(AVisibility: Integer);
begin
  Inc(FVisible, AVisibility);
end;

procedure TXcomTile.AddOverlap;
begin
  Inc(FOverlaps);
end;

procedure TXcomTile.SetObstacle(APart: Integer);
begin
  FObstacle := FObstacle or (1 shl APart);
end;

function TXcomTile.GetObstacle(APart: Integer): Boolean;
begin
  Result := (FObstacle and (1 shl APart)) <> 0;
end;

function TXcomTile.IsObstacle: Boolean;
begin
  Result := FObstacle <> 0;
end;

procedure TXcomTile.ResetObstacle;
begin
  FObstacle := 0;
end;

{ TXcomBattleUnit }

procedure TXcomBattleUnit.CommonInit;
begin
  FVisibleUnits := TList<TXcomBattleUnit>.Create;
  FUnitsSpottedThisTurn := TList<TXcomBattleUnit>.Create;
  FVisibleTiles := TList<TXcomTile>.Create;
  FInventory := TList<TXcomBattleItem>.Create;
  FStatistics := TXcomBattleUnitStatistics.Create;
  FCacheInvalid := True;
  FTurretType := -1;
  FTurnsSinceSpotted := 255;
  FFaceDirection := -1;
  FActiveHand := 'STR_RIGHT_HAND';
  FLastCover := TXcomPosition.Make(-1, -1, -1);
  FCapturable := True;
end;

procedure TXcomBattleUnit.ResolveMovementType(ADepth: Integer);
begin
  FMovementType := FArmor.MovementType;
  if FMovementType = MT_FLOAT then
  begin
    if ADepth > 0 then
      FMovementType := MT_FLY
    else
      FMovementType := MT_WALK;
  end
  else if FMovementType = MT_SINK then
  begin
    if ADepth = 0 then
      FMovementType := MT_FLY
    else
      FMovementType := MT_WALK;
  end;
end;

constructor TXcomBattleUnit.Create(const AContext: IXcomBattleContext; const ASoldier: TXcomSoldier;
  ADepth: Integer);
var
  LRankBonus: Integer;
  LLook: Integer;
  LIndex: Integer;
begin
  inherited Create;
  CommonInit;
  FContext := AContext;
  FFaction := FACTION_PLAYER;
  FOriginalFaction := FACTION_PLAYER;
  FKilledBy := FACTION_PLAYER;
  FGeoscapeSoldier := ASoldier;
  FName := ASoldier.Name;
  FId := ASoldier.Id;
  FType := 'SOLDIER';
  case ASoldier.Rank of
    RANK_ROOKIE: FRank := 'STR_ROOKIE';
    RANK_SQUADDIE: FRank := 'STR_SQUADDIE';
    RANK_SERGEANT: FRank := 'STR_SERGEANT';
    RANK_CAPTAIN: FRank := 'STR_CAPTAIN';
    RANK_COLONEL: FRank := 'STR_COLONEL';
    RANK_COMMANDER: FRank := 'STR_COMMANDER';
  else
    FRank := '';
  end;
  FStats := ASoldier.CurrentStats;
  FStandHeight := ASoldier.Rules.StandHeight;
  FKneelHeight := ASoldier.Rules.KneelHeight;
  FFloatHeight := ASoldier.Rules.FloatHeight;
  FAggroSound := -1;
  FMoveSound := -1;
  FIntelligence := 2;
  FAggression := 1;
  FSpecialAbility := SPECAB_NONE;
  FArmor := ASoldier.Armor;
  ResolveMovementType(ADepth);
  FStats := FStats + FArmor.Stats;
  FLoftempsSet := FArmor.LoftempsSet;
  FGender := ASoldier.Gender;
  FBreathFrame := -1;
  if FArmor.DrawBubbles then
    FBreathFrame := 0;
  case ASoldier.Rank of
    RANK_SERGEANT: LRankBonus := 1;
    RANK_CAPTAIN: LRankBonus := 3;
    RANK_COLONEL: LRankBonus := 6;
    RANK_COMMANDER: LRankBonus := 10;
  else
    LRankBonus := 0;
  end;
  FValue := ASoldier.Rules.Value + ASoldier.Missions + LRankBonus;
  FTimeUnits := FStats.TimeUnits;
  FEnergy := FStats.Stamina;
  FHealth := FStats.Health;
  FMorale := 100;
  FMaxArmor[SIDE_FRONT] := FArmor.FrontArmor;
  FMaxArmor[SIDE_LEFT] := FArmor.SideArmor;
  FMaxArmor[SIDE_RIGHT] := FArmor.SideArmor;
  FMaxArmor[SIDE_REAR] := FArmor.RearArmor;
  FMaxArmor[SIDE_UNDER] := FArmor.UnderArmor;
  for LIndex := 0 to 4 do
    FCurrentArmor[LIndex] := FMaxArmor[LIndex];
  DeriveRank;
  LLook := ASoldier.Gender + 2 * ASoldier.Look;
  SetRecolor(LLook, LLook, FRankInt);
end;

constructor TXcomBattleUnit.Create(const AContext: IXcomBattleContext; const AUnit: TXcomRuleUnit;
  AFaction, AId: Integer; const AArmor: TXcomArmor; const AAdjustment: TXcomStatAdjustment; ADepth: Integer;
  ABasicLook, AUtileLook, ARankLook: Integer);
const
  RANK_LIST: array[0..6] of string = ('STR_LIVE_SOLDIER', 'STR_LIVE_ENGINEER', 'STR_LIVE_MEDIC',
    'STR_LIVE_NAVIGATOR', 'STR_LIVE_LEADER', 'STR_LIVE_COMMANDER', 'STR_LIVE_TERRORIST');
var
  LIndex: Integer;
  LGeneralRank: Integer;
begin
  inherited Create;
  CommonInit;
  FContext := AContext;
  FFaction := AFaction;
  FOriginalFaction := AFaction;
  FKilledBy := AFaction;
  FId := AId;
  FArmor := AArmor;
  FUnitRules := AUnit;
  FType := AUnit.UnitType;
  FRank := AUnit.Rank;
  FRace := AUnit.Race;
  FStats := AUnit.Stats;
  FStandHeight := AUnit.StandHeight;
  FKneelHeight := AUnit.KneelHeight;
  FFloatHeight := AUnit.FloatHeight;
  FLoftempsSet := FArmor.LoftempsSet;
  FDeathSound := AUnit.DeathSounds;
  FAggroSound := AUnit.AggroSound;
  FMoveSound := AUnit.MoveSound;
  FIntelligence := AUnit.Intelligence;
  FAggression := AUnit.Aggression;
  FSpecialAbility := AUnit.SpecialAbility;
  FSpawnUnit := AUnit.SpawnUnit;
  FValue := AUnit.Value;
  FCapturable := AUnit.Capturable;
  ResolveMovementType(ADepth);
  FStats := FStats + FArmor.Stats;
  FBreathFrame := -1;
  if AArmor.DrawBubbles then
    FBreathFrame := 0;
  FMaxArmor[SIDE_FRONT] := FArmor.FrontArmor;
  FMaxArmor[SIDE_LEFT] := FArmor.SideArmor;
  FMaxArmor[SIDE_RIGHT] := FArmor.SideArmor;
  FMaxArmor[SIDE_REAR] := FArmor.RearArmor;
  FMaxArmor[SIDE_UNDER] := FArmor.UnderArmor;
  if AFaction = FACTION_HOSTILE then
    AdjustStats(AAdjustment);
  FTimeUnits := FStats.TimeUnits;
  FEnergy := FStats.Stamina;
  FHealth := FStats.Health;
  FMorale := 100;
  for LIndex := 0 to 4 do
    FCurrentArmor[LIndex] := FMaxArmor[LIndex];
  FGender := GENDER_MALE;
  LGeneralRank := 0;
  if AFaction = FACTION_HOSTILE then
  begin
    for LIndex := 0 to 6 do
      if FRank = RANK_LIST[LIndex] then
      begin
        LGeneralRank := LIndex;
        Break;
      end;
  end
  else if AFaction = FACTION_NEUTRAL then
    LGeneralRank := Max(0, ARankLook);
  SetRecolor(ABasicLook, AUtileLook, LGeneralRank);
end;

destructor TXcomBattleUnit.Destroy;
begin
  FVisibleUnits.Free;
  FUnitsSpottedThisTurn.Free;
  FVisibleTiles.Free;
  FInventory.Free;
  FStatistics.Free;
  inherited Destroy;
end;

procedure TXcomBattleUnit.SetRecolor(ABasicLook, AUtileLook, ARankLook: Integer);

  function ColorOf(const AColors: TArray<Integer>; AIndex: Integer): Integer;
  begin
    if (AIndex >= 0) and (AIndex < Length(AColors)) then
      Result := AColors[AIndex]
    else
      Result := 0;
  end;

var
  LGroups: array[0..3] of Integer;
  LColors: array[0..3] of Integer;
  LIndex: Integer;
begin
  LGroups[0] := FArmor.FaceColorGroup;
  LColors[0] := ColorOf(FArmor.FaceColor, ABasicLook);
  LGroups[1] := FArmor.HairColorGroup;
  LColors[1] := ColorOf(FArmor.HairColor, ABasicLook);
  LGroups[2] := FArmor.UtileColorGroup;
  LColors[2] := ColorOf(FArmor.UtileColor, AUtileLook);
  LGroups[3] := FArmor.RankColorGroup;
  LColors[3] := ColorOf(FArmor.RankColor, ARankLook);
  for LIndex := 0 to 3 do
    if (LGroups[LIndex] > 0) and (LColors[LIndex] > 0) then
    begin
      SetLength(FRecolor, Length(FRecolor) + 1);
      FRecolor[High(FRecolor)] := TPair<Integer, Integer>.Create(LGroups[LIndex] shl 4, LColors[LIndex]);
    end;
end;

procedure TXcomBattleUnit.Load(const ANode: IYamlNode);
var
  LIndex: Integer;
  LField: IYamlNode;
  LPair: IYamlNode;
  LItems: TArray<IYamlNode>;
begin
  FId := TXcomNodeReader.ReadInteger(ANode, 'id', FId);
  FFaction := TXcomNodeReader.ReadInteger(ANode, 'faction', FFaction);
  FOriginalFaction := FFaction;
  FStatus := TXcomNodeReader.ReadInteger(ANode, 'status', FStatus);
  FPosition := TXcomPositionCodec.Read(ANode, 'position', FPosition);
  FDirection := TXcomNodeReader.ReadInteger(ANode, 'direction', FDirection);
  FToDirection := FDirection;
  FDirectionTurret := TXcomNodeReader.ReadInteger(ANode, 'directionTurret', FDirectionTurret);
  FToDirectionTurret := FDirectionTurret;
  FTimeUnits := TXcomNodeReader.ReadInteger(ANode, 'tu', FTimeUnits);
  FHealth := TXcomNodeReader.ReadInteger(ANode, 'health', FHealth);
  FStunLevel := TXcomNodeReader.ReadInteger(ANode, 'stunlevel', FStunLevel);
  FEnergy := TXcomNodeReader.ReadInteger(ANode, 'energy', FEnergy);
  FMorale := TXcomNodeReader.ReadInteger(ANode, 'morale', FMorale);
  FKneeled := TXcomNodeReader.ReadBoolean(ANode, 'kneeled', FKneeled);
  FFloating := TXcomNodeReader.ReadBoolean(ANode, 'floating', FFloating);
  LField := TXcomNodeReader.Field(ANode, 'armor');
  for LIndex := 0 to 4 do
    if LField.IsDefined and LField.IsSequence and (LField.Size > LIndex) then
      FCurrentArmor[LIndex] := LField.Items[LIndex].AsInteger(FCurrentArmor[LIndex]);
  LField := TXcomNodeReader.Field(ANode, 'fatalWounds');
  for LIndex := 0 to 5 do
    if LField.IsDefined and LField.IsSequence and (LField.Size > LIndex) then
      FFatalWounds[LIndex] := LField.Items[LIndex].AsInteger(FFatalWounds[LIndex]);
  FFire := TXcomNodeReader.ReadInteger(ANode, 'fire', FFire);
  FExpBravery := TXcomNodeReader.ReadInteger(ANode, 'expBravery', FExpBravery);
  FExpReactions := TXcomNodeReader.ReadInteger(ANode, 'expReactions', FExpReactions);
  FExpFiring := TXcomNodeReader.ReadInteger(ANode, 'expFiring', FExpFiring);
  FExpThrowing := TXcomNodeReader.ReadInteger(ANode, 'expThrowing', FExpThrowing);
  FExpPsiSkill := TXcomNodeReader.ReadInteger(ANode, 'expPsiSkill', FExpPsiSkill);
  FExpPsiStrength := TXcomNodeReader.ReadInteger(ANode, 'expPsiStrength', FExpPsiStrength);
  FExpMelee := TXcomNodeReader.ReadInteger(ANode, 'expMelee', FExpMelee);
  FTurretType := TXcomNodeReader.ReadInteger(ANode, 'turretType', FTurretType);
  FVisible := TXcomNodeReader.ReadBoolean(ANode, 'visible', FVisible);
  FTurnsSinceSpotted := TXcomNodeReader.ReadInteger(ANode, 'turnsSinceSpotted', FTurnsSinceSpotted);
  FKilledBy := TXcomNodeReader.ReadInteger(ANode, 'killedBy', FKilledBy);
  FMoraleRestored := TXcomNodeReader.ReadInteger(ANode, 'moraleRestored', FMoraleRestored);
  FRankInt := TXcomNodeReader.ReadInteger(ANode, 'rankInt', FRankInt);
  FOriginalFaction := TXcomNodeReader.ReadInteger(ANode, 'originalFaction', FOriginalFaction);
  FKills := TXcomNodeReader.ReadInteger(ANode, 'kills', FKills);
  FDontReselect := TXcomNodeReader.ReadBoolean(ANode, 'dontReselect', FDontReselect);
  FCharging := nil;
  FSpawnUnit := TXcomNodeReader.ReadString(ANode, 'spawnUnit', FSpawnUnit);
  FMotionPoints := TXcomNodeReader.ReadInteger(ANode, 'motionPoints', 0);
  FRespawn := TXcomNodeReader.ReadBoolean(ANode, 'respawn', FRespawn);
  FActiveHand := TXcomNodeReader.ReadString(ANode, 'activeHand', FActiveHand);
  LField := TXcomNodeReader.Field(ANode, 'tempUnitStatistics');
  if LField.IsDefined then
    FStatistics.Load(LField);
  FMurdererId := TXcomNodeReader.ReadInteger(ANode, 'murdererId', FMurdererId);
  FFatalShotSide := TXcomNodeReader.ReadInteger(ANode, 'fatalShotSide', FFatalShotSide);
  FFatalShotBodyPart := TXcomNodeReader.ReadInteger(ANode, 'fatalShotBodyPart', FFatalShotBodyPart);
  FMurdererWeapon := TXcomNodeReader.ReadString(ANode, 'murdererWeapon', FMurdererWeapon);
  FMurdererWeaponAmmo := TXcomNodeReader.ReadString(ANode, 'murdererWeaponAmmo', FMurdererWeaponAmmo);
  LField := TXcomNodeReader.Field(ANode, 'recolor');
  if LField.IsDefined then
  begin
    FRecolor := nil;
    LItems := LField.Items;
    SetLength(FRecolor, Length(LItems));
    for LIndex := 0 to High(LItems) do
    begin
      LPair := LItems[LIndex];
      FRecolor[LIndex] := TPair<Integer, Integer>.Create(LPair.Items[0].AsInteger, LPair.Items[1].AsInteger);
    end;
  end;
  FMindControllerId := TXcomNodeReader.ReadInteger(ANode, 'mindControllerID', FMindControllerId);
end;

function TXcomBattleUnit.Save: IYamlNode;
var
  LIndex: Integer;
  LValues: TArray<Integer>;
  LPair: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'id', FId);
  TXcomNodeWriter.SetString(Result, 'genUnitType', FType);
  TXcomNodeWriter.SetString(Result, 'genUnitArmor', FArmor.ArmorType);
  TXcomNodeWriter.SetInteger(Result, 'faction', FFaction);
  TXcomNodeWriter.SetInteger(Result, 'status', FStatus);
  TXcomPositionCodec.Write(Result, 'position', FPosition);
  TXcomNodeWriter.SetInteger(Result, 'direction', FDirection);
  TXcomNodeWriter.SetInteger(Result, 'directionTurret', FDirectionTurret);
  TXcomNodeWriter.SetInteger(Result, 'tu', FTimeUnits);
  TXcomNodeWriter.SetInteger(Result, 'health', FHealth);
  TXcomNodeWriter.SetInteger(Result, 'stunlevel', FStunLevel);
  TXcomNodeWriter.SetInteger(Result, 'energy', FEnergy);
  TXcomNodeWriter.SetInteger(Result, 'morale', FMorale);
  TXcomNodeWriter.SetBoolean(Result, 'kneeled', FKneeled);
  TXcomNodeWriter.SetBoolean(Result, 'floating', FFloating);
  SetLength(LValues, 5);
  for LIndex := 0 to 4 do
    LValues[LIndex] := FCurrentArmor[LIndex];
  TXcomNodeWriter.SetIntegers(Result, 'armor', LValues);
  SetLength(LValues, 6);
  for LIndex := 0 to 5 do
    LValues[LIndex] := FFatalWounds[LIndex];
  TXcomNodeWriter.SetIntegers(Result, 'fatalWounds', LValues);
  TXcomNodeWriter.SetInteger(Result, 'fire', FFire);
  TXcomNodeWriter.SetInteger(Result, 'expBravery', FExpBravery);
  TXcomNodeWriter.SetInteger(Result, 'expReactions', FExpReactions);
  TXcomNodeWriter.SetInteger(Result, 'expFiring', FExpFiring);
  TXcomNodeWriter.SetInteger(Result, 'expThrowing', FExpThrowing);
  TXcomNodeWriter.SetInteger(Result, 'expPsiSkill', FExpPsiSkill);
  TXcomNodeWriter.SetInteger(Result, 'expPsiStrength', FExpPsiStrength);
  TXcomNodeWriter.SetInteger(Result, 'expMelee', FExpMelee);
  TXcomNodeWriter.SetInteger(Result, 'turretType', FTurretType);
  TXcomNodeWriter.SetBoolean(Result, 'visible', FVisible);
  TXcomNodeWriter.SetInteger(Result, 'turnsSinceSpotted', FTurnsSinceSpotted);
  TXcomNodeWriter.SetInteger(Result, 'rankInt', FRankInt);
  TXcomNodeWriter.SetInteger(Result, 'moraleRestored', FMoraleRestored);
  if Assigned(FAI) then
    TXcomNodeWriter.SetNode(Result, 'AI', FAI.Save);
  TXcomNodeWriter.SetInteger(Result, 'killedBy', FKilledBy);
  if FOriginalFaction <> FFaction then
    TXcomNodeWriter.SetInteger(Result, 'originalFaction', FOriginalFaction);
  if FKills <> 0 then
    TXcomNodeWriter.SetInteger(Result, 'kills', FKills);
  if (FFaction = FACTION_PLAYER) and FDontReselect then
    TXcomNodeWriter.SetBoolean(Result, 'dontReselect', FDontReselect);
  if FSpawnUnit <> '' then
    TXcomNodeWriter.SetString(Result, 'spawnUnit', FSpawnUnit);
  TXcomNodeWriter.SetInteger(Result, 'motionPoints', FMotionPoints);
  TXcomNodeWriter.SetBoolean(Result, 'respawn', FRespawn);
  TXcomNodeWriter.SetString(Result, 'activeHand', FActiveHand);
  TXcomNodeWriter.SetNode(Result, 'tempUnitStatistics', FStatistics.Save);
  TXcomNodeWriter.SetInteger(Result, 'murdererId', FMurdererId);
  TXcomNodeWriter.SetInteger(Result, 'fatalShotSide', FFatalShotSide);
  TXcomNodeWriter.SetInteger(Result, 'fatalShotBodyPart', FFatalShotBodyPart);
  TXcomNodeWriter.SetString(Result, 'murdererWeapon', FMurdererWeapon);
  TXcomNodeWriter.SetString(Result, 'murdererWeaponAmmo', FMurdererWeaponAmmo);
  for LIndex := 0 to High(FRecolor) do
  begin
    LPair := TXcomNodeWriter.NewSequence;
    LPair.Add(YamlStringToText(IntToStr(FRecolor[LIndex].Key and $FF)));
    LPair.Add(YamlStringToText(IntToStr(FRecolor[LIndex].Value and $FF)));
    TXcomNodeWriter.PushBack(Result, 'recolor', LPair);
  end;
  TXcomNodeWriter.SetInteger(Result, 'mindControllerID', FMindControllerId);
end;

procedure TXcomBattleUnit.SetPosition(const APosition: TXcomPosition; AUpdateLastPosition: Boolean);
begin
  if AUpdateLastPosition then
    FLastPosition := FPosition;
  FPosition := APosition;
end;

procedure TXcomBattleUnit.SetDirection(ADirection: Integer);
begin
  FDirection := ADirection;
  FToDirection := ADirection;
  FDirectionTurret := ADirection;
end;

procedure TXcomBattleUnit.StartWalking(ADirection: Integer; const ADestination: TXcomPosition;
  const ATileBelow: TXcomTile; ACache: Boolean);
var
  LFloorFound: Boolean;
begin
  if ADirection >= DIR_UP then
  begin
    FVerticalDirection := ADirection;
    FStatus := STATUS_FLYING;
  end
  else
  begin
    FDirection := ADirection;
    FStatus := STATUS_WALKING;
  end;
  LFloorFound := not FTile.HasNoFloor(ATileBelow);
  if not LFloorFound or (ADirection >= DIR_UP) then
  begin
    FStatus := STATUS_FLYING;
    FFloating := True;
  end
  else
    FFloating := False;
  FWalkPhase := 0;
  FDestination := ADestination;
  FLastPosition := FPosition;
  FCacheInvalid := ACache;
  FKneeled := False;
  if FBreathFrame >= 0 then
  begin
    FBreathing := False;
    FBreathFrame := 0;
  end;
end;

procedure TXcomBattleUnit.Breathe(ARoll: Integer);
begin
  // a breath frame of -1 means this unit doesn't produce bubbles
  if (FBreathFrame < 0) or IsOut then
  begin
    FBreathing := False;
    Exit;
  end;
  if (not FBreathing) or (FStatus = STATUS_WALKING) then
  begin
    // 5% for every animation frame, more with a low morale
    FBreathing := (FStatus <> STATUS_WALKING) and (ARoll < (105 - FMorale));
    FBreathFrame := 0;
  end;
  if FBreathing then
  begin
    // advance the bubble frame; at the end of the cycle the bubbles go away
    Inc(FBreathFrame);
    if FBreathFrame >= 17 then
    begin
      FBreathFrame := 0;
      FBreathing := False;
    end;
    FCacheInvalid := True;
  end;
end;

procedure TXcomBattleUnit.KeepWalking(const ATileBelow: TXcomTile; ACache: Boolean);
var
  LMiddle: Integer;
  LEnd: Integer;
begin
  if FVerticalDirection <> 0 then
  begin
    LMiddle := 4;
    LEnd := 8;
  end
  else
  begin
    LMiddle := 4 + 4 * (FDirection mod 2);
    LEnd := 8 + 8 * (FDirection mod 2);
    if FArmor.Size > 1 then
    begin
      if (FDirection < 1) or (FDirection > 5) then
        LMiddle := LEnd
      else if FDirection = 5 then
        LMiddle := 12
      else if FDirection = 1 then
        LMiddle := 5
      else
        LMiddle := 1;
    end;
  end;
  if not ACache then
  begin
    FPosition := FDestination;
    LEnd := 2;
  end;
  Inc(FWalkPhase);
  if FWalkPhase = LMiddle then
    FPosition := FDestination;
  if FWalkPhase >= LEnd then
  begin
    if FFloating and not FTile.HasNoFloor(ATileBelow) then
      FFloating := False;
    FStatus := STATUS_STANDING;
    FWalkPhase := 0;
    FVerticalDirection := 0;
    if FFaceDirection >= 0 then
    begin
      FDirection := FFaceDirection;
      FFaceDirection := -1;
    end;
    if FArmor.Size > 1 then
      Inc(FMotionPoints, 30)
    else if FStandHeight > 16 then
      Inc(FMotionPoints, 4)
    else
      Inc(FMotionPoints, 3);
  end;
  FCacheInvalid := ACache;
end;

function TXcomBattleUnit.WalkingPhase: Integer;
begin
  Result := FWalkPhase mod 8;
end;

function TXcomBattleUnit.DiagonalWalkingPhase: Integer;
begin
  Result := (FWalkPhase div 8) * 8;
end;

procedure TXcomBattleUnit.LookAt(const APoint: TXcomPosition; ATurret: Boolean);
var
  LDirection: Integer;
begin
  LDirection := DirectionTo(APoint);
  if ATurret then
  begin
    FToDirectionTurret := LDirection;
    if FToDirectionTurret <> FDirectionTurret then
      FStatus := STATUS_TURNING;
  end
  else
  begin
    FToDirection := LDirection;
    if (FToDirection <> FDirection) and (FToDirection < 8) and (FToDirection > -1) then
      FStatus := STATUS_TURNING;
  end;
end;

procedure TXcomBattleUnit.LookAt(ADirection: Integer; AForce: Boolean);
begin
  if not AForce then
  begin
    if (ADirection < 0) or (ADirection >= 8) then
      Exit;
    FToDirection := ADirection;
    if FToDirection <> FDirection then
      FStatus := STATUS_TURNING;
  end
  else
  begin
    FToDirection := ADirection;
    FDirection := ADirection;
  end;
end;

procedure TXcomBattleUnit.Turn(ATurret: Boolean);
var
  LDelta: Integer;
begin
  if ATurret then
  begin
    if FDirectionTurret = FToDirectionTurret then
    begin
      AbortTurn;
      Exit;
    end;
    LDelta := FToDirectionTurret - FDirectionTurret;
  end
  else
  begin
    if FDirection = FToDirection then
    begin
      AbortTurn;
      Exit;
    end;
    LDelta := FToDirection - FDirection;
  end;
  if LDelta <> 0 then
  begin
    if LDelta > 0 then
    begin
      if LDelta <= 4 then
      begin
        if not ATurret then
        begin
          if FTurretType > -1 then
            Inc(FDirectionTurret);
          Inc(FDirection);
        end
        else
          Inc(FDirectionTurret);
      end
      else if not ATurret then
      begin
        if FTurretType > -1 then
          Dec(FDirectionTurret);
        Dec(FDirection);
      end
      else
        Dec(FDirectionTurret);
    end
    else if LDelta > -4 then
    begin
      if not ATurret then
      begin
        if FTurretType > -1 then
          Dec(FDirectionTurret);
        Dec(FDirection);
      end
      else
        Dec(FDirectionTurret);
    end
    else if not ATurret then
    begin
      if FTurretType > -1 then
        Inc(FDirectionTurret);
      Inc(FDirection);
    end
    else
      Inc(FDirectionTurret);
    if FDirection < 0 then
      FDirection := 7;
    if FDirection > 7 then
      FDirection := 0;
    if FDirectionTurret < 0 then
      FDirectionTurret := 7;
    if FDirectionTurret > 7 then
      FDirectionTurret := 0;
    if FVisible or (FFaction = FACTION_PLAYER) then
      FCacheInvalid := True;
  end;
  if ATurret then
  begin
    if FToDirectionTurret = FDirectionTurret then
      FStatus := STATUS_STANDING;
  end
  else if (FToDirection = FDirection) or (FStatus = STATUS_UNCONSCIOUS) then
    FStatus := STATUS_STANDING;
end;

procedure TXcomBattleUnit.AbortTurn;
begin
  FStatus := STATUS_STANDING;
end;

procedure TXcomBattleUnit.Kneel(AKneeled: Boolean);
begin
  FKneeled := AKneeled;
  FCacheInvalid := True;
end;

procedure TXcomBattleUnit.Aim(AAiming: Boolean);
begin
  if AAiming then
    FStatus := STATUS_AIMING
  else
    FStatus := STATUS_STANDING;
  if FVisible or (FFaction = FACTION_PLAYER) then
    FCacheInvalid := True;
end;

function TXcomBattleUnit.DirectionTo(const APoint: TXcomPosition): Integer;
var
  LOx, LOy, LAngle: Double;
  LPie: array[0..3] of Double;
  LHalf: Double;
begin
  LOx := APoint.X - FPosition.X;
  LOy := APoint.Y - FPosition.Y;
  LAngle := ArcTan2(LOx, -LOy);
  LHalf := PI_QUARTER / 2.0;
  LPie[0] := (PI_QUARTER * 4.0) - LHalf;
  LPie[1] := (PI_QUARTER * 3.0) - LHalf;
  LPie[2] := (PI_QUARTER * 2.0) - LHalf;
  LPie[3] := (PI_QUARTER * 1.0) - LHalf;
  Result := 0;
  if (LAngle > LPie[0]) or (LAngle < -LPie[0]) then
    Result := 4
  else if LAngle > LPie[1] then
    Result := 3
  else if LAngle > LPie[2] then
    Result := 2
  else if LAngle > LPie[3] then
    Result := 1
  else if LAngle < -LPie[1] then
    Result := 5
  else if LAngle < -LPie[2] then
    Result := 6
  else if LAngle < -LPie[3] then
    Result := 7
  else if LAngle < LPie[0] then
    Result := 0;
end;

function TXcomBattleUnit.Damage(const ARelative: TXcomPosition; APower, AType: Integer; AIgnoreArmor: Boolean)
  : Integer;
var
  LSide: Integer;
  LBodyPart: Integer;
  LProduct: Single;
  LRelativeDirection: Integer;
  LAbsX: Integer;
  LAbsY: Integer;
  LSelector: Integer;

  function Pick(ASide, AOther: Integer): Integer;
  begin
    if FContext.Random.Generate(0, 2) < 2 then
      Result := ASide
    else
      Result := AOther;
  end;

begin
  LSide := SIDE_FRONT;
  LBodyPart := BODYPART_TORSO;
  FHitByAnything := True;
  if APower <= 0 then
    Exit(0);
  LProduct := APower * FArmor.DamageModifier[AType];
  APower := Floor(LProduct);
  if AType = TXcomRuleItem.DT_SMOKE then
    AType := TXcomRuleItem.DT_STUN;
  if not AIgnoreArmor then
  begin
    if (ARelative.X = 0) and (ARelative.Y = 0) and (ARelative.Z = 0) then
      LSide := SIDE_UNDER
    else
    begin
      LAbsX := Abs(ARelative.X);
      LAbsY := Abs(ARelative.Y);
      if LAbsY > LAbsX * 2 then
        LRelativeDirection := 8 + 4 * Ord(ARelative.Y > 0)
      else if LAbsX > LAbsY * 2 then
        LRelativeDirection := 10 + 4 * Ord(ARelative.X < 0)
      else if ARelative.X < 0 then
      begin
        if ARelative.Y > 0 then
          LRelativeDirection := 13
        else
          LRelativeDirection := 15;
      end
      else if ARelative.Y > 0 then
        LRelativeDirection := 11
      else
        LRelativeDirection := 9;
      LSelector := (LRelativeDirection - FDirection) mod 8;
      case LSelector of
        0: LSide := SIDE_FRONT;
        1: LSide := Pick(SIDE_FRONT, SIDE_RIGHT);
        2: LSide := SIDE_RIGHT;
        3: LSide := Pick(SIDE_REAR, SIDE_RIGHT);
        4: LSide := SIDE_REAR;
        5: LSide := Pick(SIDE_REAR, SIDE_LEFT);
        6: LSide := SIDE_LEFT;
        7: LSide := Pick(SIDE_FRONT, SIDE_LEFT);
      end;
      if ARelative.Z >= GetHeight then
        LBodyPart := BODYPART_HEAD
      else if ARelative.Z > 4 then
      begin
        case LSide of
          SIDE_LEFT: LBodyPart := BODYPART_LEFTARM;
          SIDE_RIGHT: LBodyPart := BODYPART_RIGHTARM;
        else
          LBodyPart := BODYPART_TORSO;
        end;
      end
      else
      begin
        case LSide of
          SIDE_LEFT: LBodyPart := BODYPART_LEFTLEG;
          SIDE_RIGHT: LBodyPart := BODYPART_RIGHTLEG;
        else
          LBodyPart := FContext.Random.Generate(BODYPART_RIGHTLEG, BODYPART_LEFTLEG);
        end;
      end;
    end;
    Dec(APower, GetArmor(LSide));
  end;
  if APower > 0 then
  begin
    if AType = TXcomRuleItem.DT_STUN then
      Inc(FStunLevel, APower)
    else
    begin
      Dec(FHealth, APower);
      if FHealth < 0 then
        FHealth := 0;
      if AType <> TXcomRuleItem.DT_IN then
      begin
        if FArmor.DamageModifier[TXcomRuleItem.DT_STUN] > 0.0 then
          Inc(FStunLevel, FContext.Random.Generate(0, APower div 4));
        if IsWoundable then
        begin
          if FContext.Random.Generate(0, 10) < APower then
            Inc(FFatalWounds[LBodyPart], FContext.Random.Generate(1, 3));
          if FFatalWounds[LBodyPart] <> 0 then
            MoraleChange(-FFatalWounds[LBodyPart]);
        end;
        SetArmor(GetArmor(LSide) - (APower div 10) - 1, LSide);
      end;
    end;
  end;
  SetFatalShotInfo(LSide, LBodyPart);
  if APower < 0 then
    Result := 0
  else
    Result := APower;
end;

procedure TXcomBattleUnit.HealStun(APower: Integer);
begin
  Dec(FStunLevel, APower);
  if FStunLevel < 0 then
    FStunLevel := 0;
end;

procedure TXcomBattleUnit.KnockOut;
begin
  FStunLevel := FHealth;
end;

procedure TXcomBattleUnit.StartFalling;
begin
  FStatus := STATUS_COLLAPSING;
  FFallPhase := 0;
  FCacheInvalid := True;
end;

procedure TXcomBattleUnit.KeepFalling;
begin
  Inc(FFallPhase);
  if FFallPhase = FArmor.DeathFrames then
  begin
    Dec(FFallPhase);
    if FHealth = 0 then
      FStatus := STATUS_DEAD
    else
      FStatus := STATUS_UNCONSCIOUS;
  end;
  FCacheInvalid := True;
end;

function TXcomBattleUnit.IsOut: Boolean;
begin
  Result := (FStatus = STATUS_DEAD) or (FStatus = STATUS_UNCONSCIOUS) or (FStatus = STATUS_IGNORE_ME);
end;

function TXcomBattleUnit.GetActionTus(AActionType: Integer; const AItem: TXcomBattleItem): Integer;
begin
  if not Assigned(AItem) then
    Exit(0);
  Result := GetActionTus(AActionType, AItem.Rules);
end;

function TXcomBattleUnit.GetActionTus(AActionType: Integer; const AItem: TXcomRuleItem): Integer;
var
  LCost: Integer;
  LScaled: Single;
begin
  if not Assigned(AItem) then
    Exit(0);
  case AActionType of
    BA_PRIME: LCost := 50;
    BA_THROW: LCost := 25;
    BA_AUTOSHOT: LCost := AItem.TimeUnitsAuto;
    BA_SNAPSHOT: LCost := AItem.TimeUnitsSnap;
    BA_HIT: LCost := AItem.TimeUnitsMelee;
    BA_LAUNCH, BA_AIMEDSHOT: LCost := AItem.TimeUnitsAimed;
    BA_USE, BA_MINDCONTROL, BA_PANIC: LCost := AItem.TimeUnitsUse;
  else
    LCost := 0;
  end;
  if not AItem.FlatRate or (AActionType = BA_THROW) or (AActionType = BA_PRIME) then
  begin
    LScaled := (FStats.TimeUnits * LCost) / Single(100.0);
    LCost := Floor(LScaled);
  end;
  Result := LCost;
end;

function TXcomBattleUnit.SpendTimeUnits(ATimeUnits: Integer): Boolean;
begin
  Result := ATimeUnits <= FTimeUnits;
  if Result then
    Dec(FTimeUnits, ATimeUnits);
end;

function TXcomBattleUnit.SpendEnergy(ATimeUnits: Integer): Boolean;
var
  LEnergy: Integer;
begin
  LEnergy := ATimeUnits div 2;
  Result := LEnergy <= FEnergy;
  if Result then
    Dec(FEnergy, LEnergy);
end;

procedure TXcomBattleUnit.SetTimeUnits(ATimeUnits: Integer);
begin
  FTimeUnits := Max(0, ATimeUnits);
end;

function TXcomBattleUnit.AddToVisibleUnits(const AUnit: TXcomBattleUnit): Boolean;
begin
  if FUnitsSpottedThisTurn.IndexOf(AUnit) < 0 then
    FUnitsSpottedThisTurn.Add(AUnit);
  if FVisibleUnits.IndexOf(AUnit) >= 0 then
    Exit(False);
  FVisibleUnits.Add(AUnit);
  Result := True;
end;

procedure TXcomBattleUnit.ClearVisibleUnits;
begin
  FVisibleUnits.Clear;
end;

function TXcomBattleUnit.AddToVisibleTiles(const ATile: TXcomTile): Boolean;
begin
  FVisibleTiles.Add(ATile);
  Result := True;
end;

procedure TXcomBattleUnit.ClearVisibleTiles;
var
  LTile: TXcomTile;
begin
  for LTile in FVisibleTiles do
    LTile.SetVisible(-1);
  FVisibleTiles.Clear;
end;

function TXcomBattleUnit.GetFiringAccuracy(AActionType: Integer; const AItem: TXcomBattleItem): Integer;
var
  LWeaponAccuracy: Integer;
begin
  LWeaponAccuracy := AItem.Rules.AccuracySnap;
  if (AActionType = BA_AIMEDSHOT) or (AActionType = BA_LAUNCH) then
    LWeaponAccuracy := AItem.Rules.AccuracyAimed
  else if AActionType = BA_AUTOSHOT then
    LWeaponAccuracy := AItem.Rules.AccuracyAuto
  else if AActionType = BA_HIT then
  begin
    if AItem.Rules.SkillApplied then
      Exit((FStats.Melee * AItem.Rules.AccuracyMelee div 100) * GetAccuracyModifier(AItem) div 100);
    Exit(AItem.Rules.AccuracyMelee * GetAccuracyModifier(AItem) div 100);
  end;
  Result := FStats.Firing * LWeaponAccuracy div 100;
  if FKneeled then
    Result := Result * 115 div 100;
  if AItem.Rules.TwoHanded then
    if Assigned(GetItem('STR_RIGHT_HAND')) and Assigned(GetItem('STR_LEFT_HAND')) then
      Result := Result * 80 div 100;
  Result := Result * GetAccuracyModifier(AItem) div 100;
end;

function TXcomBattleUnit.GetAccuracyModifier(const AItem: TXcomBattleItem): Integer;
var
  LWounds: Integer;
begin
  LWounds := FFatalWounds[BODYPART_HEAD];
  if Assigned(AItem) then
  begin
    if AItem.Rules.TwoHanded then
      Inc(LWounds, FFatalWounds[BODYPART_RIGHTARM] + FFatalWounds[BODYPART_LEFTARM])
    else if GetItem('STR_RIGHT_HAND') = AItem then
      Inc(LWounds, FFatalWounds[BODYPART_RIGHTARM])
    else
      Inc(LWounds, FFatalWounds[BODYPART_LEFTARM]);
  end;
  Result := Max(10, 25 * FHealth div FStats.Health + 75 + -10 * LWounds);
end;

function TXcomBattleUnit.GetThrowingAccuracy: Double;
begin
  Result := (FStats.Throwing * GetAccuracyModifier) / 100.0;
end;

procedure TXcomBattleUnit.SetArmor(AArmor, ASide: Integer);
begin
  if AArmor < 0 then
    AArmor := 0;
  FCurrentArmor[ASide] := AArmor;
end;

function TXcomBattleUnit.GetArmor(ASide: Integer): Integer;
begin
  Result := FCurrentArmor[ASide];
end;

function TXcomBattleUnit.GetMaxArmor(ASide: Integer): Integer;
begin
  Result := FMaxArmor[ASide];
end;

function TXcomBattleUnit.GetFatalWounds: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 5 do
    Inc(Result, FFatalWounds[LIndex]);
end;

function TXcomBattleUnit.GetFatalWound(APart: Integer): Integer;
begin
  if (APart < 0) or (APart > 5) then
    Exit(0);
  Result := FFatalWounds[APart];
end;

function TXcomBattleUnit.GetReactionScore: Double;
begin
  Result := (Double(FStats.Reactions) * Double(FTimeUnits)) / Double(FStats.TimeUnits);
end;

procedure TXcomBattleUnit.PrepareNewTurn(AFullProcess: Boolean);
var
  LDamage: Single;
  LChance: Integer;
  LType: Integer;
begin
  if FStatus = STATUS_IGNORE_ME then
    Exit;
  FUnitsSpottedThisTurn.Clear;
  if FFaction <> FOriginalFaction then
  begin
    FFaction := FOriginalFaction;
    if (FFaction = FACTION_PLAYER) and Assigned(FAI) then
      FAI := nil;
  end
  else
    RecoverTimeUnits;
  FDontReselect := False;
  FMotionPoints := 0;
  if not AFullProcess then
  begin
    if FKneeled then
      FKneeled := False;
    Exit;
  end;
  Dec(FHealth, GetFatalWounds);
  if not FHitByFire and (FFire > 0) then
  begin
    LDamage := FArmor.DamageModifier[TXcomRuleItem.DT_IN] *
      FContext.Random.Generate(FContext.FireDamageRange(0), FContext.FireDamageRange(1));
    FHealth := Trunc(FHealth - LDamage);
    Dec(FFire);
  end;
  if FHealth < 0 then
    FHealth := 0;
  if (FHealth = 0) and Assigned(FAI) then
    FAI := nil;
  if (FStunLevel > 0) and ((FArmor.Size = 1) or not IsOut) then
    HealStun(1);
  if not IsOut then
  begin
    LChance := 100 - (2 * FMorale);
    if FContext.Random.Generate(1, 100) <= LChance then
    begin
      LType := FContext.Random.Generate(0, 100);
      if LType <= 33 then
        FStatus := STATUS_BERSERK
      else
        FStatus := STATUS_PANICKING;
    end
    else if LChance > 1 then
      Inc(FExpBravery);
  end;
  FHitByFire := False;
end;

procedure TXcomBattleUnit.MoraleChange(AChange: Integer);
begin
  if not IsFearable then
    Exit;
  Inc(FMorale, AChange);
  if FMorale > 100 then
    FMorale := 100;
  if FMorale < 0 then
    FMorale := 0;
end;

procedure TXcomBattleUnit.SetFire(AFire: Integer);
begin
  if (FSpecialAbility <> SPECAB_BURNFLOOR) and (FSpecialAbility <> SPECAB_BURN_AND_EXPLODE) then
    FFire := AFire;
end;

procedure TXcomBattleUnit.SetTile(const ATile: TXcomTile; const ATileBelow: TXcomTile);
begin
  FTile := ATile;
  if not Assigned(FTile) then
  begin
    FFloating := False;
    Exit;
  end;
  if (FStatus = STATUS_WALKING) and FTile.HasNoFloor(ATileBelow) and (FMovementType = MT_FLY) then
  begin
    FStatus := STATUS_FLYING;
    FFloating := True;
  end
  else if (FStatus = STATUS_FLYING) and not FTile.HasNoFloor(ATileBelow) and (FVerticalDirection = 0) then
  begin
    FStatus := STATUS_WALKING;
    FFloating := False;
  end
  else if FStatus = STATUS_UNCONSCIOUS then
    FFloating := (FMovementType = MT_FLY) and FTile.HasNoFloor(ATileBelow);
end;

function TXcomBattleUnit.GetItem(const ASlot: TXcomRuleInventory; AX, AY: Integer): TXcomBattleItem;
var
  LItem: TXcomBattleItem;
begin
  Result := nil;
  if ASlot.InventoryType <> INV_GROUND then
  begin
    for LItem in FInventory do
      if (LItem.Slot = ASlot) and LItem.OccupiesSlot(AX, AY) then
        Exit(LItem);
  end
  else if Assigned(FTile) then
    for LItem in FTile.Inventory do
      if LItem.OccupiesSlot(AX, AY) then
        Exit(LItem);
end;

function TXcomBattleUnit.GetItem(const ASlot: string; AX, AY: Integer): TXcomBattleItem;
var
  LItem: TXcomBattleItem;
begin
  Result := nil;
  if ASlot <> 'STR_GROUND' then
  begin
    for LItem in FInventory do
      if Assigned(LItem.Slot) and (LItem.Slot.Id = ASlot) and LItem.OccupiesSlot(AX, AY) then
        Exit(LItem);
  end
  else if Assigned(FTile) then
    for LItem in FTile.Inventory do
      if Assigned(LItem.Slot) and LItem.OccupiesSlot(AX, AY) then
        Exit(LItem);
end;

function TXcomBattleUnit.GetMainHandWeapon(AQuickest: Boolean): TXcomBattleItem;
var
  LRight: TXcomBattleItem;
  LLeft: TXcomBattleItem;
  LTuRight: Integer;
  LTuLeft: Integer;
  LCurrent: TXcomBattleItem;
begin
  LRight := GetItem('STR_RIGHT_HAND');
  LLeft := GetItem('STR_LEFT_HAND');
  if not Assigned(LRight) or not Assigned(LRight.AmmoItem) or (LRight.AmmoItem.AmmoQuantity = 0) then
    LRight := nil;
  if not Assigned(LLeft) or not Assigned(LLeft.AmmoItem) or (LLeft.AmmoItem.AmmoQuantity = 0) then
    LLeft := nil;
  if Assigned(LRight) and not Assigned(LLeft) then
    Exit(LRight)
  else if not Assigned(LRight) and Assigned(LLeft) then
    Exit(LLeft)
  else if not Assigned(LRight) and not Assigned(LLeft) then
    Exit(nil);
  LTuRight := LRight.Rules.TimeUnitsSnap;
  LTuLeft := LLeft.Rules.TimeUnitsSnap;
  LCurrent := GetItem(GetActiveHand);
  if not AQuickest and (FFaction <> FACTION_PLAYER) then
  begin
    if (LRight.Rules.Waypoints <> 0) or (LRight.AmmoItem.Rules.Waypoints <> 0) then
      Exit(LRight);
    if (LLeft.Rules.Waypoints <> 0) or (LLeft.AmmoItem.Rules.Waypoints <> 0) then
      Exit(LLeft);
  end;
  if (LTuLeft <= 0) and (LTuRight > 0) then
    Exit(LRight)
  else if (LTuRight <= 0) and (LTuLeft > 0) then
    Exit(LLeft);
  if LTuLeft >= LTuRight then
  begin
    if AQuickest then
      Result := LRight
    else if FFaction = FACTION_PLAYER then
      Result := LCurrent
    else
      Result := LLeft;
  end
  else if AQuickest then
    Result := LLeft
  else if FFaction = FACTION_PLAYER then
    Result := LCurrent
  else
    Result := LRight;
end;

function TXcomBattleUnit.GetGrenadeFromBelt: TXcomBattleItem;
var
  LItem: TXcomBattleItem;
begin
  for LItem in FInventory do
    if LItem.Rules.BattleType = TXcomRuleItem.BT_GRENADE then
      Exit(LItem);
  Result := nil;
end;

function TXcomBattleUnit.CheckAmmo: Boolean;
var
  LWeapon: TXcomBattleItem;
  LAmmo: TXcomBattleItem;
  LItem: TXcomBattleItem;
  LName: string;
  LWrong: Boolean;
begin
  LWeapon := GetItem('STR_RIGHT_HAND');
  if not Assigned(LWeapon) or Assigned(LWeapon.AmmoItem) or (LWeapon.Rules.BattleType = TXcomRuleItem.BT_MELEE) or
    (TimeUnits < 15) then
  begin
    LWeapon := GetItem('STR_LEFT_HAND');
    if not Assigned(LWeapon) or Assigned(LWeapon.AmmoItem) or
      (LWeapon.Rules.BattleType = TXcomRuleItem.BT_MELEE) or (TimeUnits < 15) then
      Exit(False);
  end;
  LAmmo := nil;
  LWrong := True;
  for LItem in FInventory do
  begin
    LAmmo := LItem;
    for LName in LWeapon.Rules.CompatibleAmmo do
      if LName = LAmmo.Rules.ItemType then
      begin
        LWrong := False;
        Break;
      end;
    if not LWrong then
      Break;
  end;
  if LWrong then
    Exit(False);
  SpendTimeUnits(15);
  LWeapon.SetAmmoItem(LAmmo);
  LAmmo.MoveToOwner(nil);
  Result := True;
end;

function TXcomBattleUnit.IsInExitArea(AType: Integer): Boolean;
begin
  Result := Assigned(FTile) and Assigned(FTile.MapData[XCOM_PART_FLOOR]) and
    (FTile.MapData[XCOM_PART_FLOOR].SpecialType = AType);
end;

function TXcomBattleUnit.LiesInExitArea(const ATile: TXcomTile; AType: Integer): Boolean;
begin
  Result := Assigned(ATile) and Assigned(ATile.MapData[XCOM_PART_FLOOR]) and
    (ATile.MapData[XCOM_PART_FLOOR].SpecialType = AType);
end;

function TXcomBattleUnit.GetHeight: Integer;
begin
  if FKneeled then
    Result := FKneelHeight
  else
    Result := FStandHeight;
end;

procedure TXcomBattleUnit.AddReactionExp;
begin
  Inc(FExpReactions);
end;

procedure TXcomBattleUnit.AddFiringExp;
begin
  Inc(FExpFiring);
end;

procedure TXcomBattleUnit.AddThrowingExp;
begin
  Inc(FExpThrowing);
end;

procedure TXcomBattleUnit.AddPsiSkillExp;
begin
  Inc(FExpPsiSkill);
end;

procedure TXcomBattleUnit.AddPsiStrengthExp;
begin
  Inc(FExpPsiStrength);
end;

procedure TXcomBattleUnit.AddMeleeExp;
begin
  Inc(FExpMelee);
end;

function TXcomBattleUnit.ImproveStat(AExperience: Integer): Integer;
begin
  if AExperience > 10 then
    Result := FContext.Random.Generate(2, 6)
  else if AExperience > 5 then
    Result := FContext.Random.Generate(1, 4)
  else if AExperience > 2 then
    Result := FContext.Random.Generate(1, 3)
  else if AExperience > 0 then
    Result := FContext.Random.Generate(0, 1)
  else
    Result := 0;
end;

function TXcomBattleUnit.PostMissionProcedures(const ASoldier: TXcomSoldier; var AStatsDiff: TXcomUnitStats)
  : Boolean;
var
  LStats: TXcomUnitStats;
  LCaps: TXcomUnitStats;
  LHealthLoss: Integer;
  LValue: Integer;
begin
  if not Assigned(ASoldier) then
    Exit(False);
  ASoldier.AddMissionCount;
  ASoldier.AddKillCount(FKills);
  LStats := ASoldier.CurrentStats;
  AStatsDiff := AStatsDiff - LStats;
  LCaps := ASoldier.Rules.StatCaps;
  LHealthLoss := FStats.Health - FHealth;
  // RNG::generate((healthLoss*0.5),(healthLoss*1.5)) is the overload of doubles (a decimal number): the result is
  // cut to an int by setWoundRecovery
  ASoldier.SetWoundRecovery(Trunc(FContext.Random.Generate(Double(LHealthLoss * 0.5), Double(LHealthLoss * 1.5))));
  if (FExpBravery <> 0) and (LStats.Bravery < LCaps.Bravery) then
    if FExpBravery > FContext.Random.Generate(0, 10) then
      Inc(LStats.Bravery, 10);
  if (FExpReactions <> 0) and (LStats.Reactions < LCaps.Reactions) then
    Inc(LStats.Reactions, ImproveStat(FExpReactions));
  if (FExpFiring <> 0) and (LStats.Firing < LCaps.Firing) then
    Inc(LStats.Firing, ImproveStat(FExpFiring));
  if (FExpMelee <> 0) and (LStats.Melee < LCaps.Melee) then
    Inc(LStats.Melee, ImproveStat(FExpMelee));
  if (FExpThrowing <> 0) and (LStats.Throwing < LCaps.Throwing) then
    Inc(LStats.Throwing, ImproveStat(FExpThrowing));
  if (FExpPsiSkill <> 0) and (LStats.PsiSkill < LCaps.PsiSkill) then
    Inc(LStats.PsiSkill, ImproveStat(FExpPsiSkill));
  if (FExpPsiStrength <> 0) and (LStats.PsiStrength < LCaps.PsiStrength) then
    Inc(LStats.PsiStrength, ImproveStat(FExpPsiStrength));
  Result := False;
  if (FExpBravery <> 0) or (FExpReactions <> 0) or (FExpFiring <> 0) or (FExpPsiSkill <> 0) or
    (FExpPsiStrength <> 0) or (FExpMelee <> 0) then
  begin
    Result := True;
    if ASoldier.Rank = RANK_ROOKIE then
      ASoldier.PromoteRank;
    LValue := LCaps.TimeUnits - LStats.TimeUnits;
    if LValue > 0 then
      Inc(LStats.TimeUnits, FContext.Random.Generate(0, LValue div 10 + 2));
    LValue := LCaps.Health - LStats.Health;
    if LValue > 0 then
      Inc(LStats.Health, FContext.Random.Generate(0, LValue div 10 + 2));
    LValue := LCaps.Strength - LStats.Strength;
    if LValue > 0 then
      Inc(LStats.Strength, FContext.Random.Generate(0, LValue div 10 + 2));
    LValue := LCaps.Stamina - LStats.Stamina;
    if LValue > 0 then
      Inc(LStats.Stamina, FContext.Random.Generate(0, LValue div 15 + 2));
  end;
  ASoldier.CurrentStats := LStats;
  AStatsDiff := AStatsDiff + LStats;
end;

function TXcomBattleUnit.GetMiniMapSpriteIndex: Integer;
begin
  if IsOut then
    Exit(9);
  case FFaction of
    FACTION_HOSTILE:
      if FArmor.Size = 1 then
        Result := 3
      else
        Result := 24;
    FACTION_NEUTRAL:
      if FArmor.Size = 1 then
        Result := 6
      else
        Result := 12;
  else
    if FArmor.Size = 1 then
      Result := 0
    else
      Result := 12;
  end;
end;

procedure TXcomBattleUnit.Heal(APart, AWoundAmount, AHealthAmount: Integer);
begin
  if (APart < 0) or (APart > 5) or (FFatalWounds[APart] = 0) then
    Exit;
  Dec(FFatalWounds[APart], AWoundAmount);
  if FFatalWounds[APart] < 0 then
    FFatalWounds[APart] := 0;
  Inc(FHealth, AHealthAmount);
  if FHealth > FStats.Health then
    FHealth := FStats.Health;
end;

procedure TXcomBattleUnit.PainKillers;
var
  LLostHealth: Integer;
begin
  LLostHealth := FStats.Health - FHealth;
  if LLostHealth > FMoraleRestored then
  begin
    FMorale := Min(100, LLostHealth - FMoraleRestored + FMorale);
    FMoraleRestored := LLostHealth;
  end;
end;

procedure TXcomBattleUnit.Stimulant(AEnergy, AStun: Integer);
begin
  Inc(FEnergy, AEnergy);
  if FEnergy > FStats.Stamina then
    FEnergy := FStats.Stamina;
  HealStun(AStun);
end;

function TXcomBattleUnit.DisplayName(const ATranslate: TFunc<string, string>; ADebugAppendId: Boolean): string;
begin
  if (FType <> 'SOLDIER') and Assigned(ATranslate) then
  begin
    if Pos('STR_', FType) > 0 then
      Result := ATranslate(FType)
    else
      Result := ATranslate(FRace);
    if ADebugAppendId then
      Result := Result + ' ' + IntToStr(FId);
    Exit;
  end;
  Result := FName;
end;

function TXcomBattleUnit.GetLoftemps(AEntry: Integer): Integer;
begin
  if (AEntry < 0) or (AEntry >= Length(FLoftempsSet)) then
    raise EXcomBattleException.Create('Xcom: a unit has no loftemps entry for the tile');
  Result := FLoftempsSet[AEntry];
end;

function TXcomBattleUnit.DeathSounds: TArray<Integer>;
begin
  if (Length(FDeathSound) = 0) and Assigned(FGeoscapeSoldier) then
  begin
    if FGender = GENDER_MALE then
      Exit(FGeoscapeSoldier.Rules.DeathSoundMale);
    Exit(FGeoscapeSoldier.Rules.DeathSoundFemale);
  end;
  Result := FDeathSound;
end;

function TXcomBattleUnit.IsWoundable: Boolean;
begin
  Result := (FType = 'SOLDIER') or (FContext.AlienBleeding and (FOriginalFaction <> FACTION_PLAYER) and
    (FArmor.Size = 1));
end;

function TXcomBattleUnit.IsFearable: Boolean;
begin
  Result := FArmor.Size = 1;
end;

procedure TXcomBattleUnit.AddKillCount;
begin
  Inc(FKills);
end;

function TXcomBattleUnit.GetActiveHand: string;
begin
  if Assigned(GetItem(FActiveHand)) then
    Exit(FActiveHand);
  if Assigned(GetItem('STR_LEFT_HAND')) then
    Exit('STR_LEFT_HAND');
  Result := 'STR_RIGHT_HAND';
end;

procedure TXcomBattleUnit.ConvertToFaction(AFaction: Integer);
begin
  FFaction := AFaction;
end;

procedure TXcomBattleUnit.Kill;
begin
  FHealth := 0;
end;

procedure TXcomBattleUnit.InstaKill;
begin
  FHealth := 0;
  FStatus := STATUS_DEAD;
end;

function TXcomBattleUnit.GetCarriedWeight(const ADraggingItem: TXcomBattleItem): Integer;
var
  LItem: TXcomBattleItem;
  LWeight: Integer;
begin
  LWeight := FArmor.Weight;
  for LItem in FInventory do
  begin
    if LItem = ADraggingItem then
      Continue;
    Inc(LWeight, LItem.Rules.Weight);
    if (LItem.AmmoItem <> LItem) and Assigned(LItem.AmmoItem) then
      Inc(LWeight, LItem.AmmoItem.Rules.Weight);
  end;
  Result := Max(0, LWeight);
end;

procedure TXcomBattleUnit.DeriveRank;
begin
  if Assigned(FGeoscapeSoldier) then
    case FGeoscapeSoldier.Rank of
      RANK_ROOKIE: FRankInt := 0;
      RANK_SQUADDIE: FRankInt := 1;
      RANK_SERGEANT: FRankInt := 2;
      RANK_CAPTAIN: FRankInt := 3;
      RANK_COLONEL: FRankInt := 4;
      RANK_COMMANDER: FRankInt := 5;
    else
      FRankInt := 0;
    end;
end;

function TXcomBattleUnit.CheckViewSector(const APosition: TXcomPosition): Boolean;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  LDeltaX := APosition.X - FPosition.X;
  LDeltaY := FPosition.Y - APosition.Y;
  case FDirection of
    0: Result := (LDeltaX + LDeltaY >= 0) and (LDeltaY - LDeltaX >= 0);
    1: Result := (LDeltaX >= 0) and (LDeltaY >= 0);
    2: Result := (LDeltaX + LDeltaY >= 0) and (LDeltaY - LDeltaX <= 0);
    3: Result := (LDeltaY <= 0) and (LDeltaX >= 0);
    4: Result := (LDeltaX + LDeltaY <= 0) and (LDeltaY - LDeltaX <= 0);
    5: Result := (LDeltaX <= 0) and (LDeltaY <= 0);
    6: Result := (LDeltaX + LDeltaY <= 0) and (LDeltaY - LDeltaX >= 0);
    7: Result := (LDeltaY >= 0) and (LDeltaX <= 0);
  else
    Result := False;
  end;
end;

procedure TXcomBattleUnit.AdjustStats(const AAdjustment: TXcomStatAdjustment);
var
  LIndex: Integer;
  LProduct: Double;
begin
  FStats.TimeUnits := FStats.TimeUnits + AAdjustment.StatGrowth.TimeUnits * AAdjustment.GrowthMultiplier *
    FStats.TimeUnits div 100;
  FStats.Stamina := FStats.Stamina + AAdjustment.StatGrowth.Stamina * AAdjustment.GrowthMultiplier *
    FStats.Stamina div 100;
  FStats.Health := FStats.Health + AAdjustment.StatGrowth.Health * AAdjustment.GrowthMultiplier *
    FStats.Health div 100;
  FStats.Bravery := FStats.Bravery + AAdjustment.StatGrowth.Bravery * AAdjustment.GrowthMultiplier *
    FStats.Bravery div 100;
  FStats.Reactions := FStats.Reactions + AAdjustment.StatGrowth.Reactions * AAdjustment.GrowthMultiplier *
    FStats.Reactions div 100;
  FStats.Firing := FStats.Firing + AAdjustment.StatGrowth.Firing * AAdjustment.GrowthMultiplier *
    FStats.Firing div 100;
  FStats.Throwing := FStats.Throwing + AAdjustment.StatGrowth.Throwing * AAdjustment.GrowthMultiplier *
    FStats.Throwing div 100;
  FStats.Strength := FStats.Strength + AAdjustment.StatGrowth.Strength * AAdjustment.GrowthMultiplier *
    FStats.Strength div 100;
  FStats.PsiStrength := FStats.PsiStrength + AAdjustment.StatGrowth.PsiStrength * AAdjustment.GrowthMultiplier *
    FStats.PsiStrength div 100;
  FStats.PsiSkill := FStats.PsiSkill + AAdjustment.StatGrowth.PsiSkill * AAdjustment.GrowthMultiplier *
    FStats.PsiSkill div 100;
  FStats.Melee := FStats.Melee + AAdjustment.StatGrowth.Melee * AAdjustment.GrowthMultiplier *
    FStats.Melee div 100;
  // int *= double: the product is a double that is truncated
  // the product is stored as a Double before the truncation: the x87 would keep 64 bits of mantissa and
  // truncate 20 * 1.2 to 23, where the C++ (SSE, 53 bits) rounds it to 24.0
  LProduct := FStats.Firing * AAdjustment.AimAndArmorMultiplier;
  FStats.Firing := Trunc(LProduct);
  for LIndex := 0 to 4 do
  begin
    LProduct := FMaxArmor[LIndex] * AAdjustment.AimAndArmorMultiplier;
    FMaxArmor[LIndex] := Trunc(LProduct);
  end;
end;

function TXcomBattleUnit.HasInventory: Boolean;
begin
  Result := FArmor.HasInventory;
end;

function TXcomBattleUnit.IsSelectable(AFaction: Integer; ACheckReselect, ACheckInventory: Boolean): Boolean;
begin
  Result := (FFaction = AFaction) and not IsOut and (not ACheckReselect or not FDontReselect) and
    (not ACheckInventory or HasInventory);
end;

function TXcomBattleUnit.GetMeleeWeapon: TXcomBattleItem;
begin
  Result := GetItem('STR_RIGHT_HAND');
  if Assigned(Result) and (Result.Rules.BattleType = TXcomRuleItem.BT_MELEE) then
    Exit;
  Result := GetItem('STR_LEFT_HAND');
  if Assigned(Result) and (Result.Rules.BattleType = TXcomRuleItem.BT_MELEE) then
    Exit;
  Result := GetSpecialWeapon(TXcomRuleItem.BT_MELEE);
end;

procedure TXcomBattleUnit.GoToTimeOut;
begin
  FStatus := STATUS_IGNORE_ME;
end;

procedure TXcomBattleUnit.SetSpecialWeapon(const ARuleset: TXcomRuleset;
  const AMake: TFunc<TXcomRuleItem, TXcomBattleItem>);
var
  LIndex: Integer;
  LRules: TXcomRuleItem;
begin
  LIndex := 0;
  if Assigned(FUnitRules) then
  begin
    LRules := ARuleset.Items.Find(FUnitRules.MeleeWeapon);
    if Assigned(LRules) then
    begin
      FSpecialWeapons[LIndex] := AMake(LRules);
      Inc(LIndex);
    end;
  end;
  LRules := ARuleset.Items.Find(FArmor.SpecialWeapon);
  if Assigned(LRules) then
  begin
    FSpecialWeapons[LIndex] := AMake(LRules);
    Inc(LIndex);
  end;
  if (FStats.PsiSkill > 0) and (FOriginalFaction = FACTION_HOSTILE) then
  begin
    LRules := ARuleset.Items.Find(FUnitRules.PsiWeapon);
    if Assigned(LRules) then
      FSpecialWeapons[LIndex] := AMake(LRules);
  end;
end;

function TXcomBattleUnit.GetSpecialWeapon(ABattleType: Integer): TXcomBattleItem;
var
  LIndex: Integer;
begin
  for LIndex := 0 to SPEC_WEAPON_MAX - 1 do
    if Assigned(FSpecialWeapons[LIndex]) and (FSpecialWeapons[LIndex].Rules.BattleType = ABattleType) then
      Exit(FSpecialWeapons[LIndex]);
  Result := nil;
end;

procedure TXcomBattleUnit.RecoverTimeUnits;
var
  LRecovery: Integer;
  LEnergyRecovery: Integer;
  LWeight: Integer;
  LEncumbrance: Single;
begin
  LRecovery := FStats.TimeUnits;
  LWeight := GetCarriedWeight;
  // strength / 0 is +inf or nan in the C++ float arithmetic: never below 1
  if LWeight <> 0 then
  begin
    LEncumbrance := FStats.Strength / Single(LWeight);
    if LEncumbrance < 1 then
      LRecovery := Trunc(LEncumbrance * LRecovery);
  end;
  Dec(LRecovery, (LRecovery * ((FFatalWounds[BODYPART_LEFTLEG] + FFatalWounds[BODYPART_RIGHTLEG]) * 10)) div 100);
  SetTimeUnits(LRecovery);
  if not IsOut then
  begin
    if Assigned(FGeoscapeSoldier) then
      LEnergyRecovery := FGeoscapeSoldier.InitialStats.TimeUnits div 3
    else
      LEnergyRecovery := FUnitRules.EnergyRecovery;
    Dec(LEnergyRecovery, (FEnergy * (FFatalWounds[BODYPART_TORSO] * 10)) div 100);
    FEnergy := Max(0, Min(FStats.Stamina, FEnergy + LEnergyRecovery));
  end;
end;

procedure TXcomBattleUnit.SetFatalShotInfo(ASide, ABodyPart: Integer);
begin
  FFatalShotSide := ASide;
  FFatalShotBodyPart := ABodyPart;
end;

procedure TXcomBattleUnit.NerfFiringXp(ANewXp: Integer);
begin
  FExpFiring := ANewXp;
end;

procedure TXcomBattleUnit.ResetHitState;
begin
  FHitByAnything := False;
end;

function TXcomBattleUnit.GetVisible: Boolean;
begin
  if FFaction = FACTION_PLAYER then
    Result := True
  else
    Result := FVisible;
end;

procedure TXcomBattleUnit.ToggleFireDamage;
begin
  FHitByFire := not FHitByFire;
end;

procedure TXcomBattleUnit.FreePatrolTarget;
begin
  if Assigned(FAI) then
    FAI.FreePatrolTarget;
end;

end.
