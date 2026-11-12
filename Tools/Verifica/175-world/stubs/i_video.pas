unit i_video;
// stub of the harness: nothing is shown. I_FinishUpdate, the palette and the display modes do nothing;
// I_TranslateBuffer is the one of the original (it only changes pixels)
interface
uses
  SysUtils, g_delphi, Windows;
procedure I_InitGraphics;
procedure I_ChangeFullScreen(const dofull, doexclusive: boolean);
procedure I_ShutDownGraphics;
procedure I_SetPalette(const palette: PByteArray);
procedure I_GetPalette(const palette: PByteArray);
procedure I_FinishUpdate;
procedure I_ReadScreen32(dest: pointer);
procedure I_RestoreWindowPos;
function I_WindowWidth: integer;
function I_WindowHeight: integer;
type
  displaymode_t = record
    width, height: integer;
    bpp: integer;
  end;
  displaymode_tArray = array[0..$FF] of displaymode_t;
  Pdisplaymode_tArray = ^displaymode_tArray;
var
  displaymodes: Pdisplaymode_tArray = nil;
  numdisplaymodes: integer = 0;
function I_DisplayModeIndex(const w, h: integer): integer;
function I_NearestDisplayModeIndex(const w, h: integer): integer;
var
  vid_pillarbox_pct: integer = 17;
  vid_letterbox_pct: integer;
const
  PILLARLETTER_MIN = 0;
  PILLARLETTER_MAX = 50;
var
  fullscreen: boolean = false;
  fullscreenexclusive: boolean = false;
  doubleblit: boolean = true;
  approx_zero: byte = 0;
procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);
implementation
procedure I_InitGraphics;
begin
end;
procedure I_ChangeFullScreen(const dofull, doexclusive: boolean);
begin
end;
procedure I_ShutDownGraphics;
begin
end;
procedure I_SetPalette(const palette: PByteArray);
begin
end;
procedure I_GetPalette(const palette: PByteArray);
begin
  FillChar(palette^, 768, 0);
end;
procedure I_FinishUpdate;
begin
end;
procedure I_ReadScreen32(dest: pointer);
begin
end;
procedure I_RestoreWindowPos;
begin
end;
function I_WindowWidth: integer;
begin
  Result := 640;
end;
function I_WindowHeight: integer;
begin
  Result := 400;
end;
function I_DisplayModeIndex(const w, h: integer): integer;
begin
  Result := -1;
end;
function I_NearestDisplayModeIndex(const w, h: integer): integer;
begin
  Result := -1;
end;
procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);
var
  i: integer;
begin
  for i := 0 to sz - 1 do
    if buf[i] = 0 then
      buf[i] := approx_zero;
end;
end.
