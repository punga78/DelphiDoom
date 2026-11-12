unit modplay;
// stub of the harness: SoundEffect in the trace
interface
uses g_delphi, r_public_h;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
implementation
uses harness_convert;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  HarnessTrace.Add(n, 'sound.n');
  HarnessTrace.Add(variation, 'sound.variation');
  HarnessTrace.Add(x, 'sound.x');
  HarnessTrace.Add(y, 'sound.y');
end;
end.
