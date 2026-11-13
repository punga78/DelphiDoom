{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdParser, the preprocessing parser of        }
{  idTech 4                                                                    }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Parser.h, Parser.cpp.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Scanner.IdParser.Types,
  DelphiDoom.Scanner.IdParser.Intf, DelphiDoom.Scanner.IdParser.Define,
  DelphiDoom.Scanner.IdParser.GlobalDefines, DelphiDoom.Scanner.IdParser.Evaluator;

type
  /// <summary>
  ///   The parser of Doom 3 (idParser): a stack of TIdLexer scripts with a C preprocessor in front
  ///   (<c>#define</c> with parameters, <c>#</c> and <c>##</c>, <c>#undef</c>, <c>#if #ifdef #ifndef #elif
  ///   #else #endif</c> with expressions, <c>#include</c>, <c>#error #warning #pragma #line</c>,
  ///   <c>#eval #evalfloat</c>, <c>$evalint $evalfloat</c>, builtin <c>__LINE__ __FILE__ __DATE__
  ///   __TIME__</c>). The problems are those of the lexer (EIdLexerException with the
  ///   position, or a warning in the log with the flags LEXFL_NOFATALERRORS/LEXFL_NOERRORS).
  ///   <para>Replacements for the C++ globals: the log and the file system come from the
  ///   constructor; the global defines are a TIdParserGlobalDefines the caller owns (nil: none); the
  ///   base folder of idLexer is the property <c>BaseFolder</c>; the clock of <c>__DATE__</c> and
  ///   <c>__TIME__</c> is a property. Linked lists of tokens are arrays; the pending tokens are a stack.
  ///   Methods that return <c>int</c> in C++ return Boolean. Not reference counted: the owner frees it.</para>
  /// </summary>
  TIdParser = class(TObject, IIdTokenSource)
  strict private
    type
      TIndent = record
        Kind: Integer;
        Skip: Boolean;
        Script: TIdLexer;
      end;
  strict private
    FLoaded: Boolean;
    FFileName: AnsiString;
    FIncludePath: AnsiString;
    FOSPath: Boolean;
    FPunctuations: TIdPunctuationList;
    FFlags: Integer;
    // the script stack: the last one is the current script
    FScripts: TObjectList<TIdLexer>;
    // the tokens to read first: the last one is read first
    FTokens: TList<TIdToken>;
    // the table of defines, DEFINEHASHSIZE buckets; the last define of a bucket is its head
    FDefineHash: TArray<TList<TIdParserDefine>>;
    FIndents: TList<TIndent>;
    FSkip: Integer;
    FMarker: Integer;
    FBaseFolder: AnsiString;
    FLog: IIdLibLog;
    FFileSystem: IIdLibFileSystem;
    FGlobalDefines: TIdParserGlobalDefines;
    FEvaluator: TIdParserEvaluator;
    FClock: TFunc<TDateTime>;
    class function NameHash(const AName: AnsiString): Integer; static;
    class function Sar(const AValue, ACount: Integer): Integer; static;
    class function FormatTwoDecimals(const AValue: Double): AnsiString; static;
    function Top: TIdLexer;
    function NewLexer: TIdLexer;
    procedure CreateDefineTable;
    procedure FreeDefineTable;
    procedure AddDefineToHash(const ADefine: TIdParserDefine);
    function FindHashedDefine(const AName: AnsiString): TIdParserDefine;
    function IsDefined(const AName: AnsiString): Boolean;
    function CopyFirstDefine: TIdParserDefine;
    procedure AddGlobalDefinesToSource;
    function DefineFromString(const AText: AnsiString): TIdParserDefine;
    procedure PushIndent(const AKind: Integer; const ASkip: Boolean);
    procedure PopIndent(out AKind: Integer; out ASkip: Boolean);
    procedure PushScript(const AScript: TIdLexer);
    function ReadSourceToken(var AToken: TIdToken): Boolean;
    function ReadLine(var AToken: TIdToken): Boolean;
    procedure UnreadSourceToken(const AToken: TIdToken);
    function ReadDefineParms(const ADefine: TIdParserDefine; var AParms: TArray<TArray<TIdToken>>;
      const AMaxParms: Integer): Boolean;
    function StringizeTokens(const ATokens: TArray<TIdToken>; out AToken: TIdToken): Boolean;
    function MergeTokens(var AToken1: TIdToken; const AToken2: TIdToken): Boolean;
    function ExpandBuiltinDefine(const ADefToken: TIdToken; const ADefine: TIdParserDefine;
      out ATokens: TArray<TIdToken>): Boolean;
    function ExpandDefine(const ADefToken: TIdToken; const ADefine: TIdParserDefine;
      out ATokens: TArray<TIdToken>): Boolean;
    function ExpandDefineIntoSource(const ADefToken: TIdToken; const ADefine: TIdParserDefine): Boolean;
    function Directive_include: Boolean;
    function Directive_undef: Boolean;
    function Directive_if_def(const AKind: Integer): Boolean;
    function Directive_ifdef: Boolean;
    function Directive_ifndef: Boolean;
    function Directive_else: Boolean;
    function Directive_endif: Boolean;
    function Evaluate(out AIntValue: Integer; out AFloatValue: Double; const AInteger: Boolean): Boolean;
    function DollarEvaluate(out AIntValue: Integer; out AFloatValue: Double; const AInteger: Boolean): Boolean;
    function Directive_define: Boolean;
    function Directive_elif: Boolean;
    function Directive_if: Boolean;
    function Directive_line: Boolean;
    function Directive_error: Boolean;
    function Directive_warning: Boolean;
    function Directive_pragma: Boolean;
    procedure UnreadSignToken;
    function Directive_eval: Boolean;
    function Directive_evalfloat: Boolean;
    function ReadDirective: Boolean;
    function DollarDirective_evalint: Boolean;
    function DollarDirective_evalfloat: Boolean;
    function ReadDollarDirective: Boolean;
    function NewValueToken: TIdToken;
    function GetFlags: Integer;
    function GetFileName: AnsiString;
    function GetFileTime: Int64;
    function GetLineNum: Integer;
    function GetFileOffset: Integer;
    // IInterface without counting: the owner frees the parser
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    /// <summary>idParser(flags): nothing loaded; call LoadFile or LoadMemory</summary>
    constructor Create(const AFlags: Integer = 0; const ALog: IIdLibLog = nil;
      const AFileSystem: IIdLibFileSystem = nil; const AGlobalDefines: TIdParserGlobalDefines = nil);
    destructor Destroy; override;
    /// <summary>Loads a source file; raises if another source is loaded, false if it cannot be read</summary>
    function LoadFile(const AFileName: AnsiString; const AIsOsPath: Boolean = False): Boolean;
    /// <summary>Loads a source from memory</summary>
    function LoadMemory(const AText: AnsiString; const ALength: Integer; const AName: AnsiString): Boolean; overload;
    function LoadMemory(const AText: AnsiString; const AName: AnsiString): Boolean; overload;
    /// <summary>Frees the source; the defines stay when <c>AKeepDefines</c></summary>
    procedure FreeSource(const AKeepDefines: Boolean = False);
    function IsLoaded: Boolean;
    function ReadToken(var AToken: TIdToken): Boolean;
    function ExpectTokenString(const AText: AnsiString): Boolean;
    function ExpectTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
    function ExpectAnyToken(var AToken: TIdToken): Boolean;
    function CheckTokenString(const AText: AnsiString): Boolean;
    function CheckTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
    function PeekTokenString(const AText: AnsiString): Boolean;
    function PeekTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
    function SkipUntilString(const AText: AnsiString): Boolean;
    function SkipRestOfLine: Boolean;
    function SkipBracedSection(const AParseFirstBrace: Boolean = True): Boolean;
    /// <summary>Parses a braced section into a string (CR LF between lines); the same text is the result</summary>
    function ParseBracedSection(var AOutput: AnsiString; ATabs: Integer = -1): AnsiString;
    /// <summary>Parses a braced section keeping its layout; it reads the current script only (no preprocessing)</summary>
    function ParseBracedSectionExact(var AOutput: AnsiString; const ATabs: Integer = -1): AnsiString;
    function ParseRestOfLine(var AOutput: AnsiString): AnsiString;
    procedure UnreadToken(const AToken: TIdToken);
    function ReadTokenOnLine(var AToken: TIdToken): Boolean;
    function ParseInt: Integer;
    function ParseBool: Boolean;
    function ParseFloat: Single;
    function Parse1DMatrix(const AX: Integer; var AMatrix: array of Single; const AOffset: Integer = 0): Boolean;
    function Parse2DMatrix(const AY, AX: Integer; var AMatrix: array of Single; const AOffset: Integer = 0): Boolean;
    function Parse3DMatrix(const AZ, AY, AX: Integer; var AMatrix: array of Single; const AOffset: Integer = 0): Boolean;
    /// <summary>The white space before the last token; its length is the result</summary>
    function GetLastWhiteSpace(var AWhiteSpace: AnsiString): Integer;
    /// <summary>Sets the marker (only one): the start of the next token read</summary>
    procedure SetMarker;
    /// <summary>
    ///   The text from the marker to the current position (idParser::GetStringFromMarker). With <c>AClean</c> the
    ///   text is parsed again and the tokens are appended to <c>AOutput</c> (it is not cleared); without it
    ///   <c>AOutput</c> is replaced. The marker is an offset in the current script: it does not follow an include
    ///   (the original keeps a pointer into a script that may be gone).
    /// </summary>
    procedure GetStringFromMarker(var AOutput: AnsiString; const AClean: Boolean = False);
    /// <summary>Adds a define from text like "NAME value" (the text after <c>#define</c>); needs a loaded source</summary>
    function AddDefine(const AText: AnsiString): Boolean;
    /// <summary>Adds __LINE__, __FILE__, __DATE__, __TIME__ and __STDC__; needs a loaded source</summary>
    procedure AddBuiltinDefines;
    /// <summary>idParser::AddGlobalDefine on the global list given to the constructor</summary>
    function AddGlobalDefine(const AText: AnsiString): Boolean;
    /// <summary>Sets the include path, with a trailing path separator</summary>
    procedure SetIncludePath(const APath: AnsiString);
    /// <summary>Sets the punctuation set; an empty list is the default set</summary>
    procedure SetPunctuations(const APunctuations: TIdPunctuationList);
    function GetPunctuationFromId(const AId: Integer): AnsiString;
    function GetPunctuationId(const AText: AnsiString): Integer;
    procedure SetFlags(const AFlags: Integer);
    procedure Error(const AText: string);
    procedure Warning(const AText: string);
    property Flags: Integer read GetFlags write SetFlags;
    property FileName: AnsiString read GetFileName;
    property FileTime: Int64 read GetFileTime;
    property LineNum: Integer read GetLineNum;
    property FileOffset: Integer read GetFileOffset;
    /// <summary>idParser::SetBaseFolder (a static in the original), given to the lexers this parser makes</summary>
    property BaseFolder: AnsiString read FBaseFolder write FBaseFolder;
    /// <summary>The clock of <c>__DATE__</c> and <c>__TIME__</c> (default <c>Now</c>)</summary>
    property Clock: TFunc<TDateTime> read FClock write FClock;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Text.Str;

