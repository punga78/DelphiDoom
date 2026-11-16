{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the contracts with the system and with the window }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types;

type
  /// <summary>
  ///   The window of the editor: it draws what the presenter says and tells the presenter what the user does
  ///   (menus, buttons, the mouse on the picture). It does not decide anything
  /// </summary>
  IVoxelEditorView = interface
    ['{7D3E1B94-6A52-4C0F-8E17-B2A9D4F05C61}']
    /// <summary>
    ///   The picture of the plane that is edited: size x size cells, each cell a square of Zoom pixels (with a
    ///   grid line if Zoom is large); a cell of color 0 is drawn as "empty"
    /// </summary>
    procedure ShowPlane(const AImage: TVoxelEditorImage; ASize, AZoom: Integer);
    procedure ShowTitle(const ATitle: string);
    procedure ShowState(const AState: TVoxelEditorState);
    /// <summary>The 256 colors of the palette of the window (the first one is "no voxel"), to be shown as squares</summary>
    procedure ShowPalette(const APalette: TVoxelEditorPalette);
    /// <summary>The captions of the items of the recent files menu, newest first</summary>
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    /// <summary>The names of the planes of the list (x0..x(n-1), y0.., z0.., front, back, left, right, top, down) and the one chosen</summary>
    procedure ShowPlanes(const ANames: TArray<string>; ASelected: Integer);
    /// <summary>A long job (the conversion of files) is at APercent; a negative number ends it</summary>
    procedure ShowProgress(const AText: string; APercent: Integer);
    procedure CloseWindow;
  end;

  /// <summary>The questions and the files of the user</summary>
  IVoxelEditorDialogs = interface
    ['{C41A8E27-0B96-4D53-A1F8-35E7B0D92C84}']
    function PickVoxelToOpen(out AFileName: string): Boolean;
    function PickVoxelToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickKvxToImport(out AFileName: string): Boolean;
    function PickVoxToImport(out AFileName: string): Boolean;
    function PickDdmeshToImport(out AFileName: string): Boolean;
    function PickVoxToExport(out AFileName: string): Boolean;
    function PickMeshToExport(out AFileName: string): Boolean;
    function PickImageToImport(out AFileName: string): Boolean;
    function PickImageToExport(out AFileName: string): Boolean;
    function PickPaletteFile(out AFileName: string): Boolean;
    /// <summary>The files for a batch conversion; AKind is 'kvx' or 'ddvox'</summary>
    function PickFilesToConvert(const AKind: string; out AFileNames: TArray<string>): Boolean;
    /// <summary>The color dialog of Windows; the color is $00BBGGRR. False if the user cancels</summary>
    function PickColor(var AColor: Cardinal): Boolean;
    /// <summary>The size of a new voxel (a power of two from 16 to 256 in the old dialog)</summary>
    function AskNewSize(var ASize: Integer): Boolean;
    /// <summary>An angle in degrees for the rotation of the voxel</summary>
    function AskRotation(var ADegrees: Double): Boolean;
    /// <summary>
    ///   The two heights (0..255) of a crop or of a shrink, with the front view of the voxel to look at;
    ///   ATitle tells which of the two it is
    /// </summary>
    function AskHeightRange(const ATitle: string; const APreview: TVoxelEditorImage; ASize: Integer;
      var AMin, AMax: Integer): Boolean;
    /// <summary>The palette to reduce the voxel to; false if the user cancels</summary>
    function AskPaletteKind(out AKind: TVoxelEditorPaletteKind): Boolean;
    function AskSaveChanges: TVoxelEditorConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

  /// <summary>The picture on the clipboard of Windows</summary>
  IVoxelEditorClipboard = interface
    ['{5E92B3D0-7A18-4F64-B0C9-1D48A6E37F52}']
    /// <summary>The picture, stretched to size x size if it is another size; false if there is no picture</summary>
    function TryGetImage(ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
    procedure SetImage(const AImage: TVoxelEditorImage; ASize: Integer);
  end;

  /// <summary>The picture files (BMP, JPEG, PNG, GIF...) that become a plane, a heightmap or a texture</summary>
  IVoxelEditorImageLoader = interface
    ['{A06C7F35-2B84-4E19-9D71-C8F3E5B14A60}']
    /// <summary>The width and the height of the picture of a file; false if it cannot be read</summary>
    function TryGetDimensions(const AFileName: string; out AWidth, AHeight: Integer): Boolean;
    /// <summary>The picture of a file stretched to size x size, as $00BBGGRR; false if it cannot be read</summary>
    function TryLoad(const AFileName: string; ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
  end;

  /// <summary>Writes a picture to a file, by the extension of its name (.bmp, .png, .jpg)</summary>
  IVoxelEditorImageExporter = interface
    ['{E81D2A46-9C37-4B05-8F6E-70B5C3A9D118}']
    function Export(const AFileName: string; const AImage: TVoxelEditorImage; ASize: Integer): Boolean;
  end;

implementation

end.
