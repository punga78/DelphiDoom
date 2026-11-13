{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the fade of the music of Libs\War                      }
{                                                                              }
{  A sample rate of 1000 makes a millisecond one sample.                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MusicFade;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Music.Fade;

type
  [TestFixture]
  [Category('war')]
  TTestWarMusicFade = class
  strict private
    FFade: TWarMusicFade;
    FSamples: TArray<SmallInt>;
    procedure Fill(ACount: Integer; AValue: SmallInt);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLasciareICampioniAVolumePieno;
    [Test]
    procedure DovrebbeSalireDalSilenzioInModoLineare;
    [Test]
    procedure DovrebbeScendereAlSilenzioInModoLineare;
    [Test]
    procedure DovrebbeRestareAlVolumePienoDopoLaSalita;
    [Test]
    procedure DovrebbeRestareInSilenzioDopoLaDiscesa;
    [Test]
    procedure DovrebbeScendereDalPuntoRaggiuntoSeLaSalitaNonEFinita;
    [Test]
    procedure DovrebbePassareAlVolumePienoSubitoConDurataZero;
    [Test]
    procedure DovrebbePassareAlSilenzioSubitoConDurataZero;
    [Test]
    procedure DovrebbeTroncareVersoLoZeroIDueSegni;
    [Test]
    procedure DovrebbeSeguireLaRampaAncheInPiuChiamate;
    [Test]
    procedure DovrebbeDareSilenzioConMuteERipartireConReset;
    [Test]
    procedure DovrebbeDirsiSilenziosoSoloAFineRampaDiscendente;
    [Test]
    procedure DovrebbeLimitareUnaDurataEnorme;
  end;

implementation

{ TTestWarMusicFade }

procedure TTestWarMusicFade.Setup;
begin
  FFade := TWarMusicFade.Create(1000);
end;

procedure TTestWarMusicFade.TearDown;
begin
  FFade.Free;
end;

procedure TTestWarMusicFade.Fill(ACount: Integer; AValue: SmallInt);
var
  LIndex: Integer;
begin
  SetLength(FSamples, ACount);
  for LIndex := 0 to ACount - 1 do
    FSamples[LIndex] := AValue;
end;

procedure TTestWarMusicFade.DovrebbeLasciareICampioniAVolumePieno;
var
  LIndex: Integer;
begin
  Fill(10, 12345);
  FFade.Apply(@FSamples[0], 10);
  for LIndex := 0 to 9 do
    Assert.AreEqual<Integer>(12345, FSamples[LIndex]);
  Assert.IsFalse(FFade.IsRamping);
  Assert.IsFalse(FFade.IsSilent);
end;

procedure TTestWarMusicFade.DovrebbeSalireDalSilenzioInModoLineare;
begin
  Fill(100, 10000);
  FFade.FadeIn(100);
  Assert.IsTrue(FFade.IsRamping);
  FFade.Apply(@FSamples[0], 100);
  Assert.AreEqual<Integer>(0, FSamples[0]);
  Assert.AreEqual<Integer>(5000, FSamples[50]);
  // 10000 * 64880 / 65536, truncated
  Assert.AreEqual<Integer>(9899, FSamples[99]);
  Assert.IsTrue(FSamples[10] < FSamples[11], 'It rises');
end;

procedure TTestWarMusicFade.DovrebbeScendereAlSilenzioInModoLineare;
begin
  Fill(100, 10000);
  FFade.FadeOut(100);
  FFade.Apply(@FSamples[0], 100);
  Assert.AreEqual<Integer>(10000, FSamples[0]);
  Assert.AreEqual<Integer>(5000, FSamples[50]);
  Assert.AreEqual<Integer>(100, FSamples[99]);
end;

procedure TTestWarMusicFade.DovrebbeRestareAlVolumePienoDopoLaSalita;
begin
  Fill(150, 10000);
  FFade.FadeIn(100);
  FFade.Apply(@FSamples[0], 150);
  Assert.AreEqual<Integer>(10000, FSamples[100]);
  Assert.AreEqual<Integer>(10000, FSamples[149]);
  Assert.IsFalse(FFade.IsRamping);
  Assert.AreEqual<Integer>(65536, FFade.Gain);
end;

procedure TTestWarMusicFade.DovrebbeRestareInSilenzioDopoLaDiscesa;
begin
  Fill(150, 10000);
  FFade.FadeOut(100);
  FFade.Apply(@FSamples[0], 150);
  Assert.AreEqual<Integer>(0, FSamples[100]);
  Assert.AreEqual<Integer>(0, FSamples[149]);
  Assert.IsFalse(FFade.IsRamping);
  Assert.IsTrue(FFade.IsSilent);
end;

procedure TTestWarMusicFade.DovrebbeScendereDalPuntoRaggiuntoSeLaSalitaNonEFinita;
begin
  Fill(50, 10000);
  FFade.FadeIn(100);
  FFade.Apply(@FSamples[0], 50);
  // half way up: the gain is 0.5 and it falls from there
  Assert.AreEqual<Integer>(32768, FFade.Gain);
  FFade.FadeOut(100);
  Fill(100, 10000);
  FFade.Apply(@FSamples[0], 100);
  Assert.AreEqual<Integer>(5000, FSamples[0]);
  Assert.AreEqual<Integer>(2500, FSamples[50]);
  Assert.IsTrue(FFade.IsSilent);
end;

procedure TTestWarMusicFade.DovrebbePassareAlVolumePienoSubitoConDurataZero;
begin
  FFade.Mute;
  FFade.FadeIn(0);
  Assert.AreEqual<Integer>(65536, FFade.Gain);
  Assert.IsFalse(FFade.IsRamping);
end;

procedure TTestWarMusicFade.DovrebbePassareAlSilenzioSubitoConDurataZero;
begin
  FFade.FadeOut(0);
  Assert.AreEqual<Integer>(0, FFade.Gain);
  Assert.IsTrue(FFade.IsSilent);
  FFade.FadeIn(-5);
  Assert.AreEqual<Integer>(65536, FFade.Gain);
end;

procedure TTestWarMusicFade.DovrebbeTroncareVersoLoZeroIDueSegni;
begin
  SetLength(FSamples, 2);
  FSamples[0] := 1001;
  FSamples[1] := -1001;
  FFade.FadeOut(1000);
  // after the first sample the gain is 1 - 1/1000
  FFade.Apply(@FSamples[0], 1);
  FFade.Apply(@FSamples[1], 1);
  Assert.AreEqual<Integer>(1001, FSamples[0]);
  Assert.AreEqual<Integer>(-1000, FSamples[1]);
end;

procedure TTestWarMusicFade.DovrebbeSeguireLaRampaAncheInPiuChiamate;
var
  LWhole: TArray<SmallInt>;
  LIndex: Integer;
begin
  Fill(100, 10000);
  FFade.FadeIn(100);
  FFade.Apply(@FSamples[0], 100);
  LWhole := Copy(FSamples);
  Fill(100, 10000);
  FFade.Free;
  FFade := TWarMusicFade.Create(1000);
  FFade.FadeIn(100);
  FFade.Apply(@FSamples[0], 30);
  FFade.Apply(@FSamples[30], 30);
  FFade.Apply(@FSamples[60], 40);
  for LIndex := 0 to 99 do
    Assert.AreEqual<Integer>(LWhole[LIndex], FSamples[LIndex], IntToStr(LIndex));
end;

procedure TTestWarMusicFade.DovrebbeDareSilenzioConMuteERipartireConReset;
begin
  Fill(4, 500);
  FFade.Mute;
  FFade.Apply(@FSamples[0], 4);
  Assert.AreEqual<Integer>(0, FSamples[3]);
  FFade.Reset;
  Fill(4, 500);
  FFade.Apply(@FSamples[0], 4);
  Assert.AreEqual<Integer>(500, FSamples[3]);
end;

procedure TTestWarMusicFade.DovrebbeLimitareUnaDurataEnorme;
begin
  Fill(10, 10000);
  FFade.FadeOut(High(Integer));
  FFade.Apply(@FSamples[0], 10);
  // the ramp does not wrap around: it is still at the start
  Assert.AreEqual<Integer>(10000, FSamples[0]);
  Assert.IsTrue(FSamples[9] > 9999);
  Assert.IsTrue(FFade.IsRamping);
end;

procedure TTestWarMusicFade.DovrebbeDirsiSilenziosoSoloAFineRampaDiscendente;
begin
  Fill(100, 10000);
  FFade.FadeOut(100);
  Assert.IsFalse(FFade.IsSilent);
  FFade.Apply(@FSamples[0], 99);
  Assert.IsFalse(FFade.IsSilent);
  FFade.Apply(@FSamples[99], 1);
  Assert.IsTrue(FFade.IsSilent);
end;

end.
