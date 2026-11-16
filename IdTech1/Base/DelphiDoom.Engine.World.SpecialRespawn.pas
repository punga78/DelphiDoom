{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the respawn of the special things (Heretic, Hexen)     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.SpecialRespawn;

// The pickups of Heretic and Hexen hide for a while and come back (issue #185,
// step 2f-2b): the state actions of the hidden thing. They were in p_inter, the
// same in both games; what differs (the mace of Heretic goes to a new place) is
// the rule RepositionSpecial of TInterGameRules

interface

uses
  p_mobj_h;

//==============================================================================
//
// P_HideSpecialThing
//
//==============================================================================
procedure P_HideSpecialThing(thing: Pmobj_t);

//==============================================================================
// A_RestoreArtifact
//
// Actions
//
//==============================================================================
procedure A_RestoreArtifact(arti: Pmobj_t);

//==============================================================================
//
// A_RestoreSpecialThing1
//
//==============================================================================
procedure A_RestoreSpecialThing1(thing: Pmobj_t);

//==============================================================================
//
// A_RestoreSpecialThing2
//
//==============================================================================
procedure A_RestoreSpecialThing2(thing: Pmobj_t);

implementation

uses
  info_h,
  p_mobj,
  s_sound,
  sounddata,
  DelphiDoom.Engine.World.InterRules;

//==============================================================================
//
// P_HideSpecialThing
//
//==============================================================================
procedure P_HideSpecialThing(thing: Pmobj_t);
begin
  thing.flags := thing.flags and not MF_SPECIAL;
  thing.flags2 := thing.flags2 or MF2_DONTDRAW;
  P_SetMobjState(thing, S_HIDESPECIAL1);
end;

//==============================================================================
// A_RestoreArtifact
//
// Actions
//
//==============================================================================
procedure A_RestoreArtifact(arti: Pmobj_t);
begin
  arti.flags := arti.flags or MF_SPECIAL;
  P_SetMobjState(arti, statenum_t(arti.info.spawnstate));
  S_StartSound(arti, Ord(sfx_respawn));
end;

//==============================================================================
//
// A_RestoreSpecialThing1
//
//==============================================================================
procedure A_RestoreSpecialThing1(thing: Pmobj_t);
begin
  TInterGameRules.RepositionSpecial(thing);
  thing.flags2 := thing.flags2 and not MF2_DONTDRAW;
  S_StartSound(thing, Ord(sfx_respawn));
end;

//==============================================================================
//
// A_RestoreSpecialThing2
//
//==============================================================================
procedure A_RestoreSpecialThing2(thing: Pmobj_t);
begin
  thing.flags := thing.flags or MF_SPECIAL;
  P_SetMobjState(thing, statenum_t(thing.info.spawnstate));
end;

end.
