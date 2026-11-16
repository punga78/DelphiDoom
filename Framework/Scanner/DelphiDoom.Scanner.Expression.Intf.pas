{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the contracts of the expression evaluator      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Expression.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   A function of the expressions: the arguments are texts (a text between quotes keeps
  ///   its quotes), the result is a text
  /// </summary>
  TExpressionFunction = reference to function(const AParams: TArray<string>): string;

  /// <summary>The variables that an expression can name</summary>
  IExpressionVariables = interface
    ['{9A4E21D7-60B3-4F85-A1C9-3D7E58B02F64}']
    /// <summary>True if the name is a variable</summary>
    function Contains(const AName: string): Boolean;
    /// <summary>The value of the variable as a text</summary>
    function ValueOf(const AName: string): string;
  end;

  /// <summary>
  ///   An expression that cannot be built or evaluated (a function registered twice, a
  ///   missing operand ...). A wrong expression that the old code only warned about is a
  ///   warning to the log here too
  /// </summary>
  EExpressionException = class(Exception);

implementation

end.
