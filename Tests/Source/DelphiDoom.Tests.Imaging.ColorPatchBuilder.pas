{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingColorPatchBuilder (issue #242)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ColorPatchBuilder;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.PatchWriter,
  DelphiDoom.Imaging.ColorPatchBuilder;

type
  /// <summary>
  ///   The old W_TextureAsPatch of w_sprite.pas is copied in this unit (with a picture in place of the texture
  ///   and a byte array in place of the zone): the new builder must write the same bytes. The cases that the
  ///   golden corpus never meets (posts of more than 128 pixels, columns taller than 254) are built here
  /// </summary>
  [TestFixture]
  [Category('imaging')]
  TTestImagingColorPatchBuilder = class(TObject)
  strict private
    FBuilder: IImagingColorPatchBuilder;
    FPalette: TImagingPixels;
    function Picture(AWidth, AHeight: Integer; ASeed: Cardinal; ATransparentOneIn: Integer): TImagingPixels;
    procedure CompareWithOld(const AColors: TImagingPixels; AWidth, AHeight: Integer);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioPerUnaPatchBassa;
    [Test]
    procedure DovrebbeSpezzareIPostA128ComeIlVecchio;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioConAltezza254;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioConAltezza255;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioConAltezza256;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioConAltezza600;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioConColonneAltissime;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioConBuchiLunghi;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioSuImmaginiCasuali;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioSeLUltimaRigaEOpaca;
    [Test]
    procedure DovrebbeScrivereLeStesseColonneDelVecchioSenzaPixelOpachi;
    [Test]
    procedure DovrebbeScrivereSoloLIntestazioneConImmagineVuota;
    [Test]
    procedure DovrebbeTrattareComeTrasparenteIlNeroConQualsiasiAlfa;
    [Test]
    procedure DovrebbeConservareLIndiceZeroComePixelOpaco;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteCorta;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineConMenoColoriDelleDimensioni;
  end;

implementation

type
  /// <summary>V_FindAproxColorIndex of v_video.pas on a table of 256 colors, the same for the old text and the new</summary>
  TNearestFake = class(TInterfacedObject, IImagingColorIndex)
  public
    function Nearest(const APalette: TImagingPixels; AColor: Cardinal; ALow, AHigh: Integer): Integer;
  end;

  column_t = packed record
    topdelta: byte;
    length: byte;
  end;

  patchheader_t = packed record
    width: smallint;
    height: smallint;
    leftoffset: smallint;
    topoffset: smallint;
  end;

  /// <summary>TDByteList of the old text, with only what it used</summary>
  TOldByteList = class
  public
    Count: Integer;
    List: TBytes;
    constructor Create;
    procedure Add(const AValue: Byte);
    procedure FastClear;
  end;

function OldFindAproxColorIndex(const pal: TImagingPixels; const c: LongWord;
  const start: integer = 0; const finish: integer = 255): integer;
var
  r, g, b: integer;
  rc, gc, bc: integer;
  dr, dg, db: integer;
  i: integer;
  cc: LongWord;
  dist: LongWord;
  mindist: LongWord;
begin
  r := c and $FF;
  g := (c shr 8) and $FF;
  b := (c shr 16) and $FF;
  result := start;
  mindist := LongWord($ffffffff);
  for i := start to finish do
  begin
    cc := pal[i];
    rc := cc and $FF;
    gc := (cc shr 8) and $FF;
    bc := (cc shr 16) and $FF;
    dr := r - rc;
    dg := g - gc;
    db := b - bc;
    dist := dr * dr + dg * dg + db * db;
    if dist < mindist then
    begin
      result := i;
      if dist = 0 then
        exit
      else
        mindist := dist;
    end;
  end;
end;

{ TNearestFake }

function TNearestFake.Nearest(const APalette: TImagingPixels; AColor: Cardinal; ALow,
  AHigh: Integer): Integer;
begin
  Result := OldFindAproxColorIndex(APalette, AColor, ALow, AHigh);
end;

{ TOldByteList }

constructor TOldByteList.Create;
begin
  inherited Create;
  SetLength(List, 1024);
end;

procedure TOldByteList.Add(const AValue: Byte);
begin
  if Count >= Length(List) then
    SetLength(List, Length(List) * 2);
  List[Count] := AValue;
  Inc(Count);
end;

procedure TOldByteList.FastClear;
begin
  Count := 0;
end;

// W_TextureAsPatch of w_sprite.pas before issue #242, as it was: the texture is the picture colors (rows of w), the
// default palette is pal, Z_Malloc gives a byte array and V_FindAproxColorIndex is the copy above.
// The variable y of the for is read after the loop by flashcolumndata, as the original does.
function OldTextureAsPatch(const colors: TImagingPixels; w, h: Integer; const pal: TImagingPixels): TBytes;
var
  m, fs: TMemoryStream;
  patch: patchheader_t;
  column: column_t;
  columnofs: TList;
  columndata: TOldByteList;
  x, y: integer;
  c: LongWord;
  i: integer;
  col: array of LongWord;
  lastdelta: integer;

  procedure flashcolumnend;
  begin
    column.topdelta := 255;
    column.length := 0;
    m.Write(column, SizeOf(column_t));
  end;

  procedure flashcolumndata;
  var
    bb: byte;
    realdelta: integer;
    restdelta: integer;
  begin
    if columndata.Count > 0 then
    begin
      realdelta := y - columndata.Count;
      if realdelta >= 254 then
      begin
        if lastdelta < 254 then
        begin
          restdelta := realdelta - 254;
          column.topdelta := 254;
          column.length := 0;
          m.Write(column, SizeOf(column_t));
          bb := 0;
          m.Write(bb, SizeOf(bb));
          m.Write(bb, SizeOf(bb));
        end
        else
          restdelta := realdelta - lastdelta;
        while restdelta >= 255 do
        begin
          restdelta := restdelta - 254;
          column.topdelta := 254;
          column.length := 0;
          m.Write(column, SizeOf(column_t));
          bb := 0;
          m.Write(bb, SizeOf(bb));
          m.Write(bb, SizeOf(bb));
        end;
        column.topdelta := restdelta;
      end
      else
        column.topdelta := y - columndata.Count;
      lastdelta := realdelta;
      column.length := columndata.Count;
      m.Write(column, SizeOf(column_t));
      bb := 0;
      m.Write(bb, SizeOf(bb));
      m.Write(columndata.List[0], columndata.Count);
      m.Write(bb, SizeOf(bb));
      columndata.FastClear;
    end;
  end;

begin
  m := TMemoryStream.Create;
  fs := TMemoryStream.Create;
  columnofs := TList.Create;
  columndata := TOldByteList.Create;
  try
    patch.width := w;
    patch.height := h;
    patch.leftoffset := 7;
    patch.topoffset := 9;
    fs.Write(patch, SizeOf(patchheader_t));

    SetLength(col, h);
    for x := 0 to w - 1 do
    begin
      columnofs.Add(Pointer(m.Position + SizeOf(patchheader_t) + w * SizeOf(integer)));
      columndata.FastClear;
      for y := 0 to h - 1 do
        col[y] := colors[y * w + x];
      lastdelta := -1;
      for y := 0 to h - 1 do
      begin
        c := col[y];
        if c and $FFFFFF = 0 then
        begin
          flashcolumndata;
          continue;
        end;
        if columndata.Count = 128 then
          flashcolumndata;
        columndata.Add(OldFindAproxColorIndex(pal, c))
      end;
      flashcolumndata;
      flashcolumnend;
    end;

    for i := 0 to columnofs.Count - 1 do
    begin
      x := Integer(columnofs[i]);
      fs.Write(x, SizeOf(integer));
    end;

    SetLength(Result, fs.Size + m.Size);
    Move(fs.Memory^, Result[0], fs.Size);
    if m.Size > 0 then
      Move(m.Memory^, Result[fs.Size], m.Size);
  finally
    m.Free;
    columnofs.Free;
    columndata.Free;
    fs.Free;
  end;
end;

{ TTestImagingColorPatchBuilder }

procedure TTestImagingColorPatchBuilder.Setup;
var
  LIndex: Integer;
begin
  FBuilder := TImagingColorPatchBuilder.Create(TImagingPatchWriter.Create, TNearestFake.Create);
  SetLength(FPalette, 256);
  for LIndex := 0 to 255 do
    FPalette[LIndex] := Cardinal((LIndex * 37 and $FF) or ((LIndex * 91 and $FF) shl 8) or
      ((LIndex * 13 and $FF) shl 16));
end;

function TTestImagingColorPatchBuilder.Picture(AWidth, AHeight: Integer; ASeed: Cardinal;
  ATransparentOneIn: Integer): TImagingPixels;
var
  LIndex: Integer;
  LSeed: Cardinal;
begin
  SetLength(Result, AWidth * AHeight);
  LSeed := ASeed;
  for LIndex := 0 to High(Result) do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    if (ATransparentOneIn > 0) and ((LSeed shr 16) mod Cardinal(ATransparentOneIn) = 0) then
      Result[LIndex] := $FF000000
    else
      Result[LIndex] := (LSeed shr 8) or $FF000000;
  end;
end;

procedure TTestImagingColorPatchBuilder.CompareWithOld(const AColors: TImagingPixels; AWidth,
  AHeight: Integer);
var
  LOld: TBytes;
  LNew: TBytes;
begin
  LOld := OldTextureAsPatch(AColors, AWidth, AHeight, FPalette);
  LNew := FBuilder.Build(AColors, AWidth, AHeight, 7, 9, FPalette, IMAGING_SPRITE_POST_LENGTH);
  Assert.AreEqual<Integer>(Length(LOld), Length(LNew), 'length');
  Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], Length(LOld)), 'bytes');
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioPerUnaPatchBassa;
begin
  CompareWithOld(Picture(24, 40, 1, 4), 24, 40);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeSpezzareIPostA128ComeIlVecchio;
