{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - a directory of the library seen as the DLL one    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.DirectoryAdapter;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf, DelphiDoom.Wad.Dll.ErrorSink;

type
  /// <summary>IWadDllDirectory on top of an IWadDirectory, with its finder and reader</summary>
  TWadDllDirectoryAdapter = class(TInterfacedObject, IWadDllDirectory)
  private
    FDirectory: IWadDirectory;
    FFinder: IWadFinder;
    FReader: ILumpReader;
    FSink: IWadDllErrorSink;
    FSources: TArray<IWadDllSource>;
    function CheckLump(ALump: Integer): Integer;
  public
    constructor Create(const ADirectory: IWadDirectory; const AFinder: IWadFinder;
      const AReader: ILumpReader; const ASink: IWadDllErrorSink);
    function GetCount: Integer; stdcall;
    function GetSourceCount: Integer; stdcall;
    function AddSource(const ASource: IWadDllSource): Integer; stdcall;
    function Truncate(ASourceCount: Integer): Integer; stdcall;
    function ReplaceSource(AIndex: Integer; const ASource: IWadDllSource): Integer; stdcall;
    function GetSource(AIndex: Integer; out ASource: IWadDllSource): Integer; stdcall;
    function GetLumpName(ALump: Integer; ABuffer: PAnsiChar; ABufferSize: Cardinal;
      out ALength: Cardinal): Integer; stdcall;
    function GetLumpInfo(ALump: Integer; out AOffset, ASize: Integer; out AFlags: Cardinal;
      out ASourceIndex: Integer): Integer; stdcall;
    function CheckNumForName(AName: PAnsiChar; AFlags: Cardinal; out ALump: Integer): Integer; stdcall;
    function CheckFirstNumForName(AName: PAnsiChar; out ALump: Integer): Integer; stdcall;
    function CheckNumForNameInRange(AName: PAnsiChar; AFirst, ALast: Integer;
      out ALump: Integer): Integer; stdcall;
    function ReadLump(ALump: Integer; ADestination: Pointer; ADestinationSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Wad.Dll.Text, DelphiDoom.Wad.Dll.SourceAdapter;

{ TWadDllDirectoryAdapter }

constructor TWadDllDirectoryAdapter.Create(const ADirectory: IWadDirectory;
  const AFinder: IWadFinder; const AReader: ILumpReader; const ASink: IWadDllErrorSink);
begin
  inherited Create;
  FDirectory := ADirectory;
  FFinder := AFinder;
  FReader := AReader;
  FSink := ASink;
end;

function TWadDllDirectoryAdapter.CheckLump(ALump: Integer): Integer;
begin
  if (ALump < 0) or (ALump >= FDirectory.Count) then
    Result := WADDLL_ERR_RANGE
  else
    Result := WADDLL_OK;
end;

function TWadDllDirectoryAdapter.GetCount: Integer;
begin
  Result := FDirectory.Count;
end;

function TWadDllDirectoryAdapter.GetSourceCount: Integer;
begin
  Result := FDirectory.SourceCount;
end;

function TWadDllDirectoryAdapter.AddSource(const ASource: IWadDllSource): Integer;
var
  LAccess: IWadDllSourceAccess;
begin
  if ASource = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  if not Supports(ASource, IWadDllSourceAccess, LAccess) then
    Exit(WADDLL_ERR_FOREIGN_OBJECT);
  try
    FDirectory.AddSource(LAccess.Inner);
    // the objects of the DLL are kept so that GetSource gives back the same
    SetLength(FSources, FDirectory.SourceCount);
    FSources[High(FSources)] := ASource;
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.Truncate(ASourceCount: Integer): Integer;
begin
  if (ASourceCount < 0) or (ASourceCount > FDirectory.SourceCount) then
    Exit(WADDLL_ERR_RANGE);
  try
    FDirectory.Truncate(ASourceCount);
    SetLength(FSources, ASourceCount);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.ReplaceSource(AIndex: Integer; const ASource: IWadDllSource): Integer;
var
  LAccess: IWadDllSourceAccess;
begin
  if (AIndex < 0) or (AIndex >= FDirectory.SourceCount) then
    Exit(WADDLL_ERR_RANGE);
  if ASource = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  if not Supports(ASource, IWadDllSourceAccess, LAccess) then
    Exit(WADDLL_ERR_FOREIGN_OBJECT);
  try
    FDirectory.ReplaceSource(AIndex, LAccess.Inner);
    FSources[AIndex] := ASource;
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.GetSource(AIndex: Integer; out ASource: IWadDllSource): Integer;
begin
  ASource := nil;
  if (AIndex < 0) or (AIndex >= FDirectory.SourceCount) then
    Exit(WADDLL_ERR_RANGE);
  ASource := FSources[AIndex];
  Result := WADDLL_OK;
end;

function TWadDllDirectoryAdapter.GetLumpName(ALump: Integer; ABuffer: PAnsiChar;
  ABufferSize: Cardinal; out ALength: Cardinal): Integer;
begin
  ALength := 0;
  Result := CheckLump(ALump);
  if Result <> WADDLL_OK then
    Exit;
  try
    Result := TWadDllText.CopyOut(FDirectory.LumpName(ALump), ABuffer, ABufferSize, ALength);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.GetLumpInfo(ALump: Integer; out AOffset, ASize: Integer;
  out AFlags: Cardinal; out ASourceIndex: Integer): Integer;
begin
  AOffset := 0;
  ASize := 0;
  AFlags := 0;
  ASourceIndex := -1;
  Result := CheckLump(ALump);
  if Result <> WADDLL_OK then
    Exit;
  try
    AOffset := FDirectory.LumpOffset(ALump);
    ASize := FDirectory.LumpSize(ALump);
    AFlags := FDirectory.LumpFlags(ALump);
    ASourceIndex := FDirectory.LumpSourceIndex(ALump);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.CheckNumForName(AName: PAnsiChar; AFlags: Cardinal;
  out ALump: Integer): Integer;
begin
  ALump := -1;
  if AName = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    ALump := FFinder.CheckNumForName(TWadDllText.ToText(AName), AFlags);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.CheckFirstNumForName(AName: PAnsiChar; out ALump: Integer): Integer;
begin
  ALump := -1;
  if AName = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    ALump := FFinder.CheckFirstNumForName(TWadDllText.ToText(AName));
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.CheckNumForNameInRange(AName: PAnsiChar; AFirst, ALast: Integer;
  out ALump: Integer): Integer;
begin
  ALump := -1;
  if AName = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    ALump := FFinder.CheckNumForNameInRange(TWadDllText.ToText(AName), AFirst, ALast);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllDirectoryAdapter.ReadLump(ALump: Integer; ADestination: Pointer;
  ADestinationSize: Cardinal): Integer;
begin
  Result := CheckLump(ALump);
  if Result <> WADDLL_OK then
    Exit;
  try
    if Int64(ADestinationSize) < FDirectory.LumpSize(ALump) then
      Exit(WADDLL_ERR_BUFFER_TOO_SMALL);
    if (FDirectory.LumpSize(ALump) > 0) and (ADestination = nil) then
      Exit(WADDLL_ERR_INVALID_ARGUMENT);
    if FDirectory.LumpSize(ALump) > 0 then
      FReader.ReadLumpInto(ALump, ADestination);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

end.
