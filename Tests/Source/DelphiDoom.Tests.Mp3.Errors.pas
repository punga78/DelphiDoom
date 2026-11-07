{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mp3 library - the error codes and the shims        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.Errors;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mp3.Intf;

type
  [TestFixture]
  [Category('mp3')]
  TTestMp3Errors = class(TObject)
  public
    [Test]
    [TestCase('OK', '0,OK')]
    [TestCase('Dati', '1,More data needed')]
    [TestCase('Argomento', '-1,Invalid argument')]
    [TestCase('Layer', '-2,Unsupported MPEG layer')]
    [TestCase('Mp3', '-3,Invalid MP3 data')]
    [TestCase('Memoria', '-4,Insufficient memory')]
    [TestCase('Limite', '-5,Too much data buffered')]
    [TestCase('Interno', '-6,Internal error')]
    [TestCase('Sconosciuto', '-77,Unknown error')]
    procedure DovrebbeDareIlTestoDiOgniCodice(ACode: Integer; const AText: string);
    [Test]
    procedure DovrebbeDareIlCodiceDiUnEccezione;
    [Test]
    procedure DovrebbeScrivereCodiceETestoNelMessaggio;
    [Test]
    procedure DovrebbeFermareIlDecoderConLErroreDelloShim;
    [Test]
    procedure DovrebbeLiberareConIlFreeAndNilDelloShim;
  end;

implementation

uses
  mp3_OBuffer, i_system, d_delphi;

{ TTestMp3Errors }

procedure TTestMp3Errors.DovrebbeDareIlTestoDiOgniCodice(ACode: Integer; const AText: string);
begin
  Assert.AreEqual(AText, EMp3Exception.TextOf(ACode));
end;

procedure TTestMp3Errors.DovrebbeDareIlCodiceDiUnEccezione;
var
  LException: Exception;
begin
  LException := EMp3Exception.CreateCode(MP3_ERROR_DATA);
  try
    Assert.AreEqual(MP3_ERROR_DATA, EMp3Exception.CodeOf(LException));
  finally
    LException.Free;
  end;
  LException := EOutOfMemory.Create('');
  try
    Assert.AreEqual(MP3_ERROR_MEMORY, EMp3Exception.CodeOf(LException));
  finally
    LException.Free;
  end;
  LException := EDivByZero.Create('');
  try
    Assert.AreEqual(MP3_ERROR_INTERNAL, EMp3Exception.CodeOf(LException));
  finally
    LException.Free;
  end;
end;

procedure TTestMp3Errors.DovrebbeScrivereCodiceETestoNelMessaggio;
var
  LException: EMp3Exception;
begin
  LException := EMp3Exception.CreateCode(MP3_ERROR_LIMIT);
  try
    Assert.AreEqual(MP3_ERROR_LIMIT, LException.Code);
    Assert.AreEqual('mp3 error -5: Too much data buffered', LException.Message);
  finally
    LException.Free;
  end;
end;

procedure TTestMp3Errors.DovrebbeFermareIlDecoderConLErroreDelloShim;
begin
  // the shim of i_system: an error of the decoder is an exception, a warning goes to the debugger
  Assert.WillRaise(
    procedure
    begin
      TOBuffer_Wave_Failure;
    end,
    Exception);
  I_Warning('mp3 test');
  I_Sleep(0);
end;

procedure TTestMp3Errors.DovrebbeLiberareConIlFreeAndNilDelloShim;
var
  LObject: TObject;
begin
  LObject := TObject.Create;
  d_delphi.FreeAndNil(LObject);
  Assert.IsNull(LObject);
end;

end.
