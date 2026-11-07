{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeScriptEditorPresenter            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.ScriptEditorPresenter;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.ProjectItem,
  DelphiDoom.Ide.ScriptEditorPresenter,
  DelphiDoom.Ide.Views.Intf,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeLog,
  DelphiDoom.Tests.Ide.FakeClock,
  DelphiDoom.Tests.Ide.FakeScriptCompiler,
  DelphiDoom.Tests.Ide.FakeGameLibrary,
  DelphiDoom.Tests.Ide.FakeUi;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeScriptEditorPresenter = class(TObject)
  strict private
    FFileSystem: TFakeIdeFileSystem;
    FFileSystemIntf: IIdeFileSystem;
    FLog: TFakeIdeLog;
    FLogIntf: IIdeLog;
    FClock: IIdeClock;
    FCompiler: TFakeIdeScriptCompiler;
    FCompilerIntf: IIdeScriptCompiler;
    FLibrary: TFakeIdeGameLibrary;
    FLibraryIntf: IIdeGameLibrary;
    FFiles: TFakeIdeFileDialogs;
    FFilesIntf: IIdePCodeDialog;
    FBusy: TFakeIdeBusy;
    FBusyIntf: IIdeBusy;
    FView: TFakeIdeScriptEditorView;
    FViewIntf: IIdeScriptEditorView;
    FProject: TIdeProject;
    FPresenter: TIdeScriptEditorPresenter;
    procedure Open(const AIndex: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMostrareIlTestoDelloScriptAppenaAgganciato;
    [Test]
    procedure DovrebbeMostrareIlTestoDiUnaListaDiActor;
    [Test]
    procedure DovrebbeMostrareIlDisassemblatoDiUnoScriptCompilato;
    [Test]
    procedure DovrebbeMostrareGliStrumentiDelTipoDiFile;
    [Test]
    procedure DovrebbeLeggereGliEventiSoloPerGliScript;
    [Test]
    procedure DovrebbePrendereIlTestoScrittoSoloPerScriptEActor;
    [Test]
    procedure DovrebbeNonPrendereIlTestoSeNonEModificato;
    [Test]
    procedure DovrebbeCompilareEMuoverIlCursoreAlPrimoErrore;
    [Test]
    procedure DovrebbeNonCompilareUnFileCheNonEUnoScript;
    [Test]
    procedure DovrebbeSalvareIlCodiceCompilatoNelFileScelto;
    [Test]
    procedure DovrebbeNonSalvareIlCodiceSeLaCompilazioneFallisce;
    [Test]
    procedure DovrebbeNonSalvareIlCodiceSeLUtenteAnnulla;
    [Test]
    procedure DovrebbeScrivereUnErroreSeIlCodiceNonSiScrive;
    [Test]
    procedure DovrebbeSalvareLoScriptEUnaListaDiActorMaNonIlCompilato;
    [Test]
    procedure DovrebbeFarSapereIParametriDiUnaFunzioneDellaLibreria;
    [Test]
    procedure DovrebbeUnireGliActorAlleFunzioniSoloPerUnaListaDiActor;
    [Test]
    procedure DovrebbeAggiungereUnEventoInFondoAlloScript;
    [Test]
    procedure DovrebbeSmettereDiSeguireLoScriptQuandoSiLibera;
    [Test]
    procedure DovrebbeDareEccezioneSeUnaDipendenzaENil;
  end;

implementation

const
  FOLDER = 'C:\prj\';

{ TTestIdeScriptEditorPresenter }

procedure TTestIdeScriptEditorPresenter.Setup;
var
  LUnits: TArray<TIdeUnitDeclarations>;
begin
  FFileSystem := TFakeIdeFileSystem.Create(FOLDER);
  FFileSystemIntf := FFileSystem;
  FLog := TFakeIdeLog.Create;
  FLogIntf := FLog;
  FClock := TFakeIdeClock.Create;
  FCompiler := TFakeIdeScriptCompiler.Create;
  FCompilerIntf := FCompiler;
  FLibrary := TFakeIdeGameLibrary.Create;
  FLibraryIntf := FLibrary;
  FFiles := TFakeIdeFileDialogs.Create;
  FFilesIntf := FFiles;
  FBusy := TFakeIdeBusy.Create;
  FBusyIntf := FBusy;
  FView := TFakeIdeScriptEditorView.Create;
  FViewIntf := FView;
  FFileSystem.AddFile(FOLDER + 'p.ddide',
    'version|1.0'#13#10'game|hexen'#13#10'script|s.ddscript'#13#10'actor|a.txt'#13#10'compiledscript|c.ddout'#13#10);
  FFileSystem.AddFile(FOLDER + 's.ddscript', 'script text');
  FFileSystem.AddFile(FOLDER + 'a.txt', 'actor text');
  FFileSystem.AddFile(FOLDER + 'c.ddout', 'COMPILED');
  FProject := TIdeProject.Create(FFileSystemIntf, FLogIntf, FClock, FOLDER + 'p.ddide');
  FLibrary.SetLines(ldEvents, 'hexen', ['ONTICK|event OnTick(const tick: Integer);|begin|  |end;',
    'ONSTART|event OnStart;|begin|end;']);
  FLibrary.SetLines(ldActorDefFunctions, 'hexen', ['A_Look()', 'A_Chase(speed: Integer)']);
  SetLength(LUnits, 1);
  LUnits[0].UnitName := 'PS_FIXED';
  LUnits[0].Declarations := TArray<string>.Create('function FixedMul(a, b: fixed_t): fixed_t;');
  FLibrary.SetUnits('hexen', LUnits);
  FLog.Clear;
end;

procedure TTestIdeScriptEditorPresenter.TearDown;
begin
  FPresenter.Free;
  FPresenter := nil;
  FProject.Free;
  FViewIntf := nil;
  FBusyIntf := nil;
  FFilesIntf := nil;
  FLibraryIntf := nil;
  FCompilerIntf := nil;
  FClock := nil;
  FLogIntf := nil;
  FFileSystemIntf := nil;
end;

procedure TTestIdeScriptEditorPresenter.Open(const AIndex: Integer);
begin
  FPresenter := TIdeScriptEditorPresenter.Create(FProject.Items[AIndex], FViewIntf, FCompilerIntf,
    FLibraryIntf, FFileSystemIntf, FFilesIntf, FBusyIntf, FLogIntf);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeMostrareIlTestoDelloScriptAppenaAgganciato;
begin
  Open(0);
  Assert.AreEqual('script text', FView.Text);
  Assert.AreEqual(0, FBusy.Depth);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeMostrareIlTestoDiUnaListaDiActor;
begin
  Open(1);
  Assert.AreEqual('actor text', FView.Text);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeMostrareIlDisassemblatoDiUnoScriptCompilato;
begin
  FCompiler.DisassemblyText := 'disassembly';
  Open(2);
  Assert.AreEqual('disassembly', FView.Text);
  Assert.AreEqual('hexen', FCompiler.LastDisassembledGame);
  Assert.AreEqual('COMPILED', FCompiler.LastDisassembledPCode);
  Assert.AreEqual('NORMAL|Disassembling hexen compiled script "C:\prj\c.ddout"', FLog.Lines[0]);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeMostrareGliStrumentiDelTipoDiFile;
begin
  Open(2);
  Assert.AreEqual(Ord(ikCompiledScript), Ord(FView.Kind));
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeLeggereGliEventiSoloPerGliScript;
begin
  Open(0);
  Assert.AreEqual(2, FPresenter.EventCount);
  Assert.AreEqual('ONTICK', FPresenter.EventCaption(0));
  FPresenter.Free;
  FPresenter := nil;
  Open(1);
  Assert.AreEqual(0, FPresenter.EventCount);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbePrendereIlTestoScrittoSoloPerScriptEActor;
begin
  Open(0);
  FPresenter.EditorChanged('new script', True);
  Assert.AreEqual('new script', string(FProject.Items[0].Data));
  FPresenter.Free;
  FPresenter := nil;
  Open(2);
  FPresenter.EditorChanged('ignored', True);
  Assert.AreEqual('COMPILED', string(FProject.Items[2].Data));
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeNonPrendereIlTestoSeNonEModificato;
begin
  Open(0);
  FPresenter.EditorChanged('not edited', False);
  Assert.AreEqual('script text', string(FProject.Items[0].Data));
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeCompilareEMuoverIlCursoreAlPrimoErrore;
begin
  Open(0);
  FView.Text := 'editor text';
  FCompiler.Succeeds := False;
  FCompiler.Messages := ' Pos: 000046 Compiler: [Error] (6:3): Unknown identifier ''X''';
  FLog.Clear;
  FPresenter.Compile(False);
  Assert.AreEqual('hexen', FCompiler.LastGame);
  Assert.AreEqual('editor text', FCompiler.LastSource);
  Assert.IsTrue(FView.CaretMoved);
  Assert.AreEqual(6, FView.Caret.Line);
  Assert.AreEqual(3, FView.Caret.Column);
  Assert.AreEqual('NORMAL|Compiling hexen script "s.ddscript"', FLog.Lines[0]);
  Assert.AreEqual(0, FBusy.Depth);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeNonCompilareUnFileCheNonEUnoScript;
begin
  Open(1);
  FPresenter.Compile(False);
  Assert.AreEqual(0, FCompiler.CompileCount);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeSalvareIlCodiceCompilatoNelFileScelto;
begin
  Open(0);
  FCompiler.Succeeds := True;
  FCompiler.PCode := 'AB'#1#$FE;
  FFiles.PCodeFile := FOLDER + 'out.ddout';
  FPresenter.Compile(True);
  Assert.AreEqual(FOLDER + 's.ddout', FFiles.LastPCodeDefault);
  Assert.AreEqual(4, Length(FFileSystem.Content(FOLDER + 'out.ddout')));
  Assert.IsFalse(FView.CaretMoved);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeNonSalvareIlCodiceSeLaCompilazioneFallisce;
begin
  Open(0);
  FCompiler.Succeeds := False;
  FFiles.PCodeFile := FOLDER + 'out.ddout';
  FPresenter.Compile(True);
  Assert.IsFalse(FFileSystem.FileExists(FOLDER + 'out.ddout'));
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeNonSalvareIlCodiceSeLUtenteAnnulla;
begin
  Open(0);
  FCompiler.Succeeds := True;
  FCompiler.PCode := 'AB';
  FFiles.PCodeFile := '';
  FPresenter.Compile(True);
  Assert.IsFalse(FFileSystem.FileExists(FOLDER + 'out.ddout'));
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeScrivereUnErroreSeIlCodiceNonSiScrive;
begin
  Open(0);
  FCompiler.Succeeds := True;
  FCompiler.PCode := 'AB';
  FFiles.PCodeFile := 'C:\nowhere\out.ddout';
  FLog.Clear;
  FPresenter.Compile(True);
  Assert.AreEqual('ERROR|Can not write file "C:\nowhere\out.ddout"\r\n', FLog.Lines[FLog.Lines.Count - 1]);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeSalvareLoScriptEUnaListaDiActorMaNonIlCompilato;
begin
  Open(0);
  FPresenter.EditorChanged('saved script', True);
  FPresenter.Save;
  Assert.AreEqual('saved script', string(FFileSystem.Content(FOLDER + 's.ddscript')));
  FPresenter.Free;
  FPresenter := nil;
  Open(2);
  FFileSystem.AddFile(FOLDER + 'c.ddout', 'ON DISK');
  FPresenter.Save;
  Assert.AreEqual('ON DISK', string(FFileSystem.Content(FOLDER + 'c.ddout')));
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeFarSapereIParametriDiUnaFunzioneDellaLibreria;
var
  LName, LParameters: string;
  LIndex: Integer;
begin
  Open(0);
  Assert.IsTrue(FPresenter.FindCall('FixedMul(1, ', 13,
    function(AChar: Char): Boolean
    begin
      Result := CharInSet(AChar, ['A'..'Z', 'a'..'z', '0'..'9', '_']);
    end, LName, LIndex, LParameters));
  Assert.AreEqual('FIXEDMUL', LName);
  Assert.AreEqual(1, LIndex);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeUnireGliActorAlleFunzioniSoloPerUnaListaDiActor;
var
  LName, LParameters: string;
  LIndex: Integer;
  LIsIdent: TFunc<Char, Boolean>;
begin
  LIsIdent :=
    function(AChar: Char): Boolean
    begin
      Result := CharInSet(AChar, ['A'..'Z', 'a'..'z', '0'..'9', '_']);
    end;
  Open(0);
  Assert.IsFalse(FPresenter.FindCall('A_Chase(', 9, LIsIdent, LName, LIndex, LParameters));
  FPresenter.Free;
  FPresenter := nil;
  Open(1);
  Assert.IsTrue(FPresenter.FindCall('A_Chase(', 9, LIsIdent, LName, LIndex, LParameters));
  Assert.AreEqual('"speed: Integer"', LParameters);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeAggiungereUnEventoInFondoAlloScript;
var
  LCaret: Integer;
  LText: string;
begin
  Open(0);
  LText := FPresenter.AppendEvent(1, '', LCaret);
  Assert.AreEqual('uses'#13#10'  all;'#13#10#13#10#13#10'event OnStart;'#13#10'begin'#13#10'end;', LText);
  Assert.AreEqual(Pos('end;', LText) - 3, LCaret);
  Assert.AreEqual('ONSTART', FPresenter.EventScriptName(1));
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeSmettereDiSeguireLoScriptQuandoSiLibera;
begin
  Open(0);
  FPresenter.Free;
  FPresenter := nil;
  FView.ShowTextCount := 0;
  FProject.Items[0].AdjustLayout('later');
  Assert.AreEqual(0, FView.ShowTextCount);
end;

procedure TTestIdeScriptEditorPresenter.DovrebbeDareEccezioneSeUnaDipendenzaENil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdeScriptEditorPresenter.Create(FProject.Items[0], nil, FCompilerIntf, FLibraryIntf,
        FFileSystemIntf, FFilesIntf, FBusyIntf, FLogIntf).Free;
    end, EArgumentNilException);
end;

end.
