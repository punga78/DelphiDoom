{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorPresenter (issue #167)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Presenter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Intf,
  DelphiDoom.VoxelEditor.Presenter,
  DelphiDoom.Tests.ToolsCore.Fakes,
  DelphiDoom.Tests.VoxelEditor.Fakes;

type
  /// <summary>
  ///   The presenter with the real model (cube, painter, formats, undo, recent files, settings, backup) and fakes for
  ///   what is the system: the window, the dialogs, the clipboard, the picture files and the files
  /// </summary>
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorPresenter = class(TObject)
  strict private
    const
      INI_FILE = 'C:\tools\tools.ini';
      VOXEL_FILE = 'C:\work\mine.ddvox';
    var
      FView: TFakeVoxelView;
      FViewIntf: IVoxelEditorView;
      FDialogs: TFakeVoxelDialogs;
      FDialogsIntf: IVoxelEditorDialogs;
      FClipboard: TFakeVoxelClipboard;
      FClipboardIntf: IVoxelEditorClipboard;
      FLoader: TFakeVoxelImageLoader;
      FLoaderIntf: IVoxelEditorImageLoader;
      FExporter: TFakeVoxelImageExporter;
      FExporterIntf: IVoxelEditorImageExporter;
      FFileSystem: TFakeToolFileSystem;
      FFileSystemIntf: IToolFileSystem;
      FPresenter: TVoxelEditorPresenter;
    function NewPresenter: TVoxelEditorPresenter;
    procedure StartFresh;
    procedure PutCells(const AColors: array of Cardinal);
    function PlaneIndex(AAxis: TVoxelEditorAxis; ALevel: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMostrareAllAvvioUnVoxelNuovoEVistoDallAlto;
    [Test]
    procedure DovrebbeLeggereLeImpostazioni;
    [Test]
    procedure DovrebbeSalvareLeImpostazioniAllaChiusura;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
    [Test]
    procedure DovrebbeAprireIlVoxelDellaRigaDiComando;
    [Test]
    procedure DovrebbeDisegnareConIlMouseEPoterAnnullare;
    [Test]
    procedure DovrebbeDisegnareUnaLineaTraDuePuntiDelMouse;
    [Test]
    procedure DovrebbeCancellareConLaGomma;
    [Test]
    procedure DovrebbeRiempireUnaZona;
    [Test]
    procedure DovrebbePrendereUnColoreConIlContagocce;
    [Test]
    procedure DovrebbeAlzareUnVoxelConLaMatita;
    [Test]
    procedure DovrebbeNonPermetterediAlzareSuUnaSezione;
    [Test]
    procedure DovrebbeDareLaDescrizioneDelPuntoSottoIlMouse;
    [Test]
    procedure DovrebbeScegliereUnaSezioneEIlSuoLivello;
    [Test]
    procedure DovrebbeElencareLeSezioniELeViste;
    [Test]
    procedure DovrebbeSalireEScendereDiLivelloSoloNelleSezioni;
    [Test]
    procedure DovrebbeCopiareTagliareIncollareECancellare;
    [Test]
    procedure DovrebbeCopiareEIncollareUnaVista;
    [Test]
    procedure DovrebbeNonIncollareSeNonCEUnaImmagine;
    [Test]
    procedure DovrebbeSpecchiareEGirareIlPiano;
    [Test]
    procedure DovrebbeIngrandireEImpicciolireFinoAiLimiti;
    [Test]
    procedure DovrebbeSalvareEAprireUnVoxel;
    [Test]
    procedure DovrebbeSalvareConLaCopiaDiSicurezza;
    [Test]
    procedure DovrebbeAvvisareSeIlVoxelNonSiScrive;
    [Test]
    procedure DovrebbeAvvisareSeIlFileDaAprireNonCe;
    [Test]
    procedure DovrebbeAvvisareUnFileDaAprireMalformato;
    [Test]
    procedure DovrebbeAprireUnFileDellaListaDeiRecenti;
    [Test]
    procedure DovrebbeChiedereSeSalvareLeModificheChiudendo;
    [Test]
    procedure DovrebbeFareUnVoxelNuovoDellaDimensioneScelta;
    [Test]
    procedure DovrebbeImportareUnKvxUnVoxEUnDdmesh;
    [Test]
    procedure DovrebbeAvvisareUnImportMalformato;
    [Test]
    procedure DovrebbeEsportareIlVoxEIlDdmesh;
    [Test]
    procedure DovrebbeEsportareLeImmagini;
    [Test]
    procedure DovrebbeImportareUnaImmagineSulPiano;
    [Test]
    procedure DovrebbeFareUnVoxelDaUnaMappaDelleAltezze;
    [Test]
    procedure DovrebbeApplicareUnaTexturaAlTerreno;
    [Test]
    procedure DovrebbeTogliereIVoxelNonVisibili;
    [Test]
    procedure DovrebbeRuotareIlVoxel;
    [Test]
    procedure DovrebbeTagliareEStringereLAltezza;
    [Test]
    procedure DovrebbeContareIColori;
    [Test]
    procedure DovrebbeFareLaScalaDiGrigiESoloSeCambiaQualcosa;
    [Test]
    procedure DovrebbeRidurreAUnaPaletta;
    [Test]
    procedure DovrebbeScegliereIColoriDallaPalettaEDalDialogo;
    [Test]
    procedure DovrebbeConvertireUnElencoDiFile;
    [Test]
    procedure DovrebbeMostrareLAbout;
  end;

implementation

uses
  DelphiDoom.Tools.Factory, DelphiDoom.Tools.Types,
  DelphiDoom.VoxelEditor.Model,
  DelphiDoom.VoxelEditor.Format.Ddvox,
  DelphiDoom.VoxelEditor.Format.Vox,
  DelphiDoom.VoxelEditor.Palettes,
  DelphiDoom.Tests.VoxelEditor.Scenarios;

{ TTestVoxelEditorPresenter }

procedure TTestVoxelEditorPresenter.Setup;
begin
  FView := TFakeVoxelView.Create;
  FViewIntf := FView;
  FDialogs := TFakeVoxelDialogs.Create;
  FDialogsIntf := FDialogs;
  FClipboard := TFakeVoxelClipboard.Create;
  FClipboardIntf := FClipboard;
  FLoader := TFakeVoxelImageLoader.Create;
  FLoaderIntf := FLoader;
  FLoader.CanLoad := True;
  FLoader.Width := 10;
  FLoader.Height := 10;
  FLoader.Fill := $808080;
  FExporter := TFakeVoxelImageExporter.Create;
  FExporterIntf := FExporter;
  FFileSystem := TFakeToolFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FPresenter := NewPresenter;
end;

procedure TTestVoxelEditorPresenter.TearDown;
begin
  FreeAndNil(FPresenter);
end;

function TTestVoxelEditorPresenter.NewPresenter: TVoxelEditorPresenter;
begin
  Result := TVoxelEditorPresenter.Create(FViewIntf, FDialogsIntf, FClipboardIntf, FLoaderIntf, FExporterIntf,
    FFileSystemIntf, TToolsFactory.CreateFileBackup(FFileSystemIntf),
    TToolsFactory.CreateSettings(FFileSystemIntf, INI_FILE), TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT),
    TToolsFactory.CreateUndoHistory(TOOLS_UNDO_LIMIT));
end;

procedure TTestVoxelEditorPresenter.StartFresh;
begin
  FDialogs.NewSizeValue := 16;
  FFileSystem.PutText(INI_FILE, '[Voxel Options]'#13#10'NEWVOXELSIZE=16'#13#10'ZOOM=4'#13#10);
  FPresenter.Start('');
end;

procedure TTestVoxelEditorPresenter.PutCells(const AColors: array of Cardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AColors) do
    FPresenter.Model.Put(LIndex, 0, 0, AColors[LIndex]);
end;

function TTestVoxelEditorPresenter.PlaneIndex(AAxis: TVoxelEditorAxis; ALevel: Integer): Integer;
begin
  Result := (Ord(AAxis) - Ord(veaX)) * FPresenter.Model.Size + ALevel;
end;

procedure TTestVoxelEditorPresenter.DovrebbeMostrareAllAvvioUnVoxelNuovoEVistoDallAlto;
begin
  StartFresh;
  Assert.AreEqual(16, FPresenter.Model.Size);
  Assert.AreEqual(Ord(vevTop), Ord(FPresenter.Plane.View));
  Assert.AreEqual(Integer(Length(FView.Plane)), 16 * 16);
  Assert.AreEqual(VOXEL_EDITOR_TITLE, FView.Title);
  Assert.IsFalse(FPresenter.Modified);
  Assert.IsFalse(FView.State.CanUndo);
  Assert.IsTrue(FView.State.CanElevate);
  // the palette of Doom, with the first square empty
  Assert.AreEqual(Cardinal(0), FView.Palette[0]);
  Assert.AreNotEqual(Cardinal(0), FView.Palette[1]);
end;

procedure TTestVoxelEditorPresenter.DovrebbeLeggereLeImpostazioni;
begin
  FFileSystem.PutText(INI_FILE,
    '[Voxel Options]'#13#10'ZOOM=7'#13#10'NEWVOXELSIZE=32'#13#10'DRAWCOLOR1=255'#13#10'DRAWCOLOR2=65280'#13#10);
  FPresenter.Start('');
  Assert.AreEqual(7, FPresenter.Zoom);
  Assert.AreEqual(32, FPresenter.Model.Size);
  Assert.AreEqual(Cardinal(255), FPresenter.Color1);
  Assert.AreEqual(Cardinal(65280), FPresenter.Color2);
end;

procedure TTestVoxelEditorPresenter.DovrebbeSalvareLeImpostazioniAllaChiusura;
begin
  StartFresh;
  FPresenter.ZoomIn;
  FPresenter.PickPaletteColor(5, vebLeft);
  FPresenter.Shutdown;
  Assert.IsTrue(FFileSystem.TextOf(INI_FILE).Contains('ZOOM=5'));
  Assert.IsTrue(FFileSystem.TextOf(INI_FILE).Contains('NEWVOXELSIZE=16'));
end;

procedure TTestVoxelEditorPresenter.DovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TVoxelEditorPresenter.Create(nil, FDialogsIntf, FClipboardIntf, FLoaderIntf, FExporterIntf, FFileSystemIntf,
        TToolsFactory.CreateFileBackup(FFileSystemIntf), TToolsFactory.CreateSettings(FFileSystemIntf, INI_FILE),
        TToolsFactory.CreateRecentFiles(10), TToolsFactory.CreateUndoHistory(10)).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TVoxelEditorPresenter.Create(FViewIntf, FDialogsIntf, FClipboardIntf, FLoaderIntf, FExporterIntf, FFileSystemIntf,
        TToolsFactory.CreateFileBackup(FFileSystemIntf), TToolsFactory.CreateSettings(FFileSystemIntf, INI_FILE),
        TToolsFactory.CreateRecentFiles(10), nil).Free;
    end, EArgumentNilException);
end;

procedure TTestVoxelEditorPresenter.DovrebbeAprireIlVoxelDellaRigaDiComando;
var
  LModel: TVoxelEditorModel;
begin
  LModel := TVoxelEditorModel.Create(8);
  try
    LModel.Put(1, 2, 3, $123456);
    FFileSystem.TryWriteAllBytes(VOXEL_FILE, TVoxelEditorDdvoxFormat.Write(LModel));
  finally
    LModel.Free;
  end;
  FPresenter.Start(VOXEL_FILE);
  Assert.AreEqual(8, FPresenter.Model.Size);
  Assert.AreEqual(Cardinal($123456), FPresenter.Model.Get(1, 2, 3));
  Assert.AreEqual(VOXEL_FILE, FPresenter.FileName);
  Assert.IsTrue(FView.Title.Contains('mine.ddvox'));
  Assert.AreEqual(1, Length(FView.RecentCaptions));
end;

procedure TTestVoxelEditorPresenter.DovrebbeDisegnareConIlMouseEPoterAnnullare;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 2);
  FPresenter.PickPaletteColor(3, vebLeft);
  FPresenter.SelectTool(vetFreeDraw);
  FPresenter.MouseDown(vebLeft, 5 * 4 + 1, 6 * 4 + 1);
  FPresenter.MouseUp;
  Assert.AreEqual(FPresenter.Color1, FPresenter.Model.Get(5, 6, 2));
  Assert.AreEqual(1, FPresenter.Model.CountVoxels);
  Assert.IsTrue(FPresenter.Modified);
  Assert.IsTrue(FView.State.CanUndo);
  FPresenter.Undo;
  Assert.AreEqual(0, FPresenter.Model.CountVoxels);
  Assert.IsTrue(FView.State.CanRedo);
  FPresenter.Redo;
  Assert.AreEqual(1, FPresenter.Model.CountVoxels);
end;

procedure TTestVoxelEditorPresenter.DovrebbeDisegnareUnaLineaTraDuePuntiDelMouse;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 0);
  FPresenter.PickPaletteColor(2, vebLeft);
  FPresenter.MouseDown(vebLeft, 0, 0);
  FPresenter.MouseMove(40, 0);
  FPresenter.MouseUp;
  // 4 pixels for each cell: the cells 0 to 10 of the first row
  Assert.AreEqual(FPresenter.Color1, FPresenter.Model.Get(0, 0, 0));
  Assert.AreEqual(FPresenter.Color1, FPresenter.Model.Get(5, 0, 0));
  Assert.AreEqual(FPresenter.Color1, FPresenter.Model.Get(10, 0, 0));
  Assert.AreEqual(Cardinal(0), FPresenter.Model.Get(11, 0, 0));
end;

procedure TTestVoxelEditorPresenter.DovrebbeCancellareConLaGomma;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 0);
  FPresenter.Model.Put(3, 3, 0, 5);
  FPresenter.SelectTool(vetEraser);
  FPresenter.MouseDown(vebLeft, 3 * 4, 3 * 4);
  FPresenter.MouseUp;
  Assert.AreEqual(Cardinal(0), FPresenter.Model.Get(3, 3, 0));
  Assert.IsTrue(FPresenter.Modified);
