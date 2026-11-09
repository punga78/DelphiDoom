{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .RMP files               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.RouteReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomRouteReader = class(TObject)
  private
    FReader: IXcomRouteReader;
    /// <summary>A record of the file: the position and the first byte of each of the five links</summary>
    function Node(AY, AX, AZ: Byte; const ALinks: array of Byte): TBytes;
    function Join(const AFirst, ASecond: TBytes): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIRecordDa24Byte;
    [Test]
    procedure DovrebbeLeggereLaPosizioneNellOrdineYXZ;
    [Test]
    procedure DovrebbeIgnorareIByteDiUnRecordIncompleto;
    [Test]
    procedure DovrebbeMettereIlNodoNellaMappaDellaBattaglia;
    [Test]
    procedure DovrebbeContareIlPianoDalPiuBasso;
    [Test]
    procedure DovrebbeSommareLOffsetDeiNodiAiCollegamenti;
    [Test]
    procedure DovrebbeTradurreLeDirezioni;
    [Test]
    procedure DovrebbeLasciareIlNumeroDuecentocinquantaComeUnNodo;
    [Test]
    procedure DovrebbeTenereUnNodoFuoriDalBloccoComeFinto;
    [Test]
    procedure DovrebbeTagliareIColleamentiAUnNodoFinto;
    [Test]
    procedure DovrebbeTenereITipiERangoDelNodo;
    [Test]
    procedure DovrebbeTrattareTuttoComeFintoSeIlBloccoEVuoto;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomRouteReader }

