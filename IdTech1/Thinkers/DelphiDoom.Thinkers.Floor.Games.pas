{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - what each game has for its floors            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Floor.Games;

interface

uses
  DelphiDoom.Thinkers.Platform.Types, DelphiDoom.Thinkers.Floor.Types;

type
  /// <summary>
  ///   The rules of the classic floors of Doom and of Strife (the differences of the two
  ///   p_floor). Heretic has its own p_floor and takes the rules of Doom here
  /// </summary>
  TFloorGames = class sealed
  public
    /// <summary>The rules of a game</summary>
    class function ProfileOf(AGame: TPlatGame): TFloorProfile; static;
  end;

implementation

{ TFloorGames }

class function TFloorGames.ProfileOf(AGame: TPlatGame): TFloorProfile;
begin
  // haleyjd 09/16/2010: in Strife turboLower does not adjust the floor height
  Result.TurboLowerStopsAbove := AGame <> TPlatGame.Strife;
  Result.StrifeStairs := AGame = TPlatGame.Strife;
end;

end.
