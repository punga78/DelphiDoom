unit H2Old;
// The tools and the paste of main.pas of ENDEDIT, copied as they are (EditAction*, midpointellipse,
// LLeftMousePaintTo and the text branch of Paste1Click), on the TEndScreen of ee_screen.
interface

uses
  Windows, SysUtils, Classes, ee_screen, ee_utils;

type
  TOld = class
    escreen: TEndScreen;
    bkcolor, fgcolor: LongWord;
    lmousedownx, lmousedowny: Integer;
    lcursorx, lcursory: Integer;
    procedure EditActionFloodFill(const X, Y: integer);
    procedure EditActionRect(const X, Y: integer);
    procedure EditActionFillRect(const X, Y: integer);
    procedure EditActionLine(const X, Y: integer);
    procedure midpointellipse(const X, Y: integer; const filled: boolean);
    procedure EditActionCharRectChange(const X, Y: integer;
      const atopleft, atopright, abottomleft, abottomright, ahorz, avert: integer);
    procedure LLeftMousePaintTo(const X, Y: integer; const tool: Integer);
    procedure PasteText(const text: string);
  end;

implementation

uses
  DelphiDoom.Tests.Endoom.EditorScenarios;

procedure TOld.EditActionFloodFill(const X, Y: integer);
var
  rover: LongWord;
begin
  rover := escreen.BackgroundColor[X, Y];
  if rover <> bkcolor then
  begin
    escreen.BackgroundColor[X, Y] := bkcolor;
    if X > 0 then
      if escreen.BackgroundColor[X - 1, Y] = rover then
        EditActionFloodFill(X - 1, Y);
    if X < SCREENSIZEX - 1 then
      if escreen.BackgroundColor[X + 1, Y] = rover then
        EditActionFloodFill(X + 1, Y);
    if Y > 0 then
      if escreen.BackgroundColor[X, Y - 1] = rover then
        EditActionFloodFill(X, Y - 1);
    if Y < SCREENSIZEY - 1 then
      if escreen.BackgroundColor[X, Y + 1] = rover then
        EditActionFloodFill(X, Y + 1);
  end;
end;

procedure TOld.EditActionRect(const X, Y: integer);
var
  atop, abottom, aleft, aright: integer;
  i: integer;
begin
  aleft := MinI(lmousedownx, X);
  aright := MaxI(lmousedownx, X);
  atop := MinI(lmousedowny, Y);
  abottom := MaxI(lmousedowny, Y);
  for i := aleft to aright do
  begin
    escreen.BackgroundColor[i, atop] := bkcolor;
    escreen.BackgroundColor[i, abottom] := bkcolor;
  end;
  for i := atop + 1 to abottom - 1 do
  begin
    escreen.BackgroundColor[aleft, i] := bkcolor;
    escreen.BackgroundColor[aright, i] := bkcolor;
  end;
end;

procedure TOld.EditActionFillRect(const X, Y: integer);
var
  atop, abottom, aleft, aright: integer;
  i, j: integer;
begin
  aleft := MinI(lmousedownx, X);
  aright := MaxI(lmousedownx, X);
  atop := MinI(lmousedowny, Y);
  abottom := MaxI(lmousedowny, Y);
  for i := aleft to aright do
    for j := atop to abottom do
      escreen.BackgroundColor[i, j] := bkcolor;
end;

procedure TOld.EditActionLine(const X, Y: integer);
begin
  escreen.BackgroundColor[X, Y] := bkcolor;
end;

procedure TOld.midpointellipse(const X, Y: integer; const filled: boolean);
var
  rx, ry, xc, yc: integer;
  dx, dy, d1, d2: single;
  xx, yy: integer;
  i: integer;
  procedure _draw_point(const ax, ay: integer);
  begin
    if IsIntInRange(ax, 0, SCREENSIZEX - 1) then
      if IsIntInRange(ay, 0, SCREENSIZEY - 1) then
        escreen.BackgroundColor[ax, ay] := bkcolor;
  end;
