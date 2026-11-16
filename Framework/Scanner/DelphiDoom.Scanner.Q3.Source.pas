{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3Source, the precompiler of the scripts of  }
{  Quake III Arena                                                             }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_precomp.c. Copyright (C) 1999-2005 Id Software, Inc. Licensed under the   }
{  GNU General Public License, version 2 or later.                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.Source;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.MathCore.SoftExtended,
  DelphiDoom.Scanner.Q3.Types, DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Scanner.Q3.Script,
  DelphiDoom.Scanner.Q3.ScriptLoader.Intf, DelphiDoom.Scanner.Q3.TokenNode, DelphiDoom.Scanner.Q3.Define,
  DelphiDoom.Scanner.Q3.DefineHash, DelphiDoom.Scanner.Q3.GlobalDefines, DelphiDoom.Scanner.Q3.Punctuations;

type
  /// <summary>
  ///   source_t: a stack of scripts (the file and what it includes), the tokens read ahead, the defines
  ///   and the conditional compilation state; reads tokens with #define, #include, #if... and $evalint done.
  ///   Differences from the C: the global defines, the loader of the files, the log and the clock are given by
  ///   the creator (the C reads globals); the directives that read a freed pointer or a null pointer in the C
  ///   (see TQ3ExpressionEvaluator) are errors; __DATE__ and __TIME__ do not free the static buffer of ctime
  /// </summary>
  TQ3Source = class sealed
  strict private
    type
      TIndent = record
        IndentType: Integer;
        Skip: Boolean;
        ScriptTag: Integer;
      end;
    const
      MAX_DEFINEPARMS = 128;
      MAX_PATH = 260;
      PATH_SEPARATOR = '\';
    var
      FLoader: IQ3ScriptLoader;
      FLog: IQ3ScriptLog;
      FGlobalDefines: TQ3GlobalDefines;
      FNow: TQ3NowProvider;
      FFileName: AnsiString;
      FIncludePath: AnsiString;
      FPunctuations: TQ3PunctuationArray;
      FScriptStack: TQ3Script;
      FTokens: TQ3TokenNode;
      FDefineHash: TQ3DefineHash;
      FIndentStack: TList<TIndent>;
      FSkip: Integer;
      FToken: TQ3Token;
      FNextTag: Integer;
    procedure SourceError(const AText: AnsiString);
    procedure SourceWarning(const AText: AnsiString);
    procedure PushIndent(const AType: Integer; const ASkip: Boolean);
    procedure PopIndent(out AType: Integer; out ASkip: Boolean);
    function PushScript(const AScript: TQ3Script): Boolean;
    function ReadSourceToken(var AToken: TQ3Token): Boolean;
    procedure UnreadSourceToken(const AToken: TQ3Token);
    function ReadDefineParms(const ADefine: TQ3Define; var AParms: array of TQ3TokenNode): Boolean;
    class function StringizeTokens(const ATokens: TQ3TokenNode; out AToken: TQ3Token): Boolean; static;
    class function MergeTokens(var AFirst: TQ3Token; const ASecond: TQ3Token): Boolean; static;
    function ExpandBuiltinDefine(const ADefToken: TQ3Token; const ADefine: TQ3Define; out AFirst,
      ALast: TQ3TokenNode): Boolean;
    function ExpandDefine(const ADefToken: TQ3Token; const ADefine: TQ3Define; out AFirst,
      ALast: TQ3TokenNode): Boolean;
    function ExpandDefineIntoSource(const ADefToken: TQ3Token; const ADefine: TQ3Define): Boolean;
    class function ConvertPath(const APath: AnsiString): AnsiString; static;
    class procedure ClearTokenWhiteSpace(var AToken: TQ3Token); static;
    class function FormatTwoDecimals(const AValue: Double): AnsiString; static;
    procedure UnreadSignToken;
    function Evaluate(out AIntValue: Integer; out AFloatValue: Double; const AInteger: Boolean): Boolean;
    function DollarEvaluate(out AIntValue: Integer; out AFloatValue: Double; const AInteger: Boolean): Boolean;
    function EvaluateTokens(const ATokens: TQ3TokenNode; const AInteger: Boolean; out AIntValue: Integer;
      out AFloatValue: Double): Boolean;
    function DirectiveInclude: Boolean;
    function DirectiveUndef: Boolean;
    function DirectiveDefine: Boolean;
    function DirectiveIfDef(const AType: Integer): Boolean;
    function DirectiveElse: Boolean;
    function DirectiveEndif: Boolean;
    function DirectiveElif: Boolean;
    function DirectiveIf: Boolean;
    function DirectiveError: Boolean;
    function DirectivePragma: Boolean;
    function DirectiveEval: Boolean;
    function DirectiveEvalFloat: Boolean;
    function ReadDirective: Boolean;
    function DollarDirectiveEvalInt: Boolean;
    function DollarDirectiveEvalFloat: Boolean;
    function ReadDollarDirective: Boolean;
    constructor CreateWithScript(const ALoader: IQ3ScriptLoader; const ALog: IQ3ScriptLog;
      const AGlobalDefines: TQ3GlobalDefines; const ANow: TQ3NowProvider; const AFileName: AnsiString;
      const AScript: TQ3Script);
  public
    destructor Destroy; override;
    /// <summary>
    ///   LoadSourceFile: nil if the file is not there. The global defines are copied into the source (nil: none);
    ///   ANow gives the time of __DATE__ and __TIME__ (nil: the clock of the machine)
    /// </summary>
    class function LoadFile(const AFileName: AnsiString; const ALoader: IQ3ScriptLoader;
      const ALog: IQ3ScriptLog; const AGlobalDefines: TQ3GlobalDefines;
      const ANow: TQ3NowProvider = nil): TQ3Source; static;
    /// <summary>LoadSourceMemory</summary>
    class function LoadMemory(const AText: TBytes; const AName: AnsiString; const ALoader: IQ3ScriptLoader;
      const ALog: IQ3ScriptLog; const AGlobalDefines: TQ3GlobalDefines;
      const ANow: TQ3NowProvider = nil): TQ3Source; static;
    /// <summary>
    ///   PC_DefineFromString: the define that "NAME value" or "NAME(a, b) text" gives, nil if it is not a
    ///   define. The caller owns it (the list of global defines takes it)
    /// </summary>
    class function DefineFromString(const AText: AnsiString; const ALoader: IQ3ScriptLoader;
      const ALog: IQ3ScriptLog; const ANow: TQ3NowProvider = nil): TQ3Define; static;
    /// <summary>PC_ReadToken</summary>
    function ReadToken(var AToken: TQ3Token): Boolean;
    /// <summary>PC_ExpectTokenString</summary>
    function ExpectTokenString(const AText: AnsiString): Boolean;
    /// <summary>PC_ExpectTokenType</summary>
    function ExpectTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
    /// <summary>PC_ExpectAnyToken</summary>
    function ExpectAnyToken(var AToken: TQ3Token): Boolean;
    /// <summary>PC_CheckTokenString</summary>
    function CheckTokenString(const AText: AnsiString): Boolean;
    /// <summary>PC_CheckTokenType</summary>
    function CheckTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
    /// <summary>PC_SkipUntilString</summary>
    function SkipUntilString(const AText: AnsiString): Boolean;
    /// <summary>PC_UnreadLastToken</summary>
    procedure UnreadLastToken;
    /// <summary>PC_UnreadToken</summary>
    procedure UnreadToken(const AToken: TQ3Token);
    /// <summary>PC_ReadLine: a token of the current line (a backslash goes on to the next one), False at its end</summary>
    function ReadLine(var AToken: TQ3Token): Boolean;
    /// <summary>PC_WhiteSpaceBeforeToken</summary>
    class function WhiteSpaceBeforeToken(const AToken: TQ3Token): Boolean; static;
    /// <summary>PC_AddDefine: False if the text is not a define</summary>
    function AddDefine(const AText: AnsiString): Boolean;
    /// <summary>
    ///   PC_AddBuiltinDefines: __LINE__, __FILE__, __DATE__ and __TIME__ (nothing in the library calls it:
    ///   a source has them only if its creator asks)
    /// </summary>
    procedure AddBuiltinDefines;
    /// <summary>PC_SetIncludePath: the path gets a trailing separator</summary>
    procedure SetIncludePath(const APath: AnsiString);
    /// <summary>PC_SetPunctuations (the C keeps the set and never reads it back)</summary>
    procedure SetPunctuations(const APunctuations: TQ3PunctuationArray);
    /// <summary>The script that is being read (the top of the stack): its line is the line of the messages</summary>
    property CurrentScript: TQ3Script read FScriptStack;
    property FileName: AnsiString read FFileName;
    property IncludePath: AnsiString read FIncludePath;
    /// <summary>source->skip: more than zero while conditional code is skipped</summary>
    property Skipping: Integer read FSkip;
    /// <summary>source->token: the last token read</summary>
    property LastToken: TQ3Token read FToken;
  end;

implementation

uses
  DelphiDoom.Scanner.Q3.Expression;

const
  MonthNames: array[0..11] of AnsiString = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
    'Nov', 'Dec');

