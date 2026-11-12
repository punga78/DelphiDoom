{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the fonts, the text on the buffer   }
{  of the HUD and the messages to the player                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Font;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter,
  DelphiDoom.Greed.MessageLine, DelphiDoom.Tests.Greed.Builders;

type
  /// <summary>
  ///   A font 2 pixels high: "A" is 2 columns (1 over 0, then 2 over 3), "B" is 1 column (0 over 4), the space is
  ///   1 empty column
  /// </summary>
  TFontSample = class
  public
    class function Lump: TBytes; static;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedFont = class(TObject)
  strict private
    FFont: TGreedFont;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereAltezzaLarghezzeEPosizioni;
    [Test]
    procedure DovrebbeSommareLeLarghezzeELoSpazioTraICaratteri;
    [Test]
    procedure DovrebbeDareZeroFuoriDalLump;
    [Test]
    procedure DovrebbePrendereUnCarattereOltre255Modulo256;
    [Test]
    procedure DovrebbeRifiutareUnLumpTroppoCorto;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedTextPrinter = class(TObject)
  strict private
    FCanvas: TGreedCanvas;
    FFont: TGreedFont;
    FPrinter: TGreedTextPrinter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaCanvas;
    [Test]
    procedure DovrebbeSollevareSenzaFont;
    [Test]
    procedure DovrebbeDisegnareTestoESfondoConRawPrint;
    [Test]
    procedure DovrebbeDisegnareSoloIlTestoConRawPrint2;
    [Test]
    procedure DovrebbeAvanzareDiLarghezzaPiuSpazio;
    [Test]
    procedure DovrebbeAndareACapoConPrint;
    [Test]
    procedure DovrebbeCentrareOgniRiga;
    [Test]
    procedure DovrebbeCentrareIlBloccoInVerticale;
    [Test]
    procedure DovrebbeContinuareSullaRigaDopoOltreIlBordo;
    [Test]
    procedure DovrebbeNonDisegnareSuUnaRigaCheNonEsiste;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedMessageLine = class(TObject)
  strict private
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FState: TGreedGameState;
    FCanvas: TGreedCanvas;
    FFont: TGreedFont;
    FPrinter: TGreedTextPrinter;
    FLine: TGreedMessageLine;
    FMessages: IGreedMessages;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeMettereIlMessaggioNellUltimaRiga;
    [Test]
    procedure DovrebbeFarSalireIMessaggiVecchi;
    [Test]
    procedure DovrebbeTagliareA255Caratteri;
    [Test]
    procedure DovrebbeDisegnareLeRigheNonVuoteDallAlto;
    [Test]
    procedure DovrebbeDisegnarePiuInBassoSottoLaBarraInAlto;
    [Test]
    procedure DovrebbeTogliereLaPrimaRigaATempoScaduto;
    [Test]
    procedure DovrebbeRifiutareUnaRigaCheNonEsiste;
  end;

implementation

{ TFontSample }

class function TFontSample.Lump: TBytes;
begin
  SetLength(Result, GREED_FONT_HEADER_BYTES + 8);
  FillChar(Result[0], Length(Result), 0);
  TGreedLumps.PutWord(Result, 0, 2);
  Result[2 + Ord('A')] := 2;
  Result[2 + Ord('B')] := 1;
  Result[2 + Ord(' ')] := 1;
  TGreedLumps.PutWord(Result, 2 + 256 + 2 * Ord('A'), GREED_FONT_HEADER_BYTES);
  TGreedLumps.PutWord(Result, 2 + 256 + 2 * Ord('B'), GREED_FONT_HEADER_BYTES + 4);
  TGreedLumps.PutWord(Result, 2 + 256 + 2 * Ord(' '), GREED_FONT_HEADER_BYTES + 6);
  Result[GREED_FONT_HEADER_BYTES] := 1;
  Result[GREED_FONT_HEADER_BYTES + 1] := 0;
  Result[GREED_FONT_HEADER_BYTES + 2] := 2;
  Result[GREED_FONT_HEADER_BYTES + 3] := 3;
  Result[GREED_FONT_HEADER_BYTES + 4] := 0;
  Result[GREED_FONT_HEADER_BYTES + 5] := 4;
end;

{ TTestGreedFont }

procedure TTestGreedFont.Setup;
begin
  FFont := TGreedFont.Create(TFontSample.Lump);
end;

procedure TTestGreedFont.TearDown;
begin
  FFont.Free;
end;

procedure TTestGreedFont.DovrebbeLeggereAltezzaLarghezzeEPosizioni;
begin
  Assert.AreEqual(2, FFont.Height);
  Assert.AreEqual(2, FFont.CharWidth('A'));
  Assert.AreEqual(1, FFont.CharWidth('B'));
  Assert.AreEqual(0, FFont.CharWidth('C'));
  Assert.AreEqual(GREED_FONT_HEADER_BYTES + 4, FFont.CharOffset('B'));
  Assert.AreEqual(Byte(3), FFont.DataAt(FFont.CharOffset('A') + 3));
end;

procedure TTestGreedFont.DovrebbeSommareLeLarghezzeELoSpazioTraICaratteri;
begin
  Assert.AreEqual(0, FFont.RawWidth(''));
  Assert.AreEqual(3 + 2 + 1, FFont.RawWidth('ABC'), 'a character without a picture still takes the spacing');
  Assert.AreEqual(2 + 3 + 1 + 3, FFont.RawWidth('AB', 3));
end;

procedure TTestGreedFont.DovrebbeDareZeroFuoriDalLump;
begin
  Assert.AreEqual(Byte(0), FFont.DataAt(-1));
  Assert.AreEqual(Byte(0), FFont.DataAt(100000));
end;

procedure TTestGreedFont.DovrebbePrendereUnCarattereOltre255Modulo256;
begin
  Assert.AreEqual(2, FFont.CharWidth(Char(256 + Ord('A'))));
end;

procedure TTestGreedFont.DovrebbeRifiutareUnLumpTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedFont.Create(TBytes.Create(5, 0, 1)).Free;
    end, EGreedDataException);
