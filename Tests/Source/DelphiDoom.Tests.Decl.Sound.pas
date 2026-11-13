{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound shader declaration (TDeclSound)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Sound;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Sound.Types, DelphiDoom.Decl.Sound.Intf, DelphiDoom.Tests.Decl.Support,
  DelphiDoom.Tests.Decl.SoundSupport;

type
  /// <summary>The shader alone, with the fakes of the cache, the files and the manager</summary>
  [TestFixture]
  [Category('Decl')]
  TTestDeclSound = class
  strict private
    FLines: TStringList;
    FLog: IIdLibLog;
    FCatalog: TFakeSoundCatalog;
    FCatalogIntf: ISoundSampleCatalog;
    FProbe: TFakeSoundProbe;
    FProbeIntf: ISoundFileProbe;
    FFinderIntf: IDeclFinder;
    FOptions: TSoundShaderOptions;
    FDecl: IDecl;
    function Shader(const ABody: AnsiString; const AName: AnsiString = 'snd/test'): IDeclSound;
    function Warnings: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeUsareIParametriDiDefaultSeNonCiSonoParole;
    [Test]
    procedure DovrebbeLeggereDescrizioneDistanzeEVolume;
    [Test]
    procedure DovrebbeLeggereTuttiIFlagELeMaschere;
    [Test]
    procedure DovrebbeElencarePrimaILeadinEPoiICampioni;
    [Test]
    procedure DovrebbeDareUnaStringaVuotaFuoriDallIntervalloDeiSuoni;
    [Test]
    procedure DovrebbeLeggereLeadinVolumeEClasse;
    [Test]
    procedure DovrebbeRifiutareUnaClasseFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnLeadinSenzaNome;
    [Test]
    procedure DovrebbeRifiutareUnTestoSenzaGraffaChiusa;
    [Test]
    procedure DovrebbeRifiutareUnaVirgolaMancanteDopoReverb;
    [Test]
    procedure DovrebbeIgnorareLeParoleNonPiuSupportate;
    [Test]
    procedure DovrebbeCercareLAltSoundNelGestore;
    [Test]
    procedure DovrebbeLasciareAltSoundVuotoSeLaLetturaFallisce;
    [Test]
    procedure DovrebbeUsareUnNumeroDopoShakesEAltrimentiUno;
    [Test]
    procedure DovrebbeSegnalareShakesConUnFileOgg;
    [Test]
    procedure DovrebbeLimitareICampioniAlMassimoDelleOpzioni;
    [Test]
    procedure DovrebbeAlzareIlLimiteConMinSamples;
    [Test]
    procedure DovrebbeTenereTrentaduecampioniSeSiFaUnaBuild;
    [Test]
    procedure DovrebbeNonTenereOltreTrentaduecampioni;
    [Test]
    procedure DovrebbeCercareIlFileNellaCartellaDellaLingua;
    [Test]
    procedure DovrebbeProvareLEstensioneOggNellaCartellaDellaLingua;
    [Test]
    procedure DovrebbeLasciareIlNomeSeNessunFileEsiste;
    [Test]
    procedure DovrebbeNonCercareLaLinguaPerLInglese;
    [Test]
    procedure DovrebbeNonCercareLaLinguaSenzaIlFileSystem;
    [Test]
    procedure DovrebbeDireSeUnCampioneEIlSuonoDiDefault;
    [Test]
    procedure DovrebbeScrivereLaListaConLeadinECampioni;
    [Test]
    procedure DovrebbeTacereLaDescrizioneDiDefaultNellaLista;
    [Test]
    procedure DovrebbeGenerareIlTestoImplicitoDalNome;
    [Test]
    procedure DovrebbeLasciareLEstensioneOggNelTestoImplicito;
    [Test]
    procedure DovrebbeTroncareIlTestoImplicitoLungo;
    [Test]
    procedure DovrebbeSvuotareSoloLeListeConFreeData;
    [Test]
    procedure DovrebbeTenereDescrizioneELeadinVolumeAlleLetturaSuccessive;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultDopoUnErrore;
    [Test]
    procedure DovrebbeDareUnaDimensioneInMemoria;
    [Test]
    procedure DovrebbeDareLeOpzioniStandard;
  end;

  /// <summary>The shader inside the real manager: the folder <c>sound</c>, the implicit shader, the registration</summary>
  [TestFixture]
  [Category('Decl')]
  TTestDeclSoundManager = class
  strict private
    FKit: TDeclKit;
    function Sound(const AName: AnsiString): IDeclSound;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereUnFileSndshdDellaCartellaSound;
    [Test]
    procedure DovrebbeFareUnaDichiarazioneImplicitaPerUnNomeSenzaTesto;
    [Test]
    procedure DovrebbeLeggereLAltSoundDalGestoreVero;
    [Test]
    procedure DovrebbeUsareLeOpzioniEIlCatalogoDellaRegistrazione;
    [Test]
    procedure DovrebbeUsareIlCatalogoDeiSoliNomiSeNonSiDaNulla;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestSoundSampleNameCatalog = class
  public
    [Test]
    procedure DovrebbeRendereCanonicoIlNome;
    [Test]
    procedure DovrebbeNonSapereNientAltroDelCampione;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Base, DelphiDoom.Decl.Sound, DelphiDoom.Decl.Sound.NameCatalog,
  DelphiDoom.Decl.Sound.Registration, DelphiDoom.Tests.Scanner.IdFakes, DelphiDoom.Tests.Decl.EffectsSupport;

{ TTestDeclSound }

procedure TTestDeclSound.Setup;
begin
  FLines := TStringList.Create;
  FLog := TFakeIdLibLog.Create(FLines);
  FCatalog := TFakeSoundCatalog.Create;
  FCatalogIntf := FCatalog;
  FProbe := TFakeSoundProbe.Create;
  FProbeIntf := FProbe;
  FOptions := TSoundShaderOptions.Standard;
end;

procedure TTestDeclSound.TearDown;
begin
  FDecl := nil;
  FFinderIntf := nil;
  FProbeIntf := nil;
  FCatalogIntf := nil;
  FLog := nil;
  FreeAndNil(FLines);
end;

function TTestDeclSound.Shader(const ABody: AnsiString; const AName: AnsiString): IDeclSound;
var
  LDecl: TDeclSound;
begin
  FFinderIntf := TFakeSoundFinder.Create(nil, FLog, FCatalogIntf, FProbeIntf, FOptions);
  LDecl := TDeclSound.Create(FCatalogIntf, FProbeIntf, FOptions);
  FDecl := LDecl;
  TFakeDeclMaker.Attach(LDecl, DECL_SOUND, AName, FFinderIntf, FLog);
  LDecl.Parse('sound ' + AName + #10 + ABody);
  Result := LDecl;
end;

function TTestDeclSound.Warnings: string;
begin
  Result := FLines.Text;
end;

procedure TTestDeclSound.DovrebbeUsareIParametriDiDefaultSeNonCiSonoParole;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ }');
  Assert.AreEqual<Single>(1, LSound.GetMinDistance);
  Assert.AreEqual<Single>(10, LSound.GetMaxDistance);
  Assert.AreEqual<Single>(1, LSound.GetParms.Volume);
  Assert.AreEqual<Single>(0, LSound.GetParms.Shakes);
  Assert.AreEqual(0, LSound.GetParms.SoundShaderFlags);
  Assert.AreEqual(0, LSound.GetParms.SoundClass);
  Assert.AreEqual(0, LSound.GetSpeakerMask);
  Assert.AreEqual<Single>(0, LSound.GetLeadinVolume);
  Assert.AreEqual(0, LSound.GetNumSounds);
  Assert.AreEqual<string>('<no description>', string(LSound.GetDescription));
  Assert.IsFalse(Assigned(LSound.GetAltSound));
end;

procedure TTestDeclSound.DovrebbeLeggereDescrizioneDistanzeEVolume;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ description "a sound" mindistance 2.5 maxdistance 40 volume -3 }');
  Assert.AreEqual<string>('a sound', string(LSound.GetDescription));
  Assert.AreEqual<Single>(2.5, LSound.GetMinDistance);
  Assert.AreEqual<Single>(40, LSound.GetMaxDistance);
  Assert.AreEqual<Single>(-3, LSound.GetParms.Volume);
