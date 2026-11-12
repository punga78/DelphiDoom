unit harness_host;
// stub of the harness: the calls of EndLevel to the screen, and what Special_Code asks of m_defs.pas and of
// d_misc.pas. It is the last unit of the uses clause of the cut raven.pas, so these names hide the ones of the
// real r_render.pas
interface
var
  gameepisode: integer = 1;
procedure R_ClearRenderBuffer;
procedure I_SetPalette(const palette: pointer);
function MS_CheckParm(const check: string): integer;
implementation
uses SysUtils, harness_level;
procedure R_ClearRenderBuffer; begin HarnessTrace.Call('R_ClearRenderBuffer', []); end;
procedure I_SetPalette(const palette: pointer); begin HarnessTrace.Call('I_SetPalette', []); end;
// asked only in a net game
function MS_CheckParm(const check: string): integer; begin raise Exception.Create('MS_CheckParm'); end;
end.
