{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixHudGauges                                 }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the arithmetic of radix_hud.pas (RX_HudDrawTime,                    }
{  RX_HudDrawSpeedIndicator, RX_DrawRadar, RX_HudDrawBar,                      }
{  RX_HudDrawPowerUpIcons, RX_HudDrawCrossHair, RX_HudDrawer)                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Hud.Gauges;

interface

type
  /// <summary>Which of the displays of the craft the HUD draws</summary>
  TRadixHudMode = (
    /// <summary>Nothing (full view)</summary>
    rhmNone,
    /// <summary>Only the message "press space to restart" of a dead pilot</summary>
    rhmRestartOnly,
    /// <summary>The status bar, 41 rows at the bottom</summary>
    rhmStatusBar,
    /// <summary>The whole cockpit</summary>
    rhmCockpit,
    /// <summary>The lower part of the cockpit</summary>
    rhmHalfCockpit,
    /// <summary>The three bars, the icons and the cross hair</summary>
    rhmSmall);

  /// <summary>What the speed indicator draws: Count columns, two pixels apart, going right or left</summary>
  TRadixSpeedBars = record
    Count: Integer;
    Step: Integer;
  end;

  /// <summary>The clock of the level: minutes and seconds, or the word of the old code past 99:59</summary>
  TRadixHudClock = record
    Overflow: Boolean;
    Minutes: Integer;
    Seconds: Integer;
  end;

  /// <summary>
  ///   The numbers of the instruments of the craft, without drawing. The tics are those of the
  ///   engine (35 a second); positions and momenta are 16.16 fixed point
  /// </summary>
  TRadixHudGauges = class
  public const
    /// <summary>The columns of the speed indicator</summary>
    SPEED_COLUMNS = 15;
    /// <summary>The largest momentum on an axis of the craft (MAXMOVETHRESHOLD: 18 map units a tic)</summary>
    MAX_MOVE_UNITS = 18;
    /// <summary>The colour of the cockpit that the radar replaces to glow</summary>
    RADAR_BASE_COLOR = 124;
    /// <summary>The colour of the radar when the scanner is jammed or the pilot is dead</summary>
    RADAR_JAMMED_COLOR = 63;
    /// <summary>The steps of the cross hair while it locks a target (0 = free)</summary>
    CROSSHAIR_LOCK_STEPS = 6;
  public
    /// <summary>The display for a size of the view (screenblocks) with or without the full automap</summary>
    class function Mode(AScreenBlocks: Integer; AAutomapOnly, ADead: Boolean): TRadixHudMode; static;
    /// <summary>The clock of a level time in tics</summary>
    class function Clock(ALevelTime: Integer): TRadixHudClock; static;
    /// <summary>
    ///   The columns of the speed indicator for a momentum. AUp is the indicator of the status bar
    ///   (it fills to the right as the craft goes faster); the one of the cockpit empties to the left
    /// </summary>
    class function SpeedBars(AMomX, AMomY, AMomZ: Integer; AUp: Boolean): TRadixSpeedBars; static;
    /// <summary>The columns of a bar of AWidth pixels that stay drawn at APercent (0 = nothing, AWidth = all)</summary>
    class function BarFill(AWidth, APercent: Integer): Integer; static;
    /// <summary>A power up icon is steady while more than 128 tics are left, then it blinks</summary>
    class function PowerUpVisible(ATics: Integer): Boolean; static;
    /// <summary>The colour of the radar ring at a level time (it glows every 8 tics)</summary>
    class function RadarGlowColor(ALevelTime: Integer): Byte; static;
    /// <summary>The scanner shows nothing: the pilot is dead, or it is jammed and blinking</summary>
    class function RadarJammed(ADead, AScannerJam: Boolean; ALevelTime: Integer): Boolean; static;
    /// <summary>
    ///   The pixel of a thing on the radar, relative to its centre. ASine and ACosine are those of
    ///   (90 degrees - the angle of the craft), 16.16. False when the thing is out of ARange
    /// </summary>
    class function RadarOffset(APlayerX, APlayerY, AThingX, AThingY, ASine, ACosine,
      ARange: Integer; out ADeltaX, ADeltaY: Integer): Boolean; static;
    /// <summary>The picture of the cross hair: 0 without a target, then 1..6 as the tics pass on the same target</summary>
    class function CrossHairIndex(AHasTarget: Boolean; ALevelTime, ALockTic: Integer): Integer; static;
    /// <summary>The threat light is on (it blinks every 16 tics while the craft is under threat)</summary>
    class function ThreatLit(AThreat: Boolean; ALevelTime: Integer): Boolean; static;
  end;

implementation

uses
  System.Math;

const
  TICRATE = 35;
  CLOCK_LIMIT_SECONDS = 99 * 60 + 59;
  POWERUP_STEADY_TICS = 4 * 32;
  POWERUP_BLINK_MASK = 8;
  RADAR_SHIFT_BITS = 8;
  RADAR_SHIFT_UNIT = 1 shl RADAR_SHIFT_BITS;
  // 128 map units for a pixel, in the 24.8 numbers of the radar
  RADAR_RANGE_FACTOR = 128 * (1 shl (16 - RADAR_SHIFT_BITS));
  FRACUNIT = 65536;

