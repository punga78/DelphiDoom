{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a line seen by the teleports                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Teleport.LineSide;

interface

uses
  r_defs,
  DelphiDoom.Thinkers.Teleport.Intf;

type
  /// <summary>The exit line of a silent line teleport, which says on which side of it a point is</summary>
  TEngineTeleportLineSide = class(TInterfacedObject, ITeleportLineSide)
  strict private
    FLine: Pline_t;
  public
    constructor Create(ALine: Pline_t);
    function PointOnSide(AX, AY: Integer): Integer;
  end;

implementation

uses
  p_maputl;

{ TEngineTeleportLineSide }

constructor TEngineTeleportLineSide.Create(ALine: Pline_t);
begin
  inherited Create;
  FLine := ALine;
end;

function TEngineTeleportLineSide.PointOnSide(AX, AY: Integer): Integer;
begin
  Result := P_PointOnLineSide(AX, AY, FLine);
end;

end.
