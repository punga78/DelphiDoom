{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - numeric helpers (angles, powers of two, checksum)       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of util.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Util;

interface

type
  /// <summary>
  ///   Stateless helpers of the node builder that do not depend on the level
  /// </summary>
  TGlbspUtil = class
  public
    /// <summary>
    ///   Rounds a positive value up to the nearest power of two (values up
    ///   to 2 are returned as they are)
    /// </summary>
    class function RoundPow2(AValue: Integer): Integer; static;

    /// <summary>
    ///   Angle in degrees [0, 360) of the vector (0,0)-(ADx,ADy), 0 = east
    /// </summary>
    class function ComputeAngle(const ADx, ADy: Double): Double; static;

    /// <summary>
    ///   C rounding to integer: away from zero on the halves
    /// </summary>
    class function RoundToInt(const AValue: Double): Integer; static;

    /// <summary>Starting value of the Adler-32 checksum</summary>
    class function Adler32Begin: Cardinal; static;

    /// <summary>
    ///   Adds ALength bytes of AData to the checksum ACrc and returns it
    /// </summary>
    class function Adler32AddBlock(const ACrc: Cardinal; const AData: PByte;
      const ALength: Integer): Cardinal; static;
  end;

implementation

uses
  System.Math;

const
  ADLER_MODULUS = 65521;

{ TGlbspUtil }

class function TGlbspUtil.RoundPow2(AValue: Integer): Integer;
var
  LTemp: Integer;
begin
  if AValue <= 2 then
    Exit(AValue);

  Dec(AValue);
  LTemp := AValue div 2;
  while LTemp <> 0 do
  begin
    AValue := AValue or LTemp;
    LTemp := LTemp div 2;
  end;
  Result := AValue + 1;
end;

class function TGlbspUtil.ComputeAngle(const ADx, ADy: Double): Double;
begin
  if ADx = 0 then
  begin
    if ADy > 0 then
      Exit(90.0)
    else
      Exit(270.0);
  end;

  Result := ArcTan2(ADy, ADx) * 180.0 / Pi;
  if Result < 0 then
    Result := Result + 360.0;
end;

class function TGlbspUtil.RoundToInt(const AValue: Double): Integer;
begin
  if AValue < 0.0 then
    Result := Trunc(AValue - 0.5)
  else
    Result := Trunc(AValue + 0.5);
end;

class function TGlbspUtil.Adler32Begin: Cardinal;
begin
  Result := 1;
end;

class function TGlbspUtil.Adler32AddBlock(const ACrc: Cardinal; const AData: PByte;
  const ALength: Integer): Cardinal;
var
  LSum1: Cardinal;
  LSum2: Cardinal;
  LIndex: Integer;
begin
  LSum1 := ACrc and $FFFF;
  LSum2 := (ACrc shr 16) and $FFFF;
  for LIndex := 0 to ALength - 1 do
  begin
    LSum1 := (LSum1 + AData[LIndex]) mod ADLER_MODULUS;
    LSum2 := (LSum2 + LSum1) mod ADLER_MODULUS;
  end;
  Result := (LSum2 shl 16) or LSum1;
end;

end.
