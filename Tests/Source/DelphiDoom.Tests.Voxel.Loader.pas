{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the loader
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Loader;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Voxel.Intf,
  DelphiDoom.Tests.Voxel.Fakes;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelLoader = class(TObject)
  strict private
    FLog: TVoxelFakeLog;
    FLogIntf: ILog;
    FSource: TVoxelFakeSource;
    FSourceIntf: IVoxelFileSource;
    FLoader: IVoxelLoader;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereUnFileDiOgniFormatoDallaSuaEstensione;
    [Test]
    procedure DovrebbeDareNilSenzaAvvisiSeIlFileNonCe;
    [Test]
    procedure DovrebbeDareNilEUnAvvisoSeIlFileNonVaBene;
    [Test]
    procedure DovrebbeNonDistinguereMaiuscoleEMinuscoleNellEstensione;
    [Test]
    procedure DovrebbeDireCheUnaEstensioneSconosciutaNonESupportata;
    [Test]
    procedure DovrebbeDareNilPerUnaEstensioneSconosciuta;
    [Test]
    procedure DovrebbeDareEccezioneSeManca;
  end;

implementation

uses
  DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Factory, DelphiDoom.Tests.Voxel.Samples;

procedure TTestVoxelLoader.Setup;
begin
  FLog := TVoxelFakeLog.Create;
  FLogIntf := FLog;
  FSource := TVoxelFakeSource.Create;
  FSourceIntf := FSource;
  FLoader := TVoxelFactory.CreateLoader(FSource, FLog);
end;

procedure TTestVoxelLoader.DovrebbeLeggereUnFileDiOgniFormatoDallaSuaEstensione;
begin
  FSource.AddFile('a.ddvox', TVoxelSamples.Ddvox(3));
  FSource.AddFile('b.ddmesh', TVoxelSamples.Ddmesh(3));
  FSource.AddFile('c.kvx', TVoxelSamples.Kvx(3));
  FSource.AddFile('d', TVoxelSamples.Kvx(4));
  FSource.AddFile('e.vox', TVoxelSamples.Slab6(3));
  Assert.AreEqual(Ord(vfDdvox), Ord(FLoader.Load('a.ddvox').Format));
  Assert.AreEqual(Ord(vfDdmesh), Ord(FLoader.Load('b.ddmesh').Format));
  Assert.AreEqual(Ord(vfKvx), Ord(FLoader.Load('c.kvx').Format));
  Assert.AreEqual(Ord(vfKvx), Ord(FLoader.Load('d').Format));
  Assert.AreEqual(Ord(vfSlab6), Ord(FLoader.Load('e.vox').Format));
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestVoxelLoader.DovrebbeDareNilSenzaAvvisiSeIlFileNonCe;
begin
  Assert.IsNull(FLoader.Load('none.kvx'));
  Assert.IsNull(FLoader.Load('none.ddvox'));
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestVoxelLoader.DovrebbeDareNilEUnAvvisoSeIlFileNonVaBene;
begin
  FSource.AddFile('bad.vox', TBytes.Create(1, 2, 3));
  Assert.IsNull(FLoader.Load('bad.vox'));
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.IsTrue(FLog.Warnings[0].Contains('bad.vox'));
end;

procedure TTestVoxelLoader.DovrebbeNonDistinguereMaiuscoleEMinuscoleNellEstensione;
begin
  FSource.AddFile('A.DdVoX', TVoxelSamples.Ddvox(2));
  Assert.IsTrue(FLoader.IsSupported('A.DdVoX'));
  Assert.IsNotNull(FLoader.Load('A.DdVoX'));
end;

procedure TTestVoxelLoader.DovrebbeDireCheUnaEstensioneSconosciutaNonESupportata;
begin
  Assert.IsFalse(FLoader.IsSupported('a.xyz'));
  Assert.IsTrue(FLoader.IsSupported('a'));
end;

procedure TTestVoxelLoader.DovrebbeDareNilPerUnaEstensioneSconosciuta;
begin
  Assert.IsNull(FLoader.Load('a.xyz'));
  Assert.AreEqual(0, FSource.Calls.Count);
end;

procedure TTestVoxelLoader.DovrebbeDareEccezioneSeManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TVoxelFactory.CreateLoader(nil, FLog);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TVoxelFactory.CreateLoader(FSource, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelLoader);

end.