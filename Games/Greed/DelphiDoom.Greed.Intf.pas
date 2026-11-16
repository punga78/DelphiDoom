{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts                                    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types;

type
  /// <summary>
  ///   A correction of the data that the game applies to a lump when it reads it (FixLump of g_fixlump.pas):
  ///   a lump of a known size and checksum is replaced by another
  /// </summary>
  IGreedLumpFixes = interface
    ['{4C9A7E12-3D58-4B06-A1F7-92E8D05B6C34}']
    /// <summary>The bytes of the lump, or the ones that replace them</summary>
    function Apply(const ALump: TBytes): TBytes;
  end;

  /// <summary>The lumps of a data file of the game (GREED.BLO)</summary>
  IGreedArchive = interface
    ['{8E31B5D7-62A4-4F90-B8C3-17D6A29E0F58}']
    function GetLumpCount: Integer;
    /// <summary>The entry of the table as it is in the file</summary>
    function GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
    /// <summary>The name of the lump; empty if it has none. EGreedNotFoundException if the lump does not exist</summary>
    function GetLumpName(AIndex: Integer): string;
    /// <summary>Bytes of the lump (not the ones that a correction would give)</summary>
    function GetLumpSize(AIndex: Integer): Integer;
    /// <summary>
    ///   The number of the first lump with that name, without the difference between upper and lower case
    ///   (CA_CheckNamedNum), or -1
    /// </summary>
    function IndexOf(const AName: string): Integer;
    /// <summary>Like IndexOf, but EGreedNotFoundException when it is not there (CA_GetNamedNum)</summary>
    function RequireIndexOf(const AName: string): Integer;
    /// <summary>
    ///   The bytes of the lump, with the corrections of the data (CA_CacheLump). A lump of size 0 gives an
    ///   empty array. EGreedDataException if the lump goes past the end of the file
    /// </summary>
    function ReadLump(AIndex: Integer): TBytes;
    /// <summary>The bytes of the lump as they are in the file (CA_ReadLump)</summary>
    function ReadLumpRaw(AIndex: Integer): TBytes;
    property LumpCount: Integer read GetLumpCount;
  end;

  /// <summary>Files that are not in the archive: the maps of the demos are .LAY files next to it</summary>
  IGreedExternalFiles = interface
    ['{F2A06C48-91B3-4E5D-8D17-30C5E7B94A62}']
    function Exists(const AName: string): Boolean;
    /// <summary>The whole file; EGreedNotFoundException if it is not there</summary>
    function ReadAll(const AName: string): TBytes;
  end;

  /// <summary>A map: the 18 planes of 64 x 64 bytes</summary>
  IGreedMap = interface
    ['{17D5E8A3-B260-4C94-A3F1-6E09D4B82C75}']
    /// <summary>The 4096 bytes of a plane; the tile (x, y) is at y * 64 + x</summary>
    function GetPlane(APlane: TGreedPlane): TBytes;
    /// <summary>The byte of a plane at the tile (x, y); EGreedDataException outside 0..63</summary>
    function GetTile(APlane: TGreedPlane; X, Y: Integer): Byte;
    /// <summary>The bytes that follow the planes in the lump of a map (the script of the map); empty if none</summary>
    function GetTrailer: TBytes;
    property Planes[APlane: TGreedPlane]: TBytes read GetPlane;
    property Tiles[APlane: TGreedPlane; X, Y: Integer]: Byte read GetTile;
    property Trailer: TBytes read GetTrailer;
  end;

  /// <summary>Turns the bytes of a map (DoLoadMapData) into a map</summary>
  IGreedMapReader = interface
    ['{6B40C9F2-85D1-47A3-9E6B-D2F0A3187C54}']
    /// <summary>EGreedDataException if there are less than 18 * 4096 bytes</summary>
    function Read(const ABytes: TBytes): IGreedMap;
  end;

  /// <summary>Finds the map of a number in the archive and reads it (LoadNewMap)</summary>
  IGreedMapLoader = interface
    ['{D3E7A915-4F28-4B60-8C1E-A5694F02B7D8}']
    /// <summary>
    ///   The map of a number (lump "map" + number + 1). If its lump is empty (the demos) the map is
    ///   the file that has the name of the lump
    /// </summary>
    function Load(AMapNumber: Integer): IGreedMap;
  end;

  /// <summary>Turns the bytes of a lump of one kind into an image</summary>
  IGreedImageDecoder = interface
    ['{2A8C5F73-D914-4E06-B7A2-C41E90D63B85}']
    /// <summary>EGreedDataException if the bytes are not what the format needs</summary>
    function Decode(const ALump: TBytes): TGreedImage;
  end;

  /// <summary>What a lump is: by the group markers of the archive, or by the header of a picture</summary>
  IGreedLumpClassifier = interface
    ['{93B16E4D-7A05-4C82-A9F3-5D2E08C71B46}']
    function Classify(AIndex: Integer): TGreedLumpKind;
    /// <summary>The decoder of the kind, nil for glkOther and glkPalette</summary>
    function DecoderOf(AKind: TGreedLumpKind): IGreedImageDecoder;
  end;

  /// <summary>An image of palette indexes as the bytes of a PNG file</summary>
  IGreedImageEncoder = interface
    ['{C07E3B9A-5F61-4D28-8B14-E9A6D0372F59}']
    /// <summary>
    ///   APalette has 768 bytes (R, G, B of 8 bits). With ATransparentZero the color 0 is not drawn (alpha 0)
    /// </summary>
    function Encode(const AImage: TGreedImage; const APalette: TBytes; ATransparentZero: Boolean): TBytes;
  end;

  /// <summary>Draws a map from above, as an image of palette indexes</summary>
  IGreedMapRenderer = interface
    ['{5E92D6B0-3C47-4A81-BF05-78A1E3C94D26}']
    /// <summary>Each tile is 8 x 8 pixels: the floor, with the walls of its north and west sides</summary>
    function Render(const AMap: IGreedMap): TGreedImage;
  end;

  /// <summary>Saves a map or an image of the archive as a PNG file</summary>
  IGreedPngExporter = interface
    ['{A41F8D26-0B95-4E73-9C68-F3D2B7501E94}']
    procedure SaveMap(AMapNumber: Integer; const APath: string);
    /// <summary>The lump as an image, with the palette of the archive; EGreedDataException if it is not an image</summary>
    procedure SaveLump(AIndex: Integer; const APath: string);
  end;

implementation

end.
