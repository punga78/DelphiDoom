{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotFileSink                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.FileSink;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Screenshot.Intf,
  DelphiDoom.Screenshot.FileSink;

type
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotFileSink = class(TObject)
  private
    FFolder: string;
    FSink: IScreenshotFileSink;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereIByteDelFile;
    [Test]
    procedure DovrebbeSostituireUnFileEsistente;
    [Test]
    procedure DovrebbeDareFalsoPerUnContenutoVuoto;
    [Test]
    procedure DovrebbeDareFalsoSeLaCartellaNonEsiste;
  end;

implementation

procedure TTestScreenshotFileSink.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'dd_sshot_' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(FFolder);
  FSink := TScreenshotFileSink.Create;
end;

procedure TTestScreenshotFileSink.TearDown;
begin
  TDirectory.Delete(FFolder, True);
end;

procedure TTestScreenshotFileSink.DovrebbeScrivereIByteDelFile;
var
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, 'a.bin');
  Assert.IsTrue(FSink.Write(LPath, TBytes.Create(1, 2, 3)));
  Assert.AreEqual(3, Integer(TFile.GetSize(LPath)));
  Assert.AreEqual(2, Integer(TFile.ReadAllBytes(LPath)[1]));
end;

procedure TTestScreenshotFileSink.DovrebbeSostituireUnFileEsistente;
var
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, 'a.bin');
  Assert.IsTrue(FSink.Write(LPath, TBytes.Create(1, 2, 3, 4, 5)));
  Assert.IsTrue(FSink.Write(LPath, TBytes.Create(9)));
  Assert.AreEqual(1, Integer(TFile.GetSize(LPath)));
end;

procedure TTestScreenshotFileSink.DovrebbeDareFalsoPerUnContenutoVuoto;
var
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, 'empty.bin');
  Assert.IsFalse(FSink.Write(LPath, nil));
  Assert.IsFalse(TFile.Exists(LPath));
end;

procedure TTestScreenshotFileSink.DovrebbeDareFalsoSeLaCartellaNonEsiste;
begin
  Assert.IsFalse(FSink.Write(TPath.Combine(FFolder, 'missing\a.bin'), TBytes.Create(1)));
end;

end.
