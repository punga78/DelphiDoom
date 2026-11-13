{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: the subdivided grid      }
{                                                                              }
{  Port of srfGridMesh_t and R_CreateSurfaceGridMesh (tr_curve.c). Based on    }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C)            }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.Grid;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.ControlMesh,
  DelphiDoom.MathCore.Patch.Intf, DelphiDoom.MathCore.Patch.Types;

type
  /// <summary>
  ///   A grid of vertices with its LOD errors and bounds (srfGridMesh_t). The constructor is
  ///   R_CreateSurfaceGridMesh: it copies the live Width x Height part of a working mesh and the
  ///   error tables, and computes bounds, local origin and radius (the LOD origin and radius
  ///   start equal to them).
  /// </summary>
  TPatchGrid = class(TInterfacedObject, IPatchGrid)
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FVertices: TArray<TPatchVertex>;
    FWidthLodError: TArray<Single>;
    FHeightLodError: TArray<Single>;
    FBoundsMin: TIdVec3;
    FBoundsMax: TIdVec3;
    FLocalOrigin: TIdVec3;
    FMeshRadius: Single;
    FLodOrigin: TIdVec3;
    FLodRadius: Single;
  public
    /// <param name="AWidthLodError">at least AWidth values</param>
    /// <param name="AHeightLodError">at least AHeight values</param>
    constructor Create(const AMesh: TPatchControlMesh; const AWidth, AHeight: Integer;
      const AWidthLodError, AHeightLodError: array of Single);
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetVertex(const AIndex: Integer): TPatchVertex;
    function GetWidthLodError(const AIndex: Integer): Single;
    function GetHeightLodError(const AIndex: Integer): Single;
    function GetBoundsMin: TIdVec3;
    function GetBoundsMax: TIdVec3;
    function GetLocalOrigin: TIdVec3;
    function GetMeshRadius: Single;
    function GetLodOrigin: TIdVec3;
    function GetLodRadius: Single;
    procedure SetLodOrigin(const AValue: TIdVec3);
    procedure SetLodRadius(const AValue: Single);
    procedure SetWidthLodError(const AIndex: Integer; const AValue: Single);
    procedure SetHeightLodError(const AIndex: Integer; const AValue: Single);
  end;

implementation

uses
  DelphiDoom.MathCore.Patch.VertexMath;

constructor TPatchGrid.Create(const AMesh: TPatchControlMesh; const AWidth, AHeight: Integer;
  const AWidthLodError, AHeightLodError: array of Single);
var
  LI, LJ: Integer;
  LPoint, LTemp: TIdVec3;
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FVertices, AWidth * AHeight);
  SetLength(FWidthLodError, AWidth);
  SetLength(FHeightLodError, AHeight);
  for LI := 0 to AWidth - 1 do
    FWidthLodError[LI] := AWidthLodError[LI];
  for LI := 0 to AHeight - 1 do
    FHeightLodError[LI] := AHeightLodError[LI];

  // ClearBounds
  FBoundsMin.SetValues(99999, 99999, 99999);
  FBoundsMax.SetValues(-99999, -99999, -99999);
  for LI := 0 to AWidth - 1 do
    for LJ := 0 to AHeight - 1 do
    begin
      FVertices[LJ * AWidth + LI] := AMesh[LJ, LI];
      LPoint := FVertices[LJ * AWidth + LI].Position;
      // AddPointToBounds
      if LPoint.X < FBoundsMin.X then
        FBoundsMin.X := LPoint.X;
      if LPoint.X > FBoundsMax.X then
        FBoundsMax.X := LPoint.X;
      if LPoint.Y < FBoundsMin.Y then
        FBoundsMin.Y := LPoint.Y;
      if LPoint.Y > FBoundsMax.Y then
        FBoundsMax.Y := LPoint.Y;
      if LPoint.Z < FBoundsMin.Z then
        FBoundsMin.Z := LPoint.Z;
      if LPoint.Z > FBoundsMax.Z then
        FBoundsMax.Z := LPoint.Z;
    end;

  // compute local origin and bounds
  LTemp := FBoundsMin + FBoundsMax;
  FLocalOrigin := LTemp * 0.5;
  LTemp := FBoundsMin - FLocalOrigin;
  FMeshRadius := TPatchVertexMath.Length(LTemp);
  FLodOrigin := FLocalOrigin;
  FLodRadius := FMeshRadius;
end;

function TPatchGrid.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TPatchGrid.GetHeight: Integer;
begin
  Result := FHeight;
end;

function TPatchGrid.GetVertex(const AIndex: Integer): TPatchVertex;
begin
  Result := FVertices[AIndex];
end;

function TPatchGrid.GetWidthLodError(const AIndex: Integer): Single;
begin
  Result := FWidthLodError[AIndex];
end;

function TPatchGrid.GetHeightLodError(const AIndex: Integer): Single;
begin
  Result := FHeightLodError[AIndex];
end;

function TPatchGrid.GetBoundsMin: TIdVec3;
begin
  Result := FBoundsMin;
end;

function TPatchGrid.GetBoundsMax: TIdVec3;
begin
  Result := FBoundsMax;
end;

function TPatchGrid.GetLocalOrigin: TIdVec3;
begin
  Result := FLocalOrigin;
end;

function TPatchGrid.GetMeshRadius: Single;
begin
  Result := FMeshRadius;
end;

function TPatchGrid.GetLodOrigin: TIdVec3;
begin
  Result := FLodOrigin;
end;

function TPatchGrid.GetLodRadius: Single;
begin
  Result := FLodRadius;
end;

procedure TPatchGrid.SetLodOrigin(const AValue: TIdVec3);
begin
  FLodOrigin := AValue;
end;

procedure TPatchGrid.SetLodRadius(const AValue: Single);
begin
  FLodRadius := AValue;
end;

procedure TPatchGrid.SetWidthLodError(const AIndex: Integer; const AValue: Single);
begin
  FWidthLodError[AIndex] := AValue;
end;

procedure TPatchGrid.SetHeightLodError(const AIndex: Integer; const AValue: Single);
begin
  FHeightLodError[AIndex] := AValue;
end;

end.
