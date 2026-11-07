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

implementation

end.
