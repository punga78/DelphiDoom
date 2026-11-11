{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib text - TIdLexer and TIdToken                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Text.Lexer;

interface

uses
  System.Math, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of TIdLexer / TIdToken with idLexer / idToken of the C++ idLib (lexer.golden.txt:
  ///   token dumps of 30 texts, 60 random API calls on each of them, punctuation sets, files and
  ///   errors) and checks of the values of the numbers
  /// </summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibLexer = class(TObject)
  public
    /// <summary>
    ///   The C++ goldens were made with SSE2 doubles (53 bits). The x87 of a Win32 Delphi program
    ///   keeps 64 bits in the intermediate results and differs in the last bit of some numbers
    ///   (the lexer builds 0.000001 with a series of multiplications and sums): the tests run
    ///   with the precision of the x87 set to double
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRispostePerIlCppSuTuttiGliScenari;
    [Test]
    procedure DovrebbeCalcolareIValoriDeiNumeri;
    [Test]
    procedure DovrebbeSegnalareUnErroreFatale;
    [Test]
    procedure DovrebbeRestituireIlTokenRimessoConUnreadToken;
    [Test]
    procedure IlTokenDovrebbeDireSeHaSpazioDavantiEDimenticarlo;
    [Test]
    procedure IlTokenDovrebbeDareInfinitoIndefinitoENanDaiFlag;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Tests.IdLib.Golden,
  DelphiDoom.Tests.IdLib.Text.LexerCases;

procedure TTestIdLibLexer.DovrebbeDareLeStesseRispostePerIlCppSuTuttiGliScenari;
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('lexer.golden.txt');
  LActual := TStringList.Create;
  try
    try
      TIdLibLexerCases.Run(TIdLibGolden.DataPath('lexer.input.txt'), LActual);
    finally
      // next to the executable, for a diff with the golden file when a test fails
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.lexer.actual.txt'));
    end;
    LGolden.Compare(LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestIdLibLexer.DovrebbeCalcolareIValoriDeiNumeri;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  LLexer := TIdLexer.Create;
  try
    LLexer.LoadMemory('0x1F 077 0b101 123 1.5 2e3 -7', 'numbers');
    LLexer.ReadToken(LToken);
    Assert.AreEqual(31, LToken.GetIntValue);
    LLexer.ReadToken(LToken);
    Assert.AreEqual(63, LToken.GetIntValue);
    LLexer.ReadToken(LToken);
    Assert.AreEqual(5, LToken.GetIntValue);
    LLexer.ReadToken(LToken);
    Assert.AreEqual(123, LToken.GetIntValue);
    LLexer.ReadToken(LToken);
    Assert.AreEqual(1.5, LToken.GetDoubleValue, 0.0);
    LLexer.ReadToken(LToken);
    Assert.AreEqual(2000.0, LToken.GetDoubleValue, 0.0);
    Assert.AreEqual(-7, LLexer.ParseInt);
  finally
    LLexer.Free;
  end;
end;

procedure TTestIdLibLexer.DovrebbeSegnalareUnErroreFatale;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
  LMessage: string;
begin
  LToken := TIdToken.Create;
  LLexer := TIdLexer.Create;
  try
    LLexer.LoadMemory('a @ b', 'file.txt');
    LLexer.ReadToken(LToken);
    LMessage := '';
    try
      LLexer.ReadToken(LToken);
    except
      on E: EIdLexerException do
        LMessage := E.Message;
    end;
    Assert.AreEqual('file file.txt, line 1: unknown punctuation @', LMessage);
  finally
    LLexer.Free;
  end;
end;

procedure TTestIdLibLexer.DovrebbeRestituireIlTokenRimessoConUnreadToken;
var
  LLexer: TIdLexer;
  LToken, LAgain: TIdToken;
begin
  LToken := TIdToken.Create;
  LAgain := TIdToken.Create;
  LLexer := TIdLexer.Create;
  try
    LLexer.LoadMemory('alpha beta', 'unread');
    LLexer.ReadToken(LToken);
    LLexer.UnreadToken(LToken);
    LLexer.ReadToken(LAgain);
    Assert.AreEqual('alpha', string(LAgain.Text));
    LLexer.ReadToken(LAgain);
    Assert.AreEqual('beta', string(LAgain.Text));
  finally
    LLexer.Free;
  end;
end;

procedure TTestIdLibLexer.IlTokenDovrebbeDireSeHaSpazioDavantiEDimenticarlo;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
begin
  // idToken::WhiteSpaceBeforeToken is whiteSpaceEnd_p > whiteSpaceStart_p; ClearTokenWhiteSpace
  // clears both pointers and linesCrossed
  LToken := TIdToken.Create;
  LLexer := TIdLexer.Create;
  try
    LLexer.LoadMemory('alpha'#10#10'   beta', 'white');
    LLexer.ReadToken(LToken);
    Assert.IsFalse(LToken.WhiteSpaceBeforeToken, 'nothing before the first token');
    LLexer.ReadToken(LToken);
    Assert.IsTrue(LToken.WhiteSpaceBeforeToken);
    Assert.AreEqual(2, LToken.LinesCrossed);
    LToken.ClearTokenWhiteSpace;
    Assert.IsFalse(LToken.WhiteSpaceBeforeToken);
    Assert.AreEqual(-1, LToken.WhiteSpaceStart);
    Assert.AreEqual(-1, LToken.WhiteSpaceEnd);
    Assert.AreEqual(0, LToken.LinesCrossed);
  finally
    LLexer.Free;
  end;
end;

procedure TTestIdLibLexer.IlTokenDovrebbeDareInfinitoIndefinitoENanDaiFlag;

  function BitsOf(const ASubType: Integer): UInt64;
  var
    LToken: TIdToken;
    LValue: Double;
  begin
    LToken := TIdToken.Create;
    LToken.TokenType := TT_NUMBER;
    LToken.SubType := TT_FLOAT or ASubType;
    LValue := LToken.GetDoubleValue;
    Result := PUInt64(@LValue)^;
  end;

begin
  // idToken::NumberValue: the floats 0x7f800000, 0xffc00000 and 0x7fc00000 widened to double (the
  // lexer never sets these flags, see Libs\IdLib\README.md; a caller of the token can)
  Assert.IsTrue(BitsOf(TT_INFINITE) = UInt64($7FF0000000000000));
  Assert.IsTrue(BitsOf(TT_INDEFINITE) = UInt64($FFF8000000000000));
  Assert.IsTrue(BitsOf(TT_NAN) = UInt64($7FF8000000000000));
  Assert.IsTrue(BitsOf(TT_INFINITE or TT_NAN) = UInt64($7FF0000000000000), 'infinite wins');
end;

end.
