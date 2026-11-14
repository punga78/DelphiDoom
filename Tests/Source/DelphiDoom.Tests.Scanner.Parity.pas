{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - parity with the old script engine }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder, DelphiDoom.Scanner.Scanner;

type
  /// <summary>
  ///   The files *.golden.txt in Tests\Data\Scanner were made by the old TScriptEngine of
  ///   sc_engine.pas on the texts of the same folder: for each one the words with their line,
  ///   the levels and the flags, the reading of lines, of numbers and of booleans, the
  ///   aliases and the words to ignore, and the warnings. The scanner of the library has to
  ///   write the same dump
  /// </summary>
  [TestFixture]
  [Category('scanner')]
  TTestScannerParity = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    FOut: TStringList;
    function DataPath(const AFileName: string): string;
    function NewScanner(const AText: string): TScriptScanner;
    procedure Emit(const AText: string);
    procedure FlushWarnings(const ATag: string);
    function Quote(const AText: string): string;
    function Flag(AValue: Boolean): string;
    procedure ModeA(const AText: string);
    procedure ModeB(const AText: string);
    procedure ModeC(const AText: string);
    procedure ModeD(const AText: string);
    procedure ModeE(const AText: string);
    procedure ModeI(const AText: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('basic', 'basic')]
    [TestCase('booleans', 'booleans')]
    [TestCase('brackets', 'brackets')]
    [TestCase('comments', 'comments')]
    [TestCase('comment_at_end', 'comment_at_end')]
    [TestCase('controls', 'controls')]
    [TestCase('crlf', 'crlf')]
    [TestCase('empty', 'empty')]
    [TestCase('eol', 'eol')]
    [TestCase('high_chars', 'high_chars')]
    [TestCase('ignore_alias', 'ignore_alias')]
    [TestCase('long', 'long')]
    [TestCase('numbers', 'numbers')]
    [TestCase('quoted', 'quoted')]
    [TestCase('separators', 'separators')]
    [TestCase('slash', 'slash')]
    [TestCase('spaces_only', 'spaces_only')]
    [TestCase('unterminated', 'unterminated')]
    procedure TestSameDumpAsTheOldEngine(const ASample: string);
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory;

{ TTestScannerParity }

procedure TTestScannerParity.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
  FOut := TStringList.Create;
end;

procedure TTestScannerParity.TearDown;
begin
  FOut.Free;
  FSink := nil;
  FRecorder := nil;
end;

function TTestScannerParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Scanner\' + AFileName));
end;

function TTestScannerParity.NewScanner(const AText: string): TScriptScanner;
begin
  Result := TScriptScanner.Create(AText, TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil));
end;

procedure TTestScannerParity.Emit(const AText: string);
begin
  FOut.Add(AText);
end;

procedure TTestScannerParity.FlushWarnings(const ATag: string);
var
  LText: string;
begin
  LText := FRecorder.TextOf(TLogChannel.ErrorFile);
  if LText <> '' then
    Emit('W|' + ATag + '|' + Quote(LText));
  FRecorder.Clear;
end;