function TTestXcomRouteReader.Node(AY, AX, AZ: Byte; const ALinks: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  Result := TXcomTestBuilders.Zeros(XCOM_RMP_RECORD_BYTES);
  Result[0] := AY;
  Result[1] := AX;
  Result[2] := AZ;
  for LIndex := 0 to High(ALinks) do
    Result[4 + LIndex * 3] := ALinks[LIndex];
  Result[19] := 11;
  Result[20] := 12;
  Result[21] := 13;
  Result[22] := 14;
  Result[23] := 15;
end;

function TTestXcomRouteReader.Join(const AFirst, ASecond: TBytes): TBytes;
begin
  SetLength(Result, Length(AFirst) + Length(ASecond));
  Move(AFirst[0], Result[0], Length(AFirst));
  Move(ASecond[0], Result[Length(AFirst)], Length(ASecond));
end;

procedure TTestXcomRouteReader.Setup;
begin
  FReader := TXcomFactory.CreateRouteReader;
end;

procedure TTestXcomRouteReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestXcomRouteReader.DovrebbeLeggereIRecordDa24Byte;
var
  LRecords: TArray<TXcomRmpRecord>;
begin
  LRecords := FReader.Read(Join(Node(1, 2, 3, [4, 5, 6, 7, 8]), Node(0, 0, 0, [255, 255, 255, 255, 255])));
  Assert.AreEqual(2, Integer(Length(LRecords)));
  Assert.AreEqual(4, Integer(LRecords[0].Links[0].Target));
  Assert.AreEqual(8, Integer(LRecords[0].Links[4].Target));
  Assert.AreEqual(11, Integer(LRecords[0].NodeType));
  Assert.AreEqual(12, Integer(LRecords[0].Rank));
  Assert.AreEqual(13, Integer(LRecords[0].Flags));
  Assert.AreEqual(14, Integer(LRecords[0].Reserved));
  Assert.AreEqual(15, Integer(LRecords[0].Priority));
end;

procedure TTestXcomRouteReader.DovrebbeLeggereLaPosizioneNellOrdineYXZ;
var
  LRecords: TArray<TXcomRmpRecord>;
begin
  LRecords := FReader.Read(Node(1, 2, 3, []));
  Assert.AreEqual(1, Integer(LRecords[0].PosY));
  Assert.AreEqual(2, Integer(LRecords[0].PosX));
  Assert.AreEqual(3, Integer(LRecords[0].PosZ));
end;

procedure TTestXcomRouteReader.DovrebbeIgnorareIByteDiUnRecordIncompleto;
var
  LBytes: TBytes;
begin
  LBytes := Node(0, 0, 0, []);
  SetLength(LBytes, 30);
  Assert.AreEqual(1, Integer(Length(FReader.Read(LBytes))));
  Assert.AreEqual(0, Integer(Length(FReader.Read(nil))));
end;

procedure TTestXcomRouteReader.DovrebbeMettereIlNodoNellaMappaDellaBattaglia;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  LNodes := FReader.Resolve(FReader.Read(Node(1, 2, 0, [255, 255, 255, 255, 255])), 4, 3, 2, 10, 20, 0, LCulled);
  Assert.AreEqual(12, LNodes[0].X);
  Assert.AreEqual(21, LNodes[0].Y);
  Assert.IsFalse(LNodes[0].IsDummy);
  Assert.AreEqual(0, Integer(Length(LCulled)));
end;

procedure TTestXcomRouteReader.DovrebbeContareIlPianoDalPiuBasso;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  // the file counts the layers from the top: z 0 of a block of 3 layers is the layer 2
  LNodes := FReader.Resolve(FReader.Read(Join(Node(0, 0, 0, []), Node(0, 0, 2, []))), 1, 1, 3, 0, 0, 0, LCulled);
  Assert.AreEqual(2, LNodes[0].Z);
  Assert.AreEqual(0, LNodes[1].Z);
end;

procedure TTestXcomRouteReader.DovrebbeSommareLOffsetDeiNodiAiCollegamenti;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  LNodes := FReader.Resolve(FReader.Read(Join(Node(0, 0, 0, [1, 0, 255, 255, 255]), Node(0, 1, 0, [0, 255, 255, 255, 255]))),
    2, 1, 1, 0, 0, 7, LCulled);
  Assert.AreEqual(7, LNodes[0].Index);
  Assert.AreEqual(8, LNodes[1].Index);
  Assert.AreEqual(8, LNodes[0].Links[0]);
  Assert.AreEqual(7, LNodes[0].Links[1]);
  Assert.AreEqual(7, LNodes[1].Links[0]);
end;

procedure TTestXcomRouteReader.DovrebbeTradurreLeDirezioni;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  LNodes := FReader.Resolve(FReader.Read(Node(0, 0, 0, [255, 254, 253, 252, 251])), 1, 1, 1, 0, 0, 100, LCulled);
  Assert.AreEqual(XCOM_LINK_UNUSED, LNodes[0].Links[0]);
  Assert.AreEqual(XCOM_LINK_NORTH, LNodes[0].Links[1]);
  Assert.AreEqual(XCOM_LINK_EAST, LNodes[0].Links[2]);
  Assert.AreEqual(XCOM_LINK_SOUTH, LNodes[0].Links[3]);
  Assert.AreEqual(XCOM_LINK_WEST, LNodes[0].Links[4]);
end;

procedure TTestXcomRouteReader.DovrebbeLasciareIlNumeroDuecentocinquantaComeUnNodo;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  LNodes := FReader.Resolve(FReader.Read(Node(0, 0, 0, [250, 251, 0, 0, 0])), 1, 1, 1, 0, 0, 3, LCulled);
  Assert.AreEqual(253, LNodes[0].Links[0]);
  Assert.AreEqual(XCOM_LINK_WEST, LNodes[0].Links[1]);
end;

procedure TTestXcomRouteReader.DovrebbeTenereUnNodoFuoriDalBloccoComeFinto;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  LNodes := FReader.Resolve(FReader.Read(Join(Node(0, 0, 0, []), Node(0, 9, 0, []))), 2, 2, 1, 0, 0, 0, LCulled);
  Assert.AreEqual(2, Integer(Length(LNodes)));
  Assert.IsFalse(LNodes[0].IsDummy);
  Assert.IsTrue(LNodes[1].IsDummy);
  Assert.AreEqual(1, Integer(Length(LCulled)));
  Assert.AreEqual(1, LCulled[0]);
  Assert.AreEqual(1, LNodes[1].Index, 'il numero resta, i collegamenti degli altri nodi restano giusti');
end;

procedure TTestXcomRouteReader.DovrebbeTagliareIColleamentiAUnNodoFinto;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  // the node 0 goes to the node 1 (outside the block) and to the node 2 (inside)
  LNodes := FReader.Resolve(FReader.Read(Join(Join(Node(0, 0, 0, [1, 2, 255, 255, 255]), Node(5, 5, 0, [])),
    Node(0, 1, 0, []))), 2, 1, 1, 0, 0, 4, LCulled);
  Assert.AreEqual(XCOM_LINK_UNUSED, LNodes[0].Links[0]);
  Assert.AreEqual(6, LNodes[0].Links[1]);
end;

procedure TTestXcomRouteReader.DovrebbeTenereITipiERangoDelNodo;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  LNodes := FReader.Resolve(FReader.Read(Node(0, 0, 0, [])), 1, 1, 1, 0, 0, 0, LCulled);
  Assert.AreEqual(11, LNodes[0].NodeType);
  Assert.AreEqual(12, LNodes[0].Rank);
  Assert.AreEqual(13, LNodes[0].Flags);
  Assert.AreEqual(14, LNodes[0].Reserved);
  Assert.AreEqual(15, LNodes[0].Priority);
end;

procedure TTestXcomRouteReader.DovrebbeTrattareTuttoComeFintoSeIlBloccoEVuoto;
var
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
begin
  LNodes := FReader.Resolve(FReader.Read(Node(0, 0, 0, [])), 0, 0, 0, 0, 0, 0, LCulled);
  Assert.IsTrue(LNodes[0].IsDummy);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRouteReader);

end.
