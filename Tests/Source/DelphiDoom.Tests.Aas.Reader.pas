{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - records, header, byte order, reader  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Reader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasTypes = class
  public
    [Test]
    procedure IRecordDovrebberoAvereLeDimensioniDelC;
    [Test]
    procedure LeCostantiDovrebberoAvereIValoriDiAasfileH;
    [Test]
    procedure LEccezioneDovrebbeDareIlCodice;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasHeaderCipher = class
  public
    [Test]
    procedure DovrebbeLasciareIdentificatoreEVersione;
    [Test]
    procedure DovrebbeFareXorConIlByteIndiceper119;
    [Test]
    procedure DovrebbeEssereSuoInverso;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasByteSwapper = class
  public
    [Test]
    procedure DovrebbeInvertireIByteDiUnLong;
    [Test]
    procedure DovrebbeInvertireIByteDiUnShort;
    [Test]
    procedure DovrebbeInvertireOgniNumeroDiOgniLump;
    [Test]
    procedure DuePassateDovrebberoDareIlContenutoDiPartenza;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasReader = class
  public
    [Test]
    procedure DovrebbeLeggereLeQuattroVarianti;
    [Test]
    procedure DovrebbeDareLaStessaRappresentazioneDeiLump;
    [Test]
    procedure UnFileDellaVersioneQuattroNonDovrebbeAvereLIntestazioneCifrata;
    [Test]
    procedure UnIdentificatoreSbagliatoDovrebbeDareIlCodiceCinque;
    [Test]
    procedure UnFileCortoDovrebbeDareIlCodiceCinque;
    [Test]
    procedure UnaVersioneSbagliataDovrebbeDareIlCodiceSei;
    [Test]
    procedure UnChecksumDiversoDovrebbeDareIlCodiceSei;
    [Test]
    procedure UnLumpFuoriDalFileDovrebbeDareIlCodiceSette;
    [Test]
    procedure UnLumpConLunghezzaNegativaDovrebbeDareIlCodiceSette;
    [Test]
    procedure UnLumpNonSequenzialeDovrebbeDareUnAvviso;
    [Test]
    procedure UnFileMancanteDovrebbeDareIlCodiceQuattro;
    [Test]
    procedure LoadDovrebbeStampareIMessaggiDelC;
    [Test]
    procedure LoadSenzaVariabileDovrebbeConfrontareConZero;
    [Test]
    procedure IlChecksumDovrebbeSeguireAtoi;
    [Test]
    procedure ParseBytesDovrebbeSollevareEAasFileException;
    [Test]
    procedure UnaMacchinaBigEndianDovrebbeInvertireIByte;
    [Test]
    procedure UnaLunghezzaNonMultiplaDovrebbeIgnorareIlResto;
    [Test]
    procedure LeFabbricheDovrebberoDareGliOggetti;
  end;

implementation

uses
  System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Types,
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.ByteSwapper,
  DelphiDoom.Aas.Factory, DelphiDoom.Tests.Aas.Sample, DelphiDoom.Tests.Aas.Support;

{ TTestAasTypes }

procedure TTestAasTypes.IRecordDovrebberoAvereLeDimensioniDelC;
begin
  Assert.AreEqual<Integer>(124, SizeOf(TAasFileHeader));
  Assert.AreEqual<Integer>(8, SizeOf(TAasLump));
  Assert.AreEqual<Integer>(32, SizeOf(TAasBBox));
  Assert.AreEqual<Integer>(12, SizeOf(TVec3));
  Assert.AreEqual<Integer>(20, SizeOf(TAasPlane));
  Assert.AreEqual<Integer>(8, SizeOf(TAasEdge));
  Assert.AreEqual<Integer>(24, SizeOf(TAasFace));
  Assert.AreEqual<Integer>(48, SizeOf(TAasArea));
  Assert.AreEqual<Integer>(28, SizeOf(TAasAreaSettings));
  Assert.AreEqual<Integer>(44, SizeOf(TAasReachability));
  Assert.AreEqual<Integer>(12, SizeOf(TAasNode));
  Assert.AreEqual<Integer>(20, SizeOf(TAasPortal));
  Assert.AreEqual<Integer>(16, SizeOf(TAasCluster));
  Assert.AreEqual<Integer>(52, SizeOf(TAasAreaInfo));
end;

procedure TTestAasTypes.LeCostantiDovrebberoAvereIValoriDiAasfileH;
begin
  Assert.AreEqual<Integer>($53414145, AAS_ID);
  Assert.AreEqual<Integer>(4, AAS_VERSION_OLD);
  Assert.AreEqual<Integer>(5, AAS_VERSION);
  Assert.AreEqual<Integer>(14, AAS_LUMPS);
  Assert.AreEqual<Integer>(13, AASLUMP_CLUSTERS);
  Assert.AreEqual<Integer>($FFFFFF, TRAVELTYPE_MASK);
  Assert.AreEqual<Integer>(1 shl 24, TRAVELFLAG_NOTTEAM1);
  Assert.AreEqual<Integer>(2 shl 24, TRAVELFLAG_NOTTEAM2);
  Assert.AreEqual<Integer>(19, TRAVEL_FUNCBOB);
  Assert.AreEqual<Integer>(64, FACE_BRIDGE);
  Assert.AreEqual<Integer>(4096, AREACONTENTS_NOTTEAM2);
  Assert.AreEqual<Integer>(16, AREA_BRIDGE);
end;

procedure TTestAasTypes.LEccezioneDovrebbeDareIlCodice;
var
  LException: EAasFileException;
begin
  LException := EAasFileException.Create(BLERR_WRONGAASFILEID, 'x');
  try
    Assert.AreEqual<Integer>(5, LException.ErrorCode);
    Assert.AreEqual('x', LException.Message);
  finally
    LException.Free;
  end;
end;

{ TTestAasHeaderCipher }

procedure TTestAasHeaderCipher.DovrebbeLasciareIdentificatoreEVersione;
var
  LHeader: TAasFileHeader;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Ident := AAS_ID;
  LHeader.Version := AAS_VERSION;
  TAasHeaderCipher.Apply(LHeader);
  Assert.AreEqual<Integer>(AAS_ID, LHeader.Ident);
  Assert.AreEqual<Integer>(AAS_VERSION, LHeader.Version);
end;

procedure TTestAasHeaderCipher.DovrebbeFareXorConIlByteIndiceper119;
var
  LHeader: TAasFileHeader;
  LBytes: PByte;
  LIndex: Integer;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  TAasHeaderCipher.Apply(LHeader);
  LBytes := PByte(@LHeader) + 8;
  for LIndex := 0 to SizeOf(LHeader) - 9 do
    Assert.AreEqual<Integer>((LIndex and 255) * 119 and 255, LBytes[LIndex]);
  // the byte 3 of the data: 3 * 119 = 357 = 101 (mod 256); the byte 255 comes back to 0 after 256
  Assert.AreEqual<Integer>(101, LBytes[3]);
end;

procedure TTestAasHeaderCipher.DovrebbeEssereSuoInverso;
var
  LHeader, LCopy: TAasFileHeader;
  LIndex: Integer;
begin
  for LIndex := 0 to SizeOf(LHeader) - 1 do
    PByte(@LHeader)[LIndex] := Byte(LIndex * 7 + 3);
  LCopy := LHeader;
  TAasHeaderCipher.Apply(LHeader);
  Assert.IsFalse(CompareMem(@LHeader, @LCopy, SizeOf(LHeader)));
  TAasHeaderCipher.Apply(LHeader);
  Assert.IsTrue(CompareMem(@LHeader, @LCopy, SizeOf(LHeader)));
end;

{ TTestAasByteSwapper }

procedure TTestAasByteSwapper.DovrebbeInvertireIByteDiUnLong;
begin
  Assert.AreEqual<Cardinal>($78563412, TAasByteSwapper.SwapLong($12345678));
  Assert.AreEqual<Cardinal>($000000FF, TAasByteSwapper.SwapLong($FF000000));
end;

procedure TTestAasByteSwapper.DovrebbeInvertireIByteDiUnShort;
begin
  Assert.AreEqual<Integer>($3412, TAasByteSwapper.SwapShort($1234));
end;

procedure TTestAasByteSwapper.DovrebbeInvertireOgniNumeroDiOgniLump;
var
  LData: TAasFileData;
begin
  FillChar(LData, SizeOf(LData), 0);
  SetLength(LData.BBoxes, 1);
  LData.BBoxes[0].PresenceType := $01020304;
  LData.BBoxes[0].Maxs[2] := 0;
  SetLength(LData.Vertexes, 1);
  PCardinal(@LData.Vertexes[0][1])^ := $11223344;
  SetLength(LData.Planes, 1);
  LData.Planes[0].PlaneType := $01020304;
  SetLength(LData.Edges, 1);
  LData.Edges[0].Vertexes[1] := $01020304;
  SetLength(LData.EdgeIndex, 1);
  LData.EdgeIndex[0] := $01020304;
  SetLength(LData.Faces, 1);
  LData.Faces[0].BackArea := $01020304;
  SetLength(LData.FaceIndex, 1);
  LData.FaceIndex[0] := $01020304;
  SetLength(LData.Areas, 1);
  LData.Areas[0].AreaNum := $01020304;
  SetLength(LData.AreaSettings, 1);
  LData.AreaSettings[0].FirstReachableArea := $01020304;
  SetLength(LData.Reachability, 1);
  LData.Reachability[0].TravelType := $01020304;
  LData.Reachability[0].TravelTime := $0102;
  LData.Reachability[0].Padding := $AABB;
  SetLength(LData.Nodes, 1);
  LData.Nodes[0].Children[1] := $01020304;
  SetLength(LData.Portals, 1);
  LData.Portals[0].ClusterAreaNum[1] := $01020304;
  SetLength(LData.PortalIndex, 1);
  LData.PortalIndex[0] := $01020304;
  SetLength(LData.Clusters, 1);
  LData.Clusters[0].FirstPortal := $01020304;
  TAasByteSwapper.Swap(LData);
  Assert.AreEqual<Integer>($04030201, LData.BBoxes[0].PresenceType);
  Assert.AreEqual<Cardinal>($44332211, PCardinal(@LData.Vertexes[0][1])^);
  Assert.AreEqual<Integer>($04030201, LData.Planes[0].PlaneType);
  Assert.AreEqual<Integer>($04030201, LData.Edges[0].Vertexes[1]);
  Assert.AreEqual<Integer>($04030201, LData.EdgeIndex[0]);
  Assert.AreEqual<Integer>($04030201, LData.Faces[0].BackArea);
  Assert.AreEqual<Integer>($04030201, LData.FaceIndex[0]);
  Assert.AreEqual<Integer>($04030201, LData.Areas[0].AreaNum);
  Assert.AreEqual<Integer>($04030201, LData.AreaSettings[0].FirstReachableArea);
  Assert.AreEqual<Integer>($04030201, LData.Reachability[0].TravelType);
  Assert.AreEqual<Integer>($0201, LData.Reachability[0].TravelTime);
  // the padding is not a number of the format
  Assert.AreEqual<Integer>($AABB, LData.Reachability[0].Padding);
  Assert.AreEqual<Integer>($04030201, LData.Nodes[0].Children[1]);
  Assert.AreEqual<Integer>($04030201, LData.Portals[0].ClusterAreaNum[1]);
  Assert.AreEqual<Integer>($04030201, LData.PortalIndex[0]);
  Assert.AreEqual<Integer>($04030201, LData.Clusters[0].FirstPortal);
end;

procedure TTestAasByteSwapper.DuePassateDovrebberoDareIlContenutoDiPartenza;
var
  LData: TAasFileData;
  LCopy: TBytes;
  LBytes: TBytes;
  LFile: IAasFile;
begin
  LData := TAasSample.Content(1);
  LFile := nil;
  LCopy := TAasSample.Layout(LData, AAS_VERSION_OLD, 0);
  TAasByteSwapper.Swap(LData);
  TAasByteSwapper.Swap(LData);
  LBytes := TAasSample.Layout(LData, AAS_VERSION_OLD, 0);
  Assert.AreEqual<Integer>(Length(LCopy), Length(LBytes));
  Assert.IsTrue(CompareMem(@LCopy[0], @LBytes[0], Length(LCopy)));
end;

{ TTestAasReader }

procedure TTestAasReader.DovrebbeLeggereLeQuattroVarianti;
var
  LVariant: Integer;
  LFile: IAasFile;
  LReader: IAasReader;
begin
  for LVariant := 0 to 3 do
  begin
    LReader := TAasFactory.CreateReader(TFakeImport.Create, nil, nil);
    LFile := LReader.ParseBytes(TAasSample.Bytes(LVariant), 'x.aas', Integer(SAMPLE_CHECKSUM));
    Assert.AreEqual<Integer>(TAasSample.AreaCount(LVariant) + 1, Length(LFile.Areas), 'areas');
    Assert.AreEqual<Integer>(TAasSample.AreaCount(LVariant) + 1, Length(LFile.AreaSettings), 'settings');
    Assert.AreEqual<Integer>(2, Length(LFile.BBoxes));
    Assert.AreEqual<Integer>(Integer(SAMPLE_CHECKSUM), LFile.BspChecksum);
    Assert.AreEqual<Integer>(AAS_ID, LFile.Header.Ident);
  end;
end;

procedure TTestAasReader.DovrebbeDareLaStessaRappresentazioneDeiLump;
var
  LContent: TAasFileData;
  LFile: IAasFile;
  LIndex: Integer;
  LExpected: TBytes;
begin
  LContent := TAasSample.Content(0);
  LFile := TAasFactory.CreateReader(nil, nil, nil).ParseBytes(TAasSample.Bytes(0), 'x', Integer(SAMPLE_CHECKSUM));
  Assert.AreEqual<Integer>(Length(LContent.Nodes), Length(LFile.Nodes));
  Assert.AreEqual<Integer>(LContent.Nodes[5].Children[0], LFile.Nodes[5].Children[0]);
  Assert.AreEqual<Integer>(Length(LContent.Reachability), Length(LFile.Reachability));
  Assert.AreEqual<Integer>(Integer(LContent.Reachability[3].TravelTime), Integer(LFile.Reachability[3].TravelTime));
  Assert.AreEqual<Integer>(Length(LContent.EdgeIndex), Length(LFile.EdgeIndex));
  for LIndex := 0 to AAS_LUMPS - 1 do
  begin
    LExpected := LFile.LumpBytes(LIndex);
    Assert.IsTrue(Length(LExpected) > 0, 'lump ' + IntToStr(LIndex));
  end;
  Assert.AreEqual<Integer>(0, Length(LFile.LumpBytes(99)));
end;

procedure TTestAasReader.UnFileDellaVersioneQuattroNonDovrebbeAvereLIntestazioneCifrata;
var
  LBytes: TBytes;
  LHeader: TAasFileHeader;
begin
  LBytes := TAasSample.Bytes(2);
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual<Integer>(AAS_VERSION_OLD, LHeader.Version);
  Assert.AreEqual<Integer>(Integer(SAMPLE_CHECKSUM), LHeader.BspChecksum);
  LBytes := TAasSample.Bytes(0);
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  Assert.AreNotEqual<Integer>(Integer(SAMPLE_CHECKSUM), LHeader.BspChecksum);
end;

procedure TTestAasReader.UnIdentificatoreSbagliatoDovrebbeDareIlCodiceCinque;
var
  LBytes: TBytes;
begin
  LBytes := TAasSample.Bytes(0);
  LBytes[0] := LBytes[0] xor 1;
  try
    TAasFactory.CreateReader(nil, nil, nil).ParseBytes(LBytes, 'a.aas', Integer(SAMPLE_CHECKSUM));
    Assert.Fail('EAasFileException expected');
  except
    on E: EAasFileException do
    begin
      Assert.AreEqual<Integer>(BLERR_WRONGAASFILEID, E.ErrorCode);
      Assert.AreEqual('a.aas is not an AAS file', E.Message);
    end;
  end;
end;

procedure TTestAasReader.UnFileCortoDovrebbeDareIlCodiceCinque;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 40);
  try
    TAasFactory.CreateReader(nil, nil, nil).ParseBytes(LBytes, 'a.aas', 0);
    Assert.Fail('EAasFileException expected');
  except
    on E: EAasFileException do
      Assert.AreEqual<Integer>(BLERR_WRONGAASFILEID, E.ErrorCode);
  end;
