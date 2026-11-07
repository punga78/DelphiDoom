{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of ESndfileException                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sndfile.Exception;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Sndfile.Intf;

type
  [TestFixture]
  [Category('sndfile')]
  TTestSndfileException = class(TObject)
  public
    [Test]
    [TestCase('ok', '0,OK')]
    [TestCase('formato', '1,Unrecognised format')]
    [TestCase('sistema', '2,System error')]
    [TestCase('malformato', '3,Malformed file')]
    [TestCase('codifica', '4,Unsupported encoding')]
    [TestCase('argomento', '-1,Invalid argument')]
    [TestCase('memoria', '-2,Insufficient memory')]
    [TestCase('inatteso', '-3,Unexpected error')]
    [TestCase('interno', '30,Internal libsndfile error')]
    [TestCase('sconosciuto', '-4,Unknown error')]
    procedure DovrebbeDareIlTestoDelCodice(ACode: Integer; const AText: string);
    [Test]
    procedure DovrebbeTenereCodiceEMessaggio;
    [Test]
    procedure DovrebbeAggiungereIlDettaglioAlMessaggio;
  end;

implementation

{ TTestSndfileException }

procedure TTestSndfileException.DovrebbeDareIlTestoDelCodice(ACode: Integer;
  const AText: string);
begin
  Assert.AreEqual(AText, ESndfileException.TextOf(ACode));
end;

procedure TTestSndfileException.DovrebbeTenereCodiceEMessaggio;
var
  LException: ESndfileException;
begin
  LException := ESndfileException.CreateCode(SNDFILE_ERR_MALFORMED_FILE);
  try
    Assert.AreEqual(SNDFILE_ERR_MALFORMED_FILE, LException.Code);
    Assert.AreEqual('libsndfile error 3: Malformed file', LException.Message);
  finally
    LException.Free;
  end;
end;

procedure TTestSndfileException.DovrebbeAggiungereIlDettaglioAlMessaggio;
var
  LException: ESndfileException;
begin
  LException := ESndfileException.CreateCodeDetail(SNDFILE_ERR_SYSTEM, 'disk');
  try
    Assert.AreEqual(SNDFILE_ERR_SYSTEM, LException.Code);
    Assert.AreEqual('libsndfile error 2: System error (disk)', LException.Message);
  finally
    LException.Free;
  end;
end;

end.
