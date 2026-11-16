{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, contracts          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cgame\          }
{  cg_players.c, cgame\cg_ents.c, renderer\tr_model.c. Copyright (C) 1999-2005 }
{  Id Software, Inc. This unit is derived from the Quake III Arena source code }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Types;

type
  /// <summary>What animation.cfg says: the options of the model and its animations</summary>
  IQ3AnimationConfig = interface
    ['{7E1C4A52-93B8-4D06-A5F2-C81D0B6E3947}']
    function GetFootsteps: TQ3Footsteps;
    function GetGender: TQ3Gender;
    function GetFixedLegs: Boolean;
    function GetFixedTorso: Boolean;
    function GetHeadOffset: TIdVec3;
    function GetAnimation(const AIndex: Integer): TQ3Animation;
    property Footsteps: TQ3Footsteps read GetFootsteps;
    property Gender: TQ3Gender read GetGender;
    /// <summary>"fixedlegs": the legs always face where the torso faces</summary>
    property FixedLegs: Boolean read GetFixedLegs;
    /// <summary>"fixedtorso": the torso does not pitch</summary>
    property FixedTorso: Boolean read GetFixedTorso;
    property HeadOffset: TIdVec3 read GetHeadOffset;
    /// <summary>The animation AIndex, 0 to Q3_MAX_TOTAL_ANIMATIONS - 1; raises EArgumentOutOfRangeException otherwise</summary>
    property Animations[const AIndex: Integer]: TQ3Animation read GetAnimation;
  end;

  /// <summary>The text of a file, from wherever the caller keeps it (a pak, a folder, the memory of a test)</summary>
  IQ3TextSource = interface
    ['{2B9D6F18-4C35-4E7A-8A01-D5F7E3B20C64}']
    /// <summary>The bytes of the file as text; empty if the file does not exist</summary>
    function ReadText(const AFileName: string): AnsiString;
  end;

  /// <summary>CG_ParseAnimationFile on a text</summary>
  IQ3AnimationParser = interface
    ['{A4C83E91-5D27-4B60-9F13-0E6B2A7D8C45}']
    /// <summary>Raises EQ3PlayerException (with the line) when the text is not an animation file</summary>
    function Parse(const AText: AnsiString; const AFileName: string): IQ3AnimationConfig;
  end;

  /// <summary>Reads the animation file from a source and parses it</summary>
  IQ3AnimationLoader = interface
    ['{F1D7A3B6-2E84-4C59-B037-6A9C5E1D8F20}']
    /// <summary>Raises EQ3AnimationMissingException if the source has no such file</summary>
    function Load(const AFileName: string): IQ3AnimationConfig;
  end;

  /// <summary>CG_SetLerpFrameAnimation, CG_RunLerpFrame and CG_ClearLerpFrame: one level of animation in time</summary>
  IQ3LerpFrameRunner = interface
    ['{5A0E9C73-B1D4-4F28-86E5-3C7D2B9A1F60}']
    procedure SetAnimation(var AFrame: TQ3LerpFrame; const ANewAnimation: Integer);
    procedure Clear(var AFrame: TQ3LerpFrame; const AAnimationNumber, ATime: Integer);
    procedure Run(var AFrame: TQ3LerpFrame; const ANewAnimation: Integer; const ASpeedScale: Single; const ATime: Integer);
  end;

  /// <summary>CG_PlayerAnimation: the two levels of the animation of a player (legs and torso)</summary>
  IQ3PlayerAnimator = interface
    ['{C3B85D17-6F02-4A94-A7E1-9D4F0B2C6E38}']
    /// <summary>The time is the caller's (cg.time); AHaste is the haste power-up (speed 1.5)</summary>
    procedure Animate(var APlayer: TQ3PlayerEntity; const ATime, ALegsAnim, ATorsoAnim: Integer;
      const AHaste: Boolean; out AFrames: TQ3PlayerFrames);
  end;

  /// <summary>CG_PlayerAngles, the part that does not touch the scene: the axes of legs, torso and head</summary>
  IQ3PlayerAngles = interface
    ['{8D4F2A61-C9E3-4B75-A108-7B5E6D3C0F92}']
    /// <summary>Raises EQ3PlayerException for a movement direction out of 0 to 7</summary>
    procedure Compute(const AInput: TQ3PlayerAngleInput; var APlayer: TQ3PlayerEntity;
      out ALegs, ATorso, AHead: TQ3Axis);
  end;

  /// <summary>R_LerpTag: the interpolated position of a tag between two frames of an MD3</summary>
  IQ3TagLerper = interface
    ['{E6A19B40-3D58-4C72-B9F4-1A8C0D7E5236}']
    /// <summary>
    ///   False (and an identity orientation) if the model is nil or has no such tag; frames
    ///   after the last one use the last. AFraction is the weight of the end frame.
    /// </summary>
    function LerpTag(const AModel: IMd3Model; const AStartFrame, AEndFrame: Integer; const AFraction: Single;
      const ATagName: AnsiString; out ATag: TQ3Orientation): Boolean;
  end;

  /// <summary>CG_PositionEntityOnTag and CG_PositionRotatedEntityOnTag</summary>
  IQ3TagPositioner = interface
    ['{4B7E0D29-A5C1-4F83-96D2-E0A13C8B5F74}']
    /// <summary>The entity is placed on the tag of the parent, its axes are the tag's times the parent's</summary>
    procedure PositionEntityOnTag(var AEntity: TQ3Entity; const AParent: TQ3Entity;
      const AParentModel: IMd3Model; const ATagName: AnsiString);
    /// <summary>As above, but the axes the entity has are rotated by the tag (the head on the torso)</summary>
    procedure PositionRotatedEntityOnTag(var AEntity: TQ3Entity; const AParent: TQ3Entity;
      const AParentModel: IMd3Model; const ATagName: AnsiString);
  end;

  /// <summary>The union of legs, torso and head of CG_Player</summary>
  IQ3PlayerAssembler = interface
    ['{9C2E5B08-D7A4-4136-8F61-B3E0A94D2C57}']
    /// <summary>
    ///   Legs at AOrigin with their axes; the torso on "tag_torso" of the legs model, the head on
    ///   "tag_head" of the torso model (both rotated by the axes that CG_PlayerAngles gave).
    /// </summary>
    procedure Assemble(const ALegsModel, ATorsoModel: IMd3Model; const AOrigin: TIdVec3;
      const ALegsAxis, ATorsoAxis, AHeadAxis: TQ3Axis; const AFrames: TQ3PlayerFrames;
      out ALegs, ATorso, AHead: TQ3Entity);
    /// <summary>A weapon on "tag_weapon" of the torso (CG_AddPlayerWeapon: the gun axes start as the identity)</summary>
    procedure PositionWeapon(const ATorso: TQ3Entity; const ATorsoModel: IMd3Model; out AGun: TQ3Entity);
  end;

implementation

end.
