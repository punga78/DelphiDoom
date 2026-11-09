{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the contracts of the registry of host functions   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Intf;

interface

uses
  ps_compiler,
  ps_runtime;

type
  /// <summary>Where a group writes the functions that scripts can call</summary>
  IScriptFunctionTable = interface
    ['{5B1E3C7A-94D2-4F0B-A6E8-31C7D90F2B54}']
    /// <summary>
    ///   Adds a function. The declaration is the text that the compiler of the scripts reads
    ///   (a closing semicolon is added if it is missing); ACode is the routine to call. An empty
    ///   declaration is ignored
    /// </summary>
    procedure Add(const ADeclaration: string; const ACode: Pointer);
    /// <summary>
    ///   Adds a procedure that gives back an object of a class of the scripts: the compiler reads
    ///   the declaration with AResultType as its result, tools show AExportDeclaration
    /// </summary>
    procedure AddWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const ACode: Pointer);
    /// <summary>
    ///   Adds a function that is a method of AInstance (ACode is the address of the method, as
    ///   @TClass.Method gives it): the interpreter calls it with AInstance as Self. The object
    ///   must live as long as the interpreters that registered it
    /// </summary>
    procedure AddMethod(const ADeclaration: string; const AInstance: TObject; const ACode: Pointer);
  end;

  /// <summary>
  ///   A part of the functions of a unit of script (the keyboard, the textures...): it writes its
  ///   functions in the place of the unit where they have always been, and owns the objects that
  ///   the interpreter calls
  /// </summary>
  IScriptFunctionSection = interface
    ['{3E8F6B24-D1A7-4C95-B0E3-7A52C9D84F16}']
    procedure Describe(const ATable: IScriptFunctionTable);
  end;

  /// <summary>
  ///   A unit of script (SYSTEM, PS_GAME, ...): the group knows its name and the functions that
  ///   belong to it
  /// </summary>
  IScriptFunctionGroup = interface
    ['{C2A47E19-6B3D-4A85-9F10-E58D2B7634A1}']
    /// <summary>The name that a script writes after "uses", in upper case</summary>
    function UnitName: string;
    /// <summary>Writes the functions of the unit, in the order in which scripts see them</summary>
    procedure Describe(const ATable: IScriptFunctionTable);
  end;

  /// <summary>
  ///   The functions that scripts can call, by unit of script. The compiler of the scripts reads
  ///   the declarations and the interpreter gets the routines. The units are kept in the
  ///   alphabetical order of their names, as the scripts have always seen them
  /// </summary>
  IScriptFunctionRegistry = interface
    ['{7D90A5E2-1C48-4B3F-8E6A-A3F5C1280D97}']
    /// <summary>Asks the group for its functions and keeps them; the name of a unit can be registered once</summary>
    procedure AddGroup(const AGroup: IScriptFunctionGroup);
    /// <summary>Forgets a unit; nothing happens if it is not there</summary>
    procedure RemoveGroup(const AUnitName: string);
    /// <summary>True if the unit is registered (the case of the name does not matter)</summary>
    function Contains(const AUnitName: string): Boolean;
    /// <summary>The names of the units, in alphabetical order</summary>
    function UnitNames: TArray<string>;
    /// <summary>The units that "uses all" loads: every one but SYSTEM, in alphabetical order</summary>
    function CompilerUnitNames: TArray<string>;
    /// <summary>The declarations of a unit, one for each line (CR LF), empty for an unknown unit</summary>
    function Declarations(const AUnitName: string): string;
    /// <summary>
    ///   Marks every function as not yet registered by the compiler: only the units that a script
    ///   uses are given to the interpreter (the compiler marks them again)
    /// </summary>
    procedure Reset;
    /// <summary>Gives the declarations of a unit to the compiler; false if the unit is not registered</summary>
    function RegisterCompiler(const AUnitName: string; const ACompiler: TPSPascalCompiler): Boolean;
    /// <summary>
    ///   Gives the routines of a unit to the interpreter, those that the compiler has registered
    ///   in the last compilation; false if the unit is not registered
    /// </summary>
    function RegisterExecutor(const AUnitName: string; const AExecutor: TPSExec): Boolean;
    /// <summary>The same as RegisterExecutor for every unit, SYSTEM included (the unit "all")</summary>
    procedure RegisterExecutorForAll(const AExecutor: TPSExec);
  end;

implementation

end.
