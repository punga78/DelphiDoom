{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the rasterizer and of the pictures of the cars         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.CarSpriteRenderer;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Speed.TriangleRasterizer, DelphiDoom.Speed.CarSpriteRenderer;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedTriangleRasterizer = class(TObject)
  strict private
    FRasterizer: TSpeedTriangleRasterizer;
    function Vertex(AX, AY, ADepth: Single): TSpeedRasterVertex;
    function Identity: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireTuttoTrasparente;
    [Test]
    procedure DovrebbeColorareSoloIPixelDentroAlTriangolo;
    [Test]
    procedure DovrebbeTenereIlPiuVicinoDoveSiSovrappongono;
    [Test]
    procedure DovrebbeAccettareTriangoliConLOrdineInverso;
    [Test]
    procedure DovrebbeIgnorareITriangoliDegeneri;
    [Test]
    procedure DovrebbeTagliareQuelloCheEsceDallaImmagine;
    [Test]
    procedure DovrebbeLeggereLaTexturePassandoDallaMappaDeiColori;
    [Test]
    procedure DovrebbeScurireConLaMappaDellOmbra;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNonPositiva;
  end;

  [TestFixture]
  [Category('speed')]
  TTestSpeedCarSpriteRenderer = class(TObject)
  strict private
    function FindShareware: string;
  public
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
    [Test]
    procedure DovrebbeRifiutareDiDisegnareSenzaModello;
    [Test]
    procedure DovrebbeDisegnareLeOttoFacceDiUnaAutoDelloShareware;
  end;

implementation

uses
  DelphiDoom.GameData.Intf, DelphiDoom.GameData.Factory, DelphiDoom.Models.I3d.Intf,
  DelphiDoom.Models.I3d.Factory, DelphiDoom.Speed.Intf, DelphiDoom.Speed.Factory, DelphiDoom.Tests.Speed.Fakes;

const
  TRANSPARENT_INDEX = 255;

{ TTestSpeedTriangleRasterizer }

procedure TTestSpeedTriangleRasterizer.Setup;
begin
  FRasterizer := TSpeedTriangleRasterizer.Create(16, 16, TRANSPARENT_INDEX);
end;

procedure TTestSpeedTriangleRasterizer.TearDown;
begin
  FRasterizer.Free;
end;

function TTestSpeedTriangleRasterizer.Vertex(AX, AY, ADepth: Single): TSpeedRasterVertex;
begin
  Result := Default(TSpeedRasterVertex);
  Result.X := AX;
  Result.Y := AY;
  Result.Depth := ADepth;
end;

function TTestSpeedTriangleRasterizer.Identity: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := LIndex;
end;

procedure TTestSpeedTriangleRasterizer.DovrebbePartireTuttoTrasparente;
var
  LIndex: Integer;
begin
  Assert.AreEqual(16 * 16, Length(FRasterizer.Pixels));
  for LIndex := 0 to High(FRasterizer.Pixels) do
    Assert.AreEqual<Integer>(TRANSPARENT_INDEX, FRasterizer.Pixels[LIndex]);
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeColorareSoloIPixelDentroAlTriangolo;
begin
  FRasterizer.DrawFlat(Vertex(0, 0, 1), Vertex(8, 0, 1), Vertex(0, 8, 1), 7);
  Assert.AreEqual<Integer>(7, FRasterizer.Pixels[1 * 16 + 1]);
  Assert.AreEqual<Integer>(TRANSPARENT_INDEX, FRasterizer.Pixels[7 * 16 + 7]);
  Assert.AreEqual<Integer>(TRANSPARENT_INDEX, FRasterizer.Pixels[12 * 16 + 12]);
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeTenereIlPiuVicinoDoveSiSovrappongono;
begin
  FRasterizer.DrawFlat(Vertex(0, 0, 5), Vertex(16, 0, 5), Vertex(0, 16, 5), 1);
  FRasterizer.DrawFlat(Vertex(0, 0, 2), Vertex(16, 0, 2), Vertex(0, 16, 2), 2);
  FRasterizer.DrawFlat(Vertex(0, 0, 9), Vertex(16, 0, 9), Vertex(0, 16, 9), 3);
  Assert.AreEqual<Integer>(2, FRasterizer.Pixels[2 * 16 + 2]);
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeAccettareTriangoliConLOrdineInverso;
begin
  FRasterizer.DrawFlat(Vertex(0, 0, 1), Vertex(0, 8, 1), Vertex(8, 0, 1), 4);
  Assert.AreEqual<Integer>(4, FRasterizer.Pixels[1 * 16 + 1]);
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeIgnorareITriangoliDegeneri;
var
  LIndex: Integer;
begin
  FRasterizer.DrawFlat(Vertex(0, 0, 1), Vertex(8, 8, 1), Vertex(16, 16, 1), 9);
  for LIndex := 0 to High(FRasterizer.Pixels) do
    Assert.AreEqual<Integer>(TRANSPARENT_INDEX, FRasterizer.Pixels[LIndex]);
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeTagliareQuelloCheEsceDallaImmagine;
begin
  FRasterizer.DrawFlat(Vertex(-20, -20, 1), Vertex(40, -20, 1), Vertex(-20, 40, 1), 6);
  Assert.AreEqual<Integer>(6, FRasterizer.Pixels[0]);
  Assert.AreEqual<Integer>(6, FRasterizer.Pixels[5 * 16 + 5]);
  Assert.AreEqual(16 * 16, Length(FRasterizer.Pixels));
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeLeggereLaTexturePassandoDallaMappaDeiColori;
var
  LTexture, LColors: TBytes;
  LA, LB, LC: TSpeedRasterVertex;
begin
  // a texture of 2 x 1 texels: the left one is index 10, the right one index 20
  LTexture := TBytes.Create(10, 20);
  LColors := Identity;
  LColors[10] := 100;
  LColors[20] := 200;
  LA := Vertex(0, 0, 1);
  LB := Vertex(16, 0, 1);
  LC := Vertex(0, 16, 1);
  LA.U := 0; LB.U := 1; LC.U := 0;
  FRasterizer.DrawTextured(LA, LB, LC, LTexture, 2, 1, LColors, nil);
  Assert.AreEqual<Integer>(100, FRasterizer.Pixels[1 * 16 + 1]);
  Assert.AreEqual<Integer>(200, FRasterizer.Pixels[1 * 16 + 12]);
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeScurireConLaMappaDellOmbra;
var
  LTexture, LColors, LShade: TBytes;
  LA, LB, LC: TSpeedRasterVertex;
begin
  LTexture := TBytes.Create(5);
  LColors := Identity;
  LShade := Identity;
  LShade[5] := 77;
  LA := Vertex(0, 0, 1);
  LB := Vertex(16, 0, 1);
  LC := Vertex(0, 16, 1);
  FRasterizer.DrawTextured(LA, LB, LC, LTexture, 1, 1, LColors, LShade);
  Assert.AreEqual<Integer>(77, FRasterizer.Pixels[2 * 16 + 2]);
end;

procedure TTestSpeedTriangleRasterizer.DovrebbeRifiutareUnaDimensioneNonPositiva;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedTriangleRasterizer.Create(0, 4, 0).Free;
    end, EArgumentException);
