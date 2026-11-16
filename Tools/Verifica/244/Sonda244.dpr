program Sonda244;
// Sonda #244: stessa routine a forma di PIT_CheckLine con lo stato in
//  A: globali separate (oggi)
//  E: class var di una classe, metodi (e routine libere) che li leggono
//  D: record in un globale tipizzato
//  S: class var, routine come metodo class static
{$APPTYPE CONSOLE}
{$O+}{$R-}{$Q-}
uses
  Windows, SysUtils;

type
  Pline = ^TLine;
  TLine = record
    bbox: array[0..3] of Integer;
    dx, dy: Integer;
    flags: Integer;
    backsector: Pointer;
  end;

  TOpenInfo = record
    top, bottom, range, low: Integer;
  end;

var
  // A
  a_tmbbox: array[0..3] of Integer;
  a_tmx, a_tmy: Integer;
  a_tmfloorz, a_tmceilingz, a_tmdropoffz: Integer;
  a_ceilingline: Pline;
  a_numspechit: Integer;
  a_tmthing: Pointer;
  // D
  d_tm: record
    bbox: array[0..3] of Integer;
    x, y: Integer;
    floorz, ceilingz, dropoffz: Integer;
    ceilingline: Pline;
    numspechit: Integer;
    thing: Pointer;
  end;

type
  TMapCheck = class sealed
  public
    class var BBox: array[0..3] of Integer;
    class var X, Y: Integer;
    class var FloorZ, CeilingZ, DropOffZ: Integer;
    class var CeilingLine: Pline;
    class var NumSpecHit: Integer;
    class var Thing: Pointer;
    class function CheckLine(ld: Pline): Boolean; static;
  end;

var
  Sink: Integer;

procedure Other(ld: Pline);
begin
  Inc(Sink, ld.flags);
end;

function PIT_A(ld: Pline): Boolean;
begin
  Result := True;
  if (a_tmbbox[3] <= ld.bbox[2]) or (a_tmbbox[2] >= ld.bbox[3]) or
     (a_tmbbox[0] <= ld.bbox[1]) or (a_tmbbox[1] >= ld.bbox[0]) then
    Exit;
  if (a_tmx - ld.dx) * ld.dy < (a_tmy - ld.dy) * ld.dx then
    Exit;
  if ld.backsector = nil then
  begin
    Result := False;
    Exit;
  end;
  if a_tmceilingz > ld.bbox[0] then
  begin
    a_tmceilingz := ld.bbox[0];
    a_ceilingline := ld;
  end;
  if a_tmfloorz < ld.bbox[1] then
    a_tmfloorz := ld.bbox[1];
  if a_tmdropoffz > ld.bbox[2] then
    a_tmdropoffz := ld.bbox[2];
  if ld.flags <> 0 then
  begin
    Inc(a_numspechit);
    Other(ld);
  end;
end;

function PIT_D(ld: Pline): Boolean;
begin
  Result := True;
  if (d_tm.bbox[3] <= ld.bbox[2]) or (d_tm.bbox[2] >= ld.bbox[3]) or
     (d_tm.bbox[0] <= ld.bbox[1]) or (d_tm.bbox[1] >= ld.bbox[0]) then
    Exit;
  if (d_tm.x - ld.dx) * ld.dy < (d_tm.y - ld.dy) * ld.dx then
    Exit;
  if ld.backsector = nil then
  begin
    Result := False;
    Exit;
  end;
  if d_tm.ceilingz > ld.bbox[0] then
  begin
    d_tm.ceilingz := ld.bbox[0];
    d_tm.ceilingline := ld;
  end;
  if d_tm.floorz < ld.bbox[1] then
    d_tm.floorz := ld.bbox[1];
  if d_tm.dropoffz > ld.bbox[2] then
    d_tm.dropoffz := ld.bbox[2];
  if ld.flags <> 0 then
  begin
    Inc(d_tm.numspechit);
    Other(ld);
  end;
end;

