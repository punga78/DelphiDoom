{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiMidiWriter                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Writer.Midi;

// The bytes expected here follow the specification of the standard MIDI file
// (header chunk: format, number of tracks, division; SMPTE division: negative
// frames per second, then the ticks per frame)

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Midi.Types,
  DelphiDoom.Xmi.Midi.Song, DelphiDoom.Xmi.Writer.Midi;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiWriterMidi = class(TObject)
  private
    FSong: TXmiSong;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLaDivisioneSmpte;
    [Test]
    procedure DovrebbeNonScrivereTracceDiUnBranoDiTipoZeroVuoto;
    [Test]
    procedure DovrebbeScrivereUnaTracciaPerOgniTracciaDelTipoDue;
  end;

implementation

uses
  DelphiDoom.Tests.Xmi.ReferenceCases;

{ TTestXmiWriterMidi }

procedure TTestXmiWriterMidi.Setup;
begin
  FSong := TXmiSong.Create;
end;

procedure TTestXmiWriterMidi.TearDown;
begin
  FreeAndNil(FSong);
end;

procedure TTestXmiWriterMidi.DovrebbeScrivereLaDivisioneSmpte;
begin
  // 25 frames per second ($E7 = -25), 40 ticks per frame
  FSong.MidiType := XMI_MIDI_TYPE_SINGLE_TRACK;
  FSong.Smpte := -25;
  FSong.Division := 40;
  FSong.AddTrack;

  Assert.AreEqual('4D5468640000000600000001E7284D54726B00000000',
    TXmiReferenceCases.ToHex(TXmiMidiWriter.Write(FSong)));
end;

procedure TTestXmiWriterMidi.DovrebbeNonScrivereTracceDiUnBranoDiTipoZeroVuoto;
begin
  FSong.MidiType := XMI_MIDI_TYPE_SINGLE_TRACK;
  FSong.Division := 96;

  Assert.AreEqual('4D54686400000006000000000060',
    TXmiReferenceCases.ToHex(TXmiMidiWriter.Write(FSong)));
end;

procedure TTestXmiWriterMidi.DovrebbeScrivereUnaTracciaPerOgniTracciaDelTipoDue;
begin
  FSong.MidiType := XMI_MIDI_TYPE_MULTI_SONG;
  FSong.Division := 60;
  FSong.AddTrack;
  FSong.AddTrack;

  Assert.AreEqual('4D5468640000000600020002003C4D54726B000000004D54726B00000000',
    TXmiReferenceCases.ToHex(TXmiMidiWriter.Write(FSong)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiWriterMidi);

end.
