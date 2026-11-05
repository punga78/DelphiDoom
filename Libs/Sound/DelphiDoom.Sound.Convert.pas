{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - sample conversions                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Convert;

interface

type
  /// <summary>
  ///   Conversions of floating point samples to integers, with the rules of
  ///   libsndfile: the value is rounded with lrint, not scaled and not clipped
  ///   (the scale only exists when the file carries a peak that was asked for)
  /// </summary>
  TSoundConvert = class
  public
    /// <summary>
    ///   Round to nearest even, like the _lrint of the C code (Round() of
    ///   Delphi): the low 32 bits of a 64 bit result, 0 when even that overflows
    /// </summary>
    class function RoundToLong(const AValue: Extended): Integer; static;

    /// <summary>
    ///   Float sample to 16 bit; what does not fit wraps around
    /// </summary>
    class function SingleToShort(AValue: Single): SmallInt; static;

    /// <summary>
    ///   Float sample to 32 bit; what does not fit gives $80000000
    /// </summary>
    class function SingleToInt(AValue: Single): Integer; static;

    class function DoubleToShort(AValue: Double): SmallInt; static;
    class function DoubleToInt(AValue: Double): Integer; static;
  end;

implementation

{ TSoundConvert }

class function TSoundConvert.RoundToLong(const AValue: Extended): Integer;
begin
  // The C code calls _lrint of c_lib, which is Round() of Delphi: a 64 bit
  // result, cut to its low 32 bits. Past 64 bits the FPU gives $8000000000000000
  if not ((AValue >= -9223372036854775808.0) and (AValue < 9223372036854775808.0)) then
    Exit(0);
  Result := Integer(Int64(Round(AValue)) and $FFFFFFFF);
end;

class function TSoundConvert.SingleToShort(AValue: Single): SmallInt;
begin
  Result := SmallInt(Word(RoundToLong(AValue) and $FFFF));
end;

class function TSoundConvert.SingleToInt(AValue: Single): Integer;
begin
  Result := RoundToLong(AValue);
end;

class function TSoundConvert.DoubleToShort(AValue: Double): SmallInt;
begin
  Result := SmallInt(Word(RoundToLong(AValue) and $FFFF));
end;

class function TSoundConvert.DoubleToInt(AValue: Double): Integer;
begin
  Result := RoundToLong(AValue);
end;

end.
