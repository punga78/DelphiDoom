{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the four games                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Profiles;

interface

uses
  DelphiDoom.Renderer.Types;

type
  /// <summary>
  ///   What each game has in the cold part of the renderer: the values that the old code had in
  ///   its {$IFDEF DOOM}, {$IFDEF HERETIC}, {$IFDEF HEXEN} and {$IFDEF STRIFE}
  /// </summary>
  TRendererProfiles = class
  public
    class function ForGame(AGame: TRendererGame): TRendererProfile; static;
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    class function NameOf(AGame: TRendererGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the four</summary>
    class function TryFromName(const AName: string; out AGame: TRendererGame): Boolean; static;
    /// <summary>
    ///   The number in a side says that the wall has no texture there (zero, or a negative number
    ///   in Heretic and Hexen)
    /// </summary>
    class function IsNoSideTexture(const AProfile: TRendererProfile;
      ASideTexture: Integer): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

const
  GAME_NAMES: array[TRendererGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');
  FRACUNIT = 65536;

{ TRendererProfiles }

class function TRendererProfiles.ForGame(AGame: TRendererGame): TRendererProfile;
begin
  Result.Game := AGame;
  case AGame of
    TRendererGame.Hexen:
      Result.SkyTextureMid := 200 * FRACUNIT;
    TRendererGame.Strife:
      Result.SkyTextureMid := 199 * FRACUNIT;
  else
    Result.SkyTextureMid := 100 * FRACUNIT;
  end;
  Result.NegativeSideTextureIsNone := AGame in [TRendererGame.Heretic, TRendererGame.Hexen];
  Result.CustomColormapsOnSides := not Result.NegativeSideTextureIsNone;
  if Result.NegativeSideTextureIsNone then
    Result.MissingTexture := -1
  else
    Result.MissingTexture := 0;
  Result.DoomLightLevelColumns := AGame = TRendererGame.Doom;
end;

class function TRendererProfiles.NameOf(AGame: TRendererGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TRendererProfiles.TryFromName(const AName: string; out AGame: TRendererGame): Boolean;
var
  LGame: TRendererGame;
begin
  for LGame := Low(TRendererGame) to High(TRendererGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Exit(True);
    end;
  Result := False;
end;

class function TRendererProfiles.IsNoSideTexture(const AProfile: TRendererProfile;
  ASideTexture: Integer): Boolean;
begin
  if AProfile.NegativeSideTextureIsNone then
    Result := ASideTexture < 0
  else
    Result := ASideTexture = 0;
end;

end.
