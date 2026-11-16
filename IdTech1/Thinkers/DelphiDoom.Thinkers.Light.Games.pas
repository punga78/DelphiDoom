{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - what each game has for its lights            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Games;

interface

uses
  System.SysUtils, DelphiDoom.Thinkers.Light.Types;

type
  /// <summary>
  ///   The numbers of the games for the sequences of phased lights (the specials of the sectors
  ///   in their doomdef and p_spec): the profile replaces the compiler switches of the old code
  /// </summary>
  TLightGames = class
  public
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    class function NameOf(AGame: TLightGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the four</summary>
    class function TryFromName(const AName: string; out AGame: TLightGame): Boolean; static;
    /// <summary>The specials and the mask of the phased lights of a game</summary>
    class function SequenceProfile(AGame: TLightGame): TLightSequenceProfile; static;
  end;

implementation

const
  GAME_NAMES: array[TLightGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');

{ TLightGames }

class function TLightGames.NameOf(AGame: TLightGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TLightGames.TryFromName(const AName: string; out AGame: TLightGame): Boolean;
var
  LGame: TLightGame;
begin
  Result := False;
  AGame := TLightGame.Doom;
  for LGame := Low(TLightGame) to High(TLightGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Result := True;
      Break;
    end;
end;

class function TLightGames.SequenceProfile(AGame: TLightGame): TLightSequenceProfile;
begin
  case AGame of
    TLightGame.Heretic:
      begin
        Result.SequenceStart := 52;
        Result.Sequence := 53;
        Result.SequenceAlt := 54;
        Result.PhaseMask := $FFFF;
      end;
    TLightGame.Hexen:
      begin
        Result.SequenceStart := 2;
        Result.Sequence := 3;
        Result.SequenceAlt := 4;
        Result.PhaseMask := $FFFF;
      end;
  else
    // Doom and Strife keep the sector types in the low 5 bits
    Result.SequenceStart := 22;
    Result.Sequence := 23;
    Result.SequenceAlt := 24;
    Result.PhaseMask := 31;
  end;
end;

end.
