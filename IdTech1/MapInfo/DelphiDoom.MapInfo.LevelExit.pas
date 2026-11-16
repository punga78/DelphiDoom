{******************************************************************************}
{                                                                              }
{  DelphiDoom: map info library - what happens when a level ends               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.LevelExit;

interface

type
  /// <summary>The games whose G_DoCompleted fills the intermission (Doom, Radix, Speed; Heretic)</summary>
  TLevelExitGame = (legDoom, legHeretic);

  /// <summary>The custom games that end a level in their own way (customgame of the engine)</summary>
  TLevelExitCustom = (
    /// <summary>None of the following</summary>
    lecNone,
    /// <summary>cg_chex and cg_chex2: the game ends after the map 5</summary>
    lecChex,
    /// <summary>cg_hacx: the game ends after the map 20</summary>
    lecHacx,
    /// <summary>cg_beta (the beta of Heretic): the game ends after the map 3</summary>
    lecBeta
  );

  /// <summary>What G_DoCompleted does before it fills the intermission</summary>
  TLevelExitVerdict = record
    /// <summary>The game is won (gameaction becomes ga_victory) and nothing else happens</summary>
    Victory: Boolean;
    /// <summary>Every player is told that the secret level was found (didsecret)</summary>
    SecretForAll: Boolean;
  end;

  /// <summary>
  ///   The decisions of G_DoCompleted of Doom and Heretic that do not depend on the records of the
  ///   game: the end of the game by map, and the name of the next map in UMAPINFO
  /// </summary>
  TLevelExit = class sealed
  public
    /// <summary>The verdict of a level that ended without a UMAPINFO entry</summary>
    /// <param name="AGame">Doom or Heretic rules</param>
    /// <param name="AIsCommercial">Doom 2 (the maps are MAP01..MAP32); ignored by Heretic</param>
    /// <param name="ACustom">The custom game</param>
    /// <param name="AMap">The map that ended, from 1</param>
    class function Check(const AGame: TLevelExitGame; const AIsCommercial: Boolean;
      const ACustom: TLevelExitCustom; const AMap: Integer): TLevelExitVerdict; static;

    /// <summary>
    ///   The name of the next map from the UMAPINFO entry: the secret one after a secret exit, if
    ///   there is one, else the normal one (empty: UMAPINFO does not say)
    /// </summary>
    class function PickNextMapName(const ASecretExit: Boolean; const ANextSecret,
      ANextMap: string): string; static;
  end;

implementation

{ TLevelExit }

class function TLevelExit.Check(const AGame: TLevelExitGame; const AIsCommercial: Boolean;
  const ACustom: TLevelExitCustom; const AMap: Integer): TLevelExitVerdict;
begin
  Result.Victory := False;
  Result.SecretForAll := False;

  case AGame of
    legDoom:
      begin
        if not AIsCommercial then
        begin
          case AMap of
            8:
              begin
                Result.Victory := True;
                Exit;
              end;
            9: Result.SecretForAll := True;
          end;
        end;

        // JVAL: Chex Support
        if (ACustom = lecChex) and (AMap = 5) then
          Result.Victory := True;

        // JVAL: Hacx Support
        if (ACustom = lecHacx) and (AMap = 20) then
          Result.Victory := True;
      end;
    legHeretic:
      case AMap of
        3: Result.Victory := ACustom = lecBeta;
        8: Result.Victory := True;
        9: Result.SecretForAll := True;
      end;
  end;
end;

class function TLevelExit.PickNextMapName(const ASecretExit: Boolean; const ANextSecret,
  ANextMap: string): string;
begin
  Result := '';
  if ASecretExit then
    Result := ANextSecret;
  if Result = '' then
    Result := ANextMap;
end;

end.
