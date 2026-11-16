{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - the factory of pools                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.PoolFactory;

interface

uses
  DelphiDoom.Threading.Intf;

type
  /// <summary>Makes pools of workers made by the given thread factory</summary>
  TWorkerPoolFactory = class(TInterfacedObject, IWorkerPoolFactory)
  strict private
    FThreadFactory: IWorkerThreadFactory;
  public
    /// <summary>EArgumentNilException if AThreadFactory is nil</summary>
    constructor Create(const AThreadFactory: IWorkerThreadFactory);
    function CreatePool(ACount: Integer): IWorkerPool;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.WorkerPool;

{ TWorkerPoolFactory }

constructor TWorkerPoolFactory.Create(const AThreadFactory: IWorkerThreadFactory);
begin
  inherited Create;
  if not Assigned(AThreadFactory) then
    raise EArgumentNilException.Create('AThreadFactory');
  FThreadFactory := AThreadFactory;
end;

function TWorkerPoolFactory.CreatePool(ACount: Integer): IWorkerPool;
begin
  Result := TWorkerPool.Create(ACount, FThreadFactory);
end;

end.
