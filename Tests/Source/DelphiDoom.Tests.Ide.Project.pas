{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeProject                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Project;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.ProjectItem,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeLog,
  DelphiDoom.Tests.Ide.FakeClock;

type
  /// <summary>
  ///   The project: the golden files hold what the old TIDEProject did with the project files
  ///   of Tests\Data\Ide\Projects (items, text, lookups, messages, what saving writes)
  /// </summary>
  [TestFixture]
  [Category('ide')]
  TTestIdeProject = class(TObject)
  strict private
    FFileSystem: TFakeIdeFileSystem;
    FFileSystemIntf: IIdeFileSystem;
    FLog: TFakeIdeLog;
    FLogIntf: IIdeLog;
    FClock: IIdeClock;
    function NewProject(const AText: AnsiString = ''; const AName: string = 'p.ddide'): TIdeProject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('doom_full', 'doom_full')]
    [TestCase('heretic_mixed_case', 'heretic_mixed_case')]
    [TestCase('hexen_spaces', 'hexen_spaces')]
    [TestCase('strife_minimal', 'strife_minimal')]
    [TestCase('radix_and_mars', 'radix_and_mars')]
    [TestCase('unknown_game', 'unknown_game')]
    [TestCase('old_version', 'old_version')]
    [TestCase('no_version', 'no_version')]
    [TestCase('corrupt_text', 'corrupt_text')]
    [TestCase('duplicates', 'duplicates')]
    [TestCase('unknown_types', 'unknown_types')]
    [TestCase('relative_paths', 'relative_paths')]
    [TestCase('empty', 'empty')]
    [TestCase('blank_lines', 'blank_lines')]
    [TestCase('crlf_doom', 'crlf_doom')]
    [TestCase('no_trailing_newline', 'no_trailing_newline')]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioCodice(const AName: string);
    [Test]
    procedure DovrebbeFareLeStesseOperazioniDelVecchioCodice;
    [Test]
    procedure DovrebbeEssereDoomSeNuovo;
    [Test]
    procedure DovrebbeCreareIlFileDelProgettoSeManca;
    [Test]
    procedure DovrebbeTrovareUnFileConPercorsoRelativoAssolutoENomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeNonAggiungereDueVolteLoStessoFile;
    [Test]
    procedure DovrebbeSegnareIlProgettoComeModificatoDopoUnaAggiunta;
    [Test]
    procedure DovrebbeSegnareIlProgettoComeModificatoSeUnFileLoE;
    [Test]
    procedure DovrebbeChiamareIlGestoreAnchePerUnGiocoSconosciuto;
    [Test]
    procedure DovrebbeRifiutareIlRinominareDiUnFileCheNonCe;
    [Test]
    procedure DovrebbeRifiutareIlRinominareSulNomeDiUnAltroElemento;
    [Test]
    procedure DovrebbeSostituireIlTestoSeIlFileNuovoEsisteEIlGestoreDiceSi;
    [Test]
    procedure DovrebbeNonSostituireIlTestoSeIlGestoreDiceNo;
    [Test]
    procedure DovrebbeSalvareConUnaCopiaDatataEAggiungereLatest;
    [Test]
    procedure DovrebbeRipristinareIlNomeSeLaScritturaFallisce;
    [Test]
    procedure DovrebbeFareAnnullaERipristinaDelleSueModifiche;
    [Test]
    procedure DovrebbeDareEccezioneSeLeDipendenzeSonoNil;
  end;

implementation

uses
  DelphiDoom.Tests.Ide.TestData,
  DelphiDoom.Tests.Ide.ProjectDump;

const
  FOLDER = 'C:\prj\';

{ TTestIdeProject }

procedure TTestIdeProject.Setup;
begin
  FFileSystem := TFakeIdeFileSystem.Create(FOLDER);
  FFileSystemIntf := FFileSystem;
  FLog := TFakeIdeLog.Create;
  FLogIntf := FLog;
  FClock := TFakeIdeClock.Create;
end;

procedure TTestIdeProject.TearDown;
begin
  FClock := nil;
  FLogIntf := nil;
  FFileSystemIntf := nil;
end;

function TTestIdeProject.NewProject(const AText: AnsiString; const AName: string): TIdeProject;
begin
  if AText <> '' then
    FFileSystem.AddFile(FOLDER + AName, AText);
  Result := TIdeProject.Create(FFileSystemIntf, FLogIntf, FClock, FOLDER + AName);
end;

procedure TTestIdeProject.DovrebbeDareLoStessoRisultatoDelVecchioCodice(const AName: string);
var
  LDump: TStringList;
