{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the contracts                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.BinaryWriter;

type
  /// <summary>
  ///   The value after a key, as the formats read it. Reading is what tells the type: the text is
  ///   not typed
  /// </summary>
  IUdmfValueReader = interface
    ['{3E6A91C4-7D25-4B08-9F13-C5E2A0D84B76}']
    /// <summary>The next token in capital letters; empty at the end of the text</summary>
    function ReadToken: string;
    function ReadFloat: Single;
    function ReadInteger: Integer;
    /// <summary>A string with integers inside, like the moreids of a line</summary>
    function ReadIntegerList: TArray<Integer>;
    /// <summary>The next token, and whether it is TRUE</summary>
    function ReadIsTrue: Boolean;
    /// <summary>
    ///   The namespace of the map is not the one of the game: the specials have to be
    ///   translated. It is known when the namespace has been read
    /// </summary>
    function GetLineTranslate: Boolean;
    /// <summary>Tells the log that something in the map is not right</summary>
    procedure Warn(const AText: string);
    property LineTranslate: Boolean read GetLineTranslate;
  end;

  /// <summary>The number that the game gives to a sound by its name</summary>
  IUdmfSoundResolver = interface
    ['{B02D7F58-1A94-4C3E-8E67-4D9B1F20C583}']
    function NumberOf(const AName: string): Integer;
  end;

  /// <summary>What a game does with the things of a map: how it reads them and what it writes</summary>
  IUdmfThingFormat = interface
    ['{5C81E3A9-62F0-4D17-A4B8-9E0F7D2C1B35}']
    /// <summary>The thing before its first key</summary>
    procedure Reset(var AThing: TUdmfThing);
    /// <summary>Reads the value of a key; false if the game does not know the key</summary>
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var AThing: TUdmfThing): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    /// <summary>The record of the lump THINGS</summary>
    procedure WriteBase(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter);
    /// <summary>The record of the lump THINGS2</summary>
    procedure WriteExtra(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter);
    property BaseSize: Integer read GetBaseSize;
    property ExtraSize: Integer read GetExtraSize;
  end;

  IUdmfLineFormat = interface
    ['{A7F30B64-D81C-4E52-93A6-1C5E8D0F7A29}']
    procedure Reset(var ALine: TUdmfLine);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var ALine: TUdmfLine): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    procedure WriteBase(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter);
    procedure WriteExtra(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter);
    property BaseSize: Integer read GetBaseSize;
    property ExtraSize: Integer read GetExtraSize;
  end;

  IUdmfSideFormat = interface
    ['{19D4C7E2-8B30-4A65-B1F9-72A06E3D5C84}']
    procedure Reset(var ASide: TUdmfSide);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var ASide: TUdmfSide): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    procedure WriteBase(const ASide: TUdmfSide; const AWriter: TUdmfBinaryWriter);
    procedure WriteExtra(const ASide: TUdmfSide; const AWriter: TUdmfBinaryWriter);
    property BaseSize: Integer read GetBaseSize;
    property ExtraSize: Integer read GetExtraSize;
  end;

  IUdmfVertexFormat = interface
    ['{E3B58A17-4C92-4F06-8D71-0A9C2E6F3B45}']
    procedure Reset(var AVertex: TUdmfVertex);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var AVertex: TUdmfVertex): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    procedure WriteBase(const AVertex: TUdmfVertex; const AWriter: TUdmfBinaryWriter);
    procedure WriteExtra(const AVertex: TUdmfVertex; const AWriter: TUdmfBinaryWriter);
    property BaseSize: Integer read GetBaseSize;
    property ExtraSize: Integer read GetExtraSize;
  end;

  IUdmfSectorFormat = interface
    ['{7D26F9B3-A501-4E48-9C82-5B1E03A7D694}']
    procedure Reset(var ASector: TUdmfSector);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var ASector: TUdmfSector): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    procedure WriteBase(const ASector: TUdmfSector; const AWriter: TUdmfBinaryWriter);
    procedure WriteExtra(const ASector: TUdmfSector; const AWriter: TUdmfBinaryWriter);
    property BaseSize: Integer read GetBaseSize;
    property ExtraSize: Integer read GetExtraSize;
  end;

  /// <summary>Everything that changes from a game to another</summary>
  IUdmfProfile = interface
    ['{C4A17E80-35D9-4B26-A7F1-8E02B6D95C13}']
    /// <summary>The name of the game in capital letters: DOOM, HERETIC, HEXEN, STRIFE</summary>
    function GetGameName: string;
    function GetThings: IUdmfThingFormat;
    function GetLines: IUdmfLineFormat;
    function GetSides: IUdmfSideFormat;
    function GetVertexes: IUdmfVertexFormat;
    function GetSectors: IUdmfSectorFormat;
    property GameName: string read GetGameName;
    property Things: IUdmfThingFormat read GetThings;
    property Lines: IUdmfLineFormat read GetLines;
    property Sides: IUdmfSideFormat read GetSides;
    property Vertexes: IUdmfVertexFormat read GetVertexes;
    property Sectors: IUdmfSectorFormat read GetSectors;
  end;

  /// <summary>A text map that was converted: the lumps of a vanilla map and the extra ones</summary>
  IUdmfConvertedMap = interface
    ['{2F90D5B8-6E13-4A74-81C6-D7A4E0B3F529}']
    function GetNamespace: string;
    function GetLineTranslate: Boolean;
    function GetThingCount: Integer;
    function GetLineCount: Integer;
    function GetSideCount: Integer;
    function GetVertexCount: Integer;
    function GetSectorCount: Integer;
    function GetExtraThings: TBytes;
    function GetExtraLines: TBytes;
    function GetExtraSides: TBytes;
    function GetExtraVertexes: TBytes;
    function GetExtraSectors: TBytes;
    /// <summary>
    ///   The lumps of the map after its label, in the order of the vanilla maps (the ones that
    ///   the node builder fills are empty), then BEHAVIOR and SCRIPTS and the extra lumps
    /// </summary>
    function GetLumps(const AMapName: string; const ABehavior, AScripts: TBytes): TArray<TUdmfLump>;
    /// <summary>In capital letters, as it was written in the map</summary>
    property Namespace: string read GetNamespace;
    /// <summary>The namespace is not the one of the game</summary>
    property LineTranslate: Boolean read GetLineTranslate;
    property ThingCount: Integer read GetThingCount;
    property LineCount: Integer read GetLineCount;
    property SideCount: Integer read GetSideCount;
    property VertexCount: Integer read GetVertexCount;
    property SectorCount: Integer read GetSectorCount;
    property ExtraThings: TBytes read GetExtraThings;
    property ExtraLines: TBytes read GetExtraLines;
    property ExtraSides: TBytes read GetExtraSides;
    property ExtraVertexes: TBytes read GetExtraVertexes;
    property ExtraSectors: TBytes read GetExtraSectors;
  end;

  IUdmfConverter = interface
    ['{8B05E2D7-9A41-4C63-B0F8-3E7D1A5C9264}']
    function GetProfile: IUdmfProfile;
    /// <summary>The text of a TEXTMAP lump becomes the records of the map</summary>
    function Convert(const AText: string): IUdmfConvertedMap;
    property Profile: IUdmfProfile read GetProfile;
  end;

implementation

end.