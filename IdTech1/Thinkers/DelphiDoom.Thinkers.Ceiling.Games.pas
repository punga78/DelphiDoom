{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - what each game has for its ceilings          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Ceiling.Games;

interface

uses
  DelphiDoom.Thinkers.Platform.Types, DelphiDoom.Thinkers.Ceiling.Types;

type
  /// <summary>
  ///   The rules of the classic ceilings of each game (the differences of the three p_ceilng).
  ///   The games are the ones of the classic platforms (TPlatGame): Hexen has neither
  /// </summary>
  TCeilingGames = class sealed
  public
    /// <summary>The rules of a game</summary>
    class function ProfileOf(AGame: TPlatGame): TCeilingProfile; static;
  end;

implementation

{ TCeilingGames }

class function TCeilingGames.ProfileOf(AGame: TPlatGame): TCeilingProfile;
begin
  Result.FastCrushSpeedFactor := 2;
  Result.CrushAndRaiseCrushes := True;
  Result.LowerAndCrushReachesFloor := False;
  Result.WakeUpCounts := True;
  case AGame of
    TPlatGame.Heretic:
      Result.WakeUpCounts := False;
    TPlatGame.Strife:
      begin
        // haleyjd 10/04/10: fast crushers twice as fast, lowerAndCrush "fixed" to crush and to
        // reach the floor, the crushers that go back up no longer crush
        Result.FastCrushSpeedFactor := 4;
        Result.CrushAndRaiseCrushes := False;
        Result.LowerAndCrushReachesFloor := True;
      end;
  end;
end;

end.
