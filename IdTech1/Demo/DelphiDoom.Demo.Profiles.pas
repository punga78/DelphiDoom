{******************************************************************************}
{                                                                              }
{  DelphiDoom: demo library - the header of each game                          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Demo.Profiles;

interface

uses
  DelphiDoom.Demo.Types;

type
  /// <summary>
  ///   The header profile of each game: the only place where the differences between the demos
  ///   of Doom, Heretic, Hexen and Strife are written
  /// </summary>
  TDemoProfiles = class sealed
  public
    /// <summary>Doom (and the games that run on it): the dogs, and old demos with no magic</summary>
    class function Doom(const APlayerCount: Integer): TDemoHeaderProfile; static;

    /// <summary>Heretic: no dogs; spawnrandommonsters always, the seed from version 1.13</summary>
    class function Heretic(const APlayerCount: Integer): TDemoHeaderProfile; static;

    /// <summary>Hexen: like Heretic with a different magic and the seed from version 2.07</summary>
    class function Hexen(const APlayerCount: Integer): TDemoHeaderProfile; static;

    /// <summary>Strife: no episode, no dogs, spawnrandommonsters and seed always</summary>
    class function Strife(const APlayerCount: Integer): TDemoHeaderProfile; static;
  end;

implementation

{ TDemoProfiles }

class function TDemoProfiles.Doom(const APlayerCount: Integer): TDemoHeaderProfile;
begin
  Result := Default(TDemoHeaderProfile);
  Result.Magic := $4F4D4544; // DEMO
  Result.HasEpisode := True;
  Result.HasDogs := True;
  Result.DogsMinVersion := 205;
  Result.SpawnRandomMinVersion := 114;
  Result.SeedMinVersion := 120;
  Result.PlayerCount := APlayerCount;
end;

class function TDemoProfiles.Heretic(const APlayerCount: Integer): TDemoHeaderProfile;
begin
  Result := Default(TDemoHeaderProfile);
  Result.Magic := $4D454448; // HDEM
  Result.HasEpisode := True;
  Result.SeedMinVersion := 113;
  Result.PlayerCount := APlayerCount;
end;

class function TDemoProfiles.Hexen(const APlayerCount: Integer): TDemoHeaderProfile;
begin
  Result := Default(TDemoHeaderProfile);
  Result.Magic := $4D454458; // XDEM
  Result.HasEpisode := True;
  Result.SeedMinVersion := 207;
  Result.PlayerCount := APlayerCount;
end;

class function TDemoProfiles.Strife(const APlayerCount: Integer): TDemoHeaderProfile;
begin
  Result := Default(TDemoHeaderProfile);
  Result.Magic := $4F4D4544; // DEMO
  Result.PlayerCount := APlayerCount;
end;

end.
