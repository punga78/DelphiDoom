{******************************************************************************}
{                                                                              }
{  DelphiDoom: PAK - a stream on a file of the PAK file system                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit DelphiDoom.Pak.Stream;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Pak.EntryReader;

type
  /// <summary>
  ///   A read only stream on a file of the PAK file system: a file on disk, or the bytes of an
  ///   entry read when it is opened. IOResult is not 0 when nothing was found. The old TPakStream
  ///   of w_pak, that now asks the file system it is given instead of the global manager
  /// </summary>
  TPakFileStream = class(TDStream)
  strict private
    FDiskFile: file;
    FReader: TPakEntryReader;
  public
    constructor Create(const AFileSystem: IPakFileSystem; const AFileName: string;
      AMode: TPakLookupMode; const APreferred: TArray<string>; const ADirectory: string); overload;
    constructor CreateEntry(const AFileSystem: IPakFileSystem; AIndex: Integer);
    destructor Destroy; override;
    function Read(var Buffer; Count: Integer): Integer; override;
    function Write(const Buffer; Count: Integer): Integer; override;
    function Seek(Offset: Integer; Origin: Word): Integer; override;
    function Size: Integer; override;
    function Position: Integer; override;
  end;

implementation

uses
  i_system;

{ TPakFileStream }

constructor TPakFileStream.Create(const AFileSystem: IPakFileSystem; const AFileName: string;
  AMode: TPakLookupMode; const APreferred: TArray<string>; const ADirectory: string);
var
  LFound: Boolean;
begin
  inherited Create;
  OnBeginBusy := nil;
  OnEndBusy := nil;
  LFound := AFileSystem.Locate(AFileName, AMode, APreferred, ADirectory,
    function(const APath: string): Boolean
    begin
      Result := fopen(FDiskFile, APath, fOpenReadOnly);
    end,
    function(AIndex: Integer): Boolean
    begin
      FReader := AFileSystem.ReadEntry(AIndex);
      Result := Assigned(FReader);
    end);
  if LFound then
    FIOResult := 0
  else
    FIOResult := 1;
end;

constructor TPakFileStream.CreateEntry(const AFileSystem: IPakFileSystem; AIndex: Integer);
begin
  inherited Create;
  OnBeginBusy := nil;
  OnEndBusy := nil;
  if (AIndex >= 0) and (AIndex < AFileSystem.EntryCount) then
    FReader := AFileSystem.ReadEntry(AIndex);
  if Assigned(FReader) then
    FIOResult := 0
  else
    FIOResult := 1;
end;

destructor TPakFileStream.Destroy;
begin
  // as the old code, a stream that found nothing also closes its (never opened) file
  if Assigned(FReader) then
    FReader.Free
  else
  begin
    {$I-}
    Close(FDiskFile);
    {$I+}
    // clears the error of a file that was never opened (IOResult alone is the one of TDStream)
    System.IOResult;
  end;
  inherited;
end;

function TPakFileStream.Read(var Buffer; Count: Integer): Integer;
begin
  if Assigned(FReader) then
    Result := FReader.Read(Buffer, Count)
  else
  begin
    {$I-}
    BlockRead(FDiskFile, Buffer, Count, Result);
    {$I+}
  end;
  if System.IOResult <> 0 then
    Inc(FIOResult);
end;

function TPakFileStream.Write(const Buffer; Count: Integer): Integer;
begin
  I_Warning('TPakStream::Write(): Pak managment is read-only'#13#10);
  Inc(FIOResult);
  Result := 0;
end;

function TPakFileStream.Seek(Offset: Integer; Origin: Word): Integer;
var
  LPosition: Integer;
  LDone: Boolean;
begin
  if Origin = sFromBeginning then
    LPosition := Offset
  else if Origin = sFromCurrent then
    LPosition := Position + Offset
  else
    // sFromEnd: the old code subtracted the offset from the size
    LPosition := Size - Offset;

  if Assigned(FReader) then
    LDone := FReader.Seek(LPosition)
  else
  begin
    {$I-}
    System.Seek(FDiskFile, LPosition);
    {$I+}
    LDone := System.IOResult = 0;
  end;
  if not LDone then
    Inc(FIOResult);
  Result := LPosition;
end;

function TPakFileStream.Size: Integer;
begin
  if Assigned(FReader) then
    Result := FReader.Size
  else
  begin
    {$I-}
    Result := FileSize(FDiskFile);
    {$I+}
    if System.IOResult <> 0 then
      Result := 0;
  end;
end;

function TPakFileStream.Position: Integer;
begin
  if Assigned(FReader) then
    Result := FReader.Position
  else
    Result := FilePos(FDiskFile);
end;

end.
