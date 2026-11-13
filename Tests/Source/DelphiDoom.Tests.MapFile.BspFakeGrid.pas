{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - a grid written by hand          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspFakeGrid;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Intf, DelphiDoom.MathCore.Patch.Types;

type
  /// <summary>
  ///   A grid with the vertices and errors the test gives it (the stitcher and the LOD fixer
  ///   only read positions, sizes, errors and the LOD group)
  /// </summary>
  TFakeGrid = class(TInterfacedObject, IPatchGrid)
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FVertices: TArray<TPatchVertex>;
    FWidthErrors: TArray<Single>;
    FHeightErrors: TArray<Single>;
    FLodOrigin: TIdVec3;
    FLodRadius: Single;
  public
    /// <param name="AXs">x of each column, the same for every row</param>
    /// <param name="AYs">y of each row</param>
    constructor Create(const AXs, AYs: array of Single; const AWidthErrors, AHeightErrors: array of Single;
      const ALodRadius: Single = 10);
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

constructor TFakeGrid.Create(const AXs, AYs: array of Single; const AWidthErrors, AHeightErrors: array of Single;
  const ALodRadius: Single);
var
  LRow, LColumn: Integer;
begin
  inherited Create;
  FWidth := Length(AXs);
  FHeight := Length(AYs);
  SetLength(FVertices, FWidth * FHeight);
  for LRow := 0 to FHeight - 1 do
    for LColumn := 0 to FWidth - 1 do
    begin
      FillChar(FVertices[LRow * FWidth + LColumn], SizeOf(TPatchVertex), 0);
      FVertices[LRow * FWidth + LColumn].Position.SetValues(AXs[LColumn], AYs[LRow], 0);
    end;
  SetLength(FWidthErrors, FWidth);
  for LColumn := 0 to FWidth - 1 do
    FWidthErrors[LColumn] := AWidthErrors[LColumn];
  SetLength(FHeightErrors, FHeight);
  for LRow := 0 to FHeight - 1 do
    FHeightErrors[LRow] := AHeightErrors[LRow];
  FLodOrigin.SetValues(1, 2, 3);
  FLodRadius := ALodRadius;
end;

function TFakeGrid.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TFakeGrid.GetHeight: Integer;
begin
  Result := FHeight;
end;

function TFakeGrid.GetVertex(const AIndex: Integer): TPatchVertex;
begin
  Result := FVertices[AIndex];
end;

function TFakeGrid.GetWidthLodError(const AIndex: Integer): Single;
begin
  Result := FWidthErrors[AIndex];
end;

function TFakeGrid.GetHeightLodError(const AIndex: Integer): Single;
begin
  Result := FHeightErrors[AIndex];
end;

function TFakeGrid.GetBoundsMin: TIdVec3;
begin
  Result.SetValues(0, 0, 0);
end;

function TFakeGrid.GetBoundsMax: TIdVec3;
begin
  Result.SetValues(0, 0, 0);
end;

function TFakeGrid.GetLocalOrigin: TIdVec3;
begin
  Result.SetValues(0, 0, 0);
end;

function TFakeGrid.GetMeshRadius: Single;
begin
  Result := 0;
end;

function TFakeGrid.GetLodOrigin: TIdVec3;
begin
  Result := FLodOrigin;
end;

function TFakeGrid.GetLodRadius: Single;
begin
  Result := FLodRadius;
end;

procedure TFakeGrid.SetLodOrigin(const AValue: TIdVec3);
begin
  FLodOrigin := AValue;
end;

procedure TFakeGrid.SetLodRadius(const AValue: Single);
begin
  FLodRadius := AValue;
end;

procedure TFakeGrid.SetWidthLodError(const AIndex: Integer; const AValue: Single);
begin
  FWidthErrors[AIndex] := AValue;
end;

procedure TFakeGrid.SetHeightLodError(const AIndex: Integer; const AValue: Single);
begin
  FHeightErrors[AIndex] := AValue;
end;

end.
