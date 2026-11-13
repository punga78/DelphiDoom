{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - shared types, constants and the exception         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_file.h and war_resources.h,                }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_RESOURCES_COUNT of war.h: the most entries an archive may declare</summary>
  WAR_MAX_RESOURCES_COUNT = 586;
  /// <summary>Bytes of the header of the archive: the archive id and the number of entries</summary>
  WAR_ARCHIVE_HEADER_SIZE = 8;
  /// <summary>DOS retail: 24; the Macintosh retail is 26 (big endian, not read by the original)</summary>
  WAR_ARCHIVE_ID_RETAIL_DOS = $18;
  /// <summary>DOS and Macintosh shareware</summary>
  WAR_ARCHIVE_ID_DEMO = $19;
  /// <summary>Second retail id accepted by wfile_loadWarFile</summary>
  WAR_ARCHIVE_ID_RETAIL_ALT = $1A;
  /// <summary>An entry of the offsets table with this value (or 0) is a placeholder of the demo</summary>
  WAR_OFFSET_NONE = $FFFFFFFF;
  /// <summary>The low 29 bits of the first number of a record are its length once expanded</summary>
  WAR_LENGTH_MASK = $1FFFFFFF;
  /// <summary>Any of the high 3 bits set means the record is compressed</summary>
  WAR_COMPRESSED_MASK = $E0000000;
  /// <summary>Bytes of the sliding window of the compression</summary>
  WAR_WINDOW_SIZE = 4096;
  /// <summary>The most a compressed token gives: 3 + 15 bytes for 2 bytes of input</summary>
  WAR_MAX_EXPANSION = 2049;

type
  /// <summary>WarFileType: the edition of the archive, from its id</summary>
  TWarFileType = (wftUnknown, wftDemo, wftRetail);

  /// <summary>DatabaseEntryType of the original: what a record of DATA.WAR is</summary>
  TWarRecordType = (
    wrtUnknown, wrtImage, wrtPalette, wrtXmid, wrtCursor, wrtUI, wrtText, wrtLevelInfo,
    wrtLevelVisual, wrtLevelPassable, wrtSprite, wrtWave, wrtVoc, wrtTileset, wrtTiles);

  /// <summary>
  ///   Why a record cannot be read. All but wrsAvailable are "placeholder = true" in the original, which logs
  ///   an error for the last two and goes on
  /// </summary>
  TWarRecordStatus = (
    wrsAvailable,
    /// <summary>The offset is 0 or $FFFFFFFF: the demo does not have the record</summary>
    wrsPlaceholder,
    /// <summary>The catalog lists the record with an unknown type: it is not decoded (skipDecompress)</summary>
    wrsSkipped,
    /// <summary>The record does not fit in the file</summary>
    wrsOutOfBounds,
    /// <summary>The length of an uncompressed record is longer than what the file has for it</summary>
    wrsBadLength);

  /// <summary>
  ///   The header of the file, on disk (little endian, no pointers): archive id and number of entries. It is
  ///   followed by the offsets table, one 32 bit number per entry
  /// </summary>
  TWarArchiveHeader = packed record
    ArchiveId: Cardinal;
    EntryCount: Cardinal;
  end;

  /// <summary>One line of the directory of the archive (WarRawResource without the bytes)</summary>
  TWarRecordInfo = record
    Index: Integer;
    Status: TWarRecordStatus;
    /// <summary>The offset of the table; for a placeholder, the value that made it a placeholder</summary>
    Offset: Cardinal;
    /// <summary>Bytes the record takes in the file, its 4 byte header included</summary>
    CompressedLength: Cardinal;
    /// <summary>Bytes once expanded</summary>
    Length: Cardinal;
    Compressed: Boolean;
  end;

  /// <summary>An entry of the table assets[] of war_database.h: what the record number Index is</summary>
  TWarCatalogEntry = record
    Index: Integer;
    RecordType: TWarRecordType;
    Name: string;
    Param1: Word;
    Param2: Word;
    Param3: Word;
  end;

  /// <summary>
  ///   Anything that is wrong in an archive or in the way it is used: not a DATA.WAR, a table or a record that
  ///   does not fit, an index that is not there, a record that cannot be read
  /// </summary>
  EWarException = class(Exception);

resourcestring
  SWarStreamIsNil = 'The source of the archive is nil';
  SWarFileTooShort = 'The file has %d bytes: not an archive (the header has 8)';
  SWarBadArchiveId = 'The archive id is %d: not the DOS retail or demo DATA.WAR';
  SWarTooManyEntries = 'The archive declares %d entries, the most is %d';
  SWarTableOutOfFile = 'The offsets table of %d entries goes past the end of the file';
  SWarIndexOutOfRange = 'The record %d is not in the archive (%d entries)';
  SWarRecordNotAvailable = 'The record %d cannot be read (%s)';
  SWarReadPastEnd = 'Reading %d bytes at %d goes past the end of the data (%d bytes)';
  SWarImpossibleLength = 'The record %d claims %d bytes from %d of compressed data: more than the format can give';
  SWarTruncatedRecord = 'The compressed data of the record ends after %d of %d bytes';

/// <summary>The name of a status, for messages and listings</summary>
function WarRecordStatusName(AStatus: TWarRecordStatus): string;

implementation

function WarRecordStatusName(AStatus: TWarRecordStatus): string;
begin
  case AStatus of
    wrsAvailable: Result := 'available';
    wrsPlaceholder: Result := 'placeholder';
    wrsSkipped: Result := 'skipped';
    wrsOutOfBounds: Result := 'out of bounds';
    wrsBadLength: Result := 'bad length';
  else
    Result := 'unknown';
  end;
end;

end.
