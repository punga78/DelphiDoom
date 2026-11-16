{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - types and constants                               }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Types;

interface

uses
  System.SysUtils;

const
  VOXEL_EDITOR_TITLE = 'DelphiDoom Voxel Editor';
  /// <summary>The cube of a voxel has at most this many cells on a side (MAXVOXELSIZE of DD_VOXEL)</summary>
  VOXEL_EDITOR_MAX_SIZE = 256;
  VOXEL_EDITOR_MIN_ZOOM = 1;
  VOXEL_EDITOR_MAX_ZOOM = 32;
  VOXEL_EDITOR_DEFAULT_SIZE = 64;
  /// <summary>The magic number of a DDMESH file: 'D', 'D', 'M', 'S'</summary>
  VOXEL_EDITOR_DDMESH_MAGIC = Cardinal(Ord('D') + Ord('D') shl 8 + Ord('M') shl 16 + Ord('S') shl 24);
  VOXEL_EDITOR_DDMESH_VERSION = 1;
  /// <summary>The color that a heightmap and a terrain texture give to a pixel that would be black (0 is "no voxel")</summary>
  VOXEL_EDITOR_NEAR_BLACK = Cardinal(1);

  // the sections and names of the settings file of DD_VOXEL
  VOXEL_EDITOR_SECTION_HISTORY = 'File Menu History';
  VOXEL_EDITOR_SECTION_OPTIONS = 'Voxel Options';
  VOXEL_EDITOR_SETTING_ZOOM = 'ZOOM';
  VOXEL_EDITOR_SETTING_SIZE = 'NEWVOXELSIZE';
  VOXEL_EDITOR_SETTING_COLOR1 = 'DRAWCOLOR1';
  VOXEL_EDITOR_SETTING_COLOR2 = 'DRAWCOLOR2';

type
  /// <summary>
  ///   What a view of the 3D voxel shows, as DD_VOXEL named it (voxelview_t): the first voxel that a ray meets
  ///   when it crosses the cube from one face
  /// </summary>
  TVoxelEditorView = (vevNone, vevFront, vevBack, vevLeft, vevRight, vevTop, vevDown);

  /// <summary>The plane that is edited: a slice at x, y or z (xpos, ypos, zpos of DD_VOXEL), or a view</summary>
  TVoxelEditorAxis = (veaNone, veaX, veaY, veaZ);

  /// <summary>
  ///   The plane the user paints on. With an axis it is the slice at that level; without an axis it is the view
  ///   (Front, Back...), and with no view either nothing can be painted
  /// </summary>
  TVoxelEditorPlane = record
    Axis: TVoxelEditorAxis;
    Level: Integer;
    View: TVoxelEditorView;
    class function Slice(AAxis: TVoxelEditorAxis; ALevel: Integer): TVoxelEditorPlane; static;
    class function OfView(AView: TVoxelEditorView): TVoxelEditorPlane; static;
    function IsValid: Boolean;
  end;

  /// <summary>
  ///   One cell of a view: the color of the first voxel that is met, how deep it is (the size of the cube if the ray
  ///   crosses it with no voxel) and the cell in front of it (the index of a cell of the model, or -1)
  /// </summary>
  TVoxelEditorDepthItem = record
    Color: Cardinal;
    Depth: Cardinal;
    Previous: Integer;
  end;

  /// <summary>A flat picture of size x size pixels: the pixel (i, j) is Pixels[i * size + j] (the buffer2d of DD_VOXEL)</summary>
  TVoxelEditorImage = TArray<Cardinal>;

  /// <summary>256 colors, each $00BBGGRR as Windows has it (TPaletteArray of DD_VOXEL)</summary>
  TVoxelEditorPalette = array[0..255] of Cardinal;

  TVoxelEditorConfirmation = (vecYes, vecNo, vecCancel);

  TVoxelEditorTool = (vetFreeDraw, vetFloodFill, vetColorPicker, vetEraser, vetElevate);

  TVoxelEditorMouseButton = (vebLeft, vebRight);

  TVoxelEditorPaletteKind = (vepDoom, vepHeretic, vepHexen, vepStrife, vepRadix, vepOctree, vepFile);

  /// <summary>The batch conversions of the Tools menu: a list of files is converted, each to the file of the same name with the new extension</summary>
  TVoxelEditorBatch = (vebKvxToDdmesh, vebDdvoxToDdmesh, vebDdvoxToVox);

  /// <summary>What the window shows besides the picture of the plane (the old status bar and the buttons)</summary>
  TVoxelEditorState = record
    CanUndo: Boolean;
    CanRedo: Boolean;
    CanElevate: Boolean;
    Tool: TVoxelEditorTool;
    Color1: Cardinal;
    Color2: Cardinal;
    Zoom: Integer;
    Size: Integer;
    StatusText: string;
  end;

  /// <summary>A wrong voxel file or a wrong argument</summary>
  EVoxelEditorException = class(Exception);

resourcestring
  SVoxelEditorBadSize = 'The size of a voxel must be from 1 to 256, not %d';
  SVoxelEditorBadFile = 'The file is not a valid voxel: %s';
  SVoxelEditorFileNotFound = 'File %s does not exist!';
  SVoxelEditorCannotWrite = 'Can not save file %s';
  SVoxelEditorBadDimensions = 'File %s has invalid dimentions (%dx%dx%d)!';
  SVoxelEditorNoDdmeshMagic = 'File %s does not have DDMESH magic header!';
  SVoxelEditorBadVersion = 'File %s is from unsupported version = %d!';
  SVoxelEditorMeshReduced = 'TVoxelMeshOptimizer.Optimize(): Mesh reduced from %d to %d quads, pass count = %d.'#13#10;
  SVoxelEditorMeshNoPasses = 'TVoxelMeshOptimizer.Optimize(): Can not start optimized, vx_maxoptimizerpasscount = 0.'#13#10;
  SVoxelEditorUniqueColors = 'The number of unique colors is %d';

implementation

{ TVoxelEditorPlane }

class function TVoxelEditorPlane.Slice(AAxis: TVoxelEditorAxis; ALevel: Integer): TVoxelEditorPlane;
begin
  Result.Axis := AAxis;
  Result.Level := ALevel;
  Result.View := vevNone;
end;

class function TVoxelEditorPlane.OfView(AView: TVoxelEditorView): TVoxelEditorPlane;
begin
  Result.Axis := veaNone;
  Result.Level := -1;
  Result.View := AView;
end;

function TVoxelEditorPlane.IsValid: Boolean;
begin
  Result := (Axis <> veaNone) or (View <> vevNone);
end;

end.