end;

procedure TTestAasReader.UnaVersioneSbagliataDovrebbeDareIlCodiceSei;
var
  LBytes: TBytes;
  LVersion: Integer;
begin
  LBytes := TAasSample.Bytes(0);
  LVersion := 6;
  Move(LVersion, LBytes[4], 4);
  try
    TAasFactory.CreateReader(nil, nil, nil).ParseBytes(LBytes, 'a.aas', Integer(SAMPLE_CHECKSUM));
    Assert.Fail('EAasFileException expected');
  except
    on E: EAasFileException do
    begin
      Assert.AreEqual<Integer>(BLERR_WRONGAASFILEVERSION, E.ErrorCode);
      Assert.AreEqual('aas file a.aas is version 6, not 5', E.Message);
    end;
  end;
end;

procedure TTestAasReader.UnChecksumDiversoDovrebbeDareIlCodiceSei;
begin
  try
    TAasFactory.CreateReader(nil, nil, nil).ParseBytes(TAasSample.Bytes(0), 'a.aas', 1);
    Assert.Fail('EAasFileException expected');
  except
    on E: EAasFileException do
    begin
      Assert.AreEqual<Integer>(BLERR_WRONGAASFILEVERSION, E.ErrorCode);
      Assert.AreEqual('aas file a.aas is out of date', E.Message);
    end;
  end;
