{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - conversions at the clip boundary          }
{                                                                              }
{  The game works on the idLib types (TIdVec3, TIdMat3: IdLib and MathCore),   }
{  the collision library on the Geometry types (TGeoVec3, TGeoMat3). They have }
{  the same layout; this is the one place that turns one into the other.       }
{  Written for DelphiDoom.                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.ClipConvert;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3;

type
  /// <summary>Conversions between the game's vectors and matrices and the collision library's</summary>
  TD3ClipConvert = class sealed
  public
    class function ToGeo(const AVector: TIdVec3): TGeoVec3; overload; static; inline;
    class function ToGeo(const AMatrix: TIdMat3): TGeoMat3; overload; static;
    class function ToId(const AVector: TGeoVec3): TIdVec3; overload; static; inline;
    class function ToId(const AMatrix: TGeoMat3): TIdMat3; overload; static;
  end;

implementation

class function TD3ClipConvert.ToGeo(const AVector: TIdVec3): TGeoVec3;
begin
  Result.X := AVector.X;
  Result.Y := AVector.Y;
  Result.Z := AVector.Z;
end;

class function TD3ClipConvert.ToGeo(const AMatrix: TIdMat3): TGeoMat3;
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    Result.Rows[LRow] := ToGeo(AMatrix.Rows[LRow]);
end;

class function TD3ClipConvert.ToId(const AVector: TGeoVec3): TIdVec3;
begin
  Result.X := AVector.X;
  Result.Y := AVector.Y;
  Result.Z := AVector.Z;
end;

class function TD3ClipConvert.ToId(const AMatrix: TGeoMat3): TIdMat3;
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    Result.Rows[LRow] := ToId(AMatrix.Rows[LRow]);
end;

end.
