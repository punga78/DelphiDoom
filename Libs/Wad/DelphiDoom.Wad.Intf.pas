{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - contracts                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Intf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Types;

type
  /// <summary>
  ///   Something that has lumps: a WAD, a PAK, a ZIP (PK3), a folder or a
  ///   single file. Opened once, then read by index
  /// </summary>
  IWadSource = interface
    ['{6B1F2E0A-4C3D-4B8E-9A57-2D6F0C1E7A31}']
    function GetName: string;
    function GetKind: TWadSourceKind;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TWadEntry;
    /// <summary>The bytes of the lump; raises EWadException when it lies outside the file</summary>
    function ReadEntry(AIndex: Integer): TBytes;
    property Name: string read GetName;
    property Kind: TWadSourceKind read GetKind;
    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TWadEntry read GetEntry;
  end;

  /// <summary>
  ///   The lumps of several sources one after the other: the last loaded
  ///   takes precedence when names repeat
  /// </summary>
  IWadDirectory = interface
    ['{0E8D3C54-7A21-4F6B-8B19-5C4A9D2E6F70}']
    function GetCount: Integer;
    function GetSourceCount: Integer;
    function GetSource(AIndex: Integer): IWadSource;
    procedure AddSource(const ASource: IWadSource);
    /// <summary>Forgets the sources after the first ASourceCount (reload of a runtime WAD)</summary>
    procedure Truncate(ASourceCount: Integer);
    function LumpName(ALump: Integer): string;
    function LumpSize(ALump: Integer): Integer;
    /// <summary>TYPE_* bits of the marker pairs that enclose the lump</summary>
    function LumpFlags(ALump: Integer): Cardinal;
    function LumpSourceIndex(ALump: Integer): Integer;
    property Count: Integer read GetCount;
    property SourceCount: Integer read GetSourceCount;
    property Sources[AIndex: Integer]: IWadSource read GetSource;
  end;

  /// <summary>Searches by name, as W_CheckNumForName and friends</summary>
  IWadFinder = interface
    ['{9C7A5D13-2E48-4B0F-A6D1-8E3B1F4C0A52}']
    /// <summary>
    ///   The last lump with that name (-1 when none); AFlags limits it to the
    ///   lumps between marker pairs of those TYPE_* kinds (0 means any)
    /// </summary>
    function CheckNumForName(const AName: string; AFlags: Cardinal = 0): Integer;
    function CheckFirstNumForName(const AName: string): Integer;
    /// <summary>The last lump with that name between AFirst and ALast (included)</summary>
    function CheckNumForNameInRange(const AName: string; AFirst, ALast: Integer): Integer;
    /// <summary>Like CheckNumForName but raises EWadException when there is none</summary>
    function GetNumForName(const AName: string; AFlags: Cardinal = 0): Integer;
    function GetFirstNumForName(const AName: string): Integer;
  end;

  /// <summary>Reads the bytes of the lumps of a directory</summary>
  ILumpReader = interface
    ['{3F6E9B20-8D17-4A5C-B4E2-7A0C5D1E9F63}']
    function ReadLump(ALump: Integer): TBytes;
    /// <summary>Copies the lump into ADestination, which must hold LumpSize bytes</summary>
    procedure ReadLumpInto(ALump: Integer; ADestination: Pointer);
    /// <summary>The lump as text (one byte per character)</summary>
    function TextLump(ALump: Integer): string;
  end;

  /// <summary>How long a cached lump has to stay</summary>
  TLumpCacheLevel = (Static, Cache);

  /// <summary>Keeps the lumps already read, apart from reading them</summary>
  ILumpCache = interface
    ['{5A2C8E71-1B94-4D3F-9E60-4F7D2A8B3C15}']
    function GetCachedCount: Integer;
    /// <summary>The lump, read the first time; Static stays until Release, Cache until Purge</summary>
    function Lump(ALump: Integer; ALevel: TLumpCacheLevel): TBytes;
    procedure Release(ALump: Integer);
    /// <summary>Drops every lump cached with the Cache level</summary>
    procedure Purge;
    procedure Clear;
    property CachedCount: Integer read GetCachedCount;
  end;

  /// <summary>Makes a new WAD, or changes one read from a source</summary>
  IWadBuilder = interface
    ['{B4D07F3C-6E92-4A18-8C5B-0D2E7A91F346}']
    function GetKind: TWadKind;
    procedure SetKind(AValue: TWadKind);
    function GetCount: Integer;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpData(AIndex: Integer): TBytes;
    /// <summary>Appends a lump; returns its index</summary>
    function AddLump(const AName: string; const AData: TBytes): Integer;
    procedure InsertLump(AIndex: Integer; const AName: string; const AData: TBytes);
    procedure ReplaceLump(AIndex: Integer; const AData: TBytes);
    procedure RenameLump(AIndex: Integer; const AName: string);
    procedure DeleteLump(AIndex: Integer);
    procedure MoveLump(AFromIndex, AToIndex: Integer);
    function IndexOf(const AName: string): Integer;
    /// <summary>Replaces what is in the builder with the lumps of ASource</summary>
    procedure LoadFrom(const ASource: IWadSource);
    procedure Clear;
    function ToBytes: TBytes;
    procedure SaveToStream(AStream: TStream);
    procedure SaveToFile(const AFileName: string);
    property Kind: TWadKind read GetKind write SetKind;
    property Count: Integer read GetCount;
    property LumpNames[AIndex: Integer]: string read GetLumpName;
    property LumpData[AIndex: Integer]: TBytes read GetLumpData;
  end;

implementation

end.
