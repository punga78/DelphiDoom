{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the contract of the moving planes            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Plane.Intf;

interface

type
  /// <summary>
  ///   What the move of a plane asks of the game about a sector. One object serves every sector:
  ///   the sector is an opaque pointer that the library gives back without looking at it, so a
  ///   step of a plane makes no allocation
  /// </summary>
  IPlaneSectorHost = interface
    ['{2D8F6A41-93BC-4E07-A5D1-7B3C0E9164F8}']
    /// <summary>
    ///   Tells the game that a plane of the sector moved: things are moved or hurt (P_ChangeSector).
    ///   It gives True when something blocks the new height (ACrush is the crush flag)
    /// </summary>
    function ChangeSector(ASector: Pointer; ACrush: Boolean): Boolean;
    /// <summary>Called when a step ended without being blocked: the slopes of the sector are updated</summary>
    procedure PlaneMoved(ASector: Pointer);
  end;

implementation

end.
