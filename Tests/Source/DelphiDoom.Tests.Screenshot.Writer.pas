{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotWriter                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.Writer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Screenshot.Types,
  DelphiDoom.Screenshot.Intf, DelphiDoom.Screenshot.Writer,
  DelphiDoom.Tests.Screenshot.Fakes;

type
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotWriter = class(TObject)
  private
    FTga: TFakeEncoder;
    FPng: TFakeEncoder;
    FJpg: TFakeEncoder;
    FTgaIntf: IScreenshotEncoder;
    FPngIntf: IScreenshotEncoder;
    FJpgIntf: IScreenshotEncoder;
    FSink: TFakeSink;
    FSinkIntf: IScreenshotFileSink;
    FWriter: IScreenshotWriter;
    FPixels: TBytes;
    FTarget: TScreenshotTarget;
    procedure MakeWriter(AFailingFormat: Boolean = False);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeRifiutareUnaCodificaMancante;
    [Test]
    procedure DovrebbeRifiutareUnSinkNil;
    [Test]
    procedure DovrebbeScrivereSoloIlFormatoRichiesto;
    [Test]
    procedure DovrebbeScrivereAncheIlJpgSeRichiesto;
    [Test]
    procedure DovrebbeScrivereUnSoloJpgSeIlFormatoEGiaJpg;
    [Test]
    procedure DovrebbePassareIlVersoDelleRigheAlCodificatore;
    [Test]
    procedure DovrebbeDareFalsoSeLaCodificaFallisce;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonSiScrive;
    [Test]
    procedure DovrebbeIgnorareUnaCopiaJpgCheFallisce;
    [Test]
    procedure DovrebbeNonScrivereLaCopiaSeIlFormatoPrincipaleFallisce;
  end;

implementation

procedure TTestScreenshotWriter.Setup;
begin
  FPixels := TBytes.Create(1, 2, 3, 4);
  FTarget.Format := TScreenshotFormat.Png;
  FTarget.TgaPath := 'a.tga';
  FTarget.JpgPath := 'a.jpg';
  FTarget.PngPath := 'a.png';
  MakeWriter;
end;

procedure TTestScreenshotWriter.MakeWriter(AFailingFormat: Boolean);
begin
  FTga := TFakeEncoder.Create(TScreenshotFormat.Tga);
  FPng := TFakeEncoder.Create(TScreenshotFormat.Png, AFailingFormat);
  FJpg := TFakeEncoder.Create(TScreenshotFormat.Jpg);
  FTgaIntf := FTga;
  FPngIntf := FPng;
  FJpgIntf := FJpg;
  FSink := TFakeSink.Create;
  FSinkIntf := FSink;
  FWriter := TScreenshotWriter.Create(
    TArray<IScreenshotEncoder>.Create(FTgaIntf, FPngIntf, FJpgIntf), FSinkIntf);
end;

procedure TTestScreenshotWriter.DovrebbeRifiutareUnaCodificaMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TScreenshotWriter.Create(TArray<IScreenshotEncoder>.Create(FTgaIntf, FPngIntf), FSinkIntf);
    end, EScreenshotException);
end;

procedure TTestScreenshotWriter.DovrebbeRifiutareUnSinkNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScreenshotWriter.Create(TArray<IScreenshotEncoder>.Create(FTgaIntf, FPngIntf, FJpgIntf), nil);
    end, EArgumentNilException);
end;

procedure TTestScreenshotWriter.DovrebbeScrivereSoloIlFormatoRichiesto;
begin
  Assert.IsTrue(FWriter.Save(FTarget, Pointer(FPixels), 3, 2, False, False));
  Assert.IsTrue(FSink.Has('a.png'));
  Assert.AreEqual(1, FSink.Count);
  Assert.AreEqual(0, FTga.Calls);
  Assert.AreEqual(0, FJpg.Calls);
end;

procedure TTestScreenshotWriter.DovrebbeScrivereAncheIlJpgSeRichiesto;
begin
  Assert.IsTrue(FWriter.Save(FTarget, Pointer(FPixels), 3, 2, False, True));
  Assert.IsTrue(FSink.Has('a.png'));
  Assert.IsTrue(FSink.Has('a.jpg'));
  Assert.AreEqual(2, FSink.Count);
end;

procedure TTestScreenshotWriter.DovrebbeScrivereUnSoloJpgSeIlFormatoEGiaJpg;
begin
  FTarget.Format := TScreenshotFormat.Jpg;
  Assert.IsTrue(FWriter.Save(FTarget, Pointer(FPixels), 3, 2, False, True));
  Assert.AreEqual(1, FJpg.Calls, 'senza un secondo jpg');
  Assert.AreEqual(1, FSink.Count);
end;

procedure TTestScreenshotWriter.DovrebbePassareIlVersoDelleRigheAlCodificatore;
begin
  Assert.IsTrue(FWriter.Save(FTarget, Pointer(FPixels), 3, 2, True, True));
  Assert.IsTrue(FPng.LastBottomUp);
  Assert.IsTrue(FJpg.LastBottomUp);
end;

procedure TTestScreenshotWriter.DovrebbeDareFalsoSeLaCodificaFallisce;
begin
  MakeWriter(True);
  Assert.IsFalse(FWriter.Save(FTarget, Pointer(FPixels), 3, 2, False, True));
  Assert.AreEqual(0, FSink.Count);
end;

procedure TTestScreenshotWriter.DovrebbeDareFalsoSeIlFileNonSiScrive;
begin
  FSink.Refused := 'a.png';
  Assert.IsFalse(FWriter.Save(FTarget, Pointer(FPixels), 3, 2, False, False));
end;

procedure TTestScreenshotWriter.DovrebbeIgnorareUnaCopiaJpgCheFallisce;
begin
  FSink.Refused := 'a.jpg';
  Assert.IsTrue(FWriter.Save(FTarget, Pointer(FPixels), 3, 2, False, True));
  Assert.IsTrue(FSink.Has('a.png'));
end;

procedure TTestScreenshotWriter.DovrebbeNonScrivereLaCopiaSeIlFormatoPrincipaleFallisce;
begin
  FSink.Refused := 'a.png';
  FWriter.Save(FTarget, Pointer(FPixels), 3, 2, False, True);
  Assert.AreEqual(0, FJpg.Calls);
end;

end.
