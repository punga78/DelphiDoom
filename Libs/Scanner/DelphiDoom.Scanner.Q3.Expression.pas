{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3ExpressionEvaluator, the expressions of    }
{  #if, #elif, #eval and $evalint of the precompiler of Quake III Arena        }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_precomp.c (PC_OperatorPriority, PC_EvaluateTokens). Copyright (C)         }
{  1999-2005 Id Software, Inc. Licensed under the GNU General Public License,  }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.Expression;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Scanner.Q3.Types, DelphiDoom.Scanner.Q3.TokenNode, DelphiDoom.Scanner.Q3.DefineHash;

type
  /// <summary>Where the evaluator reports an error (SourceError of the source)</summary>
  TQ3ExpressionError = reference to procedure(const AMessage: AnsiString);

  /// <summary>
  ///   Evaluates a chain of tokens with the 32 bit signed integers and the doubles of the C (both are
  ///   computed, the caller picks one), 64 values and 64 operators at most
  /// </summary>
  TQ3ExpressionEvaluator = class sealed
  public
    /// <summary>PC_OperatorPriority</summary>
    class function OperatorPriority(const AOperator: Integer): Integer; static;
    /// <summary>
    ///   PC_EvaluateTokens. Both results are zero when it returns False. Differences from the C, which reads a
    ///   null pointer there: a "defined" with nothing after it, and a binary operator without its second
    ///   value after "++" or "--", are errors
    /// </summary>
    class function Evaluate(const AHash: TQ3DefineHash; const ATokens: TQ3TokenNode; const AInteger: Boolean;
      const AOnError: TQ3ExpressionError; out AIntValue: Integer; out AFloatValue: Double): Boolean; static;
  end;

implementation

const
  MAX_VALUES = 64;
  MAX_OPERATORS = 64;

type
  TOperatorEntry = record
    Operator: Integer;
    Priority: Integer;
    Parentheses: Integer;
    Prev: Integer;
    Next: Integer;
  end;

  TValueEntry = record
    IntValue: Integer;
    FloatValue: Double;
    Parentheses: Integer;
    Prev: Integer;
    Next: Integer;
  end;

function ShiftRightSigned(const AValue, ACount: Integer): Integer;
var
  LCount: Integer;
begin
  // sar with the count of the processor (modulo 32)
  LCount := ACount and 31;
  if AValue >= 0 then
    Result := AValue shr LCount
  else
    Result := not ((not AValue) shr LCount);
end;

function BoolToInt(const AValue: Boolean): Integer; inline;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

function BoolToFloat(const AValue: Boolean): Double; inline;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

{ TQ3ExpressionEvaluator }

class function TQ3ExpressionEvaluator.OperatorPriority(const AOperator: Integer): Integer;
begin
  case AOperator of
    P_MUL, P_DIV, P_MOD: Result := 15;
    P_ADD, P_SUB: Result := 14;
    P_LOGIC_AND: Result := 7;
    P_LOGIC_OR: Result := 6;
    P_LOGIC_GEQ, P_LOGIC_LEQ: Result := 12;
    P_LOGIC_EQ, P_LOGIC_UNEQ: Result := 11;
    P_LOGIC_NOT: Result := 16;
    P_LOGIC_GREATER, P_LOGIC_LESS: Result := 12;
    P_RSHIFT, P_LSHIFT: Result := 13;
    P_BIN_AND: Result := 10;
    P_BIN_OR: Result := 8;
    P_BIN_XOR: Result := 9;
    P_BIN_NOT: Result := 16;
    P_COLON, P_QUESTIONMARK: Result := 5;
  else
    Result := 0;
  end;
end;

class function TQ3ExpressionEvaluator.Evaluate(const AHash: TQ3DefineHash; const ATokens: TQ3TokenNode;
  const AInteger: Boolean; const AOnError: TQ3ExpressionError; out AIntValue: Integer;
  out AFloatValue: Double): Boolean;
var
  Operators: array[0..MAX_OPERATORS - 1] of TOperatorEntry;
  Values: array[0..MAX_VALUES - 1] of TValueEntry;
  NumOperators: Integer;
  NumValues: Integer;
  FirstOperator: Integer;
  LastOperator: Integer;
  FirstValue: Integer;
  LastValue: Integer;
  T: TQ3TokenNode;
  Brace: Boolean;
  Parentheses: Integer;
  Error: Boolean;
  LastWasValue: Boolean;
  NegativeValue: Boolean;
  QuestMarkIntValue: Integer;
  QuestMarkFloatValue: Double;
  GotQuestMarkValue: Boolean;
  O: Integer;
  V: Integer;
  V1: Integer;
  V2: Integer;
  Cur: Integer;

  procedure Fail(const AMessage: AnsiString);
  begin
    AOnError(AMessage);
    Error := True;
  end;

  // AllocValue and the links of a new value at the end of the list
  function NewValue(const AInt: Integer; const AFloat: Double): Boolean;
  begin
    if NumValues >= MAX_VALUES then
    begin
      Fail('out of value space'#10);
      Exit(False);
    end;
    Cur := NumValues;
    Inc(NumValues);
    Values[Cur].IntValue := AInt;
    Values[Cur].FloatValue := AFloat;
    Values[Cur].Parentheses := Parentheses;
    Values[Cur].Next := -1;
    Values[Cur].Prev := LastValue;
    if LastValue <> -1 then
      Values[LastValue].Next := Cur
    else
      FirstValue := Cur;
    LastValue := Cur;
    Result := True;
  end;

  procedure HandleName;
  begin
    if LastWasValue or NegativeValue then
    begin
      Fail('syntax error in #if/#elif');
      Exit;
    end;
    if T.Token.Text <> 'defined' then
    begin
      Fail('undefined name ' + T.Token.Text + ' in #if/#elif');
      Exit;
    end;
    T := T.Next;
    if (T <> nil) and (T.Token.Text = '(') then
    begin
      Brace := True;
      T := T.Next;
    end;
    if (T = nil) or (T.Token.TokenType <> TT_NAME) then
    begin
      Fail('defined without name in #if/#elif');
      Exit;
    end;
    if AHash.Find(T.Token.Text) <> nil then
    begin
      if not NewValue(1, 1) then
        Exit;
    end
    else if not NewValue(0, 0) then
      Exit;
    if Brace then
    begin
      T := T.Next;
      if (T = nil) or (T.Token.Text <> ')') then
      begin
        Fail('defined without ) in #if/#elif');
        Exit;
      end;
    end;
    Brace := False;
    // defined() creates a value
    LastWasValue := True;
  end;

  procedure HandleNumber;
  begin
    if LastWasValue then
    begin
      Fail('syntax error in #if/#elif');
      Exit;
    end;
    if NegativeValue then
    begin
      if not NewValue(-Integer(T.Token.IntValue), -T.Token.FloatValue.ToDouble) then
        Exit;
    end
    else if not NewValue(Integer(T.Token.IntValue), T.Token.FloatValue.ToDouble) then
      Exit;
    // last token was a value
    LastWasValue := True;
    NegativeValue := False;
  end;

  procedure AddOperator(const AOperator: Integer);
  begin
    if NumOperators >= MAX_OPERATORS then
    begin
      Fail('out of operator space'#10);
      Exit;
    end;
    O := NumOperators;
    Inc(NumOperators);
    Operators[O].Operator := AOperator;
    Operators[O].Priority := OperatorPriority(AOperator);
    Operators[O].Parentheses := Parentheses;
    Operators[O].Next := -1;
    Operators[O].Prev := LastOperator;
    if LastOperator <> -1 then
      Operators[LastOperator].Next := O
    else
      FirstOperator := O;
    LastOperator := O;
    LastWasValue := False;
  end;

  procedure HandlePunctuation;
  var
    LSubtype: Integer;
  begin
    if NegativeValue then
    begin
      Fail('misplaced minus sign in #if/#elif');
      Exit;
    end;
    LSubtype := T.Token.Subtype;
    if LSubtype = P_PARENTHESESOPEN then
    begin
      Inc(Parentheses);
      Exit;
    end
    else if LSubtype = P_PARENTHESESCLOSE then
    begin
      Dec(Parentheses);
      if Parentheses < 0 then
        Fail('too many ) in #if/#elsif');
      Exit;
    end;
    // invalid operators on floating point values
    if not AInteger then
      if (LSubtype = P_BIN_NOT) or (LSubtype = P_MOD) or (LSubtype = P_RSHIFT) or (LSubtype = P_LSHIFT) or
        (LSubtype = P_BIN_AND) or (LSubtype = P_BIN_OR) or (LSubtype = P_BIN_XOR) then
      begin
        Fail('illigal operator ' + T.Token.Text + ' on floating point operands'#10);
        Exit;
      end;
    case LSubtype of
      P_LOGIC_NOT, P_BIN_NOT:
        if LastWasValue then
          Fail('! or ~ after value in #if/#elif');
      P_INC, P_DEC:
        AOnError('++ or -- used in #if/#elif');
      P_SUB:
        if not LastWasValue then
          NegativeValue := True;
      P_MUL, P_DIV, P_MOD, P_ADD, P_LOGIC_AND, P_LOGIC_OR, P_LOGIC_GEQ, P_LOGIC_LEQ, P_LOGIC_EQ, P_LOGIC_UNEQ,
        P_LOGIC_GREATER, P_LOGIC_LESS, P_RSHIFT, P_LSHIFT, P_BIN_AND, P_BIN_OR, P_BIN_XOR, P_COLON,
        P_QUESTIONMARK:
        if not LastWasValue then
          Fail('operator ' + T.Token.Text + ' after operator in #if/#elif');
    else
      Fail('invalid operator ' + T.Token.Text + ' in #if/#elif');
    end;
    if (not Error) and (not NegativeValue) then
      AddOperator(LSubtype);
  end;

begin
  NumOperators := 0;
  NumValues := 0;
  FirstOperator := -1;
  LastOperator := -1;
  FirstValue := -1;
  LastValue := -1;
  Brace := False;
  Parentheses := 0;
  Error := False;
  LastWasValue := False;
  NegativeValue := False;
  AIntValue := 0;
  AFloatValue := 0;
  T := ATokens;
  while T <> nil do
  begin
    case T.Token.TokenType of
      TT_NAME: HandleName;
      TT_NUMBER: HandleNumber;
      TT_PUNCTUATION: HandlePunctuation;
    else
      Fail('unknown ' + T.Token.Text + ' in #if/#elif');
    end;
    if Error then
      Break;
    T := T.Next;
  end;
  if not Error then
  begin
    if not LastWasValue then
      Fail('trailing operator in #if/#elif')
    else if Parentheses <> 0 then
      Fail('too many ( in #if/#elif');
  end;
  GotQuestMarkValue := False;
  QuestMarkIntValue := 0;
  QuestMarkFloatValue := 0;
  // while there are operators
  while (not Error) and (FirstOperator <> -1) do
  begin
    V := FirstValue;
    O := FirstOperator;
    while Operators[O].Next <> -1 do
    begin
      // if the current operator is nested deeper in parentheses than the next operator
      if Operators[O].Parentheses > Operators[Operators[O].Next].Parentheses then
        Break;
      // nested equally deep: the priority of the current operator is equal or higher
      if Operators[O].Parentheses = Operators[Operators[O].Next].Parentheses then
        if Operators[O].Priority >= Operators[Operators[O].Next].Priority then
          Break;
      // if the arity of the operator isn't equal to 1
      if (Operators[O].Operator <> P_LOGIC_NOT) and (Operators[O].Operator <> P_BIN_NOT) then
        V := Values[V].Next;
      // if there's no value or no next value
      if V = -1 then
      begin
        Fail('mising values in #if/#elif');
        Break;
      end;
      O := Operators[O].Next;
    end;
    if Error then
      Break;
    V1 := V;
    V2 := Values[V].Next;
    if (V2 = -1) and (Operators[O].Operator <> P_LOGIC_NOT) and (Operators[O].Operator <> P_BIN_NOT) and
      (Operators[O].Operator <> P_QUESTIONMARK) then
    begin
      Fail('mising values in #if/#elif');
      Break;
    end;
    case Operators[O].Operator of
      P_LOGIC_NOT:
        begin
          Values[V1].IntValue := BoolToInt(Values[V1].IntValue = 0);
          Values[V1].FloatValue := BoolToFloat(Values[V1].FloatValue = 0);
        end;
      P_BIN_NOT:
        Values[V1].IntValue := not Values[V1].IntValue;
      P_MUL:
        begin
          Values[V1].IntValue := Values[V1].IntValue * Values[V2].IntValue;
          Values[V1].FloatValue := Values[V1].FloatValue * Values[V2].FloatValue;
        end;
      P_DIV:
        if (Values[V2].IntValue = 0) or (Values[V2].FloatValue = 0) then
          Fail('divide by zero in #if/#elif'#10)
        else
        begin
          Values[V1].IntValue := Integer(Int64(Values[V1].IntValue) div Int64(Values[V2].IntValue));
          Values[V1].FloatValue := Values[V1].FloatValue / Values[V2].FloatValue;
        end;
      P_MOD:
        if Values[V2].IntValue = 0 then
          Fail('divide by zero in #if/#elif'#10)
        else
          Values[V1].IntValue := Integer(Int64(Values[V1].IntValue) mod Int64(Values[V2].IntValue));
      P_ADD:
        begin
          Values[V1].IntValue := Values[V1].IntValue + Values[V2].IntValue;
          Values[V1].FloatValue := Values[V1].FloatValue + Values[V2].FloatValue;
        end;
      P_SUB:
        begin
          Values[V1].IntValue := Values[V1].IntValue - Values[V2].IntValue;
          Values[V1].FloatValue := Values[V1].FloatValue - Values[V2].FloatValue;
        end;
      P_LOGIC_AND:
        begin
          Values[V1].IntValue := BoolToInt((Values[V1].IntValue <> 0) and (Values[V2].IntValue <> 0));
          Values[V1].FloatValue := BoolToFloat((Values[V1].FloatValue <> 0) and (Values[V2].FloatValue <> 0));
        end;
      P_LOGIC_OR:
        begin
          Values[V1].IntValue := BoolToInt((Values[V1].IntValue <> 0) or (Values[V2].IntValue <> 0));
          Values[V1].FloatValue := BoolToFloat((Values[V1].FloatValue <> 0) or (Values[V2].FloatValue <> 0));
        end;
      P_LOGIC_GEQ:
        begin
          Values[V1].IntValue := BoolToInt(Values[V1].IntValue >= Values[V2].IntValue);
          Values[V1].FloatValue := BoolToFloat(Values[V1].FloatValue >= Values[V2].FloatValue);
        end;
      P_LOGIC_LEQ:
        begin
          Values[V1].IntValue := BoolToInt(Values[V1].IntValue <= Values[V2].IntValue);
          Values[V1].FloatValue := BoolToFloat(Values[V1].FloatValue <= Values[V2].FloatValue);
        end;
      P_LOGIC_EQ:
        begin
          Values[V1].IntValue := BoolToInt(Values[V1].IntValue = Values[V2].IntValue);
          Values[V1].FloatValue := BoolToFloat(Values[V1].FloatValue = Values[V2].FloatValue);
        end;
      P_LOGIC_UNEQ:
        begin
          Values[V1].IntValue := BoolToInt(Values[V1].IntValue <> Values[V2].IntValue);
          Values[V1].FloatValue := BoolToFloat(Values[V1].FloatValue <> Values[V2].FloatValue);
        end;
      P_LOGIC_GREATER:
        begin
          Values[V1].IntValue := BoolToInt(Values[V1].IntValue > Values[V2].IntValue);
          Values[V1].FloatValue := BoolToFloat(Values[V1].FloatValue > Values[V2].FloatValue);
        end;
      P_LOGIC_LESS:
        begin
          Values[V1].IntValue := BoolToInt(Values[V1].IntValue < Values[V2].IntValue);
          Values[V1].FloatValue := BoolToFloat(Values[V1].FloatValue < Values[V2].FloatValue);
        end;
      P_RSHIFT:
        Values[V1].IntValue := ShiftRightSigned(Values[V1].IntValue, Values[V2].IntValue);
      P_LSHIFT:
        Values[V1].IntValue := Values[V1].IntValue shl (Values[V2].IntValue and 31);
      P_BIN_AND:
        Values[V1].IntValue := Values[V1].IntValue and Values[V2].IntValue;
      P_BIN_OR:
        Values[V1].IntValue := Values[V1].IntValue or Values[V2].IntValue;
      P_BIN_XOR:
        Values[V1].IntValue := Values[V1].IntValue xor Values[V2].IntValue;
      P_COLON:
        if not GotQuestMarkValue then
          Fail(': without ? in #if/#elif')
        else
        begin
          if AInteger then
          begin
            if QuestMarkIntValue = 0 then
              Values[V1].IntValue := Values[V2].IntValue;
          end
          else if QuestMarkFloatValue = 0 then
            Values[V1].FloatValue := Values[V2].FloatValue;
          GotQuestMarkValue := False;
        end;
      P_QUESTIONMARK:
        if GotQuestMarkValue then
          Fail('? after ? in #if/#elif')
        else
        begin
          QuestMarkIntValue := Values[V1].IntValue;
          QuestMarkFloatValue := Values[V1].FloatValue;
          GotQuestMarkValue := True;
        end;
    end;
    if Error then
      Break;
    // if not an operator with arity 1
    if (Operators[O].Operator <> P_LOGIC_NOT) and (Operators[O].Operator <> P_BIN_NOT) then
    begin
      // remove the second value if not question mark operator
      if Operators[O].Operator <> P_QUESTIONMARK then
        V := Values[V].Next;
      if Values[V].Prev <> -1 then
        Values[Values[V].Prev].Next := Values[V].Next
      else
        FirstValue := Values[V].Next;
      if Values[V].Next <> -1 then
        Values[Values[V].Next].Prev := Values[V].Prev
      else
        LastValue := Values[V].Prev;
    end;
    // remove the operator
    if Operators[O].Prev <> -1 then
      Operators[Operators[O].Prev].Next := Operators[O].Next
    else
      FirstOperator := Operators[O].Next;
    if Operators[O].Next <> -1 then
      Operators[Operators[O].Next].Prev := Operators[O].Prev
    else
      LastOperator := Operators[O].Prev;
  end;
  if FirstValue <> -1 then
  begin
    AIntValue := Values[FirstValue].IntValue;
    AFloatValue := Values[FirstValue].FloatValue;
  end;
  if not Error then
    Exit(True);
  AIntValue := 0;
  AFloatValue := 0;
  Result := False;
end;

end.
