// TEMPORARY HARNESS of issue #149 (not for the build of the game): runs the OLD code of the light
// thinkers (copied as it was before Libs\Thinkers) next to the NEW one, for every tic of every light,
// on the same state and the same random numbers. See docs\RUN.md.
//
// For each call: copy of the thinker and of its sector -> old code on the copy (it uses the real
// random: its index is saved before and restored after) -> new code on the real thinker -> compare
// light level, fields and random index. A report is written to light_parity.txt on exit.

{$I Doom32.inc}

unit light_parity;

interface

uses
  r_defs,
  p_spec,
  udmf_lights;

type
  TLPLightProc = procedure(light: Plight_t);
  TLPPhaseProc = procedure(phase: Pphase_t);
{$IFNDEF HEXEN}
  TLPFlickerProc = procedure(flick: Pfireflicker_t);
  TLPFlashProc = procedure(flash: Plightflash_t);
  TLPStrobeProc = procedure(flash: Pstrobe_t);
  TLPGlowProc = procedure(g: Pglow_t);
{$ENDIF}

procedure LP_Light(light: Plight_t; NewProc: TLPLightProc);
procedure LP_Phase(phase: Pphase_t; NewProc: TLPPhaseProc);
{$IFNDEF HEXEN}
procedure LP_FireFlicker(flick: Pfireflicker_t; NewProc: TLPFlickerProc);
procedure LP_LightFlash(flash: Plightflash_t; NewProc: TLPFlashProc);
procedure LP_StrobeFlash(flash: Pstrobe_t; NewProc: TLPStrobeProc);
procedure LP_Glow(g: Pglow_t; NewProc: TLPGlowProc);
{$ENDIF}

implementation

uses
  SysUtils,
  m_fixed,
  m_rnd,
  p_tick,
  DelphiDoom.Engine.Light.Services;

const
  KIND_FLICKER = 0;
  KIND_FLASH = 1;
  KIND_STROBE = 2;
  KIND_GLOW = 3;
  KIND_LIGHT = 4;
  KIND_PHASE = 5;
  KIND_NAMES: array[0..5] of string = ('fireflicker', 'lightflash', 'strobe', 'glow', 'scripted', 'phase');

var
  lp_total: array[0..5] of integer;
  lp_bad: array[0..5] of integer;
  lp_log: TextFile;
  lp_logopen: boolean = false;

procedure LP_Open;
begin
  if not lp_logopen then
  begin
    AssignFile(lp_log, 'light_parity.txt');
    Rewrite(lp_log);
    lp_logopen := true;
  end;
end;

procedure LP_Account(kind: integer; same: boolean; const what: string);
begin
  inc(lp_total[kind]);
  if not same then
  begin
    inc(lp_bad[kind]);
    if lp_bad[kind] <= 20 then
    begin
      LP_Open;
      writeln(lp_log, 'MISMATCH ', KIND_NAMES[kind], ' leveltime=', leveltime, ' ', what);
    end;
  end;
end;

{$IFNDEF HEXEN}

//==============================================================================
// the old bodies
//==============================================================================
procedure Old_FireFlicker(flick: Pfireflicker_t);
var
  amount: integer;
begin
  flick.count := flick.count - 1;
  if flick.count > 0 then
    exit;

{$IFDEF STRIFE}
  amount := (P_Random and 3) * 8;
{$ELSE}
  amount := (P_Random and 3) * 16;
{$ENDIF}

  if flick.sector.lightlevel - amount < flick.minlight then
    flick.sector.lightlevel := flick.minlight
  else
    flick.sector.lightlevel := flick.maxlight - amount;

{$IFDEF STRIFE}
  flick.count := (P_Random and 3) + 1;
{$ELSE}
  flick.count := 4;
{$ENDIF}
end;

procedure Old_LightFlash(flash: Plightflash_t);
begin
  flash.count := flash.count - 1;
  if flash.count > 0 then
    exit;

  if flash.sector.lightlevel = flash.maxlight then
  begin
    flash.sector.lightlevel := flash.minlight;
    flash.count := (P_Random and flash.mintime) + 1;
  end
  else
  begin
    flash.sector.lightlevel := flash.maxlight;
    flash.count := (P_Random and flash.maxtime) + 1;
  end;
end;

