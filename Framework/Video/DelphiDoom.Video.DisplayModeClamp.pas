{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the limits of a requested display mode           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.DisplayModeClamp;

interface

type
  /// <summary>
  ///   Brings a requested display mode inside the limits of the engine (the rule of V_SetDisplayMode). Static,
  ///   no state
  /// </summary>
  TVideoDisplayModeClamp = class sealed
  public
    /// <summary>
    ///   Makes both sides even, keeps each one between its minimum and its maximum and never lets the height
    ///   exceed the width
    /// </summary>
    /// <remarks>
    ///   The old code wrote the width instead of the height when the height was over the maximum
    ///   (nwidth := MAXHEIGHT); the height was then left unlimited. Fixed
    /// </remarks>
    class procedure Clamp(const ARequestedWidth, ARequestedHeight, AMinWidth, AMinHeight, AMaxWidth,
      AMaxHeight: Integer; out AWidth, AHeight: Integer); static;
  end;

implementation

{ TVideoDisplayModeClamp }

class procedure TVideoDisplayModeClamp.Clamp(const ARequestedWidth, ARequestedHeight, AMinWidth, AMinHeight,
  AMaxWidth, AMaxHeight: Integer; out AWidth, AHeight: Integer);
begin
  AWidth := ARequestedWidth and not 1;
  if AWidth > AMaxWidth then
    AWidth := AMaxWidth
  else if AWidth < AMinWidth then
    AWidth := AMinWidth;

  AHeight := ARequestedHeight and not 1;
  if AHeight > AMaxHeight then
    AHeight := AMaxHeight
  else if AHeight < AMinHeight then
    AHeight := AMinHeight;

  if AHeight > AWidth then
    AHeight := AWidth;
end;

end.
