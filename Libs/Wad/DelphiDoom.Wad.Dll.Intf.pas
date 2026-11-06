{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - contract shared by the DLL and its clients        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes
  WADDLL_OK = 0;
  WADDLL_ERR_INVALID_ARGUMENT = -1;
  /// <summary>The file or folder does not exist</summary>
  WADDLL_ERR_NOT_FOUND = -2;
  /// <summary>The data is not what it should be (damaged file, bad name, lump outside the file)</summary>
  WADDLL_ERR_MALFORMED = -3;
  /// <summary>A lump, entry or source number that does not exist</summary>
  WADDLL_ERR_RANGE = -4;
  /// <summary>The buffer of the caller is too small; the needed size is given back</summary>
  WADDLL_ERR_BUFFER_TOO_SMALL = -5;
  WADDLL_ERR_OUT_OF_MEMORY = -6;
  /// <summary>A source that was not made by this DLL cannot be added to its directory</summary>
  WADDLL_ERR_FOREIGN_OBJECT = -7;
  WADDLL_ERR_UNEXPECTED = -8;

  // Kinds of sources (TWadSourceKind)
  WADDLL_SOURCE_WAD = 0;
  WADDLL_SOURCE_PAK = 1;
  WADDLL_SOURCE_ZIP = 2;
  WADDLL_SOURCE_FOLDER = 3;
  WADDLL_SOURCE_SINGLE_FILE = 4;

  // Kinds of WADs (TWadKind)
  WADDLL_KIND_IWAD = 0;
  WADDLL_KIND_PWAD = 1;
  WADDLL_KIND_DWAD = 2;

  // Name of the DLL and of its only export
  DDWAD_LIBRARY_NAME = 'DDWad.dll';
  DDWAD_CREATE_EXPORT = 'DDWadCreate';

type
  EWadDllException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer; const AMessage: string = '');
    property Code: Integer read FCode;
  end;

  /// <summary>
  ///   A source of lumps (WAD, PAK, ZIP, folder, single file) made by the DLL
  /// </summary>
  /// <remarks>
  ///   Like every interface of this unit: only buffers and integers cross the DLL boundary,
  ///   the caller owns every buffer, methods are stdcall. Text is UTF-8 and zero terminated; to
  ///   get a text pass the buffer (nil to only ask the length): ALength is the length in bytes
  ///   without the terminator, and WADDLL_ERR_BUFFER_TOO_SMALL tells the buffer is short
  /// </remarks>
  IWadDllSource = interface
    ['{A3F1C0E2-5B7D-4E29-8C64-9D0B2F7A1E53}']
    function GetKind: Integer; stdcall;
    function GetCount: Integer; stdcall;
    function GetName(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer; stdcall;
    function GetEntryName(AIndex: Integer; ABuffer: PAnsiChar; ABufferSize: Cardinal;
      out ALength: Cardinal): Integer; stdcall;
    function GetEntryInfo(AIndex: Integer; out AOffset, ASize: Integer): Integer; stdcall;
    /// <summary>ADestination must hold at least the size of the entry</summary>
    function ReadEntry(AIndex: Integer; ADestination: Pointer; ADestinationSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>The lumps of several sources one after the other, with the search by name</summary>
  IWadDllDirectory = interface
    ['{7E94D5B8-0C3A-4F61-A2D7-1B86E4C9F035}']
    function GetCount: Integer; stdcall;
    function GetSourceCount: Integer; stdcall;
    /// <summary>ASource must come from this DLL</summary>
    function AddSource(const ASource: IWadDllSource): Integer; stdcall;
    function Truncate(ASourceCount: Integer): Integer; stdcall;
    function ReplaceSource(AIndex: Integer; const ASource: IWadDllSource): Integer; stdcall;
    function GetSource(AIndex: Integer; out ASource: IWadDllSource): Integer; stdcall;
    function GetLumpName(ALump: Integer; ABuffer: PAnsiChar; ABufferSize: Cardinal;
      out ALength: Cardinal): Integer; stdcall;
    function GetLumpInfo(ALump: Integer; out AOffset, ASize: Integer; out AFlags: Cardinal;
      out ASourceIndex: Integer): Integer; stdcall;
    /// <summary>ALump is -1 when there is none (the result is still WADDLL_OK)</summary>
    function CheckNumForName(AName: PAnsiChar; AFlags: Cardinal; out ALump: Integer): Integer; stdcall;
    function CheckFirstNumForName(AName: PAnsiChar; out ALump: Integer): Integer; stdcall;
    function CheckNumForNameInRange(AName: PAnsiChar; AFirst, ALast: Integer;
      out ALump: Integer): Integer; stdcall;
    /// <summary>ADestination must hold at least the size of the lump</summary>
    function ReadLump(ALump: Integer; ADestination: Pointer; ADestinationSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>Makes a new WAD, or changes one read from a source</summary>
  IWadDllBuilder = interface
    ['{C58A2F17-9D40-4B3E-86E1-3A7F0D5C2B94}']
    function GetKind: Integer; stdcall;
    function SetKind(AKind: Integer): Integer; stdcall;
    function GetCount: Integer; stdcall;
    function GetLumpName(AIndex: Integer; ABuffer: PAnsiChar; ABufferSize: Cardinal;
      out ALength: Cardinal): Integer; stdcall;
    function GetLumpSize(AIndex: Integer; out ASize: Integer): Integer; stdcall;
    function ReadLump(AIndex: Integer; ADestination: Pointer; ADestinationSize: Cardinal): Integer; stdcall;
    function AddLump(AName: PAnsiChar; AData: Pointer; ASize: Cardinal; out AIndex: Integer): Integer; stdcall;
    function InsertLump(AIndex: Integer; AName: PAnsiChar; AData: Pointer; ASize: Cardinal): Integer; stdcall;
    function ReplaceLump(AIndex: Integer; AData: Pointer; ASize: Cardinal): Integer; stdcall;
    function RenameLump(AIndex: Integer; AName: PAnsiChar): Integer; stdcall;
    function DeleteLump(AIndex: Integer): Integer; stdcall;
    function MoveLump(AFromIndex, AToIndex: Integer): Integer; stdcall;
    /// <summary>AIndex is -1 when there is none</summary>
    function IndexOf(AName: PAnsiChar; out AIndex: Integer): Integer; stdcall;
    /// <summary>ASource must come from this DLL</summary>
    function LoadFrom(const ASource: IWadDllSource): Integer; stdcall;
    function Clear: Integer; stdcall;
    /// <summary>The size of the WAD that Serialize writes</summary>
    function GetSerializedSize(out ASize: Cardinal): Integer; stdcall;
    function Serialize(ADestination: Pointer; ADestinationSize: Cardinal; out AWritten: Cardinal): Integer; stdcall;
    function SaveToFile(APath: PAnsiChar): Integer; stdcall;
  end;

  /// <summary>Contract of the WAD DLL</summary>
  /// <remarks>
  ///   Every object obtained from it must be released before the DLL is unloaded, because
  ///   its code lives inside the DLL
  /// </remarks>
  IWadDll = interface
    ['{2D6B90F4-E1A7-4C83-B5D2-8F3C7A04E619}']
    function GetVersion: PAnsiChar; stdcall;
    /// <summary>
    ///   The message of the last failure of this object, UTF-8 (same protocol of the texts);
    ///   it is not kept per thread
    /// </summary>
    function GetLastMessage(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer; stdcall;
    /// <summary>A WAD, PAK, ZIP, WAD2/WAD3, a folder or any other file as one lump (UTF-8 path)</summary>
    function OpenPath(APath: PAnsiChar; out ASource: IWadDllSource): Integer; stdcall;
    /// <summary>A WAD, WAD2/WAD3 or PAK held in memory; the DLL copies the bytes</summary>
    function OpenMemory(AName: PAnsiChar; AData: Pointer; ASize: Cardinal;
      out ASource: IWadDllSource): Integer; stdcall;
    function CreateDirectory(out ADirectory: IWadDllDirectory): Integer; stdcall;
    function CreateBuilder(AKind: Integer; out ABuilder: IWadDllBuilder): Integer; stdcall;
  end;

  /// <summary>Signature of the only export of the DLL</summary>
  TDDWadCreate = function(out AWad: IWadDll): Integer; stdcall;

implementation

{ EWadDllException }

constructor EWadDllException.CreateCode(ACode: Integer; const AMessage: string);
begin
  if AMessage <> '' then
    inherited Create(AMessage)
  else
    inherited CreateFmt('WAD DLL error %d', [ACode]);
  FCode := ACode;
end;

end.
