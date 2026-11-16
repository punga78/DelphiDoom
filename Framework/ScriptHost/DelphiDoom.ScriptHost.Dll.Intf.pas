{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - DLLs that live inside the PAK files               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  A DLL in a PK3 cannot be loaded from the archive: it is copied to a         }
{  temporary file and loaded from there (the old ps_dll.pas).                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Dll.Intf;

interface

type
  /// <summary>Where the files of the DLLs come from and how they are named</summary>
  IScriptDllSource = interface
    ['{2F8C5B91-D3E4-4A07-9B6C-71E0A8D54C32}']
    /// <summary>
    ///   The name under which a DLL is remembered: the upper case short name (no folders). Two
    ///   requests with the same key are the same DLL
    /// </summary>
    function KeyOf(const AName: string): string;
    /// <summary>
    ///   Looks for the DLL (first as the script wrote it, in the folders of the game, then by its
    ///   short name in the DLL folder) and writes it to a new temporary file; false if it is
    ///   not found
    /// </summary>
    function Extract(const AName: string; out APath: string): Boolean;
  end;

  /// <summary>The operating system that loads libraries</summary>
  IScriptDllLibrary = interface
    ['{9C41E7D2-0B58-4E13-A6F9-3D2B85C07A14}']
    /// <summary>The handle of the loaded library, 0 if it could not be loaded</summary>
    function Load(const APath: string): NativeUInt;
    procedure Unload(const AHandle: NativeUInt);
  end;

  /// <summary>The DLLs that scripts and models ask for, loaded once and counted</summary>
  IScriptDllLoader = interface
    ['{E50A63C8-7F21-4B9D-8D04-C1A97B3E6F58}']
    /// <summary>
    ///   Loads the DLL (or counts one more use of one already loaded) and gives its handle; 0 if
    ///   the DLL is not found or cannot be loaded
    /// </summary>
    function Load(const AName: string): NativeUInt;
    /// <summary>One use less; at the last one the library is unloaded. False if the DLL is not loaded</summary>
    function Unload(const AName: string): Boolean;
    /// <summary>Forgets the DLLs, without unloading them (the process ends soon: the old behaviour)</summary>
    procedure Shutdown;
  end;

implementation

end.