const
  PATH_SEPARATOR: AnsiChar = '\';
  MONTH_NAMES: array[1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
    'Nov', 'Dec');

{ TIdParser }

constructor TIdParser.Create(const AFlags: Integer; const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem;
  const AGlobalDefines: TIdParserGlobalDefines);
begin
  inherited Create;
  FFlags := AFlags;
  FLog := ALog;
  FFileSystem := AFileSystem;
  FGlobalDefines := AGlobalDefines;
  FMarker := -1;
  FScripts := TObjectList<TIdLexer>.Create(True);
  FTokens := TList<TIdToken>.Create;
  FIndents := TList<TIndent>.Create;
  FClock := function: TDateTime
    begin
      Result := Now;
    end;
  FEvaluator := TIdParserEvaluator.Create(
    function(const AName: AnsiString): Boolean
    begin
      Result := IsDefined(AName);
    end,
    procedure(const AText: string)
    begin
      Error(AText);
    end);
end;

destructor TIdParser.Destroy;
begin
  FreeSource(False);
  FEvaluator.Free;
  FIndents.Free;
  FTokens.Free;
  FScripts.Free;
  inherited Destroy;
end;

function TIdParser.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TIdParser._AddRef: Integer;
begin
  Result := -1;
end;

function TIdParser._Release: Integer;
begin
  Result := -1;
end;

class function TIdParser.Sar(const AValue, ACount: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr ACount
  else
    Result := Integer((Cardinal(AValue) shr ACount) or (not (Cardinal($FFFFFFFF) shr ACount)));
end;

// PC_NameHash: the characters are signed
class function TIdParser.NameHash(const AName: AnsiString): Integer;
var
  LIndex, LHash: Integer;
begin
  LHash := 0;
  for LIndex := 0 to System.Length(AName) - 1 do
  begin
    if AName[LIndex + 1] = #0 then
      Break;
    LHash := LHash + ShortInt(Byte(AName[LIndex + 1])) * (119 + LIndex);
  end;
  Result := (LHash xor Sar(LHash, 10) xor Sar(LHash, 20)) and (DEFINEHASHSIZE - 1);
end;

// "%1.2f": the product with 100 is exact in the 80-bit Extended of Win32; a tie rounds to even like printf
class function TIdParser.FormatTwoDecimals(const AValue: Double): AnsiString;
var
  LScaled: Extended;
  LRounded: Int64;
  LDigits: string;
begin
  LScaled := Abs(AValue) * 100;
  if (AValue <> AValue) or (LScaled >= 9.0E18) then
    Exit(AnsiString(Format('%.2f', [Abs(AValue)], TFormatSettings.Invariant)));
  LRounded := Round(LScaled);
  LDigits := IntToStr(LRounded);
  while System.Length(LDigits) < 3 do
    LDigits := '0' + LDigits;
  Insert('.', LDigits, System.Length(LDigits) - 1);
  Result := AnsiString(LDigits);
end;

function TIdParser.Top: TIdLexer;
begin
  Result := FScripts.Last;
end;

function TIdParser.NewLexer: TIdLexer;
begin
  Result := TIdLexer.Create(0, FLog, FFileSystem);
  Result.BaseFolder := FBaseFolder;
end;

function TIdParser.NewValueToken: TIdToken;
begin
  Result := TIdToken.Create;
  Result.Line := Top.LineNum;
  Result.WhiteSpaceStart := -1;
  Result.WhiteSpaceEnd := -1;
  Result.LinesCrossed := 0;
  Result.Flags := 0;
end;

procedure TIdParser.CreateDefineTable;
var
  LIndex: Integer;
begin
  SetLength(FDefineHash, DEFINEHASHSIZE);
  for LIndex := 0 to DEFINEHASHSIZE - 1 do
    FDefineHash[LIndex] := TObjectList<TIdParserDefine>.Create(True);
end;

procedure TIdParser.FreeDefineTable;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FDefineHash) do
    FDefineHash[LIndex].Free;
  FDefineHash := nil;
end;

procedure TIdParser.AddDefineToHash(const ADefine: TIdParserDefine);
begin
  FDefineHash[NameHash(ADefine.Name)].Add(ADefine);
end;

function TIdParser.FindHashedDefine(const AName: AnsiString): TIdParserDefine;
var
  LBucket: TList<TIdParserDefine>;
  LIndex: Integer;
begin
  Result := nil;
  if FDefineHash = nil then
    Exit;
  LBucket := FDefineHash[NameHash(AName)];
  for LIndex := LBucket.Count - 1 downto 0 do
    if LBucket[LIndex].Name = AName then
      Exit(LBucket[LIndex]);
end;

function TIdParser.IsDefined(const AName: AnsiString): Boolean;
begin
  Result := FindHashedDefine(AName) <> nil;
end;

function TIdParser.CopyFirstDefine: TIdParserDefine;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FDefineHash) do
    if FDefineHash[LIndex].Count > 0 then
      Exit(FDefineHash[LIndex].Last.Copy);
  Result := nil;
end;

procedure TIdParser.AddGlobalDefinesToSource;
var
  LIndex: Integer;
begin
  if not Assigned(FGlobalDefines) then
    Exit;
  for LIndex := 0 to FGlobalDefines.Count - 1 do
    AddDefineToHash(FGlobalDefines.Item(LIndex).Copy);
end;

function TIdParser.DefineFromString(const AText: AnsiString): TIdParserDefine;
var
  LSource: TIdParser;
begin
  Result := nil;
  LSource := TIdParser.Create(0, FLog, FFileSystem, FGlobalDefines);
  try
    if not LSource.LoadMemory(AText, System.Length(AText), '*defineString') then
      Exit;
    // create a define from the source
    if not LSource.Directive_define then
    begin
      LSource.FreeSource;
      Exit;
    end;
    Result := LSource.CopyFirstDefine;
    LSource.FreeSource;
  finally
    LSource.Free;
  end;
end;

function TIdParser.AddDefine(const AText: AnsiString): Boolean;
var
  LDefine: TIdParserDefine;
begin
  if FDefineHash = nil then
    raise EIdLibFatalException.Create('idParser::AddDefine: no source loaded');
  LDefine := DefineFromString(AText);
  if LDefine = nil then
    Exit(False);
  AddDefineToHash(LDefine);
  Result := True;
end;

function TIdParser.AddGlobalDefine(const AText: AnsiString): Boolean;
var
  LDefine: TIdParserDefine;
begin
  if not Assigned(FGlobalDefines) then
    raise EIdLibFatalException.Create('idParser::AddGlobalDefine: no list of global defines');
  LDefine := DefineFromString(AText);
  if LDefine = nil then
    Exit(False);
  FGlobalDefines.Push(LDefine);
  Result := True;
end;

