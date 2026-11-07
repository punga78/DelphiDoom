{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - TIdHashIndex, the fast hash of indexes       }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\HashIndex.h   }
{  and HashIndex.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax       }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.HashIndex;

{$Q-}
{$R-}

interface

const
  /// <summary>DEFAULT_HASH_SIZE of idHashIndex</summary>
  ID_DEFAULT_HASH_SIZE = 1024;
  /// <summary>DEFAULT_HASH_GRANULARITY of idHashIndex</summary>
  ID_DEFAULT_HASH_GRANULARITY = 1024;

type
  /// <summary>
  ///   A hash table of indexes into an array kept by the caller (idHashIndex): <c>Add(key, index)</c>
  ///   links an index to a key, <c>First(key)</c> and <c>Next(index)</c> walk the indexes of a key
  ///   (the last added first), -1 ends the chain. Memory is allocated at the first <c>Add</c>.
  ///   Same behaviour as the original, including the order of the chains and the growth of the index
  ///   in steps of the granularity. The hash size must be a power of two (EArgumentException).
  /// </summary>
  TIdHashIndex = class
  private
    FHashSize: Integer;
    FHash: TArray<Integer>;
    FIndexSize: Integer;
    FIndexChain: TArray<Integer>;
    FGranularity: Integer;
    FHashMask: Integer;
    FLookupMask: Integer;
    procedure Init(const AInitialHashSize, AInitialIndexSize: Integer);
    procedure Allocate(const ANewHashSize, ANewIndexSize: Integer);
    function IsAllocated: Boolean; inline;
  public
    constructor Create; overload;
    constructor Create(const AInitialHashSize, AInitialIndexSize: Integer); overload;
    /// <summary>idHashIndex::Allocated: the bytes of the hash and of the index</summary>
    function Allocated: NativeInt;
    /// <summary>operator=: copies the table</summary>
    procedure Assign(const AOther: TIdHashIndex);
    /// <summary>Adds an index to the hash; the index must not be in the hash yet</summary>
    procedure Add(const AKey, AIndex: Integer);
    /// <summary>Removes an index from the hash</summary>
    procedure Remove(const AKey, AIndex: Integer);
    /// <summary>The first index of the key, -1 if the chain is empty</summary>
    function First(const AKey: Integer): Integer;
    /// <summary>The next index of the chain, -1 at the end</summary>
    function Next(const AIndex: Integer): Integer;
    /// <summary>Inserts an entry in the index and adds it to the hash, increasing all indexes &gt;= AIndex</summary>
    procedure InsertIndex(const AKey, AIndex: Integer);
    /// <summary>Removes an entry from the index and from the hash, decreasing all indexes &gt;= AIndex</summary>
    procedure RemoveIndex(const AKey, AIndex: Integer);
    /// <summary>Clears the hash (not the index chain)</summary>
    procedure Clear; overload;
    /// <summary>Clears and resizes: frees the memory, the next Add allocates the new sizes</summary>
    procedure Clear(const ANewHashSize, ANewIndexSize: Integer); overload;
    /// <summary>idHashIndex::Free: releases the memory (the object stays usable)</summary>
    procedure FreeMemory;
    function GetHashSize: Integer;
    function GetIndexSize: Integer;
    procedure SetGranularity(const ANewGranularity: Integer);
    /// <summary>Forces the index to grow (the current hash stays intact)</summary>
    procedure ResizeIndex(const ANewIndexSize: Integer);
    /// <summary>A number in [0, 100] for the spread of the entries over the table</summary>
    function GetSpread: Integer;
    /// <summary>The key of a string: idStr::Hash (or IHash, case insensitive) masked to the table</summary>
    function GenerateKey(const AText: AnsiString; const ACaseSensitive: Boolean = True): Integer; overload;
    /// <summary>The key of a vector: the sum of its truncated components</summary>
    function GenerateKey(const AX, AY, AZ: Single): Integer; overload;
    /// <summary>The key of two integers</summary>
    function GenerateKey(const AN1, AN2: Integer): Integer; overload;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings;

{ TIdHashIndex }

constructor TIdHashIndex.Create;
begin
  inherited Create;
  Init(ID_DEFAULT_HASH_SIZE, ID_DEFAULT_HASH_SIZE);
end;

constructor TIdHashIndex.Create(const AInitialHashSize, AInitialIndexSize: Integer);
begin
  inherited Create;
  Init(AInitialHashSize, AInitialIndexSize);
end;

function TIdHashIndex.IsAllocated: Boolean;
begin
  Result := Length(FHash) > 0;
end;

