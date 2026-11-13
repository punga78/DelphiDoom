{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - animations of idTech 4: shared types        }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim.h and     }
{  Anim_Blend.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media    }
{  company. This unit is derived from the Doom 3 GPL source code and is        }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Text.Types;

const
  /// <summary>ANIM_NumAnimChannels</summary>
  ANIM_NUM_ANIM_CHANNELS = 5;
  /// <summary>ANIM_MaxSyncedAnims: the anims that an animation plays together</summary>
  ANIM_MAX_SYNCED_ANIMS = 3;
  ANIMCHANNEL_ALL = 0;
  ANIMCHANNEL_TORSO = 1;
  ANIMCHANNEL_LEGS = 2;
  ANIMCHANNEL_HEAD = 3;
  ANIMCHANNEL_EYELIDS = 4;
  /// <summary>DECL_LEXER_FLAGS: the lexer flags a declaration (the MODELDEF too) is read with</summary>
  MODELDEF_LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS or LEXFL_ALLOWPATHNAMES or
    LEXFL_ALLOWMULTICHARLITERALS or LEXFL_ALLOWBACKSLASHSTRINGCONCAT or LEXFL_NOFATALERRORS;
  /// <summary>The name of a channel in a MODELDEF (channelNames)</summary>
  ANIM_CHANNEL_NAMES: array[0..ANIM_NUM_ANIM_CHANNELS - 1] of string =
    ('all', 'torso', 'legs', 'head', 'eyelids');

type
  /// <summary>frameCommandType_t, in the order of the original</summary>
  TAnimFrameCommandType = (
    fcScriptFunction, fcScriptFunctionObject, fcEventFunction, fcSound, fcSoundVoice, fcSoundVoice2,
    fcSoundBody, fcSoundBody2, fcSoundBody3, fcSoundWeapon, fcSoundItem, fcSoundGlobal, fcSoundChatter,
    fcSkin, fcTrigger, fcTriggerSmokeParticle, fcMelee, fcDirectDamage, fcBeginAttack, fcEndAttack,
    fcMuzzleFlash, fcCreateMissile, fcLaunchMissile, fcFireMissileAtTarget, fcFootstep, fcLeftFoot,
    fcRightFoot, fcEnableEyeFocus, fcDisableEyeFocus, fcFx, fcDisableGravity, fcEnableGravity, fcJump,
    fcEnableClip, fcDisableClip, fcEnableWalkIk, fcDisableWalkIk, fcEnableLegIk, fcDisableLegIk,
    fcRecordDemo, fcAviGame);

  /// <summary>
  ///   A command that fires on a frame of an animation (frameCommand_t). The game things it
  ///   points to (functions, sounds, skins) are only names here: the lookup is the game's.
  /// </summary>
  TAnimFrameCommand = record
    CommandType: TAnimFrameCommandType;
    /// <summary>The argument as written (the idStr of the original or the name of the declaration)</summary>
    Text: AnsiString;
    /// <summary>
    ///   True when the original keeps the text in a string (a sound key that starts with "snd_",
    ///   a script object function, an entity def...), False when it keeps the declaration found
    /// </summary>
    HasText: Boolean;
    /// <summary>The joint of fire_missile_at_target, the leg of enableLegIK and disableLegIK</summary>
    Index: Integer;
  end;

  /// <summary>animFlags_t</summary>
  TAnimFlags = record
    PreventIdleOverride: Boolean;
    RandomCycleStart: Boolean;
    AiNoTurn: Boolean;
    AnimTurn: Boolean;
  end;

  /// <summary>jointInfo_t: a joint of the model of a definition with its channel</summary>
  TAnimJointInfo = record
    Num: Integer;
    ParentNum: Integer;
    Channel: Integer;
  end;

  /// <summary>frameLookup_t: where the commands of a frame are in the list</summary>
  TAnimFrameLookup = record
    Num: Integer;
    FirstCommand: Integer;
  end;

  /// <summary>
  ///   A problem that the engine reports with <c>gameLocal.Error</c> (a joint handle out of range,
  ///   an anim that does not fit the model)
  /// </summary>
  EAnimException = class(Exception);

resourcestring
  SAnimJointHandle = 'Joint handle %d out of range (%d joints)';
  SAnimChannelRange = 'Channel %d out of range';
  SAnimModelJointCount = 'Model ''%s'' has different # of joints than anim ''%s''';
  SAnimModelJointNames = 'Model ''%s''''s joint names don''t match anim ''%s''''s';
  SAnimModelHierarchy = 'Model ''%s'' has different joint hierarchy than anim ''%s''';
  SAnimNoJoints = 'model ''%s'' has no joints';
  SAnimFrameRange = 'Frame %d out of range';
  SAnimEndOfLine = 'Unexpected end of line';
  SAnimUnknownCommand = 'Unknown command ''%s''';
  SAnimFunctionNotFound = 'Function ''%s'' not found';
  SAnimEventNotFound = 'Event ''%s'' not found';
  SAnimEventArguments = 'Event ''%s'' has arguments';
  SAnimSkinNotFound = 'Skin ''%s'' not found';
  SAnimFxNotFound = 'fx ''%s'' not found';
  SAnimEntityDefNotFound = 'Unknown entityDef ''%s''';
  SAnimJointNotFound = 'Joint ''%s'' not found';

implementation

end.
