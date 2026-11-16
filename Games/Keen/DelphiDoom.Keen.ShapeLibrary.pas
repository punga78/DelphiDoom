{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a SoftLib library of files (KDREAMS.CMP)          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  LoadLIBFile of soft.c and the records of sl_file.h                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ShapeLibrary;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

const
  KEEN_SOFTLIB_VERSION = 2;
  KEEN_SOFTLIB_NAME_SIZE = 16;
  // ct_TYPES of jam_io.h
  KEEN_CT_NONE = 0;
  KEEN_CT_LZW = 1;
  KEEN_CT_LZH = 2;

type
  /// <summary>SoftLibHdr of sl_file.h, after the four letters "SLIB"</summary>
  TKeenSoftLibHeader = packed record
    Version: Word;
    FileCount: Word;
  end;

  /// <summary>FileEntryHdr of sl_file.h (30 bytes): the name may fill its 16 bytes without a 0 at the end</summary>
  TKeenSoftLibEntry = packed record
    FileName: array[0..KEEN_SOFTLIB_NAME_SIZE - 1] of AnsiChar;
    /// <summary>From the end of the directory</summary>
    Offset: Cardinal;
    ChunkLength: Cardinal;
    OriginalLength: Cardinal;
    Compression: SmallInt;
  end;

  /// <summary>ChunkHeader of sl_file.h (10 bytes), "CUNK" before the data of a file</summary>
  TKeenSoftLibChunk = packed record
    HeaderId: array[0..3] of AnsiChar;
    OriginalLength: Cardinal;
    Compression: SmallInt;
  end;

  /// <summary>
  ///   A library made with SoftLib: "SLIB", the version, a directory of files and, for each file, a chunk with
  ///   its data, plain or LZH. The LZW of the older libraries is not in the sources of the game and is not here
  /// </summary>
  TKeenShapeLibrary = class
  strict private
    FBytes: TBytes;
    FEntries: TArray<TKeenSoftLibEntry>;
    FDataStart: Integer;
    class function NameOf(const AEntry: TKeenSoftLibEntry): AnsiString; static;
  public
    /// <summary>The bytes of the library file; what is not a library is an EKeenDataException</summary>
    constructor Create(const ABytes: TBytes);
    /// <summary>The names of the files, in the order of the directory</summary>
    function FileNames: TArray<AnsiString>;
    function HasFile(const AName: AnsiString): Boolean;
    /// <summary>
    ///   LoadLIBFile: the expanded bytes of a file. The name is compared without case; of two files with the same
    ///   name the last one of the directory is taken, as in the C. A file that is not there is an
    ///   EKeenFileNotFoundException
    /// </summary>
    function LoadFile(const AName: AnsiString): TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.Lzh;

const
  SIGNATURE_SIZE = 4;

{ TKeenShapeLibrary }

constructor TKeenShapeLibrary.Create(const ABytes: TBytes);
var
  LHeader: TKeenSoftLibHeader;
  LIndex: Integer;
  LPosition: Integer;
begin
  inherited Create;
  if (Length(ABytes) < SIGNATURE_SIZE + SizeOf(LHeader)) or (ABytes[0] <> Ord('S')) or (ABytes[1] <> Ord('L')) or
    (ABytes[2] <> Ord('I')) or (ABytes[3] <> Ord('B')) then
    raise EKeenDataException.CreateFmt(SKeenLibraryBad, ['the file', 'no SLIB signature']);
  FBytes := ABytes;
  Move(ABytes[SIGNATURE_SIZE], LHeader, SizeOf(LHeader));
  if LHeader.Version > KEEN_SOFTLIB_VERSION then
    raise EKeenDataException.CreateFmt(SKeenLibraryBad, ['the file', 'version ' + IntToStr(LHeader.Version)]);
  LPosition := SIGNATURE_SIZE + SizeOf(LHeader);
  if Int64(LPosition) + Int64(LHeader.FileCount) * SizeOf(TKeenSoftLibEntry) > Length(ABytes) then
    raise EKeenDataException.CreateFmt(SKeenLibraryBad, ['the file', 'the directory is cut']);
  SetLength(FEntries, LHeader.FileCount);
  for LIndex := 0 to High(FEntries) do
  begin
    Move(ABytes[LPosition], FEntries[LIndex], SizeOf(TKeenSoftLibEntry));
    Inc(LPosition, SizeOf(TKeenSoftLibEntry));
  end;
  FDataStart := LPosition;
end;

class function TKeenShapeLibrary.NameOf(const AEntry: TKeenSoftLibEntry): AnsiString;
var
  LLength: Integer;
begin
  LLength := 0;
  while (LLength < KEEN_SOFTLIB_NAME_SIZE) and (AEntry.FileName[LLength] <> #0) do
    Inc(LLength);
  SetString(Result, PAnsiChar(@AEntry.FileName[0]), LLength);
end;

function TKeenShapeLibrary.FileNames: TArray<AnsiString>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(FEntries));
  for LIndex := 0 to High(FEntries) do
    Result[LIndex] := NameOf(FEntries[LIndex]);
end;

function TKeenShapeLibrary.HasFile(const AName: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FEntries) do
    if SameText(string(NameOf(FEntries[LIndex])), string(AName)) then
      Exit(True);
  Result := False;
end;

function TKeenShapeLibrary.LoadFile(const AName: AnsiString): TBytes;
var
  LIndex: Integer;
  LFound: Integer;
  LEntry: TKeenSoftLibEntry;
  LChunk: TKeenSoftLibChunk;
  LPosition: Int64;
  LDataLength: Int64;
  LLzh: TKeenLzh;
begin
  LFound := -1;
  for LIndex := 0 to High(FEntries) do
    if SameText(string(NameOf(FEntries[LIndex])), string(AName)) then
      LFound := LIndex;
  if LFound < 0 then
    raise EKeenFileNotFoundException.CreateFmt(SKeenLibraryNoFile, [string(AName)]);
  LEntry := FEntries[LFound];
  LPosition := Int64(FDataStart) + LEntry.Offset;
  if LPosition + SizeOf(LChunk) > Length(FBytes) then
    raise EKeenDataException.CreateFmt(SKeenLibraryBad, [string(AName), 'the chunk is outside the file']);
  Move(FBytes[LPosition], LChunk, SizeOf(LChunk));
  if (LChunk.HeaderId[0] <> 'C') or (LChunk.HeaderId[1] <> 'U') or (LChunk.HeaderId[2] <> 'N') or
    (LChunk.HeaderId[3] <> 'K') then
    raise EKeenDataException.CreateFmt(SKeenLibraryBad, [string(AName), 'LIB File - BAD HeaderID!']);
  Inc(LPosition, SizeOf(LChunk));
  LDataLength := Int64(LEntry.ChunkLength) - SizeOf(LChunk);
  if (LDataLength < 0) or (LPosition + LDataLength > Length(FBytes)) or (LEntry.OriginalLength > $1000000) then
    raise EKeenDataException.CreateFmt(SKeenLibraryBad, [string(AName), 'the data are outside the file']);
  case LChunk.Compression of
    KEEN_CT_NONE:
      Result := Copy(FBytes, LPosition, LDataLength);
    KEEN_CT_LZH:
      begin
        LLzh := TKeenLzh.Create;
        try
          Result := LLzh.Decompress(FBytes, LPosition, LDataLength, LEntry.OriginalLength);
        finally
          LLzh.Free;
        end;
      end;
  else
    raise EKeenDataException.CreateFmt(SKeenLibraryBad, [string(AName), 'Unknown Chunk.Compression Type!']);
  end;
end;

end.
