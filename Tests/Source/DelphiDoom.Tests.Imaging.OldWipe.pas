{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - the melt of f_wipe.pas as it was before the facade      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.OldWipe;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   Copy of wipe_initMelt and wipe_doMelt of IdTech1\Base\f_wipe.pas at c4ce14f1 (issue #185), for
  ///   the parity of TImagingMeltWipe.StartOnBuffers. The globals of the engine (SCREENWIDTH,
  ///   SCREENHEIGHT, screen32, w_screen32, wipe_scr_start, wipe_scr_end, yy, vy) are fields,
  ///   the {$IFDEF OPENGL} is the OpenGl field, I_Random is the source given to Create, and
  ///   Z_Malloc/MT_memcpy are the plain ones. The statements are the old ones
  /// </summary>
  TOldWipe = class(TObject)
  private
    FRandom: IImagingRandom;
    yy: TArray<Integer>;
    vy: Integer;
    function I_Random: Integer;
  public
    SCREENWIDTH: Integer;
    SCREENHEIGHT: Integer;
    WIPESCREENWIDTH: Integer;
    OpenGl: Boolean;
    wipe_scr_start: PCardinal;
    wipe_scr_end: PCardinal;
    /// <summary>screen32 of the software renderer or w_screen32 of OpenGL</summary>
    screen: PCardinal;
    constructor Create(const ARandom: IImagingRandom);
    procedure wipe_initMelt;
    function wipe_doMelt(ticks: Integer): Integer;
  end;

implementation

const
  FRACUNIT = 1 shl 16;

type
  TCardinals = array[0..$FFFFFF] of Cardinal;
  PCardinals = ^TCardinals;

{ TOldWipe }

constructor TOldWipe.Create(const ARandom: IImagingRandom);
begin
  inherited Create;
  FRandom := ARandom;
end;

function TOldWipe.I_Random: Integer;
begin
  Result := FRandom.NextByte;
end;

procedure TOldWipe.wipe_initMelt;
var
  i, r: integer;
  py, py1: PInteger;
  SHEIGHTS: TArray<Integer>;
  RANDOMS: array[0..319] of byte;
begin
  SetLength(SHEIGHTS, SCREENWIDTH);
  for i := 0 to SCREENWIDTH - 1 do
    SHEIGHTS[i] := trunc(i * 320 / SCREENWIDTH);
  for i := 0 to 319 do
    RANDOMS[i] := I_Random;

  if not OpenGl then
    // copy start screen to main screen
    Move(wipe_scr_start^, screen^, SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord))
  else
    for i := 0 to SCREENWIDTH - 1 do
      for r := 0 to SCREENHEIGHT - 1 do
        PCardinals(screen)[r * WIPESCREENWIDTH + i] := PCardinals(wipe_scr_start)[r * SCREENWIDTH + i];
  // setup initial column positions
  // (y<0 => not ready to scroll yet)
  SetLength(yy, SCREENWIDTH);
  py := @yy[0];
  py1 := py;

  py^ := -(RANDOMS[0] mod 16);
  for i := 1 to SCREENWIDTH - 1 do
  begin
    inc(py);
    r := (RANDOMS[SHEIGHTS[i]] mod 3) - 1;
    py^ := py1^ + r;
    if py^ > 0 then
      py^ := 0
    else if py^ = -16 then
      py^ := -15;
    inc(py1);
  end;

// JVAL change wipe timing
  vy := FRACUNIT * SCREENHEIGHT div 200;
  py := @yy[0];
  for i := 0 to SCREENWIDTH - 1 do
  begin
    py^ := py^ * vy;
    inc(py);
  end;

  for i := 1 to SCREENWIDTH - 1 do
    if SHEIGHTS[i - 1] = SHEIGHTS[i] then
      yy[i] := yy[i - 1];
end;

function TOldWipe.wipe_doMelt(ticks: Integer): Integer;
var
  i: integer;
  j: integer;
  dy: Integer;
  sidx: PCardinal;
  didx: PCardinal;
  py: PInteger;
  pos: integer;
  alpha: Cardinal;
  pitch: Integer;
begin
  result := 1;
  if OpenGl then
  begin
    alpha := $FF000000;
    pitch := WIPESCREENWIDTH;
  end
  else
  begin
    alpha := 0;
    pitch := SCREENWIDTH;
  end;

  while ticks > 0 do
  begin
    py := @yy[0];
    for i := 0 to SCREENWIDTH - 1 do
    begin
      if py^ < 0 then
      begin
        py^ := py^ + vy;
        result := 0;
      end
      else if py^ < SCREENHEIGHT * FRACUNIT then
      begin
        if py^ <= 15 * vy then
          dy := py^ + vy
        else
          dy := 8 * vy;
        if (py^ + dy) >= SCREENHEIGHT * FRACUNIT then
          dy := SCREENHEIGHT * FRACUNIT - py^;
        if ticks = 1 then
        begin
          pos := py^ div FRACUNIT;
          sidx := @PCardinals(wipe_scr_end)[i];
          didx := @PCardinals(screen)[i];
          for j := 0 to pos - 1 do
          begin
            didx^ := sidx^ or alpha;
            inc(didx, pitch);
            inc(sidx, SCREENWIDTH);
          end;
          sidx := @PCardinals(wipe_scr_start)[i];
          for j := pos to SCREENHEIGHT - 1 do
          begin
            didx^ := sidx^ or alpha;
            inc(didx, pitch);
            inc(sidx, SCREENWIDTH);
          end;
        end;

        py^ := py^ + dy;

        result := 0;
      end;
      inc(py);
    end;
    dec(ticks);
  end;
end;

end.