function PIT_E(ld: Pline): Boolean;
begin
  Result := True;
  if (TMapCheck.BBox[3] <= ld.bbox[2]) or (TMapCheck.BBox[2] >= ld.bbox[3]) or
     (TMapCheck.BBox[0] <= ld.bbox[1]) or (TMapCheck.BBox[1] >= ld.bbox[0]) then
    Exit;
  if (TMapCheck.X - ld.dx) * ld.dy < (TMapCheck.Y - ld.dy) * ld.dx then
    Exit;
  if ld.backsector = nil then
  begin
    Result := False;
    Exit;
  end;
  if TMapCheck.CeilingZ > ld.bbox[0] then
  begin
    TMapCheck.CeilingZ := ld.bbox[0];
    TMapCheck.CeilingLine := ld;
  end;
  if TMapCheck.FloorZ < ld.bbox[1] then
    TMapCheck.FloorZ := ld.bbox[1];
  if TMapCheck.DropOffZ > ld.bbox[2] then
    TMapCheck.DropOffZ := ld.bbox[2];
  if ld.flags <> 0 then
  begin
    Inc(TMapCheck.NumSpecHit);
    Other(ld);
  end;
end;

class function TMapCheck.CheckLine(ld: Pline): Boolean;
begin
  Result := True;
  if (BBox[3] <= ld.bbox[2]) or (BBox[2] >= ld.bbox[3]) or
     (BBox[0] <= ld.bbox[1]) or (BBox[1] >= ld.bbox[0]) then
    Exit;
  if (X - ld.dx) * ld.dy < (Y - ld.dy) * ld.dx then
    Exit;
  if ld.backsector = nil then
  begin
    Result := False;
    Exit;
  end;
  if CeilingZ > ld.bbox[0] then
  begin
    CeilingZ := ld.bbox[0];
    CeilingLine := ld;
  end;
  if FloorZ < ld.bbox[1] then
    FloorZ := ld.bbox[1];
  if DropOffZ > ld.bbox[2] then
    DropOffZ := ld.bbox[2];
  if ld.flags <> 0 then
  begin
    Inc(NumSpecHit);
    Other(ld);
  end;
end;

procedure Setup(var ld: TLine; i: Integer);
begin
  ld.bbox[0] := 1000 + (i and 15);
  ld.bbox[1] := -1000 - (i and 7);
  ld.bbox[2] := -2000;
  ld.bbox[3] := 3000;
  ld.dx := i and 31;
  ld.dy := 5;
  ld.flags := i and 1;
  ld.backsector := @Sink;
end;

const
  N = 100000000;

function TimeIt(Kind: Char): Double;
var
  LLine: TLine;
  i: Integer;
  F, T0, T1: Int64;
begin
  QueryPerformanceFrequency(F);
  Setup(LLine, 3);
  a_tmbbox[0] := 0; a_tmbbox[1] := -500; a_tmbbox[2] := -500; a_tmbbox[3] := 500;
  for i := 0 to 3 do d_tm.bbox[i] := a_tmbbox[i];
  for i := 0 to 3 do TMapCheck.BBox[i] := a_tmbbox[i];
  a_tmx := 0; a_tmy := 0; d_tm.x := 0; d_tm.y := 0; TMapCheck.X := 0; TMapCheck.Y := 0;
  a_tmceilingz := 5000; a_tmfloorz := -5000; a_tmdropoffz := 5000;
  d_tm.ceilingz := 5000; d_tm.floorz := -5000; d_tm.dropoffz := 5000;
  TMapCheck.CeilingZ := 5000; TMapCheck.FloorZ := -5000; TMapCheck.DropOffZ := 5000;
  QueryPerformanceCounter(T0);
  case Kind of
    'A': for i := 1 to N do begin LLine.flags := i and 1; PIT_A(@LLine); end;
    'D': for i := 1 to N do begin LLine.flags := i and 1; PIT_D(@LLine); end;
    'E': for i := 1 to N do begin LLine.flags := i and 1; PIT_E(@LLine); end;
    'S': for i := 1 to N do begin LLine.flags := i and 1; TMapCheck.CheckLine(@LLine); end;
  end;
  QueryPerformanceCounter(T1);
  Result := (T1 - T0) / F;
end;

var
  K: Char;
  R, Best: Double;
  Round_: Integer;
begin
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);
  for K in ['A', 'D', 'E', 'S'] do
  begin
    Best := 1E30;
    for Round_ := 1 to 7 do
    begin
      R := TimeIt(K);
      if R < Best then Best := R;
    end;
    Writeln(K, ' ', FormatFloat('0.000', Best));
  end;
  Writeln(Sink);
end.
