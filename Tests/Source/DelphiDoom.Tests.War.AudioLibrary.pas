{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the sounds and songs of the archive, }
{  with parity on the C of the remake on the real DATA.WAR                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AudioLibrary;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types;

type
  /// <summary>
  ///   audio.records.golden.txt is the output of war_audio_ref.exe on DATA.WAR: wres_loadVoc, wres_loadWave and
  ///   wres_loadXmi ORIGINAL (with voc.h, wav.h and xmi2mid.h) for the 111 sounds and the 45 songs. For a sound:
  ///   format and CRC-32 of what the reader gave, length and CRC-32 of the samples at 44100 Hz (the last bytes the
  ///   original reads past its buffer are left out). For a song: the MIDI of x2m_transcode summarized
  ///   independently of how it is written (see TWarMidiSummary); the bytes of that MIDI are not the ones of
  ///   TXmiConverter, which the library uses, and are not compared
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarAudioLibrary = class(TObject)
  private
    function Fields(const ALine: string): TArray<string>;
  public
    [Test]
    procedure DovrebbeDareGliStessiCampioniDelCodiceOriginaleSuiSuoniDelGioco;
    [Test]
    procedure DovrebbeDareGliStessiEventiDelCodiceOriginaleSuiBraniDelGioco;
    [Test]
    procedure DovrebbeFinireOgniBranoNelloStessoMomentoDelCodiceOriginaleConUnaTolleranza;
    [Test]
    procedure DovrebbeChiudereLeNoteCheIlCodiceOriginaleLasciaAperteInFondoAlBrano;
    [Test]
    procedure DovrebbeAvere111SuoniE45BraniNelGolden;
    [Test]
    procedure DovrebbeDireCosaESuonoESuonoDalCatalogo;
    [Test]
    procedure DovrebbeRifiutareUnRecordCheNonEUnSuono;
    [Test]
    procedure DovrebbeRifiutareUnSuonoCheNonSiDecodifica;
    [Test]
    procedure DovrebbeRicampionareEKeneIlSuono;
    [Test]
    procedure DovrebbeDareIlMidiDelConvertitore;
    [Test]
    procedure DovrebbeRifiutareUnRecordCheNonEUnBrano;
    [Test]
    procedure DovrebbeRifiutareUnBranoCheNonSiConverte;
    [Test]
    procedure DovrebbeRifiutareArgomentiNil;
    [Test]
    procedure DovrebbeConvertireUnBranoXmiConIlConvertitoreDelMotore;
    [Test]
    procedure DovrebbeRifiutareChiNonEUnXmi;
    [Test]
    procedure DovrebbeCreareLeClassiDallaFabbrica;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.AudioSupport, DelphiDoom.War.Intf,
  DelphiDoom.War.Factory, DelphiDoom.War.Audio.Types, DelphiDoom.War.Audio.Intf, DelphiDoom.War.Audio.Records,
  DelphiDoom.War.Audio.Factory, DelphiDoom.War.Audio.VocDecoder, DelphiDoom.War.Audio.WavDecoder,
  DelphiDoom.War.Audio.XmiMusicConverter;

{ TTestWarAudioLibrary }

function TTestWarAudioLibrary.Fields(const ALine: string): TArray<string>;
begin
  Result := ALine.Split([' ']);
end;

procedure TTestWarAudioLibrary.DovrebbeDareGliStessiCampioniDelCodiceOriginaleSuiSuoniDelGioco;
var
  LCatalog: IWarCatalog;
  LArchive: IWarArchive;
  LLibrary: IWarAudioLibrary;
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LIndex, LTail: Integer;
  LRaw: TWarPcmBuffer;
  LSound: TWarPcmBuffer;
  LOk: Boolean;
  LCount: Integer;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog);
  LLibrary := TWarAudioFactory.CreateLibrary(LArchive, LCatalog);
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('audio.records.golden.txt'));
    LCount := 0;
    for LLine in LGolden do
    begin
      LFields := Fields(LLine);
      if (LFields[0] <> 'W') and (LFields[0] <> 'V') then
        Continue;
      LIndex := StrToInt(LFields[1]);
      if LFields[0] = 'V' then
        LOk := TWarVocDecoder.TryDecode(LArchive.ReadRecord(LIndex), LRaw)
      else
        LOk := TWarWavDecoder.TryDecode(LArchive.ReadRecord(LIndex), LRaw);
      Assert.IsTrue(LOk, LLine);
      Assert.AreEqual(StrToUInt64(LFields[2]), UInt64(LRaw.Channels), LLine);
      Assert.AreEqual(StrToUInt64(LFields[3]), UInt64(LRaw.SampleRate), LLine);
      Assert.AreEqual(StrToUInt64(LFields[4]), UInt64(LRaw.BitsPerSample), LLine);
      Assert.AreEqual(StrToUInt64(LFields[5]), UInt64(Length(LRaw.Data)), LLine);
      Assert.AreEqual(LFields[6], TWarAudioHash.Of_(LRaw.Data, Length(LRaw.Data)), LLine);
      LSound := LLibrary.GetSound(LIndex);
      Assert.AreEqual(StrToUInt64(LFields[7]), UInt64(Length(LSound.Data)), LLine);
      LTail := StrToInt(LFields[9]);
      Assert.AreEqual(LFields[8], TWarAudioHash.Of_(LSound.Data, Length(LSound.Data) - LTail), LLine);
      Assert.AreEqual<Cardinal>(WAR_PLAYBACK_RATE, LSound.SampleRate);
      Inc(LCount);
    end;
    Assert.AreEqual(111, LCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioLibrary.DovrebbeDareGliStessiEventiDelCodiceOriginaleSuiBraniDelGioco;
var
  LCatalog: IWarCatalog;
  LArchive: IWarArchive;
  LLibrary: IWarAudioLibrary;
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LIndex, LCount, LExtra, LWithExtra: Integer;
  LSummary: TWarMidiSummary;
begin
  LWithExtra := 0;
  LCatalog := TWarFactory.CreateCatalog;
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog);
  LLibrary := TWarAudioFactory.CreateLibrary(LArchive, LCatalog);
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('audio.records.golden.txt'));
    LCount := 0;
    for LLine in LGolden do
    begin
      LFields := Fields(LLine);
      if LFields[0] <> 'M' then
        Continue;
      LIndex := StrToInt(LFields[1]);
      Assert.AreEqual(StrToUInt64(LFields[2]), UInt64(Length(LArchive.ReadRecord(LIndex))), LLine);
      Assert.AreEqual(LFields[3], TWarAudioHash.Of_(LArchive.ReadRecord(LIndex), Length(LArchive.ReadRecord(LIndex))), LLine);
      LSummary := TWarMidiSummary.Of_(LLibrary.GetMusic(LIndex));
      Assert.AreEqual(StrToInt(LFields[6]), LSummary.NoteOn, 'Note On ' + LLine);
      // TXmiConverter writes at most one controller more than x2m_transcode (in 14 of the 45 songs: 117 = 127,
      // the loop marker of XMI); where it does not, the multiset of all the other events is identical
      LExtra := LSummary.Other - StrToInt(LFields[8]);
      Assert.IsTrue((LExtra = 0) or (LExtra = 1), 'altri eventi ' + LLine);
      if LExtra = 0 then
        Assert.AreEqual(LFields[9], LSummary.EventsCrc, 'insieme degli eventi ' + LLine)
      else
        Inc(LWithExtra);
      Inc(LCount);
    end;
    Assert.AreEqual(45, LCount);
    Assert.AreEqual(14, LWithExtra, 'brani con un controller in piu''');
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioLibrary.DovrebbeFinireOgniBranoNelloStessoMomentoDelCodiceOriginaleConUnaTolleranza;
var
  LCatalog: IWarCatalog;
  LLibrary: IWarAudioLibrary;
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LExpected, LActual: Double;
begin
  // x2m_transcode keeps the first tempo only and truncates the division of the header; TXmiConverter follows
  // the tempo changes: the last note starts within 5 % of the time of the original
  LCatalog := TWarFactory.CreateCatalog;
  LLibrary := TWarAudioFactory.CreateLibrary(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('audio.records.golden.txt'));
    for LLine in LGolden do
    begin
      LFields := Fields(LLine);
      if LFields[0] <> 'M' then
        Continue;
      LExpected := StrToFloat(LFields[10], TFormatSettings.Invariant);
      LActual := TWarMidiSummary.Of_(LLibrary.GetMusic(StrToInt(LFields[1]))).LastNoteOnMicroseconds;
      Assert.IsTrue(Abs(LActual - LExpected) <= LExpected * 0.05, LLine + ' / ' + FloatToStr(LActual));
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioLibrary.DovrebbeChiudereLeNoteCheIlCodiceOriginaleLasciaAperteInFondoAlBrano;
var
  LCatalog: IWarCatalog;
  LLibrary: IWarAudioLibrary;
  LGolden: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LSummary: TWarMidiSummary;
  LOriginalOpen, LOpened: Integer;