begin
  // all opaque: 200 rows give a post of 128 and one of 72
  CompareWithOld(Picture(3, 200, 2, 0), 3, 200);
  CompareWithOld(Picture(3, 128, 2, 0), 3, 128);
  CompareWithOld(Picture(3, 129, 2, 0), 3, 129);
  CompareWithOld(Picture(3, 256, 2, 0), 3, 256);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioConAltezza254;
begin
  CompareWithOld(Picture(6, 254, 3, 5), 6, 254);
  CompareWithOld(Picture(6, 254, 4, 0), 6, 254);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioConAltezza255;
begin
  CompareWithOld(Picture(6, 255, 5, 5), 6, 255);
  CompareWithOld(Picture(6, 255, 6, 0), 6, 255);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioConAltezza256;
begin
  CompareWithOld(Picture(6, 256, 7, 5), 6, 256);
  CompareWithOld(Picture(6, 256, 8, 0), 6, 256);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioConAltezza600;
begin
  CompareWithOld(Picture(8, 600, 9, 7), 8, 600);
  CompareWithOld(Picture(8, 600, 10, 40), 8, 600);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioConColonneAltissime;
begin
  CompareWithOld(Picture(2, 1500, 11, 0), 2, 1500);
  CompareWithOld(Picture(2, 1500, 12, 300), 2, 1500);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioConBuchiLunghi;
