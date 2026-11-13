{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - TDeclMemorySource            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Source;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Source.Memory;

type
  [TestFixture]
  [Category('Decl')]
  TTestDeclMemorySource = class
  strict private
    FSource: TDeclMemorySource;
    FSourceIntf: IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereUnFileSenzaDistinguereLeMaiuscoleEISeparatori;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileMancante;
    [Test]
    procedure DovrebbeCambiareLOrarioScrivendo;
    [Test]
    procedure DovrebbeDareLunghezzaEOrarioSenzaContareUnaLettura;
    [Test]
    procedure DovrebbeElencareSoloLaCartellaEdEstensioneRichieste;
    [Test]
    procedure DovrebbeTogliereUnFile;
  end;

implementation

{ TTestDeclMemorySource }

procedure TTestDeclMemorySource.Setup;
begin
  FSource := TDeclMemorySource.Create;
  FSourceIntf := FSource;
end;

procedure TTestDeclMemorySource.TearDown;
begin
  FSourceIntf := nil;
  FSource := nil;
end;

procedure TTestDeclMemorySource.DovrebbeLeggereUnFileSenzaDistinguereLeMaiuscoleEISeparatori;
var
  LText: AnsiString;
  LTime: Int64;
begin
  FSource.Add('Dir\File.TXT', 'abc');
  Assert.IsTrue(FSource.TryReadFile('dir/file.txt', LText, LTime));
  Assert.AreEqual('abc', string(LText));
  Assert.AreEqual(1, FSource.ReadCount);
end;

procedure TTestDeclMemorySource.DovrebbeDareFalsoPerUnFileMancante;
var
  LText: AnsiString;
  LTime: Int64;
  LLength: Integer;
begin
  Assert.IsFalse(FSource.TryReadFile('none', LText, LTime));
  Assert.IsFalse(FSource.TryGetFileInfo('none', LLength, LTime));
  Assert.AreEqual(-1, LLength);
end;

procedure TTestDeclMemorySource.DovrebbeCambiareLOrarioScrivendo;
var
  LText: AnsiString;
  LFirst, LSecond: Int64;
begin
  FSource.Add('a', 'x');
  FSource.TryReadFile('a', LText, LFirst);
  Assert.IsTrue(FSource.WriteFile('a', 'y'));
  FSource.TryReadFile('a', LText, LSecond);
  Assert.AreNotEqual(LFirst, LSecond);
  Assert.AreEqual('y', string(LText));
end;

procedure TTestDeclMemorySource.DovrebbeDareLunghezzaEOrarioSenzaContareUnaLettura;
var
  LLength: Integer;
  LTime: Int64;
begin
  FSource.Add('a', 'four');
  Assert.IsTrue(FSource.TryGetFileInfo('A', LLength, LTime));
  Assert.AreEqual(4, LLength);
  Assert.AreEqual(0, FSource.ReadCount);
end;

procedure TTestDeclMemorySource.DovrebbeElencareSoloLaCartellaEdEstensioneRichieste;
var
  LFiles: TArray<AnsiString>;
begin
  FSource.Add('d/b.x', '');
  FSource.Add('d/a.x', '');
  FSource.Add('d/s/c.X', '');
  FSource.Add('d/n.y', '');
  FSource.Add('other/z.x', '');
  FSource.Add('dd/q.x', '');
  LFiles := FSource.ListFiles('D', '.x');
  Assert.AreEqual<Integer>(3, Length(LFiles));
  Assert.AreEqual('a.x', string(LFiles[0]));
  Assert.AreEqual('b.x', string(LFiles[1]));
  Assert.AreEqual('s/c.X', string(LFiles[2]));
end;

procedure TTestDeclMemorySource.DovrebbeTogliereUnFile;
var
  LText: AnsiString;
  LTime: Int64;
begin
  FSource.Add('a', 'x');
  FSource.Remove('a');
  FSource.Remove('never');
  Assert.IsFalse(FSource.TryReadFile('a', LText, LTime));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclMemorySource);

end.
