//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  MultiThreading Utility functions: a facade over the runners of Libs\Threading
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit mt_utils;

interface

uses
  d_delphi,
  i_threads,
  DelphiDoom.Threading.Intf;

//==============================================================================
//
// MT_ConfigureThreads
//
// Gives the factory of pools, where the runners report a misuse and the memory
// primitives (composition root); MT_Init needs them
//
//==============================================================================
procedure MT_ConfigureThreads(const AFactory: IWorkerPoolFactory;
  const AMessages: IWorkerMessages; const AMemory: IWorkerMemoryOps);

//==============================================================================
//
// MT_Init
//
//==============================================================================
procedure MT_Init;

//==============================================================================
//
// MT_ShutDown
//
//==============================================================================
procedure MT_ShutDown;

//==============================================================================
//
// MT_ZeroMemory
//
//==============================================================================
procedure MT_ZeroMemory(const dest0: pointer;
  const count0: integer; threadsuse: integer = 0);

//==============================================================================
//
// MT_memset
//
//==============================================================================
procedure MT_memset(const dest0: pointer; const val: integer;
  const count0: integer; threadsuse: integer = 0);

//==============================================================================
//
// MT_memseti
//
//==============================================================================
procedure MT_memseti(const dest0: pointer; const val: integer;
  const count0: integer; threadsuse: integer = 0);

//==============================================================================
//
// MT_memcpy
//
//==============================================================================
procedure MT_memcpy(const dest0: pointer; const src0: pointer;
  const count0: integer; threadsuse: integer = 0);

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t = nil; const parms2: pointer = nil
  ); overload;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t = nil; const parms4: pointer = nil
  ); overload;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t = nil; const parms6: pointer = nil
  ); overload;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t = nil; const parms8: pointer = nil
  ); overload;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t = nil; const parms10: pointer = nil;
  const func11: threadfunc_t = nil; const parms11: pointer = nil;
  const func12: threadfunc_t = nil; const parms12: pointer = nil
  ); overload;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t; const parms10: pointer;
  const func11: threadfunc_t; const parms11: pointer;
  const func12: threadfunc_t; const parms12: pointer;
  const func13: threadfunc_t; const parms13: pointer;
  const func14: threadfunc_t = nil; const parms14: pointer = nil;
  const func15: threadfunc_t = nil; const parms15: pointer = nil;
  const func16: threadfunc_t = nil; const parms16: pointer = nil;
  const func17: threadfunc_t = nil; const parms17: pointer = nil
  ); overload;

procedure MT_Execute4(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer
  );

procedure MT_Execute6(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer
  );

procedure MT_Execute8(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer
  );

procedure MT_Execute12(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t; const parms10: pointer;
  const func11: threadfunc_t; const parms11: pointer;
  const func12: threadfunc_t; const parms12: pointer
  );

procedure MT_Execute16(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t; const parms10: pointer;
  const func11: threadfunc_t; const parms11: pointer;
  const func12: threadfunc_t; const parms12: pointer;
  const func13: threadfunc_t; const parms13: pointer;
  const func14: threadfunc_t; const parms14: pointer;
  const func15: threadfunc_t; const parms15: pointer;
  const func16: threadfunc_t; const parms16: pointer
  );

type
  mt_range_t = record
    start, finish: integer;
  end;

  mt_range_p = ^mt_range_t;

type
  iterator_t = record
    idx: integer;
    numidxs: integer;
    data: pointer;
  end;
  iterator_p = ^iterator_t;

//==============================================================================
//
// MT_Iterate
//
//==============================================================================
procedure MT_Iterate(const func: threadfunc_t; const data: pointer;
  const nthreads: integer = 0);

//==============================================================================
// MT_ScheduleTask
//
// Background tasks
//
//==============================================================================
function MT_ScheduleTask(const proc: PProcedure): integer;

//==============================================================================
//
// MT_ExecutePendingTask
//
//==============================================================================
procedure MT_ExecutePendingTask(const id: integer);

//==============================================================================
//
// MT_WaitTask
//
//==============================================================================
procedure MT_WaitTask(const id: integer);

//==============================================================================
//
// MT_WaitTasks
//
//==============================================================================
procedure MT_WaitTasks;

// JVAL: Execute code threads
const
  NUMEXECTHREADS = 64;

implementation

uses
  System.SysUtils,
  DelphiDoom.Threading.Types,
  DelphiDoom.Threading.JobRunner,
  DelphiDoom.Threading.MemoryRunner,
  DelphiDoom.Threading.TaskScheduler,
  DelphiDoom.Threading.Factory,
  i_system;

// JVAL: General purpose threads
const
  MAXGPTHREADS = 16;

// JVAL: Tasks
const
  NUMTASKTHREADS = 8;

// The runners of Libs\Threading: the job runner (MT_Execute, MT_Iterate), the memory
// runner (MT_memXXX) and the task scheduler. They exist between MT_Init and MT_ShutDown.
var
  mt_jobs: TWorkerJobRunner = nil;
  mt_memory: TWorkerMemoryRunner = nil;
  mt_tasks: TWorkerTaskScheduler = nil;

