program H2;
// Harness of the golden file of the editor model (Tests\Data\Endoom\editor.golden.txt): it runs the OLD
// ENDEDIT code (ee_screen with the tools and the paste of main.pas, copied in H2Old) on the cases of
// DelphiDoom.Tests.Endoom.EditorScenarios. Search path: Libs\Endoom and Tests\Source of the repository.
{$APPTYPE CONSOLE}
uses
  Windows, SysUtils, Classes, Graphics,
  ee_screen, ee_utils, H2Old,
  DelphiDoom.Endoom.Types,
  DelphiDoom.Tests.Endoom.Digest,
  DelphiDoom.Tests.Endoom.Fixtures,
  DelphiDoom.Tests.Endoom.EditorScenarios;

var
  Out_: TStringList;

procedure Line(const s: string);
begin
  Out_.Add(s);
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

function PixelDigest(const scr: TEndScreen; blink: Boolean): string;
var
  b: TBitmap;
  y, x: Integer;
  ln: PLongWordArray;
  px: TArray<Cardinal>;
begin
  b := TBitmap.Create;
  try
    scr.GetBitmap(b, blink);
    SetLength(px, 640 * 200);
    for y := 0 to 199 do
    begin
      ln := b.ScanLine[y];
      for x := 0 to 639 do
        px[y * 640 + x] := ln[x] and $FFFFFF;
    end;
    Result := TEndoomDigest.OfCardinals(px);
  finally
    b.Free;
  end;
end;

procedure LoadBytes(const scr: TEndScreen; const b: TBytes);
var
  m: TMemoryStream;
begin
  m := TMemoryStream.Create;
  try
    m.Write(b[0], Length(b));
    m.Position := 0;
    scr.LoadFromStream(m);
  finally
    m.Free;
  end;
end;

procedure Model;
var
  seed, i: Integer;
  scr: TEndScreen;
begin
  for seed := 1 to 6 do
  begin
    scr := TEndScreen.Create;
    ApplyOps(scr, TEditorScenarios.ModelOps(seed * 1000 + 7, 600 * seed));
    Line(Format('MODEL %d %s', [seed, TEndoomDigest.OfBytes(Bytes(scr))]));
    Line(Format('RENDERM %d 0 %s', [seed, PixelDigest(scr, False)]));
    Line(Format('RENDERM %d 1 %s', [seed, PixelDigest(scr, True)]));
    scr.Free;
  end;
  for i := 0 to 2 do
  begin
    scr := TEndScreen.Create;
    LoadBytes(scr, TEndoomFixtures.Screen(i));
    Line(Format('LOAD %d %s', [i, TEndoomDigest.OfBytes(Bytes(scr))]));
    Line(Format('RENDERF %d 0 %s', [i, PixelDigest(scr, False)]));
    Line(Format('RENDERF %d 1 %s', [i, PixelDigest(scr, True)]));
    scr.Free;
  end;
end;

procedure Quantize;
var
  colors: TArray<Cardinal>;
  scr: TEndScreen;
  i: Integer;
  bg, fg: TBytes;
  b: TBytes;
begin
  colors := TEditorScenarios.ColorsToQuantize;
  scr := TEndScreen.Create;
  SetLength(bg, Length(colors));
  SetLength(fg, Length(colors));
  for i := 0 to High(colors) do
  begin
    scr.BackgroundColor[0, 0] := colors[i];
    scr.ForegroundColor[0, 0] := colors[i];
    b := Bytes(scr);
    bg[i] := (b[1] and $70) shr 4;
    fg[i] := b[1] and $0F;
  end;
  Line('QUANT bg ' + TEndoomDigest.OfBytes(bg));
  Line('QUANT fg ' + TEndoomDigest.OfBytes(fg));
  scr.Free;
end;

procedure Draw;
const
  GROUPSIZE = 100;
var
  tool, i, g: Integer;
  cases: TArray<TEditorDrawCase>;
  base, scr: TEndScreen;
  old: TOld;
  acc: TBytes;
  b: TBytes;
begin
  base := TEndScreen.Create;
  ApplyOps(base, TEditorScenarios.BaseOps);
  scr := TEndScreen.Create;
  old := TOld.Create;
  old.escreen := scr;
  for tool := 0 to EDITOR_TOOL_COUNT - 1 do
  begin
    cases := TEditorScenarios.DrawCases(tool);
    g := 0;
    acc := nil;
    for i := 0 to High(cases) do
    begin
      scr.AssignTo(base); // copies the base into scr (the old name is the other way round)
      old.bkcolor := screencolors[cases[i].Background];
      old.fgcolor := screencolors[cases[i].Foreground];
      old.lmousedownx := cases[i].DownX;
      old.lmousedowny := cases[i].DownY;
      old.LLeftMousePaintTo(cases[i].UpX, cases[i].UpY, tool);
      b := Bytes(scr);
      SetLength(acc, Length(acc) + Length(b));
      Move(b[0], acc[Length(acc) - Length(b)], Length(b));
      if ((i + 1) mod GROUPSIZE = 0) or (i = High(cases)) then
      begin
        Line(Format('DRAW %d %d %s', [tool, g, TEndoomDigest.OfBytes(acc)]));
        Inc(g);
        acc := nil;
      end;
    end;
  end;
  old.Free;
  scr.Free;
  base.Free;
end;

procedure Paste;
var
  cases: TArray<TEditorPasteCase>;
  scr: TEndScreen;
  old: TOld;
  i: Integer;
begin
  cases := TEditorScenarios.PasteCases;
  scr := TEndScreen.Create;
  old := TOld.Create;
  old.escreen := scr;
  for i := 0 to High(cases) do
  begin
    scr.Clear;
    old.fgcolor := screencolors[cases[i].Foreground];
    old.lcursorx := cases[i].X;
    old.lcursory := cases[i].Y;
    old.PasteText(cases[i].Text);
    Line(Format('PASTE %d %s %d %d', [i, TEndoomDigest.OfBytes(Bytes(scr)), old.lcursorx, old.lcursory]));
  end;
  old.Free;
  scr.Free;
end;

begin
  Out_ := TStringList.Create;
  Model;
  Quantize;
  Draw;
  Paste;
  Out_.SaveToFile(ParamStr(1));
  Out_.Free;
end.