end;

{ TTestGreedTextPrinter }

procedure TTestGreedTextPrinter.Setup;
begin
  FCanvas := TGreedCanvas.Create;
  FCanvas.ApproxZero := 90;
  FFont := TGreedFont.Create(TFontSample.Lump);
  FPrinter := TGreedTextPrinter.Create(FCanvas);
  FPrinter.Font := FFont;
  FPrinter.BaseColor := 10;
end;

procedure TTestGreedTextPrinter.TearDown;
begin
  FPrinter.Free;
  FFont.Free;
  FCanvas.Free;
end;

procedure TTestGreedTextPrinter.DovrebbeSollevareSenzaCanvas;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedTextPrinter.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedTextPrinter.DovrebbeSollevareSenzaFont;
begin
  FPrinter.Font := nil;
  Assert.WillRaise(
    procedure
    begin
      FPrinter.RawPrint('A');
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      FPrinter.RawWidth('A');
    end, EGreedException);
end;

procedure TTestGreedTextPrinter.DovrebbeDisegnareTestoESfondoConRawPrint;
begin
  FPrinter.PrintX := 5;
  FPrinter.PrintY := 7;
  FPrinter.RawPrint('A');
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(5, 7));
  Assert.AreEqual(Byte(90), FCanvas.GetPixel(5, 8), 'the background is the approx zero');
  Assert.AreEqual(Byte(12), FCanvas.GetPixel(6, 7));
  Assert.AreEqual(Byte(13), FCanvas.GetPixel(6, 8));
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(7, 7), 'the spacing is not drawn');
  FCanvas.Clear;
  FPrinter.PrintX := 5;
  FPrinter.RawPrint4('A');
  Assert.AreEqual(Byte(90), FCanvas.GetPixel(5, 8));
end;

