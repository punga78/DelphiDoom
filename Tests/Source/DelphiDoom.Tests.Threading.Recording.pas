{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - workers that run at once       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.Recording;

interface

uses
  System.Classes, DelphiDoom.Threading.Intf, DelphiDoom.Threading.Types;

type
  /// <summary>
  ///   A worker that runs the job inside Submit, on the calling thread, and writes what happens
  ///   in a list ("S3" = job given to worker 3, "W3" = worker 3 waited for): the order of the
  ///   events is then the same on every run, so the old and the new code can be compared
  /// </summary>
  TSyncWorker = class(TInterfacedObject, IWorkerThread)
  strict private
    FLog: TStrings;
    FIndex: Integer;
    FLastResult: Integer;
  public
    constructor Create(ALog: TStrings; AIndex: Integer);
    procedure Submit(AProc: TWorkerProc; AParameter: Pointer);
    procedure Wait;
    function IsIdle: Boolean;
    function LastResult: Integer;
    procedure Shutdown;
  end;

  /// <summary>Makes TSyncWorker numbered from 0</summary>
  TSyncWorkerFactory = class(TInterfacedObject, IWorkerThreadFactory)
  strict private
    FLog: TStrings;
    FCreated: Integer;
  public
    constructor Create(ALog: TStrings);
    function CreateWorker: IWorkerThread;
  end;

  /// <summary>Writes the messages in a list ("W:" warning, "E:" error); an error raises</summary>
  TRecordingMessages = class(TInterfacedObject, IWorkerMessages)
  strict private
    FLog: TStrings;
  public
    constructor Create(ALog: TStrings);
    procedure Warning(const AText: string);
    procedure Error(const AText: string);
  end;

  /// <summary>
  ///   Memory primitives that write what they are asked ("Z offset size", "F offset value size",
  ///   "I offset value size", "C offset source size"): the pointers are only numbers from
  ///   ABase, nothing is touched
  /// </summary>
  TRecordingMemoryOps = class(TInterfacedObject, IWorkerMemoryOps)
  strict private
    FLog: TStrings;
    FBase: NativeInt;
  public
    constructor Create(ALog: TStrings; ABase: NativeInt);
    procedure Zero(ADest: Pointer; ACount: Integer);
    procedure Fill(ADest: Pointer; AValue, ACount: Integer);
    procedure FillInteger(ADest: Pointer; AValue, ACount: Integer);
    procedure Copy(ADest, ASource: Pointer; ACount: Integer);
  end;

var
  /// <summary>Where RecordJob writes</summary>
  GJobLog: TStrings;

/// <summary>The lines of the list on one line, separated by "|" (to compare logs)</summary>
function JoinLog(ALog: TStrings): string;

/// <summary>The lines of the list without the waits of the workers from AFirstIdle on ("W5", "W6"...)</summary>
function JoinLogWithoutIdleWaits(ALog: TStrings; AFirstIdle: Integer): string;

/// <summary>A pool of ACount TSyncWorker that write in ALog</summary>
function CreateSyncPool(ALog: TStrings; ACount: Integer): IWorkerPool;

/// <summary>
///   A job that reads its parameter as a TWorkerIterator and writes "I index/count/data" in
///   GJobLog (the old record has the same layout)
/// </summary>
function IterationJob(AParameter: Pointer): Integer; stdcall;

/// <summary>A job that writes "J" and its parameter as a number in GJobLog</summary>
function RecordJob(AParameter: Pointer): Integer; stdcall;

/// <summary>A job that writes "T" and its parameter as a number in GJobLog (for the tasks)</summary>
procedure RecordTask;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.PoolFactory;

function JoinLog(ALog: TStrings): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to ALog.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + '|';
    Result := Result + ALog[LIndex];
  end;
end;

function JoinLogWithoutIdleWaits(ALog: TStrings; AFirstIdle: Integer): string;
var
  LIndex: Integer;
  LLine: string;
  LKept: TStringList;
begin
  LKept := TStringList.Create;
  try
    for LIndex := 0 to ALog.Count - 1 do
    begin
      LLine := ALog[LIndex];
      if (Length(LLine) > 1) and (LLine[1] = 'W') and CharInSet(LLine[2], ['0'..'9']) and
        (StrToInt(Copy(LLine, 2, MaxInt)) >= AFirstIdle) then
        Continue;
      LKept.Add(LLine);
    end;
    Result := JoinLog(LKept);
  finally
    LKept.Free;
  end;
end;

function CreateSyncPool(ALog: TStrings; ACount: Integer): IWorkerPool;
begin
  Result := TWorkerPoolFactory.Create(TSyncWorkerFactory.Create(ALog)).CreatePool(ACount);
end;

function IterationJob(AParameter: Pointer): Integer;
begin
  with PWorkerIterator(AParameter)^ do
    GJobLog.Add(Format('I%d/%d/%d', [Index, Count, NativeInt(Data)]));
  Result := 3;
end;

function RecordJob(AParameter: Pointer): Integer;
begin
  GJobLog.Add('J' + IntToStr(NativeInt(AParameter)));
  Result := 7;
end;

procedure RecordTask;
begin
  GJobLog.Add('T');
end;

{ TSyncWorker }

constructor TSyncWorker.Create(ALog: TStrings; AIndex: Integer);
begin
  inherited Create;
  FLog := ALog;
  FIndex := AIndex;
end;

procedure TSyncWorker.Submit(AProc: TWorkerProc; AParameter: Pointer);
begin
  FLog.Add('S' + IntToStr(FIndex));
  FLastResult := AProc(AParameter);
end;

procedure TSyncWorker.Wait;
begin
  FLog.Add('W' + IntToStr(FIndex));
end;

function TSyncWorker.IsIdle: Boolean;
begin
  Result := True;
end;

function TSyncWorker.LastResult: Integer;
begin
  Result := FLastResult;
end;

procedure TSyncWorker.Shutdown;
begin
end;

{ TSyncWorkerFactory }

constructor TSyncWorkerFactory.Create(ALog: TStrings);
begin
  inherited Create;
  FLog := ALog;
end;

function TSyncWorkerFactory.CreateWorker: IWorkerThread;
begin
  Result := TSyncWorker.Create(FLog, FCreated);
  Inc(FCreated);
end;

{ TRecordingMessages }

constructor TRecordingMessages.Create(ALog: TStrings);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TRecordingMessages.Warning(const AText: string);
begin
  FLog.Add('W:' + Trim(AText));
end;

procedure TRecordingMessages.Error(const AText: string);
begin
  FLog.Add('E:' + Trim(AText));
  raise EThreadingException.Create(Trim(AText));
end;

{ TRecordingMemoryOps }

constructor TRecordingMemoryOps.Create(ALog: TStrings; ABase: NativeInt);
begin
  inherited Create;
  FLog := ALog;
  FBase := ABase;
end;

procedure TRecordingMemoryOps.Zero(ADest: Pointer; ACount: Integer);
begin
  FLog.Add(Format('Z %d %d', [NativeInt(ADest) - FBase, ACount]));
end;

procedure TRecordingMemoryOps.Fill(ADest: Pointer; AValue, ACount: Integer);
begin
  FLog.Add(Format('F %d %d %d', [NativeInt(ADest) - FBase, AValue, ACount]));
end;

procedure TRecordingMemoryOps.FillInteger(ADest: Pointer; AValue, ACount: Integer);
begin
  FLog.Add(Format('I %d %d %d', [NativeInt(ADest) - FBase, AValue, ACount]));
end;

procedure TRecordingMemoryOps.Copy(ADest, ASource: Pointer; ACount: Integer);
begin
  FLog.Add(Format('C %d %d %d', [NativeInt(ADest) - FBase, NativeInt(ASource) - FBase, ACount]));
end;

end.
