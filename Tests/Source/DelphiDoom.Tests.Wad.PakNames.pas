{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TPakNames                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.PakNames;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('wad')]
  TTestWadPakNames = class(TObject)
  public
    [Test]
    procedure DovrebbeDareZeroPerUnNomeVuoto;
    [Test]
    procedure DovrebbeRuotareDiSetteESommareInMaiuscolo;
    [Test]
    procedure DovrebbeTogliereTrentaDueAncheSopraFFSeIlByteBassoEUnaMinuscola;
    [Test]
    [TestCase('Positivo', '8193,1')]
    [TestCase('Negativo', '-5,5')]
    [TestCase('Minimo', '-2147483648,0')]
    [TestCase('Zero', '0,0')]
    procedure DovrebbeDareLaCatenaDelHash(AHash, AExpected: Integer);
    [Test]
    procedure DovrebbeMettereInMaiuscoloSoloLeLettereAscii;
    [Test]
    [TestCase('ConCartelle', 'a/b\c.txt,c.txt')]
    [TestCase('SenzaCartelle', 'nome,nome')]
    [TestCase('SoloCartella', 'dir\,')]
    procedure DovrebbeDareIlNomeCorto(const APath, AExpected: string);
    [Test]
    procedure DovrebbeUnireLeBarreRipetute;
    [Test]
    procedure DovrebbeTagliareICaratteriDiControlloAiLati;
    [Test]
    procedure DovrebbeDividereLeRigheComeTDStrings;
    [Test]
    procedure DovrebbeFermarsiAlPrimoZero;
    [Test]
    procedure DovrebbeDareLeCartelleInMaiuscoloConLaBarraFinale;
    [Test]
    procedure DovrebbeSaltareLeCartelleVuote;
    [Test]
    procedure DovrebbeContareUnInvioDelTestoComeUnaRigaInPiu;
  end;

implementation

uses
  DelphiDoom.Wad.Pak.Names;

procedure AreLines(const AExpected: array of string; const AActual: TArray<string>);
var
  LIndex: Integer;
begin
  Assert.AreEqual(Length(AExpected), Length(AActual), 'number of lines');
  for LIndex := 0 to High(AExpected) do
    Assert.AreEqual(AExpected[LIndex], AActual[LIndex]);
end;

{ TTestWadPakNames }

procedure TTestWadPakNames.DovrebbeDareZeroPerUnNomeVuoto;
begin
  Assert.AreEqual(0, TPakNames.Hash(''));
end;

procedure TTestWadPakNames.DovrebbeRuotareDiSetteESommareInMaiuscolo;
begin
  Assert.AreEqual(65, TPakNames.Hash('a'));
  Assert.AreEqual((65 shl 7) + 66, TPakNames.Hash('aB'));
  Assert.AreEqual(TPakNames.Hash('FOO.PNG'), TPakNames.Hash('foo.png'));
end;

procedure TTestWadPakNames.DovrebbeTogliereTrentaDueAncheSopraFFSeIlByteBassoEUnaMinuscola;
begin
  // toupper of d_delphi looked at the low byte only: U+0161 became U+0141
  Assert.AreEqual($0141, TPakNames.Hash(#$0161));
  Assert.AreEqual($00E9, TPakNames.Hash(#$00E9));
end;

procedure TTestWadPakNames.DovrebbeDareLaCatenaDelHash(AHash, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TPakNames.HashTableIndex(AHash));
end;

procedure TTestWadPakNames.DovrebbeMettereInMaiuscoloSoloLeLettereAscii;
begin
  Assert.AreEqual('ABC'#$E0'_1', TPakNames.UpperCase('abc'#$E0'_1'));
end;

procedure TTestWadPakNames.DovrebbeDareIlNomeCorto(const APath, AExpected: string);
begin
  Assert.AreEqual(AExpected, TPakNames.ShortName(APath));
end;

procedure TTestWadPakNames.DovrebbeUnireLeBarreRipetute;
begin
  Assert.AreEqual('a\b\c\d', TPakNames.FixPath('a//b\\\c/d'));
  Assert.AreEqual('\x', TPakNames.FixPath('\\x'));
  Assert.AreEqual('', TPakNames.FixPath(''));
end;

procedure TTestWadPakNames.DovrebbeTagliareICaratteriDiControlloAiLati;
begin
  Assert.AreEqual('x y', TPakNames.Trim('  x y  '));
  Assert.AreEqual('x', TPakNames.Trim(#9'x'#1));
  Assert.AreEqual('', TPakNames.Trim('   '));
end;

procedure TTestWadPakNames.DovrebbeDividereLeRigheComeTDStrings;
begin
  AreLines(['a', 'b', 'c', 'd'], TPakNames.SplitLines('a'#13#10'b'#10'c'#13'd'));
  AreLines(['a', '', 'b'], TPakNames.SplitLines('a'#13#13'b'));
  AreLines(['a'], TPakNames.SplitLines('a'#13#10));
  AreLines([], TPakNames.SplitLines(''));
end;

procedure TTestWadPakNames.DovrebbeFermarsiAlPrimoZero;
begin
  AreLines(['x'], TPakNames.SplitLines('x'#0'y'));
end;

procedure TTestWadPakNames.DovrebbeDareLeCartelleInMaiuscoloConLaBarraFinale;
begin
  AreLines(['DOOM\', 'HERETIC\'], TPakNames.DirectoryList('doom heretic'));
  AreLines(['A\', 'B\'], TPakNames.DirectoryList('a\,b'));
end;

procedure TTestWadPakNames.DovrebbeSaltareLeCartelleVuote;
begin
  AreLines(['DATA\SUB\'], TPakNames.DirectoryList(' , ,data\SUB'));
  AreLines([], TPakNames.DirectoryList(''));
  AreLines([], TPakNames.DirectoryList(' ,, '));
end;

procedure TTestWadPakNames.DovrebbeContareUnInvioDelTestoComeUnaRigaInPiu;
begin
  // 'x', CR, then the separator CR LF: the old TDStringList saw an empty line between them
  AreLines(['X\', 'Y\'], TPakNames.DirectoryList('x'#13' y'));
  AreLines(['X\', 'Y\'], TPakNames.DirectoryList(#9'x'#9' y'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWadPakNames);

end.
