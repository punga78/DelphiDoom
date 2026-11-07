{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the colors
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Colors;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.Colors;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelColors = class(TObject)
  public
    [Test]
    procedure DovrebbeScambiareRossoEBlu;
    [Test]
    procedure DovrebbePerdereIlByteAlto;
    [Test]
    procedure DovrebbeDareZeroPerZero;
  end;

implementation

procedure TTestVoxelColors.DovrebbeScambiareRossoEBlu;
begin
  Assert.AreEqual(Cardinal($00332211), TVoxelColors.SwapRgb($00112233));
end;

procedure TTestVoxelColors.DovrebbePerdereIlByteAlto;
begin
  Assert.AreEqual(Cardinal(0), TVoxelColors.SwapRgb($FF000000));
end;

procedure TTestVoxelColors.DovrebbeDareZeroPerZero;
begin
  Assert.AreEqual(Cardinal(0), TVoxelColors.SwapRgb(0));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelColors);

end.