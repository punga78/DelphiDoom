{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the real data of the games   }
{                                                                              }
{  The data of UFO: Enemy Unknown and Terror from the Deep are commercial and   }
{  are not in the repository. They are looked for in the folder of the          }
{  environment variable DELPHIDOOM_XCOM_DATA (the folder of the game: the one   }
{  that has GEODATA, GEOGRAPH, MAPS, ROUTES, TERRAIN, UNITS...), or in          }
{  Reference\_dati\xcom or Reference\_dati\xcom_tftd\TFTD of a folder above the  }
{  program. A test that needs them                                              }
{  is skipped if they are not there                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.RealData;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Intf;

type
  TXcomRealData = class
  public
    /// <summary>The folder of the real game, or an empty string if it is not on this machine</summary>
    class function Folder: string; static;
    /// <summary>The folder of the real TFTD data (xcom_tftd\TFTD), or an empty string</summary>
    class function TftdFolder: string; static;
    /// <summary>The folder of the real UFO data (xcom_ufo\UFO Enemy Unkown\DOS game), or an empty string</summary>
    class function UfoFolder: string; static;
  private
    class function FindFolder(const ARelative: string): string; static;
  end;

  TTestXcomRealData = class(TObject)
  strict protected
    FFolder: string;
    FData: IXcomGameData;
    procedure SkipIfMissing;
    function FindGameFolder: string; virtual;
    /// <summary>The path of LOFTEMPS.DAT in the game folder (TERRAIN in TFTD, GEODATA in UFO)</summary>
    function LoftempsPath: string; virtual;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLeCinquePalettiDellaGeoscape;
    [Test]
    procedure DovrebbeDecodificareOgniFilePckConIlSuoTab;
    [Test]
    procedure DovrebbeDecodificareGliSchermiScrDellaGeoscape;
    [Test]
    procedure DovrebbeLeggereOgniMappaDellaBattaglia;
    [Test]
    procedure DovrebbeLeggereOgniPercorsoDellaBattaglia;
    [Test]
    procedure DovrebbeLeggereOgniTerreno;
    [Test]
    procedure DovrebbeLeggereOgniFileCatDelSuono;
    [Test]
    procedure DovrebbeLeggereIPoligoniDelGlobo;
    [Test]
    procedure DovrebbeLeggereLaTabellaDelleForme;
    [Test]
    procedure DovrebbeDecodificareOgniBdyESpkConDatiDentroLImmagine;
    [Test]
    procedure DovrebbeTrovareNelPckOgniFotogrammaCheUnTerrenoUsa;
  end;

  /// <summary>The same tests on the real TFTD data</summary>
  [TestFixture]
  [Category('xcom')]
  [Category('xcom-realdata')]
  TTestXcomRealDataTftd = class(TTestXcomRealData)
  protected
    function FindGameFolder: string; override;
  end;

  /// <summary>The same tests on the real UFO: Enemy Unknown data (five palettes, SOUND1/2.CAT, LOFTEMPS in GEODATA)</summary>
  [TestFixture]
  [Category('xcom')]
  [Category('xcom-realdata')]
  TTestXcomRealDataUfo = class(TTestXcomRealData)
  protected
    function FindGameFolder: string; override;
    function LoftempsPath: string; override;
  public
    [Test]
    procedure DovrebbeAvereCinquePalettiDiUfo;
    [Test]
    procedure DovrebbeTrovareICatDelSuonoDiUfo;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Map, DelphiDoom.Xcom.Factory;

{ TXcomRealData }

class function TXcomRealData.FindFolder(const ARelative: string): string;
var
  LCurrent: string;
  LCandidate: string;
  LParent: string;
begin
  Result := '';
  LCurrent := ExtractFilePath(ParamStr(0));
  while LCurrent <> '' do
  begin
    LCandidate := TPath.Combine(LCurrent, ARelative);
    if TDirectory.Exists(LCandidate) then
      Exit(LCandidate);
    LParent := ExtractFilePath(ExcludeTrailingPathDelimiter(LCurrent));
    if LParent = LCurrent then
      Break;
    LCurrent := LParent;
  end;
end;

class function TXcomRealData.TftdFolder: string;
begin
  Result := FindFolder('Reference\_dati\xcom_tftd\TFTD');
end;

class function TXcomRealData.UfoFolder: string;
begin
  Result := FindFolder('Reference\_dati\xcom_ufo\UFO Enemy Unkown\DOS game');
end;

class function TXcomRealData.Folder: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_XCOM_DATA');
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  // the first one found: UFO (xcom), TFTD, then the UFO of the DOS install
  Result := FindFolder('Reference\_dati\xcom');
  if Result = '' then
    Result := TftdFolder;
  if Result = '' then
    Result := UfoFolder;
end;

{ TTestXcomRealData }

function TTestXcomRealData.FindGameFolder: string;
begin
  Result := TXcomRealData.Folder;
end;

function TTestXcomRealData.LoftempsPath: string;
begin
  Result := 'TERRAIN\LOFTEMPS.DAT';
end;

procedure TTestXcomRealData.Setup;
begin
  FFolder := FindGameFolder;
  if (FFolder <> '') and TFile.Exists(TPath.Combine(FFolder, 'GEODATA\PALETTES.DAT')) then
    FData := TXcomFactory.CreateGameData(TXcomFactory.CreateFolderFiles([FFolder]));
end;

procedure TTestXcomRealData.TearDown;
begin
  FData := nil;
end;

procedure TTestXcomRealData.SkipIfMissing;
begin
  if not Assigned(FData) then
    Assert.Pass('I dati di UFO o TFTD non ci sono su questo PC: prova saltata');
end;

procedure TTestXcomRealData.DovrebbeLeggereLeCinquePalettiDellaGeoscape;
var
  LIndex: Integer;
  LPalettes: Integer;
begin
  SkipIfMissing;
  // UFO has five palettes of 774 bytes (768 + 6 of header), TFTD three (2322 bytes): the real
  // TFTD data showed that a palette past the end of the file has no color with alpha 255
  LPalettes := Integer(TFile.GetSize(TPath.Combine(FFolder, 'GEODATA\PALETTES.DAT'))) div XCOM_PALETTE_STRIDE;
  Assert.IsTrue(LPalettes >= 3, 'PALETTES.DAT troppo corto');
  for LIndex := 0 to LPalettes - 1 do
  begin
    Assert.AreEqual(256, FData.LoadPalette(LIndex).Count);
    Assert.AreEqual(0, Integer(FData.LoadPalette(LIndex).Colors[0].Alpha));
    Assert.AreEqual(255, Integer(FData.LoadPalette(LIndex).Colors[1].Alpha));
  end;
end;

procedure TTestXcomRealData.DovrebbeDecodificareOgniFilePckConIlSuoTab;
var
  LPath: string;
  LName: string;
  LFrames: TArray<TXcomImage>;
  LCount: Integer;
begin
  SkipIfMissing;
  LCount := 0;
  for LPath in TDirectory.GetFiles(FFolder, '*.PCK', TSearchOption.soAllDirectories) do
  begin
    LName := LPath.Substring(Length(IncludeTrailingPathDelimiter(FFolder)));
    if not TFile.Exists(TPath.ChangeExtension(LPath, '.TAB')) then
      Continue;
    // every file has frames of the size of its set: 32 x 40 for the terrain, whatever for the others;
    // 32 x 40 only to see that the decoder gets to the end of the file with no error
    LFrames := FData.LoadImageSet(LName, '', 32, 40, FData.LoadPalette(0));
    Assert.IsTrue(Length(LFrames) > 0, LName);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun file PCK con il suo TAB');
end;

procedure TTestXcomRealData.DovrebbeDecodificareGliSchermiScrDellaGeoscape;
var
  LPath: string;
  LImage: TXcomImage;
  LCount: Integer;
begin
  SkipIfMissing;
  LCount := 0;
  for LPath in TDirectory.GetFiles(TPath.Combine(FFolder, 'GEOGRAPH'), '*.SCR') do
  begin
    LImage := FData.LoadImage('GEOGRAPH\' + TPath.GetFileName(LPath), 320, 200, FData.LoadPalette(0));
    Assert.AreEqual(320 * 200, Integer(Length(LImage.Pixels)));
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun file SCR');
end;

procedure TTestXcomRealData.DovrebbeLeggereOgniMappaDellaBattaglia;
var
  LPath: string;
  LMap: TXcomMap;
  LCount: Integer;
begin
  SkipIfMissing;
  LCount := 0;
  for LPath in TDirectory.GetFiles(TPath.Combine(FFolder, 'MAPS'), '*.MAP') do
  begin
    LMap := FData.LoadMap('MAPS\' + TPath.GetFileName(LPath));
    Assert.IsTrue((LMap.SizeX > 0) and (LMap.SizeY > 0) and (LMap.SizeZ > 0), LPath);
    Assert.IsTrue(Length(LMap.Cells) <= LMap.SizeX * LMap.SizeY * LMap.SizeZ, LPath);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun file MAP');
end;

procedure TTestXcomRealData.DovrebbeLeggereOgniPercorsoDellaBattaglia;
var
  LPath: string;
  LCount: Integer;
begin
  SkipIfMissing;
  LCount := 0;
  for LPath in TDirectory.GetFiles(TPath.Combine(FFolder, 'ROUTES'), '*.RMP') do
  begin
    // UFO ships four empty files (ROUTES\TEMP.RMP .. TEMP3.RMP, 0 bytes): editor leftovers no terrain uses
    if TFile.GetSize(LPath) = 0 then
      Assert.AreEqual(0, Length(FData.LoadRoute('ROUTES\' + TPath.GetFileName(LPath))), LPath)
    else
      Assert.IsTrue(Length(FData.LoadRoute('ROUTES\' + TPath.GetFileName(LPath))) > 0, LPath);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun file RMP');
end;

procedure TTestXcomRealData.DovrebbeLeggereOgniTerreno;
var
  LPath: string;
  LCount: Integer;
begin
  SkipIfMissing;
  LCount := 0;
  for LPath in TDirectory.GetFiles(TPath.Combine(FFolder, 'TERRAIN'), '*.MCD') do
  begin
    Assert.IsTrue(Length(FData.LoadTerrain('TERRAIN\' + TPath.GetFileName(LPath))) > 0, LPath);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun file MCD');
end;

procedure TTestXcomRealData.DovrebbeLeggereOgniFileCatDelSuono;
var
  LPath: string;
  LBytes: TBytes;
  LCat: IXcomCatArchive;
  LCount: Integer;
  LIndex: Integer;
begin
  SkipIfMissing;
  LCount := 0;
  for LPath in TDirectory.GetFiles(TPath.Combine(FFolder, 'SOUND'), '*.CAT') do
  begin
    LBytes := TFile.ReadAllBytes(LPath);
    LCat := TXcomFactory.CreateCatArchive(LBytes);
    Assert.IsTrue(LCat.Count > 0, LPath);
    for LIndex := 0 to LCat.Count - 1 do
      Assert.IsTrue(Int64(LCat.Entries[LIndex].Offset) + LCat.Entries[LIndex].Size <= Length(LBytes),
        Format('%s: la voce %d va oltre la fine del file', [LPath, LIndex]));
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun file CAT');
end;

procedure TTestXcomRealData.DovrebbeLeggereIPoligoniDelGlobo;
var
  LPolygons: TArray<TXcomWorldPolygon>;
  LIndex: Integer;
begin
  SkipIfMissing;
  LPolygons := TXcomFactory.CreateWorldReader.Read(FData.GetFiles.ReadAll('GEODATA\WORLD.DAT'));
  Assert.IsTrue(Length(LPolygons) > 100, 'pochi poligoni');
  for LIndex := 0 to High(LPolygons) do
  begin
    Assert.IsTrue(LPolygons[LIndex].Points in [3, 4], Format('poligono %d: %d punti', [LIndex, LPolygons[LIndex].Points]));
    Assert.IsTrue((LPolygons[LIndex].Texture >= 0) and (LPolygons[LIndex].Texture < 32),
      Format('poligono %d: texture %d', [LIndex, LPolygons[LIndex].Texture]));
  end;
end;

procedure TTestXcomRealData.DovrebbeLeggereLaTabellaDelleForme;
var
  LWords: TArray<Word>;
begin
  SkipIfMissing;
  LWords := TXcomFactory.CreateWordTableReader.Read(FData.GetFiles.ReadAll(LoftempsPath));
  Assert.IsTrue(Length(LWords) > 0);
  // every shape (a voxel layout) is 16 words, one for each layer of 16 x 16 voxels
  Assert.AreEqual(0, Integer(Length(LWords) mod 16));
end;

procedure TTestXcomRealData.DovrebbeDecodificareOgniBdyESpkConDatiDentroLImmagine;
var
  LPath: string;
  LImage: TXcomImage;
  LPixel: Byte;
  LHasData: Boolean;
  LCount: Integer;
begin
  SkipIfMissing;
  LCount := 0;
  for LPath in TDirectory.GetFiles(TPath.Combine(FFolder, 'UFOGRAPH'), '*.*') do
  begin
    if SameText(TPath.GetExtension(LPath), '.BDY') then
      LImage := TXcomFactory.CreateBdyDecoder.Decode(TFile.ReadAllBytes(LPath), 320, 200)
    else if SameText(TPath.GetExtension(LPath), '.SPK') then
      LImage := TXcomFactory.CreateSpkDecoder.Decode(TFile.ReadAllBytes(LPath), 320, 200)
    else
      Continue;
    Assert.AreEqual(320 * 200, Integer(Length(LImage.Pixels)), LPath);
    LHasData := False;
    for LPixel in LImage.Pixels do
      if LPixel <> 0 then
      begin
        LHasData := True;
        Break;
      end;
    Assert.IsTrue(LHasData, 'immagine vuota: ' + LPath);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun file BDY o SPK');
end;

procedure TTestXcomRealData.DovrebbeTrovareNelPckOgniFotogrammaCheUnTerrenoUsa;
var
  LPath: string;
  LPck: string;
  LRecords: TArray<TXcomMcdRecord>;
  LFrames: TArray<TXcomImage>;
  LRecord: Integer;
  LFrame: Integer;
  LCount: Integer;
  LOutside: string;
begin
  SkipIfMissing;
  LCount := 0;
  LOutside := '';
  for LPath in TDirectory.GetFiles(TPath.Combine(FFolder, 'TERRAIN'), '*.MCD') do
  begin
    LPck := TPath.ChangeExtension(LPath, '.PCK');
    // a few terrain sets of TFTD (ISLAND4, XBASE1, XBASE2) are only MCD: they use the frames of another set
    if not TFile.Exists(LPck) then
      Continue;
    LRecords := FData.LoadTerrain('TERRAIN\' + TPath.GetFileName(LPath));
    LFrames := FData.LoadImageSet('TERRAIN\' + TPath.GetFileName(LPck), '', 32, 40, FData.LoadPalette(0));
    for LRecord := 0 to High(LRecords) do
      for LFrame := 0 to 7 do
        // XBASES05 of TFTD (floppy 1.0 data) has the objects 39, 40 and 41 (frames 74, 75, 76) outside its 74
        // frames: the original game has this defect and never draws them, so it is the one that is accepted
        if (LRecords[LRecord].Frame[LFrame] >= Length(LFrames)) and
          not (SameText(TPath.GetFileNameWithoutExtension(LPath), 'XBASES05') and (LRecord in [39..41])) then
          LOutside := LOutside + Format('%s: l''oggetto %d usa il fotogramma %d di %d'#13#10,
            [TPath.GetFileName(LPath), LRecord, LRecords[LRecord].Frame[LFrame], Length(LFrames)]);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun terreno con MCD e PCK');
  Assert.AreEqual('', LOutside, 'fotogrammi fuori dal PCK');
end;

{ TTestXcomRealDataTftd }

function TTestXcomRealDataTftd.FindGameFolder: string;
begin
  Result := TXcomRealData.TftdFolder;
end;

{ TTestXcomRealDataUfo }

function TTestXcomRealDataUfo.FindGameFolder: string;
begin
  Result := TXcomRealData.UfoFolder;
end;

function TTestXcomRealDataUfo.LoftempsPath: string;
begin
  Result := 'GEODATA\LOFTEMPS.DAT';
end;

procedure TTestXcomRealDataUfo.DovrebbeAvereCinquePalettiDiUfo;
begin
  SkipIfMissing;
  Assert.AreEqual(5, Integer(TFile.GetSize(TPath.Combine(FFolder, 'GEODATA\PALETTES.DAT'))) div XCOM_PALETTE_STRIDE);
end;

procedure TTestXcomRealDataUfo.DovrebbeTrovareICatDelSuonoDiUfo;
begin
  SkipIfMissing;
  Assert.IsTrue(TFile.Exists(TPath.Combine(FFolder, 'SOUND\SOUND1.CAT')));
  Assert.IsTrue(TFile.Exists(TPath.Combine(FFolder, 'SOUND\ROLAND.CAT')));
  Assert.IsTrue(TFile.Exists(TPath.Combine(FFolder, 'SOUND\ADLIB.CAT')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealDataTftd);
  TDUnitX.RegisterTestFixture(TTestXcomRealDataUfo);

end.
