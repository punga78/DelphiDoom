unit modplay;
// stub of the harness: SoundEffect writes down the call
interface
uses r_public_h, protos_h;
type
  soundcall_t = record
    n, variation: integer;
    x, y: fixed_t;
  end;
var
  SC: SoundCard;
  soundcalls: array[0..63] of soundcall_t;
  numsoundcalls: integer = 0;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
implementation
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  soundcalls[numsoundcalls].n := n;
  soundcalls[numsoundcalls].variation := variation;
  soundcalls[numsoundcalls].x := x;
  soundcalls[numsoundcalls].y := y;
  inc(numsoundcalls);
end;
end.
