{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the real data of the games   }
{                                                                              }
{  The data of UFO: Enemy Unknown and Terror from the Deep are commercial and   }
{  are not in the repository. They are looked for in the folder of the          }
{  environment variable DELPHIDOOM_XCOM_DATA (the folder of the game: the one   }
{  that has GEODATA, GEOGRAPH, MAPS, ROUTES, TERRAIN, UNITS...), or in          }
{  Reference\_dati\xcom of a folder above the program. A test that needs them   }
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
  end;

  [TestFixture]
  [Category('xcom')]
  [Category('xcom-realdata')]
  TTestXcomRealData = class(TObject)
  private
    FFolder: string;
    FData: IXcomGameData;
    procedure SkipIfMissing;
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
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Map, DelphiDoom.Xcom.Factory;

{ TXcomRealData }

class function TXcomRealData.Folder: string;
var
  LCurrent: string;
  LCandidate: string;
  LParent: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_XCOM_DATA');
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  Result := '';
  LCurrent := ExtractFilePath(ParamStr(0));
  while LCurrent <> '' do
  begin
    LCandidate := TPath.Combine(LCurrent, 'Reference\_dati\xcom');
    if TDirectory.Exists(LCandidate) then
      Exit(LCandidate);
    LParent := ExtractFilePath(ExcludeTrailingPathDelimiter(LCurrent));
    if LParent = LCurrent then
      Break;
    LCurrent := LParent;
  end;
end;

{ TTestXcomRealData }

procedure TTestXcomRealData.Setup;
begin
  FFolder := TXcomRealData.Folder;
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
begin
  SkipIfMissing;
  for LIndex := 0 to 4 do
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

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealData);

end.
