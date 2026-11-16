{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - the index of the PAK file system                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Pak.Index;

interface

// The global hash wraps around on purpose (the old TPakManager.AddEntryToHashTable)
{$Q-}
{$R-}

uses
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Wad.Pak.Intf;

type
  /// <summary>
  ///   IPakIndex as the old TPakManager kept its entries: an array in the order they were added,
  ///   a hash table of the short names whose chains start from the last added, and the global
  ///   hash of the images of the entries
  /// </summary>
  TPakIndex = class(TInterfacedObject, IPakIndex)
  strict private
    FEntries: TArray<TPakIndexEntry>;
    FNext: TArray<Integer>;
    FCount: Integer;
    FHeads: array[0..PAK_HASH_SIZE - 1] of Integer;
    FGlobalHash: Cardinal;
    procedure AddToGlobalHash(const AImage: TPakEntryImage);
    function FirstOfChain(AHash: Integer): Integer; inline;
  public
    constructor Create;
    procedure Add(const AName, AContainer: string; ASource, AEntry, ASize: Integer);
    function Count: Integer;
    function Entry(AIndex: Integer): TPakIndexEntry;
    function FindFull(const AName: string): Integer;
    function FindShort(const AName: string): Integer;
    function FindWithDirectory(const AName: string): Integer;
    function FindPreferred(const AName: string; const APreferred: TArray<string>): Integer;
    function FindPreferredSerial(const AName: string; const APreferred: TArray<string>): Integer;
    function Matching(const AName: string): TArray<Integer>;
    function GlobalHash: Cardinal;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Pak.Names;

const
  SNoSuchEntry = 'The PAK file system has no entry %d';

{ TPakIndex }

constructor TPakIndex.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := Low(FHeads) to High(FHeads) do
    FHeads[LIndex] := -1;
end;

procedure TPakIndex.AddToGlobalHash(const AImage: TPakEntryImage);
var
  LByte: PByte;
  LIndex: Integer;
begin
  LByte := @AImage;
  for LIndex := 0 to SizeOf(TPakEntryImage) - 1 do
  begin
    if LByte^ = 0 then
      Inc(FGlobalHash)
    else
      FGlobalHash := ((FGlobalHash shl 7) or (FGlobalHash shr 25)) + LByte^;
    Inc(LByte);
  end;
end;

function TPakIndex.FirstOfChain(AHash: Integer): Integer;
begin
  Result := FHeads[TPakNames.HashTableIndex(AHash)];
end;

procedure TPakIndex.Add(const AName, AContainer: string; ASource, AEntry, ASize: Integer);
var
  LImage: TPakEntryImage;
  LEntry: TPakIndexEntry;
  LChain: Integer;
begin
  // the strings go through the old ShortString image: same truncation and same bytes of the hash
  FillChar(LImage, SizeOf(LImage), 0);
  LImage.Pak := ShortString(AContainer);
  LImage.Name := ShortString(TPakNames.FixPath(TPakNames.UpperCase(AName)));
  LImage.ShortName := ShortString(TPakNames.ShortName(string(LImage.Name)));
  LImage.Offset := AEntry;
  LImage.Size := ASize;

  LEntry.Container := string(LImage.Pak);
  LEntry.Name := string(LImage.Name);
  LEntry.ShortName := string(LImage.ShortName);
  LEntry.Source := ASource;
  LEntry.Entry := AEntry;
  LEntry.Size := ASize;
  LEntry.Hash := TPakNames.Hash(LEntry.ShortName);

  if FCount = Length(FEntries) then
  begin
    SetLength(FEntries, FCount + 512);
    SetLength(FNext, FCount + 512);
  end;
  FEntries[FCount] := LEntry;
  LChain := TPakNames.HashTableIndex(LEntry.Hash);
  FNext[FCount] := FHeads[LChain];
  FHeads[LChain] := FCount;
  Inc(FCount);

  AddToGlobalHash(LImage);
end;

function TPakIndex.Count: Integer;
begin
  Result := FCount;
end;

function TPakIndex.Entry(AIndex: Integer): TPakIndexEntry;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EWadException.CreateFmt(SNoSuchEntry, [AIndex]);
  Result := FEntries[AIndex];
end;

function TPakIndex.FindFull(const AName: string): Integer;
var
  LName: string;
  LHash: Integer;
begin
  LName := TPakNames.UpperCase(AName);
  LHash := TPakNames.Hash(TPakNames.ShortName(LName));
  Result := FirstOfChain(LHash);
  while Result >= 0 do
  begin
    if (FEntries[Result].Hash = LHash) and (FEntries[Result].Name = LName) then
      Exit;
    Result := FNext[Result];
  end;
end;

function TPakIndex.FindShort(const AName: string): Integer;
var
  LName: string;
  LHash: Integer;
begin
  LName := TPakNames.UpperCase(TPakNames.ShortName(AName));
  LHash := TPakNames.Hash(LName);
  Result := FirstOfChain(LHash);
  while Result >= 0 do
  begin
    if (FEntries[Result].Hash = LHash) and (FEntries[Result].ShortName = LName) then
      Exit;
    Result := FNext[Result];
  end;
end;

function TPakIndex.FindWithDirectory(const AName: string): Integer;
var
  LName: string;
  LTail: string;
  LHash: Integer;
begin
  LName := TPakNames.UpperCase(TPakNames.ShortName(AName));
  LTail := '\' + LName;
  LHash := TPakNames.Hash(LName);
  Result := FirstOfChain(LHash);
  while Result >= 0 do
  begin
    if (FEntries[Result].Hash = LHash) and
      ((FEntries[Result].Name = LName) or (RightStr(FEntries[Result].Name, Length(LTail)) = LTail)) then
      Exit;
    Result := FNext[Result];
  end;
end;

function TPakIndex.FindPreferred(const AName: string; const APreferred: TArray<string>): Integer;
var
  LName: string;
  LHash: Integer;
  LIndex: Integer;
  LPreferred: Integer;
  LPriority: Integer;
  LBestPriority: Integer;
begin
  LName := TPakNames.UpperCase(TPakNames.ShortName(AName));
  LHash := TPakNames.Hash(LName);
  Result := -1;
  LBestPriority := MaxInt;
  LIndex := FirstOfChain(LHash);
  while LIndex >= 0 do
  begin
    if (FEntries[LIndex].Hash = LHash) and (FEntries[LIndex].ShortName = LName) then
    begin
      LPriority := MaxInt - 1;
      for LPreferred := 0 to High(APreferred) do
        if APreferred[LPreferred] + LName = FEntries[LIndex].Name then
        begin
          LPriority := LPreferred;
          Break;
        end
        else if Pos(APreferred[LPreferred], FEntries[LIndex].Name) > 0 then
        begin
          LPriority := Length(APreferred) + LPreferred;
          Break;
        end;
      if LPriority < LBestPriority then
      begin
        Result := LIndex;
        LBestPriority := LPriority;
      end;
    end;
    LIndex := FNext[LIndex];
  end;
end;

function TPakIndex.FindPreferredSerial(const AName: string; const APreferred: TArray<string>): Integer;
var
  LName: string;
  LHash: Integer;
  LIndex: Integer;
  LPreferred: Integer;
  LPriority: Integer;
  LBestPriority: Integer;
begin
  LName := TPakNames.UpperCase(TPakNames.ShortName(AName));
  LHash := TPakNames.Hash(LName);
  Result := -1;
  LBestPriority := MaxInt;
  for LIndex := FCount - 1 downto 0 do
    if (FEntries[LIndex].Hash = LHash) and (FEntries[LIndex].ShortName = LName) then
    begin
      LPriority := Length(APreferred);
      for LPreferred := 0 to High(APreferred) do
        if Pos(APreferred[LPreferred], FEntries[LIndex].Name) > 0 then
        begin
          LPriority := LPreferred;
          Break;
        end;
      if LPriority < LBestPriority then
      begin
        Result := LIndex;
        LBestPriority := LPriority;
      end;
    end;
end;

function TPakIndex.Matching(const AName: string): TArray<Integer>;
var
  LName: string;
  LHash: Integer;
  LIndex: Integer;
  LCount: Integer;
begin
  LName := TPakNames.UpperCase(TPakNames.ShortName(AName));
  LHash := TPakNames.Hash(LName);
  Result := nil;
  LCount := 0;
  for LIndex := 0 to FCount - 1 do
    if (FEntries[LIndex].Hash = LHash) and (FEntries[LIndex].ShortName = LName) then
    begin
      if LCount = Length(Result) then
        SetLength(Result, LCount * 2 + 4);
      Result[LCount] := LIndex;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

function TPakIndex.GlobalHash: Cardinal;
begin
  Result := FGlobalHash;
end;

end.
