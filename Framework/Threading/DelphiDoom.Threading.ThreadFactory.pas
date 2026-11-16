{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - the factory of worker threads                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.ThreadFactory;

interface

uses
  DelphiDoom.Threading.Intf;

type
  /// <summary>Makes the real worker threads (one Windows thread each)</summary>
  TWorkerThreadFactory = class(TInterfacedObject, IWorkerThreadFactory)
  public
    function CreateWorker: IWorkerThread;
  end;

implementation

uses
  DelphiDoom.Threading.WorkerThread;

{ TWorkerThreadFactory }

function TWorkerThreadFactory.CreateWorker: IWorkerThread;
begin
  Result := TWorkerThread.Create;
end;

end.
