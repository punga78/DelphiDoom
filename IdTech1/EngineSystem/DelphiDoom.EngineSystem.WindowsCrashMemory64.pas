{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the memory of the crashed 64 bit program }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.WindowsCrashMemory64;

// Reads the memory of the process itself. Only Windows API calls and no allocation: it runs
// inside the unhandled exception filter. An address that does not fit in a pointer of the
// running process (a 32 bit one) is not readable.

interface

uses
  DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The memory of the running process, checked with IsBadReadPtr before it is read</summary>
  TWindowsCrashMemory64 = class(TInterfacedObject, ICrashMemory64)
  public
    function IsReadable(AAddress: UInt64; ASize: Cardinal): Boolean;
    function ReadQWord(AAddress: UInt64): UInt64;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsCrashMemory64 }

function TWindowsCrashMemory64.IsReadable(AAddress: UInt64; ASize: Cardinal): Boolean;
begin
  Result := (AAddress <= High(NativeUInt)) and (AAddress <> 0) and
    not IsBadReadPtr(Pointer(NativeUInt(AAddress)), ASize);
end;

function TWindowsCrashMemory64.ReadQWord(AAddress: UInt64): UInt64;
begin
  Result := PUInt64(NativeUInt(AAddress))^;
end;

end.