procedure TTestGreedTextPrinter.DovrebbeDisegnareSoloIlTestoConRawPrint2;
begin
  FCanvas.PutPixel(5, 8, 200);
  FPrinter.PrintX := 5;
  FPrinter.PrintY := 7;
  FPrinter.RawPrint2('A');
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(5, 7));
  Assert.AreEqual(Byte(200), FCanvas.GetPixel(5, 8), 'what is below stays');
  FPrinter.PrintX := 5;
  FPrinter.RawPrint3('A');
  Assert.AreEqual(Byte(200), FCanvas.GetPixel(5, 8));
end;

procedure TTestGreedTextPrinter.DovrebbeAvanzareDiLarghezzaPiuSpazio;
begin
  FPrinter.PrintX := 5;
  FPrinter.PrintY := 7;
  FPrinter.RawPrint2('AB');
  Assert.AreEqual(5 + 3 + 2, FPrinter.PrintX);
  Assert.AreEqual(7, FPrinter.PrintY);
  Assert.AreEqual(Byte(14), FCanvas.GetPixel(8, 8), 'B starts after A and one pixel of spacing');
  Assert.AreEqual(5, FPrinter.RawWidth('AB'));
  FPrinter.Spacing := 4;
  Assert.AreEqual(11, FPrinter.RawWidth('AB'));
end;

procedure TTestGreedTextPrinter.DovrebbeAndareACapoConPrint;
begin
  FPrinter.PrintX := 5;
  FPrinter.PrintY := 7;
  FPrinter.Print('A'#10#10'B');
  Assert.AreEqual(0, FPrinter.PrintX);
  Assert.AreEqual(7 + 3 * 2, FPrinter.PrintY);
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(5, 7));
  Assert.AreEqual(Byte(14), FCanvas.GetPixel(0, 12), 'the third line starts at the left edge');
end;

procedure TTestGreedTextPrinter.DovrebbeCentrareOgniRiga;
begin
  FPrinter.PrintY := 20;
  FPrinter.PrintCentered('A'#13#10'B');
  // (320 - 3) div 2 = 158 and (320 - 2) div 2 = 159
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(158, 20));
  Assert.AreEqual(Byte(14), FCanvas.GetPixel(159, 23));
  Assert.AreEqual(24, FPrinter.PrintY);
end;

procedure TTestGreedTextPrinter.DovrebbeCentrareIlBloccoInVerticale;
begin
  FPrinter.BlockCenterPrint('A'#10'A');
  // two lines of 2: (200 - 4) div 2 = 98
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(158, 98));
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(158, 100));
  Assert.AreEqual(102, FPrinter.PrintY);
end;

procedure TTestGreedTextPrinter.DovrebbeContinuareSullaRigaDopoOltreIlBordo;
begin
  FPrinter.PrintX := 319;
  FPrinter.PrintY := 7;
  FPrinter.RawPrint2('A');
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(319, 7));
  Assert.AreEqual(Byte(12), FCanvas.GetPixel(0, 8), 'as the original: the next byte of the buffer');
end;

procedure TTestGreedTextPrinter.DovrebbeNonDisegnareSuUnaRigaCheNonEsiste;
var
  LIndex: Integer;
begin
  FPrinter.PrintX := 5;
  FPrinter.PrintY := -1;
  FPrinter.RawPrint('A');
  FPrinter.PrintX := 5;
  FPrinter.PrintY := 199;
  FPrinter.RawPrint2('B');
  Assert.AreEqual(7, FPrinter.PrintX, 'the position still moves');
  for LIndex := 0 to High(FCanvas.Pixels) do
    Assert.AreEqual(Byte(0), FCanvas.Pixels[LIndex]);
end;

{ TTestGreedMessageLine }

procedure TTestGreedMessageLine.Setup;
begin
  FWorld := TGreedWorld.Create;
  FSprites := TGreedLinkedPool<TGreedSprite>.Create(8, 'sprites');
  FElevators := TGreedLinkedPool<TGreedElevator>.Create(8, 'elevators');
  FState := TGreedGameState.Create(FWorld, FSprites, FElevators);
  FCanvas := TGreedCanvas.Create;
  FFont := TGreedFont.Create(TFontSample.Lump);
  FPrinter := TGreedTextPrinter.Create(FCanvas);
  FLine := TGreedMessageLine.Create(FState, FPrinter, FFont);
  FMessages := FLine;
