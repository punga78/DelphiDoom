{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom screens against frames of the real        }
{  OpenXcom (skipped when the game data is not there). Each case opens the     }
{  main menu and clicks through the steps; the hash of the frame must be the   }
{  one of the real game (Tests\Data\XcomEngine\frames.golden.txt)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.RealFrames;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Factory,
  DelphiDoom.Xcom.Types, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.Game,
  DelphiDoom.XcomEngine.ModGameLoader, DelphiDoom.XcomEngine.DiskSaveCatalog, DelphiDoom.XcomEngine.FolderLanguageProvider,DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.XcomEngine.DiskModCatalog, DelphiDoom.Png.Provider,
  DelphiDoom.XcomMenu.GoToMainMenuState,DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('XcomRealData')]
  TTestXcomRealFrames = class
  strict private
    FReference: string;
    FGameFolder: string;
    FDataFolder: string;
    FOptionsFile: string;
    FSaveFolder: string;
    function Hash(AWorld: TTestWorld): string;
    function Golden(const AName: string): string;
    /// <summary>Saves the frame as a BMP when the environment variable DD_XCOM_DUMP names a file (to look at a failure)</summary>
    procedure Dump(AWorld: TTestWorld; const AFileName: string);
    ///<summary>Opens the main menu on the real data, clicks the points of the steps ("x,y;x,y") and returns the hash</summary>
    function Render(const AName, ASteps: string): string;
  public
    [Setup]
    procedure Setup;
    [Test]
    [TestCase('audio', 'audio,420:255;96:72')]
    [TestCase('audio_combo', 'audio_combo,420:255;96:72;520:116')]
    [TestCase('audio_mute', 'audio_mute,420:255;96:72;290:244;300:200')]
    [TestCase('audio_slider', 'audio_slider,420:255;96:72;300:32')]
    [TestCase('controls', 'controls,420:255;96:112')]
    [TestCase('geoscape', 'geoscape,420:255;96:152')]
    [TestCase('battlescape', 'battlescape,420:255;96:192')]
    [TestCase('advanced', 'advanced,420:255;96:232')]
    [TestCase('controls_sel', 'controls_sel,420:255;96:112;300:88')]
    [TestCase('controls_scroll', 'controls_scroll,420:255;96:112;608:272:80:14')]
    [TestCase('controls_t1', 'controls_t1,420:255;96:112;608:200')]
    [TestCase('controls_t2', 'controls_t2,420:255;96:112;608:258')]
    [TestCase('controls_t3', 'controls_t3,420:255;96:112;608:150')]
    [TestCase('advanced_click', 'advanced_click,420:255;96:232;300:56;300:40;300:104;300:104')]
    [TestCase('load_empty', 'load_empty,230:255')]
    [TestCase('load_list', 'load_list,230:255')]
    [TestCase('battle_combo', 'battle_combo,420:255;96:192;300:36')]
    [TestCase('noaudio', 'noaudio,420:255;96:72;638:398')]
    [TestCase('load_confirm', 'load_confirm,230:255;100:107;638:398')]
    [TestCase('mods', 'mods,220:312;638:398')]
    [TestCase('mods_toggle', 'mods_toggle,220:312;100:106;638:398')]
    [TestCase('mods_arrow', 'mods_arrow,220:312;100:106;638:398;543:90;638:398')]
    procedure LaSchermataELaStessaDiOpenXcomVero(const AName, ASteps: string);
    [Test]
    procedure ISuoniDeiDatiVeriSonoFileWav;
  end;

implementation

procedure TTestXcomRealFrames.Setup;
var
  LFolder: string;
begin
  FReference := '';
  LFolder := ExtractFilePath(ParamStr(0));
  while (LFolder <> '') and (FReference = '') do
  begin
    if TDirectory.Exists(TPath.Combine(LFolder, 'Reference\_dati\xcom_tftd\TFTD')) then
      FReference := TPath.Combine(LFolder, 'Reference');
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  if FReference = '' then
    Exit;
  FGameFolder := TPath.Combine(FReference, '_dati\xcom_tftd\TFTD');
  FDataFolder := TPath.Combine(FReference, 'OpenXcom\bin');
  FSaveFolder := TPath.Combine(FReference, '_dati\xcom_tftd\saveseed176\xcom2');
  FOptionsFile := TPath.Combine(FReference, '_dati\xcom_tftd\openxcom_user\options.cfg');
  if not (TDirectory.Exists(TPath.Combine(FDataFolder, 'common')) and TFile.Exists(FOptionsFile) and TDirectory.Exists(FSaveFolder)) then
    FReference := '';