end;

procedure TTestDeclSound.DovrebbeLeggereTuttiIFlagELeMaschere;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ no_dups no_flicker looping no_occlusion private antiPrivate playonce global unclamped ' +
    'omnidirectional mask_center mask_left mask_right mask_backright mask_backleft mask_lfe }');
  Assert.AreEqual(SSF_NO_DUPS or SSF_NO_FLICKER or SSF_LOOPING or SSF_NO_OCCLUSION or SSF_PRIVATE_SOUND or
    SSF_ANTI_PRIVATE_SOUND or SSF_PLAY_ONCE or SSF_GLOBAL or SSF_UNCLAMPED or SSF_OMNIDIRECTIONAL,
    LSound.GetParms.SoundShaderFlags);
  Assert.AreEqual(1023, LSound.GetParms.SoundShaderFlags);
  Assert.AreEqual(63, LSound.GetSpeakerMask);
end;

procedure TTestDeclSound.DovrebbeElencarePrimaILeadinEPoiICampioni;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ a.wav b.ogg leadin Lead\One.WAV }');
  Assert.AreEqual(3, LSound.GetNumSounds);
  Assert.AreEqual<string>('lead/one.wav', string(LSound.GetSound(0)));
  Assert.AreEqual<string>('a.wav', string(LSound.GetSound(1)));
  Assert.AreEqual<string>('b.ogg', string(LSound.GetSound(2)));
