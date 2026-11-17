{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdInterpolateAccelDecelSine<T>     }
{                                                                              }
{  Port of idInterpolateAccelDecelSine (idlib\math\Interpolate.h) of the       }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax  }
{  Media company. Based on the Doom 3 GPL Source Code (id Software).           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Interpolate.AccelDecelSine;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Interpolate.AccelDecel;

type
  /// <summary>
  ///   Continuous interpolation with a sinusoidal acceleration and a sinusoidal deceleration
  ///   phase: velocity and acceleration are continuous (idInterpolateAccelDecelSine)
  /// </summary>
  TIdInterpolateAccelDecelSine<T> = class(TIdInterpolateAccelDecel<T>)
  strict protected
    function GetAccelerationType: Integer; override;
    function GetDecelerationType: Integer; override;
    function GetPhaseFactor: Single; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.Extrapolate;

{ TIdInterpolateAccelDecelSine<T> }

function TIdInterpolateAccelDecelSine<T>.GetAccelerationType: Integer;
begin
  Result := ID_EXTRAPOLATION_ACCELSINE;
end;

function TIdInterpolateAccelDecelSine<T>.GetDecelerationType: Integer;
begin
  Result := ID_EXTRAPOLATION_DECELSINE;
end;

function TIdInterpolateAccelDecelSine<T>.GetPhaseFactor: Single;
begin
  Result := ID_SQRT_1OVER2;
end;

end.
