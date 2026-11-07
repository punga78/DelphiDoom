{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the cursor over the bytes
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.ByteReader;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.ByteReader;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelByteReader = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereNumeriLittleEndian;
    [Test]
    procedure DovrebbeLeggereUnIntegerNegativo;
    [Test]
    procedure DovrebbeDareEccezioneSeLaLetturaVaOltreLaFine;
    [Test]
    procedure DovrebbeDireQuantiByteRestano;
  end;

implementation

uses
  DelphiDoom.Voxel.Types;

procedure TTestVoxelByteReader.DovrebbeLeggereNumeriLittleEndian;
var
  LReader: TVoxelByteReader;
begin
  LReader := TVoxelByteReader.Create(TBytes.Create($01, $02, $03, $04, $05, $06, $07));
  try
    Assert.AreEqual(Cardinal($04030201), LReader.ReadCardinal);
    Assert.AreEqual(Word($0605), LReader.ReadWord);
    Assert.AreEqual(Byte($07), LReader.ReadByte);
    Assert.AreEqual(7, LReader.Position);
  finally
    LReader.Free;
  end;
end;

procedure TTestVoxelByteReader.DovrebbeLeggereUnIntegerNegativo;
var
  LReader: TVoxelByteReader;
begin
  LReader := TVoxelByteReader.Create(TBytes.Create($FE, $FF, $FF, $FF));
  try
    Assert.AreEqual(-2, LReader.ReadInteger);
  finally
    LReader.Free;
  end;
end;

procedure TTestVoxelByteReader.DovrebbeDareEccezioneSeLaLetturaVaOltreLaFine;
var
  LReader: TVoxelByteReader;
begin
  LReader := TVoxelByteReader.Create(TBytes.Create(1, 2, 3));
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadInteger;
      end, EVoxelException);
    LReader.Seek(3);
    Assert.WillRaise(
      procedure
      begin
        LReader.ReadByte;
      end, EVoxelException);
  finally
    LReader.Free;
  end;
end;

procedure TTestVoxelByteReader.DovrebbeDireQuantiByteRestano;
var
  LReader: TVoxelByteReader;
begin
  LReader := TVoxelByteReader.Create(TBytes.Create(1, 2, 3, 4, 5));
  try
    LReader.ReadWord;
    Assert.AreEqual(3, LReader.Remaining);
  finally
    LReader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelByteReader);

end.