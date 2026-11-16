{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL context - the limits of a new screen size                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlContext.DisplayModeClamp;

interface

type
  /// <summary>The smallest and the biggest screen the engine can draw</summary>
  TGlDisplayModeLimits = record
    MinWidth: Integer;
    MaxWidth: Integer;
    MinHeight: Integer;
    MaxHeight: Integer;
  end;

  /// <summary>The size of the screen after a change of video mode (the first part of GL_SetDisplayMode)</summary>
  TGlDisplayModeClamp = class sealed
  public
    /// <summary>
    ///   Makes both sizes even, brings them inside the limits and never lets the height be bigger than the width.
    ///   Kept as it was: a height over the maximum sets the width (not the height) to MaxHeight, and the final
    ///   rule then gives the height the same value
    /// </summary>
    class procedure Clamp(const ANewWidth, ANewHeight: Integer; const ALimits: TGlDisplayModeLimits;
      out AWidth, AHeight: Integer); static;
  end;

implementation

{ TGlDisplayModeClamp }

class procedure TGlDisplayModeClamp.Clamp(const ANewWidth, ANewHeight: Integer; const ALimits: TGlDisplayModeLimits;
  out AWidth, AHeight: Integer);
begin
  AWidth := ANewWidth and not 1;
  if AWidth > ALimits.MaxWidth then
    AWidth := ALimits.MaxWidth
  else if AWidth < ALimits.MinWidth then
    AWidth := ALimits.MinWidth;

  AHeight := ANewHeight and not 1;
  if AHeight > ALimits.MaxHeight then
    AWidth := ALimits.MaxHeight
  else if AHeight < ALimits.MinHeight then
    AHeight := ALimits.MinHeight;

  if AHeight > AWidth then
    AHeight := AWidth;
end;

end.
