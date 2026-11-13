{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the events of the scripts                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is TScriptEvents of ps_events.pas: the interpreter and the log come      }
{  from the constructor (the interpreter was a TDoomExec, and the warnings     }
{  I_Warning).                                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Events;

interface

uses
  System.SysUtils,
  ps_runtime,
  DelphiDoom.Logging.Intf,
  DelphiDoom.ScriptHost.Events.Intf;

type
  /// <summary>Calls the procedures of event of the script that an interpreter has loaded</summary>
  TScriptEvents = class(TInterfacedObject, IScriptEvents)
  strict private
    FExec: TPSExec;
    FLog: ILog;
    FProcActorDied: Cardinal;
    FProcPlayerEnter: Cardinal;
    FProcPlayerDied: Cardinal;
    FProcCrossLine: Cardinal;
    FProcShootLine: Cardinal;
    FProcUseLine: Cardinal;
    FProcTick: Cardinal;
    FProcTimerEverySecond: Cardinal;
    FProcTimerEveryMinute: Cardinal;
    FProcMapStart: Cardinal;
    procedure RunProc(const AProc: Cardinal; const AParams: array of Integer);
  public
    /// <summary>The interpreter is not owned: it must live as long as the events</summary>
    constructor Create(const AExec: TPSExec; const ALog: ILog);
    procedure Clear;
    procedure LinkEvents;
    procedure ProcActorDied(AActor: LongWord; AKiller: LongWord);
    procedure ProcPlayerEnter(APlayerNumber: Integer);
    procedure ProcPlayerDied(APlayerNumber: Integer; AKiller: LongWord);
    procedure ProcCrossLine(AActor: LongWord; ALine: Integer; AOldSide: Integer);
    procedure ProcShootLine(AActor: LongWord; ALine: Integer; ASide: Integer);
    procedure ProcUseLine(AActor: LongWord; ALine: Integer; ASide: Integer);
    procedure ProcTick(ATick: Integer);
    procedure ProcTimerEverySecond(ASecond: Integer);
    procedure ProcTimerEveryMinute(AMinute: Integer);
    procedure ProcMapStart;
  end;

implementation

const
  MAXIMUM_PARAMETERS = 4;

{ TScriptEvents }

constructor TScriptEvents.Create(const AExec: TPSExec; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AExec) then
    raise EArgumentNilException.Create('AExec');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FExec := AExec;
  FLog := ALog;
  Clear;
end;

procedure TScriptEvents.Clear;
begin
  FProcActorDied := InvalidVal;
  FProcPlayerEnter := InvalidVal;
  FProcPlayerDied := InvalidVal;
  FProcCrossLine := InvalidVal;
  FProcShootLine := InvalidVal;
  FProcUseLine := InvalidVal;
  FProcTick := InvalidVal;
  FProcTimerEverySecond := InvalidVal;
  FProcTimerEveryMinute := InvalidVal;
  FProcMapStart := InvalidVal;
end;

procedure TScriptEvents.LinkEvents;
begin
  FProcActorDied := FExec.GetProc('ONACTORDIED');
  FProcPlayerEnter := FExec.GetProc('ONPLAYERENTER');
  FProcPlayerDied := FExec.GetProc('ONPLAYERDIED');
  FProcCrossLine := FExec.GetProc('ONCROSSLINE');
  FProcShootLine := FExec.GetProc('ONSHOOTLINE');
  FProcUseLine := FExec.GetProc('ONUSELINE');
  FProcTick := FExec.GetProc('ONTICK');
  FProcTimerEverySecond := FExec.GetProc('ONTIMEREVERYSECOND');
  FProcTimerEveryMinute := FExec.GetProc('ONTIMEREVERYMINUTE');
  FProcMapStart := FExec.GetProc('ONMAPSTART');
end;

procedure TScriptEvents.RunProc(const AProc: Cardinal; const AParams: array of Integer);
var
  LExceptionProc: TPSProcRec;
  LMessage: string;
begin
  if AProc = InvalidVal then
    Exit;

  try
    if Length(AParams) > MAXIMUM_PARAMETERS then
    begin
      FLog.Warning(Format('TScriptEvents.RunProc(): Invalid number of parameters %d'#13#10,
        [Length(AParams)]));
      Exit;
    end;
    // in Pascal and not through a native method pointer: the thunk of GetProcAsMethod does not exist at 64 bit
    FExec.RunProcHost(AParams, AProc);
  except
    on E: Exception do
    begin
      LMessage := 'Exception in script: ''' + E.Message + '''';
      LExceptionProc := FExec.GetProcNo(FExec.ExceptionProcNo);
      if LExceptionProc is TPSInternalProcRec then
        LMessage := LMessage + ' in procedure ''' + string(TPSInternalProcRec(LExceptionProc).ExportName) + '''';
      FLog.Warning('TScriptEvents.RunProc():' + LMessage);
    end;
  end;
end;

procedure TScriptEvents.ProcActorDied(AActor: LongWord; AKiller: LongWord);
begin
  RunProc(FProcActorDied, [AActor, AKiller]);
end;

procedure TScriptEvents.ProcPlayerEnter(APlayerNumber: Integer);
begin
  RunProc(FProcPlayerEnter, [APlayerNumber]);
end;

procedure TScriptEvents.ProcPlayerDied(APlayerNumber: Integer; AKiller: LongWord);
begin
  RunProc(FProcPlayerDied, [APlayerNumber, AKiller]);
end;

procedure TScriptEvents.ProcCrossLine(AActor: LongWord; ALine: Integer; AOldSide: Integer);
begin
  RunProc(FProcCrossLine, [AActor, ALine, AOldSide]);
end;

procedure TScriptEvents.ProcShootLine(AActor: LongWord; ALine: Integer; ASide: Integer);
begin
  RunProc(FProcShootLine, [AActor, ALine, ASide]);
end;

procedure TScriptEvents.ProcUseLine(AActor: LongWord; ALine: Integer; ASide: Integer);
begin
  RunProc(FProcUseLine, [AActor, ALine, ASide]);
end;

procedure TScriptEvents.ProcTick(ATick: Integer);
begin
  RunProc(FProcTick, [ATick]);
end;

procedure TScriptEvents.ProcTimerEverySecond(ASecond: Integer);
begin
  RunProc(FProcTimerEverySecond, [ASecond]);
end;

procedure TScriptEvents.ProcTimerEveryMinute(AMinute: Integer);
begin
  RunProc(FProcTimerEveryMinute, [AMinute]);
end;

procedure TScriptEvents.ProcMapStart;
begin
  RunProc(FProcMapStart, []);
end;

end.
