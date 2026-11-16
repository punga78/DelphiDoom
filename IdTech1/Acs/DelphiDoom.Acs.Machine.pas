{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS library - the virtual machine                               }
{  Port of the interpreter of Hexen (p_acs.c, Raven Software)                  }
{  Copyright (C) 1995 Raven Software, Corp.                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Machine;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Machine.Types, DelphiDoom.Acs.Machine.Intf,
  DelphiDoom.Acs.Machine.Behavior, DelphiDoom.Acs.Machine.Variables,
  DelphiDoom.Acs.Machine.Interpreter, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   The scripts of a map: starts, suspends and ends them, keeps what they wait for and runs
  ///   them one tic at a time. The memory of a running script is the engine's (a thinker that the
  ///   host gives); the machine keeps the table of the scripts, the variables and the store
  /// </summary>
  TAcsMachine = class(TInterfacedObject, IAcsMachine)
  strict private
    FHost: IAcsHost;
    FLog: ILog;
    FBehavior: TAcsBehavior;
    FVariables: TAcsVariables;
    FInterpreter: TAcsInterpreter;
    /// <summary>The script that StartScript started last; nil if it started none</summary>
    FNewScript: PAcsScript;
    procedure Warn(const AText: string);
    procedure ScriptFinished(ANumber: Integer);
    procedure StartOpenScript(AIndex: Integer);
    function IsValidIndex(AIndex: Integer): Boolean;
    function GetScriptCount: Integer;
    function GetCodeBase: PByte;
    function GetScriptState(AIndex: Integer): TAcsScriptState;
    procedure SetScriptState(AIndex: Integer; AValue: TAcsScriptState);
    function GetScriptWaitValue(AIndex: Integer): Integer;
    procedure SetScriptWaitValue(AIndex: Integer; AValue: Integer);
    function GetMapVariables: TAcsMapVariables;
    procedure SetMapVariables(const AValue: TAcsMapVariables);
    function GetWorldVariables: TAcsWorldVariables;
    procedure SetWorldVariables(const AValue: TAcsWorldVariables);
    function GetStore: TAcsStore;
    procedure SetStore(const AValue: TAcsStore);
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const AHost: IAcsHost; const ALog: ILog);
    destructor Destroy; override;
    function Load(ACode: PByte; ASize: Integer): Integer;
    procedure Unload;
    function StartScript(ANumber, AMap: Integer; const AArguments: TAcsArguments;
      AActivator, ALine: Pointer; ASide: Integer): Boolean;
    function SuspendScript(ANumber: Integer): Boolean;
    function TerminateScript(ANumber: Integer): Boolean;
    procedure CheckStore;
    procedure InitNewGame;
    procedure TagFinished(ATag: Integer);
    procedure PolyobjectFinished(APolyobject: Integer);
    procedure Execute(AScript: PAcsScript);
  end;

implementation

const
  SUnknownScript = 'P_STARTACS ERROR: UNKNOWN SCRIPT %d';
  SWrongScriptIndex = 'ACS script %d: its entry %d is not in the table of the scripts';

{ TAcsMachine }