function TTestScannerParity.Quote(const AText: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in AText do
    if LChar = '\' then
      Result := Result + '\\'
    else if (Ord(LChar) < 32) or (Ord(LChar) > 126) then
      Result := Result + '\x' + IntToHex(Ord(LChar), 2)
    else
      Result := Result + LChar;
end;

function TTestScannerParity.Flag(AValue: Boolean): string;
begin
  if AValue then
    Result := '1'
  else
    Result := '0';
end;

procedure TTestScannerParity.ModeA(const AText: string);
var
  LScanner: TScriptScanner;
begin
  LScanner := NewScanner(AText);
  try
    while LScanner.GetString do
      Emit('S|' + Quote(LScanner.AsString) + '|' + Flag(LScanner.QuotedToken) + '|' +
        IntToStr(LScanner.Line) + '|' + Flag(LScanner.NewLine) + '|' +
        IntToStr(LScanner.BracketLevel) + '|' + IntToStr(LScanner.ParenthesisLevel));
    Emit('END|' + Flag(LScanner.Finished) + '|' + IntToStr(LScanner.Line) + '|' +
      IntToStr(LScanner.BracketLevel) + '|' + IntToStr(LScanner.ParenthesisLevel));
    FlushWarnings('A');
  finally
    LScanner.Free;
  end;
end;

procedure TTestScannerParity.ModeB(const AText: string);
var
  LScanner: TScriptScanner;
  LLine: string;
  LCount: Integer;
begin
  LScanner := NewScanner(AText);
  try
    LCount := 0;
    repeat
      LLine := LScanner.GetStringEOL;
      Emit('E|' + Quote(LLine) + '|' + IntToStr(LScanner.Line) + '|' + Flag(LScanner.Finished));
      Inc(LCount);
    until (LScanner.Finished and (LLine = '')) or (LCount > 300);
    FlushWarnings('B');
  finally
    LScanner.Free;
  end;
  LScanner := NewScanner(AText);
  try
    LCount := 0;
    repeat
      LLine := LScanner.GetStringEOLWithQuotes;
      Emit('Q|' + Quote(LLine) + '|' + IntToStr(LScanner.Line) + '|' + Flag(LScanner.Finished));
      Inc(LCount);
    until (LScanner.Finished and (LLine = '')) or (LCount > 300);
    FlushWarnings('B2');
  finally
    LScanner.Free;
  end;
end;

procedure TTestScannerParity.ModeC(const AText: string);
var
  LScanner: TScriptScanner;
  LTokens: TArray<string>;
  LCount: Integer;
  LText: string;
  LToken: string;
begin
  LScanner := NewScanner(AText);
  try
    LCount := 0;
    repeat
      LTokens := LScanner.GetTokensEOL;
      LText := '';
      for LToken in LTokens do
        LText := LText + '~' + LToken;
      Emit('T|' + IntToStr(Length(LTokens)) + '|' + Quote(LText) + '|' + IntToStr(LScanner.Line) +
        '|' + Flag(LScanner.Finished));
      Inc(LCount);
    until (LScanner.Finished and (Length(LTokens) = 0)) or (LCount > 300);
    FlushWarnings('C');
  finally
    LScanner.Free;
  end;
end;

procedure TTestScannerParity.ModeD(const AText: string);
var
  LScanner: TScriptScanner;
  LWords: TArray<string>;
begin
  LScanner := NewScanner(AText);
  LWords := TArray<string>.Create('BAZZ', 'QUX');
  try
    LScanner.AddIgnoreToken('ignoreme');
    LScanner.AddAlias('foo', 'bazz');
    while LScanner.GetString do
      Emit('D|' + Quote(LScanner.AsString) + '|' + Flag(LScanner.MatchString('bazz')) + '|' +
        Flag(LScanner.Compare('BAR')) + '|' + IntToStr(LScanner.MatchString(LWords)) + '|' +
        Flag(LScanner.MatchPosString('A')));
    FlushWarnings('D');
  finally
    LScanner.Free;
  end;
end;

procedure TTestScannerParity.ModeE(const AText: string);
var
  LScanner: TScriptScanner;
  LOk: Boolean;
  LCount: Integer;
  LFloat: Single;
begin
  LScanner := NewScanner(AText);
  try
    LCount := 0;
    repeat
      LOk := LScanner.GetInteger;
      if LOk then
        Emit('I|1|' + IntToStr(LScanner.AsInteger))
      else
        Emit('I|0|' + Flag(LScanner.Finished));
      Inc(LCount);
    until LScanner.Finished or (LCount > 300);
    FlushWarnings('E');
  finally
    LScanner.Free;
  end;
  LScanner := NewScanner(AText);
  try
    LCount := 0;
    repeat
      LOk := LScanner.GetFloat;
      if LOk then
      begin
        LFloat := LScanner.AsFloat;
        Emit('F|1|' + IntToHex(PInteger(@LFloat)^, 8));
      end
      else
        Emit('F|0|' + Flag(LScanner.Finished));
      Inc(LCount);
    until LScanner.Finished or (LCount > 300);
    FlushWarnings('F');
  finally
    LScanner.Free;
  end;
  LScanner := NewScanner(AText);
  try
    LCount := 0;
    repeat
      LOk := LScanner.GetBoolean;
      Emit('B|' + Flag(LOk) + '|' + Flag(LScanner.AsBoolean) + '|' + Flag(LScanner.Finished));
      Inc(LCount);
    until LScanner.Finished or (LCount > 300);
    FlushWarnings('G');
  finally
    LScanner.Free;
  end;
  LScanner := NewScanner(AText);
  try
    Emit('M|' + Flag(LScanner.MustGetString));
    Emit('M|' + Flag(LScanner.MustGetStringName('x')));
    Emit('M|' + Flag(LScanner.MustGetInteger));
    Emit('M|' + Flag(LScanner.MustGetFloat));
    Emit('M|' + Flag(LScanner.MustGetBoolean));
    LScanner.GetString;
    LScanner.UnGet;
    LOk := LScanner.GetString;
    Emit('U|' + Flag(LOk) + '|' + Quote(LScanner.AsString));
    LScanner.SetText('fresh text here');
    LOk := LScanner.GetString;
    Emit('R|' + Flag(LOk) + '|' + Quote(LScanner.AsString) + '|' + IntToStr(LScanner.Line));
    FlushWarnings('H');
  finally
    LScanner.Free;
  end;
end;

procedure TTestScannerParity.ModeI(const AText: string);
var
  LScanner: TScriptScanner;
begin
  LScanner := NewScanner(AText);
  try
    LScanner.GetString;
    Emit('X|' + Quote(LScanner.GetStringEOLUnchanged) + '|' + Flag(LScanner.Finished));
    Emit('X|' + Quote(LScanner.GetStringEOLUnchanged) + '|' + Flag(LScanner.Finished));
    FlushWarnings('I');
  finally
    LScanner.Free;
  end;
end;

procedure TTestScannerParity.TestSameDumpAsTheOldEngine(const ASample: string);
var
  LBytes: TBytes;
  LAnsi: AnsiString;
  LText: string;
  LExpected: TArray<string>;
  LGolden: string;
  LIndex: Integer;
begin
  LBytes := TFile.ReadAllBytes(DataPath(ASample + '.txt'));
  SetLength(LAnsi, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], LAnsi[1], Length(LBytes));
  LText := string(LAnsi);

  ModeA(LText);
  ModeB(LText);
  ModeC(LText);
  ModeD(LText);
  ModeE(LText);
  if (ASample = 'eol') or (ASample = 'basic') then
    ModeI(LText);

  // the golden files are text without conversion by git (-text): a checkout may have them with
  // CR LF or with LF only, so the line break is the one the file has
  LGolden := TFile.ReadAllText(DataPath(ASample + '.golden.txt'), TEncoding.ASCII);
  if Pos(#13#10, LGolden) > 0 then
    LExpected := LGolden.Split([#13#10], TStringSplitOptions.None)
  else
    LExpected := LGolden.Split([#10], TStringSplitOptions.None);
  if (Length(LExpected) > 0) and (LExpected[High(LExpected)] = '') then
    SetLength(LExpected, Length(LExpected) - 1);
  Assert.AreEqual<Integer>(Length(LExpected), FOut.Count, 'the number of lines of the dump of ' + ASample);
  for LIndex := 0 to High(LExpected) do
    Assert.AreEqual(LExpected[LIndex], FOut[LIndex], 'line ' + IntToStr(LIndex + 1) + ' of ' + ASample);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScannerParity);

end.
