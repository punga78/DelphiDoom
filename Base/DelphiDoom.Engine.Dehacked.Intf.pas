{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what a DEHACKED patch does to the game                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Dehacked.Intf;

interface

type
  /// <summary>
  ///   Reads a DEHACKED or BEX patch with the parser of Libs\Dehacked and applies it to the
  ///   tables of the game (mobjinfo, states, weapons, ammo, sounds, music, strings, pars).
  ///   One class for each game (TEngineDehackedApplier in the folder of the game); the
  ///   composition root gives it to deh_base. It was DEH_Parse and DEH_Apply of deh_main
  /// </summary>
  IEngineDehackedApplier = interface
    ['{93A7C1E4-5D02-4B68-8E3F-C71A0D5B92E6}']
    /// <summary>The lines of the patch, in the order of the file</summary>
    procedure Apply(const ALines: TArray<string>);
  end;

implementation

end.