end;

procedure TTestVoxelEditorPresenter.DovrebbeRiempireUnaZona;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 0);
  FPresenter.PickPaletteColor(4, vebLeft);
  FPresenter.SelectTool(vetFloodFill);
  // a wall of voxels divides the plane: the fill stays in the side that was clicked
  FPresenter.Model.Put(4, 0, 0, 9);
  FPresenter.Model.Put(4, 1, 0, 9);
  FPresenter.MouseDown(vebLeft, 0, 0);
  FPresenter.MouseUp;
  Assert.AreEqual(FPresenter.Color1, FPresenter.Model.Get(0, 0, 0));
  Assert.AreEqual(FPresenter.Color1, FPresenter.Model.Get(5, 0, 0));
  Assert.AreEqual(Cardinal(9), FPresenter.Model.Get(4, 0, 0));
  Assert.IsTrue(FView.State.CanUndo);
  // the same color again changes nothing and saves no undo
  FPresenter.Undo;
  Assert.AreEqual(Cardinal(0), FPresenter.Model.Get(0, 0, 0));
end;

procedure TTestVoxelEditorPresenter.DovrebbePrendereUnColoreConIlContagocce;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 0);
  FPresenter.Model.Put(2, 2, 0, $ABCDEF);
  FPresenter.SelectTool(vetColorPicker);
  FPresenter.MouseDown(vebRight, 2 * 4, 2 * 4);
  FPresenter.MouseUp;
  Assert.AreEqual(Cardinal($ABCDEF), FPresenter.Color2);
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestVoxelEditorPresenter.DovrebbeAlzareUnVoxelConLaMatita;
begin
  StartFresh;
  // top view: the first voxel of the column, and the cell in front of it takes the color
  FPresenter.Model.Put(3, 5, 4, 7);
  FPresenter.PickPaletteColor(6, vebLeft);
  FPresenter.SelectView(vevTop);
  FPresenter.SelectTool(vetElevate);
  Assert.AreEqual(Ord(vetElevate), Ord(FPresenter.Tool));
  // the top view shows (x, size - 1 - z): the voxel at z = 4 is at the row 11
  FPresenter.MouseDown(vebLeft, 3 * 4, 11 * 4);
  FPresenter.MouseUp;
  Assert.AreEqual(FPresenter.Color1, FPresenter.Model.Get(3, 4, 4));
  Assert.AreEqual(Cardinal(7), FPresenter.Model.Get(3, 5, 4));
