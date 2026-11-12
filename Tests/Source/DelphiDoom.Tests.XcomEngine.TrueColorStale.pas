{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the stale rows of the cache of                     }
{  TXcomTrueColorComposer (issue 183): the composer remembers the last frame    }
{  and composes only the rows that changed; the frame it shows must be the one  }
{  a full composition of the same inputs gives (the reference model)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.TrueColorStale;

{$Q-}{$R-} // the hash and the random numbers wrap around on purpose

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Ink.Types, DelphiDoom.XcomSurface.FontDetail.Intf, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.TrueColor.Intf,
  DelphiDoom.XcomEngine.TrueColorComposer, DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice;

type
  /// <summary>One widget of the model: what it leaves in a frame, from a rectangle and a seed</summary>
  TStaleLayer = record
    /// <summary>0 detail (a chart), 1 blend (smoke), 2 ink (a text)</summary>
    Kind: Integer;
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    Index: Byte;
    Seed: Cardinal;
    /// <summary>Something drawn after the widget covers one of its pixels (a button, a popup, the cursor)</summary>
    Covered: Boolean;
  end;

  /// <summary>Everything a frame is made of: the game picture, the palette and the widgets</summary>
  TStaleModel = record
    Base: TBytes;
    Palette: TXcomColors;
    Layers: TArray<TStaleLayer>;
  end;

  /// <summary>
  ///   A composer that lives through many frames (the cache) is compared at every frame with a composer made
  ///   for that frame alone (a full composition): any row the cache did not redo shows. The inputs are a random
  ///   but fixed story: pixels, palette entries and widgets that change, appear, move and go away
  /// </summary>
  [TestFixture]
  [Category('XcomTrueColor')]
  TTestXcomTrueColorStale = class
  strict private
    const
      BASE_WIDTH = 320;
      BASE_HEIGHT = 200;
    var
      FOptions: TXcomOptions;
      FDevice: TXcomMemoryTrueColorVideoDevice;
      FDeviceRef: IXcomVideoDevice;
      FComposer: TXcomTrueColorComposer;
      FComposerRef: IXcomFrameComposer;
      FScreen: TXcomScreen;
      FModel: TStaleModel;
      FRandom: Cardinal;
      FOptionOn: Boolean;
      FKept: TObjectList<TXcomSurface>;
    function NextRandom(ALimit: Integer): Integer;
    function Hash(ASeed: Cardinal; AIndex: Integer): Cardinal;
    function LayerOf(AKind: Integer): TStaleLayer;
    procedure FreshModel;
    procedure Mutate;
    procedure Draw(AScreen: TXcomScreen; const AInk: IXcomInkLayers);
    procedure DrawLayer(AScreen: TXcomScreen; const ALayer: TStaleLayer; const AInk: IXcomInkLayers);
    /// <summary>Flips and frees the detail surfaces of the frame (the composer keeps them until the flip)</summary>
    procedure ShowFrame(AScreen: TXcomScreen);
    procedure MakeScreen(ADisplayWidth, ADisplayHeight: Integer);
    /// <summary>The model drawn on a screen of its own, with a composer that has nothing remembered</summary>
    function Reference(ADisplayWidth, ADisplayHeight: Integer): TXcomTrueColorPixels;
    procedure AssertFrameIsReference(const AWhat: string; AFrame: Integer);
    procedure RunStory(ASeed: Cardinal; AFrames: Integer; AChangeSize, AToggleOption: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('doppio', '1,640,400')]
    [TestCase('doppio altro seme', '2,640,400')]
    [TestCase('triplo', '3,960,600')]
    [TestCase('quadruplo', '4,1280,800')]
    [TestCase('non intero', '5,500,333')]
    [TestCase('con bande', '6,800,400')]
    [TestCase('scala uno', '7,320,200')]
    procedure UnaStoriaDiFotogrammiDovrebbeDareSempreLaRicomposizioneIntera(ASeed, ADisplayWidth,
      ADisplayHeight: Integer);
    [Test]
    [TestCase('uno', '11')]
    [TestCase('due', '12')]
    [TestCase('tre', '13')]
    [TestCase('quattro', '14')]
    procedure IlRidimensionamentoDellaFinestraNonDovrebbeLasciareRigheStantie(ASeed: Integer);
    [Test]
    [TestCase('uno', '21')]
    [TestCase('due', '22')]
    [TestCase('tre', '23')]
    [TestCase('quattro', '24')]
    procedure SpegnereERiaccendereLOpzioneNonDovrebbeLasciareRigheStantie(ASeed: Integer);
    [Test]
    [TestCase('con ridimensionamento', '31,1')]
    [TestCase('senza ridimensionamento', '32,0')]
    procedure LOpzioneEIlRidimensionamentoInsiemeNonDovrebberoLasciareRigheStantie(ASeed, AResize: Integer);
    [Test]
    procedure UnTestoCheCambiaTraDueFotogrammiDovrebbeDareLaRicomposizioneIntera;
    [Test]
    procedure UnGraficoCheCambiaTraDueFotogrammiDovrebbeDareLaRicomposizioneIntera;
    [Test]
    procedure UnaSfumaturaCheCambiaTraDueFotogrammiDovrebbeDareLaRicomposizioneIntera;
    [Test]
    procedure UnaListaCheScorreDovrebbeDareLaRicomposizioneIntera;
  end;

implementation

procedure TTestXcomTrueColorStale.Setup;
begin
  FOptions := TXcomOptions.Create;
  FDevice := TXcomMemoryTrueColorVideoDevice.Create;
  FDeviceRef := FDevice;
  FComposer := TXcomTrueColorComposer.Create(FDevice);
  FComposerRef := FComposer;
  FOptionOn := True;
  FRandom := Cardinal($92D68CA2);
  FKept := TObjectList<TXcomSurface>.Create(True);
end;

procedure TTestXcomTrueColorStale.ShowFrame(AScreen: TXcomScreen);
begin
  AScreen.Flip;
  FKept.Clear;
end;

procedure TTestXcomTrueColorStale.TearDown;
begin
  FKept.Free;
  FScreen.Free;
  FScreen := nil;
  FComposerRef := nil;
  FDeviceRef := nil;
  FOptions.Free;
end;

function TTestXcomTrueColorStale.NextRandom(ALimit: Integer): Integer;
begin
  // xorshift32: fixed and the same on every machine
  FRandom := FRandom xor (FRandom shl 13);
  FRandom := FRandom xor (FRandom shr 17);
  FRandom := FRandom xor (FRandom shl 5);
  Result := Integer(FRandom mod Cardinal(ALimit));
end;

function TTestXcomTrueColorStale.Hash(ASeed: Cardinal; AIndex: Integer): Cardinal;
begin
  Result := ASeed * Cardinal($9E3779B1) + Cardinal(AIndex) * Cardinal(40503);
  Result := Result xor (Result shr 15);
  Result := Result * Cardinal($85EBCA77);
  Result := Result xor (Result shr 13);
end;

procedure TTestXcomTrueColorStale.FreshModel;
var
  LIndex: Integer;
begin
  SetLength(FModel.Base, BASE_WIDTH * BASE_HEIGHT);
  for LIndex := 0 to High(FModel.Base) do
    FModel.Base[LIndex] := Byte(LIndex mod 251 + 1);
  for LIndex := 0 to 255 do
  begin
    FModel.Palette[LIndex].Red := Byte(LIndex or 1);
    FModel.Palette[LIndex].Green := Byte(255 - LIndex);
    FModel.Palette[LIndex].Blue := Byte((LIndex * 7) and $FF);
    FModel.Palette[LIndex].Alpha := 255;
  end;
  FModel.Layers := nil;
end;

function TTestXcomTrueColorStale.LayerOf(AKind: Integer): TStaleLayer;
begin
  Result.Kind := AKind;
  Result.Width := 4 + NextRandom(20);
  Result.Height := 3 + NextRandom(14);
  Result.X := NextRandom(BASE_WIDTH - Result.Width);
  Result.Y := NextRandom(BASE_HEIGHT - Result.Height);
  Result.Index := Byte(150 + NextRandom(100));
  Result.Seed := Cardinal(NextRandom(1000000) + 1);
  Result.Covered := NextRandom(4) = 0;
end;

procedure TTestXcomTrueColorStale.Mutate;
var
  LCount: Integer;
  LOp: Integer;
  LIndex: Integer;
  LPixel: Integer;
begin
  // a quarter of the frames are the same as the one before: nothing must be redone
  if NextRandom(4) = 0 then
    Exit;
  for LCount := 0 to NextRandom(3) do
  begin
    LOp := NextRandom(10);
    case LOp of
      0, 1:
        for LIndex := 0 to NextRandom(6) do
          FModel.Base[NextRandom(Length(FModel.Base))] := Byte(1 + NextRandom(255));
      2:
        begin
          // a whole row, as a list that scrolls
          LPixel := NextRandom(BASE_HEIGHT);
          for LIndex := 0 to BASE_WIDTH - 1 do
            FModel.Base[LPixel * BASE_WIDTH + LIndex] := Byte((LIndex + LPixel) mod 251 + 1);
        end;
      3:
        FModel.Palette[NextRandom(256)].Green := Byte(NextRandom(256));
      4, 5:
        if Length(FModel.Layers) < 5 then
        begin
          SetLength(FModel.Layers, Length(FModel.Layers) + 1);
          FModel.Layers[High(FModel.Layers)] := LayerOf(NextRandom(3));
        end;
      6:
        if Length(FModel.Layers) > 0 then
        begin
          LIndex := NextRandom(Length(FModel.Layers));
          Delete(FModel.Layers, LIndex, 1);
        end;
      7, 8:
        if Length(FModel.Layers) > 0 then
        begin
          // the content of a widget changes: the text of a list, the points of a chart, the density of a smoke
          LIndex := NextRandom(Length(FModel.Layers));
          FModel.Layers[LIndex].Seed := Cardinal(NextRandom(1000000) + 1);
        end;
      9:
        if Length(FModel.Layers) > 0 then
        begin
          LIndex := NextRandom(Length(FModel.Layers));
          FModel.Layers[LIndex].Covered := not FModel.Layers[LIndex].Covered;
          if NextRandom(2) = 0 then
            FModel.Layers[LIndex] := LayerOf(FModel.Layers[LIndex].Kind);
        end;
    end;
  end;
end;

procedure TTestXcomTrueColorStale.DrawLayer(AScreen: TXcomScreen; const ALayer: TStaleLayer;
  const AInk: IXcomInkLayers);
var
  LScale: Integer;
  LDetailLayers: IXcomDetailLayers;
  LBlendLayers: IXcomBlendLayers;
  LDetail: TXcomSurface;
  LValid: TBytes;
  LColors: TXcomTrueColorPixels;
  LInk: TXcomInkBuffer;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LHash: Cardinal;
begin
  case ALayer.Kind of
    0:
      begin
        LDetailLayers := AScreen.DetailLayers;
        if not Assigned(LDetailLayers) then
        begin
          AScreen.GetSurface.DrawRect(ALayer.X, ALayer.Y, ALayer.Width, ALayer.Height, ALayer.Index);
          Exit;
        end;
        LScale := LDetailLayers.DetailScale;
        // the composer does not own the detail: it must live until the frame is flipped (ShowFrame frees it)
        LDetail := TXcomSurface.Create(ALayer.Width * LScale, ALayer.Height * LScale);
        FKept.Add(LDetail);
        for LY := 0 to LDetail.Height - 1 do
          for LX := 0 to LDetail.Width - 1 do
            case Hash(ALayer.Seed, LY * LDetail.Width + LX) mod 4 of
              0: LDetail.SetPixel(LX, LY, 0);
              1: LDetail.SetPixel(LX, LY, Byte(ALayer.Index xor $0F));
            else
              LDetail.SetPixel(LX, LY, ALayer.Index);
            end;
        LDetailLayers.BeginLayer(AScreen.GetSurface, ALayer.X, ALayer.Y, ALayer.Width, ALayer.Height);
        AScreen.GetSurface.DrawRect(ALayer.X, ALayer.Y, ALayer.Width, ALayer.Height, ALayer.Index);
        LDetailLayers.EndLayer(AScreen.GetSurface, LDetail);
      end;
    1:
      begin
        AScreen.GetSurface.DrawRect(ALayer.X, ALayer.Y, ALayer.Width, ALayer.Height, ALayer.Index);
        LBlendLayers := AScreen.BlendLayers;
        if not Assigned(LBlendLayers) then
          Exit;
        SetLength(LValid, ALayer.Width * ALayer.Height);
        SetLength(LColors, ALayer.Width * ALayer.Height);
        for LIndex := 0 to High(LValid) do
        begin
          LHash := Hash(ALayer.Seed, LIndex);
          if LHash mod 3 = 0 then
          begin
            LValid[LIndex] := 1;
            LColors[LIndex] := $FF000000 or (LHash shr 8);
          end;
        end;
        LBlendLayers.AddBlendLayer(AScreen.GetSurface, ALayer.X, ALayer.Y, ALayer.Width, ALayer.Height, LValid,
          LColors, ALayer.Width);
      end;
  else
    begin
      if not Assigned(AInk) or
        not AInk.BeginInk(AScreen.GetSurface, ALayer.X, ALayer.Y, ALayer.Width, ALayer.Height) then
      begin
        // no ink on this screen (scale 1 or not whole): the text of the game picture only
        for LIndex := 0 to ALayer.Width * ALayer.Height - 1 do
          if Hash(ALayer.Seed, LIndex) mod 5 = 0 then
            AScreen.GetSurface.SetPixel(ALayer.X + LIndex mod ALayer.Width, ALayer.Y + LIndex div ALayer.Width,
              ALayer.Index);
        Exit;
      end;
      LScale := AScreen.Width div BASE_WIDTH;
      LInk := TXcomInkBuffer.Make(ALayer.Width, ALayer.Height, LScale);
      for LIndex := 0 to ALayer.Width * ALayer.Height - 1 do
      begin
        LHash := Hash(ALayer.Seed, LIndex);
        if LHash mod 5 = 0 then
        begin
          // the text of the game picture, and the ink that replaces it at the scale of the display
          AScreen.GetSurface.SetPixel(ALayer.X + LIndex mod ALayer.Width, ALayer.Y + LIndex div ALayer.Width,
            ALayer.Index);
          for LY := 0 to LScale - 1 do
            for LX := 0 to LScale - 1 do
              if (LHash shr (LX + LY * 2)) and 1 = 0 then
                LInk.Put((LIndex mod ALayer.Width) * LScale + LX, (LIndex div ALayer.Width) * LScale + LY,
                  TXcomInkBuffer.Pack(Byte(ALayer.Index xor $F0), Byte(40 + (LHash shr 20) mod 200), 0, 0));
        end;
      end;
      AInk.EndInk(AScreen.GetSurface, LInk, nil);
    end;
  end;
end;

procedure TTestXcomTrueColorStale.Draw(AScreen: TXcomScreen; const AInk: IXcomInkLayers);
var
  LX: Integer;
  LY: Integer;
  LLayer: TStaleLayer;
begin
  AScreen.SetPalette(@FModel.Palette[0], 0, 256);
  for LY := 0 to BASE_HEIGHT - 1 do
    for LX := 0 to BASE_WIDTH - 1 do
      AScreen.GetSurface.SetPixel(LX, LY, FModel.Base[LY * BASE_WIDTH + LX]);
  for LLayer in FModel.Layers do
    DrawLayer(AScreen, LLayer, AInk);
  // the buttons, the popups and the cursor of the states come after the widgets
  for LLayer in FModel.Layers do
    if LLayer.Covered then
      AScreen.GetSurface.SetPixel(LLayer.X + LLayer.Width div 2, LLayer.Y + LLayer.Height div 2, 77);
end;

procedure TTestXcomTrueColorStale.MakeScreen(ADisplayWidth, ADisplayHeight: Integer);
begin
  FOptions.DisplayWidth := ADisplayWidth;
  FOptions.DisplayHeight := ADisplayHeight;
  FOptions.BaseXResolution := BASE_WIDTH;
  FOptions.BaseYResolution := BASE_HEIGHT;
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef, FComposerRef);
  FScreen.ComposerSource :=
    function: IXcomFrameComposer
    begin
      if FOptionOn then
        Result := FComposerRef
      else
        Result := nil;
    end;
  FScreen.SetPalette(@FModel.Palette[0], 0, 256);
  FScreen.GetSurface.Clear(1);
  // the composer takes ink only on a picture it already composed a frame from
  ShowFrame(FScreen);
