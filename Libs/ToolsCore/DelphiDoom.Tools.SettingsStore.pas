{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - the settings file of a tool                 }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.SettingsStore;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Tools.Intf;

type
  /// <summary>
  ///   The settings of a tool in a text file, the format of the old ee_defs/ff_defs/vxe_defs: a
  ///   line [Section] opens a group and each line after it is Name=Value (a line with no value
  ///   after the "=" is ignored when it is read; a value is read with its blanks trimmed; a
  ///   value that has no section is found under any section). The
  ///   old tools kept a table of pointers to global variables; here the values are in the store
  ///   and the tool asks for them. The file is written as UTF-8 and read as UTF-8 or, if that is
  ///   not valid, as ANSI (the old tools wrote ANSI)
  /// </summary>
  TSettingsStore = class(TInterfacedObject, ISettingsStore)
  strict private
    type
      TEntry = record
        Section: string;
        Name: string;
        Value: string;
      end;
  strict private
    FFileSystem: IToolFileSystem;
    FPath: string;
    FEntries: TList<TEntry>;
    function IndexOfEntry(const ASection, AName: string): Integer;
    function TryRead(const ASection, AName: string; out AValue: string): Boolean;
    procedure ParseText(const AText: string);
    function BuildText: string;
    class function DecodeText(const ABytes: TBytes): string; static;
  public
    constructor Create(const AFileSystem: IToolFileSystem; const APath: string);
    destructor Destroy; override;
    function ReadString(const ASection, AName, ADefault: string): string;
    function ReadInteger(const ASection, AName: string; ADefault: Integer): Integer;
    function ReadBoolean(const ASection, AName: string; ADefault: Boolean): Boolean;
    procedure WriteString(const ASection, AName, AValue: string);
    procedure WriteInteger(const ASection, AName: string; AValue: Integer);
    procedure WriteBoolean(const ASection, AName: string; AValue: Boolean);
    function Load: Boolean;
    function Save: Boolean;
  end;

implementation

uses
  System.Classes;

{ TSettingsStore }

constructor TSettingsStore.Create(const AFileSystem: IToolFileSystem; const APath: string);
begin
  inherited Create;
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  FFileSystem := AFileSystem;
  FPath := APath;
  FEntries := TList<TEntry>.Create;
end;

destructor TSettingsStore.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

function TSettingsStore.IndexOfEntry(const ASection, AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FEntries.Count - 1 do
    if SameText(FEntries[LIndex].Section, ASection) and SameText(FEntries[LIndex].Name, AName) then
      Exit(LIndex);
  Result := -1;
end;

function TSettingsStore.TryRead(const ASection, AName: string; out AValue: string): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOfEntry(ASection, AName);
  // the old tools did not look at the sections: a file with no [Section] lines still works
  if LIndex < 0 then
    LIndex := IndexOfEntry('', AName);
  Result := LIndex >= 0;
  if Result then
    AValue := FEntries[LIndex].Value
  else
    AValue := '';
end;

function TSettingsStore.ReadString(const ASection, AName, ADefault: string): string;
begin
  if not TryRead(ASection, AName, Result) then
    Result := ADefault;
end;

function TSettingsStore.ReadInteger(const ASection, AName: string; ADefault: Integer): Integer;
var
  LValue: string;
begin
  if TryRead(ASection, AName, LValue) then
    Result := StrToIntDef(LValue, ADefault)
  else
    Result := ADefault;
end;

function TSettingsStore.ReadBoolean(const ASection, AName: string; ADefault: Boolean): Boolean;
var
  LValue: string;
begin
  Result := ADefault;
  if TryRead(ASection, AName, LValue) then
    Result := StrToIntDef(LValue, Ord(ADefault)) <> 0;
end;

procedure TSettingsStore.WriteString(const ASection, AName, AValue: string);
var
  LEntry: TEntry;
  LIndex: Integer;
begin
  LEntry.Section := ASection;
  LEntry.Name := AName;
  LEntry.Value := AValue;
  LIndex := IndexOfEntry(ASection, AName);
  if LIndex >= 0 then
    FEntries[LIndex] := LEntry
  else
    FEntries.Add(LEntry);
end;

procedure TSettingsStore.WriteInteger(const ASection, AName: string; AValue: Integer);
begin
  WriteString(ASection, AName, IntToStr(AValue));
end;

procedure TSettingsStore.WriteBoolean(const ASection, AName: string; AValue: Boolean);
begin
  WriteString(ASection, AName, IntToStr(Ord(AValue)));
end;

class function TSettingsStore.DecodeText(const ABytes: TBytes): string;
var
  LStart: Integer;
begin
  LStart := 0;
  if (Length(ABytes) >= 3) and (ABytes[0] = $EF) and (ABytes[1] = $BB) and (ABytes[2] = $BF) then
    LStart := 3;
  try
    Result := TEncoding.UTF8.GetString(ABytes, LStart, Length(ABytes) - LStart);
  except
    // bytes that are not UTF-8: the old tools wrote ANSI
    on EEncodingError do
      Result := TEncoding.ANSI.GetString(ABytes, LStart, Length(ABytes) - LStart);
  end;
end;

procedure TSettingsStore.ParseText(const AText: string);
var
  LLines: TStringList;
  LLine: string;
  LSection: string;
  LPosition: Integer;
  LName: string;
  LValue: string;
  LIndex: Integer;
begin
  LSection := '';
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LLine := Trim(LLines[LIndex]);
      if (Length(LLine) >= 2) and (LLine[1] = '[') and (LLine[Length(LLine)] = ']') then
      begin
        LSection := Trim(Copy(LLine, 2, Length(LLine) - 2));
        Continue;
      end;
      LPosition := Pos('=', LLine);
      if LPosition = 0 then
        Continue;
      LName := Trim(Copy(LLine, 1, LPosition - 1));
      LValue := Trim(Copy(LLine, LPosition + 1, Length(LLine) - LPosition));
      if (LName <> '') and (LValue <> '') then
        WriteString(LSection, LName, LValue);
    end;
  finally
    LLines.Free;
  end;
end;

function TSettingsStore.BuildText: string;
var
  LLines: TStringList;
  LSections: TList<string>;
  LSection: string;
  LEntry: TEntry;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  LSections := TList<string>.Create;
  try
    for LEntry in FEntries do
      if not LSections.Contains(LEntry.Section) then
        LSections.Add(LEntry.Section);
    for LIndex := 0 to LSections.Count - 1 do
    begin
      LSection := LSections[LIndex];
      if LLines.Count > 0 then
        LLines.Add('');
      if LSection <> '' then
        LLines.Add('[' + LSection + ']');
      for LEntry in FEntries do
        if LEntry.Section = LSection then
          LLines.Add(LEntry.Name + '=' + LEntry.Value);
    end;
    Result := LLines.Text;
  finally
    LSections.Free;
    LLines.Free;
  end;
end;

function TSettingsStore.Load: Boolean;
var
  LBytes: TBytes;
begin
  Result := FFileSystem.FileExists(FPath) and FFileSystem.TryReadAllBytes(FPath, LBytes);
  if Result then
    ParseText(DecodeText(LBytes));
end;

function TSettingsStore.Save: Boolean;
begin
  Result := FFileSystem.TryWriteAllBytes(FPath, TEncoding.UTF8.GetBytes(BuildText));
end;

end.