end;

procedure TTestDeclSound.DovrebbeDareUnaStringaVuotaFuoriDallIntervalloDeiSuoni;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ a.wav }');
  Assert.AreEqual<string>('', string(LSound.GetSound(-1)));
  Assert.AreEqual<string>('', string(LSound.GetSound(1)));
  Assert.AreEqual<string>('', string(LSound.GetSound(100)));
end;

procedure TTestDeclSound.DovrebbeLeggereLeadinVolumeEClasse;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ leadinVolume 6 soundClass 3 }');
  Assert.AreEqual<Single>(6, LSound.GetLeadinVolume);
  Assert.AreEqual(3, LSound.GetParms.SoundClass);
end;

procedure TTestDeclSound.DovrebbeRifiutareUnaClasseFuoriIntervallo;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ soundClass 4 volume 9 }');
  Assert.IsTrue(Pos('SoundClass out of range', Warnings) > 0);
  // the shader is the default one
  Assert.AreEqual(1, LSound.GetNumSounds);
  Assert.AreEqual<string>('_default.wav', string(LSound.GetSound(0)));
  Assert.AreEqual<Single>(1, LSound.GetParms.Volume);
  Assert.AreEqual(0, LSound.GetParms.SoundClass);
end;

procedure TTestDeclSound.DovrebbeRifiutareUnaParolaSconosciuta;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ wrongword a.wav }');
  Assert.IsTrue(Pos('unknown token ''wrongword''', Warnings) > 0);
  Assert.AreEqual<string>('_default.wav', string(LSound.GetSound(0)));
  Assert.IsTrue(LSound.HasDefaultSound);
end;

procedure TTestDeclSound.DovrebbeRifiutareUnLeadinSenzaNome;
begin
  Shader('{ leadin');
  Assert.IsTrue(Pos('Expected sound after leadin', Warnings) > 0);
end;

