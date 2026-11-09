{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - shared types and constants                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Raised by the registry of the host functions when it is used in a wrong way (a unit of
  ///   script that is registered twice, or a group without a name)
  /// </summary>
  EScriptHostException = class(Exception);

  /// <summary>
  ///   One host function that scripts can call: the declaration that the compiler of the scripts
  ///   reads, the address that the interpreter calls and what the registration of the compiler
  ///   gave back
  /// </summary>
  TScriptFunctionEntry = record
    /// <summary>The routine, called with the register convention (a plain procedure or function)</summary>
    Code: Pointer;
    /// <summary>The declaration for the compiler, with the closing semicolon</summary>
    Declaration: string;
    /// <summary>Empty, or the (RTL) class that the function gives back instead of a plain type</summary>
    ResultType: string;
    /// <summary>The declaration that tools show (the editor of the scripts)</summary>
    ExportDeclaration: string;
    /// <summary>The upper case name that the compiler gave to the function, empty before the first compilation</summary>
    Name: string;
    /// <summary>True if the interpreter has to register the function</summary>
    Computed: Boolean;
  end;

const
  /// <summary>The unit of the scripts that every script has</summary>
  SCRIPT_UNIT_SYSTEM = 'SYSTEM';
  /// <summary>The name that a script uses to load all the units but SYSTEM</summary>
  SCRIPT_UNIT_ALL = 'ALL';

resourcestring
  SScriptUnitAlreadyRegistered = 'The unit of script "%s" is already registered';
  SScriptUnitWithoutName = 'A group of script functions needs a name';
  SScriptGroupIsNil = 'The group of script functions is nil';

implementation

end.
