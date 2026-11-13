{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the archive DATA.WAR                              }
{                                                                              }
{  Port of war1 (acoto87/war1), wfile_loadWarFile and wfile_freeWarFile of     }
{  war_file.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see            }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Archive;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Intf;

type
  /// <summary>
  ///   The file: a header of 8 bytes (archive id, number of entries), the table of the offsets (4 bytes per
  ///   entry) and the records; each record has a 4 byte header, with the length once expanded in the low 29 bits
  ///   and in the high 3 a non zero value if the data are compressed. The length a record takes in the file is
  ///   the distance to the offset of the next one that is not a placeholder (wfile_loadWarFile).
  ///   The directory is made when the archive is opened, with the same checks as the original (that logged an
  ///   error and made the record a placeholder: here the Status of its line says it); a record is expanded
  ///   when it is read, not all at once as the original did. The unsigned arithmetic of the offsets wraps on
  ///   purpose ({$Q-}), as in the original
  /// </summary>
  TWarArchive = class(TInterfacedObject, IWarArchive)
  strict private
    FSource: IWarSource;
    FHeader: TWarArchiveHeader;
    FFileType: TWarFileType;
    FInfos: TArray<TWarRecordInfo>;
    procedure CheckIndex(AIndex: Integer);
    procedure BuildDirectory(const AOffsets: TArray<Cardinal>; const ACatalog: IWarCatalog);
    function NextOffset(const AOffsets: TArray<Cardinal>; AIndex: Integer; AFileLength: Int64): Cardinal;
  public
    /// <param name="ASource">The bytes of the file</param>
    /// <param name="ACatalog">
    ///   What each record is: those it lists with an unknown type are skipped, as wg_loadDataFile does; nil
    ///   to skip none
    /// </param>
    constructor Create(const ASource: IWarSource; const ACatalog: IWarCatalog);
    function GetFileType: TWarFileType;
    function GetArchiveId: Cardinal;
    function GetEntryCount: Integer;
    function GetRecordInfo(AIndex: Integer): TWarRecordInfo;
    function IsAvailable(AIndex: Integer): Boolean;
    function ReadRecord(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.War.LittleEndian, DelphiDoom.War.Decompressor;

{ TWarArchive }

constructor TWarArchive.Create(const ASource: IWarSource; const ACatalog: IWarCatalog);
var
  LHeaderBytes: TBytes;
  LTableBytes: TBytes;
  LOffsets: TArray<Cardinal>;
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create(SWarStreamIsNil);
  FSource := ASource;
  if FSource.Size < WAR_ARCHIVE_HEADER_SIZE then
    raise EWarException.CreateFmt(SWarFileTooShort, [FSource.Size]);
  SetLength(LHeaderBytes, WAR_ARCHIVE_HEADER_SIZE);
  FSource.ReadAt(0, LHeaderBytes[0], WAR_ARCHIVE_HEADER_SIZE);
  FHeader.ArchiveId := TWarLittleEndian.ReadCardinal(LHeaderBytes, 0);
  FHeader.EntryCount := TWarLittleEndian.ReadCardinal(LHeaderBytes, 4);
  case FHeader.ArchiveId of
    WAR_ARCHIVE_ID_RETAIL_DOS, WAR_ARCHIVE_ID_RETAIL_ALT:
      FFileType := wftRetail;
    WAR_ARCHIVE_ID_DEMO:
      FFileType := wftDemo;
  else
    FFileType := wftUnknown;
  end;
  if FFileType = wftUnknown then
    raise EWarException.CreateFmt(SWarBadArchiveId, [FHeader.ArchiveId]);
  if FHeader.EntryCount > WAR_MAX_RESOURCES_COUNT then
    raise EWarException.CreateFmt(SWarTooManyEntries, [FHeader.EntryCount, WAR_MAX_RESOURCES_COUNT]);
  if Int64(WAR_ARCHIVE_HEADER_SIZE) + Int64(FHeader.EntryCount) * SizeOf(Cardinal) > FSource.Size then
    raise EWarException.CreateFmt(SWarTableOutOfFile, [FHeader.EntryCount]);
  SetLength(LOffsets, FHeader.EntryCount);
  if FHeader.EntryCount > 0 then
  begin
    SetLength(LTableBytes, Integer(FHeader.EntryCount) * SizeOf(Cardinal));
    FSource.ReadAt(WAR_ARCHIVE_HEADER_SIZE, LTableBytes[0], Length(LTableBytes));
    for LIndex := 0 to Integer(FHeader.EntryCount) - 1 do
      LOffsets[LIndex] := TWarLittleEndian.ReadCardinal(LTableBytes, LIndex * SizeOf(Cardinal));
  end;
  BuildDirectory(LOffsets, ACatalog);
end;

function TWarArchive.NextOffset(const AOffsets: TArray<Cardinal>; AIndex: Integer; AFileLength: Int64): Cardinal;
var
  LNext: Integer;
begin
  // the offset of the next record that is not a placeholder; the end of the file if there is none
  LNext := AIndex + 1;
  Result := AOffsets[LNext];
  while (Result = WAR_OFFSET_NONE) or (Result = 0) do
  begin
    if LNext + 1 >= Length(AOffsets) then
    begin
      Result := Cardinal(AFileLength);
      Break;
    end;
    Inc(LNext);
    Result := AOffsets[LNext];
  end;
end;

procedure TWarArchive.BuildDirectory(const AOffsets: TArray<Cardinal>; const ACatalog: IWarCatalog);
var
  LCount: Integer;
  LIndex: Integer;
  LFileLength: Int64;
  LInfo: TWarRecordInfo;
  LCompressedLength: Cardinal;
  LHeaderBytes: TBytes;
  LSizeField: Cardinal;
  LLength: Cardinal;
begin
  LCount := Length(AOffsets);
  LFileLength := FSource.Size;
  SetLength(FInfos, LCount);
  SetLength(LHeaderBytes, SizeOf(Cardinal));
  for LIndex := 0 to LCount - 1 do
  begin
    LInfo := Default(TWarRecordInfo);
    LInfo.Index := LIndex;
    LInfo.Offset := AOffsets[LIndex];
    // placeholders in demo versions
    if (LInfo.Offset = WAR_OFFSET_NONE) or (LInfo.Offset = 0) then
      LInfo.Status := wrsPlaceholder
    else if Assigned(ACatalog) and ACatalog.IsSkipped(LIndex) then
      LInfo.Status := wrsSkipped
    else
    begin
      if LIndex = LCount - 1 then
      begin
        if Int64(LInfo.Offset) >= LFileLength then
          LCompressedLength := 0
        else
          LCompressedLength := Cardinal(LFileLength) - LInfo.Offset;
      end
      else
        LCompressedLength := NextOffset(AOffsets, LIndex, LFileLength) - LInfo.Offset;
      if (LIndex = LCount - 1) and (Int64(LInfo.Offset) >= LFileLength) then
        LInfo.Status := wrsOutOfBounds
      else if (LCompressedLength < 4) or (Int64(LInfo.Offset) + Int64(LCompressedLength) > LFileLength) then
      begin
        LInfo.CompressedLength := LCompressedLength;
        LInfo.Status := wrsOutOfBounds;
      end
      else
      begin
        LInfo.CompressedLength := LCompressedLength;
        FSource.ReadAt(LInfo.Offset, LHeaderBytes[0], SizeOf(Cardinal));
        LSizeField := TWarLittleEndian.ReadCardinal(LHeaderBytes, 0);
        LLength := LSizeField and WAR_LENGTH_MASK;
        LInfo.Length := LLength;
        LInfo.Compressed := (LSizeField and WAR_COMPRESSED_MASK) <> 0;
        if (not LInfo.Compressed) and (LLength > LCompressedLength - 4) then
          LInfo.Status := wrsBadLength
        else
          LInfo.Status := wrsAvailable;
      end;
    end;
    FInfos[LIndex] := LInfo;
  end;
end;

procedure TWarArchive.CheckIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Length(FInfos)) then
    raise EWarException.CreateFmt(SWarIndexOutOfRange, [AIndex, Length(FInfos)]);
