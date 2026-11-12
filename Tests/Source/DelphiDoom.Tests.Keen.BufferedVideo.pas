{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the double buffered drawing,    }
{  the strings and the cursor                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.BufferedVideo;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf,
  DelphiDoom.Tests.Keen.UiWorld;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenBufferedVideo = class(TObject)
  strict private
    FWorld: TKeenUiWorld;
    procedure White;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure UnDisegnoDovrebbeAndareSulBufferEMostrarsiConLAggiornamento;
    [Test]
    procedure LAggiornamentoDovrebbeCopiareSoloLeTileSegnate;
    [Test]
    procedure IlSegnoDovrebbeTagliareIBlocchiFuoriDalloSchermo;
    [Test]
    procedure UnaStringaDovrebbeDisegnareIBitDelFontInXor;
    [Test]
    procedure UnaStringaDisegnataDueVolteDovrebbeSparire;
    [Test]
    procedure IlColoreDelFontDovrebbeScegliereIPiani;
    [Test]
    procedure UnaStringaDovrebbeSpostarePx;
    [Test]
    procedure UnaStringaAUnXDispariDovrebbeEssereSpostataDiBit;
    [Test]
    procedure UnaStringaTroppoLargaDovrebbeDareEccezione;
    [Test]
    procedure LaMisuraDovrebbeEssereQuellaDelFont;
    [Test]
    procedure IlCursoreDovrebbeVedersiSoloSullaPaginaMostrata;
    [Test]
    procedure IlCursoreSenzaSpriteDovrebbeDareEccezione;
    [Test]
    procedure LAttesaDovrebbeDurareITicChiesti;
    [Test]
    procedure IlRipristinoDelBufferDovrebbeCopiareLaPaginaMostrata;
    [Test]
    procedure LeImmaginiELeTileDovrebberoSegnareIlLoroRettangolo;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.BufferedVideo;

{ TTestKeenBufferedVideo }

procedure TTestKeenBufferedVideo.Setup;
begin
  FWorld := TKeenUiWorld.Create(nil, '');
end;

procedure TTestKeenBufferedVideo.TearDown;
begin
  FWorld.Free;
end;

procedure TTestKeenBufferedVideo.White;
begin
  FWorld.Buffered.Bar(0, 0, 320, 200, KEEN_WHITE);
  FWorld.Buffered.UpdateScreen;
end;

procedure TTestKeenBufferedVideo.UnDisegnoDovrebbeAndareSulBufferEMostrarsiConLAggiornamento;
begin
  FWorld.Buffered.InitDoubleBuffer;
  FWorld.Buffered.Bar(32, 16, 16, 8, 4);
  Assert.AreEqual(4, Integer(FWorld.BufferPixel(40, 20)));
  Assert.AreEqual(0, Integer(FWorld.DisplayPixel(40, 20)), 'not shown yet');
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(4, Integer(FWorld.DisplayPixel(40, 20)));
  Assert.AreEqual(1, FWorld.Host.Steps, 'an update is a step of the program');
end;

procedure TTestKeenBufferedVideo.LAggiornamentoDovrebbeCopiareSoloLeTileSegnate;
begin
  // drawn with the plain video manager: no mark, so the update does not show it
  FWorld.Video.Bar(0, 0, 320, 200, 7);
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(0, Integer(FWorld.DisplayPixel(100, 100)));
  // a mark on one tile shows that tile only (16x16 pixels from 96, 96)
  Assert.IsTrue(FWorld.Buffered.MarkUpdateBlock(100, 100, 100, 100));
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(7, Integer(FWorld.DisplayPixel(96, 96)));
  Assert.AreEqual(7, Integer(FWorld.DisplayPixel(111, 111)));
  Assert.AreEqual(0, Integer(FWorld.DisplayPixel(112, 100)));
  Assert.AreEqual(0, Integer(FWorld.DisplayPixel(100, 95)));
  // the marks are cleared: another update copies nothing
  FWorld.Video.Bar(0, 0, 320, 200, 2);
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(7, Integer(FWorld.DisplayPixel(100, 100)));
end;

procedure TTestKeenBufferedVideo.IlSegnoDovrebbeTagliareIBlocchiFuoriDalloSchermo;
begin
  Assert.IsFalse(FWorld.Buffered.MarkUpdateBlock(336, 0, 340, 10), 'right of the port');
  Assert.IsFalse(FWorld.Buffered.MarkUpdateBlock(-40, 0, -20, 10), 'left of the port');
  Assert.IsFalse(FWorld.Buffered.MarkUpdateBlock(0, -40, 10, -20), 'above the port');
  Assert.IsFalse(FWorld.Buffered.MarkUpdateBlock(0, 400, 10, 410), 'below the port');
  Assert.IsTrue(FWorld.Buffered.MarkUpdateBlock(-8, -8, 400, 400), 'a block over the whole port is clipped to it');
  FWorld.Video.Bar(0, 0, 320, 200, 5);
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(5, Integer(FWorld.DisplayPixel(0, 0)));
  Assert.AreEqual(5, Integer(FWorld.DisplayPixel(319, 199)));
end;

procedure TTestKeenBufferedVideo.UnaStringaDovrebbeDisegnareIBitDelFontInXor;
var
  LRow: Integer;
  LBit: Integer;
  LBits: Byte;
  LExpected: Integer;
begin
  White;
  FWorld.Buffered.FontColor := KEEN_F_BLACK;
  FWorld.Buffered.Px := 64;
  FWorld.Buffered.Py := 40;
  FWorld.Buffered.DrawString('M');
  FWorld.Buffered.UpdateScreen;
  for LRow := 0 to UI_FONT_HEIGHT - 1 do
  begin
    LBits := TUiFakeGraphics.CharRow(Ord('M'), LRow);
    for LBit := 0 to 7 do
    begin
      // white XOR 15 is black where the font has a bit
      if (LBits and ($80 shr LBit)) <> 0 then
        LExpected := KEEN_BLACK
      else
        LExpected := KEEN_WHITE;
      Assert.AreEqual(LExpected, Integer(FWorld.DisplayPixel(64 + LBit, 40 + LRow)),
        Format('row %d bit %d', [LRow, LBit]));
    end;
  end;
end;

procedure TTestKeenBufferedVideo.UnaStringaDisegnataDueVolteDovrebbeSparire;
var
  LBefore: Cardinal;
begin
  White;
  LBefore := FWorld.ScreenHash;
  FWorld.Buffered.FontColor := KEEN_F_BLACK;
  FWorld.Buffered.Px := 30;
  FWorld.Buffered.Py := 50;
  FWorld.Buffered.DrawString('Keen Dreams');
  FWorld.Buffered.UpdateScreen;
  Assert.AreNotEqual(LBefore, FWorld.ScreenHash);
  FWorld.Buffered.Px := 30;
  FWorld.Buffered.Py := 50;
  FWorld.Buffered.DrawString('Keen Dreams');
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(LBefore, FWorld.ScreenHash);
end;

procedure TTestKeenBufferedVideo.IlColoreDelFontDovrebbeScegliereIPiani;
var
  LX: Integer;
  LFound: Boolean;
begin
  White;
  // F_SECONDCOLOR (3) changes the planes 0 and 1: white (15) becomes 12, the second color of the game
  FWorld.Buffered.FontColor := KEEN_F_SECONDCOLOR;
  FWorld.Buffered.Px := 80;
  FWorld.Buffered.Py := 60;
  FWorld.Buffered.DrawString('W');
  FWorld.Buffered.UpdateScreen;
  LFound := False;
  for LX := 80 to 87 do
    if FWorld.DisplayPixel(LX, 60) = KEEN_SECONDCOLOR then
      LFound := True
    else
      Assert.AreEqual(KEEN_WHITE, Integer(FWorld.DisplayPixel(LX, 60)));
  Assert.IsTrue(LFound);
end;

procedure TTestKeenBufferedVideo.UnaStringaDovrebbeSpostarePx;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  FWorld.Buffered.MeasureString('abc', LWidth, LHeight);
  FWorld.Buffered.Px := 16;
  FWorld.Buffered.Py := 8;
  FWorld.Buffered.DrawString('abc');
  Assert.AreEqual(16 + LWidth, FWorld.Buffered.Px);
  // at an x that is not a multiple of 8 the assembler adds the bits before the string too (defect of the original kept)
  FWorld.Buffered.Px := 19;
  FWorld.Buffered.DrawString('abc');
  Assert.AreEqual(19 + 3 + LWidth, FWorld.Buffered.Px);
end;

procedure TTestKeenBufferedVideo.UnaStringaAUnXDispariDovrebbeEssereSpostataDiBit;
var
  LRow: Integer;
  LBit: Integer;
  LBits: Byte;
  LExpected: Integer;
begin
  White;
  FWorld.Buffered.FontColor := KEEN_F_BLACK;
  FWorld.Buffered.Px := 67;
  FWorld.Buffered.Py := 20;
  FWorld.Buffered.DrawString('M');
  FWorld.Buffered.UpdateScreen;
  for LRow := 0 to UI_FONT_HEIGHT - 1 do
  begin
    LBits := TUiFakeGraphics.CharRow(Ord('M'), LRow);
    for LBit := 0 to 7 do
    begin
      if (LBits and ($80 shr LBit)) <> 0 then
        LExpected := KEEN_BLACK
      else
        LExpected := KEEN_WHITE;
      Assert.AreEqual(LExpected, Integer(FWorld.DisplayPixel(67 + LBit, 20 + LRow)), Format('row %d bit %d', [LRow, LBit]));
    end;
  end;
end;

procedure TTestKeenBufferedVideo.UnaStringaTroppoLargaDovrebbeDareEccezione;
var
  LText: AnsiString;
begin
  // the buffer of the assembler is 50 bytes wide: the C writes after it, here it is an error
  LText := StringOfChar(AnsiChar('W'), 120);
  FWorld.Buffered.Px := 0;
  FWorld.Buffered.Py := 0;
  Assert.WillRaise(procedure begin FWorld.Buffered.DrawString(LText); end, EKeenException);
end;

procedure TTestKeenBufferedVideo.LaMisuraDovrebbeEssereQuellaDelFont;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  FWorld.Buffered.MeasureString('', LWidth, LHeight);
  Assert.AreEqual(0, LWidth);
  Assert.AreEqual(UI_FONT_HEIGHT, LHeight);
  FWorld.Buffered.MeasureString('ab', LWidth, LHeight);
  Assert.AreEqual(TUiFakeGraphics.CharWidth(Ord('a')) + TUiFakeGraphics.CharWidth(Ord('b')), LWidth);
end;

procedure TTestKeenBufferedVideo.IlCursoreDovrebbeVedersiSoloSullaPaginaMostrata;
var
  LBare: Cardinal;
  LWith: Cardinal;
  LX: Integer;
  LY: Integer;
  LClean: Boolean;
begin
  White;
  LBare := FWorld.ScreenHash;
  FWorld.Buffered.SetCursor(KEEN_STARTSPRITES);
  FWorld.Buffered.MoveCursor(100, 80);
  FWorld.Buffered.ShowCursor;
  FWorld.Buffered.UpdateScreen;
  LWith := FWorld.ScreenHash;
  Assert.AreNotEqual(LBare, LWith, 'the cursor is on the screen');
  // the buffer page was put back as it was
  LClean := True;
  for LY := 76 to 96 do
    for LX := 96 to 128 do
      if FWorld.BufferPixel(LX, LY) <> KEEN_WHITE then
        LClean := False;
  Assert.IsTrue(LClean, 'the cursor is not left on the buffer page');
  // moved: the old place is clean again
  FWorld.Buffered.MoveCursor(200, 120);
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.DisplayPixel(100, 80)));
  FWorld.Buffered.HideCursor;
  FWorld.Buffered.UpdateScreen;
  Assert.AreEqual(LBare, FWorld.ScreenHash);
