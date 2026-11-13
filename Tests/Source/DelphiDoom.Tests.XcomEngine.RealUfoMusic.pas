{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the music of the xcom game against the real Mod of      }
{  OpenXcom (Tools\Verifica\176\battle\musicgen.cpp): which music of the rules  }
{  loads and from which song of ADLIB.CAT and AINTRO.CAT, on the real data of   }
{  UFO and of TFTD (skipped when the game data is not there)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.RealUfoMusic;

interface

uses
  DelphiDoom.Tests.Shared.Fnv,
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.ModGameLoader,
  DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Music.Intf,
  DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomAudio.ManualOutput, DelphiDoom.XcomAudio.Factory,
  DelphiDoom.XcomAudio.CatSongs, DelphiDoom.Png.Provider;

type
  [TestFixture]
  [Category('XcomRealData')]
  TTestXcomRealUfoMusic = class
  strict private
    FGoldenFolder: string;
    FReference: string;
    FResources: IXcomResources;
    FOptions: TXcomOptions;
    FOutput: TXcomManualPcmOutput;
    FOutputRef: IXcomPcmOutput;
    FDevice: IXcomAudioDevice;
    FMusic: IXcomMusicPlayer;
    function Open(const AGameFolder, AModId: string): Boolean;
    function Rms(const ABytes: TBytes): Double;
    function Fingerprint(const ABytes: TBytes): string;
    /// <summary>Compares what loaded with the lines of the real Mod; the number of musics that loaded</summary>
    function CheckMusic(const AGolden: string): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeMusicheDiUfoSonoQuelleCheCaricaIlVeroMod;
    [Test]
    procedure LeMusicheDiTftdSonoQuelleCheCaricaIlVeroMod;
    [Test]
    procedure OgniBranoAdlibDiUfoProduceSuono;
    [Test]
    procedure UnBranoDiUfoSenzaCatPosNonParte;
  end;

implementation

procedure TTestXcomRealUfoMusic.Setup;
var
  LFolder: string;
begin
  FGoldenFolder := '';
  FReference := '';
  LFolder := ExtractFilePath(ParamStr(0));
  while LFolder <> '' do
  begin
    if (FGoldenFolder = '') and TDirectory.Exists(TPath.Combine(LFolder, 'Tests\Data\XcomEngine\sounds')) then
      FGoldenFolder := TPath.Combine(LFolder, 'Tests\Data\XcomEngine\sounds');
    if (FReference = '') and TDirectory.Exists(TPath.Combine(LFolder, 'Reference\_dati')) then
      FReference := TPath.Combine(LFolder, 'Reference');
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
end;

procedure TTestXcomRealUfoMusic.TearDown;
begin
  if FMusic <> nil then
    FMusic.Stop;
  FMusic := nil;
  if FDevice <> nil then
    FDevice.Close;
  FDevice := nil;
  FOutputRef := nil;
  FOutput := nil;
  FOptions.Free;
  FOptions := nil;
  FResources := nil;
end;

function TTestXcomRealUfoMusic.Open(const AGameFolder, AModId: string): Boolean;
var
  LSettings: TXcomLoaderSettings;
  LLoader: IXcomGameLoader;
  LLanguage: TXcomLanguage;
begin
  Result := False;
  if (FReference = '') or (FGoldenFolder = '') then
    Exit;
  LSettings.DataFolder := TPath.Combine(FReference, 'OpenXcom\bin');
  LSettings.GameFolder := TPath.Combine(FReference, AGameFolder);
  if not (TDirectory.Exists(TPath.Combine(LSettings.DataFolder, 'common')) and
    TFile.Exists(TPath.Combine(LSettings.GameFolder, 'SOUND\ADLIB.CAT'))) then
    Exit;
  LSettings.ModId := AModId;
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLanguage := nil;
  LLoader.Load(FResources, LLanguage);
  LLanguage.Free;
  FOptions := TXcomOptions.Create;
  FOutput := TXcomManualPcmOutput.Create;
  FOutputRef := FOutput;
  TXcomAudioFactory.CreateAudio(FOptions, FOutputRef, 22050, FDevice, FMusic);
  FMusic.Reload(FResources);
  Result := True;
end;

function TTestXcomRealUfoMusic.Rms(const ABytes: TBytes): Double;
var
  LIndex: Integer;
  LSum: Double;
  LSamples: PSmallInt;
begin
  LSum := 0;
  LSamples := PSmallInt(@ABytes[0]);
  for LIndex := 0 to Length(ABytes) div 2 - 1 do
  begin
    LSum := LSum + Double(LSamples^) * LSamples^;
    Inc(LSamples);
  end;
  Result := Sqrt(LSum / (Length(ABytes) div 2));
end;

function TTestXcomRealUfoMusic.Fingerprint(const ABytes: TBytes): string;
begin
  Result := IntToHex(Int64(TTestFnv.Hash64(ABytes)), 16);
end;

function TTestXcomRealUfoMusic.CheckMusic(const AGolden: string): Integer;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LExpected: string;
  LLoaded: string;
  LType: string;
  LCatalog: IXcomMusicCatalog;
  LSongs: IXcomAdlibSongs;
  LRule: TXcomMusicRule;
  LSong: TBytes;
  LRules: Integer;
  LMissing: Integer;
  LRepeated: Integer;
begin
  Result := 0;
  LRepeated := 0;
  LRules := 0;
  LExpected := '';
  LSongs := TXcomCatSongs.FromResources(FResources);
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.Combine(FGoldenFolder, AGolden));
    for LLine in LLines do
    begin
      LParts := LLine.Split([' ']);
      if (Length(LParts) < 2) or (LParts[0] = 'set') or (LParts[0] = 'currentSound') then
        Continue;
      Inc(LRules);
      if LParts[1] = 'missing' then
        Continue;
      Assert.AreEqual('adlib', LParts[1], LParts[0] + ': the real game plays the Adlib song');
      LExpected := LExpected + ' ' + LParts[0];
      Inc(Result);
      // the song the real AdlibMusic was given: the catPos-th of ADLIB.CAT, or of AINTRO.CAT after the last one
      LSong := nil;
      for LRule in FResources.MusicRules do
        if LRule.MusicType = LParts[0] then
          if LRule.CatPos < LSongs.Count then
            LSong := LSongs.Song(LRule.CatPos)
          else
            LSong := LSongs.IntroSong(LRule.CatPos - LSongs.Count);
      // "music->load(cat->load(track, true), cat->getObjectSize(track))": the order of the two arguments is not
      // specified in C++, and the build of the harness (GCC) reads the size before load() adds the name to it;
      // AdlibMusic::load then adds the length of the name. So the size of the real AdlibMusic of a song with a
      // name (TFTD) is one byte less than the bytes that were read; the songs of UFO have no name and are whole.
      // What the player makes of the size is in Libs\Opl (TXcomAdlibPlayer.Load)
      // And CatFile::load(i, true) adds the name to the size of the entry every time it is called: the second
      // rule that plays the same song (GMISPOSH after GMINTER0 in TFTD) gets a song that goes on into the next
      // entry of the file, by the length of the name plus one. Those bytes are not compared
      LMissing := Length(LSong) - StrToInt(LParts[2]);
      if LSong[0] > 56 then
        Assert.AreEqual(0, LMissing, LParts[0] + ': bytes of a song without a name')
      else
        Assert.IsTrue((LMissing <= 1) and ((1 - LMissing) mod (LSong[0] + 1) = 0),
          Format('%s: bytes of the song %d, the real one %s', [LParts[0], Length(LSong), LParts[2]]));
      if LMissing >= 0 then
        Assert.AreEqual(LParts[3], Fingerprint(Copy(LSong, 0, StrToInt(LParts[2]))),
          LParts[0] + ': fingerprint of the song')
      else
        Inc(LRepeated);
    end;
  finally
    LLines.Free;
  end;
  Assert.AreEqual<Integer>(LRules, Length(FResources.MusicRules), 'rules of the music');
  Assert.IsTrue(LRepeated <= 1, 'songs loaded twice: ' + IntToStr(LRepeated));
  Assert.IsTrue(Supports(FMusic, IXcomMusicCatalog, LCatalog));
  LLoaded := '';
  for LType in LCatalog.Types do
    LLoaded := LLoaded + ' ' + LType;
  Assert.AreEqual(LExpected, LLoaded);
