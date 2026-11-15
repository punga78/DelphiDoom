{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TWaveSoundOggDecoder, the OGG decoder of a wave file   }
{  on Libs\Sound (DUnitX), in the project of the sound library tests           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WaveOggDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Factory,
  DelphiDoom.Audio.WaveFile.Intf, DelphiDoom.Audio.WaveFile.SoundOggDecoder,
  DelphiDoom.Tests.Sound.VorbisFile;

type
  [TestFixture]
  [Category('audio')]
  TTestWaveSoundOggDecoder = class(TObject)
  public
    [Test]
    procedure DovrebbeDecodificareUnOggAShortLittleEndian;
    [Test]
    procedure DovrebbeRifiutareByteCheNonSonoUnOgg;
  end;

implementation

procedure TTestWaveSoundOggDecoder.DovrebbeDecodificareUnOggAShortLittleEndian;
var
  LDecoder: IWaveOggDecoder;
  LData: TBytes;
  LChannels: Integer;
  LRate: Cardinal;
  LPcm: TBytes;
  LEngine: ISndfile;
  LFile: ISoundFile;
  LInfo: TSoundFileInfo;
  LExpected: TArray<SmallInt>;
  LRead: Int64;
  LIndex: Integer;
begin
  LData := TSoundTestVorbisFile.Build(TSoundTestVorbisOptions.Plain);
  LDecoder := TWaveSoundOggDecoder.Create;
  Assert.IsTrue(LDecoder.TryDecode(LData, LChannels, LRate, LPcm));
  // the same samples as the engine of Libs\Sound reads
  LEngine := TSoundFactory.CreateEngine;
  Assert.AreEqual(SNDFILE_OK, LEngine.OpenMemory(@LData[0], Length(LData), LFile));
  Assert.AreEqual(SNDFILE_OK, LFile.GetInfo(LInfo));
  Assert.AreEqual(LInfo.Channels, LChannels);
  Assert.AreEqual<Cardinal>(Cardinal(LInfo.SampleRate), LRate);
  SetLength(LExpected, LInfo.Frames * LInfo.Channels);
  Assert.AreEqual(SNDFILE_OK, LFile.ReadShort(@LExpected[0], LInfo.Frames, LRead));
  Assert.AreEqual(Length(LExpected) * 2, Length(LPcm));
  for LIndex := 0 to High(LExpected) do
    Assert.AreEqual(Integer(LExpected[LIndex]), Integer(SmallInt(LPcm[LIndex * 2] or (LPcm[LIndex * 2 + 1] shl 8))));
end;

procedure TTestWaveSoundOggDecoder.DovrebbeRifiutareByteCheNonSonoUnOgg;
var
  LDecoder: IWaveOggDecoder;
  LChannels: Integer;
  LRate: Cardinal;
  LPcm: TBytes;
begin
  LDecoder := TWaveSoundOggDecoder.Create;
  Assert.IsFalse(LDecoder.TryDecode(TBytes.Create(1, 2, 3), LChannels, LRate, LPcm));
  Assert.IsFalse(LDecoder.TryDecode(TBytes.Create(Ord('O'), Ord('g'), Ord('g'), Ord('S'), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    LChannels, LRate, LPcm));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWaveSoundOggDecoder);

end.