end;

procedure TTestKeenBufferedVideo.IlCursoreSenzaSpriteDovrebbeDareEccezione;
begin
  FWorld.Buffered.ShowCursor;
  Assert.WillRaise(procedure begin FWorld.Buffered.UpdateScreen; end, EKeenException);
end;

procedure TTestKeenBufferedVideo.LAttesaDovrebbeDurareITicChiesti;
var
  LStart: Integer;
begin
  LStart := FWorld.Clock.TimeCount;
  FWorld.Buffered.WaitVBL(14);
  Assert.AreEqual(LStart + 14, FWorld.Clock.TimeCount);
  FWorld.Buffered.WaitVBL(0);
  Assert.AreEqual(LStart + 14, FWorld.Clock.TimeCount);
end;

procedure TTestKeenBufferedVideo.IlRipristinoDelBufferDovrebbeCopiareLaPaginaMostrata;
begin
  White;
  // something only on the buffer page
  FWorld.Video.Bar(0, 0, 320, 200, 3);
  Assert.AreEqual(3, Integer(FWorld.BufferPixel(50, 50)));
  FWorld.Buffered.FixRefreshBuffer;
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.BufferPixel(50, 50)));
  Assert.AreEqual(KEEN_WHITE, Integer(FWorld.BufferPixel(319, 199)));
