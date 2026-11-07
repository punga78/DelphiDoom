{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the identification of the IWAD       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.Identifier;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Types, DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.Games, DelphiDoom.Iwad.Factory, DelphiDoom.Iwad.Identifier,
  DelphiDoom.Tests.Iwad.Fakes;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadIdentifier = class(TObject)
  strict private
    FEnvironment: TFakeIwadEnvironment;
    FEnvironmentIntf: IIwadEnvironment;
    FFileSystem: TFakeIwadFileSystem;
    FFileSystemIntf: IIwadFileSystem;
    FSteam: TFakeIwadSteam;
    FSteamIntf: IIwadSteam;
    FOptions: TFakeIwadOptions;
    FOptionsIntf: IIwadOptions;
    function MakeIdentifier(AGame: TIwadGame): IIwadIdentifier;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIndeterminatoSeNonTrovaNiente;
    [Test]
    procedure DovrebbeTrovareDoom2NellaCartellaCorrente;
    [Test]
    procedure DovrebbePreferireDoom2AlloShareware;
    [Test]
    procedure DovrebbeRiconoscereIlDoom2Francese;
    [Test]
    procedure DovrebbeRiconoscereLaBfgDiDoom2;
    [Test]
    procedure DovrebbeAggiungereIlFileDellaBfgDiDoomEnonDoomU;
    [Test]
    procedure DovrebbeLasciareDecidereAlMotoreSeTrovaDoomUODoom;
    [Test]
    procedure DovrebbeDareLaMissioneDiPlutoniaEDiTnt;
    [Test]
    procedure DovrebbeCercareLeBfgSoloNellaCartellaDellaVariabile;
    [Test]
    procedure DovrebbeCercareIGiochiNellaCartellaDellaVariabileDoomWadDir;
    [Test]
    procedure DovrebbeCercareNelleCartelleDiSteam;
    [Test]
    procedure DovrebbeNonCercareNelleCartelleSeSpente;
    [Test]
    procedure DovrebbeTrovareHereticRegistratoPrimaDelloShareware;
    [Test]
    procedure DovrebbeRiconoscereHexenShareware;
    [Test]
    procedure DovrebbeDareLeVociDiStrifeRegistrato;
    [Test]
    procedure DovrebbeNonDareLeVociDiStrifeSeNonCiSono;
    [Test]
    procedure DovrebbeAccettareUnIwadScelto;
    [Test]
    procedure DovrebbeRifiutareUnIwadSceltoCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnNomeVuoto;
    [Test]
    procedure DovrebbeCercareUnIwadSceltoNelleCartelle;
    [Test]
    procedure DovrebbeAggiungereHexenPrimaDiHexdd;
    [Test]
    procedure DovrebbeAccettareHexddAncheSeIlFileNonCe;
    [Test]
    procedure DovrebbeCercareLeVociVicinoAStrife1Scelto;
    [Test]
    procedure DovrebbeDareEccezioneConUnaDipendenzaNil;
  end;

implementation

{ TTestIwadIdentifier }

procedure TTestIwadIdentifier.Setup;
begin
  FEnvironment := TFakeIwadEnvironment.Create;
  FEnvironmentIntf := FEnvironment;
  FFileSystem := TFakeIwadFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FSteam := TFakeIwadSteam.Create;
  FSteamIntf := FSteam;
  FOptions := TFakeIwadOptions.Create;
  FOptionsIntf := FOptions;
end;

procedure TTestIwadIdentifier.TearDown;
begin
  FEnvironmentIntf := nil;
  FFileSystemIntf := nil;
  FSteamIntf := nil;
  FOptionsIntf := nil;
end;

function TTestIwadIdentifier.MakeIdentifier(AGame: TIwadGame): IIwadIdentifier;
var
  LProfile: IIwadProfile;
begin
  LProfile := TIwadGames.CreateProfile(AGame);
  Result := TIwadFactory.CreateIdentifier(LProfile,
    TIwadFactory.CreateLocator(LProfile, FEnvironmentIntf, FFileSystemIntf, FSteamIntf,
      FOptionsIntf),
    FFileSystemIntf, FEnvironmentIntf, FOptionsIntf);
end;

procedure TTestIwadIdentifier.DovrebbeDareIndeterminatoSeNonTrovaNiente;
var
  LResult: TIwadIdentification;
begin
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.IsFalse(LResult.Found);
  Assert.IsTrue(LResult.Mode = igmIndetermined);
  Assert.AreEqual(0, Integer(Length(LResult.Files)));
end;

procedure TTestIwadIdentifier.DovrebbeTrovareDoom2NellaCartellaCorrente;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\doom2.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.IsTrue(LResult.Found);
  Assert.IsFalse(LResult.Custom);
  Assert.AreEqual(1, Integer(Length(LResult.Files)));
  Assert.AreEqual('.\doom2.wad', LResult.Files[0]);
  Assert.IsTrue(LResult.Mode = igmCommercial);
  Assert.IsTrue(LResult.Mission = imsDoom2);
end;

procedure TTestIwadIdentifier.DovrebbePreferireDoom2AlloShareware;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\doom1.wad');
  FFileSystem.AddFile('R:\cwd\doom2.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.AreEqual('.\doom2.wad', LResult.Files[0]);
end;

procedure TTestIwadIdentifier.DovrebbeRiconoscereIlDoom2Francese;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\doom2f.wad');
  FFileSystem.AddFile('R:\cwd\doom2.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.AreEqual('.\doom2f.wad', LResult.Files[0]);
  Assert.IsTrue(LResult.IsFrench);
  Assert.IsTrue(LResult.Mission = imsDoom2);
end;

procedure TTestIwadIdentifier.DovrebbeRiconoscereLaBfgDiDoom2;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\doom2bfg.wad');
  FFileSystem.AddFile('R:\cwd\doom2.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.AreEqual('.\doom2bfg.wad', LResult.Files[0]);
  Assert.IsTrue(LResult.IsBfg2);
  Assert.IsTrue(LResult.Mode = igmCommercial);
end;

// regression: the old IdentifyVersion saw doombfg.wad but added doomu.wad
procedure TTestIwadIdentifier.DovrebbeAggiungereIlFileDellaBfgDiDoomEnonDoomU;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\doombfg.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.AreEqual('.\doombfg.wad', LResult.Files[0]);
  Assert.IsTrue(LResult.Mode = igmRetail);
  Assert.IsTrue(LResult.Mission = imsDoom);
end;

procedure TTestIwadIdentifier.DovrebbeLasciareDecidereAlMotoreSeTrovaDoomUODoom;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\doom.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.IsTrue(LResult.Mode = igmIndetermined);
  Assert.IsTrue(LResult.Mission = imsDoom);
  Assert.IsTrue(LResult.Found);
end;

procedure TTestIwadIdentifier.DovrebbeDareLaMissioneDiPlutoniaEDiTnt;
begin
  FFileSystem.AddFile('R:\cwd\plutonia.wad');
  Assert.IsTrue(MakeIdentifier(igDoom).IdentifyKnown.Mission = imsPlutonia);
  FFileSystem := TFakeIwadFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FFileSystem.AddFile('R:\cwd\tnt.wad');
  Assert.IsTrue(MakeIdentifier(igDoom).IdentifyKnown.Mission = imsTnt);
end;

procedure TTestIwadIdentifier.DovrebbeCercareLeBfgSoloNellaCartellaDellaVariabile;
var
  LResult: TIwadIdentification;
begin
  // a BFG file in a path of DOOMWADPATH is not found (the old code never looked there)
  FEnvironment.SetValue('DOOMWADPATH', 'R:\P');
  FFileSystem.AddFile('R:\P\doom2bfg.wad');
  Assert.IsFalse(MakeIdentifier(igDoom).IdentifyKnown.Found);
  // in the folder of DOOMWADDIR it is
  FEnvironment.SetValue('DOOMWADDIR', 'R:\D');
  FFileSystem.AddFile('R:\D\doom2bfg.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.IsTrue(LResult.IsBfg2);
  Assert.AreEqual('R:\D\doom2bfg.wad', LResult.Files[0]);
end;

procedure TTestIwadIdentifier.DovrebbeCercareIGiochiNellaCartellaDellaVariabileDoomWadDir;
var
  LResult: TIwadIdentification;
begin
  FEnvironment.SetValue('DOOMWADDIR', 'R:\D');
  FFileSystem.AddFile('R:\D\tnt.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.AreEqual('R:\D\tnt.wad', LResult.Files[0]);
end;

procedure TTestIwadIdentifier.DovrebbeCercareNelleCartelleDiSteam;
var
  LResult: TIwadIdentification;
begin
  FSteam.Install(2280, 'R:\Steam\Doom\');
  FFileSystem.AddFile('R:\Steam\Doom\base\doom2.wad');
  LResult := MakeIdentifier(igDoom).IdentifyKnown;
  Assert.AreEqual('R:\Steam\Doom\base\doom2.wad', LResult.Files[0]);
end;

procedure TTestIwadIdentifier.DovrebbeNonCercareNelleCartelleSeSpente;
begin
  FSteam.Install(2280, 'R:\Steam\Doom\');
  FFileSystem.AddFile('R:\Steam\Doom\doom2.wad');
  FOptions.SearchSteamPaths := False;
  Assert.IsFalse(MakeIdentifier(igDoom).IdentifyKnown.Found);
end;

procedure TTestIwadIdentifier.DovrebbeTrovareHereticRegistratoPrimaDelloShareware;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\heretic1.wad');
  FFileSystem.AddFile('R:\cwd\heretic.wad');
  LResult := MakeIdentifier(igHeretic).IdentifyKnown;
  Assert.AreEqual('heretic.wad', LResult.Files[0]);
  Assert.IsTrue(LResult.Mode = igmIndetermined);
  Assert.IsTrue(LResult.Mission = imsUnchanged);
end;

procedure TTestIwadIdentifier.DovrebbeRiconoscereHexenShareware;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\hexendem.wad');
  LResult := MakeIdentifier(igHexen).IdentifyKnown;
  Assert.AreEqual('hexendem.wad', LResult.Files[0]);
  Assert.IsTrue(LResult.Mode = igmShareware);
end;

procedure TTestIwadIdentifier.DovrebbeDareLeVociDiStrifeRegistrato;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\strife1.wad');
  FFileSystem.AddFile('R:\cwd\voices.wad');
  LResult := MakeIdentifier(igStrife).IdentifyKnown;
  Assert.AreEqual('strife1.wad', LResult.Files[0]);
  Assert.AreEqual('voices.wad', LResult.VoicesPath);
  Assert.IsTrue(LResult.Mode = igmRegistered);
end;

procedure TTestIwadIdentifier.DovrebbeNonDareLeVociDiStrifeSeNonCiSono;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\strife1.wad');
  LResult := MakeIdentifier(igStrife).IdentifyKnown;
  Assert.AreEqual('', LResult.VoicesPath);
end;

procedure TTestIwadIdentifier.DovrebbeAccettareUnIwadScelto;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\freedoom2.wad');
  Assert.IsTrue(MakeIdentifier(igDoom).TryIdentifyCustom('freedoom2.wad', LResult));
  Assert.IsTrue(LResult.Custom);
  Assert.IsTrue(LResult.Mode = igmIndetermined);
  Assert.AreEqual('freedoom2.wad', LResult.CustomPath);
  Assert.AreEqual(1, Integer(Length(LResult.Files)));
end;

procedure TTestIwadIdentifier.DovrebbeRifiutareUnIwadSceltoCheNonEsiste;
var
  LResult: TIwadIdentification;
begin
  Assert.IsFalse(MakeIdentifier(igDoom).TryIdentifyCustom('nothing.wad', LResult));
  Assert.AreEqual('', LResult.CustomPath);
  Assert.IsFalse(LResult.Found);
end;

procedure TTestIwadIdentifier.DovrebbeRifiutareUnNomeVuoto;
var
  LResult: TIwadIdentification;
begin
  Assert.IsFalse(MakeIdentifier(igDoom).TryIdentifyCustom('', LResult));
end;

procedure TTestIwadIdentifier.DovrebbeCercareUnIwadSceltoNelleCartelle;
var
  LResult: TIwadIdentification;
begin
  FEnvironment.SetValue('DOOMWADPATH', 'R:\P');
  FFileSystem.AddFile('R:\P\freedoom2.wad');
  Assert.IsTrue(MakeIdentifier(igDoom).TryIdentifyCustom('freedoom2.wad', LResult));
  Assert.AreEqual('R:\P\freedoom2.wad', LResult.CustomPath);
end;

procedure TTestIwadIdentifier.DovrebbeAggiungereHexenPrimaDiHexdd;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\cwd\hexdd.wad');
  FFileSystem.AddFile('R:\cwd\hexen.wad');
  Assert.IsTrue(MakeIdentifier(igHexen).TryIdentifyCustom('HEXDD.WAD', LResult));
  Assert.AreEqual(2, Integer(Length(LResult.Files)));
  Assert.AreEqual('hexen.wad', LResult.Files[0]);
  Assert.AreEqual('HEXDD.WAD', LResult.Files[1]);
  Assert.IsTrue(LResult.Mode = igmUnchanged);
end;

procedure TTestIwadIdentifier.DovrebbeAccettareHexddAncheSeIlFileNonCe;
var
  LResult: TIwadIdentification;
begin
  Assert.IsTrue(MakeIdentifier(igHexen).TryIdentifyCustom('hexdd.wad', LResult));
  Assert.AreEqual(2, Integer(Length(LResult.Files)));
end;

procedure TTestIwadIdentifier.DovrebbeCercareLeVociVicinoAStrife1Scelto;
var
  LResult: TIwadIdentification;
begin
  FFileSystem.AddFile('R:\G\strife1.wad');
  FFileSystem.AddFile('R:\G\voices.wad');
  Assert.IsTrue(MakeIdentifier(igStrife).TryIdentifyCustom('R:\G\strife1.wad', LResult));
  Assert.AreEqual('R:\G\voices.wad', LResult.VoicesPath);
end;

procedure TTestIwadIdentifier.DovrebbeDareEccezioneConUnaDipendenzaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadIdentifier.Create(nil, nil, nil, nil, nil);
    end, EArgumentNilException);
end;

end.
