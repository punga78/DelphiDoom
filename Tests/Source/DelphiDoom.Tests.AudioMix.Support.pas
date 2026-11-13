{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - a generator of numbers     }
{  with a fixed seed, for the scenarios that compare the old code and the new   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.Support;

{$Q-}
{$R-}
// a linear congruential generator: the wraparound is the point

interface

type
  /// <summary>The same numbers for the same seed on every machine and at 32 and 64 bits</summary>
  TAudioMixLcg = class
  strict private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    /// <summary>0..ARange - 1</summary>
    function Next(ARange: Integer): Integer;
    /// <summary>ALow..AHigh</summary>
    function Between(ALow, AHigh: Integer): Integer;
    function Chance(APercent: Integer): Boolean;
  end;

implementation

constructor TAudioMixLcg.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed * 2654435761 + 12345;
end;

function TAudioMixLcg.Next(ARange: Integer): Integer;
begin
  FState := FState * 1664525 + 1013904223;
  Result := Integer((FState shr 8) mod Cardinal(ARange));
end;

function TAudioMixLcg.Between(ALow, AHigh: Integer): Integer;
begin
  Result := ALow + Next(AHigh - ALow + 1);
end;

function TAudioMixLcg.Chance(APercent: Integer): Boolean;
begin
  Result := Next(100) < APercent;
end;

end.
