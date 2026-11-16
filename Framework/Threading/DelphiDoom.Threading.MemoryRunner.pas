{******************************************************************************}
{                                                                              }
{  DelphiDoom: threading library - fill and copy memory on several threads     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Threading.MemoryRunner;

interface

uses
  DelphiDoom.Threading.Intf;

type
  /// <summary>What a chunk of a parallel memory operation does</summary>
  TWorkerMemoryKind = (wmkZero, wmkFill, wmkFillInteger, wmkCopy);

  /// <summary>One chunk: the part of the block a thread works on</summary>
  TWorkerMemoryChunk = record
    Runner: TObject;
    Kind: TWorkerMemoryKind;
    Dest: Pointer;
    Source: Pointer;
    Value: Integer;
    Size: Integer;
  end;
  PWorkerMemoryChunk = ^TWorkerMemoryChunk;

  /// <summary>
  ///   The MT_ZeroMemory, MT_memset, MT_memseti and MT_memcpy of the engine: a big block is cut in
  ///   equal chunks (a multiple of 8 elements), the chunks but the last go to the workers and the
  ///   last one is done by the caller, which then waits. Small blocks (under 1024 elements) and
  ///   pools with fewer than two workers are done on the calling thread with the same primitive.
  ///   It runs once per block, not per element: the class is sealed, no virtual methods.
  /// </summary>
  TWorkerMemoryRunner = class sealed
  strict private
    const
      MaxThreads = 16;
      MinimumElements = 1024;
  strict private
    FPool: IWorkerPool;
    FOps: IWorkerMemoryOps;
    FThreadCount: Integer;
    function ChooseThreads(ACount, AThreadsUse: Integer): Integer;
    procedure Run(AKind: TWorkerMemoryKind; ADest, ASource: Pointer; AValue, ACount, AThreadsUse: Integer);
  public
    /// <summary>
    ///   The threads used are at most the workers of APool and at most 16. EArgumentNilException
    ///   if a parameter is nil
    /// </summary>
    constructor Create(const APool: IWorkerPool; const AOps: IWorkerMemoryOps);
    procedure ZeroMemory(ADest: Pointer; ACount: Integer; AThreadsUse: Integer = 0);
    /// <summary>ACount bytes set to AValue</summary>
    procedure Fill(ADest: Pointer; AValue, ACount: Integer; AThreadsUse: Integer = 0);
    /// <summary>ACount 32 bit integers set to AValue</summary>
    procedure FillInteger(ADest: Pointer; AValue, ACount: Integer; AThreadsUse: Integer = 0);
    procedure Copy(ADest, ASource: Pointer; ACount: Integer; AThreadsUse: Integer = 0);
    /// <summary>Does one chunk (the job of the workers; do not call it)</summary>
    procedure RunChunk(const AChunk: TWorkerMemoryChunk);
    property ThreadCount: Integer read FThreadCount;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Threading.Types;

function ChunkJob(AParameter: Pointer): Integer; stdcall;
begin
  TWorkerMemoryRunner(PWorkerMemoryChunk(AParameter).Runner).RunChunk(PWorkerMemoryChunk(AParameter)^);
  Result := 1;
end;

{ TWorkerMemoryRunner }

constructor TWorkerMemoryRunner.Create(const APool: IWorkerPool; const AOps: IWorkerMemoryOps);
begin
  inherited Create;
  if not Assigned(APool) then
    raise EArgumentNilException.Create('APool');
  if not Assigned(AOps) then
    raise EArgumentNilException.Create('AOps');
  FPool := APool;
  FOps := AOps;
  FThreadCount := APool.Count;
  if FThreadCount > MaxThreads then
    FThreadCount := MaxThreads;
end;

procedure TWorkerMemoryRunner.RunChunk(const AChunk: TWorkerMemoryChunk);
begin
  case AChunk.Kind of
    wmkZero:
      FOps.Zero(AChunk.Dest, AChunk.Size);
    wmkFill:
      FOps.Fill(AChunk.Dest, AChunk.Value, AChunk.Size);
    wmkFillInteger:
      FOps.FillInteger(AChunk.Dest, AChunk.Value, AChunk.Size);
    wmkCopy:
      FOps.Copy(AChunk.Dest, AChunk.Source, AChunk.Size);
  end;
end;

function TWorkerMemoryRunner.ChooseThreads(ACount, AThreadsUse: Integer): Integer;
begin
  Result := AThreadsUse;
  if Result < 2 then
  begin
    Result := ACount div MinimumElements;
    if Result < 2 then
      Result := 2;
  end;
  if Result > FThreadCount then
    Result := FThreadCount;
end;

procedure TWorkerMemoryRunner.Run(AKind: TWorkerMemoryKind; ADest, ASource: Pointer; AValue, ACount,
  AThreadsUse: Integer);
var
  LChunks: array[0..MaxThreads - 1] of TWorkerMemoryChunk;
  LChunk: TWorkerMemoryChunk;
  LThreads: Integer;
  LSize: Integer;
  LStride: Integer;
  LDest: PByte;
  LSource: PByte;
  LIndex: Integer;
begin
  LChunk.Runner := Self;
  LChunk.Kind := AKind;
  LChunk.Value := AValue;
  if (FThreadCount < 2) or (ACount < MinimumElements) then
  begin
    LChunk.Dest := ADest;
    LChunk.Source := ASource;
    LChunk.Size := ACount;
    RunChunk(LChunk);
    Exit;
  end;

  LThreads := ChooseThreads(ACount, AThreadsUse);
  LSize := (ACount div LThreads) and not 7;
  if AKind = wmkFillInteger then
    LStride := LSize * SizeOf(Integer)
  else
    LStride := LSize;
  LDest := ADest;
  LSource := ASource;
  for LIndex := 0 to LThreads - 1 do
  begin
    LChunk.Dest := LDest;
    LChunk.Source := LSource;
    if LIndex = LThreads - 1 then
    begin
      LChunk.Size := ACount - LIndex * LSize;
      RunChunk(LChunk);
    end
    else
    begin
      LChunk.Size := LSize;
      LChunks[LIndex] := LChunk;
      FPool[LIndex].Submit(ChunkJob, @LChunks[LIndex]);
      Inc(LDest, LStride);
      Inc(LSource, LStride);
    end;
  end;
  for LIndex := 0 to LThreads - 2 do
    FPool[LIndex].Wait;
end;

procedure TWorkerMemoryRunner.ZeroMemory(ADest: Pointer; ACount, AThreadsUse: Integer);
begin
  Run(wmkZero, ADest, nil, 0, ACount, AThreadsUse);
end;

procedure TWorkerMemoryRunner.Fill(ADest: Pointer; AValue, ACount, AThreadsUse: Integer);
begin
  Run(wmkFill, ADest, nil, AValue, ACount, AThreadsUse);
end;

procedure TWorkerMemoryRunner.FillInteger(ADest: Pointer; AValue, ACount, AThreadsUse: Integer);
begin
  Run(wmkFillInteger, ADest, nil, AValue, ACount, AThreadsUse);
end;

procedure TWorkerMemoryRunner.Copy(ADest, ASource: Pointer; ACount, AThreadsUse: Integer);
begin
  Run(wmkCopy, ADest, ASource, 0, ACount, AThreadsUse);
end;

end.
