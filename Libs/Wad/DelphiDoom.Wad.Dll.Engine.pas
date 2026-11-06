{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - IWadDll on top of the classes of the library      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.Engine;

interface

uses
  System.SysUtils, System.IOUtils, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf,
  DelphiDoom.Wad.Dll.Intf, DelphiDoom.Wad.Dll.ErrorSink;

type
  /// <summary>
  ///   The DLL: builds the objects of the library and hands them out through IWadDll. It is
  ///   also the error sink of the objects it makes
  /// </summary>
  TWadDllEngine = class(TInterfacedObject, IWadDll, IWadDllErrorSink)
  private
    FLastMessage: string;
  public
    function Failed(AException: Exception): Integer;
    function GetVersion: PAnsiChar; stdcall;
    function GetLastMessage(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer; stdcall;
    function OpenPath(APath: PAnsiChar; out ASource: IWadDllSource): Integer; stdcall;
    function OpenMemory(AName: PAnsiChar; AData: Pointer; ASize: Cardinal;
      out ASource: IWadDllSource): Integer; stdcall;
    function CreateDirectory(out ADirectory: IWadDllDirectory): Integer; stdcall;
    function CreateBuilder(AKind: Integer; out ABuilder: IWadDllBuilder): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Wad.Factory, DelphiDoom.Wad.Dll.Text, DelphiDoom.Wad.Dll.SourceAdapter,
  DelphiDoom.Wad.Dll.DirectoryAdapter, DelphiDoom.Wad.Dll.BuilderAdapter;

{ TWadDllEngine }

function TWadDllEngine.Failed(AException: Exception): Integer;
begin
  FLastMessage := AException.Message;
  if AException is EWadException then
    Result := WADDLL_ERR_MALFORMED
  else if AException is EOutOfMemory then
    Result := WADDLL_ERR_OUT_OF_MEMORY
  else
    Result := WADDLL_ERR_UNEXPECTED;
end;

function TWadDllEngine.GetVersion: PAnsiChar;
begin
  Result := PAnsiChar('DelphiDoom.Wad');
end;

function TWadDllEngine.GetLastMessage(ABuffer: PAnsiChar; ABufferSize: Cardinal;
  out ALength: Cardinal): Integer;
begin
  Result := TWadDllText.CopyOut(FLastMessage, ABuffer, ABufferSize, ALength);
end;

function TWadDllEngine.OpenPath(APath: PAnsiChar; out ASource: IWadDllSource): Integer;
var
  LPath: string;
begin
  ASource := nil;
  if APath = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  LPath := TWadDllText.ToText(APath);
  try
    if not (TFile.Exists(LPath) or TDirectory.Exists(LPath)) then
    begin
      FLastMessage := 'The path ' + LPath + ' does not exist';
      Exit(WADDLL_ERR_NOT_FOUND);
    end;
    ASource := TWadDllSourceAdapter.Create(TWadFactory.OpenPath(LPath), Self);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := Failed(E);
  end;
end;

function TWadDllEngine.OpenMemory(AName: PAnsiChar; AData: Pointer; ASize: Cardinal;
  out ASource: IWadDllSource): Integer;
var
  LBytes: TBytes;
begin
  ASource := nil;
  if (AData = nil) or (ASize = 0) then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    SetLength(LBytes, ASize);
    Move(AData^, LBytes[0], ASize);
    ASource := TWadDllSourceAdapter.Create(
      TWadFactory.OpenBytes(TWadDllText.ToText(AName), LBytes), Self);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := Failed(E);
  end;
end;

function TWadDllEngine.CreateDirectory(out ADirectory: IWadDllDirectory): Integer;
var
  LDirectory: IWadDirectory;
begin
  ADirectory := nil;
  try
    LDirectory := TWadFactory.CreateDirectory;
    ADirectory := TWadDllDirectoryAdapter.Create(LDirectory, TWadFactory.CreateFinder(LDirectory),
      TWadFactory.CreateReader(LDirectory), Self);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := Failed(E);
  end;
end;

function TWadDllEngine.CreateBuilder(AKind: Integer; out ABuilder: IWadDllBuilder): Integer;
begin
  ABuilder := nil;
  if (AKind < Ord(Low(TWadKind))) or (AKind > Ord(High(TWadKind))) then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    ABuilder := TWadDllBuilderAdapter.Create(TWadFactory.CreateBuilder(TWadKind(AKind)), Self);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := Failed(E);
  end;
end;

end.
