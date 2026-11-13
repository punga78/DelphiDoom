{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contracts                                         }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Intf;

interface

uses
  System.SysUtils, DelphiDoom.War.Types;

type
  /// <summary>Where the bytes of the archive are: a file, a stream, a fake in a test</summary>
  IWarSource = interface
    ['{5B0E2C71-8A34-4D69-B1F5-2C9D7E04A318}']
    /// <summary>Bytes of the data</summary>
    function GetSize: Int64;
    /// <summary>Reads ACount bytes at AOffset into ABuffer; EWarException if they are not all there</summary>
    procedure ReadAt(AOffset: Int64; var ABuffer; ACount: Integer);
    property Size: Int64 read GetSize;
  end;

  /// <summary>The archive DATA.WAR: a directory of records and the bytes of each, expanded when asked</summary>
  IWarArchive = interface
    ['{A93D61F4-27CB-4E80-9D16-0F5B8C3E7A52}']
    function GetFileType: TWarFileType;
    function GetArchiveId: Cardinal;
    function GetEntryCount: Integer;
    /// <summary>The line of the directory of the record AIndex (0..EntryCount - 1)</summary>
    function GetRecordInfo(AIndex: Integer): TWarRecordInfo;
    /// <summary>True if the record can be read (Status = wrsAvailable)</summary>
    function IsAvailable(AIndex: Integer): Boolean;
    /// <summary>The bytes of the record, expanded if it is compressed; EWarException if it cannot be read</summary>
    function ReadRecord(AIndex: Integer): TBytes;
    property FileType: TWarFileType read GetFileType;
    property ArchiveId: Cardinal read GetArchiveId;
    property EntryCount: Integer read GetEntryCount;
  end;

  /// <summary>What each record of the archive is (the table assets[] of the original)</summary>
  IWarCatalog = interface
    ['{E4172B9A-5C03-4F8D-A6E1-93D0B7F24C65}']
    function GetCount: Integer;
    /// <summary>The APosition-th entry of the table, in the order of the original</summary>
    function GetEntry(APosition: Integer): TWarCatalogEntry;
    /// <summary>The entry of the record AIndex; False if the table does not list it</summary>
    function TryFind(AIndex: Integer; out AEntry: TWarCatalogEntry): Boolean;
    /// <summary>The type of the record AIndex; wrtUnknown if the table does not list it</summary>
    function RecordTypeOf(AIndex: Integer): TWarRecordType;
    /// <summary>True if the table lists the record with the unknown type: the game does not decode it</summary>
    function IsSkipped(AIndex: Integer): Boolean;
    /// <summary>
    ///   wres_tryGetPredefinedCustomMapIndex: the index of the level with that name among those that can be
    ///   played as a custom map (a level info with Param2 = 1), ASCII letters in any case
    /// </summary>
    function TryGetPredefinedCustomMapIndex(const AName: string; out AIndex: Integer): Boolean;
    property Count: Integer read GetCount;
  end;

implementation

end.