end;

function TTestXcomTrueColorStale.Reference(ADisplayWidth, ADisplayHeight: Integer): TXcomTrueColorPixels;
var
  LOptions: TXcomOptions;
  LDevice: TXcomMemoryTrueColorVideoDevice;
  LDeviceRef: IXcomVideoDevice;
  LComposer: TXcomTrueColorComposer;
  LComposerRef: IXcomFrameComposer;
  LInk: IXcomInkLayers;
  LScreen: TXcomScreen;
  LBlack: TXcomColors;
begin
  LOptions := TXcomOptions.Create;
  LDevice := TXcomMemoryTrueColorVideoDevice.Create;
  LDeviceRef := LDevice;
  LComposer := TXcomTrueColorComposer.Create(LDevice);
  LComposerRef := LComposer;
  LInk := LComposer;
  LOptions.DisplayWidth := ADisplayWidth;
  LOptions.DisplayHeight := ADisplayHeight;
  LOptions.BaseXResolution := BASE_WIDTH;
  LOptions.BaseYResolution := BASE_HEIGHT;
  LScreen := TXcomScreen.Create(LOptions, LDeviceRef, LComposerRef);
  try
    // a first frame with another palette: the second is composed in full whatever the first remembered
    FillChar(LBlack, SizeOf(LBlack), 0);
    LScreen.SetPalette(@LBlack[0], 0, 256);
    ShowFrame(LScreen);
    Draw(LScreen, LInk);
    ShowFrame(LScreen);
    Assert.AreEqual(BASE_HEIGHT, LComposer.ComposedRows, 'il riferimento si compone intero');
    Result := Copy(LDevice.TrueColorPixels);
  finally
    LScreen.Free;
    LInk := nil;
    LComposerRef := nil;
    LDeviceRef := nil;
    LOptions.Free;
  end;