var
  LColors: TImagingPixels;
  LRow: Integer;
  LColumn: Integer;
begin
  LColors := Picture(5, 700, 13, 0);
  // a few opaque rows, then 400 transparent ones, then opaque again: the gap is longer than 254
  for LColumn := 0 to 4 do
    for LRow := 10 + LColumn to 409 do
      LColors[LRow * 5 + LColumn] := 0;
  CompareWithOld(LColors, 5, 700);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioSuImmaginiCasuali;
var
  LCase: Integer;
  LWidth: Integer;
  LHeight: Integer;
begin
  for LCase := 0 to 59 do
  begin
    LWidth := 1 + (LCase * 7) mod 9;
    LHeight := 1 + (LCase * 53) mod 700;
    CompareWithOld(Picture(LWidth, LHeight, Cardinal(100 + LCase), (LCase mod 6) * 3), LWidth, LHeight);
  end;
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioSeLUltimaRigaEOpaca;
var
  LColors: TImagingPixels;
  LColumn: Integer;
begin
  LColors := Picture(4, 300, 14, 3);
  for LColumn := 0 to 3 do
    LColors[299 * 4 + LColumn] := $FF336699;
  CompareWithOld(LColors, 4, 300);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereLeStesseColonneDelVecchioSenzaPixelOpachi;
var
  LColors: TImagingPixels;
begin
  SetLength(LColors, 5 * 300);
  CompareWithOld(LColors, 5, 300);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeScrivereSoloLIntestazioneConImmagineVuota;
var
  LColors: TImagingPixels;
  LBytes: TBytes;
begin
  SetLength(LColors, 0);
  LBytes := FBuilder.Build(LColors, 0, 0, 0, 0, FPalette, IMAGING_SPRITE_POST_LENGTH);
  Assert.AreEqual<Integer>(8, Length(LBytes));
end;

procedure TTestImagingColorPatchBuilder.DovrebbeTrattareComeTrasparenteIlNeroConQualsiasiAlfa;
var
  LColors: TImagingPixels;
begin
  SetLength(LColors, 3);
  LColors[0] := $FF000000;
  LColors[1] := $00000000;
  LColors[2] := $80000000;
  CompareWithOld(LColors, 1, 3);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeConservareLIndiceZeroComePixelOpaco;
var
  LColors: TImagingPixels;
  LBytes: TBytes;
begin
  SetLength(LColors, 1);
  LColors[0] := FPalette[0];
  if LColors[0] and $FFFFFF = 0 then
    LColors[0] := $FF010101;
  LBytes := FBuilder.Build(LColors, 1, 1, 0, 0, FPalette, IMAGING_SPRITE_POST_LENGTH);
  // header 8, one offset 4, then one post of one pixel (5 bytes) and the end of the column
  Assert.AreEqual<Integer>(8 + 4 + 5 + 2, Length(LBytes));
end;

procedure TTestImagingColorPatchBuilder.DovrebbeRifiutareUnaPaletteCorta;
var
  LShort: TImagingPixels;
begin
  SetLength(LShort, 10);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(Picture(2, 2, 1, 0), 2, 2, 0, 0, LShort, IMAGING_SPRITE_POST_LENGTH);
    end, EImagingException);
end;

procedure TTestImagingColorPatchBuilder.DovrebbeRifiutareUnaImmagineConMenoColoriDelleDimensioni;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(Picture(2, 2, 1, 0), 3, 3, 0, 0, FPalette, IMAGING_SPRITE_POST_LENGTH);
    end, EImagingException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestImagingColorPatchBuilder);

end.
