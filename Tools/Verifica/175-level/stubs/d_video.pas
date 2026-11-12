unit d_video;
// stub of the harness: pic_t (weaponpic[0].height), the screen that EndLevel clears and VI_FadeOut in the trace
interface
uses SysUtils;
type
  pic_t = packed record
    width: smallint;
    height: smallint;
    orgx: smallint;
    orgy: smallint;
    data: byte;
  end;
  Ppic_t = ^pic_t;
var
  translookup: array[0..255] of PByteArray;
  screen: PByteArray;
procedure VI_FadeOut(start, stop: integer; const red, green, blue: integer; const steps: integer);
implementation
uses harness_level;
var
  screenbuffer: array[0..63999] of byte;
procedure VI_FadeOut(start, stop: integer; const red, green, blue: integer; const steps: integer);
begin
  HarnessTrace.Call('VI_FadeOut', [start, stop, red, green, blue, steps]);
end;
initialization
  screen := @screenbuffer;
end.