end;

procedure TTestXcomTrueColorStale.AssertFrameIsReference(const AWhat: string; AFrame: Integer);
var
  LExpected: TXcomTrueColorPixels;
  LIndex: Integer;
begin
  LExpected := Reference(FScreen.Width, FScreen.Height);
  Assert.AreEqual(Length(LExpected), Length(FDevice.TrueColorPixels),
    Format('%s, fotogramma %d: misura', [AWhat, AFrame]));
  for LIndex := 0 to High(LExpected) do
    if LExpected[LIndex] <> FDevice.TrueColorPixels[LIndex] then
      Assert.Fail(Format('%s, fotogramma %d: riga %d colonna %d e'' %x e doveva essere %x (righe ricomposte %d)',
        [AWhat, AFrame, LIndex div FScreen.Width, LIndex mod FScreen.Width, FDevice.TrueColorPixels[LIndex],
        LExpected[LIndex], FComposer.ComposedRows]));
end;

procedure TTestXcomTrueColorStale.RunStory(ASeed: Cardinal; AFrames: Integer; AChangeSize, AToggleOption: Boolean);
const
  SIZES: array[0..5, 0..1] of Integer = ((640, 400), (960, 600), (320, 200), (500, 333), (800, 400), (1280, 800));
var
  LFrame: Integer;
  LInk: IXcomInkLayers;
  LPresented: Integer;
  LEightBit: Integer;
  LSize: Integer;
