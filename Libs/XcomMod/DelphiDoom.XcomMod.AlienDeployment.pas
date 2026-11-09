{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - an alien deployment (AlienDeployment)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.AlienDeployment;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.WeightedOptions;

type
  /// <summary>ItemSet: the items that an alien of a technology level carries</summary>
  TXcomItemSet = record
    Items: TArray<string>;
  end;

  /// <summary>
  ///   DeploymentData: how many aliens of a rank, how they are placed and what they carry. A field that is not in
  ///   the node is 0 (the C++ leaves it undefined)
  /// </summary>
  TXcomDeploymentData = record
    AlienRank: Integer;
    LowQty: Integer;
    HighQty: Integer;
    DQty: Integer;
    ExtraQty: Integer;
    PercentageOutsideUfo: Integer;
    ItemSets: TArray<TXcomItemSet>;
  end;

  /// <summary>BriefingData: the text, music and background of the briefing of a mission</summary>
  TXcomBriefingData = record
    Palette: Integer;
    TextOffset: Integer;
    Title: string;
    Desc: string;
    Music: string;
    Background: string;
    Cutscene: string;
    ShowCraft: Boolean;
    ShowTarget: Boolean;
    class function Default_: TXcomBriefingData; static;
  end;

  /// <summary>
  ///   A deployment of aliens (or of a terror site, a base, a mission) on the battlescape: how many of what
  ///   rank, the size of the map, terrains, briefing, objectives, duration (AlienDeployment). The chrono
  ///   trigger and the escape type are the numbers of the enums (the C++ casts them without checking)
  /// </summary>
  TXcomAlienDeployment = class
  public
    const
      /// <summary>FORCE_LOSE</summary>
      FORCE_LOSE = 0;
      /// <summary>ESCAPE_NONE</summary>
      ESCAPE_NONE = 0;
  strict private
    FType: string;
    FData: TArray<TXcomDeploymentData>;
    FWidth: Integer;
    FLength: Integer;
    FHeight: Integer;
    FCivilians: Integer;
    FTerrains: TArray<string>;
    FMusic: TArray<string>;
    FShade: Integer;
    FNextStage: string;
    FRace: string;
    FScript: string;
    FFinalDestination: Boolean;
    FIsAlienBase: Boolean;
    FWinCutscene: string;
    FLoseCutscene: string;
    FAbortCutscene: string;
    FAlert: string;
    FAlertBackground: string;
    FBriefingData: TXcomBriefingData;
    FMarkerName: string;
    FObjectivePopup: string;
    FObjectiveCompleteText: string;
    FObjectiveFailedText: string;
    FGenMission: TXcomWeightedOptions;
    FMarkerIcon: Integer;
    FDurationMin: Integer;
    FDurationMax: Integer;
    FMinDepth: Integer;
    FMaxDepth: Integer;
    FGenMissionFrequency: Integer;
    FObjectiveType: Integer;
    FObjectivesRequired: Integer;
    FObjectiveCompleteScore: Integer;
    FObjectiveFailedScore: Integer;
    FDespawnPenalty: Integer;
    FPoints: Integer;
    FTurnLimit: Integer;
    FCheatTurn: Integer;
    FChronoTrigger: Integer;
    FEscapeType: Integer;
    class function ReadData(const ANode: IYamlNode; const ADefault: TArray<TXcomDeploymentData>)
      : TArray<TXcomDeploymentData>; static;
    class function ReadItemSets(const ANode: IYamlNode; const ADefault: TArray<TXcomItemSet>)
      : TArray<TXcomItemSet>; static;
    class function ReadBriefing(const ANode: IYamlNode; const ADefault: TXcomBriefingData)
      : TXcomBriefingData; static;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>Loads the deployment from a YAML node; the marker icon moves by the offset of the mod when over 8</summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
    property DeploymentType: string read FType;
    property Data: TArray<TXcomDeploymentData> read FData;
    property Width: Integer read FWidth;
    /// <summary>The size of the map along its length (getLength)</summary>
    property MapLength: Integer read FLength;
    property Height: Integer read FHeight;
    property Civilians: Integer read FCivilians;
    property Terrains: TArray<string> read FTerrains;
    property Music: TArray<string> read FMusic;
    property Shade: Integer read FShade;
    property NextStage: string read FNextStage;
    property Race: string read FRace;
    property Script: string read FScript;
    property FinalDestination: Boolean read FFinalDestination;
    property IsAlienBase: Boolean read FIsAlienBase;
    property WinCutscene: string read FWinCutscene;
    property LoseCutscene: string read FLoseCutscene;
    property AbortCutscene: string read FAbortCutscene;
    property Alert: string read FAlert;
    property AlertBackground: string read FAlertBackground;
    property BriefingData: TXcomBriefingData read FBriefingData;
    property MarkerName: string read FMarkerName;
    property ObjectivePopup: string read FObjectivePopup;
    property ObjectiveCompleteText: string read FObjectiveCompleteText;
    property ObjectiveFailedText: string read FObjectiveFailedText;
    property GenMission: TXcomWeightedOptions read FGenMission;
    property MarkerIcon: Integer read FMarkerIcon;
    property DurationMin: Integer read FDurationMin;
    property DurationMax: Integer read FDurationMax;
    property MinDepth: Integer read FMinDepth;
    property MaxDepth: Integer read FMaxDepth;
    property GenMissionFrequency: Integer read FGenMissionFrequency;
    property ObjectiveType: Integer read FObjectiveType;
    property ObjectivesRequired: Integer read FObjectivesRequired;
    property ObjectiveCompleteScore: Integer read FObjectiveCompleteScore;
    property ObjectiveFailedScore: Integer read FObjectiveFailedScore;
    property DespawnPenalty: Integer read FDespawnPenalty;
    property Points: Integer read FPoints;
    property TurnLimit: Integer read FTurnLimit;
    property CheatTurn: Integer read FCheatTurn;
    property ChronoTrigger: Integer read FChronoTrigger;
    property EscapeType: Integer read FEscapeType;
  end;

implementation

{ TXcomBriefingData }

class function TXcomBriefingData.Default_: TXcomBriefingData;
begin
  Result := Default(TXcomBriefingData);
  Result.Music := 'GMDEFEND';
  Result.Background := 'BACK16.SCR';
  Result.ShowCraft := True;
  Result.ShowTarget := True;
end;

{ TXcomAlienDeployment }

constructor TXcomAlienDeployment.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FGenMission := TXcomWeightedOptions.Create;
  FBriefingData := TXcomBriefingData.Default_;
  FShade := -1;
  FAlert := 'STR_ALIENS_TERRORISE';
  FAlertBackground := 'BACK03.SCR';
  FMarkerName := 'STR_TERROR_SITE';
  FMarkerIcon := -1;
  FObjectiveType := -1;
  FCheatTurn := 20;
  FChronoTrigger := FORCE_LOSE;
  FEscapeType := ESCAPE_NONE;
end;

destructor TXcomAlienDeployment.Destroy;
begin
  FGenMission.Free;
  inherited Destroy;
end;

class function TXcomAlienDeployment.ReadItemSets(const ANode: IYamlNode; const ADefault: TArray<TXcomItemSet>)
  : TArray<TXcomItemSet>;
var
  LField: IYamlNode;
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'itemSets');
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    // ItemSet decode: not a sequence does not convert
    if not LItems[LIndex].IsSequence then
      raise TXcomNodeReader.BadConversion(LItems[LIndex]);
    Result[LIndex].Items := TXcomNodeReader.StringsOf(LItems[LIndex]);
  end;
