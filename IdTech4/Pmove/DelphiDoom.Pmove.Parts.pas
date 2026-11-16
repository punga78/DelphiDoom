{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the parts of the movement, assembled            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): bg_pmove.c and  }
{  bg_slidemove.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is      }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Parts;

interface

uses
  System.SysUtils, DelphiDoom.Pmove.State, DelphiDoom.Pmove.Events, DelphiDoom.Pmove.Physics,
  DelphiDoom.Pmove.Slider, DelphiDoom.Pmove.Body, DelphiDoom.Pmove.Ground, DelphiDoom.Pmove.AirMover,
  DelphiDoom.Pmove.WaterMover, DelphiDoom.Pmove.FlyMover, DelphiDoom.Pmove.WalkMover, DelphiDoom.Pmove.Weapon,
  DelphiDoom.Pmove.Footsteps;

type
  /// <summary>
  ///   The classes the functions of bg_pmove.c became, built on one state and freed together (they are plain
  ///   objects, not reference counted: they share the state and refer to each other)
  /// </summary>
  TPmoveParts = class
  strict private
    FEvents: TPmoveEvents;
    FPhysics: TPmovePhysics;
    FSlider: TPmoveSlider;
    FBody: TPmoveBody;
    FGround: TPmoveGround;
    FAir: TPmoveAirMover;
    FWater: TPmoveWaterMover;
    FFly: TPmoveFlyMover;
    FWalk: TPmoveWalkMover;
    FWeapon: TPmoveWeapon;
    FFootsteps: TPmoveFootsteps;
  public
    constructor Create(const AState: TPmoveState);
    destructor Destroy; override;
    property Body: TPmoveBody read FBody;
    property Ground: TPmoveGround read FGround;
    property Air: TPmoveAirMover read FAir;
    property Water: TPmoveWaterMover read FWater;
    property Fly: TPmoveFlyMover read FFly;
    property Walk: TPmoveWalkMover read FWalk;
    property Weapon: TPmoveWeapon read FWeapon;
    property Footsteps: TPmoveFootsteps read FFootsteps;
  end;

implementation

uses
  DelphiDoom.Pmove.Intf;

constructor TPmoveParts.Create(const AState: TPmoveState);
begin
  inherited Create;
  FEvents := TPmoveEvents.Create(AState);
  FPhysics := TPmovePhysics.Create(AState);
  FSlider := TPmoveSlider.Create(AState, FEvents);
  FBody := TPmoveBody.Create(AState);
  FGround := TPmoveGround.Create(AState, FEvents);
  FAir := TPmoveAirMover.Create(AState, FPhysics, FSlider);
  FWater := TPmoveWaterMover.Create(AState, FPhysics, FSlider);
  FFly := TPmoveFlyMover.Create(AState, FPhysics, FSlider);
  FWalk := TPmoveWalkMover.Create(AState, FEvents, FPhysics, FSlider, FWater as IPmoveWaterMovement,
    FAir as IPmoveMovement);
  FWeapon := TPmoveWeapon.Create(AState, FEvents);
  FFootsteps := TPmoveFootsteps.Create(AState, FEvents, FGround);
end;

destructor TPmoveParts.Destroy;
begin
  FFootsteps.Free;
  FWeapon.Free;
  FWalk.Free;
  FFly.Free;
  FWater.Free;
  FAir.Free;
  FGround.Free;
  FBody.Free;
  FSlider.Free;
  FPhysics.Free;
  FEvents.Free;
  inherited Destroy;
end;

end.
