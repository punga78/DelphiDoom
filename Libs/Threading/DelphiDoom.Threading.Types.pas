{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - shared types and exceptions                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The work given to a worker thread: the same shape the engine always used for its jobs
  ///   (one untyped parameter, an integer result, stdcall)
  /// </summary>
  TWorkerProc = function(AParameter: Pointer): Integer; stdcall;

  /// <summary>A job for a worker: the procedure and its parameter</summary>
  TWorkerJob = record
    Proc: TWorkerProc;
    Parameter: Pointer;
    /// <summary>Makes a job; a nil AProc is a job that is skipped</summary>
    class function Make(AProc: TWorkerProc; AParameter: Pointer): TWorkerJob; static; inline;
  end;

  /// <summary>
  ///   What each thread of an iteration receives (the layout is the one the engine always
  ///   used: the jobs cast the pointer to it)
  /// </summary>
  TWorkerIterator = record
    /// <summary>The index of the thread, from 0</summary>
    Index: Integer;
    /// <summary>How many threads share the iteration</summary>
    Count: Integer;
    /// <summary>The pointer the caller gave to Iterate</summary>
    Data: Pointer;
  end;
  PWorkerIterator = ^TWorkerIterator;

  /// <summary>A background task: a procedure with no parameters</summary>
  TWorkerTaskProc = procedure;

  /// <summary>Base class of the errors of the threading library</summary>
  EThreadingException = class(Exception);

  /// <summary>
  ///   A job raised an exception on the worker thread: it is reported to whoever waits for the
  ///   job, with the class and the message of the original exception
  /// </summary>
  EWorkerJobException = class(EThreadingException)
  strict private
    FOriginalClassName: string;
    FOriginalMessage: string;
  public
    constructor Create(const AOriginalClassName, AOriginalMessage: string);
    /// <summary>The class name of the exception raised by the job</summary>
    property OriginalClassName: string read FOriginalClassName;
    /// <summary>The message of the exception raised by the job</summary>
    property OriginalMessage: string read FOriginalMessage;
  end;

implementation

const
  SJobFailed = 'A worker job raised %s: %s';

{ TWorkerJob }

class function TWorkerJob.Make(AProc: TWorkerProc; AParameter: Pointer): TWorkerJob;
begin
  Result.Proc := AProc;
  Result.Parameter := AParameter;
end;

{ EWorkerJobException }

constructor EWorkerJobException.Create(const AOriginalClassName, AOriginalMessage: string);
begin
  inherited CreateFmt(SJobFailed, [AOriginalClassName, AOriginalMessage]);
  FOriginalClassName := AOriginalClassName;
  FOriginalMessage := AOriginalMessage;
end;

end.
