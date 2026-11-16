{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the definitions read at the start of the play loop     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Definitions.Intf;

interface

type
  /// <summary>
  ///   Reads the lump ANIMDEFS in the animations of p_animdefs.pas (the lists of the animated
  ///   flats and textures and the frames that P_AnimateSurfaces plays). It was P_InitFTAnims
  /// </summary>
  IEngineAnimDefsLoader = interface
    ['{8C1A5F24-3B07-4E9D-A26B-D490E71C5F38}']
    /// <summary>Makes the lists of the animated pictures (empty) and reads the lump if there is one</summary>
    procedure Load;
    /// <summary>Frees the lists of the animated pictures (it was P_ShutDownAnimations)</summary>
    procedure Release;
  end;

  /// <summary>
  ///   Makes the list of the switches of the game (the lump SWITCHES or the table of the game)
  ///   that the buttons change. It was P_InitSwitchList of Doom
  /// </summary>
  IEngineSwitchListLoader = interface
    ['{4D97B0E6-1F25-4A83-9C5E-07B2A6E8D391}']
    procedure Load;
  end;

implementation

end.
