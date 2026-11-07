{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiCmfReader                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Reader.Cmf;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Midi.Types,
  DelphiDoom.Xmi.Midi.Song, DelphiDoom.Xmi.Reader.Cmf;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiReaderCmf = class(TObject)
  private
    function CaseData(const AName: string): TBytes;
  public
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaFirma;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneSconosciuta;
    [Test]
    procedure DovrebbeLeggereIlTitolo;
    [Test]
    procedure DovrebbeNonAvereTracceSeLaMusicaEOltreIlFile;
  end;

implementation

uses
  DelphiDoom.Tests.Xmi.ReferenceCases, DelphiDoom.Tests.Xmi.Samples;

{ TTestXmiReaderCmf }

function TTestXmiReaderCmf.CaseData(const AName: string): TBytes;
var
  LCase: TXmiReferenceCase;
begin
  for LCase in TXmiReferenceCases.All do
    if LCase.Name = AName then
      Exit(LCase.Data);
  Result := nil;
end;

procedure TTestXmiReaderCmf.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TXmiCmfReader.Read(Copy(TXmiSamples.BuildCmf, 0, 35)).Free;
    end, EXmiDataException);
end;

procedure TTestXmiReaderCmf.DovrebbeRifiutareUnFileSenzaFirma;
var
  LData: TBytes;
begin
  LData := TXmiSamples.BuildCmf;
  LData[3] := Ord('X');
  Assert.WillRaise(
    procedure
    begin
      TXmiCmfReader.Read(LData).Free;
    end, EXmiDataException);
end;

procedure TTestXmiReaderCmf.DovrebbeRifiutareUnaVersioneSconosciuta;
begin
  Assert.WillRaise(
    procedure
    begin
      TXmiCmfReader.Read(CaseData('cmf_bad_version')).Free;
    end, EXmiDataException);
end;

procedure TTestXmiReaderCmf.DovrebbeLeggereIlTitolo;
var
  LSong: TXmiSong;
begin
  LSong := TXmiCmfReader.Read(CaseData('cmf_title_after_music'));
  try
    Assert.AreEqual(1, LSong.Tracks.Count);
    Assert.AreEqual('Titolo', string(LSong.Tracks[0].Title));
    Assert.AreEqual(96, Integer(LSong.Division));
  finally
    LSong.Free;
  end;
end;

procedure TTestXmiReaderCmf.DovrebbeNonAvereTracceSeLaMusicaEOltreIlFile;
var
  LData: TBytes;
  LSong: TXmiSong;
begin
  LData := TXmiSamples.BuildCmf;
  // The offset of the music, little endian, beyond the end of the file
  LData[8] := $FF;
  LData[9] := $7F;
  LSong := TXmiCmfReader.Read(LData);
  try
    Assert.AreEqual(0, LSong.Tracks.Count);
  finally
    LSong.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiReaderCmf);

end.