constructor TAcsMachine.Create(const AHost: IAcsHost; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FHost := AHost;
  FLog := ALog;
  FBehavior := TAcsBehavior.Create(ALog);
  FVariables := TAcsVariables.Create;
  FInterpreter := TAcsInterpreter.Create(AHost, ALog, FBehavior, FVariables);
end;

destructor TAcsMachine.Destroy;
begin
  FInterpreter.Free;
  FVariables.Free;
  FBehavior.Free;
  inherited Destroy;
end;

procedure TAcsMachine.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

function TAcsMachine.IsValidIndex(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FBehavior.ScriptCount);
end;

procedure TAcsMachine.ScriptFinished(ANumber: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FBehavior.ScriptCount - 1 do
    if (FBehavior.State[LIndex] = assWaitingForScript) and
      (FBehavior.WaitValue[LIndex] = ANumber) then
      FBehavior.State[LIndex] := assRunning;
end;

procedure TAcsMachine.StartOpenScript(AIndex: Integer);
var
  LScript: PAcsScript;
begin
  LScript := FHost.AllocateScript;
  LScript.Number := FBehavior.GetScript(AIndex).Number;
  // the objects of the world have one second to be ready
  LScript.DelayCount := FHost.TicsPerSecond;
  LScript.InfoIndex := AIndex;
  LScript.Ip := FBehavior.GetScript(AIndex).Address;
end;

function TAcsMachine.Load(ACode: PByte; ASize: Integer): Integer;
var
  LIndex: Integer;
begin
  FNewScript := nil;
  if not FBehavior.Load(ACode, ASize) then
    Exit(0);
  if FBehavior.ScriptCount = 0 then
    Exit(0); // empty object code
  for LIndex := 0 to FBehavior.ScriptCount - 1 do
    if FBehavior.IsOpenScript(LIndex) then
      StartOpenScript(LIndex);
  FVariables.ClearMap;
  Result := FBehavior.ScriptCount;
end;

procedure TAcsMachine.Unload;
begin
  FBehavior.Clear;
  FNewScript := nil;
end;

function TAcsMachine.GetScriptCount: Integer;
begin
  Result := FBehavior.ScriptCount;
end;

function TAcsMachine.GetCodeBase: PByte;
begin
  Result := FBehavior.Code;
end;

function TAcsMachine.GetScriptState(AIndex: Integer): TAcsScriptState;
begin
  Result := FBehavior.State[AIndex];
end;

procedure TAcsMachine.SetScriptState(AIndex: Integer; AValue: TAcsScriptState);
begin
  FBehavior.State[AIndex] := AValue;
end;

function TAcsMachine.GetScriptWaitValue(AIndex: Integer): Integer;
begin
  Result := FBehavior.WaitValue[AIndex];
end;

procedure TAcsMachine.SetScriptWaitValue(AIndex: Integer; AValue: Integer);
begin
  FBehavior.WaitValue[AIndex] := AValue;
end;

function TAcsMachine.GetMapVariables: TAcsMapVariables;
begin
  Result := FVariables.Map;
end;

procedure TAcsMachine.SetMapVariables(const AValue: TAcsMapVariables);
begin
  FVariables.Map := AValue;
end;

function TAcsMachine.GetWorldVariables: TAcsWorldVariables;
begin
  Result := FVariables.World;
end;

procedure TAcsMachine.SetWorldVariables(const AValue: TAcsWorldVariables);
begin
  FVariables.World := AValue;
end;

function TAcsMachine.GetStore: TAcsStore;
begin
  Result := FVariables.Store;
end;

procedure TAcsMachine.SetStore(const AValue: TAcsStore);
begin
  FVariables.Store := AValue;
end;

function TAcsMachine.StartScript(ANumber, AMap: Integer; const AArguments: TAcsArguments;
  AActivator, ALine: Pointer; ASide: Integer): Boolean;
var
  LIndex: Integer;
  LScript: PAcsScript;
  LArgument: Integer;
begin
  FNewScript := nil;
  if (AMap <> 0) and (AMap <> FHost.CurrentMap) then
    Exit(FVariables.AddToStore(AMap, ANumber, AArguments));

  LIndex := FBehavior.IndexOfScript(ANumber);
  if LIndex = -1 then
  begin
    FHost.ShowConsoleMessage(Format(SUnknownScript, [ANumber]));
    Exit(False);
  end;

  case FBehavior.State[LIndex] of
    assSuspended:
      begin
        FBehavior.State[LIndex] := assRunning;
        Exit(True);
      end;
    assInactive:
      ;
  else
    Exit(False); // the script is already running
  end;

  LScript := FHost.AllocateScript;
  LScript.Number := ANumber;
  LScript.InfoIndex := LIndex;
  LScript.Activator := AActivator;
  LScript.Line := ALine;
  LScript.Side := ASide;
  LScript.Ip := FBehavior.GetScript(LIndex).Address;
  for LArgument := 0 to FBehavior.GetScript(LIndex).ArgCount - 1 do
    LScript.Vars[LArgument] := AArguments[LArgument];

  FBehavior.State[LIndex] := assRunning;
  FNewScript := LScript;
  Result := True;
end;

function TAcsMachine.SuspendScript(ANumber: Integer): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FBehavior.IndexOfScript(ANumber);
  if LIndex = -1 then
    Exit(False);
  // a script that is not running cannot be suspended
  if FBehavior.State[LIndex] in [assInactive, assSuspended, assTerminating] then
    Exit(False);
  FBehavior.State[LIndex] := assSuspended;
  Result := True;
end;

function TAcsMachine.TerminateScript(ANumber: Integer): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FBehavior.IndexOfScript(ANumber);
  if LIndex = -1 then
    Exit(False);
  if FBehavior.State[LIndex] in [assInactive, assTerminating] then
    Exit(False);
  FBehavior.State[LIndex] := assTerminating;
  Result := True;
end;

procedure TAcsMachine.CheckStore;
var
  LIndex: Integer;
  LEntry: PAcsStoreEntry;
  LArguments: TAcsArguments;
begin
  LIndex := 0;
  LEntry := FVariables.StoreEntry(0);
  while LEntry.Map <> 0 do
  begin
    if LEntry.Map = FHost.CurrentMap then
    begin
      Move(LEntry.Args, LArguments, SizeOf(LArguments));
      StartScript(LEntry.Script, 0, LArguments, nil, nil, 0);
      if Assigned(FNewScript) then
        FNewScript.DelayCount := FHost.TicsPerSecond;
      LEntry.Map := -1;
    end;
    Inc(LIndex);
    LEntry := FVariables.StoreEntry(LIndex);
  end;
end;

procedure TAcsMachine.InitNewGame;
begin
  FVariables.ClearWorld;
end;

procedure TAcsMachine.TagFinished(ATag: Integer);
var
  LIndex: Integer;
begin
  if FHost.IsTagBusy(ATag) then
    Exit;
  for LIndex := 0 to FBehavior.ScriptCount - 1 do
    if (FBehavior.State[LIndex] = assWaitingForTag) and
      (FBehavior.WaitValue[LIndex] = ATag) then
      FBehavior.State[LIndex] := assRunning;
end;

procedure TAcsMachine.PolyobjectFinished(APolyobject: Integer);
var
  LIndex: Integer;
begin
  if FHost.IsPolyobjectBusy(APolyobject) then
    Exit;
  for LIndex := 0 to FBehavior.ScriptCount - 1 do
    if (FBehavior.State[LIndex] = assWaitingForPolyobj) and
      (FBehavior.WaitValue[LIndex] = APolyobject) then
      FBehavior.State[LIndex] := assRunning;
end;

procedure TAcsMachine.Execute(AScript: PAcsScript);
begin
  if not IsValidIndex(AScript.InfoIndex) then
  begin
    // a script of another object code (a saved game of another map): it cannot run
    Warn(Format(SWrongScriptIndex, [AScript.Number, AScript.InfoIndex]));
    FHost.ReleaseScript(AScript);
    Exit;
  end;

  if FBehavior.State[AScript.InfoIndex] = assTerminating then
  begin
    FBehavior.State[AScript.InfoIndex] := assInactive;
    ScriptFinished(AScript.Number);
    // the script that ends is this one (the old code took the script that ran before)
    FHost.ReleaseScript(AScript);
    Exit;
  end;

  if FBehavior.State[AScript.InfoIndex] <> assRunning then
    Exit;

  if AScript.DelayCount <> 0 then
  begin
    Dec(AScript.DelayCount);
    Exit;
  end;

  if FInterpreter.Run(AScript) = arrTerminated then
  begin
    FBehavior.State[AScript.InfoIndex] := assInactive;
    ScriptFinished(AScript.Number);
    FHost.ReleaseScript(AScript);
  end;
end;

end.
