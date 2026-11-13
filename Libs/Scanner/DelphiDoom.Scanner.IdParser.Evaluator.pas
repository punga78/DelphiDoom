{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdParserEvaluator, the #if / $evalint        }
{  expression evaluator of the idTech 4 parser                                 }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idParser::EvaluateTokens,      }
{  PC_OperatorPriority (idlib\Parser.cpp).                                     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdParser.Evaluator;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token;

type
  /// <summary>Tells if a name is a define (the <c>defined(name)</c> operator)</summary>
  TIdParserDefinedFunc = reference to function(const AName: AnsiString): Boolean;
  /// <summary>Reports a problem (the parser's Error: it raises or logs, as the flags say)</summary>
  TIdParserMessageProc = reference to procedure(const AText: string);

  /// <summary>
  ///   Calculates a list of tokens as a C preprocessor expression, with the operators and priorities
  ///   of the original: integers are 32-bit (<c>signed long int</c> of Win32), and the integer
  ///   and the floating point value are calculated together. At most 64 values and 64 operators. The
  ///   problems go to the message procedure; when it does not raise the evaluation stops
  ///   and the result is false with zero values.
  /// </summary>
  TIdParserEvaluator = class
  strict private
    type
      TOperator = record
        Op: Integer;
        Priority: Integer;
        Parentheses: Integer;
      end;
      TValue = record
        IntValue: Integer;
        FloatValue: Double;
        Parentheses: Integer;
      end;
  strict private
    FIsDefined: TIdParserDefinedFunc;
    FOnError: TIdParserMessageProc;
    class function SarInteger(const AValue, ACount: Integer): Integer; static;
    procedure Error(const AText: string);
  public
    constructor Create(const AIsDefined: TIdParserDefinedFunc; const AOnError: TIdParserMessageProc);
    /// <summary>PC_OperatorPriority: 0 for an operator it does not know</summary>
    class function OperatorPriority(const AOp: Integer): Integer; static;
    /// <summary>
    ///   idParser::EvaluateTokens. <c>AInteger</c> false: the float operators only
    ///   (the integer ones are errors)
    /// </summary>
    function Evaluate(const ATokens: TArray<TIdToken>; const AInteger: Boolean; out AIntValue: Integer;
      out AFloatValue: Double): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types;

{ TIdParserEvaluator }

constructor TIdParserEvaluator.Create(const AIsDefined: TIdParserDefinedFunc; const AOnError: TIdParserMessageProc);
begin
  inherited Create;
  FIsDefined := AIsDefined;
  FOnError := AOnError;
end;

procedure TIdParserEvaluator.Error(const AText: string);
begin
  if Assigned(FOnError) then
    FOnError(AText);
end;

class function TIdParserEvaluator.SarInteger(const AValue, ACount: Integer): Integer;
var
  LCount: Integer;
begin
  // the shift count of the x86 is taken modulo 32 (the C++ result is undefined from 32 on)
  LCount := ACount and 31;
  if LCount = 0 then
    Exit(AValue);
  if AValue >= 0 then
    Result := AValue shr LCount
  else
    Result := Integer((Cardinal(AValue) shr LCount) or (not (Cardinal($FFFFFFFF) shr LCount)));
end;

class function TIdParserEvaluator.OperatorPriority(const AOp: Integer): Integer;
begin
  case AOp of
    P_MUL, P_DIV, P_MOD: Result := 15;
    P_ADD, P_SUB: Result := 14;
    P_LOGIC_AND: Result := 7;
    P_LOGIC_OR: Result := 6;
    P_LOGIC_GEQ, P_LOGIC_LEQ, P_LOGIC_GREATER, P_LOGIC_LESS: Result := 12;
    P_LOGIC_EQ, P_LOGIC_UNEQ: Result := 11;
    P_LOGIC_NOT, P_BIN_NOT: Result := 16;
    P_RSHIFT, P_LSHIFT: Result := 13;
    P_BIN_AND: Result := 10;
    P_BIN_OR: Result := 8;
    P_BIN_XOR: Result := 9;
    P_COLON, P_QUESTIONMARK: Result := 5;
  else
    Result := 0;
  end;
end;

function TIdParserEvaluator.Evaluate(const ATokens: TArray<TIdToken>; const AInteger: Boolean;
  out AIntValue: Integer; out AFloatValue: Double): Boolean;
const
  MAX_VALUES = 64;
  MAX_OPERATORS = 64;
var
  LOps: array[0..MAX_OPERATORS - 1] of TOperator;
  LVals: array[0..MAX_VALUES - 1] of TValue;
  LOpCount, LValCount: Integer;
  LIndex, LOpIndex, LValIndex, LDelete, LShiftIndex: Integer;
  LToken: TIdToken;
  LBrace: Boolean;
  LParentheses: Integer;
  LError: Boolean;
  LLastWasValue: Boolean;
  LNegativeValue: Boolean;
  LQuestIntValue: Integer;
  LQuestFloatValue: Double;
  LGotQuestValue: Boolean;
  LOp: Integer;
  LValue: TValue;

  procedure AddValue(const AInt: Integer; const AFloat: Double);
  begin
    LValue.IntValue := AInt;
    LValue.FloatValue := AFloat;
    LValue.Parentheses := LParentheses;
    LVals[LValCount] := LValue;
    Inc(LValCount);
  end;

  function TokenText(const AToken: TIdToken): string;
  begin
    Result := string(AToken.Text);
  end;

  function BoolInt(const AValue: Boolean): Integer;
  begin
    if AValue then
      Result := 1
    else
      Result := 0;
  end;

  function BoolFloat(const AValue: Boolean): Double;
  begin
    if AValue then
      Result := 1
    else
      Result := 0;
  end;

begin
  LOpCount := 0;
  LValCount := 0;
  LBrace := False;
  LParentheses := 0;
  LError := False;
  LLastWasValue := False;
  LNegativeValue := False;
  AIntValue := 0;
  AFloatValue := 0;
  LIndex := 0;
  while LIndex < System.Length(ATokens) do
  begin
    LToken := ATokens[LIndex];
    case LToken.TokenType of
      TT_NAME:
        begin
          if LLastWasValue or LNegativeValue then
          begin
            Error('syntax error in #if/#elif');
            LError := True;
          end
          else if not LToken.IsText('defined') then
          begin
            Error(Format('undefined name ''%s'' in #if/#elif', [TokenText(LToken)]));
            LError := True;
          end
          else
          begin
            Inc(LIndex);
            // the original reads past the end here when "defined" is the last token
            if (LIndex < System.Length(ATokens)) and ATokens[LIndex].IsText('(') then
            begin
              LBrace := True;
              Inc(LIndex);
            end;
            if (LIndex >= System.Length(ATokens)) or (ATokens[LIndex].TokenType <> TT_NAME) then
            begin
              Error('defined() without name in #if/#elif');
              LError := True;
            end
            else if LValCount >= MAX_VALUES then
            begin
              Error('out of value space'#10);
              LError := True;
            end
            else
            begin
              if FIsDefined(ATokens[LIndex].Text) then
                AddValue(1, 1)
              else
                AddValue(0, 0);
              if LBrace then
              begin
                Inc(LIndex);
                if (LIndex >= System.Length(ATokens)) or not ATokens[LIndex].IsText(')') then
                begin
                  Error('defined missing ) in #if/#elif');
                  LError := True;
                end;
              end;
              LBrace := False;
              // defined() creates a value
              if not LError then
                LLastWasValue := True;
            end;
          end;
        end;
      TT_NUMBER:
        begin
          if LLastWasValue then
          begin
            Error('syntax error in #if/#elif');
            LError := True;
          end
          else if LValCount >= MAX_VALUES then
          begin
            Error('out of value space'#10);
            LError := True;
          end
          else
          begin
            if LNegativeValue then
              AddValue(-LToken.GetIntValue, -LToken.GetFloatValue)
            else
              AddValue(LToken.GetIntValue, LToken.GetFloatValue);
            LLastWasValue := True;
            LNegativeValue := False;
          end;
        end;
      TT_PUNCTUATION:
        begin
          if LNegativeValue then
          begin
            Error('misplaced minus sign in #if/#elif');
            LError := True;
          end
          else if LToken.SubType = P_PARENTHESESOPEN then
            Inc(LParentheses)
          else if LToken.SubType = P_PARENTHESESCLOSE then
          begin
            Dec(LParentheses);
            if LParentheses < 0 then
            begin
              Error('too many ) in #if/#elsif');
              LError := True;
            end;
          end
          else
          begin
            // invalid operators on floating point values
            if (not AInteger) and (LToken.SubType in [P_BIN_NOT, P_MOD, P_RSHIFT, P_LSHIFT, P_BIN_AND,
              P_BIN_OR, P_BIN_XOR]) then
            begin
              Error(Format('illigal operator ''%s'' on floating point operands'#10, [TokenText(LToken)]));
              LError := True;
            end
            else
            begin
              case LToken.SubType of
                P_LOGIC_NOT, P_BIN_NOT:
                  if LLastWasValue then
                  begin
                    Error('! or ~ after value in #if/#elif');
                    LError := True;
                  end;
                P_INC, P_DEC:
                  // an error message only: the original goes on (and adds the operator)
                  Error('++ or -- used in #if/#elif');
                P_SUB:
                  // the original falls through to the binary operators when a value came before
                  if not LLastWasValue then
                    LNegativeValue := True;
                P_MUL, P_DIV, P_MOD, P_ADD, P_LOGIC_AND, P_LOGIC_OR, P_LOGIC_GEQ, P_LOGIC_LEQ, P_LOGIC_EQ,
                P_LOGIC_UNEQ, P_LOGIC_GREATER, P_LOGIC_LESS, P_RSHIFT, P_LSHIFT, P_BIN_AND, P_BIN_OR,
                P_BIN_XOR, P_COLON, P_QUESTIONMARK:
                  if not LLastWasValue then
                  begin
                    Error(Format('operator ''%s'' after operator in #if/#elif', [TokenText(LToken)]));
                    LError := True;
                  end;
              else
                Error(Format('invalid operator ''%s'' in #if/#elif', [TokenText(LToken)]));
                LError := True;
              end;
              if (not LError) and (not LNegativeValue) then
              begin
                if LOpCount >= MAX_OPERATORS then
                begin
                  Error('out of operator space'#10);
                  LError := True;
                end
                else
                begin
                  LOps[LOpCount].Op := LToken.SubType;
                  LOps[LOpCount].Priority := OperatorPriority(LToken.SubType);
                  LOps[LOpCount].Parentheses := LParentheses;
                  Inc(LOpCount);
                  LLastWasValue := False;
                end;
              end;
            end;
          end;
        end;
    else
      Error(Format('unknown ''%s'' in #if/#elif', [TokenText(LToken)]));
      LError := True;
    end;
    if LError then
      Break;
    Inc(LIndex);
  end;
  if not LError then
  begin
    if not LLastWasValue then
    begin
      Error('trailing operator in #if/#elif');
      LError := True;
    end
    else if LParentheses <> 0 then
    begin
      Error('too many ( in #if/#elif');
      LError := True;
    end;
  end;
  LGotQuestValue := False;
  LQuestIntValue := 0;
  LQuestFloatValue := 0;
  // while there are operators
  while (not LError) and (LOpCount > 0) do
  begin
    LValIndex := 0;
    LOpIndex := 0;
    while LOpIndex < LOpCount - 1 do
    begin
      // the current operator is nested deeper in parentheses than the next one
      if LOps[LOpIndex].Parentheses > LOps[LOpIndex + 1].Parentheses then
        Break;
      // equally deep and the priority of the current operator is equal or higher
      if (LOps[LOpIndex].Parentheses = LOps[LOpIndex + 1].Parentheses) and
        (LOps[LOpIndex].Priority >= LOps[LOpIndex + 1].Priority) then
        Break;
      // the arity of the operator is not 1
      if (LOps[LOpIndex].Op <> P_LOGIC_NOT) and (LOps[LOpIndex].Op <> P_BIN_NOT) then
        Inc(LValIndex);
      if LValIndex >= LValCount then
      begin
        Error('mising values in #if/#elif');
        LError := True;
        Break;
      end;
      Inc(LOpIndex);
    end;
    if LError then
      Break;
    LOp := LOps[LOpIndex].Op;
    // the original reads a missing second value here (it cannot happen after the checks above,
    // except after "++" or "--" under a non-fatal error flag)
    if (LOp <> P_LOGIC_NOT) and (LOp <> P_BIN_NOT) and (LValIndex + 1 >= LValCount) then
    begin
      Error('mising values in #if/#elif');
      LError := True;
      Break;
    end;
    case LOp of
      P_LOGIC_NOT:
        begin
          LVals[LValIndex].IntValue := BoolInt(LVals[LValIndex].IntValue = 0);
          LVals[LValIndex].FloatValue := BoolFloat(LVals[LValIndex].FloatValue = 0);
        end;
      P_BIN_NOT:
        LVals[LValIndex].IntValue := not LVals[LValIndex].IntValue;
      P_MUL:
        begin
          LVals[LValIndex].IntValue := LVals[LValIndex].IntValue * LVals[LValIndex + 1].IntValue;
          LVals[LValIndex].FloatValue := LVals[LValIndex].FloatValue * LVals[LValIndex + 1].FloatValue;
        end;
      P_DIV:
        if (LVals[LValIndex + 1].IntValue = 0) or (LVals[LValIndex + 1].FloatValue = 0) then
        begin
          Error('divide by zero in #if/#elif'#10);
          LError := True;
        end
        else
        begin
          // INT_MIN / -1 traps in C++; here it wraps
          if LVals[LValIndex + 1].IntValue = -1 then
            LVals[LValIndex].IntValue := -LVals[LValIndex].IntValue
          else
            LVals[LValIndex].IntValue := LVals[LValIndex].IntValue div LVals[LValIndex + 1].IntValue;
          LVals[LValIndex].FloatValue := LVals[LValIndex].FloatValue / LVals[LValIndex + 1].FloatValue;
        end;
      P_MOD:
        if LVals[LValIndex + 1].IntValue = 0 then
        begin
          Error('divide by zero in #if/#elif'#10);
          LError := True;
        end
        else if LVals[LValIndex + 1].IntValue = -1 then
          LVals[LValIndex].IntValue := 0
        else
          LVals[LValIndex].IntValue := LVals[LValIndex].IntValue mod LVals[LValIndex + 1].IntValue;
      P_ADD:
        begin
          LVals[LValIndex].IntValue := LVals[LValIndex].IntValue + LVals[LValIndex + 1].IntValue;
          LVals[LValIndex].FloatValue := LVals[LValIndex].FloatValue + LVals[LValIndex + 1].FloatValue;
        end;
      P_SUB:
        begin
          LVals[LValIndex].IntValue := LVals[LValIndex].IntValue - LVals[LValIndex + 1].IntValue;
          LVals[LValIndex].FloatValue := LVals[LValIndex].FloatValue - LVals[LValIndex + 1].FloatValue;
        end;
      P_LOGIC_AND:
        begin
          LVals[LValIndex].IntValue := BoolInt((LVals[LValIndex].IntValue <> 0) and
            (LVals[LValIndex + 1].IntValue <> 0));
          LVals[LValIndex].FloatValue := BoolFloat((LVals[LValIndex].FloatValue <> 0) and
            (LVals[LValIndex + 1].FloatValue <> 0));
        end;
      P_LOGIC_OR:
        begin
          LVals[LValIndex].IntValue := BoolInt((LVals[LValIndex].IntValue <> 0) or
            (LVals[LValIndex + 1].IntValue <> 0));
          LVals[LValIndex].FloatValue := BoolFloat((LVals[LValIndex].FloatValue <> 0) or
            (LVals[LValIndex + 1].FloatValue <> 0));
        end;
      P_LOGIC_GEQ:
        begin
          LVals[LValIndex].IntValue := BoolInt(LVals[LValIndex].IntValue >= LVals[LValIndex + 1].IntValue);
          LVals[LValIndex].FloatValue := BoolFloat(LVals[LValIndex].FloatValue >= LVals[LValIndex + 1].FloatValue);
        end;
      P_LOGIC_LEQ:
        begin
          LVals[LValIndex].IntValue := BoolInt(LVals[LValIndex].IntValue <= LVals[LValIndex + 1].IntValue);
          LVals[LValIndex].FloatValue := BoolFloat(LVals[LValIndex].FloatValue <= LVals[LValIndex + 1].FloatValue);
        end;
      P_LOGIC_EQ:
        begin
          LVals[LValIndex].IntValue := BoolInt(LVals[LValIndex].IntValue = LVals[LValIndex + 1].IntValue);
          LVals[LValIndex].FloatValue := BoolFloat(LVals[LValIndex].FloatValue = LVals[LValIndex + 1].FloatValue);
        end;
      P_LOGIC_UNEQ:
        begin
          LVals[LValIndex].IntValue := BoolInt(LVals[LValIndex].IntValue <> LVals[LValIndex + 1].IntValue);
          LVals[LValIndex].FloatValue := BoolFloat(LVals[LValIndex].FloatValue <> LVals[LValIndex + 1].FloatValue);
        end;
      P_LOGIC_GREATER:
        begin
          LVals[LValIndex].IntValue := BoolInt(LVals[LValIndex].IntValue > LVals[LValIndex + 1].IntValue);
          LVals[LValIndex].FloatValue := BoolFloat(LVals[LValIndex].FloatValue > LVals[LValIndex + 1].FloatValue);
        end;
      P_LOGIC_LESS:
        begin
          LVals[LValIndex].IntValue := BoolInt(LVals[LValIndex].IntValue < LVals[LValIndex + 1].IntValue);
          LVals[LValIndex].FloatValue := BoolFloat(LVals[LValIndex].FloatValue < LVals[LValIndex + 1].FloatValue);
        end;
      P_RSHIFT:
        LVals[LValIndex].IntValue := SarInteger(LVals[LValIndex].IntValue, LVals[LValIndex + 1].IntValue);
      P_LSHIFT:
        LVals[LValIndex].IntValue := Integer(Cardinal(LVals[LValIndex].IntValue) shl
          (LVals[LValIndex + 1].IntValue and 31));
      P_BIN_AND:
        LVals[LValIndex].IntValue := LVals[LValIndex].IntValue and LVals[LValIndex + 1].IntValue;
      P_BIN_OR:
        LVals[LValIndex].IntValue := LVals[LValIndex].IntValue or LVals[LValIndex + 1].IntValue;
      P_BIN_XOR:
        LVals[LValIndex].IntValue := LVals[LValIndex].IntValue xor LVals[LValIndex + 1].IntValue;
      P_COLON:
        if not LGotQuestValue then
        begin
          Error(': without ? in #if/#elif');
          LError := True;
        end
        else
        begin
          if AInteger then
          begin
            if LQuestIntValue = 0 then
              LVals[LValIndex].IntValue := LVals[LValIndex + 1].IntValue;
          end
          else if LQuestFloatValue = 0 then
            LVals[LValIndex].FloatValue := LVals[LValIndex + 1].FloatValue;
          LGotQuestValue := False;
        end;
      P_QUESTIONMARK:
        if LGotQuestValue then
        begin
          Error('? after ? in #if/#elif');
          LError := True;
        end
        else
        begin
          LQuestIntValue := LVals[LValIndex].IntValue;
          LQuestFloatValue := LVals[LValIndex].FloatValue;
          LGotQuestValue := True;
        end;
    end;
    if LError then
      Break;
    // not an operator with arity 1
    if (LOp <> P_LOGIC_NOT) and (LOp <> P_BIN_NOT) then
    begin
      // remove the second value, or the first one for the question mark
      if LOp <> P_QUESTIONMARK then
        LDelete := LValIndex + 1
      else
        LDelete := LValIndex;
      for LShiftIndex := LDelete to LValCount - 2 do
        LVals[LShiftIndex] := LVals[LShiftIndex + 1];
      Dec(LValCount);
    end;
    // remove the operator
    for LShiftIndex := LOpIndex to LOpCount - 2 do
      LOps[LShiftIndex] := LOps[LShiftIndex + 1];
    Dec(LOpCount);
  end;
  if LValCount > 0 then
  begin
    AIntValue := LVals[0].IntValue;
    AFloatValue := LVals[0].FloatValue;
  end;
  Result := not LError;
  if not Result then
  begin
    AIntValue := 0;
    AFloatValue := 0;
  end;
end;

end.
