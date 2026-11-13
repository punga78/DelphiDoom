{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the archive DATA.WAR                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Archive;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Intf, DelphiDoom.War.Archive,
  DelphiDoom.War.Catalog, DelphiDoom.Tests.War.Builders;

type
  [TestFixture]
  [Category('war')]
  TTestWarArchive = class(TObject)
  private
    function Open(const ABytes: TBytes; const ACatalog: IWarCatalog = nil): IWarArchive;
    function Catalog(const ATypes: array of TWarRecordType): IWarCatalog;
  public
    [Test]
    procedure DovrebbeRiconoscereIlGiocoCompletoDos;
    [Test]
    procedure DovrebbeRiconoscereLaSecondaIdentificazioneDelGiocoCompleto;
    [Test]
    procedure DovrebbeRiconoscereLaDemo;
    [Test]
    procedure DovrebbeRifiutareUnIdentificatoreSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareTroppeVoci;
    [Test]
    procedure DovrebbeAccettareIlMassimoDiVoci;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaChePassaLaFineDelFile;
    [Test]
    procedure DovrebbeVolereUnaSorgente;
    [Test]
    procedure DovrebbeAccettareUnArchivioSenzaVoci;
    [Test]
    procedure DovrebbeLeggereUnRecordNonCompresso;
    [Test]
    procedure DovrebbeLeggereUnRecordCompresso;
    [Test]
    procedure DovrebbeDareLaDirectoryDiUnRecord;
    [Test]
    procedure DovrebbeUsareIlPrimoOffsetValidoComeFineDelRecord;
    [Test]
    procedure DovrebbeSaltareISegnapostoPerTrovareLaFineDelRecord;
    [Test]
    procedure DovrebbeUsareLaFineDelFileSeDopoCeSoloSegnaposto;
    [Test]
    procedure DovrebbeUsareLaFineDelFilePerLUltimoRecord;
    [Test]
    procedure DovrebbeMarcareSegnapostoOffsetZeroEFfffffff;
    [Test]
    procedure DovrebbeSaltareIRecordDiTipoSconosciutoDelCatalogo;
    [Test]
    procedure DovrebbeNonSaltareNullaSenzaCatalogo;
    [Test]
    procedure DovrebbeMarcareUnRecordFuoriDalFile;
    [Test]
    procedure DovrebbeMarcareUnRecordPiuCortoDiQuattroByte;
    [Test]
    procedure DovrebbeMarcareUnUltimoRecordOltreLaFineDelFile;
    [Test]
    procedure DovrebbeMarcareOffsetChePassanoDavantiAlSuccessivo;
    [Test]
    procedure DovrebbeMarcareUnaLunghezzaMaggioreDeiDatiNelFile;
    [Test]
    procedure DovrebbeAccettareUnRecordNonCompressoVuoto;
    [Test]
    procedure DovrebbeConsiderareCompressiTuttiIBitAltiDellaLunghezza;
    [Test]
    procedure DovrebbeTroncareLaLunghezzaA29Bit;
    [Test]
    procedure DovrebbeRifiutareLaLetturaDiUnRecordNonDisponibile;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDallArchivio;
    [Test]
    procedure DovrebbeRifiutareUnRecordCompressoTroncato;
    [Test]
    procedure DovrebbeLeggereIDatiSoloQuandoSiChiedono;
    [Test]
    procedure DovrebbeDirePerOgniRecordSePuoEssereLetto;
  end;

implementation

{ TTestWarArchive }

function TTestWarArchive.Open(const ABytes: TBytes; const ACatalog: IWarCatalog): IWarArchive;
begin
  Result := TWarArchive.Create(TWarBytesSource.Create(ABytes), ACatalog);
end;

function TTestWarArchive.Catalog(const ATypes: array of TWarRecordType): IWarCatalog;
var
  LEntries: TArray<TWarCatalogEntry>;
  LIndex: Integer;
begin
  SetLength(LEntries, Length(ATypes));
  for LIndex := 0 to High(ATypes) do
  begin
    LEntries[LIndex] := Default(TWarCatalogEntry);
    LEntries[LIndex].Index := LIndex;
    LEntries[LIndex].RecordType := ATypes[LIndex];
  end;
  Result := TWarCatalog.Create(LEntries);
end;

procedure TTestWarArchive.DovrebbeRiconoscereIlGiocoCompletoDos;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abc'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wftRetail), Ord(LArchive.FileType));
  Assert.AreEqual(Cardinal($18), LArchive.ArchiveId);
  Assert.AreEqual(1, LArchive.EntryCount);
end;

procedure TTestWarArchive.DovrebbeRiconoscereLaSecondaIdentificazioneDelGiocoCompleto;
var
  LBuilder: TWarArchiveBuilder;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    Assert.AreEqual(Ord(wftRetail), Ord(Open(LBuilder.Build($1A)).FileType));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestWarArchive.DovrebbeRiconoscereLaDemo;
var
  LBuilder: TWarArchiveBuilder;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    Assert.AreEqual(Ord(wftDemo), Ord(Open(LBuilder.Build($19)).FileType));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestWarArchive.DovrebbeRifiutareUnIdentificatoreSconosciuto;
var
  LBytes: TBytes;
  LBuilder: TWarArchiveBuilder;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBytes := LBuilder.Build($1B);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      Open(LBytes);
    end, EWarException);