procedure TIdParser.AddBuiltinDefines;
const
  BUILTIN_NAMES: array[0..4] of AnsiString = ('__LINE__', '__FILE__', '__DATE__', '__TIME__', '__STDC__');
  BUILTIN_IDS: array[0..4] of Integer = (BUILTIN_LINE, BUILTIN_FILE, BUILTIN_DATE, BUILTIN_TIME, BUILTIN_STDC);
var
  LIndex: Integer;
  LDefine: TIdParserDefine;
begin
  if FDefineHash = nil then
    raise EIdLibFatalException.Create('idParser::AddBuiltinDefines: no source loaded');
  for LIndex := 0 to 4 do
  begin
    LDefine := TIdParserDefine.Create(BUILTIN_NAMES[LIndex]);
    LDefine.Flags := DEFINE_FIXED;
    LDefine.Builtin := BUILTIN_IDS[LIndex];
    AddDefineToHash(LDefine);
  end;
end;

procedure TIdParser.Error(const AText: string);
begin
  if FScripts.Count > 0 then
    Top.Error('%s', [AText]);
end;

procedure TIdParser.Warning(const AText: string);
begin
  if FScripts.Count > 0 then
    Top.Warning('%s', [AText]);
end;

procedure TIdParser.PushIndent(const AKind: Integer; const ASkip: Boolean);
var
  LIndent: TIndent;
begin
  LIndent.Kind := AKind;
  LIndent.Script := Top;
  LIndent.Skip := ASkip;
  if ASkip then
    Inc(FSkip);
  FIndents.Add(LIndent);
end;

procedure TIdParser.PopIndent(out AKind: Integer; out ASkip: Boolean);
var
  LIndent: TIndent;
begin
  AKind := 0;
  ASkip := False;
  if FIndents.Count = 0 then
    Exit;
  LIndent := FIndents.Last;
  // must be an indent from the current script
  if LIndent.Script <> Top then
    Exit;
  AKind := LIndent.Kind;
  ASkip := LIndent.Skip;
  FIndents.Delete(FIndents.Count - 1);
  if LIndent.Skip then
    Dec(FSkip);
end;

procedure TIdParser.PushScript(const AScript: TIdLexer);
var
  LIndex: Integer;
begin
  for LIndex := FScripts.Count - 1 downto 0 do
    if TIdStrings.Icmp(FScripts[LIndex].FileName, AScript.FileName) = 0 then
    begin
      Warning(Format('''%s'' recursively included', [string(AScript.FileName)]));
      // the original leaks the script
      AScript.Free;
      Exit;
    end;
  FScripts.Add(AScript);
end;

function TIdParser.ReadSourceToken(var AToken: TIdToken): Boolean;
var
  LChangedScript: Integer;
  LKind: Integer;
  LSkip: Boolean;
begin
  if FScripts.Count = 0 then
    raise EIdLibFatalException.Create('idParser::ReadSourceToken: not loaded');
  LChangedScript := 0;
  // if there's no token already available
  while FTokens.Count = 0 do
  begin
    // if there's a token to read from the script
    if Top.ReadToken(AToken) then
    begin
      Inc(AToken.LinesCrossed, LChangedScript);
      // set the marker based on the start of the token read in
      if FMarker < 0 then
        FMarker := AToken.WhiteSpaceEnd;
      Exit(True);
    end;
    // if at the end of the script
    if Top.EndOfFile then
    begin
      // remove all indents of the script
      while (FIndents.Count > 0) and (FIndents.Last.Script = Top) do
      begin
        Warning('missing #endif');
        PopIndent(LKind, LSkip);
      end;
      LChangedScript := 1;
    end;
    // if this was the initial script
    if FScripts.Count = 1 then
      Exit(False);
    // remove the script and return to the previous one
    FScripts.Delete(FScripts.Count - 1);
  end;
  // copy the already available token and remove it from the source
  AToken := FTokens.Last;
  FTokens.Delete(FTokens.Count - 1);
  Result := True;
end;

procedure TIdParser.UnreadSourceToken(const AToken: TIdToken);
begin
  FTokens.Add(AToken);
end;

// reads a token from the current line, continues on the next line only if a backslash is found
function TIdParser.ReadLine(var AToken: TIdToken): Boolean;
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
  until not AToken.IsText('\');
  Result := True;
end;

function TIdParser.ReadDefineParms(const ADefine: TIdParserDefine; var AParms: TArray<TArray<TIdToken>>;
  const AMaxParms: Integer): Boolean;
var
  LToken: TIdToken;
  LNewDefine: TIdParserDefine;
  LIndex, LNumParms, LIndent: Integer;
  LDone, LLastComma: Boolean;
  LList: TArray<TIdToken>;
begin
  if not ReadSourceToken(LToken) then
  begin
    Error(Format('define ''%s'' missing parameters', [string(ADefine.Name)]));
    Exit(False);
  end;
  if ADefine.NumParms > AMaxParms then
  begin
    Error(Format('define with more than %d parameters', [AMaxParms]));
    Exit(False);
  end;
  for LIndex := 0 to ADefine.NumParms - 1 do
    AParms[LIndex] := nil;
  // if no leading "("
  if not LToken.IsText('(') then
  begin
    UnreadSourceToken(LToken);
    Error(Format('define ''%s'' missing parameters', [string(ADefine.Name)]));
    Exit(False);
  end;
  // read the define parameters
  LDone := False;
  LNumParms := 0;
  LIndent := 1;
  while not LDone do
  begin
    if LNumParms >= AMaxParms then
    begin
      Error(Format('define ''%s'' with too many parameters', [string(ADefine.Name)]));
      Exit(False);
    end;
    AParms[LNumParms] := nil;
    LLastComma := True;
    LList := nil;
    while not LDone do
    begin
      if not ReadSourceToken(LToken) then
      begin
        Error(Format('define ''%s'' incomplete', [string(ADefine.Name)]));
        Exit(False);
      end;
      if LToken.IsText(',') then
      begin
        if LIndent <= 1 then
        begin
          if LLastComma then
            Warning('too many comma''s');
          if LNumParms >= ADefine.NumParms then
            Warning('too many define parameters');
          // (the original sets lastcomma here; it is set again at the start of the next parameter)
          Break;
        end;
      end
      else if LToken.IsText('(') then
        Inc(LIndent)
      else if LToken.IsText(')') then
      begin
        Dec(LIndent);
        if LIndent <= 0 then
        begin
          if System.Length(AParms[ADefine.NumParms - 1]) = 0 then
            Warning('too few define parameters');
          LDone := True;
          Break;
        end;
      end
      else if LToken.TokenType = TT_NAME then
      begin
        LNewDefine := FindHashedDefine(LToken.Text);
        if LNewDefine <> nil then
        begin
          if not ExpandDefineIntoSource(LToken, LNewDefine) then
            Exit(False);
          Continue;
        end;
      end;
      LLastComma := False;
      if LNumParms < ADefine.NumParms then
      begin
        SetLength(LList, System.Length(LList) + 1);
        LList[High(LList)] := LToken;
        AParms[LNumParms] := LList;
      end;
    end;
    Inc(LNumParms);
  end;
  Result := True;
end;

function TIdParser.StringizeTokens(const ATokens: TArray<TIdToken>; out AToken: TIdToken): Boolean;
var
  LIndex: Integer;
begin
  AToken := TIdToken.Create;
  AToken.TokenType := TT_STRING;
  AToken.WhiteSpaceStart := -1;
  AToken.WhiteSpaceEnd := -1;
  AToken.Text := '';
  for LIndex := 0 to High(ATokens) do
    AToken.Text := AToken.Text + Copy(ATokens[LIndex].Text, 1, TIdStrings.Length(ATokens[LIndex].Text));
  Result := True;
end;

function TIdParser.MergeTokens(var AToken1: TIdToken; const AToken2: TIdToken): Boolean;
begin
  // merging of a name with a name or number
  if (AToken1.TokenType = TT_NAME) and ((AToken2.TokenType = TT_NAME) or
    ((AToken2.TokenType = TT_NUMBER) and ((AToken2.SubType and TT_FLOAT) = 0))) then
  begin
    AToken1.Text := AToken1.Text + AToken2.Text;
    Exit(True);
  end;
  // merging of two strings
  if (AToken1.TokenType = TT_STRING) and (AToken2.TokenType = TT_STRING) then
  begin
    AToken1.Text := AToken1.Text + AToken2.Text;
    Exit(True);
  end;
  // merging of two numbers
  if (AToken1.TokenType = TT_NUMBER) and (AToken2.TokenType = TT_NUMBER) and
    ((AToken1.SubType and (TT_HEX or TT_BINARY)) = 0) and ((AToken2.SubType and (TT_HEX or TT_BINARY)) = 0) and
    (((AToken1.SubType and TT_FLOAT) = 0) or ((AToken2.SubType and TT_FLOAT) = 0)) then
  begin
    AToken1.Text := AToken1.Text + AToken2.Text;
    Exit(True);
  end;
  Result := False;
end;

function TIdParser.ExpandBuiltinDefine(const ADefToken: TIdToken; const ADefine: TIdParserDefine;
  out ATokens: TArray<TIdToken>): Boolean;
var
  LToken: TIdToken;
  LNow: TDateTime;
  LYear, LMonth, LDay: Word;
  LText: string;
begin
  ATokens := nil;
  LToken := ADefToken;
  case ADefine.Builtin of
    BUILTIN_LINE:
      begin
        LToken.Text := AnsiString(IntToStr(ADefToken.Line));
        LToken.SetValues(Cardinal(ADefToken.Line), ADefToken.Line);
        LToken.TokenType := TT_NUMBER;
        LToken.SubType := TT_DECIMAL or TT_INTEGER or TT_VALUESVALID;
        LToken.Line := ADefToken.Line;
        LToken.LinesCrossed := ADefToken.LinesCrossed;
        LToken.Flags := 0;
        ATokens := [LToken];
      end;
    BUILTIN_FILE:
      begin
        LToken.Text := Top.FileName;
        LToken.TokenType := TT_NAME;
        LToken.SubType := TIdStrings.Length(LToken.Text);
        LToken.Line := ADefToken.Line;
        LToken.LinesCrossed := ADefToken.LinesCrossed;
        LToken.Flags := 0;
        ATokens := [LToken];
      end;
    BUILTIN_DATE:
      begin
        // the original cuts ctime() text with writes on the token that do not do it; this is the evident intent:
        // "Mmm dd yyyy" with the day padded with a space like ctime
        LNow := FClock();
        DecodeDate(LNow, LYear, LMonth, LDay);
        LText := Format('"%s %2d %d"', [MONTH_NAMES[LMonth], LDay, LYear]);
        LToken.Text := AnsiString(LText);
        LToken.TokenType := TT_STRING;
        LToken.SubType := TIdStrings.Length(LToken.Text);
        LToken.Line := ADefToken.Line;
        LToken.LinesCrossed := ADefToken.LinesCrossed;
        LToken.Flags := 0;
        ATokens := [LToken];
      end;
    BUILTIN_TIME:
      begin
        LNow := FClock();
        LToken.Text := AnsiString('"' + FormatDateTime('hh:nn:ss', LNow) + '"');
        LToken.TokenType := TT_STRING;
        LToken.SubType := TIdStrings.Length(LToken.Text);
        LToken.Line := ADefToken.Line;
        LToken.LinesCrossed := ADefToken.LinesCrossed;
        LToken.Flags := 0;
        ATokens := [LToken];
      end;
    BUILTIN_STDC:
      Warning('__STDC__ not supported'#10);
  end;
  Result := True;
end;

function TIdParser.ExpandDefine(const ADefToken: TIdToken; const ADefine: TIdParserDefine;
  out ATokens: TArray<TIdToken>): Boolean;
var
  LParms: TArray<TArray<TIdToken>>;
  LList: TList<TIdToken>;
  LToken, LStringized: TIdToken;
  LParmNumber, LIndex, LTokenIndex: Integer;
  LDefToken: TIdToken;
  LMerged: TIdToken;
begin
  ATokens := nil;
  // if it is a builtin define
  if ADefine.Builtin <> 0 then
    Exit(ExpandBuiltinDefine(ADefToken, ADefine, ATokens));
  // if the define has parameters
  if ADefine.NumParms > 0 then
  begin
    SetLength(LParms, MAX_DEFINEPARMS);
    if not ReadDefineParms(ADefine, LParms, MAX_DEFINEPARMS) then
      Exit(False);
  end;
  LList := TList<TIdToken>.Create;
  try
    // create a list with tokens of the expanded define
    LIndex := 0;
    while LIndex < System.Length(ADefine.Tokens) do
    begin
      LDefToken := ADefine.Tokens[LIndex];
      LParmNumber := -1;
      // if the token is a name, it could be a define parameter
      if LDefToken.TokenType = TT_NAME then
        LParmNumber := ADefine.FindParm(LDefToken.Text);
      if LParmNumber >= 0 then
      begin
        for LToken in LParms[LParmNumber] do
          LList.Add(LToken);
      end
      else
      begin
        // if stringizing operator
        if LDefToken.IsText('#') then
        begin
          // the stringizing operator must be followed by a define parameter
          if LIndex + 1 < System.Length(ADefine.Tokens) then
            LParmNumber := ADefine.FindParm(ADefine.Tokens[LIndex + 1].Text)
          else
            LParmNumber := -1;
          if LParmNumber >= 0 then
          begin
            // step over the stringizing operator
            Inc(LIndex);
            if not StringizeTokens(LParms[LParmNumber], LStringized) then
            begin
              Error('can''t stringize tokens');
              Exit(False);
            end;
            LToken := LStringized;
            LToken.Line := ADefToken.Line;
          end
          else
          begin
            Warning('stringizing operator without define parameter');
            Inc(LIndex);
            Continue;
          end;
        end
        else
        begin
          LToken := LDefToken;
          LToken.Line := ADefToken.Line;
        end;
        // the token being read from the define list uses the line number of the original file
        LToken.Line := ADefToken.Line;
        LList.Add(LToken);
      end;
      Inc(LIndex);
    end;
    // check for the merging operator
    LTokenIndex := 0;
    while LTokenIndex < LList.Count do
    begin
      if LTokenIndex + 1 < LList.Count then
      begin
        // if the merging operator
        if LList[LTokenIndex + 1].IsText('##') then
        begin
          if LTokenIndex + 2 < LList.Count then
          begin
            LMerged := LList[LTokenIndex];
            if not MergeTokens(LMerged, LList[LTokenIndex + 2]) then
            begin
              Error(Format('can''t merge ''%s'' with ''%s''', [string(LList[LTokenIndex].Text),
                string(LList[LTokenIndex + 2].Text)]));
              Exit(False);
            end;
            LList[LTokenIndex] := LMerged;
            LList.Delete(LTokenIndex + 2);
            LList.Delete(LTokenIndex + 1);
            Continue;
          end;
        end;
      end;
      Inc(LTokenIndex);
    end;
    ATokens := LList.ToArray;
  finally
    LList.Free;
  end;
  Result := True;
