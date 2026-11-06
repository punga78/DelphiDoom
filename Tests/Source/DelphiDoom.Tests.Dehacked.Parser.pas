{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Dehacked library - the parser and the profiles     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.Parser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.Dehacked.Intf, DelphiDoom.Dehacked.Games;

type
  [TestFixture]
  [Category('dehacked')]
  TTestDehackedParser = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    function Parse(AGame: TDehackedGame; const AText: string): IDehackedPatch;
    function Warnings: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    // header and structure
    [Test]
    procedure TestLIntestazioneDiUnaPatchVieneLetta;
    [Test]
    procedure TestUnaPatchSenzaIntestazioneHaValoriNegativi;
    [Test]
    procedure TestUnTestoVuotoNonHaSezioni;
    [Test]
    procedure TestLeIntestazioniSconosciuteSonoIgnorate;
    [Test]
    procedure TestUnaSezioneContinuaOltreRigheVuoteECommenti;
    [Test]
    procedure TestUnCampoSconosciutoTerminaLaSezioneELaRigaVieneRiletta;
    [Test]
    procedure TestUnaIntestazioneRiletaNellUltimaRigaVieneSaltata;

    // Thing
    [Test]
    procedure TestThingConNumero;
    [Test]
    procedure TestThingConNomeENewThingSonoNuove;
    [Test]
    procedure TestGliAliasDannoIlCampoCanonico;
    [Test]
    procedure TestIlTestoDeiCampiDelleCoseNonHaVirgolette;
    [Test]
    procedure TestFlagsDiUnaCosaConNomiENumeri;
    [Test]
    procedure TestIBitAltiDiBitsSonoFlagExtra;
    [Test]
    procedure TestICampiMbf21ImpostanoIlMarcatore;
    [Test]
    procedure TestLeParoleChiaveDegliStatiDiUnaCosa;
    [Test]
    procedure TestBits2NonEsisteInDoomEdEsisteInHeretic;

    // Frame
    [Test]
    procedure TestFrameNuovoEFrameConNome;
    [Test]
    procedure TestIlProssimoStatoEIlNumeroDelloSprite;
    [Test]
    procedure TestLAzioneDiUnFrameHaNomeEArgomenti;

    // Weapon, Ammo, Misc, Sound
    [Test]
    procedure TestWeaponDiDoomControllaIlNumeroEAmmoPerShot;
    [Test]
    procedure TestWeaponDiHereticHaIlLivello;
    [Test]
    procedure TestWeaponDiHexenHaLaClasse;
    [Test]
    procedure TestAmmoControllaIlNumero;
    [Test]
    procedure TestMiscTerminaConUnValoreNegativo;
    [Test]
    procedure TestSoundHaRiferimentoANumeroOANome;

    // BEX and the others
    [Test]
    procedure TestParsDiDoomEDiHeretic;
    [Test]
    procedure TestStringsUniscaLeRigheConLaBarraInversa;
    [Test]
    procedure TestTextLeggeIlTestoVecchioEIlNuovo;
    [Test]
    procedure TestPointerLeggeIlFotogrammaDaCopiare;
    [Test]
    procedure TestCodePointerHaIlNumeroEIlNome;
    [Test]
    procedure TestMusicESoundsHannoChiaveETesto;
    [Test]
    procedure TestMusicDiHexenConLeParentesi;
    [Test]
    procedure TestSpritesControllaLaLunghezzaDelNuovoNome;
    [Test]
    procedure TestCheatELeNuoveFrameNonLeggonoRighe;

    // the other games
    [Test]
    procedure TestHexenNonHaAmmoNePars;
    [Test]
    procedure TestHexenHaMaxManaSoloNelMisc;
    [Test]
    procedure TestStrifeHaNome2ENonHaIFlagExtra;
    [Test]
    procedure TestIProfiliHannoIlNomeDelGioco;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.Dehacked.Types,
  DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Factory;

const
  CRLF = #13#10;

{ TTestDehackedParser }

procedure TTestDehackedParser.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
end;

procedure TTestDehackedParser.TearDown;
begin
  FSink := nil;
  FRecorder := nil;
end;

function TTestDehackedParser.Parse(AGame: TDehackedGame; const AText: string): IDehackedPatch;
begin
  Result := TDehackedFactory.CreateParser(AGame,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil)).Parse(AText);
