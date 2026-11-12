unit d_ints;
// stub of the harness: the clock of the game and the mouse in the trace
interface
uses g_delphi;
const
  TICRATE = 70;
var
  timecount: integer;
  waitISR: boolean = false;
  newascii: boolean = false;
  lastascii: char = #0;
procedure ResetMouse;
procedure UpdateMouse;
procedure INT_TimerHook(const hook: PProcedure);
implementation
uses harness_level;
procedure ResetMouse; begin HarnessTrace.Call('ResetMouse', []); end;
procedure UpdateMouse; begin HarnessTrace.Call('UpdateMouse', []); end;
procedure INT_TimerHook(const hook: PProcedure); begin HarnessTrace.Call('INT_TimerHook', []); end;
end.
