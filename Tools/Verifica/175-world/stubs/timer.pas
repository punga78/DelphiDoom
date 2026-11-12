unit timer;
// stub of the harness: there is no timer thread; the harness calls INT_TimerISR itself between two turns of PlayLoop
interface
uses
  g_delphi;
procedure dStopTimer;
procedure dStartTimer(const atimer: PProcedure; const rate: integer);
var
  needsblit: boolean = true;
implementation
procedure dStopTimer;
begin
end;
procedure dStartTimer(const atimer: PProcedure; const rate: integer);
begin
end;
end.
