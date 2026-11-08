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
  DelphiDoom.Threading.Intf;

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

end.
