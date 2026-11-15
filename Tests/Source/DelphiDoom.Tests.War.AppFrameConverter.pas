{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the picture for the window           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppFrameConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.App.FrameConverter;

type
  /// <summary>RGBA of the canvas to the colors of the display and to the bytes of the PNG</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppFrameConverter = class(TObject)
  public
    [Test]
    procedure DovrebbeMettereIlBluNelByteBassoEIlRossoNelAlto;
    [Test]
    procedure DovrebbeRendereOpacoOgniPixel;
    [Test]
    procedure DovrebbeUsareIlBufferDiArrivoSeHaLaLunghezzaGiusta;
    [Test]
    procedure DovrebbeAdattareIlBufferDiArrivo;
    [Test]
    procedure DovrebbeRifiutareUnaPitturaTroppoCorta;
    [Test]
    procedure DovrebbeDareIByteDelPngInOrdineBluVerdeRosso;
    [Test]
    procedure DovrebbeConvertireSoloIPixelChiesti;
  end;

implementation

{ TTestWarAppFrameConverter }

procedure TTestWarAppFrameConverter.DovrebbeMettereIlBluNelByteBassoEIlRossoNelAlto;
var
  LTarget: TArray<Cardinal>;
begin
  TWarFrameConverter.ToTrueColor([$11, $22, $33, $FF, $AA, $BB, $CC, $FF], 2, LTarget);
  Assert.AreEqual<Cardinal>($FF112233, LTarget[0]);
  Assert.AreEqual<Cardinal>($FFAABBCC, LTarget[1]);
end;

procedure TTestWarAppFrameConverter.DovrebbeRendereOpacoOgniPixel;
var
  LTarget: TArray<Cardinal>;
begin
  TWarFrameConverter.ToTrueColor([1, 2, 3, 0, 4, 5, 6, 128], 2, LTarget);
  Assert.AreEqual<Cardinal>($FF, LTarget[0] shr 24);
  Assert.AreEqual<Cardinal>($FF, LTarget[1] shr 24);
end;

procedure TTestWarAppFrameConverter.DovrebbeUsareIlBufferDiArrivoSeHaLaLunghezzaGiusta;
var
  LTarget: TArray<Cardinal>;
  LFirst: Pointer;
begin
  SetLength(LTarget, 1);
  LFirst := Pointer(LTarget);
  TWarFrameConverter.ToTrueColor([1, 2, 3, 255], 1, LTarget);
  Assert.IsTrue(LFirst = Pointer(LTarget), 'nessuna copia del buffer a ogni fotogramma');
end;

procedure TTestWarAppFrameConverter.DovrebbeAdattareIlBufferDiArrivo;
var
  LTarget: TArray<Cardinal>;
begin
  SetLength(LTarget, 5);
  TWarFrameConverter.ToTrueColor([1, 2, 3, 255, 4, 5, 6, 255], 2, LTarget);
  Assert.AreEqual<Integer>(2, Length(LTarget));
end;

procedure TTestWarAppFrameConverter.DovrebbeRifiutareUnaPitturaTroppoCorta;
var
  LTarget: TArray<Cardinal>;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarFrameConverter.ToTrueColor([1, 2, 3, 255], 2, LTarget);
    end, EArgumentException);
  Assert.WillRaise(
    procedure
    begin
      TWarFrameConverter.ToBgra([1, 2, 3], 1);
    end, EArgumentException);
end;

procedure TTestWarAppFrameConverter.DovrebbeDareIByteDelPngInOrdineBluVerdeRosso;
var
  LBytes: TArray<Byte>;
begin
  LBytes := TWarFrameConverter.ToBgra([$11, $22, $33, $00], 1);
  Assert.AreEqual<Integer>(4, Length(LBytes));
  Assert.AreEqual<Integer>($33, LBytes[0]);
  Assert.AreEqual<Integer>($22, LBytes[1]);
  Assert.AreEqual<Integer>($11, LBytes[2]);
  Assert.AreEqual<Integer>($FF, LBytes[3]);
end;

procedure TTestWarAppFrameConverter.DovrebbeConvertireSoloIPixelChiesti;
var
  LTarget: TArray<Cardinal>;
begin
  TWarFrameConverter.ToTrueColor([1, 2, 3, 255, 4, 5, 6, 255, 7, 8, 9, 255], 1, LTarget);
  Assert.AreEqual<Integer>(1, Length(LTarget));
  Assert.AreEqual<Integer>(4, Length(TWarFrameConverter.ToBgra([1, 2, 3, 255, 4, 5, 6, 255], 1)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppFrameConverter);

end.
