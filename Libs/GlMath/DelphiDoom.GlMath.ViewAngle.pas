{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL math library - the angle of the view for the clipper     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlMath.ViewAngle;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.GlMath.Types;

type
  /// <summary>The half angle of the view that the clipper keeps visible (the old gld_FrustumAngle)</summary>
  TGlViewAngle = class
  public
    /// <summary>
    ///   The half angle of the view for a look direction and the aspect of the monitor. Over about
    ///   46 degrees of tilt (ALookDirection16 is in 1/32 of a degree) the view sees all around.
    ///   The expression is the old one, a rough one that does not overestimate too much.
    /// </summary>
    class function FrustumAngle(const ALookDirection16: Integer;
      const ARelativeAspect: Double): TGlAngle; static;
  end;

implementation

uses
  System.SysUtils;

{ TGlViewAngle }

class function TGlViewAngle.FrustumAngle(const ALookDirection16: Integer;
  const ARelativeAspect: Double): TGlAngle;
var
  LTilt: Single;
begin
  LTilt := Abs(ALookDirection16 / 32);

  // if the pitch is larger than this you can look all around at a FOV of 90
  if LTilt > 46.0 then
  begin
    Result := GLMATH_ANGLE_MAX;
    Exit;
  end;

  Result := Round(GLMATH_ANG1 * (2.0 + (45.0 * ARelativeAspect + (LTilt / 1.9))));
  if Result >= GLMATH_ANG180 then
    Result := GLMATH_ANGLE_MAX;
end;

end.
