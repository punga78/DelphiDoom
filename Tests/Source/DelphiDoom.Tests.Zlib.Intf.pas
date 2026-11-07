{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of EZlibException                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Intf;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf;

type
  [TestFixture]
  [Category('zlib')]
  TTestZlibIntf = class(TObject)
  public
    [Test]
    [TestCase('ok', '0,OK')]
    [TestCase('fine', '1,Stream end')]
    [TestCase('dizionario', '2,Need dictionary')]
    [TestCase('file', '-1,File error')]
    [TestCase('flusso', '-2,Stream error')]
    [TestCase('dati', '-3,Data error')]
    [TestCase('memoria', '-4,Insufficient memory')]
    [TestCase('buffer', '-5,Buffer error')]
    [TestCase('versione', '-6,Incompatible version')]
    [TestCase('sconosciuto', '-42,Unknown error')]
    procedure DovrebbeDescrivereOgniCodice(ACode: Integer; const AText: string);
    [Test]
    procedure DovrebbeTenereIlCodiceNellEccezione;
  end;

implementation

{ TTestZlibIntf }

procedure TTestZlibIntf.DovrebbeDescrivereOgniCodice(ACode: Integer; const AText: string);
begin
  Assert.AreEqual(AText, EZlibException.TextOf(ACode));
end;

procedure TTestZlibIntf.DovrebbeTenereIlCodiceNellEccezione;
var
  LException: EZlibException;
begin
  LException := EZlibException.CreateCode(ZLIB_DATA_ERROR);
  try
    Assert.AreEqual(ZLIB_DATA_ERROR, LException.Code);
    Assert.AreEqual('zlib error -3: Data error', LException.Message);
  finally
    LException.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZlibIntf);

end.
