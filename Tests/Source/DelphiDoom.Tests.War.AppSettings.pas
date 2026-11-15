{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the settings that the program keeps  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppSettings;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Configuration.Intf, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.App.Settings;

type
  /// <summary>Warcraft32.ini: what is written, what is read and what is made of a file that someone edited</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppSettings = class(TObject)
  strict private
    FFormat: IConfigurationFormat;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireDalVolumePienoEConTuttoAcceso;
    [Test]
    procedure DovrebbeRileggereQuelloCheHaScritto;
    [Test]
    procedure DovrebbeScrivereLIntestazioneDegliAltriFileIni;
    [Test]
    procedure DovrebbeTenereIlValoreDiPartenzaPerQuelloCheManca;
    [Test]
    procedure DovrebbePortareUnVolumeFuoriLimiteDentroLimite;
    [Test]
    procedure DovrebbeRifiutareUnFileDiUnAltroProgramma;
    [Test]
    procedure DovrebbeRifiutareUnFileVuoto;
    [Test]
    procedure DovrebbeDareAlGiocoIVolumiEGliInterruttori;
    [Test]
    procedure DovrebbePrendereDalGiocoIVolumiArrotondati;
  end;

implementation

uses
  DelphiDoom.Configuration.Factory, DelphiDoom.War.Ui.GameSettings;

{ TTestWarAppSettings }

procedure TTestWarAppSettings.Setup;
begin
  FFormat := TConfigurationFactory.CreateFormat;
end;

procedure TTestWarAppSettings.TearDown;
begin
  FFormat := nil;
end;

procedure TTestWarAppSettings.DovrebbePartireDalVolumePienoEConTuttoAcceso;
var
  LSettings: TWarAppSettings;
begin
  LSettings := TWarAppSettings.Standard;
  Assert.AreEqual(100, LSettings.MusicVolume);
  Assert.AreEqual(100, LSettings.SoundVolume);
  Assert.IsTrue(LSettings.MusicEnabled);
  Assert.IsTrue(LSettings.SoundEnabled);
end;

procedure TTestWarAppSettings.DovrebbeRileggereQuelloCheHaScritto;
var
  LWritten: TWarAppSettings;
  LRead: TWarAppSettings;
begin
  LWritten.MusicVolume := 35;
  LWritten.SoundVolume := 80;
  LWritten.MusicEnabled := False;
  LWritten.SoundEnabled := True;
  Assert.IsTrue(TWarAppSettings.TryFromLines(FFormat, LWritten.ToLines(FFormat), LRead));
  Assert.AreEqual(35, LRead.MusicVolume);
  Assert.AreEqual(80, LRead.SoundVolume);
  Assert.IsFalse(LRead.MusicEnabled);
  Assert.IsTrue(LRead.SoundEnabled);
end;

procedure TTestWarAppSettings.DovrebbeScrivereLIntestazioneDegliAltriFileIni;
var
  LLines: TArray<string>;
begin
  LLines := TWarAppSettings.Standard.ToLines(FFormat);
  Assert.IsTrue(Length(LLines) > 4);
  Assert.AreEqual('[Warcraft32 ver 1.10]', LLines[0]);
end;

procedure TTestWarAppSettings.DovrebbeTenereIlValoreDiPartenzaPerQuelloCheManca;
var
  LRead: TWarAppSettings;
begin
  Assert.IsTrue(TWarAppSettings.TryFromLines(FFormat, ['[Warcraft32 ver 1.10]', 'musicvolume=40'], LRead));
  Assert.AreEqual(40, LRead.MusicVolume);
  Assert.AreEqual(100, LRead.SoundVolume);
  Assert.IsTrue(LRead.MusicEnabled);
end;

procedure TTestWarAppSettings.DovrebbePortareUnVolumeFuoriLimiteDentroLimite;
var
  LRead: TWarAppSettings;
begin
  Assert.IsTrue(TWarAppSettings.TryFromLines(FFormat, ['[Warcraft32 ver 1.10]', 'musicvolume=250',
    'soundvolume=-7'], LRead));
  Assert.AreEqual(100, LRead.MusicVolume);
  Assert.AreEqual(0, LRead.SoundVolume);
end;

procedure TTestWarAppSettings.DovrebbeRifiutareUnFileDiUnAltroProgramma;
var
  LRead: TWarAppSettings;
begin
  Assert.IsFalse(TWarAppSettings.TryFromLines(FFormat, ['[Doom32 ver 1.10]', 'musicvolume=10'], LRead));
  Assert.AreEqual(100, LRead.MusicVolume, 'le impostazioni di partenza');
end;

procedure TTestWarAppSettings.DovrebbeRifiutareUnFileVuoto;
var
  LRead: TWarAppSettings;
begin
  Assert.IsFalse(TWarAppSettings.TryFromLines(FFormat, [], LRead));
  Assert.AreEqual(100, LRead.SoundVolume);
end;

procedure TTestWarAppSettings.DovrebbeDareAlGiocoIVolumiEGliInterruttori;
var
  LSettings: TWarAppSettings;
  LGame: IWarGameSettings;
begin
  LGame := TWarGameSettings.Create;
  LSettings.MusicVolume := 25;
  LSettings.SoundVolume := 50;
  LSettings.MusicEnabled := False;
  LSettings.SoundEnabled := False;
  LSettings.ApplyTo(LGame);
  Assert.AreEqual(Double(0.25), Double(LGame.MusicVolume), 0.0001);
  Assert.AreEqual(Double(0.5), Double(LGame.SoundVolume), 0.0001);
  Assert.IsFalse(LGame.MusicEnabled);
  Assert.IsFalse(LGame.SoundEnabled);
end;

procedure TTestWarAppSettings.DovrebbePrendereDalGiocoIVolumiArrotondati;
var
  LGame: IWarGameSettings;
  LSettings: TWarAppSettings;
begin
  LGame := TWarGameSettings.Create;
  LGame.SetMusicVolume(0.35);
  LGame.SetSoundVolume(0.9);
  LGame.SoundEnabled := False;
  LSettings := TWarAppSettings.FromGame(LGame);
  Assert.AreEqual(35, LSettings.MusicVolume);
  Assert.AreEqual(90, LSettings.SoundVolume);
  Assert.IsFalse(LSettings.SoundEnabled);
  Assert.IsTrue(LSettings.MusicEnabled);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppSettings);

end.
