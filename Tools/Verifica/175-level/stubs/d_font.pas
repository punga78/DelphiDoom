unit d_font;
// stub of the harness: writemsg in the trace
interface
procedure writemsg(const s: string);
implementation
uses harness_level;
procedure writemsg(const s: string);
begin
  HarnessTrace.Call('writemsg', []);
  HarnessTrace.AddText(s, 'text');
end;
end.
