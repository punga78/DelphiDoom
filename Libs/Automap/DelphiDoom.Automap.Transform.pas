{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - from map to frame buffer and back             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.Transform;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Automap.Types;

type
  /// <summary>
  ///   The old FTOM, MTOF, CXMTOF and CYMTOF on a window. They have no state and are static, so
  ///   the clipping of a line can call them without going through an interface.
  /// </summary>
  /// <remarks>
  ///   The wraparound of the 32 bit products is wanted (as in the old code), so the unit turns
  ///   overflow and range checks off.
  /// </remarks>
  TAutomapTransform = class
  public
    /// <summary>A distance in the frame buffer as a distance on the map (the old FTOM)</summary>
    class function FrameToMap(const AWindow: TAutomapWindow; const AValue: Integer): Integer; static;
    /// <summary>A distance on the map as a distance in the frame buffer (the old MTOF)</summary>
    class function MapToFrame(const AWindow: TAutomapWindow; const AValue: Integer): Integer; static;
    /// <summary>The x of a point of the map in the frame buffer (the old CXMTOF)</summary>
    class function MapToFrameX(const AWindow: TAutomapWindow; const AValue: Integer): Integer; static;
    /// <summary>The y of a point of the map in the frame buffer, upside down (the old CYMTOF)</summary>
    class function MapToFrameY(const AWindow: TAutomapWindow; const AValue: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath;

{ TAutomapTransform }

class function TAutomapTransform.FrameToMap(const AWindow: TAutomapWindow;
  const AValue: Integer): Integer;
begin
  Result := TFixedMath.Mul(AValue * FIXED_ONE, AWindow.ScaleFrameToMap);
end;

class function TAutomapTransform.MapToFrame(const AWindow: TAutomapWindow;
  const AValue: Integer): Integer;
begin
  Result := TFixedMath.Int64ToInteger(TFixedMath.Mul64(AValue, AWindow.ScaleMapToFrame));
end;

class function TAutomapTransform.MapToFrameX(const AWindow: TAutomapWindow;
  const AValue: Integer): Integer;
begin
  Result := AWindow.FrameX + MapToFrame(AWindow, AValue) - MapToFrame(AWindow, AWindow.MapX);
end;

class function TAutomapTransform.MapToFrameY(const AWindow: TAutomapWindow;
  const AValue: Integer): Integer;
begin
  Result := AWindow.FrameY +
    (AWindow.FrameHeight - MapToFrame(AWindow, AValue) + MapToFrame(AWindow, AWindow.MapY));
end;

end.
