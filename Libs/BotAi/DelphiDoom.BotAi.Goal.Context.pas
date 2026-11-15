{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotGoalContext, what the goal AI shares                }
{                                                                              }
{  The globals of code\botlib\be_ai_goal.c (itemconfig, levelitems,            }
{  numlevelitems, maplocations, campspots, g_gametype) as the fields of an     }
{  object that the classes of the goal AI share. Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.Context;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Goal.ItemConfig, DelphiDoom.BotAi.Goal.LevelItems,
  DelphiDoom.BotAi.Goal.InfoEntities;

type
  /// <summary>The state of the goal AI that is not the state of a bot; it owns what it holds</summary>
  TBotGoalContext = class
  strict private
    FItemConfig: TBotItemConfig;
    FLevelItems: TBotLevelItems;
    FInfoEntities: TBotInfoEntities;
  public
    /// <summary>g_gametype: the game type (GT_*), read by BotSetupGoalAI</summary>
    GameType: Integer;
    /// <summary>numlevelitems</summary>
    NumLevelItems: Integer;
    constructor Create(const AImport: IBotImport);
    destructor Destroy; override;
    /// <summary>itemconfig (the context owns it; nil if none)</summary>
    property ItemConfig: TBotItemConfig read FItemConfig;
    property LevelItems: TBotLevelItems read FLevelItems;
    property InfoEntities: TBotInfoEntities read FInfoEntities;
    /// <summary>Frees the item config and takes the new one (nil is allowed)</summary>
    procedure ReplaceItemConfig(const AConfig: TBotItemConfig);
  end;

implementation

uses
  System.SysUtils;

{ TBotGoalContext }

constructor TBotGoalContext.Create(const AImport: IBotImport);
begin
  inherited Create;
  FLevelItems := TBotLevelItems.Create(AImport);
  FInfoEntities := TBotInfoEntities.Create(AImport);
end;

destructor TBotGoalContext.Destroy;
begin
  FInfoEntities.Free;
  FLevelItems.Free;
  FItemConfig.Free;
  inherited Destroy;
end;

procedure TBotGoalContext.ReplaceItemConfig(const AConfig: TBotItemConfig);
begin
  if AConfig <> FItemConfig then
    FItemConfig.Free;
  FItemConfig := AConfig;
end;

end.
