{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - the fake engine (cvars,      }
{  system, console, session, files, command buffer, events) that writes down   }
{  every call, in the same format as Tools\Verifica\255\harness.cpp            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.World;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types,
  DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Factory;

type
  /// <summary>What Sys_Quit and Sys_Error do in the engine (the process ends): here the call is left with this</summary>
  ETestExit = class(Exception)
  public
    Why: string;
    constructor CreateWhy(const AWhy: string);
  end;

  /// <summary>The text of a golden: the escapes of the harness (\\ \n \r \t \" and \xHH)</summary>
  TD3Escape = class
  public
    class function Escape(const AText: AnsiString): string; static;
    class function Unescape(const AText: string): AnsiString; static;
  end;

  TD3FakeFile = class(TInterfacedObject, ID3CommonFile)
  strict private
    FWorld: TObject;
    FName: string;
    FData: TBytes;
    FPosition: Integer;
  public
    constructor Create(const AWorld: TObject; const AName: string; const AData: TBytes);
    function Write(const ABuffer; ACount: Integer): Integer;
    function Read(var ABuffer; ACount: Integer): Integer;
    procedure Flush;
    procedure ForceFlush;
    property Name: string read FName;
  end;

  /// <summary>
  ///   All the systems that idCommon uses, in one object that the test owns (the interfaces are not reference
  ///   counted). Every call is written to Trace, one line per fact, as the C++ harness does.
  /// </summary>
  TD3FakeWorld = class(TObject, IInterface, ID3CommonCVars, ID3CommonSettings, ID3JournalSettings,
    ID3CommonSystem, ID3CommonConsole, ID3CommonSession, ID3CommonRenderState, ID3CommonFileSystem,
    ID3CommonCalendar, ID3CommonLifecycle, ICmdBuffer, ID3KeyTracker, ID3EventSource)
  strict private
    FVars: TDictionary<string, string>;
    FFiles: TDictionary<string, TBytes>;
  public
    Trace: TStringList;
    CVarsInitialized: Boolean;
    FilesInitialized: Boolean;
    OpenGLRunning: Boolean;
    OpenFails: Boolean;
    Time: Integer;
    SystemQueue: TList<TD3SysEvent>;
    constructor Create;
    destructor Destroy; override;
    procedure Line(const AText: string);
    procedure LineText(const ATag: string; const AText: AnsiString);
    function VarValue(const AName: string): string;
    function FileBytes(const AName: string): TBytes;
    procedure StoreFile(const AName: string; const AData: TBytes);
    // IInterface: not counted
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    // ID3CommonCVars
    function IsInitialized: Boolean;
    function GetCVarInteger(const AName: AnsiString): Integer;
    function GetCVarBool(const AName: AnsiString): Boolean;
    procedure SetCVarBool(const AName: AnsiString; const AValue: Boolean);
    procedure SetCVarString(const AName, AValue: AnsiString);
    // ID3CommonSettings
    function Developer: Boolean;
    function TimestampPrints: Integer;
    function LogFile: Integer;
    procedure DisableLogFile;
    function LogFileName: AnsiString;
    // ID3JournalSettings
    function JournalLevel: Integer;
    procedure SetJournalLevel(const ALevel: Integer);
    // ID3CommonSystem
    function Milliseconds: Integer;
    procedure Printf(const AText: AnsiString);
    procedure SetClipboardData(const AText: AnsiString);
    procedure SetFatalError(const AText: AnsiString);
    procedure Quit;
    procedure Error(const AText: AnsiString);
    // ID3CommonConsole
    procedure Print(const AText: AnsiString);
    // ID3CommonSession
    procedure Stop;
    procedure UpdateScreen;
    procedure PacifierUpdate;
    procedure ProcessEvent(const AEvent: TD3SysEvent);
    // ID3CommonRenderState
    function IsOpenGLRunning: Boolean;
    // ID3CommonFileSystem
    function ID3CommonFileSystem.IsInitialized = FilesAreInitialized;
    function FilesAreInitialized: Boolean;
    function OpenFileWrite(const AName, APath: AnsiString): ID3CommonFile;
    function OpenFileRead(const AName: AnsiString): ID3CommonFile;
    procedure CloseFile(const AFile: ID3CommonFile);
    // ID3CommonCalendar
    function CurrentTimeText: AnsiString;
    // ID3CommonLifecycle
    procedure Shutdown;
    // ICmdBuffer
    procedure BufferCommandText(const AExecution: TCmdExecution; const AText: AnsiString);
    procedure BufferCommandArgs(const AExecution: TCmdExecution; const AArgs: TIdCmdArgs);
    procedure ExecuteCommandBuffer;
    procedure SetWait(const AFrames: Integer);
    procedure SetupReloadEngine(const AArgs: TIdCmdArgs);
    function PostReloadEngine: Boolean;
    // ID3KeyTracker
    procedure PreliminaryKeyEvent(const AKey: Integer; const ADown: Boolean);
    // ID3EventSource
    function GetEvent: TD3SysEvent;
    /// <summary>The services record for the factory: everything is this object</summary>
    function Services: TD3HostServices;
  end;

implementation

uses
  System.Math;

const
  SExecutionName: array[TCmdExecution] of string = ('now', 'insert', 'append');
  SFixedTime = 'Thu Jan 01 00:00:00 1970' + #10;

{ ETestExit }

constructor ETestExit.CreateWhy(const AWhy: string);
begin
  inherited Create(AWhy);
  Why := AWhy;
end;

{ TD3Escape }

class function TD3Escape.Escape(const AText: AnsiString): string;
var
  LIndex: Integer;
  LCode: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LCode := Byte(AText[LIndex]);
    case LCode of
      Ord('\'): Result := Result + '\\';
      10: Result := Result + '\n';
      13: Result := Result + '\r';
      9: Result := Result + '\t';
      Ord('"'): Result := Result + '\"';
    else
      if (LCode < 32) or (LCode > 126) then
        Result := Result + '\x' + IntToHex(LCode, 2)
      else
        Result := Result + Char(LCode);
    end;
  end;
end;

class function TD3Escape.Unescape(const AText: string): AnsiString;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] <> '\') or (LIndex = Length(AText)) then
    begin
      Result := Result + AnsiChar(AText[LIndex]);
      Inc(LIndex);
      Continue;
    end;
    Inc(LIndex);
    LChar := AText[LIndex];
    if LChar = 'n' then
      Result := Result + #10
    else if LChar = 't' then
      Result := Result + #9
    else if LChar = 'r' then
      Result := Result + #13
    else if LChar = '"' then
      Result := Result + '"'
    else if LChar = '\' then
      Result := Result + '\'
    else if (LChar = 'x') and (LIndex + 2 < Length(AText) + 1) then
    begin
      Result := Result + AnsiChar(StrToInt('$' + Copy(AText, LIndex + 1, 2)));
      Inc(LIndex, 2);
    end
    else
      Result := Result + '\' + AnsiChar(LChar);
    Inc(LIndex);
  end;
end;

{ TD3FakeFile }

constructor TD3FakeFile.Create(const AWorld: TObject; const AName: string; const AData: TBytes);
begin
  inherited Create;
  FWorld := AWorld;
  FName := AName;
  FData := AData;
end;

function TD3FakeFile.Write(const ABuffer; ACount: Integer): Integer;
var
  LChunk: TBytes;
  LText: AnsiString;
  LHex: string;
  LIndex: Integer;
  LCode: Byte;
  LWorld: TD3FakeWorld;
  LStored: TBytes;
begin
  LWorld := FWorld as TD3FakeWorld;
  SetLength(LChunk, ACount);
  if ACount > 0 then
    Move(ABuffer, LChunk[0], ACount);
  LStored := LWorld.FileBytes(FName);
  SetLength(LStored, Length(LStored) + ACount);
  if ACount > 0 then
    Move(LChunk[0], LStored[Length(LStored) - ACount], ACount);
  LWorld.StoreFile(FName, LStored);
  if (Length(FName) > 4) and (Copy(FName, Length(FName) - 3, 4) = '.dat') then
  begin
    LHex := '';
    for LIndex := 0 to ACount - 1 do
    begin
      LCode := LChunk[LIndex];
      // the 4 bytes of the pointer of the C++ event are not compared
      if (ACount = 20) and (LIndex >= 16) then
        LCode := 0;
      LHex := LHex + IntToHex(LCode, 2);
    end;
    LWorld.Line('FWB ' + FName + ' ' + LHex);
  end
  else
  begin
    if ACount > 0 then
      SetString(LText, PAnsiChar(@LChunk[0]), ACount)
    else
      LText := '';
    LWorld.LineText('FW ' + FName, LText);
  end;
  Result := ACount;
end;

function TD3FakeFile.Read(var ABuffer; ACount: Integer): Integer;
begin
  Result := ACount;
  if FPosition + Result > Length(FData) then
    Result := Length(FData) - FPosition;
  if Result > 0 then
    Move(FData[FPosition], ABuffer, Result);
  Inc(FPosition, Result);
end;

procedure TD3FakeFile.Flush;
begin
  (FWorld as TD3FakeWorld).Line('FLUSH ' + FName);
end;

procedure TD3FakeFile.ForceFlush;
begin
  (FWorld as TD3FakeWorld).Line('FFLUSH ' + FName);
end;

{ TD3FakeWorld }

constructor TD3FakeWorld.Create;
begin
  inherited Create;
  FVars := TDictionary<string, string>.Create;
  FFiles := TDictionary<string, TBytes>.Create;
  Trace := TStringList.Create;
  SystemQueue := TList<TD3SysEvent>.Create;
  CVarsInitialized := True;
  FilesInitialized := True;
  // no renderer: like the program without a window
  OpenGLRunning := False;
  // the cvars of Common.cpp and EventLoop.cpp with their defaults
  FVars.Add('developer', '0');
  FVars.Add('com_timestampPrints', '0');
  FVars.Add('logFile', '0');
  FVars.Add('logFileName', 'qconsole.log');
  FVars.Add('com_journal', '0');
end;

destructor TD3FakeWorld.Destroy;
begin
  SystemQueue.Free;
  Trace.Free;
  FFiles.Free;
  FVars.Free;
  inherited Destroy;
end;

procedure TD3FakeWorld.Line(const AText: string);
begin
  Trace.Add(AText);
end;

procedure TD3FakeWorld.LineText(const ATag: string; const AText: AnsiString);
begin
  Trace.Add(ATag + ' ' + TD3Escape.Escape(AText));
end;

function TD3FakeWorld.VarValue(const AName: string): string;
begin
  if not FVars.TryGetValue(AName, Result) then
    Result := '';
end;

function TD3FakeWorld.FileBytes(const AName: string): TBytes;
begin
  if not FFiles.TryGetValue(AName, Result) then
    Result := nil;
end;

procedure TD3FakeWorld.StoreFile(const AName: string; const AData: TBytes);
begin
  FFiles.AddOrSetValue(AName, AData);
end;

function TD3FakeWorld.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TD3FakeWorld._AddRef: Integer;
begin
  Result := -1;
end;

function TD3FakeWorld._Release: Integer;
begin
  Result := -1;
end;

function CAtoi(const AText: string): Integer;
var
  LIndex: Integer;
  LNegative: Boolean;
begin
  Result := 0;
  LIndex := 1;
  while (LIndex <= Length(AText)) and (AText[LIndex] = ' ') do
    Inc(LIndex);
  LNegative := False;
  if (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['+', '-']) then
  begin
    LNegative := AText[LIndex] = '-';
    Inc(LIndex);
  end;
  while (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['0'..'9']) do
  begin
    Result := Result * 10 + Ord(AText[LIndex]) - Ord('0');
    Inc(LIndex);
  end;
  if LNegative then
    Result := -Result;
end;

function TD3FakeWorld.IsInitialized: Boolean;
begin
  Result := CVarsInitialized;
end;

function TD3FakeWorld.GetCVarInteger(const AName: AnsiString): Integer;
begin
  Result := CAtoi(VarValue(string(AName)));
end;

function TD3FakeWorld.GetCVarBool(const AName: AnsiString): Boolean;
begin
  Result := GetCVarInteger(AName) <> 0;
end;

procedure TD3FakeWorld.SetCVarBool(const AName: AnsiString; const AValue: Boolean);
begin
  Line(Format('CVARSETB %s %d', [string(AName), Ord(AValue)]));
  FVars.AddOrSetValue(string(AName), IntToStr(Ord(AValue)));
end;

procedure TD3FakeWorld.SetCVarString(const AName, AValue: AnsiString);
begin
  LineText('CVARSET', AName + ' ' + AValue);
  FVars.AddOrSetValue(string(AName), string(AValue));
end;

function TD3FakeWorld.Developer: Boolean;
begin
  Result := GetCVarInteger('developer') <> 0;
end;

function TD3FakeWorld.TimestampPrints: Integer;
begin
  Result := GetCVarInteger('com_timestampPrints');
end;

function TD3FakeWorld.LogFile: Integer;
begin
  Result := GetCVarInteger('logFile');
end;

procedure TD3FakeWorld.DisableLogFile;
begin
  // com_logFile.SetBool( false ): the C++ harness sets the value without a trace
  FVars.AddOrSetValue('logFile', '0');
end;

function TD3FakeWorld.LogFileName: AnsiString;
begin
  Result := AnsiString(VarValue('logFileName'));
end;

function TD3FakeWorld.JournalLevel: Integer;
begin
  Result := GetCVarInteger('com_journal');
end;

procedure TD3FakeWorld.SetJournalLevel(const ALevel: Integer);
begin
  FVars.AddOrSetValue('com_journal', IntToStr(ALevel));
end;

function TD3FakeWorld.Milliseconds: Integer;
begin
  Result := Time;
end;

procedure TD3FakeWorld.Printf(const AText: AnsiString);
begin
  LineText('SYS', AText);
end;

procedure TD3FakeWorld.SetClipboardData(const AText: AnsiString);
begin
  LineText('CLIP', AText);
end;

procedure TD3FakeWorld.SetFatalError(const AText: AnsiString);
begin
  LineText('FATALERR', AText);
end;

procedure TD3FakeWorld.Quit;
begin
  Line('SYSQUIT');
  raise ETestExit.CreateWhy('quit');
end;

procedure TD3FakeWorld.Error(const AText: AnsiString);
begin
  LineText('SYSERR', AText);
  raise ETestExit.CreateWhy('error');
end;

procedure TD3FakeWorld.Print(const AText: AnsiString);
begin
  LineText('CON', AText);
end;

procedure TD3FakeWorld.Stop;
begin
  Line('SESSION stop');
end;

procedure TD3FakeWorld.UpdateScreen;
begin
  Line('SESSION update');
end;

procedure TD3FakeWorld.PacifierUpdate;
begin
  Line('SESSION pacifier');
end;

procedure TD3FakeWorld.ProcessEvent(const AEvent: TD3SysEvent);
begin
  Line(Format('SESSION event %d %d %d %d', [AEvent.EvType, AEvent.EvValue, AEvent.EvValue2, Length(AEvent.EvData)]));
end;

function TD3FakeWorld.IsOpenGLRunning: Boolean;
begin
  Result := OpenGLRunning;
end;

function TD3FakeWorld.FilesAreInitialized: Boolean;
begin
  Result := FilesInitialized;
end;

function TD3FakeWorld.OpenFileWrite(const AName, APath: AnsiString): ID3CommonFile;
var
  LBase: string;
begin
  LBase := string(APath);
  if LBase = '' then
    LBase := 'fs_savepath';
  if OpenFails then
  begin
    Line(Format('OPENW %s %s fail', [string(AName), LBase]));
    Exit(nil);
  end;
  Line(Format('OPENW %s %s ok', [string(AName), LBase]));
  StoreFile(string(AName), nil);
  Result := TD3FakeFile.Create(Self, string(AName), nil);
end;

function TD3FakeWorld.OpenFileRead(const AName: AnsiString): ID3CommonFile;
var
  LBytes: TBytes;
begin
  if not FFiles.TryGetValue(string(AName), LBytes) then
  begin
    Line(Format('OPENR %s fail', [string(AName)]));
    Exit(nil);
  end;
  Line(Format('OPENR %s ok', [string(AName)]));
  Result := TD3FakeFile.Create(Self, string(AName), LBytes);
end;

procedure TD3FakeWorld.CloseFile(const AFile: ID3CommonFile);
begin
  Line('CLOSE ' + (AFile as TD3FakeFile).Name);
end;

function TD3FakeWorld.CurrentTimeText: AnsiString;
begin
  Result := SFixedTime;
end;

procedure TD3FakeWorld.Shutdown;
begin
  Line('SHUTDOWN');
end;

procedure TD3FakeWorld.BufferCommandText(const AExecution: TCmdExecution; const AText: AnsiString);
begin
  LineText('BUFTEXT ' + SExecutionName[AExecution], AText);
end;

procedure TD3FakeWorld.BufferCommandArgs(const AExecution: TCmdExecution; const AArgs: TIdCmdArgs);
var
  LIndex: Integer;
  LText: AnsiString;
begin
  LText := '';
  for LIndex := 0 to AArgs.Argc - 1 do
  begin
    if LIndex > 0 then
      LText := LText + '|';
    LText := LText + AArgs.Argv(LIndex);
  end;
  LineText('BUFARGS ' + SExecutionName[AExecution], LText);
end;

procedure TD3FakeWorld.ExecuteCommandBuffer;
begin
  Line('BUFEXEC');
end;

procedure TD3FakeWorld.SetWait(const AFrames: Integer);
begin
end;

procedure TD3FakeWorld.SetupReloadEngine(const AArgs: TIdCmdArgs);
begin
end;

function TD3FakeWorld.PostReloadEngine: Boolean;
begin
  Result := False;
end;

procedure TD3FakeWorld.PreliminaryKeyEvent(const AKey: Integer; const ADown: Boolean);
begin
  Line(Format('KEY %d %d', [AKey, Ord(ADown)]));
end;

function TD3FakeWorld.GetEvent: TD3SysEvent;
begin
  if SystemQueue.Count = 0 then
    Result := TD3SysEvent.Make(SE_NONE, 0, 0)
  else
  begin
    Result := SystemQueue[0];
    SystemQueue.Delete(0);
  end;
  Line(Format('GETEV %d %d %d %d', [Result.EvType, Result.EvValue, Result.EvValue2, Length(Result.EvData)]));
end;

function TD3FakeWorld.Services: TD3HostServices;
begin
  Result.CVars := Self;
  Result.Settings := Self;
  Result.System := Self;
  Result.Console := Self;
  Result.Session := Self;
  Result.Render := Self;
  Result.Files := Self;
  Result.Calendar := Self;
  Result.Lifecycle := Self;
  Result.Buffer := Self;
  Result.Keys := Self;
  Result.Events := Self;
  Result.Journal := Self;
end;

end.
