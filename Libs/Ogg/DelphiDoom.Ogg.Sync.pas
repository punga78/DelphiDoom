{******************************************************************************}
{                                                                              }
{  DelphiDoom: Ogg - finds the pages in a physical stream                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libogg by the Xiph.Org Foundation (BSD licence)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ogg.Sync;

interface

uses
  DelphiDoom.Ogg.Types;

type
  /// <summary>
  ///   Gives the application a buffer to fill with what it reads (Buffer, then Wrote),
  ///   and returns the pages found in it (PageOut). Each page is then submitted to the
  ///   TOggStream of its serial number. The pages point inside the buffer: they are good
  ///   until the next call of Buffer, Reset, Clear or PageSeek
  /// </summary>
  TOggSync = class
  public
    class function Init(const AState: POggSyncState): Integer; static;
    /// <returns>0 for a state that can work, -1 for a state that was cleared after an error</returns>
    class function Check(const AState: POggSyncState): Integer; static;
    /// <summary>Gives back what the state holds; the state itself is not freed</summary>
    class function Clear(const AState: POggSyncState): Integer; static;
    /// <summary>Clears the state and frees it as well</summary>
    class function ClearAndFree(const AState: POggSyncState): Integer; static;
    /// <summary>Back to the beginning, for example before a seek</summary>
    class function Reset(const AState: POggSyncState): Integer; static;

    /// <summary>A place for at least ASize more bytes, at the end of the data; nil on an error</summary>
    class function Buffer(const AState: POggSyncState; const ASize: Longint): PByte; static;
    /// <summary>Says how many bytes were put in the place that Buffer gave</summary>
    class function Wrote(const AState: POggSyncState; const ABytes: Longint): Integer; static;

    /// <summary>
    ///   Looks for a page at the head of the data
    /// </summary>
    /// <returns>
    ///   The size of the page when it was found; 0 when it needs more data (nothing was skipped);
    ///   a negative number, minus the bytes that were skipped, when there was no page there
    /// </returns>
    class function PageSeek(const AState: POggSyncState; const APage: POggPage): Longint; static;

    /// <summary>Looks for pages until it finds one</summary>
    /// <returns>1 when a page is returned, 0 when it needs more data, -1 for the first hole in the data</returns>
    class function PageOut(const AState: POggSyncState; const APage: POggPage): Integer; static;
  end;

implementation

uses
  DelphiDoom.Ogg.Memory,
  DelphiDoom.Ogg.PageReader;

const
  HEADER_SIZE = 27;
  HEADER_SEGMENTS = 26;
  HEADER_CHECKSUM = 22;
  EXTRA_STORAGE = 4096;

{ TOggSync }

class function TOggSync.Init(const AState: POggSyncState): Integer;
begin
  if Assigned(AState) then
    FillChar(AState^, SizeOf(AState^), 0);
  Result := 0;
end;

class function TOggSync.Check(const AState: POggSyncState): Integer;
begin
  if AState.Storage < 0 then
    Exit(-1);
  Result := 0;
end;

class function TOggSync.Clear(const AState: POggSyncState): Integer;
begin
  if Assigned(AState) then
  begin
    TOggMemory.Release(AState.Data);
    FillChar(AState^, SizeOf(AState^), 0);
  end;
  Result := 0;
end;

class function TOggSync.ClearAndFree(const AState: POggSyncState): Integer;
begin
  if Assigned(AState) then
  begin
    Clear(AState);
    TOggMemory.Release(AState);
  end;
  Result := 0;
end;

class function TOggSync.Reset(const AState: POggSyncState): Integer;
begin
  if Check(AState) <> 0 then
    Exit(-1);

  AState.Fill := 0;
  AState.Returned := 0;
  AState.Unsynced := 0;
  AState.HeaderBytes := 0;
  AState.BodyBytes := 0;
  Result := 0;
end;

class function TOggSync.Buffer(const AState: POggSyncState; const ASize: Longint): PByte;
var
  LNewSize: Longint;
  LNew: Pointer;
begin
  if Check(AState) <> 0 then
    Exit(nil);

  // First, the space that has been returned is given up
  if AState.Returned <> 0 then
  begin
    Dec(AState.Fill, AState.Returned);
    if AState.Fill > 0 then
      Move((AState.Data + AState.Returned)^, AState.Data^, AState.Fill);
    AState.Returned := 0;
  end;

  if ASize > AState.Storage - AState.Fill then
  begin
    // The buffer has to grow, with an extra page to be nice
    LNewSize := ASize + AState.Fill + EXTRA_STORAGE;
    if Assigned(AState.Data) then
      LNew := TOggMemory.Reallocate(AState.Data, LNewSize)
    else
      LNew := TOggMemory.Allocate(LNewSize);
    if not Assigned(LNew) then
    begin
      Clear(AState);
      Exit(nil);
    end;
    AState.Data := LNew;
    AState.Storage := LNewSize;
  end;

  Result := AState.Data + AState.Fill;
end;

class function TOggSync.Wrote(const AState: POggSyncState; const ABytes: Longint): Integer;
begin
  if Check(AState) <> 0 then
    Exit(-1);
  if AState.Fill + ABytes > AState.Storage then
    Exit(-1);
  Inc(AState.Fill, ABytes);
  Result := 0;
end;

class function TOggSync.PageSeek(const AState: POggSyncState; const APage: POggPage): Longint;
var
  LPage, LNext, LScan: PByte;
  LBytes: Longint;
  LHeaderBytes, LIndex: Integer;
  LChecksum: array[0..3] of Byte;
  LCandidate: TOggPage;
  LSkipped: Boolean;
begin
  LPage := AState.Data + AState.Returned;
  LBytes := AState.Fill - AState.Returned;

  if Check(AState) <> 0 then
    Exit(0);

  LSkipped := False;

  if AState.HeaderBytes = 0 then
  begin
    // Not enough for a header
    if LBytes < HEADER_SIZE then
      Exit(0);

    // The capture pattern
    if (LPage[0] <> Ord('O')) or (LPage[1] <> Ord('g')) or (LPage[2] <> Ord('g')) or (LPage[3] <> Ord('S')) then
      LSkipped := True
    else
    begin
      LHeaderBytes := LPage[HEADER_SEGMENTS] + HEADER_SIZE;
      // Not enough for the header and the segment table
      if LBytes < LHeaderBytes then
        Exit(0);

      // The length of the body is the sum of the segment table
      for LIndex := 0 to LPage[HEADER_SEGMENTS] - 1 do
        Inc(AState.BodyBytes, LPage[HEADER_SIZE + LIndex]);
      AState.HeaderBytes := LHeaderBytes;
    end;
  end;

  if not LSkipped then
  begin
    if AState.BodyBytes + AState.HeaderBytes > LBytes then
      Exit(0);

    // The whole page is there: the checksum has to be right
    Move((LPage + HEADER_CHECKSUM)^, LChecksum[0], 4);
    FillChar((LPage + HEADER_CHECKSUM)^, 4, 0);

    LCandidate.Header := LPage;
    LCandidate.HeaderLength := AState.HeaderBytes;
    LCandidate.Body := LPage + AState.HeaderBytes;
    LCandidate.BodyLength := AState.BodyBytes;
    TOggPageReader.SetChecksum(@LCandidate);

    if (LChecksum[0] <> LPage[HEADER_CHECKSUM]) or (LChecksum[1] <> LPage[HEADER_CHECKSUM + 1]) or
      (LChecksum[2] <> LPage[HEADER_CHECKSUM + 2]) or (LChecksum[3] <> LPage[HEADER_CHECKSUM + 3]) then
    begin
      // Corrupt, or not a page at all: the checksum that was read is put back, and sync is lost
      Move(LChecksum[0], (LPage + HEADER_CHECKSUM)^, 4);
      LSkipped := True;
    end;
  end;

  if not LSkipped then
  begin
    // A whole page, ready to go
    if Assigned(APage) then
    begin
      APage.Header := LPage;
      APage.HeaderLength := AState.HeaderBytes;
      APage.Body := LPage + AState.HeaderBytes;
      APage.BodyLength := AState.BodyBytes;
    end;

    AState.Unsynced := 0;
    LBytes := AState.HeaderBytes + AState.BodyBytes;
    Inc(AState.Returned, LBytes);
    AState.HeaderBytes := 0;
    AState.BodyBytes := 0;
    Exit(LBytes);
  end;

  // Sync was lost: the next possible capture is looked for
  AState.HeaderBytes := 0;
  AState.BodyBytes := 0;

  LNext := nil;
  LScan := LPage + 1;
  for LIndex := 1 to LBytes - 1 do
  begin
    if LScan^ = Ord('O') then
    begin
      LNext := LScan;
      Break;
    end;
    Inc(LScan);
  end;
  if not Assigned(LNext) then
    LNext := AState.Data + AState.Fill;

  AState.Returned := Integer(LNext - AState.Data);
  Result := -Longint(LNext - LPage);
end;

class function TOggSync.PageOut(const AState: POggSyncState; const APage: POggPage): Integer;
var
  LResult: Longint;
begin
  if Check(AState) <> 0 then
    Exit(0);

  // Only the head of the data has to be right: if it is not, the next possible page is looked for
  while True do
  begin
    LResult := PageSeek(AState, APage);
    if LResult > 0 then
      Exit(1);
    if LResult = 0 then
      Exit(0);

    // Some bytes were skipped; the first time is told
    if AState.Unsynced = 0 then
    begin
      AState.Unsynced := 1;
      Exit(-1);
    end;
  end;
end;

end.
