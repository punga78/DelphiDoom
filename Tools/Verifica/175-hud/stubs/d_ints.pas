unit d_ints;
// stub of the harness: the clock of the game
interface
const
  TICRATE = 70;
var
  timecount: integer;
  waitISR: boolean = false;
  newascii: boolean = false;
  lastascii: char = #0;
implementation
end.
