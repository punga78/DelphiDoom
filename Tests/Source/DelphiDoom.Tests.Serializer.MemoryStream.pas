{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the serializer library - the stream on memory          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.MemoryStream;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('serializer')]
  TTestSerializerMemoryStream = class(TObject)
  public
    [Test]
    procedure DovrebbeScrivereEleggereNellaMemoriaDelChiamante;
    [Test]
    procedure DovrebbeScrivereSoloQuelloCheEntraEDareIlConteggioMinore;
    [Test]
    procedure DovrebbeDareEccezioneConWriteBufferOltreLaFine;
    [Test]
    procedure DovrebbeLeggereSoloFinoAllaFine;
  end;

implementation

uses
  DelphiDoom.Serializer.MemoryStream;

{ TTestSerializerMemoryStream }

procedure TTestSerializerMemoryStream.DovrebbeScrivereEleggereNellaMemoriaDelChiamante;
var
  LMemory: array[0..7] of Byte;
  LStream: TSerializerMemoryStream;
  LValue: Cardinal;
begin
  FillChar(LMemory, SizeOf(LMemory), 0);
  LStream := TSerializerMemoryStream.Create(@LMemory, SizeOf(LMemory));
  try
    LValue := $04030201;
    LStream.WriteBuffer(LValue, 4);
    Assert.AreEqual<Int64>(4, LStream.Position);
    LStream.Position := 0;
    LValue := 0;
    LStream.ReadBuffer(LValue, 4);
    Assert.AreEqual<Cardinal>($04030201, LValue);
  finally
    LStream.Free;
  end;
  Assert.AreEqual<Integer>(1, LMemory[0]);
  Assert.AreEqual<Integer>(4, LMemory[3]);
  Assert.AreEqual<Integer>(0, LMemory[4]);
end;

procedure TTestSerializerMemoryStream.DovrebbeScrivereSoloQuelloCheEntraEDareIlConteggioMinore;
var
  LMemory: array[0..3] of Byte;
  LStream: TSerializerMemoryStream;
  LData: array[0..5] of Byte;
begin
  FillChar(LData, SizeOf(LData), 7);
  LStream := TSerializerMemoryStream.Create(@LMemory, SizeOf(LMemory));
  try
    Assert.AreEqual(4, LStream.Write(LData, 6));
    Assert.AreEqual(0, LStream.Write(LData, 1));
  finally
    LStream.Free;
  end;
end;

procedure TTestSerializerMemoryStream.DovrebbeDareEccezioneConWriteBufferOltreLaFine;
var
  LMemory: array[0..3] of Byte;
  LStream: TSerializerMemoryStream;
begin
  LStream := TSerializerMemoryStream.Create(@LMemory, SizeOf(LMemory));
  try
    Assert.WillRaise(
      procedure
      var
        LData: array[0..4] of Byte;
      begin
        LStream.WriteBuffer(LData, 5);
      end, EWriteError);
  finally
    LStream.Free;
  end;
end;

procedure TTestSerializerMemoryStream.DovrebbeLeggereSoloFinoAllaFine;
var
  LMemory: array[0..3] of Byte;
  LStream: TSerializerMemoryStream;
  LData: array[0..7] of Byte;
begin
  FillChar(LMemory, SizeOf(LMemory), 9);
  LStream := TSerializerMemoryStream.Create(@LMemory, SizeOf(LMemory));
  try
    Assert.AreEqual(4, LStream.Read(LData, 8));
    Assert.AreEqual(0, LStream.Read(LData, 1));
  finally
    LStream.Free;
  end;
end;

end.
