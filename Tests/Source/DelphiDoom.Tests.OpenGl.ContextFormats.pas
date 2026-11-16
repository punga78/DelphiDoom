{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL context - pixel format and full screen mode }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.ContextFormats;

interface

uses
  Winapi.Windows,
  DUnitX.TestFramework,
  DelphiDoom.GlContext.PixelFormat,
  DelphiDoom.GlContext.FullScreenMode;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlContextFormats = class(TObject)
  public
    [Test]
    procedure DovrebbeDescrivereUnaFinestraRgbaADoppioBuffer;
    [Test]
    procedure DovrebbeDareLeProfonditaDelVecchioCodice;
    [Test]
    procedure DovrebbeLasciareAZeroTuttoIlResto;
    [Test]
    procedure DovrebbeChiedereLaDimensioneDelloSchermoA32Bit;
    [Test]
    procedure DovrebbeDichiarareValidiSoloLarghezzaAltezzaEProfondita;
  end;

implementation

{ TTestOpenGlContextFormats }

procedure TTestOpenGlContextFormats.DovrebbeDescrivereUnaFinestraRgbaADoppioBuffer;
var
  LDescriptor: TPixelFormatDescriptor;
begin
  TGlPixelFormat.Describe(LDescriptor);
  Assert.AreEqual<Integer>(SizeOf(TPixelFormatDescriptor), LDescriptor.nSize);
  Assert.AreEqual<Integer>(1, LDescriptor.nVersion);
  Assert.AreEqual<Cardinal>(PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER, LDescriptor.dwFlags);
  Assert.AreEqual<Integer>(PFD_TYPE_RGBA, LDescriptor.iPixelType);
  Assert.AreEqual<Integer>(PFD_MAIN_PLANE, LDescriptor.iLayerType);
end;

procedure TTestOpenGlContextFormats.DovrebbeDareLeProfonditaDelVecchioCodice;
var
  LDescriptor: TPixelFormatDescriptor;
begin
  TGlPixelFormat.Describe(LDescriptor);
  Assert.AreEqual<Integer>(32, LDescriptor.cColorBits);
  Assert.AreEqual<Integer>(16, LDescriptor.cDepthBits);
  Assert.AreEqual<Integer>(16, LDescriptor.cStencilBits);
end;

procedure TTestOpenGlContextFormats.DovrebbeLasciareAZeroTuttoIlResto;
var
  LDescriptor: TPixelFormatDescriptor;
begin
  FillChar(LDescriptor, SizeOf(LDescriptor), $FF);
  TGlPixelFormat.Describe(LDescriptor);
  Assert.AreEqual<Integer>(0, LDescriptor.cRedBits + LDescriptor.cRedShift + LDescriptor.cGreenBits +
    LDescriptor.cGreenShift + LDescriptor.cBlueBits + LDescriptor.cBlueShift + LDescriptor.cAlphaBits +
    LDescriptor.cAlphaShift);
  Assert.AreEqual<Integer>(0, LDescriptor.cAccumBits + LDescriptor.cAccumRedBits + LDescriptor.cAccumGreenBits +
    LDescriptor.cAccumBlueBits + LDescriptor.cAccumAlphaBits + LDescriptor.cAuxBuffers + LDescriptor.bReserved);
  Assert.AreEqual<Cardinal>(0, LDescriptor.dwLayerMask + LDescriptor.dwVisibleMask + LDescriptor.dwDamageMask);
end;

procedure TTestOpenGlContextFormats.DovrebbeChiedereLaDimensioneDelloSchermoA32Bit;
var
  LMode: DEVMODE;
begin
  TGlFullScreenMode.Describe(800, 600, LMode);
  Assert.AreEqual<Integer>(SizeOf(DEVMODE), LMode.dmSize);
  Assert.AreEqual<Cardinal>(800, LMode.dmPelsWidth);
  Assert.AreEqual<Cardinal>(600, LMode.dmPelsHeight);
  Assert.AreEqual<Cardinal>(32, LMode.dmBitsPerPel);
end;

procedure TTestOpenGlContextFormats.DovrebbeDichiarareValidiSoloLarghezzaAltezzaEProfondita;
var
  LMode: DEVMODE;
begin
  FillChar(LMode, SizeOf(LMode), $FF);
  TGlFullScreenMode.Describe(640, 480, LMode);
  Assert.AreEqual<Cardinal>(DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL, LMode.dmFields);
  Assert.AreEqual<Cardinal>(0, LMode.dmDisplayFrequency);
end;

end.
