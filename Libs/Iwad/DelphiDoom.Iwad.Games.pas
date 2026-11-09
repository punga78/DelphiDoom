{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the profiles of the games                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.Games;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  TIwadGame = (igDoom, igHeretic, igHexen, igStrife, igRadix);

  /// <summary>
  ///   The profile of each game: the IWADs it knows, in order of priority, the variables and
  ///   the Steam applications where it is looked for. The differences between the games are
  ///   data here, not conditional compilation
  /// </summary>
  TIwadGames = class
  public
    /// <summary>DOOM, HERETIC, HEXEN, STRIFE or RADIX</summary>
    class function NameOf(AGame: TIwadGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the five</summary>
    class function TryFromName(const AName: string; out AGame: TIwadGame): Boolean; static;
    class function CreateProfile(AGame: TIwadGame): IIwadProfile; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Iwad.Types, DelphiDoom.Iwad.Profile;

const
  GAME_NAMES: array[TIwadGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE', 'RADIX');

function WithSearchable(const AEntry: TIwadEntry; ASearchable: Boolean): TIwadEntry;
begin
  Result := AEntry;
  Result.Searchable := ASearchable;
end;

function AsFrench(const AEntry: TIwadEntry): TIwadEntry;
begin
  Result := AEntry;
  Result.IsFrench := True;
end;

function AsBfg2(const AEntry: TIwadEntry): TIwadEntry;
begin
  Result := AEntry;
  Result.IsBfg2 := True;
end;

function WithCompanion(const AEntry: TIwadEntry; const AFileName: string): TIwadEntry;
begin
  Result := AEntry;
  Result.CompanionFileName := AFileName;
end;

function DoomProfile: IIwadProfile;
begin
  // the BFG editions are only taken where they are named: they were never looked for
  // in the other search paths
  Result := TIwadProfile.Create('DOOM',
    TArray<TIwadEntry>.Create(
      WithSearchable(AsBfg2(TIwadEntry.Make('doom2bfg.wad', igmCommercial, imsDoom2)), False),
      AsFrench(TIwadEntry.Make('doom2f.wad', igmCommercial, imsDoom2)),
      TIwadEntry.Make('doom2.wad', igmCommercial, imsDoom2),
      TIwadEntry.Make('plutonia.wad', igmCommercial, imsPlutonia),
      TIwadEntry.Make('tnt.wad', igmCommercial, imsTnt),
      WithSearchable(TIwadEntry.Make('doombfg.wad', igmRetail, imsDoom), False),
      // registered or retail: the engine decides later from the lumps
      TIwadEntry.Make('doomu.wad', igmIndetermined, imsDoom),
      TIwadEntry.Make('doom.wad', igmIndetermined, imsDoom),
      TIwadEntry.Make('doom1.wad', igmShareware, imsDoom)),
    TArray<TIwadCustomRule>.Create(),
    TArray<string>.Create('DOOMWADDIR'),
    TArray<string>.Create('DOOMWADPATH'),
    TArray<Integer>.Create(2280, 2290, 2300),
    'DOOMWADDIR');
end;

function HereticProfile: IIwadProfile;
begin
  Result := TIwadProfile.Create('HERETIC',
    TArray<TIwadEntry>.Create(
      // registered or extended: the engine decides later
      TIwadEntry.Make('heretic.wad', igmIndetermined),
      TIwadEntry.Make('heretic1.wad', igmShareware)),
    TArray<TIwadCustomRule>.Create(),
    TArray<string>.Create('HERETICWADDIR', 'DOOMWADDIR'),
    TArray<string>.Create('HERETICWADPATH', 'DOOMWADPATH'),
    TArray<Integer>.Create(2390),
    '');
end;

function HexenProfile: IIwadProfile;
begin
  Result := TIwadProfile.Create('HEXEN',
    TArray<TIwadEntry>.Create(
      TIwadEntry.Make('hexen.wad', igmIndetermined),
      TIwadEntry.Make('hexen1.wad', igmShareware),
      TIwadEntry.Make('hexendem.wad', igmShareware)),
    // Deathkings of the Dark Citadel is an add-on of Hexen: Hexen is added first
    TArray<TIwadCustomRule>.Create(
      TIwadCustomRule.Make('HEXDD.WAD', icrPrerequisite, 'hexen.wad')),
    TArray<string>.Create('HEXENWADDIR', 'DOOMWADDIR'),
    TArray<string>.Create('HEXENWADPATH', 'DOOMWADPATH'),
    TArray<Integer>.Create(2360, 2370),
    '');
end;

function StrifeProfile: IIwadProfile;
begin
  Result := TIwadProfile.Create('STRIFE',
    TArray<TIwadEntry>.Create(
      WithCompanion(TIwadEntry.Make('strife1.wad', igmRegistered), 'voices.wad'),
      TIwadEntry.Make('strife0.wad', igmShareware)),
    // the voices are next to the registered game, wherever the player took it from
    TArray<TIwadCustomRule>.Create(
      TIwadCustomRule.Make('STRIFE1.WAD', icrCompanion, 'voices.wad')),
    TArray<string>.Create('STRIFEWADDIR', 'DOOMWADDIR'),
    TArray<string>.Create('STRIFEWADPATH', 'DOOMWADPATH'),
    TArray<Integer>.Create(317040),
    '');
end;

function RadixProfile: IIwadProfile;
begin
  // Radix has no IWAD: its data are RADIX.DAT, a container that the engine translates into a WAD
  // in memory (Libs\Radix); the version (shareware or registered) is told by the CRC of the file
  Result := TIwadProfile.Create('RADIX',
    TArray<TIwadEntry>.Create(
      TIwadEntry.Make('radix.dat', igmIndetermined)),
    TArray<TIwadCustomRule>.Create(),
    TArray<string>.Create('RADIXWADDIR', 'DOOMWADDIR'),
    TArray<string>.Create('RADIXWADPATH', 'DOOMWADPATH'),
    TArray<Integer>.Create(),
    '');
end;

{ TIwadGames }

class function TIwadGames.NameOf(AGame: TIwadGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TIwadGames.TryFromName(const AName: string; out AGame: TIwadGame): Boolean;
var
  LGame: TIwadGame;
begin
  for LGame := Low(TIwadGame) to High(TIwadGame) do
  begin
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Exit(True);
    end;
  end;
  AGame := igDoom;
  Result := False;
end;

class function TIwadGames.CreateProfile(AGame: TIwadGame): IIwadProfile;
begin
  case AGame of
    igDoom: Result := DoomProfile;
    igHeretic: Result := HereticProfile;
    igHexen: Result := HexenProfile;
    igRadix: Result := RadixProfile;
  else
    Result := StrifeProfile;
  end;
end;

end.
