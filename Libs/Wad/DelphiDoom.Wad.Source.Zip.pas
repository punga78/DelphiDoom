{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: ZIP (PK3)                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.Zip;

interface

uses
  System.SysUtils, System.Classes, System.Zip, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf,
  DelphiDoom.Wad.Zip.Intf;

type
  /// <summary>
  ///   A ZIP (PK3): every file in it is a lump named by its path, upper case
  ///   with '/' as separator; folders are not lumps. It is also an IZipArchive (every entry as stored,
  ///   with CRC and size), which is what the file system of id Tech 4 reads for a PK4.
  /// </summary>
  TZipFileSource = class(TInterfacedObject, IWadSource, IZipArchive)
  private
    FName: string;
    FZip: TZipFile;
    FStream: TStream;
    FOwnsStream: Boolean;
    FEntries: TArray<TWadEntry>;
    FZipIndex: TArray<Integer>;
    procedure BuildEntries;
  public
    /// <summary>Raises EWadException when AFileName is not a ZIP</summary>
    constructor Create(const AFileName: string); overload;
    /// <summary>
    ///   Reads the ZIP from a stream (a file of a disk that is not the real one, bytes in memory); the
    ///   stream must stay alive as long as the source, and is freed with it when AOwnsStream is True.
    ///   Raises EWadException when it is not a ZIP (the stream is freed too if it is owned)
    /// </summary>
    constructor Create(AStream: TStream; AOwnsStream: Boolean; const AName: string); overload;
    destructor Destroy; override;
    function ArchiveName: string;
    function ArchiveEntryCount: Integer;
    function ArchiveEntryName(AIndex: Integer): string;
    function ArchiveEntryCrc(AIndex: Integer): Cardinal;
    function ArchiveEntrySize(AIndex: Integer): Int64;
    function ReadArchiveEntry(AIndex: Integer): TBytes;
    function GetName: string;
    function GetKind: TWadSourceKind;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TWadEntry;
    function ReadEntry(AIndex: Integer): TBytes;
    procedure ReadEntryInto(AIndex: Integer; ADestination: Pointer);
  end;

implementation

uses
  DelphiDoom.Wad.Name;

const
  SNotAZip = '%s is not a ZIP file';
  SBadZipIndex = 'Lump %d does not exist in %s (it has %d)';

{ TZipFileSource }

constructor TZipFileSource.Create(const AFileName: string);
begin
  inherited Create;
  FName := AFileName;
  FZip := TZipFile.Create;
  try
    FZip.Open(AFileName, TZipMode.zmRead);
  except
    FreeAndNil(FZip);
    raise EWadException.CreateFmt(SNotAZip, [AFileName]);
  end;
  BuildEntries;
end;

constructor TZipFileSource.Create(AStream: TStream; AOwnsStream: Boolean; const AName: string);
begin
  inherited Create;
  FName := AName;
  FStream := AStream;
  FOwnsStream := AOwnsStream;
  FZip := TZipFile.Create;
  try
    FZip.Open(AStream, TZipMode.zmRead);
  except
    // the destructor, run by the failed constructor, frees the owned stream
    FreeAndNil(FZip);
    raise EWadException.CreateFmt(SNotAZip, [AName]);
  end;
  BuildEntries;
end;

procedure TZipFileSource.BuildEntries;
var
  LIndex, LCount: Integer;
  LName: string;
begin
  SetLength(FEntries, FZip.FileCount);
  SetLength(FZipIndex, FZip.FileCount);
  LCount := 0;
  for LIndex := 0 to FZip.FileCount - 1 do
  begin
    LName := StringReplace(FZip.FileNames[LIndex], '\', '/', [rfReplaceAll]);
    if (LName = '') or (LName[Length(LName)] = '/') then
      Continue;
    FEntries[LCount].Name := TWadLumpName.UpperCase(LName);
    FEntries[LCount].Offset := 0;
    FEntries[LCount].Size := Integer(FZip.FileInfos[LIndex].UncompressedSize);
    FZipIndex[LCount] := LIndex;
    Inc(LCount);
  end;
  SetLength(FEntries, LCount);
  SetLength(FZipIndex, LCount);
end;

destructor TZipFileSource.Destroy;
begin
  FZip.Free;
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;

function TZipFileSource.ArchiveName: string;
begin
  Result := FName;
end;

function TZipFileSource.ArchiveEntryCount: Integer;
begin
  Result := FZip.FileCount;
end;

function TZipFileSource.ArchiveEntryName(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= FZip.FileCount) then
    raise EWadException.CreateFmt(SBadZipIndex, [AIndex, FName, FZip.FileCount]);
  Result := FZip.FileNames[AIndex];
end;

function TZipFileSource.ArchiveEntryCrc(AIndex: Integer): Cardinal;
begin
  ArchiveEntryName(AIndex);
  Result := FZip.FileInfos[AIndex].CRC32;
end;

function TZipFileSource.ArchiveEntrySize(AIndex: Integer): Int64;
begin
  ArchiveEntryName(AIndex);
  Result := FZip.FileInfos[AIndex].UncompressedSize;
end;

function TZipFileSource.ReadArchiveEntry(AIndex: Integer): TBytes;
begin
  ArchiveEntryName(AIndex);
  FZip.Read(AIndex, Result);
end;

function TZipFileSource.GetName: string;
begin
  Result := FName;
end;

function TZipFileSource.GetKind: TWadSourceKind;
begin
  Result := TWadSourceKind.Zip;
end;

function TZipFileSource.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TZipFileSource.GetEntry(AIndex: Integer): TWadEntry;
begin
  if (AIndex < 0) or (AIndex >= Length(FEntries)) then
    raise EWadException.CreateFmt(SBadZipIndex, [AIndex, FName, Length(FEntries)]);
  Result := FEntries[AIndex];
end;

function TZipFileSource.ReadEntry(AIndex: Integer): TBytes;
begin
  GetEntry(AIndex);
  FZip.Read(FZipIndex[AIndex], Result);
end;

procedure TZipFileSource.ReadEntryInto(AIndex: Integer; ADestination: Pointer);
var
  LBytes: TBytes;
begin
  LBytes := ReadEntry(AIndex);
  if Length(LBytes) > 0 then
    Move(LBytes[0], ADestination^, Length(LBytes));
end;

end.
