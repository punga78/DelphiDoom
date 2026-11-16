{******************************************************************************}
{                                                                              }
{  DelphiDoom: map info library - the plan of the intermission (G_DoCompleted)  }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.IntermissionPlanner;

interface

uses
  DelphiDoom.MapInfo.LevelExit,
  DelphiDoom.MapInfo.LevelProgression,
  DelphiDoom.MapInfo.MapName;

type
  /// <summary>
  ///   What G_DoCompleted of Doom and Heretic knows when a level ends and has to fill wminfo
  /// </summary>
  TIntermissionRequest = record
    /// <summary>Doom (also Radix and Speed) or Heretic rules</summary>
    Game: TLevelExitGame;
    /// <summary>Doom 2 (maps MAP01..MAP32); ignored by Heretic</summary>
    IsCommercial: Boolean;
    /// <summary>The custom game that ends the level in its own way</summary>
    Custom: TLevelExitCustom;
    /// <summary>The custom game is the BFG edition of Doom 2 (cg_bfg2)</summary>
    IsBfgSecondEdition: Boolean;
    /// <summary>The level ended with the secret exit</summary>
    SecretExit: Boolean;
    /// <summary>The episode that ended, from 1</summary>
    Episode: Integer;
    /// <summary>The map that ended, from 1</summary>
    Map: Integer;
    /// <summary>The player of the console has found the secret level (players[consoleplayer].didsecret)</summary>
    ConsoleDidSecret: Boolean;
    /// <summary>The value wminfo.next had before this call (0 biased); kept if nothing says where to go</summary>
    PreviousNext: Integer;
    /// <summary>The map has a UMAPINFO entry</summary>
    HasMapInfo: Boolean;
    /// <summary>The entry has an end picture that is not "-"</summary>
    HasEndPicture: Boolean;
    /// <summary>The entry says that there is no intermission</summary>
    NoIntermission: Boolean;
    /// <summary>The next secret map of the entry (empty: none)</summary>
    NextSecret: string;
    /// <summary>The next map of the entry (empty: none)</summary>
    NextMap: string;
    /// <summary>The par time of the entry, as the entry has it</summary>
    MapInfoPartime: Integer;
    /// <summary>What the game accepts as the name of a map</summary>
    Rules: TMapNameRules;
  end;

  /// <summary>The numbers of wminfo that G_DoCompleted decides, and the two ways out of it</summary>
  TIntermissionPlan = record
    /// <summary>The game ends with the level (the verdict of the maps): nothing else is written</summary>
    EndsGame: Boolean;
    /// <summary>Every player has found the secret level: players[i].didsecret becomes true</summary>
    SecretForAll: Boolean;
    /// <summary>
    ///   The game ends here without an intermission (UMAPINFO): the numbers below are written
    ///   first, as the old code did, and then the game ends
    /// </summary>
    EndsWithoutIntermission: Boolean;
    /// <summary>The next map is in another episode: players[i].didsecret becomes false</summary>
    ResetPlayersDidSecret: Boolean;
    /// <summary>wminfo.didsecret</summary>
    DidSecret: Boolean;
    /// <summary>wminfo.epsd, 0 biased</summary>
    Epsd: Integer;
    /// <summary>wminfo.nextep, 0 biased</summary>
    NextEp: Integer;
    /// <summary>wminfo.last, 0 biased</summary>
    Last: Integer;
    /// <summary>wminfo.next, 0 biased</summary>
    Next: Integer;
    /// <summary>The par time comes from the entry (wminfo.partime := MapInfoPartime), else from the tables of the game</summary>
    PartimeFromMapInfo: Boolean;
    /// <summary>The par time of the entry (only if PartimeFromMapInfo)</summary>
    Partime: Integer;
  end;

  /// <summary>
  ///   The decisions of G_DoCompleted of Doom and Heretic that fill wminfo: where the game goes
  ///   next, which episode, who has found the secret, how the level ends. The record wminfo, the
  ///   players and the tables of the par times stay with the game
  /// </summary>
  TIntermissionPlanner = class sealed
  public
    /// <summary>Plans the end of a level</summary>
    class function Plan(const ARequest: TIntermissionRequest): TIntermissionPlan; static;
  end;

implementation

{ TIntermissionPlanner }

class function TIntermissionPlanner.Plan(const ARequest: TIntermissionRequest): TIntermissionPlan;
var
  LVerdict: TLevelExitVerdict;
  LNextName: string;
  LNextEpisode: Integer;
  LNextMap: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);

  LVerdict := TLevelExit.Check(ARequest.Game, ARequest.IsCommercial, ARequest.Custom,
    ARequest.Map);
  Result.SecretForAll := LVerdict.SecretForAll;
  if LVerdict.Victory then
  begin
    Result.EndsGame := True;
    Exit;
  end;

  Result.DidSecret := ARequest.ConsoleDidSecret or LVerdict.SecretForAll;
  Result.Epsd := ARequest.Episode - 1;
  Result.NextEp := ARequest.Episode - 1;
  Result.Last := ARequest.Map - 1;
  Result.Next := ARequest.PreviousNext;

  if ARequest.HasMapInfo then
  begin
    if ARequest.HasEndPicture and ARequest.NoIntermission then
    begin
      Result.EndsWithoutIntermission := True;
      Exit;
    end;

    LNextName := TLevelExit.PickNextMapName(ARequest.SecretExit, ARequest.NextSecret,
      ARequest.NextMap);
    if LNextName <> '' then
      if TMapName.TryParse(LNextName, ARequest.Rules, LNextEpisode, LNextMap) then
      begin
        Result.NextEp := LNextEpisode - 1;
        Result.Next := LNextMap - 1;
        // episode change
        if Result.NextEp <> Result.Epsd then
        begin
          Result.ResetPlayersDidSecret := True;
          Result.DidSecret := False;
        end;
        Result.PartimeFromMapInfo := True;
        Result.Partime := ARequest.MapInfoPartime;
        Exit;
      end;
  end;

  // wminfo.next is 0 biased, unlike the map
  case ARequest.Game of
    legDoom:
      TLevelProgression.DoomNextMap(ARequest.IsCommercial, ARequest.SecretExit,
        ARequest.IsBfgSecondEdition, ARequest.Episode, ARequest.Map, Result.Next);
    legHeretic:
      TLevelProgression.HereticNextMap(ARequest.SecretExit, ARequest.Episode, ARequest.Map,
        Result.Next);
  end;
end;

end.