{ TRadixHudGauges }

class function TRadixHudGauges.Mode(AScreenBlocks: Integer; AAutomapOnly, ADead: Boolean): TRadixHudMode;
begin
  if AAutomapOnly or (AScreenBlocks <= 10) then
    Exit(rhmStatusBar);
  case AScreenBlocks of
    11: Result := rhmCockpit;
    12: Result := rhmHalfCockpit;
    13: Result := rhmSmall;
  else
    if ADead then
      Result := rhmRestartOnly
    else
      Result := rhmNone;
  end;
end;

class function TRadixHudGauges.Clock(ALevelTime: Integer): TRadixHudClock;
var
  LSeconds: Integer;
begin
  Result.Overflow := ALevelTime > CLOCK_LIMIT_SECONDS * TICRATE;
  LSeconds := ALevelTime div TICRATE;
  Result.Minutes := LSeconds div 60;
  Result.Seconds := LSeconds mod 60;
end;

class function TRadixHudGauges.SpeedBars(AMomX, AMomY, AMomZ: Integer; AUp: Boolean): TRadixSpeedBars;
var
  LSpeed: Double;
  LFactor: Double;
  LCount: Integer;
begin
  LSpeed := Sqrt(Sqr(AMomX / FRACUNIT) + Sqr(AMomY / FRACUNIT) + Sqr(AMomZ / FRACUNIT));
  LFactor := SPEED_COLUMNS / Sqrt(2 * Sqr(MAX_MOVE_UNITS));
  LCount := EnsureRange(SPEED_COLUMNS - Round(LSpeed * LFactor), 0, SPEED_COLUMNS);
  if AUp then
  begin
    Result.Count := SPEED_COLUMNS - LCount;
    Result.Step := 2;
  end
  else
  begin
    Result.Count := LCount;
    Result.Step := -2;
  end;
end;

class function TRadixHudGauges.BarFill(AWidth, APercent: Integer): Integer;
begin
  if APercent <= 0 then
    Result := 0
  else if APercent >= 100 then
    Result := AWidth
  else
    Result := AWidth * APercent div 100;
end;

class function TRadixHudGauges.PowerUpVisible(ATics: Integer): Boolean;
begin
  Result := (ATics > POWERUP_STEADY_TICS) or (ATics and POWERUP_BLINK_MASK <> 0);
end;

class function TRadixHudGauges.RadarGlowColor(ALevelTime: Integer): Byte;
begin
  case (ALevelTime div 8) and 3 of
    0: Result := RADAR_BASE_COLOR - 1;
    2: Result := RADAR_BASE_COLOR + 1;
  else
    Result := RADAR_BASE_COLOR;
  end;
end;

class function TRadixHudGauges.RadarJammed(ADead, AScannerJam: Boolean; ALevelTime: Integer): Boolean;
begin
  Result := ADead or (AScannerJam and (ALevelTime and 16 <> 0));
end;

class function TRadixHudGauges.RadarOffset(APlayerX, APlayerY, AThingX, AThingY, ASine, ACosine,
  ARange: Integer; out ADeltaX, ADeltaY: Integer): Boolean;

  // the distance in pixels, rounded to the nearest (div truncates towards zero)
  function ToPixels(AFrom, ATo: Integer): Integer;
  begin
    Result := AFrom div RADAR_SHIFT_UNIT - ATo div RADAR_SHIFT_UNIT;
    if Result < 0 then
      Result := Result - RADAR_RANGE_FACTOR div 2
    else
      Result := Result + RADAR_RANGE_FACTOR div 2;
    Result := Result div RADAR_RANGE_FACTOR;
  end;

  function FixedMul(A, B: Integer): Integer;
  begin
    Result := Integer((Int64(A) * Int64(B)) div FRACUNIT);
    // FixedMul of the engine is an arithmetic shift: it rounds down, div rounds to zero
    if ((Int64(A) * Int64(B)) < 0) and ((Int64(A) * Int64(B)) mod FRACUNIT <> 0) then
      Dec(Result);
  end;

var
  LX, LY: Integer;
begin
  LX := ToPixels(APlayerX, AThingX);
  LY := ToPixels(APlayerY, AThingY);
  Result := LX * LX + LY * LY <= ARange * ARange;
  if Result then
  begin
    ADeltaX := FixedMul(LY, ASine) - FixedMul(LX, ACosine);
    ADeltaY := FixedMul(LX, ASine) + FixedMul(LY, ACosine);
  end
  else
  begin
    ADeltaX := 0;
    ADeltaY := 0;
  end;
end;

class function TRadixHudGauges.CrossHairIndex(AHasTarget: Boolean; ALevelTime, ALockTic: Integer): Integer;
begin
  if not AHasTarget then
    Exit(0);
  Result := Min(ALevelTime - ALockTic + 1, CROSSHAIR_LOCK_STEPS);
end;

class function TRadixHudGauges.ThreatLit(AThreat: Boolean; ALevelTime: Integer): Boolean;
begin
  Result := AThreat and ((ALevelTime shr 4) and 1 <> 0);
end;

end.
