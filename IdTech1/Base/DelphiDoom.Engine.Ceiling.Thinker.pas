{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the ceiling thinker as the library sees it             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Ceiling.Thinker;

// What changes from a game to the other around a classic ceiling (Doom, Heretic,
// Strife): the enumeration of the kinds, the fields of ceiling_t, where a sector
// keeps its ceiling thinker and the sounds. p_ceilng.pas, one for the three
// games, goes through here and names none of them

interface

uses
{$IFNDEF HERETIC}
  DelphiDoom.Engine.World.SectorSearch,
{$ENDIF}
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  r_defs,
  DelphiDoom.Thinkers.Ceiling.Types;

//==============================================================================
//
// CeilingKindOf
//
// The kind of a classic ceiling (the ceiling_e of the game)
//
//==============================================================================
function CeilingKindOf(AType: ceiling_e): TCeilingKind;

//==============================================================================
//
// CeilingLoadState
//
// Copies the fields of the thinker, which stays a record in the zone memory,
// that the tic works on
//
//==============================================================================
procedure CeilingLoadState(ACeiling: Pceiling_t; out AState: TCeilingState);

//==============================================================================
//
// CeilingStoreState
//
//==============================================================================
procedure CeilingStoreState(ACeiling: Pceiling_t; const AState: TCeilingState);

//==============================================================================
//
// CeilingSectorBusy
//
// True when the sector already has a thinker that moves its ceiling
//
//==============================================================================
function CeilingSectorBusy(ASector: Psector_t): boolean;

//==============================================================================
//
// CeilingAttach
//
// Writes in the sector the thinker of its ceiling (nil: none)
//
//==============================================================================
procedure CeilingAttach(ASector: Psector_t; ACeiling: Pceiling_t);

//==============================================================================
//
// CeilingApply
//
// Does what the tic decided for the sector: the sounds and, for the changers of
// Boom, the special and the texture. The removal is left to the caller
//
//==============================================================================
procedure CeilingApply(ACeiling: Pceiling_t; const AActions: TCeilingActions);

implementation

uses
  s_sound,
  sounddata;

//==============================================================================
//
// CeilingKindOf
//
//==============================================================================
function CeilingKindOf(AType: ceiling_e): TCeilingKind;
begin
  case AType of
    lowerToFloor:
      result := TCeilingKind.LowerToFloor;
    raiseToHighest:
      result := TCeilingKind.RaiseToHighest;
    lowerAndCrush:
      result := TCeilingKind.LowerAndCrush;
    crushAndRaise:
      result := TCeilingKind.CrushAndRaise;
    fastCrushAndRaise:
      result := TCeilingKind.FastCrushAndRaise;
{$IFNDEF HERETIC}
    lowerToLowest:
      result := TCeilingKind.LowerToLowest;
    lowerToMaxFloor:
      result := TCeilingKind.LowerToMaxFloor;
    silentCrushAndRaise:
      result := TCeilingKind.SilentCrushAndRaise;
    genCeiling:
      result := TCeilingKind.GenCeiling;
    genCeilingChg:
      result := TCeilingKind.GenCeilingChg;
    genCeilingChg0:
      result := TCeilingKind.GenCeilingChg0;
    genCeilingChgT:
      result := TCeilingKind.GenCeilingChgT;
    genCrusher:
      result := TCeilingKind.GenCrusher;
    genSilentCrusher:
      result := TCeilingKind.GenSilentCrusher;
{$ENDIF}
  else
    // a scripted ceiling never reaches the classic thinker
    result := TCeilingKind.Other;
  end;
end;

//==============================================================================
//
// CeilingLoadState
//
//==============================================================================
procedure CeilingLoadState(ACeiling: Pceiling_t; out AState: TCeilingState);
begin
  AState.Direction := ACeiling.direction;
  AState.Speed := ACeiling.speed;
{$IFDEF HERETIC}
  // no generalized crushers: nothing reads it
  AState.OldSpeed := 0;
{$ELSE}
  AState.OldSpeed := ACeiling.oldspeed;
{$ENDIF}
end;

//==============================================================================
//
// CeilingStoreState
//
//==============================================================================
procedure CeilingStoreState(ACeiling: Pceiling_t; const AState: TCeilingState);
begin
  // the tic never changes the old speed
  ACeiling.direction := AState.Direction;
  ACeiling.speed := AState.Speed;
end;

//==============================================================================
//
// CeilingSectorBusy
//
//==============================================================================
function CeilingSectorBusy(ASector: Psector_t): boolean;
begin
{$IFDEF HERETIC}
  result := ASector.specialdata <> nil;
{$ELSE}
  result := P_SectorActive(ceiling_special, ASector);
{$ENDIF}
end;

//==============================================================================
//
// CeilingAttach
//
//==============================================================================
procedure CeilingAttach(ASector: Psector_t; ACeiling: Pceiling_t);
begin
{$IFDEF HERETIC}
  ASector.specialdata := ACeiling;
{$ELSE}
  ASector.ceilingdata := ACeiling;
{$ENDIF}
end;

//==============================================================================
//
// CeilingApply
//
//==============================================================================
procedure CeilingApply(ACeiling: Pceiling_t; const AActions: TCeilingActions);
begin
  if TCeilingAction.MoveSound in AActions then
{$IFDEF HERETIC}
    S_StartSound(@ACeiling.sector.soundorg, Ord(sfx_dormov));
{$ELSE}
    S_StartSound(@ACeiling.sector.soundorg, Ord(sfx_stnmov));

  if TCeilingAction.TransferSpecial in AActions then
  begin
    ACeiling.sector.special := ACeiling.newspecial;
    //jff 3/14/98 transfer old special field as well
    ACeiling.sector.oldspecial := ACeiling.oldspecial;
  end;

  if TCeilingAction.ChangeTexture in AActions then
    ACeiling.sector.ceilingpic := ACeiling.texture;

  if TCeilingAction.StopSound in AActions then
    S_StartSound(@ACeiling.sector.soundorg, Ord(sfx_pstop));
{$ENDIF}
end;

end.
