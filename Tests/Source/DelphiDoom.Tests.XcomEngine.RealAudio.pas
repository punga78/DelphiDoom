{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the music of the xcom game on the real data of TFTD     }
{  (skipped when the game data is not there): the rules of the music, the       }
{  songs of ADLIB.CAT and the samples the mixer makes of them                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.RealAudio;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.ModGameLoader,
  DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Music.Intf,
  DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomAudio.ManualOutput, DelphiDoom.XcomAudio.Factory, DelphiDoom.Png.Provider;

type
  [TestFixture]
  [Category('XcomRealData')]
  TTestXcomRealAudio = class
  strict private
    FGameFolder: string;
    FDataFolder: string;
    FReady: Boolean;
    FResources: IXcomResources;
    FLanguage: TXcomLanguage;
    FOptions: TXcomOptions;
    FOutput: TXcomManualPcmOutput;
    FOutputRef: IXcomPcmOutput;
    FDevice: IXcomAudioDevice;
    FMusic: IXcomMusicPlayer;
    function Rms(const ABytes: TBytes): Double;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeRegoleDellaMusicaDiTftdSonoCaricate;
    [Test]
    procedure TuttiIBraniDelleRegoleSiCaricanoDaAdlibCat;
    [Test]
    procedure IlBranoDelMenuPrincipaleSuonaConUnRmsNonNullo;
    [Test]
    procedure OgniBranoAdlibDiTftdProduceSuono;
  end;

implementation

procedure TTestXcomRealAudio.Setup;
var
  LFolder: string;
  LReference: string;
  LSettings: TXcomLoaderSettings;
  LLoader: IXcomGameLoader;
begin
  FReady := False;
  LFolder := ExtractFilePath(ParamStr(0));
  while (LFolder <> '') and (LReference = '') do
  begin
    if TDirectory.Exists(TPath.Combine(LFolder, 'Reference\_dati\xcom_tftd\TFTD')) then
      LReference := TPath.Combine(LFolder, 'Reference');
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  if LReference = '' then
    Exit;
  FGameFolder := TPath.Combine(LReference, '_dati\xcom_tftd\TFTD');
  FDataFolder := TPath.Combine(LReference, 'OpenXcom\bin');
  if not TDirectory.Exists(TPath.Combine(FDataFolder, 'common')) then
    Exit;
  LSettings.DataFolder := FDataFolder;
  LSettings.GameFolder := FGameFolder;
  LSettings.ModId := 'xcom2';
  LSettings.LanguageId := 'en-US';
  LSettings.Wordwrap := twAuto;
  LLoader := TXcomModGameLoader.Create(LSettings, TXcomDiskFileSystem.Create, TYamlFactory.CreateParser,
    TPngProvider.Client);
  LLoader.Load(FResources, FLanguage);
  FOptions := TXcomOptions.Create;
  FOutput := TXcomManualPcmOutput.Create;
  FOutputRef := FOutput;
  TXcomAudioFactory.CreateAudio(FOptions, FOutputRef, 22050, FDevice, FMusic);
  FMusic.Reload(FResources);
  FReady := True;
end;

procedure TTestXcomRealAudio.TearDown;
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
  FLanguage.Free;
  FLanguage := nil;
  FResources := nil;
end;

function TTestXcomRealAudio.Rms(const ABytes: TBytes): Double;
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

procedure TTestXcomRealAudio.LeRegoleDellaMusicaDiTftdSonoCaricate;
var
  LRules: TArray<TXcomMusicRule>;
  LRule: TXcomMusicRule;
  LFound: Boolean;
begin
  if not FReady then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  LRules := FResources.MusicRules;
  Assert.IsTrue(Length(LRules) > 10, 'music rules: ' + IntToStr(Length(LRules)));
  LFound := False;
  for LRule in LRules do
    if LRule.MusicType = 'GMWAITLO' then
    begin
      LFound := True;
      Assert.AreEqual(2, LRule.CatPos);
      Assert.AreEqual('GMWAITLO', LRule.Name);
    end;
  Assert.IsTrue(LFound, 'GMWAITLO');
  Assert.AreEqual('GMWAITLO', FResources.GetInterface('mainMenu').Music, 'mainMenu music');
end;

procedure TTestXcomRealAudio.TuttiIBraniDelleRegoleSiCaricanoDaAdlibCat;
var
  LRules: TArray<TXcomMusicRule>;
  LCatPositions: Integer;
  LRule: TXcomMusicRule;
begin
  if not FReady then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  LRules := FResources.MusicRules;
  LCatPositions := 0;
  for LRule in LRules do
    if LRule.CatPos <> MaxInt then
      Inc(LCatPositions);
  Assert.IsTrue(LCatPositions > 0);
  Assert.AreEqual(LCatPositions, FMusic.LoadedCount);
end;

procedure TTestXcomRealAudio.IlBranoDelMenuPrincipaleSuonaConUnRmsNonNullo;
var
  LSamples: TBytes;
  LMeter: IXcomMixerMeter;
begin
  if not FReady then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  FDevice.SetVolume(84, 84, 84);
  FMusic.PlayMusic('GMWAITLO');
  Assert.IsTrue(FMusic.IsPlaying);
  Assert.AreEqual('Adlib', FMusic.CurrentFormat);
  LSamples := FOutput.Pump(22050 * 4);
  Assert.IsTrue(Rms(LSamples) > 50, 'rms ' + FloatToStr(Rms(LSamples)));
  LMeter := FDevice as IXcomMixerMeter;
  Assert.IsTrue(LMeter.Statistics.Peak > 500);
end;

procedure TTestXcomRealAudio.OgniBranoAdlibDiTftdProduceSuono;
var
  LRule: TXcomMusicRule;
  LSamples: TBytes;
  LSilent: string;
begin
  if not FReady then
  begin
    Assert.Pass('no real data');
    Exit;
  end;
  FDevice.SetVolume(84, 84, 84);
  LSilent := '';
  for LRule in FResources.MusicRules do
  begin
    if LRule.CatPos = MaxInt then
      Continue;
    FMusic.PlayMusic(LRule.MusicType, 0);
    LSamples := FOutput.Pump(22050 * 4);
    if Rms(LSamples) < 5 then
      LSilent := LSilent + ' ' + LRule.MusicType;
  end;
  // the intro songs that start with a silence can be quiet in the first second: only the tracks with no sound at all fail
  Assert.AreEqual('', LSilent);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealAudio);

end.