end;

procedure TTestKeenBufferedVideo.LeImmaginiELeTileDovrebberoSegnareIlLoroRettangolo;
var
  LBlank: Cardinal;
  LAfterPicture: Cardinal;
begin
  LBlank := FWorld.ScreenHash;
  FWorld.Buffered.DrawPic(40, 32, KEEN_STARTPICS + 3);
  FWorld.Buffered.UpdateScreen;
  LAfterPicture := FWorld.ScreenHash;
  Assert.AreNotEqual(LBlank, LAfterPicture);
  FWorld.Buffered.DrawTile8(160, 100, 5);
  FWorld.Buffered.DrawTile8Masked(168, 100, 2);
  FWorld.Buffered.DrawMaskedPic(200, 48, KEEN_STARTPICM);
  FWorld.Buffered.DrawSprite(240, 150, KEEN_STARTSPRITES + 1);
  FWorld.Buffered.Plot(10, 190, 9);
  FWorld.Buffered.Hlin(20, 60, 190, 10);
  FWorld.Buffered.Vlin(150, 190, 300, 11);
  FWorld.Buffered.UpdateScreen;
  Assert.AreNotEqual(LAfterPicture, FWorld.ScreenHash);
  Assert.AreEqual(9, Integer(FWorld.DisplayPixel(10, 190)));
  Assert.AreEqual(10, Integer(FWorld.DisplayPixel(40, 190)));
  Assert.AreEqual(11, Integer(FWorld.DisplayPixel(300, 170)));
  Assert.WillRaise(procedure begin FWorld.Buffered.DrawPic(0, 0, KEEN_STARTPICS + 900); end, EKeenDataException);
  Assert.WillRaise(procedure begin FWorld.Buffered.DrawMaskedPic(0, 0, KEEN_STARTPICM + 9); end, EKeenDataException);
end;

procedure TTestKeenBufferedVideo.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure begin TKeenBufferedVideo.Create(nil, FWorld.Blocks, FWorld.Graphics, FWorld.Sprites, FWorld.Clock); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenBufferedVideo.Create(FWorld.Video, nil, FWorld.Graphics, FWorld.Sprites, FWorld.Clock); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenBufferedVideo.Create(FWorld.Video, FWorld.Blocks, nil, FWorld.Sprites, FWorld.Clock); end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure begin TKeenBufferedVideo.Create(FWorld.Video, FWorld.Blocks, FWorld.Graphics, FWorld.Sprites, nil); end,
    EArgumentNilException);
end;

end.
