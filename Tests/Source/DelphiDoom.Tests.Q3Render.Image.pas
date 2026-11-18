{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R0) - images:    }
{  the TGA and JPEG readers against the real LoadTGA and LoadJPG of Quake III  }
{  (Tests\Data\Q3Render\image.golden.txt, Tools\Verifica\254\build-image.sh),   }
{  the loader and the image table                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Image;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3ImageGolden = class
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroLoadTgaEDelVeroLoadJpg;
    [Test]
    [Category('OpenArena')]
    procedure DovrebbeDecodificareLeImmaginiDiOpenArenaComeIlC;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3TgaReader = class
  public
    [Test]
    procedure DovrebbeScartareUnFileTroncatoInvecePiLeggereOltre;
    [Test]
    procedure DovrebbeRifiutareLeDimensioniNegativeEEccessive;
    [Test]
    procedure DovrebbeAvvisareDellOrigineInAltoSenzaCapovolgere;
    [Test]
    procedure DovrebbeMetterePrimaLUltimaRigaDelFile;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3ImageLoader = class
  public
    [Test]
    procedure DovrebbeProvareIlJpgQuandoIlTgaNonCe;
    [Test]
    procedure DovrebbePreferireIlTgaAlJpg;
    [Test]
    procedure DovrebbeIgnorareLeEstensioniSconosciuteEINomiCorti;
    [Test]
    procedure DovrebbeLeggereUnaScalaDiGrigiComeRgbConAlfa255;
    [Test]
    procedure DovrebbeCercareTuttiIFormatiSeCiSiAspettaCosiComeIoquake3;
  end;

  [TestFixture]
  [Category('Q3Render')]
  TTestQ3ImageCatalog = class
  public
    [Test]
    procedure DovrebbeCaricareUnaVoltaESaperlaTrovareDaNomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeRicordareLeImmaginiMancantiSenzaRileggerle;
    [Test]
    procedure DovrebbeTenereIPixelSoloSeRichiesto;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.StrUtils, System.IOUtils, System.Zip, DelphiDoom.Logging.Intf,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Image.TgaReader,
  DelphiDoom.Q3Render.Image.JpegReader, DelphiDoom.Q3Render.Image.Loader, DelphiDoom.Q3Render.Image.Catalog,
  DelphiDoom.Tests.Q3Render.Support;

function Describe(const AKind, AName: string; const AData: TBytes; const ALog: TCountingLog; ATga: TQ3TgaReader;
  AJpeg: TQ3JpegReader): string;
var
  LImage: TQ3RenderImage;
  LMessage: string;
  LCut, LIndex: Integer;
  LSum: Int64;
begin
  ALog.Warnings.Clear;
  if AKind = 'tga' then
  begin
    try
      LImage := ATga.Read(AnsiString(AName), AData);
    except
      on E: EQ3RenderException do
      begin
        LMessage := E.Message;
        LCut := Pos(' in file ''', LMessage);
        if LCut > 0 then
          LMessage := Copy(LMessage, 1, LCut - 1);
        Exit(Format('%s %s error %s', [AKind, ExtractFileName(AName), LMessage]));
      end;
    end;
  end
  else if not AJpeg.Read(AnsiString(AName), AData, LImage) then
    Exit(Format('%s %s none', [AKind, ExtractFileName(AName)]));
  LSum := 0;
  for LIndex := 0 to LImage.Width * LImage.Height * 4 - 1 do
    Inc(LSum, LImage.Pixels[LIndex]);
  Result := Format('%s %s ok %d %d %s sum=%d warnings=%d', [AKind, ExtractFileName(AName), LImage.Width,
    LImage.Height, TTestSupport.Fnv(LImage.Pixels, LImage.Width * LImage.Height * 4), LSum, ALog.Warnings.Count]);
end;

// A JPEG that the float DCT does not give bit for bit (see imagegen.c): everything equal but the hash, and the
// sum of the bytes within MAX_SUM_DIFFERENCE
function SameWithinFloatDct(const AExpected, AActual: string): Boolean;
const
  MAX_SUM_DIFFERENCE = 128;
var
  LExpected, LActual: TArray<string>;
  LIndex: Integer;
begin
  LExpected := AExpected.Split([' ']);
  LActual := AActual.Split([' ']);
  Result := (Length(LExpected) = Length(LActual)) and (Length(LExpected) = 8) and (LExpected[2] = 'ok');
  if not Result then
    Exit;
  for LIndex := 0 to High(LExpected) do
    if LIndex = 5 then
      Continue
    else if LIndex = 6 then
    begin
      if Abs(StrToInt64(Copy(LExpected[6], 5, MaxInt)) - StrToInt64(Copy(LActual[6], 5, MaxInt))) >
        MAX_SUM_DIFFERENCE then
        Exit(False);
    end
    else if LExpected[LIndex] <> LActual[LIndex] then
      Exit(False);
end;

function FindDataFile(const AName: string): string;
var
  LRelative: string;
begin
  for LRelative in ['Tests\Data\Q3Render\tga\', 'Tests\Data\IdImages\tga\', 'Tests\Data\Jpeg\'] do
  begin
    Result := TTestFiles.FindFileUp(LRelative + AName);
    if Result <> '' then
      Exit;
  end;
  Result := '';
end;

{ TTestQ3ImageGolden }

procedure TTestQ3ImageGolden.DovrebbeDareLeStesseRisposteDelVeroLoadTgaEDelVeroLoadJpg;
var
  LGolden: TStringList;
  LLog: TCountingLog;
  LLogIntf: ILog;
  LTga: TQ3TgaReader;
  LJpeg: TQ3JpegReader;
  LLine, LKind, LName, LPath: string;
  LParts: TArray<string>;
  LChecked: Integer;
begin
  LGolden := TTestFiles.Lines(TTestFiles.FindFileUp('Tests\Data\Q3Render\image.golden.txt'));
  LLog := TCountingLog.Create;
  LLogIntf := LLog;
  LTga := TQ3TgaReader.Create(LLogIntf);
  LJpeg := TQ3JpegReader.Create(LLogIntf);
  try
    LChecked := 0;
    for LLine in LGolden do
    begin
      LParts := LLine.Split([' ']);
      if (Length(LParts) < 3) or (LParts[0] = 'oa') then
        Continue;
      LKind := LParts[0];
      LName := LParts[1];
      LPath := FindDataFile(LName);
      Assert.IsTrue(LPath <> '', 'file not found: ' + LName);
      Assert.AreEqual(LLine, Describe(LKind, LName, TFile.ReadAllBytes(LPath), LLog, LTga, LJpeg), LName);
      Inc(LChecked);
    end;
    Assert.IsTrue(LChecked >= 28, 'too few cases: ' + IntToStr(LChecked));
  finally
    LTga.Free;
    LJpeg.Free;
    LGolden.Free;
  end;
end;

procedure TTestQ3ImageGolden.DovrebbeDecodificareLeImmaginiDiOpenArenaComeIlC;
var
  LGolden: TStringList;
  LLog: TCountingLog;
  LLogIntf: ILog;
  LTga: TQ3TgaReader;
  LJpeg: TQ3JpegReader;
  LZip: TZipFile;
  LLine, LName: string;
  LParts: TArray<string>;
  LData: TBytes;
  LChecked, LSkipped, LTolerated: Integer;
  LExpected, LActual: string;
  LDifferent: TStringList;
  LImage: TQ3RenderImage;
begin
  LZip := TZipFile.Create;
  LZip.Open(TPath.Combine(TTestSupport.OpenArenaFolder, 'baseoa\pak0.pk3'), zmRead);
  LDifferent := TStringList.Create;
  LGolden := TTestFiles.Lines(TTestFiles.FindFileUp('Tests\Data\Q3Render\image.golden.txt'));
  LLog := TCountingLog.Create;
  LLogIntf := LLog;
  LTga := TQ3TgaReader.Create(LLogIntf);
  LJpeg := TQ3JpegReader.Create(LLogIntf);
  try
    LChecked := 0;
    LSkipped := 0;
    LTolerated := 0;
    for LLine in LGolden do
    begin
      LParts := LLine.Split([' ']);
      if (Length(LParts) < 5) or (LParts[0] <> 'oa') then
        Continue;
      LName := LParts[2];
      // the golden is of the files of pak0.pk3 (the later paks replace some of them)
      LZip.Read(LName, LData);
      // a JPEG that the C refuses (progressive) is decoded here: only the ones the C decodes are compared
      if LParts[3] <> 'ok' then
      begin
        Inc(LSkipped);
        Continue;
      end;
      LExpected := LParts[1] + ' ' + ExtractFileName(LName) + ' ' + string.Join(' ', Copy(LParts, 3, MaxInt));
      LActual := Describe(LParts[1], LName, LData, LLog, LTga, LJpeg);
      if (LActual <> LExpected) and (LParts[1] = 'jpg') and SameWithinFloatDct(LExpected, LActual) then
        Inc(LTolerated)
      else if LActual <> LExpected then
      begin
        LDifferent.Add(LExpected + ' <> ' + LActual);
        // DELPHIDOOM_Q3RENDER_DUMP=<folder>: the pixels of the JPEG that differs, to compare with IMAGEGEN_DUMP
        if (LParts[1] = 'jpg') and (GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_DUMP') <> '') and
          LJpeg.Read(AnsiString(LName), LData, LImage) then
          TFile.WriteAllBytes(TPath.Combine(GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_DUMP'),
            StringReplace(LName, '/', '__', [rfReplaceAll]) + '.rgba'), Copy(LImage.Pixels, 0, Length(LImage.Pixels)));
      end;
      Inc(LChecked);
    end;
    Assert.AreEqual(0, LDifferent.Count, 'differences: ' + LDifferent.Text);
    // at most a few of the JPEGs may differ in the last bit of the float DCT (one in 34 with the golden of -O0)
    Assert.IsTrue(LTolerated <= 3, 'too many JPEGs off by the float DCT: ' + IntToStr(LTolerated));
    Assert.IsTrue(LChecked >= 60, 'too few images compared: ' + IntToStr(LChecked) + ' (' + IntToStr(LSkipped) +
      ' skipped)');
  finally
    LTga.Free;
    LJpeg.Free;
    LGolden.Free;
    LDifferent.Free;
    LZip.Free;
  end;
end;

{ TTestQ3TgaReader }

procedure TTestQ3TgaReader.DovrebbeScartareUnFileTroncatoInvecePiLeggereOltre;
var
  LReader: TQ3TgaReader;
  LData: TBytes;
begin
  LData := TFile.ReadAllBytes(FindDataFile('t2_trunc.tga'));
  LReader := TQ3TgaReader.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.Read('t2_trunc.tga', LData);
      end, EQ3RenderException);
    Assert.WillRaise(
      procedure
      begin
        LReader.Read('short.tga', Copy(LData, 0, 10));
      end, EQ3RenderException);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TgaReader.DovrebbeRifiutareLeDimensioniNegativeEEccessive;
var
  LReader: TQ3TgaReader;
  LData: TBytes;
begin
  // type 2, 24 bit, width = -1 (the C reads it as a signed short and allocates a huge buffer)
  LData := TBytes.Create(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, $FF, $FF, 1, 0, 24, 0);
  LReader := TQ3TgaReader.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.Read('negative.tga', LData);
      end, EQ3RenderException);
    LData[12] := $00;
    LData[13] := $40; // 16384 columns, above the limit
    Assert.WillRaise(
      procedure
      begin
        LReader.Read('wide.tga', LData);
      end, EQ3RenderException);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TgaReader.DovrebbeAvvisareDellOrigineInAltoSenzaCapovolgere;
var
  LLog: TCountingLog;
  LLogIntf: ILog;
  LReader: TQ3TgaReader;
  LImage: TQ3RenderImage;
  LBottom, LTop: TBytes;
begin
  LLog := TCountingLog.Create;
  LLogIntf := LLog;
  LReader := TQ3TgaReader.Create(LLogIntf);
  try
    // 1 x 2, 24 bit: the first pixel of the file (1, 2, 3 = B, G, R) and the second (4, 5, 6)
    LBottom := TBytes.Create(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 24, 0, 1, 2, 3, 4, 5, 6);
    LTop := Copy(LBottom, 0, Length(LBottom));
    LTop[17] := $20;
    LImage := LReader.Read('a.tga', LBottom);
    Assert.AreEqual(0, LLog.Warnings.Count);
    LImage := LReader.Read('b.tga', LTop);
    Assert.AreEqual(1, LLog.Warnings.Count);
    Assert.IsTrue(ContainsText(LLog.Warnings[0], 'top-down'));
    // the same image as without the bit
    Assert.AreEqual(8, Length(LImage.Pixels));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TgaReader.DovrebbeMetterePrimaLUltimaRigaDelFile;
var
  LReader: TQ3TgaReader;
  LImage: TQ3RenderImage;
begin
  LReader := TQ3TgaReader.Create;
  try
    // the file has the pixel (B, G, R) = (1, 2, 3) first and (4, 5, 6) second; the buffer has the second row first
    LImage := LReader.Read('a.tga', TBytes.Create(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 24, 0,
      1, 2, 3, 4, 5, 6));
    Assert.AreEqual(1, LImage.Width);
    Assert.AreEqual(2, LImage.Height);
    // buffer row 0 = the last pixel of the file: R, G, B, A = 6, 5, 4, 255
    Assert.AreEqual<Integer>(6, LImage.Pixels[0]);
    Assert.AreEqual<Integer>(4, LImage.Pixels[2]);
    Assert.AreEqual<Integer>(255, LImage.Pixels[3]);
    // buffer row 1 = the first pixel of the file: 3, 2, 1, 255
    Assert.AreEqual<Integer>(3, LImage.Pixels[4]);
    Assert.AreEqual<Integer>(1, LImage.Pixels[6]);
  finally
    LReader.Free;
  end;
end;

{ TTestQ3ImageLoader }

procedure TTestQ3ImageLoader.DovrebbeProvareIlJpgQuandoIlTgaNonCe;
var
  LFiles: TMemoryFiles;
  LFilesIntf: IQ3RenderFiles;
  LLoader: IQ3ImageLoader;
  LImage: TQ3RenderImage;
begin
  LFiles := TMemoryFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Add('textures/a/b.jpg', TFile.ReadAllBytes(FindDataFile('encoder-17x13-c3-q80.jpg')));
  LLoader := TQ3ImageLoader.Create(LFilesIntf);
  Assert.IsTrue(LLoader.Load('textures/a/b.tga', LImage));
  Assert.AreEqual(17, LImage.Width);
  Assert.AreEqual(13, LImage.Height);
  Assert.AreEqual('textures/a/b.tga', LFiles.Reads[0]);
  Assert.AreEqual('textures/a/b.jpg', LFiles.Reads[1]);
  Assert.IsFalse(LLoader.Load('textures/a/c.tga', LImage));
end;

procedure TTestQ3ImageLoader.DovrebbePreferireIlTgaAlJpg;
var
  LFiles: TMemoryFiles;
  LFilesIntf: IQ3RenderFiles;
  LLoader: IQ3ImageLoader;
  LImage: TQ3RenderImage;
begin
  LFiles := TMemoryFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Add('x.tga', TFile.ReadAllBytes(FindDataFile('rgba32.tga')));
  LFiles.Add('x.jpg', TFile.ReadAllBytes(FindDataFile('encoder-17x13-c3-q80.jpg')));
  LLoader := TQ3ImageLoader.Create(LFilesIntf);
  Assert.IsTrue(LLoader.Load('x.TGA', LImage));
  Assert.AreEqual(3, LImage.Width);
  Assert.AreEqual(1, LFiles.Reads.Count);
end;

procedure TTestQ3ImageLoader.DovrebbeIgnorareLeEstensioniSconosciuteEINomiCorti;
var
  LFiles: TMemoryFiles;
  LFilesIntf: IQ3RenderFiles;
  LLoader: IQ3ImageLoader;
  LImage: TQ3RenderImage;
begin
  LFiles := TMemoryFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Add('a.pcx', TBytes.Create(1, 2, 3));
  LFiles.Add('a.png', TBytes.Create(1, 2, 3));
  LLoader := TQ3ImageLoader.Create(LFilesIntf);
  Assert.IsFalse(LLoader.Load('a.pcx', LImage));
  Assert.IsFalse(LLoader.Load('a.png', LImage));
  Assert.IsFalse(LLoader.Load('.tga', LImage));
  Assert.IsFalse(LLoader.Load('', LImage));
  Assert.AreEqual(0, LFiles.Reads.Count, 'no file is read for those names');
end;

procedure TTestQ3ImageLoader.DovrebbeLeggereUnaScalaDiGrigiComeRgbConAlfa255;
var
  LReader: TQ3JpegReader;
  LImage: TQ3RenderImage;
  LData: TBytes;
  LIndex: Integer;
begin
  // the grayscale JPEG of the encoder: the real LoadJPG hangs on it (1 byte per pixel, written as 4); here R = G = B
  LData := TFile.ReadAllBytes(FindDataFile('encoder-33x17-c1-q50.jpg'));
  LReader := TQ3JpegReader.Create;
  try
    Assert.IsTrue(LReader.Read('gray.jpg', LData, LImage));
    Assert.AreEqual(33, LImage.Width);
    Assert.AreEqual(17, LImage.Height);
    for LIndex := 0 to 33 * 17 - 1 do
    begin
      Assert.AreEqual<Integer>(LImage.Pixels[LIndex * 4], LImage.Pixels[LIndex * 4 + 1]);
      Assert.AreEqual<Integer>(LImage.Pixels[LIndex * 4], LImage.Pixels[LIndex * 4 + 2]);
      Assert.AreEqual<Integer>(255, LImage.Pixels[LIndex * 4 + 3]);
    end;
    Assert.IsFalse(LReader.Read('bad.jpg', TBytes.Create(1, 2, 3, 4), LImage));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3ImageLoader.DovrebbeCercareTuttiIFormatiSeCiSiAspettaCosiComeIoquake3;
var
  LFiles: TMemoryFiles;
  LFilesIntf: IQ3RenderFiles;
  LLoader: TQ3ImageLoader;
  LLoaderIntf: IQ3ImageLoader;
  LImage: TQ3RenderImage;
begin
  LFiles := TMemoryFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Add('menu/skill1.tga', TFile.ReadAllBytes(FindDataFile('rgba32.tga')));
  LFiles.Add('menu/other.jpg', TFile.ReadAllBytes(FindDataFile('encoder-17x13-c3-q80.jpg')));
  LFiles.Add('menu/onlypng.png', TBytes.Create(1, 2, 3));
  LLoader := TQ3ImageLoader.Create(LFilesIntf, nil, True);
  LLoaderIntf := LLoader;
  // no extension: the formats are tried one after the other
  Assert.IsTrue(LLoaderIntf.Load('menu/skill1', LImage));
  Assert.AreEqual(3, LImage.Width);
  Assert.IsTrue(LLoaderIntf.Load('menu/other', LImage));
  Assert.AreEqual(17, LImage.Width);
  // an extension that does not find the file: the same name with the other ones
  Assert.IsTrue(LLoaderIntf.Load('menu/other.tga', LImage));
  Assert.IsTrue(LLoaderIntf.Load('menu/skill1.jpg', LImage));
  // a file in a format that is not decoded is counted and is not found
  Assert.IsFalse(LLoaderIntf.Load('menu/onlypng', LImage));
  Assert.AreEqual(1, LLoader.UnsupportedFound);
  // the plain loader of Quake III 1.32 does not do any of this
  LLoaderIntf := TQ3ImageLoader.Create(LFilesIntf);
  Assert.IsFalse(LLoaderIntf.Load('menu/skill1', LImage));
  Assert.IsFalse(LLoaderIntf.Load('menu/skill1.jpg', LImage));
end;

{ TTestQ3ImageCatalog }

procedure TTestQ3ImageCatalog.DovrebbeCaricareUnaVoltaESaperlaTrovareDaNomeSenzaMaiuscole;
var
  LFiles: TMemoryFiles;
  LFilesIntf: IQ3RenderFiles;
  LCatalog: IQ3ImageCatalog;
  LImage: TQ3RenderImage;
  LFirst, LSecond: Integer;
begin
  LFiles := TMemoryFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Add('gfx/a.tga', TFile.ReadAllBytes(FindDataFile('rgba32.tga')));
  LCatalog := TQ3ImageCatalog.Create(TQ3ImageLoader.Create(LFilesIntf));
  LFirst := LCatalog.Find('gfx/a.tga');
  LSecond := LCatalog.Find('GFX\A.TGA');
  Assert.AreEqual(1, LFirst);
  Assert.AreEqual(LFirst, LSecond);
  Assert.AreEqual(1, LCatalog.LoadedCount);
  Assert.AreEqual(1, LFiles.Reads.Count);
  Assert.IsTrue(LCatalog.GetImage(LFirst, LImage));
  Assert.AreEqual(3, LImage.Width);
  Assert.AreEqual(5, LImage.Height);
  Assert.IsFalse(LCatalog.GetImage(2, LImage));
end;

procedure TTestQ3ImageCatalog.DovrebbeRicordareLeImmaginiMancantiSenzaRileggerle;
var
  LFiles: TMemoryFiles;
  LFilesIntf: IQ3RenderFiles;
  LCatalog: IQ3ImageCatalog;
begin
  LFiles := TMemoryFiles.Create;
  LFilesIntf := LFiles;
  // an invalid file counts as missing, the C stops the frame instead
  LFiles.Add('bad.tga', TBytes.Create(0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 8, 0, 1));
  LCatalog := TQ3ImageCatalog.Create(TQ3ImageLoader.Create(LFilesIntf));
  Assert.AreEqual(0, LCatalog.Find('none.tga'));
  Assert.AreEqual(0, LCatalog.Find('none.tga'));
  Assert.AreEqual(0, LCatalog.Find('bad.tga'));
  Assert.AreEqual(2, Length(LCatalog.MissingNames));
  Assert.AreEqual(0, LCatalog.LoadedCount);
  // none.tga: tga and jpg once; bad.tga: the tga that raises
  Assert.AreEqual(3, LFiles.Reads.Count);
end;

procedure TTestQ3ImageCatalog.DovrebbeTenereIPixelSoloSeRichiesto;
var
  LFiles: TMemoryFiles;
  LFilesIntf: IQ3RenderFiles;
  LKept, LDropped: IQ3ImageCatalog;
  LImage: TQ3RenderImage;
begin
  LFiles := TMemoryFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Add('a.tga', TFile.ReadAllBytes(FindDataFile('rgba32.tga')));
  LKept := TQ3ImageCatalog.Create(TQ3ImageLoader.Create(LFilesIntf), True);
  LDropped := TQ3ImageCatalog.Create(TQ3ImageLoader.Create(LFilesIntf), False);
  LKept.Find('a.tga');
  LDropped.Find('a.tga');
  LKept.GetImage(1, LImage);
  Assert.AreEqual(60, Length(LImage.Pixels));
  LDropped.GetImage(1, LImage);
  Assert.AreEqual(0, Length(LImage.Pixels));
  Assert.AreEqual(5, LImage.Height);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3ImageGolden);
  TDUnitX.RegisterTestFixture(TTestQ3TgaReader);
  TDUnitX.RegisterTestFixture(TTestQ3ImageLoader);
  TDUnitX.RegisterTestFixture(TTestQ3ImageCatalog);

end.
