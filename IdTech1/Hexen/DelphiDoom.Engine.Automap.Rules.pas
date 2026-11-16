{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of the automap of Hexen                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Automap.Rules;

// What differs from game to game in the drawing of the automap (the colors, the color of a wall, the
// figure of a thing, the colors of the other players) is here; the loops over the lines, the things
// and the players are in am_map. Hexen has this unit; Doom, Heretic and Strife have one with the
// same name in their own folders (the project picks it by its path, like the rules of p_map and
// p_mobj). The functions are static and are called once for a line, a thing or a player

interface

uses
  doomdef,
  doomdata,
  d_player,
  info_h,
  m_fixed,
  p_mobj_h,
  r_defs,
  DelphiDoom.Automap.Types;

const
  REDS = 12 * 8;
  REDRANGE = 1;
  BLUES = (256 - (4 * 16)) + 8;
  BLUERANGE = 1;
  GREENS = 215;
  GREENRANGE = 2;
  TRACEGREEN = 211;
  GRAYS = 5 * 8;
  GRAYSRANGE = 1;
  BROWNS = 14 * 8;
  BROWNRANGE = 1;
  YELLOWS = 10 * 8;
  YELLOWRANGE = 1;
  WHITE = 255;

  { Automap colors }
  YOURCOLORS = WHITE;
  WALLCOLORS = 83;
  WALLRANGE = 8;
  TSWALLCOLORS = 40;
  TSWALLRANGE = 8;
  FDWALLCOLORS = 96;
  FDWALLRANGE = 8;
  CDWALLCOLORS = 107;
  CDWALLRANGE = 8;
  THINGCOLORS = GREENS;
  THINGRANGE = GREENRANGE;
  SECRETWALLCOLORS = WALLCOLORS;
  SECRETWALLRANGE = WALLRANGE;
  GRIDCOLORS = GRAYS + (GRAYSRANGE div 2);
  XHAIRCOLORS = GRAYS;

  AM_PLR1_COLOR = 157; // Blue
  AM_PLR2_COLOR = 177; // Red
  AM_PLR3_COLOR = 137; // Yellow
  AM_PLR4_COLOR = 198; // Green
  AM_PLR5_COLOR = 215; // Jade
  AM_PLR6_COLOR =  32; // White
  AM_PLR7_COLOR = 106; // Hazel
  AM_PLR8_COLOR = 234; // Purple
  AM_TR1_COLOR = 154; // Blue
  AM_TR2_COLOR = 176; // Red
  AM_TR3_COLOR = 136; // Yellow
  AM_TR4_COLOR = 197; // Green
  AM_TR5_COLOR = 211; // Jade
  AM_TR6_COLOR =  25; // White
  AM_TR7_COLOR = 106; // Hazel
  AM_TR8_COLOR = 233; // Purple

  /// <summary>Color of the arrow of the player, of the one of the cheat and of the trace of the player</summary>
  AM_OWN_ARROW_COLOR = WHITE;
  AM_OWN_CHEAT_ARROW_COLOR = WHITE;
  AM_OWN_TRACE_COLOR = TRACEGREEN;
  /// <summary>How many colors of the palette the trace of a player goes through</summary>
  AM_TRACE_COLOR_RANGE = 4;
  /// <summary>The palette index of the background of the automap</summary>
  AM_BACKGROUND_COLOR = 90;

type
  /// <summary>The rules of the automap of Hexen: colors and figures, nothing is drawn here</summary>
  TAutomapGameRules = class sealed
  public
    /// <summary>The palette index of the background of the automap (the software renderer)</summary>
    class function BackgroundIndex: Integer; static;
    /// <summary>The color of the background of the automap for the OpenGL renderer ()</summary>
    class function GlBackgroundColor: LongWord; static;
    /// <summary>
    ///   The color of a line that the player has seen (or of any line with the cheat) and that is not
    ///   hidden; False when the line is not drawn
    /// </summary>
    class function MappedWallColor(const ALine: Pline_t; const ACheating, ALightLevel: Integer;
      out AColor: Integer): Boolean; static;
    /// <summary>True when the lines that the player has not seen are drawn (the map of the level)</summary>
    class function ShowsAllMapLines(const AHasAllMapPower: Boolean; const AGameMap: Integer): Boolean; static;
    /// <summary>The color of those lines</summary>
    class function AllMapWallColor: Integer; static;
    /// <summary>True when the things are drawn (the cheat twice)</summary>
    class function ShowsThings(const ACheating: Integer; const AHasAllMapPower: Boolean): Boolean; static;
    /// <summary>How a thing is drawn: figure, color, scale of the figure</summary>
    class procedure DescribeThing(const AThing: Pmobj_t; const ALightLevel: Integer;
      out AStyle: TAutomapThingStyle); static;
    /// <summary>The color of the arrow of another player (a network game) and the one of its trace</summary>
    class procedure OtherPlayerColors(const AIndex: Integer; const APlayer: Pplayer_t;
      out AColor, ATraceColor: Integer); static;
  end;

implementation

uses
  v_video;

class function TAutomapGameRules.BackgroundIndex: Integer;
begin
  Result := AM_BACKGROUND_COLOR;
end;

class function TAutomapGameRules.GlBackgroundColor: LongWord;
begin
  Result := videopal[AM_BACKGROUND_COLOR];
end;

class function TAutomapGameRules.MappedWallColor(const ALine: Pline_t; const ACheating, ALightLevel: Integer;
  out AColor: Integer): Boolean;
begin
  Result := True;
  if ALine.backsector = nil then
    AColor := WALLCOLORS + ALightLevel
  else if (ALine.special = 13) or (ALine.special = 83) then
    AColor := 198 // Locked door line -- all locked doors are greed
  else if (ALine.special = 70) or (ALine.special = 71) then
    AColor := 157 // intra-level teleports are blue
  else if (ALine.special = 74) or (ALine.special = 75) then
    AColor := 177 // intra-level teleports are blue
  else if ALine.flags and ML_SECRET <> 0 then // secret door
  begin
    if ACheating <> 0 then
      AColor := SECRETWALLCOLORS + ALightLevel
    else
      AColor := WALLCOLORS + ALightLevel;
  end
  else if ALine.backsector.floorheight <> ALine.frontsector.floorheight then
    AColor := FDWALLCOLORS + ALightLevel // floor level change
  else if ALine.backsector.ceilingheight <> ALine.frontsector.ceilingheight then
    AColor := CDWALLCOLORS + ALightLevel // ceiling level change
  else if ACheating <> 0 then
    AColor := TSWALLCOLORS + ALightLevel
  else
    Result := False;
end;

class function TAutomapGameRules.ShowsAllMapLines(const AHasAllMapPower: Boolean; const AGameMap: Integer): Boolean;
begin
  Result := AHasAllMapPower;
end;

class function TAutomapGameRules.AllMapWallColor: Integer;
begin
  Result := GRAYS + 3;
end;

class function TAutomapGameRules.ShowsThings(const ACheating: Integer; const AHasAllMapPower: Boolean): Boolean;
begin
  Result := ACheating = 2;
end;

class procedure TAutomapGameRules.DescribeThing(const AThing: Pmobj_t; const ALightLevel: Integer;
  out AStyle: TAutomapThingStyle);
begin
  AStyle.Shape := atsThinTriangle;
  AStyle.Scale := 16 * FRACUNIT;
  if (AThing.sprite >= Ord(SPR_KEY1)) and (AThing.sprite <= Ord(SPR_KEYB)) then
  begin
    AStyle.Shape := atsKeySquare;
    AStyle.Scale := 0;
    AStyle.Color := THINGCOLORS + ALightLevel;
  end
  else if (AThing.flags2_ex and MF2_EX_FRIEND <> 0) or (AThing.player <> nil) then
    AStyle.Color := WHITE
  else
    AStyle.Color := THINGCOLORS + ALightLevel;
end;

class procedure TAutomapGameRules.OtherPlayerColors(const AIndex: Integer; const APlayer: Pplayer_t;
  out AColor, ATraceColor: Integer);
const
  their_colors: array[0..MAXPLAYERS - 1] of integer = (
    AM_PLR1_COLOR,
    AM_PLR2_COLOR,
    AM_PLR3_COLOR,
    AM_PLR4_COLOR,
    AM_PLR5_COLOR,
    AM_PLR6_COLOR,
    AM_PLR7_COLOR,
    AM_PLR8_COLOR
  );
  trace_colors: array[0..MAXPLAYERS - 1] of integer = (
    AM_TR1_COLOR,
    AM_TR2_COLOR,
    AM_TR3_COLOR,
    AM_TR4_COLOR,
    AM_TR5_COLOR,
    AM_TR6_COLOR,
    AM_TR7_COLOR,
    AM_TR8_COLOR
  );
begin
  AColor := their_colors[AIndex];
  ATraceColor := trace_colors[AIndex];
  if APlayer.mo <> nil then
    if APlayer.mo.flags and (MF_SHADOW or MF_ALTSHADOW) <> 0 then
    begin
      AColor := 111; // *close* to background
      ATraceColor := 111;
    end;
end;

end.
