{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the hash table of texts        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.StringHashTable;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>Parity with the old m_hash (golden file hash.golden.txt) and the cases by hand</summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreStringHashTable = class(TObject)
  public
    [Test]
    procedure DovrebbeSeguireLaSequenzaDelVecchioMHash;
    [Test]
    procedure DovrebbeDareZeroPerUnTestoMaiSalvato;
    [Test]
    procedure DovrebbeSostituireIlTestoConLoStessoHash;
    [Test]
    procedure DovrebbeCalcolareLoSdbmDiUnTestoNoto;
    [Test]
    procedure DovrebbeTenereTabelleSeparatePerOgniOggetto;
    [Test]
    procedure DovrebbeDistinguereLeMaiuscole;
  end;

implementation

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.MathCore.Factory, DelphiDoom.MathCore.StringHashTable,
  DelphiDoom.Tests.MathCore.Golden, DelphiDoom.Tests.MathCore.Fingerprint,
  DelphiDoom.Tests.MathCore.Samples;

{ TTestMathCoreStringHashTable }

procedure TTestMathCoreStringHashTable.DovrebbeSeguireLaSequenzaDelVecchioMHash;
var
  LGolden: TGoldenFile;
  LFingerprint: TFingerprint;
  LTable: IStringHashTable;
  LState: Cardinal;
  LTexts: TArray<string>;
  LIndex: Integer;
begin
  LGolden := TGoldenFile.Create('hash.golden.txt');
  LFingerprint := TFingerprint.Create;
  try
    LTable := TMathCoreFactory.CreateStringHashTable;
    LState := TMathCoreSamples.INITIAL_STATE;
    SetLength(LTexts, 3000);
    for LIndex := 0 to High(LTexts) do
      LTexts[LIndex] := TMathCoreSamples.NextText(LState, True);
    for LIndex := 0 to High(LTexts) do
      LTable.Update(LTexts[LIndex], LIndex + 1);
    for LIndex := 0 to High(LTexts) do
      LFingerprint.AddInteger(LTable.IndexOf(LTexts[LIndex]));
    for LIndex := 1 to 500 do
      LFingerprint.AddInteger(LTable.IndexOf(TMathCoreSamples.NextText(LState, True)));
    LGolden.Check('hash.sequence', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
    LGolden.Free;
  end;
end;

procedure TTestMathCoreStringHashTable.DovrebbeDareZeroPerUnTestoMaiSalvato;
var
  LTable: IStringHashTable;
begin
  LTable := TMathCoreFactory.CreateStringHashTable;
  Assert.AreEqual(0, LTable.IndexOf('MAP01'));
end;

procedure TTestMathCoreStringHashTable.DovrebbeSostituireIlTestoConLoStessoHash;
var
  LTable: IStringHashTable;
begin
  LTable := TMathCoreFactory.CreateStringHashTable;
  LTable.Update('MAP01', 5);
  LTable.Update('MAP01', 9);
  Assert.AreEqual(9, LTable.IndexOf('MAP01'));
end;

procedure TTestMathCoreStringHashTable.DovrebbeCalcolareLoSdbmDiUnTestoNoto;
begin
  // sdbm: hash = c + (hash shl 6) + (hash shl 16) - hash, that is c + hash * 65599
  Assert.AreEqual(Cardinal(97), TStringHashTable.Hash('a'));
  Assert.AreEqual(Cardinal((98 + 97 * 65599) and $FFFF), TStringHashTable.Hash('ab'));
  Assert.AreEqual(Cardinal(0), TStringHashTable.Hash(''));
end;

procedure TTestMathCoreStringHashTable.DovrebbeTenereTabelleSeparatePerOgniOggetto;
var
  LFirst, LSecond: IStringHashTable;
begin
  LFirst := TMathCoreFactory.CreateStringHashTable;
  LSecond := TMathCoreFactory.CreateStringHashTable;
  LFirst.Update('X', 3);
  Assert.AreEqual(0, LSecond.IndexOf('X'));
end;

procedure TTestMathCoreStringHashTable.DovrebbeDistinguereLeMaiuscole;
var
  LTable: IStringHashTable;
begin
  LTable := TMathCoreFactory.CreateStringHashTable;
  LTable.Update('A', 1);
  Assert.AreEqual(0, LTable.IndexOf('a'));
end;

end.
