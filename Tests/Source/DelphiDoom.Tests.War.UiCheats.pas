{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the cheats                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiCheats;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game,
  DelphiDoom.War.Ui.CheatsPanel, DelphiDoom.Tests.War.UiFakes;

type
  /// <summary>The string functions of the cheats, the table, the effects on the settings and the panel of the menu</summary>
  [TestFixture]
  [Category('war')]
  TTestWarUiCheats = class(TObject)
  private
    FSprites: IWarUiSprites;
    FAudio: TFakeAudio;
    FAudioRef: IWarSceneAudio;
    FGame: TWarUiGame;
    FPanel: TWarCheatsPanel;
    procedure Tick(ACount: Integer = 1);
    procedure PressKey(AKey: TWarKey);
    procedure OpenPanel;
    procedure TypeAndEnter(const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeConfrontareSenzaMaiuscoleEMinuscoleSoloLeLettereAscii;
    [Test]
    procedure DovrebbeTogliereGliSpaziASinistraEADestra;
    [TestCase('decimale', '12,12,True')]
    [TestCase('con segno', '-7,-7,True')]
    [TestCase('esadecimale', '0x1F,31,True')]
    [TestCase('ottale', '010,8,True')]
    [TestCase('con spazi', '  42  ,42,True')]
    [TestCase('lettere', '12a,0,False')]
    [TestCase('vuoto', ',0,False')]
    [TestCase('solo il segno', '+,0,False')]
    [TestCase('cifra ottale sbagliata', '08,0,False')]
    [TestCase('oltre i 32 bit', '2147483648,0,False')]
    [TestCase('il minimo', '-2147483648,-2147483648,True')]
    [TestCase('solo 0x', '0x,0,False')]
    procedure DovrebbeLeggereUnIntero(const AText: string; AExpected: Integer; AOk: Boolean);
    [Test]
    procedure DovrebbeTrovareUnTruccoSenzaArgomentoSoloSeEIdenticoSenzaMaiuscole;
    [Test]
    procedure DovrebbeTrovareUnTruccoConArgomentoDalSuoInizio;
    [Test]
    procedure DovrebbeScegliereIlPrimoDellaTabellaEMusicVolPrimaDiMusic;
    [Test]
    procedure DovrebbeRifiutareUnTestoCheNonETrucco;
    [Test]
    procedure DovrebbeAccendereESpegnereITrucchiConCorwinOfAmber;
    [Test]
    procedure DovrebbeNonFareNulla;
    [Test]
    procedure DovrebbeCambiareIlVolumeArrotondandoAMultipliDiCinque;
    [Test]
    procedure DovrebbeCambiareScalaEVelocitaConLimiti;
    [Test]
    procedure DovrebbeAccendereESpegnereMusicaESuoni;
    [Test]
    procedure DovrebbeSuonareLaMusicaScelta;
    [Test]
    procedure DovrebbeRifiutareLaMusicaNellaDemoOFuoriDaiLimiti;
    [Test]
    procedure DovrebbeLasciareLeImpostazioniConLeLimitazioniDelleSette;
    [Test]
    procedure DovrebbeAprireIlPannelloConInvioEScrivere;
    [Test]
    procedure DovrebbeIgnorareIlTestoCheArrivaAPannelloChiuso;
    [Test]
    procedure DovrebbeFermarsiA31CaratteriMaAccettareLaTabulazioneFinoA39;
    [Test]
    procedure DovrebbeTagliareLaRigaDiUscitaA39Caratteri;
    [Test]
    procedure DovrebbeModificareLaRigaConIlCursore;
    [Test]
    procedure DovrebbeChiudereConEscSenzaApplicare;
    [Test]
    procedure DovrebbeApplicareConInvioEMostrareIlMessaggioPerTreSecondi;
    [Test]
    procedure DovrebbeSaltareICaratteriFuoriDaAsciiStampabile;
    [Test]
    procedure DovrebbeMostrareIlTestoDiDebugSenzaMessaggio;
    [Test]
    procedure DovrebbeMisurareLaPosizioneDelCursore;
    [Test]
    procedure DovrebbeFarFunzionareITastiRapidiAncheConIlPannelloAperto;
  end;

implementation

uses
  DelphiDoom.War.Ui.Strings, DelphiDoom.War.Ui.CheatTable, DelphiDoom.War.Ui.GameSettings,
  DelphiDoom.War.Ui.SettingsCheatEffects, DelphiDoom.War.Ui.SceneBase, DelphiDoom.War.Ui.SceneMainMenu;

{ TTestWarUiCheats }

procedure TTestWarUiCheats.Setup;
var
  LSprites: TFakeUiSprites;
begin
  LSprites := TFakeUiSprites.Create;
  FSprites := LSprites;
  FAudio := TFakeAudio.Create;
  FAudioRef := FAudio;
  FGame := TFakeUiRig.CreateGame(FSprites, FAudioRef, nil, False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateMainMenu, 0);
  Tick(2);
  FPanel := (FGame.Manager.Scene as TWarSceneBase).CheatsPanel;
end;

procedure TTestWarUiCheats.TearDown;
begin
  FreeAndNil(FGame);
  FAudioRef := nil;
  FSprites := nil;
end;

procedure TTestWarUiCheats.Tick(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
  begin
    FGame.Manager.RunFrame(Single(1) / Single(60));
    FGame.Manager.BeginInputFrame;
  end;
end;

procedure TTestWarUiCheats.PressKey(AKey: TWarKey);
begin
  FGame.Input.SetKey(AKey, True);
  FGame.Input.SetKey(AKey, False);
  Tick;
end;

procedure TTestWarUiCheats.OpenPanel;
begin
  PressKey(wkEnter);
  Assert.IsTrue(FPanel.Visible, 'aperto');
end;

procedure TTestWarUiCheats.TypeAndEnter(const AText: AnsiString);
begin
  OpenPanel;
  FGame.Manager.HandleTextInput(AText);
  PressKey(wkEnter);
end;

procedure TTestWarUiCheats.DovrebbeConfrontareSenzaMaiuscoleEMinuscoleSoloLeLettereAscii;
begin
  Assert.IsTrue(TWarStrings.EqualsIgnoreCase('Pot Of GOLD', 'pot of gold'));
  Assert.IsFalse(TWarStrings.EqualsIgnoreCase('abc', 'abcd'));
  Assert.IsFalse(TWarStrings.EqualsIgnoreCase('a', 'b'));
  Assert.IsTrue(TWarStrings.StartsWithIgnoreCase('MUSIC 5', 'music'));
  Assert.IsFalse(TWarStrings.StartsWithIgnoreCase('mu', 'music'));
end;

procedure TTestWarUiCheats.DovrebbeTogliereGliSpaziASinistraEADestra;
begin
  Assert.AreEqual<AnsiString>('a b ', TWarStrings.TrimLeft(#9' a b '));
  Assert.AreEqual<AnsiString>('a b', TWarStrings.Trim(' '#13#10'a b '#11));
  Assert.AreEqual<AnsiString>('', TWarStrings.Trim('   '));
end;

procedure TTestWarUiCheats.DovrebbeLeggereUnIntero(const AText: string; AExpected: Integer; AOk: Boolean);
var
  LValue: Integer;
begin
  Assert.AreEqual(AOk, TWarStrings.TryParseS32(AnsiString(AText), LValue));
  if AOk then
    Assert.AreEqual(AExpected, LValue);
end;

procedure TTestWarUiCheats.DovrebbeTrovareUnTruccoSenzaArgomentoSoloSeEIdenticoSenzaMaiuscole;
var
  LDescriptor: TWarCheatDescriptor;
  LArgument: AnsiString;
begin
  Assert.IsTrue(TWarCheatTable.Match('pot OF gold', LDescriptor, LArgument));
  Assert.AreEqual<AnsiString>('Pot of gold', LDescriptor.Text);
  Assert.IsFalse(TWarCheatTable.Match('Pot of gold now', LDescriptor, LArgument));
end;

procedure TTestWarUiCheats.DovrebbeTrovareUnTruccoConArgomentoDalSuoInizio;
var
  LDescriptor: TWarCheatDescriptor;
  LArgument: AnsiString;
begin
  Assert.IsTrue(TWarCheatTable.Match('scale   3', LDescriptor, LArgument));
  Assert.AreEqual<AnsiString>('Scale', LDescriptor.Text);
  Assert.AreEqual<AnsiString>('3', LArgument);
  // the start is enough: "Scaled" is Scale with the argument "d"
  Assert.IsTrue(TWarCheatTable.Match('Scaled', LDescriptor, LArgument));
  Assert.AreEqual<AnsiString>('d', LArgument);
  Assert.AreEqual(24, Length(TWarCheatTable.Descriptors));
end;

procedure TTestWarUiCheats.DovrebbeScegliereIlPrimoDellaTabellaEMusicVolPrimaDiMusic;
var
  LDescriptor: TWarCheatDescriptor;
  LArgument: AnsiString;
begin
  Assert.IsTrue(TWarCheatTable.Match('Music vol 50', LDescriptor, LArgument));
  Assert.AreEqual<AnsiString>('Music vol', LDescriptor.Text);
  Assert.AreEqual<AnsiString>('50', LArgument);
  Assert.IsTrue(TWarCheatTable.Match('Music 7', LDescriptor, LArgument));
  Assert.AreEqual<AnsiString>('Music', LDescriptor.Text);
end;

procedure TTestWarUiCheats.DovrebbeRifiutareUnTestoCheNonETrucco;
var
  LDescriptor: TWarCheatDescriptor;
  LArgument: AnsiString;
begin
  Assert.IsFalse(TWarCheatTable.Match('hello', LDescriptor, LArgument));
  Assert.AreEqual<AnsiString>('', LDescriptor.Text);
end;

procedure TTestWarUiCheats.DovrebbeAccendereESpegnereITrucchiConCorwinOfAmber;
var
  LSettings: IWarGameSettings;
  LEffects: IWarCheatEffects;
begin
  LSettings := TWarGameSettings.Create;
  LEffects := TWarSettingsCheatEffects.Create(LSettings, nil, False);
  Assert.AreEqual<AnsiString>('cheats disabled', LEffects.Apply('Corwin of Amber', ''));
  Assert.IsFalse(LSettings.CheatsEnabled);
  // without the cheats nothing else works
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Scale', '3'));
  Assert.AreEqual<AnsiString>('cheats enabled', LEffects.Apply('Corwin of Amber', ''));
  Assert.IsTrue(LSettings.CheatsEnabled);
end;

procedure TTestWarUiCheats.DovrebbeNonFareNulla;
var
  LSettings: IWarGameSettings;
  LEffects: IWarCheatEffects;
begin
  LSettings := TWarGameSettings.Create;
  LEffects := TWarSettingsCheatEffects.Create(LSettings, nil, False);
  // the cheats of the map do nothing without a map; and the ones that have no argument number
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Pot of gold', ''));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Debug render', 'status'));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Scale', 'x'));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Speed', ''));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Music vol', 'x'));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Sound vol', 'x'));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Sound', 'maybe'));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Music', 'maybe'));
end;

