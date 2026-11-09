{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - parity with OpenXcom         }
{                                                                              }
{  The file Tests\Data\Xcom\xcom_golden.txt is the answer of the loaders of     }
{  OpenXcom (SurfaceSet::loadPck/loadDat, Surface::loadScr/loadSpk/loadBdy,     }
{  Palette::loadDat, CatFile, BattlescapeGenerator::loadMAP/loadRMP,            }
{  MapDataSet::loadData/loadLOFTEMPS, RuleGlobe::loadDat, copied into a         }
{  harness outside the repository and compiled with MinGW g++, SSE doubles)     }
{  on 300 files of every format that DelphiDoom.Tests.Xcom.Cases makes          }
{  (Tests\Data\README.md). Every line is "KIND number what-the-C++-gave"        }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.Golden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Map,
  DelphiDoom.Tests.Xcom.Cases;

type
  [TestFixture]
  [Category('xcom')]
  [Category('xcom-golden')]
  TTestXcomGolden = class(TObject)
  private
    FGolden: TDictionary<string, string>;
    function Expected(const AKind: string; AIndex: Integer): string;
    function HashImages(const AImages: TArray<TXcomImage>): string;
    function HashImage(const AImage: TXcomImage): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAvereTutteLeRighe;
    [Test]
    procedure DovrebbeDecodificareIPckComeOpenXcom;
    [Test]
    procedure DovrebbeDecodificareIDatComeOpenXcom;
    [Test]
    procedure DovrebbeDecodificareGliScrComeOpenXcom;
    [Test]
    procedure DovrebbeDecodificareGliSpkComeOpenXcom;
    [Test]
    procedure DovrebbeDecodificareIBdyComeOpenXcom;
    [Test]
    procedure DovrebbeLeggereLePaletteComeOpenXcom;
    [Test]
    procedure DovrebbeLeggereIContenitoriCatComeOpenXcom;
    [Test]
    procedure DovrebbeLeggereLeMappeComeOpenXcom;
    [Test]
    procedure DovrebbeLeggereIPercorsiComeOpenXcom;
    [Test]
    procedure DovrebbeLeggereIlTerrenoComeOpenXcom;
    [Test]
    procedure DovrebbeLeggereIlGloboComeOpenXcom;
    [Test]
    procedure DovrebbeLeggereLeTabelleDiParoleComeOpenXcom;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.Factory;

{ TTestXcomGolden }

procedure TTestXcomGolden.Setup;
var
  LLines: TStringList;
  LLine: string;
  LFirst: Integer;
  LSecond: Integer;
