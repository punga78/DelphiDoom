{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - the evaluator of the expressions  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.Expression;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder, DelphiDoom.Scanner.Expression.Intf;

type
  TFakeVariables = class(TInterfacedObject, IExpressionVariables)
  public
    function Contains(const AName: string): Boolean;
    function ValueOf(const AName: string): string;
  end;

  /// <summary>
  ///   expressions.golden.txt was made by the old TEvaluator of sc_evaluate.pas on the
  ///   lines of expressions.in.txt (with three variables and the functions DOUBLE and JOIN):
  ///   the results, the warnings, and the lines that raised an exception
  /// </summary>
  [TestFixture]
  [Category('scanner')]
  TTestScannerExpression = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    function DataPath(const AFileName: string): string;
    function Quote(const AText: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSameResultsAsTheOldEvaluator;
    [Test]
    procedure TestFunctionNameHasToBeAnIdentifier;
    [Test]
    procedure TestFunctionNameCannotBeUsedTwice;
    [Test]
    procedure TestVariableValueIsEvaluated;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.Scanner.Expression.Evaluator,
  DelphiDoom.Scanner.Numbers;

{ TFakeVariables }

function TFakeVariables.Contains(const AName: string): Boolean;
begin
  Result := (AName = 'SPEED') or (AName = 'HALF') or (AName = 'NAME');
end;

function TFakeVariables.ValueOf(const AName: string): string;
begin
  if AName = 'SPEED' then
    Result := '8'
  else if AName = 'HALF' then
    Result := '0.5'
  else
    Result := '"zombie"';
end;

{ TTestScannerExpression }

procedure TTestScannerExpression.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
end;

procedure TTestScannerExpression.TearDown;
begin
  FSink := nil;
  FRecorder := nil;
end;

function TTestScannerExpression.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Scanner\Expression\' + AFileName));
end;

function TTestScannerExpression.Quote(const AText: string): string;
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

procedure TTestScannerExpression.TestSameResultsAsTheOldEvaluator;
var
  LEvaluator: TExpressionEvaluator;
  LLines: TStringList;
  LOut: TStringList;
  LExpected: TArray<string>;
  LIndex: Integer;
  LResult: string;
  LWarnings: string;
begin
  LLines := TStringList.Create;
  LOut := TStringList.Create;
  LEvaluator := TExpressionEvaluator.Create(TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil),
    TFakeVariables.Create);
  try
    LEvaluator.AddFunction('DOUBLE',
      function(const AParams: TArray<string>): string
      begin
        Result := TScannerNumbers.FloatToText(TScannerNumbers.ToFloat(AParams[0]) * 2);
      end, 1);
    LEvaluator.AddFunction('JOIN',
      function(const AParams: TArray<string>): string
      var
        LParam: string;
      begin
        Result := '';
        for LParam in AParams do
          Result := Result + '[' + LParam + ']';
      end, -1);
    LLines.LoadFromFile(DataPath('expressions.in.txt'));
    for LIndex := 0 to LLines.Count - 1 do
    begin
      FRecorder.Clear;
      try
        LResult := LEvaluator.Evaluate(LLines[LIndex]);
        LOut.Add('X|' + Quote(LLines[LIndex]) + '|' + Quote(LResult));
      except
        LOut.Add('X|' + Quote(LLines[LIndex]) + '|EXCEPTION');
      end;
      LWarnings := FRecorder.TextOf(TLogChannel.ErrorFile);
      if LWarnings <> '' then
        LOut.Add('W|' + Quote(LWarnings));
    end;
    try
      LEvaluator.AddFunction('DOUBLE', nil, 1);
      LOut.Add('A|ok');
    except
      LOut.Add('A|exception');
    end;
    try
      LEvaluator.AddFunction('1BAD', nil, 1);
      LOut.Add('A|ok');
    except
      LOut.Add('A|exception');
    end;

    LExpected := TFile.ReadAllText(DataPath('expressions.golden.txt'), TEncoding.ASCII)
      .Split([#13#10], TStringSplitOptions.None);
    if (Length(LExpected) > 0) and (LExpected[High(LExpected)] = '') then
      SetLength(LExpected, Length(LExpected) - 1);
    Assert.AreEqual<Integer>(Length(LExpected), LOut.Count, 'the number of lines');
    for LIndex := 0 to High(LExpected) do
      Assert.AreEqual(LExpected[LIndex], LOut[LIndex], 'line ' + IntToStr(LIndex + 1));
  finally
    LEvaluator.Free;
    LOut.Free;
    LLines.Free;
  end;
end;

procedure TTestScannerExpression.TestFunctionNameHasToBeAnIdentifier;
var
  LEvaluator: TExpressionEvaluator;
begin
  LEvaluator := TExpressionEvaluator.Create(nil, nil);
  try
    Assert.WillRaise(
      procedure
      begin
        LEvaluator.AddFunction('1BAD', nil, 1);
      end, EExpressionException);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestScannerExpression.TestFunctionNameCannotBeUsedTwice;
var
  LEvaluator: TExpressionEvaluator;
begin
  LEvaluator := TExpressionEvaluator.Create(nil, nil);
  try
    Assert.WillRaise(
      procedure
      begin
        LEvaluator.AddFunction('abs', nil, 1);
      end, EExpressionException);
  finally
    LEvaluator.Free;
  end;
end;

procedure TTestScannerExpression.TestVariableValueIsEvaluated;
var
  LEvaluator: TExpressionEvaluator;
begin
  LEvaluator := TExpressionEvaluator.Create(nil, TFakeVariables.Create);
  try
    Assert.AreEqual('16', LEvaluator.Evaluate('speed * 2'));
    Assert.AreEqual('TRUE', LEvaluator.Evaluate('speed > half'));
  finally
    LEvaluator.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScannerExpression);

end.
