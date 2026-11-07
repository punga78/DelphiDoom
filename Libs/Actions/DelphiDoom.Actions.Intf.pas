{******************************************************************************}
{                                                                              }
{  DelphiDoom: actions library - the registry of the state actions             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Actions.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   One registered action. The handler is an opaque code pointer: the library does not know the
  ///   types of the engine, the engine casts it back to its procedure type. A nil handler is the
  ///   action "NULL" of a state without action
  /// </summary>
  TActionEntry = record
    /// <summary>The code of the action (nil for NULL)</summary>
    Handler: Pointer;
    /// <summary>The name as it was registered, without the prefix "A_"</summary>
    OriginalName: string;
    /// <summary>The name in upper case, without the prefix "A_"</summary>
    Name: string;
    /// <summary>The values of the arguments that a state does not set; its length is the number of arguments</summary>
    DefaultArguments: TArray<Integer>;
    /// <summary>The declaration as the script compiler wants it (empty if there is none)</summary>
    Declaration: string;
  end;

  /// <summary>
  ///   The table of the actions that a state can run (A_Look, A_Chase, the ones of ACTORDEF and
  ///   MBF21). An action has an index, the number that a DEHACKED patch can use, and a name that
  ///   is found without looking at the case and with or without the prefix "A_". There is no
  ///   fixed limit on the number of actions
  /// </summary>
  IActionRegistry = interface
    ['{4D8E2B7A-9C31-4F65-A0E8-5B17C3D96F24}']
    /// <summary>
    ///   Adds an action and gives its index. A name (the prefix "A_" and the case do not count)
    ///   that is already there with a different handler is an error; with the same handler the
    ///   slot is kept, because the index is a number that patches can use, and a search by name
    ///   keeps giving the first one
    /// </summary>
    function Register(const AName: string; AHandler: Pointer;
      const ADefaultArguments: array of Integer; const ADeclaration: string): Integer;
    /// <summary>The number of registered actions</summary>
    function Count: Integer;
    /// <summary>The action at an index; an index out of range is an error</summary>
    function Entry(AIndex: Integer): TActionEntry;
    /// <summary>The index of the action with that name, or -1</summary>
    function IndexOfName(const AName: string): Integer;
    /// <summary>The index of the first action with that handler, or -1</summary>
    function IndexOfHandler(AHandler: Pointer): Integer;
    /// <summary>The name (upper case, no prefix) of the first action with that handler, or an empty string</summary>
    function NameOfHandler(AHandler: Pointer): string;
    /// <summary>The names in the order of registration, one for each index</summary>
    function Names: TArray<string>;
    /// <summary>The names in alphabetical order, without repetitions</summary>
    function SortedNames: TArray<string>;
  end;

  /// <summary>An action registered twice with different handlers, an index out of range</summary>
  EActionRegistryException = class(Exception);

implementation

end.
