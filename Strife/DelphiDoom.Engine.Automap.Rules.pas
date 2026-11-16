{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of the automap of Strife                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Automap.Rules;

// What differs from game to game in the drawing of the automap (the colors, the color of a wall, the
// figure of a thing, the colors of the other players) is here; the loops over the lines, the things
// and the players are in am_map. Strife has this unit; Doom, Heretic and Hexen have one with the
// same name in their own folders (the project picks it by its path, like the rules of p_map and
// p_mobj). The functions are static and are called once for a line, a thing or a player

interface

uses
  doomdef,
  doomdata,
  d_player,
  m_fixed,
  p_mobj_h,
  r_defs,
  DelphiDoom.Automap.Types;

const
  GRAYS = 1;
  GRAYSRANGE = 15;

  { Automap colors }
  BACKGROUND = 240;         // haleyjd [STRIFE]
  WALLCOLORS = 5;           // villsa [STRIFE]
  WALLRANGE = 16;
  TSWALLCOLORS = 16;
  FDWALLCOLORS = 122;       // villsa [STRIFE]
  CDWALLCOLORS = 116;
  CTWALLCOLORS = 19;        // villsa [STRIFE]
  SPWALLCOLORS = 243;       // villsa [STRIFE]
  THINGCOLORS = 233;        // villsa [STRIFE]
  MISSILECOLORS = 227;      // villsa [STRIFE]
  SHOOTABLECOLORS = 235;    // villsa [STRIFE]

  // JVAL: We keep grid in DelphiStrife
  GRIDCOLORS = GRAYS + (GRAYSRANGE div 2);
  XHAIRCOLORS = GRAYS;

  /// <summary>Color of the arrow of the player, of the one of the cheat and of the trace of the player</summary>
  AM_OWN_ARROW_COLOR = 224;
  AM_OWN_CHEAT_ARROW_COLOR = 224;
  AM_OWN_TRACE_COLOR = 224;
  /// <summary>How many colors of the palette the trace of a player goes through</summary>
  AM_TRACE_COLOR_RANGE = 8;
  /// <summary>The palette index of the background of the automap</summary>
  AM_BACKGROUND_COLOR = BACKGROUND;

type
  /// <summary>The rules of the automap of Strife: colors and figures, nothing is drawn here</summary>
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
  if (ALine.special = 145) or (ALine.special = 186) then
    AColor := SPWALLCOLORS
  else if ALine.backsector = nil then
    AColor := WALLCOLORS
  else if ALine.special = 39 then
    AColor := WALLCOLORS + WALLRANGE div 2 // teleporters
  else if ALine.flags and ML_SECRET <> 0 then // secret door
    AColor := WALLCOLORS + ALightLevel
  else if ALine.backsector.floorheight <> ALine.frontsector.floorheight then
    AColor := FDWALLCOLORS // floor level change
  else if ALine.backsector.ceilingheight <> ALine.frontsector.ceilingheight then
    AColor := CDWALLCOLORS // ceiling level change
  else if ACheating <> 0 then
    AColor := TSWALLCOLORS
  else
    Result := False;
end;

class function TAutomapGameRules.ShowsAllMapLines(const AHasAllMapPower: Boolean; const AGameMap: Integer): Boolean;
begin
  Result := AHasAllMapPower or (AGameMap = 15);
end;

class function TAutomapGameRules.AllMapWallColor: Integer;
begin
  Result := CTWALLCOLORS;
end;

class function TAutomapGameRules.ShowsThings(const ACheating: Integer; const AHasAllMapPower: Boolean): Boolean;
begin
  Result := (ACheating = 2) or AHasAllMapPower;
end;

class procedure TAutomapGameRules.DescribeThing(const AThing: Pmobj_t; const ALightLevel: Integer;
  out AStyle: TAutomapThingStyle);
begin
  AStyle.Shape := atsThinTriangle;
  AStyle.Scale := AThing.radius;
  if AThing.flags and (MF_MISSILE or MF_SPECIAL) <> 0 then
    AStyle.Color := MISSILECOLORS
  else if AThing.flags and MF_COUNTKILL <> 0 then
    AStyle.Color := SHOOTABLECOLORS
  else
  begin
    AStyle.Color := THINGCOLORS;
    AStyle.Scale := 16 * FRACUNIT;
  end;

  if AThing.flags2_ex and MF2_EX_FRIEND <> 0 then
    AStyle.Color := GRAYS;
end;

class procedure TAutomapGameRules.OtherPlayerColors(const AIndex: Integer; const APlayer: Pplayer_t;
  out AColor, ATraceColor: Integer);
const
  their_colors: array[0..MAXPLAYERS] of integer = ($80, $40, $B0, $10, $30, $50, $A0, $60, $90);
begin
  if APlayer.powers[Ord(pw_invisibility)] <> 0 then
    AColor := 27 // *close* to black
  else
    AColor := their_colors[AIndex];
  ATraceColor := AColor;
end;

end.
