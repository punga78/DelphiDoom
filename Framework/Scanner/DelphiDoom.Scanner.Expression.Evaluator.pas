{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the evaluator of the expressions in the scripts }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Expression.Evaluator;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.Scanner.Expression.Intf, DelphiDoom.Scanner.Expression.Node,
  DelphiDoom.Scanner.Expression.Builtins;

type
  /// <summary>
  ///   Evaluates an expression written as a text (the old TEvaluator): numbers, texts between
  ///   quotes, TRUE, FALSE and INF, the operators / * + - &amp; | ^ = &lt; &gt; != (also AND, OR,
  ///   XOR, NOT, &lt;&gt; and ==), brackets, the functions of TExpressionBuiltins and the ones
  ///   that were added, and variables. The result is always a text. Letters are read in
  ///   upper case, except in quotes. The mistakes that the old code reported with a warning
  ///   are warnings to the log
  /// </summary>
  TExpressionEvaluator = class
  private
    type
      TFunctionEntry = record
        Body: TExpressionFunction;
        Params: Integer;
      end;
  private
    FFunctions: TDictionary<string, TFunctionEntry>;
    FVariables: IExpressionVariables;
    FLog: ILog;
    FRoot: TExpressionNode;
    FBuiltins: TExpressionBuiltins;
    FExpression: string;
    procedure Warn(const AMessage: string);
    procedure SetExpression(const AValue: string);
    function Validate(AText: string): string;
    procedure Process(AText: string; ANode: TExpressionNode);
    function EvaluateNode(ANode: TExpressionNode): string;
    function CallFunction(ANode: TExpressionNode; const AArguments: string): string;
    function ApplyOperator(AOperator: Char; const ALeft, ARight: string): string;
    procedure IncompatibleTypes(const ACaller, ALeft, ARight: string);
    function OpAdd(const ALeft, ARight: string): string;
    function OpSubtract(const ALeft, ARight: string): string;
    function OpMultiply(const ALeft, ARight: string): string;
    function OpDivide(const ALeft, ARight: string): string;
    function OpAnd(const ALeft, ARight: string): string;
    function OpOr(const ALeft, ARight: string): string;
    function OpXor(const ALeft, ARight: string): string;
    function OpLess(const ALeft, ARight: string): string;
    function OpGreater(const ALeft, ARight: string): string;
  public
    constructor Create(const ALog: ILog; const AVariables: IExpressionVariables);
    destructor Destroy; override;
    /// <summary>Adds a function; the name is read in upper case. A name already used is an error</summary>
    procedure AddFunction(const AName: string; const AFunction: TExpressionFunction; AParams: Integer);
    /// <summary>The value of the last expression that was set</summary>
    function Value: string;
    /// <summary>Sets the expression and gives its value</summary>
    function Evaluate(const AExpression: string): string;
    property Expression: string read FExpression write SetExpression;
    class function IsBoolean(const AText: string): Boolean; static;
    class function BooleanToText(AValue: Boolean): string; static;
    class function TextToBoolean(const AText: string): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.Scanner.Numbers;

const
  ALLOWED_FIRST_CHARS = ['a'..'z', 'A'..'Z', '_'];
  ALLOWED_CHARS = ['a'..'z', 'A'..'Z', '_', '0'..'9', '(', ')', ',', '"', ' '];
  HIGH_MARKS = ['/', '*'];
  LOW_MARKS = ['+', '-'];
  BOOL_MARKS = ['&', '|', '^', '=', '<', '>', '!'];
  MARKS = ['/', '*', '+', '-', '&', '|', '^', '=', '<', '>', '!'];
  INPUT_MARKS = ['/', '*', '+', '-', '=', '<', '>', '&', '|', '^', '!'];

//==============================================================================
//
// CharAt
//
// The old code read the terminator of a string and the byte before its first character:
// both are zero
//
//==============================================================================
function CharAt(const AText: string; AIndex: Integer): Char;
begin
  if (AIndex >= 1) and (AIndex <= Length(AText)) then
    Result := AText[AIndex]
  else
    Result := #0;
