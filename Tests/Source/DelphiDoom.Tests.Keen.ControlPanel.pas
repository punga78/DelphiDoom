{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the control panel, driven by    }
{  the keys of a script                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.ControlPanel;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf,
  DelphiDoom.Tests.Keen.UiWorld;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenControlPanel = class(TObject)
  strict private
    FWorld: TKeenUiWorld;
    FState: IKeenUserState;
    FFiles: TUiFakeFiles;
    FFilesIntf: IKeenUserFiles;
    FSlots: IKeenSaveSlots;
    FPanel: IKeenControlPanel;
    FSound: IKeenSoundManager;
    FSoundLog: TStringList;
    FHooksLog: TStringList;
    FHooks: IKeenGameHooks;
    procedure Make(const AScript: string; AInGame: Boolean; AWithHelp: Boolean = True;
      const AGraphics: IKeenGraphics = nil);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure EscapeDovrebbeChiudereIlPannelloSenzaCambiareNulla;
    [Test]
    procedure IlPannelloDovrebbeDisegnareLeTreFinestre;
    [Test]
    procedure F5EInvioDovrebberoFarPartireUnaPartitaNormale;
    [Test]
    procedure LeFrecceDovrebberoPortareAlBottoneDellaPartitaFacile;
    [Test]
    procedure UnaNuovaPartitaDuranteIlGiocoDovrebbeAzzerareQuellaInCorso;
    [Test]
    procedure InGiocoInvioDovrebbeRiprendereLaPartita;
    [Test]
    procedure IlTastoDelSuonoDovrebbeCambiareLaModalitaAllUscita;
    [Test]
    procedure UnDispositivoDisabilitatoNonDovrebbeEssereScelto;
    [Test]
    procedure DovrebbeRidefinireUnTastoDellaTastiera;
    [Test]
    procedure UnTastoGiaUsatoNonDovrebbeEssereAccettato;
    [Test]
    procedure DovrebbeSalvareLaPartitaConIlNomeBattuto;
    [Test]
    procedure DovrebbeCaricareUnaPartitaSalvata;
    [Test]
    procedure UnCaricamentoFallitoDovrebbeChiedereDiAbbandonareLaPartita;
    [Test]
    procedure SenzaPartitaIlSalvataggioDovrebbeEssereDisabilitato;
    [Test]
    procedure LUscitaAlDosDovrebbeEssereUnEccezioneDiUscita;
    [Test]
    procedure LAiutoDovrebbeScorrereEChiudersiConEscape;
    [Test]
    procedure SenzaTestiLAiutoDovrebbeDareUnErrore;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
    [Test]
    procedure ConIDatiVeriDovrebbeFarPartireUnaPartita;
  end;

implementation

uses
  DelphiDoom.Keen.ControlPanel, DelphiDoom.Keen.UserState, DelphiDoom.Keen.SaveSlots, DelphiDoom.Keen.Factory,
  DelphiDoom.Tests.Keen.RealData, DelphiDoom.Tests.Shared.Skip;

type
  TLogSound = class(TInterfacedObject, IKeenSoundManager)
  strict private
    FLog: TStringList;
    FMode: TKeenSoundMode;
  public
    constructor Create(ALog: TStringList);
    function GetMode: TKeenSoundMode;
    procedure SetMode(AMode: TKeenSoundMode);
    procedure PlaySound(ASound: Integer);
    procedure StopSound;
    function SoundPlaying: Integer;
    procedure Service;
    procedure WaitSoundDone;
    function AdLibPresent: Boolean;
    function TrySetMode(AMode: TKeenSoundMode): Boolean;
    procedure SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
  end;

  TLogHooks = class(TInterfacedObject, IKeenGameHooks)
  strict private
    FLog: TStringList;
  public
    Accept: Boolean;
    constructor Create(ALog: TStringList);
    function LoadGame(AStream: TStream): Boolean;
    function SaveGame(AStream: TStream): Boolean;
    procedure ResetGame;
  end;

  TFakeHelp = class(TInterfacedObject, IKeenHelpTexts)
  public
    function TryGetText(AIndex: Integer; out AText: TBytes): Boolean;
  end;

{ TLogSound }

constructor TLogSound.Create(ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
  FMode := ksmAdLib;
end;

function TLogSound.GetMode: TKeenSoundMode;
begin
  Result := FMode;
end;

procedure TLogSound.SetMode(AMode: TKeenSoundMode);
begin
  FMode := AMode;
end;

procedure TLogSound.PlaySound(ASound: Integer);
begin
end;

procedure TLogSound.StopSound;
begin
end;

function TLogSound.SoundPlaying: Integer;
begin
  Result := 0;
end;

procedure TLogSound.Service;
begin
end;

procedure TLogSound.WaitSoundDone;
begin
end;

function TLogSound.AdLibPresent: Boolean;
begin
  Result := True;
end;

function TLogSound.TrySetMode(AMode: TKeenSoundMode): Boolean;
begin
  FLog.Add('mode ' + IntToStr(Ord(AMode)));
  FMode := AMode;
  Result := True;
end;

procedure TLogSound.SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
begin
end;

{ TLogHooks }

constructor TLogHooks.Create(ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
  Accept := True;
end;

function TLogHooks.LoadGame(AStream: TStream): Boolean;
begin
  FLog.Add(Format('load %d of %d', [AStream.Position, AStream.Size]));
  Result := Accept;
end;

function TLogHooks.SaveGame(AStream: TStream): Boolean;
const
  PAYLOAD: array[0..2] of Byte = (1, 2, 3);
begin
  FLog.Add('save');
  AStream.WriteBuffer(PAYLOAD[0], SizeOf(PAYLOAD));
  Result := Accept;
end;

procedure TLogHooks.ResetGame;
begin
  FLog.Add('reset');
end;

{ TFakeHelp }

function TFakeHelp.TryGetText(AIndex: Integer; out AText: TBytes): Boolean;
var
  LText: AnsiString;
  LLine: Integer;
begin
  LText := '';
  for LLine := 1 to 40 do
    LText := LText + AnsiString(Format('line %d of the text %d with some words to wrap around the window'#13#10,
      [LLine, AIndex]));
  LText := LText + '~after the end';
  SetLength(AText, Length(LText));
  Move(LText[1], AText[0], Length(LText));
  Result := True;
end;

{ TTestKeenControlPanel }

procedure TTestKeenControlPanel.Setup;
begin
  FSoundLog := TStringList.Create;
  FHooksLog := TStringList.Create;
end;

procedure TTestKeenControlPanel.TearDown;
begin
  FPanel := nil;
  FHooks := nil;
  FSound := nil;
  FSlots := nil;
  FFilesIntf := nil;
  FState := nil;
  FreeAndNil(FWorld);
  FSoundLog.Free;
  FHooksLog.Free;
end;

procedure TTestKeenControlPanel.Make(const AScript: string; AInGame: Boolean; AWithHelp: Boolean;
  const AGraphics: IKeenGraphics);
var
  LHelp: IKeenHelpTexts;
begin
  FWorld := TKeenUiWorld.Create(AGraphics, AScript);
  FState := TKeenUserState.Create;
  FState.InGame := AInGame;
  FFiles := TUiFakeFiles.Create;
  FFilesIntf := FFiles;
  FSlots := TKeenSaveSlots.Create(FFilesIntf);
  FSound := TLogSound.Create(FSoundLog);
  FHooks := TLogHooks.Create(FHooksLog);
  if AWithHelp then
    LHelp := TFakeHelp.Create
  else
    LHelp := nil;
  FPanel := TKeenControlPanel.Create(FWorld.Windows, FWorld.Input, FWorld.Clock, FSound, FState, FSlots, LHelp, nil);
  FPanel.SetHooks(FHooks);
end;

procedure TTestKeenControlPanel.EscapeDovrebbeChiudereIlPannelloSenzaCambiareNulla;
begin
  Make('wait 20'#10'press esc', False);
  FPanel.Run;
  Assert.AreEqual(Ord(kgdContinue), Ord(FState.RestartGame));
  Assert.IsFalse(FState.LoadedGame);
  Assert.AreEqual('mode 2', FSoundLog.CommaText.Replace('"', ''), 'the sound mode of the buttons is set at the end');
  Assert.AreEqual(Ord(kctKeyboard1), Ord(FWorld.Input.Controls[0]));
end;

procedure TTestKeenControlPanel.IlPannelloDovrebbeDisegnareLeTreFinestre;
var
  LBlank: Cardinal;
begin
  Make('wait 20'#10'press esc', False);
  LBlank := FWorld.ScreenHash;
  FPanel.Run;
  Assert.AreNotEqual(LBlank, FWorld.ScreenHash);
  // the background of the panel is the first color; the three windows are white
  Assert.AreEqual(KEEN_FIRSTCOLOR, Integer(FWorld.DisplayPixel(2, 198)));
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.DisplayPixel(300, 150)), 'the bottom window');
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.DisplayPixel(66, 190)), 'the help window');
  // the last window that was drawn is the big one (8, 1, 30, 20)
  Assert.AreEqual(64, FWorld.Windows.Window.X);
  Assert.AreEqual(160, FWorld.Windows.Window.H);
end;

procedure TTestKeenControlPanel.F5EInvioDovrebberoFarPartireUnaPartitaNormale;
begin
  // F5 is the hot key of "new game": the cursor goes on the "normal" button, return hits it
  Make('wait 20'#10'press f5'#10'wait 30'#10'press enter', False);
  FPanel.Run;
  Assert.AreEqual(Ord(kgdNormal), Ord(FState.RestartGame));
  Assert.AreEqual(0, FHooksLog.Count, 'no game to reset');
end;

procedure TTestKeenControlPanel.LeFrecceDovrebberoPortareAlBottoneDellaPartitaFacile;
begin
  // from the "normal" button the left arrow goes to "easy", the right one would go to "hard"
  Make('wait 20'#10'press f5'#10'wait 30'#10'press left'#10'wait 30'#10'press enter', False);
  FPanel.Run;
  Assert.AreEqual(Ord(kgdEasy), Ord(FState.RestartGame));
end;

procedure TTestKeenControlPanel.UnaNuovaPartitaDuranteIlGiocoDovrebbeAzzerareQuellaInCorso;
begin
  Make('wait 20'#10'press f5'#10'wait 30'#10'press right'#10'wait 30'#10'press enter', True);
  FPanel.Run;
  Assert.AreEqual(Ord(kgdHard), Ord(FState.RestartGame));
  Assert.AreEqual('reset', FHooksLog.CommaText);
end;

procedure TTestKeenControlPanel.InGiocoInvioDovrebbeRiprendereLaPartita;
begin
  // in a game the panel opens on "go back to the game" and the cursor is over its button
  Make('wait 20'#10'press enter', True);
  FPanel.Run;
  Assert.AreEqual(Ord(kgdContinue), Ord(FState.RestartGame));
  Assert.IsFalse(FState.LoadedGame);
  Assert.AreEqual(0, FHooksLog.Count);
end;

procedure TTestKeenControlPanel.IlTastoDelSuonoDovrebbeCambiareLaModalitaAllUscita;
begin
  // F2 shows the sound buttons, 2 is the second of the row (the PC speaker), escape leaves
  Make('wait 20'#10'press f2'#10'wait 20'#10'press 2'#10'wait 20'#10'press esc', False);
  FPanel.Run;
  Assert.AreEqual('mode 1', FSoundLog.CommaText.Replace('"', ''));
  Assert.AreEqual(Ord(ksmPC), Ord(FSound.Mode));
end;

procedure TTestKeenControlPanel.UnDispositivoDisabilitatoNonDovrebbeEssereScelto;
begin
  // 4 is the Sound Blaster, that Keen Dreams always disables: the mode stays
  Make('wait 20'#10'press f2'#10'wait 20'#10'press 4'#10'wait 20'#10'press esc', False);
  FPanel.Run;
  Assert.AreEqual('mode 2', FSoundLog.CommaText.Replace('"', ''));
end;

procedure TTestKeenControlPanel.DovrebbeRidefinireUnTastoDellaTastiera;
var
  LKeys: TKeenKeyboardDef;
begin
  // F3 shows the key caps with the cursor on the first (the jump key); return, then the new key
  Make('wait 20'#10'press f3'#10'wait 30'#10'press enter'#10'wait 20'#10'press j'#10'wait 20'#10'press esc', False);
  FPanel.Run;
  LKeys := FWorld.Input.KeyboardDefs[0];
  Assert.AreEqual($24, Integer(LKeys.Button0), 'the scan code of J');
end;

procedure TTestKeenControlPanel.UnTastoGiaUsatoNonDovrebbeEssereAccettato;
var
  LBefore: TKeenKeyboardDef;
  LAfter: TKeenKeyboardDef;
begin
  // alt is the key of the second button: it cannot be the jump key too
  Make('wait 20'#10'press f3'#10'wait 30'#10'press enter'#10'wait 20'#10'press alt'#10'wait 20'#10'press esc', False);
  LBefore := FWorld.Input.KeyboardDefs[0];
  Assert.AreEqual($38, Integer(LBefore.Button1), 'the test needs alt on the second button');
  FPanel.Run;
  LAfter := FWorld.Input.KeyboardDefs[0];
  Assert.AreEqual(Integer(LBefore.Button0), Integer(LAfter.Button0));
end;

procedure TTestKeenControlPanel.DovrebbeSalvareLaPartitaConIlNomeBattuto;
var
  LBytes: TBytes;
  LSlot: TKeenSaveSlot;
begin
  // F6 shows the saved games with the cursor on the first load button; right is its save button
  Make('wait 20'#10'press f6'#10'wait 30'#10'press right'#10'wait 30'#10'press enter'#10'wait 60'#10'type abc'#10 +
    'press enter'#10'wait 60'#10'press esc', True);
  FPanel.Run;
  Assert.AreEqual('save', FHooksLog.CommaText);
  Assert.IsTrue(FFilesIntf.TryRead('SAVEGM0.KDR', LBytes));
  Assert.AreEqual(39 + 3, Length(LBytes));
  Assert.IsTrue(TKeenSaveSlots.TryDecodeHeader(LBytes, LSlot));
  Assert.AreEqual(AnsiString('abc'), LSlot.Name);
  Assert.IsTrue(FSlots.Slots[0].Present);
  Assert.IsFalse(FState.LoadedGame);
end;

procedure TTestKeenControlPanel.DovrebbeCaricareUnaPartitaSalvata;
var
  LSlot: TKeenSaveSlot;
begin
  LSlot.Present := True;
  LSlot.Name := 'saved before';
  // the files and the slots are made by Make: the file is put after it, then the check finds it
  Make('wait 20'#10'press f6'#10'wait 30'#10'press enter', False);
  FFiles.Put('SAVEGM0.KDR', TKeenSaveSlots.EncodeHeader(LSlot) + TBytes.Create(5, 5));
  FSlots.Check;
  FPanel.Run;
  Assert.IsTrue(FState.LoadedGame);
  Assert.IsFalse(FState.AbortGame);
  Assert.AreEqual('"load 39 of 41"', FHooksLog.CommaText);
  Assert.IsTrue(FWorld.Input.Paused, 'a loaded game starts paused');
end;

procedure TTestKeenControlPanel.UnCaricamentoFallitoDovrebbeChiedereDiAbbandonareLaPartita;
var
  LSlot: TKeenSaveSlot;
begin
  LSlot.Present := True;
  LSlot.Name := 'broken';
  // the game refuses the data: the error waits for a key, then escape leaves the panel
  Make('wait 20'#10'press f6'#10'wait 30'#10'press enter'#10'wait 60'#10'press space'#10'wait 40'#10'press esc', False);
  FFiles.Put('SAVEGM0.KDR', TKeenSaveSlots.EncodeHeader(LSlot));
  FSlots.Check;
  (FHooks as TLogHooks).Accept := False;
  FPanel.Run;
  Assert.IsFalse(FState.LoadedGame);
  Assert.IsTrue(FState.AbortGame);
end;

procedure TTestKeenControlPanel.SenzaPartitaIlSalvataggioDovrebbeEssereDisabilitato;
begin
  Make('wait 20'#10'press f6'#10'wait 30'#10'press right'#10'wait 30'#10'press enter'#10'wait 40'#10'press esc', False);
  FPanel.Run;
  Assert.AreEqual(0, FHooksLog.Count);
  Assert.AreEqual(0, FFiles.Count);
end;

procedure TTestKeenControlPanel.LUscitaAlDosDovrebbeEssereUnEccezioneDiUscita;
begin
  // Q shows "exit to DOS" with the cursor on the button that asks again
  Make('wait 20'#10'press q'#10'wait 30'#10'press enter', False);
  Assert.WillRaise(procedure begin FPanel.Run; end, EKeenQuitException);
  Assert.AreEqual('mode 2', FSoundLog.CommaText.Replace('"', ''), 'the panel is torn down before the exit');
end;

procedure TTestKeenControlPanel.LAiutoDovrebbeScorrereEChiudersiConEscape;
var
  LSteps: Integer;
begin
  // F1 opens the first text; down scrolls a line, page down a page, escape closes the reader and then the panel
  Make('wait 20'#10'press f1'#10'wait 30'#10'press down'#10'wait 20'#10'press pgdn'#10'wait 20'#10'press up'#10 +
    'wait 20'#10'press pgup'#10'wait 20'#10'press esc'#10'wait 30'#10'press esc', False);
  FPanel.Run;
  LSteps := FWorld.Host.Steps;
  Assert.IsTrue(LSteps > 200, 'the reader waited for the keys');
  Assert.AreEqual(KEEN_F_BLACK, FWorld.Buffered.FontColor);
end;

procedure TTestKeenControlPanel.SenzaTestiLAiutoDovrebbeDareUnErrore;
begin
  // the error waits for a key (space), then escape closes the panel
  Make('wait 20'#10'press f1'#10'wait 30'#10'press space'#10'wait 30'#10'press esc', False, False);
  FPanel.Run;
  Assert.AreEqual(Ord(kgdContinue), Ord(FState.RestartGame));
end;

procedure TTestKeenControlPanel.DovrebbeRifiutareIParametriNulli;
begin
  Make('', False);
  Assert.WillRaise(
    procedure begin TKeenControlPanel.Create(nil, FWorld.Input, FWorld.Clock, FSound, FState, FSlots, nil, nil); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenControlPanel.Create(FWorld.Windows, nil, FWorld.Clock, FSound, FState, FSlots, nil, nil); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenControlPanel.Create(FWorld.Windows, FWorld.Input, nil, FSound, FState, FSlots, nil, nil); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenControlPanel.Create(FWorld.Windows, FWorld.Input, FWorld.Clock, nil, FState, FSlots, nil, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenControlPanel.Create(FWorld.Windows, FWorld.Input, FWorld.Clock, FSound, nil, FSlots, nil, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenControlPanel.Create(FWorld.Windows, FWorld.Input, FWorld.Clock, FSound, FState, nil, nil, nil);
    end, EArgumentNilException);
end;

procedure TTestKeenControlPanel.ConIDatiVeriDovrebbeFarPartireUnaPartita;
var
  LFiles: IKeenDataFiles;
  LData: IKeenGameData;
  LBlank: Cardinal;
begin
  LFiles := TKeenRealData.OpenFiles;
  if not Assigned(LFiles) then
    TTestSkip.Ignore('i file dello shareware di Keen Dreams non sono su questa macchina');
  LData := TKeenFactory.OpenGameData(LFiles);
  Make('wait 20'#10'press f5'#10'wait 30'#10'press enter', False, True, LData.Graphics);
  LBlank := FWorld.ScreenHash;
  FPanel.Run;
  Assert.AreEqual(Ord(kgdNormal), Ord(FState.RestartGame));
  Assert.AreNotEqual(LBlank, FWorld.ScreenHash);
end;

end.
