{******************************************************************************}
{                                                                              }
{  DelphiDoom: map info library - the names of the maps                        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.MapName;

interface

type
  /// <summary>
  ///   What a game accepts as the name of a map: the lengths, the form ExMy (the length it must
  ///   have) and the form MAPxx (G_ValidateMapName differs a little in each game)
  /// </summary>
  TMapNameRules = record
    /// <summary>The lengths of a name worth looking at (more are refused at once)</summary>
    Lengths: set of Byte;
    /// <summary>The length of a name in the form ExMy, 0 if the game does not have the form</summary>
    EpisodeFormLength: Integer;
    /// <summary>The form MAPxx (always 5 characters) is accepted</summary>
    NumberedForm: Boolean;
  end;

  /// <summary>
  ///   Reads and writes the names of the maps of the games (E1M1, MAP01): G_ValidateMapName and
  ///   the names G_LookupMapinfo looks for
  /// </summary>
  TMapName = class sealed
  public
    /// <summary>The rules of Doom: ExMy of 4 characters and MAPxx</summary>
    class function DoomRules: TMapNameRules; static;
    /// <summary>The rules of Heretic: only ExMy of 4 characters</summary>
    class function HereticRules: TMapNameRules; static;
    /// <summary>The rules of Strife: ExMy and MAPxx, both of 5 characters</summary>
    class function StrifeRules: TMapNameRules; static;

    /// <summary>Tells if a name is the one of a map of the game and which map it is</summary>
    /// <param name="AName">The name, in any case</param>
    /// <param name="ARules">What the game accepts</param>
    /// <param name="AEpisode">The episode, 0 in the form MAPxx; untouched if the name is refused</param>
    /// <param name="AMap">The number of the map; untouched if the name is refused</param>
    /// <remarks>
    ///   The number is read as the engine reads numbers (atoi), so for a name of 5 characters
    ///   MAP#5 and MAP$A are numbers too; E1M0 and MAP00 are refused
    /// </remarks>
    class function TryParse(const AName: string; const ARules: TMapNameRules;
      out AEpisode, AMap: Integer): Boolean; static;

    /// <summary>
    ///   The map the console command newgame asks for (G_CmdNewGame): the arguments are the numbers
    ///   (map, or episode and map) or a name (MAPxx, or ExMy when the second argument is empty)
    /// </summary>
    /// <param name="ANumberedMaps">The game has maps numbered from 1 (Doom 2, Strife): the first argument is the map</param>
    /// <param name="AArgument1">The first argument, not empty</param>
    /// <param name="AArgument2">The second argument, empty if the command had one</param>
    /// <param name="AEpisode">The episode, 0 for the games with numbered maps</param>
    /// <param name="AMap">The map; the numbers are read as the engine reads them (atoi)</param>
    class procedure FromArguments(const ANumberedMaps: Boolean; const AArgument1, AArgument2: string;
      out AEpisode, AMap: Integer); static;

    /// <summary>The name of a map in the form ExMy</summary>
    class function EpisodeName(const AEpisode, AMap: Integer): string; static;
    /// <summary>The name of a map in the form MAPxx (two digits at least)</summary>
    class function NumberedName(const AMap: Integer): string; static;
  end;

implementation

uses
  System.SysUtils;

// The atoi of the engine (d_delphi) for the few characters of a name: Val and the # prefix
function NameNumber(const AText: string): Integer;
var
  LCode: Integer;
  LAlternative: Integer;
begin
  Val(AText, Result, LCode);
  if LCode <> 0 then
  begin
    LAlternative := 0;
    if Copy(AText, 1, 2) = '0x' then
      Val('$' + Copy(AText, 3, Length(AText) - 2), LAlternative, LCode)
    else if Copy(AText, 1, 3) = '-0x' then
    begin
      Val('$' + Copy(AText, 4, Length(AText) - 3), LAlternative, LCode);
      LAlternative := -LAlternative;
    end
    else if (Length(AText) > 0) and (AText[1] = '#') then
      Val(Copy(AText, 2, Length(AText) - 1), LAlternative, LCode)
    else
      LCode := -1;
    if LCode = 0 then
      Result := LAlternative
    else
      Result := 0;
  end;
end;

function IsDecimalDigit(const AChar: Char): Boolean;
begin
  Result := CharInSet(AChar, ['0'..'9']);
end;

{ TMapName }

class function TMapName.DoomRules: TMapNameRules;
begin
  Result.Lengths := [4, 5];
  Result.EpisodeFormLength := 4;
  Result.NumberedForm := True;
end;

class function TMapName.HereticRules: TMapNameRules;
begin
  Result.Lengths := [4];
  Result.EpisodeFormLength := 4;
  Result.NumberedForm := False;
end;

class function TMapName.StrifeRules: TMapNameRules;
begin
  Result.Lengths := [5];
  Result.EpisodeFormLength := 5;
  Result.NumberedForm := True;
end;

class function TMapName.TryParse(const AName: string; const ARules: TMapNameRules;
  out AEpisode, AMap: Integer): Boolean;
var
  LName: string;
  LEpisode: Integer;
  LMap: Integer;
  LIndex: Integer;
begin
  Result := False;
  if (Length(AName) > 255) or not (Byte(Length(AName)) in ARules.Lengths) then
    Exit;

  LEpisode := 0;
  LMap := 0;
  // only the letters a-z go to upper case, as strupper of the engine
  LName := AName;
  for LIndex := 1 to Length(LName) do
    if (LName[LIndex] >= 'a') and (LName[LIndex] <= 'z') then
      LName[LIndex] := Char(Ord(LName[LIndex]) - 32);

  if (LName[1] = 'E') and (LName[3] = 'M') then
  begin
    if Length(LName) = ARules.EpisodeFormLength then
    begin
      if not IsDecimalDigit(LName[2]) then
        Exit;
      LEpisode := NameNumber(LName[2]);
      LMap := NameNumber(LName[4]);
      Result := (LEpisode >= 1) and (LEpisode <= 8) and (LMap >= 1) and (LMap <= 9);
    end;
  end
  else if ARules.NumberedForm and (LName[1] = 'M') and (LName[2] = 'A') and (LName[3] = 'P') then
  begin
    if Length(LName) = 5 then
    begin
      LMap := NameNumber(LName[4] + LName[5]);
      Result := (LMap >= 1) and (LMap <= 99);
    end;
  end;

  if Result then
  begin
    AEpisode := LEpisode;
    AMap := LMap;
  end;
end;

class procedure TMapName.FromArguments(const ANumberedMaps: Boolean; const AArgument1,
  AArgument2: string; out AEpisode, AMap: Integer);
var
  LName: string;
  LIndex: Integer;
begin
  LName := AArgument1;
  for LIndex := 1 to Length(LName) do
    if (LName[LIndex] >= 'a') and (LName[LIndex] <= 'z') then
      LName[LIndex] := Char(Ord(LName[LIndex]) - 32);

  if ANumberedMaps then
  begin
    AEpisode := 0;
    AMap := NameNumber(AArgument1);
    if (Length(LName) = 5) and (LName[1] = 'M') and (LName[2] = 'A') and (LName[3] = 'P') then
      AMap := NameNumber(LName[4] + LName[5]);
  end
  else
  begin
    AEpisode := NameNumber(AArgument1);
    AMap := NameNumber(AArgument2);
    if (AArgument2 = '') and (Length(LName) = 4) and (LName[1] = 'E') and (LName[3] = 'M') then
    begin
      AEpisode := NameNumber(LName[2]);
      AMap := NameNumber(LName[4]);
    end;
  end;
end;

class function TMapName.EpisodeName(const AEpisode, AMap: Integer): string;
begin
  Result := Format('E%dM%d', [AEpisode, AMap]);
end;

class function TMapName.NumberedName(const AMap: Integer): string;
begin
  Result := Format('MAP%.2d', [AMap]);
end;

end.
