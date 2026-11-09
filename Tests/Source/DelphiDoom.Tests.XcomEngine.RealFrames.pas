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
  DelphiDoom.XcomEngine.ModGameLoader, DelphiDoom.XcomEngine.FolderLanguageProvider,DelphiDoom.XcomEngine.DiskFileSystem, DelphiDoom.Png.Provider,
  DelphiDoom.XcomMenu.GoToMainMenuState,DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('XcomRealData')]
  TTestXcomRealFrames = class
  strict private
    FReference: string;
    FGameFolder: string;
    FDataFolder: string;
    function Hash(AWorld: TTestWorld): string;
    function Golden(const AName: string): string;
    /// <summary>Saves the frame as a BMP when the environment variable DD_XCOM_DUMP names a file (to look at a failure)</summary>
    procedure Dump(AWorld: TTestWorld; const AFileName: string);
    ///<summary>Opens the main menu on the real data, clicks the points of the steps ("x,y;x,y") and returns the hash</summary>
    function Render(const ASteps: string): string;
  public
    [Setup]
    procedure Setup;
    [Test]
    [TestCase('audio', 'audio,420:255;96:72')]
    [TestCase('audio_combo', 'audio_combo,420:255;96:72;520:116')]
    [TestCase('audio_mute', 'audio_mute,420:255;96:72;290:244;300:200')]
    [TestCase('audio_slider', 'audio_slider,420:255;96:72;300:32')]
    procedure LaSchermataELaStessaDiOpenXcomVero(const AName, ASteps: string);
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
  if not TDirectory.Exists(TPath.Combine(FDataFolder, 'common')) then
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

function TTestXcomRealFrames.Render(const ASteps: string): string;
var
  LWorld: TTestWorld;
  LLoader: IXcomGameLoader;
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
  LSettings: TXcomLoaderSettings;
  LStep: string;
  LPoint: TArray<string>;
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
    LWorld.Game.Options.MusicVolume := 0;
    LWorld.Game.Options.SoundVolume := 0;
    LWorld.Game.Options.UiVolume := 42;
    LWorld.Game.SetState(TXcomGoToMainMenuState.Create(LWorld.Game, '1.0 git 2026-06-05 22:05'));
    LWorld.Click(5000, 5000);
    LWorld.Wait(500);
    for LStep in ASteps.Split([';']) do
    begin
      LPoint := LStep.Split([':']);
      LWorld.Click(StrToInt(LPoint[0]), StrToInt(LPoint[1]));
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
  Assert.AreEqual(Golden(AName), Render(ASteps));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealFrames);

end.
