{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the factory
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Factory;
interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelFactory = class(TObject)
  public
    [Test]
    procedure DovrebbeCrearePerOgniFormatoUnLettore;
    [Test]
    procedure DovrebbeCreareLeAltreClassi;
  end;

implementation

uses
  DelphiDoom.Voxel.Intf, DelphiDoom.Voxel.Factory, DelphiDoom.Tests.Voxel.Fakes;

procedure TTestVoxelFactory.DovrebbeCrearePerOgniFormatoUnLettore;
var
  LFormats: TArray<IVoxelFormat>;
  LExtension: string;
  LFormat: IVoxelFormat;
  LCount: Integer;
begin
  LFormats := TVoxelFactory.CreateFormats(TVoxelFakeLog.Create);
  Assert.AreEqual(4, Length(LFormats));
  for LExtension in TArray<string>.Create('.DDVOX', '.DDMESH', '.KVX', '', '.VOX') do
  begin
    LCount := 0;
    for LFormat in LFormats do
      if LFormat.Handles(LExtension) then
        Inc(LCount);
    Assert.AreEqual(1, LCount, LExtension);
  end;
end;

procedure TTestVoxelFactory.DovrebbeCreareLeAltreClassi;
begin
  Assert.IsNotNull(TVoxelFactory.CreateCubeBuilder);
  Assert.IsNotNull(TVoxelFactory.CreatePatchBuilder(TVoxelFakeMapper.Create));
  Assert.IsNotNull(TVoxelFactory.CreateDefinitionParser(TVoxelFakeLookup.Create, TVoxelFakeLog.Create));
  Assert.IsNotNull(TVoxelFactory.CreateLoader(TVoxelFakeSource.Create, TVoxelFakeLog.Create));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelFactory);

end.