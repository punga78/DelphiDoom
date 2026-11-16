{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the memory of the crashed program       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.WindowsCrashMemory;

// Reads the memory of the process itself. Only Windows API calls and no allocation: it runs
// inside the unhandled exception filter.

interface

uses
  DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The memory of the running process, checked with IsBadReadPtr before it is read</summary>
  TWindowsCrashMemory = class(TInterfacedObject, ICrashMemory)
  public
    function IsReadable(AAddress: Cardinal; ASize: Cardinal): Boolean;
    function ReadDWord(AAddress: Cardinal): Cardinal;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsCrashMemory }

function TWindowsCrashMemory.IsReadable(AAddress: Cardinal; ASize: Cardinal): Boolean;
begin
  Result := not IsBadReadPtr(Pointer(NativeUInt(AAddress)), ASize);
end;

function TWindowsCrashMemory.ReadDWord(AAddress: Cardinal): Cardinal;
begin
  Result := PCardinal(NativeUInt(AAddress))^;
end;

end.