procedure Old_StrobeFlash(flash: Pstrobe_t);
begin
  flash.count := flash.count - 1;
  if flash.count > 0 then
    exit;

  if flash.sector.lightlevel = flash.minlight then
  begin
    flash.sector.lightlevel := flash.maxlight;
    flash.count := flash.brighttime;
  end
  else
  begin
    flash.sector.lightlevel := flash.minlight;
    flash.count := flash.darktime;
  end;
end;

procedure Old_Glow(g: Pglow_t);
begin
  case g.direction of
   -1:
      begin
        g.sector.lightlevel := g.sector.lightlevel - GLOWSPEED;
        if g.sector.lightlevel <= g.minlight then
        begin
          g.sector.lightlevel := g.sector.lightlevel + GLOWSPEED;
          g.direction := 1;
        end;
      end;
    1:
      begin
        g.sector.lightlevel := g.sector.lightlevel + GLOWSPEED;
        if g.sector.lightlevel >= g.maxlight then
        begin
          g.sector.lightlevel := g.sector.lightlevel - GLOWSPEED;
          g.direction := -1;
        end;
      end;
  end;
end;

//==============================================================================
// the checks
//==============================================================================
procedure LP_FireFlicker(flick: Pfireflicker_t; NewProc: TLPFlickerProc);
var
  ocopy: fireflicker_t;
  osec: sector_t;
  idx0, idx1: integer;
begin
  osec := flick.sector^;
  ocopy := flick^;
  ocopy.sector := @osec;
  idx0 := LightRandom.PlayIndex;
  Old_FireFlicker(@ocopy);
  idx1 := LightRandom.PlayIndex;
  LightRandom.PlayIndex := idx0;
  NewProc(flick);
  LP_Account(KIND_FLICKER, (osec.lightlevel = flick.sector.lightlevel) and (ocopy.count = flick.count) and
    (idx1 = LightRandom.PlayIndex), Format('old level %d count %d idx %d, new level %d count %d idx %d',
    [osec.lightlevel, ocopy.count, idx1, flick.sector.lightlevel, flick.count, LightRandom.PlayIndex]));
end;

procedure LP_LightFlash(flash: Plightflash_t; NewProc: TLPFlashProc);
var
  ocopy: lightflash_t;
  osec: sector_t;
  idx0, idx1: integer;
begin
  osec := flash.sector^;
  ocopy := flash^;
  ocopy.sector := @osec;
  idx0 := LightRandom.PlayIndex;
  Old_LightFlash(@ocopy);
  idx1 := LightRandom.PlayIndex;
  LightRandom.PlayIndex := idx0;
  NewProc(flash);
  LP_Account(KIND_FLASH, (osec.lightlevel = flash.sector.lightlevel) and (ocopy.count = flash.count) and
    (idx1 = LightRandom.PlayIndex), Format('old level %d count %d idx %d, new level %d count %d idx %d',
    [osec.lightlevel, ocopy.count, idx1, flash.sector.lightlevel, flash.count, LightRandom.PlayIndex]));
end;

procedure LP_StrobeFlash(flash: Pstrobe_t; NewProc: TLPStrobeProc);
var
  ocopy: strobe_t;
  osec: sector_t;
begin
  osec := flash.sector^;
  ocopy := flash^;
  ocopy.sector := @osec;
  Old_StrobeFlash(@ocopy);
  NewProc(flash);
  LP_Account(KIND_STROBE, (osec.lightlevel = flash.sector.lightlevel) and (ocopy.count = flash.count),
    Format('old level %d count %d, new level %d count %d',
    [osec.lightlevel, ocopy.count, flash.sector.lightlevel, flash.count]));
end;

procedure LP_Glow(g: Pglow_t; NewProc: TLPGlowProc);
var
  ocopy: glow_t;
  osec: sector_t;
begin
  osec := g.sector^;
  ocopy := g^;
  ocopy.sector := @osec;
  Old_Glow(@ocopy);
  NewProc(g);
  LP_Account(KIND_GLOW, (osec.lightlevel = g.sector.lightlevel) and (ocopy.direction = g.direction),
    Format('old level %d dir %d, new level %d dir %d',
    [osec.lightlevel, ocopy.direction, g.sector.lightlevel, g.direction]));
end;

{$ENDIF}

