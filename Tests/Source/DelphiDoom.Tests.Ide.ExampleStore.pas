{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeExampleStore                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.ExampleStore;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.ExampleStore,
  DelphiDoom.Tests.Ide.FakeFileSystem;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeExampleStore = class(TObject)
  strict private
    FFileSystem: TFakeIdeFileSystem;
    FFileSystemIntf: IIdeFileSystem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlTestoVuotoPerUnaVoceSenzaFile;
    [Test]
    procedure DovrebbeLeggereIlFileDellaVoce;
    [Test]
    procedure DovrebbeSalvareIlTestoDellaVoceCheSiLascia;
    [Test]
    procedure DovrebbeNonSalvareSeSolaLettura;
    [Test]
    procedure DovrebbeNonFareNullaSeLaVoceEGiaQuellaCorrente;
    [Test]
    procedure DovrebbeSalvareConSave;
    [Test]
    procedure DovrebbeNonSalvareSenzaVoceCorrente;
    [Test]
    procedure DovrebbeCreareLaCartellaSeManca;
    [Test]
    procedure DovrebbeUsareLEstensioneDellaCartella;
    [Test]
    procedure DovrebbeDareEccezioneSeNonCeIlFileSystem;
  end;

implementation

uses
  System.SysUtils;

{ TTestIdeExampleStore }

procedure TTestIdeExampleStore.Setup;
begin
  FFileSystem := TFakeIdeFileSystem.Create('C:\program');
  FFileSystemIntf := FFileSystem;
  FFileSystem.AddFolder('C:\program');
end;

procedure TTestIdeExampleStore.TearDown;
begin
  FFileSystemIntf := nil;
end;

procedure TTestIdeExampleStore.DovrebbeDareIlTestoVuotoPerUnaVoceSenzaFile;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'consts', '.ddscript', False);
  try
    Assert.IsTrue(LStore.Select('MAX', 'leftover', LText));
    Assert.AreEqual('', LText);
    Assert.AreEqual('MAX', LStore.CurrentName);
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeLeggereIlFileDellaVoce;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  FFileSystem.AddFile('C:\program\consts\MAX.ddscript', 'line one'#13#10'line two');
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'consts', '.ddscript', True);
  try
    LStore.Select('MAX', '', LText);
    Assert.AreEqual('line one'#13#10'line two'#13#10, LText);
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeSalvareIlTestoDellaVoceCheSiLascia;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'consts', '.ddscript', False);
  try
    LStore.Select('A', '', LText);
    LStore.Select('B', 'text of A', LText);
    Assert.AreEqual('text of A'#13#10, string(FFileSystem.Content('C:\program\consts\A.ddscript')));
    Assert.IsFalse(FFileSystem.FileExists('C:\program\consts\B.ddscript'));
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeNonSalvareSeSolaLettura;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'consts', '.ddscript', True);
  try
    LStore.Select('A', '', LText);
    LStore.Select('B', 'edited', LText);
    LStore.Save('edited');
    Assert.IsFalse(FFileSystem.FileExists('C:\program\consts\A.ddscript'));
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeNonFareNullaSeLaVoceEGiaQuellaCorrente;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'consts', '.ddscript', False);
  try
    LStore.Select('A', '', LText);
    Assert.IsFalse(LStore.Select('A', 'typed', LText));
    Assert.AreEqual('typed', LText);
    Assert.IsFalse(FFileSystem.FileExists('C:\program\consts\A.ddscript'));
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeSalvareConSave;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'classes', '.ddscript', False);
  try
    LStore.Select('TActor', '', LText);
    LStore.Save('example');
    Assert.AreEqual('example'#13#10, string(FFileSystem.Content('C:\program\classes\TActor.ddscript')));
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeNonSalvareSenzaVoceCorrente;
var
  LStore: TIdeExampleStore;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'classes', '.ddscript', False);
  try
    LStore.Save('example');
    Assert.AreEqual(0, Length(FFileSystem.FileNames));
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeCreareLaCartellaSeManca;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'vars', '.ddscript', False);
  try
    LStore.Select('A', '', LText);
    Assert.IsTrue(FFileSystem.DirectoryExists('C:\program\vars\'));
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeUsareLEstensioneDellaCartella;
var
  LStore: TIdeExampleStore;
  LText: string;
begin
  LStore := TIdeExampleStore.Create(FFileSystemIntf, 'actordeffuncs', '.txt', False);
  try
    LStore.Select('A', '', LText);
    LStore.Save('x');
    Assert.IsTrue(FFileSystem.FileExists('C:\program\actordeffuncs\A.txt'));
  finally
    LStore.Free;
  end;
end;

procedure TTestIdeExampleStore.DovrebbeDareEccezioneSeNonCeIlFileSystem;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdeExampleStore.Create(nil, 'a', '.b', False).Free;
    end, EArgumentNilException);
end;

end.
