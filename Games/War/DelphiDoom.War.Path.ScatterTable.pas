{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the order of the closed set of the A star         }
{                                                                              }
{  Port of the WarMapNodeMap of war1 (acoto87/war1, war_pathfinder.c over      }
{  shl/map.h and shl/internal.h by the same author, MIT), (c) 2018-2019        }
{  Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt).    }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Path.ScatterTable;

{$R-}
{$Q-}

interface

type
  /// <summary>
  ///   The hash table of shl/map.h (Fibonacci hash, chains through the buckets, doubling at half load) with the keys
  ///   only. The A star looks for the closest tile when the end cannot be reached by walking the buckets of the table
  ///   in memory order, and when two tiles are as close to the end and to the start as each other the first bucket
  ///   wins: so the order of the buckets is data of the game, and this class is the table with the same layout. It is
  ///   built only for that walk (the rest of the A star uses plain arrays)
  /// </summary>
  TWarScatterTable = class
  strict private
    type
      TEntry = record
        Active: Boolean;
        Hash: Cardinal;
        Next: Integer;
        Key: Integer;
      end;
    var
      FEntries: TArray<TEntry>;
      FCount: Integer;
      FLoadFactor: Integer;
      FShift: Integer;
    function FibonacciHash(AKey: Integer): Integer;
    function FindEmptyBucket(AStart: Integer): Integer;
    procedure Resize;
    procedure Insert(AKey: Integer);
    function GetCapacity: Integer;
    function GetActive(ABucket: Integer): Boolean;
    function GetKey(ABucket: Integer): Integer;
  public
    constructor Create;
    /// <summary>WarMapNodeMapSet: adds the key (a key that is already there stays where it is)</summary>
    procedure Add(AKey: Integer);
    /// <summary>The number of keys</summary>
    property Count: Integer read FCount;
    /// <summary>The number of buckets (a power of two)</summary>
    property Capacity: Integer read GetCapacity;
    /// <summary>Whether the bucket holds a key (the order of the walk is the order of the buckets)</summary>
    property Active[ABucket: Integer]: Boolean read GetActive;
    property Keys[ABucket: Integer]: Integer read GetKey;
  end;

implementation

const
  // SHL__INITIAL_CAPACITY, SHL__INITIAL_HASH_SHIFT, SHL__INITIAL_HASH_LOAD_FACTOR
  INITIAL_CAPACITY = 8;
  INITIAL_SHIFT = 29;
  INITIAL_LOAD_FACTOR = 6;
  HASH_CONSTANT = 2654435769;

{ TWarScatterTable }

constructor TWarScatterTable.Create;
begin
  inherited Create;
  SetLength(FEntries, INITIAL_CAPACITY);
  FShift := INITIAL_SHIFT;
  FLoadFactor := INITIAL_LOAD_FACTOR;
end;

function TWarScatterTable.GetCapacity: Integer;
begin
  Result := Length(FEntries);
end;

function TWarScatterTable.GetActive(ABucket: Integer): Boolean;
begin
  Result := FEntries[ABucket].Active;
end;

function TWarScatterTable.GetKey(ABucket: Integer): Integer;
begin
  Result := FEntries[ABucket].Key;
end;

function TWarScatterTable.FibonacciHash(AKey: Integer): Integer;
var
  LProduct: Cardinal;
begin
  // shl__fibHash: the 32 bit product wraps, then the high bits are kept
  LProduct := Cardinal((UInt64(Cardinal(AKey)) * HASH_CONSTANT) and $FFFFFFFF);
  Result := Integer(LProduct shr FShift);
end;

function TWarScatterTable.FindEmptyBucket(AStart: Integer): Integer;
var
  LIndex: Integer;
  LCurrent: Integer;
begin
  // shl__findEmptyBucket: the first free bucket from the start, wrapping around
  for LIndex := 0 to Length(FEntries) - 1 do
  begin
    LCurrent := (AStart + LIndex) mod Length(FEntries);
    if not FEntries[LCurrent].Active then
      Exit(LCurrent);
  end;
  Result := -1;
end;

procedure TWarScatterTable.Insert(AKey: Integer);
var
  LHash: Cardinal;
  LIndex: Integer;
  LNext: Integer;
begin
  LIndex := FibonacciHash(AKey);
  LHash := Cardinal(LIndex);
  while FEntries[LIndex].Active and (FEntries[LIndex].Next >= 0) do
  begin
    if (FEntries[LIndex].Hash = LHash) and (FEntries[LIndex].Key = AKey) then
      Exit;
    LIndex := FEntries[LIndex].Next;
  end;
  if FEntries[LIndex].Active then
    if (FEntries[LIndex].Hash = LHash) and (FEntries[LIndex].Key = AKey) then
      Exit;
  LNext := FindEmptyBucket(LIndex);
  if LNext < 0 then
  begin
    Resize;
    Insert(AKey);
    Exit;
  end;
  if LIndex <> LNext then
    FEntries[LIndex].Next := LNext;
  FEntries[LNext].Active := True;
  FEntries[LNext].Key := AKey;
  FEntries[LNext].Hash := LHash;
  FEntries[LNext].Next := -1;
  Inc(FCount);
end;

procedure TWarScatterTable.Resize;
var
  LOld: TArray<TEntry>;
  LIndex: Integer;
begin
  LOld := FEntries;
  FLoadFactor := Length(LOld);
  Dec(FShift);
  // a new array of empty buckets (SetLength on the shared array would keep the old ones)
  FEntries := nil;
  SetLength(FEntries, 1 shl (32 - FShift));
  FCount := 0;
  for LIndex := 0 to Length(LOld) - 1 do
    if LOld[LIndex].Active then
      Insert(LOld[LIndex].Key);
end;

procedure TWarScatterTable.Add(AKey: Integer);
begin
  if FCount = FLoadFactor then
    Resize;
  Insert(AKey);
end;

end.