//==============================================================================
// the scripted lights and the phases (all games)
//==============================================================================
procedure Old_Light(light: Plight_t);
begin
  if light.count > 0 then
  begin
    dec(light.count);
    exit;
  end;

  case light._type of
    LITE_FADE:
      begin
        light.sector.lightlevel := ((light.sector.lightlevel * FRACUNIT) + light.value2) div FRACUNIT;
        if light.tics2 = 1 then
        begin
          if light.sector.lightlevel >= light.value1 then
          begin
            light.sector.lightlevel := light.value1;
            P_RemoveThinker(@light.thinker);
          end;
        end
        else if light.sector.lightlevel <= light.value1 then
        begin
          light.sector.lightlevel := light.value1;
          P_RemoveThinker(@light.thinker);
        end;
      end;
    LITE_GLOW:
      begin
        light.sector.lightlevel := ((light.sector.lightlevel * FRACUNIT) + light.tics1) div FRACUNIT;
        if light.tics2 = 1 then
        begin
          if light.sector.lightlevel >= light.value1 then
          begin
            light.sector.lightlevel := light.value1;
            light.tics1 := -light.tics1;
            light.tics2 := -1;
          end;
        end
        else if light.sector.lightlevel <= light.value2 then
        begin
          light.sector.lightlevel := light.value2;
          light.tics1 := -light.tics1;
          light.tics2 := 1;
        end;
      end;
    LITE_FLICKER:
      begin
        if light.sector.lightlevel = light.value1 then
        begin
          light.sector.lightlevel := light.value2;
          light.count := (P_Random and 7) + 1;
        end
        else
        begin
          light.sector.lightlevel := light.value1;
          light.count := (P_Random and 31) + 1;
        end;
      end;
    LITE_STROBE,
    LITE_STROBEDOOM:
      begin
        if light.sector.lightlevel = light.value1 then
        begin
          light.sector.lightlevel := light.value2;
          light.count := light.tics2;
        end
        else
        begin
          light.sector.lightlevel := light.value1;
          light.count := light.tics1;
        end;
      end;
  end;
end;

const
  OldPhaseTable: array[0..63] of integer = (
    128, 112,  96,  80,  64,  48,  32,  32,
     16,  16,  16,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,  16,  16,  16,
     32,  32,  48,  64,  80,  96, 112, 128
  );

procedure Old_Phase(phase: Pphase_t);
begin
  phase.index := (phase.index + 1) and 63;
  phase.sector.lightlevel := phase.base + OldPhaseTable[phase.index];
end;

procedure LP_Light(light: Plight_t; NewProc: TLPLightProc);
var
  ocopy: light_t;
  osec: sector_t;
  idx0, idx1: integer;
  oremoved: boolean;
begin
  osec := light.sector^;
  ocopy := light^;
  ocopy.sector := @osec;
  idx0 := LightRandom.PlayIndex;
  Old_Light(@ocopy);
  idx1 := LightRandom.PlayIndex;
  oremoved := P_ThinkerIsRemoved(@ocopy.thinker);
  LightRandom.PlayIndex := idx0;
  NewProc(light);
  LP_Account(KIND_LIGHT, (osec.lightlevel = light.sector.lightlevel) and (ocopy.count = light.count) and
    (ocopy.tics1 = light.tics1) and (ocopy.tics2 = light.tics2) and (idx1 = LightRandom.PlayIndex) and
    (oremoved = P_ThinkerIsRemoved(@light.thinker)),
    Format('type %d old level %d count %d idx %d removed %s, new level %d count %d idx %d removed %s',
    [Ord(light._type), osec.lightlevel, ocopy.count, idx1, BoolToStr(oremoved), light.sector.lightlevel,
     light.count, LightRandom.PlayIndex, BoolToStr(P_ThinkerIsRemoved(@light.thinker))]));
end;

procedure LP_Phase(phase: Pphase_t; NewProc: TLPPhaseProc);
var
  ocopy: phase_t;
  osec: sector_t;
begin
  osec := phase.sector^;
  ocopy := phase^;
  ocopy.sector := @osec;
  Old_Phase(@ocopy);
  NewProc(phase);
  LP_Account(KIND_PHASE, (osec.lightlevel = phase.sector.lightlevel) and (ocopy.index = phase.index),
    Format('old level %d index %d, new level %d index %d',
    [osec.lightlevel, ocopy.index, phase.sector.lightlevel, phase.index]));
end;

procedure LP_WriteReport;
var
  i: integer;
begin
  LP_Open;
  for i := 0 to 5 do
    writeln(lp_log, KIND_NAMES[i], ' ticks=', lp_total[i], ' mismatches=', lp_bad[i]);
  CloseFile(lp_log);
  lp_logopen := false;
end;

initialization

finalization
  LP_WriteReport;

end.
