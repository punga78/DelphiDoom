{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - contract of the genetic selection (be_ai_gen.c)        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Gen.Intf;

interface

type
  /// <summary>The selection of the parents and of the child of the genetic evolution of the bots</summary>
  IBotGenetics = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F90}']
    /// <summary>GeneticSelection: the index of a bot (rankings below 0 do not take part)</summary>
    function Selection(const ARankings: TArray<Single>): Integer;
    /// <summary>
    ///   GeneticParentsAndChildSelection: two parents (the ones with the highest rankings) and a child (the one with
    ///   the lowest); false, with the three numbers 0 and a warning, with more than 256 bots or with fewer than three
    ///   valid ones.
    /// </summary>
    function ParentsAndChildSelection(const ARanks: TArray<Single>; out AParent1, AParent2, AChild: Integer): Boolean;
  end;

implementation

end.
