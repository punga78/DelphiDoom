{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - the old mt_utils               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.Legacy;

// A faithful copy of the bodies of Base\mt_utils.pas of master cb5a45e3 (MT_ZeroMemory,
// MT_memset, MT_memseti, MT_memcpy, some of the MT_Execute overloads, MT_Execute4/6,
// MT_Iterate and the tasks): the globals are fields, the pools and the primitives are given,
// and I_Error is a call that raises. Only what the parity tests compare is copied.

interface

uses
  System.Classes, DelphiDoom.Threading.Intf, DelphiDoom.Threading.Types;

const
  LEGACY_MAXGPTHREADS = 16;
  LEGACY_NUMEXECTHREADS = 64;
  LEGACY_NUMTASKTHREADS = 8;

type
  TLegacyIterator = record
    idx: Integer;
    numidxs: Integer;
    data: Pointer;
  end;
  PLegacyIterator = ^TLegacyIterator;

  TLegacyTaskInfo = record
    id: Integer;
    proc: TWorkerTaskProc;
  end;
  PLegacyTaskInfo = ^TLegacyTaskInfo;

  TLegacyThreads = class
  strict private
    FOps: IWorkerMemoryOps;
    FMessages: IWorkerMessages;
    FNumGpThreads: Integer;
    FGpThreads: IWorkerPool;
    FExecThreads: IWorkerPool;
    FTaskThreads: IWorkerPool;
    FInitialized: Boolean;
    FExecuteFetched: Boolean;
    FCpus: Integer;
    FTasks: array[0..LEGACY_NUMTASKTHREADS - 1] of TLegacyTaskInfo;
  public
    constructor Create(const AGpThreads, AExecThreads, ATaskThreads: IWorkerPool;
      const AOps: IWorkerMemoryOps; const AMessages: IWorkerMessages; ACpus: Integer;
      AInitialized: Boolean);
    procedure MT_ZeroMemory(const dest0: Pointer; const count0: Integer; threadsuse: Integer = 0);
    procedure MT_memset(const dest0: Pointer; const val: Integer; const count0: Integer; threadsuse: Integer = 0);
    procedure MT_memseti(const dest0: Pointer; const val: Integer; const count0: Integer; threadsuse: Integer = 0);
    procedure MT_memcpy(const dest0: Pointer; const src0: Pointer; const count0: Integer; threadsuse: Integer = 0);
    procedure MT_Execute2(const func1: TWorkerProc; const parms1: Pointer;
      const func2: TWorkerProc; const parms2: Pointer);
    procedure MT_Execute4(const func1: TWorkerProc; const parms1: Pointer;
      const func2: TWorkerProc; const parms2: Pointer;
      const func3: TWorkerProc; const parms3: Pointer;
      const func4: TWorkerProc; const parms4: Pointer);
    procedure MT_Execute4Fixed(const func1: TWorkerProc; const parms1: Pointer;
      const func2: TWorkerProc; const parms2: Pointer;
      const func3: TWorkerProc; const parms3: Pointer;
      const func4: TWorkerProc; const parms4: Pointer);
    procedure MT_Execute6Fixed(const func1: TWorkerProc; const parms1: Pointer;
      const func2: TWorkerProc; const parms2: Pointer;
      const func3: TWorkerProc; const parms3: Pointer;
      const func4: TWorkerProc; const parms4: Pointer;
      const func5: TWorkerProc; const parms5: Pointer;
      const func6: TWorkerProc; const parms6: Pointer);
    procedure MT_Iterate(const func: TWorkerProc; const data: Pointer; const nthreads: Integer = 0);
    function MT_ScheduleTask(const proc: TWorkerTaskProc): Integer;
    procedure MT_ExecutePendingTask(const id: Integer);
    procedure MT_WaitTask(const id: Integer);
    procedure MT_WaitTasks;
  end;

implementation

type
  zmparams_t = record
    dest: Pointer;
    size: Integer;
  end;
  zmparams_p = ^zmparams_t;
  zmparams_a = array[0..LEGACY_MAXGPTHREADS - 1] of zmparams_t;

  msparams_t = record
    dest: Pointer;
    value: Integer;
    size: Integer;
  end;
  msparams_p = ^msparams_t;
  msparams_a = array[0..LEGACY_MAXGPTHREADS - 1] of msparams_t;

  mcparams_t = record
    dest: Pointer;
    src: Pointer;
    size: Integer;
  end;
  mcparams_p = ^mcparams_t;
  mcparams_a = array[0..LEGACY_MAXGPTHREADS - 1] of mcparams_t;

var
  GOps: IWorkerMemoryOps;

function MT_ZeroMemory_thr(p: Pointer): Integer; stdcall;
begin
  GOps.Zero(zmparams_p(p).dest, zmparams_p(p).size);
  Result := 1;
end;

function MT_memset_thr(p: Pointer): Integer; stdcall;
begin
  GOps.Fill(msparams_p(p).dest, msparams_p(p).value, msparams_p(p).size);
  Result := 1;
end;

function MT_memseti_thr(p: Pointer): Integer; stdcall;
begin
  GOps.FillInteger(msparams_p(p).dest, msparams_p(p).value, msparams_p(p).size);
  Result := 1;
end;

function MT_memcpy_thr(p: Pointer): Integer; stdcall;
begin
  GOps.Copy(mcparams_p(p).dest, mcparams_p(p).src, mcparams_p(p).size);
  Result := 1;
end;

function _execute_task(p: Pointer): Integer; stdcall;
var
  pt: PLegacyTaskInfo;
begin
  pt := p;
  pt.proc;
  Result := pt.id;
  pt.id := -1;
  pt.proc := nil;
end;

{ TLegacyThreads }

constructor TLegacyThreads.Create(const AGpThreads, AExecThreads, ATaskThreads: IWorkerPool;
  const AOps: IWorkerMemoryOps; const AMessages: IWorkerMessages; ACpus: Integer;
  AInitialized: Boolean);
begin
  inherited Create;
  FGpThreads := AGpThreads;
  FExecThreads := AExecThreads;
  FTaskThreads := ATaskThreads;
  FOps := AOps;
  GOps := AOps;
  FMessages := AMessages;
  FNumGpThreads := AGpThreads.Count;
  FCpus := ACpus;
  FInitialized := AInitialized;
end;

procedure TLegacyThreads.MT_ZeroMemory(const dest0: Pointer; const count0: Integer; threadsuse: Integer);
var
  parms: zmparams_a;
  sz: Integer;
  dst: Pointer;
  i: Integer;
begin
  if (FNumGpThreads < 2) or (count0 < 1024) or not FInitialized then
  begin
    FOps.Zero(dest0, count0);
    Exit;
  end;

  if threadsuse < 2 then
  begin
    threadsuse := count0 div 1024;
    if threadsuse < 2 then
      threadsuse := 2;
  end;

  if threadsuse > FNumGpThreads then
    threadsuse := FNumGpThreads;

  sz := (count0 div threadsuse) and not 7;
  dst := dest0;
  for i := 0 to threadsuse - 1 do
  begin
    if i = threadsuse - 1 then
      FOps.Zero(dst, count0 - i * sz)
    else
    begin
      parms[i].dest := dst;
      parms[i].size := sz;
      FGpThreads[i].Submit(MT_ZeroMemory_thr, @parms[i]);
      dst := Pointer(Integer(dst) + sz);
    end;
  end;
  for i := 0 to threadsuse - 2 do
    FGpThreads[i].Wait;
end;

procedure TLegacyThreads.MT_memset(const dest0: Pointer; const val: Integer; const count0: Integer;
  threadsuse: Integer);
var
  parms: msparams_a;
  sz: Integer;
  dst: Pointer;
  i: Integer;
begin
  if (FNumGpThreads < 2) or (count0 < 1024) or not FInitialized then
  begin
    FOps.Fill(dest0, val, count0);
    Exit;
  end;

  if threadsuse < 2 then
  begin
    threadsuse := count0 div 1024;
    if threadsuse < 2 then
      threadsuse := 2;
  end;

  if threadsuse > FNumGpThreads then
    threadsuse := FNumGpThreads;

  sz := (count0 div threadsuse) and not 7;
  dst := dest0;
  for i := 0 to threadsuse - 1 do
  begin
    if i = threadsuse - 1 then
      FOps.Fill(dst, val, count0 - i * sz)
    else
    begin
      parms[i].dest := dst;
      parms[i].value := val;
      parms[i].size := sz;
      FGpThreads[i].Submit(MT_memset_thr, @parms[i]);
      dst := Pointer(Integer(dst) + sz);
    end;
  end;
  for i := 0 to threadsuse - 2 do
    FGpThreads[i].Wait;
end;

procedure TLegacyThreads.MT_memseti(const dest0: Pointer; const val: Integer; const count0: Integer;
  threadsuse: Integer);
var
  parms: msparams_a;
  sz, sz4: Integer;
  dst: Pointer;
  i: Integer;
begin
  if (FNumGpThreads < 2) or (count0 < 1024) or not FInitialized then
  begin
    FOps.FillInteger(dest0, val, count0);
    Exit;
  end;

  if threadsuse < 2 then
  begin
    threadsuse := count0 div 1024;
    if threadsuse < 2 then
      threadsuse := 2;
  end;

  if threadsuse > FNumGpThreads then
    threadsuse := FNumGpThreads;

  sz := (count0 div threadsuse) and not 7;
  sz4 := sz * 4;
  dst := dest0;
  for i := 0 to threadsuse - 1 do
  begin
    if i = threadsuse - 1 then
      FOps.FillInteger(dst, val, count0 - i * sz)
    else
    begin
      parms[i].dest := dst;
      parms[i].value := val;
      parms[i].size := sz;
      FGpThreads[i].Submit(MT_memseti_thr, @parms[i]);
      dst := Pointer(Integer(dst) + sz4);
    end;
  end;
  for i := 0 to threadsuse - 2 do
    FGpThreads[i].Wait;
end;

procedure TLegacyThreads.MT_memcpy(const dest0: Pointer; const src0: Pointer; const count0: Integer;
  threadsuse: Integer);
var
  parms: mcparams_a;
  sz: Integer;
  dst, src: Pointer;
  i: Integer;
begin
  if (FNumGpThreads < 2) or (count0 < 1024) or not FInitialized then
  begin
    FOps.Copy(dest0, src0, count0);
    Exit;
  end;

  if threadsuse < 2 then
  begin
    threadsuse := count0 div 1024;
    if threadsuse < 2 then
      threadsuse := 2;
  end;

  if threadsuse > FNumGpThreads then
    threadsuse := FNumGpThreads;

  sz := (count0 div threadsuse) and not 7;
  dst := dest0;
  src := src0;
  for i := 0 to threadsuse - 1 do
  begin
    if i = threadsuse - 1 then
      FOps.Copy(dst, src, count0 - i * sz)
    else
    begin
      parms[i].dest := dst;
      parms[i].src := src;
      parms[i].size := sz;
      FGpThreads[i].Submit(MT_memcpy_thr, @parms[i]);
      dst := Pointer(Integer(dst) + sz);
      src := Pointer(Integer(src) + sz);
    end;
  end;
  for i := 0 to threadsuse - 2 do
    FGpThreads[i].Wait;
end;

procedure TLegacyThreads.MT_Execute2(const func1: TWorkerProc; const parms1: Pointer;
  const func2: TWorkerProc; const parms2: Pointer);
begin
  if FExecuteFetched then
    FMessages.Error('MT_Execute(): Invalid recoursive call.'#13#10);

  FExecuteFetched := True;

  if @func2 <> nil then
  begin
    FExecThreads[0].Submit(func2, parms2);
    if @func1 = nil then
      FMessages.Warning('MT_Execute(): Called with null application thread function.'#13#10)
    else
      func1(parms1);
    FExecThreads[0].Wait;
  end
  else if @func1 = nil then
    FMessages.Warning('MT_Execute(): Called with null application thread function.'#13#10)
  else
    func1(parms1);

  FExecuteFetched := False;
end;

procedure TLegacyThreads.MT_Execute4(const func1: TWorkerProc; const parms1: Pointer;
  const func2: TWorkerProc; const parms2: Pointer;
  const func3: TWorkerProc; const parms3: Pointer;
  const func4: TWorkerProc; const parms4: Pointer);
var
  nt: Integer;
  i: Integer;
begin
  if FExecuteFetched then
    FMessages.Error('MT_Execute(): Invalid recoursive call.'#13#10);

  FExecuteFetched := True;

  nt := 0;
  if @func2 <> nil then
  begin
    FExecThreads[nt].Submit(func2, parms2);
    Inc(nt);
  end;
  if @func3 <> nil then
  begin
    FExecThreads[nt].Submit(func3, parms3);
    Inc(nt);
  end;
  if @func4 <> nil then
  begin
    FExecThreads[nt].Submit(func4, parms4);
    Inc(nt);
  end;
  if @func1 = nil then
    FMessages.Warning('MT_Execute(): Called with null application thread function.'#13#10)
  else
    func1(parms1);
  for i := 0 to nt - 1 do
    FExecThreads[i].Wait;
  FExecuteFetched := False;
end;

procedure TLegacyThreads.MT_Execute4Fixed(const func1: TWorkerProc; const parms1: Pointer;
  const func2: TWorkerProc; const parms2: Pointer;
  const func3: TWorkerProc; const parms3: Pointer;
  const func4: TWorkerProc; const parms4: Pointer);
begin
  if FExecuteFetched then
    FMessages.Error('MT_Execute(): Invalid recoursive call.'#13#10);

  FExecuteFetched := True;

  FExecThreads[0].Submit(func2, parms2);
  FExecThreads[1].Submit(func3, parms3);
  FExecThreads[2].Submit(func4, parms4);
  func1(parms1);

  FExecThreads[0].Wait;
  FExecThreads[1].Wait;
  FExecThreads[2].Wait;

  FExecuteFetched := False;
end;

procedure TLegacyThreads.MT_Execute6Fixed(const func1: TWorkerProc; const parms1: Pointer;
  const func2: TWorkerProc; const parms2: Pointer;
  const func3: TWorkerProc; const parms3: Pointer;
  const func4: TWorkerProc; const parms4: Pointer;
  const func5: TWorkerProc; const parms5: Pointer;
  const func6: TWorkerProc; const parms6: Pointer);
begin
  if FExecuteFetched then
    FMessages.Error('MT_Execute(): Invalid recoursive call.'#13#10);

  FExecuteFetched := True;

  FExecThreads[0].Submit(func2, parms2);
  FExecThreads[1].Submit(func3, parms3);
  FExecThreads[2].Submit(func4, parms4);
  FExecThreads[3].Submit(func5, parms5);
  FExecThreads[4].Submit(func6, parms6);
  func1(parms1);
  FExecThreads[0].Wait;
  FExecThreads[1].Wait;
  FExecThreads[2].Wait;
  FExecThreads[3].Wait;
  FExecThreads[4].Wait;
  FExecThreads[5].Wait;
  FExecThreads[6].Wait;
  FExecThreads[7].Wait;
  FExecThreads[8].Wait;
  FExecThreads[9].Wait;
  FExecThreads[10].Wait;
  FExecThreads[11].Wait;
  FExecThreads[12].Wait;
  FExecThreads[13].Wait;
  FExecThreads[14].Wait;

  FExecuteFetched := False;
end;

procedure TLegacyThreads.MT_Iterate(const func: TWorkerProc; const data: Pointer; const nthreads: Integer);
var
  parms: array[0..LEGACY_NUMEXECTHREADS] of TLegacyIterator;
  i, nt: Integer;
begin
  if FExecuteFetched then
    FMessages.Error('MT_Iterate(): Invalid recoursive call.'#13#10);

  FExecuteFetched := True;

  if nthreads > 0 then
    nt := nthreads
  else
    nt := FCpus;
  if nt < 2 then
    nt := 2
  else if nt > LEGACY_NUMEXECTHREADS + 1 then
    nt := LEGACY_NUMEXECTHREADS + 1;

  for i := 0 to nt - 2 do
  begin
    parms[i].idx := i;
    parms[i].numidxs := nt;
    parms[i].data := data;
    FExecThreads[i].Submit(func, @parms[i]);
  end;
  parms[nt - 1].idx := nt - 1;
  parms[nt - 1].numidxs := nt;
  parms[nt - 1].data := data;
  func(@parms[nt - 1]);

  for i := 0 to nt - 2 do
    FExecThreads[i].Wait;

  FExecuteFetched := False;
end;

function TLegacyThreads.MT_ScheduleTask(const proc: TWorkerTaskProc): Integer;
var
  i: Integer;
begin
  for i := 0 to LEGACY_NUMTASKTHREADS - 1 do
    if not Assigned(FTasks[i].proc) then
    begin
      FTasks[i].id := i;
      FTasks[i].proc := proc;
      Result := i;
      Exit;
    end;
  proc;
  Result := -1;
end;

procedure TLegacyThreads.MT_ExecutePendingTask(const id: Integer);
begin
  if Assigned(FTasks[id].proc) then
    FTaskThreads[id].Submit(_execute_task, @FTasks[id]);
end;

procedure TLegacyThreads.MT_WaitTask(const id: Integer);
begin
  if (id < 0) or (id >= LEGACY_NUMTASKTHREADS) then
    Exit;
  if Assigned(FTasks[id].proc) then
    FTaskThreads[id].Wait;
end;

procedure TLegacyThreads.MT_WaitTasks;
var
  i: Integer;
begin
  for i := 0 to LEGACY_NUMTASKTHREADS - 1 do
    if Assigned(FTasks[i].proc) then
      FTaskThreads[i].Wait;
end;

end.
