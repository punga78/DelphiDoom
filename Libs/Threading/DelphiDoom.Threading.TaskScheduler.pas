{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - background tasks on a fixed set of slots    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.TaskScheduler;

interface

uses
  DelphiDoom.Threading.Intf,
  DelphiDoom.Threading.Types;

type
  /// <summary>One slot of the scheduler: the task waiting or running, and its number</summary>
  TWorkerTaskSlot = record
    Id: Integer;
    Proc: TWorkerTaskProc;
  end;
  PWorkerTaskSlot = ^TWorkerTaskSlot;

  /// <summary>
  ///   The MT_ScheduleTask family of the engine: a task is put in a free slot (one per worker of
  ///   the pool), started later with ExecutePending on the worker of its slot and waited for with
  ///   Wait. When no slot is free the task runs at once on the calling thread and the answer is
  ///   -1. The worker frees the slot when the task is over.
  /// </summary>
  TWorkerTaskScheduler = class sealed
  strict private
    FPool: IWorkerPool;
    FSlots: TArray<TWorkerTaskSlot>;
  public
    /// <summary>One slot for each worker of APool. EArgumentNilException if it is nil</summary>
    constructor Create(const APool: IWorkerPool);
    /// <summary>
    ///   Takes the first free slot and gives its number (the task is not started); with no free
    ///   slot runs AProc here and gives -1
    /// </summary>
    function Schedule(AProc: TWorkerTaskProc): Integer;
    /// <summary>Starts the task of the slot (nothing if the slot is free or out of range)</summary>
    procedure ExecutePending(AId: Integer);
    /// <summary>Waits for the task of the slot (nothing if the slot is free or out of range)</summary>
    procedure Wait(AId: Integer);
    /// <summary>Waits for every task that is in a slot</summary>
    procedure WaitAll;
    /// <summary>How many slots there are</summary>
    function SlotCount: Integer;
  end;

implementation

uses
  System.SysUtils;

function TaskJob(AParameter: Pointer): Integer; stdcall;
var
  LSlot: PWorkerTaskSlot;
begin
  LSlot := AParameter;
  LSlot.Proc;
  Result := LSlot.Id;
  LSlot.Id := -1;
  LSlot.Proc := nil;
end;

{ TWorkerTaskScheduler }

constructor TWorkerTaskScheduler.Create(const APool: IWorkerPool);
begin
  inherited Create;
  if not Assigned(APool) then
    raise EArgumentNilException.Create('APool');
  FPool := APool;
  SetLength(FSlots, APool.Count);
end;

function TWorkerTaskScheduler.SlotCount: Integer;
begin
  Result := Length(FSlots);
end;

function TWorkerTaskScheduler.Schedule(AProc: TWorkerTaskProc): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FSlots) do
    if not Assigned(FSlots[LIndex].Proc) then
    begin
      FSlots[LIndex].Id := LIndex;
      FSlots[LIndex].Proc := AProc;
      Exit(LIndex);
    end;
  AProc;
  Result := -1;
end;

procedure TWorkerTaskScheduler.ExecutePending(AId: Integer);
begin
  if (AId < 0) or (AId >= Length(FSlots)) then
    Exit;
  if Assigned(FSlots[AId].Proc) then
    FPool[AId].Submit(TaskJob, @FSlots[AId]);
end;

procedure TWorkerTaskScheduler.Wait(AId: Integer);
begin
  if (AId < 0) or (AId >= Length(FSlots)) then
    Exit;
  if Assigned(FSlots[AId].Proc) then
    FPool[AId].Wait;
end;

procedure TWorkerTaskScheduler.WaitAll;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FSlots) do
    if Assigned(FSlots[LIndex].Proc) then
      FPool[LIndex].Wait;
end;

end.
