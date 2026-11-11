{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the promotions of the soldiers after a  }
{  mission (SavedGame::handlePromotions, processSoldier, inspectSoldiers,       }
{  getSoldierScore)                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Promotions;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Transfer, DelphiDoom.XcomSave.BaseCapacity;

type
  /// <summary>
  ///   The higher promotions (not the ones of the rookies, which the soldier gets in the battle): the army has one
  ///   commander if it has 30 soldiers, a colonel for every 23, a captain for every 11 and a sergeant for every 5;
  ///   the best soldier of the rank below, by score, is promoted
  /// </summary>
  TXcomSoldierPromotions = class
  strict private
    type
      TPromotionInfo = record
        Commanders: Integer;
        Colonels: Integer;
        Captains: Integer;
        Sergeants: Integer;
      end;
  strict private
    FGame: TXcomSavedGame;
    FFieldPromotions: Boolean;
    procedure Count(const ASoldier: TXcomSoldier; var AInfo: TPromotionInfo);
    function Inspect(const ASoldiers, AParticipants: TList<TXcomSoldier>; ARank: Integer): TXcomSoldier;
  public
    /// <param name="AGame">The saved game (not owned)</param>
    /// <param name="AFieldPromotions">Options::fieldPromotions: only the soldiers of the mission can be promoted</param>
    constructor Create(const AGame: TXcomSavedGame; AFieldPromotions: Boolean);
    /// <summary>getSoldierScore</summary>
    class function SoldierScore(const ASoldier: TXcomSoldier): Integer; static;
    /// <summary>handlePromotions: whether somebody was promoted (the promotions screen follows)</summary>
    function Handle(const AParticipants: TList<TXcomSoldier>): Boolean;
  end;

implementation

{ TXcomSoldierPromotions }

constructor TXcomSoldierPromotions.Create(const AGame: TXcomSavedGame; AFieldPromotions: Boolean);
begin
  inherited Create;
  FGame := AGame;
  FFieldPromotions := AFieldPromotions;
end;

class function TXcomSoldierPromotions.SoldierScore(const ASoldier: TXcomSoldier): Integer;
var
  LStats: TXcomUnitStats;
begin
  LStats := ASoldier.CurrentStats;
  Result := 2 * LStats.Health + 2 * LStats.Stamina + 4 * LStats.Reactions + 4 * LStats.Bravery;
  Result := Result + 3 * (LStats.TimeUnits + 2 * LStats.Firing);
  Result := Result + LStats.Melee + LStats.Throwing + LStats.Strength;
  if LStats.PsiSkill > 0 then
    Inc(Result, LStats.PsiStrength + 2 * LStats.PsiSkill);
  Inc(Result, 10 * (ASoldier.Missions + ASoldier.Kills));
end;

procedure TXcomSoldierPromotions.Count(const ASoldier: TXcomSoldier; var AInfo: TPromotionInfo);
begin
  case ASoldier.Rank of
    TXcomSoldier.RANK_COMMANDER:
      Inc(AInfo.Commanders);
    TXcomSoldier.RANK_COLONEL:
      Inc(AInfo.Colonels);
    TXcomSoldier.RANK_CAPTAIN:
      Inc(AInfo.Captains);
    TXcomSoldier.RANK_SERGEANT:
      Inc(AInfo.Sergeants);
  end;
end;

function TXcomSoldierPromotions.Inspect(const ASoldiers, AParticipants: TList<TXcomSoldier>;
  ARank: Integer): TXcomSoldier;
var
  LSoldier: TXcomSoldier;
  LScore: Integer;
  LHighest: Integer;
begin
  LHighest := 0;
  Result := nil;
  for LSoldier in ASoldiers do
    if LSoldier.Rank = ARank then
    begin
      LScore := SoldierScore(LSoldier);
      if (LScore > LHighest) and ((not FFieldPromotions) or (AParticipants.IndexOf(LSoldier) >= 0)) then
      begin
        LHighest := LScore;
        Result := LSoldier;
      end;
    end;
end;

function TXcomSoldierPromotions.Handle(const AParticipants: TList<TXcomSoldier>): Boolean;
var
  LInfo: TPromotionInfo;
  LSoldiers: TList<TXcomSoldier>;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LTransfer: TXcomTransfer;
  LTotal: Integer;
  LPromoted: Integer;
  LHighest: TXcomSoldier;

  function Promote(ARank: Integer): Boolean;
  begin
    LHighest := Inspect(LSoldiers, AParticipants, ARank);
    Result := Assigned(LHighest);
    if Result then
    begin
      LHighest.PromoteRank;
      Inc(LPromoted);
    end;
  end;

begin
  LPromoted := 0;
  LInfo := Default(TPromotionInfo);
  LSoldiers := TList<TXcomSoldier>.Create;
  try
    for LBase in FGame.Bases do
    begin
      for LSoldier in LBase.Soldiers do
      begin
        LSoldiers.Add(LSoldier);
        Count(LSoldier, LInfo);
      end;
      for LTransfer in LBase.Transfers do
        if TXcomBaseCapacity.KindOf(LTransfer) = tkSoldier then
        begin
          LSoldiers.Add(LTransfer.Soldier);
          Count(LTransfer.Soldier, LInfo);
        end;
    end;
    LTotal := LSoldiers.Count;
    if (LInfo.Commanders = 0) and (LTotal >= 30) and Promote(TXcomSoldier.RANK_COLONEL) then
    begin
      // only one colonel is promoted to commander
      Inc(LInfo.Commanders);
      Dec(LInfo.Colonels);
    end;
    while (LTotal div 23) > LInfo.Colonels do
      if Promote(TXcomSoldier.RANK_CAPTAIN) then
      begin
        Inc(LInfo.Colonels);
        Dec(LInfo.Captains);
      end
      else
        Break;
    while (LTotal div 11) > LInfo.Captains do
      if Promote(TXcomSoldier.RANK_SERGEANT) then
      begin
        Inc(LInfo.Captains);
        Dec(LInfo.Sergeants);
      end
      else
        Break;
    while (LTotal div 5) > LInfo.Sergeants do
      if Promote(TXcomSoldier.RANK_SQUADDIE) then
        Inc(LInfo.Sergeants)
      else
        Break;
    Result := LPromoted > 0;
  finally
    LSoldiers.Free;
  end;
end;

end.
