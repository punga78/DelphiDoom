{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the command line of Warcraft32       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppOptionsParser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Level.Types, DelphiDoom.War.App.Options,
  DelphiDoom.War.App.OptionsParser;

type
  /// <summary>The options of the program and the mistakes that the parser reports</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppOptionsParser = class(TObject)
  strict private
    function Parse(const AArguments: array of string; out AOptions: TWarAppOptions; out AError: string): Boolean;
  public
    [Test]
    procedure DovrebbeDareLeOpzioniDiPartenzaSenzaArgomenti;
    [Test]
    procedure DovrebbeLeggereLeCartelleEIFile;
    [Test]
    procedure DovrebbeLeggereLeOpzioniSenzaValore;
    [Test]
    procedure DovrebbeSuonareLaMusicaConIlMidiSenzaOpzioni;
    [Test]
    procedure DovrebbeLeggereLaSceltaDellaMusica;
    [Test]
    procedure DovrebbeRifiutareUnaMusicaSconosciutaOSenzaValore;
    [Test]
    procedure DovrebbeLeggereLaMissioneDaGiocare;
    [Test]
    procedure DovrebbeLeggereIlSemeEIFotogrammi;
    [Test]
    procedure DovrebbeNonDistinguereMaiuscoleEMinuscole;
    [Test]
    procedure DovrebbeRifiutareUnaOpzioneSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnaOpzioneSenzaValore;
    [Test]
    procedure DovrebbeRifiutareUnNumeroFuoriDalLimite;
    [Test]
    procedure DovrebbeRifiutareUnaRazzaOUnaMissioneSbagliata;
    [Test]
    procedure DovrebbeTenereLeOpzioniDiPartenzaPerQuelloCheNonHaLetto;
  end;

implementation

{ TTestWarAppOptionsParser }

function TTestWarAppOptionsParser.Parse(const AArguments: array of string; out AOptions: TWarAppOptions;
  out AError: string): Boolean;
var
  LArguments: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LArguments, Length(AArguments));
  for LIndex := 0 to High(AArguments) do
    LArguments[LIndex] := AArguments[LIndex];
  Result := TWarAppOptionsParser.TryParse(LArguments, AOptions, AError);
end;

procedure TTestWarAppOptionsParser.DovrebbeDareLeOpzioniDiPartenzaSenzaArgomenti;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse([], LOptions, LError));
  Assert.AreEqual('', LError);
  Assert.AreEqual('', LOptions.DataFolder);
  Assert.IsFalse(LOptions.Headless);
  Assert.IsFalse(LOptions.NoSound);
  Assert.IsFalse(LOptions.ShowHelp);
  Assert.AreEqual(0, LOptions.PlayMission);
  Assert.AreEqual<Cardinal>(WAR_APP_DEFAULT_SEED, LOptions.Seed);
  Assert.AreEqual(WAR_APP_DEFAULT_SCALE, LOptions.Scale);
  Assert.AreEqual(0, LOptions.QuitAfterFrames);
end;

procedure TTestWarAppOptionsParser.DovrebbeLeggereLeCartelleEIFile;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse(['-data', 'C:\Giochi\War', '-fonts', 'D:\Fonts', '-script', 'a.script', '-shot', 'a.png',
    '-load', 'in.sav', '-save', 'out.sav'], LOptions, LError));
  Assert.AreEqual('C:\Giochi\War', LOptions.DataFolder);
  Assert.AreEqual('D:\Fonts', LOptions.FontFolder);
  Assert.AreEqual('a.script', LOptions.ScriptPath);
  Assert.AreEqual('a.png', LOptions.ShotPath);
  Assert.AreEqual('in.sav', LOptions.LoadPath);
  Assert.AreEqual('out.sav', LOptions.SavePath);
end;

procedure TTestWarAppOptionsParser.DovrebbeLeggereLeOpzioniSenzaValore;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse(['-headless', '-nosound', '-audiostats', '-help'], LOptions, LError));
  Assert.IsTrue(LOptions.Headless);
  Assert.IsTrue(LOptions.NoSound);
  Assert.IsTrue(LOptions.AudioStatistics);
  Assert.IsTrue(LOptions.ShowHelp);
  Assert.IsTrue(Parse(['-?'], LOptions, LError));
  Assert.IsTrue(LOptions.ShowHelp);
end;

procedure TTestWarAppOptionsParser.DovrebbeSuonareLaMusicaConIlMidiSenzaOpzioni;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse([], LOptions, LError));
  Assert.IsTrue(LOptions.Music = wmmMidi);
end;

