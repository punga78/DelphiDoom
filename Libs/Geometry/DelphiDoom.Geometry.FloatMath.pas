{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - float helpers                                 }
{                                                                              }
{  Port of idMath (Math.h) and of the sign-bit macros of Doom 3 GPL Source     }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.FloatMath;

interface

type
  /// <summary>The few idMath functions and bit tricks the geometry and collision code use</summary>
  /// <remarks>
  ///   <c>Sqrt</c>, <c>InvSqrt</c> and <c>Rint</c> are a bridge to <c>TIdMath</c> of <c>Libs\IdLib\Math</c>,
  ///   the port of idMath that is verified bit for bit against the C++ (idMath::InvSqrt is a table plus
  ///   two Newton steps, idMath::Sqrt is x * InvSqrt(x)): one implementation of those functions in the
  ///   repository. Before the bridge they were computed in Double and rounded, one ULP away from the C++
  ///   in some cases.
  /// </remarks>
  TGeoMath = class sealed
  public
    class function Fabs(AValue: Single): Single; static; inline;
    class function Sqrt(AValue: Single): Single; static;
    class function InvSqrt(AValue: Single): Single; static;
    /// <summary>idMath::Rint is floorf(f + 0.5f), not the round-to-even of rint()</summary>
    class function Rint(AValue: Single): Single; static;
    /// <summary>1 when the sign bit is set (also for -0.0), as FLOATSIGNBITSET</summary>
    class function FloatSignBitSet(AValue: Single): Cardinal; static; inline;
    /// <summary>1 when the sign bit is clear, as FLOATSIGNBITNOTSET</summary>
    class function FloatSignBitNotSet(AValue: Single): Cardinal; static; inline;
    /// <summary>1 when the integer is negative, as INTSIGNBITSET</summary>
    class function IntSignBitSet(AValue: Integer): Cardinal; static; inline;
    /// <summary>1 when the integer is not negative, as INTSIGNBITNOTSET</summary>
    class function IntSignBitNotSet(AValue: Integer): Cardinal; static; inline;
    /// <summary>C++ "1 &lt;&lt; n" on a 32 bit unsigned: the shift count wraps modulo 32 as on x86</summary>
    class function BitMask(ABitNumber: Integer): Cardinal; static; inline;
    class function Deg2Rad(ADegrees: Single): Single; static; inline;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

{ TGeoMath }

class function TGeoMath.Fabs(AValue: Single): Single;
begin
  if AValue < 0 then
    Result := -AValue
  else
    Result := AValue;
end;

class function TGeoMath.Sqrt(AValue: Single): Single;
begin
  Result := TIdMath.Sqrt(AValue);
end;

class function TGeoMath.InvSqrt(AValue: Single): Single;
begin
  Result := TIdMath.InvSqrt(AValue);
end;

class function TGeoMath.Rint(AValue: Single): Single;
begin
  Result := TIdMath.Rint(AValue);
end;

class function TGeoMath.FloatSignBitSet(AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^ shr 31;
end;

class function TGeoMath.FloatSignBitNotSet(AValue: Single): Cardinal;
begin
  Result := (not PCardinal(@AValue)^) shr 31;
end;

class function TGeoMath.IntSignBitSet(AValue: Integer): Cardinal;
begin
  Result := Cardinal(AValue) shr 31;
end;

class function TGeoMath.IntSignBitNotSet(AValue: Integer): Cardinal;
begin
  Result := (not Cardinal(AValue)) shr 31;
end;

class function TGeoMath.BitMask(ABitNumber: Integer): Cardinal;
begin
  Result := Cardinal(1) shl (ABitNumber and 31);
end;

class function TGeoMath.Deg2Rad(ADegrees: Single): Single;
begin
  Result := ADegrees * (Pi / 180.0);
end;

end.
