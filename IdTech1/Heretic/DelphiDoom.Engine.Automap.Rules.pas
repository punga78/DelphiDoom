{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of the automap of Heretic                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Automap.Rules;

// What differs from game to game in the drawing of the automap (the colors, the color of a wall, the
// figure of a thing, the colors of the other players) is here; the loops over the lines, the things
// and the players are in am_map. Heretic has this unit; Doom, Hexen and Strife have one with the
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
  GREENS = 216;
  GREENRANGE = 8;
  GRAYS = 5 * 8;
  GRAYSRANGE = 1;
  BROWNS = 14 * 8;
  BROWNRANGE = 1;
  YELLOWS = 10 * 8;
  YELLOWRANGE = 1;
  WHITE = 35;

  { Automap colors }
  YOURCOLORS = WHITE;
  WALLCOLORS = REDS;
  WALLRANGE = REDRANGE;
  TSWALLCOLORS = GRAYS;
  TSWALLRANGE = GRAYSRANGE;
  FDWALLCOLORS = BROWNS;
  FDWALLRANGE = BROWNRANGE;
  CDWALLCOLORS = YELLOWS;
  CDWALLRANGE = YELLOWRANGE;
  THINGCOLORS = GREENS;
  THINGRANGE = GREENRANGE;
  SECRETWALLCOLORS = WALLCOLORS;
  SECRETWALLRANGE = WALLRANGE;
  GRIDCOLORS = GRAYS + (GRAYSRANGE div 2);
  XHAIRCOLORS = GRAYS;

  BLUEKEYCOLOR = 197;
  YELLOWKEYCOLOR = 144;
  GREENKEYCOLOR = 220;

  /// <summary>Color of the arrow of the player, of the one of the cheat and of the trace of the player</summary>
  AM_OWN_ARROW_COLOR = WHITE;
  AM_OWN_CHEAT_ARROW_COLOR = WHITE;
  AM_OWN_TRACE_COLOR = GREENS;
  /// <summary>How many colors of the palette the trace of a player goes through</summary>
  AM_TRACE_COLOR_RANGE = 4;
  /// <summary>The palette index of the background of the automap</summary>
  AM_BACKGROUND_COLOR = 104;

type
  /// <summary>The rules of the automap of Heretic: colors and figures, nothing is drawn here</summary>
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
  else if ALine.special = 39 then
    AColor := WALLCOLORS + WALLRANGE div 2 // teleporters
  else if ALine.flags and ML_SECRET <> 0 then // secret door
  begin
    if ACheating <> 0 then
      AColor := SECRETWALLCOLORS + ALightLevel
    else
      AColor := WALLCOLORS + ALightLevel;
  end
  else if (ALine.special = 26) or (ALine.special = 32) then
    AColor := BLUEKEYCOLOR
  else if (ALine.special = 27) or (ALine.special = 34) then
    AColor := YELLOWKEYCOLOR
  else if (ALine.special = 28) or (ALine.special = 33) then
    AColor := GREENKEYCOLOR
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
  if AThing._type = Ord(MT_CKEY) then
  begin
    AStyle.Shape := atsKeySquare;
    AStyle.Scale := 0;
    AStyle.Color := YELLOWKEYCOLOR;
  end
  else if AThing._type = Ord(MT_AKYY) then
  begin
    AStyle.Shape := atsKeySquare;
    AStyle.Scale := 0;
    AStyle.Color := GREENKEYCOLOR;
  end
  else if AThing._type = Ord(MT_BKYY) then
  begin
    AStyle.Shape := atsKeySquare;
    AStyle.Scale := 0;
    AStyle.Color := BLUEKEYCOLOR;
  end
  else if (AThing.flags2_ex and MF2_EX_FRIEND <> 0) or (AThing.player <> nil) then
    AStyle.Color := WHITE
  else
    AStyle.Color := THINGCOLORS + ALightLevel;
end;

class procedure TAutomapGameRules.OtherPlayerColors(const AIndex: Integer; const APlayer: Pplayer_t;
  out AColor, ATraceColor: Integer);
const
  their_colors: array[0..MAXPLAYERS - 1] of integer = (GREENS, GRAYS, BROWNS, REDS);
begin
  if APlayer.powers[Ord(pw_invisibility)] <> 0 then
    AColor := 99 // *close* to background
  else
    AColor := their_colors[AIndex];
  ATraceColor := AColor;
end;

end.
