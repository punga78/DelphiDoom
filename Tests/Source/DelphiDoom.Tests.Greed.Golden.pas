{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - parity with the original code       }
{                                                                              }
{  The golden files of Tests\Data\Greed are what the original code of xGreed    }
{  (d_disk.pas, g_fixlump.pas, LoadTextures, ScaleMaskedPost, DoLoadMapData)    }
{  gave on the GREED.BLO of the demos 1.016 and 2.0 (see Tests\Data\README.md)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Golden;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  [Category('golden')]
  TTestGreedGolden = class(TObject)
  private
    function Folder(const ADemo: string): string;
    function Golden(const ADemo: string): TStringList;
    function Fields(const ALine: string): TArray<string>;
  public
    [Test]
    [TestCase('Demo 1.016', 'demo1016')]
    [TestCase('Demo 2.0', 'demo20')]
    [TestCase('Gioco completo', 'full')]
    procedure DovrebbeDareLaTabellaEIByteDeiLumpDelCodiceOriginale(const ADemo: string);
    [Test]
    [TestCase('Demo 1.016', 'demo1016')]
    [TestCase('Demo 2.0', 'demo20')]
    [TestCase('Gioco completo', 'full')]
    procedure DovrebbeTrovareIlPrimoLumpDiOgniNomeComeIlCodiceOriginale(const ADemo: string);
    [Test]
    [TestCase('Demo 1.016', 'demo1016')]
    [TestCase('Demo 2.0', 'demo20')]
    [TestCase('Gioco completo', 'full')]
    procedure DovrebbeDareLaStessaPaletteDelCodiceOriginale(const ADemo: string);
    [Test]
    [TestCase('Demo 1.016', 'demo1016')]
    [TestCase('Demo 2.0', 'demo20')]
    [TestCase('Gioco completo', 'full')]
    procedure DovrebbeDecodificareLeImmaginiComeIlCodiceOriginale(const ADemo: string);
    [Test]
    [TestCase('Demo 1.016', 'demo1016')]
    [TestCase('Demo 2.0', 'demo20')]
    [TestCase('Gioco completo', 'full')]
    procedure DovrebbeClassificareICuriLumpComeIlCodiceOriginale(const ADemo: string);
    [Test]
    procedure DovrebbeDareIPianiDelleMappeDelCodiceOriginale;
    [Test]
    procedure DovrebbeNonUsareMaiLaCompressione;
    [Test]
    procedure DovrebbeDareIPianiDelleTrentaDueMappeDelBloDelGiocoCompleto;
    [Test]
    procedure DovrebbeCorreggereIlLumpPstDelGiocoCompletoComeIlCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Greed.Factory, DelphiDoom.Greed.Palette, DelphiDoom.Greed.PictureDecoder, DelphiDoom.Greed.FlatDecoder,
  DelphiDoom.Greed.WallDecoder, DelphiDoom.Greed.SpriteDecoder, DelphiDoom.Tests.Greed.Builders,
  DelphiDoom.Tests.Greed.RealData;

{ TTestGreedGolden }

function TTestGreedGolden.Folder(const ADemo: string): string;
begin
  if ADemo = 'demo1016' then
    Result := TGreedRealData.Demo1016Folder
  else if ADemo = 'full' then
    Result := TGreedRealData.FullFolder
  else
    Result := TGreedRealData.Demo20Folder;
end;

function TTestGreedGolden.Golden(const ADemo: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TGreedRealData.GoldenPath('blo_' + ADemo + '.golden.txt'));
end;

function TTestGreedGolden.Fields(const ALine: string): TArray<string>;
var
  LQuote: Integer;
  LClose: Integer;
  LHead: TArray<string>;
  LTail: TArray<string>;
begin
  // L index "name" position size compress crc first: the name is the only field that can have spaces
  LQuote := Pos('"', ALine);
  if LQuote = 0 then
    Exit(ALine.Split([' ']));
  LClose := Pos('"', ALine, LQuote + 1);
  LHead := Copy(ALine, 1, LQuote - 2).Split([' ']);
  LTail := Copy(ALine, LClose + 2, MaxInt).Split([' ']);
  Result := LHead + [Copy(ALine, LQuote + 1, LClose - LQuote - 1)] + LTail;
end;

procedure TTestGreedGolden.DovrebbeDareLaTabellaEIByteDeiLumpDelCodiceOriginale(const ADemo: string);
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LLine: string;
  LField: TArray<string>;
  LIndex: Integer;
  LInfo: TGreedLumpInfo;
  LChecked: Integer;
begin
  LFolder := Folder(ADemo);
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := Golden(ADemo);
  try
    LArchive := TGreedRealData.OpenArchive(LFolder);
    LChecked := 0;
    for LLine in LGolden do
    begin
      LField := Fields(LLine);
      if LField[0] = 'H' then
        Assert.AreEqual(StrToInt(LField[1]), LArchive.LumpCount)
      else if LField[0] = 'L' then
      begin
        LIndex := StrToInt(LField[1]);
        LInfo := LArchive.GetLumpInfo(LIndex);
        Assert.AreEqual(LField[2], LArchive.GetLumpName(LIndex), 'nome ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[3]), LInfo.FilePosition, 'posizione ' + LField[1]);
        Assert.AreEqual(StrToInt64(LField[4]), Int64(LInfo.Size), 'dimensione ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[5]), Integer(LInfo.Compress), 'compress ' + LField[1]);
        Assert.AreEqual(LField[6], TGreedLumps.CrcHex(LArchive.ReadLump(LIndex)), 'crc ' + LField[1]);
        Inc(LChecked);
      end;
    end;
    Assert.AreEqual(LArchive.LumpCount, LChecked);
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeTrovareIlPrimoLumpDiOgniNomeComeIlCodiceOriginale(const ADemo: string);
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LLine: string;
  LField: TArray<string>;
  LName: string;
begin
  LFolder := Folder(ADemo);
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := Golden(ADemo);
  try
    LArchive := TGreedRealData.OpenArchive(LFolder);
    for LLine in LGolden do
    begin
      LField := Fields(LLine);
      if LField[0] <> 'L' then
        Continue;
      LName := LField[2];
      // the last field is what CA_CheckNamedNum gave for the name (-1 for no name)
      Assert.AreEqual(StrToInt(LField[7]), LArchive.IndexOf(LName), 'primo ' + LName);
      Assert.AreEqual(StrToInt(LField[7]), LArchive.IndexOf(UpperCase(LName)), 'primo maiuscolo ' + LName);
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeDareLaStessaPaletteDelCodiceOriginale(const ADemo: string);
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LLine: string;
  LField: TArray<string>;
  LFound: Boolean;
begin
  LFolder := Folder(ADemo);
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := Golden(ADemo);
  try
    LArchive := TGreedRealData.OpenArchive(LFolder);
    LFound := False;
    for LLine in LGolden do
    begin
      LField := Fields(LLine);
      if LField[0] <> 'K' then
        Continue;
      LFound := True;
      Assert.AreEqual(StrToInt(LField[1]), LArchive.RequireIndexOf(GREED_LUMP_PALETTE));
      Assert.AreEqual(LField[2], TGreedLumps.CrcHex(TGreedPalette.FromLump(LArchive.ReadLump(StrToInt(LField[1])))));
    end;
    Assert.IsTrue(LFound);
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeDecodificareLeImmaginiComeIlCodiceOriginale(const ADemo: string);
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LLine: string;
  LField: TArray<string>;
  LIndex: Integer;
  LImage: TGreedImage;
  LCounts: array[0..3] of Integer;
begin
  LFolder := Folder(ADemo);
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := Golden(ADemo);
  try
    LArchive := TGreedRealData.OpenArchive(LFolder);
    FillChar(LCounts, SizeOf(LCounts), 0);
    for LLine in LGolden do
    begin
      LField := Fields(LLine);
      if (LField[0] = 'W') then
      begin
        // W index width height size crc
        LIndex := StrToInt(LField[1]);
        LImage := TGreedWallDecoder.Create.Decode(LArchive.ReadLump(LIndex));
        Assert.AreEqual(StrToInt(LField[2]), LImage.Width, 'muro ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[3]), LImage.Height, 'muro ' + LField[1]);
        Assert.AreEqual(LField[5], TGreedLumps.CrcHex(LImage.Pixels), 'muro ' + LField[1]);
        Inc(LCounts[0]);
      end
      else if LField[0] = 'F' then
      begin
        // F index size crc
        LIndex := StrToInt(LField[1]);
        LImage := TGreedFlatDecoder.Create.Decode(LArchive.ReadLump(LIndex));
        Assert.AreEqual(LField[3], TGreedLumps.CrcHex(LImage.Pixels), 'flat ' + LField[1]);
        Inc(LCounts[1]);
      end
      else if LField[0] = 'S' then
      begin
        // S index left offset width height size crc
        LIndex := StrToInt(LField[1]);
        LImage := TGreedSpriteDecoder.Create.Decode(LArchive.ReadLump(LIndex));
        Assert.AreEqual(StrToInt(LField[2]), LImage.OriginX, 'sprite ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[3]), LImage.Width, 'sprite ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[4]), LImage.Height, 'sprite ' + LField[1]);
        Assert.AreEqual(LField[6], TGreedLumps.CrcHex(LImage.Pixels), 'sprite ' + LField[1]);
        Inc(LCounts[2]);
      end
      else if LField[0] = 'P' then
      begin
        // P index width height origin x origin y crc
        LIndex := StrToInt(LField[1]);
        LImage := TGreedPictureDecoder.Create.Decode(LArchive.ReadLump(LIndex));
        Assert.AreEqual(StrToInt(LField[2]), LImage.Width, 'immagine ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[3]), LImage.Height, 'immagine ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[4]), LImage.OriginX, 'immagine ' + LField[1]);
        Assert.AreEqual(StrToInt(LField[5]), LImage.OriginY, 'immagine ' + LField[1]);
        Assert.AreEqual(LField[6], TGreedLumps.CrcHex(LImage.Pixels), 'immagine ' + LField[1]);
        Inc(LCounts[3]);
      end;
    end;
    // every group has lumps: the demos have hundreds of sprites and walls
    Assert.IsTrue(LCounts[0] > 100, 'muri');
    Assert.IsTrue(LCounts[1] > 100, 'flat');
    Assert.IsTrue(LCounts[2] > 300, 'sprite');
    Assert.IsTrue(LCounts[3] > 100, 'immagini');
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeClassificareICuriLumpComeIlCodiceOriginale(const ADemo: string);
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LClassifier: IGreedLumpClassifier;
  LLine: string;
  LField: TArray<string>;
  LExpected: array of TGreedLumpKind;
  LIndex: Integer;
begin
  LFolder := Folder(ADemo);
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := Golden(ADemo);
  try
    LArchive := TGreedRealData.OpenArchive(LFolder);
    LClassifier := TGreedFactory.CreateLumpClassifier(LArchive);
    SetLength(LExpected, LArchive.LumpCount);
    for LIndex := 0 to High(LExpected) do
      LExpected[LIndex] := glkOther;
    for LLine in LGolden do
    begin
      LField := Fields(LLine);
      LIndex := -1;
      if Length(LField) > 1 then
        TryStrToInt(LField[1], LIndex);
      if (LIndex < 0) or (LIndex >= Length(LExpected)) then
        Continue;
      if LField[0] = 'K' then
        LExpected[LIndex] := glkPalette
      else if LField[0] = 'W' then
        LExpected[LIndex] := glkWall
      else if LField[0] = 'F' then
        LExpected[LIndex] := glkFlat
      else if LField[0] = 'S' then
        LExpected[LIndex] := glkSprite
      else if LField[0] = 'P' then
        LExpected[LIndex] := glkPicture;
    end;
    for LIndex := 0 to High(LExpected) do
      Assert.AreEqual(Ord(LExpected[LIndex]), Ord(LClassifier.Classify(LIndex)), 'lump ' + IntToStr(LIndex));
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeDareIPianiDelleMappeDelCodiceOriginale;
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LLoader: IGreedMapLoader;
  LMap: IGreedMap;
  LLine: string;
  LField: TArray<string>;
  LMapNumber: Integer;
  LChecked: Integer;
begin
  LFolder := TGreedRealData.Demo20Folder;
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath('maps_demo20.golden.txt'));
    LArchive := TGreedRealData.OpenArchive(LFolder);
    // the maps of the demo are empty lumps: the planes are in LEVEL1.LAY ... LEVEL4.LAY next to the archive
    LLoader := TGreedFactory.CreateMapLoader(LArchive, TGreedFactory.CreateFolderFiles([LFolder]));
    LChecked := 0;
    for LLine in LGolden do
    begin
      // M LEVELn.LAY plane crc
      LField := LLine.Split([' ']);
      LMapNumber := StrToInt(Copy(LField[1], 6, 1)) - 1;
      LMap := LLoader.Load(LMapNumber);
      Assert.AreEqual(LField[3], TGreedLumps.CrcHex(LMap.Planes[TGreedPlane(StrToInt(LField[2]))]), LLine);
      Inc(LChecked);
    end;
    Assert.AreEqual(4 * GREED_MAP_PLANES, LChecked);
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeDareIPianiDelleTrentaDueMappeDelBloDelGiocoCompleto;
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LLoader: IGreedMapLoader;
  LMap: IGreedMap;
  LLine: string;
  LField: TArray<string>;
  LChecked: Integer;
begin
  LFolder := TGreedRealData.FullFolder;
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := Golden('full');
  try
    LArchive := TGreedRealData.OpenArchive(LFolder);
    // in the complete game the 18 planes are inside the lump of the map (no .LAY file next to the archive)
    LLoader := TGreedFactory.CreateMapLoader(LArchive, nil);
    LChecked := 0;
    for LLine in LGolden do
    begin
      LField := Fields(LLine);
      if LField[0] <> 'B' then
        Continue;
      // B map number, lump, plane, "name", crc: what DoLoadMapData gave after the seek to the lump
      LMap := LLoader.Load(StrToInt(LField[1]));
      Assert.AreEqual(LField[5], TGreedLumps.CrcHex(LMap.Planes[TGreedPlane(StrToInt(LField[3]))]), LLine);
      Inc(LChecked);
    end;
    Assert.AreEqual(32 * GREED_MAP_PLANES, LChecked);
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeCorreggereIlLumpPstDelGiocoCompletoComeIlCodiceOriginale;
var
  LFolder: string;
  LGolden: TStringList;
  LArchive: IGreedArchive;
  LLine: string;
  LField: TArray<string>;
  LIndex: Integer;
  LFound: Integer;
begin
  LFolder := TGreedRealData.FullFolder;
  if LFolder = '' then
    Assert.Pass('I dati di GREED non ci sono su questo PC: prova saltata');
  LGolden := Golden('full');
  try
    LArchive := TGreedRealData.OpenArchive(LFolder);
    LFound := 0;
    for LLine in LGolden do
    begin
      LField := Fields(LLine);
      if (LField[0] <> 'L') or (LField[4] <> '10463') then
        Continue;
      LIndex := StrToInt(LField[1]);
      // the lump as it is on disk has the CRC32 of the defect, the one after FixLump is in the golden
      if TGreedLumps.CrcHex(LArchive.ReadLumpRaw(LIndex)) <> '48818333' then
        Continue;
      Inc(LFound);
      Assert.AreEqual(LField[6], TGreedLumps.CrcHex(LArchive.ReadLump(LIndex)), 'lump corretto ' + LField[1]);
      Assert.AreNotEqual('48818333', TGreedLumps.CrcHex(LArchive.ReadLump(LIndex)));
    end;
    Assert.AreEqual(1, LFound, 'un solo lump da correggere');
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedGolden.DovrebbeNonUsareMaiLaCompressione;
var
  LFolder: string;
  LArchive: IGreedArchive;
  LIndex: Integer;
begin
  for LFolder in TArray<string>.Create(TGreedRealData.Demo1016Folder, TGreedRealData.Demo20Folder,
    TGreedRealData.FullFolder) do
  begin
    if LFolder = '' then
      Continue;
    LArchive := TGreedRealData.OpenArchive(LFolder);
    // the field "compress" is 0 in every lump of both demos (and the original never reads it)
    for LIndex := 0 to LArchive.LumpCount - 1 do
      Assert.AreEqual(0, Integer(LArchive.GetLumpInfo(LIndex).Compress), LFolder + ' lump ' + IntToStr(LIndex));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedGolden);

end.