begin
  rx := abs(lmousedownx - X);
  ry := abs(lmousedowny - Y);
  xc := lmousedownx;
  yc := lmousedowny;
  xx := 0;
  yy := ry;
  d1 := (ry * ry) -
        (rx * rx * ry) +
        (0.25 * rx * rx);
  dx := 2 * ry * ry * xx;
  dy := 2 * rx * rx * yy;
  while dx < dy do
  begin
    _draw_point(xx + xc, yy + yc);
    _draw_point(-xx + xc, yy + yc);
    _draw_point(xx + xc, -yy + yc);
    _draw_point(-xx + xc, -yy + yc);
    if filled then
      for i := -xx + xc + 1 to xx + xc - 1 do
      begin
        _draw_point(i, yy + yc);
        _draw_point(i, -yy + yc);
      end;
    if d1 < 0 then
    begin
      inc(xx);
      dx := dx + (2 * ry * ry);
      d1 := d1 + dx + (ry * ry);
    end
    else
    begin
      inc(xx);
      dec(yy);
      dx := dx + (2 * ry * ry);
      dy := dy - (2 * rx * rx);
      d1 := d1 + dx - dy + (ry * ry);
    end;
  end;
  d2 := ((ry * ry) * ((xx + 0.5) * (xx + 0.5))) +
        ((rx * rx) * ((yy - 1) * (yy - 1))) -
        (rx * rx * ry * ry);
  while yy >= 0 do
  begin
    _draw_point(xx + xc, yy + yc);
    _draw_point(-xx + xc, yy + yc);
    _draw_point(xx + xc, -yy + yc);
    _draw_point(-xx + xc, -yy + yc);
    if filled then
      for i := -xx + xc + 1 to xx + xc - 1 do
      begin
        _draw_point(i, yy + yc);
        _draw_point(i, -yy + yc);
      end;
    if d2 > 0 then
    begin
      dec(yy);
      dy := dy - (2 * rx * rx);
      d2 := d2 + (rx * rx) - dy;
    end
    else
    begin
      dec(yy);
      inc(xx);
      dx := dx + (2 * ry * ry);
      dy := dy - (2 * rx * rx);
      d2 := d2 + dx - dy + (rx * rx);
    end;
  end;
end;

procedure TOld.EditActionCharRectChange(const X, Y: integer;
  const atopleft, atopright, abottomleft, abottomright, ahorz, avert: integer);
var
  atop, abottom, aleft, aright: integer;
  i: integer;
begin
  aleft := MinI(lmousedownx, X);
  aright := MaxI(lmousedownx, X);
  atop := MinI(lmousedowny, Y);
  abottom := MaxI(lmousedowny, Y);
  for i := aleft + 1 to aright - 1 do
  begin
    escreen.ForegroundColor[i, atop] := fgcolor;
    escreen.Character[i, atop] := Chr(ahorz);
    escreen.ForegroundColor[i, abottom] := fgcolor;
    escreen.Character[i, abottom] := Chr(ahorz);
  end;
  for i := atop + 1 to abottom - 1 do
  begin
    escreen.ForegroundColor[aleft, i] := fgcolor;
    escreen.Character[aleft, i] := Chr(avert);
    escreen.ForegroundColor[aright, i] := fgcolor;
    escreen.Character[aright, i] := Chr(avert);
  end;
  escreen.ForegroundColor[aleft, atop] := fgcolor;
  escreen.Character[aleft, atop] := Chr(atopleft);
  escreen.ForegroundColor[aright, atop] := fgcolor;
  escreen.Character[aright, atop] := Chr(atopright);
  escreen.ForegroundColor[aleft, abottom] := fgcolor;
  escreen.Character[aleft, abottom] := Chr(abottomleft);
  escreen.ForegroundColor[aright, abottom] := fgcolor;
  escreen.Character[aright, abottom] := Chr(abottomright);
