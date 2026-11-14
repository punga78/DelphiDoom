{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what a game changes in the generalized lines of Boom   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Generalized.Rules;

// The few points where the generalized lines of Doom and of Strife differ
// (p_genlin.pas, one unit for the two games, names neither): the sounds of the
// doors and the stairs of the old demos. The kinds of the doors go through
// DelphiDoom.Engine.Door.Kinds

interface

uses
  m_fixed,
  r_defs;

//==============================================================================
//
// GenStairsStepBeforeLockout
//
// True when the height of the next step grows before the check of the sector
// that is already moving (the old demos of Doom: a skipped sector still counts
// as a step); false when it grows after it (jff 6/19/98)
//
//==============================================================================
function GenStairsStepBeforeLockout: boolean;

//==============================================================================
//
// GenDoorStartOpenSound
//
// The sound of a generalized door that opens at ASpeed
//
//==============================================================================
procedure GenDoorStartOpenSound(ASector: Psector_t; ASpeed: fixed_t);

//==============================================================================
//
// GenDoorStartCloseSound
//
// The sound of a generalized door that closes
//
//==============================================================================
procedure GenDoorStartCloseSound(ASector: Psector_t);

implementation

uses
{$IFDEF DOOM}
  g_game,
{$ENDIF}
  p_spec,
  s_sound,
  sounddata;

//==============================================================================
//
// GenStairsStepBeforeLockout
//
//==============================================================================
function GenStairsStepBeforeLockout: boolean;
begin
{$IFDEF DOOM}
  result := G_IsOldDemoPlaying;
{$ELSE}
  result := false;
{$ENDIF}
end;

//==============================================================================
//
// GenDoorStartOpenSound
//
//==============================================================================
procedure GenDoorStartOpenSound(ASector: Psector_t; ASpeed: fixed_t);
begin
{$IFDEF DOOM}
  // killough 4/15/98: fix generalized door opening sounds
  // (previously they always had the blazing door close sound)
  if ASpeed >= VDOORSPEED * 4 then
    S_StartSound(@ASector.soundorg, Ord(sfx_bdopn))  // killough 4/15/98
  else
    S_StartSound(@ASector.soundorg, Ord(sfx_doropn));
{$ELSE}
  S_StartSound(@ASector.soundorg, Ord(sfx_bdopn));
{$ENDIF}
end;

//==============================================================================
//
// GenDoorStartCloseSound
//
//==============================================================================
procedure GenDoorStartCloseSound(ASector: Psector_t);
begin
{$IFDEF DOOM}
  S_StartSound(@ASector.soundorg, Ord(sfx_dorcls));
{$ELSE}
  S_StartSound(@ASector.soundorg, Ord(sfx_bdcls));
{$ENDIF}
end;

end.