end;

function TIdParser.ExpandDefineIntoSource(const ADefToken: TIdToken; const ADefine: TIdParserDefine): Boolean;
var
  LTokens: TArray<TIdToken>;
  LIndex: Integer;
begin
  if not ExpandDefine(ADefToken, ADefine, LTokens) then
    Exit(False);
  // if the define is not empty put its tokens in front of the others
  if System.Length(LTokens) > 0 then
  begin
    Inc(LTokens[0].LinesCrossed, ADefToken.LinesCrossed);
    for LIndex := High(LTokens) downto 0 do
      FTokens.Add(LTokens[LIndex]);
  end;
  Result := True;
end;

function TIdParser.Directive_include: Boolean;
var
  LScript: TIdLexer;
  LToken: TIdToken;
  LPath: TIdStr;
begin
  LScript := nil;
  LPath := TIdStr.Create('');
  if not ReadSourceToken(LToken) then
  begin
    Error('#include without file name');
    Exit(False);
  end;
  if LToken.LinesCrossed > 0 then
  begin
    Error('#include without file name');
    Exit(False);
  end;
  if LToken.TokenType = TT_STRING then
  begin
    LScript := NewLexer;
    // try relative to the current file
    LPath := TIdStr.Create(Top.FileName);
    LPath.StripFilename;
    LPath.Append('/');
    LPath.Append(LToken.Text);
    if not LScript.LoadFile(LPath.Text, FOSPath) then
    begin
      // try absolute path
      LPath := TIdStr.Create(LToken.Text);
      if not LScript.LoadFile(LPath.Text, FOSPath) then
      begin
        // try from the include path
        LPath := TIdStr.Create(FIncludePath + LToken.Text);
        if not LScript.LoadFile(LPath.Text, FOSPath) then
          FreeAndNil(LScript);
      end;
    end;
  end
  else if (LToken.TokenType = TT_PUNCTUATION) and LToken.IsText('<') then
  begin
    LPath := TIdStr.Create(FIncludePath);
    while ReadSourceToken(LToken) do
    begin
      if LToken.LinesCrossed > 0 then
      begin
        UnreadSourceToken(LToken);
        Break;
      end;
      if (LToken.TokenType = TT_PUNCTUATION) and LToken.IsText('>') then
        Break;
      LPath.Append(LToken.Text);
    end;
    if not LToken.IsText('>') then
      Warning('#include missing trailing >');
    if LPath.Length = 0 then
    begin
      Error('#include without file name between < >');
      Exit(False);
    end;
    if (FFlags and LEXFL_NOBASEINCLUDES) <> 0 then
      Exit(True);
    LScript := NewLexer;
    if not LScript.LoadFile(FIncludePath + LPath.Text, FOSPath) then
      FreeAndNil(LScript);
  end
  else
  begin
    Error('#include without file name');
    Exit(False);
  end;
  if LScript = nil then
  begin
    Error(Format('file ''%s'' not found', [string(LPath.Text)]));
    Exit(False);
  end;
  LScript.Flags := FFlags;
  LScript.SetPunctuations(FPunctuations);
  PushScript(LScript);
  Result := True;