end;

{ TTestSpeedCarSpriteRenderer }

function TTestSpeedCarSpriteRenderer.FindShareware: string;
var
  LRoot: string;
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  LCandidates := [TPath.Combine(LRoot, 'bin\Speed\SPEEDH.JCL'), TPath.Combine(LRoot, 'Reference\_dati\speed\SPEEDH.JCL'),
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\Reference\_dati\speed\SPEEDH.JCL'))];
  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

// A picture of a car as an 8 bit BMP to look at (the transparent color is magenta)
procedure WriteBmp(const AFileName: string; const AImage: TSpeedCarSpriteImage; const APlayPal: TBytes);
var
  LStream: TFileStream;
  LHeader: array[0..53] of Byte;
  LRow, LColor, LStride, LSize: Integer;
  LPalette: array[0..255, 0..3] of Byte;
  LZero: Byte;
begin
  LStride := (AImage.Width + 3) and not 3;
  LSize := 54 + 1024 + LStride * AImage.Height;
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader[0] := Ord('B');
  LHeader[1] := Ord('M');
  PInteger(@LHeader[2])^ := LSize;
  PInteger(@LHeader[10])^ := 54 + 1024;
  PInteger(@LHeader[14])^ := 40;
  PInteger(@LHeader[18])^ := AImage.Width;
  PInteger(@LHeader[22])^ := AImage.Height;
  PWord(@LHeader[26])^ := 1;
  PWord(@LHeader[28])^ := 8;
  PInteger(@LHeader[34])^ := LStride * AImage.Height;
  PInteger(@LHeader[46])^ := 256;
  for LColor := 0 to 255 do
  begin
    LPalette[LColor, 0] := APlayPal[LColor * 3 + 2];
    LPalette[LColor, 1] := APlayPal[LColor * 3 + 1];
    LPalette[LColor, 2] := APlayPal[LColor * 3];
    LPalette[LColor, 3] := 0;
  end;
  LPalette[255, 0] := 255;
  LPalette[255, 1] := 0;
  LPalette[255, 2] := 255;
  LZero := 0;
  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    LStream.WriteBuffer(LHeader, SizeOf(LHeader));
    LStream.WriteBuffer(LPalette, SizeOf(LPalette));
    for LRow := AImage.Height - 1 downto 0 do
    begin
      LStream.WriteBuffer(AImage.Pixels[LRow * AImage.Width], AImage.Width);
      for LColor := AImage.Width to LStride - 1 do
        LStream.WriteBuffer(LZero, 1);
    end;
  finally
    LStream.Free;
  end;
end;

// A picture lump (patch) as a picture to look at
procedure WritePatchBmp(const AFileName: string; const APatch, APlayPal: TBytes);
var
  LImage: TSpeedCarSpriteImage;
  LColumn, LOffset, LRow, LCount, LIndex: Integer;
begin
  LImage.Width := PSmallInt(@APatch[0])^;
  LImage.Height := PSmallInt(@APatch[2])^;
  SetLength(LImage.Pixels, LImage.Width * LImage.Height);
  FillChar(LImage.Pixels[0], Length(LImage.Pixels), 255);
  for LColumn := 0 to LImage.Width - 1 do
  begin
    LOffset := PInteger(@APatch[8 + 4 * LColumn])^;
    while APatch[LOffset] <> 255 do
    begin
      LRow := APatch[LOffset];
      LCount := APatch[LOffset + 1];
      for LIndex := 0 to LCount - 1 do
        if LRow + LIndex < LImage.Height then
          LImage.Pixels[(LRow + LIndex) * LImage.Width + LColumn] := APatch[LOffset + 3 + LIndex];
      Inc(LOffset, LCount + 4);
    end;
  end;
  WriteBmp(AFileName, LImage, APlayPal);
end;

procedure TTestSpeedCarSpriteRenderer.DovrebbeRifiutareGliOggettiNil;
var
  LPalette, LColorMap: TBytes;
  LAxes: TSpeedModelAxes;
begin
  SetLength(LPalette, 768);
  SetLength(LColorMap, 34 * 256);
  LAxes := Default(TSpeedModelAxes);
  Assert.WillRaise(
    procedure
    begin
      TSpeedCarSpriteRenderer.Create(nil, TI3dFactory.CreateRenderer, TI3dFactory.CreateMeshBuilder, LPalette,
        LColorMap, 255, LAxes, 100, 20).Free;
    end, EArgumentNilException);
end;

procedure TTestSpeedCarSpriteRenderer.DovrebbeRifiutareDiDisegnareSenzaModello;
var
  LPalette, LColorMap: TBytes;
  LRenderer: TSpeedCarSpriteRenderer;
  LAxes: TSpeedModelAxes;
begin
  SetLength(LPalette, 768);
  SetLength(LColorMap, 34 * 256);
  LAxes := Default(TSpeedModelAxes);
  LRenderer := TSpeedCarSpriteRenderer.Create(TI3dFactory.CreateParser, TI3dFactory.CreateRenderer,
    TI3dFactory.CreateMeshBuilder, LPalette, LColorMap, 255, LAxes, 100, 20);
  try
    Assert.WillRaise(
      procedure
      begin
        LRenderer.Render(1, 0);
      end, EInvalidOpException);
  finally
    LRenderer.Free;
  end;
end;

procedure TTestSpeedCarSpriteRenderer.DovrebbeDisegnareLeOttoFacceDiUnaAutoDelloShareware;
var
  LPath, LDump: string;
  LContainer: ISpeedContainer;
  LWad: IGameWadComposer;
  LBytes: TBytes;
  LRenderer: TSpeedCarSpriteRenderer;
  LAxes: TSpeedModelAxes;
  LImage: TSpeedCarSpriteImage;
  LRotation, LIndex, LOpaque: Integer;
  LMinimum, LMaximum: Single;
  LText: TStringList;
  LName: string;
  LData: TBytes;
begin
  LPath := FindShareware;
  if LPath = '' then
  begin
    Assert.Pass('SPEEDH.JCL is not there');
    Exit;
  end;
  LContainer := TSpeedFactory.OpenContainer(LPath);
  LWad := TGameDataFactory.CreateWadComposer;
  TSpeedFactory.CreateTranslator(TFakeLog.Create).Translate(LContainer, LWad);
  Assert.IsTrue(LContainer.TryRead('CAR0N0A.I3D', LBytes), 'model');
  LAxes.ForwardAxis := 2; LAxes.ForwardSign := 1;
  LAxes.LeftAxis := 0; LAxes.LeftSign := 1;
  LAxes.UpAxis := 1; LAxes.UpSign := 1;
  LRenderer := TSpeedCarSpriteRenderer.Create(TI3dFactory.CreateParser, TI3dFactory.CreateRenderer,
    TI3dFactory.CreateMeshBuilder, LWad.LumpData[LWad.IndexOf('PLAYPAL')], LWad.LumpData[LWad.IndexOf('COLORMAP')],
    255, LAxes, 128, 20);
  try
    LRenderer.Load(LBytes);
    LDump := TPath.Combine(TPath.GetTempPath, 'ddspeed');
    TDirectory.CreateDirectory(LDump);
    LText := TStringList.Create;
    try
      for LIndex := 0 to 2 do
      begin
        LRenderer.Extent(LIndex, LMinimum, LMaximum);
        LText.Add(Format('axis %d: %.3f .. %.3f', [LIndex, LMinimum, LMaximum]));
      end;
      for LRotation := 1 to SPEED_SPRITE_ROTATIONS do
      begin
        LImage := LRenderer.Render(LRotation, 0);
        LOpaque := 0;
        for LIndex := 0 to High(LImage.Pixels) do
          if LImage.Pixels[LIndex] <> 255 then
            Inc(LOpaque);
        LText.Add(Format('rotation %d: %dx%d offsets %d,%d opaque %d', [LRotation, LImage.Width, LImage.Height,
          LImage.LeftOffset, LImage.TopOffset, LOpaque]));
        Assert.IsTrue(LOpaque > 100, 'the car is not drawn');
        WriteBmp(TPath.Combine(LDump, Format('car_%d.bmp', [LRotation])), LImage, LWad.LumpData[LWad.IndexOf('PLAYPAL')]);
      end;
      for LName in ['NUBES0','NUBES1','NUBES7','MOUNT0','MOUNT1','MOUNT7','SKY1','SKY2','MBG_CAR','CARPOS0','RACEPOS0','RACE_3','MFBG0','MMHELMET','MREVO0','MG0','MPOS','MLAP','MTIME','MGEAR','MWQUOTE','MLAPS'] do
        if LWad.IndexOf(LName) >= 0 then
        begin
          LData := LWad.LumpData[LWad.IndexOf(LName)];
          if Length(LData) >= 8 then
            LText.Add(Format('lump %s: %d bytes, patch %dx%d offsets %d,%d', [LName, Length(LData), PSmallInt(@LData[0])^, PSmallInt(@LData[2])^, PSmallInt(@LData[4])^, PSmallInt(@LData[6])^]));
        end;
      for LName in ['MFBG0', 'MFBW0', 'MFLG0', 'MFLW0', 'MFMG0', 'MFMW0', 'MFMG5', 'MFMW5', 'MG0', 'MG3', 'MREVO0', 'MREVO1', 'MPOS', 'MLAP', 'MTIME',
        'MLAPS', 'MMHELMET', 'MGEAR', 'MSCBAR', 'MPOSBAR', 'RACEPOS0', 'RACEPOS1', 'MBEST', 'MRECORD', 'REXTTIME', 'RFINLAP', 'RTIMEOUT', 'MFBGB', 'MFMGB', 'CARPOS0', 'MSFBAR'] do
        if LWad.IndexOf(LName) >= 0 then
          WritePatchBmp(TPath.Combine(LDump, 'hud_' + LName + '.bmp'), LWad.LumpData[LWad.IndexOf(LName)],
            LWad.LumpData[LWad.IndexOf('PLAYPAL')]);
      for LName in ['SNDINFO', 'SPEEDINF', 'GRAFSPAL', 'FLATSIZE'] do
        if LWad.IndexOf(LName) >= 0 then
          TFile.WriteAllBytes(TPath.Combine(LDump, 'lump_' + LName + '.txt'), LWad.LumpData[LWad.IndexOf(LName)]);
      for LName in ['NUBES0', 'MOUNT0', 'SKY1'] do
        WritePatchBmp(TPath.Combine(LDump, 'lump_' + LName + '.bmp'), LWad.LumpData[LWad.IndexOf(LName)],
          LWad.LumpData[LWad.IndexOf('PLAYPAL')]);
      LText.SaveToFile(TPath.Combine(LDump, 'extents.txt'));
    finally
      LText.Free;
    end;
  finally
    LRenderer.Free;
  end;
end;

end.
