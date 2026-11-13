{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the old code            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// The code of Base\hu_lib.pas and Base\hu_stuff.pas as it was before issue #185 (commit
// 138347fd), copied line by line: the widgets as records, the message and chat logic, the
// frame counter and the keyboard tables. Only the world around it is replaced by the variables
// below (the players, the keys, the strings, the drawing that writes a log), so that the old and
// the new code can be run side by side on the same inputs. The Doom branch is the one compiled.
{$DEFINE DOOM}
unit DelphiDoom.Tests.Hud.Legacy;

interface

uses
  d_delphi;

const
  KEY_ESCAPE = 27;
  KEY_ENTER = 13;
  KEY_BACKSPACE = 127;
  KEY_RSHIFT = $80 + $36;
  KEY_RALT = $80 + $38;
  KEY_LALT = KEY_RALT;
  TICRATE = 35;
  FRACUNIT = 65536;
  MAXPLAYERS = 4;
  SCN_FG = 0;
  HU_FONTSTART = '!';
  HU_FONTEND = '_';
  HU_FONTSIZE = (Ord(HU_FONTEND) - Ord(HU_FONTSTART)) + 1;
  HU_BROADCAST = 5;
  HU_MSGREFRESH = KEY_ENTER;
  HU_MSGX = 0;
  HU_MSGY = 0;
  HU_MSGHEIGHT = 1; // in lines
  HU_MSGTIMEOUT = 4 * TICRATE;
  FPSSIZE = 128;
  FPSSIZE2 = 512;
  HUSTR_TALKTOSELF1 = 'You mumble to yourself';
  HUSTR_TALKTOSELF2 = 'Who''s there?';
  HUSTR_TALKTOSELF3 = 'You scare yourself';
  HUSTR_TALKTOSELF4 = 'You start to rave';
  HUSTR_TALKTOSELF5 = 'You''ve lost it...';
  HUSTR_MSGU = '[Message unsent]';
  ev_keydown = 0;
  ev_keyup = 1;

{ HU_MAXLINES, HU_MAXLINELINESS, HU_MAXLINELENGTH }
  HU_MAXLINES = 4;
  HU_MAXLINELINESS = 4;
  HU_MAXLINELENGTH = HU_MAXLINELINESS * 80;

type
  patch_t = record
    width: smallint;
    height: smallint;
  end;
  Ppatch_t = ^patch_t;
  patch_tPArray = packed array[0..$FFFF] of Ppatch_t;
  Ppatch_tPArray = ^patch_tPArray;

  Tevent_t = record
    _type: integer;
    data1: integer;
  end;
  Pevent_t = ^Tevent_t;

  Tlegacycmd_t = record
    chatchar: byte;
  end;

  Tlegacyplayer_t = record
    _message: string;
    cmd: Tlegacycmd_t;
  end;
  Plegacyplayer_t = ^Tlegacyplayer_t;

  TLegacyByteArray = array[0..255] of byte;
  PByteArray = ^TLegacyByteArray;
  menupos_t = record
    x: integer;
    y: integer;
  end;

  Tlegacylanguage_t = (english, french);
  Tlegacygamemode_t = (shareware, registered, retail, commercial);
  Tlegacysfx_t = (sfx_tink, sfx_radio);

type
  hu_textline_t = record
    // left-justified position of scrolling text window
    x: integer;
    y: integer;

    font: Ppatch_tPArray; // font
    sc: integer; // start character
    line: array[0..(HU_MAXLINELENGTH + 1) - 1] of AnsiChar; // line of text
    len: integer; // current line length

    // whether this line needs to be udpated
    needsupdate: integer;
  end;
  Phu_textline_t = ^hu_textline_t;

// Scrolling Text window widget
//  (child of Text Line widget)

  hu_stext_t = record
    lines: array[0..HU_MAXLINES - 1] of hu_textline_t; // text lines to draw
    height: integer;      // height in lines
    curline: integer;     // current line number
    _on: Pboolean;        // pointer to boolean stating whether to update window
    laston: boolean;      // last value of *._on.
  end;
  Phu_stext_t = ^hu_stext_t;

// Input Text Line widget
//  (child of Text Line widget)
  hu_itext_t = record
    line: hu_textline_t;  // text line to input on
    lm: integer;          // left margin past which I am not to delete characters
    _on: Pboolean;        // pointer to boolean stating whether to update window
    laston: boolean;      // last value of *->on;
  end;
  Phu_itext_t = ^hu_itext_t;

var
  // the world around the old code (the globals of the engine, here under the same names)
  netgame: boolean;
  consoleplayer: integer;
  playeringame: array[0..MAXPLAYERS - 1] of boolean;
  players: array[0..MAXPLAYERS - 1] of Tlegacyplayer_t;
  language: Tlegacylanguage_t;
  gamemode: Tlegacygamemode_t;
  showMessages: integer;
  chat_macros: array[0..9] of string;
  destination_keys: array[0..MAXPLAYERS - 1] of string;
  player_names: array[0..3] of string;
  shiftxform: array[0..127] of Char;
  // the heads-up display of the old code
  hu_font: array[0..HU_FONTSIZE - 1] of Ppatch_t;
  yfont: array[0..HU_FONTSIZE - 1] of Ppatch_t;
  chat_on: boolean;
  message_on: boolean;
  message_dontfuckwithme: boolean;
  message_nottobefuckedwith: boolean;
  plr: Plegacyplayer_t;
  w_title: hu_textline_t;
  w_leveltime: hu_textline_t;
  w_chat: hu_itext_t;
  always_off: boolean = false;
  chat_dest: array[0..MAXPLAYERS - 1] of Char;
  w_inputbuffer: array[0..MAXPLAYERS - 1] of hu_itext_t;
  w_message: hu_stext_t;
  message_counter: integer;
  m_fps: string = '';
  fps_ticker: integer = 0;
  v_translation: PByteArray;
  // what the fake engine saw
  LegacyDrawLog: string;
  LegacyEchoLog: string;
  LegacySounds: string;
  LegacyFracTime: integer;

procedure HUlib_clearTextLine(t: Phu_textline_t);
procedure HUlib_initTextLine(t: Phu_textline_t; x: integer; y: integer; f: Ppatch_tPArray; sc: integer);
function HUlib_addCharToTextLine(t: Phu_textline_t; ch: char): boolean;
function HUlib_delCharFromTextLine(t: Phu_textline_t): boolean;
procedure HUlib_drawTextLine(l: Phu_textline_t; drawcursor: boolean);
procedure HUlib_drawYellowText(x, y: integer; txt: string; const scn: integer);
function HUlib_countLineLines(l: Phu_textline_t): integer;
procedure HUlib_initSText(s: Phu_stext_t; x: integer; y: integer; h: integer;
  font: Ppatch_tPArray; startchar: integer; _on: Pboolean);
procedure HUlib_addLineToSText(s: Phu_stext_t);
procedure HUlib_removeLineFromSText(s: Phu_stext_t);
procedure HUlib_addMessageToSText(s: Phu_stext_t; prefix: string; msg: string);
procedure HUlib_addMessageToSText2(s: Phu_stext_t; prefix: string; msg: string);
procedure HUlib_drawSText(s: Phu_stext_t);
procedure HUlib_initIText(it: Phu_itext_t; x: integer; y: integer; font: Ppatch_tPArray;
  startchar: integer; _on: Pboolean);
procedure HUlib_delCharFromIText(it: Phu_itext_t);
procedure HUlib_resetIText(it: Phu_itext_t);
function HUlib_keyInIText(it: Phu_itext_t; ch: byte): boolean;
procedure HUlib_drawIText(it: Phu_itext_t);
procedure HU_DoFPSStuff;
function HU_FPS: integer;
procedure HU_Ticker;
procedure HU_queueChatChar(c: char);
function HU_dequeueChatChar: char;
function HU_Responder(ev: Pevent_t): boolean;
function ForeignTranslation(ch: char): char;
function HU_WriteText(x, y: integer; const str: string; const highlightnums: boolean): menupos_t;

/// <summary>A font of fake patches: the glyph i is Widths[i] columns wide and has height i</summary>
procedure Legacy_MakeFonts(const AWidths: array of Integer);
/// <summary>The part of HU_Start that makes the widgets (the Doom title and level time positions)</summary>
procedure Legacy_Start(const ATitle: string);
/// <summary>Puts back the globals that the old code kept to itself (queue, shift and alt, tries, frame ring heads)</summary>
procedure Legacy_ResetState;
/// <summary>The part of HU_Init that chooses the keyboard map</summary>
procedure Legacy_Init;
/// <summary>The lines of HU_Drawer that write the time of the level (the automap)</summary>
procedure Legacy_UpdateLevelTime(const ALevelTime: Integer);
/// <summary>The part of HU_DrawCrossHair that chooses the patch: 0 if no target or a friend</summary>
function Legacy_CrosshairIndex(const AHasTarget, AFriend: Boolean; const ALevelTime, ACrossTic: Integer): Integer;
/// <summary>The offset of the crosshair of HU_DrawCrossHair</summary>
function Legacy_CrosshairOffset(const ALookDir, AViewWidth: Integer): Integer;
/// <summary>HU_TITLE of Doom with the names of the table</summary>
function Legacy_Title(const ANames: array of string; const AEpisode, AMap: Integer): string;
function Legacy_Title2(const ANames: array of string; const AMap: Integer): string;

implementation

uses
  System.SysUtils;

procedure printf(const Fmt: string; const Args: array of const);
begin
  LegacyEchoLog := LegacyEchoLog + Format(Fmt, Args);
end;

var
  LegacyWhiteTable: TLegacyByteArray;

procedure V_DrawPatch(x, y: integer; scrn: integer; patch: Ppatch_t; preserve: boolean);
begin
  LegacyDrawLog := LegacyDrawLog + Format('%d,%d,%d,%d,%d;',
    [x, y, patch.height, Ord(preserve), Ord(v_translation = @LegacyWhiteTable)]);
end;

const
  PU_STATIC = 1;
  PU_CACHE = 2;

function W_GetNumForName(const name: string): integer;
begin
  Result := 77;
end;

function W_CacheLumpNum(lump: integer; tag: integer): PByteArray;
begin
  Result := @LegacyWhiteTable;
end;

procedure Z_ChangeTag(p: pointer; tag: integer);
begin
end;

procedure S_StartSound(origin: pointer; sfx_id: integer);
begin
  LegacySounds := LegacySounds + IntToStr(sfx_id) + ';';
end;

function I_GetFracTime: integer;
begin
  Result := LegacyFracTime;
end;

const
  HU_INPUTTOGGLE: char = 't';
  HU_TITLEHEIGHT = 1;

procedure HUlib_clearTextLine(t: Phu_textline_t);
begin
  t.len := 0;
  t.line[0] := Chr(0);
  t.needsupdate := 1; //true;
end;

//==============================================================================
//
// HUlib_initTextLine
//
//==============================================================================
procedure HUlib_initTextLine(t: Phu_textline_t; x: integer; y: integer; f: Ppatch_tPArray; sc: integer);
begin
  t.x := x;
  t.y := y;
  t.font := f;
  t.sc := sc;
  HUlib_clearTextLine(t);
end;

//==============================================================================
//
// HUlib_addCharToTextLine
//
//==============================================================================
function HUlib_addCharToTextLine(t: Phu_textline_t; ch: char): boolean;
begin
  if t.len = HU_MAXLINELENGTH then
    result := false
  else
  begin
    t.line[t.len] := AnsiChar(ch);
    inc(t.len);
    t.line[t.len] := Chr(0);
    t.needsupdate := 4;
    result := true;
  end;
end;

//==============================================================================
//
// HUlib_delCharFromTextLine
//
//==============================================================================
function HUlib_delCharFromTextLine(t: Phu_textline_t): boolean;
begin
  if t.len = 0 then
    result := false
  else
  begin
    dec(t.len);
    t.line[t.len] := Chr(0);
    t.needsupdate := 4;
    result := true;
  end;
end;
procedure HUlib_drawTextLine(l: Phu_textline_t; drawcursor: boolean);
var
  i: integer;
  w: integer;
  x: integer;
  y: integer;
  c: AnsiChar;
begin
  // draw the new stuff
  x := l.x;
  y := l.y;
  for i := 0 to l.len - 1 do
  begin
    c := toupper(l.line[i]);
    if c = #10 then
      x := l.x
    else if c = #13 then
      y := y + 8
    else if c = ' ' then
    begin
      x := x + 4;
      if x >= {$IFDEF OPENGL}V_GetScreenWidth(SCN_FG){$ELSE}320{$ENDIF} then
        break;
    end
    else if (Ord(c) >= l.sc) and (c {$IFDEF STRIFE}<{$ELSE}<={$ENDIF} '_') then
    begin
      w := l.font[Ord(c) - l.sc].width;
      if x + w > {$IFDEF OPENGL}V_GetScreenWidth(SCN_FG){$ELSE}320{$ENDIF} then
        break;
      V_DrawPatch(x, y, SCN_FG, l.font[Ord(c) - l.sc], {$IFDEF OPENGL}false{$ELSE}true{$ENDIF});
      x := x + w;
    end;
  end;

  // draw the cursor if requested
  if drawcursor and (x + l.font[Ord('_') - l.sc].width <= {$IFDEF OPENGL}V_GetScreenWidth(SCN_FG){$ELSE}320{$ENDIF}) then
    V_DrawPatch(x, l.y, SCN_FG, l.font[Ord('_') - l.sc], true);
end;
procedure HUlib_drawYellowText(x, y: integer; txt: string; const scn: integer);
var
  i: integer;
  w: integer;
  c: char;
  len: integer;
  start_x: integer;
  patch: Ppatch_t;
  id: integer;
begin
  len := length(txt);
  start_x := x;
  for i := 1 to len do
  begin
    c := toupper(txt[i]);
    if c = #10 then
    begin
      x := start_x;
      continue;
    end
    else if c = #13 then
    begin
      y := y + 12;
      continue;
    end
    else if c = '_' then
      c := ' '
    else if (c = ' ') and (x = start_x) then // skip spaces at the start of a line
      continue;

    id := Ord(c) - Ord(HU_FONTSTART);
    if (id < 0) or (id >= Ord(HU_FONTSIZE)) then
    begin
      x := x + 4;
      continue;
    end;

    patch := yfont[id];
    w := patch.width;
    if x + w > 320 - 20 then
    begin // word warp
      x := start_x;
      y := y + 12;
    end;
    V_DrawPatch(x, y, scn, patch, scn = SCN_FG);
    x := x + w;
  end;
end;
function HUlib_countLineLines(l: Phu_textline_t): integer;
var
  i: integer;
begin
  if l.len = 0 then
    result := 0
  else
  begin
    result := 1;
    for i := 1 to l.len - 1 do
      if l.line[i] = #10 then
        inc(result);
  end;
end;
procedure HUlib_initSText(s: Phu_stext_t; x: integer; y: integer; h: integer;
  font: Ppatch_tPArray; startchar: integer; _on: Pboolean);
var
  i: integer;
begin
  s.height := h;
  s._on := _on;
  s.laston := true;
  s.curline := 0;
  for i := 0 to h - 1 do
    HUlib_initTextLine(@s.lines[i], x, y - i * (font[0].height + 1),
      font, startchar);
end;

//==============================================================================
//
// HUlib_addLineToSText
//
//==============================================================================
procedure HUlib_addLineToSText(s: Phu_stext_t);
var
  i: integer;
begin
  // add a clear line
  inc(s.curline);
  if s.curline = s.height then
    s.curline := 0;
  HUlib_clearTextLine(@s.lines[s.curline]);

  // everything needs updating
  for i := 0 to s.height - 1 do
    s.lines[i].needsupdate := 4;
end;

//==============================================================================
//
// HUlib_removeLineFromSText
//
//==============================================================================
procedure HUlib_removeLineFromSText(s: Phu_stext_t);
var
  i: integer;
  len: integer;
  sl: TDStringList;
  ss: string;
begin
  len := s.lines[s.curline].len;
  ss := '';
  for i := 0 to len - 1 do
    ss := ss + Char(s.lines[s.curline].line[i]);
  sl := TDStringList.Create;
  try
    sl.Text := ss;
    if sl.Count > 0 then
      sl.Delete(0);
    ss := sl.Text;
    if Length(ss) > 1 then
      if Copy(ss, Length(ss) - 1, 2) = #13#10 then
        SetLength(ss, Length(ss) - 2);
    len := Length(ss);
    for i := 1 to len do
      s.lines[s.curline].line[i - 1] := AnsiChar(ss[i]);
    s.lines[s.curline].len := len;
  finally
    sl.Free;
  end;

  s.lines[s.curline].needsupdate := 4;
end;

//==============================================================================
//
// HUlib_addMessageToSText
//
//==============================================================================
procedure HUlib_addMessageToSText(s: Phu_stext_t; prefix: string; msg: string);
var
  i: integer;
begin
  HUlib_addLineToSText(s);

  printf('%s%s'#13#10, [prefix, msg]);

  for i := 1 to Length(prefix) do
    HUlib_addCharToTextLine(@s.lines[s.curline], prefix[i]);

  for i := 1 to Length(msg) do
    HUlib_addCharToTextLine(@s.lines[s.curline], msg[i]);
end;

//==============================================================================
//
// HUlib_addMessageToSText2
//
//==============================================================================
procedure HUlib_addMessageToSText2(s: Phu_stext_t; prefix: string; msg: string);
var
  i: integer;
begin
  while HUlib_countLineLines(@s.lines[s.curline]) >= HU_MAXLINELINESS do
  begin
    HUlib_removeLineFromSText(s);
  end;

  printf('%s%s'#13#10, [prefix, msg]);

  if s.lines[s.curline].len > 0 then
  begin
    HUlib_addCharToTextLine(@s.lines[s.curline], #13);
    HUlib_addCharToTextLine(@s.lines[s.curline], #10);
  end;

  for i := 1 to Length(prefix) do
    HUlib_addCharToTextLine(@s.lines[s.curline], prefix[i]);

  for i := 1 to Length(msg) do
    HUlib_addCharToTextLine(@s.lines[s.curline], msg[i]);

  s.lines[s.curline].needsupdate := 4;

end;
procedure HUlib_drawSText(s: Phu_stext_t);
var
  i, idx: integer;
  l: Phu_textline_t;
begin
  if not s._on^ then
    exit; // if not on, don't draw

  // draw everything
  for i := 0 to s.height - 1 do
  begin
    idx := s.curline - i;
    if idx < 0 then
      idx := idx + s.height; // handle queue of lines

    l := @s.lines[idx];

    // need a decision made here on whether to skip the draw
    HUlib_drawTextLine(l, false); // no cursor, please
  end;
end;
procedure HUlib_initIText(it: Phu_itext_t; x: integer; y: integer; font: Ppatch_tPArray;
  startchar: integer; _on: Pboolean);
begin
  it.lm := 0; // default left margin is start of text
  it._on := _on;
  it.laston := true;
  HUlib_initTextLine(@it.line, x, y, font, startchar);
end;

//==============================================================================
// HUlib_delCharFromIText
//
// The following deletion routines adhere to the left margin restriction
//
//==============================================================================
procedure HUlib_delCharFromIText(it: Phu_itext_t);
begin
  if it.line.len <> it.lm then
    HUlib_delCharFromTextLine(@it.line);
end;

//==============================================================================
// HUlib_resetIText
//
// Resets left margin as well
//
//==============================================================================
procedure HUlib_resetIText(it: Phu_itext_t);
begin
  it.lm := 0;
  HUlib_clearTextLine(@it.line);
end;

//==============================================================================
// HUlib_keyInIText
//
// wrapper function for handling general keyed input.
// returns true if it ate the key
//
//==============================================================================
function HUlib_keyInIText(it: Phu_itext_t; ch: byte): boolean;
begin
  if (ch >= Ord(' ')) and (ch <= Ord('_')) then
    HUlib_addCharToTextLine(@it.line, Chr(ch))
  else
  if ch = KEY_BACKSPACE then
    HUlib_delCharFromIText(it)
  else if ch <> KEY_ENTER then
  begin
    result := false; // did not eat key
    exit;
  end;

  result := true; // ate the key
end;

//==============================================================================
//
// HUlib_drawIText
//
//==============================================================================
procedure HUlib_drawIText(it: Phu_itext_t);
begin
  if it._on^ then
    HUlib_drawTextLine(@it.line, true); // draw the line w/ cursor
end;
var
  FPSHISTORY: array[0..FPSSIZE - 1] of integer;
  FPSHISTORY2: array[0..FPSSIZE2 - 1] of integer;
  fpshead: integer = -1;
  fpshead2: integer = -1;

//==============================================================================
//
// HU_DoFPSStuff
//
//==============================================================================
procedure HU_DoFPSStuff;
var
  ftime: integer;
begin
  ftime := I_GetFracTime;
  fpshead := (fpshead + 1) mod FPSSIZE;
  FPSHISTORY[fpshead] := ftime;
  fpshead2 := (fpshead2 + 1) mod FPSSIZE2;
  FPSHISTORY2[fpshead2] := ftime;
end;

//==============================================================================
//
// HU_FPS
//
//==============================================================================
function HU_FPS: integer;
var
  fpsdiff: integer;
begin
  fpsdiff := FPSHISTORY[fpshead] - FPSHISTORY[(fpshead + 1) mod FPSSIZE] + 1;
  if fpsdiff > 0 then
  begin
    result :=  TICRATE * FPSSIZE * FRACUNIT div fpsdiff;
    if result > FPSSIZE then
    begin
      fpsdiff := FPSHISTORY2[fpshead2] - FPSHISTORY2[(fpshead2 + 1) mod FPSSIZE2] + 1;
      if fpsdiff > 0 then
        result :=  TICRATE * FPSSIZE2 * FRACUNIT div fpsdiff;
    end;
  end
  else
    result := TICRATE;
end;
const
  french_shiftxform: array[0..127] of Char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '?', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    '0', // shift-0
    '1', // shift-1
    '2', // shift-2
    '3', // shift-3
    '4', // shift-4
    '5', // shift-5
    '6', // shift-6
    '7', // shift-7
    '8', // shift-8
    '9', // shift-9
    '/',
    '.', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  english_shiftxform: array[0..127] of Char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '<', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    ')', // shift-0
    '!', // shift-1
    '@', // shift-2
    '#', // shift-3
    '$', // shift-4
    '%', // shift-5
    '^', // shift-6
    '&', // shift-7
    '*', // shift-8
    '(', // shift-9
    ':',
    ':', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  frenchKeyMap: array[0..127] of Char = (
    #0,
    #1,#2,#3,#4,#5,#6,#7,#8,#9,#10,
    #11,#12,#13,#14,#15,#16,#17,#18,#19,#20,
    #21,#22,#23,#24,#25,#26,#27,#28,#29,#30,
    #31,
    ' ','!','"','#','$','%','&','%','(',')','*','+',';','-',':','!',
    '0','1','2','3','4','5','6','7','8','9',':','M','<','=','>','?',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^','_',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^',#127
  );

//==============================================================================
//
// ForeignTranslation
//
//==============================================================================
function ForeignTranslation(ch: char): char;
begin
  if ch < #128 then
    result := frenchKeyMap[Ord(ch)]
  else
    result := ch;
end;
procedure HU_Ticker;
var
  i: integer;
  rc: boolean;
  c: char;
begin
  dec(fps_ticker);
  if fps_ticker <= 0 then
  begin
    m_fps := itoa(HU_FPS) + ' fps';
    fps_ticker := TICRATE div 2;
  end;

  // tick down message counter if message is up
  if message_counter <> 0 then
  begin
    dec(message_counter);
    if message_counter = 0 then
    begin
      HUlib_removeLineFromSText(@w_message);
      message_on := w_message.lines[w_message.curline].len > 0;
      if message_on then
        message_counter := HU_MSGTIMEOUT;
      message_nottobefuckedwith := false;
    end;
  end;

  if (showMessages <> 0) or message_dontfuckwithme then
  begin
    // display message if necessary
{$IFDEF DOOM}
    if plr <> nil then
      if ((plr._message <> '') and not message_nottobefuckedwith) or
         ((plr._message <> '') and message_dontfuckwithme) then
      begin
        HUlib_addMessageToSText2(@w_message, '', plr._message);
        plr._message := '';
        message_on := true;
        message_counter := HU_MSGTIMEOUT;
        message_nottobefuckedwith := message_dontfuckwithme;
        message_dontfuckwithme := false;
      end;
{$ELSE}
    if ((plr._message <> '') and not message_nottobefuckedwith) or
       ((plr._message <> '') and message_dontfuckwithme) then
    begin
      HUlib_addMessageToSText2(@w_message, '', plr._message);
      plr._message := '';
      message_on := true;
      message_counter := HU_MSGTIMEOUT;
      message_nottobefuckedwith := message_dontfuckwithme;
      message_dontfuckwithme := false;
    end;
{$ENDIF}
  end; // else message_on = false;

  // check for incoming chat characters
  if netgame then
  begin
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if not playeringame[i] then
        continue;
      c := Chr(players[i].cmd.chatchar);
      if (i <> consoleplayer) and (c <> #0) then
      begin
{$IFDEF STRIFE}
        if c <= Chr(HU_CHANGENAME) then // [STRIFE]: allow HU_CHANGENAME here
{$ELSE}
        if c <= Chr(HU_BROADCAST) then
{$ENDIF}
          chat_dest[i] := c
        else
        begin
          if (c >= 'a') and (c <= 'z') then
            c := shiftxform[Ord(c)];
          rc := HUlib_keyInIText(@w_inputbuffer[i], Ord(c));
          if rc and (Ord(c) = KEY_ENTER) then
          begin
            if (w_inputbuffer[i].line.len <> 0) and
               ((Ord(chat_dest[i]) = consoleplayer + 1) or (Ord(chat_dest[i]) = HU_BROADCAST)) then
            begin
              HUlib_addMessageToSText(@w_message,
                player_names[i],
                string(PAnsiChar(@w_inputbuffer[i].line.line[0])));

              message_nottobefuckedwith := true;
              message_on := true;
              message_counter := HU_MSGTIMEOUT;
{$IF DEFINED(DOOM)}
              if gamemode = commercial then
                S_StartSound(nil, Ord(sfx_radio))
              else
                S_StartSound(nil, Ord(sfx_tink));
{$ELSEIF DEFINED(STRIFE)}
              S_StartSound(nil, Ord(sfx_radio))
{$ENDIF}
            end;
            HUlib_resetIText(@w_inputbuffer[i]);
          end;
        end;
        players[i].cmd.chatchar := 0;
      end;
    end;
  end;
end;

const
  QUEUESIZE = 128;

var
  chatchars: array[0..QUEUESIZE - 1] of Char;
  head: integer = 0;
  tail: integer = 0;

//==============================================================================
//
// HU_queueChatChar
//
//==============================================================================
procedure HU_queueChatChar(c: char);
begin
  if ((head + 1) and (QUEUESIZE - 1)) = tail then
    plr._message := HUSTR_MSGU
  else
  begin
    chatchars[head] := c;
    head := (head + 1) and (QUEUESIZE - 1);
  end;
end;

//==============================================================================
//
// HU_dequeueChatChar
//
//==============================================================================
function HU_dequeueChatChar: char;
begin
  if head <> tail then
  begin
    result := chatchars[tail];
    tail := (tail + 1) and (QUEUESIZE - 1);
  end
  else
    result := #0;
end;
var
  lastmessage: string;
  shiftdown: boolean = false;
  altdown: boolean = false;
  num_nobrainers: integer = 0;

//==============================================================================
//
// HU_Responder
//
//==============================================================================
function HU_Responder(ev: Pevent_t): boolean;
var
  macromessage: string;
  c: char;
  i: integer;
  numplayers: integer;
begin
  result := false;

  if ev.data1 = KEY_RSHIFT then
  begin
    shiftdown := ev._type = ev_keydown;
    exit;
  end
  else if (ev.data1 = KEY_RALT) or (ev.data1 = KEY_LALT) then
  begin
    altdown := ev._type = ev_keydown;
    exit;
  end;

  if ev._type <> ev_keydown then
    exit;

  numplayers := 0;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      inc(numplayers);

  if not chat_on then
  begin
    if ev.data1 = HU_MSGREFRESH then
    begin
      message_on := true;
      message_counter := HU_MSGTIMEOUT;
      result := true;
    end
    else if netgame and (ev.data1 = Ord(HU_INPUTTOGGLE)) then
    begin
      result := true;
      chat_on := true;
      HUlib_resetIText(@w_chat);
      HU_queueChatChar(Chr(HU_BROADCAST));
    end
    else if netgame and (numplayers > 2) then
    begin
      for i := 0 to MAXPLAYERS - 1 do
      begin
{$IFDEF STRIFE}
        if key_multi_msgplayer[i] <> '' then
{$ELSE}
        if destination_keys[i] <> '' then
{$ENDIF}
        begin
{$IFDEF STRIFE}
          if ev.data1 = Ord(key_multi_msgplayer[i][1]) then
{$ELSE}
          if ev.data1 = Ord(destination_keys[i][1]) then
{$ENDIF}
          begin
            if playeringame[i] and (i <> consoleplayer) then
            begin
              result := true;
              chat_on := true;
              HUlib_resetIText(@w_chat);
              HU_queueChatChar(Chr(i + 1));
              break;
            end
            else if i = consoleplayer then
            begin
              inc(num_nobrainers);
              if num_nobrainers < 3 then
                plr._message := HUSTR_TALKTOSELF1
              else if num_nobrainers < 6 then
                plr._message := HUSTR_TALKTOSELF2
              else if num_nobrainers < 9 then
                plr._message := HUSTR_TALKTOSELF3
              else if num_nobrainers < 32 then
                plr._message := HUSTR_TALKTOSELF4
              else
                plr._message := HUSTR_TALKTOSELF5;
            end
          end;
        end;
      end;
    end;
  end
  else
  begin
    c := Chr(ev.data1);
    // send a macro
    if altdown then
    begin
      c := Chr(Ord(c) - Ord('0'));
      if c > Chr(9) then
        exit;
      macromessage := chat_macros[Ord(c)];

      // kill last message with a '\n'
      HU_queueChatChar(Chr(KEY_ENTER)); // DEBUG!!!

      // send the macro message
      for i := 1 to Length(macromessage) do
        HU_queueChatChar(macromessage[i]);
      HU_queueChatChar(Chr(KEY_ENTER));

      // leave chat mode and notify that it was sent
      chat_on := false;
      lastmessage := chat_macros[Ord(c)];
      plr._message := lastmessage;
      result := true;
    end
    else
    begin
      if language = french then
        c := ForeignTranslation(c);
      if shiftdown or ((c >= 'a') and (c <= 'z')) then
        c := shiftxform[Ord(c)];
      result := HUlib_keyInIText(@w_chat, Ord(c));
      if result then
        HU_queueChatChar(c);
      if Ord(c) = KEY_ENTER then
      begin
        chat_on := false;
        if w_chat.line.len <> 0 then
        begin
          lastmessage := string(PAnsiChar(@w_chat.line.line[0]));
          plr._message := lastmessage;
        end
      end
      else if Ord(c) = KEY_ESCAPE then
        chat_on := false;
    end;
  end;
end;
var
  lump_trn: Integer = -2;

//==============================================================================
//
// HU_WriteText
// Write a string using the hu_font, use white for numeric characters
//
//==============================================================================
function HU_WriteText(x, y: integer; const str: string; const highlightnums: boolean): menupos_t;
var
  w: integer;
  ch: integer;
  c: integer;
  currchar: char;
  cx: integer;
  cy: integer;
  len: integer;
  oldtranslation, newtranslation: PByteArray;
  dowhite: boolean;
begin
  len := Length(str);
  if len = 0 then
  begin
    result.x := x;
    result.y := y;
    exit;
  end;

  ch := 1;
  cx := x;
  cy := y;

  if lump_trn < 0 then
    lump_trn := W_GetNumForName('TRN_MENU');

  oldtranslation := v_translation;
  newtranslation := W_CacheLumpNum(lump_trn, PU_STATIC);

  dowhite := False;

  while true do
  begin
    if ch > len then
      break;

    currchar := str[ch];
    c := Ord(currchar);
    inc(ch);

    if highlightnums then
      dowhite := dowhite or CharInSet(currchar, ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);

    if c = 0 then
      break;

    if c = 10 then
    begin
      cx := x;
      continue;
    end;

    if c = 13 then
    begin
      cy := cy + 12;
      continue;
    end;

    c := Ord(toupper(Chr(c))) - Ord(HU_FONTSTART);
    if (c < 0) or (c >= HU_FONTSIZE) then
    begin
      cx := cx + 4;
      continue;
    end;

    w := hu_font[c].width;
    if (cx + w) > 320 then
      break;

    if dowhite then
      v_translation := newtranslation
    else
      v_translation := oldtranslation;

    V_DrawPatch(cx, cy, SCN_FG, hu_font[c], true);

    cx := cx + w;
  end;

  Z_ChangeTag(newtranslation, PU_CACHE);
  v_translation := oldtranslation;

  result.x := cx;
  result.y := cy;
end;

var
  LegacyPatches: array[0..HU_FONTSIZE - 1] of patch_t;
  LegacyYellowPatches: array[0..HU_FONTSIZE - 1] of patch_t;

procedure Legacy_MakeFonts(const AWidths: array of Integer);
var
  i: Integer;
begin
  for i := 0 to HU_FONTSIZE - 1 do
  begin
    LegacyPatches[i].width := AWidths[i mod Length(AWidths)];
    LegacyPatches[i].height := i + 1;
    hu_font[i] := @LegacyPatches[i];
    LegacyYellowPatches[i].width := AWidths[(i + 3) mod Length(AWidths)];
    LegacyYellowPatches[i].height := 100 + i;
    yfont[i] := @LegacyYellowPatches[i];
  end;
end;

procedure Legacy_Start(const ATitle: string);
var
  i: integer;
begin
  plr := @players[consoleplayer];
  message_on := false;
  message_dontfuckwithme := false;
  message_nottobefuckedwith := false;
  chat_on := false;

  // create the message widget
  HUlib_initSText(@w_message,
    HU_MSGX, HU_MSGY, HU_MSGHEIGHT,
    @hu_font,
    Ord(HU_FONTSTART), @message_on);

  // create the map title widget
  HUlib_initTextLine(@w_title,
    0, 167 - hu_font[0].height,
    @hu_font,
    Ord(HU_FONTSTART));

  HUlib_initTextLine(@w_leveltime,
    0, 167 - 2 * hu_font[0].height,
    @hu_font,
    Ord(HU_FONTSTART));

  for i := 1 to Length(ATitle) do
    HUlib_addCharToTextLine(@w_title, ATitle[i]);

  // create the chat widget
  HUlib_initIText(@w_chat,
    HU_MSGX, HU_MSGY + HU_MSGHEIGHT * (hu_font[0].height + 1),
    @hu_font,
    Ord(HU_FONTSTART), @chat_on);

  // create the inputbuffer widgets
  for i := 0 to MAXPLAYERS - 1 do
    HUlib_initIText(@w_inputbuffer[i], 0, 0, nil, 0, @always_off);
end;

procedure Legacy_ResetState;
var
  i: Integer;
begin
  // what the old code kept in globals of its own between two games
  shiftdown := false;
  altdown := false;
  num_nobrainers := 0;
  lastmessage := '';
  head := 0;
  tail := 0;
  fpshead := -1;
  fpshead2 := -1;
  for i := 0 to QUEUESIZE - 1 do
    chatchars[i] := #0;
end;

procedure Legacy_Init;
var
  i: integer;
begin
  if language = french then
  begin
    for i := 0 to 127 do
      shiftxform[i] := french_shiftxform[i];
  end
  else
  begin
    for i := 0 to 127 do
      shiftxform[i] := english_shiftxform[i];
  end;
  for i := 0 to FPSSIZE - 1 do
    FPSHISTORY[i] := 0;
  for i := 0 to FPSSIZE2 - 1 do
    FPSHISTORY2[i] := 0;
end;

procedure Legacy_UpdateLevelTime(const ALevelTime: Integer);
var
  i, t: integer;
  lt: string;
begin
    repeat
    until not HUlib_delCharFromTextLine(@w_leveltime);
    t := ALevelTime div TICRATE;
    lt := IntToStrZFill(2, t mod 60);
    t := t div 60;
    lt := IntToStrZFill(2, t mod 60) + ':' + lt;
    t := t div 60;
    lt := 'Time: ' + IntToStrZFill(2, t) + ':' + lt;

    for i := 1 to Length(lt) do
      HUlib_addCharToTextLine(@w_leveltime, lt[i]);
end;

function Legacy_CrosshairIndex(const AHasTarget, AFriend: Boolean; const ALevelTime, ACrossTic: Integer): Integer;
begin
  if not AHasTarget then
    Result := 0
  else if AFriend then
    Result := 0
  else
    Result := (((ALevelTime - ACrossTic) div 8) mod 4) + 1;
end;

function Legacy_CrosshairOffset(const ALookDir, AViewWidth: Integer): Integer;
begin
  if ALookDir < 128 then
    Result := ALookDir * AViewWidth div 40
  else
    Result := - (255 - ALookDir) * AViewWidth div 40;
end;

function Legacy_Title(const ANames: array of string; const AEpisode, AMap: Integer): string;
var
  x: integer;
begin
  x := (AEpisode - 1) * 9 + AMap - 1;
  if IsIntegerInRange(x, 0, High(ANames)) then
    result := ANames[x]
  else
    sprintf(result, 'Episode %d - Map %d', [AEpisode, AMap]);
end;

function Legacy_Title2(const ANames: array of string; const AMap: Integer): string;
begin
  if IsIntegerInRange(AMap, 1, Length(ANames)) then
    result := ANames[AMap - 1]
  else
    sprintf(result, 'Map %d', [AMap]);
end;

end.
