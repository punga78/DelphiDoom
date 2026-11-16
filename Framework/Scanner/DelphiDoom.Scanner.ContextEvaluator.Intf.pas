{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the contracts of the expressions on a context  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.ContextEvaluator.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   A function of the expressions that reads a context (for the engine, the actor whose
  ///   parameters are evaluated). The context is an opaque pointer: the library never looks
  ///   at it. The arguments are texts as in TExpressionFunction
  /// </summary>
  TContextExpressionFunction = reference to function(AContext: Pointer;
    const AParams: TArray<string>): string;

  /// <summary>Where the functions that read the context are added</summary>
  IContextFunctionRegistry = interface
    ['{1E6A3F52-B7C4-4D19-8E05-72A9C3D6F481}']
    /// <summary>
    ///   Adds a function; the name is read in upper case and a name already used is an
    ///   EExpressionException. A function without arguments (AParams = 0) is also a
    ///   single token (IsSingleToken)
    /// </summary>
    procedure AddFunction(const AName: string; const AFunction: TContextExpressionFunction;
      AParams: Integer);
  end;

  /// <summary>Evaluates the expressions of the parameters of an actor (the old SC_EvaluateActorExpression)</summary>
  IContextExpressionEvaluator = interface
    ['{8B47D0C3-2F95-4A6E-B13D-E6C058A7942F}']
    /// <summary>
    ///   The value of the expression with AContext as the context of the functions. An
    ///   expression that raises an exception gives back its own text
    /// </summary>
    function Evaluate(AContext: Pointer; const AExpression: string): string;
    /// <summary>True for the name (any case) of a function that takes no arguments</summary>
    function IsSingleToken(const AToken: string): Boolean;
  end;

implementation

end.
