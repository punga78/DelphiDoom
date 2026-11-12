unit r_conten;
// stub of the harness: the lists of r_conten.pas, declared as in the original
interface
uses
  r_public_h;
var
  firstscaleobj, lastscaleobj: scaleobj_t; // just placeholders for links
  scaleobjlist: array[0..MAXSPRITES - 1] of scaleobj_t;
  freescaleobj_p: Pscaleobj_t;
  doorlist: array[0..MAXDOORS - 1] of doorobj_t;
  numdoors: integer;
  firstelevobj, lastelevobj: elevobj_t;
  elevlist: array[0..MAXELEVATORS - 1] of elevobj_t;
  freeelevobj_p: Pelevobj_t;
  spawnareas: array[0..MAXSPAWNAREAS - 1] of spawnarea_t;
  numspawnareas, rtimecount: integer;
implementation
end.
