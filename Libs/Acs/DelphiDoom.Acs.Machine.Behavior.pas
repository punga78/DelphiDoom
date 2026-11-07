{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS library - the object code of a map (BEHAVIOR)               }
{  Port of the interpreter of Hexen (p_acs.c, Raven Software)                  }
{  Copyright (C) 1995 Raven Software, Corp.                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Machine.Behavior;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Machine.Types, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   The object code that the compiler makes: a header (the marker, where the table of the
  ///   scripts is, where the code starts), the table (how many scripts, then number, address and
  ///   arguments of each; how many strings, then the address of each) and the code. The memory is
  ///   the caller's and stays there while the object code is used. Every address is checked
  ///   against the size: a table that points out of the memory makes the whole object code wrong
  /// </summary>
  TAcsBehavior = class
  strict private
    FLog: ILog;
    FCode: PByte;
    FSize: Integer;
    FScripts: TArray<TAcsScriptInfo>;
    FOpen: TArray<Boolean>;
    FStrings: TArray<string>;
    function GetScriptCount: Integer;
    function GetState(AIndex: Integer): TAcsScriptState;
    procedure SetState(AIndex: Integer; AValue: TAcsScriptState);
    function GetWaitValue(AIndex: Integer): Integer;
    procedure SetWaitValue(AIndex: Integer; AValue: Integer);
    procedure Warn(const AText: string);
    function LongAt(AOffset: Integer): Integer;
    function Fits(AOffset, ALength: Int64): Boolean;
    function TryReadString(AOffset: Integer; out AText: string): Boolean;
    function TryReadTable(out AScripts: TArray<TAcsScriptInfo>; out AOpen: TArray<Boolean>;
      out AStrings: TArray<string>): Boolean;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const ALog: ILog);
    /// <summary>
    ///   Reads the table of the scripts and the strings. False (and no scripts) if the marker is
    ///   not the one of an object code or if the table is wrong; an object code with no scripts
    ///   is loaded and has none
    /// </summary>
    function Load(ACode: PByte; ASize: Integer): Boolean;
    procedure Clear;
    property Code: PByte read FCode;
    property Size: Integer read FSize;
    property ScriptCount: Integer read GetScriptCount;
    /// <summary>The state that a script has when the map starts: open scripts are running</summary>
    function IsOpenScript(AIndex: Integer): Boolean;
    /// <summary>The index of the script with the number, -1 if there is none</summary>
    function IndexOfScript(ANumber: Integer): Integer;
    property State[AIndex: Integer]: TAcsScriptState read GetState write SetState;
    property WaitValue[AIndex: Integer]: Integer read GetWaitValue write SetWaitValue;
    function GetScript(AIndex: Integer): TAcsScriptInfo;
    function StringCount: Integer;
    /// <summary>The string of the table; false if there is no such string</summary>
    function TryGetString(AIndex: Integer; out AText: string): Boolean;
    /// <summary>The address of a position in the code; nil if it is not in the object code</summary>
    function AddressAt(AOffset: Integer): PInteger;
    /// <summary>True if there are four bytes of the object code at the address</summary>
    function Contains(AAddress: PInteger): Boolean;
  end;

implementation

uses
  DelphiDoom.Acs.PCodes;

type
  TAcsHeader = packed record
    Marker: Integer;
    InfoOffset: Integer;
    Code: Integer;
  end;

const
  SWrongMarker = 'ACS: the object code does not start with the marker';
  SWrongHeader = 'ACS: the object code is too short for the header';
  SWrongTable = 'ACS: the table of the scripts is out of the object code';
  SWrongScriptAddress = 'ACS: the script %d starts out of the object code';
  SWrongScriptArguments = 'ACS: the script %d has %d arguments';
  SWrongString = 'ACS: the string %d is out of the object code';
  SScriptTableEntrySize = 12;

{ TAcsBehavior }

constructor TAcsBehavior.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TAcsBehavior.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

function TAcsBehavior.Fits(AOffset, ALength: Int64): Boolean;
begin
  Result := (AOffset >= 0) and (ALength >= 0) and (AOffset + ALength <= FSize);
end;

function TAcsBehavior.LongAt(AOffset: Integer): Integer;
begin
  Result := PInteger(FCode + AOffset)^;
end;

function TAcsBehavior.TryReadString(AOffset: Integer; out AText: string): Boolean;
var
  LIndex: Integer;
  LLength: Integer;
begin
  Result := False;
  AText := '';
  if not Fits(AOffset, 1) then
    Exit;
  LLength := 0;
  while (AOffset + LLength < FSize) and (PByte(FCode + AOffset + LLength)^ <> 0) do
    Inc(LLength);
  if AOffset + LLength >= FSize then
    Exit; // not ended
  SetLength(AText, LLength);
  for LIndex := 1 to LLength do
    AText[LIndex] := Char(PByte(FCode + AOffset + LIndex - 1)^);
  Result := True;
end;

function TAcsBehavior.TryReadTable(out AScripts: TArray<TAcsScriptInfo>;
  out AOpen: TArray<Boolean>; out AStrings: TArray<string>): Boolean;
var
  LOffset: Integer;
  LCount: Integer;
  LIndex: Integer;
  LNumber: Integer;
  LAddress: Integer;
  LArgCount: Integer;
begin
  Result := False;
  AScripts := nil;
  AOpen := nil;
  AStrings := nil;
  LOffset := LongAt(SizeOf(Integer)); // the offset of the table is the second long of the header
  if not Fits(LOffset, SizeOf(Integer)) then
  begin
    Warn(SWrongTable);
    Exit;
  end;
  LCount := LongAt(LOffset);
  Inc(LOffset, SizeOf(Integer));
  if (LCount < 0) or not Fits(LOffset, Int64(LCount) * SScriptTableEntrySize) then
  begin
    Warn(SWrongTable);
    Exit;
  end;
  SetLength(AScripts, LCount);
  SetLength(AOpen, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LNumber := LongAt(LOffset);
    LAddress := LongAt(LOffset + 4);
    LArgCount := LongAt(LOffset + 8);
    Inc(LOffset, SScriptTableEntrySize);
    if not Fits(LAddress, SizeOf(Integer)) then
    begin
      Warn(Format(SWrongScriptAddress, [LNumber]));
      Exit;
    end;
    if (LArgCount < 0) or (LArgCount > ACS_MAX_SCRIPT_ARGUMENTS) then
    begin
      Warn(Format(SWrongScriptArguments, [LNumber, LArgCount]));
      Exit;
    end;
    AOpen[LIndex] := LNumber >= OPEN_SCRIPTS_BASE;
    if AOpen[LIndex] then
      Dec(LNumber, OPEN_SCRIPTS_BASE);
    AScripts[LIndex].Number := LNumber;
    AScripts[LIndex].Address := PInteger(FCode + LAddress);
    AScripts[LIndex].ArgCount := LArgCount;
    if AOpen[LIndex] then
      AScripts[LIndex].State := assRunning
    else
      AScripts[LIndex].State := assInactive;
    AScripts[LIndex].WaitValue := 0;
  end;
  if LCount = 0 then
    Exit(True); // empty object code: no strings either
  if not Fits(LOffset, SizeOf(Integer)) then
  begin
    Warn(SWrongTable);
    Exit;
  end;
  LCount := LongAt(LOffset);
  Inc(LOffset, SizeOf(Integer));
  if (LCount < 0) or not Fits(LOffset, Int64(LCount) * SizeOf(Integer)) then
  begin
    Warn(SWrongTable);
    Exit;
  end;
  SetLength(AStrings, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    if not TryReadString(LongAt(LOffset), AStrings[LIndex]) then
    begin
      Warn(Format(SWrongString, [LIndex]));
      Exit;
    end;
    Inc(LOffset, SizeOf(Integer));
  end;
  Result := True;
end;

function TAcsBehavior.Load(ACode: PByte; ASize: Integer): Boolean;
var
  LScripts: TArray<TAcsScriptInfo>;
  LOpen: TArray<Boolean>;
  LStrings: TArray<string>;
begin
  Clear;
  Result := False;
  if not Assigned(ACode) or (ASize < SizeOf(TAcsHeader)) then
  begin
    Warn(SWrongHeader);
    Exit;
  end;
  FCode := ACode;
  FSize := ASize;
  if LongAt(0) <> ACS_MAGIC then
  begin
    Warn(SWrongMarker);
    Clear;
    Exit;
  end;
  if not TryReadTable(LScripts, LOpen, LStrings) then
  begin
    Clear;
    Exit;
  end;
  FScripts := LScripts;
  FOpen := LOpen;
  FStrings := LStrings;
  Result := True;
end;

procedure TAcsBehavior.Clear;
begin
  FCode := nil;
  FSize := 0;
  FScripts := nil;
  FOpen := nil;
  FStrings := nil;
end;

function TAcsBehavior.GetScriptCount: Integer;
begin
  Result := Length(FScripts);
end;

function TAcsBehavior.IsOpenScript(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Length(FOpen)) and FOpen[AIndex];
end;

function TAcsBehavior.IndexOfScript(ANumber: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FScripts) do
    if FScripts[LIndex].Number = ANumber then
      Exit(LIndex);
  Result := -1;
end;

function TAcsBehavior.GetState(AIndex: Integer): TAcsScriptState;
begin
  Result := FScripts[AIndex].State;
end;

procedure TAcsBehavior.SetState(AIndex: Integer; AValue: TAcsScriptState);
begin
  FScripts[AIndex].State := AValue;
end;

function TAcsBehavior.GetWaitValue(AIndex: Integer): Integer;
begin
  Result := FScripts[AIndex].WaitValue;
end;

procedure TAcsBehavior.SetWaitValue(AIndex: Integer; AValue: Integer);
begin
  FScripts[AIndex].WaitValue := AValue;
end;

function TAcsBehavior.GetScript(AIndex: Integer): TAcsScriptInfo;
begin
  Result := FScripts[AIndex];
end;

function TAcsBehavior.StringCount: Integer;
begin
  Result := Length(FStrings);
end;

function TAcsBehavior.TryGetString(AIndex: Integer; out AText: string): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Length(FStrings));
  if Result then
    AText := FStrings[AIndex]
  else
    AText := '';
end;

function TAcsBehavior.AddressAt(AOffset: Integer): PInteger;
begin
  if Fits(AOffset, SizeOf(Integer)) then
    Result := PInteger(FCode + AOffset)
  else
    Result := nil;
end;

function TAcsBehavior.Contains(AAddress: PInteger): Boolean;
begin
  Result := Assigned(FCode) and (NativeUInt(AAddress) >= NativeUInt(FCode)) and
    (NativeUInt(AAddress) + SizeOf(Integer) <= NativeUInt(FCode) + NativeUInt(FSize));
end;

end.