begin
  // difetto del C corretto: x2m_transcode smette di scrivere all'evento di fine traccia e perde i Note Off che
  // vengono dopo (le note restano accese); TXmiConverter li scrive tutti, uno per ogni Note On
  LCatalog := TWarFactory.CreateCatalog;
  LLibrary := TWarAudioFactory.CreateLibrary(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('audio.records.golden.txt'));
    LOpened := 0;
    for LLine in LGolden do
    begin
      LFields := Fields(LLine);
      if LFields[0] <> 'M' then
        Continue;
      LSummary := TWarMidiSummary.Of_(LLibrary.GetMusic(StrToInt(LFields[1])));
      Assert.AreEqual(LSummary.NoteOn, LSummary.NoteOff, LLine);
      LOriginalOpen := StrToInt(LFields[6]) - StrToInt(LFields[7]);
      if LOriginalOpen > 0 then
        Inc(LOpened);
    end;
    Assert.IsTrue(LOpened > 0, 'nel gioco ci sono brani con note lasciate accese dal C');
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioLibrary.DovrebbeAvere111SuoniE45BraniNelGolden;
var
  LGolden: TStringList;
  LLine: string;
  LSounds, LSongs: Integer;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('audio.records.golden.txt'));
    LSounds := 0;
    LSongs := 0;
    for LLine in LGolden do
    begin
      if LLine.StartsWith('M ') then Inc(LSongs);
      if LLine.StartsWith('W ') or LLine.StartsWith('V ') then Inc(LSounds);
    end;
    Assert.AreEqual(111, LSounds);
    Assert.AreEqual(45, LSongs);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAudioLibrary.DovrebbeDireCosaESuonoESuonoDalCatalogo;
