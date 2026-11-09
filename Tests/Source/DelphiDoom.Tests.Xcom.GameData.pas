{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the data of a game           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.GameData;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.MemoryFiles;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomGameData = class(TObject)
  private
    FFiles: TXcomMemoryFiles;
    FOwner: IXcomDataFiles;
    FData: IXcomGameData;
    function Palette: TXcomPalette;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLaPaletteScelta;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteNegativa;
    [Test]
    procedure DovrebbeLeggereUnoScrDallEstensione;
    [Test]
    procedure DovrebbeLeggereUnoSpkDallEstensione;
    [Test]
    procedure DovrebbeLeggereUnBdyDallEstensione;
    [Test]
    procedure DovrebbeMettereLaPaletteSulleImmagini;
    [Test]
    procedure DovrebbeLeggereUnPckConIlSuoTab;
    [Test]
    procedure DovrebbeLeggereUnPckSenzaTab;
    [Test]
    procedure DovrebbeLeggereUnPckConUnTabCheHaUnAltroNome;
    [Test]
    procedure DovrebbeRifiutareUnTabNominatoCheNonCe;
    [Test]
    procedure DovrebbeLeggereUnDat;
    [Test]
    procedure DovrebbeLeggereUnaMappaUnPercorsoEUnTerreno;
    [Test]
    procedure DovrebbeDareIFile;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Xcom.GameData, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomGameData }

function TTestXcomGameData.Palette: TXcomPalette;
begin
  Result := TXcomPalette.Create(256);
  Result.Colors[1].Red := 200;
end;

procedure TTestXcomGameData.Setup;
var
  LPalettes: TBytes;
  LRoute: TBytes;
  LTerrain: TBytes;
begin
  FFiles := TXcomMemoryFiles.Create;
  FOwner := FFiles;
  // two palettes of 774 bytes: the first color of the second is (1, 2, 3)
  LPalettes := TXcomTestBuilders.Zeros(774 * 2);
  LPalettes[774] := 1;
  LPalettes[775] := 2;
  LPalettes[776] := 3;
  FFiles.Add('GEODATA/PALETTES.DAT', LPalettes);
  FFiles.Add('GEOGRAPH/BACK.SCR', TXcomTestBuilders.Bytes([1, 2, 3, 4]));
  FFiles.Add('GEOGRAPH/BACK.SPK', TXcomTestBuilders.Bytes([$FE, $FF, 1, 0, 5, 6]));
  FFiles.Add('GEOGRAPH/BACK.BDY', TXcomTestBuilders.Bytes([$FE, 7]));
  FFiles.Add('UNITS/MAN.PCK', TXcomTestBuilders.Bytes([0, 1, 255, 0, 2, 255]));
  FFiles.Add('UNITS/MAN.TAB', TXcomTestBuilders.Bytes([0, 0, 0, 0, 3, 0, 0, 0]));
  FFiles.Add('UNITS/OTHER.TAB', TXcomTestBuilders.Bytes([0, 0, 0, 0, 3, 0, 0, 0, 6, 0, 0, 0]));
  FFiles.Add('UNITS/ALONE.PCK', TXcomTestBuilders.Bytes([0, 9, 255]));
  FFiles.Add('UNITS/SHEET.DAT', TXcomTestBuilders.Bytes([1, 2, 3, 4]));
  FFiles.Add('MAPS/BLOCK.MAP', TXcomTestBuilders.Bytes([1, 1, 1, 9, 8, 7, 6]));
  LRoute := TXcomTestBuilders.Zeros(XCOM_RMP_RECORD_BYTES);
  FFiles.Add('ROUTES/BLOCK.RMP', LRoute);
  // armor 1 and no reference to other objects
  LTerrain := TXcomTestBuilders.Zeros(XCOM_MCD_RECORD_BYTES);
  LTerrain[42] := 1;
  FFiles.Add('TERRAIN/BLOCK.MCD', LTerrain);
  FData := TXcomFactory.CreateGameData(FOwner);
end;

procedure TTestXcomGameData.TearDown;
begin
  FData := nil;
  FOwner := nil;
  FFiles := nil;
end;

procedure TTestXcomGameData.DovrebbeLeggereLaPaletteScelta;
var
  LPalette: TXcomPalette;
begin
  LPalette := FData.LoadPalette(1);
  Assert.AreEqual(256, LPalette.Count);
  Assert.AreEqual(4, Integer(LPalette.Colors[0].Red));
  Assert.AreEqual(8, Integer(LPalette.Colors[0].Green));
  Assert.AreEqual(12, Integer(LPalette.Colors[0].Blue));
