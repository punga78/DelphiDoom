{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEndoomEditorPresenter                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EndoomEditor.Presenter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf, DelphiDoom.Imaging.Intf,
  DelphiDoom.Endoom.Types,
  DelphiDoom.EndoomEditor.Types,
  DelphiDoom.EndoomEditor.Intf,
  DelphiDoom.EndoomEditor.Presenter,
  DelphiDoom.Tests.ToolsCore.Fakes,
  DelphiDoom.Tests.EndoomEditor.Fakes;

type
  /// <summary>
  ///   The presenter with the real model (screen, drawing, text art, undo, recent files, settings) and fakes for
  ///   what is the system: the window, the dialogs, the clipboard, the exporter, the files and the resampler
  /// </summary>
  [TestFixture]
  [Category('endoomeditor')]
  TTestEndoomEditorPresenter = class(TObject)
  strict private
    FView: TFakeEditorView;
    FViewIntf: IEndoomEditorView;
    FDialogs: TFakeEditorDialogs;
    FDialogsIntf: IEndoomEditorDialogs;
    FClipboard: TFakeEditorClipboard;
    FClipboardIntf: IEndoomEditorClipboard;
    FExporter: TFakeEditorExporter;
    FExporterIntf: IEndoomEditorImageExporter;
    FResampler: TFakeEditorResampler;
    FResamplerIntf: IImagingResampler;
    FFileSystem: TFakeToolFileSystem;
    FFileSystemIntf: IToolFileSystem;
    FPresenter: TEndoomEditorPresenter;
    function NewPresenter: TEndoomEditorPresenter;
    function Px(ACell: Integer): Integer;
    function Py(ACell: Integer): Integer;
    procedure Drag(AX1, AY1, AX2, AY2: Integer);
    procedure Click(AX, AY: Integer);
    procedure PutScreenFile(const APath: string; ACode: Byte);
    procedure Type_(const AText: string);
    function Background(AX, AY: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCreareUnaSchermataVuotaAllAvvio;
    [Test]
    procedure DovrebbeCaricareIlFileDellaRigaDiComando;
    [Test]
    procedure DovrebbeRipiegareSuUnaSchermataVuotaSeIlFileManca;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeLeggereLeImpostazioni;
    [Test]
    procedure DovrebbeLimitareLeImpostazioniFuoriIntervallo;
    [Test]
    procedure DovrebbeSalvareLeImpostazioniAllaChiusura;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
    [Test]
    procedure DovrebbeDisegnareLungoIlTrascinamentoConUnSoloAnnulla;
    [Test]
    procedure DovrebbeDisegnareUnaLineaCheSegueIlMouse;
    [Test]
    procedure DovrebbeDisegnareUnRettangoloChePuoCrescereERiavvolgersi;
    [Test]
    procedure DovrebbeRiempireUnRettangolo;
    [Test]
    procedure DovrebbeDisegnareLeEllissi;
    [Test]
    procedure DovrebbeRiempireConIlSecchiello;
    [Test]
    procedure DovrebbeCancellareIlTesto;
    [Test]
    procedure DovrebbeUsareICaratteriSpeciali;
    [Test]
    procedure DovrebbeCambiareSoloIlPrimoPiano;
    [Test]
    procedure DovrebbeDisegnareLeCornici;
    [Test]
    procedure DovrebbeAccendereESpegnereIlLampeggio;
    [Test]
    procedure DovrebbeMettereIlCursoreConLoStrumentoTesto;
    [Test]
    procedure DovrebbeScrivereIlTestoDalCursore;
    [Test]
    procedure DovrebbeAndareACapoAFineRiga;
    [Test]
    procedure DovrebbeCancellareIndietro;
    [Test]
    procedure DovrebbeAndareACapoConInvio;
    [Test]
    procedure DovrebbeMuovereIlCursoreConITasti;
    [Test]
    procedure DovrebbeCancellareIlCarattereConCanc;
    [Test]
    procedure DovrebbeIgnorareITastiConUnAltroStrumento;
    [Test]
    procedure DovrebbeIgnorareICaratteriFuoriDalDominio;
    [Test]
    procedure DovrebbeTrovareLaCellaConLoZoom;
    [Test]
    procedure DovrebbeLimitareLoZoom;
    [Test]
    procedure DovrebbeMostrareLaGriglia;
    [Test]
    procedure DovrebbeAnnullareERifare;
    [Test]
    procedure DovrebbeSegnareLeModifiche;
    [Test]
    procedure DovrebbeChiedereSeSalvareLeModifiche;
    [Test]
    procedure DovrebbeSalvareSeLUtenteDiceSi;
    [Test]
    procedure DovrebbeNonChiudereSeLUtenteAnnulla;
    [Test]
    procedure DovrebbeCreareUnNuovoDocumento;
    [Test]
    procedure DovrebbeAprireUnFile;
    [Test]
    procedure DovrebbeAprireUnFileRecente;
    [Test]
    procedure DovrebbeSalvareConLaCopiaDiSicurezza;
    [Test]
    procedure DovrebbeSalvareConNome;
    [Test]
    procedure DovrebbeDireSeNonRiesceASalvare;
    [Test]
    procedure DovrebbeEsportareLaPittura;
    [Test]
    procedure DovrebbeCopiareLaPitturaNegliAppunti;
    [Test]
    procedure DovrebbeTagliareLaPittura;
    [Test]
    procedure DovrebbeIncollareUnaPitturaComeTestoColorato;
    [Test]
    procedure DovrebbeIncollareUnTesto;
    [Test]
    procedure DovrebbeNonIncollareSenzaAppunti;
    [Test]
    procedure DovrebbeUsareLaSelezione;
    [Test]
    procedure DovrebbeNonUsareLaSelezioneSeNonCe;
    [Test]
    procedure DovrebbeNasconderePerIlLampeggioIlCarattereCheLampeggia;
    [Test]
    procedure DovrebbeFarLampeggiareIlCursoreSoloConLoStrumentoTesto;
    [Test]
    procedure DovrebbeDireLaPosizioneInBarraDiStato;
    [Test]
    procedure DovrebbeIgnorareIlMouseSenzaPulsante;
    [Test]
    procedure DovrebbeMostrareLeScelteEIlTitolo;
    [Test]
    procedure DovrebbeAggiornareLoStatoDeiComandi;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Endoom.Intf, DelphiDoom.Endoom.EditorFactory, DelphiDoom.Endoom.TextArt.Types, DelphiDoom.Endoom.TextArt.Intf,
  DelphiDoom.Endoom.TextArt.Factory, DelphiDoom.Tools.Factory, DelphiDoom.Tools.Types;

const
  SINI = 'C:\tool\endedit.ini';

{ TTestEndoomEditorPresenter }

procedure TTestEndoomEditorPresenter.Setup;
begin
  FView := TFakeEditorView.Create;
  FViewIntf := FView;
  FDialogs := TFakeEditorDialogs.Create;
  FDialogsIntf := FDialogs;
  FClipboard := TFakeEditorClipboard.Create;
  FClipboardIntf := FClipboard;
  FExporter := TFakeEditorExporter.Create;
  FExporterIntf := FExporter;
  FFileSystem := TFakeToolFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FResampler := TFakeEditorResampler.Create;
  FResamplerIntf := FResampler;
  FPresenter := NewPresenter;
end;

procedure TTestEndoomEditorPresenter.TearDown;
begin
  FPresenter.Free;
end;

function TTestEndoomEditorPresenter.NewPresenter: TEndoomEditorPresenter;
begin
  Result := TEndoomEditorPresenter.Create(FViewIntf, FDialogsIntf, FClipboardIntf, FExporterIntf, FFileSystemIntf,
    TToolsFactory.CreateFileBackup(FFileSystemIntf), TToolsFactory.CreateSettings(FFileSystemIntf, SINI),
    TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT), TToolsFactory.CreateUndoHistory(TOOLS_UNDO_LIMIT),
    TEndoomEditorFactory.CreateScreen, TEndoomEditorFactory.CreateScreenImage, TEndoomEditorFactory.CreateEditorFontSource,
    TEndoomTextArtFactory.CreateConverter(FResamplerIntf),
    function(AKind: TEndoomTextArtKind): IEndoomTextArtMethod
    begin
      Result := TEndoomTextArtFactory.CreateMethod(AKind);
    end);
end;

function TTestEndoomEditorPresenter.Px(ACell: Integer): Integer;
begin
  Result := ACell * 8 + 1;
end;

function TTestEndoomEditorPresenter.Py(ACell: Integer): Integer;
begin
  Result := ACell * 16 + 1;
end;

procedure TTestEndoomEditorPresenter.Click(AX, AY: Integer);
begin
  FPresenter.MouseDown(Px(AX), Py(AY));
  FPresenter.MouseUp(Px(AX), Py(AY));
end;

procedure TTestEndoomEditorPresenter.Drag(AX1, AY1, AX2, AY2: Integer);
begin
  FPresenter.MouseDown(Px(AX1), Py(AY1));
  FPresenter.MouseMove(Px(AX2), Py(AY2));
  FPresenter.MouseUp(Px(AX2), Py(AY2));
end;

procedure TTestEndoomEditorPresenter.PutScreenFile(const APath: string; ACode: Byte);
var
  LScreen: IEndoomScreen;
begin
  LScreen := TEndoomEditorFactory.CreateScreen;
  LScreen.SetCharacter(0, 0, ACode);
  FFileSystem.TryWriteAllBytes(APath, LScreen.ToBytes);
end;

procedure TTestEndoomEditorPresenter.Type_(const AText: string);
var
  LChar: Char;
begin
  for LChar in AText do
    FPresenter.KeyPress(LChar);
end;

function TTestEndoomEditorPresenter.Background(AX, AY: Integer): Integer;
begin
  Result := FPresenter.Screen.GetBackground(AX, AY);
end;

procedure TTestEndoomEditorPresenter.DovrebbeCreareUnaSchermataVuotaAllAvvio;
begin
  FPresenter.Start('');
  Assert.AreEqual<Integer>(ENDOOM_LUMP_SIZE, Length(FPresenter.Screen.ToBytes));
  Assert.IsTrue(FPresenter.Screen.IsSameAs(TEndoomEditorFactory.CreateScreen));
  Assert.AreEqual(ENDOOM_EDITOR_TITLE, FView.Title);
  Assert.AreEqual<Integer>(ENDOOM_WIDTH * ENDOOM_HEIGHT, Length(FView.Pixels));
  Assert.IsTrue(FView.PictureCount >= 1);
  Assert.IsFalse(FView.State.CanUndo);
  Assert.IsFalse(FView.State.CanRedo);
  Assert.IsFalse(FView.State.CanPaste);
  Assert.IsFalse(FView.State.CanZoomOut);
  Assert.IsTrue(FView.State.CanZoomIn);
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestEndoomEditorPresenter.DovrebbeCaricareIlFileDellaRigaDiComando;
begin
  PutScreenFile('C:\dati\fine.bin', 65);
  FPresenter.Start('C:\dati\fine.bin');
  Assert.AreEqual(65, Integer(FPresenter.Screen.GetCharacter(0, 0)));
  Assert.AreEqual('C:\dati\fine.bin', FPresenter.FileName);
  Assert.AreEqual(ENDOOM_EDITOR_TITLE + ' - C:\dati\fine.bin', FView.Title);
  Assert.AreEqual<Integer>(1, Length(FView.RecentCaptions));
  Assert.AreEqual('&1. C:\dati\fine.bin', FView.RecentCaptions[0]);
  Assert.AreEqual(0, FDialogs.Messages.Count);
end;

procedure TTestEndoomEditorPresenter.DovrebbeRipiegareSuUnaSchermataVuotaSeIlFileManca;
begin
  FPresenter.Start('C:\manca.bin');
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('Can not find file'));
  Assert.AreEqual('', FPresenter.FileName);
  Assert.AreEqual(ENDOOM_EDITOR_TITLE, FView.Title);
