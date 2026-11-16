{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - travel time through an area             }
{                                                                              }
{  Port of idAASLocal::AreaTravelTime (AAS_routing.cpp), Doom 3 GPL Source     }
{  Code.                                                                       }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Framework\IdLib); the repository as a whole is }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.TravelTime;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>The time to walk, swim or crouch between two points of an area</summary>
  TAasTravelTime = class sealed
  public
    /// <summary>
    ///   The travel time between two points inside an area with the travel flags given, in 100th of a
    ///   second: the distance scaled by 100/100 when crouching, by 100/150 in water and by 100/300
    ///   otherwise, at least 1, rounded to nearest even (idMath::FtoiFast) and wrapped to 16 bits
    ///   as the unsigned short of the original
    /// </summary>
    class function Calculate(const ATravelFlags: Integer; const AStart, AEnd: TGeoVec3): Word; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.MapFile.Aas.Types;

const
  // 100.0f / 100.0f, 100.0f / 150.0f and 100.0f / 300.0f as the float constants of the C compiler
  // (the decimal expansion of the nearest float, never a literal that is rounded as an Extended)
  CCrouchScale: Single = 1.0;
  CWaterScale: Single = 0.666666686534881591796875;
  CWalkScale: Single = 0.3333333432674407958984375;

{ TAasTravelTime }

class function TAasTravelTime.Calculate(const ATravelFlags: Integer; const AStart, AEnd: TGeoVec3): Word;
var
  LDelta: TGeoVec3;
  LDist: Single;
begin
  LDelta := AEnd - AStart;
  LDist := LDelta.Length;
  if (ATravelFlags and TFL_CROUCH) <> 0 then
    LDist := LDist * CCrouchScale
  else if (ATravelFlags and TFL_WATER) <> 0 then
    LDist := LDist * CWaterScale
  else
    LDist := LDist * CWalkScale;
  if LDist < 1.0 then
    Exit(1);
  Result := Word(TIdMath.FtoiFast(LDist) and $FFFF);
end;

end.
