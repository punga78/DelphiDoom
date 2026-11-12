{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the proportional font           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Font;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Font;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenFont = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereAltezzaELarghezze;
    [Test]
    procedure DovrebbeDareIByteDiUnaRigaDelCarattere;
    [Test]
    procedure DovrebbeDareZeroFuoriDaiDati;
    [Test]
    procedure DovrebbeMisurareUnaStringa;
    [Test]
    procedure DovrebbeRifiutareUnChunkTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnAltezzaImpossibile;
    [Test]
    procedure IlFontDelloSharewareDovrebbeAvereLeCifreDiLarghezzaFissa;
  end;

implementation

uses
  DelphiDoom.Keen.Intf, DelphiDoom.Keen.Factory, DelphiDoom.Tests.Keen.UiWorld, DelphiDoom.Tests.Keen.RealData,
  DelphiDoom.Tests.Shared.Skip;

{ TTestKeenFont }

procedure TTestKeenFont.DovrebbeLeggereAltezzaELarghezze;
var
  LFont: TKeenFont;
begin
  LFont := TKeenFont.Create(TUiFakeGraphics.FontChunk);
  try
    Assert.AreEqual(UI_FONT_HEIGHT, LFont.Height);
    Assert.AreEqual(TUiFakeGraphics.CharWidth(65), LFont.CharWidth(65));
    Assert.AreEqual(6, LFont.CharWidth(129));
    Assert.AreEqual(770, KEEN_FONT_HEADER_BYTES, 'sizeof(fontstruct)');
  finally
    LFont.Free;
  end;
end;

procedure TTestKeenFont.DovrebbeDareIByteDiUnaRigaDelCarattere;
var
  LFont: TKeenFont;
  LRow: Integer;
begin
  LFont := TKeenFont.Create(TUiFakeGraphics.FontChunk);
  try
    for LRow := 0 to UI_FONT_HEIGHT - 1 do
      Assert.AreEqual(TUiFakeGraphics.CharRow(77, LRow), LFont.RowByte(77, LRow, 0));
  finally
    LFont.Free;
  end;
end;

procedure TTestKeenFont.DovrebbeDareZeroFuoriDaiDati;
var
  LFont: TKeenFont;
  LChunk: TBytes;
begin
  // the character 255 points past the end of the chunk
  LChunk := TUiFakeGraphics.FontChunk;
  LChunk[2 + 255 * 2] := $FF;
  LChunk[3 + 255 * 2] := $FF;
  LFont := TKeenFont.Create(LChunk);
  try
    Assert.AreEqual(0, Integer(LFont.RowByte(255, 3, 0)));
  finally
    LFont.Free;
  end;
end;

procedure TTestKeenFont.DovrebbeMisurareUnaStringa;
var
  LFont: TKeenFont;
begin
  LFont := TKeenFont.Create(TUiFakeGraphics.FontChunk);
  try
    Assert.AreEqual(0, LFont.Measure(''));
    Assert.AreEqual(TUiFakeGraphics.CharWidth(Ord('a')) + TUiFakeGraphics.CharWidth(Ord('b')) +
      TUiFakeGraphics.CharWidth(Ord(' ')), LFont.Measure('ab '));
  finally
    LFont.Free;
  end;
end;

procedure TTestKeenFont.DovrebbeRifiutareUnChunkTroppoCorto;
begin
  Assert.WillRaise(procedure begin TKeenFont.Create(TBytes.Create(10, 0, 1, 2)).Free; end, EKeenDataException);
  Assert.WillRaise(procedure begin TKeenFont.Create(nil).Free; end, EKeenDataException);
end;

procedure TTestKeenFont.DovrebbeRifiutareUnAltezzaImpossibile;
var
  LChunk: TBytes;
begin
  LChunk := TUiFakeGraphics.FontChunk;
  LChunk[0] := 33;
  Assert.WillRaise(procedure begin TKeenFont.Create(LChunk).Free; end, EKeenDataException);
  LChunk[0] := $FF;
  LChunk[1] := $FF;
  Assert.WillRaise(procedure begin TKeenFont.Create(LChunk).Free; end, EKeenDataException);
end;

procedure TTestKeenFont.IlFontDelloSharewareDovrebbeAvereLeCifreDiLarghezzaFissa;
var
  LFiles: IKeenDataFiles;
  LData: IKeenGameData;
  LFont: TKeenFont;
  LDigit: Integer;
begin
  LFiles := TKeenRealData.OpenFiles;
  if not Assigned(LFiles) then
    TTestSkip.Ignore('i file dello shareware di Keen Dreams non sono su questa macchina');
  LData := TKeenFactory.OpenGameData(LFiles);
  LFont := TKeenFont.Create(LData.Graphics.Chunks.Read(KEEN_STARTFONT));
  try
    Assert.IsTrue((LFont.Height >= 6) and (LFont.Height <= 16), 'height ' + IntToStr(LFont.Height));
    // the scores are printed with the characters 129..138: the digits, all of the same width
    for LDigit := 130 to 138 do
      Assert.AreEqual(LFont.CharWidth(129), LFont.CharWidth(LDigit));
    Assert.IsTrue(LFont.Measure('Commander Keen') > 40);
  finally
    LFont.Free;
  end;
end;

end.
