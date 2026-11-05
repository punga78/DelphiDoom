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
    ///   Round to nearest even, like lrint on a 32 bit long: a value that does
    ///   not fit gives the "integer indefinite" of the FPU, $80000000
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
  if not ((AValue > -2147483649.0) and (AValue < 2147483648.0)) then
    Exit(Low(Integer));
  Result := Integer(Round(AValue));
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
