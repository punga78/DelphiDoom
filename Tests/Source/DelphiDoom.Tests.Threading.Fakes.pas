{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - fake workers                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.Fakes;

interface

uses
  System.Generics.Collections, DelphiDoom.Threading.Intf, DelphiDoom.Threading.Types;

type
  /// <summary>What the fake workers of a test did, in one place</summary>
  TFakeWorkerLog = class
  public
    Submits: Integer;
    Shutdowns: Integer;
    Destroyed: Integer;
    /// <summary>The indexes of the workers, in the order they were waited for</summary>
    Waits: TList<Integer>;
    /// <summary>The workers whose Wait raises an EWorkerJobException</summary>
    FailingIndexes: TList<Integer>;
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>A worker that only counts what it is asked and fails when it is told to</summary>
  TFakeWorker = class(TInterfacedObject, IWorkerThread)
  strict private
    FLog: TFakeWorkerLog;
    FIndex: Integer;
  public
    constructor Create(ALog: TFakeWorkerLog; AIndex: Integer);
    destructor Destroy; override;
    procedure Submit(AProc: TWorkerProc; AParameter: Pointer);
    procedure Wait;
    function IsIdle: Boolean;
    function LastResult: Integer;
    procedure Shutdown;
  end;

  /// <summary>Makes fake workers numbered from 0; it can fail when it makes the Nth one</summary>
  TFakeWorkerFactory = class(TInterfacedObject, IWorkerThreadFactory)
  strict private
    FLog: TFakeWorkerLog;
    FCreated: Integer;
    FFailAtIndex: Integer;
  public
    /// <summary>AFailAtIndex is the index of the worker that cannot be made (-1 = none)</summary>
    constructor Create(ALog: TFakeWorkerLog; AFailAtIndex: Integer = -1);
    function CreateWorker: IWorkerThread;
    property Created: Integer read FCreated;
  end;

implementation

uses
  System.SysUtils;

{ TFakeWorkerLog }

constructor TFakeWorkerLog.Create;
begin
  inherited Create;
  Waits := TList<Integer>.Create;
  FailingIndexes := TList<Integer>.Create;
end;

destructor TFakeWorkerLog.Destroy;
begin
  FailingIndexes.Free;
  Waits.Free;
  inherited Destroy;
end;

{ TFakeWorker }

constructor TFakeWorker.Create(ALog: TFakeWorkerLog; AIndex: Integer);
begin
  inherited Create;
  FLog := ALog;
  FIndex := AIndex;
end;

destructor TFakeWorker.Destroy;
begin
  Inc(FLog.Destroyed);
  inherited Destroy;
end;

procedure TFakeWorker.Submit(AProc: TWorkerProc; AParameter: Pointer);
begin
  Inc(FLog.Submits);
end;

procedure TFakeWorker.Wait;
begin
  FLog.Waits.Add(FIndex);
  if FLog.FailingIndexes.Contains(FIndex) then
    raise EWorkerJobException.Create('FakeError' + IntToStr(FIndex), 'message ' + IntToStr(FIndex));
end;

function TFakeWorker.IsIdle: Boolean;
begin
  Result := True;
end;

function TFakeWorker.LastResult: Integer;
begin
  Result := FIndex;
end;

procedure TFakeWorker.Shutdown;
begin
  Inc(FLog.Shutdowns);
end;

{ TFakeWorkerFactory }

constructor TFakeWorkerFactory.Create(ALog: TFakeWorkerLog; AFailAtIndex: Integer);
begin
  inherited Create;
  FLog := ALog;
  FFailAtIndex := AFailAtIndex;
end;

function TFakeWorkerFactory.CreateWorker: IWorkerThread;
begin
  if FCreated = FFailAtIndex then
    raise EThreadingException.Create('no more workers');
  Result := TFakeWorker.Create(FLog, FCreated);
  Inc(FCreated);
end;

end.