procedure TTestWarUiCheats.DovrebbeCambiareIlVolumeArrotondandoAMultipliDiCinque;
var
  LSettings: IWarGameSettings;
  LEffects: IWarCheatEffects;
begin
  LSettings := TWarGameSettings.Create;
  LEffects := TWarSettingsCheatEffects.Create(LSettings, nil, False);
  Assert.AreEqual<AnsiString>('Music volume set to 45', LEffects.Apply('Music vol', '47'));
  Assert.AreEqual(0.45, Double(LSettings.MusicVolume), 0.00001);
  Assert.AreEqual<AnsiString>('Music volume set to 50', LEffects.Apply('Music vol', '48'));
  Assert.AreEqual<AnsiString>('Music volume set to 50', LEffects.Apply('Music vol', '51'));
  Assert.AreEqual<AnsiString>('Music volume set to 55', LEffects.Apply('Music vol', '54'));
  Assert.AreEqual<AnsiString>('Music volume set to 100', LEffects.Apply('Music vol', '150'));
  Assert.AreEqual<AnsiString>('Music volume set to 0', LEffects.Apply('Music vol', '-9'));
  Assert.AreEqual<AnsiString>('Sounds volume set to 20', LEffects.Apply('Sound vol', '20'));
  Assert.AreEqual(0.2, Double(LSettings.SoundVolume), 0.00001);
  Assert.IsTrue(LSettings.AudioEnabled);
