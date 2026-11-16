{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the contracts                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.Intf;

interface

uses
  System.Classes, DelphiDoom.Serializer.Types;

type
  /// <summary>Turns a pointer to a state into its index and back; the library does not know the type of a state</summary>
  ISerializerStateResolver = interface
    ['{3B5E8A12-7C40-4D9B-A1F6-52C8E0D47B91}']
    /// <summary>The index of a state (AState is never nil)</summary>
    function StateIndex(const AState: Pointer): Cardinal;
    /// <summary>The state with an index</summary>
    function StateAt(AIndex: Cardinal): Pointer;
  end;

  /// <summary>Turns a pointer to a mobj into its key and back</summary>
  ISerializerMobjResolver = interface
    ['{9E27C4B0-1D83-4A6F-8B35-F0A71C62D894}']
    /// <summary>The key of a mobj (AMobj is never nil); 0 means that it has none and it is not written</summary>
    function MobjKey(const AMobj: Pointer): Cardinal;
    /// <summary>The mobj with a key, or nil</summary>
    function MobjByKey(AKey: Cardinal): Pointer;
  end;

  /// <summary>Turns a pointer to a player into its number (index + 1, never 0) and back</summary>
  ISerializerPlayerResolver = interface
    ['{C1704E5D-62B9-4F38-9A0E-7D3B58E1A246}']
    function PlayerNumber(const APlayer: Pointer): Cardinal;
    function PlayerByNumber(ANumber: Cardinal): Pointer;
  end;

  /// <summary>
  ///   The table of the fields of a record and the way to write it to a stream and to read it
  ///   back. A record in the stream is a list of (field number, value) of the fields that are not
  ///   at their default, then the end marker 0; numbers are 16 bit, values little endian
  /// </summary>
  ISerializer = interface
    ['{57F0A3C8-D914-4B27-86E1-0A9C35B7D2F6}']
    procedure Clear;
    function GetCount: Integer;
    /// <summary>A block of AOffset..AOffset+ASize bytes, at zero when not in the stream</summary>
    procedure AddGeneric(AOffset: NativeInt; ASize: Integer; const AOnLoaded: TSerializerLoadedProc = nil);
    /// <summary>A short string (the record holds 256 bytes: length and characters)</summary>
    procedure AddText(AOffset: NativeInt; const ADefault: AnsiString; const AOnLoaded: TSerializerLoadedProc = nil);
    procedure AddFloat(AOffset: NativeInt; ADefault: Single; const AOnLoaded: TSerializerLoadedProc = nil);
    /// <summary>A field of a kind other than Generic, Float and Text; ADefault is what it is when it is not in the stream</summary>
    procedure AddTyped(AOffset: NativeInt; AKind: TSerializerFieldKind; ADefault: Int64;
      const AOnLoaded: TSerializerLoadedProc = nil);
    /// <summary>Writes the record; gives the bytes written. Raises ESerializerException/EWriteError if it cannot</summary>
    function SaveToStream(const AStream: TStream; const AStruct: Pointer): Integer;
    /// <summary>Sets the defaults, reads the record; gives the bytes read. Raises ESerializerException/EReadError for a stream the table cannot read</summary>
    function LoadFromStream(const AStream: TStream; const AStruct: Pointer): Integer;
    /// <summary>Writes into AMemory, that has AMaxSize bytes</summary>
    function SaveToMemory(const AMemory, AStruct: Pointer; AMaxSize: Integer): Integer;
    function LoadFromMemory(const AMemory, AStruct: Pointer; AMaxSize: Integer): Integer;
    /// <summary>
    ///   After the whole level is read: the slots of mobj, player and state fields (that hold the
    ///   raw numbers read from the stream) become pointers
    /// </summary>
    procedure ResolvePointers(const AStruct: Pointer);
    property Count: Integer read GetCount;
  end;

  /// <summary>Makes serializers that share the same resolvers</summary>
  ISerializerFactory = interface
    ['{A862D1F7-30E5-4C94-B17A-E4F59B0C8D63}']
    function CreateSerializer: ISerializer;
  end;

  /// <summary>
  ///   How a record that is saved "raw" (the whole record, not field by field) lies on disk. On disk it
  ///   is what the 32 bit program keeps in memory: a pointer and a NativeInt are 4 bytes and the fields are
  ///   aligned as the 32 bit compiler aligns them. In memory it is what the running program has. With a
  ///   32 bit program the two are the same bytes (issue #40)
  /// </summary>
  IDiskLayout = interface
    ['{6D0B4F1A-93C7-4E52-8A1D-B7E260F4C935}']
    function GetName: string;
    function GetNativeSize: Integer;
    function GetDiskSize: Integer;
    /// <summary>Writes the record of memory into ADisk (DiskSize bytes)</summary>
    procedure Pack(const ANative: Pointer; const ADisk: Pointer);
    /// <summary>Reads the DiskSize bytes of ADisk into the record of memory; a 4 byte value keeps its sign</summary>
    procedure Unpack(const ADisk: Pointer; const ANative: Pointer);
    /// <summary>
    ///   Reads only the first ADiskBytes bytes of the layout on disk. The engine reads the record of an old
    ///   version of the saved games over the start of the record of today: the old one is a prefix of it
    ///   for the 32 bit program, so on disk, but not always in the memory of the 64 bit program
    /// </summary>
    procedure UnpackPrefix(const ADisk: Pointer; const ANative: Pointer; ADiskBytes: Integer);
    /// <summary>
    ///   The layout on disk in words: the size, then offset, size and name of every field and the offsets of
    ///   the values that are pointers in memory. It never tells anything of the layout in memory, so the
    ///   32 and the 64 bit programs must say the same lines
    /// </summary>
    function Describe: TArray<string>;
    property Name: string read GetName;
    property NativeSize: Integer read GetNativeSize;
    property DiskSize: Integer read GetDiskSize;
  end;

  /// <summary>The layouts on disk of the records of the saved games, by type</summary>
  IDiskLayouts = interface
    ['{F38A27C1-5B60-4D0E-9C74-1E8D53A6B0F2}']
    /// <summary>
    ///   Tells what a field with an unnamed type is (the compiler keeps no type information for
    ///   "array[0..3] of pspdef_t" written in the record): ACount elements of the type AElement
    /// </summary>
    procedure DescribeArray(const ARecord: Pointer; const AField: string; const AElement: Pointer;
      ACount: Integer);
    /// <summary>Adds a record to the list that DescribeAll tells (ATypeInfo is TypeInfo(the record))</summary>
    procedure Declare(const ATypeInfo: Pointer);
    /// <summary>The layout of a record; ESerializerException when the record cannot be understood</summary>
    function LayoutOf(const ATypeInfo: Pointer): IDiskLayout;
    /// <summary>The lines of Describe of every declared record, in the order of the declarations</summary>
    function DescribeAll: TArray<string>;
  end;

  /// <summary>
  ///   The raw records being written to the buffer of a saved game: a copy in memory to change (pointers
  ///   into numbers) and, at the end, the copies written to their places with the layout on disk
  /// </summary>
  IDiskRecordWriter = interface
    ['{2C9E61B4-A7D3-4F08-B5E2-90D14C3F7A68}']
    /// <summary>A copy of ASource to change; its place is ADisk, which moves after the record</summary>
    function Reserve(const ALayout: IDiskLayout; const ASource: Pointer; var ADisk: Pointer): Pointer;
    /// <summary>Writes the copies to their places and frees them</summary>
    procedure Commit;
  end;

implementation

end.
