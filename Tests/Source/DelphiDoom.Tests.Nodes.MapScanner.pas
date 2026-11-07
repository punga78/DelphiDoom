{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the lumps of a map                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.MapScanner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.MapScanner, DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesMapScanner = class(TObject)
  strict private
    FSource: TFakeLumpSource;
    FRef: INodesLumpSource;
    procedure AddAll;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestUnaMappaCompletaDovrebbeEssereCompleta;
    [Test]
    procedure TestUnaMappaSenzaNodiDovrebbeDareMenoUnoAiLumpMancanti;
    [Test]
    procedure TestIlComplessoDelleMappeInOrdineDiversoNonDovrebbeEssereCompleto;
    [Test]
    procedure TestInHexenDovrebbeCercareAncheIlBehavior;
    [Test]
    procedure TestNonInHexenIlBehaviorNonDovrebbeEssereCercato;
    [Test]
    procedure TestUnLumpRipetutoDovrebbeTenereLaPrimaPosizione;
    [Test]
    procedure TestIlNomeNonDovrebbeDistinguereLeMaiuscole;
    [Test]
    procedure TestVicinoAllaFineDelladirectoryDovrebbeCercareSoloLeCinquePrime;
    [Test]
    procedure TestTroppoVicinoAllaFineNonDovrebbeTrovareNulla;
    [Test]
    procedure TestNonDovrebbeLeggereOltreLaFineDellaDirectory;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

{ TTestNodesMapScanner }

procedure TTestNodesMapScanner.Setup;
begin
  FSource := TFakeLumpSource.Create;
  FRef := FSource;
end;

procedure TTestNodesMapScanner.AddAll;
var
  LName: string;
begin
  FSource.Add('MAP01');
  for LName in ['THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS', 'SSECTORS', 'NODES',
    'SECTORS', 'REJECT', 'BLOCKMAP'] do
    FSource.Add(LName);
end;

procedure TTestNodesMapScanner.TestUnaMappaCompletaDovrebbeEssereCompleta;
var
  LLayout: TNodesMapLayout;
begin
  AddAll;
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.IsTrue(LLayout.IsComplete(False));
  Assert.AreEqual(4, LLayout.Vertexes);
  Assert.AreEqual(10, LLayout.Blockmap);
  Assert.AreEqual(-1, LLayout.Behavior);
end;

procedure TTestNodesMapScanner.TestUnaMappaSenzaNodiDovrebbeDareMenoUnoAiLumpMancanti;
var
  LLayout: TNodesMapLayout;
  LName: string;
begin
  FSource.Add('MAP01');
  for LName in ['THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SECTORS'] do
    FSource.Add(LName);
  FSource.Add('MAP02');
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.IsFalse(LLayout.IsComplete(False));
  Assert.AreEqual(1, LLayout.Things);
  Assert.AreEqual(5, LLayout.Sectors);
  Assert.AreEqual(-1, LLayout.Segs);
  Assert.AreEqual(-1, LLayout.Nodes);
  Assert.IsTrue(LLayout.CanBuildNodes);
end;

procedure TTestNodesMapScanner.TestIlComplessoDelleMappeInOrdineDiversoNonDovrebbeEssereCompleto;
var
  LName: string;
  LLayout: TNodesMapLayout;
begin
  FSource.Add('MAP01');
  for LName in ['THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS', 'SSECTORS', 'NODES',
    'REJECT', 'SECTORS', 'BLOCKMAP'] do
    FSource.Add(LName);
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.IsFalse(LLayout.IsComplete(False));
  Assert.IsTrue(LLayout.CanBuildNodes);
end;

procedure TTestNodesMapScanner.TestInHexenDovrebbeCercareAncheIlBehavior;
var
  LLayout: TNodesMapLayout;
begin
  AddAll;
  FSource.Add('BEHAVIOR');
  LLayout := TNodesMapScanner.Scan(FRef, 0, True);
  Assert.AreEqual(11, LLayout.Behavior);
  Assert.IsTrue(LLayout.IsComplete(True));
end;

procedure TTestNodesMapScanner.TestNonInHexenIlBehaviorNonDovrebbeEssereCercato;
var
  LLayout: TNodesMapLayout;
begin
  AddAll;
  FSource.Add('BEHAVIOR');
  FSource.Add('X');
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  // si guardano solo dieci lump
  Assert.AreEqual(-1, LLayout.Behavior);
end;

procedure TTestNodesMapScanner.TestUnLumpRipetutoDovrebbeTenereLaPrimaPosizione;
var
  LLayout: TNodesMapLayout;
begin
  FSource.Add('MAP01');
  FSource.Add('THINGS');
  FSource.Add('THINGS');
  FSource.Add('LINEDEFS');
  FSource.Add('X1');
  FSource.Add('X2');
  FSource.Add('X3');
  FSource.Add('X4');
  FSource.Add('X5');
  FSource.Add('X6');
  FSource.Add('X7');
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.AreEqual(1, LLayout.Things);
  Assert.AreEqual(3, LLayout.Linedefs);
end;

procedure TTestNodesMapScanner.TestIlNomeNonDovrebbeDistinguereLeMaiuscole;
var
  LLayout: TNodesMapLayout;
begin
  FSource.Add('MAP01');
  FSource.Add('things');
  FSource.Add('LineDefs');
  FSource.Add('a');
  FSource.Add('b');
  FSource.Add('c');
  FSource.Add('d');
  FSource.Add('e');
  FSource.Add('f');
  FSource.Add('g');
  FSource.Add('h');
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.AreEqual(1, LLayout.Things);
  Assert.AreEqual(2, LLayout.Linedefs);
end;

procedure TTestNodesMapScanner.TestVicinoAllaFineDelladirectoryDovrebbeCercareSoloLeCinquePrime;
var
  LName: string;
  LLayout: TNodesMapLayout;
begin
  // 6 lump dopo l'etichetta non bastano per una mappa intera: SEGS non si cerca
  FSource.Add('MAP01');
  for LName in ['THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SECTORS', 'SEGS'] do
    FSource.Add(LName);
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.AreEqual(1, LLayout.Things);
  Assert.AreEqual(5, LLayout.Sectors);
  Assert.AreEqual(-1, LLayout.Segs);
end;

procedure TTestNodesMapScanner.TestTroppoVicinoAllaFineNonDovrebbeTrovareNulla;
var
  LLayout: TNodesMapLayout;
begin
  FSource.Add('MAP01');
  FSource.Add('THINGS');
  FSource.Add('LINEDEFS');
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.AreEqual(-1, LLayout.Things);
  Assert.IsFalse(LLayout.CanBuildNodes);
end;

procedure TTestNodesMapScanner.TestNonDovrebbeLeggereOltreLaFineDellaDirectory;
var
  LLayout: TNodesMapLayout;
  LName: string;
begin
  // regressione: il vecchio codice leggeva il nome del lump dopo l'ultimo
  FSource.Add('MAP01');
  for LName in ['THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS', 'SSECTORS', 'NODES',
    'SECTORS', 'REJECT'] do
    FSource.Add(LName);
  LLayout := TNodesMapScanner.Scan(FRef, 0, False);
  Assert.AreEqual(9, LLayout.Reject);
  Assert.AreEqual(-1, LLayout.Blockmap);
end;

procedure TTestNodesMapScanner.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TNodesMapScanner.Scan(nil, 0, False);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesMapScanner);

end.