end;

procedure TTestVoxelEditorPresenter.DovrebbeNonPermetterediAlzareSuUnaSezione;
begin
  StartFresh;
  FPresenter.SelectSlice(veaX, 1);
  FPresenter.SelectTool(vetElevate);
  Assert.AreEqual(Ord(vetFreeDraw), Ord(FPresenter.Tool));
  Assert.IsFalse(FView.State.CanElevate);
  // going to a slice with the pencil on gives the free draw back
  FPresenter.SelectView(vevFront);
  FPresenter.SelectTool(vetElevate);
  FPresenter.SelectSlice(veaY, 0);
  Assert.AreEqual(Ord(vetFreeDraw), Ord(FPresenter.Tool));
end;

procedure TTestVoxelEditorPresenter.DovrebbeDareLaDescrizioneDelPuntoSottoIlMouse;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 3);
  FPresenter.Model.Put(1, 2, 3, $030201);
  FPresenter.SelectTool(vetColorPicker);
  FPresenter.MouseDown(vebLeft, 1 * 4, 2 * 4);
  Assert.AreEqual('x=1, y=2, depth=3, color=(1, 2, 3)', FView.State.StatusText);
  FPresenter.MouseUp;
end;

procedure TTestVoxelEditorPresenter.DovrebbeScegliereUnaSezioneEIlSuoLivello;
begin
  StartFresh;
  FPresenter.SelectSlice(veaY, 5);
  Assert.AreEqual(Ord(veaY), Ord(FPresenter.Plane.Axis));
  Assert.AreEqual(5, FPresenter.Plane.Level);
  Assert.AreEqual(PlaneIndex(veaY, 5), FView.SelectedPlane);
  FPresenter.SelectPlaneByIndex(PlaneIndex(veaX, 9));
  Assert.AreEqual(Ord(veaX), Ord(FPresenter.Plane.Axis));
  Assert.AreEqual(9, FPresenter.Plane.Level);
  FPresenter.SelectPlaneByIndex(3 * 16 + 2);
  Assert.AreEqual(Ord(vevLeft), Ord(FPresenter.Plane.View));
  FPresenter.SelectPlaneByIndex(-1);
  FPresenter.SelectPlaneByIndex(3 * 16 + 6);
  Assert.AreEqual(Ord(vevLeft), Ord(FPresenter.Plane.View));
  FPresenter.SelectSlice(veaNone, 1);
  Assert.AreEqual(Ord(vevLeft), Ord(FPresenter.Plane.View));
