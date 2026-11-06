{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the bounding boxes                          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.BoundingBox;

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>The functions of the old m_bbox on a TBoundingBox (TOP, BOTTOM, LEFT, RIGHT)</summary>
  TBoundingBoxMath = class
  public
    /// <summary>Makes the box empty: the next point gives its first corner (the old M_ClearBox)</summary>
    class procedure Clear(var ABox: TBoundingBox); static; inline;
    /// <summary>Grows the box to hold a point (the old M_AddToBox)</summary>
    class procedure AddPoint(var ABox: TBoundingBox; const AX, AY: TFixed); static; inline;
  end;

implementation

{ TBoundingBoxMath }

class procedure TBoundingBoxMath.Clear(var ABox: TBoundingBox);
begin
  ABox[BOX_TOP] := FIXED_MIN;
  ABox[BOX_RIGHT] := FIXED_MIN;
  ABox[BOX_BOTTOM] := FIXED_MAX;
  ABox[BOX_LEFT] := FIXED_MAX;
end;

class procedure TBoundingBoxMath.AddPoint(var ABox: TBoundingBox; const AX, AY: TFixed);
begin
  // the "else" is the one of the old code: a point is never both left and right
  if AX < ABox[BOX_LEFT] then
    ABox[BOX_LEFT] := AX
  else if AX > ABox[BOX_RIGHT] then
    ABox[BOX_RIGHT] := AX;
  if AY < ABox[BOX_BOTTOM] then
    ABox[BOX_BOTTOM] := AY
  else if AY > ABox[BOX_TOP] then
    ABox[BOX_TOP] := AY;
end;

end.