end;

function TIdParser.Directive_undef: Boolean;
var
  LToken: TIdToken;
  LBucket: TList<TIdParserDefine>;
  LIndex: Integer;
begin
  if not ReadLine(LToken) then
  begin
    Error('undef without name');
    Exit(False);
  end;
  if LToken.TokenType <> TT_NAME then
  begin
    UnreadSourceToken(LToken);
    Error(Format('expected name but found ''%s''', [string(LToken.Text)]));
    Exit(False);
  end;
  LBucket := FDefineHash[NameHash(LToken.Text)];
  for LIndex := LBucket.Count - 1 downto 0 do
    if LBucket[LIndex].Name = LToken.Text then
    begin
      if (LBucket[LIndex].Flags and DEFINE_FIXED) <> 0 then
        Warning(Format('can''t undef ''%s''', [string(LToken.Text)]))
      else
        LBucket.Delete(LIndex);
      Break;
    end;
  Result := True;
end;

function TIdParser.Directive_define: Boolean;
var
  LToken, LParm: TIdToken;
  LDefine: TIdParserDefine;
  LLast: TIdToken;
begin
  if not ReadLine(LToken) then
  begin
    Error('#define without name');
    Exit(False);
  end;
  if LToken.TokenType <> TT_NAME then
  begin
    UnreadSourceToken(LToken);
    Error(Format('expected name after #define, found ''%s''', [string(LToken.Text)]));
    Exit(False);
  end;
  // check if the define already exists
  LDefine := FindHashedDefine(LToken.Text);
  if LDefine <> nil then
  begin
    if (LDefine.Flags and DEFINE_FIXED) <> 0 then
    begin
      Error(Format('can''t redefine ''%s''', [string(LToken.Text)]));
      Exit(False);
    end;
    Warning(Format('redefinition of ''%s''', [string(LToken.Text)]));
    // unread the define name before executing the #undef directive
    UnreadSourceToken(LToken);
    if not Directive_undef then
      Exit(False);
  end;
  LDefine := TIdParserDefine.Create(Copy(LToken.Text, 1, TIdStrings.Length(LToken.Text)));
  // add the define to the source
  AddDefineToHash(LDefine);
  // if nothing is defined, just return
  if not ReadLine(LToken) then
    Exit(True);
  // if it is a define with parameters
  if (not LToken.WhiteSpaceBeforeToken) and LToken.IsText('(') then
  begin
    // read the define parameters
    if not CheckTokenString(')') then
    begin
      while True do
      begin
        if not ReadLine(LToken) then
        begin
          Error('expected define parameter');
          Exit(False);
        end;
        // if it isn't a name
        if LToken.TokenType <> TT_NAME then
        begin
          Error('invalid define parameter');
          Exit(False);
        end;
        if LDefine.FindParm(LToken.Text) >= 0 then
        begin
          Error('two the same define parameters');
          Exit(False);
        end;
        // add the define parm
        LParm := LToken;
        LParm.ClearTokenWhiteSpace;
        LDefine.AddParm(LParm);
        // read next token
        if not ReadLine(LToken) then
        begin
          Error('define parameters not terminated');
          Exit(False);
        end;
        if LToken.IsText(')') then
          Break;
        // then it must be a comma
        if not LToken.IsText(',') then
        begin
          Error('define not terminated');
          Exit(False);
        end;
      end;
    end;
    if not ReadLine(LToken) then
      Exit(True);
  end;
  // read the defined stuff
  repeat
    LParm := LToken;
    if (LParm.TokenType = TT_NAME) and (LParm.Text = LDefine.Name) then
    begin
      LParm.Flags := LParm.Flags or TOKEN_FL_RECURSIVE_DEFINE;
      Warning('recursive define (removed recursion)');
    end;
    LParm.ClearTokenWhiteSpace;
    LDefine.AddToken(LParm);
  until not ReadLine(LToken);
  if System.Length(LDefine.Tokens) > 0 then
  begin
    LLast := LDefine.Tokens[High(LDefine.Tokens)];
    // check for merge operators at the beginning or end
    if LDefine.Tokens[0].IsText('##') or LLast.IsText('##') then
    begin
      Error('define with misplaced ##');
      Exit(False);
    end;
  end;
  Result := True;
end;

function TIdParser.Directive_if_def(const AKind: Integer): Boolean;
var
  LToken: TIdToken;
  LSkip: Boolean;
begin
  if not ReadLine(LToken) then
  begin
    Error('#ifdef without name');
    Exit(False);
  end;
  if LToken.TokenType <> TT_NAME then
  begin
    UnreadSourceToken(LToken);
    Error(Format('expected name after #ifdef, found ''%s''', [string(LToken.Text)]));
    Exit(False);
  end;
  LSkip := (AKind = INDENT_IFDEF) = (FindHashedDefine(LToken.Text) = nil);
  PushIndent(AKind, LSkip);
  Result := True;
end;

function TIdParser.Directive_ifdef: Boolean;
begin
  Result := Directive_if_def(INDENT_IFDEF);
end;

function TIdParser.Directive_ifndef: Boolean;
begin
  Result := Directive_if_def(INDENT_IFNDEF);
end;

function TIdParser.Directive_else: Boolean;
var
  LKind: Integer;
  LSkip: Boolean;
begin
  PopIndent(LKind, LSkip);
  if LKind = 0 then
  begin
    Error('misplaced #else');
    Exit(False);
  end;
  if LKind = INDENT_ELSE then
  begin
    Error('#else after #else');
    Exit(False);
  end;
  PushIndent(INDENT_ELSE, not LSkip);
  Result := True;
end;

function TIdParser.Directive_endif: Boolean;
var
  LKind: Integer;
  LSkip: Boolean;
begin
  PopIndent(LKind, LSkip);
  if LKind = 0 then
  begin
    Error('misplaced #endif');
    Exit(False);
  end;
  Result := True;
end;

function TIdParser.Evaluate(out AIntValue: Integer; out AFloatValue: Double; const AInteger: Boolean): Boolean;
var
  LToken, LCopy: TIdToken;
  LList: TList<TIdToken>;
  LDefine: TIdParserDefine;
  LDefined: Boolean;
begin
  AIntValue := 0;
  AFloatValue := 0;
  if not ReadLine(LToken) then
  begin
    Error('no value after #if/#elif');
    Exit(False);
  end;
  LDefined := False;
  LList := TList<TIdToken>.Create;
  try
    repeat
      // if the token is a name
      if LToken.TokenType = TT_NAME then
      begin
        if LDefined then
        begin
          LDefined := False;
          LList.Add(LToken);
        end
        else if LToken.IsText('defined') then
        begin
          LDefined := True;
          LList.Add(LToken);
        end
        else
        begin
          // then it must be a define
          LDefine := FindHashedDefine(LToken.Text);
          if LDefine = nil then
          begin
            Error(Format('can''t Evaluate ''%s'', not defined', [string(LToken.Text)]));
            Exit(False);
          end;
          if not ExpandDefineIntoSource(LToken, LDefine) then
            Exit(False);
        end;
      end
      // if the token is a number or a punctuation
      else if (LToken.TokenType = TT_NUMBER) or (LToken.TokenType = TT_PUNCTUATION) then
      begin
        LCopy := LToken;
        LList.Add(LCopy);
      end
      else
      begin
        Error(Format('can''t Evaluate ''%s''', [string(LToken.Text)]));
        Exit(False);
      end;
    until not ReadLine(LToken);
    Result := FEvaluator.Evaluate(LList.ToArray, AInteger, AIntValue, AFloatValue);
  finally
    LList.Free;
  end;
end;

function TIdParser.DollarEvaluate(out AIntValue: Integer; out AFloatValue: Double; const AInteger: Boolean): Boolean;
var
  LIndent: Integer;
  LDefined: Boolean;
  LToken: TIdToken;
  LList: TList<TIdToken>;
  LDefine: TIdParserDefine;
  LBreak: Boolean;