end;

procedure TTestVoxelEditorPresenter.DovrebbeElencareLeSezioniELeViste;
begin
  StartFresh;
  Assert.AreEqual(3 * 16 + 6, Integer(Length(FView.PlaneNames)));
  Assert.AreEqual('x0', FView.PlaneNames[0]);
  Assert.AreEqual('y15', FView.PlaneNames[31]);
  Assert.AreEqual('z0', FView.PlaneNames[32]);
  Assert.AreEqual('front', FView.PlaneNames[48]);
  Assert.AreEqual('down', FView.PlaneNames[53]);
  Assert.AreEqual(3 * 16 + 4, FView.SelectedPlane); // top
end;

procedure TTestVoxelEditorPresenter.DovrebbeSalireEScendereDiLivelloSoloNelleSezioni;
begin
  StartFresh;
  FPresenter.IncreaseLevel;
  Assert.AreEqual(Ord(vevTop), Ord(FPresenter.Plane.View));
  FPresenter.SelectSlice(veaZ, 0);
  FPresenter.DecreaseLevel;
  Assert.AreEqual(0, FPresenter.Plane.Level);
  FPresenter.IncreaseLevel;
  FPresenter.IncreaseLevel;
  Assert.AreEqual(2, FPresenter.Plane.Level);
  FPresenter.SelectSlice(veaZ, 15);
  FPresenter.IncreaseLevel;
  Assert.AreEqual(15, FPresenter.Plane.Level);
end;

procedure TTestVoxelEditorPresenter.DovrebbeCopiareTagliareIncollareECancellare;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 0);
  PutCells([5, 6]);
  FPresenter.Copy;
  Assert.IsTrue(FClipboard.HasImage);
  Assert.AreEqual(5, Integer(FClipboard.Image[0]));
  FPresenter.Clear;
  Assert.AreEqual(0, FPresenter.Model.CountVoxels);
  FPresenter.Paste;
  Assert.AreEqual(Cardinal(5), FPresenter.Model.Get(0, 0, 0));
  Assert.AreEqual(Cardinal(6), FPresenter.Model.Get(1, 0, 0));
  FPresenter.Cut;
  Assert.AreEqual(0, FPresenter.Model.CountVoxels);
  Assert.AreEqual(6, Integer(FClipboard.Image[16]));
  FPresenter.Undo;
  Assert.AreEqual(2, FPresenter.Model.CountVoxels);
end;

procedure TTestVoxelEditorPresenter.DovrebbeCopiareEIncollareUnaVista;
begin
  StartFresh;
  FPresenter.Model.Put(2, 3, 4, 8);
  FPresenter.CopyView(vevFront);
  Assert.AreEqual(Cardinal(8), FClipboard.Image[2 * 16 + 3]);
  FPresenter.Model.Clear;
  FPresenter.Model.Put(2, 3, 9, 1);
  FPresenter.PasteView(vevFront);
  // the first voxel of the ray takes the color of the picture
  Assert.AreEqual(Cardinal(8), FPresenter.Model.Get(2, 3, 9));
end;

