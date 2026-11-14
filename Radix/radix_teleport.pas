{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the sparks of a teleport                           }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of RX_SpawnTeleportForceField of radix_teleport.pas of Rad-X.          }
{  RX_DoomFogPresent (the teleports of the lines of Doom) is not ported        }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit radix_teleport;

interface

uses
  p_mobj_h;

//==============================================================================
//
// RX_SpawnTeleportForceField
// The cloud of sparks around a craft that an action of the level teleports.
// Nothing without the actor MT_TELEPORTFORCEFIELD
//
//==============================================================================
procedure RX_SpawnTeleportForceField(const mo: Pmobj_t);

implementation

uses
  d_delphi,
  m_fixed,
  m_rnd,
  tables,
  info_common,
  p_mobj,
  radix_codepointers;

const
  TELEPORTDENSITY = 1000;

var
  radixteleportforcefield_id: integer = -1;

//==============================================================================
//
// RX_SpawnTeleportForceField
//
//==============================================================================
procedure RX_SpawnTeleportForceField(const mo: Pmobj_t);
var
  i: integer;
  tt: Pmobj_t;
  an: angle_t;
  dist: integer;
  rnd: integer;
begin
  if radixteleportforcefield_id < 0 then
    radixteleportforcefield_id := Info_GetMobjNumForName('MT_TELEPORTFORCEFIELD');

  if radixteleportforcefield_id >= 0 then
    for i := 0 to TELEPORTDENSITY - 1 do
    begin
      // one random number for each statement: the order must not depend on the compiler
      an := Sys_Random * (FINEANGLES div 256);
      dist := 32 + P_Random and 63;
      rnd := P_Random;
      tt := P_SpawnMobj(mo.x + dist * finecosine[an],
                        mo.y + dist * finesine[an],
                        mo.z + (rnd - 128) * FRACUNIT, radixteleportforcefield_id);
      rnd := Sys_Random;
      tt.momx := finecosine[an] * (256 + rnd) div 256;
      rnd := Sys_Random;
      tt.momy := finesine[an] * (256 + rnd) div 256;
      rnd := P_Random;
      if rnd < 128 then
        tt.momz := mo.momz - Sys_Random * 1024
      else
        tt.momz := mo.momz + Sys_Random * 1024;
    end;

  RX_AmbientSound(mo.x, mo.y, 'radix/SndTelePort');
end;

end.
