{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the DirectDraw records at 32 and 64 bit (issue #44)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Win64.DirectDrawLayout;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   The sizes of the DirectDraw structures must be the ones of the C structures of ddraw.h: the
  ///   runtime checks dwSize and refuses the call (E_INVALIDARG) when it is not equal to its own.
  /// </summary>
  [TestFixture]
  [Category('win64')]
  TTestWin64DirectDrawLayout = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLaDimensioneDelC_DDSURFACEDESC2;
    [Test]
    procedure DovrebbeDareLaDimensioneDelC_DDSURFACEDESC;
    [Test]
    procedure DovrebbeDareLaDimensioneDelC_DDPIXELFORMAT;
    [Test]
    procedure DovrebbeDareLaDimensioneDelC_DDSCAPS2;
    [Test]
    procedure DovrebbeTenereIlPuntatoreDellaSuperficieAllineatoAllaLarghezzaDelPuntatore;
  end;

implementation

uses
  DirectX;

const
  // sizeof() of the structures of ddraw.h compiled by Visual C++ for x86 and for x64
{$IFDEF CPUX64}
  SIZE_SURFACEDESC2 = 136;
  SIZE_SURFACEDESC = 120;
{$ELSE}
  SIZE_SURFACEDESC2 = 124;
  SIZE_SURFACEDESC = 108;
{$ENDIF}

procedure TTestWin64DirectDrawLayout.DovrebbeDareLaDimensioneDelC_DDSURFACEDESC2;
begin
  Assert.AreEqual(SIZE_SURFACEDESC2, Integer(SizeOf(DDSURFACEDESC2)));
end;

procedure TTestWin64DirectDrawLayout.DovrebbeDareLaDimensioneDelC_DDSURFACEDESC;
begin
  Assert.AreEqual(SIZE_SURFACEDESC, Integer(SizeOf(DDSURFACEDESC)));
end;

procedure TTestWin64DirectDrawLayout.DovrebbeDareLaDimensioneDelC_DDPIXELFORMAT;
begin
  Assert.AreEqual(32, Integer(SizeOf(TDDPixelFormat)));
end;

procedure TTestWin64DirectDrawLayout.DovrebbeDareLaDimensioneDelC_DDSCAPS2;
begin
  Assert.AreEqual(16, Integer(SizeOf(TDDSCaps2)));
end;

procedure TTestWin64DirectDrawLayout.DovrebbeTenereIlPuntatoreDellaSuperficieAllineatoAllaLarghezzaDelPuntatore;
var
  LDesc: DDSURFACEDESC2;
begin
  // lpSurface sits after dwReserved: at offset 36 at 32 bit and at 40 at 64 bit (8 byte alignment)
  Assert.AreEqual(Integer(36 + (SizeOf(Pointer) - 4)),
    Integer(NativeInt(@LDesc.lpSurface) - NativeInt(@LDesc)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWin64DirectDrawLayout);

end.
