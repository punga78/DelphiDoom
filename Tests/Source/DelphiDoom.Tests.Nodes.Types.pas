{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - records and layout                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.Types;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Nodes.Types;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesTypes = class(TObject)
  public
    [Test]
    procedure TestIRecordDelleLumpDovrebberoAvereLeDimensioniDelFormato;
    [Test]
    procedure TestUnLayoutMancanteNonDovrebbeEssereCompletoNePoterCostruireINodi;
    [Test]
    procedure TestUnLayoutInOrdineDovrebbeEssereCompleto;
    [Test]
    procedure TestInHexenServeAncheIlBehavior;
    [Test]
    procedure TestIRecordDiUnaMappaConUnLumpFuoriPostoNonDovrebbeEssereCompleto;
    [Test]
    procedure TestServonoCosePareteLineeLatiVerticiESettoriPerCostruireINodi;
  end;

implementation

function InOrder: TNodesMapLayout;
begin
  Result.Things := NODES_MAP_THINGS;
  Result.Linedefs := NODES_MAP_LINEDEFS;
  Result.Sidedefs := NODES_MAP_SIDEDEFS;
  Result.Vertexes := NODES_MAP_VERTEXES;
  Result.Segs := NODES_MAP_SEGS;
  Result.Subsectors := NODES_MAP_SSECTORS;
  Result.Nodes := NODES_MAP_NODES;
  Result.Sectors := NODES_MAP_SECTORS;
  Result.Reject := NODES_MAP_REJECT;
  Result.Blockmap := NODES_MAP_BLOCKMAP;
  Result.Behavior := -1;
end;

{ TTestNodesTypes }

procedure TTestNodesTypes.TestIRecordDelleLumpDovrebberoAvereLeDimensioniDelFormato;
begin
  Assert.AreEqual(4, SizeOf(TNodesGlVertex1));
  Assert.AreEqual(8, SizeOf(TNodesGlVertex));
  Assert.AreEqual(10, SizeOf(TNodesGlSeg1));
  Assert.AreEqual(16, SizeOf(TNodesGlSeg));
  Assert.AreEqual(4, SizeOf(TNodesGlSubsector1));
  Assert.AreEqual(8, SizeOf(TNodesGlSubsector));
  Assert.AreEqual(28, SizeOf(TNodesGlNode1));
  Assert.AreEqual(32, SizeOf(TNodesGlNode));
  Assert.AreEqual(12, SizeOf(TNodesWadHeader));
  Assert.AreEqual(16, SizeOf(TNodesWadEntry));
  Assert.AreEqual(10, SizeOf(TNodesVanillaThing));
  Assert.AreEqual(20, SizeOf(TNodesHexenThing));
  Assert.AreEqual(14, SizeOf(TNodesVanillaLinedef));
  Assert.AreEqual(16, SizeOf(TNodesHexenLinedef));
  Assert.AreEqual(12, SizeOf(TNodesVanillaSeg));
  Assert.AreEqual(4, SizeOf(TNodesVanillaSubsector));
  Assert.AreEqual(28, SizeOf(TNodesVanillaNode));
end;

procedure TTestNodesTypes.TestUnLayoutMancanteNonDovrebbeEssereCompletoNePoterCostruireINodi;
var
  LLayout: TNodesMapLayout;
begin
  LLayout := TNodesMapLayout.Missing;
  Assert.IsFalse(LLayout.IsComplete(False));
  Assert.IsFalse(LLayout.CanBuildNodes);
end;

procedure TTestNodesTypes.TestUnLayoutInOrdineDovrebbeEssereCompleto;
begin
  Assert.IsTrue(InOrder.IsComplete(False));
  Assert.IsTrue(InOrder.CanBuildNodes);
end;

procedure TTestNodesTypes.TestInHexenServeAncheIlBehavior;
var
  LLayout: TNodesMapLayout;
begin
  LLayout := InOrder;
  Assert.IsFalse(LLayout.IsComplete(True));
  LLayout.Behavior := NODES_MAP_BEHAVIOR;
  Assert.IsTrue(LLayout.IsComplete(True));
end;

procedure TTestNodesTypes.TestIRecordDiUnaMappaConUnLumpFuoriPostoNonDovrebbeEssereCompleto;
var
  LLayout: TNodesMapLayout;
begin
  LLayout := InOrder;
  LLayout.Segs := 6;
  Assert.IsFalse(LLayout.IsComplete(False));
end;

procedure TTestNodesTypes.TestServonoCosePareteLineeLatiVerticiESettoriPerCostruireINodi;
var
  LLayout: TNodesMapLayout;
begin
  LLayout := InOrder;
  LLayout.Sectors := -1;
  Assert.IsFalse(LLayout.CanBuildNodes);
  LLayout := InOrder;
  LLayout.Things := -1;
  Assert.IsFalse(LLayout.CanBuildNodes);
  // i lump che il costruttore fa da solo non servono
  LLayout := InOrder;
  LLayout.Segs := -1;
  LLayout.Nodes := -1;
  LLayout.Reject := -1;
  Assert.IsTrue(LLayout.CanBuildNodes);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesTypes);

end.
