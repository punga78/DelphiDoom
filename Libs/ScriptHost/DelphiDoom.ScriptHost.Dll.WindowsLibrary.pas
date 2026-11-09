{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - libraries of Windows                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Dll.WindowsLibrary;

interface

uses
  DelphiDoom.ScriptHost.Dll.Intf;

type
  /// <summary>LoadLibrary and FreeLibrary</summary>
  TScriptDllWindowsLibrary = class(TInterfacedObject, IScriptDllLibrary)
  public
    function Load(const APath: string): NativeUInt;
    procedure Unload(const AHandle: NativeUInt);
  end;

implementation

uses
  Winapi.Windows;

{ TScriptDllWindowsLibrary }

function TScriptDllWindowsLibrary.Load(const APath: string): NativeUInt;
begin
  Result := LoadLibrary(PChar(APath));
end;

procedure TScriptDllWindowsLibrary.Unload(const AHandle: NativeUInt);
begin
  FreeLibrary(AHandle);
end;

end.