begin
  LDump := TProjectDump.Run(TIdeTestData.ReadBytes('Projects\' + AName + '.ddide'), AName + '.ddide');
  try
    Assert.AreEqual('', TIdeTestData.Compare('Projects\' + AName + '.golden.txt', LDump));
  finally
    LDump.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeFareLeStesseOperazioniDelVecchioCodice;
var
  LDump: TStringList;
begin
  LDump := TProjectDump.RunOperations;
  try
    Assert.AreEqual('', TIdeTestData.Compare('Projects\operations.golden.txt', LDump));
  finally
    LDump.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeEssereDoomSeNuovo;
var
  LProject: TIdeProject;
begin
  LProject := TIdeProject.Create(FFileSystemIntf, FLogIntf, FClock);
  try
    Assert.AreEqual('doom', LProject.Game);
    Assert.AreEqual(0, LProject.Count);
    Assert.AreEqual('', LProject.FileName);
    Assert.IsFalse(LProject.Modified);
    Assert.AreEqual(0, FLog.Lines.Count);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeCreareIlFileDelProgettoSeManca;
var
  LProject: TIdeProject;
begin
  LProject := NewProject('', 'new.ddide');
  try
    Assert.IsTrue(FFileSystem.FileExists(FOLDER + 'new.ddide'));
    Assert.AreEqual('NORMAL|Loading "C:\prj\new.ddide"\r\n', FLog.Lines[0]);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeTrovareUnFileConPercorsoRelativoAssolutoENomeSenzaMaiuscole;
var
  LProject: TIdeProject;
  LItem: TIdeProjectItem;
begin
  LProject := NewProject('version|1.0'#13#10'game|doom'#13#10'script|a.ddscript'#13#10);
  try
    LItem := LProject.Find('a.ddscript');
    Assert.IsNotNull(LItem);
    Assert.AreSame(LItem, LProject.Find(FOLDER + 'a.ddscript'));
    Assert.AreSame(LItem, LProject.Find('A.DDSCRIPT'));
    Assert.AreSame(LItem, LProject.Find('.\a.ddscript'));
    Assert.AreSame(LItem, LProject.Find('sub\..\a.ddscript'));
    Assert.IsNull(LProject.Find('b.ddscript'));
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeNonAggiungereDueVolteLoStessoFile;
var
  LProject: TIdeProject;
begin
  LProject := NewProject;
  try
    LProject.Add(FOLDER + 'a.ddscript', ikScript);
    LProject.Add('A.ddscript', ikScript);
    LProject.Add(FOLDER + 'a.ddscript', ikActor);
    Assert.AreEqual(1, LProject.Count);
    Assert.AreEqual(Ord(ikScript), Ord(LProject.Items[0].Kind));
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeSegnareIlProgettoComeModificatoDopoUnaAggiunta;
var
  LProject: TIdeProject;
begin
  LProject := NewProject;
  try
    Assert.IsFalse(LProject.Modified);
    LProject.Add(FOLDER + 'a.ddscript', ikScript);
    Assert.IsTrue(LProject.Modified);
    Assert.AreEqual('version|1.0'#13#10'game|doom'#13#10'script|a.ddscript'#13#10, string(LProject.Data));
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeSegnareIlProgettoComeModificatoSeUnFileLoE;
var
  LProject: TIdeProject;
begin
  LProject := NewProject('version|1.0'#13#10'game|doom'#13#10'script|a.ddscript'#13#10);
  try
    Assert.IsFalse(LProject.Modified);
    LProject.Items[0].AdjustLayout('changed');
    Assert.IsTrue(LProject.Items[0].Modified);
    Assert.IsTrue(LProject.Modified);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeChiamareIlGestoreAnchePerUnGiocoSconosciuto;
var
  LProject: TIdeProject;
  LHeard: TStringList;
begin
  LHeard := TStringList.Create;
  LProject := NewProject;
  try
    LProject.OnGameChanged :=
      procedure(const AGame: string)
      begin
        LHeard.Add(AGame);
      end;
    LProject.Game := ' Heretic';
    LProject.Game := 'Quake';
    Assert.AreEqual('heretic', LHeard[0]);
    Assert.AreEqual('quake', LHeard[1]);
    // the unknown game leaves the old one, with a warning that has the name as it was typed
    Assert.AreEqual('heretic', LProject.Game);
    Assert.AreEqual('WARNING|Unknown game type "Quake"\r\n', FLog.Lines[FLog.Lines.Count - 1]);
  finally
    LProject.Free;
    LHeard.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeRifiutareIlRinominareDiUnFileCheNonCe;
var
  LProject: TIdeProject;
begin
  LProject := NewProject;
  try
    Assert.IsFalse(LProject.CanRename('zzz'));
    Assert.IsFalse(LProject.ExecRename('b.ddscript'));
    Assert.IsFalse(LProject.Rename('zzz', 'b.ddscript'));
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeRifiutareIlRinominareSulNomeDiUnAltroElemento;
var
  LProject: TIdeProject;
begin
  LProject := NewProject('version|1.0'#13#10'game|doom'#13#10'script|a.ddscript'#13#10'script|b.ddscript'#13#10);
  try
    FLog.Clear;
    Assert.IsFalse(LProject.Rename('a.ddscript', 'b.ddscript'));
    Assert.AreEqual('ERROR|TIDEProject.ExecRename(): Can not rename "a.ddscript" to "b.ddscript". "b.ddscript" already in project\r\n',
      FLog.Lines[0]);
    Assert.AreEqual(2, LProject.Count);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeSostituireIlTestoSeIlFileNuovoEsisteEIlGestoreDiceSi;
var
  LProject: TIdeProject;
  LAsked: Integer;
begin
  LAsked := 0;
  FFileSystem.AddFile(FOLDER + 'other.ddscript', 'other text');
  LProject := NewProject('version|1.0'#13#10'game|doom'#13#10'script|a.ddscript'#13#10);
  try
    LProject.OnQueryModifiedItem :=
      function(const AItem: TIdeProjectItem): Boolean
      begin
        Inc(LAsked);
        Result := True;
      end;
    LProject.Items[0].AdjustLayout('edited');
    FLog.Clear;
    Assert.IsTrue(LProject.Rename('a.ddscript', 'other.ddscript'));
    Assert.AreEqual(1, LAsked);
    Assert.AreEqual('other text', string(LProject.Items[0].Data));
    Assert.AreEqual('other.ddscript', LProject.Items[0].RelativePath);
    Assert.IsFalse(LProject.Items[0].Modified);
    Assert.AreEqual('INFO|File "a.ddscript" replaced with existing file "other.ddscript"\r\n',
      FLog.Lines[FLog.Lines.Count - 1]);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeNonSostituireIlTestoSeIlGestoreDiceNo;
var
  LProject: TIdeProject;
begin
  FFileSystem.AddFile(FOLDER + 'other.ddscript', 'other text');
  LProject := NewProject('version|1.0'#13#10'game|doom'#13#10'script|a.ddscript'#13#10);
  try
    LProject.OnQueryModifiedItem :=
      function(const AItem: TIdeProjectItem): Boolean
      begin
        Result := False;
      end;
    LProject.Items[0].AdjustLayout('edited');
    FLog.Clear;
    Assert.IsFalse(LProject.Rename('a.ddscript', 'other.ddscript'));
    Assert.AreEqual('edited', string(LProject.Items[0].Data));
    Assert.AreEqual('a.ddscript', LProject.Items[0].RelativePath);
    Assert.AreEqual('WARNING|Please save "a.ddscript" before replacing it with file "other.ddscript"\r\n',
      FLog.Lines[0]);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeSalvareConUnaCopiaDatataEAggiungereLatest;
var
  LProject: TIdeProject;
begin
  FFileSystem.AddFile(FOLDER + 'p.ddide', 'old project text');
  LProject := TIdeProject.Create(FFileSystemIntf, FLogIntf, FClock);
  try
    Assert.IsTrue(LProject.SaveToFile(FOLDER + 'p.ddide'));
    Assert.AreEqual('old project text', string(FFileSystem.Content(FOLDER + 'p.ddide_20220304')));
    Assert.IsTrue(LProject.SaveToFile(FOLDER + 'p.ddide'));
    Assert.AreEqual('version|1.0'#13#10'game|doom'#13#10, string(FFileSystem.Content(FOLDER + 'p.ddide_20220304_latest')));
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeRipristinareIlNomeSeLaScritturaFallisce;
var
  LProject: TIdeProject;
begin
  LProject := NewProject('version|1.0'#13#10'game|doom'#13#10);
  try
    FFileSystem.FailWritesTo(FOLDER + 'x.ddide');
    FLog.Clear;
    Assert.IsFalse(LProject.SaveToFile(FOLDER + 'x.ddide'));
    Assert.AreEqual(FOLDER + 'p.ddide', LProject.FileName);
    Assert.AreEqual('ERROR|Can not write file "C:\prj\x.ddide"\r\n', FLog.Lines[0]);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeFareAnnullaERipristinaDelleSueModifiche;
var
  LProject: TIdeProject;
begin
  LProject := NewProject('version|1.0'#13#10'game|doom'#13#10);
  try
    Assert.IsFalse(LProject.CanUndo);
    LProject.SaveUndo;
    LProject.Game := 'hexen';
    Assert.IsTrue(LProject.CanUndo);
    LProject.Undo;
    Assert.AreEqual('doom', LProject.Game);
    Assert.IsTrue(LProject.CanRedo);
    LProject.Redo;
    Assert.AreEqual('hexen', LProject.Game);
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProject.DovrebbeDareEccezioneSeLeDipendenzeSonoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdeProject.Create(nil, FLogIntf, FClock).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TIdeProject.Create(FFileSystemIntf, nil, FClock).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TIdeProject.Create(FFileSystemIntf, FLogIntf, nil).Free;
    end, EArgumentNilException);
end;

end.
