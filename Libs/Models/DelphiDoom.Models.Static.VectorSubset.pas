{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: welding of near vectors      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\containers\        }
{  VectorSet.h (idVectorSubset). Copyright (C) 1999-2011 id Software LLC, a    }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.VectorSubset;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Containers.HashIndex,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>
  ///   idVectorSubset: finds, for a vector of a list, the first earlier vector of the list that is
  ///   within an epsilon on every axis, through a hash of boxes. The vectors are kept by the caller
  ///   as a flat list of Single (Dimension values each). Dimension 2 and 3 only (the two used).
  /// </summary>
  TStaticVectorSubset = class
  strict private
    FDimension: Integer;
    FBoxHashSize: Integer;
    FHash: TIdHashIndex;
    FMins: TArray<Single>;
    FBoxInvSize: TArray<Single>;
    FBoxHalfSize: TArray<Single>;
  public
    /// <summary>idVectorSubset::Init(mins, maxs, boxHashSize, initialSize)</summary>
    constructor Create(const AMins, AMaxs: array of Single; const ABoxHashSize, AInitialSize: Integer);
    destructor Destroy; override;
    /// <summary>
    ///   idVectorSubset::FindVector: AVectorNum itself, or the index of a previous vector that
    ///   was found within the epsilon (the vector is added to the hash if it is new)
    /// </summary>
    function FindVector(const AVectors: TArray<Single>; const AVectorNum: Integer; const AEpsilon: Single): Integer;
    /// <summary>
    ///   The loop of the converters for the positions: MinMax of the list, boxes expanded by
    ///   2 * 32 * epsilon, FindVector for each vector. Result[i] is the vertex that i collapses to.
    /// </summary>
    class function RemapPositions(const APositions: TArray<TIdVec3>; const AEpsilon: Single): TArray<Integer>; static;
    /// <summary>The same for the texture coordinates</summary>
    class function RemapTexCoords(const ATexCoords: TArray<TIdVec2>; const AEpsilon: Single): TArray<Integer>; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math;

type
  TSingles = TArray<Single>;

function Remap(const AFlat: TSingles; const ADimension, ACount: Integer; const AEpsilon: Single): TArray<Integer>;
var
  LMins, LMaxs: TArray<Single>;
  LAxis, LIndex: Integer;
  LExpand, LValue: Single;
  LSubset: TStaticVectorSubset;
begin
  SetLength(Result, ACount);
  if ACount = 0 then
    Exit;
  SetLength(LMins, ADimension);
  SetLength(LMaxs, ADimension);
  for LAxis := 0 to ADimension - 1 do
  begin
    LMins[LAxis] := AFlat[LAxis];
    LMaxs[LAxis] := AFlat[LAxis];
  end;
  for LIndex := 1 to ACount - 1 do
    for LAxis := 0 to ADimension - 1 do
    begin
      LValue := AFlat[LIndex * ADimension + LAxis];
      if LValue < LMins[LAxis] then
        LMins[LAxis] := LValue;
      if LValue > LMaxs[LAxis] then
        LMaxs[LAxis] := LValue;
    end;
  LExpand := 2 * 32 * AEpsilon;
  for LAxis := 0 to ADimension - 1 do
  begin
    LMins[LAxis] := LMins[LAxis] - LExpand;
    LMaxs[LAxis] := LMaxs[LAxis] + LExpand;
  end;
  LSubset := TStaticVectorSubset.Create(LMins, LMaxs, 32, 1024);
  try
    for LIndex := 0 to ACount - 1 do
      Result[LIndex] := LSubset.FindVector(AFlat, LIndex, AEpsilon);
  finally
    LSubset.Free;
  end;
end;

{ TStaticVectorSubset }

constructor TStaticVectorSubset.Create(const AMins, AMaxs: array of Single; const ABoxHashSize, AInitialSize: Integer);
var
  LAxis: Integer;
  LBoxSize: Single;
