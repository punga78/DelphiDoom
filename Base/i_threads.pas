//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_threads;

interface

uses
  DelphiDoom.Threading.Types,
  DelphiDoom.Threading.Intf;

type
  // The job of a thread: the same type as TWorkerProc of Libs\Threading
  threadfunc_t = TWorkerProc;

type
  //
  // TDThread: thin facade over IWorkerThread (Libs\Threading), kept for the units
  // that create their own threads (walls, fake 3d, depth buffer, menu shader, automap).
  // The thread waits on an event, is never suspended and is joined by Free.
  //
  TDThread = class
  private
    FWorker: IWorkerThread;
    FFunc: threadfunc_t;
  public
    constructor Create(const func: threadfunc_t = nil);
    destructor Destroy; override;
    procedure Activate(const parms: pointer); overload;
    procedure Activate(const func: threadfunc_t; const parms: pointer); overload;
    procedure Wait;
    function IsIdle: Boolean;
  end;

var
  dotestactivethreads: boolean = true;

//==============================================================================
//
// I_ConfigureThreads
//
// Gives the factory of worker threads (composition root); TDThread.Create
// needs it
//
//==============================================================================
procedure I_ConfigureThreads(const AFactory: IWorkerThreadFactory);

//==============================================================================
//
// TestActiveThreads
//
// It used to suspend the threads that had finished their job; the workers now
// sleep on an event, so there is nothing to do. Kept for the callers.
//
//==============================================================================
procedure TestActiveThreads;

//==============================================================================
//
// ThreadInc
//
//==============================================================================
function ThreadInc(var x: Integer): Integer;

//==============================================================================
//
// ThreadSet
//
//==============================================================================
function ThreadSet(var x: Integer; const newvalue: Integer): Integer;

implementation

uses
  Windows,
  i_system;

var
  threadfactory: IWorkerThreadFactory = nil;

//==============================================================================
//
// I_ConfigureThreads
//
//==============================================================================
procedure I_ConfigureThreads(const AFactory: IWorkerThreadFactory);
begin
  threadfactory := AFactory;
end;

//==============================================================================
//
// TDThread.Create
//
//==============================================================================
constructor TDThread.Create(const func: threadfunc_t = nil);
begin
  inherited Create;
  if not Assigned(threadfactory) then
    I_Error('TDThread.Create(): Threads are not configured');
  FFunc := func;
  FWorker := threadfactory.CreateWorker;
end;

//==============================================================================
//
// TDThread.Destroy
//
// Releasing the worker waits for the running job and for the thread to leave
//
//==============================================================================
destructor TDThread.Destroy;
begin
  FWorker := nil;
  inherited Destroy;
end;

//==============================================================================
// TDThread.Activate
//
// A new job waits for the previous one if it is still running
//
//==============================================================================
procedure TDThread.Activate(const parms: pointer);
begin
  if not Assigned(FFunc) then
    I_Error('TDThread.Activate(): Null function pointer');
  FWorker.Submit(FFunc, parms);
end;

//==============================================================================
//
// TDThread.Activate
//
//==============================================================================
procedure TDThread.Activate(const func: threadfunc_t; const parms: pointer);
begin
  FFunc := func;
  Activate(parms);
end;

//==============================================================================
//
// TDThread.Wait
//
//==============================================================================
procedure TDThread.Wait;
begin
  FWorker.Wait;
end;

//==============================================================================
//
// TDThread.IsIdle
//
//==============================================================================
function TDThread.IsIdle: Boolean;
begin
  Result := FWorker.IsIdle;
end;

//==============================================================================
//
// TestActiveThreads
//
//==============================================================================
procedure TestActiveThreads;
begin
end;

//==============================================================================
//
// ThreadInc
//
//==============================================================================
function ThreadInc(var x: Integer): Integer;
begin
  Result := InterlockedIncrement(x);
end;

//==============================================================================
//
// ThreadSet
//
//==============================================================================
function ThreadSet(var x: Integer; const newvalue: Integer): Integer;
begin
  Result := InterlockedExchange(x, newvalue);
end;

end.
