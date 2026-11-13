{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - things and lines as Hexen records  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.HexenConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.HexenConverter;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesHexenConverter = class(TObject)
  public
    [Test]
    procedure TestLeCoseDovrebberoPassareAlFormatoHexen;
    [Test]
    procedure TestUnaCosaConTipoAltoNonDovrebbePerderBit;
    [Test]
    procedure TestLeLineeDovrebberoPassareAlFormatoHexen;
    [Test]
    procedure TestLoSpecialFuoriDaZeroDuecentocinquantacinqueDovrebbeDiventareZero;
    [Test]
    procedure TestUnaLineaConUnSoloLatoDovrebbeConservareMenoUno;
    [Test]
    procedure TestUnRecordParzialeDovrebbeEssereScartato;
    [Test]
    procedure TestUnLumpVuotoDovrebbeDareUnLumpVuoto;
  end;

implementation

{ TTestNodesHexenConverter }

procedure TTestNodesHexenConverter.TestLeCoseDovrebberoPassareAlFormatoHexen;
var
  LVanilla: array[0..1] of TNodesVanillaThing;
  LBytes: TBytes;
  LThings: array[0..1] of TNodesHexenThing;
begin
  LVanilla[0].X := -100;
  LVanilla[0].Y := 200;
  LVanilla[0].Angle := 90;
  LVanilla[0].ThingType := 3004;
  LVanilla[0].Options := 7;
  LVanilla[1].X := 1;
  LVanilla[1].Y := 2;
  LVanilla[1].Angle := 3;
  LVanilla[1].ThingType := 4;
  LVanilla[1].Options := 5;
  SetLength(LBytes, SizeOf(LVanilla));
  Move(LVanilla, LBytes[0], SizeOf(LVanilla));
  LBytes := TNodesHexenConverter.ConvertThings(LBytes);
  Assert.AreEqual<Integer>(2 * 20, Length(LBytes));
  Move(LBytes[0], LThings, SizeOf(LThings));
  Assert.AreEqual(SmallInt(0), LThings[0].Tid);
  Assert.AreEqual(SmallInt(-100), LThings[0].X);
  Assert.AreEqual(SmallInt(200), LThings[0].Y);
  Assert.AreEqual(SmallInt(0), LThings[0].Height);
  Assert.AreEqual(SmallInt(90), LThings[0].Angle);
  Assert.AreEqual(Word(3004), LThings[0].ThingType);
  Assert.AreEqual(SmallInt(7), LThings[0].Options);
  Assert.AreEqual(Byte(0), LThings[0].Special);
  Assert.AreEqual(Byte(0), LThings[0].Arguments[4]);
  Assert.AreEqual(SmallInt(5), LThings[1].Options);
  Assert.AreEqual(SmallInt(1), LThings[1].X);
end;

procedure TTestNodesHexenConverter.TestUnaCosaConTipoAltoNonDovrebbePerderBit;
var
  LVanilla: TNodesVanillaThing;
  LBytes: TBytes;
  LThing: TNodesHexenThing;
begin
  FillChar(LVanilla, SizeOf(LVanilla), 0);
  LVanilla.ThingType := 65000;
  SetLength(LBytes, SizeOf(LVanilla));
  Move(LVanilla, LBytes[0], SizeOf(LVanilla));
  Move(TNodesHexenConverter.ConvertThings(LBytes)[0], LThing, SizeOf(LThing));
  Assert.AreEqual(Word(65000), LThing.ThingType);
end;

procedure TTestNodesHexenConverter.TestLeLineeDovrebberoPassareAlFormatoHexen;
var
  LVanilla: TNodesVanillaLinedef;
  LBytes: TBytes;
  LLine: TNodesHexenLinedef;
begin
  LVanilla.Vertex1 := 10;
  LVanilla.Vertex2 := 11;
  LVanilla.Flags := 4;
  LVanilla.Special := 117;
  LVanilla.Tag := 99;
  LVanilla.SideNumber[0] := 5;
  LVanilla.SideNumber[1] := 6;
  SetLength(LBytes, SizeOf(LVanilla));
  Move(LVanilla, LBytes[0], SizeOf(LVanilla));
  LBytes := TNodesHexenConverter.ConvertLinedefs(LBytes);
  Assert.AreEqual<Integer>(16, Length(LBytes));
  Move(LBytes[0], LLine, SizeOf(LLine));
  Assert.AreEqual(SmallInt(10), LLine.Vertex1);
  Assert.AreEqual(SmallInt(11), LLine.Vertex2);
  Assert.AreEqual(SmallInt(4), LLine.Flags);
  Assert.AreEqual(Byte(117), LLine.Special);
  // il tag di Doom non diventa un argomento
  Assert.AreEqual(Byte(0), LLine.Arguments[0]);
  Assert.AreEqual(SmallInt(5), LLine.SideNumber[0]);
  Assert.AreEqual(SmallInt(6), LLine.SideNumber[1]);
end;

procedure TTestNodesHexenConverter.TestLoSpecialFuoriDaZeroDuecentocinquantacinqueDovrebbeDiventareZero;
var
  LVanilla: array[0..3] of TNodesVanillaLinedef;
  LBytes: TBytes;
  LLines: array[0..3] of TNodesHexenLinedef;
  LIndex: Integer;
begin
  FillChar(LVanilla, SizeOf(LVanilla), 0);
  LVanilla[0].Special := 255;
  LVanilla[1].Special := 256;
  LVanilla[2].Special := -1;
  LVanilla[3].Special := 0;
  SetLength(LBytes, SizeOf(LVanilla));
  Move(LVanilla, LBytes[0], SizeOf(LVanilla));
  LBytes := TNodesHexenConverter.ConvertLinedefs(LBytes);
  Move(LBytes[0], LLines, SizeOf(LLines));
  Assert.AreEqual(Byte(255), LLines[0].Special);
  for LIndex := 1 to 3 do
    Assert.AreEqual(Byte(0), LLines[LIndex].Special);
end;

procedure TTestNodesHexenConverter.TestUnaLineaConUnSoloLatoDovrebbeConservareMenoUno;
var
  LVanilla: TNodesVanillaLinedef;
  LBytes: TBytes;
  LLine: TNodesHexenLinedef;
begin
  FillChar(LVanilla, SizeOf(LVanilla), 0);
  LVanilla.SideNumber[0] := 0;
  LVanilla.SideNumber[1] := -1;
  SetLength(LBytes, SizeOf(LVanilla));
  Move(LVanilla, LBytes[0], SizeOf(LVanilla));
  Move(TNodesHexenConverter.ConvertLinedefs(LBytes)[0], LLine, SizeOf(LLine));
  Assert.AreEqual(SmallInt(-1), LLine.SideNumber[1]);
end;

procedure TTestNodesHexenConverter.TestUnRecordParzialeDovrebbeEssereScartato;
begin
  Assert.AreEqual<Integer>(20, Length(TNodesHexenConverter.ConvertThings(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8,
    9, 10, 11, 12))));
  Assert.AreEqual<Integer>(0, Length(TNodesHexenConverter.ConvertLinedefs(TBytes.Create(1, 2, 3))));
end;

procedure TTestNodesHexenConverter.TestUnLumpVuotoDovrebbeDareUnLumpVuoto;
begin
  Assert.AreEqual<Integer>(0, Length(TNodesHexenConverter.ConvertThings(nil)));
  Assert.AreEqual<Integer>(0, Length(TNodesHexenConverter.ConvertLinedefs(nil)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesHexenConverter);

end.
