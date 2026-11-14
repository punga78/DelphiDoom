{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - AM_drawFline of am_map.pas as it was before             }
{  TAutomapLineRasterizer                                                      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.OldLine;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Automap.Types;

type
  /// <summary>
  ///   Copy of the software AM_drawFline of Base\am_map.pas at 54262e7a (issue #185), with its
  ///   nested PUTDOT. The globals of the engine (amstate, viewwindowx/y, viewwidth/height,
  ///   videomode, fb, fb32, f_w, videopal) are fields
  /// </summary>
  TOldAutomapLine = class(TObject)
  public
    Overlay: Boolean;
    viewwindowx: Integer;
    viewwindowy: Integer;
    viewwidth: Integer;
    viewheight: Integer;
    Is32Bit: Boolean;
    fb: array of Byte;
    fb32: array of Cardinal;
    f_w: Integer;
    videopal: array[0..255] of Cardinal;
    procedure AM_drawFline(const fl: TAutomapFrameLine; color: Integer);
  end;

implementation

{ TOldAutomapLine }

procedure TOldAutomapLine.AM_drawFline(const fl: TAutomapFrameLine; color: Integer);
var
  x, y,
  dx, dy,
  sx, sy,
  ax, ay,
  d: integer;

  procedure PUTDOT(xx, yy, cc: integer);
  begin
  // JVAL Clip line if in overlay mode
    if Overlay then
    begin
      if yy <= viewwindowy then
        exit;
      if yy >= viewwindowy + viewheight then
        exit;
      if xx <= viewwindowx then
        exit;
      if xx >= viewwindowx + viewwidth then
        exit;
    end;
    if Is32Bit then
      fb32[yy * f_w + xx] := videopal[cc]
    else
      fb[yy * f_w + xx] := cc;
  end;

begin
  dx := fl.b.x - fl.a.x;
  ax := 2 * abs(dx);
  if dx < 0 then
    sx := -1
  else
    sx := 1;

  dy := fl.b.y - fl.a.y;
  ay := 2 * abs(dy);
  if dy < 0 then
    sy := -1
  else
    sy := 1;

  x := fl.a.x;
  y := fl.a.y;

  if ax > ay then
  begin
    d := ay - ax div 2;
    while true do
    begin
      PUTDOT(x, y, color);
      if x = fl.b.x then exit;
      if d >= 0 then
      begin
        y := y + sy;
        d := d - ax;
      end;
      x := x + sx;
      d := d + ay;
    end;
  end
  else
  begin
    d := ax - ay div 2;
    while true do
    begin
      PUTDOT(x, y, color);
      if y = fl.b.y then exit;
      if d >= 0 then
      begin
        x := x + sx;
        d := d - ay;
      end;
      y := y + sy;
      d := d + ax;
    end;
  end;
end;

end.