function IntText(const AValue: Integer): AnsiString; inline;
begin
  Result := AnsiString(IntToStr(AValue));
end;

function FirstChar(const AText: AnsiString): AnsiChar; inline;
begin
  if AText = '' then
    Result := #0
  else
    Result := AText[1];
end;

{ TQ3Source }

constructor TQ3Source.CreateWithScript(const ALoader: IQ3ScriptLoader; const ALog: IQ3ScriptLog;
  const AGlobalDefines: TQ3GlobalDefines; const ANow: TQ3NowProvider; const AFileName: AnsiString;
  const AScript: TQ3Script);
begin
  inherited Create;
  FLoader := ALoader;
  FLog := ALog;
  FGlobalDefines := AGlobalDefines;
  FNow := ANow;
  if not Assigned(FNow) then
    FNow := function: TDateTime
      begin
        Result := Now;
      end;
  FFileName := AFileName;
  FIndentStack := TList<TIndent>.Create;
  FDefineHash := TQ3DefineHash.Create;
  AScript.Next := nil;
  Inc(FNextTag);
  AScript.Tag := FNextTag;
  FScriptStack := AScript;
end;

destructor TQ3Source.Destroy;
var
  LScript: TQ3Script;
begin
  while FScriptStack <> nil do
  begin
    LScript := FScriptStack;
    FScriptStack := FScriptStack.Next;
    LScript.Free;
  end;
  TQ3TokenNode.FreeChain(FTokens);
  FDefineHash.Free;
  FIndentStack.Free;
  inherited;
end;

class function TQ3Source.LoadFile(const AFileName: AnsiString; const ALoader: IQ3ScriptLoader;
  const ALog: IQ3ScriptLog; const AGlobalDefines: TQ3GlobalDefines; const ANow: TQ3NowProvider): TQ3Source;
var
  LScript: TQ3Script;
begin
  LScript := ALoader.LoadFile(AFileName);
  if LScript = nil then
    Exit(nil);
  Result := TQ3Source.CreateWithScript(ALoader, ALog, AGlobalDefines, ANow, Copy(AFileName, 1, MAX_PATH),
    LScript);
  if AGlobalDefines <> nil then
    AGlobalDefines.AddTo(Result.FDefineHash);
end;

class function TQ3Source.LoadMemory(const AText: TBytes; const AName: AnsiString;
  const ALoader: IQ3ScriptLoader; const ALog: IQ3ScriptLog; const AGlobalDefines: TQ3GlobalDefines;
  const ANow: TQ3NowProvider): TQ3Source;
var
  LScript: TQ3Script;
begin
  LScript := ALoader.LoadMemory(AText, AName);
  Result := TQ3Source.CreateWithScript(ALoader, ALog, AGlobalDefines, ANow, Copy(AName, 1, MAX_PATH), LScript);
  if AGlobalDefines <> nil then
    AGlobalDefines.AddTo(Result.FDefineHash);
end;