end;

//==============================================================================
//
// SplitArgument
//
// Splits at the first comma that is not in quotes or in brackets; the last character
// is never looked at
//
//==============================================================================
procedure SplitArgument(var AFirst, ARest: string);
var
  LIndex: Integer;
  LPosition: Integer;
  LLength: Integer;
  LQuote: Boolean;
  LBracket: Integer;
begin
  LPosition := 0;
  LIndex := 1;
  LLength := Length(ARest);
  LQuote := False;
  LBracket := 0;
  while (LPosition = 0) and (LIndex < LLength) do
  begin
    if ARest[LIndex] = '"' then
      LQuote := not LQuote
    else if ARest[LIndex] = '(' then
      Inc(LBracket)
    else if ARest[LIndex] = ')' then
      Dec(LBracket);
    if not LQuote and (LBracket = 0) and (ARest[LIndex] = ',') then
      LPosition := LIndex;
    Inc(LIndex);
  end;
  if LPosition = 0 then
  begin
    AFirst := ARest;
    ARest := '';
  end
  else
  begin
    AFirst := Copy(ARest, 1, LPosition - 1);
    Delete(ARest, 1, LPosition);
  end;
end;

//==============================================================================
//
// SplitArguments
//
//==============================================================================
function SplitArguments(AText: string): TArray<string>;
var
  LItem: string;
begin
  Result := nil;
  while AText <> '' do
  begin
    SplitArgument(LItem, AText);
    if LItem <> '' then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LItem;
    end;
  end;
end;

//==============================================================================
//
// SubstituteMarks
//
// Replaces a symbol with another, except in quotes
//
//==============================================================================
function SubstituteMarks(AText, AOut, AIn: string): string;
var
  LQuote: Boolean;
  LIndex: Integer;
begin
  LQuote := False;
  LIndex := 1;
  while LIndex < Length(AText) do
  begin
    if AText[LIndex] = '"' then
      LQuote := not LQuote;
    if not LQuote then
      if Copy(AText, LIndex, Length(AOut)) = AOut then
        AText := Copy(AText, 1, LIndex - 1) + AIn + Copy(AText, LIndex + Length(AOut), Length(AText));
    Inc(LIndex);
  end;
  Result := AText;
end;

//==============================================================================
//
// SubstituteWords
//
// Replaces a word with another; the word has to be between brackets or spaces
//
//==============================================================================
function SubstituteWords(AText, AOut, AIn: string): string;
var
  LPosition: Integer;
  LMatch: Boolean;
  LRest: string;
begin
  if AText = AOut then
    Exit(AIn);

  LRest := AText;
  Result := '';
  repeat
    LPosition := Pos(AOut, LRest);
    LMatch := False;
    if LPosition > 0 then
    begin
      LMatch := (LPosition = 1) and (CharAt(LRest, LPosition + Length(AOut)) = ' ');
      LMatch := LMatch or ((LPosition = Length(LRest) - Length(AOut) + 1) and
        (CharAt(LRest, LPosition - 1) = ' '));
      if not LMatch then
      begin
        LMatch := (CharAt(LRest, LPosition - 1) = '(') and (CharAt(LRest, LPosition + Length(AOut)) = ')');
        LMatch := LMatch or ((CharAt(LRest, LPosition - 1) = ')') and (CharAt(LRest, LPosition + Length(AOut)) = '('));
        LMatch := LMatch or ((CharAt(LRest, LPosition - 1) = ' ') and (CharAt(LRest, LPosition + Length(AOut)) = ' '));
      end;
    end;
    if LMatch then
    begin
      Delete(LRest, LPosition, Length(AOut));
      Insert(AIn, LRest, LPosition);
      Result := Result + Copy(LRest, 1, LPosition + Length(AIn));
      Delete(LRest, 1, LPosition + Length(AIn));
    end;
  until not LMatch;
  Result := Result + LRest;
end;