end;

function TTestXcomRealFrames.Hash(AWorld: TTestWorld): string;
var
  LHash: Cardinal;
  LIndex: Integer;
  LColor: TXcomColor;
begin
  LHash := 2166136261;
  for LIndex := 0 to Length(AWorld.Device.Pixels) - 1 do
  begin
    LColor := AWorld.Device.Palette[AWorld.Device.Pixels[LIndex]];
    LHash := (LHash xor LColor.Red) * 16777619;
    LHash := (LHash xor LColor.Green) * 16777619;
    LHash := (LHash xor LColor.Blue) * 16777619;
  end;
  Result := Format('%dx%d %s', [AWorld.Device.Width, AWorld.Device.Height, LowerCase(IntToHex(LHash, 8))]);
end;

function TTestXcomRealFrames.Golden(const AName: string): string;
var
  LFolder: string;
  LLine: string;
  LPath: string;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  LPath := '';
  while LFolder <> '' do
  begin
    if TFile.Exists(TPath.Combine(LFolder, 'Tests\Data\XcomEngine\frames.golden.txt')) then
    begin
      LPath := TPath.Combine(LFolder, 'Tests\Data\XcomEngine\frames.golden.txt');
      Break;
    end;
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Assert.IsTrue(LPath <> '', 'frames.golden.txt not found');
  for LLine in TFile.ReadAllLines(LPath) do
    if LLine.StartsWith(AName + ' ') then
      Exit(Copy(LLine, Length(AName) + 2, MaxInt).Trim);
  Result := '';
end;

procedure TTestXcomRealFrames.Dump(AWorld: TTestWorld; const AFileName: string);
var
  LStream: TFileStream;
  LRow: TBytes;
  LX: Integer;
  LY: Integer;
  LColor: TXcomColor;
  LHeader: array[0..53] of Byte;
  LSize: Cardinal;
begin
  if AFileName = '' then
    Exit;
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader[0] := Ord('B');
  LHeader[1] := Ord('M');
  LSize := 54 + Cardinal(AWorld.Device.Width * AWorld.Device.Height * 3);
  Move(LSize, LHeader[2], 4);
  LHeader[10] := 54;
  LHeader[14] := 40;
  PInteger(@LHeader[18])^ := AWorld.Device.Width;
  PInteger(@LHeader[22])^ := AWorld.Device.Height;
  LHeader[26] := 1;
  LHeader[28] := 24;
  SetLength(LRow, AWorld.Device.Width * 3);
  LStream := TFileStream.Create(AFileName + '.bmp', fmCreate);
  try
    LStream.WriteBuffer(LHeader, SizeOf(LHeader));
    for LY := AWorld.Device.Height - 1 downto 0 do
    begin
      for LX := 0 to AWorld.Device.Width - 1 do
      begin
        LColor := AWorld.Device.Palette[AWorld.Device.Pixels[LY * AWorld.Device.Width + LX]];
        LRow[LX * 3] := LColor.Blue;
        LRow[LX * 3 + 1] := LColor.Green;
        LRow[LX * 3 + 2] := LColor.Red;
      end;
      LStream.WriteBuffer(LRow[0], Length(LRow));
    end;
  finally
    LStream.Free;
  end;
end;

function TTestXcomRealFrames.Render(const AName, ASteps: string): string;
var
  LWorld: TTestWorld;
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
  LSettings: TXcomLoaderSettings;
  LStep: string;
  LPoint: TArray<string>;
  LRepeat: Integer;
