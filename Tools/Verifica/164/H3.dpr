program H3;
// Harness of the golden file of the text art and of the Lanczos resampler (Tests\Data\Endoom\textart.golden.txt):
// the OLD ENDEDIT code (ee_textart with Graphics32, compiled with -DVER340) on the pictures of
// DelphiDoom.Tests.Imaging.ResampleCases. It also writes the 160x50 picture of each case (BitmapLanczosDraw,
// copied from ee_textart) to a binary file, to measure the difference of the new resampler.
{$APPTYPE CONSOLE}
uses
  Windows, SysUtils, Classes, Graphics,
  GR32, GR32_Resamplers,
  ee_screen, ee_textart, ee_utils,
  DelphiDoom.Endoom.Types,
  DelphiDoom.Tests.Endoom.Digest,
  DelphiDoom.Tests.Endoom.EditorScenarios,
  DelphiDoom.Tests.Imaging.ResampleCases;

var
  Out_: TStringList;
  OutDir: string;

procedure Line(const s: string);
begin
  Out_.Add(s);
end;

// FlipBitmapVertical and BitmapLanczosDraw of ee_textart.pas, as they are
procedure FlipBitmapVertical(const b: TBitmap);
var
  i, j: integer;
  tmp: LongWord;
  l1, l2: PLongWordArray;
begin
  b.PixelFormat := pf32bit;

  for j := 0 to b.Height div 2 - 1 do
  begin
    l1 := b.ScanLine[j];
    l2 := b.ScanLine[b.Height - 1 - j];
    for i := 0 to b.Width - 1 do
    begin
      tmp := l1[i];
      l1[i] := l2[i];
      l2[i] := tmp;
    end;
  end;
end;

procedure BitmapLanczosDraw(const bm: TBitmap; const destbm: TBitmap);
var
  R: TKernelResampler;
  Src, Dst: TBitmap32;
  bmp: TBitmap;
  bi: TBitmapInfo;
  abitmap: HBitmap;
begin
  Src := TBitmap32.Create;
  Src.Assign(bm);
  Dst := TBitmap32.Create;
  Dst.Assign(destbm);

  R := TKernelResampler.Create(Src);
  R.Kernel := TLanczosKernel.Create;
  Dst.Draw(Dst.BoundsRect, Src.BoundsRect, Src);

  FillChar(bi, SizeOf(bi), 0);
  with bi.bmiHeader do
  begin
     biSize := SizeOf(bi.bmiHeader);
     biWidth := Dst.Width;
     biHeight := Dst.height;
     biPlanes := 1;
     biBitCount := 32;
     biCompression := BI_RGB;
  end;

  bmp := TBitmap.Create;

  aBitmap := 0;
  try
    aBitmap := CreateDIBitmap(GetDC(0), bi.bmiHeader, CBM_INIT,  @Dst.Bits[0], bi, DIB_RGB_COLORS);
    bmp.handle := aBitmap;
    destbm.Assign(bmp);
    destbm.PixelFormat := pf32bit;
  finally
    DeleteObject(aBitmap);
    bmp.Free;
  end;

  FlipBitmapVertical(destbm);
  Src.Free;
  Dst.Free;
end;

function MakeBitmap(const px: TArray<Cardinal>; w, h: Integer): TBitmap;
var
  y, x: Integer;
  ln: PLongWordArray;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf32bit;
  Result.Width := w;
  Result.Height := h;
  for y := 0 to h - 1 do
  begin
    ln := Result.ScanLine[y];
    for x := 0 to w - 1 do
      ln[x] := px[y * w + x] and $FFFFFF;
  end;
end;

function Bytes(const scr: TEndScreen): TBytes;
var
  m: TMemoryStream;
begin
  m := TMemoryStream.Create;
  try
    scr.SaveToStream(m);
    SetLength(Result, m.Size);
    m.Position := 0;
    if m.Size > 0 then
      m.Read(Result[0], m.Size);
  finally
    m.Free;
  end;
end;

procedure ApplyOps(const scr: TEndScreen; const ops: TArray<TEditorModelOp>);
var
  i: Integer;
begin
  for i := 0 to High(ops) do
    case ops[i].Kind of
      EDITOR_OP_CHARACTER: scr.Character[ops[i].X, ops[i].Y] := Chr(ops[i].Value);
      EDITOR_OP_FOREGROUND: scr.ForegroundColor[ops[i].X, ops[i].Y] := ops[i].Color;
      EDITOR_OP_BACKGROUND: scr.BackgroundColor[ops[i].X, ops[i].Y] := ops[i].Color;
      EDITOR_OP_BLINK: scr.Blink[ops[i].X, ops[i].Y] := Odd(ops[i].Value);
      EDITOR_OP_CLEAR: scr.Clear;
    end;
end;

procedure Run;
var
  c, m, y, x, w, h: Integer;
  px, out160: TArray<Cardinal>;
  bm, dst: TBitmap;
  scr: TEndScreen;
  ln: PLongWordArray;
  fs: TFileStream;
begin
  for c := 0 to TResampleCases.Count - 1 do
  begin
    px := TResampleCases.Build(c, w, h);
    bm := MakeBitmap(px, w, h);
    // the 160x50 picture
    dst := TBitmap.Create;
    dst.Width := 160;
    dst.Height := 50;
    dst.PixelFormat := pf32bit;
    BitmapLanczosDraw(bm, dst);
    SetLength(out160, 160 * 50);
    for y := 0 to 49 do
    begin
      ln := dst.ScanLine[y];
      for x := 0 to 159 do
        out160[y * 160 + x] := dst.Canvas.Pixels[x, y]; // TColor, as ee_textart reads it
    end;
    // TColor is $00BBGGRR: swap to $00RRGGBB, the order of the new code
    for x := 0 to High(out160) do
      out160[x] := TEditorScenarios.ToRgb(out160[x] and $FFFFFF);
    Line(Format('RESAMPLE %s %s', [TResampleCases.Name(c), TEndoomDigest.OfCardinals(out160)]));
    fs := TFileStream.Create(OutDir + 'resample_' + TResampleCases.Name(c) + '.bin', fmCreate);
    fs.Write(out160[0], Length(out160) * 4);
    fs.Free;
    dst.Free;
    // the text screen
    for m := 0 to Ord(NUMTEXTARTMETHOD) - 1 do
    begin
      scr := TEndScreen.Create;
      ApplyOps(scr, TEditorScenarios.ModelOps(555, 700));
      BitmapToScreen(bm, scr, textartmethod_t(m));
      Line(Format('TEXTART %s %d %s', [TResampleCases.Name(c), m, TEndoomDigest.OfBytes(Bytes(scr))]));
      scr.Free;
    end;
    bm.Free;
  end;
end;

begin
  Out_ := TStringList.Create;
  OutDir := ExtractFilePath(ParamStr(1));
  Run;
  Out_.SaveToFile(ParamStr(1));
  Out_.Free;
end.
