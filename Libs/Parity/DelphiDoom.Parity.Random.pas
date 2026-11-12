{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the random numbers of the pilot                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.Random;

// the generator wraps around on purpose: no overflow and no range checks
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   A generator of its own (SplitMix32 of 32 bits of state): it has nothing to do with the random numbers
  ///   of the game, so the pilot never changes the sequence of the game, and the same seed always gives the
  ///   same numbers on every machine
  /// </summary>
  TParityRandom = class
  strict private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    /// <summary>The next 32 bit number</summary>
    function NextCardinal: Cardinal;
    /// <summary>A number from 0 to ALimit - 1 (0 when ALimit is not more than 1)</summary>
    function NextBelow(ALimit: Integer): Integer;
    /// <summary>A number from AMinimum to AMaximum, both included</summary>
    function NextBetween(AMinimum, AMaximum: Integer): Integer;
  end;

implementation

{ TParityRandom }

constructor TParityRandom.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

function TParityRandom.NextCardinal: Cardinal;
begin
  FState := FState + $9E3779B9;
  Result := FState;
  Result := (Result xor (Result shr 16)) * $85EBCA6B;
  Result := (Result xor (Result shr 13)) * $C2B2AE35;
  Result := Result xor (Result shr 16);
end;

function TParityRandom.NextBelow(ALimit: Integer): Integer;
begin
  if ALimit <= 1 then
    Exit(0);
  Result := Integer(NextCardinal mod Cardinal(ALimit));
end;

function TParityRandom.NextBetween(AMinimum, AMaximum: Integer): Integer;
begin
  if AMaximum <= AMinimum then
    Exit(AMinimum);
  Result := AMinimum + NextBelow(AMaximum - AMinimum + 1);
end;

end.
