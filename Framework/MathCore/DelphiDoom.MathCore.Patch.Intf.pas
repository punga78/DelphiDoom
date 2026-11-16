{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: interfaces               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.Intf;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Types;

type
  /// <summary>
  ///   A subdivided patch (srfGridMesh_t): a grid of Width x Height vertices, row by row
  ///   (index = Row * Width + Column), with the LOD error of every column and row and the
  ///   bounds the renderer culls with.
  /// </summary>
  IPatchGrid = interface
    ['{6B1D8C2E-4A57-4F0B-9C3A-17E5D0A2B4C1}']
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
    /// <summary>Changes the error of a column (R_FixSharedVertexLodError of tr_bsp.c does)</summary>
    procedure SetWidthLodError(const AIndex: Integer; const AValue: Single);
    /// <summary>Changes the error of a row</summary>
    procedure SetHeightLodError(const AIndex: Integer; const AValue: Single);
    /// <summary>The number of columns</summary>
    property Width: Integer read GetWidth;
    /// <summary>The number of rows</summary>
    property Height: Integer read GetHeight;
    /// <summary>The vertex at Row * Width + Column</summary>
    property Vertices[const AIndex: Integer]: TPatchVertex read GetVertex;
    /// <summary>The error of each column (widthLodError)</summary>
    property WidthLodError[const AIndex: Integer]: Single read GetWidthLodError;
    /// <summary>The error of each row (heightLodError)</summary>
    property HeightLodError[const AIndex: Integer]: Single read GetHeightLodError;
    property BoundsMin: TIdVec3 read GetBoundsMin;
    property BoundsMax: TIdVec3 read GetBoundsMax;
    property LocalOrigin: TIdVec3 read GetLocalOrigin;
    property MeshRadius: Single read GetMeshRadius;
    property LodOrigin: TIdVec3 read GetLodOrigin write SetLodOrigin;
    property LodRadius: Single read GetLodRadius write SetLodRadius;
  end;

  /// <summary>R_SubdividePatchToGrid: turns the control points of a patch into a grid</summary>
  IPatchSubdivider = interface
    ['{0F3A92D7-5C18-4E6B-8D41-B2A76C9E3F05}']
    /// <summary>
    ///   Subdivides a biquadratic patch (AWidth x AHeight control points, both odd, from 3 to
    ///   MAX_PATCH_SIZE, row by row) according to the maximum error of the subdivider
    /// </summary>
    function SubdividePatchToGrid(const AWidth, AHeight: Integer;
      const APoints: TArray<TPatchVertex>): IPatchGrid;
  end;

  /// <summary>R_GridInsertColumn and R_GridInsertRow: add a column or a row to a grid</summary>
  IPatchGridEditor = interface
    ['{C4E8157A-93B2-4D06-A7F9-5E0B1D2C8A36}']
    /// <summary>
    ///   Inserts a column before AColumn (1 to Width - 1) with the interpolated vertices and the
    ///   position APoint in row ARow; nil when the grid has MAX_GRID_SIZE columns already
    /// </summary>
    function InsertColumn(const AGrid: IPatchGrid; const AColumn, ARow: Integer;
      const APoint: TIdVec3; const ALodError: Single): IPatchGrid;
    /// <summary>Same for a row: before ARow (1 to Height - 1), position APoint in column AColumn</summary>
    function InsertRow(const AGrid: IPatchGrid; const ARow, AColumn: Integer;
      const APoint: TIdVec3; const ALodError: Single): IPatchGrid;
  end;

implementation

end.