end;

class function TXcomAlienDeployment.ReadData(const ANode: IYamlNode; const ADefault: TArray<TXcomDeploymentData>)
  : TArray<TXcomDeploymentData>;
var
  LField, LItem: IYamlNode;
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'data');
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    LItem := LItems[LIndex];
    if not LItem.IsMap then
      raise TXcomNodeReader.BadConversion(LItem);
    Result[LIndex].AlienRank := TXcomNodeReader.ReadInteger(LItem, 'alienRank', 0);
    Result[LIndex].LowQty := TXcomNodeReader.ReadInteger(LItem, 'lowQty', 0);
    Result[LIndex].HighQty := TXcomNodeReader.ReadInteger(LItem, 'highQty', 0);
    Result[LIndex].DQty := TXcomNodeReader.ReadInteger(LItem, 'dQty', 0);
    Result[LIndex].ExtraQty := TXcomNodeReader.ReadInteger(LItem, 'extraQty', 0);
    Result[LIndex].PercentageOutsideUfo := TXcomNodeReader.ReadInteger(LItem, 'percentageOutsideUfo', 0);
    Result[LIndex].ItemSets := ReadItemSets(LItem, nil);
  end;
end;

class function TXcomAlienDeployment.ReadBriefing(const ANode: IYamlNode; const ADefault: TXcomBriefingData)
  : TXcomBriefingData;
var
  LField: IYamlNode;
begin
  LField := TXcomNodeReader.Field(ANode, 'briefing');
  if not LField.IsDefined or not LField.IsMap then
    Exit(ADefault);
  // decoded into a new BriefingData: a missing field is its default, not the current value
  Result := TXcomBriefingData.Default_;
  Result.Palette := TXcomNodeReader.ReadInteger(LField, 'palette', Result.Palette);
  Result.TextOffset := TXcomNodeReader.ReadInteger(LField, 'textOffset', Result.TextOffset);
  Result.Title := TXcomNodeReader.ReadString(LField, 'title', Result.Title);
  Result.Desc := TXcomNodeReader.ReadString(LField, 'desc', Result.Desc);
  Result.Music := TXcomNodeReader.ReadString(LField, 'music', Result.Music);
  Result.Cutscene := TXcomNodeReader.ReadString(LField, 'cutscene', Result.Cutscene);
  Result.Background := TXcomNodeReader.ReadString(LField, 'background', Result.Background);
  Result.ShowCraft := TXcomNodeReader.ReadBoolean(LField, 'showCraft', Result.ShowCraft);
  Result.ShowTarget := TXcomNodeReader.ReadBoolean(LField, 'showTarget', Result.ShowTarget);
