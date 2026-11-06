{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the object code                           }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.ObjectWriter;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Types, DelphiDoom.Acs.Diagnostics;

type
  /// <summary>
  ///   The bytes of the object: "ACS", the offset of the script table, the code, the strings, the
  ///   script table and the list of strings. Numbers are always little endian. The object cannot
  ///   be bigger than DEFAULT_OBJECT_SIZE bytes
  /// </summary>
  TAcsObjectWriter = class
  private
    type
      TScriptInfo = record
        Number: Integer;
        Address: Integer;
        ArgCount: Integer;
      end;
    var
      FDiagnostics: TAcsDiagnostics;
      FBuffer: TBytes;
      FAddress: Integer;
      FScripts: array[0..MAX_SCRIPT_COUNT - 1] of TScriptInfo;
      FScriptCount: Integer;
    procedure CheckRoom(ASize, AAddress: Integer);
    procedure WriteAt(const ABytes: TBytes; AAddress: Integer);
  public
    constructor Create(const ADiagnostics: TAcsDiagnostics);
    /// <summary>Where the next byte goes: the size of the object so far</summary>
    property Address: Integer read FAddress;
    property ScriptCount: Integer read FScriptCount;
    procedure AppendBytes(const ABytes: TBytes);
    procedure AppendLong(AValue: LongWord);
    /// <summary>The characters, one byte each, and a zero</summary>
    procedure AppendString(const AText: string);
    procedure AppendCmd(ACommand: Integer);
    procedure WriteLong(AValue: LongWord; AAddress: Integer);
    procedure SkipLong;
    /// <summary>A script that starts at the current address</summary>
    procedure AddScript(ANumber, AArgCount: Integer);
    /// <summary>The table of the scripts: how many, then number, address and arguments of each</summary>
    procedure AppendScriptTable;
    /// <summary>The bytes written so far</summary>
    function ToBytes: TBytes;
  end;

implementation

uses
  DelphiDoom.Acs.ErrorCodes;

{ TAcsObjectWriter }

constructor TAcsObjectWriter.Create(const ADiagnostics: TAcsDiagnostics);
begin
  inherited Create;
  FDiagnostics := ADiagnostics;
  SetLength(FBuffer, DEFAULT_OBJECT_SIZE);
  AppendString('ACS');
  SkipLong; // the offset of the script table
end;

procedure TAcsObjectWriter.CheckRoom(ASize, AAddress: Integer);
begin
  if AAddress + ASize > DEFAULT_OBJECT_SIZE then
    FDiagnostics.Fail(ERR_PCODE_BUFFER_OVERFLOW, False);
end;

procedure TAcsObjectWriter.AppendBytes(const ABytes: TBytes);
begin
  CheckRoom(Length(ABytes), FAddress);
  if Length(ABytes) > 0 then
    Move(ABytes[0], FBuffer[FAddress], Length(ABytes));
  Inc(FAddress, Length(ABytes));
end;

procedure TAcsObjectWriter.WriteAt(const ABytes: TBytes; AAddress: Integer);
begin
  CheckRoom(Length(ABytes), AAddress);
  Move(ABytes[0], FBuffer[AAddress], Length(ABytes));
end;

procedure TAcsObjectWriter.AppendLong(AValue: LongWord);
begin
  AppendBytes(TBytes.Create(Byte(AValue), Byte(AValue shr 8), Byte(AValue shr 16),
    Byte(AValue shr 24)));
end;

procedure TAcsObjectWriter.AppendString(const AText: string);
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AText) + 1);
  for LIndex := 1 to Length(AText) do
    LBytes[LIndex - 1] := Byte(Ord(AText[LIndex]));
  LBytes[Length(AText)] := 0;
  AppendBytes(LBytes);
end;

procedure TAcsObjectWriter.AppendCmd(ACommand: Integer);
begin
  AppendLong(LongWord(ACommand));
end;

procedure TAcsObjectWriter.WriteLong(AValue: LongWord; AAddress: Integer);
begin
  WriteAt(TBytes.Create(Byte(AValue), Byte(AValue shr 8), Byte(AValue shr 16),
    Byte(AValue shr 24)), AAddress);
end;

procedure TAcsObjectWriter.SkipLong;
begin
  CheckRoom(SizeOf(LongWord), FAddress);
  Inc(FAddress, SizeOf(LongWord));
end;

procedure TAcsObjectWriter.AddScript(ANumber, AArgCount: Integer);
begin
  if FScriptCount = MAX_SCRIPT_COUNT then
    FDiagnostics.Fail(ERR_TOO_MANY_SCRIPTS, True);

  FScripts[FScriptCount].Number := ANumber;
  FScripts[FScriptCount].Address := FAddress;
  FScripts[FScriptCount].ArgCount := AArgCount;
  Inc(FScriptCount);
end;

procedure TAcsObjectWriter.AppendScriptTable;
var
  LIndex: Integer;
begin
  AppendLong(LongWord(FScriptCount));
  for LIndex := 0 to FScriptCount - 1 do
  begin
    AppendLong(LongWord(FScripts[LIndex].Number));
    AppendLong(LongWord(FScripts[LIndex].Address));
    AppendLong(LongWord(FScripts[LIndex].ArgCount));
  end;
end;

function TAcsObjectWriter.ToBytes: TBytes;
begin
  Result := Copy(FBuffer, 0, FAddress);
end;

end.