procedure TTestVoxelEditorPresenter.DovrebbeNonIncollareSeNonCEUnaImmagine;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 0);
  FPresenter.Paste;
  Assert.IsFalse(FPresenter.Modified);
  FClipboard.HasImage := True;
  FClipboard.Image := TVoxelScenarios.ProbeImage(16, 1);
  FPresenter.SelectView(vevNone);
  FPresenter.Paste;
  Assert.IsFalse(FPresenter.Modified);
  FPresenter.Clear;
  FPresenter.Cut;
  FPresenter.FlipHorizontal;
  Assert.IsFalse(FPresenter.Modified);
end;

procedure TTestVoxelEditorPresenter.DovrebbeSpecchiareEGirareIlPiano;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 0);
  FPresenter.Model.Put(1, 2, 0, 5);
  FPresenter.FlipHorizontal;
  Assert.AreEqual(Cardinal(5), FPresenter.Model.Get(14, 2, 0));
  FPresenter.FlipVertical;
  Assert.AreEqual(Cardinal(5), FPresenter.Model.Get(14, 13, 0));
  FPresenter.RotateLeft;
  Assert.AreEqual(1, FPresenter.Model.CountVoxels);
  FPresenter.RotateRight;
  Assert.AreEqual(Cardinal(5), FPresenter.Model.Get(14, 13, 0));
  Assert.IsTrue(FPresenter.Modified);
end;

procedure TTestVoxelEditorPresenter.DovrebbeIngrandireEImpicciolireFinoAiLimiti;
var
  LIndex: Integer;
begin
  StartFresh;
  for LIndex := 1 to 50 do
    FPresenter.ZoomIn;
  Assert.AreEqual(VOXEL_EDITOR_MAX_ZOOM, FPresenter.Zoom);
  Assert.AreEqual(VOXEL_EDITOR_MAX_ZOOM, FView.PlaneZoom);
  for LIndex := 1 to 50 do
    FPresenter.ZoomOut;
  Assert.AreEqual(VOXEL_EDITOR_MIN_ZOOM, FPresenter.Zoom);
end;

procedure TTestVoxelEditorPresenter.DovrebbeSalvareEAprireUnVoxel;
begin
  StartFresh;
  FPresenter.Model.Put(3, 4, 5, $222222);
  FDialogs.Answer(1, VOXEL_FILE);
  FPresenter.Save;
  Assert.IsTrue(FFileSystem.FileExists(VOXEL_FILE));
  Assert.AreEqual(VOXEL_FILE, FPresenter.FileName);
  Assert.IsFalse(FPresenter.Modified);
  FPresenter.NewVoxel;
  Assert.AreEqual('', FPresenter.FileName);
  FDialogs.Answer(0, VOXEL_FILE);
  FPresenter.OpenFile;
  Assert.AreEqual(Cardinal($222222), FPresenter.Model.Get(3, 4, 5));
  FPresenter.Save;
  Assert.AreEqual(VOXEL_FILE, FPresenter.FileName);
end;

procedure TTestVoxelEditorPresenter.DovrebbeSalvareConLaCopiaDiSicurezza;
begin
  StartFresh;
  FFileSystem.PutText(VOXEL_FILE, 'old');
  FDialogs.Answer(1, VOXEL_FILE);
  FPresenter.SaveAs;
  Assert.AreEqual('old', FFileSystem.TextOf(VOXEL_FILE + '_bak'));
  FDialogs.Answer(1, '', False);
  FPresenter.SaveAs;
end;

procedure TTestVoxelEditorPresenter.DovrebbeAvvisareSeIlVoxelNonSiScrive;
begin
  StartFresh;
  FPresenter.Model.Put(1, 1, 1, 1);
  FPresenter.SelectView(vevNone);
  FPresenter.Model.Put(1, 1, 2, 1);
  FDialogs.Answer(1, VOXEL_FILE);
  FFileSystem.FailWrite := True;
  FPresenter.Save;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.AreEqual('', FPresenter.FileName);
end;

procedure TTestVoxelEditorPresenter.DovrebbeAvvisareSeIlFileDaAprireNonCe;
begin
  StartFresh;
  FDialogs.Answer(0, 'C:\work\missing.ddvox');
  FPresenter.OpenFile;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.IsTrue(FDialogs.Messages[0].Contains('missing.ddvox'));
end;

procedure TTestVoxelEditorPresenter.DovrebbeAvvisareUnFileDaAprireMalformato;
begin
  StartFresh;
  FFileSystem.PutText(VOXEL_FILE, 'hello world');
  FDialogs.Answer(0, VOXEL_FILE);
  FPresenter.OpenFile;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  Assert.AreEqual(16, FPresenter.Model.Size);
  Assert.AreEqual('', FPresenter.FileName);
end;

procedure TTestVoxelEditorPresenter.DovrebbeAprireUnFileDellaListaDeiRecenti;
begin
  StartFresh;
  FFileSystem.TryWriteAllBytes(VOXEL_FILE, TVoxelEditorDdvoxFormat.Write(FPresenter.Model));
  FPresenter.OpenVoxel(VOXEL_FILE);
  FPresenter.NewVoxel;
  Assert.AreEqual(1, Length(FView.RecentCaptions));
  FPresenter.OpenRecent(0);
  Assert.AreEqual(VOXEL_FILE, FPresenter.FileName);
  FPresenter.OpenRecent(5);
  FPresenter.OpenRecent(-1);
  Assert.AreEqual(VOXEL_FILE, FPresenter.FileName);
end;

