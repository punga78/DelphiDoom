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
    /// <summary>The routine, called with the register convention (a plain procedure or function, or a method)</summary>
    Code: Pointer;
    /// <summary>The object that Code is a method of (the Self of the call); nil for a plain routine</summary>
    Instance: Pointer;
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

  /// <summary>The games that have their own functions in the units of script</summary>
  TScriptGame = (sgDoom, sgHeretic, sgHexen, sgStrife);

  /// <summary>A set of games</summary>
  TScriptGameSet = set of TScriptGame;

  /// <summary>
  ///   The keys and the buttons that scripts can ask for (key_right, mousebfire...): the union of
  ///   the ones that the four games have, in the order of the declarations
  /// </summary>
  TScriptKey = (
    skRight, skLeft, skUp, skDown, skLookUp, skLookDown, skLookCenter, skLookRight, skLookLeft,
    skLookForward, skStrafeLeft, skStrafeRight, skFire, skUse, skStrafe, skSpeed, skJump, skCrouch,
    skWeapon0, skWeapon1, skWeapon2, skWeapon3, skWeapon4, skWeapon5, skWeapon6, skWeapon7,
    skWeapon8, skWeapon9, skFlyUp, skFlyDown, skFlyCenter, skInvLeft, skInvRight, skUseArtifact,
    skUseHealth, skInvQuery, skMission, skInvPop, skInvKey, skInvHome, skInvEnd, skInvUse,
    skInvDrop, skMouseFire, skMouseStrafe, skMouseForward, skJoyFire, skJoyStrafe, skJoyUse,
    skJoySpeed, skJoyJump, skJoyCrouch, skJoyLeft, skJoyRight
  );

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
