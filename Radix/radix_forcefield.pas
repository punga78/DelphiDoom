{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the force fields of the transporters               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_forcefield.pas of Rad-X: the sparks in the cells of the grid  }
{  whose trigger starts a transporter (action 12), while the trigger is not    }
{  suspended. Not ported: the force fields of the sectors with the special     }
{  FORCEFIELD_MASK and RX_ForceFieldThrust (they are of the sector specials    }
{  and of the movement code of Rad-X, that the engine does not have)           }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit radix_forcefield;

interface

//==============================================================================
//
// RX_InitForceFields
// To call when the level is loaded, after the grid and the triggers
//
//==============================================================================
procedure RX_InitForceFields;

//==============================================================================
//
// RX_RunForceFields
//
//==============================================================================
procedure RX_RunForceFields;

implementation

uses
  d_delphi,
  m_fixed,
  m_rnd,
  info_common,
  p_mobj_h,
  p_mobj,
  r_defs,
  r_main,
  radix_grid,
  radix_logic,
  DelphiDoom.Radix.Level.Types,
  DelphiDoom.Radix.LevelLogic.Types;

type
  forcefielditem_t = record
    xpos: fixed_t;
    ypos: fixed_t;
    sector: Psector_t;
    trigger: integer;
  end;

var
  numforcefielditems: integer = 0;
  forcefield: array of forcefielditem_t;
  radixforcefield_id: integer = -1;

const
  FF_DENSITY = 1;  // How many to spawn in a 64x64x64 cube

//==============================================================================
//
// RX_InitForceFields
//
//==============================================================================
procedure RX_InitForceFields;
var
  i: integer;
  x, y: integer;
  trig_id: integer;
begin
  numforcefielditems := 0;
  SetLength(forcefield, 0);
  radixforcefield_id := Info_GetMobjNumForName('MT_FORCEFIELD');
  if (radixgrid = nil) or (radixlogic = nil) or not radixgrid.HasGrid then
    exit;

  x := 0;
  y := 0;
  for i := 0 to RADIX_GRID_SIZE - 1 do
  begin
    trig_id := radixgrid.TriggerAt(i);
    if trig_id < 0 then
      continue;
    if not radixlogic.TriggerHasActionOfKind(trig_id, RADIX_ACTION_PLANE_TRANSPO) then
      continue;
    if not RX_GridToMap(i, x, y) then
      continue;
    if numforcefielditems >= Length(forcefield) then
      SetLength(forcefield, numforcefielditems + 16);
    forcefield[numforcefielditems].xpos := x * FRACUNIT;
    forcefield[numforcefielditems].ypos := y * FRACUNIT;
    forcefield[numforcefielditems].sector := R_PointInSubSector(x * FRACUNIT, y * FRACUNIT).sector;
    forcefield[numforcefielditems].trigger := trig_id;
    inc(numforcefielditems);
  end;
end;

//==============================================================================
//
// RX_SpawnForceFields
//
//==============================================================================
procedure RX_SpawnForceFields(const idx: integer);
var
  item: ^forcefielditem_t;
  th: Pmobj_t;
  i: integer;
  numff: integer;
  x, y, z: fixed_t;
  zstep: fixed_t;
  rnd: integer;
begin
  item := @forcefield[idx];
  if radixlogic.IsTriggerSuspended(item.trigger) then
    exit;

  zstep := (RADIX_GRID_CELL_SIZE * FRACUNIT) div FF_DENSITY;
  numff := (item.sector.ceilingheight - item.sector.floorheight) div zstep;
  z := item.sector.floorheight + zstep div 2;
  for i := 0 to numff - 1 do
    if Sys_Random < 128 then
    begin
      // one random number for each statement: the order must not depend on the compiler
      rnd := Sys_Random;
      x := item.xpos + rnd * 256 * RADIX_GRID_CELL_SIZE;
      rnd := Sys_Random;
      y := item.ypos - rnd * 256 * RADIX_GRID_CELL_SIZE;
      th := P_SpawnMobj(x, y, z, radixforcefield_id);
      rnd := Sys_Random;
      if Sys_Random < 128 then
        th.momz := -rnd * 1024
      else
        th.momz := rnd * 1024;
      z := z + zstep;
    end;
end;

//==============================================================================
//
// RX_RunForceFields
//
//==============================================================================
procedure RX_RunForceFields;
var
  i: integer;
begin
  // without the actors of Radix there is nothing to spawn
  if (radixforcefield_id < 0) or (radixlogic = nil) then
    exit;

  for i := 0 to numforcefielditems - 1 do
    RX_SpawnForceFields(i);
end;

end.
