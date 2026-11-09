{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the random numbers of OpenXcom (RNG)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit. The generator is    }
{  xorshift64* by Sebastiano Vigna (public domain, CC0)                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Random;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Types;

type
  /// <summary>The random numbers the rules ask for (the RNG namespace of OpenXcom)</summary>
  IXcomRandom = interface
    ['{4C2E8A17-9D35-4B6F-A0E1-7F3B52D8C964}']
    /// <summary>RNG::generate(int, int): a number from AMin to AMax</summary>
    function Generate(AMin, AMax: Integer): Integer; overload;
    /// <summary>RNG::generate(double, double)</summary>
    function Generate(AMin, AMax: Double): Double; overload;
    function Seed: UInt64;
    procedure SetSeed(AValue: UInt64);
  end;

  /// <summary>
  ///   RNG::next/generate: a xorshift64* generator. Like the C++ the integer range is computed as an unsigned
  ///   64 bit remainder of the signed difference, so a reversed range does not fail but gives a wide number;
  ///   an empty divisor (AMax - AMin + 1 = 0), undefined in the C++, raises EXcomModException
  /// </summary>
  TXcomRandom = class(TInterfacedObject, IXcomRandom)
  strict private
    FState: UInt64;
    function Next: UInt64;
  public
    /// <param name="ASeed">The state; it must not be zero (the C++ seeds it with the time)</param>
    constructor Create(ASeed: UInt64);
    function Generate(AMin, AMax: Integer): Integer; overload;
    function Generate(AMin, AMax: Double): Double; overload;
    function Seed: UInt64;
    procedure SetSeed(AValue: UInt64);
  end;

implementation

const
  SZeroDivisor = 'Xcom: random range with a zero divisor';
  UINT64_MAX_AS_DOUBLE: Double = 18446744073709551616.0;

{ TXcomRandom }

constructor TXcomRandom.Create(ASeed: UInt64);
begin
  inherited Create;
  FState := ASeed;
end;

function TXcomRandom.Next: UInt64;
begin
  FState := FState xor (FState shr 12);
  FState := FState xor (FState shl 25);
  FState := FState xor (FState shr 27);
  Result := FState * UInt64(2685821657736338717);
end;

function TXcomRandom.Generate(AMin, AMax: Integer): Integer;
var
  LNumber: UInt64;
  LDivisor: Integer;
begin
  LNumber := Next;
  LDivisor := AMax - AMin + 1;
  if LDivisor = 0 then
    raise EXcomModException.Create(SZeroDivisor);
  // the C++ converts the int divisor to uint64 (sign extension) and the sum is taken modulo 2^64
  Result := Integer(Cardinal((LNumber mod UInt64(Int64(LDivisor)) + UInt64(Int64(AMin))) and $FFFFFFFF));
end;

function TXcomRandom.Generate(AMin, AMax: Double): Double;
var
  LNumber: UInt64;
  LAsDouble, LRange, LScale, LQuotient: Double;
begin
  LNumber := Next;
  // the C++ divides by zero and gets +inf here, so the quotient is 0 (Delphi would raise)
  if AMax = AMin then
    Exit(AMin);
  if LNumber and UInt64($8000000000000000) <> 0 then
    LAsDouble := Double(Int64(LNumber shr 1 or (LNumber and 1))) * 2.0
  else
    LAsDouble := Double(Int64(LNumber));
  LRange := AMax - AMin;
  LScale := UINT64_MAX_AS_DOUBLE / LRange;
  LQuotient := LAsDouble / LScale;
  Result := LQuotient + AMin;
end;

function TXcomRandom.Seed: UInt64;
begin
  Result := FState;
end;

procedure TXcomRandom.SetSeed(AValue: UInt64);
begin
  FState := AValue;
end;

end.
