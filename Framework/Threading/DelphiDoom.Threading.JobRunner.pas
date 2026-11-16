{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - run a set of jobs and wait for them         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.JobRunner;

interface

uses
  DelphiDoom.Threading.Intf,
  DelphiDoom.Threading.Types;

type
  /// <summary>
  ///   Runs a set of jobs at once: the first one on the calling thread, each other non nil one
  ///   on a worker of the pool (worker 0, 1, ... in the order given), then waits for the
  ///   workers. This is MT_Execute and MT_Iterate of the engine. A call made while another is
  ///   running is a misuse (reported to the messages). It is used once or a few times per
  ///   frame, never per element: the class is sealed and has no virtual methods.
  /// </summary>
  TWorkerJobRunner = class sealed
  strict private
    const
      /// <summary>The most threads an iteration can have (the pool plus the caller)</summary>
      MaxIterationThreads = 65;
  strict private
    FPool: IWorkerPool;
    FMessages: IWorkerMessages;
    FCpuCount: Integer;
    FBusy: Boolean;
    procedure Enter(const ARecursiveMessage: string);
  public
    /// <summary>
    ///   APool gives the workers (64 in the engine), ACpuCount is how many threads an iteration
    ///   uses when the caller does not say. EArgumentNilException if a parameter is nil
    /// </summary>
    constructor Create(const APool: IWorkerPool; const AMessages: IWorkerMessages; ACpuCount: Integer);
    /// <summary>
    ///   AJobs[0] runs here; the other jobs with a procedure go to the workers. A nil AJobs[0]
    ///   is reported as a warning (the workers still run and are waited for)
    /// </summary>
    procedure Execute(const AJobs: array of TWorkerJob);
    /// <summary>
    ///   Runs AFunc on AThreadCount threads (the number of CPUs if it is 0 or less; at least 2
    ///   and at most 65), each with its TWorkerIterator; the last one runs here
    /// </summary>
    procedure Iterate(AFunc: TWorkerProc; AData: Pointer; AThreadCount: Integer);
    /// <summary>True while a call is running</summary>
    property Busy: Boolean read FBusy;
  end;

implementation

uses
  System.SysUtils;

const
  SRecursiveExecute = 'MT_Execute(): Invalid recoursive call.'#13#10;
  SRecursiveIterate = 'MT_Iterate(): Invalid recoursive call.'#13#10;
  SNullApplicationJob = 'MT_Execute(): Called with null application thread function.'#13#10;

{ TWorkerJobRunner }

constructor TWorkerJobRunner.Create(const APool: IWorkerPool; const AMessages: IWorkerMessages;
  ACpuCount: Integer);
begin
  inherited Create;
  if not Assigned(APool) then
    raise EArgumentNilException.Create('APool');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  FPool := APool;
  FMessages := AMessages;
  FCpuCount := ACpuCount;
end;

procedure TWorkerJobRunner.Enter(const ARecursiveMessage: string);
begin
  if FBusy then
    FMessages.Error(ARecursiveMessage);
  FBusy := True;
end;

procedure TWorkerJobRunner.Execute(const AJobs: array of TWorkerJob);
var
  LStarted: Integer;
  LIndex: Integer;
begin
  Enter(SRecursiveExecute);
  try
    LStarted := 0;
    for LIndex := 1 to High(AJobs) do
      if Assigned(AJobs[LIndex].Proc) then
      begin
        FPool[LStarted].Submit(AJobs[LIndex].Proc, AJobs[LIndex].Parameter);
        Inc(LStarted);
      end;
    if (Length(AJobs) = 0) or not Assigned(AJobs[0].Proc) then
      FMessages.Warning(SNullApplicationJob)
    else
      AJobs[0].Proc(AJobs[0].Parameter);
    for LIndex := 0 to LStarted - 1 do
      FPool[LIndex].Wait;
  finally
    FBusy := False;
  end;
end;

procedure TWorkerJobRunner.Iterate(AFunc: TWorkerProc; AData: Pointer; AThreadCount: Integer);
var
  LParameters: array[0..MaxIterationThreads - 1] of TWorkerIterator;
  LIndex: Integer;
  LThreads: Integer;
begin
  Enter(SRecursiveIterate);
  try
    if AThreadCount > 0 then
      LThreads := AThreadCount
    else
      LThreads := FCpuCount;
    if LThreads < 2 then
      LThreads := 2
    else if LThreads > MaxIterationThreads then
      LThreads := MaxIterationThreads;

    for LIndex := 0 to LThreads - 2 do
    begin
      LParameters[LIndex].Index := LIndex;
      LParameters[LIndex].Count := LThreads;
      LParameters[LIndex].Data := AData;
      FPool[LIndex].Submit(AFunc, @LParameters[LIndex]);
    end;
    LParameters[LThreads - 1].Index := LThreads - 1;
    LParameters[LThreads - 1].Count := LThreads;
    LParameters[LThreads - 1].Data := AData;
    AFunc(@LParameters[LThreads - 1]);

    for LIndex := 0 to LThreads - 2 do
      FPool[LIndex].Wait;
  finally
    FBusy := False;
  end;
end;

end.
