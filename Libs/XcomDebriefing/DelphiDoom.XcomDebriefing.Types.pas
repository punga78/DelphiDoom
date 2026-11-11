{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the types of the report of a mission  }
{  (DebriefingStat, ReequipStat, RecoveryItem and what DebriefingState keeps)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Types;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.MissionStatistics;

type
  /// <summary>One line of the list of the debriefing (DebriefingStat): what, how many and the score</summary>
  TXcomDebriefingStat = class
  strict private
    FItem: string;
    FQuantity: Integer;
    FScore: Integer;
    FRecovery: Boolean;
  public
    constructor Create(const AItem: string; ARecovery: Boolean);
    property Item: string read FItem;
    property Quantity: Integer read FQuantity write FQuantity;
    property Score: Integer read FScore write FScore;
    /// <summary>True for the recovered objects of the second list (the first is the statistics of the battle)</summary>
    property Recovery: Boolean read FRecovery;
  end;

  /// <summary>An item or a vehicle that the craft misses after the mission (ReequipStat)</summary>
  TXcomReequipStat = record
    Item: string;
    Quantity: Integer;
    CraftName: string;
  end;

  /// <summary>The improvement of the stats of a soldier after a mission (SoldierStatsEntry)</summary>
  TXcomSoldierImprovement = record
    Name: string;
    Stats: TXcomUnitStats;
  end;

  /// <summary>An object of the alien base or of the UFO that is worth points (RecoveryItem)</summary>
  TXcomRecoveryItem = class
  strict private
    FName: string;
    FValue: Integer;
  public
    constructor Create(const AName: string; AValue: Integer);
    property Name: string read FName;
    property Value: Integer read FValue;
  end;

  /// <summary>
  ///   What the options of the game say that the debriefing needs (Options::storageLimitsEnforced,
  ///   psiStrengthEval, fieldPromotions) and the name of a craft (Craft::getName(Language*), which the saved game does
  ///   not know: the interface gives it)
  /// </summary>
  TXcomDebriefingOptions = record
    StorageLimitsEnforced: Boolean;
    FieldPromotions: Boolean;
    /// <summary>Options::psiStrengthEval: the stat string counts the psionic strength once the psi lab is researched</summary>
    PsiStrengthEval: Boolean;
    CraftName: TFunc<TXcomCraft, string>;
    /// <summary>The defaults of Options.cpp: limits off, promotions for everybody, the craft is named by its type</summary>
    class function Default: TXcomDebriefingOptions; static;
  end;

  /// <summary>
  ///   Everything that DebriefingState keeps after prepareDebriefing and init: the lists of the two pages, the
  ///   score, the flags that decide which screens follow and the soldiers that got a commendation. It owns its lists;
  ///   the region, the country, the base and the soldiers are the ones of the saved game (not owned)
  /// </summary>
  TXcomDebriefingReport = class
  strict private
    FStats: TObjectList<TXcomDebriefingStat>;
    FSoldierStats: TList<TXcomSoldierImprovement>;
    FMissingItems: TList<TXcomReequipStat>;
    FRecoveryStats: TObjectDictionary<Integer, TXcomRecoveryItem>;
    FSoldiersCommended: TList<TXcomSoldier>;
    FDeadSoldiersCommended: TList<TXcomSoldier>;
    FRounds: TDictionary<string, Integer>;
    FTitle: string;
    FRecoveryTitle: string;
    FRating: string;
    FTotal: Integer;
    FPositiveScore: Boolean;
    FNoContainment: Boolean;
    FManageContainment: Boolean;
    FDestroyBase: Boolean;
    FPromotions: Boolean;
    FRegion: TXcomRegion;
    FCountry: TXcomCountry;
    FBase: TXcomBase;
    FMissionStatistics: TXcomMissionStatistics;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>addStat: adds to the line of that name (a name that is not in the list is ignored)</summary>
    procedure AddStat(const AName: string; AQuantity, AScore: Integer);
    /// <summary>The line of that name, nil if there is none</summary>
    function FindStat(const AName: string): TXcomDebriefingStat;
    property Stats: TObjectList<TXcomDebriefingStat> read FStats;
    property SoldierStats: TList<TXcomSoldierImprovement> read FSoldierStats;
    property MissingItems: TList<TXcomReequipStat> read FMissingItems;
    /// <summary>The objects worth points by their special type (the order of the keys is the one of the std::map)</summary>
    property RecoveryStats: TObjectDictionary<Integer, TXcomRecoveryItem> read FRecoveryStats;
    property SoldiersCommended: TList<TXcomSoldier> read FSoldiersCommended;
    property DeadSoldiersCommended: TList<TXcomSoldier> read FDeadSoldiersCommended;
    /// <summary>_rounds: the rounds left in the clips that were recovered, by the name of the clip</summary>
    property Rounds: TDictionary<string, Integer> read FRounds;
    /// <summary>The text of the title (_txtTitle): a key of the language file</summary>
    property Title: string read FTitle write FTitle;
    /// <summary>The text above the second list (_txtRecovery): a key, empty when there is none</summary>
    property RecoveryTitle: string read FRecoveryTitle write FRecoveryTitle;
    /// <summary>The key of the rating (STR_RATING_OK...)</summary>
    property Rating: string read FRating write FRating;
    property Total: Integer read FTotal write FTotal;
    property PositiveScore: Boolean read FPositiveScore write FPositiveScore;
    property NoContainment: Boolean read FNoContainment write FNoContainment;
    property ManageContainment: Boolean read FManageContainment write FManageContainment;
    property DestroyBase: Boolean read FDestroyBase write FDestroyBase;
    property Promotions: Boolean read FPromotions write FPromotions;
    property Region: TXcomRegion read FRegion write FRegion;
    property Country: TXcomCountry read FCountry write FCountry;
    /// <summary>_base: the base of the mission, nil if it was lost</summary>
    property Base: TXcomBase read FBase write FBase;
    /// <summary>The record that the saved game keeps for the diaries (the saved game owns it once it is added)</summary>
    property MissionStatistics: TXcomMissionStatistics read FMissionStatistics write FMissionStatistics;
  end;

implementation

{ TXcomDebriefingStat }

constructor TXcomDebriefingStat.Create(const AItem: string; ARecovery: Boolean);
begin
  inherited Create;
  FItem := AItem;
  FRecovery := ARecovery;
end;

{ TXcomRecoveryItem }

constructor TXcomRecoveryItem.Create(const AName: string; AValue: Integer);
begin
  inherited Create;
  FName := AName;
  FValue := AValue;
end;

{ TXcomDebriefingOptions }

class function TXcomDebriefingOptions.Default: TXcomDebriefingOptions;
begin
  Result.StorageLimitsEnforced := False;
  Result.FieldPromotions := False;
  Result.PsiStrengthEval := False;
  Result.CraftName :=
    function(ACraft: TXcomCraft): string
    begin
      Result := ACraft.Rules.CraftType + '-' + IntToStr(ACraft.Id);
    end;
end;

{ TXcomDebriefingReport }

constructor TXcomDebriefingReport.Create;
begin
  inherited Create;
  FStats := TObjectList<TXcomDebriefingStat>.Create(True);
  FSoldierStats := TList<TXcomSoldierImprovement>.Create;
  FMissingItems := TList<TXcomReequipStat>.Create;
  FRecoveryStats := TObjectDictionary<Integer, TXcomRecoveryItem>.Create([doOwnsValues]);
  FSoldiersCommended := TList<TXcomSoldier>.Create;
  FDeadSoldiersCommended := TList<TXcomSoldier>.Create;
  FRounds := TDictionary<string, Integer>.Create;
  FPositiveScore := True;
end;

destructor TXcomDebriefingReport.Destroy;
begin
  FRounds.Free;
  FDeadSoldiersCommended.Free;
  FSoldiersCommended.Free;
  FRecoveryStats.Free;
  FMissingItems.Free;
  FSoldierStats.Free;
  FStats.Free;
  inherited Destroy;
end;

procedure TXcomDebriefingReport.AddStat(const AName: string; AQuantity, AScore: Integer);
var
  LStat: TXcomDebriefingStat;
begin
  LStat := FindStat(AName);
  if Assigned(LStat) then
  begin
    LStat.Quantity := LStat.Quantity + AQuantity;
    LStat.Score := LStat.Score + AScore;
  end;
end;

function TXcomDebriefingReport.FindStat(const AName: string): TXcomDebriefingStat;
var
  LStat: TXcomDebriefingStat;
begin
  for LStat in FStats do
    if LStat.Item = AName then
      Exit(LStat);
  Result := nil;
end;

end.
