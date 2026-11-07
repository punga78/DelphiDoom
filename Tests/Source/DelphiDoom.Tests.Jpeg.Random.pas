{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the JPEG decoder - generator of repeatable numbers     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Random;

interface

type
  /// <summary>
  ///   Pseudo random numbers that are the same on every machine and every
  ///   compiler (xorshift32), so that the test streams never change
  /// </summary>
  TJpegRandom = record
  private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);

    /// <summary>A number in 0..AUpperBound - 1</summary>
    function Next(AUpperBound: Integer): Integer;

    /// <summary>A number in ALow..AHigh</summary>
    function Between(ALow, AHigh: Integer): Integer;

    /// <summary>True AChance times out of 100</summary>
    function Chance(APercent: Integer): Boolean;
  end;

implementation

{$Q-}
{$R-}

{ TJpegRandom }

constructor TJpegRandom.Create(ASeed: Cardinal);
begin
  FState := ASeed;
  if FState = 0 then
    FState := $9E3779B9;
  // Mixes a small seed so that neighbouring seeds give different streams
  Next(2);
  Next(2);
  Next(2);
end;

function TJpegRandom.Next(AUpperBound: Integer): Integer;
begin
  FState := FState xor (FState shl 13);
  FState := FState xor (FState shr 17);
  FState := FState xor (FState shl 5);
  if AUpperBound <= 1 then
    Result := 0
  else
    Result := Integer((FState shr 4) mod Cardinal(AUpperBound));
end;

function TJpegRandom.Between(ALow, AHigh: Integer): Integer;
begin
  Result := ALow + Next(AHigh - ALow + 1);
end;

function TJpegRandom.Chance(APercent: Integer): Boolean;
begin
  Result := Next(100) < APercent;
end;

end.
