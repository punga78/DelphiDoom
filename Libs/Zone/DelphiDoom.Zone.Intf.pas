{******************************************************************************}
{                                                                              }
{  DelphiDoom: zone library - the contracts                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zone.Intf;

interface

uses
  DelphiDoom.Zone.Types;

type
  /// <summary>
  ///   Where the raw bytes of the zone come from: the heap of the program, or a fake one that
  ///   counts and checks in the tests
  /// </summary>
  IZoneMemory = interface
    ['{4C8E2B71-90A5-4D3F-B6E8-17A2C5D94F03}']
    /// <summary>ASize bytes, never nil; raises when the memory is not there</summary>
    function Allocate(ASize: NativeInt): Pointer;
    /// <summary>Gives back a block of Allocate; ASize is the size that was asked</summary>
    procedure Release(APointer: Pointer; ASize: NativeInt);
  end;

  /// <summary>
  ///   The allocator of the engine: blocks with a tag (how long they live) and an optional
  ///   user pointer, a variable that always holds the address of the block and that is set to
  ///   nil when the block is freed. Blocks are not cleared. It raises EZoneException when a
  ///   pointer is not a block of the zone (never given, or already freed)
  /// </summary>
  IZoneAllocator = interface
    ['{B3F6A0D8-5E21-4C97-8A4B-6D0E9F13C752}']
    /// <summary>
    ///   A block of ASize bytes (0 is allowed). AUser, when not nil, receives the address
    ///   of the block now and nil when the block is freed
    /// </summary>
    function Allocate(ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
    /// <summary>
    ///   Resizes a block, keeping the bytes that fit: nil with a size is Allocate, a size of
    ///   0 is Free (the result is nil), the same size gives the same block untouched (tag
    ///   and user too). Otherwise the block moves; the old user pointer is set to nil
    /// </summary>
    function Reallocate(APointer: Pointer; ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
    procedure FreeBlock(APointer: Pointer);
    /// <summary>The size that was asked for the block</summary>
    function BlockSize(APointer: Pointer): Integer;
    procedure ChangeTag(APointer: Pointer; ATag: Integer);
    /// <summary>Frees every block whose tag is between the two (included); gives how many</summary>
    function FreeTags(ALowTag, AHighTag: Integer): Integer;
    /// <summary>
    ///   A block of memory that holds user pointers has moved (a table that grew): the
    ///   user pointers inside [AOldStart, AOldStart + AByteCount) follow it to ANewStart.
    ///   Gives how many were changed
    /// </summary>
    function MoveUsers(AOldStart: Pointer; AByteCount: NativeInt; ANewStart: Pointer): Integer;
    /// <summary>Checks the table of the blocks and every header; raises on the first damage</summary>
    procedure CheckHeap;
    /// <summary>Raises when a user pointer is a small number (a value that is not an address)</summary>
    procedure CheckUsers;
    function Statistics: TZoneStatistics;
    /// <summary>
    ///   A line of text for the zone and one for every block with a tag in the range, in
    ///   the order of the table
    /// </summary>
    function Describe(ALowTag, AHighTag: Integer): TArray<string>;
  end;

implementation

end.