var
  poolfactory: IWorkerPoolFactory = nil;
  threadmessages: IWorkerMessages = nil;
  threadmemory: IWorkerMemoryOps = nil;

//==============================================================================
//
// MT_ConfigureThreads
//
//==============================================================================
procedure MT_ConfigureThreads(const AFactory: IWorkerPoolFactory;
  const AMessages: IWorkerMessages; const AMemory: IWorkerMemoryOps);
begin
  poolfactory := AFactory;
  threadmessages := AMessages;
  threadmemory := AMemory;
end;

//==============================================================================
//
// MT_Runner
//
//==============================================================================
function MT_Runner: TWorkerJobRunner;
begin
  if mt_jobs = nil then
    I_Error('MT_Execute(): Threads are not initialized');
  result := mt_jobs;
end;

//==============================================================================
//
// MT_ZeroMemory
//
//==============================================================================
procedure MT_ZeroMemory(const dest0: pointer;
  const count0: integer; threadsuse: integer = 0);
begin
  if mt_memory = nil then
    ZeroMemory(dest0, count0)
  else
    mt_memory.ZeroMemory(dest0, count0, threadsuse);
end;

//==============================================================================
//
// MT_memset
//
//==============================================================================
procedure MT_memset(const dest0: pointer; const val: integer;
  const count0: integer; threadsuse: integer = 0);
begin
  if mt_memory = nil then
    memset(dest0, val, count0)
  else
    mt_memory.Fill(dest0, val, count0, threadsuse);
end;

//==============================================================================
//
// MT_memseti
//
//==============================================================================
procedure MT_memseti(const dest0: pointer; const val: integer;
  const count0: integer; threadsuse: integer = 0);
begin
  if mt_memory = nil then
    memseti(dest0, val, count0)
  else
    mt_memory.FillInteger(dest0, val, count0, threadsuse);
end;

//==============================================================================
//
// MT_memcpy
//
//==============================================================================
procedure MT_memcpy(const dest0: pointer; const src0: pointer;
  const count0: integer; threadsuse: integer = 0);
begin
  if mt_memory = nil then
    memcpy(dest0, src0, count0)
  else
    mt_memory.Copy(dest0, src0, count0, threadsuse);
end;

//==============================================================================
//
// MT_Init
//
//==============================================================================
procedure MT_Init;
var
  numgpthreads: integer;
  numcpus: integer;
  gp_threads: IWorkerPool;
  exec_threads: IWorkerPool;
  task_threads: IWorkerPool;
begin
  if not Assigned(poolfactory) then
    I_Error('MT_Init(): Threads are not configured');
  numcpus := I_GetNumCPUs;
  numgpthreads := numcpus;
  if numgpthreads < 2 then
    numgpthreads := 2;
  if numgpthreads > MAXGPTHREADS then
    numgpthreads := MAXGPTHREADS;
  gp_threads := poolfactory.CreatePool(numgpthreads);
  exec_threads := poolfactory.CreatePool(NUMEXECTHREADS);
  task_threads := poolfactory.CreatePool(NUMTASKTHREADS);
  mt_memory := TThreadingFactory.CreateMemoryRunner(gp_threads, threadmemory);
  mt_jobs := TThreadingFactory.CreateJobRunner(exec_threads, threadmessages, numcpus);
  mt_tasks := TThreadingFactory.CreateTaskScheduler(task_threads);
end;

//==============================================================================
//
// MT_ShutDown
//
// Releasing a pool waits for its running jobs and for its threads to leave
//
//==============================================================================
procedure MT_ShutDown;
begin
  FreeAndNil(mt_memory);
  FreeAndNil(mt_jobs);
  FreeAndNil(mt_tasks);
end;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t = nil; const parms2: pointer = nil
  ); overload;
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2)
    ]);
end;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t = nil; const parms4: pointer = nil
  ); overload;
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4)
    ]);
end;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t = nil; const parms6: pointer = nil
  ); overload;
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6)
    ]);
end;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t = nil; const parms8: pointer = nil
  ); overload;
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6),
    TWorkerJob.Make(func7, parms7),
    TWorkerJob.Make(func8, parms8)
    ]);
end;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t = nil; const parms10: pointer = nil;
  const func11: threadfunc_t = nil; const parms11: pointer = nil;
  const func12: threadfunc_t = nil; const parms12: pointer = nil
  ); overload;
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6),
    TWorkerJob.Make(func7, parms7),
    TWorkerJob.Make(func8, parms8),
    TWorkerJob.Make(func9, parms9),
    TWorkerJob.Make(func10, parms10),
    TWorkerJob.Make(func11, parms11),
    TWorkerJob.Make(func12, parms12)
    ]);
end;

