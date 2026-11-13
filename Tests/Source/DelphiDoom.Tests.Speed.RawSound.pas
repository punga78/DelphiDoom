{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedRawSound                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.RawSound;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedRawSound = class(TObject)
  public
    [Test]
    procedure DovrebbeScrivereLIntestazioneDiUnWav;
    [Test]
    procedure DovrebbeScrivereLaFrequenzaDueVolte;
    [Test]
    procedure DovrebbeSpostareICampioniDi128;
    [Test]
    procedure DovrebbeFarGirareICampioniOltre255;
    [Test]
    procedure DovrebbeUsareIlVolume;
    [Test]
    procedure DovrebbeFareUnWavDiSoloLIntestazioneSeIlSuonoEVuoto;
    [Test]
    procedure DovrebbeAvereUnIntestazioneDiQuarantaquattroByte;
  end;

implementation

uses
  DelphiDoom.Speed.RawSound;

{ TTestSpeedRawSound }

procedure TTestSpeedRawSound.DovrebbeScrivereLIntestazioneDiUnWav;
var
  LWav: TBytes;
begin
  LWav := TSpeedRawSound.ToWav(TBytes.Create(1, 2, 3), 13000, SPEED_FRACUNIT);
  Assert.AreEqual<Integer>(47, Length(LWav));
  Assert.AreEqual('RIFF', TEncoding.ASCII.GetString(LWav, 0, 4));
  Assert.AreEqual('WAVE', TEncoding.ASCII.GetString(LWav, 8, 4));
  Assert.AreEqual('fmt ', TEncoding.ASCII.GetString(LWav, 12, 4));
  Assert.AreEqual('data', TEncoding.ASCII.GetString(LWav, 36, 4));
  Assert.AreEqual(47, Integer(PInteger(@LWav[4])^), 'the size of the file, as the old code wrote it');
  Assert.AreEqual(3, Integer(PInteger(@LWav[40])^), 'the size of the data');
  Assert.AreEqual<Word>(1, PWord(@LWav[20])^, 'PCM');
  Assert.AreEqual<Word>(1, PWord(@LWav[22])^, 'one channel');
  Assert.AreEqual<Word>(8, PWord(@LWav[34])^, '8 bits');
end;

procedure TTestSpeedRawSound.DovrebbeScrivereLaFrequenzaDueVolte;
var
  LWav: TBytes;
begin
  LWav := TSpeedRawSound.ToWav(TBytes.Create(1), 11125, SPEED_FRACUNIT);
  Assert.AreEqual(11125, Integer(PInteger(@LWav[24])^), 'samples per second');
  Assert.AreEqual(11125, Integer(PInteger(@LWav[28])^), 'bytes per second');
end;

procedure TTestSpeedRawSound.DovrebbeSpostareICampioniDi128;
var
  LWav: TBytes;
begin
  LWav := TSpeedRawSound.ToWav(TBytes.Create(0, 1, 100), 8000, SPEED_FRACUNIT);
  Assert.AreEqual<Byte>(128, LWav[44]);
  Assert.AreEqual<Byte>(129, LWav[45]);
  Assert.AreEqual<Byte>(228, LWav[46]);
end;

procedure TTestSpeedRawSound.DovrebbeFarGirareICampioniOltre255;
var
  LWav: TBytes;
begin
  LWav := TSpeedRawSound.ToWav(TBytes.Create(255, 128), 8000, SPEED_FRACUNIT);
  Assert.AreEqual<Byte>(127, LWav[44], '383 wraps');
  Assert.AreEqual<Byte>(0, LWav[45], '256 wraps');
end;

procedure TTestSpeedRawSound.DovrebbeUsareIlVolume;
var
  LWav: TBytes;
begin
  LWav := TSpeedRawSound.ToWav(TBytes.Create(200, 3), 8000, SPEED_FRACUNIT div 2);
  Assert.AreEqual<Byte>(228, LWav[44], '200 / 2 + 128');
  Assert.AreEqual<Byte>(129, LWav[45], '3 / 2 = 1');
end;

procedure TTestSpeedRawSound.DovrebbeFareUnWavDiSoloLIntestazioneSeIlSuonoEVuoto;
begin
  Assert.AreEqual<Integer>(44, Length(TSpeedRawSound.ToWav(nil, 8000, SPEED_FRACUNIT)));
end;

procedure TTestSpeedRawSound.DovrebbeAvereUnIntestazioneDiQuarantaquattroByte;
begin
  Assert.AreEqual(44, WAV_HEADER_SIZE);
end;

end.
