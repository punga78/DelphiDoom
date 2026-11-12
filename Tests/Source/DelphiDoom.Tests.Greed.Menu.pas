{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the menu, its keyboard and its      }
{  screen                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Menu;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.Menu,
  DelphiDoom.Tests.Greed.MenuScenarios;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMenuInput = class(TObject)
  strict private
    FInput: TGreedMenuInput;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereITastiSoloNeiTicDispari;
    [Test]
    procedure DovrebbeDareIlCarattereMaiuscoloDelTastoPremuto;
    [Test]
    procedure DovrebbeAzzerareIlCarattereAllaLetturaSeguente;
    [Test]
    procedure DovrebbeNonRipetereIlCarattereDiUnTastoTenuto;
    [Test]
    procedure DovrebbeSegnareUsatoUnTastoFinoAlRilascio;
    [Test]
    procedure DovrebbeVedereUnTastoPremutoERilasciatoTraDueLetture;
    [Test]
    procedure DovrebbeIgnorareUnCodiceFuoriDallaTabella;
    [Test]
    procedure DovrebbeTrovareIlCodiceDiUnCarattere;
    [Test]
    procedure DovrebbeRilasciareTutto;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedDisplay = class(TObject)
  strict private
    FArchive: IGreedArchive;
    FCanvas: TGreedCanvas;
    FDisplay: TGreedDisplay;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaMancante;
    [Test]
    procedure DovrebbeMostrareLaPalettaEContareIlCambio;
    [Test]
    procedure DovrebbeCalcolareIlColoreVicinoAlloZero;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaCorta;
    [Test]
    procedure DovrebbeMoltiplicarePerQuattroLaPalettaDelLump;
    [Test]
    procedure DovrebbeDareFalsoSeLoSchermoNonEsiste;
    [Test]
    procedure DovrebbeCaricareLoSchermoELaSuaPaletta;
    [Test]
    procedure DovrebbeRiempireLoSchermo;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedMenu = class(TObject)
  strict private
    FArchive: IGreedArchive;
    FRunner: TMenuLibraryRunner;
    FScenario: TMenuScenario;
    FBackground: TBytes;
    procedure Open(ALevel: Integer = GREED_MENU_MAIN);
    procedure Ticks(ACount: Integer);
    procedure Tap(AScanCode: Integer);
    procedure TypeText(const AText: string);
    function Menu: TGreedMenu;
    function ScreenIsBackground: Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaMancante;
    [Test]
    procedure DovrebbeAprireIlMenuPrincipaleConIlCursoreSullaPrimaVoce;
    [Test]
    procedure DovrebbeRifiutareUnLivelloCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareDiAprirsiDueVolte;
    [Test]
    procedure DovrebbeAnimareLAperturaPrimaDiMostrareIlMenu;
    [Test]
    procedure DovrebbeScendereERisalireConLeFrecce;
    [Test]
    procedure DovrebbeMuovereIlCursoreUnaVoltaOgniDieciTic;
    [Test]
    procedure DovrebbeAvviareUnaNuovaPartitaConPersonaggioEDifficolta;
    [Test]
    procedure DovrebbePartireDallaMappaDellEpisodio;
    [Test]
    procedure DovrebbeNonAprireIlSalvataggioSenzaUnaPartita;
    [Test]
    procedure DovrebbeSalvareConIlNomeScritto;
    [Test]
    procedure DovrebbeLasciareIlNomeDiPrimaSeSiPremeEsc;
    [Test]
    procedure DovrebbeTagliareIlNomeAVentidueCaratteri;
    [Test]
    procedure DovrebbeCaricareLaPartitaScelta;
    [Test]
    procedure DovrebbeAlzareIlVolumeDellaMusicaConLaFrecciaDestra;
    [Test]
    procedure DovrebbeSpegnereLaViolenzaConLaFrecciaDestra;
    [Test]
    procedure DovrebbeDireAlGiocoLaLuceCambiata;
    [Test]
    procedure DovrebbeUscireDalGiocoSeSiRispondeSi;
    [Test]
    procedure DovrebbeRestareNelMenuSeSiRispondeNo;
    [Test]
    procedure DovrebbeChiudersiConEscSoloDopoTrentaTic;
    [Test]
    procedure DovrebbeTornareAlMenuPrincipaleConEsc;
    [Test]
    procedure DovrebbeApplicareLaDimensioneDellaVistaAllaChiusura;
    [Test]
    procedure DovrebbeMostrareLAiutoERimettereLaPaletta;
    [Test]
    procedure DovrebbeMostrareTrePagineDiAiutoNellaDemo;
    [Test]
    procedure DovrebbeUsareIlFileDiAiutoSeDato;
    [Test]
    procedure DovrebbeRifiutareUnFileDiAiutoCorto;
    [Test]
    procedure DovrebbeDareLaRispostaDelPannelloDiUscita;
    [Test]
    procedure DovrebbeChiudereLaPausaAlPrimoTasto;
    [Test]
    procedure DovrebbeAnimareIlPannelloDiAttesaSoloSeIlTempoPassa;
    [Test]
    procedure DovrebbeNonFareNullaDaChiuso;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedMenuParity = class(TObject)
  strict private
    procedure CheckGolden(const AArchive: IGreedArchive; const AGoldenName: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleSuiDatiSintetici;
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleNelGiocoCompleto;
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleNellaDemo20;
  end;

implementation

uses
  DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Settings,
  DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.SaveGames, DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Menu.Intf,
  DelphiDoom.Tests.Greed.RealData, DelphiDoom.Tests.Shared.Skip;

{ TTestGreedMenuInput }

procedure TTestGreedMenuInput.Setup;
begin
  FInput := TGreedMenuInput.Create;
end;

procedure TTestGreedMenuInput.TearDown;
begin
  FInput.Free;
end;

procedure TTestGreedMenuInput.DovrebbeLeggereITastiSoloNeiTicDispari;
begin
  FInput.TimeCount := 1;
  FInput.SetKey(GREED_SC_ENTER, True);
  FInput.TimerTick;
  Assert.AreEqual(2, FInput.TimeCount);
  Assert.AreEqual(0, FInput.Keyboard[GREED_SC_ENTER], 'tic pari: nessuna lettura');
  FInput.TimerTick;
  Assert.AreEqual(1, FInput.Keyboard[GREED_SC_ENTER]);
end;

procedure TTestGreedMenuInput.DovrebbeDareIlCarattereMaiuscoloDelTastoPremuto;
begin
  FInput.SetKey(TGreedMenuInput.ScanCodeOfChar('y'), True);
  FInput.TimerTick;
  Assert.IsTrue(FInput.NewAscii);
  Assert.AreEqual('Y', string(AnsiString(FInput.LastAscii)));
end;

procedure TTestGreedMenuInput.DovrebbeAzzerareIlCarattereAllaLetturaSeguente;
begin
  FInput.PressKey(gmkEnter, True);
  FInput.TimerTick;
  Assert.AreEqual(13, Integer(Ord(FInput.LastAscii)));
  FInput.TimerTick;
  Assert.AreEqual(13, Integer(Ord(FInput.LastAscii)), 'tic pari: resta');
  FInput.TimerTick;
  Assert.AreEqual(0, Integer(Ord(FInput.LastAscii)));
  Assert.IsTrue(FInput.NewAscii, 'NewAscii lo azzera chi lo usa');
end;

procedure TTestGreedMenuInput.DovrebbeNonRipetereIlCarattereDiUnTastoTenuto;
begin
  FInput.PressKey(gmkSpace, True);
  FInput.TimerTick;
  FInput.NewAscii := False;
  FInput.TimerTick;
  FInput.TimerTick;
  Assert.IsFalse(FInput.NewAscii);
  Assert.AreEqual(1, FInput.Keyboard[GREED_SC_SPACE]);
end;

procedure TTestGreedMenuInput.DovrebbeSegnareUsatoUnTastoFinoAlRilascio;
begin
  FInput.PressKey(gmkEscape, True);
  FInput.TimerTick;
  FInput.EatKey(GREED_SC_ESCAPE);
  Assert.AreEqual(2, FInput.Keyboard[GREED_SC_ESCAPE]);
  FInput.TimerTick;
  FInput.TimerTick;
  Assert.AreEqual(2, FInput.Keyboard[GREED_SC_ESCAPE]);
  FInput.PressKey(gmkEscape, False);
  FInput.TimerTick;
  FInput.TimerTick;
  Assert.AreEqual(0, FInput.Keyboard[GREED_SC_ESCAPE]);
  FInput.EatKey(GREED_SC_ESCAPE);
  Assert.AreEqual(0, FInput.Keyboard[GREED_SC_ESCAPE], 'un tasto alzato non si usa');
end;

procedure TTestGreedMenuInput.DovrebbeVedereUnTastoPremutoERilasciatoTraDueLetture;
begin
  FInput.TimeCount := 1;
  FInput.PressKey(gmkUp, True);
  FInput.PressKey(gmkUp, False);
  FInput.TimerTick;
  Assert.AreEqual(0, FInput.Keyboard[GREED_SC_UPARROW]);
  FInput.TimerTick;
  Assert.AreEqual(1, FInput.Keyboard[GREED_SC_UPARROW]);
  FInput.TimerTick;
  FInput.TimerTick;
  Assert.AreEqual(0, FInput.Keyboard[GREED_SC_UPARROW]);
end;

procedure TTestGreedMenuInput.DovrebbeIgnorareUnCodiceFuoriDallaTabella;
begin
  FInput.SetKey(-1, True);
  FInput.SetKey(GREED_MENU_SCAN_CODES, True);
  FInput.EatKey(500);
  FInput.TimerTick;
  Assert.IsFalse(FInput.NewAscii);
  Assert.AreEqual(0, FInput.Keyboard[-1]);
  Assert.AreEqual(0, FInput.Keyboard[GREED_MENU_SCAN_CODES]);
end;

procedure TTestGreedMenuInput.DovrebbeTrovareIlCodiceDiUnCarattere;
begin
  Assert.AreEqual(GREED_SC_Y, TGreedMenuInput.ScanCodeOfChar('Y'));
  Assert.AreEqual(GREED_SC_Y, TGreedMenuInput.ScanCodeOfChar('y'));
  Assert.AreEqual(GREED_SC_SPACE, TGreedMenuInput.ScanCodeOfChar(' '));
  Assert.AreEqual(2, TGreedMenuInput.ScanCodeOfChar('1'));
  Assert.AreEqual(-1, TGreedMenuInput.ScanCodeOfChar(#0));
  Assert.AreEqual(-1, TGreedMenuInput.ScanCodeOfChar(#$20AC));
  Assert.AreEqual(GREED_SC_BACKSPACE, TGreedMenuInput.ScanCodeOf(gmkBackspace));
  Assert.AreEqual(GREED_SC_LEFTARROW, TGreedMenuInput.ScanCodeOf(gmkLeft));
  Assert.AreEqual(GREED_SC_RIGHTARROW, TGreedMenuInput.ScanCodeOf(gmkRight));
  Assert.AreEqual(GREED_SC_DOWNARROW, TGreedMenuInput.ScanCodeOf(gmkDown));
end;

procedure TTestGreedMenuInput.DovrebbeRilasciareTutto;
begin
  FInput.PressKey(gmkEnter, True);
  FInput.TimerTick;
  FInput.ReleaseAll;
  Assert.IsFalse(FInput.NewAscii);
  Assert.AreEqual(0, Integer(Ord(FInput.LastAscii)));
  Assert.AreEqual(0, FInput.Keyboard[GREED_SC_ENTER]);
  Assert.AreEqual(1, FInput.TimeCount);
  FInput.TimerTick;
  FInput.TimerTick;
  Assert.AreEqual(0, FInput.Keyboard[GREED_SC_ENTER]);
end;

{ TTestGreedDisplay }

procedure TTestGreedDisplay.Setup;
begin
  FArchive := TMenuScenarios.SyntheticArchive;
  FCanvas := TGreedCanvas.Create;
  FDisplay := TGreedDisplay.Create(FCanvas, FArchive);
end;

procedure TTestGreedDisplay.TearDown;
begin
  FDisplay.Free;
  FCanvas.Free;
  FArchive := nil;
end;

procedure TTestGreedDisplay.DovrebbeRifiutareUnaDipendenzaMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedDisplay.Create(nil, FArchive);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedDisplay.Create(FCanvas, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedDisplay.DovrebbeMostrareLaPalettaEContareIlCambio;
var
  LPalette: TBytes;
begin
  SetLength(LPalette, 800);
  LPalette[5] := 77;
  FDisplay.SetPalette(LPalette);
  Assert.AreEqual(1, FDisplay.PaletteVersion);
  Assert.AreEqual(768, Integer(Length(FDisplay.Palette)));
  Assert.AreEqual(Byte(77), FDisplay.Palette[5]);
  LPalette[5] := 1;
  Assert.AreEqual(Byte(77), FDisplay.Palette[5], 'la paletta mostrata e'' una copia');
  FDisplay.FillPalette(9, 8, 7);
  Assert.AreEqual(2, FDisplay.PaletteVersion);
  Assert.AreEqual(Byte(9), FDisplay.Palette[765]);
  Assert.AreEqual(Byte(7), FDisplay.Palette[767]);
end;

procedure TTestGreedDisplay.DovrebbeCalcolareIlColoreVicinoAlloZero;
var
  LPalette: TBytes;
  LIndex: Integer;
begin
  SetLength(LPalette, 768);
  for LIndex := 3 to 767 do
    LPalette[LIndex] := 200;
  LPalette[9 * 3] := 1;
  LPalette[9 * 3 + 1] := 1;
  LPalette[9 * 3 + 2] := 1;
  FDisplay.SetPalette(LPalette);
  Assert.AreEqual(Byte(9), FCanvas.ApproxZero);
end;

procedure TTestGreedDisplay.DovrebbeRifiutareUnaPalettaCorta;
var
  LPalette: TBytes;
begin
  SetLength(LPalette, 767);
  Assert.WillRaise(
    procedure
    begin
      FDisplay.SetPalette(LPalette);
    end, EGreedDataException);
end;

procedure TTestGreedDisplay.DovrebbeMoltiplicarePerQuattroLaPalettaDelLump;
var
  LLump: TBytes;
  LIndex: Integer;
begin
  LLump := FArchive.ReadLump(FArchive.RequireIndexOf('palette'));
  FDisplay.SetPaletteFromLump('palette');
  for LIndex := 0 to 767 do
    Assert.AreEqual(Byte(LLump[LIndex] * 4), FDisplay.Palette[LIndex]);
end;

procedure TTestGreedDisplay.DovrebbeDareFalsoSeLoSchermoNonEsiste;
begin
  FCanvas.PutPixel(3, 3, 5);
  Assert.IsFalse(FDisplay.LoadScreen('NOSUCHSCREEN'));
  Assert.AreEqual(0, FDisplay.RenderClears);
  Assert.AreEqual(Byte(5), FCanvas.GetPixel(3, 3));
end;

procedure TTestGreedDisplay.DovrebbeCaricareLoSchermoELaSuaPaletta;
var
  LIndex: Integer;
  LPicture, LPalette, LOld: TBytes;
begin
  LIndex := FArchive.RequireIndexOf('INFO2');
  LPicture := FArchive.ReadLump(LIndex);
  LPalette := FArchive.ReadLump(LIndex + 1);
  LOld := FDisplay.Colors;
  Assert.IsTrue(FDisplay.LoadScreen('info2'));
  Assert.AreEqual(1, FDisplay.RenderClears);
  Assert.AreEqual(0, FDisplay.PaletteVersion, 'la paletta mostrata non cambia');
  Assert.AreEqual(LPicture[GREED_PICTURE_HEADER_BYTES], FCanvas.GetPixel(0, 0));
  Assert.AreEqual(LPicture[GREED_PICTURE_HEADER_BYTES + 63999], FCanvas.GetPixel(319, 199));
  // 8 bit: the values over 63 wrap around
  Assert.AreEqual(Byte(LPalette[0] * 4), FDisplay.Colors[0]);
  Assert.AreEqual(Byte(LPalette[767] * 4), FDisplay.Colors[767]);
  Assert.IsTrue(Pointer(LOld) <> Pointer(FDisplay.Colors), 'chi ha salvato Colors tiene i valori di prima');
  FDisplay.ShowColors;
  Assert.AreEqual(FDisplay.Colors[100], FDisplay.Palette[100]);
  FDisplay.ClearRender;
  Assert.AreEqual(2, FDisplay.RenderClears);
end;

procedure TTestGreedDisplay.DovrebbeRiempireLoSchermo;
begin
  FDisplay.FillScreen(300);
  Assert.AreEqual(Byte(44), FCanvas.GetPixel(0, 0));
  Assert.AreEqual(Byte(44), FCanvas.GetPixel(319, 199));
  Assert.AreSame(FCanvas, FDisplay.Canvas);
  Assert.IsTrue(FArchive = FDisplay.Archive);
end;

{ TTestGreedMenu }

procedure TTestGreedMenu.Setup;
begin
  FArchive := TMenuScenarios.SyntheticArchive;
  FRunner := TMenuLibraryRunner.Create(FArchive);
  FScenario := Default(TMenuScenario);
  FScenario.Animation := False;
  FScenario.Episode := 1;
  FScenario.MusicVol := 100;
  FScenario.SfxVol := 128;
  FScenario.AmbientLight := 2048;
  FScenario.ScreenSize := 2;
  FScenario.CamDelay := 35;
  FScenario.BackgroundSeed := 77;
  FScenario.HasDirectory := True;
  FScenario.SaveNames[2] := 'OLD NAME';
  FBackground := TMenuScenarios.Background(77);
end;

procedure TTestGreedMenu.TearDown;
begin
  FRunner.Free;
  FArchive := nil;
end;

function TTestGreedMenu.Menu: TGreedMenu;
begin
  Result := FRunner.Menu;
end;

procedure TTestGreedMenu.Open(ALevel: Integer);
begin
  FRunner.Prepare(FScenario);
  Menu.OpenMenu(ALevel);
  // KBDELAY2: the keys are not read in the first ten tics
  if not FScenario.Animation then
    Ticks(11);
end;

procedure TTestGreedMenu.Ticks(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    Menu.Tick;
end;

procedure TTestGreedMenu.Tap(AScanCode: Integer);
begin
  FRunner.Input.SetKey(AScanCode, True);
  Ticks(3);
  FRunner.Input.SetKey(AScanCode, False);
  Ticks(12);
end;

procedure TTestGreedMenu.TypeText(const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
  begin
    FRunner.Input.SetKey(TGreedMenuInput.ScanCodeOfChar(AText[LIndex]), True);
    Ticks(2);
    FRunner.Input.SetKey(TGreedMenuInput.ScanCodeOfChar(AText[LIndex]), False);
    Ticks(2);
  end;
end;

function TTestGreedMenu.ScreenIsBackground: Boolean;
begin
  Result := CompareMem(@FBackground[0], @FRunner.Canvas.Pixels[0], Length(FBackground));
end;

procedure TTestGreedMenu.DovrebbeRifiutareUnaDipendenzaMancante;
var
  LCanvas: TGreedCanvas;
  LDisplay: TGreedDisplay;
  LInput: TGreedMenuInput;
  LPrinter: TGreedTextPrinter;
  LFont: TGreedFont;
  LSettings: IGreedSettings;
  LHost: TMenuHostFake;
  LHostRef: IGreedMenuHost;
  LVolumes: IGreedSoundVolumes;
  LSaves: IGreedSaveGames;
  LCase: Integer;
begin
  LCanvas := TGreedCanvas.Create;
  LDisplay := TGreedDisplay.Create(LCanvas, FArchive);
  LInput := TGreedMenuInput.Create;
  LPrinter := TGreedTextPrinter.Create(LCanvas);
  LFont := TGreedFont.Create(FArchive.ReadLump(FArchive.RequireIndexOf('FONT1')));
  try
    LSettings := TGreedSettings.Create;
    LHost := TMenuHostFake.Create;
    LHostRef := LHost;
    LVolumes := LHost;
    LSaves := TGreedSaveGames.Create(TMenuSaveFilesFake.Create, ggvGame1);
    for LCase := 0 to 7 do
      Assert.WillRaise(
        procedure
        var
          LDisplayArg: TGreedDisplay;
          LInputArg: TGreedMenuInput;
          LPrinterArg: TGreedTextPrinter;
          LFontArg: TGreedFont;
          LSettingsArg: IGreedSettings;
          LVolumesArg: IGreedSoundVolumes;
          LSavesArg: IGreedSaveGames;
          LHostArg: IGreedMenuHost;
        begin
          LDisplayArg := LDisplay;
          LInputArg := LInput;
          LPrinterArg := LPrinter;
          LFontArg := LFont;
          LSettingsArg := LSettings;
          LVolumesArg := LVolumes;
          LSavesArg := LSaves;
          LHostArg := LHostRef;
          case LCase of
            0: LDisplayArg := nil;
            1: LInputArg := nil;
            2: LPrinterArg := nil;
            3: LFontArg := nil;
            4: LSettingsArg := nil;
            5: LVolumesArg := nil;
            6: LSavesArg := nil;
            7: LHostArg := nil;
          end;
          TGreedMenu.Create(LDisplayArg, LInputArg, LPrinterArg, LFontArg, LSettingsArg, LVolumesArg, LSavesArg,
            LHostArg);
        end, EArgumentNilException, 'dipendenza ' + IntToStr(LCase));
  finally
    LFont.Free;
    LPrinter.Free;
    LInput.Free;
    LDisplay.Free;
    LCanvas.Free;
  end;
end;

procedure TTestGreedMenu.DovrebbeAprireIlMenuPrincipaleConIlCursoreSullaPrimaVoce;
begin
  Open;
  Assert.IsTrue(Menu.Active);
  Assert.AreEqual(Ord(gmsMain), Ord(Menu.State));
  Assert.AreEqual(GREED_MENU_MAIN, Menu.Level);
  Assert.AreEqual(0, Menu.Cursor);
  // the frame of the cursor of "new game"
  Assert.AreEqual(Byte(133), FRunner.Canvas.GetPixel(41, 114));
  Assert.AreEqual(Byte(133), FRunner.Canvas.GetPixel(95, 133));
  Assert.IsFalse(ScreenIsBackground);
end;

procedure TTestGreedMenu.DovrebbeRifiutareUnLivelloCheNonEsiste;
begin
  FRunner.Prepare(FScenario);
  Assert.WillRaise(
    procedure
    begin
      Menu.OpenMenu(GREED_MENU_LEVELS);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      Menu.OpenMenu(-1);
    end, EGreedException);
  Assert.IsFalse(Menu.Active);
end;

procedure TTestGreedMenu.DovrebbeRifiutareDiAprirsiDueVolte;
begin
  Open;
  Assert.WillRaise(
    procedure
    begin
      Menu.OpenMenu;
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      Menu.OpenQuit;
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      Menu.OpenPause;
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      Menu.OpenHelp;
    end, EGreedException);
end;

procedure TTestGreedMenu.DovrebbeAnimareLAperturaPrimaDiMostrareIlMenu;
begin
  FScenario.Animation := True;
  Open;
  Assert.AreEqual(Ord(gmsAnimate), Ord(Menu.State));
  Assert.IsTrue(ScreenIsBackground, 'il primo fotogramma arriva al primo tic');
  // eight frames 7 tics apart, then the menu
  Ticks(55);
  Assert.AreEqual(Ord(gmsAnimate), Ord(Menu.State));
  Assert.AreNotEqual(Byte(133), FRunner.Canvas.GetPixel(41, 114));
  Ticks(1);
  Assert.AreEqual(Ord(gmsMain), Ord(Menu.State));
  Assert.AreEqual(Byte(133), FRunner.Canvas.GetPixel(41, 114));
end;

procedure TTestGreedMenu.DovrebbeScendereERisalireConLeFrecce;
begin
  Open;
  Tap(GREED_SC_DOWNARROW);
  Assert.AreEqual(1, Menu.Cursor);
  Assert.AreEqual(Byte(133), FRunner.Canvas.GetPixel(41, 138));
  Tap(GREED_SC_UPARROW);
  Tap(GREED_SC_UPARROW);
  Assert.AreEqual(6, Menu.Cursor, 'dalla prima voce si passa all''ultima');
  Tap(GREED_SC_DOWNARROW);
  Assert.AreEqual(0, Menu.Cursor);
end;

procedure TTestGreedMenu.DovrebbeMuovereIlCursoreUnaVoltaOgniDieciTic;
begin
  Open;
  FRunner.Input.SetKey(GREED_SC_DOWNARROW, True);
  Ticks(10);
  Assert.AreEqual(1, Menu.Cursor);
  Ticks(14);
  Assert.AreEqual(3, Menu.Cursor, 'un tasto tenuto ripete ogni undici tic');
end;

procedure TTestGreedMenu.DovrebbeAvviareUnaNuovaPartitaConPersonaggioEDifficolta;
begin
  Open;
  Tap(GREED_SC_ENTER);
  Assert.AreEqual(GREED_MENU_CHARACTER, Menu.Level);
  Assert.AreEqual(1, Menu.Cursor);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_ENTER);
  Assert.AreEqual(GREED_MENU_DIFFICULTY, Menu.Level);
  Assert.AreEqual(2, Menu.Character);
  Assert.AreEqual(2, Menu.Cursor);
  Tap(GREED_SC_UPARROW);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(2);
  Assert.IsFalse(Menu.Active);
  Assert.AreEqual(1, FRunner.Host.NewGames);
  Assert.AreEqual(0, FRunner.Host.LastMap);
  Assert.AreEqual(2, FRunner.Host.LastCharacter);
  Assert.AreEqual(5, FRunner.Host.LastDifficulty, 'la prima riga e'' la difficolta'' 5');
  Assert.AreEqual(0, FRunner.Input.TimeCount, 'timecount riparte da zero');
  Assert.IsTrue(ScreenIsBackground, 'lo schermo di prima torna');
  Assert.AreEqual(1, FRunner.Host.SettingsSaved);
  Assert.AreEqual(1, FRunner.Host.ControlsReset);
end;

procedure TTestGreedMenu.DovrebbePartireDallaMappaDellEpisodio;
begin
  FScenario.Episode := 3;
  Open(GREED_MENU_DIFFICULTY);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(2);
  Assert.AreEqual(16, FRunner.Host.LastMap);
  Assert.AreEqual(0, FRunner.Host.LastDifficulty);
end;

procedure TTestGreedMenu.DovrebbeNonAprireIlSalvataggioSenzaUnaPartita;
begin
  Open;
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_ENTER);
  Assert.AreEqual(GREED_MENU_MAIN, Menu.Level);
  Assert.IsTrue(Menu.Active);
end;

procedure TTestGreedMenu.DovrebbeSalvareConIlNomeScritto;
var
  LFile: TBytes;
begin
  FScenario.GameLoaded := True;
  Open(GREED_MENU_SAVE);
  Assert.AreEqual(1, Menu.Cursor);
  Assert.AreEqual('OLD NAME', Menu.SaveNames[2]);
  Tap(GREED_SC_ENTER);
  Assert.AreEqual(Ord(gmsSaveName), Ord(Menu.State));
  Assert.AreEqual('_', Menu.SaveNames[0]);
  TypeText('ab 1');
  Assert.AreEqual('AB 1_', Menu.SaveNames[0]);
  Tap(GREED_SC_BACKSPACE);
  Assert.AreEqual('AB _', Menu.SaveNames[0]);
  TypeText('z');
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(2);
  FRunner.Input.SetKey(GREED_SC_ENTER, False);
  Assert.AreEqual('AB Z', Menu.SaveNames[0]);
  Assert.AreEqual(1, FRunner.Host.SavedGames);
  Assert.AreEqual(0, FRunner.Host.LastSlot);
  Assert.AreEqual(1, Menu.SavePosition);
  Assert.AreEqual(GREED_MENU_MAIN, Menu.Level, 'dopo il salvataggio si torna al menu principale');
  LFile := FRunner.Files.Files['SAVE1.DIR'];
  Assert.AreEqual(Byte(4), LFile[0]);
  Assert.AreEqual(Byte(Ord('A')), LFile[1]);
  Assert.AreEqual(Byte(Ord('Z')), LFile[4]);
  Assert.AreEqual('', Menu.SaveNames[-1]);
  Assert.AreEqual('', Menu.SaveNames[10]);
end;

procedure TTestGreedMenu.DovrebbeLasciareIlNomeDiPrimaSeSiPremeEsc;
begin
  FScenario.GameLoaded := True;
  Open(GREED_MENU_SAVE);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_ENTER);
  Assert.AreEqual('OLD NAME_', Menu.SaveNames[2]);
  TypeText('xx');
  Assert.AreEqual('OLD NAMEXX_', Menu.SaveNames[2]);
  Tap(GREED_SC_ESCAPE);
  Assert.AreEqual('OLD NAME', Menu.SaveNames[2], 'il file dei nomi e'' riletto');
  Assert.AreEqual(0, FRunner.Host.SavedGames);
  Assert.AreEqual(GREED_MENU_SAVE, Menu.Level);
  Assert.AreEqual(Ord(gmsMain), Ord(Menu.State));
end;

procedure TTestGreedMenu.DovrebbeTagliareIlNomeAVentidueCaratteri;
begin
  FScenario.GameLoaded := True;
  Open(GREED_MENU_SAVE);
  Tap(GREED_SC_ENTER);
  TypeText('abcdefghijklmnopqrstuvwxyz');
  Assert.AreEqual(22, Length(Menu.SaveNames[0]));
  Assert.AreEqual('ABCDEFGHIJKLMNOPQRSTU', Copy(Menu.SaveNames[0], 1, 21));
end;

procedure TTestGreedMenu.DovrebbeCaricareLaPartitaScelta;
begin
  Open(GREED_MENU_LOAD);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(2);
  Assert.IsFalse(Menu.Active);
  Assert.AreEqual(1, FRunner.Host.LoadedGames);
  Assert.AreEqual(3, FRunner.Host.LastSlot);
  Assert.AreEqual(4, Menu.SavePosition);
end;

procedure TTestGreedMenu.DovrebbeAlzareIlVolumeDellaMusicaConLaFrecciaDestra;
begin
  Open(GREED_MENU_OPTIONS);
  Assert.AreEqual(2, Menu.Cursor);
  FRunner.Input.SetKey(GREED_SC_RIGHTARROW, True);
  Ticks(2);
  Assert.AreEqual(104, FRunner.Settings.GetInteger('musicvol'));
  Assert.AreEqual(104, FRunner.Host.Music);
  Assert.AreEqual(128, FRunner.Host.Sfx);
  Ticks(2);
  Assert.AreEqual(112, FRunner.Settings.GetInteger('musicvol'), 'la freccia tenuta alza a ogni tic');
  FRunner.Input.SetKey(GREED_SC_RIGHTARROW, False);
  Ticks(2);
  Tap(GREED_SC_DOWNARROW);
  FRunner.Input.SetKey(GREED_SC_LEFTARROW, True);
  Ticks(40);
  Assert.AreEqual(0, FRunner.Settings.GetInteger('sfxvol'), 'il volume non scende sotto zero');
  Assert.AreEqual(0, FRunner.Host.Sfx);
end;

procedure TTestGreedMenu.DovrebbeSpegnereLaViolenzaConLaFrecciaDestra;
begin
  FScenario.Violence := True;
  Open(GREED_MENU_OPTIONS);
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_DOWNARROW);
  Assert.AreEqual(4, Menu.Cursor);
  Tap(GREED_SC_RIGHTARROW);
  Assert.IsFalse(FRunner.Settings.GetBoolean('violence'));
  Tap(GREED_SC_LEFTARROW);
  Assert.IsTrue(FRunner.Settings.GetBoolean('violence'));
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_LEFTARROW);
  Assert.IsTrue(FRunner.Settings.GetBoolean('animation'));
  Tap(GREED_SC_RIGHTARROW);
  Assert.IsFalse(FRunner.Settings.GetBoolean('animation'));
end;

procedure TTestGreedMenu.DovrebbeDireAlGiocoLaLuceCambiata;
var
  LStep: Integer;
begin
  Open(GREED_MENU_OPTIONS);
  for LStep := 1 to 4 do
    Tap(GREED_SC_DOWNARROW);
  Assert.AreEqual(6, Menu.Cursor);
  FRunner.Input.SetKey(GREED_SC_LEFTARROW, True);
  Ticks(2);
  FRunner.Input.SetKey(GREED_SC_LEFTARROW, False);
  Ticks(2);
  // 64 less for each tic the key is seen down
  Assert.AreEqual(2048 - 128, FRunner.Settings.GetInteger('ambientlight'));
  Assert.AreEqual(2048 - 128, FRunner.Host.ChangeLight);
  Assert.AreEqual(1, FRunner.Host.Lighting);
  // the screen size moves once for each press, the camera delay at each tic
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_LEFTARROW);
  Assert.AreEqual(3, FRunner.Settings.GetInteger('screensize'));
  Tap(GREED_SC_RIGHTARROW);
  Tap(GREED_SC_RIGHTARROW);
  Assert.AreEqual(1, FRunner.Settings.GetInteger('screensize'));
  Tap(GREED_SC_DOWNARROW);
  FRunner.Input.SetKey(GREED_SC_RIGHTARROW, True);
  Ticks(80);
  Assert.AreEqual(70, FRunner.Settings.GetInteger('camdelay'));
end;

procedure TTestGreedMenu.DovrebbeUscireDalGiocoSeSiRispondeSi;
begin
  Open;
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_ENTER);
  Assert.IsTrue(Menu.State in [gmsQuitDelay, gmsQuitDrop]);
  Ticks(12);
  Assert.AreEqual(Ord(gmsQuitDrop), Ord(Menu.State));
  FRunner.Input.SetKey(GREED_SC_Y, True);
  Ticks(2);
  Assert.IsFalse(Menu.Active);
  Assert.IsTrue(FRunner.Host.QuitAsked);
  Assert.IsTrue(Menu.QuitAnswer);
  Assert.IsTrue(ScreenIsBackground);
end;

procedure TTestGreedMenu.DovrebbeRestareNelMenuSeSiRispondeNo;
begin
  Open;
  Tap(GREED_SC_DOWNARROW);
  Tap(GREED_SC_ENTER);
  Ticks(12);
  Tap(GREED_SC_N);
  Assert.IsTrue(Menu.Active);
  Assert.AreEqual(Ord(gmsMain), Ord(Menu.State));
  Assert.IsFalse(FRunner.Host.QuitAsked);
  Assert.IsFalse(Menu.QuitAnswer);
  Assert.AreEqual(1, FRunner.Host.ControlsReset);
end;

procedure TTestGreedMenu.DovrebbeChiudersiConEscSoloDopoTrentaTic;
begin
  Open;
  // 11 tics have passed: escape is read but the menu is too young to close
  Tap(GREED_SC_ESCAPE);
  Assert.IsTrue(Menu.Active);
  Ticks(10);
  FRunner.Input.SetKey(GREED_SC_ESCAPE, True);
  Ticks(2);
  Assert.IsFalse(Menu.Active);
  Assert.IsTrue(ScreenIsBackground);
  Assert.AreEqual(0, FRunner.Host.NewGames);
  Assert.AreEqual(1, FRunner.Host.SettingsSaved);
end;

procedure TTestGreedMenu.DovrebbeTornareAlMenuPrincipaleConEsc;
begin
  Open(GREED_MENU_CHARACTER);
  Tap(GREED_SC_ESCAPE);
  Assert.AreEqual(GREED_MENU_MAIN, Menu.Level);
  Assert.IsTrue(Menu.Active);
  // "resume" closes the menu
  Tap(GREED_SC_UPARROW);
  Assert.AreEqual(6, Menu.Cursor);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(2);
  Assert.IsFalse(Menu.Active);
end;

procedure TTestGreedMenu.DovrebbeApplicareLaDimensioneDellaVistaAllaChiusura;
begin
  FScenario.GameLoaded := True;
  FScenario.ScreenSize := 9;
  Open;
  FRunner.Host.ViewSize := -1;
  Tap(GREED_SC_UPARROW);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(2);
  Assert.IsFalse(Menu.Active);
  Assert.AreEqual(4, FRunner.Host.ViewSize, 'la dimensione e'' riportata tra 0 e 4');
  Assert.AreEqual(4, FRunner.Settings.GetInteger('screensize'));
end;

procedure TTestGreedMenu.DovrebbeMostrareLAiutoERimettereLaPaletta;
var
  LGamePalette: TBytes;
  LVersion: Integer;
begin
  FRunner.Prepare(FScenario);
  LGamePalette := Copy(FRunner.Display.Palette);
  LVersion := FRunner.Display.PaletteVersion;
  Menu.OpenHelp;
  Assert.AreEqual(Ord(gmsHelp), Ord(Menu.State));
  Assert.IsTrue(FRunner.Display.PaletteVersion > LVersion);
  Assert.AreEqual(FRunner.Display.Colors[300], FRunner.Display.Palette[300]);
  Assert.IsFalse(ScreenIsBackground);
  Ticks(25);
  Assert.IsTrue(Menu.Active, 'senza tasti resta');
  FRunner.Input.SetKey(GREED_SC_SPACE, True);
  Ticks(10);
  Assert.IsFalse(Menu.Active);
  Assert.IsTrue(ScreenIsBackground);
  Assert.IsTrue(CompareMem(@LGamePalette[0], @FRunner.Display.Palette[0], 768));
end;

procedure TTestGreedMenu.DovrebbeMostrareTrePagineDiAiutoNellaDemo;
var
  LPage: Integer;
  LFirst: Byte;
begin
  FScenario.Demo := True;
  FRunner.Prepare(FScenario);
  Menu.OpenHelp;
  for LPage := 1 to 3 do
  begin
    Assert.IsTrue(Menu.Active, 'pagina ' + IntToStr(LPage));
    LFirst := FArchive.ReadLump(FArchive.RequireIndexOf('INFO' + IntToStr(LPage)))[GREED_PICTURE_HEADER_BYTES];
    Assert.AreEqual(LFirst, FRunner.Canvas.GetPixel(0, 0));
    FRunner.Input.SetKey(GREED_SC_SPACE, True);
    Ticks(10);
    FRunner.Input.SetKey(GREED_SC_SPACE, False);
    Ticks(2);
  end;
  Assert.IsFalse(Menu.Active);
end;

procedure TTestGreedMenu.DovrebbeUsareIlFileDiAiutoSeDato;
var
  LData: TBytes;
begin
  FRunner.Prepare(FScenario);
  SetLength(LData, 64768);
  LData[0] := 9;
  LData[63999] := 8;
  LData[64000] := 250;
  Menu.HelpData := LData;
  Menu.OpenHelp;
  Assert.AreEqual(Byte(9), FRunner.Canvas.GetPixel(0, 0));
  Assert.AreEqual(Byte(8), FRunner.Canvas.GetPixel(319, 199));
  Assert.AreEqual(Byte(250), FRunner.Display.Palette[0], 'la paletta del file non e'' moltiplicata');
end;

procedure TTestGreedMenu.DovrebbeRifiutareUnFileDiAiutoCorto;
var
  LData: TBytes;
begin
  FRunner.Prepare(FScenario);
  SetLength(LData, 64000);
  Menu.HelpData := LData;
  Assert.WillRaise(
    procedure
    begin
      Menu.OpenHelp;
    end, EGreedDataException);
end;

procedure TTestGreedMenu.DovrebbeDareLaRispostaDelPannelloDiUscita;
begin
  FRunner.Prepare(FScenario);
  Menu.OpenQuit;
  Assert.AreEqual(Ord(gmsQuitDelay), Ord(Menu.State));
  Ticks(10);
  Assert.AreEqual(Ord(gmsQuitDrop), Ord(Menu.State));
  Ticks(5);
  Assert.IsFalse(ScreenIsBackground, 'il pannello e'' disegnato');
  FRunner.Input.SetKey(GREED_SC_Y, True);
  Ticks(2);
  Assert.IsFalse(Menu.Active);
  Assert.IsTrue(Menu.QuitAnswer);
  Assert.IsFalse(FRunner.Host.QuitAsked, 'fuori dal menu decide chi ha chiesto');
  Assert.IsTrue(ScreenIsBackground);
end;

procedure TTestGreedMenu.DovrebbeChiudereLaPausaAlPrimoTasto;
begin
  FScenario.Animation := True;
  FRunner.Prepare(FScenario);
  Menu.OpenPause;
  Ticks(10);
  Assert.AreEqual(Ord(gmsPauseShow), Ord(Menu.State));
  // the panel drops two rows a tic from -56 to 72
  Ticks(80);
  Assert.AreEqual(Ord(gmsPauseShow), Ord(Menu.State));
  Assert.IsFalse(ScreenIsBackground);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(2);
  Assert.AreEqual(Ord(gmsPauseLeave), Ord(Menu.State));
  Ticks(70);
  Assert.IsFalse(Menu.Active);
  Assert.IsTrue(ScreenIsBackground);
end;

procedure TTestGreedMenu.DovrebbeAnimareIlPannelloDiAttesaSoloSeIlTempoPassa;
var
  LFirst, LSecond: TBytes;
begin
  FRunner.Prepare(FScenario);
  Menu.StartWait;
  Assert.IsTrue(Menu.Waiting);
  Assert.IsFalse(ScreenIsBackground);
  LFirst := Copy(FRunner.Canvas.Pixels);
  FRunner.Input.TimeCount := FRunner.Input.TimeCount + 10;
  Menu.UpdateWait;
  Assert.IsTrue(CompareMem(@LFirst[0], @FRunner.Canvas.Pixels[0], Length(LFirst)), 'dieci tic non bastano');
  FRunner.Input.TimeCount := FRunner.Input.TimeCount + 1;
  Menu.UpdateWait;
  LSecond := Copy(FRunner.Canvas.Pixels);
  Assert.IsFalse(CompareMem(@LFirst[0], @LSecond[0], Length(LFirst)));
  Menu.EndWait;
  Assert.IsFalse(Menu.Waiting);
  Assert.IsFalse(Menu.Active);
end;

procedure TTestGreedMenu.DovrebbeNonFareNullaDaChiuso;
begin
  FRunner.Prepare(FScenario);
  FRunner.Input.TimeCount := 5;
  Menu.Tick;
  Menu.Step;
  Assert.AreEqual(5, FRunner.Input.TimeCount);
  Assert.AreEqual(Ord(gmsClosed), Ord(Menu.State));
  Assert.IsTrue(ScreenIsBackground);
end;

{ TTestGreedMenuParity }

procedure TTestGreedMenuParity.CheckGolden(const AArchive: IGreedArchive; const AGoldenName: string);
var
  LGolden, LLines: TStringList;
  LIndex, LDifferent: Integer;
  LFirst: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(AGoldenName));
    LLines := MenuLibraryLines(AArchive);
    try
      Assert.AreEqual(MENU_SCENARIOS, LLines.Count);
      Assert.AreEqual(LGolden.Count, LLines.Count, 'the golden file has other scenarios');
      LDifferent := 0;
      LFirst := '';
      for LIndex := 0 to LLines.Count - 1 do
        if LLines[LIndex] <> LGolden[LIndex] then
        begin
          if LDifferent = 0 then
            LFirst := LGolden[LIndex] + ' / ' + LLines[LIndex];
          Inc(LDifferent);
        end;
      Assert.AreEqual(0, LDifferent, 'scenarios that differ from the original; the first (original / library): ' +
        LFirst);
    finally
      LLines.Free;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedMenuParity.DovrebbeDareGliStessiSchermiDelloOriginaleSuiDatiSintetici;
begin
  CheckGolden(TMenuScenarios.SyntheticArchive, 'menu.golden.txt');
end;

procedure TTestGreedMenuParity.DovrebbeDareGliStessiSchermiDelloOriginaleNelGiocoCompleto;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('i dati del gioco completo (GREED.BLO) non ci sono');
  CheckGolden(TGreedRealData.OpenArchive(TGreedRealData.FullFolder), 'menu.full.golden.txt');
end;

procedure TTestGreedMenuParity.DovrebbeDareGliStessiSchermiDelloOriginaleNellaDemo20;
begin
  if TGreedRealData.Demo20Folder = '' then
    TTestSkip.Ignore('i dati della demo 2.0 (GREED.BLO) non ci sono');
  CheckGolden(TGreedRealData.OpenArchive(TGreedRealData.Demo20Folder), 'menu.demo20.golden.txt');
end;

end.