//==============================================================================
//
// IsIdentifier
//
//==============================================================================
function IsIdentifier(const AText: string): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  if (Length(AText) = 0) or not CharInSet(AText[1], ['A'..'Z', 'a'..'z', '_']) then
    Exit;
  for LIndex := 2 to Length(AText) do
    if not CharInSet(AText[LIndex], ['A'..'Z', 'a'..'z', '_', '0'..'9']) then
      Exit;
  Result := True;
end;

//==============================================================================
//
// MarkPosition
//
// The last position of a mark outside quotes and brackets, or -1
//
//==============================================================================
function MarkPosition(const AText: string; const AMarks: TSysCharSet): Integer;
var
  LIndex: Integer;
  LBracket: Integer;
  LQuote: Boolean;
  LChar: Char;
begin
  Result := -1;
  LIndex := Length(AText);
  LBracket := 0;
  LQuote := False;
  while (Result < 0) and (LIndex > 0) do
  begin
    LChar := AText[LIndex];
    if LChar = '"' then
      LQuote := not LQuote;
    if not LQuote then
    begin
      if LChar = '(' then
        Inc(LBracket)
      else if LChar = ')' then
        Dec(LBracket);
      if LBracket = 0 then
        if CharInSet(LChar, AMarks) then
          Result := LIndex;
    end;
    Dec(LIndex);
  end;
end;

{ TExpressionEvaluator }

constructor TExpressionEvaluator.Create(const ALog: ILog; const AVariables: IExpressionVariables);
begin
  inherited Create;
  FLog := ALog;
  FVariables := AVariables;
  FFunctions := TDictionary<string, TFunctionEntry>.Create;
  FExpression := '';
  // the functions of the builtins are methods of it: it lives as long as the evaluator
  FBuiltins := TExpressionBuiltins.Create(ALog);
  FBuiltins.RegisterAll(
    procedure(const AName: string; const AFunction: TExpressionFunction; AParams: Integer)
    begin
      AddFunction(AName, AFunction, AParams);
    end);
end;

destructor TExpressionEvaluator.Destroy;
begin
  FRoot.Free;
  FFunctions.Free;
  FBuiltins.Free;
  inherited Destroy;
end;

procedure TExpressionEvaluator.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

class function TExpressionEvaluator.IsBoolean(const AText: string): Boolean;
var
  LUpper: string;
begin
  LUpper := TScannerStrings.UpperAscii(AText);
  Result := (LUpper = 'FALSE') or (LUpper = 'TRUE');
end;

class function TExpressionEvaluator.BooleanToText(AValue: Boolean): string;
begin
  if AValue then
    Result := 'TRUE'
  else
    Result := 'FALSE';
end;

class function TExpressionEvaluator.TextToBoolean(const AText: string): Boolean;
begin
  Result := TScannerStrings.UpperAscii(AText) = 'TRUE';
end;

procedure TExpressionEvaluator.AddFunction(const AName: string; const AFunction: TExpressionFunction;
  AParams: Integer);
var
  LName: string;
  LEntry: TFunctionEntry;
begin
  LName := TScannerStrings.UpperAscii(AName);
  if not IsIdentifier(LName) then
    raise EExpressionException.CreateFmt('TEvaluator.AddFunc(): Invalid function name "%s"', [LName]);
  if FFunctions.ContainsKey(LName) then
    raise EExpressionException.CreateFmt('TEvaluator.AddFunc(): Function name "%s" already used', [LName]);
  LEntry.Body := AFunction;
  LEntry.Params := AParams;
  FFunctions.Add(LName, LEntry);
end;

function TExpressionEvaluator.Value: string;
begin
  Result := EvaluateNode(FRoot);
end;

function TExpressionEvaluator.Evaluate(const AExpression: string): string;
begin
  SetExpression(AExpression);
  Result := EvaluateNode(FRoot);
end;

procedure TExpressionEvaluator.SetExpression(const AValue: string);
begin
  FExpression := Validate(AValue);
  FRoot.Free;
  FRoot := TExpressionNode.Create;
  Process(FExpression, FRoot);
end;

