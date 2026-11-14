{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixMapInfoReader and of TRadixSlopePlanes           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.MapInfo;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.MapInfo.Types;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixMapInfoReader = class(TObject)
  strict private
    FReader: IRadixMapInfoReader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareNienteDaUnTestoVuoto;
    [Test]
    procedure DovrebbeLeggereLaPosizioneEIFlagDiUnSettore;
    [Test]
    procedure DovrebbeDareIValoriDiUnSettoreNonNominatoAiCampiNonDati;
    [Test]
    procedure DovrebbeLeggereLePendenzeEITrePunti;
    [Test]
    procedure DovrebbeLeggereGliAngoliDeiFlatAncheSeScrittiNegativi;
    [Test]
    procedure DovrebbeDareLeIstruzioniAlSettoreZeroPrimaDiSectorid;
    [Test]
    procedure DovrebbeTenereUnSettoreSoloAncheSeNominatoDueVolte;
    [Test]
    procedure DovrebbeLeggereIMuri;
    [Test]
    procedure DovrebbeLeggereLineBriefingIgnoreSenzaNumeri;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleELeParoleSconosciute;
    [Test]
    procedure DovrebbeDareErroreSeMancaUnNumero;
    [Test]
    procedure DovrebbeDareErroreSeIlNumeroNonEUnNumero;
    [Test]
    procedure DovrebbeRicominciareDaCapoAOgniLettura;
  end;

  [TestFixture]
  [Category('radix')]
  TTestRadixSlopePlanes = class(TObject)
  strict private
    function Sector(AXMul, AXAdd, AYMul, AYAdd: Integer): TRadixSectorInfo;
  public
    [Test]
    procedure DovrebbePortareLeCoordinateDiRadixInQuelleDiDoom;
    [Test]
    procedure DovrebbeDareUnPianoOrizzontaleDaTrePuntiAllaStessaAltezza;
    [Test]
    procedure DovrebbePassarePerITrePunti;
    [Test]
    procedure DovrebbeDareNonValidoPerTrePuntiAllineati;
    [Test]
    procedure DovrebbeFareIlPianoDelPavimentoEDelSoffittoDelSettore;
    [Test]
    [TestCase('zero', '0,0')]
    [TestCase('un passo', '1,2097152')]
    [TestCase('un quarto di giro', '1024,2147483648')]
    [TestCase('mezzo giro torna a zero', '2048,0')]
    [TestCase('tre quarti', '3072,2147483648')]
    procedure DovrebbePortareLAngoloDiRadixInQuelloDelMotore(ARadixAngle: Integer; const AExpected: string);
  end;

  /// <summary>The RMAP that the library writes for the levels of the real RADIX.DAT, read back</summary>
  [TestFixture]
  [Category('radix')]
  TTestRadixMapInfoRealData = class(TObject)
  strict private
    FWad: IInterface;
    FSkipReason: string;
    function FindData: string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeNominareOgniSettoreDiOgniLivello;
    [Test]
    procedure DovrebbeFarePassareIPianiPerIPuntiDelLivello;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Math,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.Factory,
  DelphiDoom.Radix.MapInfo.Reader, DelphiDoom.Radix.SlopePlanes, DelphiDoom.Tests.Shared.Skip;

const
  MAP_SECTOR_SIZE = 26;

{ TTestRadixMapInfoReader }

procedure TTestRadixMapInfoReader.Setup;
begin
  FReader := TRadixFactory.CreateMapInfoReader;
end;

procedure TTestRadixMapInfoReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestRadixMapInfoReader.DovrebbeDareNienteDaUnTestoVuoto;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('');
  Assert.AreEqual(0, Integer(Length(LInfo.Sectors)));
  Assert.AreEqual(0, Integer(Length(LInfo.Walls)));
  LInfo := FReader.Read(#13#10'  '#9#13#10);
  Assert.AreEqual(0, Integer(Length(LInfo.Sectors)));
end;

procedure TTestRadixMapInfoReader.DovrebbeLeggereLaPosizioneEIFlagDiUnSettore;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('sectorid 5'#13#10'xmul 1'#13#10'xadd -32000'#13#10'ymul -1'#13#10'yadd 31000'#13#10 +
    'sectorflags 16385'#13#10#13#10);
  Assert.AreEqual(1, Integer(Length(LInfo.Sectors)));
  Assert.AreEqual(5, LInfo.Sectors[0].SectorId);
  Assert.AreEqual(1, LInfo.Sectors[0].XMul);
  Assert.AreEqual(-32000, LInfo.Sectors[0].XAdd);
  Assert.AreEqual(-1, LInfo.Sectors[0].YMul);
  Assert.AreEqual(31000, LInfo.Sectors[0].YAdd);
  Assert.AreEqual(16385, LInfo.Sectors[0].Flags);
  Assert.IsTrue(LInfo.Sectors[0].Statements = [rssXMul, rssXAdd, rssYMul, rssYAdd, rssFlags]);
end;

procedure TTestRadixMapInfoReader.DovrebbeDareIValoriDiUnSettoreNonNominatoAiCampiNonDati;
var
  LInfo: TRadixMapInfo;
  LDefault: TRadixSectorInfo;
begin
  LInfo := FReader.Read('sectorid 2');
  Assert.AreEqual(1, Integer(Length(LInfo.Sectors)));
  Assert.IsTrue(LInfo.Sectors[0].Statements = []);
  Assert.AreEqual(1, LInfo.Sectors[0].XMul);
  Assert.AreEqual(1, LInfo.Sectors[0].YMul);
  Assert.AreEqual(0, LInfo.Sectors[0].XAdd);
  Assert.AreEqual(0, LInfo.Sectors[0].Flags);
  LDefault := TRadixMapInfoReader.DefaultSector(9);
  Assert.AreEqual(9, LDefault.SectorId);
  Assert.AreEqual(1, LDefault.XMul);
  Assert.AreEqual(1, LDefault.YMul);
end;

procedure TTestRadixMapInfoReader.DovrebbeLeggereLePendenzeEITrePunti;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('sectorid 1 floorslope 10 -20 30 -40 ceilingslope 1 2 3 4'#13#10 +
    'heightnodesx 100 200 300'#13#10'heightnodesy 400 500 600'#13#10 +
    'floorheights 0 64 128'#13#10'ceilingheights 256 320 384');
  Assert.AreEqual(1, Integer(Length(LInfo.Sectors)));
  Assert.AreEqual(10, LInfo.Sectors[0].FloorSlope.A);
  Assert.AreEqual(-20, LInfo.Sectors[0].FloorSlope.B);
  Assert.AreEqual(30, LInfo.Sectors[0].FloorSlope.C);
  Assert.AreEqual(-40, LInfo.Sectors[0].FloorSlope.D);
  Assert.AreEqual(4, LInfo.Sectors[0].CeilingSlope.D);
  Assert.AreEqual(300, LInfo.Sectors[0].HeightNodesX[2]);
  Assert.AreEqual(400, LInfo.Sectors[0].HeightNodesY[0]);
  Assert.AreEqual(64, LInfo.Sectors[0].FloorHeights[1]);
  Assert.AreEqual(384, LInfo.Sectors[0].CeilingHeights[2]);
  Assert.IsTrue(LInfo.Sectors[0].Statements = [rssFloorSlope, rssCeilingSlope, rssHeightNodesX,
    rssHeightNodesY, rssFloorHeights, rssCeilingHeights]);
end;

procedure TTestRadixMapInfoReader.DovrebbeLeggereGliAngoliDeiFlatAncheSeScrittiNegativi;
var
  LInfo: TRadixMapInfo;
begin
  // the old code wrote a LongWord with itoa: past 2^31 it is a negative number
  LInfo := FReader.Read('sectorid 0 floorangle 1024 floorangle_x 7 floorangle_y 9 ' +
    'ceilingangle -2 ceilingangle_x 4294967295 ceilingangle_y 0');
  Assert.AreEqual(Cardinal(1024), LInfo.Sectors[0].FloorAngle);
  Assert.AreEqual(Cardinal(7), LInfo.Sectors[0].FloorAngleX);
  Assert.AreEqual(Cardinal(9), LInfo.Sectors[0].FloorAngleY);
  Assert.AreEqual(Cardinal($FFFFFFFE), LInfo.Sectors[0].CeilingAngle);
  Assert.AreEqual(Cardinal($FFFFFFFF), LInfo.Sectors[0].CeilingAngleX);
  Assert.IsTrue(rssCeilingAngleY in LInfo.Sectors[0].Statements);
end;

procedure TTestRadixMapInfoReader.DovrebbeDareLeIstruzioniAlSettoreZeroPrimaDiSectorid;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('xadd 12 sectorid 3 xadd 34');
  Assert.AreEqual(2, Integer(Length(LInfo.Sectors)));
  Assert.AreEqual(0, LInfo.Sectors[0].SectorId);
  Assert.AreEqual(12, LInfo.Sectors[0].XAdd);
  Assert.AreEqual(3, LInfo.Sectors[1].SectorId);
  Assert.AreEqual(34, LInfo.Sectors[1].XAdd);
end;

procedure TTestRadixMapInfoReader.DovrebbeTenereUnSettoreSoloAncheSeNominatoDueVolte;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('sectorid 3 xadd 1 sectorid 4 xadd 2 sectorid 3 xadd 5 yadd 6');
  Assert.AreEqual(2, Integer(Length(LInfo.Sectors)));
  Assert.AreEqual(3, LInfo.Sectors[0].SectorId);
  Assert.AreEqual(5, LInfo.Sectors[0].XAdd);
  Assert.AreEqual(6, LInfo.Sectors[0].YAdd);
  Assert.AreEqual(2, LInfo.Sectors[1].XAdd);
end;

procedure TTestRadixMapInfoReader.DovrebbeLeggereIMuri;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('wallid 7'#13#10'wallflags 258'#13#10'wallhitpoints 100'#13#10'walltrigger 12'#13#10 +
    'wallid 9 wallflags 1');
  Assert.AreEqual(2, Integer(Length(LInfo.Walls)));
  Assert.AreEqual(7, LInfo.Walls[0].WallId);
  Assert.AreEqual(258, LInfo.Walls[0].Flags);
  Assert.AreEqual(100, LInfo.Walls[0].HitPoints);
  Assert.AreEqual(12, LInfo.Walls[0].Trigger);
  Assert.IsTrue(LInfo.Walls[0].Statements = [rwsFlags, rwsHitPoints, rwsTrigger]);
  Assert.AreEqual(9, LInfo.Walls[1].WallId);
  Assert.IsTrue(LInfo.Walls[1].Statements = [rwsFlags]);
  Assert.AreEqual(0, Integer(Length(LInfo.Sectors)));
end;

procedure TTestRadixMapInfoReader.DovrebbeLeggereLineBriefingIgnoreSenzaNumeri;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('wallid 665 LINEBRIEFINGIGNORE'#13#10'wallid 666 wallflags 4');
  Assert.AreEqual(2, Integer(Length(LInfo.Walls)));
  Assert.IsTrue(LInfo.Walls[0].Statements = [rwsBriefingIgnore]);
  Assert.AreEqual(4, LInfo.Walls[1].Flags);
end;

procedure TTestRadixMapInfoReader.DovrebbeIgnorareLeMaiuscoleELeParoleSconosciute;
var
  LInfo: TRadixMapInfo;
begin
  LInfo := FReader.Read('SectorID 1 unknown XAdd 44 another 5 WallId 2 WALLFLAGS 3');
  Assert.AreEqual(1, Integer(Length(LInfo.Sectors)));
  Assert.AreEqual(44, LInfo.Sectors[0].XAdd);
  Assert.AreEqual(1, Integer(Length(LInfo.Walls)));
  Assert.AreEqual(3, LInfo.Walls[0].Flags);
end;

procedure TTestRadixMapInfoReader.DovrebbeDareErroreSeMancaUnNumero;
begin
  Assert.WillRaise(
    procedure
    begin
      FReader.Read('sectorid 1 heightnodesx 1 2');
    end, ERadixException);
  Assert.WillRaise(
    procedure
    begin
      FReader.Read('sectorid');
    end, ERadixException);
end;

procedure TTestRadixMapInfoReader.DovrebbeDareErroreSeIlNumeroNonEUnNumero;
begin
  Assert.WillRaise(
    procedure
    begin
      FReader.Read('sectorid 1 xadd twelve');
    end, ERadixException);
end;

procedure TTestRadixMapInfoReader.DovrebbeRicominciareDaCapoAOgniLettura;
var
  LInfo: TRadixMapInfo;
begin
  FReader.Read('sectorid 1 xadd 5 wallid 2 wallflags 1');
  LInfo := FReader.Read('sectorid 8 yadd 3');
  Assert.AreEqual(1, Integer(Length(LInfo.Sectors)));
  Assert.AreEqual(8, LInfo.Sectors[0].SectorId);
  Assert.AreEqual(0, Integer(Length(LInfo.Walls)));
end;

{ TTestRadixSlopePlanes }

function TTestRadixSlopePlanes.Sector(AXMul, AXAdd, AYMul, AYAdd: Integer): TRadixSectorInfo;
begin
  Result := TRadixMapInfoReader.DefaultSector(0);
  Result.XMul := AXMul;
  Result.XAdd := AXAdd;
  Result.YMul := AYMul;
  Result.YAdd := AYAdd;
end;

procedure TTestRadixSlopePlanes.DovrebbePortareLeCoordinateDiRadixInQuelleDiDoom;
var
  LSector: TRadixSectorInfo;
begin
  LSector := Sector(1, -32000, -1, 31000);
  Assert.AreEqual(-31900, TRadixSlopePlanes.ToDoomX(LSector, 100));
  Assert.AreEqual(30900, TRadixSlopePlanes.ToDoomY(LSector, 100));
end;

procedure TTestRadixSlopePlanes.DovrebbeDareUnPianoOrizzontaleDaTrePuntiAllaStessaAltezza;
var
  LPlane: TRadixSlopePlane;
begin
  LPlane := TRadixSlopePlanes.FromPoints(0, 0, 64, 100, 0, 64, 0, 100, 64);
  Assert.IsTrue(LPlane.Valid);
  Assert.AreEqual(Double(0), Double(LPlane.A), 0.0001);
  Assert.AreEqual(Double(0), Double(LPlane.B), 0.0001);
  Assert.AreEqual(Double(64), Double(TRadixSlopePlanes.HeightAt(LPlane, 37, -512)), 0.001);
end;

procedure TTestRadixSlopePlanes.DovrebbePassarePerITrePunti;
var
  LPlane: TRadixSlopePlane;
begin
  LPlane := TRadixSlopePlanes.FromPoints(0, 0, 0, 128, 0, 64, 0, 256, 32);
  Assert.IsTrue(LPlane.Valid);
  Assert.AreEqual(Double(0), Double(TRadixSlopePlanes.HeightAt(LPlane, 0, 0)), 0.001);
  Assert.AreEqual(Double(64), Double(TRadixSlopePlanes.HeightAt(LPlane, 128, 0)), 0.001);
  Assert.AreEqual(Double(32), Double(TRadixSlopePlanes.HeightAt(LPlane, 0, 256)), 0.001);
  // the middle of the first two points
  Assert.AreEqual(Double(32), Double(TRadixSlopePlanes.HeightAt(LPlane, 64, 0)), 0.001);
end;

procedure TTestRadixSlopePlanes.DovrebbeDareNonValidoPerTrePuntiAllineati;
var
  LPlane: TRadixSlopePlane;
begin
  LPlane := TRadixSlopePlanes.FromPoints(0, 0, 0, 10, 10, 5, 20, 20, 10);
  Assert.IsFalse(LPlane.Valid);
  Assert.AreEqual(Double(0), Double(LPlane.InverseC), 0.0001);
end;

procedure TTestRadixSlopePlanes.DovrebbeFareIlPianoDelPavimentoEDelSoffittoDelSettore;
var
  LSector: TRadixSectorInfo;
  LFloor: TRadixSlopePlane;
  LCeiling: TRadixSlopePlane;
begin
  LSector := Sector(1, -1000, -1, 2000);
  LSector.HeightNodesX[0] := 1000;
  LSector.HeightNodesY[0] := 2000;
  LSector.HeightNodesX[1] := 1128;
  LSector.HeightNodesY[1] := 2000;
  LSector.HeightNodesX[2] := 1000;
  LSector.HeightNodesY[2] := 1872;
  LSector.FloorHeights[0] := 0;
  LSector.FloorHeights[1] := 64;
  LSector.FloorHeights[2] := 0;
  LSector.CeilingHeights[0] := 200;
  LSector.CeilingHeights[1] := 200;
  LSector.CeilingHeights[2] := 264;
  LFloor := TRadixSlopePlanes.Floor(LSector);
  LCeiling := TRadixSlopePlanes.Ceiling(LSector);
  Assert.IsTrue(LFloor.Valid);
  Assert.IsTrue(LCeiling.Valid);
  // the nodes in Doom coordinates: (0, 0), (128, 0) and (0, 128)
  Assert.AreEqual(Double(0), Double(TRadixSlopePlanes.HeightAt(LFloor, 0, 0)), 0.001);
  Assert.AreEqual(Double(64), Double(TRadixSlopePlanes.HeightAt(LFloor, 128, 0)), 0.001);
  Assert.AreEqual(Double(0), Double(TRadixSlopePlanes.HeightAt(LFloor, 0, 128)), 0.001);
  Assert.AreEqual(Double(200), Double(TRadixSlopePlanes.HeightAt(LCeiling, 128, 0)), 0.001);
  Assert.AreEqual(Double(264), Double(TRadixSlopePlanes.HeightAt(LCeiling, 0, 128)), 0.001);
end;

procedure TTestRadixSlopePlanes.DovrebbePortareLAngoloDiRadixInQuelloDelMotore(ARadixAngle: Integer;
  const AExpected: string);
begin
  Assert.AreEqual(Cardinal(StrToInt64(AExpected)), TRadixSlopePlanes.ToEngineAngle(Cardinal(ARadixAngle)));
end;

{ TTestRadixMapInfoRealData }

function TTestRadixMapInfoRealData.FindData: string;
const
  DATA_FILE = 'Reference\_dati\radix\v20\game\RADIX.DAT';
var
  LRoot: string;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  // the worktrees of the repository are under .claude\worktrees\<name>
  for LCandidate in TArray<string>.Create(TPath.Combine(LRoot, DATA_FILE),
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\' + DATA_FILE))) do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

procedure TTestRadixMapInfoRealData.SetupFixture;
var
  LPath: string;
begin
  FWad := nil;
  LPath := FindData;
  if LPath = '' then
  begin
    FSkipReason := 'RADIX.DAT (2.0 shareware) non c''e'': i dati del gioco non stanno nel repository';
    Exit;
  end;
  FWad := TRadixFactory.CreateTranslator.Translate(TRadixFactory.OpenContainer(LPath));
end;

procedure TTestRadixMapInfoRealData.TearDownFixture;
begin
  FWad := nil;
end;

procedure TTestRadixMapInfoRealData.DovrebbeNominareOgniSettoreDiOgniLivello;
var
  LWad: IGameWadComposer;
  LReader: IRadixMapInfoReader;
  LIndex: Integer;
  LSectorCount: Integer;
  LLevels: Integer;
  LInfo: TRadixMapInfo;
begin
  if not Assigned(FWad) then
  begin
    TTestSkip.Ignore(FSkipReason);
    Exit;
  end;
  LWad := FWad as IGameWadComposer;
  LReader := TRadixFactory.CreateMapInfoReader;
  LLevels := 0;
  LSectorCount := -1;
  for LIndex := 0 to LWad.Count - 1 do
    if LWad.LumpNames[LIndex] = 'SECTORS' then
      LSectorCount := Length(LWad.LumpData[LIndex]) div MAP_SECTOR_SIZE
    else if LWad.LumpNames[LIndex] = 'RMAP' then
    begin
      LInfo := LReader.Read(TEncoding.ANSI.GetString(LWad.LumpData[LIndex]));
      Assert.AreEqual(LSectorCount, Integer(Length(LInfo.Sectors)), 'sectors of the level ' + IntToStr(LLevels + 1));
      Assert.IsTrue(Length(LInfo.Walls) > 0, 'walls of the level ' + IntToStr(LLevels + 1));
      Inc(LLevels);
    end;
  // the shareware has the nine levels of the first episode
  Assert.AreEqual(9, LLevels);
end;

procedure TTestRadixMapInfoRealData.DovrebbeFarePassareIPianiPerIPuntiDelLivello;
const
  TOLERANCE = 0.5;
var
  LWad: IGameWadComposer;
  LReader: IRadixMapInfoReader;
  LIndex: Integer;
  LNode: Integer;
  LInfo: TRadixMapInfo;
  LSector: TRadixSectorInfo;
  LPlane: TRadixSlopePlane;
  LSlopes: Integer;
  LX, LY: Integer;
begin
  if not Assigned(FWad) then
  begin
    TTestSkip.Ignore(FSkipReason);
    Exit;
  end;
  LWad := FWad as IGameWadComposer;
  LReader := TRadixFactory.CreateMapInfoReader;
  LSlopes := 0;
  for LIndex := 0 to LWad.Count - 1 do
    if LWad.LumpNames[LIndex] = 'RMAP' then
    begin
      LInfo := LReader.Read(TEncoding.ANSI.GetString(LWad.LumpData[LIndex]));
      for LSector in LInfo.Sectors do
      begin
        if rssFloorHeights in LSector.Statements then
        begin
          LPlane := TRadixSlopePlanes.Floor(LSector);
          if LPlane.Valid then
          begin
            Inc(LSlopes);
            for LNode := 0 to 2 do
            begin
              LX := TRadixSlopePlanes.ToDoomX(LSector, LSector.HeightNodesX[LNode]);
              LY := TRadixSlopePlanes.ToDoomY(LSector, LSector.HeightNodesY[LNode]);
              Assert.AreEqual(Double(LSector.FloorHeights[LNode]),
                Double(TRadixSlopePlanes.HeightAt(LPlane, LX, LY)), TOLERANCE,
                Format('floor of the sector %d, node %d', [LSector.SectorId, LNode]));
            end;
          end;
        end;
        if rssCeilingHeights in LSector.Statements then
        begin
          LPlane := TRadixSlopePlanes.Ceiling(LSector);
          if LPlane.Valid then
          begin
            Inc(LSlopes);
            for LNode := 0 to 2 do
            begin
              LX := TRadixSlopePlanes.ToDoomX(LSector, LSector.HeightNodesX[LNode]);
              LY := TRadixSlopePlanes.ToDoomY(LSector, LSector.HeightNodesY[LNode]);
              Assert.AreEqual(Double(LSector.CeilingHeights[LNode]),
                Double(TRadixSlopePlanes.HeightAt(LPlane, LX, LY)), TOLERANCE,
                Format('ceiling of the sector %d, node %d', [LSector.SectorId, LNode]));
            end;
          end;
        end;
      end;
    end;
  Assert.IsTrue(LSlopes > 0, 'the first episode has sloped sectors');
end;

end.