var
  LCatalog: TWarFakeCatalog;
  LLibrary: IWarAudioLibrary;
begin
  LCatalog := TWarFakeCatalog.Create;
  LCatalog.Put(1, wrtXmid);
  LCatalog.Put(2, wrtWave);
  LCatalog.Put(3, wrtVoc);
  LCatalog.Put(4, wrtImage);
  LLibrary := TWarAudioLibrary.Create(TWarFakeArchive.Create, LCatalog, TWarFakeMusicConverter.Create);
  Assert.AreEqual(Ord(wakMidi), Ord(LLibrary.KindOf(1)));
  Assert.AreEqual(Ord(wakWave), Ord(LLibrary.KindOf(2)));
  Assert.AreEqual(Ord(wakWave), Ord(LLibrary.KindOf(3)));
  Assert.WillRaise(
    procedure
    begin
      LLibrary.KindOf(4);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LLibrary.KindOf(99);
    end, EWarException);
end;

procedure TTestWarAudioLibrary.DovrebbeRifiutareUnRecordCheNonEUnSuono;
var
  LCatalog: TWarFakeCatalog;
  LLibrary: IWarAudioLibrary;
begin
  LCatalog := TWarFakeCatalog.Create;
  LCatalog.Put(1, wrtXmid);
  LLibrary := TWarAudioLibrary.Create(TWarFakeArchive.Create, LCatalog, TWarFakeMusicConverter.Create);
  Assert.WillRaise(
    procedure
    begin
      LLibrary.GetSound(1);
    end, EWarException);
