{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the drawing of the heads-up display                    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Hud.Drawer;

{$I Doom32.inc}

interface

uses
  r_defs,
  DelphiDoom.Hud.Types,
  DelphiDoom.Hud.TextLine,
  DelphiDoom.Hud.Layout,
  DelphiDoom.Hud.View,
  DelphiDoom.Engine.Hud.Intf,
  DelphiDoom.Engine.Hud.Environment;

type
  /// <summary>
  ///   HU_Drawer, HU_Erase and the drawing of the widgets (HUlib_drawTextLine and the others): reads
  ///   the model through IHudView, lets Libs\Hud say where each glyph goes and calls V_DrawPatch
  ///   for it. The class is sealed and has no virtual method: a frame crosses the contract of
  ///   the screen once and then only calls routines of the engine, so no glyph is drawn through an
  ///   interface
  /// </summary>
  TEngineHudDrawer = class sealed(TInterfacedObject, IHudScreen)
  strict private
    FView: IHudView;
    FEnvironment: TEngineHudEnvironment;
    FLayout: THudLayout;
    FWidths: THudFontWidths;
    FCrosshairs: array[0..4] of Ppatch_t;
    FHeight: Integer;
{$IFDEF STRIFE}
    FYellowWidths: THudFontWidths;
{$ENDIF}
{$IFDEF DOOM}
    FTranslationLump: Integer;
{$ENDIF}
    procedure ReadWidths(const AFont: Ppatch_tPArray; const ACount: Integer; var AWidths: THudFontWidths);
    procedure DrawTextLine(const ALine: THudTextLine; const ACursor: Boolean);
    procedure EraseTextLine(const ALine: THudTextLine);
    procedure DrawMessages;
    procedure DrawFramesPerSecond;
    procedure DrawAimingCrosshair;
{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}
    procedure DrawDemoProgress;
{$ENDIF}
{$IFDEF DOOM}
    procedure WriteText(const AX, AY: Integer; const AText: string; const AHighlightDigits: Boolean);
    procedure DrawAutomapStatistics;
{$ENDIF}
  public
    /// <summary>A drawing that reads the model through AView and the player through AEnvironment</summary>
    constructor Create(const AView: IHudView; const AEnvironment: TEngineHudEnvironment);
    destructor Destroy; override;
    procedure Initialize;
    procedure Draw;
    procedure Erase;
    function Height: Integer;
{$IFDEF STRIFE}
    procedure DrawYellowText(const AX, AY: Integer; const AText: string; const AScreen: Integer);
{$ENDIF}
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  doomdef,
  doomstat,
  d_player,
  g_game,
  m_fixed,
  p_tick,
  p_mobj_h,
{$IFDEF DOOM}
  m_menu,
  st_stuff,
{$ENDIF}
  w_wad,
  z_zone,
  am_map,
  hu_stuff,
  r_draw,
  r_main,
  v_data,
  v_video,
{$IFDEF RADIX}
  radix_fonts,
{$ENDIF}
  DelphiDoom.Hud.ScrollingText,
  DelphiDoom.Hud.TextLayout,
  DelphiDoom.Hud.Crosshair;

const
  // glyphs of the small font that the text lines can reach: from '!' to '_' (the cursor)
  LINE_GLYPHS = Ord('_') - Ord(HU_FONTSTART) + 1;
  // the last character a text line writes with a glyph ('_', Strife stops before it)
{$IFDEF STRIFE}
  LINE_LAST_CHAR = Ord('_') - 1;
{$ELSE}
  LINE_LAST_CHAR = Ord('_');
{$ENDIF}

function ScreenWidthOfLines: Integer; inline;
begin
{$IFDEF OPENGL}
  Result := V_GetScreenWidth(SCN_FG);
{$ELSE}
  Result := 320;
{$ENDIF}
end;

{ TEngineHudDrawer }

constructor TEngineHudDrawer.Create(const AView: IHudView; const AEnvironment: TEngineHudEnvironment);
begin
  inherited Create;
  if not Assigned(AView) then
    raise EArgumentNilException.Create('The drawing of the heads-up display needs the view');
  if not Assigned(AEnvironment) then
    raise EArgumentNilException.Create('The drawing of the heads-up display needs the environment');
  FView := AView;
  FEnvironment := AEnvironment;
  FLayout := THudLayout.Create;
{$IFDEF DOOM}
  FTranslationLump := -2;
{$ENDIF}
end;

destructor TEngineHudDrawer.Destroy;
begin
  FLayout.Free;
  inherited Destroy;
end;

procedure TEngineHudDrawer.ReadWidths(const AFont: Ppatch_tPArray; const ACount: Integer;
  var AWidths: THudFontWidths);
var
  LIndex: Integer;
begin
  AWidths.Count := ACount;
  for LIndex := 0 to ACount - 1 do
    if AFont[LIndex] <> nil then
      AWidths.Width[LIndex] := AFont[LIndex].width
    else
      AWidths.Width[LIndex] := 0;
end;

procedure TEngineHudDrawer.Initialize;
var
  LIndex: Integer;
begin
  // the text lines reach the glyph of the underscore even if the font is shorter (Heretic and
  // Hexen: the old code read the pointers that follow the array, the next fonts)
  if HU_FONTSIZE > LINE_GLYPHS then
    ReadWidths(@hu_font, HU_FONTSIZE, FWidths)
  else
    ReadWidths(@hu_font, LINE_GLYPHS, FWidths);
{$IFDEF STRIFE}
  ReadWidths(@yfont, HU_FONTSIZE, FYellowWidths);
{$ENDIF}
  for LIndex := 0 to 4 do
{$IFDEF RADIX}
    // the system WAD of Radix has no crosshairs of the engine (the cockpit draws its own)
    FCrosshairs[LIndex] := W_CacheLumpNum(RX_LumpNumOrEmpty('XCROSS' + itoa(LIndex)), PU_STATIC);
{$ELSE}
    FCrosshairs[LIndex] := W_CacheLumpName('XCROSS' + itoa(LIndex), PU_STATIC);
{$ENDIF}
end;

procedure TEngineHudDrawer.DrawTextLine(const ALine: THudTextLine; const ACursor: Boolean);
var
  LIndex: Integer;
  LGlyphs: TArray<THudGlyph>;
begin
  THudTextLayout.Line(ALine, FWidths, ScreenWidthOfLines, LINE_LAST_CHAR, ACursor, FLayout);
  LGlyphs := FLayout.Glyphs;
  for LIndex := 0 to FLayout.Count - 1 do
    V_DrawPatch(LGlyphs[LIndex].X, LGlyphs[LIndex].Y, SCN_FG, hu_font[LGlyphs[LIndex].Index],
      {$IFDEF OPENGL}false{$ELSE}true{$ENDIF});
  // draw the cursor if requested
  if FLayout.CursorFits then
    V_DrawPatch(FLayout.CursorX, FLayout.CursorY, SCN_FG,
      Ppatch_tPArray(@hu_font)[Ord('_') - ALine.StartChar], true);
end;

procedure TEngineHudDrawer.EraseTextLine(const ALine: THudTextLine);
var
  lh: integer;
  y: integer;
  yoffset: integer;
begin
  // Only erases when NOT in automap and the screen is reduced,
  // and the text must either need updating or refreshing
  // (because of a recent change back from the automap)
  if (amstate <> am_only) and (viewwindowx <> 0) and (ALine.NeedsUpdate <> 0) then
  begin
    lh := hu_font[0].height + 1;
    lh := lh * HUD_MAX_LINE_ROWS;
    y := V_PreserveY(ALine.Y);
    yoffset := y * SCREENWIDTH;
    while y < V_PreserveY(ALine.Y) + V_PreserveY(lh) + 1 do
    begin
      if (y < viewwindowy) or (y >= viewwindowy + viewheight) then
        {$IFDEF OPENGL}
        R_VideoErase(V_PreserveGLY(yoffset), GLDRAWWIDTH) // erase entire line
        {$ELSE}
        R_VideoErase(yoffset, SCREENWIDTH) // erase entire line
        {$ENDIF}
      else
      begin
        // erase left border
        {$IFDEF OPENGL}
        R_VideoErase(V_PreserveGLY(yoffset), V_PreserveGLX(viewwindowx));
        // erase right border     asfa
        R_VideoErase(V_PreserveGLY(yoffset + viewwindowx + viewwidth), V_PreserveGLX(viewwindowx));
        {$ELSE}
        R_VideoErase(yoffset, viewwindowx);
        // erase right border
        R_VideoErase(yoffset + viewwindowx + viewwidth, viewwindowx);
        {$ENDIF}
      end;
      inc(y);
      yoffset := yoffset + SCREENWIDTH;
    end;
  end;

  ALine.ConsumePass;
end;

procedure TEngineHudDrawer.DrawMessages;
var
  LWindow: THudScrollingText;
  LLine: THudTextLine;
  LIndex: Integer;
{$IF DEFINED(OPENGL) AND NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  LRows: Integer;
  LCharIndex: Integer;
{$ENDIF}
begin
  if not FView.MessageVisible then
    Exit; // if not on, don't draw
  LWindow := FView.MessageWindow;
  // draw everything
  for LIndex := 0 to LWindow.Height - 1 do
  begin
    LLine := LWindow.LineBack(LIndex);
    DrawTextLine(LLine, false); // no cursor, please
{$IF DEFINED(OPENGL) AND NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
    LRows := 0;
    for LCharIndex := 0 to LLine.Length - 1 do
      if LLine.CharAt(LCharIndex) = #10 then
        inc(LRows);
    if LRows * 10 > FHeight then
      FHeight := LRows * 10;
{$ENDIF}
  end;
end;

procedure TEngineHudDrawer.DrawFramesPerSecond;
var
  i: integer;
  x, y: integer;
  c: integer;
  LText: string;
begin
  LText := FView.FpsText;
{$IFDEF OPENGL}
  x := V_GetScreenWidth(SCN_FG) - 9;
  y := 1;
  for i := length(LText) downto 1 do
  begin
    if LText[i] <> ' ' then
    begin
      c := Ord(toupper(LText[i])) - Ord(HU_FONTSTART);
      V_DrawPatch(x, y, SCN_FG, hu_font[c], false);
      x := x - 8;
    end
    else
      x := x - 4;
  end;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  FHeight := FHeight + 9;
{$ENDIF}
{$ELSE}
  if amstate = am_only then
  begin
    x := 311;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    y := 0;
{$ELSE}
    y := 1;
{$ENDIF}
  end
  else
  begin
    x := (viewwindowx + viewwidth) * 320 div SCREENWIDTH - 9;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    y := viewwindowy * 200 div SCREENHEIGHT;
{$ELSE}
    y := viewwindowy * 200 div SCREENHEIGHT + 1;
{$ENDIF}
  end;
  for i := length(LText) downto 1 do
  begin
    if LText[i] <> ' ' then
    begin
      c := Ord(toupper(LText[i])) - Ord(HU_FONTSTART);
      V_DrawPatch(x, y, SCN_FG, hu_font[c], true);
      x := x - 8;
    end
    else
      x := x - 4;
  end;
{$ENDIF}
end;

procedure TEngineHudDrawer.DrawAimingCrosshair;
var
  plr: Pplayer_t;
  target: THudCrosshairTarget;
  cidx: integer;
  dx: integer;
  p: Ppatch_t;
begin
  if not drawcrosshair then
    exit;

  if (amstate = am_only) or (amstate = am_overlay) then
    exit;

  plr := FEnvironment.Player;
  if plr = nil then
    exit;

  if plr.playerstate = PST_DEAD then
    exit;

{$IFDEF HEXEN}
  if plr.morphTics <> 0 then
    exit;

{$ENDIF}
  if plr.plinetarget = nil then
    target := THudCrosshairTarget.None
{$IFDEF STRIFE}
  else if plr.plinetarget.flags and MF_ALLY <> 0 then
    target := THudCrosshairTarget.Friend
{$ENDIF}
  else if plr.plinetarget.flags2_ex and MF2_EX_FRIEND <> 0 then
    target := THudCrosshairTarget.Friend
  else
    target := THudCrosshairTarget.Enemy;
  cidx := THudCrosshair.PatchIndex(target, leveltime, plr.pcrosstic);
  dx := THudCrosshair.OffsetX(plr.lookdir2, viewwidth);

  p := FCrosshairs[cidx];
  if screenblocks > 10 then
    V_DrawPatch(160 + dx, 100, SCN_FG, p, true)
  else
    V_DrawPatch(160 + dx, 84, SCN_FG, p, true);
end;

{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}

//==============================================================================
// DrawDemoProgress
//
// 19/9/2009 JVAL: For drawing demo progress
//
//==============================================================================
procedure TEngineHudDrawer.DrawDemoProgress;
var
  dp: Ppatch_t;
  i: integer;
  x, y: integer;
begin
  dp := W_CacheLumpName('DEMOTIME', PU_STATIC);
  x := viewwindowx{$IFDEF OPENGL} * 320 div SCREENWIDTH{$ENDIF};
  y := (viewwindowy + viewheight){$IFDEF OPENGL} * 200 div SCREENHEIGHT{$ENDIF};
{$IFDEF OPENGL}
  i := round(G_DemoProgress * viewwidth / SCREENWIDTH * 320 / FRACUNIT);
{$ELSE}
  i := G_DemoProgress * viewwidth div FRACUNIT;
{$ENDIF}
  while i > 0 do
  begin
    V_DrawPatchTransparent(x, y, SCN_FG, dp, {$IFDEF OPENGL}true{$ELSE}false{$ENDIF});
    i := i - dp.width;
    x := x + dp.width;
  end;
  Z_ChangeTag(dp, PU_CACHE);
end;
{$ENDIF}

{$IFDEF DOOM}

//==============================================================================
// WriteText
// Write a string using the hu_font, use white for numeric characters
//
//==============================================================================
procedure TEngineHudDrawer.WriteText(const AX, AY: Integer; const AText: string;
  const AHighlightDigits: Boolean);
var
  LIndex: Integer;
  LGlyphs: TArray<THudGlyph>;
  oldtranslation, newtranslation: PByteArray;
begin
  if Length(AText) = 0 then
    exit;

  THudTextLayout.Highlighted(AText, AX, AY, FWidths, Ord(HU_FONTSTART), 12, 320,
    AHighlightDigits, FLayout);

  if FTranslationLump < 0 then
    FTranslationLump := W_GetNumForName('TRN_MENU');

  oldtranslation := v_translation;
  newtranslation := W_CacheLumpNum(FTranslationLump, PU_STATIC);

  LGlyphs := FLayout.Glyphs;
  for LIndex := 0 to FLayout.Count - 1 do
  begin
    if LGlyphs[LIndex].Highlighted then
      v_translation := newtranslation
    else
      v_translation := oldtranslation;

    V_DrawPatch(LGlyphs[LIndex].X, LGlyphs[LIndex].Y, SCN_FG, hu_font[LGlyphs[LIndex].Index], true);
  end;

  Z_ChangeTag(newtranslation, PU_CACHE);
  v_translation := oldtranslation;
end;

procedure TEngineHudDrawer.DrawAutomapStatistics;
const
  XOFFS = 320 - 2;
  YOFFS = ST_Y - 1;
var
  plr: Pplayer_t;
  s1, s2, s3: string;
  x, y: integer;
begin
  if not amdrawstats then
    exit;

  plr := FEnvironment.Player;
  if plr = nil then
    exit;

  sprintf(s1, 'Kills: %d/%d', [plr.killcount, totalkills]);
  sprintf(s2, 'Items: %d/%d', [plr.itemcount, totalitems]);
  sprintf(s3, 'Secrets: %d/%d', [plr.secretcount, totalsecret]);

  x := XOFFS - Max3I(M_StringWidth(s1), M_StringWidth(s2), M_StringWidth(s3));
  y := YOFFS - M_StringHeight(s3);
  WriteText(x, y, s3, True);

  y := y - M_StringHeight(s2);
  WriteText(x, y, s2, True);

  y := y - M_StringHeight(s1);
  WriteText(x, y, s1, True);
end;
{$ENDIF}

procedure TEngineHudDrawer.Draw;
begin
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
{$IFDEF OPENGL}
  FHeight := 0;
{$ENDIF}
{$ENDIF}
  if drawfps then
    DrawFramesPerSecond;
{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}
  if demoplayback and showdemoplaybackprogress then
    DrawDemoProgress;

{$ENDIF}
  DrawAimingCrosshair;
  DrawMessages;
  if FView.ChatVisible then
    DrawTextLine(FView.ChatLine.Line, true); // draw the line w/ cursor
  if amstate = am_only then
  begin
    FView.UpdateLevelTime(leveltime);
    DrawTextLine(FView.LevelTime, false);
    DrawTextLine(FView.Title, false);
{$IFDEF DOOM}

    // JVAL: 20220501 - Draw automap stats (https://www.doomworld.com/forum/topic/92113-delphidoom-207734-udmf-umapinfo-mbf21-apr-28-2022/?do=findComment&comment=2488715)
    DrawAutomapStatistics;
{$ENDIF}
  end;
end;

procedure TEngineHudDrawer.Erase;
var
  LWindow: THudScrollingText;
  LIndex: Integer;
begin
  LWindow := FView.MessageWindow;
  LWindow.PrepareErase(FView.MessageVisible);
  for LIndex := 0 to LWindow.Height - 1 do
    EraseTextLine(LWindow.Lines[LIndex]);
  FView.ChatLine.PrepareErase(FView.ChatVisible);
  EraseTextLine(FView.ChatLine.Line);
  EraseTextLine(FView.Title);
end;

function TEngineHudDrawer.Height: Integer;
begin
  Result := FHeight;
end;

{$IFDEF STRIFE}
procedure TEngineHudDrawer.DrawYellowText(const AX, AY: Integer; const AText: string;
  const AScreen: Integer);
var
  LIndex: Integer;
  LGlyphs: TArray<THudGlyph>;
begin
  THudTextLayout.Wrapped(AText, AX, AY, FYellowWidths, Ord(HU_FONTSTART), 12, 320 - 20, FLayout);
  LGlyphs := FLayout.Glyphs;
  for LIndex := 0 to FLayout.Count - 1 do
    V_DrawPatch(LGlyphs[LIndex].X, LGlyphs[LIndex].Y, AScreen, yfont[LGlyphs[LIndex].Index],
      AScreen = SCN_FG);
end;
{$ENDIF}

end.
