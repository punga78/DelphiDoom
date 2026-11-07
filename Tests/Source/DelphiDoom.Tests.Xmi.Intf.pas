{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of EXmiException                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Intf;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Intf;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiIntf = class(TObject)
  public
    [Test]
    [TestCase('ok', '0,OK')]
    [TestCase('argomento', '-1,Invalid argument')]
    [TestCase('formato', '-2,Unsupported format')]
    [TestCase('dati', '-3,Corrupted data')]
    [TestCase('traccia', '-4,Track not found')]
    [TestCase('buffer', '-5,Buffer too small')]
    [TestCase('memoria', '-6,Insufficient memory')]
    [TestCase('interno', '-7,Internal error')]
    [TestCase('sconosciuto', '-99,Unknown error')]
    procedure DovrebbeDescrivereOgniCodice(ACode: Integer; const AText: string);
    [Test]
    procedure DovrebbeTenereIlCodiceNellEccezione;
  end;

implementation

{ TTestXmiIntf }

procedure TTestXmiIntf.DovrebbeDescrivereOgniCodice(ACode: Integer; const AText: string);
begin
  Assert.AreEqual(AText, EXmiException.TextOf(ACode));
end;

procedure TTestXmiIntf.DovrebbeTenereIlCodiceNellEccezione;
var
  LException: EXmiException;
begin
  LException := EXmiException.CreateCode(XMI_ERROR_TRACK);
  try
    Assert.AreEqual(XMI_ERROR_TRACK, LException.Code);
    Assert.AreEqual('XMI error -4: Track not found', LException.Message);
  finally
    LException.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiIntf);

end.