end;

procedure TTestWarAudioLibrary.DovrebbeRifiutareUnSuonoCheNonSiDecodifica;
var
  LCatalog: TWarFakeCatalog;
  LArchive: TWarFakeArchive;
  LLibrary: IWarAudioLibrary;
begin
  LCatalog := TWarFakeCatalog.Create;
  LArchive := TWarFakeArchive.Create;
  LCatalog.Put(1, wrtVoc);
  LCatalog.Put(2, wrtWave);
  LArchive.Put(1, TBytes.Create(1, 2, 3));
  LArchive.Put(2, TBytes.Create(1, 2, 3));
  LLibrary := TWarAudioLibrary.Create(LArchive, LCatalog, TWarFakeMusicConverter.Create);
  Assert.WillRaise(
    procedure
    begin
      LLibrary.GetSound(1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LLibrary.GetSound(2);
    end, EWarException);
end;

procedure TTestWarAudioLibrary.DovrebbeRicampionareEKeneIlSuono;
var
  LCatalog: TWarFakeCatalog;
  LArchive: TWarFakeArchive;
  LLibrary: IWarAudioLibrary;
  LFirst, LSecond: TWarPcmBuffer;
begin
  LCatalog := TWarFakeCatalog.Create;
  LArchive := TWarFakeArchive.Create;
  LCatalog.Put(1, wrtVoc);
  LCatalog.Put(2, wrtWave);
  LArchive.Put(1, TWarSyntheticAudio.Voc(9, 22050, 8, 1, 100));
  LArchive.Put(2, TWarSyntheticAudio.Wav(1, 11025, 8, 1, 50));
  LLibrary := TWarAudioLibrary.Create(LArchive, LCatalog, TWarFakeMusicConverter.Create);
  LFirst := LLibrary.GetSound(1);
  Assert.AreEqual<Integer>(200, Length(LFirst.Data));
  Assert.AreEqual<Cardinal>(WAR_PLAYBACK_RATE, LFirst.SampleRate);
  Assert.AreEqual<Integer>(200, Length(LLibrary.GetSound(2).Data));
  // the second time it is the same buffer (kept)
  LSecond := LLibrary.GetSound(1);
  Assert.IsTrue(Pointer(LFirst.Data) = Pointer(LSecond.Data));
end;

procedure TTestWarAudioLibrary.DovrebbeDareIlMidiDelConvertitore;
var
  LCatalog: TWarFakeCatalog;
  LArchive: TWarFakeArchive;
  LConverter: TWarFakeMusicConverter;
  LLibrary: IWarAudioLibrary;
  LHold: IWarMusicConverter;
begin
  LCatalog := TWarFakeCatalog.Create;
  LArchive := TWarFakeArchive.Create;
  LConverter := TWarFakeMusicConverter.Create;
  LHold := LConverter;
  LConverter.Output := TBytes.Create(9, 8, 7);
  LCatalog.Put(1, wrtXmid);
  LArchive.Put(1, TBytes.Create(1));
  LLibrary := TWarAudioLibrary.Create(LArchive, LCatalog, LHold);
  Assert.AreEqual<Integer>(8, LLibrary.GetMusic(1)[1]);
  Assert.AreEqual(1, LConverter.Calls);
end;

procedure TTestWarAudioLibrary.DovrebbeRifiutareUnRecordCheNonEUnBrano;
var
  LCatalog: TWarFakeCatalog;
  LLibrary: IWarAudioLibrary;
begin
  LCatalog := TWarFakeCatalog.Create;
  LCatalog.Put(1, wrtVoc);
  LLibrary := TWarAudioLibrary.Create(TWarFakeArchive.Create, LCatalog, TWarFakeMusicConverter.Create);
  Assert.WillRaise(
    procedure
    begin
      LLibrary.GetMusic(1);
    end, EWarException);
end;

procedure TTestWarAudioLibrary.DovrebbeRifiutareUnBranoCheNonSiConverte;
var
  LCatalog: TWarFakeCatalog;
  LArchive: TWarFakeArchive;
  LConverter: TWarFakeMusicConverter;
  LLibrary: IWarAudioLibrary;
  LHold: IWarMusicConverter;
begin
  LCatalog := TWarFakeCatalog.Create;
  LArchive := TWarFakeArchive.Create;
  LConverter := TWarFakeMusicConverter.Create;
  LHold := LConverter;
  LConverter.Succeeds := False;
  LCatalog.Put(1, wrtXmid);
  LArchive.Put(1, TBytes.Create(1));
  LLibrary := TWarAudioLibrary.Create(LArchive, LCatalog, LHold);
  Assert.WillRaise(
    procedure
    begin
      LLibrary.GetMusic(1);
    end, EWarException);
end;

procedure TTestWarAudioLibrary.DovrebbeRifiutareArgomentiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarAudioLibrary.Create(nil, TWarFakeCatalog.Create, TWarFakeMusicConverter.Create);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarAudioLibrary.Create(TWarFakeArchive.Create, nil, TWarFakeMusicConverter.Create);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarAudioLibrary.Create(TWarFakeArchive.Create, TWarFakeCatalog.Create, nil);
    end, EWarException);