begin
  AIntValue := 0;
  AFloatValue := 0;
  if not ReadSourceToken(LToken) then
  begin
    Error('no leading ( after $evalint/$evalfloat');
    Exit(False);
  end;
  if not ReadSourceToken(LToken) then
  begin
    Error('nothing to Evaluate');
    Exit(False);
  end;
  LIndent := 1;
  LDefined := False;
  LList := TList<TIdToken>.Create;
  try
    repeat
      LBreak := False;
      // if the token is a name
      if LToken.TokenType = TT_NAME then
      begin
        if LDefined then
        begin
          LDefined := False;
          LList.Add(LToken);
        end
        else if LToken.IsText('defined') then
        begin
          LDefined := True;
          LList.Add(LToken);
        end
        else
        begin
          // then it must be a define
          LDefine := FindHashedDefine(LToken.Text);
          if LDefine = nil then
          begin
            Warning(Format('can''t Evaluate ''%s'', not defined', [string(LToken.Text)]));
            Exit(False);
          end;
          if not ExpandDefineIntoSource(LToken, LDefine) then
            Exit(False);
        end;
      end
      // if the token is a number or a punctuation
      else if (LToken.TokenType = TT_NUMBER) or (LToken.TokenType = TT_PUNCTUATION) then
      begin
        if TIdStrings.CharAt(LToken.Text, 0) = Ord('(') then
          Inc(LIndent)
        else if TIdStrings.CharAt(LToken.Text, 0) = Ord(')') then
          Dec(LIndent);
        if LIndent <= 0 then
          LBreak := True
        else
          LList.Add(LToken);
      end
      else
      begin
        Error(Format('can''t Evaluate ''%s''', [string(LToken.Text)]));
        Exit(False);
      end;
    until LBreak or not ReadSourceToken(LToken);
    Result := FEvaluator.Evaluate(LList.ToArray, AInteger, AIntValue, AFloatValue);
  finally
    LList.Free;
  end;
end;

function TIdParser.Directive_elif: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LKind: Integer;
  LSkip: Boolean;
begin
  PopIndent(LKind, LSkip);
  if (LKind = 0) or (LKind = INDENT_ELSE) then
  begin
    Error('misplaced #elif');
    Exit(False);
  end;
  if not Evaluate(LValue, LFloat, True) then
    Exit(False);
  PushIndent(INDENT_ELIF, LValue = 0);
  Result := True;
end;

function TIdParser.Directive_if: Boolean;
var
  LValue: Integer;
  LFloat: Double;
begin
  if not Evaluate(LValue, LFloat, True) then
    Exit(False);
  PushIndent(INDENT_IF, LValue = 0);
  Result := True;
end;

function TIdParser.Directive_line: Boolean;
var
  LToken: TIdToken;
begin
  Error('#line directive not supported');
  while ReadLine(LToken) do
    ;
  Result := True;
end;

function TIdParser.Directive_error: Boolean;
var
  LToken: TIdToken;
begin
  if (not ReadLine(LToken)) or (LToken.TokenType <> TT_STRING) then
  begin
    Error('#error without string');
    Exit(False);
  end;
  Error('#error: ' + string(LToken.Text));
  Result := True;
end;

function TIdParser.Directive_warning: Boolean;
var
  LToken: TIdToken;
begin
  if (not ReadLine(LToken)) or (LToken.TokenType <> TT_STRING) then
  begin
    Warning('#warning without string');
    Exit(False);
  end;
  Warning('#warning: ' + string(LToken.Text));
  Result := True;
end;

function TIdParser.Directive_pragma: Boolean;
var
  LToken: TIdToken;
begin
  Warning('#pragma directive not supported');
  while ReadLine(LToken) do
    ;
  Result := True;
end;

procedure TIdParser.UnreadSignToken;
var
  LToken: TIdToken;
begin
  LToken := NewValueToken;
  LToken.Text := '-';
  LToken.TokenType := TT_PUNCTUATION;
  LToken.SubType := P_SUB;
  UnreadSourceToken(LToken);
end;

function TIdParser.Directive_eval: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LToken: TIdToken;
begin
  if not Evaluate(LValue, LFloat, True) then
    Exit(False);
  LToken := NewValueToken;
  LToken.Text := AnsiString(IntToStr(Abs(LValue)));
  LToken.TokenType := TT_NUMBER;
  LToken.SubType := TT_INTEGER or TT_LONG or TT_DECIMAL;
  UnreadSourceToken(LToken);
  if LValue < 0 then
    UnreadSignToken;
  Result := True;
end;

function TIdParser.Directive_evalfloat: Boolean;
var
  LInt: Integer;
  LValue: Double;
  LToken: TIdToken;
begin
  if not Evaluate(LInt, LValue, False) then
    Exit(False);
  LToken := NewValueToken;
  LToken.Text := FormatTwoDecimals(LValue);
  LToken.TokenType := TT_NUMBER;
  LToken.SubType := TT_FLOAT or TT_LONG or TT_DECIMAL;
  UnreadSourceToken(LToken);
  if LValue < 0 then
    UnreadSignToken;
  Result := True;
end;

function TIdParser.ReadDirective: Boolean;
var
  LToken: TIdToken;
begin
  // read the directive name
  if not ReadSourceToken(LToken) then
  begin
    Error('found ''#'' without name');
    Exit(False);
  end;
  // directive name must be on the same line
  if LToken.LinesCrossed > 0 then
  begin
    UnreadSourceToken(LToken);
    Error('found ''#'' at end of line');
    Exit(False);
  end;
  if LToken.TokenType = TT_NAME then
  begin
    if LToken.IsText('if') then
      Exit(Directive_if)
    else if LToken.IsText('ifdef') then
      Exit(Directive_ifdef)
    else if LToken.IsText('ifndef') then
      Exit(Directive_ifndef)
    else if LToken.IsText('elif') then
      Exit(Directive_elif)
    else if LToken.IsText('else') then
      Exit(Directive_else)
    else if LToken.IsText('endif') then
      Exit(Directive_endif)
    else if FSkip > 0 then
    begin
      // skip the rest of the line
      while ReadLine(LToken) do
        ;
      Exit(True);
    end
    else
    begin
      if LToken.IsText('include') then
        Exit(Directive_include)
      else if LToken.IsText('define') then
        Exit(Directive_define)
      else if LToken.IsText('undef') then
        Exit(Directive_undef)
      else if LToken.IsText('line') then
        Exit(Directive_line)
      else if LToken.IsText('error') then
        Exit(Directive_error)
      else if LToken.IsText('warning') then
        Exit(Directive_warning)
      else if LToken.IsText('pragma') then
        Exit(Directive_pragma)
      else if LToken.IsText('eval') then
        Exit(Directive_eval)
      else if LToken.IsText('evalfloat') then
        Exit(Directive_evalfloat);
    end;
  end;
  Error(Format('unknown precompiler directive ''%s''', [string(LToken.Text)]));
  Result := False;
end;

function TIdParser.DollarDirective_evalint: Boolean;
var
  LValue: Integer;
  LFloat: Double;
  LToken: TIdToken;
begin
  if not DollarEvaluate(LValue, LFloat, True) then
    Exit(False);
  LToken := NewValueToken;
  LToken.Text := AnsiString(IntToStr(Abs(LValue)));
  LToken.TokenType := TT_NUMBER;
  LToken.SubType := TT_INTEGER or TT_LONG or TT_DECIMAL or TT_VALUESVALID;
  LToken.SetValues(Cardinal(Abs(LValue)), Abs(LValue));
  UnreadSourceToken(LToken);
  if LValue < 0 then
    UnreadSignToken;
  Result := True;
end;

function TIdParser.DollarDirective_evalfloat: Boolean;
var
  LInt: Integer;
  LValue: Double;
  LToken: TIdToken;
begin
  if not DollarEvaluate(LInt, LValue, False) then
    Exit(False);
  LToken := NewValueToken;
  LToken.Text := FormatTwoDecimals(LValue);
  LToken.TokenType := TT_NUMBER;
  LToken.SubType := TT_FLOAT or TT_LONG or TT_DECIMAL or TT_VALUESVALID;
  // (unsigned long) fabs(value): the conversion of a value out of range is undefined in C++
  if Abs(LValue) < 4294967296.0 then
    LToken.SetValues(Cardinal(Trunc(Abs(LValue))), Abs(LValue))
  else
    LToken.SetValues(0, Abs(LValue));
  UnreadSourceToken(LToken);
  if LValue < 0 then
    UnreadSignToken;
  Result := True;
end;

function TIdParser.ReadDollarDirective: Boolean;
var
  LToken: TIdToken;
begin
  // read the directive name
  if not ReadSourceToken(LToken) then
  begin
    Error('found ''$'' without name');
    Exit(False);
  end;
  // directive name must be on the same line
  if LToken.LinesCrossed > 0 then
  begin
    UnreadSourceToken(LToken);
    Error('found ''$'' at end of line');
    Exit(False);
  end;
  if LToken.TokenType = TT_NAME then
  begin
    if LToken.IsText('evalint') then
      Exit(DollarDirective_evalint)
    else if LToken.IsText('evalfloat') then
      Exit(DollarDirective_evalfloat);
  end;
  UnreadSourceToken(LToken);
  Result := False;
end;

function TIdParser.ReadToken(var AToken: TIdToken): Boolean;
var
  LDefine: TIdParserDefine;
  LNewToken: TIdToken;
