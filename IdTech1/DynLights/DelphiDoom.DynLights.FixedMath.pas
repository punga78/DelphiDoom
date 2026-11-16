{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - fixed point division                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.FixedMath;

interface

type
  /// <summary>The fixed point division of the engine (m_fixed.FixedDiv), without assembler</summary>
  TDynLightFixedMath = class
  public
    /// <summary>
    ///   A / B with 16 bits of fraction, truncated toward zero; a result that does not fit is
    ///   the largest (or the smallest) integer, and a division by zero too
    /// </summary>
    class function Divide(A, B: Integer): Integer; static;
  end;

implementation

/// <summary>An arithmetic shift to the right of 14 bits: the sign is kept (the old _SHR14)</summary>
function ShiftRight14(AValue: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr 14
  else
    Result := not ((not AValue) shr 14);
end;

{ TDynLightFixedMath }

class function TDynLightFixedMath.Divide(A, B: Integer): Integer;
const
  FRACBITS = 16;
begin
  if ShiftRight14(Abs(A)) >= Abs(B) then
  begin
    if (A xor B) < 0 then
      Result := Low(Integer)
    else
      Result := High(Integer);
  end
  else
    Result := Integer((Int64(A) shl FRACBITS) div B);
end;

end.
