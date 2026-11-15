{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotInfoEntities, the map locations and the camp spots }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): maplocations,       }
{  campspots, BotInitInfoEntities, BotFreeInfoEntities, BotGetMapLocationGoal  }
{  and BotGetNextCampSpotGoal of code\botlib\be_ai_goal.c. Based on the Quake  }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.InfoEntities;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Goal.Types;

type
  /// <summary>
  ///   The <c>target_location</c> and <c>info_camp</c> entities of the map. Both lists are "in testa" as in the
  ///   original: the last entity of the map is the first of the list.
  /// </summary>
  TBotInfoEntities = class
  strict private
    FImport: IBotImport;
    FLocations: TList<TBotMapLocation>;
    FCampSpots: TList<TBotCampSpot>;
  public
    constructor Create(const AImport: IBotImport);
    destructor Destroy; override;
    /// <summary>BotFreeInfoEntities</summary>
    procedure Clear;
    /// <summary>
    ///   BotInitInfoEntities: a camp spot in solid is skipped with a message; with <c>ADeveloper</c> the counts are
    ///   printed
    /// </summary>
    procedure Init(const AWorld: IBotAasWorld; const ADeveloper: Boolean);
    /// <summary>BotGetMapLocationGoal: the goal of the location with the name (case does not matter)</summary>
    function GetMapLocationGoal(const AName: AnsiString; var AGoal: TBotGoal): Boolean;
    /// <summary>BotGetNextCampSpotGoal: the number to ask for the next one, 0 at the end</summary>
    function GetNextCampSpotGoal(const ANum: Integer; var AGoal: TBotGoal): Integer;
    function LocationCount: Integer;
    function CampSpotCount: Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Bsp.Intf, DelphiDoom.BotAi.Types,
  DelphiDoom.BotAi.Chat.Text, DelphiDoom.BotAi.Text.CFormat;

const
  MAX_EPAIRKEY = 128;

// the mins and maxs of the goals of a location and of a camp spot: {-8, -8, -8}, {8, 8, 8}
procedure SetBoxGoal(var AGoal: TBotGoal);
begin
  AGoal.Mins[0] := -8;
  AGoal.Mins[1] := -8;
  AGoal.Mins[2] := -8;
  AGoal.Maxs[0] := 8;
  AGoal.Maxs[1] := 8;
  AGoal.Maxs[2] := 8;
end;

{ TBotInfoEntities }

constructor TBotInfoEntities.Create(const AImport: IBotImport);
begin
  inherited Create;
  FImport := AImport;
  FLocations := TList<TBotMapLocation>.Create;
  FCampSpots := TList<TBotCampSpot>.Create;
end;

destructor TBotInfoEntities.Destroy;
begin
  FCampSpots.Free;
  FLocations.Free;
  inherited Destroy;
end;

procedure TBotInfoEntities.Clear;
begin
  FLocations.Clear;
  FCampSpots.Clear;
end;

function TBotInfoEntities.LocationCount: Integer;
begin
  Result := FLocations.Count;
end;

function TBotInfoEntities.CampSpotCount: Integer;
begin
  Result := FCampSpots.Count;
end;

procedure TBotInfoEntities.Init(const AWorld: IBotAasWorld; const ADeveloper: Boolean);
var
  LEntities: IAasBspEntities;
  LClassName: AnsiString;
  LEntity: Integer;
  LLocation: TBotMapLocation;
  LCampSpot: TBotCampSpot;
  LNumLocations: Integer;
  LNumCampSpots: Integer;
begin
  Clear;
  LEntities := AWorld.BspEntities;
  LNumLocations := 0;
  LNumCampSpots := 0;
  LEntity := LEntities.NextEntity(0);
  while LEntity <> 0 do
  begin
    if LEntities.ValueForKey(LEntity, 'classname', LClassName, MAX_EPAIRKEY) then
    begin
      if LClassName = 'target_location' then
      begin
        // map locations
        LLocation := Default(TBotMapLocation);
        LEntities.VectorForKey(LEntity, 'origin', LLocation.Origin);
        LEntities.ValueForKey(LEntity, 'message', LLocation.Name, MAX_EPAIRKEY);
        LLocation.AreaNum := AWorld.Sampler.PointAreaNum(LLocation.Origin);
        FLocations.Insert(0, LLocation);
        Inc(LNumLocations);
      end
      else if LClassName = 'info_camp' then
      begin
        // camp spots
        LCampSpot := Default(TBotCampSpot);
        LEntities.VectorForKey(LEntity, 'origin', LCampSpot.Origin);
        LEntities.ValueForKey(LEntity, 'message', LCampSpot.Name, MAX_EPAIRKEY);
        LEntities.FloatForKey(LEntity, 'range', LCampSpot.Range);
        LEntities.FloatForKey(LEntity, 'weight', LCampSpot.Weight);
        LEntities.FloatForKey(LEntity, 'wait', LCampSpot.Wait);
        LEntities.FloatForKey(LEntity, 'random', LCampSpot.Random);
        LCampSpot.AreaNum := AWorld.Sampler.PointAreaNum(LCampSpot.Origin);
        if LCampSpot.AreaNum = 0 then
          FImport.Print(PRT_MESSAGE, 'camp spot at ' + TBotCFormat.Fixed1(LCampSpot.Origin[0]) + ' ' +
            TBotCFormat.Fixed1(LCampSpot.Origin[1]) + ' ' + TBotCFormat.Fixed1(LCampSpot.Origin[2]) +
            ' in solid'#10)
        else
        begin
          FCampSpots.Insert(0, LCampSpot);
          Inc(LNumCampSpots);
        end;
      end;
    end;
    LEntity := LEntities.NextEntity(LEntity);
  end;
  if ADeveloper then
  begin
    FImport.Print(PRT_MESSAGE, TBotCFormat.Int(LNumLocations) + ' map locations'#10);
    FImport.Print(PRT_MESSAGE, TBotCFormat.Int(LNumCampSpots) + ' camp spots'#10);
  end;
end;

function TBotInfoEntities.GetMapLocationGoal(const AName: AnsiString; var AGoal: TBotGoal): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FLocations.Count - 1 do
  begin
    if TBotChatText.SameTextAscii(FLocations[LIndex].Name, AName) then
    begin
      AGoal.AreaNum := FLocations[LIndex].AreaNum;
      AGoal.Origin := FLocations[LIndex].Origin;
      AGoal.EntityNum := 0;
      SetBoxGoal(AGoal);
      Exit(True);
    end;
  end;
  Result := False;
end;

function TBotInfoEntities.GetNextCampSpotGoal(const ANum: Integer; var AGoal: TBotGoal): Integer;
var
  LNum: Integer;
  LRemaining: Integer;
  LIndex: Integer;
begin
  LNum := ANum;
  if LNum < 0 then
    LNum := 0;
  LRemaining := LNum;
  for LIndex := 0 to FCampSpots.Count - 1 do
  begin
    Dec(LRemaining);
    if LRemaining < 0 then
    begin
      AGoal.AreaNum := FCampSpots[LIndex].AreaNum;
      AGoal.Origin := FCampSpots[LIndex].Origin;
      AGoal.EntityNum := 0;
      SetBoxGoal(AGoal);
      Exit(LNum + 1);
    end;
  end;
  Result := 0;
end;

end.