end;

procedure TTestGreedMessageLine.TearDown;
begin
  FMessages := nil;
  FPrinter.Free;
  FFont.Free;
  FCanvas.Free;
  FState.Free;
  FElevators.Free;
  FSprites.Free;
  FWorld := nil;
end;

procedure TTestGreedMessageLine.DovrebbeSollevareSenzaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedMessageLine.Create(nil, FPrinter, FFont).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMessageLine.Create(FState, nil, FFont).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedMessageLine.Create(FState, FPrinter, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedMessageLine.DovrebbeMettereIlMessaggioNellUltimaRiga;
begin
  FState.TimeCount := 100;
  FMessages.WriteMessage('A');
  Assert.AreEqual('', FLine.Lines[0]);
  Assert.AreEqual('', FLine.Lines[1]);
  Assert.AreEqual('A', FLine.Lines[2]);
  Assert.AreEqual(100 + GREED_MESSAGE_TIME, FLine.TimeMessage);
end;

procedure TTestGreedMessageLine.DovrebbeFarSalireIMessaggiVecchi;
begin
  FMessages.WriteMessage('1');
  FMessages.WriteMessage('2');
  FMessages.WriteMessage('3');
  FMessages.WriteMessage('4');
  Assert.AreEqual('2', FLine.Lines[0]);
  Assert.AreEqual('3', FLine.Lines[1]);
  Assert.AreEqual('4', FLine.Lines[2]);
end;

procedure TTestGreedMessageLine.DovrebbeTagliareA255Caratteri;
begin
  FMessages.WriteMessage(StringOfChar('A', 300));
  Assert.AreEqual(255, Integer(Length(FLine.Lines[2])));
end;

procedure TTestGreedMessageLine.DovrebbeDisegnareLeRigheNonVuoteDallAlto;
begin
  FMessages.WriteMessage('A');
  FMessages.WriteMessage('B');
  FLine.Rewrite(0);
  // the font 1 with the base color 73, the lines 6 rows apart from (2, 1)
  Assert.AreEqual(Byte(74), FCanvas.GetPixel(2, 1));
  Assert.AreEqual(Byte(77), FCanvas.GetPixel(2, 8));
  Assert.AreEqual(73, FPrinter.BaseColor);
end;

procedure TTestGreedMessageLine.DovrebbeDisegnarePiuInBassoSottoLaBarraInAlto;
begin
  FMessages.WriteMessage('A');
  FLine.Rewrite(4);
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(2, 1));
  Assert.AreEqual(Byte(74), FCanvas.GetPixel(2, 11));
end;

procedure TTestGreedMessageLine.DovrebbeTogliereLaPrimaRigaATempoScaduto;
begin
  FState.TimeCount := 0;
  FMessages.WriteMessage('1');
  FMessages.WriteMessage('2');
  FState.TimeCount := GREED_MESSAGE_TIME;
  FLine.Rewrite(0);
  Assert.AreEqual('1', FLine.Lines[1], 'not yet: the time must be over, not just reached');
  FState.TimeCount := GREED_MESSAGE_TIME + 1;
  FLine.Rewrite(0);
  Assert.AreEqual('1', FLine.Lines[0], 'the lines go up by one');
  Assert.AreEqual('2', FLine.Lines[1]);
  Assert.AreEqual('', FLine.Lines[2]);
  Assert.AreEqual(2 * GREED_MESSAGE_TIME + 1, FLine.TimeMessage);
  FState.TimeCount := 3 * GREED_MESSAGE_TIME;
  FLine.Rewrite(0);
  Assert.AreEqual('2', FLine.Lines[0]);
  Assert.AreEqual('', FLine.Lines[1]);
end;

procedure TTestGreedMessageLine.DovrebbeRifiutareUnaRigaCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      Assert.AreEqual('', FLine.Lines[3]);
    end, EGreedException);
end;

end.
