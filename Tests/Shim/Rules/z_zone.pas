{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of z_zone for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real z_zone in DelphiDoom.Tests.Rules only: the zone tags and allocator calls (the real unit is the zone memory of the engine).
{$I Doom32.inc}
unit z_zone;

interface

const
  PU_STATIC = 1;
  PU_LEVEL = 50;

function Z_Malloc(const size: integer; tag: integer; user: pointer): pointer;

procedure Z_Free(ptr: pointer);

function Z_Realloc(ptr: pointer; const size: integer; tag: integer; user: pointer): pointer;

implementation

function Z_Malloc(const size: integer; tag: integer; user: pointer): pointer;
begin
  GetMem(result, size);
  FillChar(result^, size, 0);
end;

procedure Z_Free(ptr: pointer);
begin
  FreeMem(ptr);
end;

function Z_Realloc(ptr: pointer; const size: integer; tag: integer; user: pointer): pointer;
begin
  result := ptr;
  ReallocMem(result, size);
end;

end.