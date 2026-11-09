{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixSmallFontPart                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.SmallFontPart;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Context, DelphiDoom.Radix.SmallFontPart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixSmallFontPart = class(TObject)
  strict private
    FWad: IGameWadComposer;
    procedure Run(ALength: Integer);
    function ReadWord(const ABytes: TBytes; AOffset: Integer): Integer;
  public
    [Test]
    procedure DovrebbeScrivereLaStrisciaIntera;
    [Test]
    procedure DovrebbeScrivereUnaLetteraPerOgniCarattereDaTrentatreACentoventotto;
    [Test]
    procedure DovrebbeSaltareICaratteriCheNonHannoUnaLettera;
    [Test]
    procedure DovrebbeFareVuotaUnaLetteraCheLaStrisciaNonHa;
    [Test]
    procedure DovrebbeFareLeLettereDi5x6;
    [Test]
    procedure DovrebbeNonFareNullaSeLaStrisciaHaUnaLunghezzaDiversa;
    [Test]
    procedure DovrebbePrendereLaLetteraGiustaDallaStriscia;
  end;

implementation

{ TTestRadixSmallFontPart }

procedure TTestRadixSmallFontPart.Run(ALength: Integer);
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('SmallFont', TRadixDatBuilder.Pattern(ALength, 5));
    FWad := TRadixPartRunner.Run(TRadixSmallFontPart.Create, LBuilder.ToBytes, nil, LAliases);
  finally
    LBuilder.Free;
  end;
end;

function TTestRadixSmallFontPart.ReadWord(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := PSmallInt(@ABytes[AOffset])^;
end;

procedure TTestRadixSmallFontPart.DovrebbeScrivereLaStrisciaIntera;
var
  LStrip: TBytes;
begin
  Run(2222);
  LStrip := FWad.LumpData[FWad.IndexOf('SMALLFNT')];
  Assert.AreEqual(368, ReadWord(LStrip, 0));
  Assert.AreEqual(6, ReadWord(LStrip, 2));
  Assert.AreEqual(0, ReadWord(LStrip, 4));
  Assert.AreEqual(0, ReadWord(LStrip, 6));
end;

procedure TTestRadixSmallFontPart.DovrebbeScrivereUnaLetteraPerOgniCarattereDaTrentatreACentoventotto;
begin
  Run(2222);
  Assert.IsTrue(FWad.IndexOf('FNTA033') >= 0);
  Assert.IsTrue(FWad.IndexOf('FNTA065') >= 0);
  Assert.IsTrue(FWad.IndexOf('FNTA128') >= 0);
  Assert.AreEqual(-1, FWad.IndexOf('FNTA032'));
  Assert.AreEqual(-1, FWad.IndexOf('FNTA129'));
end;

procedure TTestRadixSmallFontPart.DovrebbeSaltareICaratteriCheNonHannoUnaLettera;
var
  LCode: Integer;
begin
  Run(2222);
  for LCode in [Ord('%'), Ord('('), Ord(')'), Ord('*'), Ord('+'), Ord('#'), Ord('/'),
    Ord('<'), Ord('='), Ord('>')] do
    Assert.AreEqual(-1, FWad.IndexOf('FNTA' + Format('%.3d', [LCode])));
end;

procedure TTestRadixSmallFontPart.DovrebbeFareVuotaUnaLetteraCheLaStrisciaNonHa;
begin
  Run(2222);
  // the dollar is not in the strip: a glyph of holes, which has no post
  Assert.AreEqual(8 + 5 * 4 + 5 * 2, Length(FWad.LumpData[FWad.IndexOf('FNTA036')]));
end;

procedure TTestRadixSmallFontPart.DovrebbeFareLeLettereDi5x6;
var
  LGlyph: TBytes;
begin
  Run(2222);
  LGlyph := FWad.LumpData[FWad.IndexOf('FNTA065')];
  Assert.AreEqual(5, ReadWord(LGlyph, 0));
  Assert.AreEqual(6, ReadWord(LGlyph, 2));
end;

procedure TTestRadixSmallFontPart.DovrebbeNonFareNullaSeLaStrisciaHaUnaLunghezzaDiversa;
begin
  Run(2221);
  Assert.AreEqual(0, FWad.Count);
end;

procedure TTestRadixSmallFontPart.DovrebbePrendereLaLetteraGiustaDallaStriscia;
var
  LGlyphB: TBytes;
  LColumnOffset: Integer;
begin
  Run(2222);
  // B is the second letter of the strip: its first column is the column 5 of the strip.
  // The patch has a post for the pixels that are not holes: the first post of the first
  // column starts after the table of the offsets
  LGlyphB := FWad.LumpData[FWad.IndexOf('FNTA066')];
  LColumnOffset := PInteger(@LGlyphB[8])^;
  Assert.AreEqual(8 + 5 * 4, LColumnOffset);
end;

end.