end;

procedure TTestXcomGameData.DovrebbeRifiutareUnaPaletteNegativa;
begin
  Assert.WillRaise(procedure begin FData.LoadPalette(-1); end, EXcomException);
end;

procedure TTestXcomGameData.DovrebbeLeggereUnoScrDallEstensione;
begin
  Assert.AreEqual('01 02 03 04', TXcomTestBuilders.Pixels(FData.LoadImage('GEOGRAPH/BACK.SCR', 2, 2, Palette)));
end;

procedure TTestXcomGameData.DovrebbeLeggereUnoSpkDallEstensione;
begin
  Assert.AreEqual('05 06 00 00', TXcomTestBuilders.Pixels(FData.LoadImage('GEOGRAPH/BACK.SPK', 2, 2, Palette)));
end;

procedure TTestXcomGameData.DovrebbeLeggereUnBdyDallEstensione;
begin
  Assert.AreEqual('07 07 07 00', TXcomTestBuilders.Pixels(FData.LoadImage('GEOGRAPH/BACK.BDY', 4, 1, Palette)));
end;

procedure TTestXcomGameData.DovrebbeMettereLaPaletteSulleImmagini;
var
  LImage: TXcomImage;
begin
  LImage := FData.LoadImage('GEOGRAPH/BACK.SCR', 2, 2, Palette);
  Assert.IsTrue(LImage.HasPalette);
  Assert.AreEqual(200, Integer(LImage.Palette.Colors[1].Red));
end;

procedure TTestXcomGameData.DovrebbeLeggereUnPckConIlSuoTab;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FData.LoadImageSet('UNITS/MAN.PCK', '', 2, 1, Palette);
  Assert.AreEqual(2, Integer(Length(LFrames)));
  Assert.AreEqual('02 00', TXcomTestBuilders.Pixels(LFrames[1]));
  Assert.IsTrue(LFrames[0].HasPalette);
end;

procedure TTestXcomGameData.DovrebbeLeggereUnPckSenzaTab;
begin
  Assert.AreEqual(1, Integer(Length(FData.LoadImageSet('UNITS/ALONE.PCK', '', 2, 1, Palette))));
end;

procedure TTestXcomGameData.DovrebbeLeggereUnPckConUnTabCheHaUnAltroNome;
begin
  Assert.AreEqual(3, Integer(Length(FData.LoadImageSet('UNITS/MAN.PCK', 'UNITS/OTHER.TAB', 2, 1, Palette))));
end;

procedure TTestXcomGameData.DovrebbeRifiutareUnTabNominatoCheNonCe;
begin
  Assert.WillRaise(procedure begin FData.LoadImageSet('UNITS/MAN.PCK', 'UNITS/NO.TAB', 2, 1, Palette); end,
    EXcomFileNotFoundException);
end;

procedure TTestXcomGameData.DovrebbeLeggereUnDat;
var
  LFrames: TArray<TXcomImage>;
begin
  LFrames := FData.LoadImageSet('UNITS/SHEET.DAT', '', 2, 1, Palette);
  Assert.AreEqual(2, Integer(Length(LFrames)));
  Assert.AreEqual('03 04', TXcomTestBuilders.Pixels(LFrames[1]));
end;

procedure TTestXcomGameData.DovrebbeLeggereUnaMappaUnPercorsoEUnTerreno;
begin
  Assert.AreEqual(9, Integer(FData.LoadMap('MAPS/BLOCK.MAP').Cells[0].Floor));
  Assert.AreEqual(1, Integer(Length(FData.LoadRoute('ROUTES/BLOCK.RMP'))));
  Assert.AreEqual(1, Integer(Length(FData.LoadTerrain('TERRAIN/BLOCK.MCD'))));
  Assert.WillRaise(procedure begin FData.LoadMap('MAPS/NO.MAP'); end, EXcomFileNotFoundException);
end;

procedure TTestXcomGameData.DovrebbeDareIFile;
begin
  Assert.IsTrue(FData.Files.Exists('MAPS/BLOCK.MAP'));
end;

procedure TTestXcomGameData.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomGameData.Create(nil, TXcomFactory.CreatePaletteReader, TXcomFactory.CreateScrDecoder,
        TXcomFactory.CreateSpkDecoder, TXcomFactory.CreateBdyDecoder, TXcomFactory.CreatePckDecoder,
        TXcomFactory.CreateDatDecoder, TXcomFactory.CreateMapReader, TXcomFactory.CreateRouteReader,
        TXcomFactory.CreateMcdReader);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGameData);

end.
