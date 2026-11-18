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
  DelphiDoom.IdLib.Math.Vec3;

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
  end;

implementation

end.
