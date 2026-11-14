{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSfxChannelPicker                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.ChannelPicker;

// Angles and seeds wrap around, as in the engine (Doom32.inc has no overflow checks)
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Audio.ChannelPicker,
  DelphiDoom.Tests.Audio.OldSound;

type
  [TestFixture]
  [Category('audio')]
  TTestAudioChannelPicker = class(TObject)
  private
    FSounds: array[0..7] of TOldSfxInfo;
    FOrigins: array[0..5] of Integer;
    FChannels: array[0..3] of TSfxChannelSlot;
    procedure Fill(AChannel, ASound, AOrigin: Integer);
    function Pick(AOrigin, AListener, APriority: Integer): TSfxChannelChoice;
    function OriginAt(AIndex: Integer): Pointer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLoStessoDelVecchioCodiceSuScenariCasuali;
    [Test]
    procedure DovrebbeAvereIlLayoutDelCanaleDelMotore;
    [Test]
    procedure DovrebbePrendereIlPrimoCanaleLibero;
    [Test]
    procedure DovrebbeFermareIlCanaleDellaStessaOrigine;
    [Test]
    procedure NonDovrebbeCercareLaStessaOrigineSeNonCeOrigine;
    [Test]
    procedure DovrebbeFermarsiAlCanaleLiberoPrimaDellaStessaOrigine;
    [Test]
    procedure DovrebbeCacciareIlPrimoCheContaMeno;
    [Test]
    procedure DovrebbeCacciareIlPrimoCheContaUgualeSeNessunoContaMeno;
    [Test]
    procedure DovrebbeDareMenoUnoSeTuttiContanoDiPiu;
    [Test]
    procedure DovrebbeCacciareUnAltraOriginePerUnSuonoDiChiAscolta;
    [Test]
    procedure DovrebbeCacciareUnAltraOriginePerUnSuonoSenzaOrigine;
    [Test]
    procedure DovrebbeDareMenoUnoSenzaCanali;
  end;

implementation

function PriorityOfSound(ASound: Pointer): Integer;
begin
  Result := POldSfxInfo(ASound).priority;
end;

{ TTestAudioChannelPicker }

procedure TTestAudioChannelPicker.Setup;
var
  LIndex: Integer;
begin
  // the sound i has priority 10 * i
  for LIndex := 0 to High(FSounds) do
  begin
    FSounds[LIndex].priority := 10 * LIndex;
    FSounds[LIndex].usefulness := 0;
  end;
  FillChar(FChannels, SizeOf(FChannels), 0);
end;

function TTestAudioChannelPicker.OriginAt(AIndex: Integer): Pointer;
begin
  if AIndex < 0 then
    Result := nil
  else
    Result := @FOrigins[AIndex];
end;

procedure TTestAudioChannelPicker.Fill(AChannel, ASound, AOrigin: Integer);
begin
  FChannels[AChannel].Sound := @FSounds[ASound];
  FChannels[AChannel].Origin := OriginAt(AOrigin);
  FChannels[AChannel].Handle := 100 + AChannel;
end;

function TTestAudioChannelPicker.Pick(AOrigin, AListener, APriority: Integer): TSfxChannelChoice;
begin
  Result := TSfxChannelPicker.Pick(@FChannels[0], Length(FChannels), OriginAt(AOrigin),
    OriginAt(AListener), APriority, PriorityOfSound);
end;

procedure TTestAudioChannelPicker.DovrebbeDareLoStessoDelVecchioCodiceSuScenariCasuali;
const
  SCENARIOS = 400;
  STEPS = 120;
var
  LScenario, LStep, LIndex, LCount: Integer;
  LSeed: Cardinal;
  LOld: TOldSound;
  LNew: array of TSfxChannelSlot;
  LSounds: array[0..9] of TOldSfxInfo;
  LOrigins: array[0..4] of Integer;
  LOrigin, LListener: Pointer;
  LSound: Integer;
  LOldChannel: Integer;
  LChoice: TSfxChannelChoice;
  LStoppedBefore: Integer;
  LWhere: string;

  function Next(ARange: Integer): Integer;
  begin
{$Q-}
    LSeed := LSeed * 1664525 + 1013904223;
    Result := Integer((LSeed shr 8) mod Cardinal(ARange));
  end;

  function RandomOrigin: Pointer;
  var
    LPick: Integer;
  begin
    LPick := Next(Length(LOrigins) + 2);
    if LPick >= Length(LOrigins) then
      Result := nil
    else
      Result := @LOrigins[LPick];
  end;

begin
  for LScenario := 1 to SCENARIOS do
  begin
    LSeed := Cardinal(LScenario) * 2654435761;
    LCount := 1 + Next(8);
    // few different priorities: ties and "all more important" must happen
    for LIndex := 0 to High(LSounds) do
    begin
      LSounds[LIndex].priority := 32 * Next(4);
      LSounds[LIndex].usefulness := 0;
    end;
    LOld := TOldSound.Create;
    try
      LOld.numChannels := LCount;
      SetLength(LOld.channels, LCount);
      SetLength(LNew, LCount);
      for LIndex := 0 to LCount - 1 do
      begin
        LOld.channels[LIndex].sfxinfo := nil;
        LOld.channels[LIndex].origin := nil;
        LOld.channels[LIndex].handle := 0;
        LNew[LIndex].Sound := nil;
        LNew[LIndex].Origin := nil;
        LNew[LIndex].Handle := 0;
      end;
      LListener := @LOrigins[0];
      LOld.ConsolePlayerMo := LListener;

      for LStep := 1 to STEPS do
      begin
        LWhere := Format('scenario %d passo %d (%d canali)', [LScenario, LStep, LCount]);
        if Next(5) = 0 then
        begin
          // a sound ends: both free the same channel
          LIndex := Next(LCount);
          LOld.channels[LIndex].sfxinfo := nil;
          LNew[LIndex].Sound := nil;
          Continue;
        end;

        LOrigin := RandomOrigin;
        LSound := Next(Length(LSounds));
        LStoppedBefore := Length(LOld.Stopped);
        LOldChannel := LOld.S_GetChannel(LOrigin, @LSounds[LSound]);

        LChoice := TSfxChannelPicker.Pick(@LNew[0], LCount, LOrigin, LListener,
          LSounds[LSound].priority, PriorityOfSound);
        Assert.AreEqual(LOldChannel, LChoice.Channel, 'dovrebbe scegliere il canale del vecchio: ' + LWhere);
        if LChoice.Channel >= 0 then
        begin
          // what the facade does with the choice
          Assert.AreEqual(Length(LOld.Stopped) > LStoppedBefore, LChoice.MustStop,
            'dovrebbe fermare il canale quando lo fermava il vecchio: ' + LWhere);
          if LChoice.MustStop then
            Assert.AreEqual(LOld.Stopped[High(LOld.Stopped)], LChoice.Channel,
              'dovrebbe fermare lo stesso canale del vecchio: ' + LWhere);
          LNew[LChoice.Channel].Sound := @LSounds[LSound];
          LNew[LChoice.Channel].Origin := LOrigin;
        end
        else
          Assert.AreEqual(LStoppedBefore, Length(LOld.Stopped),
            'il vecchio non dovrebbe aver fermato niente: ' + LWhere);

        for LIndex := 0 to LCount - 1 do
        begin
          Assert.AreEqual(NativeUInt(LOld.channels[LIndex].sfxinfo), NativeUInt(LNew[LIndex].Sound),
            Format('il canale %d dovrebbe avere il suono del vecchio: %s', [LIndex, LWhere]));
          Assert.AreEqual(NativeUInt(LOld.channels[LIndex].origin), NativeUInt(LNew[LIndex].Origin),
            Format('il canale %d dovrebbe avere l''origine del vecchio: %s', [LIndex, LWhere]));
        end;
      end;
    finally
      LOld.Free;
    end;
  end;
end;

procedure TTestAudioChannelPicker.DovrebbeAvereIlLayoutDelCanaleDelMotore;
var
  LSlot: TSfxChannelSlot;
begin
  // channel_t of s_sound.pas: two pointers and an integer, in this order
  Assert.AreEqual<NativeInt>(0, NativeInt(@LSlot.Sound) - NativeInt(@LSlot));
  Assert.AreEqual<NativeInt>(SizeOf(Pointer), NativeInt(@LSlot.Origin) - NativeInt(@LSlot));
  Assert.AreEqual<NativeInt>(2 * SizeOf(Pointer), NativeInt(@LSlot.Handle) - NativeInt(@LSlot));
  Assert.AreEqual<Integer>(SizeOf(TOldChannel), SizeOf(TSfxChannelSlot));
end;

procedure TTestAudioChannelPicker.DovrebbePrendereIlPrimoCanaleLibero;
var
  LChoice: TSfxChannelChoice;
begin
  Fill(0, 1, 1);
  Fill(2, 1, 2);
  LChoice := Pick(3, 0, 10);
  Assert.AreEqual(1, LChoice.Channel);
  Assert.IsFalse(LChoice.MustStop, 'un canale libero non si ferma');
end;

procedure TTestAudioChannelPicker.DovrebbeFermareIlCanaleDellaStessaOrigine;
var
  LChoice: TSfxChannelChoice;
begin
  Fill(0, 1, 1);
  Fill(1, 1, 2);
  LChoice := Pick(2, 0, 10);
  Assert.AreEqual(1, LChoice.Channel, 'dovrebbe riusare il canale di quell''origine');
  Assert.IsTrue(LChoice.MustStop, 'dovrebbe chiedere di fermare il suono di prima');
end;

procedure TTestAudioChannelPicker.NonDovrebbeCercareLaStessaOrigineSeNonCeOrigine;
var
  LChoice: TSfxChannelChoice;
begin
  Fill(0, 1, -1);
  Fill(1, 1, -1);
  LChoice := Pick(-1, 0, 10);
  Assert.AreEqual(2, LChoice.Channel, 'due suoni senza origine non sono la stessa origine');
  Assert.IsFalse(LChoice.MustStop);
end;

procedure TTestAudioChannelPicker.DovrebbeFermarsiAlCanaleLiberoPrimaDellaStessaOrigine;
var
  LChoice: TSfxChannelChoice;
begin
  Fill(0, 1, 1);
  Fill(2, 1, 3);
  LChoice := Pick(3, 0, 10);
  Assert.AreEqual(1, LChoice.Channel, 'il canale libero viene prima di quello della stessa origine');
  Assert.IsFalse(LChoice.MustStop);
end;

procedure TTestAudioChannelPicker.DovrebbeCacciareIlPrimoCheContaMeno;
var
  LChoice: TSfxChannelChoice;
begin
  // a greater number of priority matters less
  Fill(0, 1, 1);
  Fill(1, 5, 2);
  Fill(2, 7, 3);
  Fill(3, 1, 4);
  LChoice := Pick(5, 0, 30);
  Assert.AreEqual(1, LChoice.Channel);
  Assert.IsTrue(LChoice.MustStop);
end;

procedure TTestAudioChannelPicker.DovrebbeCacciareIlPrimoCheContaUgualeSeNessunoContaMeno;
var
  LChoice: TSfxChannelChoice;
begin
  Fill(0, 1, 1);
  Fill(1, 2, 2);
  Fill(2, 3, 3);
  Fill(3, 3, 4);
  LChoice := Pick(5, 0, 30);
  Assert.AreEqual(2, LChoice.Channel);
  Assert.IsTrue(LChoice.MustStop);
end;

procedure TTestAudioChannelPicker.DovrebbeDareMenoUnoSeTuttiContanoDiPiu;
var
  LChoice: TSfxChannelChoice;
begin
  Fill(0, 1, 1);
  Fill(1, 2, 2);
  Fill(2, 1, 3);
  Fill(3, 2, 4);
  LChoice := Pick(5, 0, 30);
  Assert.AreEqual(-1, LChoice.Channel);
  Assert.IsFalse(LChoice.MustStop, 'senza canale non c''e'' niente da fermare');
end;

procedure TTestAudioChannelPicker.DovrebbeCacciareUnAltraOriginePerUnSuonoDiChiAscolta;
var
  LChoice: TSfxChannelChoice;
begin
  // every channel matters more than the new sound, which is of the listener (origin 5): the
  // channel 0 has no origin, the 1 is the first of somebody else
  Fill(0, 1, -1);
  Fill(1, 2, 3);
  Fill(2, 1, 3);
  Fill(3, 2, 4);
  LChoice := Pick(5, 5, 30);
  Assert.AreEqual(1, LChoice.Channel, 'dovrebbe cacciare il primo suono di un altro');
  Assert.IsTrue(LChoice.MustStop);

  // the same sound made by somebody that is not the listener finds no channel
  LChoice := Pick(5, 0, 30);
  Assert.AreEqual(-1, LChoice.Channel, 'solo chi ascolta puo'' cacciare chi conta di piu''');
end;

procedure TTestAudioChannelPicker.DovrebbeCacciareUnAltraOriginePerUnSuonoSenzaOrigine;
var
  LChoice: TSfxChannelChoice;
begin
  Fill(0, 1, -1);
  Fill(1, 2, 0);
  Fill(2, 1, 3);
  Fill(3, 2, 4);
  LChoice := Pick(-1, 0, 30);
  Assert.AreEqual(2, LChoice.Channel, 'salta il canale senza origine e quello di chi ascolta');
  Assert.IsTrue(LChoice.MustStop);
end;

procedure TTestAudioChannelPicker.DovrebbeDareMenoUnoSenzaCanali;
var
  LChoice: TSfxChannelChoice;
begin
  LChoice := TSfxChannelPicker.Pick(@FChannels[0], 0, OriginAt(1), OriginAt(0), 10,
    PriorityOfSound);
  Assert.AreEqual(-1, LChoice.Channel);
  Assert.IsFalse(LChoice.MustStop);
end;

end.
