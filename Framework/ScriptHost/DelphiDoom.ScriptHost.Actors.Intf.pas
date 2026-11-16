{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what the actor functions of the scripts ask of    }
{  the engine                                                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  IScriptActorSource is the only door to the mobjs (mobj_t): a script knows   }
{  an actor by its key (a LongWord) and the key 0 means "the current actor",   }
{  the one that the engine runs the script for (IScriptActorContext). The      }
{  library builds what scripts see (invalid keys, values for an actor that is  }
{  not there, the lists of keys), the engine answers with the raw data.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Actors.Intf;

interface

uses
  DelphiDoom.ScriptHost.Actors.KeyList,
  DelphiDoom.ScriptHost.Intf;

type
  /// <summary>
  ///   The numbers of an actor that scripts can read (and, but the last ones, write): one for each
  ///   GetActor* function that gives a number. acfX and acfY move the actor when they are written,
  ///   acfSpeed is the length of the momentum (writing it scales the momentum),
  ///   acfHealth kills it when it is written as zero or less, acfCustomDropItem turns on the flag of
  ///   the custom drop item
  /// </summary>
  TScriptActorField = (
    acfX, acfY, acfZ, acfMomX, acfMomY, acfMomZ, acfFloorZ, acfCeilingZ, acfSpeed, acfAngle, acfHealth,
    acfMass, acfHeight, acfScale, acfPushFactor, acfGravity, acfSpecial,
    acfArg1, acfArg2, acfArg3, acfArg4, acfArg5, acfWeaveIndexXY, acfWeaveIndexZ, acfFriction,
    acfPainChance, acfSpriteDX, acfSpriteDY, acfInfightingGroup, acfProjectileGroup, acfSplashGroup,
    acfCustomDropItem,
    // read only
    acfSpawnHealth, acfSector, acfMobjType, acfEditorNumber, acfState
  );

  /// <summary>The texts of an actor (the sounds are names, empty for no sound)</summary>
  TScriptActorText = (
    actTranslation, actBloodColor, actName, actName2, actSeeSound, actAttackSound, actPainSound,
    actDeathSound, actActiveSound, actCustomSound1, actCustomSound2, actCustomSound3,
    actMeleeSound
  );

  /// <summary>The actors that an actor points to</summary>
  TScriptActorRelation = (acrTarget, acrTracer, acrMaster);

  /// <summary>The lists of actors that scripts can ask for (Actors.All*)</summary>
  TScriptActorSelection = (
    acsAll, acsMonstersAlive, acsMonstersDead, acsMonsters, acsMissiles, acsEditorNumber,
    acsSector, acsSectorTag, acsType
  );

  /// <summary>The implicit actor of a script: the one that the engine is running it for</summary>
  IScriptActorContext = interface
    ['{4C8E2A71-F3D5-4B96-A018-7E5B9D2C61F3}']
    /// <summary>The key of the current actor, SCRIPT_INVALID_ID when no actor runs a script</summary>
    function CurrentKey: Cardinal;
  end;

  /// <summary>
  ///   The mobjs for the scripts. Every key can be 0 (the current actor) or SCRIPT_INVALID_ID or a
  ///   key that is no actor any more: then the methods that read answer ANotFound and the ones
  ///   that write do nothing
  /// </summary>
  IScriptActorSource = interface
    ['{9B3D5F18-6A24-4E70-8C1D-D2F47A09B35E}']
    /// <summary>The key of the actor behind the key (0 gives the current actor), SCRIPT_INVALID_ID if there is none</summary>
    function KeyOf(const AKey: Cardinal): Cardinal;
    function GetNumber(const AKey: Cardinal; const AField: TScriptActorField;
      const ANotFound: Integer): Integer;
    function GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
    /// <summary>The key of the target, tracer or master of the actor, SCRIPT_INVALID_ID if it has none</summary>
    function RelatedKey(const AKey: Cardinal; const ARelation: TScriptActorRelation): Cardinal;
    function CustomParam(const AKey: Cardinal; const AName: string): Integer;
    /// <summary>One of the flags of the actor (the number is the one of the flags of the scripts)</summary>
    function CheckFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
    /// <summary>The distance between two actors, 0 if one is not there (the squares are 32 bit integers: they wrap)</summary>
    function Distance(const AKey1, AKey2: Cardinal; const AWithZ: Boolean): Integer;
    /// <summary>The number of the player that the actor is, -1 if it is no player or the player is not in the game</summary>
    function PlayerNumber(const AKey: Cardinal): Integer;
    /// <summary>The number of mobj types</summary>
    function MobjTypeCount: Integer;
    function MobjTypeFromName(const AName: string): Integer;
    function MobjTypeFromEditorNumber(const ANumber: Integer): Integer;
    /// <summary>Whether the first actor sees the second one; both are actors that exist</summary>
    function CheckSight(const AKey1, AKey2: Cardinal): Boolean;
    /// <summary>True if the key is an actor (0 is the current one, if there is one)</summary>
    function Exists(const AKey: Cardinal): Boolean;
    /// <summary>Writes a number of an actor (the library does not give the read only ones)</summary>
    procedure SetNumber(const AKey: Cardinal; const AField: TScriptActorField; const AValue: Integer);
    procedure SetText(const AKey: Cardinal; const AField: TScriptActorText; const AValue: string);
    /// <summary>Makes the actor of ATargetKey (0 is the current one, SCRIPT_INVALID_ID none) the target, tracer or master</summary>
    procedure SetRelated(const AKey: Cardinal; const ARelation: TScriptActorRelation;
      const ATargetKey: Cardinal);
    procedure SetPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
    procedure SetCustomParam(const AKey: Cardinal; const AName: string; const AValue: Integer);
    /// <summary>Gives back the default drop item</summary>
    procedure SetDefaultDropItem(const AKey: Cardinal);
    /// <summary>Turns a flag on or off (a number of flag that the actor has no word for does nothing)</summary>
    procedure SetFlag(const AKey: Cardinal; const AFlag: Cardinal; const AOn: Boolean);
    /// <summary>The number of states</summary>
    function StateCount: Integer;
    /// <summary>Puts the actor in a state that exists (P_SetMobjState)</summary>
    procedure SetState(const AKey: Cardinal; const AState: Integer);
    /// <summary>Plays a sound (or a random list of sounds) by name from the actor</summary>
    procedure PlayActorSound(const AKey: Cardinal; const AName: string);
    /// <summary>Plays a sound (or a random list of sounds) by name with no origin</summary>
    procedure PlayGlobalSound(const AName: string);
    /// <summary>Spawns an actor of a type that exists, the key of the new one or SCRIPT_INVALID_ID</summary>
    function Spawn(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
    procedure Remove(const AKey: Cardinal);
    /// <summary>Adds to the list the keys of the actors of the selection (AArgument is the sector, tag, editor number or type)</summary>
    procedure Collect(const ASelection: TScriptActorSelection; const AArgument: Integer;
      const AKeys: TScriptActorKeyList);
  end;

  /// <summary>
  ///   The actor functions of the scripts (the properties of the classes of the scripts in psi_game
  ///   call them). The functions that give a number or a text of an actor are GetNumber and GetText
  /// </summary>
  IScriptActors = interface(IScriptFunctionSection)
    ['{E2A64C90-5D17-4F83-9B26-0C8F13D7A4E5}']
    function Actor: Cardinal;
    function TActor(const AKey: Cardinal): Cardinal;
    /// <summary>A number of an actor; for an actor that is not there the value that scripts have always got</summary>
    function GetNumber(const AKey: Cardinal; const AField: TScriptActorField): Integer;
    function GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
    function GetRelation(const AKey: Cardinal; const ARelation: TScriptActorRelation): Cardinal;
    function GetActorCustomParam(const AKey: Cardinal; const AName: string): Integer;
    function CheckActorFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
    function GetActorDistanceXY(const AKey1, AKey2: Cardinal): Integer;
    function GetActorDistanceXYZ(const AKey1, AKey2: Cardinal): Integer;
    function GetActorPlayer(const AKey: Cardinal): Integer;
    function IsValidActor(const AKey: Cardinal): Boolean;
    function ActorTypeFromEditorNumber(const ANumber: Integer): Integer;
    function ActorTypeFromName(const AName: string): Integer;
    procedure SetNumber(const AKey: Cardinal; const AField: TScriptActorField; const AValue: Integer);
    procedure SetText(const AKey: Cardinal; const AField: TScriptActorText; const AValue: string);
    procedure SetRelation(const AKey: Cardinal; const ARelation: TScriptActorRelation;
      const ATargetKey: Cardinal);
    procedure SetActorPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
    procedure SetActorCustomParam(const AKey: Cardinal; const AName: string; const AValue: Integer);
    procedure SetActorDefaultDropItem(const AKey: Cardinal);
    procedure SetActorFlag(const AKey: Cardinal; const AFlag: Cardinal);
    procedure UnSetActorFlag(const AKey: Cardinal; const AFlag: Cardinal);
    procedure SetActorState(const AKey: Cardinal; const AState: Integer);
    procedure ActorPlaySound(const AKey: Cardinal; const AName: string);
    procedure PlaySound(const AName: string);
    function SpawnActorType(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
    function SpawnActorEditorNumber(const AX, AY, AZ: Integer; const ANumber: Integer): Cardinal;
    function SpawnActorName(const AX, AY, AZ: Integer; const AName: string): Cardinal;
    procedure RemoveActor(const AKey: Cardinal);
    function CheckActorSight(const AKey1, AKey2: Cardinal): Boolean;
    function AllActors: TArray<Cardinal>;
    function AllMonstersAlive: TArray<Cardinal>;
    function AllMonstersDead: TArray<Cardinal>;
    function AllMonsters: TArray<Cardinal>;
    function AllMissiles: TArray<Cardinal>;
    function AllAtSector(const ASector: Integer): TArray<Cardinal>;
    function AllAtSectorTag(const ATag: Integer): TArray<Cardinal>;
    function AllEditorNumber(const ANumber: Integer): TArray<Cardinal>;
    function AllType(const AType: Integer): TArray<Cardinal>;
  end;

implementation

end.