begin
  FRandom := FRandom xor (ASeed * Cardinal($9E3779B1));
  FreshModel;
  Mutate;
  MakeScreen(640, 400);
  for LFrame := 1 to AFrames do
  begin
    Mutate;
    if AChangeSize and (NextRandom(6) = 0) then
    begin
      LSize := NextRandom(Length(SIZES));
      FOptions.DisplayWidth := SIZES[LSize, 0];
      FOptions.DisplayHeight := SIZES[LSize, 1];
      FScreen.ResetDisplay;
    end;
    if AToggleOption and (NextRandom(5) = 0) then
    begin
      FOptionOn := not FOptionOn;
      FScreen.ResetDisplay;
    end;
    LPresented := FDevice.TrueColorPresented;
    LEightBit := FDevice.Presented;
    if FOptionOn then
      LInk := FComposer
    else
      LInk := nil;
    Draw(FScreen, LInk);
    ShowFrame(FScreen);
    if FOptionOn then
    begin
      Assert.AreEqual(LPresented + 1, FDevice.TrueColorPresented, Format('fotogramma %d a colori', [LFrame]));
      AssertFrameIsReference(Format('seme %d', [ASeed]), LFrame);
    end
    else
    begin
      Assert.AreEqual(LPresented, FDevice.TrueColorPresented, 'a opzione spenta nessun fotogramma a colori');
      Assert.AreEqual(LEightBit + 1, FDevice.Presented, 'a opzione spenta l''immagine a 8 bit');
    end;
  end;