procedure TTestDeclSound.DovrebbeRifiutareUnTestoSenzaGraffaChiusa;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ a.wav');
  Assert.IsTrue(Pos('couldn''t read expected token', Warnings) > 0);
  Assert.AreEqual<string>('_default.wav', string(LSound.GetSound(0)));
end;

procedure TTestDeclSound.DovrebbeRifiutareUnaVirgolaMancanteDopoReverb;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ reverb 1 2 a.wav }');
  Assert.IsTrue(Pos('expected '','' but found ''2''', Warnings) > 0);
  Assert.AreEqual<string>('_default.wav', string(LSound.GetSound(0)));
  LSound := Shader('{ reverb 1 , 2 a.wav }');
  Assert.AreEqual<string>('a.wav', string(LSound.GetSound(0)));
end;

procedure TTestDeclSound.DovrebbeIgnorareLeParoleNonPiuSupportate;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ ordered plain onDemand a.wav }');
  Assert.AreEqual(1, LSound.GetNumSounds);
  Assert.AreEqual('', Warnings);
end;

procedure TTestDeclSound.DovrebbeCercareLAltSoundNelGestore;
var
  LSound: IDeclSound;
  LAlt: IDecl;
begin
  LSound := Shader('{ altSound snd/other }');
  Assert.IsTrue(Assigned(LSound.GetAltSound));
  Assert.IsTrue(Supports(LSound.GetAltSound, IDecl, LAlt));
  Assert.AreEqual<string>('snd/other', string(LAlt.GetName));
end;

procedure TTestDeclSound.DovrebbeLasciareAltSoundVuotoSeLaLetturaFallisce;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ altSound }');
  Assert.IsFalse(Assigned(LSound.GetAltSound));
end;

procedure TTestDeclSound.DovrebbeUsareUnNumeroDopoShakesEAltrimentiUno;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ shakes 2.5 }');
  Assert.AreEqual<Single>(2.5, LSound.GetParms.Shakes);
  LSound := Shader('{ shakes looping }');
  Assert.AreEqual<Single>(1, LSound.GetParms.Shakes);
  Assert.AreEqual(SSF_LOOPING, LSound.GetParms.SoundShaderFlags);
end;

procedure TTestDeclSound.DovrebbeSegnalareShakesConUnFileOgg;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ shakes 3 leadin lead.ogg a.wav b.OGG }', 'snd/shake');
  Assert.IsTrue(Pos('W: sound shader ''snd/shake'' has shakes and uses OGG file ''lead.ogg''', Warnings) > 0);
  Assert.IsTrue(Pos('uses OGG file ''b.ogg''', Warnings) > 0);
  Assert.IsTrue(LSound.CheckShakesAndOgg);
  LSound := Shader('{ shakes 3 a.wav }');
  Assert.IsFalse(LSound.CheckShakesAndOgg);
  // the check is about the format only: the parse calls it when the shader shakes
  LSound := Shader('{ a.ogg }');
  Assert.IsTrue(LSound.CheckShakesAndOgg);
end;

procedure TTestDeclSound.DovrebbeLimitareICampioniAlMassimoDelleOpzioni;
var
  LSound: IDeclSound;
begin
  FOptions.MaxSoundsPerShader := 2;
  LSound := Shader('{ leadin l1.wav leadin l2.wav leadin l3.wav a.wav b.wav c.wav }');
  Assert.AreEqual(4, LSound.GetNumSounds);
  Assert.AreEqual<string>('l2.wav', string(LSound.GetSound(1)));
  Assert.AreEqual<string>('b.wav', string(LSound.GetSound(3)));
end;

procedure TTestDeclSound.DovrebbeAlzareIlLimiteConMinSamples;
var
  LSound: IDeclSound;
begin
  FOptions.MaxSoundsPerShader := 2;
  LSound := Shader('{ minSamples 4 a.wav b.wav c.wav d.wav e.wav }');
  Assert.AreEqual(4, LSound.GetNumSounds);
  // below the limit it changes nothing
  LSound := Shader('{ minSamples 1 a.wav b.wav c.wav }');
  Assert.AreEqual(2, LSound.GetNumSounds);