end;

procedure TTestWarUiCheats.DovrebbeCambiareScalaEVelocitaConLimiti;
var
  LSettings: IWarGameSettings;
  LEffects: IWarCheatEffects;
begin
  LSettings := TWarGameSettings.Create;
  LEffects := TWarSettingsCheatEffects.Create(LSettings, nil, False);
  Assert.AreEqual<AnsiString>('Global scale set to 5', LEffects.Apply('Scale', '9'));
  Assert.AreEqual(5, RoundInt(LSettings.GlobalScale));
  Assert.AreEqual<AnsiString>('Global scale set to 1', LEffects.Apply('Scale', '0'));
  Assert.AreEqual<AnsiString>('Global speed set to 3', LEffects.Apply('Speed', '3'));
  Assert.AreEqual(3, RoundInt(LSettings.GlobalSpeed));
  Assert.AreEqual<AnsiString>('Global speed set to 1', LEffects.Apply('Speed', '-4'));
  // the setters themselves never go under 1 (scale, speed) and stay between 0 and 1 (the volumes)
  LSettings.SetGlobalSpeed(0.5);
  Assert.AreEqual(1, RoundInt(LSettings.GlobalSpeed));
  LSettings.SetGlobalScale(0);
  Assert.AreEqual(1, RoundInt(LSettings.GlobalScale));
  LSettings.SetMusicVolume(3);
  Assert.AreEqual(1, RoundInt(LSettings.MusicVolume));
  LSettings.SetSoundVolume(-3);
  Assert.AreEqual(0, RoundInt(LSettings.SoundVolume));
  LSettings.SetSoundVolume(0.5);
  Assert.AreEqual(0.5, Double(LSettings.SoundVolume), 0.00001);
  LSettings.SetMusicVolume(0.25);
  Assert.AreEqual(0.25, Double(LSettings.MusicVolume), 0.00001);
