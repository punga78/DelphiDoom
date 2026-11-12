unit sprites;
// stub of the harness: MoveSprites in the trace
interface
procedure MoveSprites;
implementation
uses harness_level;
procedure MoveSprites; begin HarnessTrace.Call('MoveSprites', []); end;
end.
