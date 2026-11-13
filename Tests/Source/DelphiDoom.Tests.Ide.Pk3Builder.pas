{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdePk3Builder                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Pk3Builder;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.Pk3Builder,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeLog,
  DelphiDoom.Tests.Ide.FakeClock,
  DelphiDoom.Tests.Ide.FakeArchive;

type
  [TestFixture]
  [Category('ide')]
  TTestIdePk3Builder = class(TObject)
  strict private
    FFileSystem: TFakeIdeFileSystem;
    FFileSystemIntf: IIdeFileSystem;
    FLog: TFakeIdeLog;
    FLogIntf: IIdeLog;
    FClock: IIdeClock;
    FArchive: TFakeIdeArchive;
    FArchiveIntf: IIdeArchive;
    FProject: TIdeProject;
    FBuilder: TIdePk3Builder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMettereGliScriptNellOrdineEGliActorInFondoInUnSoloFile;
    [Test]
    procedure DovrebbeUsareIlNomeBreveDelFile;
    [Test]
    procedure DovrebbeRileggereLoScriptCompilatoDalDisco;
    [Test]
    procedure DovrebbeUsareLaDataDelOrologio;
    [Test]
    procedure DovrebbeNonScrivereActordefSeNonCiSonoActor;
    [Test]
    procedure DovrebbeScrivereIlMessaggioDiRiuscita;
    [Test]
    procedure DovrebbeDareFalsoEUnMessaggioSeLArchivioFallisce;
    [Test]
    procedure DovrebbeDareEccezioneSeLeDipendenzeSonoNil;
  end;

implementation

const
  FOLDER = 'C:\prj\';

{ TTestIdePk3Builder }

procedure TTestIdePk3Builder.Setup;
begin
  FFileSystem := TFakeIdeFileSystem.Create(FOLDER);
  FFileSystemIntf := FFileSystem;
  FLog := TFakeIdeLog.Create;
  FLogIntf := FLog;
  FClock := TFakeIdeClock.Create;
  FArchive := TFakeIdeArchive.Create;
  FArchiveIntf := FArchive;
  FFileSystem.AddFolder(FOLDER + 'scripts');
  FFileSystem.AddFile(FOLDER + 'p.ddide',
    'version|1.0'#13#10'game|doom'#13#10 +
    'script|a.ddscript'#13#10 +
    'actor|one.txt'#13#10 +
    'actor|two.txt'#13#10 +
    'compiledscript|c.ddout'#13#10 +
    'script|scripts\b.ddscript'#13#10);
  FFileSystem.AddFile(FOLDER + 'a.ddscript', 'SCRIPT A');
  FFileSystem.AddFile(FOLDER + 'one.txt', 'ACTOR1');
  FFileSystem.AddFile(FOLDER + 'two.txt', 'ACTOR2');
  FFileSystem.AddFile(FOLDER + 'c.ddout', 'OLD COMPILED');
  FFileSystem.AddFile(FOLDER + 'scripts\b.ddscript', 'SCRIPT B');
  FProject := TIdeProject.Create(FFileSystemIntf, FLogIntf, FClock, FOLDER + 'p.ddide');
  FBuilder := TIdePk3Builder.Create(
    function: IIdeArchive
    begin
      Result := FArchiveIntf;
    end, FLogIntf, FClock);
  FLog.Clear;
end;

procedure TTestIdePk3Builder.TearDown;
begin
  FBuilder.Free;
  FProject.Free;
  FArchiveIntf := nil;
  FClock := nil;
  FLogIntf := nil;
  FFileSystemIntf := nil;
end;

procedure TTestIdePk3Builder.DovrebbeMettereGliScriptNellOrdineEGliActorInFondoInUnSoloFile;
begin
  Assert.IsTrue(FBuilder.Generate(FProject, 'out.pk3'));
  Assert.AreEqual(4, FArchive.Names.Count);
  Assert.AreEqual('a.ddscript', FArchive.Names[0]);
  Assert.AreEqual('c.ddout', FArchive.Names[1]);
  Assert.AreEqual('b.ddscript', FArchive.Names[2]);
  Assert.AreEqual('ACTORDEF.TXT', FArchive.Names[3]);
  Assert.AreEqual('SCRIPT A', FArchive.Contents[0]);
  Assert.AreEqual('ACTOR1\r\nACTOR2\r\n', FArchive.Contents[3]);
  Assert.AreEqual('out.pk3', FArchive.SavedAs);
end;

procedure TTestIdePk3Builder.DovrebbeUsareIlNomeBreveDelFile;
begin
  FBuilder.Generate(FProject, 'out.pk3');
  Assert.AreEqual(-1, FArchive.Names.IndexOf('scripts\b.ddscript'));
  Assert.AreEqual(2, FArchive.Names.IndexOf('b.ddscript'));
end;

procedure TTestIdePk3Builder.DovrebbeRileggereLoScriptCompilatoDalDisco;
begin
  FFileSystem.AddFile(FOLDER + 'c.ddout', 'NEW COMPILED');
  FBuilder.Generate(FProject, 'out.pk3');
  Assert.AreEqual('NEW COMPILED', FArchive.Contents[1]);
end;

procedure TTestIdePk3Builder.DovrebbeUsareLaDataDelOrologio;
var
  LDate: TDateTime;
begin
  FBuilder.Generate(FProject, 'out.pk3');
  LDate := FClock.Now;
  Assert.AreEqual<Integer>(4, Length(FArchive.Dates));
  Assert.AreEqual(LDate, FArchive.Dates[0]);
  Assert.AreEqual(LDate, FArchive.Dates[3]);
end;

procedure TTestIdePk3Builder.DovrebbeNonScrivereActordefSeNonCiSonoActor;
begin
  FProject.Delete('one.txt');
  FProject.Delete('two.txt');
  FBuilder.Generate(FProject, 'out.pk3');
  Assert.AreEqual(-1, FArchive.Names.IndexOf('ACTORDEF.TXT'));
  Assert.AreEqual(3, FArchive.Names.Count);
end;

procedure TTestIdePk3Builder.DovrebbeScrivereIlMessaggioDiRiuscita;
begin
  FBuilder.Generate(FProject, 'out.pk3');
  Assert.AreEqual('NORMAL|Created PK3 file "out.pk3"\r\n', FLog.Lines[FLog.Lines.Count - 1]);
end;

procedure TTestIdePk3Builder.DovrebbeDareFalsoEUnMessaggioSeLArchivioFallisce;
begin
  FArchive.FailOnSave := True;
  Assert.IsFalse(FBuilder.Generate(FProject, 'out.pk3'));
  Assert.AreEqual('ERROR|Can not generate file "out.pk3"\r\n', FLog.Lines[FLog.Lines.Count - 1]);
end;

procedure TTestIdePk3Builder.DovrebbeDareEccezioneSeLeDipendenzeSonoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdePk3Builder.Create(nil, FLogIntf, FClock).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Generate(nil, 'out.pk3');
    end, EArgumentNilException);
end;

end.
