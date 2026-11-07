{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the blockmap library - fingerprint of a list of numbers}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Blockmap.Fingerprint;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Blockmap.Types;

type
  /// <summary>
  ///   FNV-1a (64 bit) of 32 bit numbers, least significant byte first: the same count as
  ///   the temporary harness that made the golden files from the old code of the engine
  /// </summary>
  TBlockmapFingerprint = class sealed
  public
    class function OfIntegers(const AValues: TArray<Integer>): UInt64; static;
    /// <summary>The coordinates of the vertexes, x then y for each one</summary>
    class function OfVertexes(const AVertexes: TArray<TBlockmapPoint>): UInt64; static;
  end;

implementation

const
  FNV_OFFSET = UInt64($CBF29CE484222325);
  FNV_PRIME = UInt64($100000001B3);

{ TBlockmapFingerprint }

class function TBlockmapFingerprint.OfIntegers(const AValues: TArray<Integer>): UInt64;
var
  LIndex, LByte: Integer;
begin
  Result := FNV_OFFSET;
  for LIndex := 0 to High(AValues) do
    for LByte := 0 to 3 do
      Result := (Result xor ((Cardinal(AValues[LIndex]) shr (8 * LByte)) and $FF)) * FNV_PRIME;
end;

class function TBlockmapFingerprint.OfVertexes(const AVertexes: TArray<TBlockmapPoint>): UInt64;
var
  LValues: TArray<Integer>;
  LIndex: Integer;
begin
  SetLength(LValues, Length(AVertexes) * 2);
  for LIndex := 0 to High(AVertexes) do
  begin
    LValues[2 * LIndex] := AVertexes[LIndex].X;
    LValues[2 * LIndex + 1] := AVertexes[LIndex].Y;
  end;
  Result := OfIntegers(LValues);
end;

end.
