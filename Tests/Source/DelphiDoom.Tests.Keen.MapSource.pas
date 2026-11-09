{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the maps of KDREAMS.MAP              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.MapSource;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Tests.Keen.Builders;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenMapSource = class(TObject)
  private
    FGame: TTestGame;
    FMaps: IKeenMapSource;
    function SourceWith(const AHeader, AData: TBytes): IKeenMapSource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIlMarcatoreRlew;
    [Test]
    procedure DovrebbeElencareLeMappeCheCiSono;
    [Test]
    procedure DovrebbeDirePerOgniSlotSeHaUnaMappa;
    [Test]
    procedure DovrebbeLeggereLIntestazioneDiUnaMappa;
    [Test]
    procedure DovrebbeLeggereITrePianiDiOgniMappa;
    [Test]
    procedure DovrebbeLeggereLaSecondaMappaDopoLaPrima;
    [Test]
    procedure DovrebbeLeggereLaStessaMappaDueVolte;
    [Test]
    procedure DovrebbeDareLeInformazioniDeiTile;
    [Test]
    procedure DovrebbeRifiutareUnaMappaCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaTestataTroppoCorta;
    [Test]
    procedure DovrebbeRifiutareUnFileDiMappeTroncato;
    [Test]
    procedure DovrebbeRifiutareUnPianoCheNonRiempieLaMappa;
    [Test]
    procedure DovrebbeRifiutareUnaMappaPiuGrandeDi64KPerPiano;
    [Test]
    procedure DovrebbeVolerOgniArgomento;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.MapSource;

{ TTestKeenMapSource }

procedure TTestKeenMapSource.Setup;
begin
  FGame := TTestGame.Create(3);
  FMaps := TKeenFactory.OpenGameData(FGame.Files).Maps;
end;

procedure TTestKeenMapSource.TearDown;
begin
  FMaps := nil;
  FGame.Free;
end;

function TTestKeenMapSource.SourceWith(const AHeader, AData: TBytes): IKeenMapSource;
begin
  Result := TKeenFactory.CreateMapSource(AHeader,
    TKeenFactory.CreateHuffman(FGame.Files.ReadAll('MAPDICT.KDR')), TBytesStream.Create(AData));
end;

procedure TTestKeenMapSource.DovrebbeLeggereIlMarcatoreRlew;
begin
  Assert.AreEqual(Integer(TEST_RLEW_TAG), Integer(FMaps.RlewTag));
end;

procedure TTestKeenMapSource.DovrebbeElencareLeMappeCheCiSono;
var
  LNumbers: TArray<Integer>;
begin
  LNumbers := FMaps.MapNumbers;
  Assert.AreEqual(2, Length(LNumbers));
  Assert.AreEqual(FGame.MapSlot[0], LNumbers[0]);
  Assert.AreEqual(FGame.MapSlot[1], LNumbers[1]);
end;

procedure TTestKeenMapSource.DovrebbeDirePerOgniSlotSeHaUnaMappa;
begin
  Assert.IsTrue(FMaps.HasMap(0));
  Assert.IsFalse(FMaps.HasMap(1), 'offset 0');
  Assert.IsFalse(FMaps.HasMap(2), 'offset -1');
  Assert.IsTrue(FMaps.HasMap(3));
  Assert.IsFalse(FMaps.HasMap(-1));
  Assert.IsFalse(FMaps.HasMap(100));
end;

procedure TTestKeenMapSource.DovrebbeLeggereLIntestazioneDiUnaMappa;
var
  LMap: IKeenMap;
begin
  LMap := FMaps.LoadMap(3);
  Assert.AreEqual(3, LMap.Number);
  Assert.AreEqual('TEST MAP 1', LMap.Name);
  Assert.AreEqual(12, LMap.Width);
  Assert.AreEqual(7, LMap.Height);
  Assert.AreEqual(12, Integer(LMap.Header.Width));
  Assert.AreEqual(7, Integer(LMap.Header.Height));
end;

procedure TTestKeenMapSource.DovrebbeLeggereITrePianiDiOgniMappa;
var
  LMap: IKeenMap;
  LNumber: Integer;
  LPlane: Integer;
  LIndex: Integer;
begin
  for LNumber := 0 to 1 do
  begin
    LMap := FMaps.LoadMap(FGame.MapSlot[LNumber]);
    for LPlane := 0 to 2 do
    begin
      Assert.AreEqual(FGame.MapWidth[LNumber] * FGame.MapHeight[LNumber], Length(LMap.Planes[LPlane]));
      for LIndex := 0 to High(LMap.Planes[LPlane]) do
        if LMap.Planes[LPlane][LIndex] <> FGame.MapPlanes[LNumber, LPlane][LIndex] then
          Assert.Fail(Format('mappa %d, piano %d, parola %d', [LNumber, LPlane, LIndex]));
    end;
  end;
end;

procedure TTestKeenMapSource.DovrebbeLeggereLaSecondaMappaDopoLaPrima;
var
  LFirst: IKeenMap;
  LSecond: IKeenMap;
begin
  LFirst := FMaps.LoadMap(0);
  LSecond := FMaps.LoadMap(3);
  Assert.AreEqual(Integer(FGame.MapPlanes[1, 2][5]), Integer(LSecond.GetTile(2, 5, 0)));
  Assert.AreEqual(Integer(FGame.MapPlanes[0, 0][0]), Integer(LFirst.GetTile(0, 0, 0)));
end;

procedure TTestKeenMapSource.DovrebbeLeggereLaStessaMappaDueVolte;
begin
  Assert.AreEqual(Integer(FMaps.LoadMap(0).GetTile(1, 2, 3)), Integer(FMaps.LoadMap(0).GetTile(1, 2, 3)));
end;

procedure TTestKeenMapSource.DovrebbeDareLeInformazioniDeiTile;
begin
  Assert.AreEqual(KEEN_TINF_SIZE, Length(FMaps.TileInfo.Bytes));
  Assert.IsTrue(CompareMem(@FGame.TileInfo[0], @FMaps.TileInfo.Bytes[0], KEEN_TINF_SIZE));
end;

procedure TTestKeenMapSource.DovrebbeRifiutareUnaMappaCheNonCe;
begin
  Assert.WillRaise(procedure begin FMaps.LoadMap(2); end, EKeenDataException);
  Assert.WillRaise(procedure begin FMaps.LoadMap(100); end, EKeenDataException);
end;

procedure TTestKeenMapSource.DovrebbeRifiutareUnaTestataTroppoCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      SourceWith(Copy(FGame.Files.ReadAll('MAPHEAD.KDR'), 0, 11000), FGame.Files.ReadAll('KDREAMS.MAP'));
    end, EKeenDataException);
