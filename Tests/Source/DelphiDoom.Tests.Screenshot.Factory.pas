{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotFactory                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.Factory;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Engine,
  DelphiDoom.Png.Engine, DelphiDoom.Png.Client, DelphiDoom.Jpeg.Engine, DelphiDoom.Jpeg.Client,
  DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.Intf, DelphiDoom.Screenshot.Factory,
  DelphiDoom.Tests.Screenshot.Fakes;

type
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotFactory = class(TObject)
  private
    FPng: TPngClient;
    FJpeg: TJpegClient;
    FFolder: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCreareGliEncoderDeiTreFormati;
    [Test]
    procedure DovrebbeCreareUnWriterCheScriveSuDisco;
    [Test]
    procedure DovrebbeCreareLeDestinazioni;
  end;

implementation

procedure TTestScreenshotFactory.Setup;
begin
  FPng := TPngClient.Create(TPngEngine.Create(TZlibEngine.Create));
  FJpeg := TJpegClient.Create(TJpegEngine.Create);
  FFolder := TPath.Combine(TPath.GetTempPath, 'dd_sshot_' + TGuid.NewGuid.ToString);
  TDirectory.CreateDirectory(FFolder);
end;

procedure TTestScreenshotFactory.TearDown;
begin
  TDirectory.Delete(FFolder, True);
  FJpeg.Free;
  FPng.Free;
end;

procedure TTestScreenshotFactory.DovrebbeCreareGliEncoderDeiTreFormati;
begin
  Assert.AreEqual(Ord(TScreenshotFormat.Tga), Ord(TScreenshotFactory.CreateTgaEncoder.Format));
  Assert.AreEqual(Ord(TScreenshotFormat.Png), Ord(TScreenshotFactory.CreatePngEncoder(FPng).Format));
  Assert.AreEqual(Ord(TScreenshotFormat.Jpg), Ord(TScreenshotFactory.CreateJpegEncoder(FJpeg).Format));
end;

procedure TTestScreenshotFactory.DovrebbeCreareUnWriterCheScriveSuDisco;
var
  LTarget: TScreenshotTarget;
  LPixels: TBytes;
  LIndex: Integer;
begin
  SetLength(LPixels, 16 * 16 * 4);
  for LIndex := 0 to High(LPixels) do
    LPixels[LIndex] := Byte(LIndex);
  LTarget.Format := TScreenshotFormat.Png;
  LTarget.TgaPath := TPath.Combine(FFolder, 'a.tga');
  LTarget.JpgPath := TPath.Combine(FFolder, 'a.jpg');
  LTarget.PngPath := TPath.Combine(FFolder, 'a.png');
  Assert.IsTrue(TScreenshotFactory.CreateWriter(FPng, FJpeg).Save(LTarget, Pointer(LPixels),
    16, 16, False, True));
  Assert.IsTrue(TFile.Exists(LTarget.PngPath));
  Assert.IsTrue(TFile.Exists(LTarget.JpgPath));
  Assert.IsFalse(TFile.Exists(LTarget.TgaPath));
end;

procedure TTestScreenshotFactory.DovrebbeCreareLeDestinazioni;
begin
  Assert.AreEqual('C:\Game\DATA\SCREENSHOTS\PNG\x.png',
    TScreenshotFactory.CreateTargets(TFakeFolders.Create).ForFileName('x').PngPath);
end;

end.
