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

{ EWorkerJobException }

constructor EWorkerJobException.Create(const AOriginalClassName, AOriginalMessage: string);
begin
  inherited CreateFmt(SJobFailed, [AOriginalClassName, AOriginalMessage]);
  FOriginalClassName := AOriginalClassName;
  FOriginalMessage := AOriginalMessage;
end;

end.