end;

procedure TTestWarAudioLibrary.DovrebbeConvertireUnBranoXmiConIlConvertitoreDelMotore;
var
  LConverter: IWarMusicConverter;
  LMidi: TBytes;
  LXmi: TBytes;
begin
  // FORM XDIR / INFO, CAT XMID, FORM XMID, EVNT of 12 bytes: Program Change 5, Note On 60 velocity 100 lasting
  // 10, end of the track after a delay of 10
  LXmi := TBytes.Create(
    Ord('F'), Ord('O'), Ord('R'), Ord('M'), 0, 0, 0, 14, Ord('X'), Ord('D'), Ord('I'), Ord('R'),
    Ord('I'), Ord('N'), Ord('F'), Ord('O'), 0, 0, 0, 2, 1, 0,
    Ord('C'), Ord('A'), Ord('T'), Ord(' '), 0, 0, 0, 36, Ord('X'), Ord('M'), Ord('I'), Ord('D'),
    Ord('F'), Ord('O'), Ord('R'), Ord('M'), 0, 0, 0, 24, Ord('X'), Ord('M'), Ord('I'), Ord('D'),
    Ord('E'), Ord('V'), Ord('N'), Ord('T'), 0, 0, 0, 12,
    0, $C0, 5, 0, $90, 60, 100, 10, 10, $FF, $2F, 0);
  LConverter := TWarAudioFactory.CreateMusicConverter;
  Assert.IsTrue(LConverter.TryConvert(LXmi, LMidi));
  Assert.AreEqual<Integer>(Ord('M'), LMidi[0]);
  Assert.AreEqual<Integer>(Ord('T'), LMidi[1]);
  Assert.AreEqual(1, TWarMidiSummary.Of_(LMidi).NoteOn);
  Assert.AreEqual(1, TWarMidiSummary.Of_(LMidi).NoteOff);
  Assert.AreEqual(1, TWarMidiSummary.Of_(LMidi).Other);
end;

procedure TTestWarAudioLibrary.DovrebbeRifiutareChiNonEUnXmi;
var
  LConverter: IWarMusicConverter;
  LMidi: TBytes;
begin
  LConverter := TWarXmiMusicConverter.Create;
  Assert.IsFalse(LConverter.TryConvert(nil, LMidi));
  Assert.IsFalse(LConverter.TryConvert(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), LMidi));
end;

procedure TTestWarAudioLibrary.DovrebbeCreareLeClassiDallaFabbrica;
var
  LLibrary: IWarAudioLibrary;
  LMixer: IWarSoundMixer;
begin
  LLibrary := TWarAudioFactory.CreateLibrary(TWarFakeArchive.Create, TWarFakeCatalog.Create);
  Assert.IsNotNull(LLibrary);
  LMixer := TWarAudioFactory.CreateMixer(LLibrary);
  Assert.IsNotNull(LMixer);
  Assert.IsNotNull(TWarAudioFactory.CreatePcmSource(LMixer));
end;

end.
