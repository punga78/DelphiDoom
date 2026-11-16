{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.Factory;

interface

uses
  DelphiDoom.Threading.Intf,
  DelphiDoom.Threading.JobRunner,
  DelphiDoom.Threading.MemoryRunner,
  DelphiDoom.Threading.TaskScheduler;

type
  /// <summary>The only place that knows the classes behind the threading interfaces</summary>
  TThreadingFactory = class
  public
    /// <summary>The factory of real worker threads</summary>
    class function CreateThreadFactory: IWorkerThreadFactory; static;
    /// <summary>A factory of pools whose workers come from AThreadFactory</summary>
    class function CreatePoolFactory(const AThreadFactory: IWorkerThreadFactory): IWorkerPoolFactory; static;
    /// <summary>A pool of ACount real worker threads</summary>
    class function CreatePool(ACount: Integer): IWorkerPool; static;
    /// <summary>The runner of MT_Execute and MT_Iterate (a class: it is called every frame)</summary>
    class function CreateJobRunner(const APool: IWorkerPool; const AMessages: IWorkerMessages;
      ACpuCount: Integer): TWorkerJobRunner; static;
    /// <summary>The runner of the parallel zero, fill and copy of memory</summary>
    class function CreateMemoryRunner(const APool: IWorkerPool;
      const AOps: IWorkerMemoryOps): TWorkerMemoryRunner; static;
    /// <summary>The scheduler of the background tasks, one slot per worker of the pool</summary>
    class function CreateTaskScheduler(const APool: IWorkerPool): TWorkerTaskScheduler; static;
  end;

implementation

uses
  DelphiDoom.Threading.ThreadFactory, DelphiDoom.Threading.PoolFactory;

{ TThreadingFactory }

class function TThreadingFactory.CreateThreadFactory: IWorkerThreadFactory;
begin
  Result := TWorkerThreadFactory.Create;
end;

class function TThreadingFactory.CreatePoolFactory(
  const AThreadFactory: IWorkerThreadFactory): IWorkerPoolFactory;
begin
  Result := TWorkerPoolFactory.Create(AThreadFactory);
end;

class function TThreadingFactory.CreatePool(ACount: Integer): IWorkerPool;
begin
  Result := CreatePoolFactory(CreateThreadFactory).CreatePool(ACount);
end;

class function TThreadingFactory.CreateJobRunner(const APool: IWorkerPool;
  const AMessages: IWorkerMessages; ACpuCount: Integer): TWorkerJobRunner;
begin
  Result := TWorkerJobRunner.Create(APool, AMessages, ACpuCount);
end;

class function TThreadingFactory.CreateMemoryRunner(const APool: IWorkerPool;
  const AOps: IWorkerMemoryOps): TWorkerMemoryRunner;
begin
  Result := TWorkerMemoryRunner.Create(APool, AOps);
end;

class function TThreadingFactory.CreateTaskScheduler(const APool: IWorkerPool): TWorkerTaskScheduler;
begin
  Result := TWorkerTaskScheduler.Create(APool);
end;

end.
