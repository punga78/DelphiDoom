unit i_windows;
// stub of the harness: the system clock is the one that the driver of the scenario sets
interface
function clock: LongWord;
procedure I_PeekAndDisplatch;
procedure I_Sleep(const msecs: integer);
implementation
uses harness_level;
function clock: LongWord; begin Result := HarnessClock; end;
procedure I_PeekAndDisplatch; begin end;
procedure I_Sleep(const msecs: integer); begin end;
end.