procedure TTestWarAppOptionsParser.DovrebbeLeggereLaSceltaDellaMusica;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse(['-music', 'none'], LOptions, LError));
  Assert.IsTrue(LOptions.Music = wmmNone);
  Assert.IsTrue(Parse(['-MUSIC', 'MIDI'], LOptions, LError));
  Assert.IsTrue(LOptions.Music = wmmMidi);
end;

procedure TTestWarAppOptionsParser.DovrebbeRifiutareUnaMusicaSconosciutaOSenzaValore;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsFalse(Parse(['-music', 'soundfont'], LOptions, LError));
  Assert.IsTrue(LError.Contains('soundfont'));
  Assert.IsFalse(Parse(['-music'], LOptions, LError));
  Assert.IsTrue(LError.Contains('-music'));
end;

procedure TTestWarAppOptionsParser.DovrebbeLeggereLaMissioneDaGiocare;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse(['-play', 'human', '3'], LOptions, LError));
  Assert.IsTrue(LOptions.PlayRace = wraHumans);
  Assert.AreEqual(3, LOptions.PlayMission);
  Assert.IsTrue(Parse(['-play', 'orc', '12'], LOptions, LError));
  Assert.IsTrue(LOptions.PlayRace = wraOrcs);
  Assert.AreEqual(12, LOptions.PlayMission);
  Assert.IsTrue(Parse(['-play', 'Orcs', '1'], LOptions, LError));
  Assert.IsTrue(LOptions.PlayRace = wraOrcs);
end;

procedure TTestWarAppOptionsParser.DovrebbeLeggereIlSemeEIFotogrammi;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse(['-seed', '4294967295', '-quitafter', '900', '-scale', '8'], LOptions, LError));
  Assert.AreEqual<Cardinal>(4294967295, LOptions.Seed);
  Assert.AreEqual(900, LOptions.QuitAfterFrames);
  Assert.AreEqual(8, LOptions.Scale);
end;

procedure TTestWarAppOptionsParser.DovrebbeNonDistinguereMaiuscoleEMinuscole;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(Parse(['-HEADLESS', '-Data', 'X'], LOptions, LError));
  Assert.IsTrue(LOptions.Headless);
  Assert.AreEqual('X', LOptions.DataFolder);
end;

procedure TTestWarAppOptionsParser.DovrebbeRifiutareUnaOpzioneSconosciuta;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsFalse(Parse(['-headless', '-boh'], LOptions, LError));
  Assert.IsTrue(LError.Contains('-boh'), LError);
end;

procedure TTestWarAppOptionsParser.DovrebbeRifiutareUnaOpzioneSenzaValore;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsFalse(Parse(['-data'], LOptions, LError));
  Assert.IsTrue(LError.Contains('-data'), LError);
  Assert.IsFalse(Parse(['-seed'], LOptions, LError));
  Assert.IsFalse(Parse(['-play', 'orc'], LOptions, LError));
end;

procedure TTestWarAppOptionsParser.DovrebbeRifiutareUnNumeroFuoriDalLimite;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsFalse(Parse(['-scale', '0'], LOptions, LError));
  Assert.IsTrue(LError.Contains('-scale'), LError);
  Assert.IsFalse(Parse(['-scale', '9'], LOptions, LError));
  Assert.IsFalse(Parse(['-scale', 'tre'], LOptions, LError));
  Assert.IsFalse(Parse(['-seed', '-1'], LOptions, LError));
  Assert.IsFalse(Parse(['-seed', '4294967296'], LOptions, LError));
  Assert.IsFalse(Parse(['-quitafter', '-5'], LOptions, LError));
end;

procedure TTestWarAppOptionsParser.DovrebbeRifiutareUnaRazzaOUnaMissioneSbagliata;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsFalse(Parse(['-play', 'elf', '1'], LOptions, LError));
  Assert.IsTrue(LError.Contains('-play'), LError);
  Assert.IsFalse(Parse(['-play', 'human', '0'], LOptions, LError));
  Assert.IsFalse(Parse(['-play', 'human', '13'], LOptions, LError));
  Assert.IsFalse(Parse(['-play', 'human', 'uno'], LOptions, LError));
end;

procedure TTestWarAppOptionsParser.DovrebbeTenereLeOpzioniDiPartenzaPerQuelloCheNonHaLetto;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  // dopo un errore le opzioni sono quelle di partenza: nessuna e' a meta'
  Assert.IsFalse(Parse(['-headless', '-scale', '99'], LOptions, LError));
  Assert.AreEqual(WAR_APP_DEFAULT_SCALE, LOptions.Scale);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppOptionsParser);

end.
