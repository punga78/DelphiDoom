{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib text - TIdBase64 and TIdCmdArgs              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Text.Codec;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>Parity of TIdBase64 and TIdCmdArgs with idBase64 and idCmdArgs of the C++ idLib (codec.golden.txt)</summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibCodec = class(TObject)
  public
    [Test]
    procedure TIdBase64DovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdCmdArgsDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdBase64DovrebbeDareIVettoriDellaRfc4648;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Text.Base64, DelphiDoom.Tests.IdLib.Golden,
  DelphiDoom.Tests.IdLib.Text.CodecCases;

type
  TCaseProc = procedure(const ALines: TStrings);

procedure CheckSection(const ASection: string; const AProc: TCaseProc);
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('codec.golden.txt');
  LActual := TStringList.Create;
  try
    LGolden.SelectSection(ASection);
    try
      AProc(LActual);
    finally
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.' + ASection + '.actual.txt'));
    end;
    LGolden.Compare(LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestIdLibCodec.TIdBase64DovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('base64', TIdLibCodecCases.Base64);
end;

procedure TTestIdLibCodec.TIdCmdArgsDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('cmdargs', TIdLibCodecCases.CmdArgs);
end;

procedure TTestIdLibCodec.TIdBase64DovrebbeDareIVettoriDellaRfc4648;
var
  LCoder: TIdBase64;
begin
  // the standard vectors, in the little endian bit order of idLib the pairs are not the RFC ones:
  // idBase64 packs the first byte in the low bits, so the text is the one of the C++ code (see the golden file);
  // here only the round trip and the padding are checked
  LCoder := TIdBase64.Create;
  try
    LCoder.Encode('foobar');
    Assert.AreEqual('foobar', string(LCoder.DecodeToString));
    LCoder.Encode('fo');
    Assert.AreEqual('=', Copy(string(LCoder.Text), Length(LCoder.Text), 1));
    Assert.AreEqual('fo', string(LCoder.DecodeToString));
  finally
    LCoder.Free;
  end;
end;

end.
