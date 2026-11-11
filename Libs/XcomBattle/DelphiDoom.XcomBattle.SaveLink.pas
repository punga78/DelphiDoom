{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the battle inside a saved game        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.SaveLink;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.MapDataLoader,
  DelphiDoom.XcomMod.McdPatch, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.SavedBattleGame;

type
  /// <summary>
  ///   Joins SavedGame and SavedBattleGame: the saved game keeps the "battleGame" document as it is (it cannot
  ///   depend on this library) and this class turns it into a battle and back, as SavedGame::load and
  ///   SavedGame::save do with their _battleGame
  /// </summary>
  TXcomBattleSaveLink = class
  public
    /// <summary>
    ///   SavedBattleGame::load of the "battleGame" of AGame with its soldiers, then loadMapResources (the data of
    ///   the map data sets and the parts of every tile); nil if the saved game is not in a battle. The caller
    ///   frees the battle
    /// </summary>
    class function LoadBattle(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
      const AContext: IXcomBattleContext): TXcomSavedBattleGame; static;
    /// <summary>SavedGame::_battleGame = battle: the saved game writes the battle in its "battleGame"</summary>
    class procedure StoreBattle(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame); static;
  end;

implementation

class function TXcomBattleSaveLink.LoadBattle(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const AContext: IXcomBattleContext): TXcomSavedBattleGame;
var
  LLoader: TXcomMapDataLoader;
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
begin
  if not Assigned(AGame.BattleGame) then
    Exit(nil);
  Result := TXcomSavedBattleGame.Create(AContext);
  try
    Result.Load(AGame.BattleGame, ARuleset, AGame.Difficulty,
      function(AId: Integer): TXcomSoldier
      var
        LBase: TXcomBase;
        LSoldier: TXcomSoldier;
      begin
        // SavedGame::getSoldier: the soldiers of the bases, then the dead ones (killed earlier in this battle)
        for LBase in AGame.Bases do
          for LSoldier in LBase.Soldiers do
            if LSoldier.Id = AId then
              Exit(LSoldier);
        for LSoldier in AGame.DeadSoldiers do
          if LSoldier.Id = AId then
            Exit(LSoldier);
        Result := nil;
      end);
    LLoader := TXcomMapDataLoader.Create(ARuleset.Files);
    try
      for LSet in Result.MapDataSets do
      begin
        if not ARuleset.McdPatches.TryGetValue(LSet.Name, LPatch) then
          LPatch := nil;
        LLoader.LoadData(LSet, LPatch);
      end;
    finally
      LLoader.Free;
    end;
    Result.ResolveMapData;
  except
    Result.Free;
    raise;
  end;
end;

class procedure TXcomBattleSaveLink.StoreBattle(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame);
begin
  AGame.BattleGame := ABattle.Save;
end;

end.