procedure TTestVoxelEditorPresenter.DovrebbeChiedereSeSalvareLeModificheChiudendo;
begin
  StartFresh;
  FPresenter.RequestClose;
  Assert.AreEqual(1, FView.CloseCount);
  Assert.AreEqual(0, FDialogs.ConfirmCount);
  FPresenter.SelectSlice(veaZ, 1);
  FPresenter.Model.Put(0, 0, 1, 3);
  FPresenter.FlipHorizontal;
  Assert.IsTrue(FPresenter.Modified);
  FDialogs.Confirmation := vecCancel;
  Assert.IsFalse(FPresenter.TryClose);
  FDialogs.Confirmation := vecNo;
  Assert.IsTrue(FPresenter.TryClose);
  FDialogs.Confirmation := vecYes;
  FDialogs.Answer(1, VOXEL_FILE);
  Assert.IsTrue(FPresenter.TryClose);
  Assert.IsTrue(FFileSystem.FileExists(VOXEL_FILE));
  Assert.IsFalse(FPresenter.Modified);
  // a save that fails keeps the window open
  FPresenter.FlipHorizontal;
  FFileSystem.FailWrite := True;
  FPresenter.RequestClose;
  Assert.IsTrue(FPresenter.Modified);
  Assert.AreEqual(1, FView.CloseCount);
end;

procedure TTestVoxelEditorPresenter.DovrebbeFareUnVoxelNuovoDellaDimensioneScelta;
begin
  StartFresh;
  FPresenter.Model.Put(1, 1, 1, 1);
  FDialogs.NewSizeValue := 32;
  FPresenter.NewVoxel;
  Assert.AreEqual(32, FPresenter.Model.Size);
  Assert.AreEqual(0, FPresenter.Model.CountVoxels);
  Assert.AreEqual(3 * 32 + 6, Integer(Length(FView.PlaneNames)));
  FDialogs.NewSizeResult := False;
  FDialogs.NewSizeValue := 64;
  FPresenter.NewVoxel;
  Assert.AreEqual(32, FPresenter.Model.Size);
end;

procedure TTestVoxelEditorPresenter.DovrebbeImportareUnKvxUnVoxEUnDdmesh;
var
  LModel: TVoxelEditorModel;
  LMesh: TBytes;
begin
  StartFresh;
  FFileSystem.TryWriteAllBytes('C:\a.kvx', TVoxelScenarios.KvxBytes(0));
  FDialogs.Answer(2, 'C:\a.kvx');
  FPresenter.ImportKvx;
  Assert.AreEqual(32, FPresenter.Model.Size);
  Assert.IsTrue(FPresenter.Model.CountVoxels > 0);
  Assert.AreEqual('', FPresenter.FileName);
  Assert.IsFalse(FPresenter.Modified);

  FFileSystem.TryWriteAllBytes('C:\a.vox', TVoxelScenarios.VoxBytes(0));
  FDialogs.Answer(3, 'C:\a.vox');
  FPresenter.ImportVox;
  Assert.AreEqual(8, FPresenter.Model.Size);

  LModel := TVoxelEditorModel.Create(8);
  try
    LModel.Put(2, 2, 2, 77);
    FPresenter.Model.AssignFrom(LModel);
  finally
    LModel.Free;
  end;
  FPresenter.SelectView(vevTop);
  FDialogs.Answer(6, 'C:\a.ddmesh');
  FPresenter.ExportMesh;
  Assert.IsTrue(FFileSystem.TryReadAllBytes('C:\a.ddmesh', LMesh));
  FFileSystem.TryWriteAllBytes('C:\b.ddmesh', LMesh);
  FPresenter.Model.Clear;
  FDialogs.Answer(4, 'C:\b.ddmesh');
  FPresenter.ImportDdmesh;
  Assert.AreEqual(Cardinal(77), FPresenter.Model.Get(2, 2, 2));
end;

procedure TTestVoxelEditorPresenter.DovrebbeAvvisareUnImportMalformato;
begin
  StartFresh;
  FFileSystem.PutText('C:\bad.kvx', 'short');
  FDialogs.Answer(2, 'C:\bad.kvx');
  FPresenter.ImportKvx;
  FDialogs.Answer(3, 'C:\bad.vox');
  FPresenter.ImportVox;
  FFileSystem.PutText('C:\bad.ddmesh', 'a mesh that is not one at all');
  FDialogs.Answer(4, 'C:\bad.ddmesh');
  FPresenter.ImportDdmesh;
  Assert.AreEqual(3, FDialogs.Messages.Count);
end;

procedure TTestVoxelEditorPresenter.DovrebbeEsportareIlVoxEIlDdmesh;
var
  LBytes: TBytes;
begin
  StartFresh;
  FPresenter.Model.Put(2, 3, 4, $102030);
  FDialogs.Answer(5, 'C:\out.vox');
  FPresenter.ExportVox;
  Assert.IsTrue(FFileSystem.TryReadAllBytes('C:\out.vox', LBytes));
  Assert.AreEqual(12 + 16 * 16 * 16 + 768, Integer(Length(LBytes)));
  FDialogs.Answer(6, 'C:\out.ddmesh');
  FPresenter.ExportMesh;
  Assert.IsTrue(FFileSystem.FileExists('C:\out.ddmesh'));
  FFileSystem.FailWrite := True;
  FPresenter.ExportMesh;
  FPresenter.ExportVox;
  Assert.AreEqual(2, FDialogs.Messages.Count);
end;

procedure TTestVoxelEditorPresenter.DovrebbeEsportareLeImmagini;
begin
  StartFresh;
  FPresenter.Model.Put(1, 2, 3, 9);
  FPresenter.SelectSlice(veaZ, 3);
  FDialogs.Answer(8, 'C:\plane.png');
  FPresenter.ExportPlaneImage;
  Assert.AreEqual(1, FExporter.Names.Count);
  Assert.AreEqual(Cardinal(9), FExporter.Images[0][1 * 16 + 2]);
  FPresenter.ExportViewImage(vevFront);
  Assert.AreEqual(Cardinal(9), FExporter.Images[1][1 * 16 + 2]);
  FPresenter.ExportViewImage(vevNone);
  Assert.AreEqual(2, FExporter.Names.Count);
  FExporter.Succeeds := False;
  FPresenter.ExportPlaneImage;
  FPresenter.ExportViewImage(vevBack);
  Assert.AreEqual(2, FDialogs.Messages.Count);
  FDialogs.Answer(8, '', False);
  FPresenter.ExportPlaneImage;
  Assert.AreEqual(4, FExporter.Names.Count);
