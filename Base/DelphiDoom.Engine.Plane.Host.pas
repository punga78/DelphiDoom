{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the game does when a plane of a sector moves      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Plane.Host;

interface

uses
  DelphiDoom.Thinkers.Plane.Intf;

type
  /// <summary>
  ///   Answers the moving planes of the library with P_ChangeSector and P_DynamicSlope. It has
  ///   no state: the same object serves every sector
  /// </summary>
  TEnginePlaneHost = class(TInterfacedObject, IPlaneSectorHost)
  public
    function ChangeSector(ASector: Pointer; ACrush: Boolean): Boolean;
    procedure PlaneMoved(ASector: Pointer);
  end;

implementation

uses
  r_defs,
  p_map,
  p_slopes;

{ TEnginePlaneHost }

function TEnginePlaneHost.ChangeSector(ASector: Pointer; ACrush: Boolean): Boolean;
begin
  Result := P_ChangeSector(Psector_t(ASector), ACrush);
end;

procedure TEnginePlaneHost.PlaneMoved(ASector: Pointer);
begin
  // JVAL: Slopes
  P_DynamicSlope(Psector_t(ASector));
end;

end.