end;

function TWarArchive.GetFileType: TWarFileType;
begin
  Result := FFileType;
end;

function TWarArchive.GetArchiveId: Cardinal;
begin
  Result := FHeader.ArchiveId;
end;

function TWarArchive.GetEntryCount: Integer;
begin
  Result := Length(FInfos);
end;

function TWarArchive.GetRecordInfo(AIndex: Integer): TWarRecordInfo;
begin
  CheckIndex(AIndex);
  Result := FInfos[AIndex];
end;

function TWarArchive.IsAvailable(AIndex: Integer): Boolean;
begin
  CheckIndex(AIndex);
  Result := FInfos[AIndex].Status = wrsAvailable;
end;

function TWarArchive.ReadRecord(AIndex: Integer): TBytes;
var
  LInfo: TWarRecordInfo;
  LPayload: TBytes;
begin
  CheckIndex(AIndex);
  LInfo := FInfos[AIndex];
  if LInfo.Status <> wrsAvailable then
    raise EWarException.CreateFmt(SWarRecordNotAvailable, [AIndex, WarRecordStatusName(LInfo.Status)]);
  if LInfo.Compressed then
  begin
    SetLength(LPayload, LInfo.CompressedLength - 4);
    if Length(LPayload) > 0 then
      FSource.ReadAt(Int64(LInfo.Offset) + 4, LPayload[0], Length(LPayload));
    Result := TWarDecompressor.Expand(LPayload, LInfo.Length, AIndex);
  end
  else
  begin
    SetLength(Result, LInfo.Length);
    if LInfo.Length > 0 then
      FSource.ReadAt(Int64(LInfo.Offset) + 4, Result[0], Integer(LInfo.Length));
  end;
end;

end.
