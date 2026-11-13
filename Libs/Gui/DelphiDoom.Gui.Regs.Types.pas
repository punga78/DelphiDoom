{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - types of the registers and expressions            }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.h (wexpOp_t,     }
{  wexpOpType_t) and ui\RegExp.h (idRegister::REGTYPE).                        }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Regs.Types;

interface

uses
  DelphiDoom.Gui.WinVar.Base;

const
  /// <summary>MAX_EXPRESSION_REGISTERS and MAX_EXPRESSION_OPS (idlib\precompiled.h)</summary>
  GUI_MAX_EXPRESSION_REGISTERS = 4096;
  GUI_MAX_EXPRESSION_OPS = 4096;
  /// <summary>WEXP_REG_TIME and WEXP_REG_NUM_PREDEFINED</summary>
  WEXP_REG_TIME = 0;
  WEXP_REG_NUM_PREDEFINED = 1;

type
  /// <summary>idRegister::REGTYPE</summary>
  TGuiRegisterType = (rtVec4, rtFloat, rtBool, rtInt, rtString, rtVec2, rtVec3, rtRectangle);

const
  /// <summary>idRegister::REGCOUNT: how many registers a type uses</summary>
  GUI_REGISTER_COUNT: array[TGuiRegisterType] of Integer = (4, 1, 1, 1, 0, 2, 3, 4);

type
  /// <summary>wexpOpType_t</summary>
  TGuiOpType = (otAdd, otSubtract, otMultiply, otDivide, otMod, otTable, otGt, otGe, otLt, otLe, otEq, otNe,
    otAnd, otOr, otVar, otVars, otVarf, otVari, otVarb, otCond);

  /// <summary>
  ///   wexpOp_t. The original keeps a pointer to a variable (or to the text of a name still to
  ///   resolve) in the integer <c>a</c>; here they are <c>Variable</c> and <c>PendingName</c>, and
  ///   <c>B = -2</c> still marks an operation whose variable is resolved after the parse (FixupParms).
  /// </summary>
  TGuiOp = record
    OpType: TGuiOpType;
    A: Integer;
    B: Integer;
    C: Integer;
    D: Integer;
    Variable: TGuiWinVar;
    PendingName: AnsiString;
  end;

  TGuiRegisters = array[0..GUI_MAX_EXPRESSION_REGISTERS - 1] of Single;

implementation

end.
