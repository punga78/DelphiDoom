{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - the pool of workers                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.WorkerPool;

interface

uses
  DelphiDoom.Threading.Intf;

type
  /// <summary>A fixed number of workers made by a factory; closed together</summary>
  TWorkerPool = class(TInterfacedObject, IWorkerPool)
  strict private
    FWorkers: TArray<IWorkerThread>;
  public
    /// <summary>
    ///   Makes ACount workers with AFactory. EArgumentNilException if AFactory is nil,
    ///   EArgumentOutOfRangeException if ACount is negative
    /// </summary>
    constructor Create(ACount: Integer; const AFactory: IWorkerThreadFactory);
    destructor Destroy; override;
    function GetCount: Integer;
    function GetWorker(AIndex: Integer): IWorkerThread;
    procedure WaitAll;
    procedure Shutdown;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.Types;

const
  SIndexOutOfRange = 'Worker index %d is out of range (pool of %d)';
  SNegativeCount = 'A pool cannot have a negative number of workers.';

{ TWorkerPool }

constructor TWorkerPool.Create(ACount: Integer; const AFactory: IWorkerThreadFactory);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AFactory) then
    raise EArgumentNilException.Create('AFactory');
  if ACount < 0 then
    raise EArgumentOutOfRangeException.Create(SNegativeCount);
  SetLength(FWorkers, ACount);
  // if a worker cannot be made the ones already made are released with the pool
  for LIndex := 0 to ACount - 1 do
    FWorkers[LIndex] := AFactory.CreateWorker;
end;

destructor TWorkerPool.Destroy;
begin
  Shutdown;
  inherited Destroy;
end;

function TWorkerPool.GetCount: Integer;
begin
  Result := Length(FWorkers);
end;

function TWorkerPool.GetWorker(AIndex: Integer): IWorkerThread;
begin
  if (AIndex < 0) or (AIndex >= Length(FWorkers)) then
    raise EArgumentOutOfRangeException.CreateFmt(SIndexOutOfRange, [AIndex, Length(FWorkers)]);
  Result := FWorkers[AIndex];
end;

procedure TWorkerPool.WaitAll;
var
  LIndex: Integer;
  LFailed: Boolean;
  LClassName: string;
  LMessage: string;
begin
  LFailed := False;
  for LIndex := 0 to High(FWorkers) do
  begin
    try
      FWorkers[LIndex].Wait;
    except
      on E: EWorkerJobException do
        if not LFailed then
        begin
          LFailed := True;
          LClassName := E.OriginalClassName;
          LMessage := E.OriginalMessage;
        end;
    end;
  end;
  if LFailed then
    raise EWorkerJobException.Create(LClassName, LMessage);
end;

procedure TWorkerPool.Shutdown;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FWorkers) do
    if Assigned(FWorkers[LIndex]) then
      FWorkers[LIndex].Shutdown;
end;

end.