end;

procedure TTestAasReader.UnLumpFuoriDalFileDovrebbeDareIlCodiceSette;
var
  LBytes: TBytes;
begin
  // the original reads what it finds and leaves the rest zero; here the file is not valid
  LBytes := TAasSample.Bytes(0);
  SetLength(LBytes, Length(LBytes) - 10);
  try
    TAasFactory.CreateReader(nil, nil, nil).ParseBytes(LBytes, 'a.aas', Integer(SAMPLE_CHECKSUM));
    Assert.Fail('EAasFileException expected');
  except
    on E: EAasFileException do
      Assert.AreEqual<Integer>(BLERR_CANNOTREADAASLUMP, E.ErrorCode);
  end;
end;

procedure TTestAasReader.UnLumpConLunghezzaNegativaDovrebbeDareIlCodiceSette;
var
  LBytes: TBytes;
  LContent: TAasFileData;
begin
  LContent := TAasSample.Content(0);
  LBytes := TAasSample.Layout(LContent, AAS_VERSION_OLD, 0);
  // the length of the lump of the planes (the header is not scrambled in version 4): offset of
  // the lump 2 = 12 + 2 * 8, its length 4 bytes more
  PInteger(@LBytes[12 + 2 * 8 + 4])^ := -4;
  try
    TAasFactory.CreateReader(nil, nil, nil).ParseBytes(LBytes, 'a.aas', Integer(SAMPLE_CHECKSUM));
    Assert.Fail('EAasFileException expected');
  except
    on E: EAasFileException do
      Assert.AreEqual<Integer>(BLERR_CANNOTREADAASLUMP, E.ErrorCode);
  end;
