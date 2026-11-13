{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity of the text and of the        }
{  sprites with the C of the remake                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.RenderParity;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Types,
  DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Font.Intf, DelphiDoom.War.Render.Types,
  DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   render.text.golden.txt and render.sprites.golden.txt are the output of war_render_ref.exe: the ORIGINAL war_font.c,
  ///   wr_save ... wr_subImage of war_render.c and war_sprites.c of war1, extracted as they are and compiled with gcc;
  ///   SDL is replaced by stubs that record what they receive (Tools\Verifica\192). The text is 240 scenarios with a
  ///   fixed seed, the sprites are the images, sprites and cursors of the real DATA.WAR. The numbers of the text are
  ///   compared as the bits of the float
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarRenderParity = class(TObject)
  private
    FRng: Cardinal;
    function Golden(const AName: string): TStringList;
    procedure Seed(ASeed: Cardinal);
    function RngNext: Cardinal;
    function RngRange(ACount: Integer): Integer;
    function Bits(AValue: Single): string;
    function BlitsChecksum(const ABlits: TList<TWarBlit>; AFrom: Integer): string;
  public
    [Test]
    procedure DovrebbeDareLeStesseMisureEgliStessiBlitDelCodiceOriginaleSuDuecentoQuarantaTesti;
    [Test]
    procedure DovrebbeDareGliStessiSpriteDelCodiceOriginaleSuTuttiIRecordGrafici;
  end;

implementation

uses
  System.Math, DelphiDoom.MathCore.Crc32, DelphiDoom.War.Factory, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Font.Types, DelphiDoom.War.Text.Types, DelphiDoom.War.Text.Layout, DelphiDoom.War.Text.Renderer,
  DelphiDoom.War.Render.Transform, DelphiDoom.War.Sprite.Sheet;

{ TTestWarRenderParity }

function TTestWarRenderParity.Golden(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TWarRealData.GoldenPath(AName));
  while (Result.Count > 0) and (Result[Result.Count - 1] = '') do
    Result.Delete(Result.Count - 1);
end;

procedure TTestWarRenderParity.Seed(ASeed: Cardinal);
begin
  FRng := ASeed;
end;

function TTestWarRenderParity.RngNext: Cardinal;
begin
  FRng := FRng * 1103515245 + 12345;
  Result := (FRng shr 16) and $7FFF;
end;

function TTestWarRenderParity.RngRange(ACount: Integer): Integer;
begin
  Result := Integer(RngNext mod Cardinal(ACount));
end;

function TTestWarRenderParity.Bits(AValue: Single): string;
var
  LBits: Cardinal;
begin
  Move(AValue, LBits, SizeOf(LBits));
  Result := LowerCase(IntToHex(LBits, 8));
end;

function TTestWarRenderParity.BlitsChecksum(const ABlits: TList<TWarBlit>; AFrom: Integer): string;
var
  LCrc: TCrc32;
  LIndex: Integer;
  LBlit: TWarBlit;
  LFlip: Cardinal;
  procedure Put(AFloat: Single);
  begin
    LCrc.Update(AFloat, 4);
  end;
begin
  LCrc := TCrc32.Create;
  try
    for LIndex := AFrom to ABlits.Count - 1 do
    begin
      LBlit := ABlits[LIndex];
      Put(LBlit.Source.X);
      Put(LBlit.Source.Y);
      Put(LBlit.Source.Width);
      Put(LBlit.Source.Height);
      Put(LBlit.Destination.X);
      Put(LBlit.Destination.Y);
      Put(LBlit.Destination.Width);
      Put(LBlit.Destination.Height);
      LFlip := Cardinal(Ord(LBlit.FlipHorizontal)) + 2 * Cardinal(Ord(LBlit.FlipVertical));
      LCrc.Update(LFlip, 4);
      LCrc.Update(LBlit.Color.R, 1);
      LCrc.Update(LBlit.Color.G, 1);
      LCrc.Update(LBlit.Color.B, 1);
      LCrc.Update(LBlit.Color.A, 1);
    end;
    Result := LowerCase(TCrc32.ToHex(LCrc.Value));
  finally
    LCrc.Free;
  end;
end;

procedure TTestWarRenderParity.DovrebbeDareLeStesseMisureEgliStessiBlitDelCodiceOriginaleSuDuecentoQuarantaTesti;
const
  ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !"#$%&''()*+,-./:;<=>?@[\]^_`{|}~';
  SIZES: array[0..6] of Single = (48.0, 24.0, 36.0, 64.0, 96.0, 13.5, 72.0);
var
  LGolden: TStringList;
  LActual: TStringList;
  LMetrics: IWarFontMetrics;
  LBlits: TList<TWarBlit>;
  LTransform: TWarRenderTransform;
  LRenderer: TWarTextRenderer;
  LScenario: Integer;
  LText: AnsiString;
  LCount: Integer;
  LIndex: Integer;
  LKind: Integer;
  LParams: TWarFontParams;
  LFontIndex: Integer;
  LMode: Integer;
  LMaxCount: Integer;
  LPositionX: Single;
  LPositionY: Single;
  LMeasure1: TWarTextSize;
  LMeasure2: TWarTextSize;
  LMeasure3: TWarTextSize;
  LFrom: Integer;
  LBlit: TWarBlit;
  LOffset: TWarTextSize;
  LSizeOfText: TWarTextSize;
begin
  LGolden := Golden('render.text.golden.txt');
  LActual := TStringList.Create;
  LBlits := TList<TWarBlit>.Create;
  LTransform := TWarRenderTransform.Create(LBlits);
  LRenderer := TWarTextRenderer.Create(LTransform);
  LMetrics := TWarFactory.CreateFontMetrics;
  try
    for LScenario := 0 to 239 do
    begin
      Seed(11000 + Cardinal(LScenario));
      LCount := RngRange(70);
      SetLength(LText, LCount);
      for LIndex := 1 to LCount do
      begin
        LKind := RngRange(24);
        if LKind = 0 then
          LText[LIndex] := #10
        else if LKind = 1 then
          LText[LIndex] := #9
        else if LKind < 5 then
          LText[LIndex] := ' '
        else if (LKind = 5) and (RngRange(8) = 0) then
          LText[LIndex] := AnsiChar(Chr($E0 + RngRange(16)))
        else
          LText[LIndex] := AnsiChar(ALPHABET[RngRange(Length(ALPHABET)) + 1]);
      end;
      LParams := Default(TWarFontParams);
      LFontIndex := RngRange(2);
      Assert.IsTrue(LMetrics.TryGetFont(LFontIndex, LParams.FontData));
      LParams.FontSize := SIZES[RngRange(Length(SIZES))];
      if RngRange(3) = 0 then
        LParams.LineHeight := 20 + RngRange(60)
      else
        LParams.LineHeight := 0;
      LParams.FontColor.R := $EF;
      LParams.FontColor.G := $FF;
      LParams.FontColor.B := $DB;
      LParams.FontColor.A := $FF;
      LParams.HighlightColor.R := $FF;
      LParams.HighlightColor.G := $E3;
      LParams.HighlightColor.B := $49;
      LParams.HighlightColor.A := $FF;
      if RngRange(2) <> 0 then
        LParams.FontColor.R := Byte(RngRange(256));
      LMode := RngRange(4);
      if LMode = 0 then
        LParams.HighlightIndex := -1
      else if LMode = 1 then
        LParams.HighlightIndex := -2
      else
        LParams.HighlightIndex := RngRange(LCount + 1);
      if LParams.HighlightIndex >= 0 then
        LMaxCount := LCount - LParams.HighlightIndex
      else
        LMaxCount := LCount;
      LParams.HighlightCount := RngRange(Min(12, LMaxCount + 1));
      if RngRange(3) <> 0 then
      begin
        LParams.BoundingsX := 40 + RngRange(400);
        LParams.BoundingsY := 30 + RngRange(300);
      end;
      LParams.HorizontalAlign := TWarTextAlignment(RngRange(3));
      LParams.VerticalAlign := TWarTextAlignment(3 + RngRange(3));
      LParams.LineAlign := TWarTextAlignment(RngRange(3));
      LParams.Wrapping := TWarTextWrapping(RngRange(2));
      LParams.Trimming := TWarTextTrimming(RngRange(3));
      LPositionX := RngRange(300);
      LPositionY := RngRange(200);

      LMeasure1 := TWarTextLayout.MeasureSingle(LText, -1, LParams);
      LMeasure2 := TWarTextLayout.MeasureMulti(LText, LParams);
      LMeasure3 := TWarTextLayout.MeasureSingle(LText, LCount div 2, LParams);
      LActual.Add(Format('M %d %s %s %s %s %s %s', [LScenario, Bits(LMeasure1.X), Bits(LMeasure1.Y), Bits(LMeasure2.X),
        Bits(LMeasure2.Y), Bits(LMeasure3.X), Bits(LMeasure3.Y)]));

      LBlits.Clear;
      LFrom := 0;
      LRenderer.RenderSingle(LText, LPositionX, LPositionY, LParams);
      LActual.Add(Format('R %d %d %s', [LScenario, LBlits.Count - LFrom, BlitsChecksum(LBlits, LFrom)]));
      LFrom := LBlits.Count;
      LRenderer.RenderMulti(LText, LPositionX, LPositionY, LParams);
      LActual.Add(Format('L %d %d %s', [LScenario, LBlits.Count - LFrom, BlitsChecksum(LBlits, LFrom)]));
      if (LScenario < 6) and (LBlits.Count > LFrom) then
      begin
        LBlit := LBlits[LFrom];
        LActual.Add(Format('B %d %s %s %s %s %s %s %s %s %d %d %d %d %d', [LScenario, Bits(LBlit.Source.X),
          Bits(LBlit.Source.Y), Bits(LBlit.Source.Width), Bits(LBlit.Source.Height), Bits(LBlit.Destination.X),
          Bits(LBlit.Destination.Y), Bits(LBlit.Destination.Width), Bits(LBlit.Destination.Height),
          Ord(LBlit.FlipHorizontal) + 2 * Ord(LBlit.FlipVertical), LBlit.Color.R, LBlit.Color.G, LBlit.Color.B,
          LBlit.Color.A]));
      end;
      Assert.AreEqual<Integer>(0, LTransform.Depth, 'pila');
    end;
    LParams := Default(TWarFontParams);
    Assert.IsTrue(LMetrics.TryGetFont(0, LParams.FontData));
    LSizeOfText.X := 100;
    LSizeOfText.Y := 30;
    LOffset := TWarTextLayout.AlignmentOffset(wtaRight, wtaBottom, 300, 100, LSizeOfText);
    LActual.Add(Format('A %s %s', [Bits(LOffset.X), Bits(LOffset.Y)]));
    Assert.AreEqual<Integer>(LGolden.Count, LActual.Count, 'righe');
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
  finally
    LMetrics := nil;
    LRenderer.Free;
    LTransform.Free;
    LBlits.Free;
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarRenderParity.DovrebbeDareGliStessiSpriteDelCodiceOriginaleSuTuttiIRecordGrafici;
var
  LGolden: TStringList;
  LActual: TStringList;
  LCatalog: IWarCatalog;
  LGraphics: IWarGraphics;
  LBlits: TList<TWarBlit>;
  LTransform: TWarRenderTransform;
  LLine: string;
  LIndex: Integer;
  LResource: Integer;
  LSheet: TWarSpriteSheet;
  LSubset: TWarSpriteSheet;
  LSprite: TWarSprite;
  LPick: TArray<Integer>;
  LCount: Integer;
  LFrame: TWarSpriteFrame;
  LSource: TWarRectF;
  LDestination: TWarRectF;
  LKind: TWarRecordType;
  LImage: TWarImage;
  LCursor: TWarCursor;

  function Summary(const ATag: string; AResource: Integer; const ASheet: TWarSpriteSheet): string;
  var
    LHead: TCrc32;
    LPool: TCrc32;
    LK: Integer;
    LF: TWarSpriteFrame;
    LHeader: array[0..3] of Word;
  begin
    LHead := TCrc32.Create;
    LPool := TCrc32.Create;
    try
      for LK := 0 to ASheet.FrameCount - 1 do
      begin
        LF := ASheet.GetFrame(LK);
        LHeader[0] := LF.Dx;
        LHeader[1] := LF.Dy;
        LHeader[2] := LF.Width;
        LHeader[3] := LF.Height;
        LHead.Update(LHeader[0], 8);
        LPool.Update(LF.Pixels[0], ASheet.FrameWidth * ASheet.FrameHeight * 4);
      end;
      Result := Format('%s %d %d %d %d %s %s', [ATag, AResource, ASheet.FrameWidth, ASheet.FrameHeight,
        ASheet.FrameCount, LowerCase(TCrc32.ToHex(LHead.Value)), LowerCase(TCrc32.ToHex(LPool.Value))]);
    finally
      LPool.Free;
      LHead.Free;
    end;
  end;

  function BlitsOf(const ASheet: TWarSpriteSheet): string;
  var
    LCrc: TCrc32;
    LK: Integer;
    LB: TWarBlit;
    LFlip: Cardinal;
    procedure Put(AFloat: Single);
    begin
      LCrc.Update(AFloat, 4);
    end;
  begin
    LBlits.Clear;
    LTransform.Save;
    LTransform.Translate(10, 20);
    ASheet.Render(LTransform, 3, 4, 1, 1);
    ASheet.Render(LTransform, 3, 4, -1, 1);
    ASheet.Render(LTransform, 3, 4, 1, -1);
    ASheet.Render(LTransform, 3, 4, -2, -2.5);
    LTransform.Scale(-1, 1);
    LTransform.GlobalAlpha(0.5);
    LSource.X := 1;
    LSource.Y := 2;
    LSource.Width := 5;
    LSource.Height := 6;
    LDestination.X := 7;
    LDestination.Y := 8;
    LDestination.Width := 5;
    LDestination.Height := 6;
    ASheet.RenderPart(LTransform, LSource, LDestination, 2, 2);
    LTransform.Restore;
    LCrc := TCrc32.Create;
    try
      for LK := 0 to LBlits.Count - 1 do
      begin
        LB := LBlits[LK];
        Put(LB.Source.X);
        Put(LB.Source.Y);
        Put(LB.Source.Width);
        Put(LB.Source.Height);
        Put(LB.Destination.X);
        Put(LB.Destination.Y);
        Put(LB.Destination.Width);
        Put(LB.Destination.Height);
        LFlip := Cardinal(Ord(LB.FlipHorizontal)) + 2 * Cardinal(Ord(LB.FlipVertical));
        LCrc.Update(LFlip, 4);
        LCrc.Update(LB.Color.R, 1);
        LCrc.Update(LB.Color.G, 1);
        LCrc.Update(LB.Color.B, 1);
        LCrc.Update(LB.Color.A, 1);
      end;
      Result := Format('%d %s', [LBlits.Count, LowerCase(TCrc32.ToHex(LCrc.Value))]);
    finally
      LCrc.Free;
    end;
  end;

begin
  LCatalog := TWarFactory.CreateCatalog;
  LGraphics := TWarFactory.CreateGraphics(TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog), LCatalog);
  LGolden := Golden('render.sprites.golden.txt');
  LActual := TStringList.Create;
  LBlits := TList<TWarBlit>.Create;
  LTransform := TWarRenderTransform.Create(LBlits);
  try
    for LLine in LGolden do
    begin
      if LLine[1] <> 'W' then
        Continue;
      LResource := StrToInt(Copy(LLine, 3, Pos(' ', Copy(LLine, 3, MaxInt)) - 1));
      LKind := LCatalog.RecordTypeOf(LResource);
      LSheet := nil;
      case LKind of
        wrtImage:
          begin
            LImage := LGraphics.GetImage(LResource);
            LSheet := TWarSpriteSheet.FromImage(LImage);
          end;
        wrtCursor:
          begin
            LCursor := LGraphics.GetCursor(LResource);
            LSheet := TWarSpriteSheet.FromCursor(LCursor);
          end;
        wrtSprite:
          begin
            LSprite := LGraphics.GetSprite(LResource);
            LSheet := TWarSpriteSheet.FromSprite(LSprite, nil);
          end;
      end;
      Assert.IsNotNull(LSheet, 'tipo del record ' + IntToStr(LResource));
      try
        LActual.Add(Summary('W', LResource, LSheet));
        if LKind = wrtSprite then
        begin
          LCount := Length(LSprite.Frames);
          LPick := [LCount - 1];
          if LCount > 1 then
            LPick := LPick + [0];
          if LCount > 2 then
            LPick := LPick + [LCount div 2];
          if LCount > 3 then
            LPick := LPick + [1];
          LSubset := TWarSpriteSheet.FromSprite(LSprite, LPick);
          try
            LActual.Add(Summary('U', LResource, LSubset));
            LFrame := LSubset.GetFrame(LSubset.FrameCount - 1);
            LActual.Add(Format('G %d %d %d %d %d', [LResource, LFrame.Dx, LFrame.Dy, LFrame.Width, LFrame.Height]));
          finally
            LSubset.Free;
          end;
        end;
        LActual.Add(Format('D %d %s', [LResource, BlitsOf(LSheet)]));
      finally
        LSheet.Free;
      end;
    end;
    Assert.AreEqual<Integer>(LGolden.Count, LActual.Count, 'righe');
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
  finally
    LTransform.Free;
    LBlits.Free;
    LActual.Free;
    LGolden.Free;
  end;
end;

end.
