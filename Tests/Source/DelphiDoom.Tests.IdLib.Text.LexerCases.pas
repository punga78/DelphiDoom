{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib text - the scenarios of lexer.golden.txt     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Text.LexerCases;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The same scenarios as the C++ harness that wrote lexer.golden.txt: the sections of
  ///   lexer.input.txt are read token by token, then driven by a pseudo random series of calls
  ///   of the whole API, then a few special cases (punctuation sets, files, errors)
  /// </summary>
  TIdLibLexerCases = class
  public
    class procedure Run(const AInputPath: string; const ALines: TStrings); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Tests.IdLib.Fakes;

type
  TSection = record
    Name: string;
    Flags: Integer;
    Text: AnsiString;
  end;

  TRunner = class
  private
    FLines: TStrings;
    FLog: TIdLibLogRecorder;
    FLogIntf: IIdLibLog;
    FFileSystem: TIdLibMemoryFileSystem;
    FFileSystemIntf: IIdLibFileSystem;
    FSections: TArray<TSection>;
    FRandom: Cardinal;
    function NextRandom: Integer;
    procedure Add(const ALine: string);
    procedure FlushLog;
    procedure RecordException(const AException: Exception);
    procedure LoadSections(const AInputPath: string);
    procedure PrintToken(var AToken: TIdToken; const ALexer: TIdLexer);
    procedure DumpTokens(const ASection: TSection; const AFlags: Integer);
    procedure ApiRun(const ASection: TSection; const AIndex: Integer);
    procedure Punctuations;
    procedure FilesAndErrors;
    function NewLexer(const AFlags: Integer): TIdLexer;
  public
    constructor Create(const ALines: TStrings);
    destructor Destroy; override;
    procedure Run(const AInputPath: string);
  end;

function Esc(const AText: AnsiString): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '"';
  for LIndex := 1 to Length(AText) do
  begin
    LByte := Byte(AText[LIndex]);
    if (LByte >= 32) and (LByte < 127) and (LByte <> Ord('\')) and (LByte <> Ord('"')) then
      Result := Result + Char(LByte)
    else
      Result := Result + '\x' + LowerCase(IntToHex(LByte, 2));
  end;
  Result := Result + '"';
end;

function B(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

function Hex8(const AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

function SingleBits(const AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

{ TRunner }

constructor TRunner.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
  FLog := TIdLibLogRecorder.Create;
  FLogIntf := FLog;
  FFileSystem := TIdLibMemoryFileSystem.Create;
  FFileSystemIntf := FFileSystem;
end;

destructor TRunner.Destroy;
begin
  FFileSystemIntf := nil;
  FLogIntf := nil;
  inherited Destroy;
end;

function TRunner.NewLexer(const AFlags: Integer): TIdLexer;
begin
  Result := TIdLexer.Create(AFlags, FLogIntf, FFileSystemIntf);
end;

procedure TRunner.Add(const ALine: string);
begin
  FLines.Add(ALine);
end;

procedure TRunner.FlushLog;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FLog.Entries.Count - 1 do
    Add('log ' + Esc(AnsiString(FLog.Entries[LIndex])));
  FLog.Entries.Clear;
end;

procedure TRunner.RecordException(const AException: Exception);
begin
  if AException is EIdLibFatalException then
    FLog.Add('F:' + AException.Message)
  else
    FLog.Add('E:' + AException.Message);
end;

function TRunner.NextRandom: Integer;
begin
  FRandom := FRandom * 1664525 + 1013904223;
  Result := Integer(FRandom shr 16);
end;

procedure TRunner.LoadSections(const AInputPath: string);
var
  LInput: TStringList;
  LLine: string;
  LIndex, LPosition: Integer;
  LSection: TSection;
  LParts: TArray<string>;
  LText: AnsiString;
  LCount: Integer;
begin
  LInput := TStringList.Create;
  try
    LInput.LoadFromFile(AInputPath, TEncoding.ANSI);
    LCount := 0;
    SetLength(FSections, 0);
    for LIndex := 0 to LInput.Count - 1 do
    begin
      LLine := LInput[LIndex];
      if Copy(LLine, 1, 2) = '@@' then
      begin
        LParts := Copy(LLine, 4, MaxInt).Split([' ']);
        LSection.Name := LParts[0];
        LSection.Flags := StrToInt(LParts[1]);
        LSection.Text := '';
        SetLength(FSections, LCount + 1);
        FSections[LCount] := LSection;
        Inc(LCount);
        Continue;
      end;
      if LCount = 0 then
        Continue;
      LText := '';
      LPosition := 1;
      while LPosition <= Length(LLine) do
      begin
        if (LLine[LPosition] = '%') and (LPosition < Length(LLine)) and (LLine[LPosition + 1] = 'x') then
        begin
          LText := LText + AnsiChar(Byte(StrToInt('$' + Copy(LLine, LPosition + 2, 2))));
          Inc(LPosition, 4);
        end
        else
        begin
          LText := LText + AnsiChar(Byte(Ord(LLine[LPosition])));
          Inc(LPosition);
        end;
      end;
      FSections[LCount - 1].Text := FSections[LCount - 1].Text + LText + #10;
    end;
  finally
    LInput.Free;
  end;
end;

procedure TRunner.PrintToken(var AToken: TIdToken; const ALexer: TIdLexer);
var
  LLine, LWhite: string;
  LInteger: Cardinal;
  LDouble: Double;
  LBits: UInt64;
begin
  if (ALexer.GetLastWhiteSpaceStart < 0) or (ALexer.GetLastWhiteSpaceEnd < 0) then
    LWhite := 'nil'
  else
    LWhite := Format('%d,%d', [ALexer.GetLastWhiteSpaceStart, ALexer.GetLastWhiteSpaceEnd]);
  LLine := Format('tok type=%d sub=%d line=%d lc=%d ws=%s fl=%d %s', [AToken.TokenType, AToken.SubType,
    AToken.Line, AToken.LinesCrossed, LWhite, AToken.Flags, Esc(AToken.Text)]);
  if AToken.TokenType = TT_NUMBER then
  begin
    LInteger := AToken.GetUnsignedLongValue;
    LDouble := AToken.GetDoubleValue;
    LBits := PUInt64(@LDouble)^;
    LLine := LLine + Format(' i=%u f=%s%s sub2=%d', [LInteger, Hex8(Cardinal(LBits shr 32)), Hex8(Cardinal(LBits)),
      AToken.SubType]);
  end;
  Add(LLine);
end;

procedure TRunner.DumpTokens(const ASection: TSection; const AFlags: Integer);
var
  LLexer: TIdLexer;
  LToken: TIdToken;
begin
  Add(Format('== tokens %s flags=%d', [ASection.Name, AFlags]));
  LLexer := NewLexer(AFlags);
  try
    LLexer.LoadMemory(ASection.Text, Length(ASection.Text), AnsiString(ASection.Name));
    LToken := TIdToken.Create;
    try
      while LLexer.ReadToken(LToken) do
        PrintToken(LToken, LLexer);
    except
      on E: EIdLibException do
      begin
        RecordException(E);
        Add('EXC');
      end;
    end;
    Add(Format('end line=%d eof=%d had=%d off=%d', [LLexer.LineNum, B(LLexer.EndOfFile), B(LLexer.HadError),
      LLexer.GetFileOffset]));
    FlushLog;
  finally
    LLexer.Free;
  end;
end;

procedure TRunner.ApiRun(const ASection: TSection; const AIndex: Integer);
const
  WORDS: array[0..7] of AnsiString = ('{', '}', '(', ')', '=', ';', 'a', 'x');
var
  LFlags, LStep, LOp, LWord, LRand, LIndex, LLength, LStartPos, LEndPos: Integer;
  LLexer: TIdLexer;
  LToken, LLast: TIdToken;
  LOutput, LWhite: AnsiString;
  LOk: Boolean;
  LErrorFlag: Boolean;
  LValue: Single;
  LMatrix: array[0..7] of Single;
  LLine: string;
begin
  LFlags := ASection.Flags or LEXFL_NOFATALERRORS;
  Add(Format('== api %s flags=%d', [ASection.Name, LFlags]));
  FRandom := Cardinal(AIndex * 7919 + 1);
  LLexer := NewLexer(LFlags);
  try
    LLexer.LoadMemory(ASection.Text, Length(ASection.Text), AnsiString(ASection.Name));
    LToken := TIdToken.Create;
    LLast := TIdToken.Create;
    for LStep := 0 to 59 do
    begin
      LOp := NextRandom mod 22;
      LWord := NextRandom mod 8;
      LRand := NextRandom;
      LLine := Format('op %d:', [LOp]);
      try
        case LOp of
          0:
            begin
              LOk := LLexer.ReadToken(LToken);
              Add(LLine + Format(' ReadToken=%d', [B(LOk)]));
              if LOk then
              begin
                PrintToken(LToken, LLexer);
                LLast := LToken;
              end;
            end;
          1: Add(LLine + Format(' CheckTokenString=%d', [B(LLexer.CheckTokenString(WORDS[LWord]))]));
          2: Add(LLine + Format(' PeekTokenString=%d', [B(LLexer.PeekTokenString(WORDS[LWord]))]));
          3:
            begin
              LOk := LLexer.ReadTokenOnLine(LToken);
              Add(LLine + Format(' ReadTokenOnLine=%d', [B(LOk)]));
              if LOk then
              begin
                PrintToken(LToken, LLexer);
                LLast := LToken;
              end;
            end;
          4: Add(LLine + Format(' SkipRestOfLine=%d', [B(LLexer.SkipRestOfLine)]));
          5: Add(LLine + Format(' ParseInt=%d', [LLexer.ParseInt]));
          6:
            begin
              LErrorFlag := False;
              if (LRand and 1) <> 0 then
                LValue := LLexer.ParseFloat(@LErrorFlag)
              else
                LValue := LLexer.ParseFloat;
              Add(LLine + Format(' ParseFloat=%s ef=%d', [Hex8(SingleBits(LValue)), B(LErrorFlag)]));
            end;
          7:
            begin
              LOutput := '';
              LLexer.ParseRestOfLine(LOutput);
              Add(LLine + ' ParseRestOfLine=' + Esc(LOutput));
            end;
          8:
            begin
              LLexer.UnreadToken(LLast);
              Add(LLine + ' UnreadToken');
            end;
          9:
            begin
              LOutput := '';
              LLexer.ParseBracedSection(LOutput);
              Add(LLine + ' ParseBracedSection=' + Esc(LOutput));
            end;
          10: Add(LLine + Format(' SkipBracedSection=%d', [B(LLexer.SkipBracedSection((LRand and 1) <> 0))]));
          11:
            begin
              LOk := LLexer.ExpectTokenType(TT_NAME, 0, LToken);
              Add(LLine + Format(' ExpectName=%d', [B(LOk)]));
              if LOk then
              begin
                PrintToken(LToken, LLexer);
                LLast := LToken;
              end;
            end;
          12:
            begin
              LOk := LLexer.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken);
              Add(LLine + Format(' ExpectInt=%d', [B(LOk)]));
              if LOk then
              begin
                PrintToken(LToken, LLexer);
                LLast := LToken;
              end;
            end;
          13: Add(LLine + Format(' ExpectTokenString=%d', [B(LLexer.ExpectTokenString(WORDS[LWord]))]));
          14:
            begin
              LOutput := 'pre ';
              LLexer.ReadRestOfLine(LOutput);
              Add(LLine + ' ReadRestOfLine=' + Esc(LOutput));
            end;
          15:
            begin
              LStartPos := LLexer.GetLastWhiteSpaceStart;
              LEndPos := LLexer.GetLastWhiteSpaceEnd;
              if (LStartPos < 0) or (LEndPos < LStartPos) or (LEndPos > Length(ASection.Text)) then
                Add(LLine + ' WhiteSpace skipped')
              else
              begin
                LLength := LLexer.GetLastWhiteSpace(LWhite);
                Add(LLine + Format(' WhiteSpace=%d,%d,%d %s', [LLength, LLexer.GetLastWhiteSpaceStart,
                  LLexer.GetLastWhiteSpaceEnd, Esc(LWhite)]));
              end;
            end;
          16: Add(LLine + Format(' ParseBool=%d', [B(LLexer.ParseBool)]));
          17:
            begin
              LOutput := '';
              LLexer.ParseBracedSectionExact(LOutput, (LRand mod 3) - 1);
              Add(LLine + ' ParseBracedSectionExact=' + Esc(LOutput));
            end;
          18: Add(LLine + Format(' SkipUntilString=%d', [B(LLexer.SkipUntilString(WORDS[LWord]))]));
          19:
            begin
              LOk := LLexer.ExpectAnyToken(LToken);
              Add(LLine + Format(' ExpectAny=%d', [B(LOk)]));
              if LOk then
              begin
                PrintToken(LToken, LLexer);
                LLast := LToken;
              end;
            end;
          20:
            if (LRand mod 5) = 0 then
            begin
              LLexer.Reset;
              Add(LLine + ' Reset');
            end
            else
              Add(LLine + ' nop');
          21:
            begin
              FillChar(LMatrix, SizeOf(LMatrix), 0);
              LOk := LLexer.Parse2DMatrix(2, 2, LMatrix);
              LLine := LLine + Format(' Parse2DMatrix=%d', [B(LOk)]);
              for LIndex := 0 to 3 do
                LLine := LLine + ' ' + Hex8(SingleBits(LMatrix[LIndex]));
              Add(LLine);
            end;
        end;
      except
        on E: EIdLibException do
        begin
          RecordException(E);
          Add(LLine + ' EXC');
        end;
      end;
      Add(Format('  state line=%d off=%d eof=%d had=%d', [LLexer.LineNum, LLexer.GetFileOffset, B(LLexer.EndOfFile),
        B(LLexer.HadError)]));
      FlushLog;
    end;
  finally
    LLexer.Free;
  end;
end;

procedure TRunner.Punctuations;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
  LId: Integer;
  LCustom: TIdPunctuationList;
  LTexts: array[0..10] of AnsiString;
  LIndex: Integer;

  procedure SetPunctuation(const AIndex: Integer; const AText: AnsiString; const AId: Integer);
  begin
    LCustom[AIndex].Text := AText;
    LCustom[AIndex].Id := AId;
  end;

begin
  Add('== punct');
  LLexer := NewLexer(0);
  try
    for LId := 0 to 53 do
      Add(Format('pid %d %s', [LId, Esc(LLexer.GetPunctuationFromId(LId))]));
    LTexts[0] := '>>='; LTexts[1] := '<<='; LTexts[2] := '...'; LTexts[3] := '##'; LTexts[4] := '&&';
    LTexts[5] := ';'; LTexts[6] := '{'; LTexts[7] := 'nope'; LTexts[8] := ''; LTexts[9] := '$'; LTexts[10] := '\';
    for LIndex := 0 to 10 do
      Add(Format('pstr %d %d', [LIndex, LLexer.GetPunctuationId(LTexts[LIndex])]));
    SetLength(LCustom, 8);
    SetPunctuation(0, '=', 1);
    SetPunctuation(1, '==', 2);
    SetPunctuation(2, '===', 3);
    SetPunctuation(3, '=>', 4);
    SetPunctuation(4, 'a', 5);
    SetPunctuation(5, 'ab', 6);
    SetPunctuation(6, '<', 7);
    SetPunctuation(7, '<<', 8);
    LLexer.SetPunctuations(LCustom);
    LLexer.LoadMemory('= == === ==== => a ab abc < << <<< <= x', 'custom');
    LToken := TIdToken.Create;
    try
      while LLexer.ReadToken(LToken) do
        PrintToken(LToken, LLexer);
    except
      on E: EIdLibException do
      begin
        RecordException(E);
        Add('EXC');
      end;
    end;
    FlushLog;
  finally
    LLexer.Free;
  end;
end;

procedure TRunner.FilesAndErrors;
var
  LLexer, LLexer2: TIdLexer;
  LToken: TIdToken;
begin
  Add('== files');
  FFileSystem.SetFile('base/test.txt', Copy(AnsiString('hello "world" 42'#10'line2'), 1, 21));
  LToken := TIdToken.Create;
  LLexer := NewLexer(0);
  try
    LLexer.LoadFile('base/test.txt', False);
    Add(Format('loaded=%d name=%s', [B(LLexer.IsLoaded), Esc(LLexer.FileName)]));
    while LLexer.ReadToken(LToken) do
      PrintToken(LToken, LLexer);
  finally
    LLexer.Free;
  end;
  LLexer := NewLexer(0);
  try
    LLexer.LoadFile('base/missing.txt', False);
    Add(Format('missing loaded=%d', [B(LLexer.IsLoaded)]));
  finally
    LLexer.Free;
  end;
  LLexer := NewLexer(0);
  LLexer2 := NewLexer(0);
  try
    LLexer.BaseFolder := 'base';
    LLexer.LoadFile('test.txt', False);
    Add(Format('base loaded=%d', [B(LLexer.IsLoaded)]));
    LLexer2.BaseFolder := 'base';
    LLexer2.LoadFile('base/test.txt', True);
    Add(Format('os loaded=%d', [B(LLexer2.IsLoaded)]));
  finally
    LLexer2.Free;
    LLexer.Free;
  end;
  // errors that raise
  LLexer := NewLexer(0);
  try
    try
      LLexer.ReadToken(LToken);
    except
      on E: EIdLibException do
      begin
        RecordException(E);
        Add('EXC not loaded');
      end;
    end;
    LLexer.LoadMemory('a b', 'm');
    try
      LLexer.LoadMemory('a b', 'm');
    except
      on E: EIdLibException do
      begin
        RecordException(E);
        Add('EXC loaded twice');
      end;
    end;
    try
      LLexer.ExpectTokenString('x');
    except
      on E: EIdLibException do
      begin
        RecordException(E);
        Add('EXC expect');
      end;
    end;
    Add(Format('had=%d', [B(LLexer.HadError)]));
    FlushLog;
  finally
    LLexer.Free;
  end;
  LLexer := NewLexer(LEXFL_NOERRORS);
  try
    LLexer.LoadMemory('a b', 'm');
    Add(Format('noerrors expect=%d had=%d', [B(LLexer.ExpectTokenString('x')), B(LLexer.HadError)]));
    FlushLog;
  finally
    LLexer.Free;
  end;
  LLexer := NewLexer(LEXFL_NOWARNINGS);
  try
    LLexer.LoadMemory('''ab''', 'm');
    LLexer.ReadToken(LToken);
    PrintToken(LToken, LLexer);
    FlushLog;
  finally
    LLexer.Free;
  end;
  LLexer := NewLexer(LEXFL_ALLOWMULTICHARLITERALS);
  try
    LLexer.LoadMemory('''ab'' ''c''', 'm');
    while LLexer.ReadToken(LToken) do
      PrintToken(LToken, LLexer);
    FlushLog;
  finally
    LLexer.Free;
  end;
  LLexer := NewLexer(0);
  try
    LLexer.LoadMemory('a'#10'b'#10'c', 5, 'm', 10);
    while LLexer.ReadToken(LToken) do
      PrintToken(LToken, LLexer);
    Add(Format('line=%d', [LLexer.LineNum]));
    LLexer.Reset;
    Add(Format('after reset line=%d eof=%d', [LLexer.LineNum, B(LLexer.EndOfFile)]));
  finally
    LLexer.Free;
  end;
end;

procedure TRunner.Run(const AInputPath: string);
var
  LIndex: Integer;
begin
  LoadSections(AInputPath);
  for LIndex := 0 to High(FSections) do
  begin
    DumpTokens(FSections[LIndex], FSections[LIndex].Flags);
    if FSections[LIndex].Flags = 0 then
      DumpTokens(FSections[LIndex], LEXFL_ALLOWPATHNAMES or LEXFL_ALLOWNUMBERNAMES or LEXFL_NOFATALERRORS);
  end;
  for LIndex := 0 to High(FSections) do
    ApiRun(FSections[LIndex], LIndex);
  Punctuations;
  FilesAndErrors;
end;

{ TIdLibLexerCases }

class procedure TIdLibLexerCases.Run(const AInputPath: string; const ALines: TStrings);
var
  LRunner: TRunner;
begin
  LRunner := TRunner.Create(ALines);
  try
    LRunner.Run(AInputPath);
  finally
    LRunner.Free;
  end;
end;

end.