end;

procedure TTestEndoomEditorPresenter.DovrebbeRifiutareUnFileTroppoCorto;
begin
  FFileSystem.TryWriteAllBytes('C:\corto.bin', TBytes.Create(1, 2, 3));
  FPresenter.Start('C:\corto.bin');
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('is not a text screen'));
  Assert.AreEqual('', FPresenter.FileName);
  // the same from the dialog of the files, and for a file that cannot be read
  FDialogs.OpenResult := True;
  FDialogs.OpenName := 'C:\corto.bin';
  FPresenter.OpenFile;
  Assert.AreEqual(2, FDialogs.Messages.Count);
  PutScreenFile('C:\buono.bin', 1);
  FFileSystem.FailRead := True;
  FDialogs.OpenName := 'C:\buono.bin';
  FPresenter.OpenFile;
  Assert.AreEqual(3, FDialogs.Messages.Count);
  Assert.AreEqual('', FPresenter.FileName);
end;

procedure TTestEndoomEditorPresenter.DovrebbeLeggereLeImpostazioni;
begin
  FFileSystem.PutText(SINI, '[Options]'#13#10'SHOWGRID=1'#13#10'ZOOM=7'#13#10'TEXTARTMETHOD=3'#13#10 +
    '[File Menu History]'#13#10'FILEMENUHISTORY0=C:\a.bin'#13#10);
  FPresenter.Start('');
  Assert.AreEqual(7, FPresenter.Zoom);
  Assert.IsTrue(FPresenter.ShowGrid);
  Assert.AreEqual(Ord(eakSpecialCharacters), Ord(FPresenter.TextArtMethod));
  Assert.AreEqual<Integer>(1, Length(FView.RecentCaptions));
  Assert.AreEqual(7, FView.Overlay.Zoom);
  Assert.IsTrue(FView.Overlay.ShowGrid);
end;

procedure TTestEndoomEditorPresenter.DovrebbeLimitareLeImpostazioniFuoriIntervallo;
begin
  FFileSystem.PutText(SINI, 'ZOOM=99'#13#10'TEXTARTMETHOD=9');
  FPresenter.Start('');
  Assert.AreEqual(ENDOOM_EDITOR_MAX_ZOOM, FPresenter.Zoom);
  Assert.AreEqual(Ord(High(TEndoomTextArtKind)), Ord(FPresenter.TextArtMethod));
  FFileSystem.PutText(SINI, 'ZOOM=-5'#13#10'TEXTARTMETHOD=-1');
  FPresenter.Free;
  FPresenter := NewPresenter;
  FPresenter.Start('');
  Assert.AreEqual(ENDOOM_EDITOR_MIN_ZOOM, FPresenter.Zoom);
  Assert.AreEqual(Ord(eakBackgroundOnly), Ord(FPresenter.TextArtMethod));
end;

procedure TTestEndoomEditorPresenter.DovrebbeSalvareLeImpostazioniAllaChiusura;
var
  LText: string;
begin
  PutScreenFile('C:\a.bin', 1);
  FPresenter.Start('C:\a.bin');
  FPresenter.ZoomIn;
  FPresenter.ZoomIn;
  FPresenter.ToggleGrid;
  FPresenter.SelectTextArtMethod(eakDither);
  FPresenter.Shutdown;
  LText := FFileSystem.TextOf(SINI);
  Assert.IsTrue(LText.Contains('ZOOM=2'));
  Assert.IsTrue(LText.Contains('SHOWGRID=1'));
  Assert.IsTrue(LText.Contains('TEXTARTMETHOD=2'));
  Assert.IsTrue(LText.Contains('FILEMENUHISTORY0=C:\a.bin'));
  Assert.IsTrue(LText.Contains('[File Menu History]'));
end;

procedure TTestEndoomEditorPresenter.DovrebbeRifiutareLeDipendenzeNil;
var
  LMethods: TEndoomTextArtMethodProvider;
  LNoView: TProc;
  LNoMethods: TProc;
  LNoScreen: TProc;
begin
  LMethods := function(AKind: TEndoomTextArtKind): IEndoomTextArtMethod
    begin
      Result := TEndoomTextArtFactory.CreateMethod(AKind);
    end;
  LNoView := procedure
    begin
      TEndoomEditorPresenter.Create(nil, FDialogsIntf, FClipboardIntf, FExporterIntf, FFileSystemIntf,
        TToolsFactory.CreateFileBackup(FFileSystemIntf), TToolsFactory.CreateSettings(FFileSystemIntf, SINI),
        TToolsFactory.CreateRecentFiles(3), TToolsFactory.CreateUndoHistory(3), TEndoomEditorFactory.CreateScreen,
        TEndoomEditorFactory.CreateScreenImage, TEndoomEditorFactory.CreateEditorFontSource,
        TEndoomTextArtFactory.CreateConverter(FResamplerIntf), LMethods).Free;
    end;
  LNoMethods := procedure
    begin
      TEndoomEditorPresenter.Create(FViewIntf, FDialogsIntf, FClipboardIntf, FExporterIntf, FFileSystemIntf,
        TToolsFactory.CreateFileBackup(FFileSystemIntf), TToolsFactory.CreateSettings(FFileSystemIntf, SINI),
        TToolsFactory.CreateRecentFiles(3), TToolsFactory.CreateUndoHistory(3), TEndoomEditorFactory.CreateScreen,
        TEndoomEditorFactory.CreateScreenImage, TEndoomEditorFactory.CreateEditorFontSource,
        TEndoomTextArtFactory.CreateConverter(FResamplerIntf), nil).Free;
    end;
  LNoScreen := procedure
    begin
      TEndoomEditorPresenter.Create(FViewIntf, FDialogsIntf, FClipboardIntf, FExporterIntf, FFileSystemIntf,
        TToolsFactory.CreateFileBackup(FFileSystemIntf), TToolsFactory.CreateSettings(FFileSystemIntf, SINI),
        TToolsFactory.CreateRecentFiles(3), TToolsFactory.CreateUndoHistory(3), nil,
        TEndoomEditorFactory.CreateScreenImage, TEndoomEditorFactory.CreateEditorFontSource,
        TEndoomTextArtFactory.CreateConverter(FResamplerIntf), LMethods).Free;
    end;
  Assert.WillRaise(LNoView, EArgumentNilException);
  Assert.WillRaise(LNoMethods, EArgumentNilException);
  Assert.WillRaise(LNoScreen, EArgumentNilException);
end;
procedure TTestEndoomEditorPresenter.DovrebbeDisegnareLungoIlTrascinamentoConUnSoloAnnulla;
var
  LX: Integer;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(3);
  Drag(5, 5, 10, 5);
  for LX := 5 to 10 do
    Assert.AreEqual(3, Background(LX, 5));
  Assert.AreEqual(0, Background(4, 5));
  Assert.AreEqual(0, Background(11, 5));
  Assert.IsTrue(FPresenter.Modified);
  Assert.IsTrue(FView.State.CanUndo);
  FPresenter.Undo;
  Assert.IsTrue(FPresenter.Screen.IsSameAs(TEndoomEditorFactory.CreateScreen));
  Assert.IsFalse(FView.State.CanUndo);
  Assert.IsTrue(FView.State.CanRedo);
end;

procedure TTestEndoomEditorPresenter.DovrebbeDisegnareUnaLineaCheSegueIlMouse;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetLine);
  FPresenter.SelectBackground(2);
  FPresenter.MouseDown(Px(0), Py(0));
  FPresenter.MouseMove(Px(30), Py(0));
  Assert.AreEqual(2, Background(30, 0));
  FPresenter.MouseMove(Px(5), Py(0));
  // the screen goes back to what it was before each painting: the cells past the mouse are not painted
  Assert.AreEqual(0, Background(30, 0));
  Assert.AreEqual(2, Background(5, 0));
  FPresenter.MouseUp(Px(5), Py(0));
  Assert.AreEqual(2, Background(3, 0));
  Assert.AreEqual(0, Background(6, 0));
end;

procedure TTestEndoomEditorPresenter.DovrebbeDisegnareUnRettangoloChePuoCrescereERiavvolgersi;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetRectangle);
  FPresenter.SelectBackground(4);
  FPresenter.MouseDown(Px(10), Py(5));
  FPresenter.MouseMove(Px(20), Py(10));
  FPresenter.MouseMove(Px(14), Py(7));
  FPresenter.MouseUp(Px(14), Py(7));
  Assert.AreEqual(4, Background(10, 5));
  Assert.AreEqual(4, Background(14, 7));
  Assert.AreEqual(4, Background(12, 5));
  Assert.AreEqual(0, Background(12, 6));
  Assert.AreEqual(0, Background(20, 10));
end;

procedure TTestEndoomEditorPresenter.DovrebbeRiempireUnRettangolo;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetFilledRectangle);
  FPresenter.SelectBackground(5);
  Drag(2, 2, 4, 3);
  Assert.AreEqual(5, Background(3, 2));
  Assert.AreEqual(5, Background(4, 3));
  Assert.AreEqual(0, Background(5, 3));
