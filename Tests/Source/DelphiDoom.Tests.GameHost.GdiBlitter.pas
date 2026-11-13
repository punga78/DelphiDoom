{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the game host library - the GDI step of a picture of    }
{  colors (a memory device context: no window)                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameHost.GdiBlitter;

interface

uses
  Winapi.Windows, System.Types, System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Win.GdiBlitter;

type
  [TestFixture]
  [Category('gamehost')]
  TTestGameHostGdiBlitter = class(TObject)
  strict private
    FDevice: HDC;
    FBitmap: HBITMAP;
    FOld: HGDIOBJ;
    FBits: PCardinal;
    FWidth: Integer;
    FHeight: Integer;
    procedure MakeTarget(AWidth, AHeight: Integer);
    function PixelAt(AX, AY: Integer): Cardinal;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCopiareUnaDestinazioneDellaStessaMisura;
    [Test]
    procedure DovrebbeAllungareAlVicinoPiuProssimo;
    [Test]
    procedure DovrebbeDisegnareNelRettangoloDato;
    [Test]
    procedure DovrebbeLeggereLeRigheDallAlto;
    [Test]
    procedure DovrebbeDareFalsoSenzaPixel;
    [Test]
    procedure DovrebbeDareFalsoConUnaDestinazioneVuota;
    [Test]
    procedure DovrebbeDareFalsoSenzaContesto;
  end;

implementation

{ TTestGameHostGdiBlitter }

procedure TTestGameHostGdiBlitter.MakeTarget(AWidth, AHeight: Integer);
var
  LInfo: TBitmapInfo;
  LBits: Pointer;
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FDevice := CreateCompatibleDC(0);
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.bmiHeader.biSize := SizeOf(LInfo.bmiHeader);
  LInfo.bmiHeader.biWidth := AWidth;
  LInfo.bmiHeader.biHeight := -AHeight;
  LInfo.bmiHeader.biPlanes := 1;
  LInfo.bmiHeader.biBitCount := 32;
  LInfo.bmiHeader.biCompression := BI_RGB;
  FBitmap := CreateDIBSection(FDevice, LInfo, DIB_RGB_COLORS, LBits, 0, 0);
  FBits := LBits;
  FOld := SelectObject(FDevice, FBitmap);
  FillChar(FBits^, AWidth * AHeight * 4, 0);
end;

function TTestGameHostGdiBlitter.PixelAt(AX, AY: Integer): Cardinal;
begin
  Result := PCardinal(PByte(FBits) + (AY * FWidth + AX) * 4)^ and $FFFFFF;
end;

procedure TTestGameHostGdiBlitter.TearDown;
begin
  if FDevice <> 0 then
  begin
    SelectObject(FDevice, FOld);
    DeleteObject(FBitmap);
    DeleteDC(FDevice);
    FDevice := 0;
  end;
end;

procedure TTestGameHostGdiBlitter.DovrebbeCopiareUnaDestinazioneDellaStessaMisura;
var
  LPixels: array[0..5] of Cardinal;
begin
  MakeTarget(3, 2);
  LPixels[0] := $FF0000;
  LPixels[1] := $00FF00;
  LPixels[2] := $0000FF;
  LPixels[3] := $123456;
  LPixels[4] := $ABCDEF;
  LPixels[5] := $000001;
  Assert.IsTrue(TGameHostWinGdiBlitter.Draw(FDevice, @LPixels[0], 3, 2, TRect.Create(0, 0, 3, 2)));
  Assert.AreEqual<Cardinal>($FF0000, PixelAt(0, 0));
  Assert.AreEqual<Cardinal>($00FF00, PixelAt(1, 0));
  Assert.AreEqual<Cardinal>($0000FF, PixelAt(2, 0));
  Assert.AreEqual<Cardinal>($123456, PixelAt(0, 1));
  Assert.AreEqual<Cardinal>($ABCDEF, PixelAt(1, 1));
  Assert.AreEqual<Cardinal>($000001, PixelAt(2, 1));
end;

procedure TTestGameHostGdiBlitter.DovrebbeAllungareAlVicinoPiuProssimo;
var
  LPixels: array[0..3] of Cardinal;
begin
  MakeTarget(4, 4);
  LPixels[0] := $111111;
  LPixels[1] := $222222;
  LPixels[2] := $333333;
  LPixels[3] := $444444;
  Assert.IsTrue(TGameHostWinGdiBlitter.Draw(FDevice, @LPixels[0], 2, 2, TRect.Create(0, 0, 4, 4)));
  Assert.AreEqual<Cardinal>($111111, PixelAt(0, 0));
  Assert.AreEqual<Cardinal>($111111, PixelAt(1, 1));
  Assert.AreEqual<Cardinal>($222222, PixelAt(2, 0));
  Assert.AreEqual<Cardinal>($222222, PixelAt(3, 1));
  Assert.AreEqual<Cardinal>($333333, PixelAt(0, 2));
  Assert.AreEqual<Cardinal>($444444, PixelAt(3, 3));
end;

procedure TTestGameHostGdiBlitter.DovrebbeDisegnareNelRettangoloDato;
var
  LPixels: array[0..0] of Cardinal;
begin
  MakeTarget(4, 4);
  LPixels[0] := $ABCDEF;
  Assert.IsTrue(TGameHostWinGdiBlitter.Draw(FDevice, @LPixels[0], 1, 1, TRect.Create(2, 1, 3, 2)));
  Assert.AreEqual<Cardinal>($ABCDEF, PixelAt(2, 1));
  Assert.AreEqual<Cardinal>(0, PixelAt(1, 1));
  Assert.AreEqual<Cardinal>(0, PixelAt(2, 0));
  Assert.AreEqual<Cardinal>(0, PixelAt(3, 2));
end;

procedure TTestGameHostGdiBlitter.DovrebbeLeggereLeRigheDallAlto;
var
  LPixels: array[0..1] of Cardinal;
begin
  MakeTarget(1, 2);
  LPixels[0] := $0000AA;
  LPixels[1] := $BB0000;
  Assert.IsTrue(TGameHostWinGdiBlitter.Draw(FDevice, @LPixels[0], 1, 2, TRect.Create(0, 0, 1, 2)));
  Assert.AreEqual<Cardinal>($0000AA, PixelAt(0, 0));
  Assert.AreEqual<Cardinal>($BB0000, PixelAt(0, 1));
end;

procedure TTestGameHostGdiBlitter.DovrebbeDareFalsoSenzaPixel;
begin
  MakeTarget(2, 2);
  Assert.IsFalse(TGameHostWinGdiBlitter.Draw(FDevice, nil, 2, 2, TRect.Create(0, 0, 2, 2)));
end;

procedure TTestGameHostGdiBlitter.DovrebbeDareFalsoConUnaDestinazioneVuota;
var
  LPixels: array[0..0] of Cardinal;
begin
  MakeTarget(2, 2);
  Assert.IsFalse(TGameHostWinGdiBlitter.Draw(FDevice, @LPixels[0], 1, 1, TRect.Create(0, 0, 0, 0)));
end;

procedure TTestGameHostGdiBlitter.DovrebbeDareFalsoSenzaContesto;
var
  LPixels: array[0..0] of Cardinal;
begin
  Assert.IsFalse(TGameHostWinGdiBlitter.Draw(0, @LPixels[0], 1, 1, TRect.Create(0, 0, 1, 1)));
end;

end.
