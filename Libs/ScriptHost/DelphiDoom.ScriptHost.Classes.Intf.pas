{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the contracts of the classes that scripts see     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Classes.Intf;

interface

uses
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   Gives the object that a variable of the scripts is bound to. It is asked when an interpreter
  ///   loads a script, not when the class is described: the objects are born with the engine
  /// </summary>
  TScriptInstanceProvider = reference to function: TObject;

  /// <summary>
  ///   One class that scripts see (Actors, Lines, MapStrings...): the table of its members. The
  ///   same table feeds the compiler (SIRegister_*) and the interpreter (RIRegister_*), so a
  ///   property is written once. Properties, methods and constructors are registered in the order
  ///   they are added
  /// </summary>
  IScriptClassDescriptor = interface
    ['{7D3A91C4-2E58-4B6F-A0D7-C4E19B53F826}']
    /// <summary>The name that the compiler knows, as it is written ('!TActor')</summary>
    function ScriptName: string;
    /// <summary>
    ///   Adds a property for the compiler and the interpreter, in the games that have it.
    ///   AReader and AWriter are the helpers of the interpreter (nil for a missing one)
    /// </summary>
    procedure AddProperty(const AName, AType: string; const AAccess: TPSPropType;
      const AReader, AWriter: Pointer; const AGames: TScriptGameSet = [sgDoom, sgHeretic, sgHexen, sgStrife]); overload;
    /// <summary>
    ///   Adds a property that the compiler has in ACompilerGames and the interpreter in
    ///   ARuntimeGames (the two sets are not always the same)
    /// </summary>
    procedure AddProperty(const AName, AType: string; const AAccess: TPSPropType;
      const AReader, AWriter: Pointer; const ACompilerGames, ARuntimeGames: TScriptGameSet); overload;
    /// <summary>Adds a property that only the interpreter knows (a script cannot compile a use of it)</summary>
    procedure AddRuntimeProperty(const AName: string; const AReader, AWriter: Pointer);
    /// <summary>Makes a property that was added the default one of the class (the indexed one: Actors[key])</summary>
    procedure AddDefaultProperty(const AName: string);
    /// <summary>Adds a method: the declaration for the compiler, the name and the address for the interpreter</summary>
    procedure AddMethod(const ADeclaration, AName: string; const ACode: Pointer);
    /// <summary>Adds a virtual method (the interpreter registers it with RegisterVirtualMethod)</summary>
    procedure AddVirtualMethod(const ADeclaration, AName: string; const ACode: Pointer);
    /// <summary>Adds the constructor Create, with its address for the interpreter</summary>
    procedure AddConstructor(const ACode: Pointer);
    /// <summary>Adds the virtual constructor Create (the interpreter registers it with RegisterVirtualConstructor)</summary>
    procedure AddVirtualConstructor(const ACode: Pointer);
    /// <summary>
    ///   Adds a variable of the class that every script has (Actors, MapStrings...): the compiler
    ///   knows the name, the interpreter binds the object that AInstance gives to it. The object
    ///   is not owned
    /// </summary>
    procedure AddVariable(const AName: string; const AInstance: TScriptInstanceProvider);
    /// <summary>The names of the properties that the compiler has in AGame, in order</summary>
    function CompilerProperties(const AGame: TScriptGame): TArray<string>;
    /// <summary>The names of the properties that the interpreter has in AGame, in order</summary>
    function RuntimeProperties(const AGame: TScriptGame): TArray<string>;
    /// <summary>Writes the class in the compiler (AClass was created by the catalog)</summary>
    procedure RegisterCompiler(const ACompiler: TPSPascalCompiler; const AClass: TPSCompileTimeClass;
      const AGame: TScriptGame);
    /// <summary>Writes the members in the class of the interpreter</summary>
    procedure RegisterRuntime(const AClass: TPSRuntimeClass; const AGame: TScriptGame);
    /// <summary>Binds the variables of the class to their instances in a loaded interpreter</summary>
    procedure BindVariables(const AExec: TPSExec);
  end;

  /// <summary>The classes that scripts see, for one game</summary>
  IScriptClassCatalog = interface
    ['{E1B64F08-5C93-47A2-8D3E-92A7F5C1B046}']
    /// <summary>The game whose members are registered</summary>
    function Game: TScriptGame;
    /// <summary>
    ///   Adds a class: its name for the compiler and the class that the interpreter calls (the
    ///   instances are the ones of the variables)
    /// </summary>
    function AddClass(const AScriptName: string; const ARuntimeClass: TClass): IScriptClassDescriptor;
    function Count: Integer;
    function ClassAt(const AIndex: Integer): IScriptClassDescriptor;
    /// <summary>Finds a class by its name for the compiler (nil if it is not there)</summary>
    function FindClass(const AScriptName: string): IScriptClassDescriptor;
    /// <summary>Writes all the classes in the compiler: first the classes, then their members</summary>
    procedure RegisterCompiler(const ACompiler: TPSPascalCompiler);
    /// <summary>Writes all the classes in the class importer of the interpreter</summary>
    procedure RegisterRuntime(const AImporter: TPSRuntimeClassImporter);
    /// <summary>Binds the variables of all the classes in an interpreter that loaded a script</summary>
    procedure BindVariables(const AExec: TPSExec);
  end;

implementation

end.