end;

procedure TTestWarUiCheats.DovrebbeAccendereESpegnereMusicaESuoni;
var
  LSettings: IWarGameSettings;
  LEffects: IWarCheatEffects;
begin
  LSettings := TWarGameSettings.Create;
  LEffects := TWarSettingsCheatEffects.Create(LSettings, nil, False);
  Assert.AreEqual<AnsiString>('Music off', LEffects.Apply('Music', 'OFF'));
  Assert.IsFalse(LSettings.MusicEnabled);
  Assert.AreEqual<AnsiString>('Music on', LEffects.Apply('Music', 'on'));
  Assert.IsTrue(LSettings.MusicEnabled);
  Assert.AreEqual<AnsiString>('Sounds off', LEffects.Apply('Sound', 'off'));
  Assert.IsFalse(LSettings.SoundEnabled);
  Assert.AreEqual<AnsiString>('Sounds on', LEffects.Apply('Sound', 'on'));
  Assert.IsTrue(LSettings.SoundEnabled);
  LSettings.AudioEnabled := False;
  Assert.IsFalse(LSettings.AudioEnabled);
end;

procedure TTestWarUiCheats.DovrebbeSuonareLaMusicaScelta;
var
  LSettings: IWarGameSettings;
  LEffects: IWarCheatEffects;