begin
  while True do
  begin
    if not ReadSourceToken(AToken) then
      Exit(False);
    // check for precompiler directives
    if (AToken.TokenType = TT_PUNCTUATION) and (AToken.Text = '#') then
    begin
      // read the precompiler directive
      if not ReadDirective then
        Exit(False);
      Continue;
    end;
    // if skipping source because of conditional compilation
    if FSkip <> 0 then
      Continue;
    // recursively concatenate strings that are behind each other still resolving defines
    if (AToken.TokenType = TT_STRING) and ((Top.Flags and LEXFL_NOSTRINGCONCAT) = 0) then
    begin
      if ReadToken(LNewToken) then
      begin
        if LNewToken.TokenType = TT_STRING then
          AToken.Text := AToken.Text + LNewToken.Text
        else
          UnreadSourceToken(LNewToken);
      end;
    end;
    if (Top.Flags and LEXFL_NODOLLARPRECOMPILE) = 0 then
    begin
      // check for special precompiler directives
      if (AToken.TokenType = TT_PUNCTUATION) and (AToken.Text = '$') then
      begin
        // read the precompiler directive
        if ReadDollarDirective then
          Continue;
      end;
    end;
    // if the token is a name
    if (AToken.TokenType = TT_NAME) and ((AToken.Flags and TOKEN_FL_RECURSIVE_DEFINE) = 0) then
    begin
      // check if the name is a define macro
      LDefine := FindHashedDefine(AToken.Text);
      if LDefine <> nil then
      begin
        // expand the defined macro
        if not ExpandDefineIntoSource(AToken, LDefine) then
          Exit(False);
        Continue;
      end;
    end;
    // found a token
    Exit(True);
  end;
end;

function TIdParser.ExpectTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
  begin
    Error(Format('couldn''t find expected ''%s''', [string(AText)]));
    Exit(False);
  end;
  if not LToken.IsText(AText) then
  begin
    Error(Format('expected ''%s'' but found ''%s''', [string(AText), string(LToken.Text)]));
    Exit(False);
  end;
  Result := True;
end;

function TIdParser.ExpectTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
var
  LText: AnsiString;
begin
  if not ReadToken(AToken) then
  begin
    Error('couldn''t read expected token');
    Exit(False);
  end;
  if AToken.TokenType <> AType then
  begin
    case AType of
      TT_STRING: LText := 'string';
      TT_LITERAL: LText := 'literal';
      TT_NUMBER: LText := 'number';
      TT_NAME: LText := 'name';
      TT_PUNCTUATION: LText := 'punctuation';
    else
      LText := 'unknown type';
    end;
    Error(Format('expected a %s but found ''%s''', [string(LText), string(AToken.Text)]));
    Exit(False);
  end;
  if AToken.TokenType = TT_NUMBER then
  begin
    if (AToken.SubType and ASubType) <> ASubType then
    begin
      LText := '';
      if (ASubType and TT_DECIMAL) <> 0 then
        LText := 'decimal ';
      if (ASubType and TT_HEX) <> 0 then
        LText := 'hex ';
      if (ASubType and TT_OCTAL) <> 0 then
        LText := 'octal ';
      if (ASubType and TT_BINARY) <> 0 then
        LText := 'binary ';
      if (ASubType and TT_UNSIGNED) <> 0 then
        LText := LText + 'unsigned ';
      if (ASubType and TT_LONG) <> 0 then
        LText := LText + 'long ';
      if (ASubType and TT_FLOAT) <> 0 then
        LText := LText + 'float ';
      if (ASubType and TT_INTEGER) <> 0 then
        LText := LText + 'integer ';
      while (LText <> '') and (LText[System.Length(LText)] = ' ') do
        SetLength(LText, System.Length(LText) - 1);
      Error(Format('expected %s but found ''%s''', [string(LText), string(AToken.Text)]));
      Exit(False);
    end;
  end
  else if AToken.TokenType = TT_PUNCTUATION then
  begin
    if ASubType < 0 then
    begin
      Error('BUG: wrong punctuation subtype');
      Exit(False);
    end;
    if AToken.SubType <> ASubType then
    begin
      Error(Format('expected ''%s'' but found ''%s''', [string(GetPunctuationFromId(ASubType)),
        string(AToken.Text)]));
      Exit(False);
    end;
  end;
  Result := True;
end;

function TIdParser.ExpectAnyToken(var AToken: TIdToken): Boolean;
begin
  if not ReadToken(AToken) then
  begin
    Error('couldn''t read expected token');
    Exit(False);
  end;
  Result := True;
end;

function TIdParser.CheckTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
    Exit(False);
  // if the token is available
  if LToken.IsText(AText) then
    Exit(True);
  UnreadSourceToken(LToken);
  Result := False;
end;

function TIdParser.CheckTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
    Exit(False);
  // if the type matches
  if (LToken.TokenType = AType) and ((LToken.SubType and ASubType) = ASubType) then
  begin
    AToken := LToken;
    Exit(True);
  end;
  UnreadSourceToken(LToken);
  Result := False;
end;

function TIdParser.PeekTokenString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
    Exit(False);
  UnreadSourceToken(LToken);
  Result := LToken.IsText(AText);
end;

function TIdParser.PeekTokenType(const AType, ASubType: Integer; var AToken: TIdToken): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
    Exit(False);
  UnreadSourceToken(LToken);
  if (LToken.TokenType = AType) and ((LToken.SubType and ASubType) = ASubType) then
  begin
    AToken := LToken;
    Exit(True);
  end;
  Result := False;
end;

