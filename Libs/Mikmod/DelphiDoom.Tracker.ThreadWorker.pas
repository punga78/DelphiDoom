{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - runs the playback in a thread                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.ThreadWorker;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiDoom.Tracker.Output.Intf;

type
  /// <summary>A new thread for each piece of work; it waits for the last one when destroyed</summary>
  TTrackerThreadWorker = class(TInterfacedObject, ITrackerWorker)
  strict private
    FThread: TThread;
  public
    destructor Destroy; override;
    procedure Start(const AWork: TProc);
    procedure WaitFor;
    function IsRunning: Boolean;
  end;

implementation

{ TTrackerThreadWorker }

destructor TTrackerThreadWorker.Destroy;
begin
  WaitFor;
  inherited Destroy;
end;

procedure TTrackerThreadWorker.Start(const AWork: TProc);
begin
  WaitFor;
  FThread := TThread.CreateAnonymousThread(AWork);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

procedure TTrackerThreadWorker.WaitFor;
begin
  if not Assigned(FThread) then
    Exit;
  FThread.WaitFor;
  FreeAndNil(FThread);
end;

function TTrackerThreadWorker.IsRunning: Boolean;
begin
  Result := Assigned(FThread) and not FThread.Finished;
end;

end.
