{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - a machine on fakes      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Rig;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.ClassInfo,
  DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.ScriptProgram,
  DelphiDoom.DoomScript.Thread, DelphiDoom.DoomScript.Machine, DelphiDoom.Tests.IdLib.Fakes,
  DelphiDoom.Tests.DoomScript.Fakes;

type
  /// <summary>
  ///   A script machine of the library on fakes (host, world, log, files in memory) for the fixtures: the
  ///   default script declares the events of the threads the tests use, <c>Compile</c> adds a script,
  ///   <c>Run</c> starts a function now, <c>Printed</c> is what the scripts printed.
  /// </summary>
  TDoomScriptTestRig = class
  strict private
    FHost: TDoomScriptFakeHost;
    FHostIntf: IDoomScriptHost;
    FLog: TIdLibLogRecorder;
    FLogIntf: IIdLibLog;
    FFiles: TIdLibMemoryFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FMachine: TDoomScriptMachine;
    FEntityClass: TDoomScriptClassInfo;
    FTargets: TArray<TDoomScriptEventTarget>;
    FEntityNames: TArray<AnsiString>;
    FEntityNumbers: TArray<Integer>;
  public
    const
      DEFS: AnsiString =
        'scriptEvent void terminate( float threadNumber );'#10 +
        'scriptEvent void pause();'#10 +
        'scriptEvent void wait( float time );'#10 +
        'scriptEvent void waitFrame();'#10 +
        'scriptEvent void waitFor( entity mover );'#10 +
        'scriptEvent void waitForThread( float threadNumber );'#10 +
        'scriptEvent void print( string text );'#10 +
        'scriptEvent void println( string text );'#10 +
        'scriptEvent void assert( float condition );'#10 +
        'scriptEvent float random( float range );'#10 +
        'scriptEvent float getTime();'#10 +
        'scriptEvent void killthread( string threadName );'#10 +
        'scriptEvent void threadname( string name );'#10 +
        'scriptEvent entity getEntity( string name );'#10 +
        'scriptEvent entity spawn( string classname );'#10 +
        'scriptEvent void copySpawnArgs( entity ent );'#10 +
        'scriptEvent void setSpawnArg( string key, string value );'#10 +
        'scriptEvent string SpawnString( string key, string default );'#10 +
        'scriptEvent float SpawnFloat( string key, float default );'#10 +
        'scriptEvent vector SpawnVector( string key, vector default );'#10 +
        'scriptEvent vector angToForward( vector angles );'#10 +
        'scriptEvent vector angToRight( vector angles );'#10 +
        'scriptEvent vector angToUp( vector angles );'#10 +
        'scriptEvent float sin( float degrees );'#10 +
        'scriptEvent float cos( float degrees );'#10 +
        'scriptEvent float sqrt( float square );'#10 +
        'scriptEvent vector vecNormalize( vector vec );'#10 +
        'scriptEvent float vecLength( vector vec );'#10 +
        'scriptEvent float DotProduct( vector vec1, vector vec2 );'#10 +
        'scriptEvent vector CrossProduct( vector vec1, vector vec2 );'#10 +
        'scriptEvent vector VecToAngles( vector vec );'#10 +
        'scriptEvent void onSignal( float signalNum, entity ent, string functionName );'#10 +
        'scriptEvent void clearSignalThread( float signalNum, entity ent );'#10 +
        'scriptEvent void error( string text );'#10 +
        'scriptEvent void warning( string text );'#10 +
        'scriptEvent float strLength( string text );'#10 +
        'scriptEvent string strLeft( string text, float num );'#10 +
        'scriptEvent string strRight( string text, float num );'#10 +
        'scriptEvent string strSkip( string text, float num );'#10 +
        'scriptEvent string strMid( string text, float start, float num );'#10 +
        'scriptEvent float strToFloat( string text );'#10 +
        'scriptEvent float getFrameTime();'#10 +
        'scriptEvent float getTicsPerSecond();'#10 +
        'scriptEvent void remove();'#10 +
        'scriptEvent void say( string text );'#10 +
        'scriptEvent void ping( float value );'#10 +
        'scriptEvent float twice( float value );'#10;
    /// <param name="AWithWorld">False: a machine without a world (the world events have no handler)</param>
    constructor Create(const AWithWorld: Boolean = True);
    destructor Destroy; override;
    /// <summary>Compiles a script as the file test.script; the program is left open for more</summary>
    procedure Compile(const AText: AnsiString);
    /// <summary>Compiles and gives the message of the error of the compilation ('' if there is none)</summary>
    function CompileError(const AText: AnsiString): string;
    function FindFunction(const AName: AnsiString): TDoomScriptFunction;
    /// <summary>A new thread on a function, started now: true if the function ended</summary>
    function Run(const AFunction: AnsiString): Boolean;
    /// <summary>Runs the function and gives the message of the script error it ends with</summary>
    function RunError(const AFunction: AnsiString): string;
    /// <summary>Moves the time of the host forward and serves the events</summary>
    procedure Frame(const AMsec: Integer = 16);
    /// <summary>
    ///   Adds an entity of the class "testEntity", which answers the events "ping" (recorded in the calls of
    ///   the host) and "twice" (returns its argument times two)
    /// </summary>
    function AddEntity(const ANumber: Integer; const AName: AnsiString): TDoomScriptEventTarget;
    /// <summary>All the text printed, in order</summary>
    function Printed: string;
    /// <summary>All the warnings, one per line</summary>
    function Warnings: string;
    property Host: TDoomScriptFakeHost read FHost;
    property Log: TIdLibLogRecorder read FLog;
    property Files: TIdLibMemoryFileSystem read FFiles;
    property Machine: TDoomScriptMachine read FMachine;
    property EntityClass: TDoomScriptClassInfo read FEntityClass;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.DoomScript.Factory;

constructor TDoomScriptTestRig.Create(const AWithWorld: Boolean);
var
  LWorld: IDoomScriptWorld;
  LHost: TDoomScriptFakeHost;
  LMachine: TDoomScriptMachine;
begin
  inherited Create;
  FHost := TDoomScriptFakeHost.Create;
  FHostIntf := FHost;
  FLog := TIdLibLogRecorder.Create;
  FLogIntf := FLog;
  FFiles := TIdLibMemoryFileSystem.Create;
  FFilesIntf := FFiles;
  FFiles.SetFile('script/doom_defs.script', DEFS);
  if AWithWorld then
    LWorld := FHost
  else
    LWorld := nil;
  FMachine := TDoomScriptFactory.CreateMachine(FHostIntf, LWorld, FLogIntf, FFilesIntf);
  LHost := FHost;
  LMachine := FMachine;
  FEntityClass := FMachine.Classes.Declare('testEntity', 'idClass');
  FEntityClass.AddEvent(FMachine.Events.Define('ping', 'f'),
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LHost.Calls.Add(Format('ping %d %g', [LMachine.Entities.NumberOf(TDoomScriptEventTarget(ATarget)),
        AArgs[0].FloatValue], TFormatSettings.Invariant));
    end);
  FEntityClass.AddEvent(FMachine.Events.Define('twice', 'f', 'f'),
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LMachine.ScriptProgram.ReturnFloat(AArgs[0].FloatValue * 2);
    end);
  FMachine.ScriptProgram.BeginCompilation;
end;

destructor TDoomScriptTestRig.Destroy;
var
  LTarget: TDoomScriptEventTarget;
begin
  FMachine.Free;
  for LTarget in FTargets do
    LTarget.Free;
  FFilesIntf := nil;
  FLogIntf := nil;
  FHostIntf := nil;
  inherited;
end;

procedure TDoomScriptTestRig.Compile(const AText: AnsiString);
var
  LIndex: Integer;
begin
  FMachine.ScriptProgram.CompileText('test.script', AText, False);
  // the entities of the rig exist before the scripts that name them: give their numbers to the new $names
  for LIndex := 0 to High(FEntityNames) do
    if FMachine.Entities.Exists(FEntityNumbers[LIndex]) then
      FMachine.ScriptProgram.SetEntity(FEntityNames[LIndex], FEntityNumbers[LIndex]);
end;

function TDoomScriptTestRig.CompileError(const AText: AnsiString): string;
begin
  Result := '';
  try
    Compile(AText);
  except
    on E: EDoomScriptError do
      Result := E.Message;
  end;
end;

function TDoomScriptTestRig.FindFunction(const AName: AnsiString): TDoomScriptFunction;
begin
  Result := FMachine.ScriptProgram.FindFunction(AName);
  if not Assigned(Result) then
    raise EArgumentException.Create('no function ' + string(AName));
end;

function TDoomScriptTestRig.Run(const AFunction: AnsiString): Boolean;
begin
  Result := FMachine.CreateThread(FindFunction(AFunction)).Start;
end;

function TDoomScriptTestRig.RunError(const AFunction: AnsiString): string;
begin
  Result := '';
  try
    Run(AFunction);
  except
    on E: EDoomScriptError do
      Result := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TDoomScriptTestRig.Frame(const AMsec: Integer);
begin
  FHost.Time := FHost.Time + AMsec;
  FHost.RealClientTime := FHost.Time;
  FMachine.ServiceEvents;
end;

function TDoomScriptTestRig.AddEntity(const ANumber: Integer; const AName: AnsiString): TDoomScriptEventTarget;
begin
  Result := TDoomScriptEventTarget.Create(FEntityClass);
  FTargets := FTargets + [Result];
  FEntityNames := FEntityNames + [AName];
  FEntityNumbers := FEntityNumbers + [ANumber];
  FMachine.Entities.Add(ANumber, Result, AName);
  FMachine.ScriptProgram.SetEntity(AName, ANumber);
end;

function TDoomScriptTestRig.Printed: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FLog.Entries.Count - 1 do
    if FLog.Entries[LIndex].StartsWith('P:') then
      Result := Result + Copy(FLog.Entries[LIndex], 3, MaxInt);
end;

function TDoomScriptTestRig.Warnings: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FLog.Entries.Count - 1 do
    if FLog.Entries[LIndex].StartsWith('W:') then
      Result := Result + Copy(FLog.Entries[LIndex], 3, MaxInt) + #10;
end;

end.