procedure TQ3Source.SourceError(const AText: AnsiString);
begin
  if (FLog <> nil) and (FScriptStack <> nil) then
    FLog.Print(Q3_PRT_ERROR, 'file ' + FScriptStack.FileName + ', line ' + IntText(FScriptStack.Line) + ': ' +
      AText + #10);
end;

procedure TQ3Source.SourceWarning(const AText: AnsiString);
begin
  if (FLog <> nil) and (FScriptStack <> nil) then
    FLog.Print(Q3_PRT_WARNING, 'file ' + FScriptStack.FileName + ', line ' + IntText(FScriptStack.Line) + ': ' +
      AText + #10);
end;

procedure TQ3Source.PushIndent(const AType: Integer; const ASkip: Boolean);
var
  LIndent: TIndent;
begin
  LIndent.IndentType := AType;
  LIndent.ScriptTag := FScriptStack.Tag;
  LIndent.Skip := ASkip;
  if ASkip then
    Inc(FSkip);
  FIndentStack.Add(LIndent);
end;

procedure TQ3Source.PopIndent(out AType: Integer; out ASkip: Boolean);
var
  LIndent: TIndent;
begin
  AType := 0;
  ASkip := False;
  if FIndentStack.Count = 0 then
    Exit;
  LIndent := FIndentStack[FIndentStack.Count - 1];
  // must be an indent from the current script
  if LIndent.ScriptTag <> FScriptStack.Tag then
    Exit;
  AType := LIndent.IndentType;
  ASkip := LIndent.Skip;
  FIndentStack.Delete(FIndentStack.Count - 1);
  if LIndent.Skip then
    Dec(FSkip);
end;

// PC_PushScript. A script that is already on the stack (by name, ignoring the case) is an error and is not
// pushed: it is freed here (the C leaks it)
function TQ3Source.PushScript(const AScript: TQ3Script): Boolean;
var
  LScript: TQ3Script;
begin
  LScript := FScriptStack;
  while LScript <> nil do
  begin
    if SameText(string(LScript.FileName), string(AScript.FileName)) then
    begin
      SourceError(AScript.FileName + ' recursively included');
      AScript.Free;
      Exit(False);
    end;
    LScript := LScript.Next;
  end;
  // push the script on the script stack
  Inc(FNextTag);
  AScript.Tag := FNextTag;
  AScript.Next := FScriptStack;
  FScriptStack := AScript;
  Result := True;
end;

function TQ3Source.ReadSourceToken(var AToken: TQ3Token): Boolean;
var
  LNode: TQ3TokenNode;
  LScript: TQ3Script;
  LType: Integer;
  LSkip: Boolean;
begin
  // if there's no token already available
  while FTokens = nil do
  begin
    // if there's a token to read from the script
    if FScriptStack.ReadToken(AToken) then
      Exit(True);
    // if at the end of the script
    if FScriptStack.EndOfScript then
      // remove all indents of the script
      while (FIndentStack.Count > 0) and (FIndentStack[FIndentStack.Count - 1].ScriptTag = FScriptStack.Tag) do
      begin
        SourceWarning('missing #endif');
        PopIndent(LType, LSkip);
      end;
    // if this was the initial script
    if FScriptStack.Next = nil then
      Exit(False);
    // remove the script and return to the last one
    LScript := FScriptStack;
    FScriptStack := FScriptStack.Next;
    LScript.Free;
  end;
  // copy the already available token
  AToken := FTokens.Token;
  LNode := FTokens;
  FTokens := FTokens.Next;
  LNode.Free;
  Result := True;
end;

procedure TQ3Source.UnreadSourceToken(const AToken: TQ3Token);
var
  LNode: TQ3TokenNode;
begin
  LNode := TQ3TokenNode.CreateCopy(AToken);
  LNode.Next := FTokens;
  FTokens := LNode;
end;

// PC_ReadDefineParms: the "(" that opens a nested group is dropped and its ")" is kept (as the C does)
function TQ3Source.ReadDefineParms(const ADefine: TQ3Define; var AParms: array of TQ3TokenNode): Boolean;
var
  LToken: TQ3Token;
  LNode: TQ3TokenNode;
  LLast: TQ3TokenNode;
  LIndex: Integer;
  LDone: Boolean;
  LLastComma: Boolean;
  LNumParms: Integer;
  LIndent: Integer;
begin
  if not ReadSourceToken(LToken) then
  begin
    SourceError('define ' + ADefine.Name + ' missing parms');
    Exit(False);
  end;
  if ADefine.NumParms > MAX_DEFINEPARMS then
  begin
    SourceError('define with more than ' + IntText(MAX_DEFINEPARMS) + ' parameters');
    Exit(False);
  end;
  for LIndex := 0 to ADefine.NumParms - 1 do
    AParms[LIndex] := nil;
  // if no leading "("
  if LToken.Text <> '(' then
  begin
    UnreadSourceToken(LToken);
    SourceError('define ' + ADefine.Name + ' missing parms');
    Exit(False);
  end;
  // read the define parameters
  LDone := False;
  LNumParms := 0;
  LIndent := 0;
  while not LDone do
  begin
    if LNumParms >= MAX_DEFINEPARMS then
    begin
      SourceError('define ' + ADefine.Name + ' with too many parms');
      Exit(False);
    end;
    if LNumParms >= ADefine.NumParms then
    begin
      SourceWarning('define ' + ADefine.Name + ' has too many parms');
      Exit(False);
    end;
    AParms[LNumParms] := nil;
    LLastComma := True;
    LLast := nil;
    while not LDone do
    begin
      if not ReadSourceToken(LToken) then
      begin
        SourceError('define ' + ADefine.Name + ' incomplete');
        Exit(False);
      end;
      if LToken.Text = ',' then
        if LIndent <= 0 then
        begin
          if LLastComma then
            SourceWarning('too many comma''s');
          // (the C sets lastcomma again here: the next parameter starts with it set anyway)
          Break;
        end;
      LLastComma := False;
      if LToken.Text = '(' then
      begin
        Inc(LIndent);
        Continue;
      end
      else if LToken.Text = ')' then
      begin
        Dec(LIndent);
        if LIndent <= 0 then
        begin
          if AParms[ADefine.NumParms - 1] = nil then
            SourceWarning('too few define parms');
          LDone := True;
          Break;
        end;
      end;
      if LNumParms < ADefine.NumParms then
      begin
        LNode := TQ3TokenNode.CreateCopy(LToken);
        if LLast <> nil then
          LLast.Next := LNode
        else
          AParms[LNumParms] := LNode;
        LLast := LNode;
      end;
    end;
    Inc(LNumParms);
  end;
  Result := True;
end;

class function TQ3Source.StringizeTokens(const ATokens: TQ3TokenNode; out AToken: TQ3Token): Boolean;
var
  LNode: TQ3TokenNode;
  LText: AnsiString;
begin
  AToken := Default(TQ3Token);
  AToken.TokenType := TT_STRING;
  LText := '"';
  LNode := ATokens;
  while LNode <> nil do
  begin
    // strncat(string, t->string, MAX_TOKEN - strlen(string))
    LText := LText + Copy(LNode.Token.Text, 1, Q3_MAX_TOKEN - Length(LText));
    LNode := LNode.Next;
  end;
  if Length(LText) < Q3_MAX_TOKEN then
    LText := LText + '"';
  AToken.Text := LText;
  Result := True;
end;

class function TQ3Source.MergeTokens(var AFirst: TQ3Token; const ASecond: TQ3Token): Boolean;
begin
  // merging of a name with a name or number
  if (AFirst.TokenType = TT_NAME) and ((ASecond.TokenType = TT_NAME) or (ASecond.TokenType = TT_NUMBER)) then
  begin
    AFirst.Text := AFirst.Text + ASecond.Text;
    Exit(True);
  end;
  // merging of two strings: the trailing quote of the first and the leading one of the second go
  if (AFirst.TokenType = TT_STRING) and (ASecond.TokenType = TT_STRING) then
  begin
    AFirst.Text := Copy(AFirst.Text, 1, Length(AFirst.Text) - 1) + Copy(ASecond.Text, 2, MaxInt);
    Exit(True);
  end;
  Result := False;
end;

procedure TQ3Source.AddBuiltinDefines;
const
  Names: array[0..3] of AnsiString = ('__LINE__', '__FILE__', '__DATE__', '__TIME__');
var
  LIndex: Integer;
  LDefine: TQ3Define;
begin
  for LIndex := 0 to High(Names) do
  begin
    LDefine := TQ3Define.Create;
    LDefine.Name := Names[LIndex];
    LDefine.Flags := LDefine.Flags or DEFINE_FIXED;
    LDefine.Builtin := LIndex + 1;
    FDefineHash.Add(LDefine);
  end;
end;

function TQ3Source.ExpandBuiltinDefine(const ADefToken: TQ3Token; const ADefine: TQ3Define; out AFirst,
  ALast: TQ3TokenNode): Boolean;
var
  LNode: TQ3TokenNode;
  LTime: TDateTime;
  LYear: Word;
  LMonth: Word;
  LDay: Word;
  LHour: Word;
  LMinute: Word;
  LSecond: Word;
  LMilli: Word;
begin
  LNode := TQ3TokenNode.CreateCopy(ADefToken);
  AFirst := LNode;
  ALast := LNode;
  case ADefine.Builtin of
    BUILTIN_LINE:
      begin
        LNode.Token.Text := IntText(ADefToken.Line);
        LNode.Token.IntValue := Cardinal(ADefToken.Line);
        LNode.Token.FloatValue := TSoftExtended.FromInt64(ADefToken.Line);
        LNode.Token.TokenType := TT_NUMBER;
        LNode.Token.Subtype := TT_DECIMAL or TT_INTEGER;
      end;
    BUILTIN_FILE:
      begin
        LNode.Token.Text := FScriptStack.FileName;
        LNode.Token.TokenType := TT_NAME;
        LNode.Token.Subtype := Length(LNode.Token.Text);
      end;
    BUILTIN_DATE:
      begin
        LTime := FNow();
        DecodeDate(LTime, LYear, LMonth, LDay);
        // "Mmm dd yyyy" (the C appends to the wrong place and frees a static buffer)
        LNode.Token.Text := '"' + MonthNames[LMonth - 1] + ' ' + AnsiString(Format('%2d', [LDay])) + ' ' +
          AnsiString(Format('%4d', [LYear])) + '"';
        LNode.Token.TokenType := TT_NAME;
        LNode.Token.Subtype := Length(LNode.Token.Text);
      end;
    BUILTIN_TIME:
      begin
        LTime := FNow();
        DecodeTime(LTime, LHour, LMinute, LSecond, LMilli);
        LNode.Token.Text := '"' + AnsiString(Format('%.2d:%.2d:%.2d', [LHour, LMinute, LSecond])) + '"';
        LNode.Token.TokenType := TT_NAME;
        LNode.Token.Subtype := Length(LNode.Token.Text);
      end;
  else
    LNode.Free;
    AFirst := nil;
    ALast := nil;
  end;
  Result := True;
end;

function TQ3Source.ExpandDefine(const ADefToken: TQ3Token; const ADefine: TQ3Define; out AFirst,
  ALast: TQ3TokenNode): Boolean;
var
  LParms: array[0..MAX_DEFINEPARMS - 1] of TQ3TokenNode;
  LDefineToken: TQ3TokenNode;
  LParmToken: TQ3TokenNode;
  LNode: TQ3TokenNode;
  LFirst: TQ3Token;
  LMerge1: TQ3TokenNode;
  LMerge2: TQ3TokenNode;
  LStringized: TQ3Token;
  LParmNumber: Integer;
  LIndex: Integer;
  LHeadNode: TQ3TokenNode;
  LTailNode: TQ3TokenNode;
  LSkip: Boolean;

  procedure FreeParms;
  var
    LParm: Integer;
  begin
    for LParm := 0 to MAX_DEFINEPARMS - 1 do
      TQ3TokenNode.FreeChain(LParms[LParm]);
  end;

  procedure Append(const ANode: TQ3TokenNode);
  begin
    ANode.Next := nil;
    if LTailNode <> nil then
      LTailNode.Next := ANode
    else
      LHeadNode := ANode;
    LTailNode := ANode;
  end;

begin
  AFirst := nil;
  ALast := nil;
  // if it is a builtin define
  if ADefine.Builtin <> 0 then
    Exit(ExpandBuiltinDefine(ADefToken, ADefine, AFirst, ALast));
  for LIndex := 0 to MAX_DEFINEPARMS - 1 do
    LParms[LIndex] := nil;
  // if the define has parameters
  if ADefine.NumParms <> 0 then
    if not ReadDefineParms(ADefine, LParms) then
    begin
      FreeParms;
      Exit(False);
    end;
  // empty list at first
  LHeadNode := nil;
  LTailNode := nil;
  // create a list with tokens of the expanded define
  LDefineToken := ADefine.Tokens;
  while LDefineToken <> nil do
  begin
    LParmNumber := -1;
    // if the token is a name, it could be a define parameter
    if LDefineToken.Token.TokenType = TT_NAME then
      LParmNumber := ADefine.FindParm(LDefineToken.Token.Text);
    // if it is a define parameter
    if LParmNumber >= 0 then
    begin
      LParmToken := LParms[LParmNumber];
      while LParmToken <> nil do
      begin
        Append(TQ3TokenNode.CreateCopy(LParmToken.Token));
        LParmToken := LParmToken.Next;
      end;
    end
    else
    begin
      LSkip := False;
      // if stringizing operator
      if LDefineToken.Token.Text = '#' then
      begin
        // the stringizing operator must be followed by a define parameter
        if LDefineToken.Next <> nil then
          LParmNumber := ADefine.FindParm(LDefineToken.Next.Token.Text)
        else
          LParmNumber := -1;
        if LParmNumber >= 0 then
        begin
          // step over the stringizing operator
          LDefineToken := LDefineToken.Next;
          // stringize the define parameter tokens
          StringizeTokens(LParms[LParmNumber], LStringized);
          Append(TQ3TokenNode.CreateCopy(LStringized));
        end
        else
        begin
          SourceWarning('stringizing operator without define parameter');
          LSkip := True;
        end;
      end
      else
        Append(TQ3TokenNode.CreateCopy(LDefineToken.Token));
      if LSkip then
      begin
        LDefineToken := LDefineToken.Next;
        Continue;
      end;
    end;
    LDefineToken := LDefineToken.Next;
  end;
  // check for the merging operator
  LNode := LHeadNode;
  while LNode <> nil do
  begin
    if LNode.Next <> nil then
      // if the merging operator
      if Copy(LNode.Next.Token.Text, 1, 2) = '##' then
      begin
        LMerge1 := LNode;
        LMerge2 := LNode.Next.Next;
        if LMerge2 <> nil then
        begin
          LFirst := LMerge1.Token;
          if not MergeTokens(LMerge1.Token, LMerge2.Token) then
          begin
            SourceError('can''t merge ' + LFirst.Text + ' with ' + LMerge2.Token.Text);
            TQ3TokenNode.FreeChain(LHeadNode);
            FreeParms;
            Exit(False);
          end;
          LMerge1.Next.Free;
          LMerge1.Next := LMerge2.Next;
          if LMerge2 = LTailNode then
            LTailNode := LMerge1;
          LMerge2.Free;
          Continue;
        end;
      end;
    LNode := LNode.Next;
  end;
  // store the first and last token of the list
  AFirst := LHeadNode;
  ALast := LTailNode;
  // free all the parameter tokens
  FreeParms;
  Result := True;
end;

// An empty expansion is not a success: the C returns False for a define that has no tokens
function TQ3Source.ExpandDefineIntoSource(const ADefToken: TQ3Token; const ADefine: TQ3Define): Boolean;
var
  LFirst: TQ3TokenNode;
  LLast: TQ3TokenNode;
begin
  if not ExpandDefine(ADefToken, ADefine, LFirst, LLast) then
    Exit(False);
  if (LFirst <> nil) and (LLast <> nil) then
  begin
    LLast.Next := FTokens;
    FTokens := LFirst;
    Exit(True);
  end;
  Result := False;
end;

class function TQ3Source.ConvertPath(const APath: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  // remove double path seperators
  Result := '';
  LIndex := 1;
  while LIndex <= Length(APath) do
  begin
    if (APath[LIndex] in ['\', '/']) and (LIndex < Length(APath)) and (APath[LIndex + 1] in ['\', '/']) then
      Inc(LIndex)
    else
    begin
      Result := Result + APath[LIndex];
      Inc(LIndex);
    end;
  end;
  // set OS dependent path seperators
  for LIndex := 1 to Length(Result) do
    if Result[LIndex] in ['\', '/'] then
      Result[LIndex] := PATH_SEPARATOR;
end;

class procedure TQ3Source.ClearTokenWhiteSpace(var AToken: TQ3Token);
begin
  AToken.WhitespaceOffset := 0;
  AToken.EndWhitespaceOffset := 0;
  AToken.LinesCrossed := 0;
end;

// "%1.2f" of a value that is not negative: the exact decimal value rounded to the nearest (halves to the even)
class function TQ3Source.FormatTwoDecimals(const AValue: Double): AnsiString;
var
  LBits: UInt64;
  LExponent: Integer;
  LMantissa: UInt64;
  LShift: Integer;
  LProduct: UInt64;
  LQuotient: UInt64;
  LRemainder: UInt64;
  LHalf: UInt64;
begin
  LBits := UInt64(PInt64(@AValue)^);
  LExponent := Integer((LBits shr 52) and $7FF);
  LMantissa := LBits and $FFFFFFFFFFFFF;
  if LExponent = 0 then
    Exit('0.00');
  LMantissa := LMantissa or (UInt64(1) shl 52);
  LShift := 1075 - LExponent;
  if LShift <= 0 then
  begin
    if LShift < -10 then
      Exit(AnsiString(Format('%.2f', [AValue])));
    Exit(AnsiString(UIntToStr(LMantissa shl (-LShift))) + '.00');
  end;
  LProduct := LMantissa * 100;
  if LShift >= 64 then
    LQuotient := 0
  else
  begin
    LQuotient := LProduct shr LShift;
    LRemainder := LProduct and ((UInt64(1) shl LShift) - 1);
    LHalf := UInt64(1) shl (LShift - 1);
    if (LRemainder > LHalf) or ((LRemainder = LHalf) and ((LQuotient and 1) = 1)) then
      Inc(LQuotient);
  end;
  Result := AnsiString(UIntToStr(LQuotient div 100)) + '.' + AnsiString(Format('%.2d', [Integer(LQuotient mod 100)]));
end;

function TQ3Source.EvaluateTokens(const ATokens: TQ3TokenNode; const AInteger: Boolean; out AIntValue: Integer;
  out AFloatValue: Double): Boolean;
begin
  Result := TQ3ExpressionEvaluator.Evaluate(FDefineHash, ATokens, AInteger,
    procedure(const AMessage: AnsiString)
    begin
      SourceError(AMessage);
    end, AIntValue, AFloatValue);
end;

function TQ3Source.Evaluate(out AIntValue: Integer; out AFloatValue: Double; const AInteger: Boolean): Boolean;
var
  LToken: TQ3Token;
  LFirst: TQ3TokenNode;
  LLast: TQ3TokenNode;
  LNode: TQ3TokenNode;
  LDefine: TQ3Define;
  LDefined: Boolean;

  procedure AddToken;
  begin
    LNode := TQ3TokenNode.CreateCopy(LToken);
    if LLast <> nil then
      LLast.Next := LNode
    else
      LFirst := LNode;
    LLast := LNode;
  end;

begin
  AIntValue := 0;
  AFloatValue := 0;
  LDefined := False;
  if not ReadLine(LToken) then
  begin
    SourceError('no value after #if/#elif');
    Exit(False);
  end;
  LFirst := nil;
  LLast := nil;
  repeat
    // if the token is a name
    if LToken.TokenType = TT_NAME then
    begin
      if LDefined then
      begin
        LDefined := False;
        AddToken;
      end
      else if LToken.Text = 'defined' then
      begin
        LDefined := True;
        AddToken;
      end
      else
      begin
        // then it must be a define
        LDefine := FDefineHash.Find(LToken.Text);
        if LDefine = nil then
        begin
          SourceError('can''t evaluate ' + LToken.Text + ', not defined');
          TQ3TokenNode.FreeChain(LFirst);
          Exit(False);
        end;
        if not ExpandDefineIntoSource(LToken, LDefine) then
        begin
          TQ3TokenNode.FreeChain(LFirst);
          Exit(False);
        end;
      end;
    end
    // if the token is a number or a punctuation
    else if (LToken.TokenType = TT_NUMBER) or (LToken.TokenType = TT_PUNCTUATION) then
      AddToken
    // can't evaluate the token
    else
    begin
      SourceError('can''t evaluate ' + LToken.Text);
      TQ3TokenNode.FreeChain(LFirst);
      Exit(False);
    end;
  until not ReadLine(LToken);
  Result := EvaluateTokens(LFirst, AInteger, AIntValue, AFloatValue);
  TQ3TokenNode.FreeChain(LFirst);
end;

function TQ3Source.DollarEvaluate(out AIntValue: Integer; out AFloatValue: Double;
  const AInteger: Boolean): Boolean;
var
  LToken: TQ3Token;
  LFirst: TQ3TokenNode;
  LLast: TQ3TokenNode;
  LNode: TQ3TokenNode;
  LDefine: TQ3Define;
  LDefined: Boolean;
  LIndent: Integer;

  procedure AddToken;
  begin
    LNode := TQ3TokenNode.CreateCopy(LToken);
    if LLast <> nil then
      LLast.Next := LNode
    else
      LFirst := LNode;
    LLast := LNode;
  end;

begin
  AIntValue := 0;
  AFloatValue := 0;
  LDefined := False;
  if not ReadSourceToken(LToken) then
  begin
    SourceError('no leading ( after $evalint/$evalfloat');
    Exit(False);
  end;
  if not ReadSourceToken(LToken) then
  begin
    SourceError('nothing to evaluate');
    Exit(False);
  end;
  LIndent := 1;
  LFirst := nil;
  LLast := nil;
  repeat
    // if the token is a name
    if LToken.TokenType = TT_NAME then
    begin
      if LDefined then
      begin
        LDefined := False;
        AddToken;
      end
      else if LToken.Text = 'defined' then
      begin
        LDefined := True;
        AddToken;
      end
      else
      begin
        // then it must be a define
        LDefine := FDefineHash.Find(LToken.Text);
        if LDefine = nil then
        begin
          SourceError('can''t evaluate ' + LToken.Text + ', not defined');
          TQ3TokenNode.FreeChain(LFirst);
          Exit(False);
        end;
        if not ExpandDefineIntoSource(LToken, LDefine) then
        begin
          TQ3TokenNode.FreeChain(LFirst);
          Exit(False);
        end;
      end;
    end
    // if the token is a number or a punctuation
    else if (LToken.TokenType = TT_NUMBER) or (LToken.TokenType = TT_PUNCTUATION) then
    begin
      if FirstChar(LToken.Text) = '(' then
        Inc(LIndent)
      else if FirstChar(LToken.Text) = ')' then
        Dec(LIndent);
      if LIndent <= 0 then
        Break;
      AddToken;
    end
    // can't evaluate the token
    else
    begin
      SourceError('can''t evaluate ' + LToken.Text);
      TQ3TokenNode.FreeChain(LFirst);
      Exit(False);
    end;
  until not ReadSourceToken(LToken);
  Result := EvaluateTokens(LFirst, AInteger, AIntValue, AFloatValue);
  TQ3TokenNode.FreeChain(LFirst);
end;

function TQ3Source.DirectiveInclude: Boolean;
var
  LScript: TQ3Script;
  LToken: TQ3Token;
  LPath: AnsiString;
  LName: AnsiString;
begin
  if FSkip > 0 then
    Exit(True);
  if not ReadSourceToken(LToken) then
  begin
    SourceError('#include without file name');
    Exit(False);
  end;
  if LToken.LinesCrossed > 0 then
  begin
    SourceError('#include without file name');
    Exit(False);
  end;
  LPath := '';
  if LToken.TokenType = TT_STRING then
  begin
    LName := LToken.Text;
    TQ3Script.StripDoubleQuotes(LName);
    LName := ConvertPath(LName);
    LScript := FLoader.LoadFile(LName);
    if LScript = nil then
    begin
      LPath := FIncludePath + LName;
      LScript := FLoader.LoadFile(LPath);
    end;
  end
  else if (LToken.TokenType = TT_PUNCTUATION) and (FirstChar(LToken.Text) = '<') then
  begin
    LPath := FIncludePath;
    while ReadSourceToken(LToken) do
    begin
      if LToken.LinesCrossed > 0 then
      begin
        UnreadSourceToken(LToken);
        Break;
      end;
      if (LToken.TokenType = TT_PUNCTUATION) and (FirstChar(LToken.Text) = '>') then
        Break;
      LPath := LPath + LToken.Text;
    end;
    if FirstChar(LToken.Text) <> '>' then
      SourceWarning('#include missing trailing >');
    if LPath = '' then
    begin
      SourceError('#include without file name between < >');
      Exit(False);
    end;
    LPath := ConvertPath(LPath);
    LScript := FLoader.LoadFile(LPath);
  end
  else
  begin
    SourceError('#include without file name');
    Exit(False);
  end;
  if LScript = nil then
  begin
    SourceError('file ' + LPath + ' not found');
    Exit(False);
  end;
  PushScript(LScript);
  Result := True;
end;

function TQ3Source.ReadLine(var AToken: TQ3Token): Boolean;
var
  LCrossLine: Integer;
begin
  LCrossLine := 0;
  repeat
    if not ReadSourceToken(AToken) then
      Exit(False);
    if AToken.LinesCrossed > LCrossLine then
    begin
      UnreadSourceToken(AToken);
      Exit(False);
    end;
    LCrossLine := 1;
  until AToken.Text <> '\';
  Result := True;
end;

class function TQ3Source.WhiteSpaceBeforeToken(const AToken: TQ3Token): Boolean;
begin
  Result := AToken.EndWhitespaceOffset - AToken.WhitespaceOffset > 0;
end;

function TQ3Source.DirectiveUndef: Boolean;
var
  LToken: TQ3Token;
  LDefine: TQ3Define;
begin
  if FSkip > 0 then
    Exit(True);
  if not ReadLine(LToken) then
  begin
    SourceError('undef without name');
    Exit(False);
  end;
  if LToken.TokenType <> TT_NAME then
  begin
    UnreadSourceToken(LToken);
    SourceError('expected name, found ' + LToken.Text);
    Exit(False);
  end;
  LDefine := FDefineHash.Find(LToken.Text);
  if LDefine <> nil then
  begin
    if (LDefine.Flags and DEFINE_FIXED) <> 0 then
      SourceWarning('can''t undef ' + LToken.Text)
    else
    begin
      FDefineHash.Unlink(LDefine);
      LDefine.Free;
    end;
  end;
  Result := True;
end;

function TQ3Source.DirectiveDefine: Boolean;
var
  LToken: TQ3Token;
  LNode: TQ3TokenNode;
  LLast: TQ3TokenNode;
  LDefine: TQ3Define;
begin
  if FSkip > 0 then
    Exit(True);
  if not ReadLine(LToken) then
  begin
    SourceError('#define without name');
    Exit(False);
  end;
  if LToken.TokenType <> TT_NAME then
  begin
    UnreadSourceToken(LToken);
    SourceError('expected name after #define, found ' + LToken.Text);
    Exit(False);
  end;
  // check if the define already exists
  LDefine := FDefineHash.Find(LToken.Text);
  if LDefine <> nil then
  begin
    if (LDefine.Flags and DEFINE_FIXED) <> 0 then
    begin
      SourceError('can''t redefine ' + LToken.Text);
      Exit(False);
    end;
    SourceWarning('redefinition of ' + LToken.Text);
    // unread the define name before executing the #undef directive
    UnreadSourceToken(LToken);
    if not DirectiveUndef then
      Exit(False);
  end;
  // allocate define and add it to the source
  LDefine := TQ3Define.Create;
  LDefine.Name := LToken.Text;
  FDefineHash.Add(LDefine);
  // if nothing is defined, just return
  if not ReadLine(LToken) then
    Exit(True);
  // if it is a define with parameters
  if (not WhiteSpaceBeforeToken(LToken)) and (LToken.Text = '(') then
  begin
    // read the define parameters
    LLast := nil;
    if not CheckTokenString(')') then
    begin
      while True do
      begin
        if not ReadLine(LToken) then
        begin
          SourceError('expected define parameter');
          Exit(False);
        end;
        // if it isn't a name
        if LToken.TokenType <> TT_NAME then
        begin
          SourceError('invalid define parameter');
          Exit(False);
        end;
        if LDefine.FindParm(LToken.Text) >= 0 then
        begin
          SourceError('two the same define parameters');
          Exit(False);
        end;
        // add the define parm
        LNode := TQ3TokenNode.CreateCopy(LToken);
        ClearTokenWhiteSpace(LNode.Token);
        if LLast <> nil then
          LLast.Next := LNode
        else
          LDefine.Parms := LNode;
        LLast := LNode;
        Inc(LDefine.NumParms);
        // read next token
        if not ReadLine(LToken) then
        begin
          SourceError('define parameters not terminated');
          Exit(False);
        end;
        if LToken.Text = ')' then
          Break;
        // then it must be a comma
        if LToken.Text <> ',' then
        begin
          SourceError('define not terminated');
          Exit(False);
        end;
      end;
    end;
    if not ReadLine(LToken) then
      Exit(True);
  end;
  // read the defined stuff
  LLast := nil;
  repeat
    LNode := TQ3TokenNode.CreateCopy(LToken);
    if (LNode.Token.TokenType = TT_NAME) and (LNode.Token.Text = LDefine.Name) then
    begin
      SourceError('recursive define (removed recursion)');
      LNode.Free;
    end
    else
    begin
      ClearTokenWhiteSpace(LNode.Token);
      if LLast <> nil then
        LLast.Next := LNode
      else
        LDefine.Tokens := LNode;
      LLast := LNode;
    end;
  until not ReadLine(LToken);
  if LLast <> nil then
    // check for merge operators at the beginning or end
    if (LDefine.Tokens.Token.Text = '##') or (LLast.Token.Text = '##') then
    begin
      SourceError('define with misplaced ##');
      Exit(False);
    end;
  Result := True;
end;

class function TQ3Source.DefineFromString(const AText: AnsiString; const ALoader: IQ3ScriptLoader;
  const ALog: IQ3ScriptLog; const ANow: TQ3NowProvider): TQ3Define;
var
  LSource: TQ3Source;
  LBytes: TBytes;
  LScript: TQ3Script;
  LResult: Boolean;
begin
  SetLength(LBytes, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], LBytes[0], Length(AText));
  LScript := ALoader.LoadMemory(LBytes, '*extern');
  // a new source without the global defines
  LSource := TQ3Source.CreateWithScript(ALoader, ALog, nil, ANow, '*extern', LScript);
  try
    // create a define from the source
    LResult := LSource.DirectiveDefine;
    Result := LSource.FDefineHash.FirstDefine;
    if LResult and (Result <> nil) then
      LSource.FDefineHash.Unlink(Result)
    else
      Result := nil;
  finally
    LSource.Free;
  end;
end;

function TQ3Source.AddDefine(const AText: AnsiString): Boolean;
var
  LDefine: TQ3Define;
begin
  LDefine := DefineFromString(AText, FLoader, FLog, FNow);
  if LDefine = nil then
    Exit(False);
  FDefineHash.Add(LDefine);
  Result := True;
end;

function TQ3Source.DirectiveIfDef(const AType: Integer): Boolean;
var
  LToken: TQ3Token;
  LDefine: TQ3Define;
begin
  if not ReadLine(LToken) then
  begin
    SourceError('#ifdef without name');
    Exit(False);
  end;
  if LToken.TokenType <> TT_NAME then
  begin
    UnreadSourceToken(LToken);
    SourceError('expected name after #ifdef, found ' + LToken.Text);
    Exit(False);
  end;
  LDefine := FDefineHash.Find(LToken.Text);
  PushIndent(AType, (AType = INDENT_IFDEF) = (LDefine = nil));
  Result := True;
end;

function TQ3Source.DirectiveElse: Boolean;
var
  LType: Integer;
  LSkip: Boolean;
begin
  PopIndent(LType, LSkip);
  if LType = 0 then
  begin
    SourceError('misplaced #else');
    Exit(False);
  end;
  if LType = INDENT_ELSE then
  begin
    SourceError('#else after #else');
    Exit(False);
  end;
  PushIndent(INDENT_ELSE, not LSkip);
  Result := True;
end;

function TQ3Source.DirectiveEndif: Boolean;
var
  LType: Integer;
  LSkip: Boolean;
begin
  PopIndent(LType, LSkip);
  if LType = 0 then
  begin
    SourceError('misplaced #endif');
    Exit(False);
  end;
  Result := True;
end;

function TQ3Source.DirectiveElif: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LType: Integer;
  LSkip: Boolean;
begin
  PopIndent(LType, LSkip);
  if (LType = 0) or (LType = INDENT_ELSE) then
  begin
    SourceError('misplaced #elif');
    Exit(False);
  end;
  if not Evaluate(LValue, LFloat, True) then
    Exit(False);
  PushIndent(INDENT_ELIF, LValue = 0);
  Result := True;
end;

function TQ3Source.DirectiveIf: Boolean;
var
  LValue: Integer;
  LFloat: Double;
begin
  if not Evaluate(LValue, LFloat, True) then
    Exit(False);
  PushIndent(INDENT_IF, LValue = 0);
  Result := True;
end;

function TQ3Source.DirectiveError: Boolean;
var
  LToken: TQ3Token;
begin
  LToken := Default(TQ3Token);
  ReadSourceToken(LToken);
  SourceError('#error directive: ' + LToken.Text);
  Result := False;
end;

function TQ3Source.DirectivePragma: Boolean;
var
  LToken: TQ3Token;
begin
  SourceWarning('#pragma directive not supported');
  while ReadLine(LToken) do
    ;
  Result := True;
end;

procedure TQ3Source.UnreadSignToken;
var
  LToken: TQ3Token;
begin
  LToken := Default(TQ3Token);
  LToken.Line := FScriptStack.Line;
  LToken.WhitespaceOffset := FScriptStack.Position;
  LToken.EndWhitespaceOffset := FScriptStack.Position;
  LToken.LinesCrossed := 0;
  LToken.Text := '-';
  LToken.TokenType := TT_PUNCTUATION;
  LToken.Subtype := P_SUB;
  UnreadSourceToken(LToken);
end;

function TQ3Source.DirectiveEval: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LToken: TQ3Token;
begin
  if not Evaluate(LValue, LFloat, True) then
    Exit(False);
  LToken := Default(TQ3Token);
  LToken.Line := FScriptStack.Line;
  LToken.WhitespaceOffset := FScriptStack.Position;
  LToken.EndWhitespaceOffset := FScriptStack.Position;
  LToken.LinesCrossed := 0;
  // sprintf("%d", abs(value))
  if LValue < 0 then
    LToken.Text := IntText(-LValue)
  else
    LToken.Text := IntText(LValue);
  LToken.TokenType := TT_NUMBER;
  LToken.Subtype := TT_INTEGER or TT_LONG or TT_DECIMAL;
  UnreadSourceToken(LToken);
  if LValue < 0 then
    UnreadSignToken;
  Result := True;
end;

function TQ3Source.DirectiveEvalFloat: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LToken: TQ3Token;
begin
  if not Evaluate(LValue, LFloat, False) then
    Exit(False);
  LToken := Default(TQ3Token);
  LToken.Line := FScriptStack.Line;
  LToken.WhitespaceOffset := FScriptStack.Position;
  LToken.EndWhitespaceOffset := FScriptStack.Position;
  LToken.LinesCrossed := 0;
  LToken.Text := FormatTwoDecimals(Abs(LFloat));
  LToken.TokenType := TT_NUMBER;
  LToken.Subtype := TT_FLOAT or TT_LONG or TT_DECIMAL;
  UnreadSourceToken(LToken);
  if LFloat < 0 then
    UnreadSignToken;
  Result := True;
end;

function TQ3Source.ReadDirective: Boolean;
var
  LToken: TQ3Token;
begin
  // read the directive name
  if not ReadSourceToken(LToken) then
  begin
    SourceError('found # without name');
    Exit(False);
  end;
  // directive name must be on the same line
  if LToken.LinesCrossed > 0 then
  begin
    UnreadSourceToken(LToken);
    SourceError('found # at end of line');
    Exit(False);
  end;
  // if if is a name, find the precompiler directive
  if LToken.TokenType = TT_NAME then
  begin
    if LToken.Text = 'if' then
      Exit(DirectiveIf)
    else if LToken.Text = 'ifdef' then
      Exit(DirectiveIfDef(INDENT_IFDEF))
    else if LToken.Text = 'ifndef' then
      Exit(DirectiveIfDef(INDENT_IFNDEF))
    else if LToken.Text = 'elif' then
      Exit(DirectiveElif)
    else if LToken.Text = 'else' then
      Exit(DirectiveElse)
    else if LToken.Text = 'endif' then
      Exit(DirectiveEndif)
    else if LToken.Text = 'include' then
      Exit(DirectiveInclude)
    else if LToken.Text = 'define' then
      Exit(DirectiveDefine)
    else if LToken.Text = 'undef' then
      Exit(DirectiveUndef)
    else if LToken.Text = 'line' then
    begin
      SourceError('#line directive not supported');
      Exit(False);
    end
    else if LToken.Text = 'error' then
      Exit(DirectiveError)
    else if LToken.Text = 'pragma' then
      Exit(DirectivePragma)
    else if LToken.Text = 'eval' then
      Exit(DirectiveEval)
    else if LToken.Text = 'evalfloat' then
      Exit(DirectiveEvalFloat);
  end;
  SourceError('unknown precompiler directive ' + LToken.Text);
  Result := False;
end;

function TQ3Source.DollarDirectiveEvalInt: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LToken: TQ3Token;
begin
  if not DollarEvaluate(LValue, LFloat, True) then
    Exit(False);
  LToken := Default(TQ3Token);
  LToken.Line := FScriptStack.Line;
  LToken.WhitespaceOffset := FScriptStack.Position;
  LToken.EndWhitespaceOffset := FScriptStack.Position;
  LToken.LinesCrossed := 0;
  if LValue < 0 then
    LToken.Text := IntText(-LValue)
  else
    LToken.Text := IntText(LValue);
  LToken.TokenType := TT_NUMBER;
  LToken.Subtype := TT_INTEGER or TT_LONG or TT_DECIMAL;
  LToken.IntValue := Cardinal(LValue);
  LToken.FloatValue := TSoftExtended.FromInt64(LValue);
  UnreadSourceToken(LToken);
  if LValue < 0 then
    UnreadSignToken;
  Result := True;
end;

function TQ3Source.DollarDirectiveEvalFloat: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LToken: TQ3Token;
begin
  if not DollarEvaluate(LValue, LFloat, False) then
    Exit(False);
  LToken := Default(TQ3Token);
  LToken.Line := FScriptStack.Line;
  LToken.WhitespaceOffset := FScriptStack.Position;
  LToken.EndWhitespaceOffset := FScriptStack.Position;
  LToken.LinesCrossed := 0;
  LToken.Text := FormatTwoDecimals(Abs(LFloat));
  LToken.TokenType := TT_NUMBER;
  LToken.Subtype := TT_FLOAT or TT_LONG or TT_DECIMAL;
  // (unsigned long) of a double: the low 32 bits of the truncated value
  LToken.IntValue := Cardinal(Int64(Trunc(LFloat)) and $FFFFFFFF);
  LToken.FloatValue := TSoftExtended.FromDouble(LFloat);
  UnreadSourceToken(LToken);
  if LFloat < 0 then
    UnreadSignToken;
  Result := True;
end;

function TQ3Source.ReadDollarDirective: Boolean;
var
  LToken: TQ3Token;
begin
  // read the directive name
  if not ReadSourceToken(LToken) then
  begin
    SourceError('found $ without name');
    Exit(False);
  end;
  // directive name must be on the same line
  if LToken.LinesCrossed > 0 then
  begin
    UnreadSourceToken(LToken);
    SourceError('found $ at end of line');
    Exit(False);
  end;
  if LToken.TokenType = TT_NAME then
  begin
    if LToken.Text = 'evalint' then
      Exit(DollarDirectiveEvalInt)
    else if LToken.Text = 'evalfloat' then
      Exit(DollarDirectiveEvalFloat);
  end;
  UnreadSourceToken(LToken);
  SourceError('unknown precompiler directive ' + LToken.Text);
  Result := False;
end;

function TQ3Source.ReadToken(var AToken: TQ3Token): Boolean;
var
  LNewToken: TQ3Token;
  LDefine: TQ3Define;
begin
  while True do
  begin
    if not ReadSourceToken(AToken) then
      Exit(False);
    // check for precompiler directives
    if (AToken.TokenType = TT_PUNCTUATION) and (FirstChar(AToken.Text) = '#') then
    begin
      // read the precompiler directive
      if not ReadDirective then
        Exit(False);
      Continue;
    end;
    if (AToken.TokenType = TT_PUNCTUATION) and (FirstChar(AToken.Text) = '$') then
    begin
      if not ReadDollarDirective then
        Exit(False);
      Continue;
    end;
    // recursively concatenate strings that are behind each other still resolving defines
    if AToken.TokenType = TT_STRING then
    begin
      if ReadToken(LNewToken) then
      begin
        if LNewToken.TokenType = TT_STRING then
        begin
          AToken.Text := Copy(AToken.Text, 1, Length(AToken.Text) - 1);
          if Length(AToken.Text) + (Length(LNewToken.Text) - 1) + 1 >= Q3_MAX_TOKEN then
          begin
            SourceError('string longer than MAX_TOKEN ' + IntText(Q3_MAX_TOKEN) + #10);
            Exit(False);
          end;
          AToken.Text := AToken.Text + Copy(LNewToken.Text, 2, MaxInt);
        end
        else
          UnreadToken(LNewToken);
      end;
    end;
    // if skipping source because of conditional compilation
    if FSkip <> 0 then
      Continue;
    // if the token is a name
    if AToken.TokenType = TT_NAME then
    begin
      // check if the name is a define macro; if so expand it
      LDefine := FDefineHash.Find(AToken.Text);
      if LDefine <> nil then
      begin
        if not ExpandDefineIntoSource(AToken, LDefine) then
          Exit(False);
        Continue;
      end;
    end;
    // copy token for unreading
    FToken := AToken;
    // found a token
    Exit(True);
  end;
end;

function TQ3Source.ExpectTokenString(const AText: AnsiString): Boolean;
var
  LToken: TQ3Token;
begin
  if not ReadToken(LToken) then
  begin
    SourceError('couldn''t find expected ' + AText);
    Exit(False);
  end;
  if LToken.Text <> AText then
  begin
    SourceError('expected ' + AText + ', found ' + LToken.Text);
    Exit(False);
  end;
  Result := True;
end;

function TQ3Source.ExpectTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
var
  LText: AnsiString;
begin
  if not ReadToken(AToken) then
  begin
    SourceError('couldn''t read expected token');
    Exit(False);
  end;
  if AToken.TokenType <> AType then
  begin
    LText := '';
    if AType = TT_STRING then
      LText := 'string';
    if AType = TT_LITERAL then
      LText := 'literal';
    if AType = TT_NUMBER then
      LText := 'number';
    if AType = TT_NAME then
      LText := 'name';
    if AType = TT_PUNCTUATION then
      LText := 'punctuation';
    SourceError('expected a ' + LText + ', found ' + AToken.Text);
    Exit(False);
  end;
  if AToken.TokenType = TT_NUMBER then
  begin
    if (AToken.Subtype and ASubtype) <> ASubtype then
    begin
      LText := '';
      if (ASubtype and TT_DECIMAL) <> 0 then
        LText := 'decimal';
      if (ASubtype and TT_HEX) <> 0 then
        LText := 'hex';
      if (ASubtype and TT_OCTAL) <> 0 then
        LText := 'octal';
      if (ASubtype and TT_BINARY) <> 0 then
        LText := 'binary';
      if (ASubtype and TT_LONG) <> 0 then
        LText := LText + ' long';
      if (ASubtype and TT_UNSIGNED) <> 0 then
        LText := LText + ' unsigned';
      if (ASubtype and TT_FLOAT) <> 0 then
        LText := LText + ' float';
      if (ASubtype and TT_INTEGER) <> 0 then
        LText := LText + ' integer';
      SourceError('expected ' + LText + ', found ' + AToken.Text);
      Exit(False);
    end;
  end
  else if AToken.TokenType = TT_PUNCTUATION then
  begin
    if AToken.Subtype <> ASubtype then
    begin
      SourceError('found ' + AToken.Text);
      Exit(False);
    end;
  end;
  Result := True;
end;

function TQ3Source.ExpectAnyToken(var AToken: TQ3Token): Boolean;
begin
  Result := ReadToken(AToken);
  if not Result then
    SourceError('couldn''t read expected token');
end;

function TQ3Source.CheckTokenString(const AText: AnsiString): Boolean;
var
  LToken: TQ3Token;
begin
  if not ReadToken(LToken) then
    Exit(False);
  // if the token is available
  if LToken.Text = AText then
    Exit(True);
  UnreadSourceToken(LToken);
  Result := False;
end;

function TQ3Source.CheckTokenType(const AType, ASubtype: Integer; var AToken: TQ3Token): Boolean;
var
  LToken: TQ3Token;
begin
  if not ReadToken(LToken) then
    Exit(False);
  // if the type matches
  if (LToken.TokenType = AType) and ((LToken.Subtype and ASubtype) = ASubtype) then
  begin
    AToken := LToken;
    Exit(True);
  end;
  UnreadSourceToken(LToken);
  Result := False;
end;

function TQ3Source.SkipUntilString(const AText: AnsiString): Boolean;
var
  LToken: TQ3Token;
begin
  while ReadToken(LToken) do
    if LToken.Text = AText then
      Exit(True);
  Result := False;
end;

procedure TQ3Source.UnreadLastToken;
begin
  UnreadSourceToken(FToken);
end;

procedure TQ3Source.UnreadToken(const AToken: TQ3Token);
begin
  UnreadSourceToken(AToken);
end;

procedure TQ3Source.SetIncludePath(const APath: AnsiString);
begin
  FIncludePath := Copy(APath, 1, MAX_PATH);
  // add trailing path seperator
  if (FIncludePath = '') or not (FIncludePath[Length(FIncludePath)] in ['\', '/']) then
    FIncludePath := FIncludePath + PATH_SEPARATOR;
end;

procedure TQ3Source.SetPunctuations(const APunctuations: TQ3PunctuationArray);
begin
  FPunctuations := APunctuations;
end;

end.