end;

procedure TTestKeenMapSource.DovrebbeRifiutareUnFileDiMappeTroncato;
var
  LMaps: IKeenMapSource;
begin
  LMaps := SourceWith(FGame.Files.ReadAll('MAPHEAD.KDR'), Copy(FGame.Files.ReadAll('KDREAMS.MAP'), 0, 10));
  Assert.WillRaise(procedure begin LMaps.LoadMap(0); end, EKeenDataException);
end;

procedure TTestKeenMapSource.DovrebbeRifiutareUnPianoCheNonRiempieLaMappa;
var
  LData: TBytes;
  LMaps: IKeenMapSource;
begin
  // the first plane of the first map starts at the start of the file: its first word is the length that the
  // Huffman data give; with 4 bytes there is room for the word of the RLEW length and one word only
  LData := Copy(FGame.Files.ReadAll('KDREAMS.MAP'));
  LData[0] := 4;
  LData[1] := 0;
  LMaps := SourceWith(FGame.Files.ReadAll('MAPHEAD.KDR'), LData);
  Assert.WillRaise(procedure begin LMaps.LoadMap(0); end, EKeenDataException);
end;

procedure TTestKeenMapSource.DovrebbeRifiutareUnaMappaPiuGrandeDi64KPerPiano;
var
  LHead: TBytes;
  LCode: TTestHuffmanCode;
  LHeader: TBytes;
  LCompressed: TBytes;
  LData: TBytes;
  LMaps: IKeenMapSource;
  LIndex: Integer;
begin
  // a map of 200 x 200 tiles: 80000 bytes for each plane, the C counts them in 16 bits (unsigned)
  LCode := TTestHuffmanCode.Create(3 + 2);
  try
    SetLength(LHeader, 38);
    FillChar(LHeader[0], 38, 0);
    LHeader[18] := 200;
    LHeader[20] := 200;
    LCompressed := LCode.Encode(LHeader);
    LHead := Copy(FGame.Files.ReadAll('MAPHEAD.KDR'));
    // slot 0: header at offset 0, with its size
    for LIndex := 0 to 3 do
      LHead[2 + LIndex] := 0;
    LHead[2] := 1;
    LHead[2 + KEEN_MAP_SLOTS * 4] := Byte(Length(LCompressed));
    SetLength(LData, 1 + Length(LCompressed));
    LData[0] := 0;
    Move(LCompressed[0], LData[1], Length(LCompressed));
    LMaps := TKeenFactory.CreateMapSource(LHead,
      TKeenFactory.CreateHuffman(LCode.Dictionary), TBytesStream.Create(LData));
    Assert.WillRaise(procedure begin LMaps.LoadMap(0); end, EKeenDataException);
  finally
    LCode.Free;
  end;
end;

procedure TTestKeenMapSource.DovrebbeVolerOgniArgomento;
var
  LHuffman: IKeenHuffman;
  LStream: TStream;
begin
  LHuffman := TKeenFactory.CreateHuffman(FGame.Files.ReadAll('MAPDICT.KDR'));
  LStream := TMemoryStream.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        TKeenMapSource.Create(FGame.Files.ReadAll('MAPHEAD.KDR'), nil, TKeenFactory.CreateRlew, LStream);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TKeenMapSource.Create(FGame.Files.ReadAll('MAPHEAD.KDR'), LHuffman, nil, LStream);
      end, EArgumentNilException);
    Assert.WillRaise(
      procedure
      begin
        TKeenMapSource.Create(FGame.Files.ReadAll('MAPHEAD.KDR'), LHuffman, TKeenFactory.CreateRlew, nil);
      end, EArgumentNilException);
  finally
    LStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenMapSource);

end.
