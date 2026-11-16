{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - a source of the library seen as IWadDllSource     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.SourceAdapter;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf, DelphiDoom.Wad.Dll.ErrorSink;

type
  /// <summary>Gives back the source of the library behind an object of the DLL</summary>
  IWadDllSourceAccess = interface
    ['{91C3F5A0-6B2D-4E78-A4F1-0D7E8B3C5A26}']
    function Inner: IWadSource;
  end;

  /// <summary>IWadDllSource on top of an IWadSource</summary>
  TWadDllSourceAdapter = class(TInterfacedObject, IWadDllSource, IWadDllSourceAccess)
  private
    FSource: IWadSource;
    FSink: IWadDllErrorSink;
    function CheckIndex(AIndex: Integer): Integer;
  public
    constructor Create(const ASource: IWadSource; const ASink: IWadDllErrorSink);
    function Inner: IWadSource;
    function GetKind: Integer; stdcall;
    function GetCount: Integer; stdcall;
    function GetName(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer; stdcall;
    function GetEntryName(AIndex: Integer; ABuffer: PAnsiChar; ABufferSize: Cardinal;
      out ALength: Cardinal): Integer; stdcall;
    function GetEntryInfo(AIndex: Integer; out AOffset, ASize: Integer): Integer; stdcall;
    function ReadEntry(AIndex: Integer; ADestination: Pointer; ADestinationSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Wad.Types, DelphiDoom.Wad.Dll.Text;

{ TWadDllSourceAdapter }

constructor TWadDllSourceAdapter.Create(const ASource: IWadSource; const ASink: IWadDllErrorSink);
begin
  inherited Create;
  FSource := ASource;
  FSink := ASink;
end;

function TWadDllSourceAdapter.Inner: IWadSource;
begin
  Result := FSource;
end;

function TWadDllSourceAdapter.CheckIndex(AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= FSource.Count) then
    Result := WADDLL_ERR_RANGE
  else
    Result := WADDLL_OK;
end;

function TWadDllSourceAdapter.GetKind: Integer;
begin
  Result := Ord(FSource.Kind);
end;

function TWadDllSourceAdapter.GetCount: Integer;
begin
  Result := FSource.Count;
end;

function TWadDllSourceAdapter.GetName(ABuffer: PAnsiChar; ABufferSize: Cardinal;
  out ALength: Cardinal): Integer;
begin
  try
    Result := TWadDllText.CopyOut(FSource.Name, ABuffer, ABufferSize, ALength);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllSourceAdapter.GetEntryName(AIndex: Integer; ABuffer: PAnsiChar;
  ABufferSize: Cardinal; out ALength: Cardinal): Integer;
begin
  ALength := 0;
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    Result := TWadDllText.CopyOut(FSource.Entries[AIndex].Name, ABuffer, ABufferSize, ALength);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllSourceAdapter.GetEntryInfo(AIndex: Integer; out AOffset, ASize: Integer): Integer;
begin
  AOffset := 0;
  ASize := 0;
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    AOffset := FSource.Entries[AIndex].Offset;
    ASize := FSource.Entries[AIndex].Size;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllSourceAdapter.ReadEntry(AIndex: Integer; ADestination: Pointer;
  ADestinationSize: Cardinal): Integer;
begin
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    if Int64(ADestinationSize) < FSource.Entries[AIndex].Size then
      Exit(WADDLL_ERR_BUFFER_TOO_SMALL);
    if (FSource.Entries[AIndex].Size > 0) and (ADestination = nil) then
      Exit(WADDLL_ERR_INVALID_ARGUMENT);
    if FSource.Entries[AIndex].Size > 0 then
      FSource.ReadEntryInto(AIndex, ADestination);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

end.