begin
  LSettings := TWarGameSettings.Create;
  LEffects := TWarSettingsCheatEffects.Create(LSettings, FAudioRef, False);
  Assert.AreEqual<AnsiString>('Music 12 set', LEffects.Apply('Music', '12'));
  Assert.AreEqual(1, FAudio.MusicStops);
  Assert.AreEqual(11, FAudio.Played[FAudio.Played.Count - 1]);
  Assert.IsTrue(FAudio.Loops[FAudio.Loops.Count - 1]);
end;

procedure TTestWarUiCheats.DovrebbeRifiutareLaMusicaNellaDemoOFuoriDaiLimiti;
var
  LSettings: IWarGameSettings;
  LEffects: IWarCheatEffects;
begin
  LSettings := TWarGameSettings.Create;
  LEffects := TWarSettingsCheatEffects.Create(LSettings, FAudioRef, True);
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Music', '12'), 'demo');
  LEffects := TWarSettingsCheatEffects.Create(LSettings, FAudioRef, False);
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Music', '0'));
  Assert.AreEqual<AnsiString>('', LEffects.Apply('Music', '46'));
  Assert.AreEqual<AnsiString>('Music 45 set', LEffects.Apply('Music', '45'));
  Assert.AreEqual<AnsiString>('Music 1 set', LEffects.Apply('Music', '1'));
end;

procedure TTestWarUiCheats.DovrebbeLasciareLeImpostazioniConLeLimitazioniDelleSette;
var
  LSettings: IWarGameSettings;
begin
  LSettings := TWarGameSettings.Create;
  Assert.IsTrue(LSettings.CheatsEnabled, 'wg_initGame li accende');
  LSettings.CheatsEnabled := False;
  Assert.IsFalse(LSettings.CheatsEnabled);
end;

procedure TTestWarUiCheats.DovrebbeAprireIlPannelloConInvioEScrivere;
begin
  Assert.IsTrue(FPanel.Enabled);
  Assert.IsFalse(FPanel.Visible);
  OpenPanel;
  Assert.IsTrue(FGame.Manager.TextInputActive, 'la finestra riceve il testo');
  FGame.Manager.HandleTextInput('Hi');
  Assert.AreEqual<AnsiString>('Hi', FPanel.Text);
  Assert.AreEqual(2, FPanel.Position);
end;

procedure TTestWarUiCheats.DovrebbeIgnorareIlTestoCheArrivaAPannelloChiuso;
begin
  FGame.Manager.HandleTextInput('abc');
  Assert.AreEqual<AnsiString>('', FPanel.Text);
end;

procedure TTestWarUiCheats.DovrebbeFermarsiA31CaratteriMaAccettareLaTabulazioneFinoA39;
var
  LIndex: Integer;
begin
  OpenPanel;
  FGame.Manager.HandleTextInput(AnsiString(StringOfChar('a', 40)));
  Assert.AreEqual(31, Length(FPanel.Text), 'i caratteri si fermano a 31');
  for LIndex := 1 to 10 do
    PressKey(wkTab);
  // the Tab is checked against 40: it goes in while the line has at most 38 characters
  Assert.AreEqual(39, Length(FPanel.Text));
end;

procedure TTestWarUiCheats.DovrebbeTagliareLaRigaDiUscitaA39Caratteri;
var
  LIndex: Integer;
begin
  OpenPanel;
  FGame.Manager.HandleTextInput(AnsiString(StringOfChar('b', 31)));
  for LIndex := 1 to 5 do
    PressKey(wkTab);
  Assert.AreEqual(36, Length(FPanel.Text));
  // "MSG: " and the text are cut to 39 characters in the line that is drawn: no exception, the frame is drawn
  Tick(2);
  Assert.IsTrue(FPanel.CursorX > 0);
end;

