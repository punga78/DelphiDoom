{******************************************************************************}
{                                                                              }
{  DelphiDoom: zone library - the allocator                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the allocator of the engine (z_memmgr): same table of blocks,       }
{  same rules for tags and user pointers.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zone.Allocator;

interface

uses
  System.SysUtils, DelphiDoom.Zone.Intf, DelphiDoom.Zone.Types;

type
  /// <summary>
  ///   The header that sits in front of the bytes of every block. Index is the place of the
  ///   block in the table: a pointer is a block of the zone only if the table holds it there
  /// </summary>
  TZoneBlock = record
    Size: Integer;
    Tag: Integer;
    Index: Integer;
    User: PPointer;
  end;
  PZoneBlock = ^TZoneBlock;

  /// <summary>
  ///   Every block is its own piece of the memory source, with a header in front, and the
  ///   table lists them all (a freed block is replaced by the last one). Cost of every call:
  ///   one interface call to the memory source
  /// </summary>
  TZoneAllocator = class(TInterfacedObject, IZoneAllocator)
  strict private
    FMemory: IZoneMemory;
    FBlocks: TArray<PZoneBlock>;
    FCount: Integer;
    function BlockOf(const APointer: Pointer): PZoneBlock;
    function DataOf(const ABlock: PZoneBlock): Pointer; inline;
    procedure Grow;
    procedure Release(ABlock: PZoneBlock);
  public
    /// <summary>The allocator frees every block it still holds when it is destroyed</summary>
    constructor Create(const AMemory: IZoneMemory);
    destructor Destroy; override;
    function Allocate(ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
    function Reallocate(APointer: Pointer; ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
    procedure FreeBlock(APointer: Pointer);
    function BlockSize(APointer: Pointer): Integer;
    procedure ChangeTag(APointer: Pointer; ATag: Integer);
    function FreeTags(ALowTag, AHighTag: Integer): Integer;
    function MoveUsers(AOldStart: Pointer; AByteCount: NativeInt; ANewStart: Pointer): Integer;
    procedure CheckHeap;
    procedure CheckUsers;
    function Statistics: TZoneStatistics;
    function Describe(ALowTag, AHighTag: Integer): TArray<string>;
  end;

implementation

const
  SZoneMemoryMissing = 'The zone needs a memory source.';
  SZoneNilPointer = 'The pointer is nil.';
  SZoneNegativeSize = 'A block cannot have a negative size (%d).';
  SZoneNotABlock = 'The pointer $%s is not a block of the zone (never allocated, or already freed).';
  SZoneBadIndex = 'Block %d of the table has the index %d in its header.';
  SZoneNilBlock = 'The table of the zone has a hole at the place %d.';
  SZoneBadSize = 'Block %d of the table has a negative size (%d).';
  SZoneBadUser = 'The user pointer $%s of the block %d is not an address.';
  SZoneDescription = 'zone blocks: %d  bytes: %d  bytes with headers: %d';
  SZoneTagRange = 'tag range: %.3d to %.3d';
  SZoneBlockLine = 'block:%s    size:%.7d    user:%s    tag:%.3d';

  // A user pointer smaller than this is a number, not an address
  USER_LOWEST_ADDRESS = $10000;
  USER_HIGHEST_NUMBER = 100;

function AddressText(const APointer: Pointer): string;
begin
  Result := IntToHex(NativeUInt(APointer), SizeOf(Pointer) * 2);
end;

{ TZoneAllocator }

constructor TZoneAllocator.Create(const AMemory: IZoneMemory);
begin
  inherited Create;
  if not Assigned(AMemory) then
    raise EArgumentNilException.Create(SZoneMemoryMissing);
  FMemory := AMemory;
end;

destructor TZoneAllocator.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := FCount - 1 downto 0 do
    FMemory.Release(FBlocks[LIndex], FBlocks[LIndex].Size + SizeOf(TZoneBlock));
  inherited;
end;

function TZoneAllocator.DataOf(const ABlock: PZoneBlock): Pointer;
begin
  Result := PByte(ABlock) + SizeOf(TZoneBlock);
end;

function TZoneAllocator.BlockOf(const APointer: Pointer): PZoneBlock;
begin
  if not Assigned(APointer) then
    raise EZoneException.Create(SZoneNilPointer);
  Result := PZoneBlock(PByte(APointer) - SizeOf(TZoneBlock));
  if (Result.Index < 0) or (Result.Index >= FCount) or (FBlocks[Result.Index] <> Result) then
    raise EZoneException.CreateFmt(SZoneNotABlock, [AddressText(APointer)]);
end;

procedure TZoneAllocator.Grow;
begin
  // the same growth as the old table: a third more plus 64, a multiple of 8
  SetLength(FBlocks, (Length(FBlocks) * 4 div 3 + 64) and not 7);
end;

procedure TZoneAllocator.Release(ABlock: PZoneBlock);
var
  LIndex: Integer;
begin
  LIndex := ABlock.Index;
  if Assigned(ABlock.User) then
    ABlock.User^ := nil;
  FMemory.Release(ABlock, ABlock.Size + SizeOf(TZoneBlock));
  Dec(FCount);
  if LIndex < FCount then
  begin
    FBlocks[LIndex] := FBlocks[FCount];
    FBlocks[LIndex].Index := LIndex;
  end;
  FBlocks[FCount] := nil;
end;

function TZoneAllocator.Allocate(ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
var
  LBlock: PZoneBlock;
begin
  if ASize < 0 then
    raise EZoneException.CreateFmt(SZoneNegativeSize, [ASize]);
  if Length(FBlocks) <= FCount then
    Grow;
  LBlock := FMemory.Allocate(ASize + SizeOf(TZoneBlock));
  LBlock.Size := ASize;
  LBlock.Tag := ATag;
  LBlock.Index := FCount;
  LBlock.User := AUser;
  FBlocks[FCount] := LBlock;
  Inc(FCount);
  Result := DataOf(LBlock);
  if Assigned(AUser) then
    AUser^ := Result;
end;

function TZoneAllocator.Reallocate(APointer: Pointer; ASize: Integer; ATag: Integer;
  AUser: PPointer): Pointer;
var
  LOld: PZoneBlock;
  LNew: PZoneBlock;
  LCopySize: Integer;
begin
  if ASize = 0 then
  begin
    if Assigned(APointer) then
      FreeBlock(APointer);
    Result := nil;
    Exit;
  end;
  if not Assigned(APointer) then
    Exit(Allocate(ASize, ATag, AUser));

  LOld := BlockOf(APointer);
  if LOld.Size = ASize then
    Exit(APointer);

  // The new block is made without a user: the old one is freed (and its user cleared)
  // before the user of the new one is set, so the same variable can be passed again
  Result := Allocate(ASize, ATag, nil);
  LNew := PZoneBlock(PByte(Result) - SizeOf(TZoneBlock));
  if ASize < LOld.Size then
    LCopySize := ASize
  else
    LCopySize := LOld.Size;
  Move(APointer^, Result^, LCopySize);
  FreeBlock(APointer);
  LNew.User := AUser;
  if Assigned(AUser) then
    AUser^ := Result;
end;

procedure TZoneAllocator.FreeBlock(APointer: Pointer);
begin
  Release(BlockOf(APointer));
end;

function TZoneAllocator.BlockSize(APointer: Pointer): Integer;
begin
  Result := BlockOf(APointer).Size;
end;

procedure TZoneAllocator.ChangeTag(APointer: Pointer; ATag: Integer);
begin
  BlockOf(APointer).Tag := ATag;
end;

function TZoneAllocator.FreeTags(ALowTag, AHighTag: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  // From the end: the block that takes the place of a freed one was already looked at
  for LIndex := FCount - 1 downto 0 do
    if (FBlocks[LIndex].Tag >= ALowTag) and (FBlocks[LIndex].Tag <= AHighTag) then
    begin
      Release(FBlocks[LIndex]);
      Inc(Result);
    end;
end;

function TZoneAllocator.MoveUsers(AOldStart: Pointer; AByteCount: NativeInt;
  ANewStart: Pointer): Integer;
var
  LIndex: Integer;
  LOffset: NativeUInt;
begin
  Result := 0;
  for LIndex := 0 to FCount - 1 do
    if Assigned(FBlocks[LIndex].User) and
       (NativeUInt(FBlocks[LIndex].User) >= NativeUInt(AOldStart)) then
    begin
      LOffset := NativeUInt(FBlocks[LIndex].User) - NativeUInt(AOldStart);
      if LOffset < NativeUInt(AByteCount) then
      begin
        FBlocks[LIndex].User := PPointer(PByte(ANewStart) + LOffset);
        Inc(Result);
      end;
    end;
end;

procedure TZoneAllocator.CheckHeap;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
  begin
    if not Assigned(FBlocks[LIndex]) then
      raise EZoneException.CreateFmt(SZoneNilBlock, [LIndex]);
    if FBlocks[LIndex].Index <> LIndex then
      raise EZoneException.CreateFmt(SZoneBadIndex, [LIndex, FBlocks[LIndex].Index]);
    if FBlocks[LIndex].Size < 0 then
      raise EZoneException.CreateFmt(SZoneBadSize, [LIndex, FBlocks[LIndex].Size]);
  end;
end;

procedure TZoneAllocator.CheckUsers;
var
  LIndex: Integer;
  LUser: NativeUInt;
begin
  for LIndex := 0 to FCount - 1 do
  begin
    LUser := NativeUInt(FBlocks[LIndex].User);
    if (LUser > USER_HIGHEST_NUMBER) and (LUser < USER_LOWEST_ADDRESS) then
      raise EZoneException.CreateFmt(SZoneBadUser, [IntToHex(LUser, 4), LIndex]);
  end;
end;

function TZoneAllocator.Statistics: TZoneStatistics;
var
  LIndex: Integer;
  LTotal: Int64;
begin
  Result := Default(TZoneStatistics);
  Result.BlockCount := FCount;
  for LIndex := 0 to FCount - 1 do
  begin
    LTotal := Int64(FBlocks[LIndex].Size) + SizeOf(TZoneBlock);
    Inc(Result.UserBytes, FBlocks[LIndex].Size);
    Inc(Result.TotalBytes, LTotal);
    if FBlocks[LIndex].Tag >= ZONE_TAG_PURGELEVEL then
      Inc(Result.PurgableBytes, LTotal);
  end;
end;

function TZoneAllocator.Describe(ALowTag, AHighTag: Integer): TArray<string>;
var
  LIndex: Integer;
  LStatistics: TZoneStatistics;
  LLines: TArray<string>;
  LUsed: Integer;
begin
  LStatistics := Statistics;
  SetLength(LLines, FCount + 2);
  LLines[0] := Format(SZoneDescription,
    [LStatistics.BlockCount, LStatistics.UserBytes, LStatistics.TotalBytes]);
  LLines[1] := Format(SZoneTagRange, [ALowTag, AHighTag]);
  LUsed := 2;
  for LIndex := 0 to FCount - 1 do
    if (FBlocks[LIndex].Tag >= ALowTag) and (FBlocks[LIndex].Tag <= AHighTag) then
    begin
      LLines[LUsed] := Format(SZoneBlockLine, [AddressText(FBlocks[LIndex]),
        FBlocks[LIndex].Size, AddressText(FBlocks[LIndex].User), FBlocks[LIndex].Tag]);
      Inc(LUsed);
    end;
  SetLength(LLines, LUsed);
  Result := LLines;
end;

end.
