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
    FProcActorDied: TMethod;
    FProcPlayerEnter: TMethod;
    FProcPlayerDied: TMethod;
    FProcCrossLine: TMethod;
    FProcShootLine: TMethod;
    FProcUseLine: TMethod;
    FProcTick: TMethod;
    FProcTimerEverySecond: TMethod;
    FProcTimerEveryMinute: TMethod;
    FProcMapStart: TMethod;
    procedure RunProc(const AProc: TMethod; const AParams: array of Integer);
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

type
  TScriptEvent = procedure of object;
  TScriptEvent1I = procedure (AParam1: Integer) of object;
  TScriptEvent2I = procedure (AParam1, AParam2: Integer) of object;
  TScriptEvent3I = procedure (AParam1, AParam2, AParam3: Integer) of object;
  TScriptEvent4I = procedure (AParam1, AParam2, AParam3, AParam4: Integer) of object;

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
  FProcActorDied.Code := nil;
  FProcPlayerEnter.Code := nil;
  FProcPlayerDied.Code := nil;
  FProcCrossLine.Code := nil;
  FProcShootLine.Code := nil;
  FProcUseLine.Code := nil;
  FProcTick.Code := nil;
  FProcTimerEverySecond.Code := nil;
  FProcTimerEveryMinute.Code := nil;
  FProcMapStart.Code := nil;
end;

procedure TScriptEvents.LinkEvents;
begin
  FProcActorDied := FExec.GetProcAsMethodN('ONACTORDIED');
  FProcPlayerEnter := FExec.GetProcAsMethodN('ONPLAYERENTER');
  FProcPlayerDied := FExec.GetProcAsMethodN('ONPLAYERDIED');
  FProcCrossLine := FExec.GetProcAsMethodN('ONCROSSLINE');
  FProcShootLine := FExec.GetProcAsMethodN('ONSHOOTLINE');
  FProcUseLine := FExec.GetProcAsMethodN('ONUSELINE');
  FProcTick := FExec.GetProcAsMethodN('ONTICK');
  FProcTimerEverySecond := FExec.GetProcAsMethodN('ONTIMEREVERYSECOND');
  FProcTimerEveryMinute := FExec.GetProcAsMethodN('ONTIMEREVERYMINUTE');
  FProcMapStart := FExec.GetProcAsMethodN('ONMAPSTART');
end;

procedure TScriptEvents.RunProc(const AProc: TMethod; const AParams: array of Integer);
var
  LExceptionProc: TPSProcRec;
  LMessage: string;
begin
  if AProc.Code = nil then
    Exit;

  try
    case Length(AParams) of
      0: TScriptEvent(AProc);
      1: TScriptEvent1I(AProc)(AParams[0]);
      2: TScriptEvent2I(AProc)(AParams[0], AParams[1]);
      3: TScriptEvent3I(AProc)(AParams[0], AParams[1], AParams[2]);
      4: TScriptEvent4I(AProc)(AParams[0], AParams[1], AParams[2], AParams[3]);
    else
      FLog.Warning(Format('TScriptEvents.RunProc(): Invalid number of parameters %d'#13#10,
        [Length(AParams)]));
      Exit;
    end;
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
