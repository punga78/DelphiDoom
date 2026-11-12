unit utils;
// stub of the harness: the globals of utils.pas that event.pas reads and writes
interface
uses protos_h;
var
  primaries: array[0..3] of integer;
  secondaries: array[0..13] of integer;
  pcount: array[0..1] of integer;
  scount: array[0..6] of integer;
  bonustime: integer;
  levelscore: integer;
  gameloading, eventloading: boolean;
  startlocations: array[0..MAXSTARTLOCATIONS - 1, 0..1] of integer;
implementation
end.
