{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the physics an entity asks of its body    }
{                                                                              }
{  The small part of game\physics\Physics.h that the entity classes of this    }
{  phase use (position, bounds, time, evaluation and the end of a motion).     }
{  Written for this repository; licensed under the GNU General Public License, }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Physics.Intf;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.D3Game.ClipModel;

type
  /// <summary>
  ///   idPhysics reduced to what <c>idEntity::RunPhysics</c> and the movers use. There is no clipping, no team, no
  ///   pushing and no angle in this phase: <c>Evaluate</c> says if the body moved.
  /// </summary>
  ID3Physics = interface
    ['{91D4E6B2-0A37-4C85-8F1D-6B3C2E9A57F0}']
    function GetOrigin: TIdVec3;
    procedure SetOrigin(const AOrigin: TIdVec3);
    /// <summary>The corners of the absolute bounds; both are the origin for a body that has no size</summary>
    function GetAbsBoundsMin: TIdVec3;
    function GetAbsBoundsMax: TIdVec3;
    /// <summary>idPhysics::Evaluate: false if the body did not move</summary>
    function Evaluate(const ATimeStepMSec, AEndTimeMSec: Integer): Boolean;
    procedure UpdateTime(const AEndTimeMSec: Integer);
    function GetTime: Integer;
    /// <summary>The end of the linear motion in ms of game time, 0 if there is none</summary>
    function GetLinearEndTime: Integer;
    function GetAngularEndTime: Integer;
    function IsAtRest: Boolean;
    /// <summary>idPhysics::GetAxis</summary>
    function GetAxis: TIdMat3;
    /// <summary>idPhysics::SetAxis: relinks the clip model</summary>
    procedure SetAxis(const AAxis: TIdMat3);
    /// <summary>
    ///   idPhysics::SetClipModel: the physics owns the model and links it at its origin and axis. A game with no clip
    ///   gives the model back to nobody: the model is freed.
    /// </summary>
    procedure SetClipModel(const AModel: TD3ClipModel);
    /// <summary>
    ///   idPhysics::GetClipModel: nil if there is none (the original gives the default clip model; a caller checks
    ///   <c>GetNumClipModels</c> first, as <c>idClip::GetTraceClipModels</c> does)
    /// </summary>
    function GetClipModel: TD3ClipModel;
    function GetNumClipModels: Integer;
    procedure SetContents(const AContents: Integer);
    function GetContents: Integer;
    procedure DisableClip;
    procedure EnableClip;
    procedure UnlinkClip;
    procedure LinkClip;
    /// <summary>idPhysics::ClipContents: the contents of the clip model of the physics in a clip model (nil: in the world)</summary>
    function ClipContents(const AModel: TD3ClipModel): Integer;
  end;

implementation

end.
