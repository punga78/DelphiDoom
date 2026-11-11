{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what a compiler and an interpreter of scripts use }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Services.Intf;

interface

uses
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Source.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   The parts that TDoomCompiler, TDoomExec and the class importer of the scripts were reading
  ///   from the unit ps_import and from the globals of the engine: the functions, the classes and
  ///   the constants that scripts see, the files they include and the game they run in. The
  ///   composition root gives it to them
  /// </summary>
  IScriptHostServices = interface
    ['{91C5E3A7-4B28-4D6F-8E10-A7F2C95B3D48}']
    /// <summary>The functions of the units of script (SYSTEM, PS_GAME...)</summary>
    function Registry: IScriptFunctionRegistry;
    /// <summary>The classes that scripts see (Actors, Lines, MapStrings...)</summary>
    function Classes: IScriptClassCatalog;
    /// <summary>The constants of the unit SYSTEM</summary>
    function Constants: IScriptConstantProvider;
    /// <summary>The files that a script includes, and the scripts of the maps</summary>
    function Sources: IScriptSourceProvider;
    /// <summary>The name of the game of the engine, as a compiled script records it (DOOM, Radix...)</summary>
    function GameName: string;
    /// <summary>The game whose functions and classes the scripts have</summary>
    function Game: TScriptGame;
    /// <summary>The names that a script can test with {$IFDEF}, for the game (see TScriptDefines)</summary>
    function Defines: TArray<string>;
  end;

implementation

end.
