{******************************************************************************}
{                                                                              }
{  DelphiDoom: zone library - the factory: the composition root                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zone.Factory;

interface

uses
  DelphiDoom.Zone.Intf;

type
  /// <summary>The only place that knows the classes behind IZoneAllocator</summary>
  TZoneFactory = class
  public
    /// <summary>An allocator on the heap of the program</summary>
    class function CreateAllocator: IZoneAllocator; overload; static;
    /// <summary>An allocator on any memory (a fake one, in the tests)</summary>
    class function CreateAllocator(const AMemory: IZoneMemory): IZoneAllocator; overload; static;
  end;

implementation

uses
  DelphiDoom.Zone.Allocator, DelphiDoom.Zone.HeapMemory;

{ TZoneFactory }

class function TZoneFactory.CreateAllocator: IZoneAllocator;
begin
  Result := TZoneAllocator.Create(TZoneHeapMemory.Create);
end;

class function TZoneFactory.CreateAllocator(const AMemory: IZoneMemory): IZoneAllocator;
begin
  Result := TZoneAllocator.Create(AMemory);
end;

end.
