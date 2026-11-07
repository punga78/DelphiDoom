{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiXmiReader                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Reader.Xmi;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Midi.Types,
  DelphiDoom.Xmi.Midi.Song, DelphiDoom.Xmi.Reader.Xmi;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiReaderXmi = class(TObject)
  public
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaXmid;
    [Test]
    procedure DovrebbeLeggereUnBranoPerOgniForm;
  end;

implementation

uses
  DelphiDoom.Tests.Xmi.ReferenceCases, DelphiDoom.Tests.Xmi.Samples;

{ TTestXmiReaderXmi }

procedure TTestXmiReaderXmi.DovrebbeRifiutareUnFileSenzaXmid;
begin
  Assert.WillRaise(
    procedure
    begin
      TXmiXmiReader.Read(TXmiSamples.BuildCmf).Free;
    end, EXmiDataException);
end;

procedure TTestXmiReaderXmi.DovrebbeLeggereUnBranoPerOgniForm;
var
  LCase: TXmiReferenceCase;
  LSong: TXmiSong;
begin
  for LCase in TXmiReferenceCases.All do
    if LCase.Name = 'xmi_two_forms_without_cat' then
    begin
      LSong := TXmiXmiReader.Read(LCase.Data);
      try
        Assert.AreEqual(2, LSong.Tracks.Count);
        // Program change and the end of the track
        Assert.AreEqual(2, LSong.Tracks[1].Count);
        Assert.AreEqual($C1, Integer(LSong.Tracks[1][0].Status));
        Assert.AreEqual(7, Integer(LSong.Tracks[1][0].Param1));
      finally
        LSong.Free;
      end;
      Exit;
    end;
  Assert.Fail('song not found');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiReaderXmi);

end.