end;

procedure TTestXcomTrueColorStale.UnaStoriaDiFotogrammiDovrebbeDareSempreLaRicomposizioneIntera(ASeed,
  ADisplayWidth, ADisplayHeight: Integer);
var
  LFrame: Integer;
  LInk: IXcomInkLayers;
begin
  FRandom := FRandom xor (Cardinal(ASeed) * Cardinal($9E3779B1));
  FreshModel;
  Mutate;
  MakeScreen(ADisplayWidth, ADisplayHeight);
  LInk := FComposer;
  for LFrame := 1 to 40 do
  begin
    Mutate;
    Draw(FScreen, LInk);
    ShowFrame(FScreen);
    AssertFrameIsReference(Format('seme %d, %dx%d', [ASeed, ADisplayWidth, ADisplayHeight]), LFrame);
  end;
end;

procedure TTestXcomTrueColorStale.IlRidimensionamentoDellaFinestraNonDovrebbeLasciareRigheStantie(ASeed: Integer);
begin
  RunStory(Cardinal(ASeed), 40, True, False);
end;

procedure TTestXcomTrueColorStale.SpegnereERiaccendereLOpzioneNonDovrebbeLasciareRigheStantie(ASeed: Integer);
begin
  RunStory(Cardinal(ASeed), 40, False, True);
