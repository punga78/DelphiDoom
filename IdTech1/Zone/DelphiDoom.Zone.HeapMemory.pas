{******************************************************************************}
{                                                                              }
{  DelphiDoom: zone library - the memory of the heap                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zone.HeapMemory;

interface

uses
  DelphiDoom.Zone.Intf;

type
  /// <summary>The raw memory of the zone, from GetMem and FreeMem</summary>
  TZoneHeapMemory = class(TInterfacedObject, IZoneMemory)
  public
    function Allocate(ASize: NativeInt): Pointer;
    procedure Release(APointer: Pointer; ASize: NativeInt);
  end;

implementation

{ TZoneHeapMemory }

function TZoneHeapMemory.Allocate(ASize: NativeInt): Pointer;
begin
  GetMem(Result, ASize);
end;

procedure TZoneHeapMemory.Release(APointer: Pointer; ASize: NativeInt);
begin
  FreeMem(APointer, ASize);
end;

end.
