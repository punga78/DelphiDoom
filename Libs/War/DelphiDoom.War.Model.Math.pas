{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the vectors and the time of the model             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_math.c, wmap_mapToTileCoordinatesV,        }
{  wmap_tileToMapCoordinatesV, wmap_getMapScaledTime and wu_getDirectionFrom-  }
{  Diff, (c) 2019 Alejandro Coto Gutierrez, zlib License (see                  }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Math;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   The 32 bit float operations of the original. Every operation is stored in a Single: at Win32 the x87 would
  ///   keep more bits between two operations and give a last bit different from the one of the C (SSE) at Win64
  /// </summary>
  TWarModelMath = class
  public
    class function Vec(AX, AY: Single): TWarVec2; static; inline;
    class function Add(const A, B: TWarVec2): TWarVec2; static;
    class function Sub(const A, B: TWarVec2): TWarVec2; static;
    class function Scale(const A: TWarVec2; AFactor: Single): TWarVec2; static;
    class function Half(const A: TWarVec2): TWarVec2; static;
    /// <summary>vec2_lengthSqr</summary>
    class function LengthSqr(const A: TWarVec2): Single; static;
    /// <summary>vec2_length</summary>
    class function Length(const A: TWarVec2): Single; static;
    /// <summary>vec2_distanceSqr</summary>
    class function DistanceSqr(const A, B: TWarVec2): Single; static;
    /// <summary>vec2_normalize: the zero vector stays zero</summary>
    class function Normalize(const A: TWarVec2): TWarVec2; static;
    /// <summary>vec2_distanceInTiles: the larger of the two differences</summary>
    class function DistanceInTiles(const A, B: TWarVec2): Single; static;
    /// <summary>wmap_mapToTileCoordinatesV: pixels to tiles (floor)</summary>
    class function MapToTile(const A: TWarVec2): TWarVec2; static;
    /// <summary>wmap_tileToMapCoordinatesV</summary>
    class function TileToMap(const A: TWarVec2; ACenteredInTile: Boolean): TWarVec2; static;
    /// <summary>wu_getDirectionFromDiff: North where both differences are 0</summary>
    class function DirectionFromDiff(AX, AY: Single): Integer; static;
    /// <summary>PERCENTABI(a, b): (s32)(((f32)a / b) * 100)</summary>
    class function PercentOf(AValue, AMax: Integer): Integer; static;
    /// <summary>__frameCountToSeconds</summary>
    class function FramesToSeconds(AFrames: Integer): Single; static;
    /// <summary>wmap_getMapScaledTime: seconds of game at the speed of the map</summary>
    class function ScaledTime(const AClock: TWarGameClock; ASeconds: Single): Single; static;
  end;

implementation

{ TWarModelMath }

class function TWarModelMath.Vec(AX, AY: Single): TWarVec2;
begin
  Result.X := AX;
  Result.Y := AY;
end;

class function TWarModelMath.Add(const A, B: TWarVec2): TWarVec2;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

class function TWarModelMath.Sub(const A, B: TWarVec2): TWarVec2;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

class function TWarModelMath.Scale(const A: TWarVec2; AFactor: Single): TWarVec2;
begin
  Result.X := A.X * AFactor;
  Result.Y := A.Y * AFactor;
end;

class function TWarModelMath.Half(const A: TWarVec2): TWarVec2;
begin
  Result.X := A.X * 0.5;
  Result.Y := A.Y * 0.5;
end;

class function TWarModelMath.LengthSqr(const A: TWarVec2): Single;
var
  LXX: Single;
  LYY: Single;
begin
  LXX := A.X * A.X;
  LYY := A.Y * A.Y;
  Result := LXX + LYY;
end;

class function TWarModelMath.Length(const A: TWarVec2): Single;
var
  LSquare: Single;
begin
  LSquare := LengthSqr(A);
  Result := Sqrt(LSquare);
end;

class function TWarModelMath.DistanceSqr(const A, B: TWarVec2): Single;
var
  LDx: Single;
  LDy: Single;
  LXX: Single;
  LYY: Single;
begin
  LDx := A.X - B.X;
  LDy := A.Y - B.Y;
  LXX := LDx * LDx;
  LYY := LDy * LDy;
  Result := LXX + LYY;
end;

class function TWarModelMath.Normalize(const A: TWarVec2): TWarVec2;
var
  LLength: Single;
  LInverse: Single;
begin
  LLength := Length(A);
  if LLength <> 0 then
  begin
    LInverse := 1.0 / LLength;
    Result := Scale(A, LInverse);
  end
  else
  begin
    Result.X := 0;
    Result.Y := 0;
  end;
end;

class function TWarModelMath.DistanceInTiles(const A, B: TWarVec2): Single;
var
  LDx: Single;
  LDy: Single;
begin
  LDx := Abs(A.X - B.X);
  LDy := Abs(A.Y - B.Y);
  if LDx > LDy then
    Result := LDx
  else
    Result := LDy;
end;

class function TWarModelMath.MapToTile(const A: TWarVec2): TWarVec2;
var
  LQuotient: Single;
begin
  LQuotient := A.X / WAR_MEGA_TILE_SIZE;
  Result.X := Floor(LQuotient);
  LQuotient := A.Y / WAR_MEGA_TILE_SIZE;
  Result.Y := Floor(LQuotient);
end;

class function TWarModelMath.TileToMap(const A: TWarVec2; ACenteredInTile: Boolean): TWarVec2;
begin
  Result.X := A.X * WAR_MEGA_TILE_SIZE;
  Result.Y := A.Y * WAR_MEGA_TILE_SIZE;
  if ACenteredInTile then
  begin
    Result.X := Result.X + WAR_MEGA_TILE_SIZE div 2;
    Result.Y := Result.Y + WAR_MEGA_TILE_SIZE div 2;
  end;
end;

class function TWarModelMath.DirectionFromDiff(AX, AY: Single): Integer;
begin
  if (AX < 0) and (AY < 0) then
    Exit(WAR_DIRECTION_NORTH_WEST);
  if (AX = 0) and (AY < 0) then
    Exit(WAR_DIRECTION_NORTH);
  if (AX > 0) and (AY < 0) then
    Exit(WAR_DIRECTION_NORTH_EAST);
  if (AX < 0) and (AY = 0) then
    Exit(WAR_DIRECTION_WEST);
  if (AX > 0) and (AY = 0) then
    Exit(WAR_DIRECTION_EAST);
  if (AX < 0) and (AY > 0) then
    Exit(WAR_DIRECTION_SOUTH_WEST);
  if (AX = 0) and (AY > 0) then
    Exit(WAR_DIRECTION_SOUTH);
  if (AX > 0) and (AY > 0) then
    Exit(WAR_DIRECTION_SOUTH_EAST);
  Result := WAR_DIRECTION_NORTH;
end;

class function TWarModelMath.PercentOf(AValue, AMax: Integer): Integer;
var
  LQuotient: Single;
  LPercent: Single;
begin
  LQuotient := Single(AValue) / Single(AMax);
  LPercent := LQuotient * 100;
  Result := Trunc(LPercent);
end;

class function TWarModelMath.FramesToSeconds(AFrames: Integer): Single;
begin
  Result := Single(AFrames) / WAR_MODEL_FRAMES_PER_SECOND;
end;

class function TWarModelMath.ScaledTime(const AClock: TWarGameClock; ASeconds: Single): Single;
var
  LFactor: Single;
begin
  Result := ASeconds / AClock.GlobalSpeed;
  if AClock.GameSpeed < 2 then
  begin
    LFactor := (2 - AClock.GameSpeed) * 0.25;
    LFactor := 1.0 - LFactor;
    Result := Result / LFactor;
  end
  else if AClock.GameSpeed > 2 then
  begin
    LFactor := (AClock.GameSpeed - 2) * 0.5;
    LFactor := 1.0 + LFactor;
    Result := Result / LFactor;
  end;
end;

end.
