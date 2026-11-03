{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TPngFileWriter                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.PngFileWriter;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('png')]
  TTestPngFileWriter = class(TObject)
  private
    FFileName: string;
    function ReadBack: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSaveBgrxWritesADecodableFile;
    [Test]
    procedure TestSaveBgrxKeepsTheColors;
    [Test]
    procedure TestSaveBgrxFlipsTheRowsOnRequest;
    [Test]
    procedure TestSaveGrayWritesAGrayscaleFile;
    [Test]
    procedure TestInvalidArgumentsReturnFalse;
    [Test]
    procedure TestUnwritableFileReturnsFalse;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Png.Intf, DelphiDoom.Png.Client,
  DelphiDoom.Png.Provider, DelphiDoom.Zlib.Provider,
  DelphiDoom.Texture.PngFileWriter;

{ TTestPngFileWriter }

procedure TTestPngFileWriter.Setup;
begin
  TPngProvider.Release;
  TZlibProvider.Release;
  FFileName := TPath.Combine(TPath.GetTempPath, 'ddpng_filewriter_test.png');
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
end;

procedure TTestPngFileWriter.TearDown;
begin
  TPngProvider.Release;
  TZlibProvider.Release;
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
end;

function TTestPngFileWriter.ReadBack: TBytes;
begin
  Result := TFile.ReadAllBytes(FFileName);
end;

procedure TTestPngFileWriter.TestSaveBgrxWritesADecodableFile;
var
  LPixels: TBytes;
  LInfo: TPngInfo;
begin
  SetLength(LPixels, 5 * 3 * 4);
  Assert.IsTrue(TPngFileWriter.SaveBgrx(FFileName, Pointer(LPixels), 5, 3, False));
  LInfo := TPngProvider.Client.GetInfo(ReadBack);
  Assert.AreEqual(5, LInfo.Width);
  Assert.AreEqual(3, LInfo.Height);
end;

procedure TTestPngFileWriter.TestSaveBgrxKeepsTheColors;
var
  LPixels: TBytes;
  LImage: TPngImage;
begin
  // One pixel: blue 10, green 20, red 30, fourth byte ignored
  LPixels := TBytes.Create(10, 20, 30, 99);
  Assert.IsTrue(TPngFileWriter.SaveBgrx(FFileName, Pointer(LPixels), 1, 1, False));
  LImage := TPngProvider.Client.Decode(ReadBack);
  Assert.AreEqual(10, Integer(LImage.Pixels[0]));
  Assert.AreEqual(20, Integer(LImage.Pixels[1]));
  Assert.AreEqual(30, Integer(LImage.Pixels[2]));
end;

procedure TTestPngFileWriter.TestSaveBgrxFlipsTheRowsOnRequest;
var
  LPixels: TBytes;
  LImage: TPngImage;
begin
  // Two rows of one pixel: the first is blue 1, the second blue 2
  LPixels := TBytes.Create(1, 0, 0, 0, 2, 0, 0, 0);
  Assert.IsTrue(TPngFileWriter.SaveBgrx(FFileName, Pointer(LPixels), 1, 2, True));
  LImage := TPngProvider.Client.Decode(ReadBack);
  Assert.AreEqual(2, Integer(LImage.Pixels[0]));
  Assert.AreEqual(1, Integer(LImage.Pixels[4]));
end;

procedure TTestPngFileWriter.TestSaveGrayWritesAGrayscaleFile;
var
  LPixels: TBytes;
  LInfo: TPngInfo;
begin
  LPixels := TBytes.Create(0, 64, 128, 255);
  Assert.IsTrue(TPngFileWriter.SaveGray(FFileName, Pointer(LPixels), 2, 2));
  LInfo := TPngProvider.Client.GetInfo(ReadBack);
  Assert.AreEqual(DDPNG_COLOR_GRAY, LInfo.ColorType);
  Assert.AreEqual(2, LInfo.Width);
end;

procedure TTestPngFileWriter.TestInvalidArgumentsReturnFalse;
var
  LPixels: TBytes;
begin
  LPixels := TBytes.Create(1, 2, 3, 4);
  Assert.IsFalse(TPngFileWriter.SaveBgrx(FFileName, nil, 1, 1, False));
  Assert.IsFalse(TPngFileWriter.SaveBgrx(FFileName, Pointer(LPixels), 0, 1, False));
  Assert.IsFalse(TPngFileWriter.SaveGray(FFileName, Pointer(LPixels), 1, 0));
  Assert.IsFalse(TFile.Exists(FFileName));
end;

procedure TTestPngFileWriter.TestUnwritableFileReturnsFalse;
var
  LPixels: TBytes;
begin
  LPixels := TBytes.Create(1, 2, 3, 4);
  Assert.IsFalse(TPngFileWriter.SaveBgrx(
    TPath.Combine(TPath.GetTempPath, 'no_such_dir_ddpng' + PathDelim + 'x.png'),
    Pointer(LPixels), 1, 1, False));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPngFileWriter);

end.