procedure TIdHashIndex.Init(const AInitialHashSize, AInitialIndexSize: Integer);
begin
  if (AInitialHashSize <= 0) or ((AInitialHashSize and (AInitialHashSize - 1)) <> 0) then
    raise EArgumentException.CreateFmt('TIdHashIndex: the hash size %d is not a power of two', [AInitialHashSize]);
  FHashSize := AInitialHashSize;
  FHash := nil;
  FIndexSize := AInitialIndexSize;
  FIndexChain := nil;
  FGranularity := ID_DEFAULT_HASH_GRANULARITY;
  FHashMask := FHashSize - 1;
  FLookupMask := 0;
end;

procedure TIdHashIndex.Allocate(const ANewHashSize, ANewIndexSize: Integer);
var
  LIndex: Integer;
begin
  if (ANewHashSize <= 0) or ((ANewHashSize and (ANewHashSize - 1)) <> 0) then
    raise EArgumentException.CreateFmt('TIdHashIndex: the hash size %d is not a power of two', [ANewHashSize]);
  FreeMemory;
  FHashSize := ANewHashSize;
  SetLength(FHash, FHashSize);
  for LIndex := 0 to FHashSize - 1 do
    FHash[LIndex] := -1;
  FIndexSize := ANewIndexSize;
  SetLength(FIndexChain, FIndexSize);
  for LIndex := 0 to FIndexSize - 1 do
    FIndexChain[LIndex] := -1;
  FHashMask := FHashSize - 1;
  FLookupMask := -1;
end;

function TIdHashIndex.Allocated: NativeInt;
begin
  Result := FHashSize * SizeOf(Integer) + FIndexSize * SizeOf(Integer);
end;

procedure TIdHashIndex.Assign(const AOther: TIdHashIndex);
begin
  FGranularity := AOther.FGranularity;
  FHashMask := AOther.FHashMask;
  FLookupMask := AOther.FLookupMask;
  if AOther.FLookupMask = 0 then
  begin
    FHashSize := AOther.FHashSize;
    FIndexSize := AOther.FIndexSize;
    FreeMemory;
  end
  else
  begin
    FHashSize := AOther.FHashSize;
    FIndexSize := AOther.FIndexSize;
    FHash := Copy(AOther.FHash, 0, FHashSize);
    FIndexChain := Copy(AOther.FIndexChain, 0, FIndexSize);
  end;
end;

procedure TIdHashIndex.Add(const AKey, AIndex: Integer);
var
  LHashIndex: Integer;
begin
  if not IsAllocated then
  begin
    if AIndex >= FIndexSize then
      Allocate(FHashSize, AIndex + 1)
    else
      Allocate(FHashSize, FIndexSize);
  end
  else if AIndex >= FIndexSize then
    ResizeIndex(AIndex + 1);
  LHashIndex := AKey and FHashMask;
  FIndexChain[AIndex] := FHash[LHashIndex];
  FHash[LHashIndex] := AIndex;
end;

procedure TIdHashIndex.Remove(const AKey, AIndex: Integer);
var
  LKey, LIndex: Integer;
begin
  LKey := AKey and FHashMask;
  if not IsAllocated then
    Exit;
  if FHash[LKey] = AIndex then
    FHash[LKey] := FIndexChain[AIndex]
  else
  begin
    LIndex := FHash[LKey];
    while LIndex <> -1 do
    begin
      if FIndexChain[LIndex] = AIndex then
      begin
        FIndexChain[LIndex] := FIndexChain[AIndex];
        Break;
      end;
      LIndex := FIndexChain[LIndex];
    end;
  end;
  FIndexChain[AIndex] := -1;
end;

function TIdHashIndex.First(const AKey: Integer): Integer;
begin
  if not IsAllocated then
    Exit(-1);
  Result := FHash[AKey and FHashMask];
end;

function TIdHashIndex.Next(const AIndex: Integer): Integer;
begin
  if not IsAllocated then
    Exit(-1);
  Result := FIndexChain[AIndex];
end;

procedure TIdHashIndex.InsertIndex(const AKey, AIndex: Integer);
var
  LIndex, LMax: Integer;
begin
  if IsAllocated then
  begin
    LMax := AIndex;
    for LIndex := 0 to FHashSize - 1 do
      if FHash[LIndex] >= AIndex then
      begin
        Inc(FHash[LIndex]);
        if FHash[LIndex] > LMax then
          LMax := FHash[LIndex];
      end;
    for LIndex := 0 to FIndexSize - 1 do
      if FIndexChain[LIndex] >= AIndex then
      begin
        Inc(FIndexChain[LIndex]);
        if FIndexChain[LIndex] > LMax then
          LMax := FIndexChain[LIndex];
      end;
    if LMax >= FIndexSize then
      ResizeIndex(LMax + 1);
    for LIndex := LMax downto AIndex + 1 do
      FIndexChain[LIndex] := FIndexChain[LIndex - 1];
    FIndexChain[AIndex] := -1;
  end;
  Add(AKey, AIndex);
