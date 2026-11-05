{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mapping of the effects of the tracker              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.Effects;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tracker.Effects,
  DelphiDoom.Tracker.Types;

type
  [TestFixture]
  [Category('tracker')]
  TTestTrackerEffectMapper = class(TObject)
  private
    procedure Check(const AFormat: TTrackerFormat; const AEffect, AParam: Byte;
      const AExpectedKind: TTrackerEffectKind; const AExpectedParam: Byte);
    procedure CheckColumn(const AFormat: TTrackerFormat; const AVolume: Integer;
      const AExpectedKind: TTrackerEffectKind; const AExpectedParam: Byte);
  public
    [Test]
    procedure TestEffettiBaseDelMod;
    [Test]
    procedure TestEffettiEstesiDelMod;
    [Test]
    procedure TestVelocitaETempoDelMod;
    [Test]
    procedure TestArpeggioSenzaParametroNonFaNulla;
    [Test]
    procedure TestEffettiPropriDellXm;
    [Test]
    procedure TestEffettiDelloS3m;
    [Test]
    procedure TestInterruzioneDecimaleEBinaria;
    [Test]
    procedure TestEffettiDiIt;
    [Test]
    procedure TestColonnaDelVolumeDelloS3m;
    [Test]
    procedure TestColonnaDelVolumeDellXm;
    [Test]
    procedure TestColonnaDelVolumeDiIt;
    [Test]
    procedure TestColonnaVuotaONonSupportata;
  end;

implementation

{ TTestTrackerEffectMapper }

procedure TTestTrackerEffectMapper.Check(const AFormat: TTrackerFormat; const AEffect,
  AParam: Byte; const AExpectedKind: TTrackerEffectKind; const AExpectedParam: Byte);
var
  LEffect: TTrackerEffect;
begin
  LEffect := TTrackerEffectMapper.Map(AFormat, AEffect, AParam);
  Assert.IsTrue(LEffect.Kind = AExpectedKind, Format('effect %d param %d: kind %d instead of %d',
    [AEffect, AParam, Ord(LEffect.Kind), Ord(AExpectedKind)]));
  Assert.AreEqual(Integer(AExpectedParam), Integer(LEffect.Param),
    Format('effect %d param %d', [AEffect, AParam]));
end;

procedure TTestTrackerEffectMapper.CheckColumn(const AFormat: TTrackerFormat; const AVolume: Integer;
  const AExpectedKind: TTrackerEffectKind; const AExpectedParam: Byte);
var
  LEffect: TTrackerEffect;
begin
  LEffect := TTrackerEffectMapper.MapVolumeColumn(AFormat, AVolume);
  Assert.IsTrue(LEffect.Kind = AExpectedKind, Format('column %d: kind %d instead of %d',
    [AVolume, Ord(LEffect.Kind), Ord(AExpectedKind)]));
  Assert.AreEqual(Integer(AExpectedParam), Integer(LEffect.Param), Format('column %d', [AVolume]));
end;

procedure TTestTrackerEffectMapper.TestEffettiBaseDelMod;
begin
  Check(tfMod, $1, $10, ekPortamentoUp, $10);
  Check(tfMod, $2, $11, ekPortamentoDown, $11);
  Check(tfMod, $3, $12, ekTonePortamento, $12);
  Check(tfMod, $4, $48, ekVibrato, $48);
  Check(tfMod, $5, $02, ekTonePortamentoVolumeSlide, $02);
  Check(tfMod, $6, $20, ekVibratoVolumeSlide, $20);
  Check(tfMod, $7, $44, ekTremolo, $44);
  Check(tfMod, $8, $40, ekSetPanning, $40);
  Check(tfMod, $9, $05, ekSampleOffset, $05);
  Check(tfMod, $A, $0A, ekVolumeSlide, $0A);
  Check(tfMod, $B, $02, ekPositionJump, $02);
  Check(tfMod, $C, $20, ekSetVolume, $20);
end;

procedure TTestTrackerEffectMapper.TestEffettiEstesiDelMod;
begin
  Check(tfMod, $E, $12, ekFinePortamentoUp, 2);
  Check(tfMod, $E, $23, ekFinePortamentoDown, 3);
  Check(tfMod, $E, $62, ekPatternLoop, 2);
  Check(tfMod, $E, $85, ekSetPanning, 85);
  Check(tfMod, $E, $91, ekRetrigger, 1);
  Check(tfMod, $E, $A5, ekFineVolumeSlideUp, 5);
  Check(tfMod, $E, $B4, ekFineVolumeSlideDown, 4);
  Check(tfMod, $E, $C3, ekNoteCut, 3);
  Check(tfMod, $E, $D2, ekNoteDelay, 2);
  Check(tfMod, $E, $E1, ekPatternDelay, 1);
  Check(tfMod, $E, $F0, ekNone, 0);
end;

procedure TTestTrackerEffectMapper.TestVelocitaETempoDelMod;
begin
  Check(tfMod, $F, 3, ekSetSpeed, 3);
  Check(tfMod, $F, 31, ekSetSpeed, 31);
  Check(tfMod, $F, 32, ekSetTempo, 32);
  Check(tfMod, $F, $80, ekSetTempo, $80);
  Check(tfMod, $F, 0, ekNone, 0);
  // The pattern break is in decimal digits
  Check(tfMod, $D, $12, ekPatternBreak, 12);
end;

procedure TTestTrackerEffectMapper.TestArpeggioSenzaParametroNonFaNulla;
begin
  Check(tfMod, 0, $37, ekArpeggio, $37);
  Check(tfMod, 0, 0, ekNone, 0);
end;

procedure TTestTrackerEffectMapper.TestEffettiPropriDellXm;
begin
  Check(tfXm, 16, 32, ekSetGlobalVolume, 32);
  Check(tfXm, 16, 200, ekSetGlobalVolume, 64);
  Check(tfXm, 20, 0, ekKeyOff, 0);
  Check(tfXm, 33, $13, ekExtraFinePortamentoUp, 3);
  Check(tfXm, 33, $24, ekExtraFinePortamentoDown, 4);
  // The ones of MOD are there too
  Check(tfXm, $F, 6, ekSetSpeed, 6);
  Check(tfMod, 16, 32, ekNone, 0);
end;

procedure TTestTrackerEffectMapper.TestEffettiDelloS3m;
begin
  Check(tfS3m, 1, 6, ekSetSpeed, 6);
  Check(tfS3m, 1, 0, ekNone, 0);
  Check(tfS3m, 2, 4, ekPositionJump, 4);
  Check(tfS3m, 4, $F1, ekVolumeSlide, $F1);
  Check(tfS3m, 5, $E3, ekPortamentoDown, $E3);
  Check(tfS3m, 6, $F3, ekPortamentoUp, $F3);
  Check(tfS3m, 7, $10, ekTonePortamento, $10);
  Check(tfS3m, 8, $48, ekVibrato, $48);
  Check(tfS3m, 10, $37, ekArpeggio, $37);
  Check(tfS3m, 11, $02, ekVibratoVolumeSlide, $02);
  Check(tfS3m, 12, $02, ekTonePortamentoVolumeSlide, $02);
  Check(tfS3m, 15, $05, ekSampleOffset, $05);
  Check(tfS3m, 17, $41, ekRetrigger, $41);
  Check(tfS3m, 18, $44, ekTremolo, $44);
  Check(tfS3m, 19, $85, ekSetPanning, 85);
  Check(tfS3m, 19, $B2, ekPatternLoop, 2);
  Check(tfS3m, 19, $C3, ekNoteCut, 3);
  Check(tfS3m, 19, $D2, ekNoteDelay, 2);
  Check(tfS3m, 19, $E1, ekPatternDelay, 1);
  Check(tfS3m, 20, $7D, ekSetTempo, 125);
  Check(tfS3m, 20, 10, ekNone, 0);
  Check(tfS3m, 22, 40, ekSetGlobalVolume, 40);
  // The effect X is only of Impulse Tracker
  Check(tfS3m, 24, $80, ekNone, 0);
end;

procedure TTestTrackerEffectMapper.TestInterruzioneDecimaleEBinaria;
begin
  Check(tfS3m, 3, $12, ekPatternBreak, 12);
  Check(tfIt, 3, $12, ekPatternBreak, 18);
  Check(tfXm, $D, $12, ekPatternBreak, 12);
end;

procedure TTestTrackerEffectMapper.TestEffettiDiIt;
begin
  Check(tfIt, 24, $80, ekSetPanning, $80);
  Check(tfIt, 22, 100, ekSetGlobalVolume, 100);
  Check(tfIt, 1, 3, ekSetSpeed, 3);
  Check(tfIt, 19, $C2, ekNoteCut, 2);
end;

procedure TTestTrackerEffectMapper.TestColonnaDelVolumeDelloS3m;
begin
  CheckColumn(tfS3m, 32, ekSetVolume, 32);
  CheckColumn(tfS3m, 0, ekSetVolume, 0);
  CheckColumn(tfS3m, 65, ekNone, 0);
end;

procedure TTestTrackerEffectMapper.TestColonnaDelVolumeDellXm;
begin
  CheckColumn(tfXm, $30, ekSetVolume, 32);
  CheckColumn(tfXm, $65, ekVolumeSlide, 5);
  CheckColumn(tfXm, $75, ekVolumeSlide, $50);
  CheckColumn(tfXm, $85, ekFineVolumeSlideDown, 5);
  CheckColumn(tfXm, $95, ekFineVolumeSlideUp, 5);
  CheckColumn(tfXm, $C8, ekSetPanning, 136);
  CheckColumn(tfXm, $F4, ekTonePortamento, $40);
  CheckColumn(tfXm, $55, ekNone, 0);
end;

procedure TTestTrackerEffectMapper.TestColonnaDelVolumeDiIt;
begin
  CheckColumn(tfIt, 0, ekSetVolume, 0);
  CheckColumn(tfIt, 64, ekSetVolume, 64);
  CheckColumn(tfIt, 70, ekFineVolumeSlideUp, 5);
  CheckColumn(tfIt, 80, ekFineVolumeSlideDown, 5);
  CheckColumn(tfIt, 90, ekVolumeSlide, $50);
  CheckColumn(tfIt, 100, ekVolumeSlide, 5);
  CheckColumn(tfIt, 110, ekPortamentoDown, 20);
  CheckColumn(tfIt, 120, ekPortamentoUp, 20);
  CheckColumn(tfIt, 150, ekSetPanning, 88);
  CheckColumn(tfIt, 195, ekTonePortamento, 8);
end;

procedure TTestTrackerEffectMapper.TestColonnaVuotaONonSupportata;
begin
  CheckColumn(tfMod, 20, ekNone, 0);
  CheckColumn(tfXm, -1, ekNone, 0);
  CheckColumn(tfIt, -1, ekNone, 0);
  CheckColumn(tfS3m, -1, ekNone, 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerEffectMapper);

end.
