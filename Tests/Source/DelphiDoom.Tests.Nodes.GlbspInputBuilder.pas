{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the WAD for the node builder       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.GlbspInputBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.GlbspInputBuilder, DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesGlbspInputBuilder = class(TObject)
  strict private
    FSource: TFakeLumpSource;
    FRef: INodesLumpSource;
    function Fill(ASize: Integer; AValue: Byte): TBytes;
    function Builder(AHexen: Boolean): INodesGlbspInputBuilder;
    procedure AddMap(AWithBehavior: Boolean);
    function Open(const ABytes: TBytes): TFakeLumpSource;
    function Header(const ABytes: TBytes): TNodesWadHeader;
    function Entry(const ABytes: TBytes; AIndex: Integer): TNodesWadEntry;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestUnaMappaSenzaBehaviorDovrebbeCopiareUndiciLump;
    [Test]
    procedure TestIDatiDelleMappeSenzaBehaviorNonDovrebberoCambiare;
    [Test]
    procedure TestUnaMappaConBehaviorFuoriDaHexenDovrebbeAvereCoseELineeDiHexen;
    [Test]
    procedure TestUnaMappaConBehaviorFuoriDaHexenDovrebbeCopiareIlBehavior;
    [Test]
    procedure TestInHexenUnaMappaSenzaBehaviorDovrebbeAvereDodiciVociConBehaviorAssente;
    [Test]
    procedure TestInHexenUnaMappaConBehaviorNonDovrebbeConvertireNulla;
    [Test]
    procedure TestLaMappaAllaFineDelladirectoryDovrebbeAvereVociVuote;
    [Test]
    procedure TestSenzaNodiDovrebbeScrivereUndiciLumpInOrdine;
    [Test]
    procedure TestSenzaNodiIVertexesDovrebberoAvereLaLoroLunghezza;
    [Test]
    procedure TestSenzaNodiILumpMancantiDovrebberoEssereVuoti;
    [Test]
    procedure TestSenzaNodiIlNomeDellEtichettaDovrebbeEssereInMaiuscolo;
    [Test]
    procedure TestSenzaNodiInHexenDovrebbeScrivereIlBehavior;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

const
  NAMES: array[0..10] of string = ('MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS',
    'SSECTORS', 'NODES', 'SECTORS', 'REJECT', 'BLOCKMAP');

{ TTestNodesGlbspInputBuilder }

procedure TTestNodesGlbspInputBuilder.Setup;
begin
  FSource := TFakeLumpSource.Create;
  FRef := FSource;
end;

function TTestNodesGlbspInputBuilder.Builder(AHexen: Boolean): INodesGlbspInputBuilder;
begin
  Result := TNodesGlbspInputBuilder.Create(FRef, AHexen);
end;

function TTestNodesGlbspInputBuilder.Fill(ASize: Integer; AValue: Byte): TBytes;
begin
  SetLength(Result, ASize);
  if ASize > 0 then
    FillChar(Result[0], ASize, AValue);
end;

procedure TTestNodesGlbspInputBuilder.AddMap(AWithBehavior: Boolean);
var
  LIndex: Integer;
begin
  // THINGS 2 things, LINEDEFS 2 lines; the others of different sizes
  FSource.Add(NAMES[0]);
  FSource.Add(NAMES[1], Fill(20, 1));
  FSource.Add(NAMES[2], Fill(28, 2));
  for LIndex := 3 to 10 do
    FSource.Add(NAMES[LIndex], Fill(LIndex * 3, LIndex));
  if AWithBehavior then
    FSource.Add('BEHAVIOR', Fill(5, 99));
end;

function TTestNodesGlbspInputBuilder.Open(const ABytes: TBytes): TFakeLumpSource;
begin
  Result := TFakeLumpSource.Create;
  Result.AddWad(ABytes);
end;

function TTestNodesGlbspInputBuilder.Header(const ABytes: TBytes): TNodesWadHeader;
begin
  Move(ABytes[0], Result, SizeOf(Result));
end;

function TTestNodesGlbspInputBuilder.Entry(const ABytes: TBytes; AIndex: Integer): TNodesWadEntry;
begin
  Move(ABytes[Header(ABytes).DirectoryOffset + AIndex * 16], Result, 16);
end;

procedure TTestNodesGlbspInputBuilder.TestUnaMappaSenzaBehaviorDovrebbeCopiareUndiciLump;
var
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
  LIndex: Integer;
begin
  AddMap(False);
  LBytes := Builder(False).BuildForMap(0);
  Assert.AreEqual(11, Header(LBytes).LumpCount);
  LWad := Open(LBytes);
  LRef := LWad;
  for LIndex := 0 to 10 do
    Assert.AreEqual(NAMES[LIndex], LWad.LumpName(LIndex));
end;

procedure TTestNodesGlbspInputBuilder.TestIDatiDelleMappeSenzaBehaviorNonDovrebberoCambiare;
var
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
  LIndex: Integer;
begin
  AddMap(False);
  LBytes := Builder(False).BuildForMap(0);
  LWad := Open(LBytes);
  LRef := LWad;
  for LIndex := 0 to 10 do
    Assert.AreEqual(TNodesTestData.Fingerprint(FSource.ReadLump(LIndex)),
      TNodesTestData.Fingerprint(LWad.ReadLump(LIndex)), NAMES[LIndex]);
end;

procedure TTestNodesGlbspInputBuilder.TestUnaMappaConBehaviorFuoriDaHexenDovrebbeAvereCoseELineeDiHexen;
var
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  AddMap(True);
  LBytes := Builder(False).BuildForMap(0);
  Assert.AreEqual(12, Header(LBytes).LumpCount);
  LWad := Open(LBytes);
  LRef := LWad;
  // 2 cose da 10 byte diventano 2 da 20, 2 linee da 14 diventano 2 da 16
  Assert.AreEqual(40, LWad.LumpLength(1));
  Assert.AreEqual(32, LWad.LumpLength(2));
  Assert.AreEqual(Integer(Length(FSource.ReadLump(3))), LWad.LumpLength(3));
end;

procedure TTestNodesGlbspInputBuilder.TestUnaMappaConBehaviorFuoriDaHexenDovrebbeCopiareIlBehavior;
var
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  AddMap(True);
  LBytes := Builder(False).BuildForMap(0);
  LWad := Open(LBytes);
  LRef := LWad;
  Assert.AreEqual('BEHAVIOR', LWad.LumpName(11));
  Assert.AreEqual(5, LWad.LumpLength(11));
  Assert.AreEqual(Byte(99), LWad.ReadLump(11)[0]);
end;

procedure TTestNodesGlbspInputBuilder.TestInHexenUnaMappaSenzaBehaviorDovrebbeAvereDodiciVociConBehaviorAssente;
var
  LBytes: TBytes;
  LEntry: TNodesWadEntry;
begin
  AddMap(False);
  LBytes := Builder(True).BuildForMap(0);
  Assert.AreEqual(12, Header(LBytes).LumpCount);
  LEntry := Entry(LBytes, 11);
  Assert.AreEqual(0, LEntry.Position);
  Assert.AreEqual(0, LEntry.Size);
  Assert.AreEqual('BEHAVIOR', string(AnsiString(PAnsiChar(@LEntry.Name[0]))).Substring(0, 8));
end;

procedure TTestNodesGlbspInputBuilder.TestInHexenUnaMappaConBehaviorNonDovrebbeConvertireNulla;
var
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  AddMap(True);
  LBytes := Builder(True).BuildForMap(0);
  LWad := Open(LBytes);
  LRef := LWad;
  Assert.AreEqual(20, LWad.LumpLength(1));
  Assert.AreEqual(28, LWad.LumpLength(2));
  Assert.AreEqual(5, LWad.LumpLength(11));
end;

procedure TTestNodesGlbspInputBuilder.TestLaMappaAllaFineDelladirectoryDovrebbeAvereVociVuote;
var
  LBytes: TBytes;
  LEntry: TNodesWadEntry;
begin
  // etichetta e solo tre lump: il resto delle undici voci e' vuoto
  FSource.Add('MAP01');
  FSource.Add('THINGS', Fill(10, 1));
  FSource.Add('LINEDEFS', Fill(14, 2));
  LBytes := Builder(False).BuildForMap(0);
  Assert.AreEqual(11, Header(LBytes).LumpCount);
  LEntry := Entry(LBytes, 2);
  Assert.AreEqual(14, LEntry.Size);
  LEntry := Entry(LBytes, 5);
  Assert.AreEqual(0, LEntry.Size);
  Assert.AreEqual(0, LEntry.Position);
  Assert.AreEqual(0, Integer(Ord(LEntry.Name[0])));
end;

procedure TTestNodesGlbspInputBuilder.TestSenzaNodiDovrebbeScrivereUndiciLumpInOrdine;
var
  LLayout: TNodesMapLayout;
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
  LIndex: Integer;
begin
  FSource.Add('map01');
  FSource.Add('THINGS', Fill(10, 1));
  FSource.Add('LINEDEFS', Fill(14, 2));
  FSource.Add('SIDEDEFS', Fill(30, 3));
  FSource.Add('VERTEXES', Fill(8, 4));
  FSource.Add('SECTORS', Fill(26, 5));
  LLayout := TNodesMapLayout.Missing;
  LLayout.Things := 1;
  LLayout.Linedefs := 2;
  LLayout.Sidedefs := 3;
  LLayout.Vertexes := 4;
  LLayout.Sectors := 5;
  LBytes := Builder(False).BuildForMapWithoutNodes(0, LLayout);
  Assert.AreEqual(11, Header(LBytes).LumpCount);
  LWad := Open(LBytes);
  LRef := LWad;
  for LIndex := 0 to 10 do
    Assert.AreEqual(NAMES[LIndex], LWad.LumpName(LIndex));
  Assert.AreEqual(10, LWad.LumpLength(1));
  Assert.AreEqual(26, LWad.LumpLength(8));
  Assert.AreEqual(0, LWad.LumpLength(5));
  Assert.AreEqual(0, LWad.LumpLength(10));
end;

procedure TTestNodesGlbspInputBuilder.TestSenzaNodiIVertexesDovrebberoAvereLaLoroLunghezza;
var
  LLayout: TNodesMapLayout;
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  // regressione: il vecchio codice usava la lunghezza di SIDEDEFS per VERTEXES (e scriveva
  // byte a caso quando i lati sono piu' dei vertici)
  FSource.Add('MAP01');
  FSource.Add('THINGS', Fill(10, 1));
  FSource.Add('LINEDEFS', Fill(14, 2));
  FSource.Add('SIDEDEFS', Fill(300, 3));
  FSource.Add('VERTEXES', Fill(8, 4));
  FSource.Add('SECTORS', Fill(26, 5));
  LLayout := TNodesMapLayout.Missing;
  LLayout.Things := 1;
  LLayout.Linedefs := 2;
  LLayout.Sidedefs := 3;
  LLayout.Vertexes := 4;
  LLayout.Sectors := 5;
  LBytes := Builder(False).BuildForMapWithoutNodes(0, LLayout);
  LWad := Open(LBytes);
  LRef := LWad;
  Assert.AreEqual(8, LWad.LumpLength(4));
  Assert.AreEqual(Byte(4), LWad.ReadLump(4)[7]);
  Assert.AreEqual(300, LWad.LumpLength(3));
end;

procedure TTestNodesGlbspInputBuilder.TestSenzaNodiILumpMancantiDovrebberoEssereVuoti;
var
  LLayout: TNodesMapLayout;
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  FSource.Add('MAP01');
  LLayout := TNodesMapLayout.Missing;
  LBytes := Builder(False).BuildForMapWithoutNodes(0, LLayout);
  LWad := Open(LBytes);
  LRef := LWad;
  Assert.AreEqual(11, LWad.GetLumpCount);
  Assert.AreEqual(0, LWad.LumpLength(1));
  Assert.AreEqual(0, LWad.LumpLength(8));
end;

procedure TTestNodesGlbspInputBuilder.TestSenzaNodiIlNomeDellEtichettaDovrebbeEssereInMaiuscolo;
var
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  FSource.Add('map01');
  LBytes := Builder(False).BuildForMapWithoutNodes(0,
    TNodesMapLayout.Missing);
  LWad := Open(LBytes);
  LRef := LWad;
  Assert.AreEqual('MAP01', LWad.LumpName(0));
end;

procedure TTestNodesGlbspInputBuilder.TestSenzaNodiInHexenDovrebbeScrivereIlBehavior;
var
  LLayout: TNodesMapLayout;
  LBytes: TBytes;
  LWad: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  FSource.Add('MAP01');
  FSource.Add('BEHAVIOR', Fill(7, 8));
  LLayout := TNodesMapLayout.Missing;
  LLayout.Behavior := 1;
  LBytes := Builder(True).BuildForMapWithoutNodes(0, LLayout);
  Assert.AreEqual(12, Header(LBytes).LumpCount);
  LWad := Open(LBytes);
  LRef := LWad;
  Assert.AreEqual('BEHAVIOR', LWad.LumpName(11));
  Assert.AreEqual(7, LWad.LumpLength(11));
end;

procedure TTestNodesGlbspInputBuilder.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TNodesGlbspInputBuilder.Create(nil, False);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesGlbspInputBuilder);

end.
