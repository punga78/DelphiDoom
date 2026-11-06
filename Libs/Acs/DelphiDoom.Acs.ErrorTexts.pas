{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the texts of the errors                 }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.ErrorTexts;

interface

type
  TAcsErrorTexts = class
  public
    /// <summary>The text of an error code; empty if there is none</summary>
    class function TextOf(ACode: Integer): string; static;
  end;

implementation

uses
  DelphiDoom.Acs.ErrorCodes;

type
  TAcsErrorText = record
    Code: Integer;
    Text: string;
  end;

const
  ERROR_TEXTS: array[0..69] of TAcsErrorText = (
    (Code: ERR_MISSING_SEMICOLON; Text: 'Missing semicolon.'),
    (Code: ERR_MISSING_LPAREN; Text: 'Missing ''(''.'),
    (Code: ERR_MISSING_RPAREN; Text: 'Missing '')''.'),
    (Code: ERR_MISSING_SCRIPT_NUMBER; Text: 'Missing script number.'),
    (Code: ERR_IDENTIFIER_TOO_LONG; Text: 'Identifier too long.'),
    (Code: ERR_STRING_TOO_LONG; Text: 'String too long.'),
    (Code: ERR_FILE_NAME_TOO_LONG; Text: 'File name too long.'),
    (Code: ERR_BAD_CHARACTER; Text: 'Bad character in script text.'),
    (Code: ERR_ALLOC_PCODE_BUFFER; Text: 'Failed to allocate PCODE buffer.'),
    (Code: ERR_PCODE_BUFFER_OVERFLOW; Text: 'PCODE buffer overflow.'),
    (Code: ERR_TOO_MANY_SCRIPTS; Text: 'Too many scripts.'),
    (Code: ERR_SAVE_OBJECT_FAILED; Text: 'Couldn''t save object file.'),
    (Code: ERR_MISSING_LPAREN_SCR; Text: 'Missing ''('' in script definition.'),
    (Code: ERR_INVALID_IDENTIFIER; Text: 'Invalid identifier.'),
    (Code: ERR_REDEFINED_IDENTIFIER; Text: 'Redefined identifier.'),
    (Code: ERR_MISSING_COMMA; Text: 'Missing comma.'),
    (Code: ERR_BAD_VAR_TYPE; Text: 'Invalid variable type.'),
    (Code: ERR_TOO_MANY_SCRIPT_ARGS; Text: 'Too many script arguments.'),
    (Code: ERR_MISSING_LBRACE_SCR; Text: 'Missing opening ''{'' in script definition.'),
    (Code: ERR_MISSING_RBRACE_SCR; Text: 'Missing closing ''}'' in script definition.'),
    (Code: ERR_TOO_MANY_MAP_VARS; Text: 'Too many map variables.'),
    (Code: ERR_TOO_MANY_SCRIPT_VARS; Text: 'Too many script variables.'),
    (Code: ERR_MISSING_WVAR_INDEX; Text: 'Missing index in world variable declaration.'),
    (Code: ERR_BAD_WVAR_INDEX; Text: 'World variable index out of range.'),
    (Code: ERR_MISSING_WVAR_COLON; Text: 'Missing colon in world variable declaration.'),
    (Code: ERR_MISSING_SPEC_VAL; Text: 'Missing value in special declaration.'),
    (Code: ERR_MISSING_SPEC_COLON; Text: 'Missing colon in special declaration.'),
    (Code: ERR_MISSING_SPEC_ARGC; Text: 'Missing argument count in special declaration.'),
    (Code: ERR_CANT_READ_FILE; Text: 'Couldn''t read file.'),
    (Code: ERR_CANT_OPEN_FILE; Text: 'Couldn''t open file.'),
    (Code: ERR_CANT_OPEN_DBGFILE; Text: 'Couldn''t open debug file.'),
    (Code: ERR_INVALID_DIRECTIVE; Text: 'Invalid directive.'),
    (Code: ERR_BAD_DEFINE; Text: 'Non-numeric constant found in #define.'),
    (Code: ERR_INCL_NESTING_TOO_DEEP; Text: 'Include nesting too deep.'),
    (Code: ERR_STRING_LIT_NOT_FOUND; Text: 'String literal not found.'),
    (Code: ERR_INVALID_DECLARATOR; Text: 'Invalid declarator.'),
    (Code: ERR_BAD_LSPEC_ARG_COUNT; Text: 'Incorrect number of special arguments.'),
    (Code: ERR_BAD_ARG_COUNT; Text: 'Incorrect number of arguments.'),
    (Code: ERR_UNKNOWN_IDENTIFIER; Text: 'Identifier has not been declared.'),
    (Code: ERR_MISSING_COLON; Text: 'Missing colon.'),
    (Code: ERR_BAD_EXPR; Text: 'Syntax error in expression.'),
    (Code: ERR_BAD_CONST_EXPR; Text: 'Syntax error in constant expression.'),
    (Code: ERR_NO_DIRECT_VER; Text: 'Internal function has no direct version.'),
    (Code: ERR_ILLEGAL_EXPR_IDENT; Text: 'Illegal identifier in expression.'),
    (Code: ERR_EXPR_FUNC_NO_RET_VAL; Text: 'Function call in expression has no return value.'),
    (Code: ERR_MISSING_ASSIGN_OP; Text: 'Missing assignment operator.'),
    (Code: ERR_INCDEC_OP_ON_NON_VAR; Text: '''++'' or ''--'' used on a non-variable.'),
    (Code: ERR_MISSING_RBRACE; Text: 'Missing ''}'' at end of compound statement.'),
    (Code: ERR_INVALID_STATEMENT; Text: 'Invalid statement.'),
    (Code: ERR_BAD_DO_STATEMENT; Text: 'Do statement not followed by ''while'' or ''until''.'),
    (Code: ERR_BAD_SCRIPT_DECL; Text: 'Bad script declaration.'),
    (Code: ERR_CASE_OVERFLOW; Text: 'Internal Error: stack overflow.'),
    (Code: ERR_BREAK_OVERFLOW; Text: 'Internal Error: Break stack overflow.'),
    (Code: ERR_CONTINUE_OVERFLOW; Text: 'Internal Error: Continue stack overflow.'),
    (Code: ERR_STATEMENT_OVERFLOW; Text: 'Internal Error: Statement overflow.'),
    (Code: ERR_MISPLACED_BREAK; Text: 'Misplaced BREAK statement.'),
    (Code: ERR_MISPLACED_CONTINUE; Text: 'Misplaced CONTINUE statement.'),
    (Code: ERR_CASE_NOT_IN_SWITCH; Text: 'CASE must appear in case statement.'),
    (Code: ERR_DEFAULT_NOT_IN_SWITCH; Text: 'DEFAULT must appear in case statement.'),
    (Code: ERR_MULTIPLE_DEFAULT; Text: 'Only 1 DEFAULT per case allowed.'),
    (Code: ERR_EXPR_STACK_OVERFLOW; Text: 'Expression stack overflow.'),
    (Code: ERR_EXPR_STACK_EMPTY; Text: 'Tried to POP empty expression stack.'),
    (Code: ERR_UNKNOWN_CONST_EXPR_PCD; Text: 'Unknown PCD in constant expression.'),
    (Code: ERR_BAD_RADIX_CONSTANT; Text: 'Radix out of range in integer constant.'),
    (Code: ERR_BAD_ASSIGNMENT; Text: 'Syntax error in multiple assignment statement.'),
    (Code: ERR_OUT_OF_MEMORY; Text: 'Out of memory.'),
    (Code: ERR_TOO_MANY_STRINGS; Text: 'Too many strings.'),
    (Code: ERR_UNKNOWN_PRTYPE; Text: 'Unknown cast type in print statement.'),
    (Code: ERR_ALLOC_SCRIPT_BUFFER; Text: 'Can not allocate script buffer.'),
    (Code: ERR_STATEMENT_NOT_IMPLEMENTED; Text: 'This statement is not implemented by the compiler.')
  );

{ TAcsErrorTexts }

class function TAcsErrorTexts.TextOf(ACode: Integer): string;
var
  LIndex: Integer;
begin
  for LIndex := Low(ERROR_TEXTS) to High(ERROR_TEXTS) do
    if ERROR_TEXTS[LIndex].Code = ACode then
    begin
      Result := ERROR_TEXTS[LIndex].Text;
      Exit;
    end;
  Result := '';
end;

end.