end;

procedure TIdHashIndex.RemoveIndex(const AKey, AIndex: Integer);
var
  LIndex, LMax: Integer;
begin
  Remove(AKey, AIndex);
  if IsAllocated then
  begin
    LMax := AIndex;
    for LIndex := 0 to FHashSize - 1 do
      if FHash[LIndex] >= AIndex then
      begin
        if FHash[LIndex] > LMax then
          LMax := FHash[LIndex];
        Dec(FHash[LIndex]);
      end;
    for LIndex := 0 to FIndexSize - 1 do
      if FIndexChain[LIndex] >= AIndex then
      begin
        if FIndexChain[LIndex] > LMax then
          LMax := FIndexChain[LIndex];
        Dec(FIndexChain[LIndex]);
      end;
    for LIndex := AIndex to LMax - 1 do
      FIndexChain[LIndex] := FIndexChain[LIndex + 1];
    FIndexChain[LMax] := -1;
  end;
end;

procedure TIdHashIndex.Clear;
var
  LIndex: Integer;
begin
  // only the hash table is cleared: clearing the index chain is not needed
  if IsAllocated then
    for LIndex := 0 to FHashSize - 1 do
      FHash[LIndex] := -1;
end;

procedure TIdHashIndex.Clear(const ANewHashSize, ANewIndexSize: Integer);
begin
  FreeMemory;
  FHashSize := ANewHashSize;
  FIndexSize := ANewIndexSize;
end;

procedure TIdHashIndex.FreeMemory;
begin
  FHash := nil;
  FIndexChain := nil;
  FLookupMask := 0;
end;

function TIdHashIndex.GetHashSize: Integer;
begin
  Result := FHashSize;
end;

function TIdHashIndex.GetIndexSize: Integer;
begin
  Result := FIndexSize;
end;

procedure TIdHashIndex.SetGranularity(const ANewGranularity: Integer);
begin
  if ANewGranularity <= 0 then
    raise EArgumentException.Create('TIdHashIndex: the granularity must be greater than zero');
  FGranularity := ANewGranularity;
end;

procedure TIdHashIndex.ResizeIndex(const ANewIndexSize: Integer);
var
  LMod, LNewSize, LIndex: Integer;
begin
  if ANewIndexSize <= FIndexSize then
    Exit;
  LMod := ANewIndexSize mod FGranularity;
  if LMod = 0 then
    LNewSize := ANewIndexSize
  else
    LNewSize := ANewIndexSize + FGranularity - LMod;
  if not IsAllocated then
  begin
    FIndexSize := LNewSize;
    Exit;
  end;
  SetLength(FIndexChain, LNewSize);
  for LIndex := FIndexSize to LNewSize - 1 do
    FIndexChain[LIndex] := -1;
  FIndexSize := LNewSize;
end;

function TIdHashIndex.GetSpread: Integer;
var
  LIndex, LEntry, LTotal, LAverage, LError, LDifference: Integer;
  LCounts: TArray<Integer>;
begin
  if not IsAllocated then
    Exit(100);
  LTotal := 0;
  SetLength(LCounts, FHashSize);
  for LIndex := 0 to FHashSize - 1 do
  begin
    LCounts[LIndex] := 0;
    LEntry := FHash[LIndex];
    while LEntry >= 0 do
    begin
      Inc(LCounts[LIndex]);
      LEntry := FIndexChain[LEntry];
    end;
    Inc(LTotal, LCounts[LIndex]);
  end;
  // if no items in hash
  if LTotal <= 1 then
    Exit(100);
  LAverage := LTotal div FHashSize;
  LError := 0;
  for LIndex := 0 to FHashSize - 1 do
  begin
    LDifference := Abs(LCounts[LIndex] - LAverage);
    if LDifference > 1 then
      Inc(LError, LDifference - 1);
  end;
  Result := 100 - (LError * 100 div LTotal);
end;

function TIdHashIndex.GenerateKey(const AText: AnsiString; const ACaseSensitive: Boolean): Integer;
begin
  if ACaseSensitive then
    Result := TIdStrings.Hash(AText) and FHashMask
  else
    Result := TIdStrings.IHash(AText) and FHashMask;
end;

function TIdHashIndex.GenerateKey(const AX, AY, AZ: Single): Integer;
begin
  Result := (Trunc(AX) + Trunc(AY) + Trunc(AZ)) and FHashMask;
end;

function TIdHashIndex.GenerateKey(const AN1, AN2: Integer): Integer;
begin
  Result := (AN1 + AN2) and FHashMask;
end;

end.
