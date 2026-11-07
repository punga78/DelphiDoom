{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of EMikModException                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mikmod.Intf;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mikmod.Intf;

type
  [TestFixture]
  [Category('mikmod')]
  TTestMikModIntf = class(TObject)
  public
    [Test]
    [TestCase('ok', '0,OK')]
    [TestCase('non inizializzato', '-1,Not initialized')]
    [TestCase('gia inizializzato', '-2,Already initialized')]
    [TestCase('libreria', '-3,Cannot load the sound library')]
    [TestCase('dispositivo', '-4,Cannot initialize the audio device')]
    [TestCase('modulo', '-5,Cannot load the module')]
    [TestCase('argomento', '-6,Invalid argument')]
    [TestCase('occupato', '-7,Resource busy')]
    [TestCase('senza modulo', '-8,No module loaded')]
    [TestCase('file', '-9,File error')]
    [TestCase('interno', '-10,Internal error')]
    [TestCase('sconosciuto', '-77,Unknown error')]
    procedure DovrebbeDescrivereOgniCodice(ACode: Integer; const AText: string);
    [Test]
    procedure DovrebbeAggiungereIlDettaglioAlMessaggio;
  end;

implementation

{ TTestMikModIntf }

procedure TTestMikModIntf.DovrebbeDescrivereOgniCodice(ACode: Integer; const AText: string);
begin
  Assert.AreEqual(AText, EMikModException.TextOf(ACode));
end;

procedure TTestMikModIntf.DovrebbeAggiungereIlDettaglioAlMessaggio;
var
  LException: EMikModException;
begin
  LException := EMikModException.CreateCode(MIKMOD_ERR_IO, 'song.xm');
  try
    Assert.AreEqual(MIKMOD_ERR_IO, LException.Code);
    Assert.AreEqual('MikMod error -9: File error (song.xm)', LException.Message);
  finally
    LException.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMikModIntf);

end.