end;

procedure TTestWarArchive.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      Open(TBytes.Create(24, 0, 0, 0, 0, 0, 0));
    end, EWarException);
end;

procedure TTestWarArchive.DovrebbeRifiutareTroppeVoci;
begin
  // 587 voci dichiarate: l'originale non apre l'archivio
  Assert.WillRaise(
    procedure
    begin
      Open(TBytes.Create(24, 0, 0, 0, $4B, $02, 0, 0));
    end, EWarException);
end;

procedure TTestWarArchive.DovrebbeAccettareIlMassimoDiVoci;
var
  LBuilder: TWarArchiveBuilder;
  LIndex: Integer;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    for LIndex := 1 to WAR_MAX_RESOURCES_COUNT do
      LBuilder.AddUncompressed(WarBytesOf('x'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(WAR_MAX_RESOURCES_COUNT, LArchive.EntryCount);
  Assert.IsTrue(LArchive.IsAvailable(WAR_MAX_RESOURCES_COUNT - 1));
end;

procedure TTestWarArchive.DovrebbeRifiutareUnaTabellaChePassaLaFineDelFile;
begin
  // 10 voci dichiarate e nessun offset
  Assert.WillRaise(
    procedure
    begin
      Open(TBytes.Create(24, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0));
    end, EWarException);
end;

procedure TTestWarArchive.DovrebbeVolereUnaSorgente;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarArchive.Create(nil, nil);
    end, EArgumentNilException);
end;

procedure TTestWarArchive.DovrebbeAccettareUnArchivioSenzaVoci;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(0, LArchive.EntryCount);
end;

procedure TTestWarArchive.DovrebbeLeggereUnRecordNonCompresso;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
  LData: TBytes;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('Orcs'));
    LBuilder.AddUncompressed(WarBytesOf('Humans'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  LData := LArchive.ReadRecord(1);
  Assert.AreEqual<Integer>(6, Length(LData));
  Assert.AreEqual(Integer(Ord('H')), Integer(LData[0]));
  Assert.AreEqual(Integer(Ord('s')), Integer(LData[5]));
  Assert.AreEqual<Integer>(4, Length(LArchive.ReadRecord(0)));
end;

procedure TTestWarArchive.DovrebbeLeggereUnRecordCompresso;
var
  LBuilder: TWarArchiveBuilder;
  LWriter: TWarTokenWriter;
  LArchive: IWarArchive;
  LData: TBytes;
begin
  LBuilder := TWarArchiveBuilder.Create;
  LWriter := TWarTokenWriter.Create;
  try
    LWriter.Literal(Ord('Z'));
    LWriter.Copy(0, 6);
    LBuilder.AddCompressed(LWriter.ToBytes, 7);
    LArchive := Open(LBuilder.Build($18));
  finally
    LWriter.Free;
    LBuilder.Free;
  end;
  LData := LArchive.ReadRecord(0);
  Assert.AreEqual<Integer>(7, Length(LData));
  Assert.AreEqual(Integer(Ord('Z')), Integer(LData[6]));
  Assert.IsTrue(LArchive.GetRecordInfo(0).Compressed);
end;

procedure TTestWarArchive.DovrebbeDareLaDirectoryDiUnRecord;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
  LInfo: TWarRecordInfo;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abcd'));
    LBuilder.AddUncompressed(WarBytesOf('efghij'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  LInfo := LArchive.GetRecordInfo(1);
  Assert.AreEqual(1, LInfo.Index);
  Assert.AreEqual(Ord(wrsAvailable), Ord(LInfo.Status));
  // 8 + 2 * 4 byte di intestazione e tabella, il primo record di 8 byte
  Assert.AreEqual(Cardinal(24), LInfo.Offset);
  Assert.AreEqual(Cardinal(10), LInfo.CompressedLength);
  Assert.AreEqual(Cardinal(6), LInfo.Length);
  Assert.IsFalse(LInfo.Compressed);
end;

procedure TTestWarArchive.DovrebbeUsareIlPrimoOffsetValidoComeFineDelRecord;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abc'));
    LBuilder.AddUncompressed(WarBytesOf('de'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Cardinal(7), LArchive.GetRecordInfo(0).CompressedLength);
  Assert.AreEqual(Cardinal(6), LArchive.GetRecordInfo(1).CompressedLength);
end;

procedure TTestWarArchive.DovrebbeSaltareISegnapostoPerTrovareLaFineDelRecord;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abc'));
    LBuilder.AddPlaceholder(0);
    LBuilder.AddPlaceholder($FFFFFFFF);
    LBuilder.AddUncompressed(WarBytesOf('de'));
    LArchive := Open(LBuilder.Build($19));
  finally
    LBuilder.Free;
  end;
  // la tabella e' di 16 byte: il primo record parte a 24 e il quarto a 24 + 7
  Assert.AreEqual(Cardinal(7), LArchive.GetRecordInfo(0).CompressedLength);
  Assert.AreEqual(Ord(wrsPlaceholder), Ord(LArchive.GetRecordInfo(1).Status));
  Assert.AreEqual(Ord(wrsPlaceholder), Ord(LArchive.GetRecordInfo(2).Status));
  Assert.AreEqual(Ord(wrsAvailable), Ord(LArchive.GetRecordInfo(3).Status));
end;

procedure TTestWarArchive.DovrebbeUsareLaFineDelFileSeDopoCeSoloSegnaposto;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abc'));
    LBuilder.AddPlaceholder(0);
    LBuilder.AddPlaceholder(0);
    LArchive := Open(LBuilder.Build($19));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Cardinal(7), LArchive.GetRecordInfo(0).CompressedLength);
  Assert.AreEqual(Ord(wrsPlaceholder), Ord(LArchive.GetRecordInfo(2).Status));
end;

procedure TTestWarArchive.DovrebbeUsareLaFineDelFilePerLUltimoRecord;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abcdef'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Cardinal(10), LArchive.GetRecordInfo(0).CompressedLength);
end;

procedure TTestWarArchive.DovrebbeMarcareSegnapostoOffsetZeroEFfffffff;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddPlaceholder(0);
    LBuilder.AddPlaceholder($FFFFFFFF);
    LArchive := Open(LBuilder.Build($19));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wrsPlaceholder), Ord(LArchive.GetRecordInfo(0).Status));
  Assert.AreEqual(Cardinal($FFFFFFFF), LArchive.GetRecordInfo(1).Offset);
  Assert.IsFalse(LArchive.IsAvailable(0));
end;

procedure TTestWarArchive.DovrebbeSaltareIRecordDiTipoSconosciutoDelCatalogo;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('a'));
    LBuilder.AddUncompressed(WarBytesOf('b'));
    LArchive := Open(LBuilder.Build($18), Catalog([wrtImage, wrtUnknown]));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wrsAvailable), Ord(LArchive.GetRecordInfo(0).Status));
  Assert.AreEqual(Ord(wrsSkipped), Ord(LArchive.GetRecordInfo(1).Status));
  // la lunghezza di quello che la fine del record dei vicini calcola non cambia
  Assert.AreEqual(Cardinal(5), LArchive.GetRecordInfo(0).CompressedLength);
