{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - the contract                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.Intf;

interface

uses
  DelphiDoom.Threading.Types;

type
  /// <summary>
  ///   One thread that waits for a job, runs it and goes back to waiting. The wait is on
  ///   events (no busy loops), the thread is never suspended, and closing it always waits for
  ///   the thread to leave. A worker may be driven by several threads: Submit calls are
  ///   serialised, and each one starts only after the previous job is over.
  /// </summary>
  IWorkerThread = interface
    ['{6F0B3C52-91E4-4C1B-8D7A-2E5C0A9D7B31}']
    /// <summary>
    ///   Gives a job to the thread and returns at once. If the previous job is still running
    ///   it waits for it first (and reports its exception, if it had one).
    ///   EThreadingException if the worker is closed or AProc is nil.
    /// </summary>
    procedure Submit(AProc: TWorkerProc; AParameter: Pointer);
    /// <summary>
    ///   Waits until the thread is idle (returns at once if it is). If the last job raised an
    ///   exception it is raised here, as an EWorkerJobException, once.
    /// </summary>
    procedure Wait;
    /// <summary>True when no job is running</summary>
    function IsIdle: Boolean;
    /// <summary>The value returned by the last job that finished</summary>
    function LastResult: Integer;
    /// <summary>
    ///   Waits for the running job, stops the thread and waits for it to leave. It can be
    ///   called more than once; after it Submit raises EThreadingException
    /// </summary>
    procedure Shutdown;
  end;

  /// <summary>A fixed set of workers, created together and closed together</summary>
  IWorkerPool = interface
    ['{A2D94E17-5B0C-4F6E-B83D-70C1E4F52A96}']
    function GetCount: Integer;
    function GetWorker(AIndex: Integer): IWorkerThread;
    /// <summary>Waits for every worker; the first job exception is raised after the last wait</summary>
    procedure WaitAll;
    /// <summary>Closes every worker (see IWorkerThread.Shutdown)</summary>
    procedure Shutdown;
    /// <summary>How many workers the pool has</summary>
    property Count: Integer read GetCount;
    /// <summary>A worker by index (EArgumentOutOfRangeException outside 0..Count-1)</summary>
    property Workers[AIndex: Integer]: IWorkerThread read GetWorker; default;
  end;

  /// <summary>
  ///   Where the runners report a misuse. Error does not return in the engine (it stops the
  ///   program); a fake may raise
  /// </summary>
  IWorkerMessages = interface
    ['{5B1E84D3-0C72-4A9F-B6E8-3D40F1A7C592}']
    procedure Warning(const AText: string);
    procedure Error(const AText: string);
  end;

  /// <summary>
  ///   The memory primitives the parallel fill and copy split among threads. The engine gives
  ///   its own (d_delphi), so a chunk is filled exactly as the single thread fills it
  /// </summary>
  IWorkerMemoryOps = interface
    ['{E7A03C58-61D4-4B2F-8F19-A5D6C0B93E74}']
    procedure Zero(ADest: Pointer; ACount: Integer);
    /// <summary>ACount bytes set to AValue</summary>
    procedure Fill(ADest: Pointer; AValue, ACount: Integer);
    /// <summary>ACount 32 bit integers set to AValue</summary>
    procedure FillInteger(ADest: Pointer; AValue, ACount: Integer);
    procedure Copy(ADest, ASource: Pointer; ACount: Integer);
  end;

  /// <summary>Makes workers; the tests give a fake one</summary>
  IWorkerThreadFactory = interface
    ['{3E8F1A64-D2B7-4A09-9C45-B6E70D18F3A2}']
    function CreateWorker: IWorkerThread;
  end;

  /// <summary>Makes pools</summary>
  IWorkerPoolFactory = interface
    ['{C7B52D09-4E61-4F38-A1D0-5993E2B8C614}']
    /// <summary>A pool of ACount workers (0 is a valid, empty pool)</summary>
    function CreatePool(ACount: Integer): IWorkerPool;
  end;

implementation

end.