end;

function TTestDehackedParser.Warnings: string;
begin
  Result := StringReplace(FRecorder.TextOf(TLogChannel.Output), CRLF, '|', [rfReplaceAll]);
end;

procedure TTestDehackedParser.TestLIntestazioneDiUnaPatchVieneLetta;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Patch File for DeHackEd v3.0'#10'Doom version = 21'#10'Patch format = 6'#10);
  Assert.IsTrue(LPatch.HasSignature);
  Assert.AreEqual(21, LPatch.DoomVersion);
  Assert.AreEqual(6, LPatch.PatchFormat);
  Assert.AreEqual(0, LPatch.SectionCount);
end;

procedure TTestDehackedParser.TestUnaPatchSenzaIntestazioneHaValoriNegativi;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Thing 1'#10'Speed = 3');
  Assert.IsFalse(LPatch.HasSignature);
  Assert.AreEqual(-1, LPatch.DoomVersion);
  Assert.AreEqual(-1, LPatch.PatchFormat);
end;

procedure TTestDehackedParser.TestUnTestoVuotoNonHaSezioni;
begin
  Assert.AreEqual(0, Parse(dgDoom, '').SectionCount);
  Assert.AreEqual(0, Parse(dgDoom, '# solo un commento').SectionCount);
end;

procedure TTestDehackedParser.TestLeIntestazioniSconosciuteSonoIgnorate;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Foo bar'#10'baz = 3'#10'Thing 2'#10'Speed = 4');
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual('', Warnings);
end;

procedure TTestDehackedParser.TestUnaSezioneContinuaOltreRigheVuoteECommenti;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Thing 2'#10#10'# c'#10'Speed = 4'#10'// c'#10'  '#10'Mass = 5');
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(2, LPatch.Section(0).Count);
  Assert.AreEqual(4, LPatch.Section(0)[0].Line);
  Assert.AreEqual(7, LPatch.Section(0)[1].Line);
end;

