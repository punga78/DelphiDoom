{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - contracts                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types;

type
  /// <summary>
  ///   A voxel model as the file has it: the full voxels with their colors and nothing about
  ///   how it is drawn. The axes are the ones of the file. A color is $00RRGGBB in the order the
  ///   renderers use (the DDVOX and DDMESH colors are already swapped); zero is no voxel.
  /// </summary>
  IVoxelModel = interface
    ['{5B1E7C20-9D43-4A86-B7F1-2C60E8A4D915}']
    function GetFormat: TVoxelFormatKind;
    function GetSizeX: Integer;
    function GetSizeY: Integer;
    function GetSizeZ: Integer;
    function GetPivotX: Integer;
    function GetPivotY: Integer;
    function GetPivotZ: Integer;
    function GetCells: TArray<Cardinal>;
    function GetQuadCount: Integer;
    /// <summary>The color of a voxel (zero outside the model): the index is (X * SizeY + Y) * SizeZ + Z</summary>
    function Cell(const AX, AY, AZ: Integer): Cardinal;
    /// <summary>A face of the mesh of a DDMESH file</summary>
    function Quad(const AIndex: Integer): TVoxelQuad;
    property Format: TVoxelFormatKind read GetFormat;
    property SizeX: Integer read GetSizeX;
    property SizeY: Integer read GetSizeY;
    property SizeZ: Integer read GetSizeZ;
    /// <summary>The pivot of a KVX file in 1/256 of a voxel (zero for the other formats)</summary>
    property PivotX: Integer read GetPivotX;
    property PivotY: Integer read GetPivotY;
    property PivotZ: Integer read GetPivotZ;
    property Cells: TArray<Cardinal> read GetCells;
    /// <summary>The faces of a DDMESH file (zero for the other formats)</summary>
    property QuadCount: Integer read GetQuadCount;
  end;

  /// <summary>
  ///   A model put in a cube of equal sides, the way the renderers and the sprites want it: the
  ///   index of a cell is (X * Size + Y) * Size + Z and zero is no voxel
  /// </summary>
  IVoxelCube = interface
    ['{8E24D6B9-1F70-4C35-A2E8-6B9C0D3F7A41}']
    function GetSize: Integer;
    function GetCells: TArray<Cardinal>;
    function Cell(const AX, AY, AZ: Integer): Cardinal;
    property Size: Integer read GetSize;
    property Cells: TArray<Cardinal> read GetCells;
  end;

  /// <summary>
  ///   Where the files come from: the engine looks in the game directories and the PAK files,
  ///   in the current directory and in the lumps of the WADs. Each call says if it found the file.
  /// </summary>
  IVoxelFileSource = interface
    ['{C3A9F581-6E2D-4B07-9D14-A85E3F20B6C7}']
    /// <summary>The file in the voxel folders of the game directories and the PAK files</summary>
    function TryReadFile(const AName: string; out ABytes: TBytes): Boolean;
    /// <summary>The file in the directory of the program only</summary>
    function TryReadDirectoryFile(const AName: string; out ABytes: TBytes): Boolean;
    /// <summary>The lump of a voxel (AName is the name of the lump, without the extension)</summary>
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
  end;

  /// <summary>A kind of voxel file: where to look for it and how to read its bytes</summary>
  IVoxelFormat = interface
    ['{2D7B04E6-A1C8-4F93-8E5A-91B6C3D2F078}']
    /// <summary>True if the extension (capital letters, with the dot, or empty) is of this format</summary>
    function Handles(const AExtension: string): Boolean;
    /// <summary>Finds the bytes of the file; false if there is no such file</summary>
    function Locate(const ASource: IVoxelFileSource; const AName: string; out ABytes: TBytes): Boolean;
    /// <summary>The model of the bytes; EVoxelException if they are not a good file</summary>
    function Decode(const ABytes: TBytes): IVoxelModel;
  end;

  /// <summary>Finds and reads a voxel file by its name: the format is the one of the extension</summary>
  IVoxelLoader = interface
    ['{F6C18A3D-5B92-4E70-A4D6-1E8F07B3C259}']
    /// <summary>True if the extension of the name is one of a format the loader reads</summary>
    function IsSupported(const AName: string): Boolean;
    /// <summary>The model of the file; nil if there is no such file or it is not good (a warning tells why)</summary>
    function Load(const AName: string): IVoxelModel;
  end;

  /// <summary>Puts a model in a cube</summary>
  IVoxelCubeBuilder = interface
    ['{4A9E52C7-D018-4B6F-83A1-7C25F9E0B684}']
    function Build(const AModel: IVoxelModel; const AFit: TVoxelCubeFit): IVoxelCube;
  end;

  /// <summary>The color of the palette of the game that is the nearest to a color of a voxel</summary>
  IVoxelColorMapper = interface
    ['{B0E3D749-82A5-4C1E-95F6-3D7A18C4E2B0}']
    function PaletteIndex(const AColor: Cardinal): Byte;
  end;

  /// <summary>Makes the patch of a sprite (the lump of Doom) from the top view of a cube</summary>
  IVoxelPatchBuilder = interface
    ['{7F5C2A18-3E94-4D60-B8A7-E1964D0C5F32}']
    function Build(const ACube: IVoxelCube): TBytes;
  end;

  /// <summary>What the parser of VOXELDEF asks of the game: its states and its sprites</summary>
  IVoxelDefinitionLookup = interface
    ['{1C84E6A5-F273-4B09-A5D1-80B9E37C4D16}']
    /// <summary>The index of a state by its name (capital letters); negative if there is none</summary>
    function FindState(const AName: string): Integer;
    /// <summary>The states that use a sprite by its name</summary>
    function FindStatesOfSprite(const ASpriteName: string): TArray<Integer>;
  end;

  /// <summary>What the parser of VOXELDEF gives: the voxels, the states and the sprites they replace</summary>
  IVoxelDefinitionSink = interface
    ['{E92B7D40-6A1F-48C3-B5E8-4F03A6D91C27}']
    /// <summary>Adds a voxel; the answer is its index (the one of a voxel with the same name if it is there)</summary>
    function AddVoxel(const AItem: TVoxelDefinitionItem): Integer;
    /// <summary>Adds a state that shows a voxel</summary>
    procedure AddState(const AState: TVoxelDefinitionState);
    /// <summary>A sprite is replaced by a voxel (only the names)</summary>
    procedure CheckSprite(const ASpriteName, AVoxelName: string);
  end;

  /// <summary>Reads the text of a VOXELDEF lump</summary>
  IVoxelDefinitionParser = interface
    ['{93D0B5F2-4C68-4A17-8E3B-D5A1260F7C94}']
    /// <summary>The parts of the text go to the sink in the order they are written; the problems are warnings</summary>
    procedure Parse(const AText: string; const ASink: IVoxelDefinitionSink);
  end;

  /// <summary>The names of the lumps of the game, in the order of the directory</summary>
  IVoxelLumpNames = interface
    ['{5D2C8E71-A0B4-4F39-9E62-71C3B8D40F5A}']
    function LumpCount: Integer;
    /// <summary>The name of a lump as the game has it (up to 8 characters, nothing after a #0)</summary>
    function LumpName(const AIndex: Integer): string;
  end;

  /// <summary>
  ///   The voxel files that become sprites when the game has no patch for them: a file of a known
  ///   extension (or without one in the VOXELS folder) whose name is a sprite and a frame (5
  ///   characters, or 6 ending with 0) and whose sprite has no lump between S_START and S_END
  /// </summary>
  IVoxelSpriteNames = interface
    ['{A84F1E63-27C9-4B5D-8D10-E6F35B29C7A4}']
    /// <summary>Looks at a file of the file system of the game and keeps it if it is a sprite</summary>
    procedure AddFileName(const AFileName: string);
    function Count: Integer;
    /// <summary>The name and the extension of a kept file, in capital letters (what the loader reads)</summary>
    function Entry(const AIndex: Integer): string;
    /// <summary>The name of the lump of the sprite of a kept file: the name with 0 for the rotation</summary>
    function SpriteName(const AIndex: Integer): string;
  end;

implementation

end.
