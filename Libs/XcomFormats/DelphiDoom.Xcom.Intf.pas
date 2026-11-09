{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the contracts                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Intf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Map;

type
  /// <summary>
  ///   Where the files of the game are: a folder of the original game (UFO or TFTD) or the memory of a test.
  ///   Names use / or \ for the folders (GEODATA/PALETTES.DAT) and do not care about the case
  /// </summary>
  IXcomDataFiles = interface
    ['{6D2A8E41-0B73-4C95-A1F6-3E58D90B7C24}']
    function Exists(const AName: string): Boolean;
    /// <summary>The whole file; EXcomFileNotFoundException if it is not there</summary>
    function ReadAll(const AName: string): TBytes;
  end;

  /// <summary>An image that is only the pixels of a file of one picture (.SCR, .SPK, .BDY)</summary>
  IXcomImageDecoder = interface
    ['{B4F10C97-52E8-4D3A-8B06-A19C7E2D5F83}']
    /// <summary>
    ///   Decodes the bytes into an image of AWidth x AHeight pixels. Like the original it does not check the
    ///   data: what the file does not fill stays 0 and what is past the image is lost
    /// </summary>
    function Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TXcomImage;
  end;

  /// <summary>A .PCK file with its .TAB: the frames of a set of sprites (SurfaceSet::loadPck)</summary>
  IXcomPckDecoder = interface
    ['{19E7D3A0-8C64-47B2-9F15-D2A60B8C3E71}']
    /// <summary>
    ///   Decodes the frames, all of AWidth x AHeight pixels. The .TAB only gives HOW MANY frames there are (the
    ///   offsets are not used: the frames follow one another in the .PCK); an empty ATab is one frame
    /// </summary>
    function Decode(const APck, ATab: TBytes; AWidth, AHeight: Integer): TArray<TXcomImage>;
  end;

  /// <summary>A .DAT file of pictures that follow one another with no compression (SurfaceSet::loadDat)</summary>
  IXcomDatDecoder = interface
    ['{7A05CB82-E391-4F6D-B2D8-5C14F9A03E67}']
    /// <summary>As many frames of AWidth x AHeight pixels as the bytes fill; the pixels that are left are lost</summary>
    function Decode(const ABytes: TBytes; AWidth, AHeight: Integer): TArray<TXcomImage>;
  end;

  /// <summary>The colors of GEODATA\PALETTES.DAT and BACKPALS.DAT (Palette::loadDat)</summary>
  IXcomPaletteReader = interface
    ['{D3816F2B-A47C-4E90-8153-B7E02C69A1D4}']
    /// <summary>
    ///   ACount colors of 3 bytes of 6 bits each, from the byte AOffset (each value times 4); a color
    ///   the file does not have stays black with alpha 0, and the color 0 has alpha 0 always
    /// </summary>
    function Read(const ABytes: TBytes; ACount, AOffset: Integer): TXcomPalette;
    /// <summary>Where the palette number AIndex starts in PALETTES.DAT (Palette::palOffset)</summary>
    function OffsetOf(AIndex: Integer): Integer;
  end;

  /// <summary>A .CAT file: an index of entries, each with a name that starts it (CatFile)</summary>
  IXcomCatArchive = interface
    ['{4C97E1D5-3A82-4B06-95F7-E0D18A6C2B39}']
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TXcomCatEntry;
    /// <summary>
    ///   The bytes of an entry (CatFile::load). The entry starts with a name (a length byte of at most 56 and the
    ///   name): it is skipped, unless AKeepName. The size of the index is the size of what follows the name
    /// </summary>
    function Load(AIndex: Integer; AKeepName: Boolean = False): TBytes;
    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TXcomCatEntry read GetEntry;
  end;

  IXcomMapReader = interface
    ['{0E5B7A93-C1F4-48D6-A279-6B3D80E5F1C2}']
    /// <summary>
    ///   Only the three signed bytes of the size (what the C++ reads into char size[3]): negative for 128..255.
    ///   EXcomDataException if the file has less than 3 bytes
    /// </summary>
    function ReadHeader(const ABytes: TBytes): TXcomMapHeader;
    /// <summary>
    ///   The block. The cells are read four bytes at a time while there are four (a few bytes at the end are
    ///   ignored). EXcomDataException when a size is not more than 0, or the file has more cells than the size says
    /// </summary>
    function Read(const ABytes: TBytes): TXcomMap;
  end;

  IXcomRouteReader = interface
    ['{85A3D6C0-92E1-4F7B-B684-1D0E7C5A93F8}']
    /// <summary>The records of the file, 24 bytes each (a few bytes at the end are ignored)</summary>
    function Read(const ABytes: TBytes): TArray<TXcomRmpRecord>;
    /// <summary>
    ///   Turns the records of a block of ASizeX x ASizeY x ASizeZ cells placed at (AOffsetX, AOffsetY) into nodes
    ///   whose numbers start at ANodeOffset. A node outside the block becomes a dummy and the links of the other
    ///   nodes that go to it are cut; ACulled gets the numbers (in the file) of the dummies
    /// </summary>
    function Resolve(const ARecords: TArray<TXcomRmpRecord>; ASizeX, ASizeY, ASizeZ,
      AOffsetX, AOffsetY, ANodeOffset: Integer; out ACulled: TArray<Integer>): TArray<TXcomRouteNode>;
  end;

  /// <summary>The terrain of a .MCD file (MapDataSet::loadData)</summary>
  IXcomMcdReader = interface
    ['{F27C41E8-6D95-4A03-8B1C-C9E3A0D57B62}']
    /// <summary>The records, 62 bytes each (a few bytes at the end are ignored); no check is done</summary>
    function Read(const ABytes: TBytes): TArray<TXcomMcdRecord>;
    /// <summary>
    ///   The check that MapDataSet does after the patches of the rules: DieMCD and AltMCD must be objects
    ///   of the file and the armor must not be 0. EXcomDataException with the first problem
    /// </summary>
    procedure Validate(const ARecords: TArray<TXcomMcdRecord>);
  end;

  /// <summary>WORLD.DAT (RuleGlobe::loadDat)</summary>
  IXcomWorldReader = interface
    ['{3B9E50D1-A8C7-4162-9F04-E571D2B86C3A}']
    function Read(const ABytes: TBytes): TArray<TXcomWorldPolygon>;
    /// <summary>X-Com degrees (an eighth of a degree) to radians (Xcom2Rad)</summary>
    function ToRadians(ADegrees: Integer): Double;
  end;

  /// <summary>
  ///   What IMG_Load makes of an .LBM file: the indexed picture with its palette (Image.Palette) and the
  ///   color key of the surface (SDL_SRCCOLORKEY with the transparent color of the BMHD, when masking is 2)
  /// </summary>
  TXcomLbmPicture = record
    Image: TXcomImage;
    HasColorKey: Boolean;
    ColorKey: Cardinal;
  end;

  /// <summary>.LBM files (IFF PBM and ILBM), read like SDL_image does</summary>
  IXcomLbmReader = interface
    ['{5E2A9C47-31B8-4D06-A7F1-C94E08B2D5A3}']
    function Read(const ABytes: TBytes): TXcomLbmPicture;
  end;

  /// <summary>LOFTEMPS.DAT and the other files that are a row of 16 bit numbers (MapDataSet::loadLOFTEMPS)</summary>
  IXcomWordTableReader = interface
    ['{C61F8A27-0D53-4E9B-A4B2-8F7D19E36C05}']
    /// <summary>The words (a odd byte at the end is ignored)</summary>
    function Read(const ABytes: TBytes): TArray<Word>;
  end;

  /// <summary>
  ///   The data of an installed game (UFO or TFTD) seen through its folders: files are looked for with the
  ///   names that OpenXcom uses (GEODATA/PALETTES.DAT, GEOGRAPH/BACK01.SCR, MAPS/URBAN01.MAP...)
  /// </summary>
  IXcomGameData = interface
    ['{5E80B3C9-17A4-4D62-93FB-A06C1D4E7B25}']
    function GetFiles: IXcomDataFiles;
    /// <summary>The palette AIndex of GEODATA/PALETTES.DAT (0 geoscape, 1 basescape, 2 graphs, 3 ufopaedia, 4 battlescape...)</summary>
    function LoadPalette(AIndex: Integer): TXcomPalette;
    /// <summary>
    ///   A picture of one of the formats of full images, chosen from the extension of the name: .SCR, .SPK or .BDY.
    ///   The palette is put on the image
    /// </summary>
    function LoadImage(const AName: string; AWidth, AHeight: Integer; const APalette: TXcomPalette): TXcomImage;
    /// <summary>
    ///   The frames of a .PCK and its .TAB (ATabName, or the same name as the .PCK when it is empty; a missing .TAB is
    ///   one frame), or of a .DAT; with the palette
    /// </summary>
    function LoadImageSet(const AName, ATabName: string; AWidth, AHeight: Integer;
      const APalette: TXcomPalette): TArray<TXcomImage>;
    function LoadMap(const AName: string): TXcomMap;
    function LoadRoute(const AName: string): TArray<TXcomRmpRecord>;
    function LoadTerrain(const AName: string): TArray<TXcomMcdRecord>;
    property Files: IXcomDataFiles read GetFiles;
  end;

  /// <summary>A picture goes into the bytes of a file of an image format</summary>
  IXcomImageEncoder = interface
    ['{92D40B6E-F185-47A3-8C69-E0A5B3D71F48}']
    /// <summary>
    ///   The image with its palette (the Palette of AImage must be there) as the bytes of the file;
    ///   the pixels of index 0 are transparent when ATransparentZero
    /// </summary>
    function Encode(const AImage: TXcomImage; ATransparentZero: Boolean): TBytes;
  end;

implementation

end.