begin
  inherited Create;
  FDimension := Length(AMins);
  FBoxHashSize := ABoxHashSize;
  FHash := TIdHashIndex.Create(TIdMath.IPow(ABoxHashSize, FDimension), AInitialSize);
  SetLength(FMins, FDimension);
  SetLength(FBoxInvSize, FDimension);
  SetLength(FBoxHalfSize, FDimension);
  for LAxis := 0 to FDimension - 1 do
  begin
    FMins[LAxis] := AMins[LAxis];
    LBoxSize := (AMaxs[LAxis] - AMins[LAxis]) / ABoxHashSize;
    FBoxInvSize[LAxis] := 1.0 / LBoxSize;
    FBoxHalfSize[LAxis] := LBoxSize * 0.5;
  end;
end;

destructor TStaticVectorSubset.Destroy;
begin
  FHash.Free;
  inherited Destroy;
end;

function TStaticVectorSubset.FindVector(const AVectors: TArray<Single>; const AVectorNum: Integer;
  const AEpsilon: Single): Integer;
var
  LPartial: TArray<Integer>;
  LAxis, LCorner, LKey, LCandidate: Integer;
  LValue, LStep: Single;
  LMatch: Boolean;
begin
  SetLength(LPartial, FDimension);
  for LAxis := 0 to FDimension - 1 do
  begin
    LValue := AVectors[AVectorNum * FDimension + LAxis];
    LStep := LValue - FMins[LAxis];
    LStep := LStep - FBoxHalfSize[LAxis];
    LStep := LStep * FBoxInvSize[LAxis];
    LPartial[LAxis] := Trunc(LStep);
  end;
  for LCorner := 0 to (1 shl FDimension) - 1 do
  begin
    LKey := 0;
    for LAxis := 0 to FDimension - 1 do
    begin
      LKey := LKey * FBoxHashSize;
      LKey := LKey + LPartial[LAxis] + ((LCorner shr LAxis) and 1);
    end;
    LCandidate := FHash.First(LKey);
    while LCandidate >= 0 do
    begin
      LMatch := True;
      for LAxis := 0 to FDimension - 1 do
        if Abs(AVectors[LCandidate * FDimension + LAxis] - AVectors[AVectorNum * FDimension + LAxis]) > AEpsilon then
        begin
          LMatch := False;
          Break;
        end;
      if LMatch then
        Exit(LCandidate);
      LCandidate := FHash.Next(LCandidate);
    end;
  end;
  LKey := 0;
  for LAxis := 0 to FDimension - 1 do
  begin
    LKey := LKey * FBoxHashSize;
    LValue := AVectors[AVectorNum * FDimension + LAxis] - FMins[LAxis];
    LValue := LValue * FBoxInvSize[LAxis];
    LKey := LKey + Trunc(LValue);
  end;
  FHash.Add(LKey, AVectorNum);
  Result := AVectorNum;
end;

class function TStaticVectorSubset.RemapPositions(const APositions: TArray<TIdVec3>;
  const AEpsilon: Single): TArray<Integer>;
var
  LFlat: TSingles;
  LIndex: Integer;
begin
  SetLength(LFlat, Length(APositions) * 3);
  for LIndex := 0 to High(APositions) do
  begin
    LFlat[LIndex * 3] := APositions[LIndex].X;
    LFlat[LIndex * 3 + 1] := APositions[LIndex].Y;
    LFlat[LIndex * 3 + 2] := APositions[LIndex].Z;
  end;
  Result := Remap(LFlat, 3, Length(APositions), AEpsilon);
end;

class function TStaticVectorSubset.RemapTexCoords(const ATexCoords: TArray<TIdVec2>;
  const AEpsilon: Single): TArray<Integer>;
var
  LFlat: TSingles;
  LIndex: Integer;
begin
  SetLength(LFlat, Length(ATexCoords) * 2);
  for LIndex := 0 to High(ATexCoords) do
  begin
    LFlat[LIndex * 2] := ATexCoords[LIndex].X;
    LFlat[LIndex * 2 + 1] := ATexCoords[LIndex].Y;
  end;
  Result := Remap(LFlat, 2, Length(ATexCoords), AEpsilon);
end;

end.
