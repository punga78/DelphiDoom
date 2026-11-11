{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the music of the xcom game: the music player (the       }
{  rules and the choice of the track), the songs of the CAT files, the link     }
{  with the game and the factory (fakes: no device, no file of the original     }
{  game)                                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.AudioMusic;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomAdlib.Intf,
  DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomAudio.Mixer, DelphiDoom.XcomAudio.ManualOutput,
  DelphiDoom.XcomAudio.MusicPlayer, DelphiDoom.XcomAudio.CatSongs, DelphiDoom.XcomAudio.Factory,
  DelphiDoom.XcomAudio.OptionsSettings, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomEngine.AudioFakes;

type
  /// <summary>IXcomMusicSink that records the calls (and starts the track, as the mixer does)</summary>
  TSpySink = class(TInterfacedObject, IXcomMusicSink)
  public
    Track: IXcomMusicTrack;
    LastLoop: Integer;
    Plays: Integer;
    Stops: Integer;
    Paused: Boolean;
    procedure PlayTrack(const ATrack: IXcomMusicTrack; ALoop: Integer);
    procedure StopTrack;
    procedure PauseTrack(APaused: Boolean);
    function CurrentTrack: IXcomMusicTrack;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomMusicPlayer = class
  strict private
    FSettings: TFakeSettings;
    FSettingsRef: IXcomMusicSettings;
    FSink: TSpySink;
    FSinkRef: IXcomMusicSink;
    FPlayer: TFakeAdlibPlayer;
    FPlayerRef: IXcomAdlibPlayer;
    FSongs: TFakeSongs;
    FSongsRef: IXcomAdlibSongs;
    FResources: TFakeResources;
    FResourcesRef: IXcomResources;
    FMusic: IXcomMusicPlayer;
    FRandomMaximum: Integer;
    FRandomPick: Integer;
    function Rule(const AType: string; ACatPos: Integer): TXcomMusicRule;
    procedure Build(const ARules: TArray<TXcomMusicRule>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ReloadTieneSoloLeMusicheCheSiCaricano;
    [Test]
    procedure UnaMusicaOltreAdlibCatVieneDaAintroCat;
    [Test]
    procedure SenzaAdlibCatNonSiCaricaNulla;
    [Test]
    procedure UnWavDellaCartellaSoundVieneProvatoPrimaDiAdlib;
    [Test]
    procedure UnWavMalformatoNonSiCaricaEResta;
    [Test]
    procedure PlayMusicConIdUsaNomePiuId;
    [Test]
    procedure PlayMusicSenzaIdSceglieATestaTraLeMusicheDelNome;
    [Test]
    procedure LaStessaMusicaDueVolteNonRiparte;
    [Test]
    procedure UnaMusicaCheNonEsisteNonCambiaNulla;
    [Test]
    procedure ConMuteNonSuonaNulla;
    [Test]
    procedure GmstoryNonRipeteSeNonMusicAlwaysLoop;
    [Test]
    procedure GmstoryRipeteConMusicAlwaysLoop;
    [Test]
    procedure UnaMusicaNormaleRipeteSempre;
    [Test]
    procedure StopPausaERiprendiVannoAlMixer;
    [Test]
    procedure IlFormatoCorrenteESenzaMusicaAdlib;
    [Test]
    procedure IlFormatoCorrenteEQuelloDellaTraccia;
    [Test]
    procedure IlPlayerAdlibNascePrimaDelPrimoBrano;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomOptionsSettings = class
  public
    [Test]
    procedure LeggeMuteLoopEFormatoPreferitoDalleOpzioni;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomCatSongs = class
  strict private
    function MakeCat(const AName: string; const ASongs: TArray<TBytes>): TBytes;
  public
    [Test]
    procedure IBraniSiLeggonoConIlNomeDellaVoce;
    [Test]
    procedure SenzaContenitoriNonCiSonoBrani;
    [Test]
    procedure UnFileCortoNonEUnContenitore;
    [Test]
    procedure AintroCatEIndipendenteDaAdlibCat;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomGameMusic = class
  strict private
    FWorld: TTestWorld;
    FMusic: TFakeMusicPlayer;
    FMusicRef: IXcomMusicPlayer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LoStatoCheHaUnaMusicaNellInterfacciaLaAvvia;
    [Test]
    procedure PlayMusicDelGiocoVaAlPlayer;
    [Test]
    procedure ConMuteIlGiocoNonAvviaLaMusica;
    [Test]
    procedure IlGiocoRicaricaLeMusicheQuandoAdottaIDati;
    [Test]
    procedure ImpostareIlPlayerRicaricaSeCiSonoGiaIDati;
    [Test]
    procedure IlFormatoCorrenteVieneDalPlayer;
    [Test]
    procedure StopMusicFermaIlPlayer;
    [Test]
    procedure SenzaPlayerIlFormatoEAdlibENienteSuona;
    [Test]
    procedure IlVolumeDeiSuoniDelGiocoUsaLaCurvaEsponenziale;
  end;

  [TestFixture]
  [Category('XcomAudio')]
  TTestXcomAudioFactory = class
  public
    [Test]
    procedure LaFabbricaMetteInsiemeUnaMusicaCheSuonaDavvero;
    [Test]
    procedure SenzaUscitaIlDispositivoNonEDisponibile;
  end;

implementation

const
  RATE = 22050;

{ TSpySink }

procedure TSpySink.PlayTrack(const ATrack: IXcomMusicTrack; ALoop: Integer);
begin
  Inc(Plays);
  LastLoop := ALoop;
  if (Track <> nil) and (Track <> ATrack) then
    Track.Stop;
  Track := ATrack;
  Track.Start(ALoop);
end;

procedure TSpySink.StopTrack;
begin
  Inc(Stops);
  if Track <> nil then
    Track.Stop;
  Track := nil;
end;

procedure TSpySink.PauseTrack(APaused: Boolean);
begin
  Paused := APaused;
end;

function TSpySink.CurrentTrack: IXcomMusicTrack;
begin
  Result := Track;
end;

{ TTestXcomMusicPlayer }

procedure TTestXcomMusicPlayer.Setup;
begin
  FSettings := TFakeSettings.Create;
  FSettingsRef := FSettings;
  FSink := TSpySink.Create;
  FSinkRef := FSink;
  FPlayer := TFakeAdlibPlayer.Create;
  FPlayerRef := FPlayer;
  FSongs := TFakeSongs.Create;
  FSongsRef := FSongs;
  FResources := TFakeResources.Create;
  FResourcesRef := FResources;
  FRandomMaximum := -1;
  FRandomPick := 0;
  FMusic := TXcomMusicPlayer.Create(FSinkRef, FSettingsRef, RATE,
    function: IXcomAdlibPlayer
    begin
      Result := FPlayerRef;
    end,
    function(const AResources: IXcomResources): IXcomAdlibSongs
    begin
      Result := FSongsRef;
    end,
    function(AMaximum: Integer): Integer
    begin
      FRandomMaximum := AMaximum;
      Result := FRandomPick;
    end);
  FSongs.Songs := [TBytes.Create(1), TBytes.Create(2), TBytes.Create(3), TBytes.Create(4)];
end;

procedure TTestXcomMusicPlayer.TearDown;
begin
  FMusic := nil;
  FSink.Track := nil;
end;

function TTestXcomMusicPlayer.Rule(const AType: string; ACatPos: Integer): TXcomMusicRule;
begin
  Result.MusicType := AType;
  Result.Name := AType;
  Result.CatPos := ACatPos;
  Result.Normalization := 0.76;
end;

procedure TTestXcomMusicPlayer.Build(const ARules: TArray<TXcomMusicRule>);
begin
  FResources.Rules := ARules;
  FMusic.Reload(FResourcesRef);
end;

procedure TTestXcomMusicPlayer.ReloadTieneSoloLeMusicheCheSiCaricano;
begin
  Build([Rule('A', 0), Rule('B', 1), Rule('C', MaxInt), Rule('D', 7), Rule('E', -1)]);
  Assert.AreEqual(2, FMusic.LoadedCount);
  // a second Reload starts again from nothing
  Build([Rule('X', 3)]);
  Assert.AreEqual(1, FMusic.LoadedCount);
end;

procedure TTestXcomMusicPlayer.UnaMusicaOltreAdlibCatVieneDaAintroCat;
begin
  FSongs.Intro := [TBytes.Create(9, 9)];
  Build([Rule('INTRO', 4), Rule('PAST', 5)]);
  Assert.AreEqual(1, FMusic.LoadedCount);
  FMusic.PlayMusic('INTRO', 0);
  Assert.AreEqual(2, Length(FPlayer.Loaded));
  Assert.AreEqual(9, Integer(FPlayer.Loaded[0]));
end;

procedure TTestXcomMusicPlayer.SenzaAdlibCatNonSiCaricaNulla;
begin
  FSongs.Songs := nil;
  Build([Rule('A', 0)]);
  Assert.AreEqual(0, FMusic.LoadedCount);
  // and there is no player of Adlib to make
  FMusic.PlayMusic('A', 0);
  Assert.AreEqual(0, FSink.Plays);
end;

procedure TTestXcomMusicPlayer.UnWavDellaCartellaSoundVieneProvatoPrimaDiAdlib;
begin
  FResources.SoundFiles.Add('gmwav.wav', TWaveMaker.Constant(255, 100));
  Build([Rule('GMWAV', 0), Rule('GMADLIB', 1)]);
  Assert.AreEqual(2, FMusic.LoadedCount);
  FMusic.PlayMusic('GMWAV', 0);
  Assert.AreEqual('Wav', FMusic.CurrentFormat);
  FMusic.PlayMusic('GMADLIB', 0);
  Assert.AreEqual('Adlib', FMusic.CurrentFormat);
  Assert.AreEqual(2, Integer(FPlayer.Loaded[0]));
end;

procedure TTestXcomMusicPlayer.UnWavMalformatoNonSiCaricaEResta;
begin
  FResources.SoundFiles.Add('gma.wav', TBytes.Create(1, 2, 3, 4));
  Build([Rule('GMA', 0)]);
  // the bad file is not music: the Adlib song of the same rule is
  Assert.AreEqual(1, FMusic.LoadedCount);
  FMusic.PlayMusic('GMA', 0);
  Assert.AreEqual('Adlib', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicPlayer.PlayMusicConIdUsaNomePiuId;
begin
  Build([Rule('GMGEO1', 0), Rule('GMGEO2', 1), Rule('GMGEO', 2)]);
  FMusic.PlayMusic('GMGEO', 2);
  Assert.AreEqual(2, Integer(FPlayer.Loaded[0]));
  Assert.AreEqual(-1, FSink.LastLoop);
end;

procedure TTestXcomMusicPlayer.PlayMusicSenzaIdSceglieATestaTraLeMusicheDelNome;
begin
  Build([Rule('GMGEO1', 0), Rule('GMINTER1', 1), Rule('GMINTER2', 2), Rule('XGMINTER3', 3)]);
  FRandomPick := 1;
  FMusic.PlayMusic('GMINTER', 0);
  // three tracks have GMINTER in the name: the pick is from 0 to 2, and the second of them plays
  Assert.AreEqual(2, FRandomMaximum);
  Assert.AreEqual(3, Integer(FPlayer.Loaded[0]));
end;

procedure TTestXcomMusicPlayer.LaStessaMusicaDueVolteNonRiparte;
begin
  Build([Rule('GMGEO1', 0), Rule('GMINTER1', 1)]);
  FMusic.PlayMusic('GMGEO', 1);
  FMusic.PlayMusic('GMGEO', 1);
  Assert.AreEqual(1, FSink.Plays);
  FMusic.PlayMusic('GMINTER', 0);
  Assert.AreEqual(2, FSink.Plays);
  // the first one again is a change of name
  FMusic.PlayMusic('GMGEO', 1);
  Assert.AreEqual(3, FSink.Plays);
end;

procedure TTestXcomMusicPlayer.UnaMusicaCheNonEsisteNonCambiaNulla;
begin
  Build([Rule('GMGEO1', 0)]);
  FMusic.PlayMusic('NOPE', 3);
  FMusic.PlayMusic('NOPE', 0);
  Assert.AreEqual(0, FSink.Plays);
  // the name that failed is not remembered as the one that plays
  FMusic.PlayMusic('GMGEO', 1);
  Assert.AreEqual(1, FSink.Plays);
end;

procedure TTestXcomMusicPlayer.ConMuteNonSuonaNulla;
begin
  Build([Rule('GMGEO1', 0)]);
  FSettings.MuteOn := True;
  FMusic.PlayMusic('GMGEO', 1);
  Assert.AreEqual(0, FSink.Plays);
  // with mute on, no music is loaded at all
  FMusic.Reload(FResourcesRef);
  Assert.AreEqual(0, FMusic.LoadedCount);
end;

procedure TTestXcomMusicPlayer.GmstoryNonRipeteSeNonMusicAlwaysLoop;
begin
  Build([Rule('GMSTORY', 0), Rule('GMWIN', 1), Rule('GMLOSE', 2)]);
  FMusic.PlayMusic('GMSTORY', 0);
  Assert.AreEqual(0, FSink.LastLoop);
  FMusic.PlayMusic('GMWIN', 0);
  Assert.AreEqual(0, FSink.LastLoop);
  FMusic.PlayMusic('GMLOSE', 0);
  Assert.AreEqual(0, FSink.LastLoop);
end;

procedure TTestXcomMusicPlayer.GmstoryRipeteConMusicAlwaysLoop;
begin
  FSettings.LoopOn := True;
  Build([Rule('GMSTORY', 0)]);
  FMusic.PlayMusic('GMSTORY', 0);
  Assert.AreEqual(-1, FSink.LastLoop);
end;

procedure TTestXcomMusicPlayer.UnaMusicaNormaleRipeteSempre;
begin
  Build([Rule('GMGEO1', 0)]);
  FMusic.PlayMusic('GMGEO', 0);
  Assert.AreEqual(-1, FSink.LastLoop);
  Assert.IsTrue(FMusic.IsPlaying);
end;

procedure TTestXcomMusicPlayer.StopPausaERiprendiVannoAlMixer;
begin
  Build([Rule('GMGEO1', 0)]);
  FMusic.PlayMusic('GMGEO', 1);
  FMusic.Pause;
  Assert.IsTrue(FSink.Paused);
  FMusic.Resume;
  Assert.IsFalse(FSink.Paused);
  // (Reload stopped the sink once already)
  FMusic.Stop;
  Assert.AreEqual(2, FSink.Stops);
  Assert.IsFalse(FMusic.IsPlaying);
  // the C++ does not forget the name when the music stops: the same music is not started again
  FMusic.PlayMusic('GMGEO', 1);
  Assert.AreEqual(1, FSink.Plays);
end;

procedure TTestXcomMusicPlayer.IlFormatoCorrenteESenzaMusicaAdlib;
begin
  Assert.AreEqual('Adlib', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicPlayer.IlFormatoCorrenteEQuelloDellaTraccia;
begin
  FResources.SoundFiles.Add('gmw.wav', TWaveMaker.Constant(255, 100));
  Build([Rule('GMW', 0)]);
  FMusic.PlayMusic('GMW', 0);
  Assert.AreEqual('Wav', FMusic.CurrentFormat);
end;

procedure TTestXcomMusicPlayer.IlPlayerAdlibNascePrimaDelPrimoBrano;
var
  LMade: Integer;
  LMusic: IXcomMusicPlayer;
begin
  LMade := 0;
  LMusic := TXcomMusicPlayer.Create(FSinkRef, FSettingsRef, RATE,
    function: IXcomAdlibPlayer
    begin
      Inc(LMade);
      Result := FPlayerRef;
    end,
    function(const AResources: IXcomResources): IXcomAdlibSongs
    begin
      Result := FSongsRef;
    end);
  FResources.Rules := [Rule('A', 0), Rule('B', 1)];
  LMusic.Reload(FResourcesRef);
  // the two chips are made once, and shared by the songs
  Assert.AreEqual(1, LMade);
  LMusic.Stop;
end;

{ TTestXcomOptionsSettings }

procedure TTestXcomOptionsSettings.LeggeMuteLoopEFormatoPreferitoDalleOpzioni;
var
  LOptions: TXcomOptions;
  LSettings: IXcomMusicSettings;
begin
  LOptions := TXcomOptions.Create;
  try
    LSettings := TXcomOptionsMusicSettings.Create(LOptions);
    Assert.IsFalse(LSettings.Mute);
    Assert.IsFalse(LSettings.AlwaysLoop);
    Assert.AreEqual(0, LSettings.PreferredFormat);
    LOptions.Mute := True;
    LOptions.SetValue('musicAlwaysLoop', 1);
    LOptions.PreferredMusic := 5;
    Assert.IsTrue(LSettings.Mute);
    Assert.IsTrue(LSettings.AlwaysLoop);
    Assert.AreEqual(5, LSettings.PreferredFormat);
  finally
    LSettings := nil;
    LOptions.Free;
  end;
end;

{ TTestXcomCatSongs }

function TTestXcomCatSongs.MakeCat(const AName: string; const ASongs: TArray<TBytes>): TBytes;
var
  LIndex: Integer;
  LOffset: Cardinal;
  LEntry: TBytes;
begin
  // the index (offset and size of each entry), then the entries: a length byte, the name and the song
  SetLength(Result, Length(ASongs) * 8);
  LOffset := Length(ASongs) * 8;
  for LIndex := 0 to High(ASongs) do
  begin
    Move(LOffset, Result[LIndex * 8], 4);
    PCardinal(@Result[LIndex * 8 + 4])^ := Length(ASongs[LIndex]);
    LEntry := TBytes.Create(Length(AName)) + TEncoding.ASCII.GetBytes(AName) + ASongs[LIndex];
    Result := Result + LEntry;
    Inc(LOffset, Length(LEntry));
  end;
end;

procedure TTestXcomCatSongs.IBraniSiLeggonoConIlNomeDellaVoce;
var
  LResources: TFakeResources;
  LRef: IXcomResources;
  LSongs: IXcomAdlibSongs;
begin
  LResources := TFakeResources.Create;
  LRef := LResources;
  LResources.SoundFiles.Add('adlib.cat', MakeCat('ABC', [TBytes.Create(10, 11, 12), TBytes.Create(20)]));
  LSongs := TXcomCatSongs.FromResources(LRef);
  Assert.AreEqual(2, LSongs.Count);
  // the name stays: the sequencer reads its length (AdlibMusic is given CatFile::load(i, true))
  Assert.AreEqual(7, Length(LSongs.Song(0)));
  Assert.AreEqual(3, Integer(LSongs.Song(0)[0]));
  Assert.AreEqual(Integer(Ord('A')), Integer(LSongs.Song(0)[1]));
  Assert.AreEqual(10, Integer(LSongs.Song(0)[4]));
  Assert.AreEqual(5, Length(LSongs.Song(1)));
  Assert.AreEqual(0, LSongs.IntroCount);
end;

procedure TTestXcomCatSongs.SenzaContenitoriNonCiSonoBrani;
var
  LResources: TFakeResources;
  LRef: IXcomResources;
  LSongs: IXcomAdlibSongs;
begin
  LResources := TFakeResources.Create;
  LRef := LResources;
  LSongs := TXcomCatSongs.FromResources(LRef);
  Assert.AreEqual(0, LSongs.Count);
  Assert.AreEqual(0, LSongs.IntroCount);
end;

procedure TTestXcomCatSongs.UnFileCortoNonEUnContenitore;
var
  LResources: TFakeResources;
  LRef: IXcomResources;
  LSongs: IXcomAdlibSongs;
begin
  LResources := TFakeResources.Create;
  LRef := LResources;
  LResources.SoundFiles.Add('adlib.cat', TBytes.Create(1, 2, 3));
  LSongs := TXcomCatSongs.FromResources(LRef);
  Assert.AreEqual(0, LSongs.Count);
end;

procedure TTestXcomCatSongs.AintroCatEIndipendenteDaAdlibCat;
var
  LResources: TFakeResources;
  LRef: IXcomResources;
  LSongs: IXcomAdlibSongs;
begin
  LResources := TFakeResources.Create;
  LRef := LResources;
  LResources.SoundFiles.Add('aintro.cat', MakeCat('I', [TBytes.Create(5, 6)]));
  LSongs := TXcomCatSongs.FromResources(LRef);
  Assert.AreEqual(0, LSongs.Count);
  Assert.AreEqual(1, LSongs.IntroCount);
  Assert.AreEqual(4, Length(LSongs.IntroSong(0)));
end;

{ TTestXcomGameMusic }

procedure TTestXcomGameMusic.Setup;
begin
  FWorld := TTestWorld.Create;
  FMusic := TFakeMusicPlayer.Create;
  FMusicRef := FMusic;
  FWorld.Game.SetMusicPlayer(FMusicRef);
end;

procedure TTestXcomGameMusic.TearDown;
begin
  FWorld.Free;
  FMusicRef := nil;
end;

procedure TTestXcomGameMusic.LoStatoCheHaUnaMusicaNellInterfacciaLaAvvia;
begin
  FWorld.Game.SetState(TMusicState.Create(FWorld.Game));
  FWorld.Wait(50);
  Assert.IsTrue(FMusic.Names.IndexOf('GMTEST:0') >= 0);
end;

procedure TTestXcomGameMusic.PlayMusicDelGiocoVaAlPlayer;
begin
  FWorld.Game.PlayMusic('GMGEO', 3);
  Assert.AreEqual('GMGEO:3', FMusic.Names[0]);
end;

procedure TTestXcomGameMusic.ConMuteIlGiocoNonAvviaLaMusica;
begin
  FWorld.Game.Options.Mute := True;
  FWorld.Game.PlayMusic('GMGEO', 3);
  Assert.AreEqual(0, FMusic.Names.Count);
end;

procedure TTestXcomGameMusic.IlGiocoRicaricaLeMusicheQuandoAdottaIDati;
var
  LBefore: Integer;
begin
  LBefore := FMusic.Reloads;
  FWorld.Game.AdoptData(FWorld.Resources as IXcomResources, nil);
  Assert.AreEqual(LBefore + 1, FMusic.Reloads);
end;

procedure TTestXcomGameMusic.ImpostareIlPlayerRicaricaSeCiSonoGiaIDati;
begin
  // the world adopted its data before the player was set
  Assert.AreEqual(1, FMusic.Reloads);
end;

procedure TTestXcomGameMusic.IlFormatoCorrenteVieneDalPlayer;
begin
  Assert.AreEqual('Wav', FWorld.Game.CurrentMusicFormat);
end;

procedure TTestXcomGameMusic.StopMusicFermaIlPlayer;
begin
  FWorld.Game.StopMusic;
  Assert.AreEqual(1, FMusic.Stops);
end;

procedure TTestXcomGameMusic.SenzaPlayerIlFormatoEAdlibENienteSuona;
var
  LWorld: TTestWorld;
begin
  LWorld := TTestWorld.Create;
  try
    Assert.AreEqual('Adlib', LWorld.Game.CurrentMusicFormat);
    LWorld.Game.PlayMusic('GMGEO', 1);
    LWorld.Game.StopMusic;
    LWorld.Game.SetState(TMusicState.Create(LWorld.Game));
    LWorld.Wait(50);
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomGameMusic.IlVolumeDeiSuoniDelGiocoUsaLaCurvaEsponenziale;
var
  LOutput: TXcomManualPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LDevice: IXcomAudioDevice;
  LSamples: TBytes;
begin
  LOutput := TXcomManualPcmOutput.Create;
  LOutputRef := LOutput;
  LDevice := TXcomMixer.Create(LOutputRef, RATE);
  Assert.IsTrue((LDevice as IXcomMixerMeter).Open);
  FWorld.Game.SetAudioDevice(LDevice);
  FWorld.Resources.Wave := TWaveMaker.Constant(255, 50);
  FWorld.Game.PlaySound('GEO.CAT', 0);
  LSamples := LOutput.Pump(40);
  // the sound volume 84 is 48 of 128 on the curve of the game (the linear value would be 84): the sample 255 of
  // 8 bits becomes 128 + 127 * 48 / 128 = 175, that is (175 - 128) * 256 in 16 bits
  Assert.AreEqual(12032, Integer(SmallInt(LSamples[0] or (LSamples[1] shl 8))));
  LDevice := nil;
end;

{ TTestXcomAudioFactory }

procedure TTestXcomAudioFactory.LaFabbricaMetteInsiemeUnaMusicaCheSuonaDavvero;
var
  LOptions: TXcomOptions;
  LOutput: TXcomManualPcmOutput;
  LOutputRef: IXcomPcmOutput;
  LDevice: IXcomAudioDevice;
  LMusic: IXcomMusicPlayer;
  LResources: TFakeResources;
  LResourcesRef: IXcomResources;
  LRule: TXcomMusicRule;
  LSamples: TBytes;
begin
  LOptions := TXcomOptions.Create;
  LOutput := TXcomManualPcmOutput.Create;
  LOutputRef := LOutput;
  LResources := TFakeResources.Create;
  LResourcesRef := LResources;
  try
    TXcomAudioFactory.CreateAudio(LOptions, LOutputRef, RATE, LDevice, LMusic);
    Assert.IsTrue(LDevice.IsAvailable);
    Assert.AreEqual(RATE, LOutput.Rate);
    LRule.MusicType := 'GMW';
    LRule.Name := 'GMW';
    LRule.CatPos := MaxInt;
    LRule.Normalization := 0.76;
    LResources.Rules := [LRule];
    LResources.SoundFiles.Add('gmw.wav', TWaveMaker.Constant(255, 5000));
    LMusic.Reload(LResourcesRef);
    Assert.AreEqual(1, LMusic.LoadedCount);
    LMusic.PlayMusic('GMW', 0);
    Assert.IsTrue(LMusic.IsPlaying);
    LSamples := LOutput.Pump(400);
    // the music volume of the options (84) is 0.38 on the curve: 127 * 256 * 0.38 = 12428
    Assert.IsTrue(Abs(Integer(SmallInt(LSamples[0] or (LSamples[1] shl 8))) - 12428) <= 8);
    Assert.IsTrue((LDevice as IXcomMixerMeter).Statistics.Rms > 1000);
    LMusic.Stop;
    LDevice.Close;
  finally
    LMusic := nil;
    LDevice := nil;
    LOptions.Free;
  end;
end;

procedure TTestXcomAudioFactory.SenzaUscitaIlDispositivoNonEDisponibile;
var
  LOptions: TXcomOptions;
  LDevice: IXcomAudioDevice;
  LMusic: IXcomMusicPlayer;
begin
  LOptions := TXcomOptions.Create;
  try
    TXcomAudioFactory.CreateAudio(LOptions, TXcomManualPcmOutput.Create(False), RATE, LDevice, LMusic);
    Assert.IsFalse(LDevice.IsAvailable);
    Assert.IsFalse(LMusic.IsPlaying);
    Assert.AreEqual('Adlib', LMusic.CurrentFormat);
    LDevice.Close;
  finally
    LMusic := nil;
    LDevice := nil;
    LOptions.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMusicPlayer);
  TDUnitX.RegisterTestFixture(TTestXcomOptionsSettings);
  TDUnitX.RegisterTestFixture(TTestXcomCatSongs);
  TDUnitX.RegisterTestFixture(TTestXcomGameMusic);
  TDUnitX.RegisterTestFixture(TTestXcomAudioFactory);

end.
