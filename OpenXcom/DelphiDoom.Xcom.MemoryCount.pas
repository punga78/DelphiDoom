{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - counts the blocks of memory that are still allocated   }
{                                                                              }
{  This program is free software; you can redistribute it and/or               }
{  modify it under the terms of the GNU General Public License                 }
{  as published by the Free Software Foundation; either version 2              }
{  of the License, or (at your option) any later version.                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.MemoryCount;

interface

type
  /// <summary>
  ///   Counts the blocks taken and given back through the memory manager from the moment it is installed
  ///   (Xcom32 -memstats): what is left after the game of a script was freed, compared between two scripts, is
  ///   what leaked. It only counts; the blocks go to the memory manager that was there
  /// </summary>
  TXcomMemoryCount = class
  public
    /// <summary>Puts the counter in front of the memory manager (once; later calls do nothing)</summary>
    class procedure Install; static;
    /// <summary>Blocks taken and not given back since Install</summary>
    class function Blocks: Integer; static;
  end;

implementation

var
  GInstalled: Boolean;
  GBlocks: Integer;
  GInner: TMemoryManagerEx;

function CountedGetMem(ASize: NativeInt): Pointer;
begin
  Result := GInner.GetMem(ASize);
  if Assigned(Result) then
    AtomicIncrement(GBlocks);
end;

function CountedFreeMem(APointer: Pointer): Integer;
begin
  Result := GInner.FreeMem(APointer);
  AtomicDecrement(GBlocks);
end;

function CountedReallocMem(APointer: Pointer; ASize: NativeInt): Pointer;
begin
  Result := GInner.ReallocMem(APointer, ASize);
end;

function CountedAllocMem(ASize: NativeInt): Pointer;
begin
  Result := GInner.AllocMem(ASize);
  if Assigned(Result) then
    AtomicIncrement(GBlocks);
end;

class procedure TXcomMemoryCount.Install;
var
  LCounted: TMemoryManagerEx;
begin
  if GInstalled then
    Exit;
  GInstalled := True;
  GetMemoryManager(GInner);
  LCounted := GInner;
  LCounted.GetMem := CountedGetMem;
  LCounted.FreeMem := CountedFreeMem;
  LCounted.ReallocMem := CountedReallocMem;
  LCounted.AllocMem := CountedAllocMem;
  SetMemoryManager(LCounted);
end;

class function TXcomMemoryCount.Blocks: Integer;
begin
  Result := GBlocks;
end;

end.