end;

procedure TTestDeclSound.DovrebbeTenereTrentaduecampioniSeSiFaUnaBuild;
var
  LSound: IDeclSound;
begin
  FOptions.MaxSoundsPerShader := 1;
  FOptions.MakingBuild := True;
  LSound := Shader('{ a.wav b.wav c.wav }');
  Assert.AreEqual(3, LSound.GetNumSounds);
  // a cvar above 32 is 32 too
  FOptions.MakingBuild := False;
  FOptions.MaxSoundsPerShader := 99;
  LSound := Shader('{ a.wav b.wav c.wav }');
  Assert.AreEqual(3, LSound.GetNumSounds);
end;

procedure TTestDeclSound.DovrebbeNonTenereOltreTrentaduecampioni;
var
  LBody: string;
  LIndex: Integer;
  LSound: IDeclSound;
begin
  LBody := '{';
  for LIndex := 1 to 40 do
    LBody := LBody + Format(' s%d.wav', [LIndex]);
  LSound := Shader(AnsiString(LBody + ' }'));
  Assert.AreEqual(SOUND_MAX_LIST_WAVS, LSound.GetNumSounds);
  // minSamples above the limit raises the limit (as in the original), but the array stops at 32
  LSound := Shader(AnsiString('{ minSamples 40 ' + Copy(LBody, 3, MaxInt) + ' }'));
  Assert.AreEqual(SOUND_MAX_LIST_WAVS, LSound.GetNumSounds);
end;

procedure TTestDeclSound.DovrebbeCercareIlFileNellaCartellaDellaLingua;
var
  LSound: IDeclSound;
begin
  FOptions.Language := 'german';
  FProbe.Add('sound/vo/german/hello/world.wav', 100);
  LSound := Shader('{ Sound\VO\Hello\World.wav }');
  Assert.AreEqual<string>('sound/vo/german/hello/world.wav', string(LSound.GetSound(0)));
end;

procedure TTestDeclSound.DovrebbeProvareLEstensioneOggNellaCartellaDellaLingua;
var
  LSound: IDeclSound;
begin
  FOptions.Language := 'german';
  FProbe.Add('sound/vo/german/hello/world.ogg', 10);
  LSound := Shader('{ sound/vo/hello/world.wav }');
  Assert.AreEqual<string>('sound/vo/german/hello/world.ogg', string(LSound.GetSound(0)));
  // an empty file does not count
  FProbe.Add('sound/vo/german/hello/world.ogg', 0);
  LSound := Shader('{ sound/vo/hello/world.wav }');
  Assert.AreEqual<string>('sound/vo/hello/world.wav', string(LSound.GetSound(0)));
end;

procedure TTestDeclSound.DovrebbeLasciareIlNomeSeNessunFileEsiste;
var
  LSound: IDeclSound;
begin
  FOptions.Language := 'german';
  LSound := Shader('{ sound/vo/Hello/World.wav sound/other/x.wav }');
  Assert.AreEqual<string>('sound/vo/hello/world.wav', string(LSound.GetSound(0)));
  Assert.AreEqual<string>('sound/other/x.wav', string(LSound.GetSound(1)));
end;

procedure TTestDeclSound.DovrebbeNonCercareLaLinguaPerLInglese;
var
  LSound: IDeclSound;
begin
  FOptions.Language := 'English';
  FProbe.Add('sound/vo/english/hello.wav', 100);
  LSound := Shader('{ sound/vo/hello.wav }');
  Assert.AreEqual<string>('sound/vo/hello.wav', string(LSound.GetSound(0)));
end;

procedure TTestDeclSound.DovrebbeNonCercareLaLinguaSenzaIlFileSystem;
var
  LDecl: TDeclSound;
  LFinder: IDeclFinder;
