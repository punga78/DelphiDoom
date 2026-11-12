unit d_ints;
// the variables of d_ints.pas that ControlMovement reads; the keys are set by the program as INT_ReadControls does
interface
uses d_ints_h;
const
  TICRATE = 70;
type
  mouse_t = record
    oldflags: integer;
    flags: integer;
    dx, dy: integer;
  end;
var
  timecount: integer;
  keyboard: array[0..NUMCODES - 1] of smallint;
  newascii: boolean;
  invertmouseturn, invertmouselook: boolean;
  in_button: array[0..NUMBUTTONS - 1] of integer;
  lastascii: char;
  mousedx: integer = 0;
  mousedy: integer = 0;
  mousebuttons: array[0..NUMMBUTTONS - 1] of boolean;
  mousesensitivityx: integer = 10;
  mousesensitivityy: integer = 5;
  mouse: mouse_t;
const
  scanbuttons: array[0..NUMBUTTONS - 1] of integer = (
    SC_UPARROW, SC_RIGHTARROW, SC_DOWNARROW, SC_LEFTARROW, SC_CONTROL, SC_ALT, SC_SPACE, SC_LSHIFT, SC_Z, SC_X,
    SC_A, SC_PGUP, SC_PGDN, SC_HOME, SC_COMMA, SC_PERIOD, SC_INSERT, SC_DELETE, SC_S);
procedure eat_key(const k: integer);
implementation
procedure eat_key(const k: integer);
begin
  if keyboard[k] = 1 then
    keyboard[k] := 2;
end;
end.