function TExpressionEvaluator.Validate(AText: string): string;
var
  LBracketLevel: Integer;
  LIndex: Integer;
  LQuote: Boolean;
  LChar: Char;
begin
  LQuote := False;
  LBracketLevel := 0;
  for LIndex := 1 to Length(AText) do
  begin
    if AText[LIndex] = '"' then
      LQuote := not LQuote;
    if (not LQuote) and (AText[LIndex] = '(') then
      Inc(LBracketLevel);
    if (not LQuote) and (AText[LIndex] = ')') then
      Dec(LBracketLevel);
    if not LQuote then
    begin
      LChar := AText[LIndex];
      if not (CharInSet(LChar, ALLOWED_CHARS) or CharInSet(LChar, INPUT_MARKS) or (LChar = '.')) then
      begin
        Warn('TEvaluator.ValidateExpression(): Illegal character ' + LChar + ' while validating "' +
          AText + '"'#13#10);
        AText[LIndex] := '_';
      end
      else if (LChar >= 'a') and (LChar <= 'z') then
        AText[LIndex] := Char(Ord(LChar) - 32);
    end;
  end;
  if LBracketLevel <> 0 then
    Warn('TEvaluator.ValidateExpression(): Wrong number of brackets "' + AText + '"'#13#10);

  // boolean and multi-character operators
  AText := SubstituteWords(AText, 'AND', '&');
  AText := SubstituteWords(AText, 'XOR', '^');
  AText := SubstituteWords(AText, 'OR', '|');
  AText := SubstituteWords(AText, 'NOT', 'TRUE^');
  AText := SubstituteMarks(AText, '<>', '!');
  AText := SubstituteMarks(AText, '!=', '!');
  AText := SubstituteMarks(AText, '==', '=');

  // spaces out of quotes go away
  LIndex := 0;
  LQuote := False;
  while LIndex < Length(AText) do
  begin
    Inc(LIndex);
    if AText[LIndex] = '"' then
      LQuote := not LQuote;
    if (not LQuote) and (AText[LIndex] = ' ') then
    begin
      Delete(AText, LIndex, 1);
      Dec(LIndex);
    end;
  end;
  Result := AText;
end;

procedure TExpressionEvaluator.Process(AText: string; ANode: TExpressionNode);
var
  LPosition: Integer;
  LName: string;
  LArguments: string;
  LArgument: string;
  LEntry: TFunctionEntry;
begin
  if AText = '' then
    Exit;

  // the brackets around everything go away
  if MarkPosition(AText, MARKS) < 0 then
  begin
    repeat
      if (CharAt(AText, 1) = '(') and (CharAt(AText, Length(AText)) = ')') then
        AText := Copy(AText, 2, Length(AText) - 2);
    until (CharAt(AText, 1) <> '(') or (CharAt(AText, Length(AText)) <> ')');
  end;
  LPosition := MarkPosition(AText, LOW_MARKS);
  if LPosition = 1 then
  begin
    AText := '0' + AText;
    LPosition := 2;
  end;
  if LPosition < 0 then
    LPosition := MarkPosition(AText, BOOL_MARKS);
  if LPosition < 0 then
    LPosition := MarkPosition(AText, HIGH_MARKS);
  if LPosition = Length(AText) then
    Warn('TEvaluator.ProcessExpression(): Invalid expression "' + AText + '"'#13#10);
  if LPosition > -1 then
  begin
    ANode.OperatorChar := AText[LPosition];
    Process(Copy(AText, 1, LPosition - 1), ANode.AddChild);
    Process(Copy(AText, LPosition + 1, Length(AText)), ANode.AddChild);
  end
  else
  begin
    if Assigned(FVariables) and FVariables.Contains(AText) then
      AText := FVariables.ValueOf(AText);
    if CharInSet(CharAt(AText, 1), ALLOWED_FIRST_CHARS) then
    begin
      // the name and the arguments
      LName := AText;
      LArguments := '';
      LPosition := Pos('(', LName);
      if LPosition > 0 then
      begin
        LName := Copy(AText, 1, LPosition - 1);
        LArguments := Copy(AText, LPosition + 1, Length(AText));
        Delete(LArguments, Length(LArguments), 1);
      end;
      if (LArguments = '') and ((LName = 'TRUE') or (LName = 'FALSE') or (LName = 'INF')) then
        ANode.Value := LName
      else
      begin
        if FFunctions.TryGetValue(LName, LEntry) then
          ANode.SetFunction(LName, LEntry.Body, LEntry.Params)
        else
          Warn('TEvaluator.ProcessExpression(): Unknown function "' + LName + '"'#13#10);
        // one node for each argument
        while LArguments <> '' do
        begin
          SplitArgument(LArgument, LArguments);
          Process(LArgument, ANode.AddChild);
        end;
      end;
    end
    else
      ANode.Value := AText;
  end;
end;

function TExpressionEvaluator.CallFunction(ANode: TExpressionNode; const AArguments: string): string;
var
  LParams: TArray<string>;
begin
  LParams := SplitArguments(AArguments);
  if (Length(LParams) <> ANode.FunctionParams) and (ANode.FunctionParams > -1) then
  begin
    Warn('TEvalFunction.Value(): Wrong number of parameters in function ' + ANode.FunctionName + #13#10);
    Exit('');
  end;
  Result := ANode.FunctionBody(LParams);
end;

function TExpressionEvaluator.EvaluateNode(ANode: TExpressionNode): string;
var
  LArguments: string;
  LIndex: Integer;
begin
  Result := ANode.Value;
  if ANode.OperatorChar <> #0 then
    Result := ApplyOperator(ANode.OperatorChar, EvaluateNode(ANode[0]), EvaluateNode(ANode[1]));
  if ANode.HasFunction then
  begin
    LArguments := '';
    for LIndex := 0 to ANode.Count - 1 do
      LArguments := LArguments + ',' + EvaluateNode(ANode[LIndex]);
    Delete(LArguments, 1, 1);
    Result := CallFunction(ANode, LArguments);
  end;
end;

function TExpressionEvaluator.ApplyOperator(AOperator: Char; const ALeft, ARight: string): string;
begin
  Result := '';
  case AOperator of
    '/': Result := OpDivide(ALeft, ARight);
    '*': Result := OpMultiply(ALeft, ARight);
    '+': Result := OpAdd(ALeft, ARight);
    '-': Result := OpSubtract(ALeft, ARight);
    '&': Result := OpAnd(ALeft, ARight);
    '|': Result := OpOr(ALeft, ARight);
    '^': Result := OpXor(ALeft, ARight);
    '=': Result := BooleanToText(ALeft = ARight);
    '<': Result := OpLess(ALeft, ARight);
    '>': Result := OpGreater(ALeft, ARight);
    '!': Result := BooleanToText(ALeft <> ARight);
  end;
end;

procedure TExpressionEvaluator.IncompatibleTypes(const ACaller, ALeft, ARight: string);
begin
  Warn('TEvaluator.' + ACaller + '(): Incompatible types ("' + ALeft + '", "' + ARight + ')'#13#10);
end;

function TExpressionEvaluator.OpAdd(const ALeft, ARight: string): string;
begin
  Result := '';
  if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := TScannerNumbers.FloatToText(TScannerNumbers.ToFloat(ALeft) + TScannerNumbers.ToFloat(ARight))
  else if (ALeft = 'INF') or (ARight = 'INF') then
    Result := 'INF'
  else
    IncompatibleTypes('OP_Add', ALeft, ARight);
end;

function TExpressionEvaluator.OpSubtract(const ALeft, ARight: string): string;
begin
  Result := '';
  if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := TScannerNumbers.FloatToText(TScannerNumbers.ToFloat(ALeft) - TScannerNumbers.ToFloat(ARight))
  else if ALeft = 'INF' then
  begin
    if ARight <> 'INF' then
      Result := 'INF'
    else
      Result := '0';
  end
  else
    IncompatibleTypes('OP_Subtract', ALeft, ARight);
end;

function TExpressionEvaluator.OpMultiply(const ALeft, ARight: string): string;
begin
  Result := '';
  if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := TScannerNumbers.FloatToText(TScannerNumbers.ToFloat(ALeft) * TScannerNumbers.ToFloat(ARight))
  else if (ALeft = 'INF') or (ARight = 'INF') then
    Result := 'INF'
  else
    IncompatibleTypes('OP_Multiply', ALeft, ARight);
end;

function TExpressionEvaluator.OpDivide(const ALeft, ARight: string): string;
begin
  Result := '';
  if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := TScannerNumbers.FloatToText(TScannerNumbers.ToFloat(ALeft) / TScannerNumbers.ToFloat(ARight))
  else if (ALeft = 'INF') and (ARight = 'INF') then
    Result := '1'
  else if ALeft = 'INF' then
    Result := 'INF'
  else if ARight = 'INF' then
    Result := '0'
  else
    IncompatibleTypes('OP_Divide', ALeft, ARight);
end;

function TExpressionEvaluator.OpAnd(const ALeft, ARight: string): string;
begin
  Result := '';
  if IsBoolean(ALeft) and IsBoolean(ARight) then
    Result := BooleanToText(TextToBoolean(ALeft) and TextToBoolean(ARight))
  else if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := TScannerNumbers.IntToText(Round(TScannerNumbers.ToFloat(ALeft)) and Round(TScannerNumbers.ToFloat(ARight)))
  else
    IncompatibleTypes('OP_And', ALeft, ARight);
end;

function TExpressionEvaluator.OpOr(const ALeft, ARight: string): string;
begin
  Result := '';
  if IsBoolean(ALeft) and IsBoolean(ARight) then
    Result := BooleanToText(TextToBoolean(ALeft) or TextToBoolean(ARight))
  else if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := TScannerNumbers.IntToText(Round(TScannerNumbers.ToFloat(ALeft)) or Round(TScannerNumbers.ToFloat(ARight)))
  else
    IncompatibleTypes('OP_OR', ALeft, ARight);
end;

function TExpressionEvaluator.OpXor(const ALeft, ARight: string): string;
begin
  Result := '';
  if IsBoolean(ALeft) and IsBoolean(ARight) then
    Result := BooleanToText(TextToBoolean(ALeft) xor TextToBoolean(ARight))
  else if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := TScannerNumbers.IntToText(Round(TScannerNumbers.ToFloat(ALeft)) xor Round(TScannerNumbers.ToFloat(ARight)))
  else if IsBoolean(ALeft) and TScannerNumbers.IsFloat(ARight) then
  begin
    if ALeft = 'TRUE' then
      Result := TScannerNumbers.IntToText(Integer($FFFFFFFF) xor Round(TScannerNumbers.ToFloat(ARight)))
    else
      Result := TScannerNumbers.IntToText(Round(TScannerNumbers.ToFloat(ARight)));
  end
  else if TScannerNumbers.IsFloat(ALeft) and IsBoolean(ARight) then
  begin
    if ARight = 'TRUE' then
      Result := TScannerNumbers.IntToText(Round(TScannerNumbers.ToFloat(ALeft)) xor Integer($FFFFFFFF))
    else
      Result := TScannerNumbers.IntToText(Round(TScannerNumbers.ToFloat(ALeft)));
  end
  else
    IncompatibleTypes('OP_XOR', ALeft, ARight);
end;

function TExpressionEvaluator.OpLess(const ALeft, ARight: string): string;
begin
  if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := BooleanToText(TScannerNumbers.ToFloat(ALeft) < TScannerNumbers.ToFloat(ARight))
  else
    Result := BooleanToText(ALeft < ARight);
end;

function TExpressionEvaluator.OpGreater(const ALeft, ARight: string): string;
begin
  if TScannerNumbers.IsFloat(ALeft) and TScannerNumbers.IsFloat(ARight) then
    Result := BooleanToText(TScannerNumbers.ToFloat(ALeft) > TScannerNumbers.ToFloat(ARight))
  else
    Result := BooleanToText(ALeft > ARight);
end;

end.
