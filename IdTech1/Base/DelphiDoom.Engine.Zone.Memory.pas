{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the raw memory of the zone                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Zone.Memory;

interface

uses
  DelphiDoom.Zone.Intf;

type
  /// <summary>
  ///   The bytes of the zone, taken the way the rest of the engine takes them (malloc and
  ///   memfree of d_delphi), so that the "mem" command still counts them in memoryusage
  /// </summary>
  TEngineZoneMemory = class(TInterfacedObject, IZoneMemory)
  public
    function Allocate(ASize: NativeInt): Pointer;
    procedure Release(APointer: Pointer; ASize: NativeInt);
  end;

implementation

uses
  d_delphi;

{ TEngineZoneMemory }

function TEngineZoneMemory.Allocate(ASize: NativeInt): Pointer;
begin
  // the size is never 0: the allocator always adds the header
  Result := malloc(Integer(ASize));
end;

procedure TEngineZoneMemory.Release(APointer: Pointer; ASize: NativeInt);
begin
  memfree(APointer, Integer(ASize));
end;

end.
