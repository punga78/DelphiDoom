{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the DDVOX format
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Ddvox;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Intf,
  DelphiDoom.Tests.Voxel.Fakes;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelDdvox = class(TObject)
  strict private
    FLog: TVoxelFakeLog;
    FLogIntf: ILog;
    FFormat: IVoxelFormat;
    function Decode(const AText: string): IVoxelModel;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereLeColonneConISalti;
    [Test]
    procedure DovrebbeScambiareRossoEBluDeiColori;
    [Test]
    procedure DovrebbeRiconoscereSoloLEstensioneDdvox;
    [Test]
    procedure DovrebbeRifiutareUnLatoFuoriDa1A256;
    [Test]
    procedure DovrebbeRifiutareUnSaltoCheSuperaLaColonna;
    [Test]
    procedure DovrebbeCercareIlFileNelleCartelleDeiVoxel;
  end;

implementation

uses
  System.Classes, DelphiDoom.Voxel.Format.Ddvox;

function TTestVoxelDdvox.Decode(const AText: string): IVoxelModel;
begin
  Result := FFormat.Decode(TEncoding.ANSI.GetBytes(AText));
end;

procedure TTestVoxelDdvox.Setup;
begin
  FLog := TVoxelFakeLog.Create;
  FLogIntf := FLog;
  FFormat := TVoxelDdvoxFormat.Create(FLog);
end;

procedure TTestVoxelDdvox.DovrebbeLeggereLeColonneConISalti;
var
  LModel: IVoxelModel;
begin
  LModel := Decode('2'#13#10'skip 1 255'#13#10'1 2'#13#10'skip 2'#13#10'3 skip 1');
  Assert.AreEqual(2, LModel.SizeX);
  Assert.AreEqual(Cardinal(0), LModel.Cell(0, 0, 0));
  Assert.AreNotEqual(Cardinal(0), LModel.Cell(0, 0, 1));
  Assert.AreNotEqual(Cardinal(0), LModel.Cell(0, 1, 0));
  Assert.AreNotEqual(Cardinal(0), LModel.Cell(0, 1, 1));
  Assert.AreEqual(Cardinal(0), LModel.Cell(1, 0, 0));
  Assert.AreEqual(Cardinal(0), LModel.Cell(1, 0, 1));
  Assert.AreNotEqual(Cardinal(0), LModel.Cell(1, 1, 0));
  Assert.AreEqual(Cardinal(0), LModel.Cell(1, 1, 1));
end;

procedure TTestVoxelDdvox.DovrebbeScambiareRossoEBluDeiColori;
var
  LModel: IVoxelModel;
begin
  LModel := Decode('1 ' + IntToStr($112233));
  Assert.AreEqual(Cardinal($332211), LModel.Cell(0, 0, 0));
end;

procedure TTestVoxelDdvox.DovrebbeRiconoscereSoloLEstensioneDdvox;
begin
  Assert.IsTrue(FFormat.Handles('.DDVOX'));
  Assert.IsFalse(FFormat.Handles('.KVX'));
  Assert.IsFalse(FFormat.Handles(''));
end;

procedure TTestVoxelDdvox.DovrebbeRifiutareUnLatoFuoriDa1A256;
begin
  Assert.WillRaise(
    procedure
    begin
      Decode('0');
    end, EVoxelException);
  Assert.WillRaise(
    procedure
    begin
      Decode('257');
    end, EVoxelException);
  Assert.WillRaise(
    procedure
    begin
      Decode('');
    end, EVoxelException);
end;

procedure TTestVoxelDdvox.DovrebbeRifiutareUnSaltoCheSuperaLaColonna;
begin
  // the old loader went on writing out of the column
  Assert.WillRaise(
    procedure
    begin
      Decode('2 skip 3');
    end, EVoxelException);
end;

procedure TTestVoxelDdvox.DovrebbeCercareIlFileNelleCartelleDeiVoxel;
var
  LSource: TVoxelFakeSource;
  LSourceIntf: IVoxelFileSource;
  LBytes: TBytes;
begin
  LSource := TVoxelFakeSource.Create;
  LSourceIntf := LSource;
  Assert.IsFalse(FFormat.Locate(LSourceIntf, 'a.ddvox', LBytes));
  Assert.AreEqual('file a.ddvox', LSource.Calls.Text.Trim);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelDdvox);

end.