begin
  FOptions.Language := 'german';
  LFinder := TFakeSoundFinder.Create(nil, FLog, FCatalogIntf, nil, FOptions);
  LDecl := TDeclSound.Create(FCatalogIntf, nil, FOptions);
  FDecl := LDecl;
  TFakeDeclMaker.Attach(LDecl, DECL_SOUND, 'snd/nofiles', LFinder, FLog);
  LDecl.Parse('sound snd/nofiles'#10'{ sound/vo/hello.wav }');
  Assert.AreEqual<string>('sound/vo/hello.wav', string(LDecl.GetSound(0)));
  FFinderIntf := LFinder;
end;

procedure TTestDeclSound.DovrebbeDireSeUnCampioneEIlSuonoDiDefault;
begin
  Assert.IsTrue(Shader('{ a.wav b_default.wav }').HasDefaultSound);
  Assert.IsFalse(Shader('{ a.wav }').HasDefaultSound);
  // only the samples count, not the lead-ins
  Assert.IsFalse(Shader('{ leadin x_default.wav a.wav }').HasDefaultSound);
end;

procedure TTestDeclSound.DovrebbeScrivereLaListaConLeadinECampioni;
var
  LSound: IDeclSound;
  LExpectedLength: Integer;
begin
  LSound := Shader('{ description "listed" leadin lead22k.wav one11k.wav three.wav }');
  FLines.Clear;
  (LSound as IDecl).List;
  Assert.AreEqual(5, FLines.Count);
  Assert.AreEqual('P: ' + Format('%4d: snd/test\n', [0]), FLines[0]);
  Assert.AreEqual('P:       description: listed\n', FLines[1]);
  LExpectedLength := (1000 + 37 * (Ord('l') + Ord('e') + Ord('a') + Ord('d') + Ord('2') + Ord('2') + Ord('k') +
    Ord('.') + Ord('w') + Ord('a') + Ord('v'))) shl 1;
  Assert.AreEqual('P: ' + Format('      %5dms', [LExpectedLength div 44]), Copy(FLines[2], 1, 16));
  Assert.IsTrue(FLines[2].EndsWith(' lead22k.wav (LEADIN)\n'));
  Assert.IsTrue(FLines[3].EndsWith(' one11k.wav\n'));
  Assert.IsTrue(FLines[4].EndsWith(' three.wav\n'));
  Assert.IsTrue(FLines[4].EndsWith(' three.wav\n'));
end;

procedure TTestDeclSound.DovrebbeTacereLaDescrizioneDiDefaultNellaLista;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ a.wav }');
  FLines.Clear;
  (LSound as IDecl).List;
  Assert.AreEqual(2, FLines.Count);
  Assert.IsFalse(FLines.Text.Contains('description'));
end;

procedure TTestDeclSound.DovrebbeGenerareIlTestoImplicitoDalNome;
var
  LDecl: TDeclSound;
begin
  Shader('{ }', 'snd/foo');
  LDecl := TDeclSound(FDecl as TObject);
  Assert.IsTrue(LDecl.SetDefaultText);
  Assert.AreEqual<string>('sound snd/foo // IMPLICITLY GENERATED'#10'{'#10'snd/foo.wav'#10'}'#10,
    string(FDecl.GetText));
end;

procedure TTestDeclSound.DovrebbeLasciareLEstensioneOggNelTestoImplicito;
var
  LDecl: TDeclSound;