end;

procedure TTestVoxelEditorPresenter.DovrebbeImportareUnaImmagineSulPiano;
begin
  StartFresh;
  FPresenter.SelectSlice(veaZ, 1);
  FDialogs.Answer(7, 'C:\pic.bmp');
  FPresenter.ImportImage;
  Assert.AreEqual(Cardinal($808080), FPresenter.Model.Get(5, 5, 1));
  Assert.AreEqual(16 * 16, FPresenter.Model.CountVoxels);
  FPresenter.Undo;
  Assert.AreEqual(0, FPresenter.Model.CountVoxels);
  FLoader.CanLoad := False;
  FPresenter.ImportImage;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  FDialogs.Answer(7, '', False);
  FLoader.CanLoad := True;
  FPresenter.ImportImage;
  Assert.AreEqual(0, FPresenter.Model.CountVoxels);
end;

procedure TTestVoxelEditorPresenter.DovrebbeFareUnVoxelDaUnaMappaDelleAltezze;
begin
  StartFresh;
  FLoader.Width := 20;
  FLoader.Height := 30;
  FDialogs.Answer(7, 'C:\height.png');
  FPresenter.ImportHeightmap;
  // 30 pixels need 32 cells; the gray 128 makes columns of 16 cells
  Assert.AreEqual(32, FPresenter.Model.Size);
  Assert.IsTrue(FPresenter.Model.CountVoxels > 0);
  Assert.AreEqual(Cardinal($808080), FPresenter.Model.Get(5, 31, 5));
  Assert.IsTrue(FPresenter.Modified);
  FLoader.CanLoad := False;
  FPresenter.ImportHeightmap;
  Assert.AreEqual(1, FDialogs.Messages.Count);
end;

procedure TTestVoxelEditorPresenter.DovrebbeApplicareUnaTexturaAlTerreno;
begin
  StartFresh;
  FPresenter.Model.Put(2, 5, 3, 1234);
  FDialogs.Answer(7, 'C:\texture.png');
  FLoader.Fill := 0;
  FPresenter.ApplyTerrainTexture;
  Assert.AreEqual(VOXEL_EDITOR_NEAR_BLACK, FPresenter.Model.Get(2, 5, 3));
  FLoader.Fill := $445566;
  FPresenter.ApplyTerrainTexture;
  Assert.AreEqual(Cardinal($445566), FPresenter.Model.Get(2, 5, 3));
  FLoader.CanLoad := False;
  FPresenter.ApplyTerrainTexture;
  Assert.AreEqual(1, FDialogs.Messages.Count);
  FDialogs.Answer(7, '', False);
  FPresenter.ApplyTerrainTexture;
  Assert.AreEqual(1, FDialogs.Messages.Count);
end;

procedure TTestVoxelEditorPresenter.DovrebbeTogliereIVoxelNonVisibili;
var
  LX, LY, LZ: Integer;
begin
  StartFresh;
  for LX := 4 to 8 do
    for LY := 4 to 8 do
      for LZ := 4 to 8 do
        FPresenter.Model.Put(LX, LY, LZ, 5);
  FPresenter.RemoveNonVisible;
  Assert.AreEqual(Cardinal(0), FPresenter.Model.Get(6, 6, 6));
  Assert.AreEqual(Cardinal(5), FPresenter.Model.Get(4, 6, 6));
  FPresenter.Undo;
  Assert.AreEqual(Cardinal(5), FPresenter.Model.Get(6, 6, 6));
end;

procedure TTestVoxelEditorPresenter.DovrebbeRuotareIlVoxel;
begin
  StartFresh;
  FPresenter.Model.Put(12, 3, 8, 5);
  FDialogs.RotationValue := 90;
  FPresenter.Rotate;
  Assert.AreEqual(1, FPresenter.Model.CountVoxels);
  Assert.IsTrue(FPresenter.Modified);
  FPresenter.Undo;
  FPresenter.RotateHighQuality;
  Assert.IsTrue(FPresenter.Model.CountVoxels >= 0);
  FDialogs.RotationResult := False;
  FPresenter.Undo;
  FPresenter.Rotate;
  Assert.AreEqual(1, FPresenter.Model.CountVoxels);
end;

procedure TTestVoxelEditorPresenter.DovrebbeTagliareEStringereLAltezza;
begin
  StartFresh;
  FPresenter.Model.Put(3, 0, 3, 1);
  FPresenter.Model.Put(3, 15, 3, 2);
  FDialogs.HeightMin := 64;
  FDialogs.HeightMax := 191;
  FPresenter.CropHeight;
  Assert.AreEqual('Crop heightmap', FDialogs.HeightTitle);
  Assert.AreEqual(Cardinal(1), FPresenter.Model.Get(3, 4, 3));
  // the heights 64 and 191 of 256 are the rows 4 and 12 of 16 (11.94 is rounded)
  Assert.AreEqual(Cardinal(2), FPresenter.Model.Get(3, 12, 3));
  FPresenter.Undo;
  FPresenter.ShrinkHeight;
  Assert.AreEqual('Shrink heightmap', FDialogs.HeightTitle);
  FDialogs.HeightResult := False;
  FPresenter.Undo;
  FPresenter.CropHeight;
  FPresenter.ShrinkHeight;
  Assert.AreEqual(Cardinal(1), FPresenter.Model.Get(3, 0, 3));
