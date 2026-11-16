{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdInterpolateAccelDecelLinear<T>   }
{                                                                              }
{  Port of idInterpolateAccelDecelLinear (idlib\math\Interpolate.h) of the     }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax  }
{  Media company. Based on the Doom 3 GPL Source Code (id Software).           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Interpolate.AccelDecelLinear;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Interpolate.AccelDecel;

type
  /// <summary>
  ///   Continuous interpolation with a linear acceleration and a linear deceleration phase: the
  ///   velocity is continuous, the acceleration is not (idInterpolateAccelDecelLinear)
  /// </summary>
  TIdInterpolateAccelDecelLinear<T> = class(TIdInterpolateAccelDecel<T>)
  strict protected
    function GetAccelerationType: Integer; override;
    function GetDecelerationType: Integer; override;
    function GetPhaseFactor: Single; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Extrapolate;

{ TIdInterpolateAccelDecelLinear<T> }

function TIdInterpolateAccelDecelLinear<T>.GetAccelerationType: Integer;
begin
  Result := ID_EXTRAPOLATION_ACCELLINEAR;
end;

function TIdInterpolateAccelDecelLinear<T>.GetDecelerationType: Integer;
begin
  Result := ID_EXTRAPOLATION_DECELLINEAR;
end;

function TIdInterpolateAccelDecelLinear<T>.GetPhaseFactor: Single;
begin
  Result := 0.5;
end;

end.
