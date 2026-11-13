{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - animations of idTech 4: contracts           }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim.h,        }
{  Anim.cpp and Anim_Blend.cpp. Copyright (C) 1999-2011 id Software LLC, a     }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Anim.Types;

type
  /// <summary>
  ///   A random integer in [0, AMax - 1] (the generator of the game): it picks one of the anims
  ///   with the same name
  /// </summary>
  TAnimRandomInt = reference to function(const AMax: Integer): Integer;

  /// <summary>
  ///   What the frame commands and the definitions ask to the game: does the function, event,
  ///   skin, fx or entity def exist. Replaces <c>gameLocal.program</c>, <c>idEventDef</c> and the
  ///   declaration manager.
  /// </summary>
  IModelDefGameLookup = interface
    ['{2D8C5A71-4E36-4B9A-A1C7-6F03E9D5B284}']
    function FindScriptFunction(const AName: AnsiString): Boolean;
    /// <summary>The event and the number of its arguments (an event used by a frame command has none)</summary>
    function FindEvent(const AName: AnsiString; out AArgumentCount: Integer): Boolean;
    function FindSkin(const AName: AnsiString): Boolean;
    function FindFx(const AName: AnsiString): Boolean;
    function FindEntityDef(const AName: AnsiString): Boolean;
    /// <summary>The sound shader does not exist (the original only warns)</summary>
    function IsSoundDefaulted(const AName: AnsiString): Boolean;
  end;

  /// <summary>
  ///   The animation of a definition (idAnim): the md5anims that it plays together, its names, the
  ///   flags and the commands of its frames. A command is a value; the md5anims are shared.
  /// </summary>
  IAnim = interface
    ['{A94E27C0-83D1-45F6-9B2E-D7510C6A38F4}']
    function GetName: AnsiString;
    function GetFullName: AnsiString;
    function GetNumAnims: Integer;
    function GetFlags: TAnimFlags;
    procedure SetFlags(const AValue: TAnimFlags);
    function GetFrameCommandCount: Integer;
    /// <summary>idAnim::Name: the name without the numeric suffix</summary>
    property Name: AnsiString read GetName;
    /// <summary>idAnim::FullName: the name of the definition with its suffix</summary>
    property FullName: AnsiString read GetFullName;
    property NumAnims: Integer read GetNumAnims;
    property Flags: TAnimFlags read GetFlags write SetFlags;
    property FrameCommandCount: Integer read GetFrameCommandCount;
    /// <summary>idAnim::MD5Anim: nil out of range</summary>
    function GetMd5Anim(const ANumber: Integer): IMd5Anim;
    /// <summary>idAnim::Length: 0 without anims</summary>
    function Length: Integer;
    function NumFrames: Integer;
    function TotalMovementDelta: TIdVec3;
    function GetOrigin(const AAnimNumber, ATime, ACycleCount: Integer; out AOffset: TIdVec3): Boolean;
    function GetOriginRotation(const AAnimNumber, ATime, ACycleCount: Integer; out ARotation: TIdQuat): Boolean;
    function GetBounds(const AAnimNumber, ATime, ACycleCount: Integer; out ABounds: TGeoBounds): Boolean;
    /// <summary>
    ///   Puts the command on a frame (zero based) as AddFrameCommand does once it has parsed it:
    ///   the commands of the later frames move up. The frame must exist.
    /// </summary>
    procedure AddFrameCommand(const AFrame: Integer; const ACommand: TAnimFrameCommand);
    /// <summary>The commands of a frame (zero based), in the order they were added</summary>
    function GetFrameCommands(const AFrame: Integer): TArray<TAnimFrameCommand>;
    function HasFrameCommands: Boolean;
    /// <summary>
    ///   FindFrameForFrameCommand: the first frame (zero based) that has a command of the type,
    ///   -1 if none; the command is the first found
    /// </summary>
    function FindFrameForFrameCommand(const AType: TAnimFrameCommandType;
      out ACommand: TAnimFrameCommand): Integer;
    /// <summary>idAnim(modelDef, anim): a copy that shares the md5anims (and counts them)</summary>
    function Clone: IAnim;
  end;

  /// <summary>
  ///   A definition of a model: the md5mesh, the joints with their channels, the offset and the
  ///   anims (idDeclModelDef). A defaulted one is empty.
  /// </summary>
  IModelDef = interface
    ['{5B1F7D92-C463-4E08-8A3D-E92B07C14F65}']
    function GetName: AnsiString;
    function GetModel: IMd5Model;
    function GetSkinName: AnsiString;
    function GetOffset: TIdVec3;
    function GetNumJoints: Integer;
    function GetJointInfo(const AHandle: Integer): TAnimJointInfo;
    function GetJointParents: TArray<Integer>;
    function GetNumAnims: Integer;
    function GetDefaulted: Boolean;
    property Name: AnsiString read GetName;
    /// <summary>The md5 model (ModelHandle), nil when there is none</summary>
    property Model: IMd5Model read GetModel;
    /// <summary>The name of the default skin, empty if none (the skin is not looked up here)</summary>
    property SkinName: AnsiString read GetSkinName;
    /// <summary>GetVisualOffset</summary>
    property Offset: TIdVec3 read GetOffset;
    property NumJoints: Integer read GetNumJoints;
    property JointInfo[const AHandle: Integer]: TAnimJointInfo read GetJointInfo;
    property JointParents: TArray<Integer> read GetJointParents;
    /// <summary>NumAnims: the anims plus 1, the anim 0 is "no anim"</summary>
    property NumAnims: Integer read GetNumAnims;
    /// <summary>The definition could not be parsed (DS_DEFAULTED)</summary>
    property Defaulted: Boolean read GetDefaulted;
    function GetModelName: AnsiString;
    /// <summary>GetAnim(index): index 1 is the first, nil out of range</summary>
    function GetAnimByIndex(const AIndex: Integer): IAnim;
    function HasAnim(const AName: AnsiString): Boolean;
    /// <summary>GetSpecificAnim: the exact anim for a full name, 0 if none</summary>
    function GetSpecificAnim(const AName: AnsiString): Integer;
    /// <summary>
    ///   GetAnim(name): a name that ends with a digit is a specific anim; otherwise one of the
    ///   anims with that name is picked at random (up to 64). 0 if none.
    /// </summary>
    function GetAnim(const AName: AnsiString; const ARandom: TAnimRandomInt): Integer;
    /// <summary>FindJoint: the handle of the joint with the name (ASCII, ignoring case), -1 if none</summary>
    function FindJoint(const AName: AnsiString): Integer;
    /// <summary>GetJointName</summary>
    function GetJointName(const AHandle: Integer): AnsiString;
    /// <summary>
    ///   GetJointList: a list of names (a name may start with "-" to remove it and with "*" to
    ///   include its children); an unknown joint is a warning. Empty without a model.
    /// </summary>
    function GetJointList(const AJointNames: AnsiString; const ALog: IIdLibLog): TArray<Integer>;
    function NumJointsOnChannel(const AChannel: Integer): Integer;
    function GetChannelJoints(const AChannel: Integer): TArray<Integer>;
    /// <summary>
    ///   SetupJoints: the absolute matrices of the default pose with the offset (the origin is
    ///   replaced by the offset when ARemoveOriginOffset) and the bounds of the model. The list
    ///   is empty (and the bounds cleared) without a model.
    /// </summary>
    function SetupJoints(const ARemoveOriginOffset: Boolean; out ABounds: TGeoBounds): TArray<TMd5JointMat>;
  end;

  /// <summary>Finds the models and the definitions that a definition uses</summary>
  IModelDefSource = interface
    ['{E1630B4C-9D27-4A58-B3F1-48C5A02D97E6}']
    /// <summary>
    ///   FindModel of the model manager for an md5mesh: nil when the file is not an md5mesh or
    ///   there is no model at all; <c>ADefaulted</c> is true when the manager gave the default model
    /// </summary>
    function FindMd5Model(const AName: AnsiString; out ADefaulted: Boolean): IMd5Model;
    /// <summary>The definition to inherit from: nil if unknown; ADefaulted when it failed to parse</summary>
    function FindModelDef(const AName: AnsiString; out ADefaulted: Boolean): IModelDef;
  end;

  /// <summary>The reader of a MODELDEF declaration</summary>
  IModelDefParser = interface
    ['{7A4D90E3-1B65-4F2C-9E08-D3C57B1F6A92}']
    /// <summary>
    ///   idDeclModelDef::Parse for the text of a declaration (the body in braces). A problem is a
    ///   warning in the log and the result is the defaulted definition (<c>Defaulted</c> True),
    ///   as MakeDefault does.
    /// </summary>
    function Parse(const AName, AText: AnsiString): IModelDef;
  end;

  /// <summary>The cache of the md5anims and the names of the joints (idAnimManager)</summary>
  IAnimManager = interface
    ['{C3E8149A-6D07-4B25-81FA-95B0D72E4C13}']
    /// <summary>
    ///   GetAnim: the md5anim of a file name, loaded the first time; nil if the name is not an
    ///   md5anim or the file does not load (and the failure is remembered, with a warning only
    ///   the first time)
    /// </summary>
    function GetAnim(const AName: AnsiString): IMd5Anim;
    /// <summary>ReloadAnims: reads again every anim that is loaded and replaces it</summary>
    procedure ReloadAnims;
    /// <summary>JointIndex: the index of a joint name in the pool, added if new (case sensitive)</summary>
    function JointIndex(const AName: AnsiString): Integer;
    function JointName(const AIndex: Integer): AnsiString;
    function NumJointNames: Integer;
    /// <summary>The users of an md5anim (idMD5Anim::numRefs)</summary>
    function NumRefs(const AAnim: IMd5Anim): Integer;
    procedure IncreaseRefs(const AAnim: IMd5Anim);
    procedure DecreaseRefs(const AAnim: IMd5Anim);
    /// <summary>FlushUnusedAnims: forgets the anims nobody uses; true if there were some</summary>
    function FlushUnusedAnims: Boolean;
    /// <summary>The number of anims loaded (not counting the failures)</summary>
    function NumAnims: Integer;
    /// <summary>Shutdown: forgets anims and joint names</summary>
    procedure Shutdown;
    /// <summary>
    ///   idMD5Anim::CheckModelHierarchy: the joints of the anim and of the model must be the same
    ///   (EAnimException)
    /// </summary>
    procedure CheckModelHierarchy(const AAnim: IMd5Anim; const AModel: IMd5Model);
  end;

implementation

end.