begin
  Shader('{ }', 'snd/foo.ogg');
  LDecl := TDeclSound(FDecl as TObject);
  LDecl.SetDefaultText;
  Assert.IsTrue(Pos(#10'snd/foo.ogg'#10, string(FDecl.GetText)) > 0);
end;

procedure TTestDeclSound.DovrebbeTroncareIlTestoImplicitoLungo;
var
  LDecl: TDeclSound;
begin
  Shader('{ }', AnsiString(StringOfChar('a', 1100)));
  FLines.Clear;
  LDecl := TDeclSound(FDecl as TObject);
  LDecl.SetDefaultText;
  Assert.AreEqual(2047, FDecl.GetTextLength);
  Assert.AreEqual('W: idStr::snPrintf: overflow of 2240 in 2048\n', FLines[0]);
end;

procedure TTestDeclSound.DovrebbeSvuotareSoloLeListeConFreeData;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ description "d" volume 3 leadin a.wav b.wav }');
  TDeclSound(FDecl as TObject).FreeData;
  Assert.AreEqual(0, LSound.GetNumSounds);
  Assert.AreEqual<string>('d', string(LSound.GetDescription));
  Assert.AreEqual<Single>(3, LSound.GetParms.Volume);
end;

procedure TTestDeclSound.DovrebbeTenereDescrizioneELeadinVolumeAlleLetturaSuccessive;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ description "d" leadinVolume 5 volume 3 a.wav }');
  TDeclSound(FDecl as TObject).Parse('sound x { volume 7 }');
  Assert.AreEqual<string>('d', string(LSound.GetDescription));
  Assert.AreEqual<Single>(5, LSound.GetLeadinVolume);
  Assert.AreEqual<Single>(7, LSound.GetParms.Volume);
  Assert.AreEqual(0, LSound.GetNumSounds);
end;

procedure TTestDeclSound.DovrebbeUsareLaDefinizioneDiDefaultDopoUnErrore;
var
  LSound: IDeclSound;
begin
  LSound := Shader('{ volume 9 wrongword }');
  Assert.AreEqual<Single>(1, LSound.GetParms.Volume);
  Assert.AreEqual(1, LSound.GetNumSounds);
  Assert.AreEqual<string>('{'#10#9'_default.wav'#10'}', string(TDeclSound(FDecl as TObject).DefaultDefinition));
end;

procedure TTestDeclSound.DovrebbeDareUnaDimensioneInMemoria;
begin
  Shader('{ }');
  Assert.IsTrue(TDeclSound(FDecl as TObject).Size > 0);
end;

procedure TTestDeclSound.DovrebbeDareLeOpzioniStandard;
var
  LOptions: TSoundShaderOptions;
begin
  LOptions := TSoundShaderOptions.Standard;
  Assert.AreEqual(0, LOptions.MaxSoundsPerShader);
  Assert.IsFalse(LOptions.MakingBuild);
  Assert.AreEqual<string>('english', string(LOptions.Language));
end;

{ TTestDeclSoundManager }

procedure TTestDeclSoundManager.Setup;
begin
  FKit := TDeclKit.Create;
end;

procedure TTestDeclSoundManager.TearDown;
begin
  FreeAndNil(FKit);
end;

function TTestDeclSoundManager.Sound(const AName: AnsiString): IDeclSound;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_SOUND, AName), IDeclSound, Result));
end;

procedure TTestDeclSoundManager.DovrebbeLeggereUnFileSndshdDellaCartellaSound;
var
  LSound: IDeclSound;
begin
  FKit.Source.Add('sound/test.sndshd', 'sound snd/one { volume -2 looping Snd\One.wav }'#10 +
    'snd/two { description "two" snd/two.ogg }');
  FKit.Start(True, True);
  LSound := Sound('snd/one');
  Assert.AreEqual<Single>(-2, LSound.GetParms.Volume);
  Assert.AreEqual(SSF_LOOPING, LSound.GetParms.SoundShaderFlags);
  Assert.AreEqual<string>('snd/one.wav', string(LSound.GetSound(0)));
  Assert.AreEqual<string>('two', string(Sound('snd/two').GetDescription));
end;

procedure TTestDeclSoundManager.DovrebbeFareUnaDichiarazioneImplicitaPerUnNomeSenzaTesto;
var
  LDecl: IDecl;
  LSound: IDeclSound;