end;

procedure TTestXcomRealUfoMusic.LeMusicheDiUfoSonoQuelleCheCaricaIlVeroMod;
begin
  if not Open('_dati\xcom_ufo\UFO Enemy Unkown\DOS game', 'xcom1') then
  begin
    TTestSkip.Ignore('no real data');
    Exit;
  end;
  // 14 of the 32 rules: the others (GMGEO3..10, GMTACTIC1..10) have no catPos and UFO has no file for them
  Assert.AreEqual(14, CheckMusic('ufo_music.txt'));
end;

procedure TTestXcomRealUfoMusic.LeMusicheDiTftdSonoQuelleCheCaricaIlVeroMod;
begin
  if not Open('_dati\xcom_tftd\TFTD', 'xcom2') then
  begin
    TTestSkip.Ignore('no real data');
    Exit;
  end;
  Assert.AreEqual(23, CheckMusic('tftd_music.txt'));
end;

procedure TTestXcomRealUfoMusic.OgniBranoAdlibDiUfoProduceSuono;
var
  LCatalog: IXcomMusicCatalog;
  LType: string;
  LSilent: string;
  LCount: Integer;
begin
  if not Open('_dati\xcom_ufo\UFO Enemy Unkown\DOS game', 'xcom1') then
  begin
    TTestSkip.Ignore('no real data');
    Exit;
  end;
  Assert.IsTrue(Supports(FMusic, IXcomMusicCatalog, LCatalog));
  FDevice.SetVolume(84, 84, 84);
  LSilent := '';
  LCount := 0;
  for LType in LCatalog.Types do
  begin
    // the id picks the music by its whole type (GMGEO + 1), the name alone picks at random among those that hold it
    FMusic.Stop;
    FMusic.PlayMusic(LType, 0);
    Assert.IsTrue(FMusic.IsPlaying, LType + ' does not play');
    Inc(LCount);
    if Rms(FOutput.Pump(22050 * 4)) < 5 then
      LSilent := LSilent + ' ' + LType;
  end;
  Assert.AreEqual(14, LCount);
  Assert.AreEqual('', LSilent);
end;

procedure TTestXcomRealUfoMusic.UnBranoDiUfoSenzaCatPosNonParte;
begin
  if not Open('_dati\xcom_ufo\UFO Enemy Unkown\DOS game', 'xcom1') then
  begin
    TTestSkip.Ignore('no real data');
    Exit;
  end;
  FMusic.PlayMusic('GMGEO', 3);
  Assert.IsFalse(FMusic.IsPlaying, 'GMGEO3 has no song in UFO');
  FMusic.PlayMusic('GMTACTIC', 5);
  Assert.IsFalse(FMusic.IsPlaying, 'GMTACTIC5 has no song in UFO');
  // the name alone finds the only ones that loaded: GMGEO1 or GMGEO2, GMTACTIC
  FMusic.PlayMusic('GMGEO', 0);
  Assert.IsTrue(FMusic.IsPlaying);
  FMusic.Stop;
  FMusic.PlayMusic('GMTACTIC', 0);
  Assert.IsTrue(FMusic.IsPlaying);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealUfoMusic);

end.
