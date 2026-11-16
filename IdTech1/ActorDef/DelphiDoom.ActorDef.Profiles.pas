{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the four games                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.Profiles;

interface

uses
  DelphiDoom.ActorDef.Types;

type
  /// <summary>
  ///   What each game has in its definitions: the values that the old code had in its
  ///   {$IFDEF DOOM}, {$IFDEF HERETIC}, {$IFDEF HEXEN} and {$IFDEF STRIFE}
  /// </summary>
  TActorDefProfiles = class
  public
    class function ForGame(AGame: TActorDefGame): TActorDefProfile; static;
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    class function NameOf(AGame: TActorDefGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the four</summary>
    class function TryFromName(const AName: string; out AGame: TActorDefGame): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

const
  GAME_NAMES: array[TActorDefGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');

{ TActorDefProfiles }

class function TActorDefProfiles.ForGame(AGame: TActorDefGame): TActorDefProfile;
begin
  Result.Game := AGame;
  Result.HasFlags2 := AGame in [TActorDefGame.Heretic, TActorDefGame.Hexen];
  Result.HasStrifeName := AGame = TActorDefGame.Strife;
  Result.KeywordsUseFlags2 := AGame = TActorDefGame.Hexen;
  Result.WeaponHasLevel := AGame = TActorDefGame.Heretic;
  if AGame = TActorDefGame.Heretic then
    Result.WeaponDefaultLevel := 1
  else
    Result.WeaponDefaultLevel := 0;
  Result.WeaponHasPlayerClass := AGame = TActorDefGame.Hexen;
  Result.WeaponStatesWriteFlagsEx := AGame <> TActorDefGame.Strife;
  Result.SoundInfoHexenExtensions := AGame = TActorDefGame.Hexen;
end;

class function TActorDefProfiles.NameOf(AGame: TActorDefGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TActorDefProfiles.TryFromName(const AName: string; out AGame: TActorDefGame): Boolean;
var
  LGame: TActorDefGame;
begin
  for LGame := Low(TActorDefGame) to High(TActorDefGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Exit(True);
    end;
  Result := False;
end;

end.
