{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the archive GREED.BLO               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.BloArchive;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedBloArchive = class(TObject)
  private
    FArchive: IGreedArchive;
    function Open(const ABytes: TBytes): IGreedArchive;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeContareILump;
    [Test]
    procedure DovrebbeDareIlNomeDiOgniLump;
    [Test]
    procedure DovrebbeDareUnNomeVuotoAIlumpSenzaNome;
    [Test]
    procedure DovrebbeCercareUnNomeSenzaDifferenzaTraMaiuscoleEMinuscole;
    [Test]
    procedure DovrebbeDareMenoUnoSeIlNomeNonCe;
    [Test]
    procedure DovrebbeDareMenoUnoPerUnNomeVuoto;
    [Test]
    procedure DovrebbeDareIlPrimoLumpConLoStessoNome;
    [Test]
    procedure DovrebbeSollevareSeUnNomeObbligatorioNonCe;
    [Test]
    procedure DovrebbeLeggereIByteDiUnLump;
    [Test]
    procedure DovrebbeLeggereUnLumpVuoto;
    [Test]
    procedure DovrebbeDareLaDimensioneEL_EntrataDellaTabella;
    [Test]
    procedure DovrebbeTenereIlCampoCompress;
    [Test]
    procedure DovrebbeApplicareLeCorrezioniSoloAReadLump;
    [Test]
    procedure DovrebbeRifiutareUnLumpCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnaIntestazioneConValoriNegativi;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaChePassaLaFineDelFile;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaPiuPiccolaDeiLump;
    [Test]
    procedure DovrebbeRifiutareUnNomeFuoriDallaTabella;
    [Test]
    procedure DovrebbeRifiutareUnNomeSenzaTerminatore;
    [Test]
    procedure DovrebbeRifiutareUnLumpChePassaLaFineDelFile;
    [Test]
    procedure DovrebbeVolereUnFlusso;
    [Test]
    procedure DovrebbeRilasciareIlFlussoSeUnaIntestazioneNonVa;
    [Test]
    procedure DovrebbeLasciareIlFlussoAChiLoPossiede;
    [Test]
    procedure DovrebbeLeggereUnaTabellaSenzaLump;
  end;

implementation

uses
  DelphiDoom.Greed.Factory, DelphiDoom.Tests.Greed.Builders;

type
  /// <summary>Replaces any lump of 2 bytes with one byte</summary>
  TFakeFixes = class(TInterfacedObject, IGreedLumpFixes)
  public
    function Apply(const ALump: TBytes): TBytes;
  end;

function TFakeFixes.Apply(const ALump: TBytes): TBytes;
begin
  if Length(ALump) = 2 then
    Result := TBytes.Create(77)
  else
    Result := ALump;
end;

{ TTestGreedBloArchive }

procedure TTestGreedBloArchive.Setup;
begin
  FArchive := TGreedTestArchive.Open;
end;

procedure TTestGreedBloArchive.TearDown;
begin
  FArchive := nil;
end;

function TTestGreedBloArchive.Open(const ABytes: TBytes): IGreedArchive;
begin
  Result := TGreedFactory.OpenArchive(TBytesStream.Create(ABytes), True, nil);
end;

procedure TTestGreedBloArchive.DovrebbeContareILump;
begin
  Assert.AreEqual(TGreedTestArchive.LUMP_COUNT, FArchive.LumpCount);
end;

procedure TTestGreedBloArchive.DovrebbeDareIlNomeDiOgniLump;
begin
  Assert.AreEqual('palette', FArchive.GetLumpName(TGreedTestArchive.LUMP_PALETTE));
  Assert.AreEqual('level1.lay', FArchive.GetLumpName(TGreedTestArchive.LUMP_MAP0));
  Assert.AreEqual('font1', FArchive.GetLumpName(TGreedTestArchive.LUMP_FONT));
end;

procedure TTestGreedBloArchive.DovrebbeDareUnNomeVuotoAIlumpSenzaNome;
begin
  Assert.AreEqual('', FArchive.GetLumpName(TGreedTestArchive.LUMP_UNNAMED));
end;

procedure TTestGreedBloArchive.DovrebbeCercareUnNomeSenzaDifferenzaTraMaiuscoleEMinuscole;
begin
  Assert.AreEqual(TGreedTestArchive.LUMP_PALETTE, FArchive.IndexOf('palette'));
  Assert.AreEqual(TGreedTestArchive.LUMP_PALETTE, FArchive.IndexOf('PALETTE'));
  Assert.AreEqual(TGreedTestArchive.LUMP_MAP0, FArchive.IndexOf('Level1.LAY'));
  Assert.AreEqual(TGreedTestArchive.LUMP_MAP0, FArchive.RequireIndexOf('LEVEL1.LAY'));
end;

procedure TTestGreedBloArchive.DovrebbeDareMenoUnoSeIlNomeNonCe;
begin
  Assert.AreEqual(-1, FArchive.IndexOf('nothing'));
  Assert.AreEqual(-1, FArchive.IndexOf('palett'));
  Assert.AreEqual(-1, FArchive.IndexOf('palettes'));
end;

procedure TTestGreedBloArchive.DovrebbeDareMenoUnoPerUnNomeVuoto;
begin
  Assert.AreEqual(-1, FArchive.IndexOf(''));
end;

procedure TTestGreedBloArchive.DovrebbeDareIlPrimoLumpConLoStessoNome;
var
  LBlo: TGreedBlo;
  LArchive: IGreedArchive;
begin
  // slugs.lvl is twice in the demo 1.016: CA_CheckNamedNum gives the first
  LBlo := TGreedBlo.Create;
  try
    LBlo.Add('a', nil).Add('slugs.lvl', TBytes.Create(1)).Add('b', nil).Add('SLUGS.LVL', TBytes.Create(2));
    LArchive := LBlo.Open;
  finally
    LBlo.Free;
  end;
  Assert.AreEqual(1, LArchive.IndexOf('slugs.lvl'));
  Assert.AreEqual(1, LArchive.IndexOf('Slugs.Lvl'));
  Assert.AreEqual(4, LArchive.LumpCount);
end;

procedure TTestGreedBloArchive.DovrebbeSollevareSeUnNomeObbligatorioNonCe;
begin
  Assert.WillRaise(procedure begin FArchive.RequireIndexOf('nothing'); end, EGreedNotFoundException);
end;

procedure TTestGreedBloArchive.DovrebbeLeggereIByteDiUnLump;
begin
  Assert.AreEqual(TGreedLumps.CrcHex(TGreedLumps.Palette),
    TGreedLumps.CrcHex(FArchive.ReadLump(TGreedTestArchive.LUMP_PALETTE)));
  Assert.AreEqual(3, Length(FArchive.ReadLump(TGreedTestArchive.LUMP_FONT)));
  Assert.AreEqual(1, Integer(FArchive.ReadLump(TGreedTestArchive.LUMP_FONT)[0]));
  Assert.AreEqual(9, Integer(FArchive.ReadLump(TGreedTestArchive.LUMP_UNNAMED)[1]));
end;

procedure TTestGreedBloArchive.DovrebbeLeggereUnLumpVuoto;
begin
  Assert.AreEqual(0, Length(FArchive.ReadLump(TGreedTestArchive.LUMP_MAP)));
  Assert.AreEqual(0, Length(FArchive.ReadLumpRaw(TGreedTestArchive.LUMP_MAP)));
  Assert.AreEqual(0, FArchive.GetLumpSize(TGreedTestArchive.LUMP_MAP));
end;

procedure TTestGreedBloArchive.DovrebbeDareLaDimensioneEL_EntrataDellaTabella;
var
  LInfo: TGreedLumpInfo;
begin
  Assert.AreEqual(GREED_PALETTE_BYTES, FArchive.GetLumpSize(TGreedTestArchive.LUMP_PALETTE));
  LInfo := FArchive.GetLumpInfo(TGreedTestArchive.LUMP_PALETTE);
  Assert.AreEqual(GREED_FILEINFO_BYTES, LInfo.FilePosition);
  Assert.AreEqual(Cardinal(GREED_PALETTE_BYTES), LInfo.Size);
  Assert.AreNotEqual(0, Integer(LInfo.NameOffset));
  LInfo := FArchive.GetLumpInfo(TGreedTestArchive.LUMP_UNNAMED);
  Assert.AreEqual(0, Integer(LInfo.NameOffset));
end;

procedure TTestGreedBloArchive.DovrebbeTenereIlCampoCompress;
var
  LBlo: TGreedBlo;
  LArchive: IGreedArchive;
begin
  LBlo := TGreedBlo.Create;
  try
    LBlo.Add('x', TBytes.Create(1, 2, 3), 5);
    LArchive := LBlo.Open;
  finally
    LBlo.Free;
  end;
  // the game never reads it: the bytes are the ones of the file whatever it says
  Assert.AreEqual(5, Integer(LArchive.GetLumpInfo(0).Compress));
  Assert.AreEqual(3, Length(LArchive.ReadLump(0)));
end;

procedure TTestGreedBloArchive.DovrebbeApplicareLeCorrezioniSoloAReadLump;
var
  LBlo: TGreedBlo;
  LArchive: IGreedArchive;
begin
  LBlo := TGreedBlo.Create;
  try
    LBlo.Add('x', TBytes.Create(1, 2));
    LArchive := LBlo.Open(TFakeFixes.Create);
  finally
    LBlo.Free;
  end;
  // CA_CacheLump corrects, CA_ReadLump does not
  Assert.AreEqual(1, Length(LArchive.ReadLump(0)));
  Assert.AreEqual(77, Integer(LArchive.ReadLump(0)[0]));
  Assert.AreEqual(2, Length(LArchive.ReadLumpRaw(0)));
  Assert.AreEqual(2, LArchive.GetLumpSize(0));
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnLumpCheNonCe;
begin
  Assert.WillRaise(procedure begin FArchive.ReadLump(-1); end, EGreedNotFoundException);
  Assert.WillRaise(procedure begin FArchive.ReadLump(TGreedTestArchive.LUMP_COUNT); end, EGreedNotFoundException);
  Assert.WillRaise(procedure begin FArchive.GetLumpName(TGreedTestArchive.LUMP_COUNT); end, EGreedNotFoundException);
  Assert.WillRaise(procedure begin FArchive.GetLumpInfo(-1); end, EGreedNotFoundException);
  Assert.WillRaise(procedure begin FArchive.GetLumpSize(999); end, EGreedNotFoundException);
  Assert.WillRaise(procedure begin FArchive.ReadLumpRaw(999); end, EGreedNotFoundException);
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(procedure begin Open(TBytes.Create(1, 0, 0)); end, EGreedDataException);
  Assert.WillRaise(procedure begin Open(nil); end, EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnaIntestazioneConValoriNegativi;
var
  LBytes: TBytes;
begin
  LBytes := TGreedTestArchive.Bytes;
  LBytes[1] := $FF; // 18 lumps -> -...: the count becomes negative
  LBytes[0] := $FF;
  Assert.WillRaise(procedure begin Open(LBytes); end, EGreedDataException);
  LBytes := TGreedTestArchive.Bytes;
  LBytes[5] := $FF; // offset of the table negative
  Assert.WillRaise(procedure begin Open(LBytes); end, EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnaTabellaChePassaLaFineDelFile;
var
  LBytes: TBytes;
begin
  LBytes := TGreedTestArchive.Bytes;
  SetLength(LBytes, Length(LBytes) - 1);
  Assert.WillRaise(procedure begin Open(LBytes); end, EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnaTabellaPiuPiccolaDeiLump;
var
  LBytes: TBytes;
begin
  LBytes := TGreedTestArchive.Bytes;
  // the size of the table (offset 6) becomes less than 18 entries
  LBytes[6] := 10;
  LBytes[7] := 0;
  LBytes[8] := 0;
  LBytes[9] := 0;
  Assert.WillRaise(procedure begin Open(LBytes); end, EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnNomeFuoriDallaTabella;
var
  LBytes: TBytes;
  LTable: Integer;
begin
  LBytes := TGreedTestArchive.Bytes;
  LTable := PInteger(@LBytes[2])^;
  // the name offset of the first lump points past the end of the table
  TGreedLumps.PutWord(LBytes, LTable + 8, 30000);
  Assert.WillRaise(procedure begin Open(LBytes); end, EGreedDataException);
  LBytes := TGreedTestArchive.Bytes;
  LTable := PInteger(@LBytes[2])^;
  TGreedLumps.PutWord(LBytes, LTable + 8, $FFFF); // -1
  Assert.WillRaise(procedure begin Open(LBytes); end, EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnNomeSenzaTerminatore;
var
  LBytes: TBytes;
begin
  LBytes := TGreedTestArchive.Bytes;
  // the last byte of the file is the zero that ends the last name
  LBytes[High(LBytes)] := Ord('x');
  Assert.WillRaise(procedure begin Open(LBytes); end, EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeRifiutareUnLumpChePassaLaFineDelFile;
var
  LBytes: TBytes;
  LTable: Integer;
  LArchive: IGreedArchive;
begin
  LBytes := TGreedTestArchive.Bytes;
  LTable := PInteger(@LBytes[2])^;
  PInteger(@LBytes[LTable + 4])^ := 100000; // size of the palette
  LArchive := Open(LBytes);
  Assert.WillRaise(procedure begin LArchive.ReadLump(0); end, EGreedDataException);
  PInteger(@LBytes[LTable + 4])^ := 10;
  PInteger(@LBytes[LTable])^ := -5; // position
  LArchive := Open(LBytes);
  Assert.WillRaise(procedure begin LArchive.ReadLumpRaw(0); end, EGreedDataException);
  PInteger(@LBytes[LTable + 4])^ := -1; // 4 billion bytes
  PInteger(@LBytes[LTable])^ := 10;
  LArchive := Open(LBytes);
  Assert.WillRaise(procedure begin LArchive.ReadLump(0); end, EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeVolereUnFlusso;
begin
  Assert.WillRaise(procedure begin TGreedFactory.OpenArchive(nil, True, nil); end, EArgumentNilException);
end;

procedure TTestGreedBloArchive.DovrebbeRilasciareIlFlussoSeUnaIntestazioneNonVa;
begin
  // the stream is owned: the leak check of the runner would show it if the archive kept it
  Assert.WillRaise(procedure begin TGreedFactory.OpenArchive(TBytesStream.Create(TBytes.Create(1)), True, nil); end,
    EGreedDataException);
end;

procedure TTestGreedBloArchive.DovrebbeLasciareIlFlussoAChiLoPossiede;
var
  LStream: TBytesStream;
  LArchive: IGreedArchive;
begin
  LStream := TBytesStream.Create(TGreedTestArchive.Bytes);
  try
    LArchive := TGreedFactory.OpenArchive(LStream, False, nil);
    Assert.AreEqual(TGreedTestArchive.LUMP_COUNT, LArchive.LumpCount);
    LArchive := nil;
    Assert.AreEqual(1, Integer(LStream.Bytes[0] <> 0)); // the stream is still usable
  finally
    LStream.Free;
  end;
end;

procedure TTestGreedBloArchive.DovrebbeLeggereUnaTabellaSenzaLump;
var
  LBlo: TGreedBlo;
  LArchive: IGreedArchive;
begin
  LBlo := TGreedBlo.Create;
  try
    LArchive := LBlo.Open;
  finally
    LBlo.Free;
  end;
  Assert.AreEqual(0, LArchive.LumpCount);
  Assert.AreEqual(-1, LArchive.IndexOf('x'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedBloArchive);

end.
