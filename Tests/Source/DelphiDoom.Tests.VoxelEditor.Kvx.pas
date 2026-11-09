{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorKvxFormat (issue #167)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Kvx;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorKvxFormat = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
    FBytes: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFareUnCuboDelProssimoPesoDiDueRaddoppiatoSottoIl256;
    [Test]
    procedure DovrebbeMetterePiuVoxelDelleCelleVuote;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareLatiFuoriDaiLimiti;
    [Test]
    procedure DovrebbeRifiutareUnaColonnaFuoriDaiDati;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiByteChePassaIlFile;
    [Test]
    procedure DovrebbeRifiutareUnoSlabCheNonCabe;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Format.Kvx,
  DelphiDoom.Tests.VoxelEditor.Scenarios;

procedure TTestVoxelEditorKvxFormat.Setup;
begin
  FModel := TVoxelEditorModel.Create(1);
  FBytes := TVoxelScenarios.KvxBytes(0); // 10 x 12 x 14
end;

procedure TTestVoxelEditorKvxFormat.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorKvxFormat.DovrebbeFareUnCuboDelProssimoPesoDiDueRaddoppiatoSottoIl256;
begin
  TVoxelEditorKvxFormat.Read(FBytes, FModel);
  // 14 needs 16, and a cube under 256 is doubled
  Assert.AreEqual(32, FModel.Size);
  FBytes := TVoxelScenarios.KvxBytes(1);
  TVoxelEditorKvxFormat.Read(FBytes, FModel);
  Assert.AreEqual(32, FModel.Size);
end;

procedure TTestVoxelEditorKvxFormat.DovrebbeMetterePiuVoxelDelleCelleVuote;
begin
  TVoxelEditorKvxFormat.Read(FBytes, FModel);
  // 30% of 10 x 12 x 14
  Assert.IsTrue(FModel.CountVoxels > 300);
  Assert.IsTrue(FModel.CountVoxels < 700);
end;

procedure TTestVoxelEditorKvxFormat.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(nil, FModel); end, EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(Copy(FBytes, 0, 100), FModel); end, EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(Copy(FBytes, 0, 768 + 8), FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorKvxFormat.DovrebbeRifiutareLatiFuoriDaiLimiti;
begin
  PInteger(@FBytes[4])^ := 0;
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(FBytes, FModel); end, EVoxelEditorException);
  PInteger(@FBytes[4])^ := 10;
  PInteger(@FBytes[8])^ := 300;
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(FBytes, FModel); end, EVoxelEditorException);
  PInteger(@FBytes[8])^ := 12;
  PInteger(@FBytes[12])^ := -1;
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(FBytes, FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorKvxFormat.DovrebbeRifiutareUnaColonnaFuoriDaiDati;
var
  LOffset: Integer;
begin
  // the first table of the offsets of the columns follows the 11 integers and the x offsets
  LOffset := 28 + (10 + 1) * 4;
  PWord(@FBytes[LOffset + 4])^ := 65000;
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(FBytes, FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorKvxFormat.DovrebbeRifiutareUnNumeroDiByteChePassaIlFile;
begin
  PInteger(@FBytes[0])^ := PInteger(@FBytes[0])^ + 100000;
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(FBytes, FModel); end, EVoxelEditorException);
  PInteger(@FBytes[0])^ := 10;
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(FBytes, FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorKvxFormat.DovrebbeRifiutareUnoSlabCheNonCabe;
var
  LTiny: TBytes;
  LValues: array[0..9] of Integer;
  LIndex: Integer;
begin
  // a KVX of 1 x 1 x 1 whose only slab says that it has 200 colors, and has 1
  SetLength(LTiny, 4 * 10 + 4 + 4 + 768);
  FillChar(LTiny[0], Length(LTiny), 0);
  LValues[0] := 24 + 2 * 4 + 2 * 2 + 4; // numbytes
  LValues[1] := 1;
  LValues[2] := 1;
  LValues[3] := 1;
  LValues[4] := 0; // pivots
  LValues[5] := 0;
  LValues[6] := 0;
  LValues[7] := 0; // xoffset[0] and [1]
  LValues[8] := 4;
  LValues[9] := 0; // the two offsets of the column, as words: 0 and 4
  for LIndex := 0 to 9 do
    PInteger(@LTiny[LIndex * 4])^ := LValues[LIndex];
  PWord(@LTiny[36])^ := 0;
  PWord(@LTiny[38])^ := 4;
  LTiny[40] := 0; // ztop
  LTiny[41] := 200; // zleng
  Assert.WillRaise(procedure begin TVoxelEditorKvxFormat.Read(LTiny, FModel); end, EVoxelEditorException);
end;

end.