begin
  LSettings.DataFolder := FDataFolder;
  LSettings.GameFolder := FGameFolder;
  LSettings.ModId := 'xcom2';
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLoader.Load(LResources, LLanguage);
  LWorld := TTestWorld.Create;
  try
    LWorld.Game.AdoptData(LResources, LLanguage);
    // the options.cfg of the real game that made the frames
    LWorld.Game.Options.DisplayWidth := 640;
    LWorld.Game.Options.DisplayHeight := 400;
    LWorld.Game.Options.BaseXResolution := 640;
    LWorld.Game.Options.BaseYResolution := 400;
    LWorld.Game.Screen.ResetDisplay;
    LWorld.Game.SetLanguageProvider(TXcomFolderLanguageProvider.Create(FDataFolder,
      TPath.Combine(TPath.Combine(FDataFolder, 'standard'), 'xcom2'), TXcomDiskFileSystem.Create,
      TYamlFactory.CreateParser));
    // the saves of the seed folder (made for the comparison; their dates are fixed) for the case load_list
    if AName = 'load_list' then
      LWorld.Game.SetSaveCatalog(TXcomDiskSaveCatalog.Create(FSaveFolder, 'xcom2', TYamlFactory.CreateParser));
    // the mods of the data folder: the Mods screen
    if AName.StartsWith('mods') then
      LWorld.Game.SetModCatalog(TXcomDiskModCatalog.Create([TPath.Combine(FDataFolder, 'standard')], ['xcom2'],
        TYamlFactory.CreateParser));
    // two saves, one of them needs a mod that is not active (saveseed176b)
    if AName = 'load_confirm' then
      LWorld.Game.SetSaveCatalog(TXcomDiskSaveCatalog.Create(
        TPath.Combine(FReference, '_dati\xcom_tftd\saveseed176b\xcom2'), 'xcom2', TYamlFactory.CreateParser));
    LWorld.Game.Options.Load(TYamlFactory.CreateParser.Load(TFile.ReadAllBytes(FOptionsFile)));
    // the real game with SDL_AUDIODRIVER set to a driver that does not exist: no audio, Options::mute
    if AName = 'noaudio' then
      LWorld.Game.Options.Mute := True;
    LWorld.Game.SetState(TXcomGoToMainMenuState.Create(LWorld.Game, '1.0 git 2026-06-05 22:05'));
    LWorld.Click(5000, 5000);
    LWorld.Wait(500);
    for LStep in ASteps.Split([';']) do
    begin
      LPoint := LStep.Split([':']);
      // x:y is a click, x:y:n holds the button down for n milliseconds, x:y:n:r repeats it r times
      if Length(LPoint) = 2 then
        LWorld.Click(StrToInt(LPoint[0]), StrToInt(LPoint[1]))
      else
        for LRepeat := 1 to StrToInt(LPoint[3]) do
        begin
          LWorld.ClickHeld(StrToInt(LPoint[0]), StrToInt(LPoint[1]), StrToInt(LPoint[2]));
          LWorld.Wait(300);
        end;
      LWorld.Wait(300);
    end;
    Result := Hash(LWorld);
    Dump(LWorld, GetEnvironmentVariable('DD_XCOM_DUMP'));
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomRealFrames.LaSchermataELaStessaDiOpenXcomVero(const AName, ASteps: string);
begin
  if FReference = '' then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  Assert.AreEqual(Golden(AName), Render(AName, ASteps));
end;

procedure TTestXcomRealFrames.ISuoniDeiDatiVeriSonoFileWav;
var
  LSettings: TXcomLoaderSettings;
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
  LWave: TBytes;
  LSet: Integer;
begin
  if FReference = '' then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  LSettings.DataFolder := FDataFolder;
  LSettings.GameFolder := FGameFolder;
  LSettings.ModId := 'xcom2';
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLoader.Load(LResources, LLanguage);
  try
    Assert.AreEqual(5, LResources.Constant('ufoFire', 8));
    Assert.AreEqual(0, LResources.Constant('buttonPress', 9));
    Assert.AreEqual(77, LResources.Constant('nope', 77));
    // the press of a button is the entry 120 of SAMPLE.CAT: an 8 bit mono WAV file at 11025 Hz
    for LSet in [0, 5] do
    begin
      LWave := LResources.SoundWave('GEO.CAT', LSet);
      Assert.IsTrue(Length(LWave) > 1000, 'sound ' + IntToStr(LSet));
      Assert.AreEqual('RIFF', TEncoding.ASCII.GetString(LWave, 0, 4));
      Assert.AreEqual(Integer(Length(LWave) - 44), Integer(PCardinal(@LWave[40])^));
    end;
    Assert.AreEqual(0, Integer(Length(LResources.SoundWave('GEO.CAT', 9999))));
    Assert.AreEqual(0, Integer(Length(LResources.SoundWave('NOPE.CAT', 0))));
  finally
    LLanguage.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealFrames);

end.
