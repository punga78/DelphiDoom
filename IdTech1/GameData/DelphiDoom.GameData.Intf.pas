{******************************************************************************}
{                                                                              }
{  DelphiDoom: game data library - contracts                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameData.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Makes patches (the picture format of Doom) from the pictures that a game with its own
  ///   data files keeps. Images are arrays of palette indices; nothing here reads a file
  /// </summary>
  IGamePatchBuilder = interface
    ['{4E1B7A92-3D05-4C68-9F2A-61B8D0E5A347}']
    /// <summary>
    ///   An image stored by columns: the pixel (X, Y) is AImage[X * AHeight + Y]. When ASolid is
    ///   false the transparent index of the options makes holes. The offsets may be
    ///   GAMEDATA_PATCH_DEFAULT_OFFSET
    /// </summary>
    function FromColumns(const AImage: TBytes; AWidth, AHeight: Integer; ASolid: Boolean;
      ALeftOffset, ATopOffset: Integer): TBytes; overload;
    /// <summary>The same with the default offsets (half the width, the height)</summary>
    function FromColumns(const AImage: TBytes; AWidth, AHeight: Integer;
      ASolid: Boolean): TBytes; overload;
    /// <summary>An image stored by rows: the pixel (X, Y) is AImage[Y * AWidth + X]; offsets 0, 0</summary>
    function FromRows(const AImage: TBytes; AWidth, AHeight: Integer; ASolid: Boolean): TBytes;
    /// <summary>
    ///   An image stored by rows whose indices are those of APalette (768 bytes of R, G, B, each
    ///   0..63 as in VGA); every color goes to the nearest of ADefaultPalette ($00RRGGBB, 256
    ///   colors) inside the range of the options
    /// </summary>
    function FromPalettedRows(const AImage: TBytes; AWidth, AHeight: Integer;
      const APalette: TBytes; ASolid: Boolean; const ADefaultPalette: TArray<Cardinal>): TBytes;
    /// <summary>
    ///   As FromPalettedRows, but the index ABackground becomes the transparent index and a
    ///   color that falls on the transparent index goes two indices before it (the Rad-X
    ///   "opaque" variant); the patch is not solid
    /// </summary>
    function FromPalettedRowsWithBackground(const AImage: TBytes; AWidth, AHeight: Integer;
      const APalette: TBytes; ABackground: Integer;
      const ADefaultPalette: TArray<Cardinal>): TBytes;
    /// <summary>A sky: stored by columns, always solid, offsets half the width and the height</summary>
    function SkyFromColumns(const AImage: TBytes; AWidth, AHeight: Integer): TBytes;
  end;

  /// <summary>
  ///   A WAD held in memory that a converter fills lump after lump (what TWadWriter was for the
  ///   forks). Names are upper cased and have 1 to 8 characters
  /// </summary>
  IGameWadComposer = interface
    ['{A93C5D17-80E4-4B2F-B6D1-2F7E49C3A058}']
    function GetCount: Integer;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpData(AIndex: Integer): TBytes;
    /// <summary>Appends a lump; returns its index</summary>
    function AddLump(const AName: string; const AData: TBytes): Integer;
    /// <summary>Appends an empty lump (S_START, F_END, a level name ...)</summary>
    function AddMarker(const AName: string): Integer;
    /// <summary>Appends a text lump: one byte per character, the characters above 255 cut</summary>
    function AddText(const AName, AText: string): Integer;
    function IndexOf(const AName: string): Integer;
    /// <summary>The PWAD, data aligned to 4 bytes and the directory at the end</summary>
    function ToBytes: TBytes;
    procedure SaveToFile(const AFileName: string);
    property Count: Integer read GetCount;
    property LumpNames[AIndex: Integer]: string read GetLumpName;
    property LumpData[AIndex: Integer]: TBytes read GetLumpData;
  end;

implementation

end.
