unit d_ints;
// stub of the harness: the timer and the keyboard of the original without Windows. Wait (intro.pas) calls HarnessTic
// once for each tic it waits: the screen is captured, the keys of the scenario are applied and the body of
// INT_TimerISR runs (timecount, INT_ReadControls on the odd tics as the ORIGINAL reads them, the timer hook)
interface
uses g_delphi, d_ints_h;
const
  TICRATE = 70;
  MOUSESIZE = 16;
var
  timerhook: PProcedure;
  timecount: integer;
  gametic: integer = 0;
  keyboard: array[0..NUMCODES - 1] of smallint;
  pause, capslock, newascii: boolean;
  in_button: array[0..NUMBUTTONS - 1] of integer;
  lastascii: char;
  mousehx: float = 160.0;
  mousehy: float = 100.0;
  menuusemouse: boolean = false;
  waitISR: boolean = false;
procedure INT_TimerHook(const hook: PProcedure);
procedure eat_key(const k: integer);
function MouseGetClick(var x, y: smallint): boolean;
procedure ResetMouse;
procedure MouseHide;
procedure MouseShow;
procedure HarnessTic;
procedure HarnessResetKeys;
implementation
uses harness_menu, DelphiDoom.Tests.Greed.MenuScenarios;
const
  ASCIINames: array[0..127] of char = ( // Unshifted ASCII for scan codes
    #0, #27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', #8, #9,
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', #13, #0, 'a', 's',
    'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', #39, '`', #0, #92, 'z', 'x', 'c', 'v',
    'b', 'n', 'm', ',', '.', '/', #0, '*', #0, ' ', #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, '-', #0, #0, #0, '+', #0,
    #0, #0, #0, #127, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0,
    #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
  );
var
  oldkeyboard: array[0..NUMCODES - 1] of smallint;

// INT_ReadControls of the original: the keys come from the scenario (HDown) and not from Windows
procedure INT_ReadControls;
var
  i: integer;
  c: char;
begin
  lastascii := #0;
  for i := 0 to NUMCODES - 1 do
  begin
    if HDown[i] then
    begin
      if keyboard[i] = 0 then
        keyboard[i] := 1;
      if oldkeyboard[i] = 0 then
      begin
        c := UpCase(ASCIINames[i]);
        if c <> #0 then
        begin
          lastascii := c;
          newascii := true;
        end;
      end;
    end
    else
      keyboard[i] := 0;
  end;
  for i := 0 to NUMCODES - 1 do
    oldkeyboard[i] := keyboard[i];
end;

procedure HarnessTic;
begin
  if HTics = HScenario.MaxTics then
    raise EHarnessStop.Create('stop');
  if Assigned(HCapture) then
    HCapture;
  while (HNextKey < Length(HScenario.Keys)) and (HScenario.Keys[HNextKey].Tic <= HTics + 1) do
  begin
    HDown[HScenario.Keys[HNextKey].ScanCode] := HScenario.Keys[HNextKey].Down;
    Inc(HNextKey);
  end;
  // INT_TimerISR
  inc(timecount);
  inc(gametic);
  if timecount and 1 <> 0 then
    INT_ReadControls;
  if Assigned(timerhook) then
    timerhook;
  Inc(HTics);
end;

procedure HarnessResetKeys;
begin
  FillChar(HDown, SizeOf(HDown), 0);
  FillChar(keyboard, SizeOf(keyboard), 0);
  FillChar(oldkeyboard, SizeOf(oldkeyboard), 0);
  newascii := false;
  lastascii := #0;
  timerhook := nil;
end;

procedure INT_TimerHook(const hook: PProcedure);
begin
  timerhook := hook;
end;

procedure eat_key(const k: integer);
begin
  if keyboard[k] = 1 then
    keyboard[k] := 2;
end;

function MouseGetClick(var x, y: smallint): boolean;
begin
  result := false;
end;

procedure ResetMouse;
begin
  HTrace.Add(MENU_TRACE_RESET_CONTROLS);
end;

procedure MouseHide; begin end;
procedure MouseShow; begin end;
end.
