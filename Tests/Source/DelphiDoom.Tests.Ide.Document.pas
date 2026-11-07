{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeDocument                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Document;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Document,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeLog,
  DelphiDoom.Tests.Ide.FakeClock;

type
  /// <summary>Remembers what a document told it</summary>
  TRecordingObserver = class(TInterfacedObject, IIdeDocumentObserver)
  public
    Texts: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure DocumentChanged(const AData: AnsiString);
  end;

  [TestFixture]
  [Category('ide')]
  TTestIdeDocument = class(TObject)
  strict private
    FFileSystem: TFakeIdeFileSystem;
    FFileSystemIntf: IIdeFileSystem;
    FLog: TFakeIdeLog;
    FLogIntf: IIdeLog;
    FClock: IIdeClock;
    function NewDocument(const AFileName: string = ''): TIdeDocument;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIlFileInDataECreareUnDocumentoNonModificato;
    [Test]
    procedure DovrebbeCreareIlFileVuotoSeManca;
    [Test]
    procedure DovrebbeDireCheNonPuoCreareIlFileSeLaCartellaNonCe;
    [Test]
    procedure DovrebbeSegnareIlDocumentoComeModificatoQuandoCambiaIlTesto;
    [Test]
    procedure DovrebbeNonSegnareModificatoSeIlTestoEUguale;
    [Test]
    procedure DovrebbeSalvareIlTestoENonEssereModificato;
    [Test]
    procedure DovrebbeFareUnaCopiaDatataDelFileEsistente;
    [Test]
    procedure DovrebbeNonFareLaCopiaSeIlFileNonEsisteGia;
    [Test]
    procedure DovrebbeFallireSeLaCopiaDiSicurezzaFallisce;
    [Test]
    procedure DovrebbeAvvisareIlVisoreAllAggancioEAlCambioDelTesto;
    [Test]
    procedure DovrebbeNonAvvisareIlVisoreDopoIlDistacco;
    [Test]
    procedure DovrebbeTornareAlTestoPrecedenteConAnnulla;
    [Test]
    procedure DovrebbeDareIlNomeBreveDelFile;
    [Test]
    procedure DovrebbeDarePerLeggereUnFileDopoUnFallimentoIlNomeDiPrima;
  end;

implementation

const
  FOLDER = 'C:\prj\';

{ TRecordingObserver }

constructor TRecordingObserver.Create;
begin
  inherited Create;
  Texts := TStringList.Create;
end;

destructor TRecordingObserver.Destroy;
begin
  Texts.Free;
  inherited Destroy;
end;

procedure TRecordingObserver.DocumentChanged(const AData: AnsiString);
begin
  Texts.Add(string(AData));
end;

{ TTestIdeDocument }

procedure TTestIdeDocument.Setup;
begin
  FFileSystem := TFakeIdeFileSystem.Create(FOLDER);
  FFileSystemIntf := FFileSystem;
  FLog := TFakeIdeLog.Create;
  FLogIntf := FLog;
  FClock := TFakeIdeClock.Create;
end;

procedure TTestIdeDocument.TearDown;
begin
  FClock := nil;
  FLogIntf := nil;
  FFileSystemIntf := nil;
end;

function TTestIdeDocument.NewDocument(const AFileName: string): TIdeDocument;
begin
  Result := TIdeDocument.Create(FFileSystemIntf, FLogIntf, FClock, AFileName);
end;

procedure TTestIdeDocument.DovrebbeLeggereIlFileInDataECreareUnDocumentoNonModificato;
var
  LDocument: TIdeDocument;
begin
  FFileSystem.AddFile(FOLDER + 'a.ddscript', 'begin end');
  LDocument := NewDocument('a.ddscript');
  try
    Assert.AreEqual('begin end', string(LDocument.Data));
    Assert.IsFalse(LDocument.Modified);
    Assert.AreEqual(FOLDER + 'a.ddscript', LDocument.FileName);
    Assert.AreEqual('NORMAL|Loading "C:\prj\a.ddscript"\r\n', FLog.Lines[0]);
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeCreareIlFileVuotoSeManca;
var
  LDocument: TIdeDocument;
begin
  LDocument := NewDocument('new.ddscript');
  try
    Assert.IsTrue(FFileSystem.FileExists(FOLDER + 'new.ddscript'));
    Assert.AreEqual('', string(LDocument.Data));
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeDireCheNonPuoCreareIlFileSeLaCartellaNonCe;
var
  LDocument: TIdeDocument;
begin
  LDocument := NewDocument('missing\a.ddscript');
  try
    Assert.AreEqual('ERROR|Can not create file "C:\prj\missing\a.ddscript"\r\n', FLog.Lines[0]);
    // the document keeps the name it was given: it can be saved later
    Assert.AreEqual(FOLDER + 'missing\a.ddscript', LDocument.FileName);
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeSegnareIlDocumentoComeModificatoQuandoCambiaIlTesto;
var
  LDocument: TIdeDocument;
begin
  LDocument := NewDocument;
  try
    LDocument.Data := 'one';
    Assert.IsTrue(LDocument.Modified);
    Assert.AreEqual('one', string(LDocument.Data));
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeNonSegnareModificatoSeIlTestoEUguale;
var
  LDocument: TIdeDocument;
begin
  FFileSystem.AddFile(FOLDER + 'a.ddscript', 'same');
  LDocument := NewDocument('a.ddscript');
  try
    LDocument.Data := 'same';
    Assert.IsFalse(LDocument.Modified);
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeSalvareIlTestoENonEssereModificato;
var
  LDocument: TIdeDocument;
begin
  LDocument := NewDocument;
  try
    LDocument.Data := 'text to save';
    FLog.Clear;
    Assert.IsTrue(LDocument.SaveToFile('out.ddscript'));
    Assert.AreEqual('text to save', string(FFileSystem.Content(FOLDER + 'out.ddscript')));
    Assert.IsFalse(LDocument.Modified);
    Assert.AreEqual(FOLDER + 'out.ddscript', LDocument.FileName);
    Assert.AreEqual('NORMAL|Saving "C:\prj\out.ddscript"\r\n', FLog.Lines[0]);
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeFareUnaCopiaDatataDelFileEsistente;
var
  LDocument: TIdeDocument;
begin
  FFileSystem.AddFile(FOLDER + 'a.ddscript', 'before');
  LDocument := NewDocument('a.ddscript');
  try
    LDocument.Data := 'after';
    Assert.IsTrue(LDocument.SaveToFile('a.ddscript'));
    Assert.AreEqual('before', string(FFileSystem.Content(FOLDER + 'a.ddscript_20220304')));
    Assert.AreEqual('after', string(FFileSystem.Content(FOLDER + 'a.ddscript')));
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeNonFareLaCopiaSeIlFileNonEsisteGia;
var
  LDocument: TIdeDocument;
begin
  LDocument := NewDocument;
  try
    LDocument.Data := 'text';
    Assert.IsTrue(LDocument.SaveToFile('fresh.ddscript'));
    Assert.AreEqual(1, Length(FFileSystem.FileNames));
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeFallireSeLaCopiaDiSicurezzaFallisce;
var
  LDocument: TIdeDocument;
begin
  FFileSystem.AddFile(FOLDER + 'a.ddscript', 'before');
  LDocument := NewDocument('a.ddscript');
  try
    LDocument.Data := 'after';
    FFileSystem.FailWritesTo(FOLDER + 'a.ddscript_20220304');
    Assert.IsFalse(LDocument.SaveToFile('a.ddscript'));
    // nothing was written: the old text is still on the disk
    Assert.AreEqual('before', string(FFileSystem.Content(FOLDER + 'a.ddscript')));
    Assert.IsTrue(LDocument.Modified);
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeAvvisareIlVisoreAllAggancioEAlCambioDelTesto;
var
  LDocument: TIdeDocument;
  LObserver: TRecordingObserver;
  LObserverIntf: IIdeDocumentObserver;
begin
  FFileSystem.AddFile(FOLDER + 'a.ddscript', 'text');
  LDocument := NewDocument('a.ddscript');
  LObserver := TRecordingObserver.Create;
  LObserverIntf := LObserver;
  try
    LDocument.Attach(LObserverIntf);
    LDocument.AdjustLayout('changed');
    Assert.AreEqual(2, LObserver.Texts.Count);
    Assert.AreEqual('text', LObserver.Texts[0]);
    Assert.AreEqual('changed', LObserver.Texts[1]);
  finally
    LDocument.Detach;
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeNonAvvisareIlVisoreDopoIlDistacco;
var
  LDocument: TIdeDocument;
  LObserver: TRecordingObserver;
  LObserverIntf: IIdeDocumentObserver;
begin
  LDocument := NewDocument;
  LObserver := TRecordingObserver.Create;
  LObserverIntf := LObserver;
  try
    LDocument.Attach(LObserverIntf);
    LDocument.Detach;
    LDocument.AdjustLayout('changed');
    Assert.AreEqual(1, LObserver.Texts.Count);
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeTornareAlTestoPrecedenteConAnnulla;
var
  LDocument: TIdeDocument;
begin
  LDocument := NewDocument;
  try
    LDocument.Data := 'one';
    LDocument.SaveUndo;
    LDocument.Data := 'two';
    LDocument.Undo;
    Assert.AreEqual('one', string(LDocument.Data));
    LDocument.Redo;
    Assert.AreEqual('two', string(LDocument.Data));
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeDareIlNomeBreveDelFile;
var
  LDocument: TIdeDocument;
begin
  LDocument := NewDocument('sub\a.ddscript');
  try
    Assert.AreEqual('a.ddscript', LDocument.ShortFileName);
  finally
    LDocument.Free;
  end;
end;

procedure TTestIdeDocument.DovrebbeDarePerLeggereUnFileDopoUnFallimentoIlNomeDiPrima;
var
  LDocument: TIdeDocument;
begin
  FFileSystem.AddFile(FOLDER + 'a.ddscript', 'text');
  LDocument := NewDocument('a.ddscript');
  try
    // a missing folder: the file can not be created
    Assert.IsFalse(LDocument.LoadFromFile('nowhere\b.ddscript'));
    Assert.AreEqual(FOLDER + 'a.ddscript', LDocument.FileName);
    Assert.AreEqual('text', string(LDocument.Data));
  finally
    LDocument.Free;
  end;
end;

end.