end;

procedure TTestEndoomEditorPresenter.DovrebbeDisegnareLeEllissi;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(6);
  FPresenter.SelectTool(eetEllipse);
  Drag(40, 12, 50, 17);
  Assert.AreEqual(6, Background(50, 12));
  Assert.AreEqual(6, Background(40, 7));
  Assert.AreEqual(0, Background(40, 12));
  FPresenter.SelectTool(eetFilledEllipse);
  Drag(40, 12, 50, 17);
  Assert.AreEqual(6, Background(40, 12));
end;

procedure TTestEndoomEditorPresenter.DovrebbeRiempireConIlSecchiello;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetFloodFill);
  FPresenter.SelectBackground(4);
  Click(10, 10);
  Assert.AreEqual(4, Background(0, 0));
  Assert.AreEqual(4, Background(79, 24));
end;

procedure TTestEndoomEditorPresenter.DovrebbeCancellareIlTesto;
begin
  FPresenter.Start('');
  FPresenter.Screen.SetCharacter(3, 3, 65);
  FPresenter.SelectTool(eetEraseText);
  Click(3, 3);
  Assert.AreEqual(0, Integer(FPresenter.Screen.GetCharacter(3, 3)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeUsareICaratteriSpeciali;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(1);
  FPresenter.SelectForeground(14);
  FPresenter.SelectTool(eetSpecialCharacterWithBackground);
  Click(4, 4);
  Assert.AreEqual(1, Background(4, 4));
  Assert.AreEqual(14, FPresenter.Screen.GetForeground(4, 4));
  Assert.AreEqual(Integer(ENDOOM_EDITOR_FIRST_SPECIAL_CODE), Integer(FPresenter.Screen.GetCharacter(4, 4)));
  FPresenter.SelectSpecialCharacter1($DB);
  Click(5, 4);
  Assert.AreEqual(Integer($DB), Integer(FPresenter.Screen.GetCharacter(5, 4)));
  FPresenter.SelectSpecialCharacter2($B2);
  FPresenter.SelectTool(eetSpecialCharacter);
  Click(6, 4);
  Assert.AreEqual(Integer($B2), Integer(FPresenter.Screen.GetCharacter(6, 4)));
  Assert.AreEqual(0, Background(6, 4));
  Assert.AreEqual(14, FPresenter.Screen.GetForeground(6, 4));
end;

procedure TTestEndoomEditorPresenter.DovrebbeCambiareSoloIlPrimoPiano;
begin
  FPresenter.Start('');
  FPresenter.Screen.SetCharacter(2, 2, 66);
  FPresenter.SelectForeground(9);
  FPresenter.SelectTool(eetTextColor);
  Click(2, 2);
  Assert.AreEqual(9, FPresenter.Screen.GetForeground(2, 2));
  Assert.AreEqual(66, Integer(FPresenter.Screen.GetCharacter(2, 2)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeDisegnareLeCornici;
begin
  FPresenter.Start('');
  FPresenter.SelectForeground(14);
  FPresenter.SelectTool(eetFrameDouble);
  Drag(2, 2, 6, 5);
  Assert.AreEqual(Integer($C9), Integer(FPresenter.Screen.GetCharacter(2, 2)));
  Assert.AreEqual(Integer($BC), Integer(FPresenter.Screen.GetCharacter(6, 5)));
  Assert.AreEqual(14, FPresenter.Screen.GetForeground(4, 2));
  FPresenter.SelectTool(eetFrameSingle);
  Drag(10, 2, 12, 4);
  Assert.AreEqual(Integer($DA), Integer(FPresenter.Screen.GetCharacter(10, 2)));
  FPresenter.SelectTool(eetFrameDoubleHorizontal);
  Drag(20, 2, 22, 4);
  Assert.AreEqual(Integer($D5), Integer(FPresenter.Screen.GetCharacter(20, 2)));
  FPresenter.SelectTool(eetFrameDoubleVertical);
  Drag(30, 2, 32, 4);
  Assert.AreEqual(Integer($D6), Integer(FPresenter.Screen.GetCharacter(30, 2)));
  FPresenter.SelectTool(eetFrameBlock);
  Drag(40, 2, 42, 4);
  Assert.AreEqual(Integer($DB), Integer(FPresenter.Screen.GetCharacter(41, 2)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeAccendereESpegnereIlLampeggio;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetBlinkOn);
  Drag(3, 3, 6, 3);
  Assert.IsTrue(FPresenter.Screen.GetBlink(3, 3));
  Assert.IsTrue(FPresenter.Screen.GetBlink(6, 3));
  FPresenter.SelectTool(eetBlinkOff);
  Click(4, 3);
  Assert.IsFalse(FPresenter.Screen.GetBlink(4, 3));
  Assert.IsTrue(FPresenter.Screen.GetBlink(5, 3));
end;

procedure TTestEndoomEditorPresenter.DovrebbeMettereIlCursoreConLoStrumentoTesto;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  Click(7, 9);
  Assert.AreEqual(7, FPresenter.CursorX);
  Assert.AreEqual(9, FPresenter.CursorY);
  Assert.IsTrue(FView.Overlay.CursorVisible);
  Assert.AreEqual(7, FView.Overlay.CursorX);
  // the click does not change the screen: nothing to undo, nothing changed
  Assert.IsFalse(FView.State.CanUndo);
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestEndoomEditorPresenter.DovrebbeScrivereIlTestoDalCursore;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  FPresenter.SelectForeground(12);
  Click(5, 2);
  Type_('Hi');
  Assert.AreEqual(Integer(Ord('H')), Integer(FPresenter.Screen.GetCharacter(5, 2)));
  Assert.AreEqual(Integer(Ord('i')), Integer(FPresenter.Screen.GetCharacter(6, 2)));
  Assert.AreEqual(12, FPresenter.Screen.GetForeground(6, 2));
  Assert.AreEqual(7, FPresenter.CursorX);
  Assert.IsTrue(FPresenter.Modified);
  Assert.IsTrue(FView.State.CanUndo);
  // the same character on the same color is not a change
  FPresenter.Undo;
  FPresenter.Undo;
  Assert.AreEqual(0, Integer(FPresenter.Screen.GetCharacter(5, 2)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeAndareACapoAFineRiga;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  Click(79, 3);
  Type_('ab');
  Assert.AreEqual(Integer(Ord('a')), Integer(FPresenter.Screen.GetCharacter(79, 3)));
  Assert.AreEqual(Integer(Ord('b')), Integer(FPresenter.Screen.GetCharacter(0, 4)));
  Click(79, 24);
  Type_('zz');
  Assert.AreEqual(79, FPresenter.CursorX);
  Assert.AreEqual(24, FPresenter.CursorY);
end;

procedure TTestEndoomEditorPresenter.DovrebbeCancellareIndietro;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  Click(0, 4);
  Type_('x');
  FPresenter.KeyPress(#8);
  Assert.AreEqual(0, FPresenter.CursorX);
  Assert.AreEqual(Integer(Ord(' ')), Integer(FPresenter.Screen.GetCharacter(0, 4)));
  // at the start of a row it goes to the end of the row before
  FPresenter.KeyPress(#8);
  Assert.AreEqual(79, FPresenter.CursorX);
  Assert.AreEqual(3, FPresenter.CursorY);
  // at the very start it stays
  Click(0, 0);
  FPresenter.KeyPress(#8);
  Assert.AreEqual(0, FPresenter.CursorX);
  Assert.AreEqual(0, FPresenter.CursorY);
end;

procedure TTestEndoomEditorPresenter.DovrebbeAndareACapoConInvio;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  Click(30, 4);
  FPresenter.KeyPress(#13);
  Assert.AreEqual(0, FPresenter.CursorX);
  Assert.AreEqual(5, FPresenter.CursorY);
  Click(10, 24);
  FPresenter.KeyPress(#13);
  Assert.AreEqual(10, FPresenter.CursorX);
  Assert.AreEqual(24, FPresenter.CursorY);
end;

procedure TTestEndoomEditorPresenter.DovrebbeMuovereIlCursoreConITasti;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  Click(10, 10);
  FPresenter.KeyDown(eekLeft);
  FPresenter.KeyDown(eekUp);
  Assert.AreEqual(9, FPresenter.CursorX);
  Assert.AreEqual(9, FPresenter.CursorY);
  FPresenter.KeyDown(eekRight);
  FPresenter.KeyDown(eekRight);
  FPresenter.KeyDown(eekDown);
  Assert.AreEqual(11, FPresenter.CursorX);
  Assert.AreEqual(10, FPresenter.CursorY);
  FPresenter.KeyDown(eekHome);
  Assert.AreEqual(0, FPresenter.CursorX);
  FPresenter.KeyDown(eekLeft);
  Assert.AreEqual(0, FPresenter.CursorX);
  FPresenter.KeyDown(eekEnd);
  Assert.AreEqual(79, FPresenter.CursorX);
  FPresenter.KeyDown(eekRight);
  Assert.AreEqual(79, FPresenter.CursorX);
  FPresenter.KeyDown(eekPageUp);
  Assert.AreEqual(5, FPresenter.CursorY);
  FPresenter.KeyDown(eekPageUp);
  FPresenter.KeyDown(eekPageUp);
  Assert.AreEqual(0, FPresenter.CursorY);
  FPresenter.KeyDown(eekUp);
  Assert.AreEqual(0, FPresenter.CursorY);
  FPresenter.KeyDown(eekPageDown);
  FPresenter.KeyDown(eekPageDown);
  FPresenter.KeyDown(eekPageDown);
  FPresenter.KeyDown(eekPageDown);
  FPresenter.KeyDown(eekPageDown);
  FPresenter.KeyDown(eekPageDown);
  Assert.AreEqual(24, FPresenter.CursorY);
  FPresenter.KeyDown(eekDown);
  Assert.AreEqual(24, FPresenter.CursorY);
end;

procedure TTestEndoomEditorPresenter.DovrebbeCancellareIlCarattereConCanc;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  FPresenter.Screen.SetCharacter(3, 3, 65);
  Click(3, 3);
  FPresenter.KeyDown(eekDelete);
  Assert.AreEqual(Integer(Ord(' ')), Integer(FPresenter.Screen.GetCharacter(3, 3)));
  Assert.IsTrue(FPresenter.Modified);
  // a blank cell is not a change: nothing more to undo than the first
  FPresenter.KeyDown(eekDelete);
  FPresenter.Undo;
  Assert.AreEqual(65, Integer(FPresenter.Screen.GetCharacter(3, 3)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeIgnorareITastiConUnAltroStrumento;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetFreeDraw);
  Type_('abc');
  FPresenter.KeyDown(eekEnd);
  Assert.AreEqual(0, FPresenter.CursorX);
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestEndoomEditorPresenter.DovrebbeIgnorareICaratteriFuoriDalDominio;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetText);
  FPresenter.KeyPress(#5);
  FPresenter.KeyPress(#$20AC);
  FPresenter.KeyPress(Chr(129));
  Assert.IsFalse(FPresenter.Modified);
  Assert.AreEqual(0, FPresenter.CursorX);
  // the characters 32 to 128 are the ones that are typed (as in ENDEDIT)
  FPresenter.KeyPress(Chr(128));
  Assert.IsTrue(FPresenter.Modified, 'modified');
  Assert.AreEqual(1, FPresenter.CursorX, 'cursor');
  Assert.AreEqual(128, Integer(FPresenter.Screen.GetCharacter(0, 0)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeTrovareLaCellaConLoZoom;
begin
  FPresenter.Start('');
  FPresenter.ZoomIn;
  FPresenter.ZoomIn;
  // zoom 2: a cell is 10 pixels wide and 20 tall, and the pixels past the picture belong to the last cell
  FPresenter.SelectBackground(1);
  FPresenter.SelectTool(eetFloodFill);
  FPresenter.SelectTool(eetFreeDraw);
  FPresenter.MouseDown(35, 41);
  FPresenter.MouseUp(35, 41);
  Assert.AreEqual(1, Background(3, 2));
  FPresenter.MouseDown(5000, 5000);
  FPresenter.MouseUp(5000, 5000);
  Assert.AreEqual(1, Background(79, 24));
  FPresenter.MouseDown(-5, -5);
  FPresenter.MouseUp(-5, -5);
  Assert.AreEqual(1, Background(0, 0));
end;

procedure TTestEndoomEditorPresenter.DovrebbeLimitareLoZoom;
var
  LIndex: Integer;
begin
  FPresenter.Start('');
  FPresenter.ZoomOut;
  Assert.AreEqual(0, FPresenter.Zoom);
  for LIndex := 1 to 30 do
    FPresenter.ZoomIn;
  Assert.AreEqual(ENDOOM_EDITOR_MAX_ZOOM, FPresenter.Zoom);
  Assert.IsFalse(FView.State.CanZoomIn);
  Assert.IsTrue(FView.State.CanZoomOut);
  FPresenter.ZoomOut;
  Assert.AreEqual(ENDOOM_EDITOR_MAX_ZOOM - 1, FPresenter.Zoom);
  Assert.AreEqual(ENDOOM_EDITOR_MAX_ZOOM - 1, FView.Overlay.Zoom);
end;

procedure TTestEndoomEditorPresenter.DovrebbeMostrareLaGriglia;
begin
  FPresenter.Start('');
  Assert.IsFalse(FView.Overlay.ShowGrid);
  FPresenter.ToggleGrid;
  Assert.IsTrue(FView.Overlay.ShowGrid);
  FPresenter.ToggleGrid;
  Assert.IsFalse(FView.Overlay.ShowGrid);
end;

procedure TTestEndoomEditorPresenter.DovrebbeAnnullareERifare;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(2);
  Click(1, 1);
  Click(2, 1);
  FPresenter.Undo;
  Assert.AreEqual(0, Background(2, 1));
  Assert.AreEqual(2, Background(1, 1));
  FPresenter.Redo;
  Assert.AreEqual(2, Background(2, 1));
  FPresenter.Redo;
  FPresenter.Undo;
  FPresenter.Undo;
  FPresenter.Undo;
  Assert.AreEqual(0, Background(1, 1));
  Assert.IsFalse(FView.State.CanUndo);
end;

procedure TTestEndoomEditorPresenter.DovrebbeSegnareLeModifiche;
begin
  FPresenter.Start('');
  Assert.IsFalse(FPresenter.Modified);
  Click(1, 1);
  Assert.IsTrue(FPresenter.Modified);
end;

procedure TTestEndoomEditorPresenter.DovrebbeChiedereSeSalvareLeModifiche;
begin
  FPresenter.Start('');
  Assert.IsTrue(FPresenter.TryClose);
  Assert.AreEqual(0, FDialogs.ConfirmCount);
  Click(1, 1);
  FDialogs.Confirmation := ecNo;
  Assert.IsTrue(FPresenter.TryClose);
  Assert.AreEqual(1, FDialogs.ConfirmCount);
  FDialogs.Confirmation := ecCancel;
  Assert.IsFalse(FPresenter.TryClose);
end;

procedure TTestEndoomEditorPresenter.DovrebbeSalvareSeLUtenteDiceSi;
begin
  FPresenter.Start('');
  Click(1, 1);
  FDialogs.Confirmation := ecYes;
  FDialogs.SaveResult := True;
  FDialogs.SaveName := 'C:\nuovo.bin';
  Assert.IsTrue(FPresenter.TryClose);
  Assert.IsTrue(FFileSystem.FileExists('C:\nuovo.bin'));
  Assert.IsFalse(FPresenter.Modified);
  // yes, but the file is not chosen: the changes are still there and the program does not close
  Click(2, 2);
  FFileSystem.FailWrite := True;
  Assert.IsFalse(FPresenter.TryClose);
  Assert.IsTrue(FPresenter.Modified);
end;
procedure TTestEndoomEditorPresenter.DovrebbeNonChiudereSeLUtenteAnnulla;
begin
  FPresenter.Start('');
  Click(1, 1);
  FDialogs.Confirmation := ecCancel;
  FPresenter.RequestClose;
  Assert.AreEqual(0, FView.CloseCount);
  FDialogs.Confirmation := ecNo;
  FPresenter.RequestClose;
  Assert.AreEqual(1, FView.CloseCount);
  FPresenter.About;
  Assert.AreEqual(1, FDialogs.AboutCount);
end;

procedure TTestEndoomEditorPresenter.DovrebbeCreareUnNuovoDocumento;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(5);
  Click(2, 2);
  FDialogs.Confirmation := ecCancel;
  FPresenter.NewDocument;
  Assert.AreEqual(5, Background(2, 2));
  FDialogs.Confirmation := ecNo;
  FPresenter.NewDocument;
  Assert.AreEqual(0, Background(2, 2));
  Assert.IsFalse(FPresenter.Modified);
  Assert.IsFalse(FView.State.CanUndo);
  Assert.AreEqual(ENDOOM_EDITOR_TITLE, FView.Title);
end;

procedure TTestEndoomEditorPresenter.DovrebbeAprireUnFile;
begin
  PutScreenFile('C:\x\aperto.bin', 70);
  FPresenter.Start('');
  FDialogs.OpenResult := False;
  FPresenter.OpenFile;
  Assert.AreEqual('', FPresenter.FileName);
  FDialogs.OpenResult := True;
  FDialogs.OpenName := 'C:\x\aperto.bin';
  FPresenter.OpenFile;
  Assert.AreEqual(70, Integer(FPresenter.Screen.GetCharacter(0, 0)));
  Assert.AreEqual('C:\x\aperto.bin', FPresenter.FileName);
  FDialogs.OpenName := 'C:\x\manca.bin';
  FPresenter.OpenFile;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.AreEqual('C:\x\aperto.bin', FPresenter.FileName);
end;

procedure TTestEndoomEditorPresenter.DovrebbeAprireUnFileRecente;
begin
  PutScreenFile('C:\a.bin', 1);
  PutScreenFile('C:\b.bin', 2);
  FPresenter.Start('C:\a.bin');
  FPresenter.OpenRecent(0);
  FDialogs.OpenResult := True;
  FDialogs.OpenName := 'C:\b.bin';
  FPresenter.OpenFile;
  Assert.AreEqual<Integer>(2, Length(FView.RecentCaptions));
  Assert.AreEqual('&1. C:\b.bin', FView.RecentCaptions[0]);
  FPresenter.OpenRecent(1);
  Assert.AreEqual(1, Integer(FPresenter.Screen.GetCharacter(0, 0)));
  FPresenter.OpenRecent(7);
  FPresenter.OpenRecent(-1);
  Assert.AreEqual('C:\a.bin', FPresenter.FileName);
  // not while there are changes that the user wants to keep
  Click(3, 3);
  FDialogs.Confirmation := ecCancel;
  FPresenter.OpenRecent(1);
  Assert.AreEqual('C:\a.bin', FPresenter.FileName);
end;

procedure TTestEndoomEditorPresenter.DovrebbeSalvareConLaCopiaDiSicurezza;
begin
  PutScreenFile('C:\a.bin', 1);
  FPresenter.Start('C:\a.bin');
  FPresenter.SelectBackground(3);
  Click(5, 5);
  Assert.IsTrue(FPresenter.Modified);
  FPresenter.Save;
  Assert.IsFalse(FPresenter.Modified);
  Assert.IsTrue(FFileSystem.FileExists('C:\a.bin_bak'));
  Assert.AreEqual(1, FFileSystem.CopyCount);
  Assert.AreEqual(Integer($30), Integer(FPresenter.Screen.GetCell(5, 5).Attributes));
  Assert.AreEqual<Integer>(1, Length(FView.RecentCaptions));
end;

procedure TTestEndoomEditorPresenter.DovrebbeSalvareConNome;
var
  LBytes: TBytes;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(2);
  Click(1, 1);
  FDialogs.SaveResult := False;
  FPresenter.Save;
  Assert.IsTrue(FPresenter.Modified);
  FDialogs.SaveResult := True;
  FDialogs.SaveName := 'C:\nuovo\fine.bin';
  FPresenter.Save;
  Assert.IsFalse(FPresenter.Modified);
  Assert.AreEqual('C:\nuovo\fine.bin', FPresenter.FileName);
  Assert.IsTrue(FFileSystem.TryReadAllBytes('C:\nuovo\fine.bin', LBytes));
  Assert.AreEqual<Integer>(ENDOOM_LUMP_SIZE, Length(LBytes));
  // no backup of a file that did not exist
  Assert.AreEqual(0, FFileSystem.CopyCount);
  // saved again with the name it has now
  FDialogs.SaveResult := False;
  Click(2, 2);
  FPresenter.Save;
  Assert.IsFalse(FPresenter.Modified);
  Assert.AreEqual(1, FFileSystem.CopyCount);
  FPresenter.SaveAs;
  Assert.AreEqual('C:\nuovo\fine.bin', FDialogs.SaveSuggested);
end;

procedure TTestEndoomEditorPresenter.DovrebbeDireSeNonRiesceASalvare;
begin
  FPresenter.Start('');
  Click(1, 1);
  FDialogs.SaveResult := True;
  FDialogs.SaveName := 'C:\x.bin';
  FFileSystem.FailWrite := True;
  FPresenter.Save;
  Assert.IsTrue(FPresenter.Modified);
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('Can not write'));
  Assert.AreEqual('', FPresenter.FileName);
end;

procedure TTestEndoomEditorPresenter.DovrebbeEsportareLaPittura;
var
  LRow: Integer;
  LColumn: Integer;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(1);
  Click(0, 0);
  FDialogs.ExportResult := False;
  FPresenter.ExportImage;
  Assert.AreEqual(0, FExporter.Calls);
  FDialogs.ExportResult := True;
  FDialogs.ExportName := 'C:\fine.png';
  FPresenter.ExportImage;
  Assert.AreEqual(1, FExporter.Calls);
  Assert.AreEqual('C:\fine.png', FExporter.FileName);
  Assert.AreEqual(640, FExporter.Width);
  Assert.AreEqual(400, FExporter.Height);
  Assert.AreEqual<Integer>(640 * 400, Length(FExporter.Pixels));
  // every row of the screen twice
  for LRow := 0 to 399 do
    for LColumn := 0 to 639 do
      if FExporter.Pixels[LRow * 640 + LColumn] <> FView.Pixels[(LRow div 2) * 640 + LColumn] then
        Assert.Fail('row ' + IntToStr(LRow));
  Assert.AreEqual(Int64($FF0000AA), Int64(FExporter.Pixels[0]));
  FExporter.Succeeds := False;
  FPresenter.ExportImage;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('Can not export'));
end;

procedure TTestEndoomEditorPresenter.DovrebbeCopiareLaPitturaNegliAppunti;
begin
  FPresenter.Start('');
  FPresenter.CopyImage;
  Assert.AreEqual(1, FClipboard.SetImageCount);
  Assert.AreEqual(640, FClipboard.ImageWidth);
  Assert.AreEqual(400, FClipboard.ImageHeight);
  // now it can be pasted
  Assert.IsTrue(FView.State.CanPaste);
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestEndoomEditorPresenter.DovrebbeTagliareLaPittura;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(4);
  FPresenter.SelectTool(eetFloodFill);
  Click(1, 1);
  FPresenter.CutImage;
  Assert.AreEqual(1, FClipboard.SetImageCount);
  Assert.AreEqual(0, Background(10, 10));
  Assert.IsTrue(FPresenter.Modified);
  FPresenter.Undo;
  Assert.AreEqual(4, Background(10, 10));
end;

procedure TTestEndoomEditorPresenter.DovrebbeIncollareUnaPitturaComeTestoColorato;
var
  LBefore: Integer;
begin
  FPresenter.Start('');
  SetLength(FClipboard.ImagePixels, 4);
  FClipboard.ImageWidth := 2;
  FClipboard.ImageHeight := 2;
  FResampler.Fill := $0000AA;
  FDialogs.MethodResult := False;
  FPresenter.Paste;
  // the user cancelled the choice of the method: nothing changes
  Assert.AreEqual(0, FResampler.Calls);
  Assert.IsFalse(FPresenter.Modified);
  FDialogs.MethodResult := True;
  FDialogs.MethodKind := eakBackgroundOnly;
  FPresenter.Paste;
  Assert.AreEqual(1, FResampler.Calls);
  Assert.AreEqual(1, Background(0, 0));
  Assert.AreEqual(1, Background(79, 24));
  Assert.AreEqual(Ord(eakBackgroundOnly), Ord(FPresenter.TextArtMethod));
  Assert.IsTrue(FPresenter.Modified);
  Assert.IsTrue(FView.State.CanUndo);
  LBefore := FView.PictureCount;
  FPresenter.Undo;
  Assert.AreEqual(0, Background(0, 0));
  Assert.IsTrue(FView.PictureCount > LBefore);
end;

procedure TTestEndoomEditorPresenter.DovrebbeIncollareUnTesto;
begin
  FPresenter.Start('');
  FClipboard.Text := 'uno'#13#10'due';
  FPresenter.SelectForeground(10);
  FPresenter.Paste;
  Assert.AreEqual(Integer(Ord('u')), Integer(FPresenter.Screen.GetCharacter(0, 0)));
  Assert.AreEqual(Integer(Ord('d')), Integer(FPresenter.Screen.GetCharacter(0, 1)));
  Assert.AreEqual(10, FPresenter.Screen.GetForeground(2, 1));
  Assert.AreEqual(3, FPresenter.CursorX);
  Assert.AreEqual(1, FPresenter.CursorY);
  Assert.IsTrue(FPresenter.Modified);
  // with the text tool it goes where the cursor is
  FPresenter.SelectTool(eetText);
  Click(20, 10);
  FClipboard.Text := 'xy';
  FPresenter.Paste;
  Assert.AreEqual(Integer(Ord('x')), Integer(FPresenter.Screen.GetCharacter(20, 10)));
  Assert.AreEqual(22, FPresenter.CursorX);
end;

procedure TTestEndoomEditorPresenter.DovrebbeNonIncollareSenzaAppunti;
begin
  FPresenter.Start('');
  FPresenter.Paste;
  Assert.IsFalse(FPresenter.Modified);
  Assert.IsFalse(FView.State.CanUndo);
  // a picture on the clipboard comes before a text
  SetLength(FClipboard.ImagePixels, 4);
  FClipboard.ImageWidth := 2;
  FClipboard.ImageHeight := 2;
  FClipboard.Text := 'testo';
  FDialogs.MethodResult := False;
  FPresenter.Paste;
  Assert.AreEqual(0, Integer(FPresenter.Screen.GetCharacter(0, 0)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeUsareLaSelezione;
begin
  FPresenter.Start('');
  FPresenter.SelectBackground(3);
  FPresenter.SelectTool(eetSelect);
  Drag(10, 5, 12, 6);
  Assert.IsTrue(FPresenter.HasSelection);
  Assert.AreEqual(10, FPresenter.Selection.Left);
  Assert.AreEqual(12, FPresenter.Selection.Right);
  Assert.AreEqual(6, FPresenter.Selection.Bottom);
  Assert.IsTrue(FView.Overlay.SelectionVisible);
  Assert.IsTrue(FView.State.HasSelection);
  // the selection does not change the screen
  Assert.IsFalse(FPresenter.Modified);
  FPresenter.FillSelection;
  Assert.AreEqual(3, Background(11, 5));
  Assert.AreEqual(0, Background(13, 5));
  FPresenter.Screen.SetCharacter(10, 5, 65);
  FPresenter.CopySelection;
  Assert.IsTrue(FView.State.HasBlock);
  FPresenter.DeleteSelection;
  Assert.AreEqual(0, Background(11, 5));
  Assert.AreEqual(0, Integer(FPresenter.Screen.GetCharacter(10, 5)));
  // paste at the selection, then somewhere else
  FPresenter.PasteSelection;
  Assert.AreEqual(65, Integer(FPresenter.Screen.GetCharacter(10, 5)));
  Assert.AreEqual(3, Background(12, 6));
  Drag(40, 10, 40, 10);
  FPresenter.PasteSelection;
  Assert.AreEqual(65, Integer(FPresenter.Screen.GetCharacter(40, 10)));
  FPresenter.CutSelection;
  Assert.AreEqual(0, Integer(FPresenter.Screen.GetCharacter(40, 10)));
  FPresenter.SelectAll;
  Assert.AreEqual(79, FPresenter.Selection.Right);
  Assert.AreEqual(24, FPresenter.Selection.Bottom);
  FPresenter.ClearSelection;
  Assert.IsFalse(FPresenter.HasSelection);
  Assert.IsFalse(FView.Overlay.SelectionVisible);
  // with no selection the block goes to the cursor
  FPresenter.SelectTool(eetText);
  Click(60, 20);
  FPresenter.PasteSelection;
  Assert.AreEqual(65, Integer(FPresenter.Screen.GetCharacter(60, 20)));
end;

procedure TTestEndoomEditorPresenter.DovrebbeNonUsareLaSelezioneSeNonCe;
begin
  FPresenter.Start('');
  FPresenter.CopySelection;
  FPresenter.CutSelection;
  FPresenter.DeleteSelection;
  FPresenter.FillSelection;
  FPresenter.PasteSelection;
  Assert.IsFalse(FPresenter.Modified);
  Assert.IsFalse(FView.State.HasBlock);
  Assert.IsFalse(FView.State.CanUndo);
end;

procedure TTestEndoomEditorPresenter.DovrebbeNasconderePerIlLampeggioIlCarattereCheLampeggia;
begin
  FPresenter.Start('');
  // a full block, white on blue, that blinks
  FPresenter.Screen.SetCharacter(0, 0, $DB);
  FPresenter.Screen.SetForeground(0, 0, 15);
  FPresenter.Screen.SetBackground(0, 0, 1);
  FPresenter.Screen.SetBlink(0, 0, True);
  FPresenter.SelectTool(eetFreeDraw);
  Assert.IsFalse(FPresenter.BlinkHidden);
  Assert.AreEqual(Int64($FFFFFFFF), Int64(FView.Pixels[0]));
  FPresenter.BlinkTick;
  Assert.IsTrue(FPresenter.BlinkHidden);
  Assert.AreEqual(Int64($FF0000AA), Int64(FView.Pixels[0]));
  FPresenter.BlinkTick;
  Assert.AreEqual(Int64($FFFFFFFF), Int64(FView.Pixels[0]));
end;

procedure TTestEndoomEditorPresenter.DovrebbeFarLampeggiareIlCursoreSoloConLoStrumentoTesto;
begin
  FPresenter.Start('');
  FPresenter.CursorTick;
  Assert.IsFalse(FView.Overlay.CursorInverted);
  FPresenter.SelectTool(eetText);
  FPresenter.CursorTick;
  Assert.IsTrue(FView.Overlay.CursorInverted);
  FPresenter.CursorTick;
  Assert.IsFalse(FView.Overlay.CursorInverted);
  FPresenter.SelectTool(eetFreeDraw);
  Assert.IsFalse(FView.Overlay.CursorVisible);
end;

procedure TTestEndoomEditorPresenter.DovrebbeDireLaPosizioneInBarraDiStato;
begin
  FPresenter.Start('');
  FPresenter.Screen.SetCharacter(3, 2, $41);
  FPresenter.Screen.SetBackground(3, 2, 1);
  FPresenter.Screen.SetForeground(3, 2, 14);
  FPresenter.MouseMove(Px(3), Py(2));
  Assert.AreEqual('Position: (3, 2), Background: (#0000AA), Foreground: (#FFFF55), Text: (#41)', FView.Status);
end;

procedure TTestEndoomEditorPresenter.DovrebbeIgnorareIlMouseSenzaPulsante;
var
  LCount: Integer;
begin
  FPresenter.Start('');
  LCount := FView.PictureCount;
  FPresenter.MouseMove(Px(5), Py(5));
  FPresenter.MouseUp(Px(5), Py(5));
  Assert.AreEqual(LCount, FView.PictureCount);
  Assert.IsFalse(FPresenter.Modified);
  // changing the tool in the middle of a drag drops the drag
  FPresenter.SelectBackground(3);
  FPresenter.MouseDown(Px(5), Py(5));
  FPresenter.SelectTool(eetLine);
  FPresenter.MouseMove(Px(9), Py(9));
  Assert.AreEqual(0, Background(9, 9));
end;

procedure TTestEndoomEditorPresenter.DovrebbeMostrareLeScelteEIlTitolo;
begin
  FPresenter.Start('');
  FPresenter.SelectTool(eetBlinkOn);
  FPresenter.SelectForeground(99);
  FPresenter.SelectBackground(99);
  FPresenter.SelectSpecialCharacter1(300);
  FPresenter.SelectSpecialCharacter2(-4);
  Assert.AreEqual(Ord(eetBlinkOn), Ord(FView.Tool));
  Assert.AreEqual(15, FView.Foreground);
  Assert.AreEqual(7, FView.Background);
  Assert.AreEqual(255, FView.Special1);
  Assert.AreEqual(0, FView.Special2);
  Assert.AreEqual(Ord(eetBlinkOn), Ord(FPresenter.Tool));
  FPresenter.SelectForeground(-3);
  Assert.AreEqual(0, FPresenter.Foreground);
  FPresenter.SelectBackground(-3);
  Assert.AreEqual(0, FPresenter.Background);
  Assert.AreEqual(255, FPresenter.SpecialCharacter1);
  Assert.AreEqual(0, FPresenter.SpecialCharacter2);
end;

procedure TTestEndoomEditorPresenter.DovrebbeAggiornareLoStatoDeiComandi;
begin
  FPresenter.Start('');
  Assert.IsFalse(FView.State.CanPaste);
  FClipboard.Text := 'x';
  FPresenter.RefreshState;
  Assert.IsTrue(FView.State.CanPaste);
end;

end.
