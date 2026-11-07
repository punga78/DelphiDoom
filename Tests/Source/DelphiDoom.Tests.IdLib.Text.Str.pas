{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib text - TIdStr and TIdStrings                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Text.Str;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>Parity of TIdStr / TIdStrings with idStr of the C++ idLib (str.golden.txt) and hand checks</summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibStr = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeStesseRispostePerIlCppSuTuttiGliScenari;
    [Test]
    procedure DovrebbeConfrontareICaratteriAltiComeByteConSegno;
    [Test]
    procedure DovrebbeCopiarePerValore;
    [Test]
    procedure DovrebbeSegnalareUnIndiceOltreLaFine;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Text.Str,
  DelphiDoom.Tests.IdLib.Golden, DelphiDoom.Tests.IdLib.Text.StrCases;

procedure TTestIdLibStr.DovrebbeDareLeStesseRispostePerIlCppSuTuttiGliScenari;
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('str.golden.txt');
  LActual := TStringList.Create;
  try
    try
      TIdLibStrCases.Run(LActual);
    finally
      // next to the executable, for a diff with the golden file when a test fails
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.str.actual.txt'));
    end;
    LGolden.Compare(LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestIdLibStr.DovrebbeConfrontareICaratteriAltiComeByteConSegno;
begin
  // the char of the original compiler is signed: 0xE9 is below 'a'
  Assert.AreEqual(-1, TIdStrings.Cmp(AnsiChar($E9), 'a'));
  Assert.AreEqual(1, TIdStrings.Cmp('a', AnsiChar($E9)));
end;

procedure TTestIdLibStr.DovrebbeCopiarePerValore;
var
  LFirst, LSecond: TIdStr;
begin
  LFirst := 'abc';
  LSecond := LFirst;
  LSecond.Append('d');
  Assert.AreEqual('abc', string(LFirst.Text));
  Assert.AreEqual('abcd', string(LSecond.Text));
end;

procedure TTestIdLibStr.DovrebbeSegnalareUnIndiceOltreLaFine;
var
  LText: TIdStr;
  LChar: AnsiChar;
  LRaised: Boolean;
begin
  LChar := #0;
  LText := 'abc';
  Assert.IsTrue(LText[3] = #0);
  LRaised := False;
  try
    LChar := LText[4];
  except
    on ERangeError do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  Assert.IsTrue(LChar = #0);
end;

end.