end;

procedure TTestWarArchive.DovrebbeNonSaltareNullaSenzaCatalogo;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('a'));
    LArchive := Open(LBuilder.Build($18), nil);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LArchive.IsAvailable(0));
end;

procedure TTestWarArchive.DovrebbeMarcareUnRecordFuoriDalFile;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abc'));
    LBuilder.AddUncompressed(WarBytesOf('def'));
    // l'offset del secondo avanti alla fine: il primo arriva fino a li' e non ci sta
    LBuilder.OverrideOffset(1, 5000);
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wrsOutOfBounds), Ord(LArchive.GetRecordInfo(0).Status));
  Assert.AreEqual(Ord(wrsOutOfBounds), Ord(LArchive.GetRecordInfo(1).Status));
end;

procedure TTestWarArchive.DovrebbeMarcareUnRecordPiuCortoDiQuattroByte;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abc'));
    LBuilder.AddUncompressed(WarBytesOf('def'));
    // il secondo parte tre byte dopo il primo: al primo restano 3 byte
    LBuilder.OverrideOffset(1, 8 + 8 + 3);
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wrsOutOfBounds), Ord(LArchive.GetRecordInfo(0).Status));
  Assert.AreEqual(Cardinal(3), LArchive.GetRecordInfo(0).CompressedLength);
end;