end;

procedure TTestAasReader.UnLumpNonSequenzialeDovrebbeDareUnAvviso;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  TAasFactory.CreateReader(LKeeper, nil, nil).ParseBytes(TAasSample.Bytes(3), 'a.aas', Integer(SAMPLE_CHECKSUM));
  // the faces and every lump after them (the offset that was jumped to is not remembered)
  Assert.AreEqual<Integer>(9, LImport.Count);
  Assert.AreEqual<Integer>(PRT_WARNING, LImport.Level(0));
  Assert.AreEqual('AAS file not sequentially read'#10, LImport.Message(0));
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  TAasFactory.CreateReader(LKeeper, nil, nil).ParseBytes(TAasSample.Bytes(0), 'a.aas', Integer(SAMPLE_CHECKSUM));
  Assert.AreEqual<Integer>(0, LImport.Count);
end;

procedure TTestAasReader.UnFileMancanteDovrebbeDareIlCodiceQuattro;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LFile: IAasFile;
  LCode: Integer;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  LCode := TAasFactory.CreateReader(LKeeper, TFakeFiles.Create('a.aas', nil), nil).Load('b.aas', LFile);
  Assert.AreEqual<Integer>(BLERR_CANNOTOPENAASFILE, LCode);
  Assert.IsNull(LFile);
  Assert.AreEqual<Integer>(2, LImport.Count);
  Assert.AreEqual('trying to load b.aas'#10, LImport.Message(0));
  Assert.AreEqual(PRT_FATAL, LImport.Level(1));
  Assert.AreEqual('can''t open b.aas'#10, LImport.Message(1));
  // no file source at all
  LCode := TAasFactory.CreateReader(LKeeper, nil, nil).Load('b.aas', LFile);
  Assert.AreEqual<Integer>(BLERR_CANNOTOPENAASFILE, LCode);
end;

procedure TTestAasReader.LoadDovrebbeStampareIMessaggiDelC;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LFile: IAasFile;
  LBytes: TBytes;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  LBytes := TAasSample.Bytes(0);
  Assert.AreEqual<Integer>(BLERR_NOERROR, TAasFactory.CreateReader(LKeeper, TFakeFiles.Create('m.aas', LBytes),
    TFakeLibVars.Create(IntToStr(SAMPLE_CHECKSUM))).Load('m.aas', LFile));
  Assert.IsNotNull(LFile);
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.AreEqual(PRT_MESSAGE, LImport.Level(0));
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  Assert.AreEqual<Integer>(BLERR_WRONGAASFILEVERSION, TAasFactory.CreateReader(LKeeper,
    TFakeFiles.Create('m.aas', LBytes), TFakeLibVars.Create('7')).Load('m.aas', LFile));
  Assert.IsNull(LFile);
  Assert.AreEqual('aas file m.aas is out of date'#10, LImport.Message(1));
  Assert.AreEqual(PRT_FATAL, LImport.Level(1));
end;

procedure TTestAasReader.LoadSenzaVariabileDovrebbeConfrontareConZero;
var
  LFile: IAasFile;
  LBytes: TBytes;
  LContent: TAasFileData;
begin
  // without the variable the checksum is 0 (atoi of an empty text)
  LContent := TAasSample.Content(0);
  LBytes := TAasSample.Layout(LContent, AAS_VERSION_OLD, 0);
  PInteger(@LBytes[8])^ := 0;
  Assert.AreEqual<Integer>(BLERR_NOERROR, TAasFactory.CreateReader(nil, TFakeFiles.Create('m.aas', LBytes),
    nil).Load('m.aas', LFile));
end;

procedure TTestAasReader.IlChecksumDovrebbeSeguireAtoi;
var
  LFile: IAasFile;
  LBytes: TBytes;
  LContent: TAasFileData;

  function Code(const AText: string; const AChecksum: Integer): Integer;
  begin
    PInteger(@LBytes[8])^ := AChecksum;
    Result := TAasFactory.CreateReader(nil, TFakeFiles.Create('m.aas', LBytes),
      TFakeLibVars.Create(AnsiString(AText))).Load('m.aas', LFile);
  end;

begin
  LContent := TAasSample.Content(0);
  LBytes := TAasSample.Layout(LContent, AAS_VERSION_OLD, 0);
  Assert.AreEqual<Integer>(BLERR_NOERROR, Code('  42xyz', 42));
  Assert.AreEqual<Integer>(BLERR_NOERROR, Code('-17', -17));
  Assert.AreEqual<Integer>(BLERR_NOERROR, Code('+5', 5));
  Assert.AreEqual<Integer>(BLERR_NOERROR, Code('abc', 0));
  // the number wraps as a 32 bit integer
  Assert.AreEqual<Integer>(BLERR_NOERROR, Code('4294967297', 1));
  Assert.AreEqual<Integer>(BLERR_WRONGAASFILEVERSION, Code('43', 42));
end;

procedure TTestAasReader.ParseBytesDovrebbeSollevareEAasFileException;
begin
  Assert.WillRaise(
    procedure
    begin
      TAasFactory.CreateReader(nil, nil, nil).ParseBytes(nil, 'x', 0);
    end, EAasFileException);
end;

procedure TTestAasReader.UnaMacchinaBigEndianDovrebbeInvertireIByte;
var
  LNative, LSwapped: IAasFile;
begin
  LNative := TAasFactory.CreateReader(nil, nil, nil).ParseBytes(TAasSample.Bytes(0), 'x', Integer(SAMPLE_CHECKSUM));
  LSwapped := TAasFactory.CreateReader(nil, nil, nil, True).ParseBytes(TAasSample.Bytes(0), 'x',
    Integer(SAMPLE_CHECKSUM));
  Assert.AreEqual<Cardinal>(TAasByteSwapper.SwapLong(Cardinal(LNative.Nodes[3].PlaneNum)),
    Cardinal(LSwapped.Nodes[3].PlaneNum));
  Assert.AreEqual<Cardinal>(TAasByteSwapper.SwapLong(Bits(LNative.Planes[5].Dist)), Bits(LSwapped.Planes[5].Dist));
  Assert.AreEqual<Integer>(Integer(TAasByteSwapper.SwapShort(LNative.Reachability[2].TravelTime)),
    Integer(LSwapped.Reachability[2].TravelTime));
end;

procedure TTestAasReader.UnaLunghezzaNonMultiplaDovrebbeIgnorareIlResto;
var
  LContent: TAasFileData;
  LBytes: TBytes;
  LFile: IAasFile;
begin
  // the number of records is length / size; the original reads all the bytes and uses the whole records
  LContent := TAasSample.Content(0);
  LBytes := TAasSample.Layout(LContent, AAS_VERSION_OLD, 0);
  Inc(PInteger(@LBytes[12 + 2 * 8 + 4])^, 3);
  LFile := TAasFactory.CreateReader(nil, nil, nil).ParseBytes(LBytes, 'x', Integer(SAMPLE_CHECKSUM));
  Assert.AreEqual<Integer>(Length(LContent.Planes), Length(LFile.Planes));
end;

procedure TTestAasReader.LeFabbricheDovrebberoDareGliOggetti;
var
  LFile: IAasFile;
begin
  LFile := TAasFactory.CreateReader(nil, nil, nil).ParseBytes(TAasSample.Bytes(0), 'x', Integer(SAMPLE_CHECKSUM));
  Assert.IsNotNull(TAasFactory.CreateSampler(LFile, nil));
  Assert.IsNotNull(TAasFactory.CreateTracer(LFile, nil));
  Assert.IsNotNull(TAasFactory.CreateFaceTester(LFile, nil));
  Assert.IsNotNull(TAasFactory.CreateBoxAreas(LFile, nil));
  Assert.IsNotNull(TAasFactory.CreateAreaQuery(LFile, nil));
end;

end.