begin
  FGolden := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Xcom\xcom_golden.txt'));
    for LLine in LLines do
    begin
      LFirst := Pos(' ', LLine);
      LSecond := Pos(' ', LLine, LFirst + 1);
      if LFirst > 0 then
        FGolden.Add(Copy(LLine, 1, LSecond - 1), Copy(LLine, LSecond + 1, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestXcomGolden.TearDown;
begin
  FGolden.Free;
end;

function TTestXcomGolden.Expected(const AKind: string; AIndex: Integer): string;
begin
  if not FGolden.TryGetValue(Format('%s %d', [AKind, AIndex]), Result) then
    raise Exception.CreateFmt('la riga %s %d non e'' nel file golden', [AKind, AIndex]);
end;

function TTestXcomGolden.HashImage(const AImage: TXcomImage): string;
var
  LFnv: TXcomFnv;
  LByte: Byte;
begin
  LFnv.Start;
  for LByte in AImage.Pixels do
    LFnv.AddByte(LByte);
  Result := LFnv.ToHex;
end;

function TTestXcomGolden.HashImages(const AImages: TArray<TXcomImage>): string;
var
  LFnv: TXcomFnv;
  LImage: TXcomImage;
  LByte: Byte;
begin
  LFnv.Start;
  for LImage in AImages do
    for LByte in LImage.Pixels do
      LFnv.AddByte(LByte);
  Result := LFnv.ToHex;
end;

procedure TTestXcomGolden.DovrebbeAvereTutteLeRighe;
begin
  Assert.AreEqual(XCOM_CASES * 12, FGolden.Count);
end;

procedure TTestXcomGolden.DovrebbeDecodificareIPckComeOpenXcom;
var
  LIndex: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LPck: TBytes;
  LTab: TBytes;
  LFrames: TArray<TXcomImage>;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    TXcomCases.Pck(LIndex, LWidth, LHeight, LPck, LTab);
    LFrames := TXcomFactory.CreatePckDecoder.Decode(LPck, LTab, LWidth, LHeight);
    Assert.AreEqual(Expected('PCK', LIndex), Format('%d %s', [Length(LFrames), HashImages(LFrames)]),
      'PCK ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeDecodificareIDatComeOpenXcom;
var
  LIndex: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LBytes: TBytes;
  LFrames: TArray<TXcomImage>;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    TXcomCases.Dat(LIndex, LWidth, LHeight, LBytes);
    LFrames := TXcomFactory.CreateDatDecoder.Decode(LBytes, LWidth, LHeight);
    Assert.AreEqual(Expected('DAT', LIndex), Format('%d %s', [Length(LFrames), HashImages(LFrames)]),
      'DAT ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeDecodificareGliScrComeOpenXcom;
var
  LIndex: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LBytes: TBytes;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    TXcomCases.Scr(LIndex, LWidth, LHeight, LBytes);
    Assert.AreEqual(Expected('SCR', LIndex),
      HashImage(TXcomFactory.CreateScrDecoder.Decode(LBytes, LWidth, LHeight)), 'SCR ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeDecodificareGliSpkComeOpenXcom;
var
  LIndex: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LBytes: TBytes;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    TXcomCases.Spk(LIndex, LWidth, LHeight, LBytes);
    Assert.AreEqual(Expected('SPK', LIndex),
      HashImage(TXcomFactory.CreateSpkDecoder.Decode(LBytes, LWidth, LHeight)), 'SPK ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeDecodificareIBdyComeOpenXcom;
var
  LIndex: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LBytes: TBytes;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    TXcomCases.Bdy(LIndex, LWidth, LHeight, LBytes);
    Assert.AreEqual(Expected('BDY', LIndex),
      HashImage(TXcomFactory.CreateBdyDecoder.Decode(LBytes, LWidth, LHeight)), 'BDY ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeLeggereLePaletteComeOpenXcom;
var
  LIndex: Integer;
  LBytes: TBytes;
  LCount: Integer;
  LOffset: Integer;
  LPalette: TXcomPalette;
  LFnv: TXcomFnv;
  LColor: Integer;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    TXcomCases.Pal(LIndex, LBytes, LCount, LOffset);
    LPalette := TXcomFactory.CreatePaletteReader.Read(LBytes, LCount, LOffset);
    LFnv.Start;
    for LColor := 0 to LCount - 1 do
    begin
      LFnv.AddByte(LPalette.Colors[LColor].Red);
      LFnv.AddByte(LPalette.Colors[LColor].Green);
      LFnv.AddByte(LPalette.Colors[LColor].Blue);
      LFnv.AddByte(LPalette.Colors[LColor].Alpha);
    end;
    Assert.AreEqual(Expected('PAL', LIndex), Format('%d %s', [LCount, LFnv.ToHex]), 'PAL ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeLeggereIContenitoriCatComeOpenXcom;
var
  LIndex: Integer;
  LArchive: IXcomCatArchive;
  LPlain: TXcomFnv;
  LWithName: TXcomFnv;
  LEntry: Integer;
  LBytes: TBytes;
  LByte: Byte;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    LArchive := TXcomFactory.CreateCatArchive(TXcomCases.Cat(LIndex));
    LPlain.Start;
    LWithName.Start;
    for LEntry := 0 to LArchive.Count - 1 do
    begin
      LBytes := LArchive.Load(LEntry, False);
      LPlain.AddU32(LArchive.Entries[LEntry].Size);
      for LByte in LBytes do
        LPlain.AddByte(LByte);
      LBytes := LArchive.Load(LEntry, True);
      LWithName.AddU32(Length(LBytes));
      for LByte in LBytes do
        LWithName.AddByte(LByte);
    end;
    Assert.AreEqual(Expected('CAT', LIndex), Format('%d %s %s', [LArchive.Count, LPlain.ToHex, LWithName.ToHex]),
      'CAT ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeLeggereLeMappeComeOpenXcom;
var
  LIndex: Integer;
  LBytes: TBytes;
  LReader: IXcomMapReader;
  LHeader: TXcomMapHeader;
  LMap: TXcomMap;
  LCells: Integer;
  LFnv: TXcomFnv;
  LCell: TXcomMapCell;
  LChecked: Integer;
begin
  LReader := TXcomFactory.CreateMapReader;
  LChecked := 0;
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    LBytes := TXcomCases.MapFile(LIndex);
    LHeader := LReader.ReadHeader(LBytes);
    LCells := (Length(LBytes) - 3) div 4;
    LFnv.Start;
    try
      LMap := LReader.Read(LBytes);
    except
      on EXcomDataException do
      begin
        // the size is not more than 0 or there are more cells than it says: no cells to compare, the size yes
        Assert.IsTrue((LHeader.SizeX <= 0) or (LHeader.SizeY <= 0) or (LHeader.SizeZ <= 0) or
          (LCells > LHeader.SizeX * LHeader.SizeY * LHeader.SizeZ));
        Assert.StartsWith(Format('%d %d %d %d ', [LHeader.SizeY, LHeader.SizeX, LHeader.SizeZ, LCells]),
          Expected('MAP', LIndex));
        Continue;
      end;
    end;
    for LCell in LMap.Cells do
    begin
      LFnv.AddByte(LCell.Floor);
      LFnv.AddByte(LCell.WestWall);
      LFnv.AddByte(LCell.NorthWall);
      LFnv.AddByte(LCell.Obj);
    end;
    Assert.AreEqual(Expected('MAP', LIndex), Format('%d %d %d %d %s', [LHeader.SizeY, LHeader.SizeX, LHeader.SizeZ,
      Length(LMap.Cells), LFnv.ToHex]), 'MAP ' + IntToStr(LIndex));
    Inc(LChecked);
  end;
  Assert.IsTrue(LChecked > 50, 'troppo pochi casi validi per essere un confronto: ' + IntToStr(LChecked));
end;

procedure TTestXcomGolden.DovrebbeLeggereIPercorsiComeOpenXcom;
var
  LIndex: Integer;
  LCase: TXcomRouteCase;
  LReader: IXcomRouteReader;
  LRecords: TArray<TXcomRmpRecord>;
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
  LFnv: TXcomFnv;
  LNode: TXcomRouteNode;
  LLink: Integer;
  LValue: Integer;
begin
  LReader := TXcomFactory.CreateRouteReader;
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    LCase := TXcomCases.Route(LIndex);
    LRecords := LReader.Read(LCase.Bytes);
    LNodes := LReader.Resolve(LRecords, LCase.SizeX, LCase.SizeY, LCase.SizeZ, LCase.OffsetX, LCase.OffsetY,
      LCase.NodeOffset, LCulled);
    LFnv.Start;
    LFnv.AddU32(Cardinal(Length(LRecords)));
    for LNode in LNodes do
    begin
      if LNode.IsDummy then
        LFnv.AddU32(1)
      else
      begin
        LFnv.AddU32(0);
        LFnv.AddU32(Cardinal(LNode.X));
        LFnv.AddU32(Cardinal(LNode.Y));
        LFnv.AddU32(Cardinal(LNode.Z));
        LFnv.AddU32(Cardinal(LNode.Index));
        LFnv.AddU32(Cardinal(LNode.NodeType));
        LFnv.AddU32(Cardinal(LNode.Rank));
        LFnv.AddU32(Cardinal(LNode.Flags));
        LFnv.AddU32(Cardinal(LNode.Reserved));
        LFnv.AddU32(Cardinal(LNode.Priority));
        for LLink := 0 to XCOM_RMP_LINKS - 1 do
          LFnv.AddU32(Cardinal(LNode.Links[LLink]));
      end;
    end;
    LFnv.AddU32(Cardinal(Length(LCulled)));
    for LValue in LCulled do
      LFnv.AddU32(Cardinal(LValue));
    Assert.AreEqual(Expected('RMP', LIndex), Format('%d %d %s', [Length(LRecords), Length(LCulled), LFnv.ToHex]),
      'RMP ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeLeggereIlTerrenoComeOpenXcom;
var
  LIndex: Integer;
  LReader: IXcomMcdReader;
  LRecords: TArray<TXcomMcdRecord>;
  LRecord: TXcomMcdRecord;
  LFnv: TXcomFnv;
  LValid: Integer;
  LValidCases: Integer;
begin
  LReader := TXcomFactory.CreateMcdReader;
  LValidCases := 0;
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    LRecords := LReader.Read(TXcomCases.Mcd(LIndex));
    LFnv.Start;
    for LRecord in LRecords do
    begin
      LFnv.AddU32(LRecord.Frame[0]);
      LFnv.AddU32(LRecord.Frame[7]);
      LFnv.AddU32(LRecord.Loft[0]);
      LFnv.AddU32(LRecord.Loft[11]);
      LFnv.AddU32(LRecord.ScanG);
      LFnv.AddU32(LRecord.U23);
      LFnv.AddU32(LRecord.U30);
      LFnv.AddU32(LRecord.UfoDoor);
      LFnv.AddU32(LRecord.StopLos);
      LFnv.AddU32(LRecord.NoFloor);
      LFnv.AddU32(LRecord.BigWall);
      LFnv.AddU32(LRecord.Gravlift);
      LFnv.AddU32(LRecord.Door);
      LFnv.AddU32(LRecord.BlockFire);
      LFnv.AddU32(LRecord.BlockSmoke);
      LFnv.AddU32(LRecord.U39);
      LFnv.AddU32(LRecord.TuWalk);
      LFnv.AddU32(LRecord.TuSlide);
      LFnv.AddU32(LRecord.TuFly);
      LFnv.AddU32(LRecord.Armor);
      LFnv.AddU32(LRecord.HeBlock);
      LFnv.AddU32(LRecord.DieMcd);
      LFnv.AddU32(LRecord.Flammable);
      LFnv.AddU32(LRecord.AltMcd);
      LFnv.AddU32(LRecord.U48);
      LFnv.AddU32(Cardinal(Integer(LRecord.TerrainLevel)));
      LFnv.AddU32(LRecord.PLevel);
      LFnv.AddU32(LRecord.U51);
      LFnv.AddU32(LRecord.LightBlock);
      LFnv.AddU32(LRecord.Footstep);
      LFnv.AddU32(LRecord.TileType);
      LFnv.AddU32(LRecord.HeType);
      LFnv.AddU32(LRecord.HeStrength);
      LFnv.AddU32(LRecord.SmokeBlockage);
      LFnv.AddU32(LRecord.Fuel);
      LFnv.AddU32(LRecord.LightSource);
      LFnv.AddU32(LRecord.TargetType);
      LFnv.AddU32(LRecord.XcomBase);
      LFnv.AddU32(LRecord.U62);
    end;
    LValid := 1;
    try
      LReader.Validate(LRecords);
    except
      on EXcomDataException do
        LValid := 0;
    end;
    Inc(LValidCases, LValid);
    Assert.AreEqual(Expected('MCD', LIndex), Format('%d %d %s', [Length(LRecords), LValid, LFnv.ToHex]),
      'MCD ' + IntToStr(LIndex));
  end;
  Assert.IsTrue(LValidCases > 20, 'troppo pochi terreni validi: ' + IntToStr(LValidCases));
end;

procedure TTestXcomGolden.DovrebbeLeggereIlGloboComeOpenXcom;
var
  LIndex: Integer;
  LReader: IXcomWorldReader;
  LPolygons: TArray<TXcomWorldPolygon>;
  LPolygon: TXcomWorldPolygon;
  LFnv: TXcomFnv;
  LPoint: Integer;
  LLongitude: Double;
  LLatitude: Double;
begin
  LReader := TXcomFactory.CreateWorldReader;
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    LPolygons := LReader.Read(TXcomCases.World(LIndex));
    LFnv.Start;
    for LPolygon in LPolygons do
    begin
      LFnv.AddU32(Cardinal(LPolygon.Points));
      for LPoint := 0 to LPolygon.Points - 1 do
      begin
        LLongitude := LPolygon.Longitude[LPoint];
        LLatitude := LPolygon.Latitude[LPoint];
        LFnv.AddU64(PUInt64(@LLongitude)^);
        LFnv.AddU64(PUInt64(@LLatitude)^);
      end;
      LFnv.AddU32(Cardinal(LPolygon.Texture));
    end;
    Assert.AreEqual(Expected('WORLD', LIndex), Format('%d %s', [Length(LPolygons), LFnv.ToHex]),
      'WORLD ' + IntToStr(LIndex));
  end;
end;

procedure TTestXcomGolden.DovrebbeLeggereLeTabelleDiParoleComeOpenXcom;
var
  LIndex: Integer;
  LWords: TArray<Word>;
  LWord: Word;
  LFnv: TXcomFnv;
begin
  for LIndex := 0 to XCOM_CASES - 1 do
  begin
    LWords := TXcomFactory.CreateWordTableReader.Read(TXcomCases.WordTable(LIndex));
    LFnv.Start;
    for LWord in LWords do
      LFnv.AddU32(LWord);
    Assert.AreEqual(Expected('WORD', LIndex), Format('%d %s', [Length(LWords), LFnv.ToHex]), 'WORD ' + IntToStr(LIndex));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGolden);

end.
