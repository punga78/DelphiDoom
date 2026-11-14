{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - helpers on the text of a line     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.Text;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Scanner.Text, DelphiDoom.Scanner.Strings, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder;

type
  /// <summary>
  ///   helpers.golden.txt was made by the functions SC_* of sc_engine.pas on the lines of
  ///   helpers.in.txt
  /// </summary>
  [TestFixture]
  [Category('scanner')]
  TTestScannerText = class(TObject)
  private
    function DataPath(const AFileName: string): string;
    function Quote(const AText: string): string;
    function Flag(AValue: Boolean): string;
  public
    [Test]
    procedure TestSameDumpAsTheOldFunctions;
    [Test]
    procedure TestSplitLinesLikeAStringList;
    [Test]
    procedure TestTrim;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory;

{ TTestScannerText }

function TTestScannerText.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Scanner\' + AFileName));
end;

function TTestScannerText.Quote(const AText: string): string;
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

function TTestScannerText.Flag(AValue: Boolean): string;
begin
  if AValue then
    Result := '1'
  else
    Result := '0';
end;

procedure TTestScannerText.TestSameDumpAsTheOldFunctions;
var
  LRecorder: TLogRecorder;
  LSink: ILogSink;
  LLog: ILog;
  LInput: TStringList;
  LOut: TStringList;
  LExpected: TArray<string>;
  LGolden: string;
  LIndex: Integer;
  LLine: string;
  LParams: TArray<string>;
  LTokens: TArray<string>;
  LText: string;
  LItem: string;
begin
  LRecorder := TLogRecorder.Create;
  LSink := LRecorder;
  LLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(LSink), nil);
  LInput := TStringList.Create;
  LOut := TStringList.Create;
  try
    LInput.LoadFromFile(DataPath('helpers.in.txt'));
    for LIndex := 0 to LInput.Count - 1 do
    begin
      LLine := LInput[LIndex];
      LOut.Add('L|' + Quote(LLine));
      LOut.Add('RC|' + Quote(TScannerText.RemoveLineComments(LLine)));
      LOut.Add('FP|' + Quote(TScannerText.FixParenthesisLevel(LLine)));
      LOut.Add('IQ|' + Flag(TScannerText.IsStringInQuotes(LLine)));
      LParams := TScannerText.ParamsToList(LLine);
      LText := '';
      for LItem in LParams do
        LText := LText + LItem + #13#10;
      LOut.Add('PL|' + IntToStr(Length(LParams)) + '|' +
        Quote(TScannerStrings.Trim(LText).Replace(#13#10, '~')));
      LTokens := TScannerText.TokensToList(LLine, LLog);
      LOut.Add('TL|' + IntToStr(Length(LTokens)));
      for LItem in LTokens do
        LOut.Add('TK|' + Quote(LItem));
    end;
    LOut.Add('RQ|' + Quote(TScannerText.RemoveLineQuotes(LInput.Text)));
    if LRecorder.TextOf(TLogChannel.ErrorFile) <> '' then
      LOut.Add('W|Helpers|' + Quote(LRecorder.TextOf(TLogChannel.ErrorFile)));

    // the golden file has the line break of the checkout (git does not convert it, -text)
    LGolden := TFile.ReadAllText(DataPath('helpers.golden.txt'), TEncoding.ASCII);
    if Pos(#13#10, LGolden) > 0 then
      LExpected := LGolden.Split([#13#10], TStringSplitOptions.None)
    else
      LExpected := LGolden.Split([#10], TStringSplitOptions.None);
    if (Length(LExpected) > 0) and (LExpected[High(LExpected)] = '') then
      SetLength(LExpected, Length(LExpected) - 1);
    Assert.AreEqual<Integer>(Length(LExpected), LOut.Count, 'the number of lines');
    for LIndex := 0 to High(LExpected) do
      Assert.AreEqual(LExpected[LIndex], LOut[LIndex], 'line ' + IntToStr(LIndex + 1));
  finally
    LOut.Free;
    LInput.Free;
  end;
end;

procedure TTestScannerText.TestSplitLinesLikeAStringList;
var
  LLines: TArray<string>;
begin
  LLines := TScannerStrings.SplitLines('a'#13#10'b'#10'c'#13'd'#13#10);
  Assert.AreEqual(4, Integer(Length(LLines)));
  Assert.AreEqual('c', LLines[2]);
  LLines := TScannerStrings.SplitLines('x'#10#10'y');
  Assert.AreEqual(3, Integer(Length(LLines)));
  Assert.AreEqual('', LLines[1]);
  Assert.AreEqual(0, Integer(Length(TScannerStrings.SplitLines(''))));
end;

procedure TTestScannerText.TestTrim;
begin
  Assert.AreEqual('a b', TScannerStrings.Trim(#9'  a b '#13#10));
  Assert.AreEqual('', TScannerStrings.Trim('   '));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScannerText);

end.