procedure TTestDehackedParser.TestUnCampoSconosciutoTerminaLaSezioneELaRigaVieneRiletta;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Thing 1'#10'Speed = 1'#10'Weapon 3'#10'Select frame = 5');
  // "Weapon 3" is not a field of a thing: it ends the block and opens the next one
  Assert.AreEqual(2, LPatch.SectionCount);
  Assert.AreEqual(dskThing, LPatch.Section(0).Kind);
  Assert.AreEqual(1, LPatch.Section(0).Count);
  Assert.AreEqual(dskWeapon, LPatch.Section(1).Kind);
  LPatch := Parse(dgDoom, 'Thing 1'#10'Speed = 1'#10'Misc'#10'Max Health = 5');
  Assert.AreEqual(2, LPatch.SectionCount);
  Assert.AreEqual(dskMisc, LPatch.Section(1).Kind);
  Assert.AreEqual('', Warnings);
  Parse(dgDoom, 'Thing 1'#10'Speed = 1'#10'Nonexistent = 3'#10'Mass = 2');
  Assert.AreEqual('I_Warning: DEH_Parse(): Wrong think field = NONEXISTENT (Think number = 0)|', Warnings);
end;

procedure TTestDehackedParser.TestUnaIntestazioneRiletaNellUltimaRigaVieneSaltata;
var
  LPatch: IDehackedPatch;
begin
  // difetto del vecchio codice conservato: il ciclo principale guardava solo se c'erano righe
  // ancora da leggere, e una riga restituita dall'ultima sezione non era piu' riletta
  LPatch := Parse(dgDoom, 'Thing 1'#10'Speed = 1'#10'SUBMITNEWSTATES');
  Assert.AreEqual(1, LPatch.SectionCount);
  LPatch := Parse(dgDoom, 'Thing 1'#10'Speed = 1'#10'SUBMITNEWSTATES'#10'# fine');
  Assert.AreEqual(2, LPatch.SectionCount);
  Assert.AreEqual(dskSubmitNewStates, LPatch.Section(1).Kind);
end;

procedure TTestDehackedParser.TestThingConNumero;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Thing 3 (Zombie)'#10'Hit points = 99'#10'ID # = 0x10').Section(0);
  Assert.AreEqual(dskThing, LSection.Kind);
  Assert.AreEqual('THING', LSection.Keyword);
  Assert.AreEqual(3, LSection.Reference.Number);
  Assert.IsFalse(LSection.Reference.IsNew);
  Assert.AreEqual(2, LSection.Count);
  Assert.AreEqual('HIT POINTS', LSection[0].FieldName);
  Assert.AreEqual(99, LSection[0].Number);
  Assert.IsTrue(LSection[0].IsNumber);
  Assert.AreEqual(16, LSection[1].Number);
  Assert.IsFalse(LSection[1].IsNumber);
end;

procedure TTestDehackedParser.TestThingConNomeENewThingSonoNuove;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'NEWTHING Mio'#10'Speed = 1'#10'Thing "Altro Nome" x'#10'Speed = 2'#10'Thing 007'#10'Speed = 3');
  Assert.IsTrue(LPatch.Section(0).Reference.IsNew);
  Assert.AreEqual('MIO', LPatch.Section(0).Reference.Name);
  Assert.IsTrue(LPatch.Section(1).Reference.IsNew);
  Assert.AreEqual('ALTRO NOME', LPatch.Section(1).Reference.Name);
  // un numero che non si scrive come e' (007) e' il nome di una nuova cosa
  Assert.IsTrue(LPatch.Section(2).Reference.IsNew);
  Assert.AreEqual('007', LPatch.Section(2).Reference.Name);
end;

procedure TTestDehackedParser.TestGliAliasDannoIlCampoCanonico;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Thing 1'#10'Radius = 5'#10'Width = 6'#10'Pain frame = 7'#10'Active sound = 8').Section(0);
  Assert.AreEqual('RADIUS', LSection[0].Key);
  Assert.AreEqual('WIDTH', LSection[0].FieldName);
  Assert.AreEqual(LSection[1].Field, LSection[0].Field);
  Assert.AreEqual('INJURY FRAME', LSection[2].FieldName);
  Assert.AreEqual('ACTION SOUND', LSection[3].FieldName);
end;

procedure TTestDehackedParser.TestIlTestoDeiCampiDelleCoseNonHaVirgolette;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Thing 1'#10'Obituary = "was shot"'#10'Translation = x').Section(0);
  Assert.AreEqual('WAS SHOT', LSection[0].Text);
  Assert.AreEqual('X', LSection[1].Text);
end;

procedure TTestDehackedParser.TestFlagsDiUnaCosaConNomiENumeri;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Thing 1'#10'Bits = SOLID+MF_SHOOTABLE | NOSUCH'#10'Bits = 12'#10 +
    'Bits = NOSUCH'#10'Flags_ex = MF_EX_REDLIGHT, WHITELIGHT').Section(0);
  Assert.IsTrue(LSection[0].HasFlags);
  Assert.AreEqual(2 or 4, LSection[0].Flags);
  Assert.IsTrue(LSection[1].HasFlags);
  Assert.AreEqual(12, LSection[1].Flags);
  Assert.IsFalse(LSection[2].HasFlags); // nessun nome noto: il campo non cambia
  Assert.AreEqual(2 or 4, LSection[3].Flags);
end;

procedure TTestDehackedParser.TestIBitAltiDiBitsSonoFlagExtra;
var
  LSection: TDehackedSection;
begin
  // MF_TRANSLUCENT, MF_UNUSED4, MF_UNUSED3 e MF_UNUSED2 sono i bit 31..28: non vanno nei flag
  LSection := Parse(dgDoom, 'Thing 1'#10'Bits = SOLID+TRANSLUCENT+UNUSED4+UNUSED3+UNUSED2').Section(0);
  Assert.AreEqual(2, LSection[0].Flags);
  Assert.AreEqual(15, LSection.ExtraFlags);
  LSection := Parse(dgDoom, 'Thing 1'#10'Bits = -2147483647').Section(0);
  Assert.AreEqual(1, LSection.ExtraFlags);
  LSection := Parse(dgDoom, 'Thing 1'#10'Bits = UNUSED4'#10'Speed = 1').Section(0);
  Assert.IsFalse(LSection[0].HasFlags);
  Assert.AreEqual(2, LSection.ExtraFlags);
end;

procedure TTestDehackedParser.TestICampiMbf21ImpostanoIlMarcatore;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Thing 1'#10'MBF21 Bits = MF2_BOSS + MBM21_RIP | NOSUCH'#10'Speed = 1').Section(0);
  Assert.IsTrue(LSection[0].Mbf21);
  Assert.IsTrue(LSection[0].HasFlags);
  Assert.AreEqual((1 shl 9) or (1 shl 17), LSection[0].Flags);
  Assert.IsFalse(LSection[1].Mbf21);
end;

procedure TTestDehackedParser.TestLeParoleChiaveDegliStatiDiUnaCosa;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Thing 1'#10'Initial frame = NEWFRAME 5'#10'Injury frame = ORIGINALSTATE 7'#10 +
    'Death frame = 9'#10'Far attack frame = NEWFRAME x'#10'Speed = NEWFRAME 5'#10'Respawn frame = ORIGINALFRAME').Section(0);
  Assert.AreEqual(Ord(srNew), Ord(LSection[0].StateRef.Kind));
  Assert.AreEqual(5, LSection[0].StateRef.Number);
  Assert.AreEqual(Ord(srOriginal), Ord(LSection[1].StateRef.Kind));
  Assert.AreEqual(7, LSection[1].StateRef.Number);
  Assert.AreEqual(Ord(srPlain), Ord(LSection[2].StateRef.Kind));
  Assert.AreEqual(9, LSection[2].StateRef.Number);
  // le due righe con il numero sbagliato sono avvisi e non campi; Speed non e' uno stato
  Assert.AreEqual(4, LSection.Count);
  Assert.AreEqual(Ord(srPlain), Ord(LSection[3].StateRef.Kind));
  Assert.AreEqual('I_Warning: DEH_Parse(): After NEWFRAME keyword found invalid numeric X (Think number = 0)|' +
    'I_Warning: DEH_Parse(): After ORIGINALFRAME keyword found invalid numeric  (Think number = 0)|', Warnings);
end;

procedure TTestDehackedParser.TestBits2NonEsisteInDoomEdEsisteInHeretic;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Thing 1'#10'Bits2 = 4'#10'Speed = 3').Section(0);
  Assert.AreEqual(1, LSection.Count);
  Assert.AreEqual('I_Warning: DEH_Parse(): Unsupported Doom field: "BITS2".|', Warnings);
  FRecorder.Clear;
  LSection := Parse(dgHeretic, 'Thing 1'#10'Bits2 = MF2_BOSS+RIP'#10'Speed = 3').Section(0);
  Assert.AreEqual(2, LSection.Count);
  Assert.AreEqual('BITS2', LSection[0].FieldName);
  Assert.AreEqual((1 shl 15) or (1 shl 8), LSection[0].Flags);
  Assert.AreEqual('', Warnings);
end;

procedure TTestDehackedParser.TestFrameNuovoEFrameConNome;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Frame NEW 3'#10'Duration = 5'#10'Frame 12'#10'Duration = 6'#10 +
    'Frame S_POSS_STND'#10'Duration = 7'#10'Frame NEWSTATE'#10'Duration = 8'#10'Frame NEW -2'#10'Duration = 9');
  Assert.AreEqual(3, LPatch.SectionCount);
  Assert.IsTrue(LPatch.Section(0).Reference.IsNew);
  Assert.AreEqual(3, LPatch.Section(0).Reference.Number);
  Assert.AreEqual(12, LPatch.Section(1).Reference.Number);
  Assert.AreEqual(-1, LPatch.Section(2).Reference.Number);
  Assert.AreEqual('S_POSS_STND', LPatch.Section(2).Reference.Name);
  Assert.AreEqual('I_Warning: DEH_Parse(): New state number unspecified after NEWSTATE keyword|' +
    'I_Warning: DEH_Parse(): Wrong new state number = -2|', Warnings);
end;

procedure TTestDehackedParser.TestIlProssimoStatoEIlNumeroDelloSprite;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Frame 5'#10'Next frame = NEW 4'#10'Next frame = ORIGINAL 6'#10'Next frame = 7'#10 +
    'Sprite subnumber = BRIGHT 3'#10'Sprite subnumber = 2').Section(0);
  Assert.AreEqual(Ord(srNew), Ord(LSection[0].StateRef.Kind));
  Assert.AreEqual(4, LSection[0].StateRef.Number);
  Assert.AreEqual(Ord(srOriginal), Ord(LSection[1].StateRef.Kind));
  Assert.AreEqual(Ord(srPlain), Ord(LSection[2].StateRef.Kind));
  Assert.AreEqual(7, LSection[2].Number);
  Assert.IsTrue(LSection[3].Bright);
  Assert.AreEqual(3, LSection[3].Number);
  Assert.IsFalse(LSection[4].Bright);
  Assert.AreEqual(2, LSection[4].Number);
end;

procedure TTestDehackedParser.TestLAzioneDiUnFrameHaNomeEArgomenti;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, 'Frame 5'#10'Codep frame = A_Explode(128, 4)'#10'Codep frame = 19'#10'Codep frame = Chase').Section(0);
  Assert.AreEqual('A_EXPLODE', LSection[0].ActionName);
  Assert.AreEqual('128, 4)', LSection[0].ActionArguments);
  Assert.AreEqual(19, LSection[1].Number);
  Assert.AreEqual('CHASE', LSection[2].ActionName);
  Assert.AreEqual('', LSection[2].ActionArguments);
end;

procedure TTestDehackedParser.TestWeaponDiDoomControllaIlNumeroEAmmoPerShot;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Weapon 2'#10'Ammo per shot = 5'#10'Ammo per shot = -1'#10'Select frame = NEWFRAME 3'#10 +
    'Weapon 9'#10'Select frame = 1'#10'Weapon WP_BFG'#10'Select frame = 2');
  Assert.AreEqual(2, LPatch.SectionCount);
  Assert.AreEqual(2, LPatch.Section(0).Count);
  Assert.AreEqual(Ord(srNew), Ord(LPatch.Section(0)[1].StateRef.Kind));
  // un nome lo risolve il motore
  Assert.AreEqual(-1, LPatch.Section(1).Reference.Number);
  Assert.AreEqual('WP_BFG', LPatch.Section(1).Reference.Name);
  Assert.AreEqual('I_Warning: DEH_Parse(): Positive number expected after keyword (AMMO PER SHOT) - (-1) (Weapon number = 2)|' +
    'I_Warning: DEH_Parse(): Wrong weapon number = 9|', Warnings);
end;

procedure TTestDehackedParser.TestWeaponDiHereticHaIlLivello;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgHeretic, 'Weapon 1'#10'Level = 2'#10'Select frame = 4'#10'Level = 3'#10'Level = 1'#10'Ammo per shot = 6').Section(0);
  Assert.AreEqual(4, LSection.Count);
  Assert.AreEqual('LEVEL', LSection[0].FieldName);
  Assert.AreEqual(2, LSection[0].Number);
  Assert.AreEqual(1, LSection[2].Number);
  Assert.AreEqual('I_Warning: DEH_Parse(): After LEVEL keyword found invalid level 3 (Weapon number = 1)|', Warnings);
end;

procedure TTestDehackedParser.TestWeaponDiHexenHaLaClasse;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgHexen, 'Weapon 2 Mage'#10'Select frame = 4'#10'Weapon 1 2'#10'Select frame = 5'#10 +
    'Weapon 1'#10'Select frame = 6'#10'Weapon 4 Mage'#10'Select frame = 7');
  Assert.AreEqual(2, LPatch.SectionCount);
  Assert.AreEqual('MAGE', LPatch.Section(0).Reference.Qualifier);
  Assert.AreEqual(-1, LPatch.Section(0).Reference.QualifierNumber);
  Assert.AreEqual(2, LPatch.Section(1).Reference.QualifierNumber);
  Assert.AreEqual('I_Warning: DEH_Parse(): Wrong weapon number = 4|', Warnings);
end;

procedure TTestDehackedParser.TestAmmoControllaIlNumero;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Ammo 1'#10'Max ammo = abc'#10'Per ammo = 7'#10'Ammo 4'#10'Max ammo = 1');
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(0, LPatch.Section(0)[0].Number); // il testo che non e' un numero vale zero
  Assert.AreEqual('I_Warning: DEH_Parse(): Wrong ammo number = 4|', Warnings);
  Assert.AreEqual(1, Parse(dgHeretic, 'Ammo 5'#10'Max ammo = 3').SectionCount);
end;

procedure TTestDehackedParser.TestMiscTerminaConUnValoreNegativo;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Misc'#10'Max health = 5'#10'Max armor = -1'#10'Blue armor class = 3');
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(1, LPatch.Section(0).Count);
  Assert.AreEqual('I_Warning: DEH_Parse(): Wrong misc value -1, field = MAX ARMOR|', Warnings);
end;

procedure TTestDehackedParser.TestSoundHaRiferimentoANumeroOANome;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Sound 5'#10'Value = 7'#10'Name = X'#10'Sound DSPISTOL'#10'Value = 8'#10'Sound 12x'#10'Value = 9');
  Assert.AreEqual(5, LPatch.Section(0).Reference.Number);
  Assert.AreEqual('DSPISTOL', LPatch.Section(1).Reference.Name);
  Assert.AreEqual(-1, LPatch.Section(1).Reference.Number);
  Assert.AreEqual(-1, LPatch.Section(2).Reference.Number);
  Assert.AreEqual('12X', LPatch.Section(2).Reference.Name);
  Assert.AreEqual(7, LPatch.Section(0)[0].Number);
end;

procedure TTestDehackedParser.TestParsDiDoomEDiHeretic;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, '[PARS]'#10'par 2 3 99'#10'par 5 70'#10'par 4 1 5'#10'par 33 1'#10'par 1'#10'Thing 1').Section(0);
  Assert.AreEqual(2, LSection.Count);
  Assert.AreEqual(3, Length(LSection[0].Numbers));
  Assert.AreEqual(99, LSection[0].Numbers[2]);
  Assert.AreEqual(5, LSection[1].Numbers[0]);
  Assert.AreEqual('', Warnings);
  LSection := Parse(dgHeretic, '[PARS]'#10'par 5 9 1'#10'par 4 1'#10'par 6 1 1').Section(0);
  Assert.AreEqual(1, LSection.Count);
  Assert.AreEqual('I_Warning: DEH_Parse(): Wrong misc value 4, field = PAR|', Warnings);
end;

procedure TTestDehackedParser.TestStringsUniscaLeRigheConLaBarraInversa;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, '[STRINGS]'#10'GOTARMOR = Picked\'#10'  up\'#10'# c'#10'  armor'#10'GGSAVED = ok'#10'x'#10).Section(0);
  Assert.AreEqual(2, LSection.Count);
  Assert.AreEqual('GOTARMOR', LSection[0].Key);
  // il tratto di unione e' un a capo; i bordi sono tagliati
  Assert.AreEqual('PICKED'#10'UP'#10'ARMOR', LSection[0].Text);
  Assert.AreEqual('OK', LSection[1].Text);
end;

procedure TTestDehackedParser.TestTextLeggeIlTestoVecchioEIlNuovo;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Text 5 3'#10'abcdWXYZ'#10'Text 3 2'#10'abc'#10'de'#10'Text 0 1'#10'x'#10'Text 3 3'#10'xyz');
  Assert.AreEqual(3, LPatch.SectionCount);
  Assert.AreEqual('ABCDW', LPatch.Section(0).OldText);
  Assert.AreEqual('XYZ', LPatch.Section(0).NewText);
  Assert.AreEqual(5, LPatch.Section(0).OldLength);
  // due righe: il testo nuovo comincia con un a capo (e il suo numero e' quello ricalcolato)
  Assert.AreEqual('ABC', LPatch.Section(1).OldText);
  Assert.AreEqual(#10'DE', LPatch.Section(1).NewText);
  Assert.AreEqual(3, LPatch.Section(1).NewLength);
  // old text only and the line break after it: a new text of one character (as the old code)
  Assert.AreEqual('XYZ', LPatch.Section(2).OldText);
  Assert.AreEqual(#10, LPatch.Section(2).NewText);
end;

procedure TTestDehackedParser.TestPointerLeggeIlFotogrammaDaCopiare;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Pointer 7 (Frame 17)'#10'Codep Frame = 18'#10'Pointer 8 (Weapon 1)'#10'Codep Frame = 3'#10 +
    'Pointer 9 (Frame 5)'#10'Duration = 4');
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(17, LPatch.Section(0).Reference.Number);
  Assert.AreEqual(18, LPatch.Section(0)[0].Number);
end;

procedure TTestDehackedParser.TestCodePointerHaIlNumeroEIlNome;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, '[CODEPTR]'#10'Frame 30 = Explode(128)'#10'Thing 3 = Look'#10'Frame x = Look'#10'Frame 31 = 19').Section(0);
  Assert.AreEqual(2, LSection.Count);
  Assert.AreEqual(30, LSection[0].Numbers[0]);
  Assert.AreEqual('EXPLODE', LSection[0].ActionName);
  Assert.AreEqual('128)', LSection[0].ActionArguments);
  Assert.AreEqual(19, LSection[1].Number);
end;

procedure TTestDehackedParser.TestMusicESoundsHannoChiaveETesto;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, '[MUSIC]'#10'1 = d_one extra'#10'E1M2 = D_TWO'#10'[SOUNDS]'#10'3 = DSX more'#10'dspistol = DSY');
  Assert.AreEqual('D_ONE', LPatch.Section(0)[0].Text);
  Assert.AreEqual(1, LPatch.Section(0)[0].Number);
  Assert.AreEqual(-1, LPatch.Section(0)[1].Number);
  Assert.AreEqual('E1M2', LPatch.Section(0)[1].Key);
  Assert.AreEqual('DSX MORE', LPatch.Section(1)[0].Text);
  Assert.AreEqual('[SOUNDS]', LPatch.Section(1).Keyword);
end;

procedure TTestDehackedParser.TestMusicDiHexenConLeParentesi;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgHexen, '[MUSIC]'#10'1 = (none)'#10'2 = MUS_X ignored').Section(0);
  Assert.IsTrue(LSection[0].Cleared);
  Assert.AreEqual('', LSection[0].Text);
  Assert.IsFalse(LSection[1].Cleared);
  Assert.AreEqual('MUS_X', LSection[1].Text);
  LSection := Parse(dgDoom, '[MUSIC]'#10'1 = (none)').Section(0);
  Assert.IsFalse(LSection[0].Cleared);
  Assert.AreEqual('(NONE)', LSection[0].Text);
end;

procedure TTestDehackedParser.TestSpritesControllaLaLunghezzaDelNuovoNome;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgDoom, '[SPRITES]'#10'TROO = abcd'#10'1 = abc'#10'SHTG = abcde'#10'TOOLONG = wxyz').Section(0);
  Assert.AreEqual(2, LSection.Count);
  Assert.AreEqual('TROO', LSection[0].Key);
  Assert.AreEqual('ABCD', LSection[0].Text);
  Assert.AreEqual('TOOLONG', LSection[1].Key);
  Assert.AreEqual('I_Warning: DEH_Parse(): Sprite name with 3 characters = ABC|' +
    'I_Warning: DEH_Parse(): Sprite name with 5 characters = ABCDE|', Warnings);
end;

procedure TTestDehackedParser.TestCheatELeNuoveFrameNonLeggonoRighe;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgDoom, 'Cheat 0'#10'Change music = idmus'#10'Thing 4'#10'Speed = 2');
  Assert.AreEqual(2, LPatch.SectionCount);
  Assert.AreEqual(dskCheat, LPatch.Section(0).Kind);
  Assert.AreEqual(0, LPatch.Section(0).Count);
  Assert.AreEqual(dskThing, LPatch.Section(1).Kind);
end;

procedure TTestDehackedParser.TestHexenNonHaAmmoNePars;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgHexen, 'Ammo 1'#10'Max ammo = 5'#10'[PARS]'#10'par 1 1 1'#10'Thing 1'#10'Speed = 2');
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(dskThing, LPatch.Section(0).Kind);
  Assert.AreEqual('', Warnings);
  LPatch := Parse(dgStrife, '[PARS]'#10'par 1 1 1'#10'Ammo 6'#10'Max ammo = 5');
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(dskAmmo, LPatch.Section(0).Kind);
end;

procedure TTestDehackedParser.TestHexenHaMaxManaSoloNelMisc;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse(dgHexen, 'Max Mana 150'#10'Max Mana'#10'Max Mana x'#10'Misc'#10'Max Morph Health = 5');
  // difetto del vecchio codice conservato: il blocco 'MAX MANA' non veniva mai letto, perche' la parola
  // di una riga e' tagliata al primo spazio; il massimo di mana e' il campo MAX MANA di Misc
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(dskMisc, LPatch.Section(0).Kind);
  Assert.AreEqual('MAX MORPH HEALTH', LPatch.Section(0)[0].FieldName);
  LPatch := Parse(dgHexen, 'Misc'#10'Max Mana = 150');
  Assert.AreEqual('MAX MANA', LPatch.Section(0)[0].FieldName);
end;

procedure TTestDehackedParser.TestStrifeHaNome2ENonHaIFlagExtra;
var
  LSection: TDehackedSection;
begin
  LSection := Parse(dgStrife, 'Thing 1'#10'Name2 = other').Section(0);
  Assert.AreEqual('NAME2', LSection[0].FieldName);
  Assert.AreEqual(0, LSection.ExtraFlags);
  // senza i bit extra i flag alti sono flag come gli altri: MF_COLORSWAP1 e' il bit 28
  LSection := Parse(dgStrife, 'Thing 1'#10'Bits = SOLID+COLORSWAP1+ALLY').Section(0);
  Assert.AreEqual(2 or (1 shl 28) or (1 shl 26), LSection[0].Flags);
  Assert.AreEqual(0, LSection.ExtraFlags);
end;

procedure TTestDehackedParser.TestIProfiliHannoIlNomeDelGioco;
var
  LGame, LOther: TDehackedGame;
begin
  for LGame := Low(TDehackedGame) to High(TDehackedGame) do
  begin
    Assert.AreEqual(TDehackedGames.NameOf(LGame), TDehackedGames.CreateProfile(LGame, nil).GameName);
    Assert.IsTrue(TDehackedGames.TryFromName(LowerCase(TDehackedGames.NameOf(LGame)), LOther));
    Assert.AreEqual(Ord(LGame), Ord(LOther));
  end;
  Assert.IsFalse(TDehackedGames.TryFromName('QUAKE', LOther));
end;

end.