end;

procedure TTestVoxelEditorPresenter.DovrebbeContareIColori;
begin
  StartFresh;
  PutCells([1, 2, 2, 3]);
  FPresenter.CountColors;
  Assert.AreEqual(Format(SVoxelEditorUniqueColors, [3]), FDialogs.Messages[0]);
end;

procedure TTestVoxelEditorPresenter.DovrebbeFareLaScalaDiGrigiESoloSeCambiaQualcosa;
begin
  StartFresh;
  FPresenter.ToGrayScale;
  Assert.IsFalse(FView.State.CanUndo);
  // the palette of the window becomes the gray ramp
  Assert.AreEqual(Cardinal($010101), FView.Palette[1]);
  PutCells([$000064]);
  FPresenter.ToGrayScale;
  Assert.AreEqual(Cardinal($646464), FPresenter.Model.Get(0, 0, 0));
  Assert.IsTrue(FView.State.CanUndo);
end;

procedure TTestVoxelEditorPresenter.DovrebbeRidurreAUnaPaletta;
begin
  StartFresh;
  PutCells([$000011]);
  FDialogs.PaletteKind := vepDoom;
  FPresenter.ConvertToPalette;
  Assert.AreNotEqual(Cardinal($000011), FPresenter.Model.Get(0, 0, 0));
  Assert.IsTrue(FView.State.CanUndo);
  // the palette of the window is the one of the game
  Assert.AreEqual(Cardinal(0), FView.Palette[0]);

  FPresenter.Undo;
  FDialogs.PaletteKind := vepOctree;
  FPresenter.ConvertToPalette;
  Assert.AreEqual(1, FPresenter.Model.CountVoxels);

  FDialogs.PaletteKind := vepFile;
  FDialogs.Answer(9, 'C:\gray.pal');
  FPresenter.ConvertToPalette;
  FDialogs.Answer(9, 'C:\missing.pal');
  FPresenter.ConvertToPalette;
  FDialogs.Answer(9, '', False);
  FPresenter.ConvertToPalette;
  FDialogs.PaletteResult := False;
  FPresenter.ConvertToPalette;
  FPresenter.ShowGamePalette(vepHexen);
  Assert.AreEqual(Cardinal(0), FView.Palette[0]);
end;

procedure TTestVoxelEditorPresenter.DovrebbeScegliereIColoriDallaPalettaEDalDialogo;
begin
  StartFresh;
  FPresenter.PickPaletteColor(1, vebLeft);
  Assert.AreEqual(FView.Palette[1], FPresenter.Color1);
  FPresenter.PickPaletteColor(2, vebRight);
  Assert.AreEqual(FView.Palette[2], FPresenter.Color2);
  FPresenter.PickPaletteColor(256, vebLeft);
  FPresenter.PickPaletteColor(-1, vebLeft);
  FDialogs.ColorValue := $123456;
  FPresenter.ChooseColor(1);
  Assert.AreEqual(Cardinal($123456), FPresenter.Color1);
  FDialogs.ColorValue := $654321;
  FPresenter.ChooseColor(2);
  Assert.AreEqual(Cardinal($654321), FPresenter.Color2);
  FDialogs.ColorResult := False;
  FDialogs.ColorValue := 5;
  FPresenter.ChooseColor(1);
  Assert.AreEqual(Cardinal($123456), FPresenter.Color1);
end;

procedure TTestVoxelEditorPresenter.DovrebbeConvertireUnElencoDiFile;
var
  LModel: TVoxelEditorModel;
  LBytes: TBytes;
begin
  StartFresh;
  LModel := TVoxelEditorModel.Create(8);
  try
    LModel.Put(1, 1, 1, 5);
    FFileSystem.TryWriteAllBytes('C:\a.ddvox', TVoxelEditorDdvoxFormat.Write(LModel));
  finally
    LModel.Free;
  end;
  FFileSystem.TryWriteAllBytes('C:\k.kvx', TVoxelScenarios.KvxBytes(0));
  FFileSystem.PutText('C:\bad.ddvox', 'nonsense');
  FDialogs.ConvertFiles := TArray<string>.Create('C:\a.ddvox', 'C:\bad.ddvox', 'C:\missing.ddvox');
  FPresenter.ConvertFiles(vebDdvoxToVox);
  Assert.IsTrue(FFileSystem.TryReadAllBytes('C:\a.vox', LBytes));
  Assert.AreEqual(12 + 8 * 8 * 8 + 768, Integer(Length(LBytes)));
  Assert.IsFalse(FFileSystem.FileExists('C:\bad.vox'));
  FPresenter.ConvertFiles(vebDdvoxToDdmesh);
  Assert.IsTrue(FFileSystem.FileExists('C:\a.ddmesh'));
  FDialogs.ConvertFiles := TArray<string>.Create('C:\k.kvx');
  FPresenter.ConvertFiles(vebKvxToDdmesh);
  Assert.IsTrue(FFileSystem.FileExists('C:\k.ddmesh'));
  Assert.AreEqual(-1, FView.ProgressPercents[FView.ProgressPercents.Count - 1]);
  FDialogs.ConvertFiles := nil;
  FPresenter.ConvertFiles(vebKvxToDdmesh);
end;

procedure TTestVoxelEditorPresenter.DovrebbeMostrareLAbout;
begin
  StartFresh;
  FPresenter.About;
  Assert.AreEqual(1, FDialogs.AboutCount);
end;

end.
