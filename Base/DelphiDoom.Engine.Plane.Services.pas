{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the services that the moving planes use                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Plane.Services;

interface

uses
  r_defs,
  DelphiDoom.Thinkers.Plane.Types,
  DelphiDoom.Thinkers.Plane.Intf;

//==============================================================================
//
// P_ConfigurePlanes
//
// Gives the moving planes what they need from the rest of the engine (the
// composition root calls it); until it is called they give an I_Error
//
//==============================================================================
procedure P_ConfigurePlanes(const AHost: IPlaneSectorHost);

//==============================================================================
//
// PlaneHost
//
//==============================================================================
function PlaneHost: IPlaneSectorHost;

//==============================================================================
//
// PlaneMove
//
// One step of a floor (floorOrCeiling = 0) or of a ceiling (1) of a sector: the
// old T_MovePlane of every game, with the rules of the game. Any other value of
// floorOrCeiling moves nothing and gives Ok, as the old code did
//
//==============================================================================
function PlaneMove(const ASector: Psector_t; ASpeed, ADestination: integer;
  ACrush: boolean; AFloorOrCeiling, ADirection: integer;
  const ARules: TPlaneMoveRules): TPlaneMoveResult;

implementation

uses
  i_system,
  DelphiDoom.Thinkers.Plane.Mover;

var
  plane_host: IPlaneSectorHost;

//==============================================================================
//
// P_ConfigurePlanes
//
//==============================================================================
procedure P_ConfigurePlanes(const AHost: IPlaneSectorHost);
begin
  plane_host := AHost;
end;

//==============================================================================
//
// PlaneHost
//
//==============================================================================
function PlaneHost: IPlaneSectorHost;
begin
  if plane_host = nil then
    I_Error('P_ConfigurePlanes(): the services of the moving planes were not given');
  result := plane_host;
end;

//==============================================================================
//
// PlaneMove
//
//==============================================================================
function PlaneMove(const ASector: Psector_t; ASpeed, ADestination: integer;
  ACrush: boolean; AFloorOrCeiling, ADirection: integer;
  const ARules: TPlaneMoveRules): TPlaneMoveResult;
var
  LHost: IPlaneSectorHost;
begin
  LHost := PlaneHost;
  case AFloorOrCeiling of
    0:
      result := TPlaneMover.Move(ASector.floorheight, ASector.ceilingheight,
        ASpeed, ADestination, ACrush, TPlaneKind.Floor, ADirection, ARules,
        LHost, ASector);
    1:
      result := TPlaneMover.Move(ASector.ceilingheight, ASector.floorheight,
        ASpeed, ADestination, ACrush, TPlaneKind.Ceiling, ADirection, ARules,
        LHost, ASector);
  else
    begin
      LHost.PlaneMoved(ASector);
      result := TPlaneMoveResult.Ok;
    end;
  end;
end;

end.
