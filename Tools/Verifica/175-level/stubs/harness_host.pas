unit harness_host;
// stub of the harness: the calls of EndLevel to the screen. It is the last unit of the uses clause of the cut
// raven.pas, so these names hide the ones of the real r_render.pas
interface
procedure R_ClearRenderBuffer;
procedure I_SetPalette(const palette: pointer);
implementation
uses harness_level;
procedure R_ClearRenderBuffer; begin HarnessTrace.Call('R_ClearRenderBuffer', []); end;
procedure I_SetPalette(const palette: pointer); begin HarnessTrace.Call('I_SetPalette', []); end;
end.