end;

procedure TOld.LLeftMousePaintTo(const X, Y: integer; const tool: Integer);
var
  dx, dy: integer;
  curx, cury: integer;
  sx, sy, ax, ay, d: integer;

  procedure PaintAt(const px, py: Integer);
  begin
    case tool of
      EDITOR_TOOL_RECTANGLE: EditActionRect(px, py);
      EDITOR_TOOL_FILL_RECTANGLE: EditActionFillRect(px, py);
      EDITOR_TOOL_ELLIPSE: midpointellipse(px, py, False);
      EDITOR_TOOL_FILLED_ELLIPSE: midpointellipse(px, py, True);
      EDITOR_TOOL_LINE: EditActionLine(px, py);
      EDITOR_TOOL_FLOOD_FILL: EditActionFloodFill(px, py);
      EDITOR_TOOL_FRAME + 0: EditActionCharRectChange(px, py, $DA, $BF, $C0, $D9, $C4, $B3);
      EDITOR_TOOL_FRAME + 1: EditActionCharRectChange(px, py, $D5, $B8, $D4, $BE, $CD, $B3);
      EDITOR_TOOL_FRAME + 2: EditActionCharRectChange(px, py, $D6, $B7, $D3, $BD, $C4, $BA);
      EDITOR_TOOL_FRAME + 3: EditActionCharRectChange(px, py, $C9, $BB, $C8, $BC, $CD, $BA);
      EDITOR_TOOL_FRAME + 4: EditActionCharRectChange(px, py, $DB, $DB, $DB, $DB, $DB, $DB);
    end;
  end;

begin
  if tool <> EDITOR_TOOL_LINE then
  begin
    PaintAt(X, Y);
    Exit;
  end;
  dx := X - lmousedownx;
  ax := 2 * abs(dx);
  if dx < 0 then
    sx := -1
  else
    sx := 1;
  dy := Y - lmousedowny;
  ay := 2 * abs(dy);
  if dy < 0 then
    sy := -1
  else
    sy := 1;
  curx := lmousedownx;
  cury := lmousedowny;
  if ax > ay then
  begin
    d := ay - ax div 2;
    while True do
    begin
      PaintAt(curx, cury);
      if curx = X then
        break;
      if d >= 0 then
      begin
        cury := cury + sy;
        d := d - ax;
      end;
      curx := curx + sx;
      d := d + ay;
    end;
  end
  else
  begin
    d := ax - ay div 2;
    while True do
    begin
      PaintAt(curx, cury);
      if cury = Y then
        break;
      if d >= 0 then
      begin
        curx := curx + sx;
        d := d - ay;
      end;
      cury := cury + sy;
      d := d + ax;
    end;
  end;
end;

procedure TOld.PasteText(const text: string);
var
  lst: TStringList;
  s: string;
  tx, ty: integer;
  i, j: integer;
begin
  lst := TStringList.Create;
  try
    lst.Text := text;
    tx := lcursorx;
    ty := lcursory;
    for i := 0 to lst.Count - 1 do
    begin
      if ty >= SCREENSIZEY then
        Break;
      s := lst.Strings[i];
      if Length(s) > SCREENSIZEX then
        SetLength(s, SCREENSIZEX);
      for j := 1 to Length(s) do
      begin
        escreen.ForegroundColor[tx, ty] := fgcolor;
        escreen.Character[tx, ty] := s[j];
        inc(tx);
        if tx >= SCREENSIZEX then
          Break;
      end;
      if i < lst.Count - 1 then
      begin
        tx := 0;
        inc(ty);
      end;
    end;
    lcursorx := GetIntInRange(tx, 0, SCREENSIZEX - 1);
    lcursory := GetIntInRange(ty, 0, SCREENSIZEY - 1);
  finally
    lst.Free;
  end;
end;

end.