begin
  FKit.Start(True, True);
  LDecl := FKit.Manager.FindType(DECL_SOUND, 'snd/implicit');
  Assert.IsTrue(LDecl.IsImplicit);
  LSound := Sound('snd/implicit');
  Assert.AreEqual(1, LSound.GetNumSounds);
  Assert.AreEqual<string>('snd/implicit.wav', string(LSound.GetSound(0)));
  // the generated text is dropped once it is read
end;

procedure TTestDeclSoundManager.DovrebbeLeggereLAltSoundDalGestoreVero;
var
  LSound: IDeclSound;
  LAlt: IDecl;
begin
  FKit.Source.Add('sound/test.sndshd', 'sound snd/a { altSound snd/b a.wav }'#10'snd/b { volume 4 b.wav }');
  FKit.Start(True, True);
  LSound := Sound('snd/a');
  Assert.IsTrue(Assigned(LSound.GetAltSound));
  Assert.AreEqual<Single>(4, LSound.GetAltSound.GetParms.Volume);
  Supports(LSound.GetAltSound, IDecl, LAlt);
  Assert.AreEqual<string>('snd/b', string(LAlt.GetName));
end;

procedure TTestDeclSoundManager.DovrebbeUsareLeOpzioniEIlCatalogoDellaRegistrazione;
var
  LCatalog: TFakeSoundCatalog;
  LCatalogIntf: ISoundSampleCatalog;
  LOptions: TSoundShaderOptions;
  LSound: IDeclSound;
begin
  LCatalog := TFakeSoundCatalog.Create;
  LCatalogIntf := LCatalog;
  LOptions := TSoundShaderOptions.Standard;
  LOptions.MaxSoundsPerShader := 1;
  FKit.Source.Add('sound/test.sndshd', 'sound snd/c { x.wav y.wav }');
  FKit.Start(False, False);
  TDeclSoundRegistration.Register(FKit.Manager.GetRegistry, LCatalogIntf, nil, LOptions);
  FKit.Manager.GetRegistry.RegisterDeclFolder('sound', '.sndshd', DECL_SOUND);
  LSound := Sound('snd/c');
  Assert.AreEqual(1, LSound.GetNumSounds);
  Assert.AreEqual(1, LCatalog.Requests.Count);
  Assert.AreEqual('x.wav', LCatalog.Requests[0]);
end;

procedure TTestDeclSoundManager.DovrebbeUsareIlCatalogoDeiSoliNomiSeNonSiDaNulla;
var
  LSound: IDeclSound;
begin
  FKit.Source.Add('sound/test.sndshd', 'sound snd/d { Some\Where.OGG }');
  FKit.Start(False, False);
  TDeclSoundRegistration.Register(FKit.Manager.GetRegistry);
  FKit.Manager.GetRegistry.RegisterDeclFolder('sound', '.sndshd', DECL_SOUND);
  LSound := Sound('snd/d');
  Assert.AreEqual<string>('some/where.ogg', string(LSound.GetSound(0)));
end;

{ TTestSoundSampleNameCatalog }

procedure TTestSoundSampleNameCatalog.DovrebbeRendereCanonicoIlNome;
var
  LCatalog: ISoundSampleCatalog;
begin
  LCatalog := TSoundSampleNameCatalog.Create;
  Assert.AreEqual<string>('sound/a/b.wav', string(LCatalog.FindSample('Sound\A/B.WAV').Name));
end;

procedure TTestSoundSampleNameCatalog.DovrebbeNonSapereNientAltroDelCampione;
var
  LInfo: TSoundSampleInfo;
begin
  LInfo := TSoundSampleNameCatalog.Create.FindSample('x_default.ogg');
  Assert.IsFalse(LInfo.IsOgg);
  Assert.IsFalse(LInfo.IsDefault);
  Assert.AreEqual(0, LInfo.Length44kHzSamples);
  Assert.AreEqual(0, LInfo.MemorySize);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclSound);
  TDUnitX.RegisterTestFixture(TTestDeclSoundManager);
  TDUnitX.RegisterTestFixture(TTestSoundSampleNameCatalog);

end.
