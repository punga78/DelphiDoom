unit r_render;
// stub of the harness: the planes of the map of r_render.pas, declared in the order of the original, and the sky
interface
uses
  r_public_h;
var
  westwall: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  westflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  northwall: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  northflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floorpic: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floorflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingpic: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floorheight: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingheight: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floordef: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floordefflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingdef: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingdefflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  maplights: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapsprites: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapslopes: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapeffects: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  spritelump, walllump, flatlump: integer;
  backdrop: packed array[0..256 * 256 - 1] of byte;
implementation
end.