end;

procedure TXcomAlienDeployment.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
var
  LField: IYamlNode;
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FData := ReadData(ANode, FData);
  FWidth := TXcomNodeReader.ReadInteger(ANode, 'width', FWidth);
  FLength := TXcomNodeReader.ReadInteger(ANode, 'length', FLength);
  FHeight := TXcomNodeReader.ReadInteger(ANode, 'height', FHeight);
  FCivilians := TXcomNodeReader.ReadInteger(ANode, 'civilians', FCivilians);
  FTerrains := TXcomNodeReader.ReadStrings(ANode, 'terrains', FTerrains);
  FShade := TXcomNodeReader.ReadInteger(ANode, 'shade', FShade);
  FNextStage := TXcomNodeReader.ReadString(ANode, 'nextStage', FNextStage);
  FRace := TXcomNodeReader.ReadString(ANode, 'race', FRace);
  FFinalDestination := TXcomNodeReader.ReadBoolean(ANode, 'finalDestination', FFinalDestination);
  FWinCutscene := TXcomNodeReader.ReadString(ANode, 'winCutscene', FWinCutscene);
  FLoseCutscene := TXcomNodeReader.ReadString(ANode, 'loseCutscene', FLoseCutscene);
  FAbortCutscene := TXcomNodeReader.ReadString(ANode, 'abortCutscene', FAbortCutscene);
  FScript := TXcomNodeReader.ReadString(ANode, 'script', FScript);
  FAlert := TXcomNodeReader.ReadString(ANode, 'alert', FAlert);
  FAlertBackground := TXcomNodeReader.ReadString(ANode, 'alertBackground', FAlertBackground);
  FBriefingData := ReadBriefing(ANode, FBriefingData);
  FMarkerName := TXcomNodeReader.ReadString(ANode, 'markerName', FMarkerName);
  if TXcomNodeReader.Field(ANode, 'markerIcon').IsDefined then
    FMarkerIcon := AOffsets.GetOffset(TXcomNodeReader.ReadInteger(ANode, 'markerIcon', FMarkerIcon), 8);
  LField := TXcomNodeReader.Field(ANode, 'depth');
  if LField.IsDefined then
  begin
    FMinDepth := LField.Find(0).AsInteger(FMinDepth);
    FMaxDepth := LField.Find(1).AsInteger(FMaxDepth);
  end;
  LField := TXcomNodeReader.Field(ANode, 'duration');
  if LField.IsDefined then
  begin
    FDurationMin := LField.Find(0).AsInteger(FDurationMin);
    FDurationMax := LField.Find(1).AsInteger(FDurationMax);
  end;
  FMusic := TXcomNodeReader.ReadStrings(ANode, 'music', FMusic);
  FObjectiveType := TXcomNodeReader.ReadInteger(ANode, 'objectiveType', FObjectiveType);
  FObjectivesRequired := TXcomNodeReader.ReadInteger(ANode, 'objectivesRequired', FObjectivesRequired);
  FObjectivePopup := TXcomNodeReader.ReadString(ANode, 'objectivePopup', FObjectivePopup);
  LField := TXcomNodeReader.Field(ANode, 'objectiveComplete');
  if LField.IsDefined then
  begin
    FObjectiveCompleteText := LField.Find(0).AsString(FObjectiveCompleteText);
    FObjectiveCompleteScore := LField.Find(1).AsInteger(FObjectiveCompleteScore);
  end;
  LField := TXcomNodeReader.Field(ANode, 'objectiveFailed');
  if LField.IsDefined then
  begin
    FObjectiveFailedText := LField.Find(0).AsString(FObjectiveFailedText);
    FObjectiveFailedScore := LField.Find(1).AsInteger(FObjectiveFailedScore);
  end;
  FDespawnPenalty := TXcomNodeReader.ReadInteger(ANode, 'despawnPenalty', FDespawnPenalty);
  FPoints := TXcomNodeReader.ReadInteger(ANode, 'points', FPoints);
  FCheatTurn := TXcomNodeReader.ReadInteger(ANode, 'cheatTurn', FCheatTurn);
  FTurnLimit := TXcomNodeReader.ReadInteger(ANode, 'turnLimit', FTurnLimit);
  FChronoTrigger := TXcomNodeReader.ReadInteger(ANode, 'chronoTrigger', FChronoTrigger);
  FIsAlienBase := TXcomNodeReader.ReadBoolean(ANode, 'alienBase', FIsAlienBase);
  FEscapeType := TXcomNodeReader.ReadInteger(ANode, 'escapeType', FEscapeType);
  LField := TXcomNodeReader.Field(ANode, 'genMission');
  if LField.IsDefined then
    FGenMission.Load(LField);
  FGenMissionFrequency := TXcomNodeReader.ReadInteger(ANode, 'genMissionFreq', FGenMissionFrequency);
end;

end.
