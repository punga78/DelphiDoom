{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TLauncherEngines                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Launcher.Engines;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Launcher.Engines;

type
  [TestFixture]
  [Category('launcher')]
  TTestLauncherEngines = class(TObject)
  strict private
    FFiles: TStringList;
    function Exists: TLauncherFileExists;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('doom', '0,Doom,doom\')]
    [TestCase('heretic', '1,Heretic,heretic\')]
    [TestCase('hexen', '2,Hexen,hexen\')]
    [TestCase('strife', '3,Strife,strife\')]
    [TestCase('radix', '4,Radix,radix\')]
    [TestCase('nessuno', '5,,')]
    [TestCase('negativo', '-1,,')]
    procedure DovrebbeDareNomeECartellaDiOgniMotore(AEngine: Integer; const AName, AFolder: string);
    [Test]
    [TestCase('come nel gruppo', 'Radix,4')]
    [TestCase('minuscolo', 'radix,4')]
    [TestCase('con spazi', ' HEXEN ,2')]
    [TestCase('doom', 'doom,0')]
    [TestCase('sconosciuto', 'quake,-1')]
    [TestCase('vuoto', ',-1')]
    procedure DovrebbeTrovareUnMotoreDalNome(const AName: string; AExpected: Integer);
    [Test]
    [TestCase('doom software', '0,False,doom32.exe')]
    [TestCase('doom opengl', '0,True,gldoom32.exe')]
    [TestCase('heretic opengl', '1,True,glheretic32.exe')]
    [TestCase('hexen software', '2,False,hexen32.exe')]
    [TestCase('strife opengl', '3,True,glstrife32.exe')]
    [TestCase('radix software', '4,False,radix32.exe')]
    [TestCase('radix non ha opengl', '4,True,radix32.exe')]
    [TestCase('nessun motore', '6,False,')]
    [TestCase('nessun motore opengl', '-1,True,')]
    procedure DovrebbeDareIlProgrammaDiUnMotore(AEngine: Integer; AOpenGl: Boolean; const AExpected: string);
    [Test]
    procedure SoloRadixNonDovrebbeAvereOpenGl;
    [Test]
    procedure IlProgrammaDovrebbeEssereCercatoPrimaNellaCartellaDeiDati;
    [Test]
    procedure IlProgrammaDovrebbeEssereTrovatoAccantoAlLauncher;
    [Test]
    procedure IlProgrammaDovrebbeEssereTrovatoNellaCartellaDelLauncher;
    [Test]
    procedure UnProgrammaCheNonCEDovrebbeRestareUnNomeNudo;
    [Test]
    procedure SenzaCartelleDovrebbeRestareUnNomeNudo;
    [Test]
    procedure NessunMotoreNonDovrebbeAvereUnProgramma;
    [Test]
    procedure SenzaLaFunzioneDeiFileDovrebbeEssereUnErrore;
    [Test]
    [TestCase('doom2', 'DOOM2.WAD,0')]
    [TestCase('doom shareware', 'doom1.wad,0')]
    [TestCase('heretic', 'Heretic1.wad,1')]
    [TestCase('hexen', 'HEXEN.WAD,2')]
    [TestCase('strife', 'strife0.wad,3')]
    [TestCase('radix', 'RADIX.DAT,4')]
    [TestCase('radix con percorso', 'C:\Games\Radix\radix.dat,4')]
    [TestCase('pwad', 'mymap.wad,-1')]
    [TestCase('nome simile', 'radix.dat.bak,-1')]
    [TestCase('vuoto', ',-1')]
    procedure DovrebbeRiconoscereIlMotoreDalFileDeiDati(const AFileName: string; AExpected: Integer);
    [Test]
    procedure IlFileDeiDatiPredefinitoDovrebbeEssereIlPrimoCheCE;
    [Test]
    procedure IlMotorePredefinitoDovrebbeEssereIlPrimoConIDati;
    [Test]
    procedure SenzaDatiIlMotorePredefinitoDovrebbeEssereDoom;
    [Test]
    procedure RadixDovrebbeAvereLeSueMappeSenzaLeggereUnWad;
    [Test]
    procedure LeMaschereDovrebberoDistinguereIDatiDiRadix;
    [Test]
    [TestCase('doom', '0,4,6,&Run DelphiDoom')]
    [TestCase('heretic', '1,4,6,&Run DelphiHeretic')]
    [TestCase('hexen', '2,8,8,&Run DelphiHexen')]
    [TestCase('strife', '3,8,6,&Run DelphiStrife')]
    [TestCase('radix', '4,4,6,&Run Radix')]
    [TestCase('nessuno', '9,4,6,')]
    procedure DovrebbeDareGiocatoriZonaEVoceDiMenu(AEngine, APlayers, AZone: Integer; const ACaption: string);
    [Test]
    procedure DovrebbeMettereTraVirgoletteSoloCioCheHaUnoSpazio;
  end;

implementation

const
  LAUNCHER_FOLDER = 'C:\dd\bin\Win32\Release\';
  DATA_FOLDER = 'C:\dd\bin\radix\';

{ TTestLauncherEngines }

procedure TTestLauncherEngines.Setup;
begin
  FFiles := TStringList.Create;
  FFiles.CaseSensitive := False;
end;

procedure TTestLauncherEngines.TearDown;
begin
  FFiles.Free;
end;

function TTestLauncherEngines.Exists: TLauncherFileExists;
begin
  Result :=
    function(const AFileName: string): Boolean
    begin
      Result := FFiles.IndexOf(AFileName) >= 0;
    end;
end;

procedure TTestLauncherEngines.DovrebbeDareNomeECartellaDiOgniMotore(AEngine: Integer; const AName, AFolder: string);
begin
  Assert.AreEqual(AName, TLauncherEngines.Name(AEngine));
  Assert.AreEqual(AFolder, TLauncherEngines.Folder(AEngine));
  Assert.AreEqual(AName <> '', TLauncherEngines.IsEngine(AEngine));
end;

procedure TTestLauncherEngines.DovrebbeTrovareUnMotoreDalNome(const AName: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TLauncherEngines.IndexOfName(AName));
end;

procedure TTestLauncherEngines.DovrebbeDareIlProgrammaDiUnMotore(AEngine: Integer; AOpenGl: Boolean;
  const AExpected: string);
begin
  Assert.AreEqual(AExpected, TLauncherEngines.Executable(AEngine, AOpenGl));
end;

procedure TTestLauncherEngines.SoloRadixNonDovrebbeAvereOpenGl;
var
  LEngine: Integer;
begin
  for LEngine := 0 to TLauncherEngines.COUNT - 1 do
    Assert.AreEqual(LEngine <> TLauncherEngines.RADIX, TLauncherEngines.HasOpenGl(LEngine),
      TLauncherEngines.Name(LEngine));
  Assert.IsFalse(TLauncherEngines.HasOpenGl(TLauncherEngines.NONE));
end;

procedure TTestLauncherEngines.IlProgrammaDovrebbeEssereCercatoPrimaNellaCartellaDeiDati;
begin
  FFiles.Add(DATA_FOLDER + 'radix32.exe');
  FFiles.Add(LAUNCHER_FOLDER + 'radix\radix32.exe');
  Assert.AreEqual(DATA_FOLDER + 'radix32.exe',
    TLauncherEngines.ExecutablePath(TLauncherEngines.RADIX, False, LAUNCHER_FOLDER, DATA_FOLDER, Exists()));
end;

procedure TTestLauncherEngines.IlProgrammaDovrebbeEssereTrovatoAccantoAlLauncher;
begin
  FFiles.Add(LAUNCHER_FOLDER + 'radix\radix32.exe');
  FFiles.Add(LAUNCHER_FOLDER + 'doom\gldoom32.exe');
  // the folders are given without their last separator too
  Assert.AreEqual(LAUNCHER_FOLDER + 'radix\radix32.exe',
    TLauncherEngines.ExecutablePath(TLauncherEngines.RADIX, True, 'C:\dd\bin\Win32\Release', 'C:\dd\bin\radix',
      Exists()));
  Assert.AreEqual(LAUNCHER_FOLDER + 'doom\gldoom32.exe',
    TLauncherEngines.ExecutablePath(TLauncherEngines.DOOM, True, LAUNCHER_FOLDER, 'C:\dd\bin\doom\', Exists()));
end;

procedure TTestLauncherEngines.IlProgrammaDovrebbeEssereTrovatoNellaCartellaDelLauncher;
begin
  FFiles.Add(LAUNCHER_FOLDER + 'hexen32.exe');
  Assert.AreEqual(LAUNCHER_FOLDER + 'hexen32.exe',
    TLauncherEngines.ExecutablePath(TLauncherEngines.HEXEN, False, LAUNCHER_FOLDER, 'C:\dd\bin\hexen\', Exists()));
end;

procedure TTestLauncherEngines.UnProgrammaCheNonCEDovrebbeRestareUnNomeNudo;
begin
  FFiles.Add(LAUNCHER_FOLDER + 'doom\doom32.exe');
  Assert.AreEqual('gldoom32.exe',
    TLauncherEngines.ExecutablePath(TLauncherEngines.DOOM, True, LAUNCHER_FOLDER, 'C:\dd\bin\doom\', Exists()));
end;

procedure TTestLauncherEngines.SenzaCartelleDovrebbeRestareUnNomeNudo;
begin
  FFiles.Add('strife32.exe');
  Assert.AreEqual('strife32.exe',
    TLauncherEngines.ExecutablePath(TLauncherEngines.STRIFE, False, '', '', Exists()));
end;

procedure TTestLauncherEngines.NessunMotoreNonDovrebbeAvereUnProgramma;
begin
  Assert.AreEqual('', TLauncherEngines.ExecutablePath(TLauncherEngines.NONE, False, LAUNCHER_FOLDER, DATA_FOLDER,
    Exists()));
  Assert.AreEqual('', TLauncherEngines.ExecutablePath(TLauncherEngines.COUNT + 1, True, LAUNCHER_FOLDER, DATA_FOLDER,
    Exists()));
end;

procedure TTestLauncherEngines.SenzaLaFunzioneDeiFileDovrebbeEssereUnErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      TLauncherEngines.ExecutablePath(TLauncherEngines.DOOM, False, LAUNCHER_FOLDER, DATA_FOLDER, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TLauncherEngines.DefaultDataFile(TLauncherEngines.DOOM, nil);
    end, EArgumentNilException);
end;

procedure TTestLauncherEngines.DovrebbeRiconoscereIlMotoreDalFileDeiDati(const AFileName: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TLauncherEngines.EngineOfDataFile(AFileName));
end;

procedure TTestLauncherEngines.IlFileDeiDatiPredefinitoDovrebbeEssereIlPrimoCheCE;
begin
  Assert.AreEqual('', TLauncherEngines.DefaultDataFile(TLauncherEngines.DOOM, Exists()));
  FFiles.Add('doom1.wad');
  Assert.AreEqual('doom1.wad', TLauncherEngines.DefaultDataFile(TLauncherEngines.DOOM, Exists()));
  FFiles.Add('DOOM2.WAD');
  Assert.AreEqual('doom2.wad', TLauncherEngines.DefaultDataFile(TLauncherEngines.DOOM, Exists()));
  FFiles.Add('strife0.wad');
  FFiles.Add('strife1.wad');
  Assert.AreEqual('strife1.wad', TLauncherEngines.DefaultDataFile(TLauncherEngines.STRIFE, Exists()));
  Assert.AreEqual('', TLauncherEngines.DefaultDataFile(TLauncherEngines.RADIX, Exists()));
  FFiles.Add('RADIX.DAT');
  Assert.AreEqual('radix.dat', TLauncherEngines.DefaultDataFile(TLauncherEngines.RADIX, Exists()));
  Assert.AreEqual('', TLauncherEngines.DefaultDataFile(TLauncherEngines.NONE, Exists()));
end;

procedure TTestLauncherEngines.IlMotorePredefinitoDovrebbeEssereIlPrimoConIDati;
begin
  FFiles.Add('radix.dat');
  Assert.AreEqual(TLauncherEngines.RADIX, TLauncherEngines.DefaultEngine(Exists()));
  FFiles.Add('hexen1.wad');
  Assert.AreEqual(TLauncherEngines.HEXEN, TLauncherEngines.DefaultEngine(Exists()));
  FFiles.Add('tnt.wad');
  Assert.AreEqual(TLauncherEngines.DOOM, TLauncherEngines.DefaultEngine(Exists()));
end;

procedure TTestLauncherEngines.SenzaDatiIlMotorePredefinitoDovrebbeEssereDoom;
begin
  Assert.AreEqual(TLauncherEngines.DOOM, TLauncherEngines.DefaultEngine(Exists()));
end;

procedure TTestLauncherEngines.RadixDovrebbeAvereLeSueMappeSenzaLeggereUnWad;
var
  LNames: TArray<string>;
  LEngine: Integer;
begin
  LNames := TLauncherEngines.BuiltInMapNames(TLauncherEngines.RADIX);
  Assert.AreEqual<Integer>(27, Length(LNames));
  Assert.AreEqual('E1M1', LNames[0]);
  Assert.AreEqual('E1M9', LNames[8]);
  Assert.AreEqual('E2M1', LNames[9]);
  Assert.AreEqual('E3M9', LNames[26]);
  Assert.IsFalse(TLauncherEngines.MainDataIsWad(TLauncherEngines.RADIX));
  for LEngine := TLauncherEngines.DOOM to TLauncherEngines.STRIFE do
  begin
    Assert.IsTrue(TLauncherEngines.MainDataIsWad(LEngine));
    Assert.AreEqual<Integer>(0, Length(TLauncherEngines.BuiltInMapNames(LEngine)));
  end;
  // an unknown engine is read as the Launcher has always done
  Assert.IsTrue(TLauncherEngines.MainDataIsWad(TLauncherEngines.NONE));
end;

procedure TTestLauncherEngines.LeMaschereDovrebberoDistinguereIDatiDiRadix;
begin
  Assert.AreEqual('*.dat', TLauncherEngines.MainDataMask(TLauncherEngines.RADIX));
  Assert.AreEqual('*.wad', TLauncherEngines.MainDataMask(TLauncherEngines.DOOM));
  Assert.AreEqual('*.wad', TLauncherEngines.MainDataMask(TLauncherEngines.NONE));
end;

procedure TTestLauncherEngines.DovrebbeDareGiocatoriZonaEVoceDiMenu(AEngine, APlayers, AZone: Integer;
  const ACaption: string);
begin
  Assert.AreEqual(APlayers, TLauncherEngines.MaxPlayers(AEngine));
  Assert.AreEqual(AZone, TLauncherEngines.MinZoneSize(AEngine));
  Assert.AreEqual(ACaption, TLauncherEngines.RunCaption(AEngine));
end;

procedure TTestLauncherEngines.DovrebbeMettereTraVirgoletteSoloCioCheHaUnoSpazio;
begin
  Assert.AreEqual('radix32.exe', TLauncherEngines.Quoted('radix32.exe'));
  Assert.AreEqual('"C:\My Games\radix32.exe"', TLauncherEngines.Quoted('C:\My Games\radix32.exe'));
  Assert.AreEqual('', TLauncherEngines.Quoted(''));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLauncherEngines);

end.
