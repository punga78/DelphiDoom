{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeMainPresenter                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.MainPresenter;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.MessageLog,
  DelphiDoom.Ide.Pk3Builder,
  DelphiDoom.Ide.MainPresenter,
  DelphiDoom.Ide.Views.Intf,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeClock,
  DelphiDoom.Tests.Ide.FakeArchive,
  DelphiDoom.Tests.Ide.FakeGameLibrary,
  DelphiDoom.Tests.Ide.FakeUi;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeMainPresenter = class(TObject)
  strict private
    FFileSystem: TFakeIdeFileSystem;
    FFileSystemIntf: IIdeFileSystem;
    FLog: TIdeMessageLog;
    FLogIntf: IIdeLog;
    FClockIntf: IIdeClock;
    FMessages: TFakeIdeMessageDialogs;
    FMessagesIntf: IIdeMessageDialogs;
    FFiles: TFakeIdeFileDialogs;
    FFilesIntf: IIdeFileDialogs;
    FBusy: TFakeIdeBusy;
    FBusyIntf: IIdeBusy;
    FClipboard: TFakeIdeClipboard;
    FClipboardIntf: IIdeClipboard;
    FLibrary: TFakeIdeGameLibrary;
    FLibraryIntf: IIdeGameLibrary;
    FArchive: TFakeIdeArchive;
    FArchiveIntf: IIdeArchive;
    FView: TFakeIdeMainView;
    FViewIntf: IIdeMainView;
    FBuilder: TIdePk3Builder;
    FPresenter: TIdeMainPresenter;
    procedure WriteProject(const AName, AText: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeIniziareConUnProgettoNuovoPerDoom;
    [Test]
    procedure DovrebbeAprireIlProgettoDellaRigaDiComandoConIlSuoGioco;
    [Test]
    procedure DovrebbeCaricareLaLibreriaDelGiocoEPoiRilasciarla;
    [Test]
    procedure DovrebbeRilasciareLaLibreriaAncheSeIPannelliFalliscono;
    [Test]
    procedure DovrebbeScrivereTitoloENomeDellaSchedaDelProgetto;
    [Test]
    procedure DovrebbeChiudereGliEditorQuandoSiApreUnAltroProgetto;
    [Test]
    procedure DovrebbeChiedereDiSalvareUnProgettoModificatoPrimaDelNuovo;
    [Test]
    procedure DovrebbeRestareSeLUtenteAnnulla;
    [Test]
    procedure DovrebbeSalvareSeLUtenteDiceSi;
    [Test]
    procedure DovrebbeScartareSeLUtenteDiceNo;
    [Test]
    procedure DovrebbeNonChiedereNullaSeIlProgettoNonECambiato;
    [Test]
    procedure DovrebbeChiedereIlNomeSeIlProgettoNonLoHa;
    [Test]
    procedure DovrebbeNonFareNullaSeLUtenteAnnullaIlSalvataggioConNome;
    [Test]
    procedure DovrebbeSalvareConNomeEAggiornareIlTitolo;
    [Test]
    procedure DovrebbeAggiungereIFileScelti;
    [Test]
    procedure DovrebbeNonAggiungereNullaSeLUtenteAnnulla;
    [Test]
    procedure DovrebbeAprireUnFileDelProgettoPerModificarlo;
    [Test]
    procedure DovrebbeNonAprireUnaRigaCheNonEUnFile;
    [Test]
    procedure DovrebbeTogliereUnFileEChiudereLaSuaScheda;
    [Test]
    procedure DovrebbeNonRinominareUnRamoDellAlbero;
    [Test]
    procedure DovrebbeRinominareUnFileSenzaSchedaEDareIlPercorsoDelProgetto;
    [Test]
    procedure DovrebbeLasciareIlTestoDatoSeCeLaSchedaAperta;
    [Test]
    procedure DovrebbeRipristinareIlNomeSeIlRinominareFallisce;
    [Test]
    procedure DovrebbeNonPoterFareIlPk3SenzaFile;
    [Test]
    procedure DovrebbeFareIlPk3NelFileScelto;
    [Test]
    procedure DovrebbeCopiareIlMessaggioSelezionatoNegliAppunti;
    [Test]
    procedure DovrebbeSalvareEPulireLaListaDeiMessaggi;
    [Test]
    procedure DovrebbeScrivereLaVersioneENelCopyrightNelleInformazioni;
    [Test]
    procedure DovrebbeDareEccezioneSeUnaDipendenzaENil;
  end;

implementation

const
  FOLDER = 'C:\prj\';
  TITLE = 'DelphiDOOM Script IDE';

{ TTestIdeMainPresenter }

procedure TTestIdeMainPresenter.Setup;
begin
  FFileSystem := TFakeIdeFileSystem.Create(FOLDER);
  FFileSystemIntf := FFileSystem;
  FLog := TIdeMessageLog.Create;
  FLogIntf := FLog;
  FClockIntf := TFakeIdeClock.Create;
  FMessages := TFakeIdeMessageDialogs.Create;
  FMessagesIntf := FMessages;
  FFiles := TFakeIdeFileDialogs.Create;
  FFilesIntf := FFiles;
  FBusy := TFakeIdeBusy.Create;
  FBusyIntf := FBusy;
  FClipboard := TFakeIdeClipboard.Create;
  FClipboardIntf := FClipboard;
  FLibrary := TFakeIdeGameLibrary.Create;
  FLibraryIntf := FLibrary;
  FArchive := TFakeIdeArchive.Create;
  FArchiveIntf := FArchive;
  FView := TFakeIdeMainView.Create;
  FViewIntf := FView;
  FBuilder := TIdePk3Builder.Create(
    function: IIdeArchive
    begin
      Result := FArchiveIntf;
    end, FLogIntf, FClockIntf);
  FPresenter := TIdeMainPresenter.Create(FViewIntf, FFileSystemIntf, FLog, FClockIntf, FMessagesIntf,
    FFilesIntf, FBusyIntf, FClipboardIntf, FLibraryIntf, FBuilder,
    function: string
    begin
      Result := '1.2.3';
    end, TITLE);
end;

procedure TTestIdeMainPresenter.TearDown;
begin
  FPresenter.Free;
  FBuilder.Free;
  FViewIntf := nil;
  FArchiveIntf := nil;
  FLibraryIntf := nil;
  FClipboardIntf := nil;
  FBusyIntf := nil;
  FFilesIntf := nil;
  FMessagesIntf := nil;
  FClockIntf := nil;
  FLogIntf := nil;
  FFileSystemIntf := nil;
end;

procedure TTestIdeMainPresenter.WriteProject(const AName, AText: string);
begin
  FFileSystem.AddFile(FOLDER + AName, AnsiString(AText));
end;

procedure TTestIdeMainPresenter.DovrebbeIniziareConUnProgettoNuovoPerDoom;
begin
  FPresenter.Start('');
  Assert.AreEqual('doom', FPresenter.Project.Game);
  Assert.AreEqual('', FPresenter.Project.FileName);
  Assert.IsTrue(FView.Calls.IndexOf('ShowProject doom') >= 0);
end;

procedure TTestIdeMainPresenter.DovrebbeAprireIlProgettoDellaRigaDiComandoConIlSuoGioco;
begin
  // regression: the old window opened a project and then set its game back to Doom, and a
  // single argument on the command line was ignored
  WriteProject('a.ddide', 'version|1.0'#13#10'game|heretic'#13#10'script|s.ddscript'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  Assert.AreEqual('heretic', FPresenter.Project.Game);
  Assert.AreEqual(1, FPresenter.Project.Count);
  Assert.IsTrue(FView.Calls.IndexOf('UpdateLibraryGame heretic') >= 0);
  Assert.AreEqual(-1, FView.Calls.IndexOf('UpdateLibraryGame doom'));
end;

procedure TTestIdeMainPresenter.DovrebbeCaricareLaLibreriaDelGiocoEPoiRilasciarla;
begin
  FPresenter.Start('');
  Assert.AreEqual(1, FLibrary.OpenedGames.Count);
  Assert.AreEqual('doom', FLibrary.OpenedGames[0]);
  Assert.AreEqual(1, FLibrary.CloseCount);
  Assert.AreEqual(0, FBusy.Depth);
  Assert.IsTrue(FBusy.Entered > 0);
end;

procedure TTestIdeMainPresenter.DovrebbeRilasciareLaLibreriaAncheSeIPannelliFalliscono;
begin
  FView.FailOnUpdateLibrary := True;
  Assert.WillRaise(
    procedure
    begin
      FPresenter.Start('');
    end, Exception);
  Assert.AreEqual(1, FLibrary.CloseCount);
  Assert.AreEqual(0, FBusy.Depth);
end;

procedure TTestIdeMainPresenter.DovrebbeScrivereTitoloENomeDellaSchedaDelProgetto;
begin
  FPresenter.Start('');
  Assert.IsTrue(FView.Calls.IndexOf('SetCaptions ' + TITLE + ' - Untitled | Untitled') >= 0);
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  Assert.IsTrue(FView.Calls.IndexOf('SetCaptions ' + TITLE + ' - a.ddide | a.ddide') >= 0);
end;

procedure TTestIdeMainPresenter.DovrebbeChiudereGliEditorQuandoSiApreUnAltroProgetto;
begin
  FPresenter.Start('');
  FView.Calls.Clear;
  FPresenter.NewProject;
  Assert.AreEqual('CloseAllEditors', FView.Calls[0]);
end;

procedure TTestIdeMainPresenter.DovrebbeChiedereDiSalvareUnProgettoModificatoPrimaDelNuovo;
begin
  FPresenter.Start('');
  FPresenter.Project.Add(FOLDER + 'x.ddscript', ikScript);
  FMessages.Answers.Enqueue(cfNo);
  FPresenter.NewProject;
  Assert.AreEqual(1, FMessages.Questions.Count);
  Assert.AreEqual('Do you want to save changes?', FMessages.Questions[0]);
  Assert.AreEqual(0, FPresenter.Project.Count);
end;

procedure TTestIdeMainPresenter.DovrebbeRestareSeLUtenteAnnulla;
begin
  FPresenter.Start('');
  FPresenter.Project.Add(FOLDER + 'x.ddscript', ikScript);
  FMessages.Answers.Enqueue(cfCancel);
  FPresenter.NewProject;
  Assert.AreEqual(1, FPresenter.Project.Count);
  Assert.IsFalse(FPresenter.CheckCanClose);
end;

procedure TTestIdeMainPresenter.DovrebbeSalvareSeLUtenteDiceSi;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  FPresenter.Project.Add(FOLDER + 'x.ddscript', ikScript);
  FMessages.Answers.Enqueue(cfYes);
  Assert.IsTrue(FPresenter.CheckCanClose);
  Assert.AreEqual('version|1.0'#13#10'game|doom'#13#10'script|x.ddscript'#13#10,
    string(FFileSystem.Content(FOLDER + 'a.ddide')));
end;

procedure TTestIdeMainPresenter.DovrebbeScartareSeLUtenteDiceNo;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  FPresenter.Project.Add(FOLDER + 'x.ddscript', ikScript);
  FMessages.Answers.Enqueue(cfNo);
  Assert.IsTrue(FPresenter.CheckCanClose);
  Assert.AreEqual('version|1.0'#13#10'game|doom'#13#10, string(FFileSystem.Content(FOLDER + 'a.ddide')));
end;

procedure TTestIdeMainPresenter.DovrebbeNonChiedereNullaSeIlProgettoNonECambiato;
begin
  FPresenter.Start('');
  Assert.IsTrue(FPresenter.CheckCanClose);
  Assert.AreEqual(0, FMessages.Questions.Count);
end;

procedure TTestIdeMainPresenter.DovrebbeChiedereIlNomeSeIlProgettoNonLoHa;
begin
  FPresenter.Start('');
  FFiles.ProjectToSave := FOLDER + 'new.ddide';
  FPresenter.Save;
  Assert.IsTrue(FFileSystem.FileExists(FOLDER + 'new.ddide'));
  Assert.AreEqual('new.ddide', FPresenter.Project.ShortFileName);
end;

procedure TTestIdeMainPresenter.DovrebbeNonFareNullaSeLUtenteAnnullaIlSalvataggioConNome;
begin
  FPresenter.Start('');
  FFiles.ProjectToSave := '';
  FPresenter.SaveAs;
  Assert.AreEqual<Integer>(0, Length(FFileSystem.FileNames));
end;

procedure TTestIdeMainPresenter.DovrebbeSalvareConNomeEAggiornareIlTitolo;
begin
  FPresenter.Start('');
  FView.Calls.Clear;
  FFiles.ProjectToSave := FOLDER + 'named.ddide';
  FPresenter.SaveAs;
  Assert.IsTrue(FView.Calls.IndexOf('SetCaptions ' + TITLE + ' - named.ddide | named.ddide') >= 0);
  Assert.AreEqual(0, FBusy.Depth);
end;

procedure TTestIdeMainPresenter.DovrebbeAggiungereIFileScelti;
begin
  FPresenter.Start('');
  FFiles.ItemsToAdd := TArray<string>.Create(FOLDER + 'a.ddscript', FOLDER + 'b.ddscript');
  FPresenter.AddItems(ikScript);
  Assert.AreEqual(2, FPresenter.Project.Count);
  Assert.AreEqual(Ord(ikScript), Ord(FFiles.LastItemKind));
  Assert.IsTrue(FPresenter.Project.Modified);
end;

procedure TTestIdeMainPresenter.DovrebbeNonAggiungereNullaSeLUtenteAnnulla;
begin
  FPresenter.Start('');
  FFiles.ItemsToAdd := nil;
  FPresenter.AddItems(ikActor);
  Assert.AreEqual(0, FPresenter.Project.Count);
end;

procedure TTestIdeMainPresenter.DovrebbeAprireUnFileDelProgettoPerModificarlo;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10'script|s.ddscript'#13#10'compiledscript|c.ddout'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  FPresenter.EditItem('s.ddscript');
  FPresenter.EditItem('c.ddout');
  Assert.AreEqual(2, FView.EditorOpen.Count);
end;

procedure TTestIdeMainPresenter.DovrebbeNonAprireUnaRigaCheNonEUnFile;
begin
  FPresenter.Start('');
  FPresenter.EditItem('Scripts');
  Assert.AreEqual(0, FView.EditorOpen.Count);
end;

procedure TTestIdeMainPresenter.DovrebbeTogliereUnFileEChiudereLaSuaScheda;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10'script|s.ddscript'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  FPresenter.EditItem('s.ddscript');
  FPresenter.DeleteItem('s.ddscript');
  Assert.AreEqual(0, FView.EditorOpen.Count);
  Assert.AreEqual(0, FPresenter.Project.Count);
  Assert.IsTrue(FView.Calls.IndexOf('CloseEditor s.ddscript') >= 0);
end;

procedure TTestIdeMainPresenter.DovrebbeNonRinominareUnRamoDellAlbero;
begin
  FPresenter.Start('');
  Assert.IsFalse(FPresenter.CanRename('Scripts', True));
  Assert.AreEqual('Other', FPresenter.Rename('Scripts', 'Other', True));
end;

procedure TTestIdeMainPresenter.DovrebbeRinominareUnFileSenzaSchedaEDareIlPercorsoDelProgetto;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10'script|s.ddscript'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  Assert.IsTrue(FPresenter.CanRename('s.ddscript', False));
  Assert.AreEqual('new.ddscript', FPresenter.Rename('s.ddscript', FOLDER + 'new.ddscript', False));
  Assert.AreEqual('new.ddscript', FPresenter.Project.Items[0].RelativePath);
end;

procedure TTestIdeMainPresenter.DovrebbeLasciareIlTestoDatoSeCeLaSchedaAperta;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10'script|s.ddscript'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  FPresenter.EditItem('s.ddscript');
  FPresenter.CanRename('s.ddscript', False);
  // as the old window did: with a tab open the typed text stays in the tree
  Assert.AreEqual(FOLDER + 'new.ddscript', FPresenter.Rename('s.ddscript', FOLDER + 'new.ddscript', False));
  Assert.IsTrue(FView.Calls.IndexOf('ActivateEditor new.ddscript') >= 0);
end;

procedure TTestIdeMainPresenter.DovrebbeRipristinareIlNomeSeIlRinominareFallisce;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10'script|s.ddscript'#13#10'script|t.ddscript'#13#10);
  FPresenter.Start(FOLDER + 'a.ddide');
  FPresenter.CanRename('s.ddscript', False);
  Assert.AreEqual('s.ddscript', FPresenter.Rename('s.ddscript', 't.ddscript', False));
end;

procedure TTestIdeMainPresenter.DovrebbeNonPoterFareIlPk3SenzaFile;
begin
  FPresenter.Start('');
  Assert.IsFalse(FPresenter.CanGeneratePk3);
  FFiles.Pk3ToSave := 'out.pk3';
  FPresenter.GeneratePk3;
  Assert.AreEqual('', FArchive.SavedAs);
end;

procedure TTestIdeMainPresenter.DovrebbeFareIlPk3NelFileScelto;
begin
  WriteProject('a.ddide', 'version|1.0'#13#10'game|doom'#13#10'script|s.ddscript'#13#10);
  FFileSystem.AddFile(FOLDER + 's.ddscript', 'text');
  FPresenter.Start(FOLDER + 'a.ddide');
  Assert.IsTrue(FPresenter.CanGeneratePk3);
  FFiles.Pk3ToSave := 'C:\out\x.pk3';
  FPresenter.GeneratePk3;
  Assert.AreEqual('C:\out\x.pk3', FArchive.SavedAs);
end;

procedure TTestIdeMainPresenter.DovrebbeCopiareIlMessaggioSelezionatoNegliAppunti;
begin
  FLogIntf.Write(mkInfo, 'first'#13#10'second');
  FPresenter.CopyMessage(1);
  Assert.AreEqual('second', FClipboard.Text);
  FPresenter.CopyMessage(9);
  Assert.AreEqual('second', FClipboard.Text);
  FPresenter.CopyMessage(-1);
  Assert.AreEqual('second', FClipboard.Text);
end;

procedure TTestIdeMainPresenter.DovrebbeSalvareEPulireLaListaDeiMessaggi;
begin
  FLogIntf.Write(mkInfo, 'first'#13#10'second');
  FFiles.MessagesFile := FOLDER + 'log.txt';
  FPresenter.SaveMessages;
  Assert.AreEqual('first'#13#10'second'#13#10, string(FFileSystem.Content(FOLDER + 'log.txt')));
  FPresenter.ClearMessages;
  Assert.AreEqual(0, FLog.Count);
end;

procedure TTestIdeMainPresenter.DovrebbeScrivereLaVersioneENelCopyrightNelleInformazioni;
begin
  FPresenter.About;
  Assert.AreEqual(TITLE + #13#10'Version 1.2.3'#13#10#13#10 +
    'A tool for creating SCRIPTS for the DelphiDoom engine.'#13#10#169' 2016 - 2022, jvalavanis@gmail.com',
    FMessages.About);
end;

procedure TTestIdeMainPresenter.DovrebbeDareEccezioneSeUnaDipendenzaENil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdeMainPresenter.Create(nil, FFileSystemIntf, FLog, FClockIntf, FMessagesIntf, FFilesIntf,
        FBusyIntf, FClipboardIntf, FLibraryIntf, FBuilder,
        function: string
        begin
          Result := '';
        end, TITLE).Free;
    end, EArgumentNilException);
end;

end.