end;

procedure TTestXcomTrueColorStale.LOpzioneEIlRidimensionamentoInsiemeNonDovrebberoLasciareRigheStantie(ASeed,
  AResize: Integer);
begin
  RunStory(Cardinal(ASeed), 50, AResize <> 0, True);
end;

procedure TTestXcomTrueColorStale.UnTestoCheCambiaTraDueFotogrammiDovrebbeDareLaRicomposizioneIntera;
var
  LInk: IXcomInkLayers;
begin
  FreshModel;
  SetLength(FModel.Layers, 1);
  FModel.Layers[0] := LayerOf(2);
  MakeScreen(960, 600);
  LInk := FComposer;
  Draw(FScreen, LInk);
  ShowFrame(FScreen);
  AssertFrameIsReference('testo', 1);
  // the text of the label changes, the rectangle stays
  FModel.Layers[0].Seed := FModel.Layers[0].Seed + 17;
  Draw(FScreen, LInk);
  ShowFrame(FScreen);
  AssertFrameIsReference('testo', 2);
  // and goes away
  FModel.Layers := nil;
  Draw(FScreen, LInk);
  ShowFrame(FScreen);
  AssertFrameIsReference('testo', 3);
end;

procedure TTestXcomTrueColorStale.UnGraficoCheCambiaTraDueFotogrammiDovrebbeDareLaRicomposizioneIntera;
begin
  FreshModel;
  SetLength(FModel.Layers, 1);
  FModel.Layers[0] := LayerOf(0);
  MakeScreen(1280, 800);
  Draw(FScreen, nil);
  ShowFrame(FScreen);
  AssertFrameIsReference('grafico', 1);
  // a new point of the chart: the finer drawing changes, the game picture does not
  FModel.Layers[0].Seed := FModel.Layers[0].Seed + 1;
  Draw(FScreen, nil);
  ShowFrame(FScreen);
  AssertFrameIsReference('grafico', 2);
  FModel.Layers := nil;
  Draw(FScreen, nil);
  ShowFrame(FScreen);
  AssertFrameIsReference('grafico', 3);
end;

procedure TTestXcomTrueColorStale.UnaSfumaturaCheCambiaTraDueFotogrammiDovrebbeDareLaRicomposizioneIntera;
begin
  FreshModel;
  SetLength(FModel.Layers, 1);
  FModel.Layers[0] := LayerOf(1);
  MakeScreen(640, 400);
  Draw(FScreen, nil);
  ShowFrame(FScreen);
  AssertFrameIsReference('fumo', 1);
  FModel.Layers[0].Seed := FModel.Layers[0].Seed + 1;
  Draw(FScreen, nil);
  ShowFrame(FScreen);
  AssertFrameIsReference('fumo', 2);
  FModel.Layers := nil;
  Draw(FScreen, nil);
  ShowFrame(FScreen);
  AssertFrameIsReference('fumo', 3);
end;

procedure TTestXcomTrueColorStale.UnaListaCheScorreDovrebbeDareLaRicomposizioneIntera;
var
  LFrame: Integer;
  LRow: Integer;
  LX: Integer;
  LInk: IXcomInkLayers;
begin
  FreshModel;
  SetLength(FModel.Layers, 1);
  FModel.Layers[0] := LayerOf(2);
  FModel.Layers[0].Covered := False;
  MakeScreen(640, 400);
  LInk := FComposer;
  for LFrame := 1 to 12 do
  begin
    // every row of the list takes the pixels of the one below it, as a list that scrolls
    for LRow := 100 to 140 do
      for LX := 0 to BASE_WIDTH - 1 do
        FModel.Base[LRow * BASE_WIDTH + LX] := FModel.Base[(LRow + 1) * BASE_WIDTH + LX];
    FModel.Layers[0].Seed := FModel.Layers[0].Seed + Cardinal(LFrame);
    Draw(FScreen, LInk);
    ShowFrame(FScreen);
    AssertFrameIsReference('lista', LFrame);
  end;
end;

end.
