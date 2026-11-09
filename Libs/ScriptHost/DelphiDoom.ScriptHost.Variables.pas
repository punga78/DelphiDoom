{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the variables of the scripts of a map or world    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is TGlobalVariablesList of psi_globals.pas as a class with its services  }
{  (files and failures) given by the constructor. The format of the buffer is  }
{  the one of the savegames and does not change: integers of 4 bytes, floats   }
{  of 4 bytes, strings with the length and 2 bytes for each character.         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Variables;

interface

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Variables.HashList,
  DelphiDoom.ScriptHost.Variables.Intf;

type
  /// <summary>The variables of the scripts of a map or of the world</summary>
  TScriptVariables = class(TInterfacedObject, IScriptVariables)
  strict private
    FFiles: IScriptVariablesFiles;
    FFailure: IScriptVariablesFailure;
    FStrings: TScriptHashStringList;
    FIntegers: TScriptHashStringList;
    FFloats: TScriptHashStringList;
    class procedure FreeList(var AList: TScriptHashStringList); static;
    class function ArrayName(const AName: string; const AIndex: Integer): string; static;
    procedure Fail(const AMessage: string);
    function AddNewString(const AName, AValue: string): Integer;
    function AddNewInteger(const AName: string; const AValue: Integer): Integer;
    function AddNewFloat(const AName: string; const AValue: Single): Integer;
  public
    constructor Create(const AFiles: IScriptVariablesFiles; const AFailure: IScriptVariablesFailure);
    destructor Destroy; override;
    function GetInteger(const AName: string): Integer;
    procedure PutInteger(const AName: string; const AValue: Integer);
    function GetIntegerArray(const AName: string; const AIndex: Integer): Integer;
    procedure PutIntegerArray(const AName: string; const AIndex: Integer; const AValue: Integer);
    function GetFloat(const AName: string): Single;
    procedure PutFloat(const AName: string; const AValue: Single);
    function GetFloatArray(const AName: string; const AIndex: Integer): Single;
    procedure PutFloatArray(const AName: string; const AIndex: Integer; const AValue: Single);
    function GetString(const AName: string): string;
    procedure PutString(const AName: string; const AValue: string);
    function GetStringArray(const AName: string; const AIndex: Integer): string;
    procedure PutStringArray(const AName: string; const AIndex: Integer; const AValue: string);
    function AddString(const AName: string; const AValue: string): Integer;
    function AddInteger(const AName: string; const AValue: Integer): Integer;
    function AddFloat(const AName: string; const AValue: Single): Integer;
    function HasString(const AName: string): Boolean;
    function HasInteger(const AName: string): Boolean;
    function HasFloat(const AName: string): Boolean;
    function StringCount: Integer;
    function IntegerCount: Integer;
    function FloatCount: Integer;
    procedure Clear;
    function LoadFromBuffer(const ABuffer: Pointer): Integer;
    function LoadFromBufferBounded(const ABuffer: Pointer; const ALength: Integer): Integer;
    function SaveToBuffer(const ABuffer: Pointer): Integer;
    function StructureSize: Integer;
    procedure LoadFromFile(const AName: string);
    procedure SaveToFile(const AName: string);
  end;

implementation

uses
  DelphiDoom.ScriptHost.Variables.Types;

{ TScriptVariables }

constructor TScriptVariables.Create(const AFiles: IScriptVariablesFiles;
  const AFailure: IScriptVariablesFailure);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(AFailure) then
    raise EArgumentNilException.Create('AFailure');
  FFiles := AFiles;
  FFailure := AFailure;
  FStrings := TScriptHashStringList.Create;
  FIntegers := TScriptHashStringList.Create;
  FFloats := TScriptHashStringList.Create;
end;

destructor TScriptVariables.Destroy;
begin
  FreeList(FStrings);
  FreeList(FIntegers);
  FreeList(FFloats);
  inherited Destroy;
end;

class procedure TScriptVariables.FreeList(var AList: TScriptHashStringList);
var
  LIndex: Integer;
begin
  if not Assigned(AList) then
    Exit;
  for LIndex := 0 to AList.Count - 1 do
    AList.Objects[LIndex].Free;
  FreeAndNil(AList);
end;

class function TScriptVariables.ArrayName(const AName: string; const AIndex: Integer): string;
begin
  Result := AName + '[' + IntToStr(AIndex) + ']';
end;

procedure TScriptVariables.Fail(const AMessage: string);
begin
  FFailure.Report(AMessage);
  // an application that comes back from a failure gets the exception
  raise EScriptVariablesException.Create(AMessage);
end;

procedure TScriptVariables.Clear;
begin
  FreeList(FStrings);
  FreeList(FIntegers);
  FreeList(FFloats);
  FStrings := TScriptHashStringList.Create;
  FIntegers := TScriptHashStringList.Create;
  FFloats := TScriptHashStringList.Create;
end;

// The Add... below assume that the name is in upper case and is not there already

function TScriptVariables.AddNewString(const AName, AValue: string): Integer;
begin
  Result := FStrings.AddObject(AName, TScriptStringValue.Create(AValue));
end;

function TScriptVariables.AddNewInteger(const AName: string; const AValue: Integer): Integer;
begin
  Result := FIntegers.AddObject(AName, TScriptIntegerValue.Create(AValue));
end;

function TScriptVariables.AddNewFloat(const AName: string; const AValue: Single): Integer;
begin
  Result := FFloats.AddObject(AName, TScriptFloatValue.Create(AValue));
end;

function TScriptVariables.GetInteger(const AName: string): Integer;
var
  LName: string;
  LIndex: Integer;
begin
  LName := UpperCase(AName);
  LIndex := FIntegers.IndexOf(LName);
  if LIndex >= 0 then
    Exit(TScriptIntegerValue(FIntegers.Objects[LIndex]).Value);

  LIndex := FFloats.IndexOf(LName);
  if LIndex < 0 then
    Exit(0);
  Result := Round(TScriptFloatValue(FFloats.Objects[LIndex]).Value);
end;

procedure TScriptVariables.PutInteger(const AName: string; const AValue: Integer);
var
  LName: string;
  LIndex: Integer;
begin
  LName := UpperCase(AName);
  LIndex := FIntegers.IndexOf(LName);
  if LIndex < 0 then
    AddNewInteger(LName, AValue)
  else
    TScriptIntegerValue(FIntegers.Objects[LIndex]).Value := AValue;
end;

function TScriptVariables.GetIntegerArray(const AName: string; const AIndex: Integer): Integer;
begin
  Result := GetInteger(ArrayName(AName, AIndex));
end;

procedure TScriptVariables.PutIntegerArray(const AName: string; const AIndex: Integer;
  const AValue: Integer);
begin
  PutInteger(ArrayName(AName, AIndex), AValue);
end;

function TScriptVariables.GetFloat(const AName: string): Single;
var
  LName: string;
  LIndex: Integer;
begin
  LName := UpperCase(AName);
  LIndex := FFloats.IndexOf(LName);
  if LIndex >= 0 then
    Exit(TScriptFloatValue(FFloats.Objects[LIndex]).Value);

  LIndex := FIntegers.IndexOf(LName);
  if LIndex < 0 then
    Exit(0.0);
  Result := TScriptIntegerValue(FIntegers.Objects[LIndex]).Value;
end;

procedure TScriptVariables.PutFloat(const AName: string; const AValue: Single);
var
  LName: string;
  LIndex: Integer;
begin
  LName := UpperCase(AName);
  LIndex := FFloats.IndexOf(LName);
  if LIndex < 0 then
    AddNewFloat(LName, AValue)
  else
    TScriptFloatValue(FFloats.Objects[LIndex]).Value := AValue;
end;

function TScriptVariables.GetFloatArray(const AName: string; const AIndex: Integer): Single;
begin
  Result := GetFloat(ArrayName(AName, AIndex));
end;

procedure TScriptVariables.PutFloatArray(const AName: string; const AIndex: Integer;
  const AValue: Single);
begin
  PutFloat(ArrayName(AName, AIndex), AValue);
end;

function TScriptVariables.GetString(const AName: string): string;
var
  LIndex: Integer;
begin
  LIndex := FStrings.IndexOf(UpperCase(AName));
  if LIndex < 0 then
    Exit('');
  Result := TScriptStringValue(FStrings.Objects[LIndex]).Value;
end;

procedure TScriptVariables.PutString(const AName: string; const AValue: string);
var
  LName: string;
  LIndex: Integer;
begin
  LName := UpperCase(AName);
  LIndex := FStrings.IndexOf(LName);
  if LIndex < 0 then
    AddNewString(LName, AValue)
  else
    TScriptStringValue(FStrings.Objects[LIndex]).Value := AValue;
end;

function TScriptVariables.GetStringArray(const AName: string; const AIndex: Integer): string;
begin
  Result := GetString(ArrayName(AName, AIndex));
end;

procedure TScriptVariables.PutStringArray(const AName: string; const AIndex: Integer;
  const AValue: string);
begin
  PutString(ArrayName(AName, AIndex), AValue);
end;

function TScriptVariables.AddString(const AName: string; const AValue: string): Integer;
var
  LName: string;
begin
  LName := UpperCase(AName);
  Result := FStrings.IndexOf(LName);
  if Result < 0 then
    Result := AddNewString(LName, AValue)
  else
    TScriptStringValue(FStrings.Objects[Result]).Value := AValue;
end;

function TScriptVariables.AddInteger(const AName: string; const AValue: Integer): Integer;
var
  LName: string;
begin
  LName := UpperCase(AName);
  Result := FIntegers.IndexOf(LName);
  if Result < 0 then
    Result := AddNewInteger(LName, AValue)
  else
    TScriptIntegerValue(FIntegers.Objects[Result]).Value := AValue;
end;

function TScriptVariables.AddFloat(const AName: string; const AValue: Single): Integer;
var
  LName: string;
begin
  LName := UpperCase(AName);
  Result := FFloats.IndexOf(LName);
  if Result < 0 then
    Result := AddNewFloat(LName, AValue)
  else
    TScriptFloatValue(FFloats.Objects[Result]).Value := AValue;
end;

function TScriptVariables.HasString(const AName: string): Boolean;
begin
  Result := FStrings.IndexOf(AName) >= 0;
end;

function TScriptVariables.HasInteger(const AName: string): Boolean;
begin
  Result := FIntegers.IndexOf(AName) >= 0;
end;

function TScriptVariables.HasFloat(const AName: string): Boolean;
begin
  Result := FFloats.IndexOf(AName) >= 0;
end;

function TScriptVariables.StringCount: Integer;
begin
  Result := FStrings.Count;
end;

function TScriptVariables.IntegerCount: Integer;
begin
  Result := FIntegers.Count;
end;

function TScriptVariables.FloatCount: Integer;
begin
  Result := FFloats.Count;
end;

function TScriptVariables.LoadFromBuffer(const ABuffer: Pointer): Integer;
begin
  Result := LoadFromBufferBounded(ABuffer, High(Integer));
end;

function TScriptVariables.LoadFromBufferBounded(const ABuffer: Pointer;
  const ALength: Integer): Integer;
var
  LPosition: Int64;
  LBytes: PByte;

  procedure Need(const ACount: Int64);
  begin
    if LPosition + ACount > ALength then
      raise EScriptVariablesException.Create(SScriptVariablesTruncatedBuffer);
  end;

  function ReadInteger: Integer;
  begin
    Need(SizeOf(Integer));
    Result := PInteger(LBytes + LPosition)^;
    Inc(LPosition, SizeOf(Integer));
  end;

  function ReadFloat: Single;
  begin
    Need(SizeOf(Single));
    Result := PSingle(LBytes + LPosition)^;
    Inc(LPosition, SizeOf(Single));
  end;

  function ReadString: string;
  var
    LLength: Integer;
    LIndex: Integer;
  begin
    LLength := ReadInteger;
    if LLength < 0 then
      raise EScriptVariablesException.Create(SScriptVariablesInvalidBuffer);
    Need(Int64(LLength) * SizeOf(WideChar));
    SetLength(Result, LLength);
    for LIndex := 1 to LLength do
    begin
      Result[LIndex] := PWideChar(LBytes + LPosition)^;
      Inc(LPosition, SizeOf(WideChar));
    end;
  end;

  function ReadCount: Integer;
  begin
    Result := ReadInteger;
    if Result < 0 then
      raise EScriptVariablesException.Create(SScriptVariablesInvalidBuffer);
  end;

var
  LIndex: Integer;
  LCount: Integer;
  LName: string;
begin
  Clear;
  LPosition := 0;
  LBytes := ABuffer;

  LCount := ReadCount;
  for LIndex := 0 to LCount - 1 do
  begin
    LName := ReadString;
    AddString(LName, ReadString);
  end;

  LCount := ReadCount;
  for LIndex := 0 to LCount - 1 do
  begin
    LName := ReadString;
    AddInteger(LName, ReadInteger);
  end;

  LCount := ReadCount;
  for LIndex := 0 to LCount - 1 do
  begin
    LName := ReadString;
    AddFloat(LName, ReadFloat);
  end;

  Result := LPosition;
end;

function TScriptVariables.SaveToBuffer(const ABuffer: Pointer): Integer;
var
  LPosition: Integer;
  LBytes: PByte;

  procedure WriteInteger(const AValue: Integer);
  begin
    PInteger(LBytes + LPosition)^ := AValue;
    Inc(LPosition, SizeOf(Integer));
  end;

  procedure WriteFloat(const AValue: Single);
  begin
    PSingle(LBytes + LPosition)^ := AValue;
    Inc(LPosition, SizeOf(Single));
  end;

  procedure WriteString(const AValue: string);
  var
    LIndex: Integer;
  begin
    WriteInteger(Length(AValue));
    for LIndex := 1 to Length(AValue) do
    begin
      PWideChar(LBytes + LPosition)^ := AValue[LIndex];
      Inc(LPosition, SizeOf(WideChar));
    end;
  end;

var
  LIndex: Integer;
begin
  LPosition := 0;
  LBytes := ABuffer;

  WriteInteger(FStrings.Count);
  for LIndex := 0 to FStrings.Count - 1 do
  begin
    WriteString(FStrings[LIndex]);
    WriteString(TScriptStringValue(FStrings.Objects[LIndex]).Value);
  end;

  WriteInteger(FIntegers.Count);
  for LIndex := 0 to FIntegers.Count - 1 do
  begin
    WriteString(FIntegers[LIndex]);
    WriteInteger(TScriptIntegerValue(FIntegers.Objects[LIndex]).Value);
  end;

  WriteInteger(FFloats.Count);
  for LIndex := 0 to FFloats.Count - 1 do
  begin
    WriteString(FFloats[LIndex]);
    WriteFloat(TScriptFloatValue(FFloats.Objects[LIndex]).Value);
  end;

  Result := LPosition;
end;

function TScriptVariables.StructureSize: Integer;
var
  LIndex: Integer;
begin
  Result := SizeOf(Integer);

  for LIndex := 0 to FStrings.Count - 1 do
  begin
    Inc(Result, SizeOf(Integer) + Length(FStrings[LIndex]) * SizeOf(WideChar));
    Inc(Result, SizeOf(Integer) +
      Length(TScriptStringValue(FStrings.Objects[LIndex]).Value) * SizeOf(WideChar));
  end;

  Inc(Result, SizeOf(Integer));
  for LIndex := 0 to FIntegers.Count - 1 do
  begin
    Inc(Result, SizeOf(Integer) + Length(FIntegers[LIndex]) * SizeOf(WideChar));
    Inc(Result, SizeOf(Integer));
  end;

  Inc(Result, SizeOf(Integer));
  for LIndex := 0 to FFloats.Count - 1 do
  begin
    Inc(Result, SizeOf(Integer) + Length(FFloats[LIndex]) * SizeOf(WideChar));
    Inc(Result, SizeOf(Single));
  end;
end;

procedure TScriptVariables.LoadFromFile(const AName: string);
var
  LBytes: TBytes;
  LDataLength: Integer;
begin
  LBytes := FFiles.ReadFile(AName);
  LDataLength := Length(LBytes) - SizeOf(Integer);
  if LDataLength < 0 then
    Fail(Format(SScriptVariablesCannotLoadFile, [AName]));

  try
    LoadFromBufferBounded(PByte(LBytes) + SizeOf(Integer), LDataLength);
  except
    on EScriptVariablesException do
      Fail(Format(SScriptVariablesCannotLoadFile, [AName]));
  end;
  if LDataLength <> StructureSize then
    Fail(Format(SScriptVariablesCannotLoadFile, [AName]));
end;

procedure TScriptVariables.SaveToFile(const AName: string);
var
  LBytes: TBytes;
  LDataLength: Integer;
begin
  LDataLength := StructureSize;
  SetLength(LBytes, LDataLength + SizeOf(Integer));
  PInteger(LBytes)^ := LDataLength;
  SaveToBuffer(PByte(LBytes) + SizeOf(Integer));
  FFiles.WriteFile(AName, LBytes);
end;

end.