function TIdParser.SkipUntilString(const AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  while ReadToken(LToken) do
    if LToken.IsText(AText) then
      Exit(True);
  Result := False;
end;

function TIdParser.SkipRestOfLine: Boolean;
var
  LToken: TIdToken;
begin
  while ReadToken(LToken) do
    if LToken.LinesCrossed <> 0 then
    begin
      UnreadSourceToken(LToken);
      Exit(True);
    end;
  Result := False;
end;

function TIdParser.SkipBracedSection(const AParseFirstBrace: Boolean): Boolean;
var
  LToken: TIdToken;
  LDepth: Integer;
begin
  if AParseFirstBrace then
    LDepth := 0
  else
    LDepth := 1;
  repeat
    if not ReadToken(LToken) then
      Exit(False);
    if LToken.TokenType = TT_PUNCTUATION then
    begin
      if LToken.IsText('{') then
        Inc(LDepth)
      else if LToken.IsText('}') then
        Dec(LDepth);
    end;
  until LDepth = 0;
  Result := True;
end;

function TIdParser.ParseBracedSectionExact(var AOutput: AnsiString; const ATabs: Integer): AnsiString;
begin
  if FScripts.Count = 0 then
  begin
    AOutput := '';
    Exit('');
  end;
  Result := Top.ParseBracedSectionExact(AOutput, ATabs);
end;

function TIdParser.ParseBracedSection(var AOutput: AnsiString; ATabs: Integer): AnsiString;
var
  LToken: TIdToken;
  LIndex, LDepth, LCount: Integer;
  LDoTabs: Boolean;
begin
  LDoTabs := ATabs >= 0;
  AOutput := '';
  if not ExpectTokenString('{') then
    Exit(AOutput);
  AOutput := '{';
  LDepth := 1;
  repeat
    if not ReadToken(LToken) then
    begin
      Error('missing closing brace');
      Exit(AOutput);
    end;
    // if the token is on a new line
    for LIndex := 1 to LToken.LinesCrossed do
      AOutput := AOutput + #13#10;
    if LDoTabs and (LToken.LinesCrossed <> 0) then
    begin
      LCount := ATabs;
      if (TIdStrings.CharAt(LToken.Text, 0) = Ord('}')) and (LCount > 0) then
        Dec(LCount);
      while LCount > 0 do
      begin
        AOutput := AOutput + #9;
        Dec(LCount);
      end;
    end;
    if LToken.TokenType = TT_PUNCTUATION then
    begin
      if TIdStrings.CharAt(LToken.Text, 0) = Ord('{') then
      begin
        Inc(LDepth);
        if LDoTabs then
          Inc(ATabs);
      end
      else if TIdStrings.CharAt(LToken.Text, 0) = Ord('}') then
      begin
        Dec(LDepth);
        if LDoTabs then
          Dec(ATabs);
      end;
    end;
    if LToken.TokenType = TT_STRING then
      AOutput := AOutput + '"' + LToken.Text + '"'
    else
      AOutput := AOutput + LToken.Text;
    AOutput := AOutput + ' ';
  until LDepth = 0;
  Result := AOutput;
end;

function TIdParser.ParseRestOfLine(var AOutput: AnsiString): AnsiString;
var
  LToken: TIdToken;
begin
  AOutput := '';
  while ReadToken(LToken) do
  begin
    if LToken.LinesCrossed <> 0 then
    begin
      UnreadSourceToken(LToken);
      Break;
    end;
    if AOutput <> '' then
      AOutput := AOutput + ' ';
    AOutput := AOutput + LToken.Text;
  end;
  Result := AOutput;
end;

procedure TIdParser.UnreadToken(const AToken: TIdToken);
begin
  UnreadSourceToken(AToken);
end;

function TIdParser.ReadTokenOnLine(var AToken: TIdToken): Boolean;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
    Exit(False);
  // if no lines were crossed before this token
  if LToken.LinesCrossed = 0 then
  begin
    AToken := LToken;
    Exit(True);
  end;
  UnreadSourceToken(LToken);
  Result := False;
end;

function TIdParser.ParseInt: Integer;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
  begin
    Error('couldn''t read expected integer');
    Exit(0);
  end;
  if (LToken.TokenType = TT_PUNCTUATION) and LToken.IsText('-') then
  begin
    ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
    Exit(-LToken.GetIntValue);
  end
  else if (LToken.TokenType <> TT_NUMBER) or (LToken.SubType = TT_FLOAT) then
    Error(Format('expected integer value, found ''%s''', [string(LToken.Text)]));
  Result := LToken.GetIntValue;
end;

function TIdParser.ParseBool: Boolean;
var
  LToken: TIdToken;
begin
  if not ExpectTokenType(TT_NUMBER, 0, LToken) then
  begin
    Error('couldn''t read expected boolean');
    Exit(False);
  end;
  Result := LToken.GetIntValue <> 0;
end;

function TIdParser.ParseFloat: Single;
var
  LToken: TIdToken;
begin
  if not ReadToken(LToken) then
  begin
    Error('couldn''t read expected floating point number');
    Exit(0.0);
  end;
  if (LToken.TokenType = TT_PUNCTUATION) and LToken.IsText('-') then
  begin
    ExpectTokenType(TT_NUMBER, 0, LToken);
    Result := -LToken.GetFloatValue;
    Exit;
  end
  else if LToken.TokenType <> TT_NUMBER then
    Error(Format('expected float value, found ''%s''', [string(LToken.Text)]));
  Result := LToken.GetFloatValue;
end;

function TIdParser.Parse1DMatrix(const AX: Integer; var AMatrix: array of Single; const AOffset: Integer): Boolean;
var
  LIndex: Integer;
begin
  if not ExpectTokenString('(') then
    Exit(False);
  for LIndex := 0 to AX - 1 do
    AMatrix[AOffset + LIndex] := ParseFloat;
  Result := ExpectTokenString(')');
end;

function TIdParser.Parse2DMatrix(const AY, AX: Integer; var AMatrix: array of Single; const AOffset: Integer): Boolean;
var
  LIndex: Integer;
begin
  if not ExpectTokenString('(') then
    Exit(False);
  for LIndex := 0 to AY - 1 do
    if not Parse1DMatrix(AX, AMatrix, AOffset + LIndex * AX) then
      Exit(False);
  Result := ExpectTokenString(')');
end;

function TIdParser.Parse3DMatrix(const AZ, AY, AX: Integer; var AMatrix: array of Single;
  const AOffset: Integer): Boolean;
var
  LIndex: Integer;
begin
  if not ExpectTokenString('(') then
    Exit(False);
  for LIndex := 0 to AZ - 1 do
    if not Parse2DMatrix(AY, AX, AMatrix, AOffset + LIndex * AX * AY) then
      Exit(False);
  Result := ExpectTokenString(')');
end;

function TIdParser.GetLastWhiteSpace(var AWhiteSpace: AnsiString): Integer;
begin
  if FScripts.Count > 0 then
    Top.GetLastWhiteSpace(AWhiteSpace)
  else
    AWhiteSpace := '';
  Result := System.Length(AWhiteSpace);
end;

procedure TIdParser.SetMarker;
begin
  FMarker := -1;
end;

procedure TIdParser.GetStringFromMarker(var AOutput: AnsiString; const AClean: Boolean);
var
  LEnd: Integer;
  LText: AnsiString;
  LTemp: TIdParser;
  LToken: TIdToken;
begin
  if FScripts.Count = 0 then
    Exit;
  if FMarker < 0 then
    FMarker := 0;
  if (FTokens.Count > 0) and (FTokens.Last.WhiteSpaceStart >= 0) then
    LEnd := FTokens.Last.WhiteSpaceStart
  else
    LEnd := Top.GetFileOffset;
  LText := Top.GetBufferText(FMarker, LEnd);
  // if cleaning then reparse
  if AClean then
  begin
    LTemp := TIdParser.Create(FFlags, FLog, FFileSystem, FGlobalDefines);
    try
      if LTemp.LoadMemory(LText, System.Length(LText), 'temp') then
        while LTemp.ReadToken(LToken) do
          AOutput := AOutput + LToken.Text;
    finally
      LTemp.Free;
    end;
  end
  else
    AOutput := LText;
end;

procedure TIdParser.SetIncludePath(const APath: AnsiString);
begin
  FIncludePath := APath;
  // add trailing path separator
  if (FIncludePath = '') or ((FIncludePath[System.Length(FIncludePath)] <> '\') and
    (FIncludePath[System.Length(FIncludePath)] <> '/')) then
    FIncludePath := FIncludePath + PATH_SEPARATOR;
end;

procedure TIdParser.SetPunctuations(const APunctuations: TIdPunctuationList);
begin
  FPunctuations := APunctuations;
end;

function TIdParser.GetPunctuationFromId(const AId: Integer): AnsiString;
var
  LIndex: Integer;
  LLexer: TIdLexer;
begin
  if System.Length(FPunctuations) = 0 then
  begin
    LLexer := TIdLexer.Create;
    try
      Exit(LLexer.GetPunctuationFromId(AId));
    finally
      LLexer.Free;
    end;
  end;
  for LIndex := 0 to High(FPunctuations) do
    if FPunctuations[LIndex].Id = AId then
      Exit(FPunctuations[LIndex].Text);
  Result := 'unkown punctuation';
end;

function TIdParser.GetPunctuationId(const AText: AnsiString): Integer;
var
  LIndex: Integer;
  LLexer: TIdLexer;
begin
  if System.Length(FPunctuations) = 0 then
  begin
    LLexer := TIdLexer.Create;
    try
      Exit(LLexer.GetPunctuationId(AText));
    finally
      LLexer.Free;
    end;
  end;
  for LIndex := 0 to High(FPunctuations) do
    if FPunctuations[LIndex].Text = AText then
      Exit(FPunctuations[LIndex].Id);
  Result := 0;
end;

procedure TIdParser.SetFlags(const AFlags: Integer);
var
  LScript: TIdLexer;
begin
  FFlags := AFlags;
  for LScript in FScripts do
    LScript.Flags := AFlags;
end;

function TIdParser.GetFlags: Integer;
begin
  Result := FFlags;
end;

function TIdParser.GetFileName: AnsiString;
begin
  if FScripts.Count > 0 then
    Result := Top.FileName
  else
    Result := '';
end;

function TIdParser.GetFileOffset: Integer;
begin
  if FScripts.Count > 0 then
    Result := Top.GetFileOffset
  else
    Result := 0;
end;

function TIdParser.GetFileTime: Int64;
begin
  if FScripts.Count > 0 then
    Result := Top.FileTime
  else
    Result := 0;
end;

function TIdParser.GetLineNum: Integer;
begin
  if FScripts.Count > 0 then
    Result := Top.LineNum
  else
    Result := 0;
end;

function TIdParser.IsLoaded: Boolean;
begin
  Result := FLoaded;
end;

function TIdParser.LoadFile(const AFileName: AnsiString; const AIsOsPath: Boolean): Boolean;
var
  LScript: TIdLexer;
begin
  if FLoaded then
    raise EIdLibFatalException.Create('idParser::loadFile: another source already loaded');
  LScript := NewLexer;
  if not LScript.LoadFile(AFileName, AIsOsPath) then
  begin
    LScript.Free;
    Exit(False);
  end;
  LScript.Flags := FFlags;
  LScript.SetPunctuations(FPunctuations);
  FOSPath := AIsOsPath;
  FFileName := AFileName;
  FScripts.Add(LScript);
  FTokens.Clear;
  FIndents.Clear;
  FSkip := 0;
  FLoaded := True;
  if FDefineHash = nil then
  begin
    CreateDefineTable;
    AddGlobalDefinesToSource;
  end;
  Result := True;
end;

function TIdParser.LoadMemory(const AText: AnsiString; const ALength: Integer; const AName: AnsiString): Boolean;
var
  LScript: TIdLexer;
begin
  if FLoaded then
    raise EIdLibFatalException.Create('idParser::loadMemory: another source already loaded');
  LScript := NewLexer;
  if not LScript.LoadMemory(AText, ALength, AName) then
  begin
    LScript.Free;
    Exit(False);
  end;
  LScript.Flags := FFlags;
  LScript.SetPunctuations(FPunctuations);
  FFileName := AName;
  FScripts.Add(LScript);
  FTokens.Clear;
  FIndents.Clear;
  FSkip := 0;
  FLoaded := True;
  if FDefineHash = nil then
  begin
    CreateDefineTable;
    AddGlobalDefinesToSource;
  end;
  Result := True;
end;

function TIdParser.LoadMemory(const AText: AnsiString; const AName: AnsiString): Boolean;
begin
  Result := LoadMemory(AText, System.Length(AText), AName);
end;

procedure TIdParser.FreeSource(const AKeepDefines: Boolean);
begin
  // free all the scripts, tokens and indents
  FScripts.Clear;
  FTokens.Clear;
  FIndents.Clear;
  if not AKeepDefines then
    FreeDefineTable;
  FLoaded := False;
end;

end.