procedure TTestWarArchive.DovrebbeMarcareUnUltimoRecordOltreLaFineDelFile;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abc'));
    LBuilder.OverrideOffset(0, 5000);
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wrsOutOfBounds), Ord(LArchive.GetRecordInfo(0).Status));
  Assert.AreEqual(Cardinal(0), LArchive.GetRecordInfo(0).CompressedLength);
end;

procedure TTestWarArchive.DovrebbeMarcareOffsetChePassanoDavantiAlSuccessivo;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abcdef'));
    LBuilder.AddUncompressed(WarBytesOf('ghijkl'));
    // il secondo e' prima del primo: la differenza avvolge (senza segno) e il primo non ci sta
    LBuilder.OverrideOffset(1, 12);
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wrsOutOfBounds), Ord(LArchive.GetRecordInfo(0).Status));
  Assert.AreEqual(Cardinal($FFFFFFFC),LArchive.GetRecordInfo(0).CompressedLength);
end;

procedure TTestWarArchive.DovrebbeMarcareUnaLunghezzaMaggioreDeiDatiNelFile;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddRaw(100, WarBytesOf('abc'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Ord(wrsBadLength), Ord(LArchive.GetRecordInfo(0).Status));
  Assert.AreEqual(Cardinal(100), LArchive.GetRecordInfo(0).Length);
end;

procedure TTestWarArchive.DovrebbeAccettareUnRecordNonCompressoVuoto;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(nil);
    LBuilder.AddUncompressed(WarBytesOf('x'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LArchive.IsAvailable(0));
  Assert.AreEqual<Integer>(0, Length(LArchive.ReadRecord(0)));
end;

procedure TTestWarArchive.DovrebbeConsiderareCompressiTuttiIBitAltiDellaLunghezza;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddRaw($80000000 or 0, nil);
    LBuilder.AddRaw($40000000 or 0, nil);
    LBuilder.AddRaw($20000000 or 0, nil);
    LBuilder.AddRaw(0, nil);
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LArchive.GetRecordInfo(0).Compressed);
  Assert.IsTrue(LArchive.GetRecordInfo(1).Compressed);
  Assert.IsTrue(LArchive.GetRecordInfo(2).Compressed);
  Assert.IsFalse(LArchive.GetRecordInfo(3).Compressed);
end;

procedure TTestWarArchive.DovrebbeTroncareLaLunghezzaA29Bit;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddRaw($A0000005, WarBytesOf('abcde'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(Cardinal(5), LArchive.GetRecordInfo(0).Length);
end;

procedure TTestWarArchive.DovrebbeRifiutareLaLetturaDiUnRecordNonDisponibile;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddPlaceholder(0);
    LArchive := Open(LBuilder.Build($19));
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LArchive.ReadRecord(0);
    end, EWarException);
end;

procedure TTestWarArchive.DovrebbeRifiutareUnIndiceFuoriDallArchivio;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('a'));
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LArchive.ReadRecord(1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LArchive.GetRecordInfo(-1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LArchive.IsAvailable(5);
    end, EWarException);
end;

procedure TTestWarArchive.DovrebbeRifiutareUnRecordCompressoTroncato;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    // dichiara 10 byte e ne da' 2 (un letterale)
    LBuilder.AddCompressed(TBytes.Create(1, 65), 10);
    LArchive := Open(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LArchive.IsAvailable(0));
  Assert.WillRaise(
    procedure
    begin
      LArchive.ReadRecord(0);
    end, EWarException);
end;

procedure TTestWarArchive.DovrebbeLeggereIDatiSoloQuandoSiChiedono;
var
  LBuilder: TWarArchiveBuilder;
  LSource: TWarBytesSource;
  LArchive: IWarArchive;
  LReadsAfterOpen: Integer;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('abcdef'));
    LBuilder.AddUncompressed(WarBytesOf('ghi'));
    LSource := TWarBytesSource.Create(LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
  LArchive := TWarArchive.Create(LSource, nil);
  // intestazione, tabella e l'intestazione di ognuno dei due record: quattro letture
  LReadsAfterOpen := LSource.Reads;
  Assert.AreEqual(4, LReadsAfterOpen);
  LArchive.ReadRecord(0);
  Assert.AreEqual(LReadsAfterOpen + 1, LSource.Reads);
end;

procedure TTestWarArchive.DovrebbeDirePerOgniRecordSePuoEssereLetto;
var
  LBuilder: TWarArchiveBuilder;
  LArchive: IWarArchive;
begin
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('a'));
    LBuilder.AddPlaceholder(0);
    LArchive := Open(LBuilder.Build($19));
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(LArchive.IsAvailable(0));
  Assert.IsFalse(LArchive.IsAvailable(1));
end;

end.