procedure TTestWarUiCheats.DovrebbeModificareLaRigaConIlCursore;
begin
  OpenPanel;
  FGame.Manager.HandleTextInput('abcd');
  PressKey(wkLeft);
  PressKey(wkLeft);
  Assert.AreEqual(2, FPanel.Position);
  FGame.Manager.HandleTextInput('X');
  Assert.AreEqual<AnsiString>('abXcd', FPanel.Text);
  PressKey(wkBackspace);
  Assert.AreEqual<AnsiString>('abcd', FPanel.Text);
  PressKey(wkDelete);
  Assert.AreEqual<AnsiString>('abd', FPanel.Text);
  PressKey(wkHome);
  Assert.AreEqual(0, FPanel.Position);
  PressKey(wkBackspace);
  Assert.AreEqual<AnsiString>('abd', FPanel.Text, 'Backspace all''inizio non cancella');
  PressKey(wkLeft);
  Assert.AreEqual(0, FPanel.Position);
  PressKey(wkRight);
  Assert.AreEqual(1, FPanel.Position);
  PressKey(wkEnd);
  Assert.AreEqual(3, FPanel.Position);
  PressKey(wkRight);
  Assert.AreEqual(3, FPanel.Position);
  PressKey(wkDelete);
  Assert.AreEqual<AnsiString>('abd', FPanel.Text, 'Canc alla fine non cancella');
end;

procedure TTestWarUiCheats.DovrebbeChiudereConEscSenzaApplicare;
begin
  OpenPanel;
  FGame.Manager.HandleTextInput('Corwin of Amber');
  PressKey(wkEsc);
  Assert.IsFalse(FPanel.Visible);
  Assert.IsFalse(FGame.Manager.TextInputActive);
  Assert.IsTrue(FGame.Settings.CheatsEnabled, 'non applicato');
  Assert.AreEqual<AnsiString>('', FPanel.Text);
end;

procedure TTestWarUiCheats.DovrebbeApplicareConInvioEMostrareIlMessaggioPerTreSecondi;
begin
  TypeAndEnter('Corwin of Amber');
  Assert.IsFalse(FPanel.Visible);
  Assert.IsFalse(FGame.Settings.CheatsEnabled);
  Assert.IsTrue(FPanel.Feedback);
  Assert.AreEqual<AnsiString>('cheats disabled', FPanel.FeedbackText);
  Tick(170);
  Assert.IsTrue(FPanel.Feedback, 'ancora entro tre secondi');
  Tick(20);
  Assert.IsFalse(FPanel.Feedback, 'dopo tre secondi');
  // an unknown text does nothing and shows nothing
  TypeAndEnter('xyz');
  Assert.IsFalse(FPanel.Feedback);
end;

procedure TTestWarUiCheats.DovrebbeSaltareICaratteriFuoriDaAsciiStampabile;
begin
  OpenPanel;
  FGame.Manager.HandleTextInput(AnsiString('a'#1#127#200'b'));
  Assert.AreEqual<AnsiString>('ab', FPanel.Text);
end;

procedure TTestWarUiCheats.DovrebbeMostrareIlTestoDiDebugSenzaMessaggio;
begin
  FPanel.SetDebugText('line 1'#10'line 2');
  Tick(2);
  FPanel.SetFeedback('feedback');
  Tick;
  FPanel.SetFeedback('');
  Assert.IsFalse(FPanel.Feedback);
  Tick;
  FPanel.SetDebugText('');
  Tick;
end;

procedure TTestWarUiCheats.DovrebbeMisurareLaPosizioneDelCursore;
var
  LAtStart: Single;
begin
  OpenPanel;
  LAtStart := FPanel.CursorX;
  FGame.Manager.HandleTextInput('ab');
  Tick;
  Assert.IsTrue(FPanel.CursorX > LAtStart, 'avanza con il testo');
  PressKey(wkEsc);
  Assert.AreEqual(-1, RoundInt(FPanel.CursorX), 'chiuso: nessun cursore');
end;

procedure TTestWarUiCheats.DovrebbeFarFunzionareITastiRapidiAncheConIlPannelloAperto;
begin
  // a defect of the original: only a map turns the hotkeys off while the panel is open
  OpenPanel;
  FGame.Manager.HandleTextInput('ab');
  PressKey(wkS);
  Assert.AreEqual(Ord(wmpSinglePlayer), Ord((FGame.Manager.Scene as TWarSceneMainMenu).MenuPanel));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarUiCheats);

end.
