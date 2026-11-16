{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - a builder of the library seen as the DLL one      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.BuilderAdapter;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf, DelphiDoom.Wad.Dll.ErrorSink;

type
  /// <summary>IWadDllBuilder on top of an IWadBuilder</summary>
  TWadDllBuilderAdapter = class(TInterfacedObject, IWadDllBuilder)
  private
    FBuilder: IWadBuilder;
    FSink: IWadDllErrorSink;
    function CheckIndex(AIndex: Integer): Integer;
    function DataOf(AData: Pointer; ASize: Cardinal; out ABytes: TBytes): Integer;
  public
    constructor Create(const ABuilder: IWadBuilder; const ASink: IWadDllErrorSink);
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
    function IndexOf(AName: PAnsiChar; out AIndex: Integer): Integer; stdcall;
    function LoadFrom(const ASource: IWadDllSource): Integer; stdcall;
    function Clear: Integer; stdcall;
    function GetSerializedSize(out ASize: Cardinal): Integer; stdcall;
    function Serialize(ADestination: Pointer; ADestinationSize: Cardinal; out AWritten: Cardinal): Integer; stdcall;
    function SaveToFile(APath: PAnsiChar): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Wad.Types, DelphiDoom.Wad.Dll.Text, DelphiDoom.Wad.Dll.SourceAdapter;

{ TWadDllBuilderAdapter }

constructor TWadDllBuilderAdapter.Create(const ABuilder: IWadBuilder; const ASink: IWadDllErrorSink);
begin
  inherited Create;
  FBuilder := ABuilder;
  FSink := ASink;
end;

function TWadDllBuilderAdapter.CheckIndex(AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= FBuilder.Count) then
    Result := WADDLL_ERR_RANGE
  else
    Result := WADDLL_OK;
end;

function TWadDllBuilderAdapter.DataOf(AData: Pointer; ASize: Cardinal; out ABytes: TBytes): Integer;
begin
  ABytes := nil;
  if (ASize > 0) and (AData = nil) then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  SetLength(ABytes, ASize);
  if ASize > 0 then
    Move(AData^, ABytes[0], ASize);
  Result := WADDLL_OK;
end;

function TWadDllBuilderAdapter.GetKind: Integer;
begin
  Result := Ord(FBuilder.Kind);
end;

function TWadDllBuilderAdapter.SetKind(AKind: Integer): Integer;
begin
  if (AKind < Ord(Low(TWadKind))) or (AKind > Ord(High(TWadKind))) then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  FBuilder.Kind := TWadKind(AKind);
  Result := WADDLL_OK;
end;

function TWadDllBuilderAdapter.GetCount: Integer;
begin
  Result := FBuilder.Count;
end;

function TWadDllBuilderAdapter.GetLumpName(AIndex: Integer; ABuffer: PAnsiChar;
  ABufferSize: Cardinal; out ALength: Cardinal): Integer;
begin
  ALength := 0;
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    Result := TWadDllText.CopyOut(FBuilder.LumpNames[AIndex], ABuffer, ABufferSize, ALength);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.GetLumpSize(AIndex: Integer; out ASize: Integer): Integer;
begin
  ASize := 0;
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    ASize := Length(FBuilder.LumpData[AIndex]);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.ReadLump(AIndex: Integer; ADestination: Pointer;
  ADestinationSize: Cardinal): Integer;
var
  LData: TBytes;
begin
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    LData := FBuilder.LumpData[AIndex];
    if Int64(ADestinationSize) < Length(LData) then
      Exit(WADDLL_ERR_BUFFER_TOO_SMALL);
    if (Length(LData) > 0) and (ADestination = nil) then
      Exit(WADDLL_ERR_INVALID_ARGUMENT);
    if Length(LData) > 0 then
      Move(LData[0], ADestination^, Length(LData));
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.AddLump(AName: PAnsiChar; AData: Pointer; ASize: Cardinal;
  out AIndex: Integer): Integer;
var
  LData: TBytes;
begin
  AIndex := -1;
  if AName = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  Result := DataOf(AData, ASize, LData);
  if Result <> WADDLL_OK then
    Exit;
  try
    AIndex := FBuilder.AddLump(TWadDllText.ToText(AName), LData);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.InsertLump(AIndex: Integer; AName: PAnsiChar; AData: Pointer;
  ASize: Cardinal): Integer;
var
  LData: TBytes;
begin
  if AName = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  if (AIndex < 0) or (AIndex > FBuilder.Count) then
    Exit(WADDLL_ERR_RANGE);
  Result := DataOf(AData, ASize, LData);
  if Result <> WADDLL_OK then
    Exit;
  try
    FBuilder.InsertLump(AIndex, TWadDllText.ToText(AName), LData);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.ReplaceLump(AIndex: Integer; AData: Pointer; ASize: Cardinal): Integer;
var
  LData: TBytes;
begin
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  Result := DataOf(AData, ASize, LData);
  if Result <> WADDLL_OK then
    Exit;
  try
    FBuilder.ReplaceLump(AIndex, LData);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.RenameLump(AIndex: Integer; AName: PAnsiChar): Integer;
begin
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  if AName = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    FBuilder.RenameLump(AIndex, TWadDllText.ToText(AName));
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.DeleteLump(AIndex: Integer): Integer;
begin
  Result := CheckIndex(AIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    FBuilder.DeleteLump(AIndex);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.MoveLump(AFromIndex, AToIndex: Integer): Integer;
begin
  Result := CheckIndex(AFromIndex);
  if Result = WADDLL_OK then
    Result := CheckIndex(AToIndex);
  if Result <> WADDLL_OK then
    Exit;
  try
    FBuilder.MoveLump(AFromIndex, AToIndex);
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.IndexOf(AName: PAnsiChar; out AIndex: Integer): Integer;
begin
  AIndex := -1;
  if AName = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    AIndex := FBuilder.IndexOf(TWadDllText.ToText(AName));
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.LoadFrom(const ASource: IWadDllSource): Integer;
var
  LAccess: IWadDllSourceAccess;
begin
  if ASource = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  if not Supports(ASource, IWadDllSourceAccess, LAccess) then
    Exit(WADDLL_ERR_FOREIGN_OBJECT);
  try
    FBuilder.LoadFrom(LAccess.Inner);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.Clear: Integer;
begin
  FBuilder.Clear;
  Result := WADDLL_OK;
end;

function TWadDllBuilderAdapter.GetSerializedSize(out ASize: Cardinal): Integer;
begin
  ASize := 0;
  try
    ASize := Length(FBuilder.ToBytes);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.Serialize(ADestination: Pointer; ADestinationSize: Cardinal;
  out AWritten: Cardinal): Integer;
var
  LBytes: TBytes;
begin
  AWritten := 0;
  try
    LBytes := FBuilder.ToBytes;
    if Int64(ADestinationSize) < Length(LBytes) then
    begin
      AWritten := Length(LBytes);
      Exit(WADDLL_ERR_BUFFER_TOO_SMALL);
    end;
    if ADestination = nil then
      Exit(WADDLL_ERR_INVALID_ARGUMENT);
    Move(LBytes[0], ADestination^, Length(LBytes));
    AWritten := Length(LBytes);
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

function TWadDllBuilderAdapter.SaveToFile(APath: PAnsiChar): Integer;
begin
  if APath = nil then
    Exit(WADDLL_ERR_INVALID_ARGUMENT);
  try
    FBuilder.SaveToFile(TWadDllText.ToText(APath));
    Result := WADDLL_OK;
  except
    on E: Exception do
      Result := FSink.Failed(E);
  end;
end;

end.
