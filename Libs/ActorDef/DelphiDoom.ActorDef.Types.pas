{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the model of the definitions of the actors   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.Types;

interface

{$SCOPEDENUMS ON}

const
  /// <summary>
  ///   A state number at or above this value is a state of the engine tables (the number is
  ///   the value minus the marker); below it, it is a state of the definition itself
  /// </summary>
  ACTORDEF_ORIGINAL_STATE_MARKER = $FFFFF;
  /// <summary>The fixed point unit (1.0) of the engine</summary>
  ACTORDEF_FRACUNIT = 65536;
  /// <summary>The most states that one actor or weapon can have</summary>
  ACTORDEF_MAX_STATES = 1024;
  /// <summary>The thinker names and scripts are short strings of 255 characters</summary>
  ACTORDEF_MAX_THINKER_TEXT = 255;

  /// <summary>Bits of StatesDefined of an actor: the labels that the definition has</summary>
  ACTORDEF_ST_SPAWN = 1;
  ACTORDEF_ST_SEE = 2;
  ACTORDEF_ST_MELEE = 4;
  ACTORDEF_ST_MISSILE = 8;
  ACTORDEF_ST_PAIN = 16;
  ACTORDEF_ST_DEATH = 32;
  ACTORDEF_ST_XDEATH = 64;
  ACTORDEF_ST_RAISE = 128;
  ACTORDEF_ST_HEAL = 256;
  ACTORDEF_ST_CRASH = 512;
  ACTORDEF_ST_INTERACT = 1024;
  ACTORDEF_ST_CRUSH = 2048;

  /// <summary>Bits of StatesDefined of a weapon</summary>
  ACTORDEF_WT_UP = 1;
  ACTORDEF_WT_DOWN = 2;
  ACTORDEF_WT_READY = 4;
  ACTORDEF_WT_ATTACK = 8;
  ACTORDEF_WT_FLASH = 16;
  ACTORDEF_WT_HOLDATTACK = 32;

  /// <summary>Bits of FlagsEx of a state (the engine flags of a state)</summary>
  ACTORDEF_STATE_RANDOM_SELECT = $40;
  ACTORDEF_STATE_RANDOM_RANGE = $80;

type
  /// <summary>The lists of flags of the engine: each one has its own words in a definition</summary>
  TActorDefFlagCategory = (
    Flags,
    Flags2,
    FlagsEx,
    Flags2Ex,
    Flags3Ex,
    Flags4Ex,
    Flags5Ex,
    Flags6Ex,
    /// <summary>The flags of a weapon</summary>
    Weapon
  );

  /// <summary>The games that the definitions are for</summary>
  TActorDefGame = (Doom, Heretic, Hexen, Strife);

  /// <summary>Where a script of a definition lives</summary>
  TActorDefScriptType = (Normal, Global);

  /// <summary>
  ///   What changes from a game to another in the definitions. The profile is data: the
  ///   code has no conditions on the game
  /// </summary>
  TActorDefProfile = record
    Game: TActorDefGame;
    /// <summary>The actors have a second list of flags (MF2_...)</summary>
    HasFlags2: Boolean;
    /// <summary>The actors have a second name (Strife)</summary>
    HasStrifeName: Boolean;
    /// <summary>MONSTER, PROJECTILE... set bits in the flags2 and not in the flags5_ex (Hexen)</summary>
    KeywordsUseFlags2: Boolean;
    /// <summary>A weapon has a level (Heretic)</summary>
    WeaponHasLevel: Boolean;
    /// <summary>The level of a weapon that does not say it</summary>
    WeaponDefaultLevel: Integer;
    /// <summary>A weapon has a class of the player, and "mana" is another name of "ammo" (Hexen)</summary>
    WeaponHasPlayerClass: Boolean;
    /// <summary>The states of a weapon have the flags of the state (all the games but Strife)</summary>
    WeaponStatesWriteFlagsEx: Boolean;
    /// <summary>SNDINFO has $MAP lines that give the song of a map, and the sounds have tags (Hexen)</summary>
    SoundInfoHexenExtensions: Boolean;
  end;

  /// <summary>One state of an actor or of a weapon</summary>
  TActorDefState = record
    Sprite: string;
    /// <summary>0 is A</summary>
    Frame: Integer;
    Tics: Integer;
    /// <summary>The same as Tics, or the other end of a random duration</summary>
    Tics2: Integer;
    Action: string;
    /// <summary>The next state: a state of the definition, a marker plus a state of the engine, or -1 for none</summary>
    NextState: Integer;
    FlagsEx: Integer;
    Bright: Boolean;
    /// <summary>The next state is the one of a goto that is already known</summary>
    HasGoto: Boolean;
    /// <summary>The goto is a text that has to be resolved when the definition is submitted</summary>
    GotoNeedsCalc: Boolean;
    GotoText: string;
    /// <summary>The name of the engine for the state when it has a label of its own</summary>
    Alias: string;
    /// <summary>The label as it is written</summary>
    SaveAlias: string;
    Fast: Boolean;
  end;

  TActorDefStates = TArray<TActorDefState>;

  /// <summary>
  ///   The definition of an actor (ACTOR). The numbers of the states follow the
  ///   convention of ACTORDEF_ORIGINAL_STATE_MARKER; the lists of flags are words
  ///   separated by a space, each one followed by a space, as the lines of a patch have them
  /// </summary>
  TActorDefActor = record
    Name: string;
    /// <summary>Only Strife has it</summary>
    Name2: string;
    InheritsFrom: string;
    DoomedNum: Integer;
    SpawnState: Integer;
    SpawnHealth: Integer;
    SeeState: Integer;
    SeeSound: string;
    ReactionTime: Integer;
    AttackSound: string;
    PainState: Integer;
    PainChance: Integer;
    PainSound: string;
    MeleeState: Integer;
    MissileState: Integer;
    DeathState: Integer;
    XDeathState: Integer;
    DeathSound: string;
    Speed: Integer;
    Radius: Integer;
    Height: Integer;
    Mass: Integer;
    Damage: Integer;
    ActiveSound: string;
    Flags: string;
    Flags2: string;
    FlagsEx: string;
    Flags2Ex: string;
    Flags3Ex: string;
    Flags4Ex: string;
    Flags5Ex: string;
    Flags6Ex: string;
    RaiseState: Integer;
    CustomSound1: string;
    CustomSound2: string;
    CustomSound3: string;
    DropItem: string;
    MissileType: string;
    ExplosionDamage: Integer;
    ExplosionRadius: Integer;
    MeleeDamage: Integer;
    MeleeSound: string;
    RenderStyle: string;
    Alpha: Integer;
    HealState: Integer;
    CrashState: Integer;
    InteractState: Integer;
    MissileHeight: Integer;
    VSpeed: Single;
    PushFactor: Single;
    Friction: Single;
    /// <summary>The ACTORDEF_ST_ bits of the labels that the definition has (also the inherited ones)</summary>
    StatesDefined: Cardinal;
    /// <summary>The number of the actor of the engine that this one replaces, or -1</summary>
    ReplacesId: Integer;
    Scale: Single;
    Gravity: Single;
    MinMissileChance: Integer;
    FloatSpeed: Integer;
    NormalSpeed: Integer;
    FastSpeed: Integer;
    Obituary: string;
    HitObituary: string;
    Gender: string;
    MeleeRange: Integer;
    MaxStepHeight: Integer;
    MaxDropoffHeight: Integer;
    GibHealth: Integer;
    MaxTargetRange: Integer;
    WeaveIndexXY: Integer;
    WeaveIndexZ: Integer;
    SpriteDX: Single;
    SpriteDY: Single;
    RipSound: string;
    BloodColor: string;
    Translation: string;
    CrushState: Integer;
    MeleeThreshold: Integer;
    States: TActorDefStates;
  end;

  /// <summary>The definition of a weapon (WEAPON)</summary>
  TActorDefWeapon = record
    Ammo: Integer;
    /// <summary>Only Heretic has it</summary>
    Level: Integer;
    /// <summary>Only Hexen has it</summary>
    PlayerClass: Integer;
    WeaponNo: Integer;
    UpState: Integer;
    DownState: Integer;
    ReadyState: Integer;
    AttackState: Integer;
    HoldAttackState: Integer;
    FlashState: Integer;
    AmmoPerShot: Integer;
    /// <summary>The ACTORDEF_WT_ bits of the labels that the definition has</summary>
    StatesDefined: Cardinal;
    Flags: string;
    States: TActorDefStates;
  end;

  PActorDefActor = ^TActorDefActor;
  PActorDefWeapon = ^TActorDefWeapon;

  /// <summary>A thinker: an actor that runs a script every Interval tics</summary>
  TActorDefThinker = record
    Name: string;
    Script: string;
    Dn: Integer;
    /// <summary>0 is forever</summary>
    RepeatCount: Integer;
    Interval: Integer;
  end;

implementation

end.
