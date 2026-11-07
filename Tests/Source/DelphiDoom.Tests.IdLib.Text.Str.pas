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
    [Test]
    procedure IMetodiDiConfrontoDovrebberoDareIRisultatiDiIdStr;
    [Test]
    procedure DovrebbeCostruireInserireEFiltrareAgliEstremi;
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

// The expected values below are read in Str.h / Str.cpp: the methods of idStr call the static
// functions on their own text, the comparisons give -1, 0 or 1, the paths treat '/' and '\' alike

procedure TTestIdLibStr.IMetodiDiConfrontoDovrebberoDareIRisultatiDiIdStr;
var
  LText: TIdStr;
  LPlain: AnsiString;
begin
  LText := 'abcdef';
  Assert.AreEqual(0, LText.Cmp('abcdef'));
  Assert.AreEqual(-1, LText.Cmp('abd'));
  Assert.AreEqual(0, LText.Cmpn('abcxyz', 3));
  Assert.AreEqual(0, LText.Icmp('ABCDEF'));
  Assert.AreEqual(1, LText.Icmp('ABC'), 'the longer text is greater');
  Assert.AreEqual(0, LText.Icmpn('ABCxyz', 3));
  Assert.AreEqual(0, LText.IcmpPrefix('ABC'));
  Assert.AreEqual(0, LText.IcmpNoColor('ABCDEF'));
  LText := 'textures\base\wall';
  Assert.AreEqual(0, LText.IcmpPath('TEXTURES/BASE/WALL'));
  Assert.AreEqual(0, LText.IcmpnPath('TEXTURES/BASE/xxxx', 14));
  Assert.AreEqual(0, LText.IcmpPrefixPath('Textures/'));
  Assert.IsTrue(LText <> TIdStr.Create('textures'));
  Assert.IsFalse(LText <> TIdStr.Create('textures\base\wall'));
  LPlain := LText;
  Assert.AreEqual('textures\base\wall', string(LPlain));
  Assert.IsTrue(LText[1] = 'e');
  LText.Empty;
  Assert.AreEqual(0, LText.Length);
end;

procedure TTestIdLibStr.DovrebbeCostruireInserireEFiltrareAgliEstremi;
var
  LText: TIdStr;
begin
  Assert.AreEqual('', string(TIdStr.Create('abc', 5, 7).Text), 'a start past the end');
  Assert.AreEqual('0', string(TIdStr.FromBoolean(False).Text));
  LText := 'ab';
  LText.AppendBoolean(False);
  Assert.AreEqual('abfalse', string(LText.Text));
  LText := 'abc';
  LText.Insert(AnsiChar('x'), 10);
  Assert.AreEqual('abcx', string(LText.Text), 'an index past the end appends');
  LText.Insert(AnsiString('yz'), -3);
  Assert.AreEqual('yzabcx', string(LText.Text), 'a negative index inserts at the start');
  LText := 'abcdef';
  // the original reads before the buffer: the Delphi port drops the part before the start
  Assert.AreEqual('ab', string(LText.Mid(-2, 4).Text));
  Assert.AreEqual('', string(LText.Mid(-5, 3).Text));
  Assert.IsTrue(LText.Filter('a*f', True));
  Assert.IsFalse(LText.Filter('A*F', True));
  Assert.IsTrue(LText.Filter('A*F', False));
  LText := 'maps\e1m1.map';
  Assert.IsTrue(LText.CheckExtension('.map'));
  Assert.IsFalse(LText.CheckExtension('.wad'));
end;

end.
