{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the subsector of a point for the renderer library      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Renderer.SubsectorLocator;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Finds the subsector of a point walking down the nodes of the level (R_PointInSubSectorClassic)
  ///   and refuses the point that is on the side of one of the segs of the subsector, as the
  ///   precalculation of R_PrecalcPointInSubSector did
  /// </summary>
  TEngineRendererSubsectorLocator = class(TInterfacedObject, IRendererSubsectorLocator)
  public
    function Locate(AX, AY: Integer): Integer;
  end;

implementation

uses
  r_defs,
  r_main,
  p_setup;

{ TEngineRendererSubsectorLocator }

function TEngineRendererSubsectorLocator.Locate(AX, AY: Integer): Integer;
var
  LSubsector: Psubsector_t;
  LIndex: Integer;
begin
  LSubsector := R_PointInSubSectorClassic(AX, AY);
  for LIndex := 0 to LSubsector.numlines - 1 do
    if R_PointOnSegSide(AX, AY, @segs[LSubsector.firstline + LIndex]) then
    begin
      Result := -1;
      Exit;
    end;
  Result := (NativeInt(LSubsector) - NativeInt(@subsectors[0])) div SizeOf(subsector_t);
end;

end.