procedure MT_Execute(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t; const parms10: pointer;
  const func11: threadfunc_t; const parms11: pointer;
  const func12: threadfunc_t; const parms12: pointer;
  const func13: threadfunc_t; const parms13: pointer;
  const func14: threadfunc_t = nil; const parms14: pointer = nil;
  const func15: threadfunc_t = nil; const parms15: pointer = nil;
  const func16: threadfunc_t = nil; const parms16: pointer = nil;
  const func17: threadfunc_t = nil; const parms17: pointer = nil
  ); overload;
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6),
    TWorkerJob.Make(func7, parms7),
    TWorkerJob.Make(func8, parms8),
    TWorkerJob.Make(func9, parms9),
    TWorkerJob.Make(func10, parms10),
    TWorkerJob.Make(func11, parms11),
    TWorkerJob.Make(func12, parms12),
    TWorkerJob.Make(func13, parms13),
    TWorkerJob.Make(func14, parms14),
    TWorkerJob.Make(func15, parms15),
    TWorkerJob.Make(func16, parms16),
    TWorkerJob.Make(func17, parms17)
    ]);
end;

procedure MT_Execute4(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer
  );
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4)
    ]);
end;

procedure MT_Execute6(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer
  );
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6)
    ]);
end;

procedure MT_Execute8(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer
  );
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6),
    TWorkerJob.Make(func7, parms7),
    TWorkerJob.Make(func8, parms8)
    ]);
end;

procedure MT_Execute12(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t; const parms10: pointer;
  const func11: threadfunc_t; const parms11: pointer;
  const func12: threadfunc_t; const parms12: pointer
  );
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6),
    TWorkerJob.Make(func7, parms7),
    TWorkerJob.Make(func8, parms8),
    TWorkerJob.Make(func9, parms9),
    TWorkerJob.Make(func10, parms10),
    TWorkerJob.Make(func11, parms11),
    TWorkerJob.Make(func12, parms12)
    ]);
end;

procedure MT_Execute16(
  const func1: threadfunc_t; const parms1: pointer;
  const func2: threadfunc_t; const parms2: pointer;
  const func3: threadfunc_t; const parms3: pointer;
  const func4: threadfunc_t; const parms4: pointer;
  const func5: threadfunc_t; const parms5: pointer;
  const func6: threadfunc_t; const parms6: pointer;
  const func7: threadfunc_t; const parms7: pointer;
  const func8: threadfunc_t; const parms8: pointer;
  const func9: threadfunc_t; const parms9: pointer;
  const func10: threadfunc_t; const parms10: pointer;
  const func11: threadfunc_t; const parms11: pointer;
  const func12: threadfunc_t; const parms12: pointer;
  const func13: threadfunc_t; const parms13: pointer;
  const func14: threadfunc_t; const parms14: pointer;
  const func15: threadfunc_t; const parms15: pointer;
  const func16: threadfunc_t; const parms16: pointer
  );
begin
  MT_Runner.Execute([
    TWorkerJob.Make(func1, parms1),
    TWorkerJob.Make(func2, parms2),
    TWorkerJob.Make(func3, parms3),
    TWorkerJob.Make(func4, parms4),
    TWorkerJob.Make(func5, parms5),
    TWorkerJob.Make(func6, parms6),
    TWorkerJob.Make(func7, parms7),
    TWorkerJob.Make(func8, parms8),
    TWorkerJob.Make(func9, parms9),
    TWorkerJob.Make(func10, parms10),
    TWorkerJob.Make(func11, parms11),
    TWorkerJob.Make(func12, parms12),
    TWorkerJob.Make(func13, parms13),
    TWorkerJob.Make(func14, parms14),
    TWorkerJob.Make(func15, parms15),
    TWorkerJob.Make(func16, parms16)
    ]);
end;

//==============================================================================
//
// MT_Iterate
//
//==============================================================================
procedure MT_Iterate(const func: threadfunc_t; const data: pointer;
  const nthreads: integer = 0);
begin
  MT_Runner.Iterate(func, data, nthreads);
end;

//==============================================================================
//
// MT_ScheduleTask
//
//==============================================================================
function MT_ScheduleTask(const proc: PProcedure): integer;
begin
  if mt_tasks = nil then
  begin
    proc;
    result := -1;
  end
  else
    result := mt_tasks.Schedule(proc);
end;

//==============================================================================
//
// MT_ExecutePendingTask
//
//==============================================================================
procedure MT_ExecutePendingTask(const id: integer);
begin
  if mt_tasks <> nil then
    mt_tasks.ExecutePending(id);
end;

//==============================================================================
//
// MT_WaitTask
//
//==============================================================================
procedure MT_WaitTask(const id: integer);
begin
  if mt_tasks <> nil then
    mt_tasks.Wait(id);
end;

//==============================================================================
//
// MT_WaitTasks
//
//==============================================================================
procedure MT_WaitTasks;
begin
  if mt_tasks <> nil then
    mt_tasks.WaitAll;
end;

end.
