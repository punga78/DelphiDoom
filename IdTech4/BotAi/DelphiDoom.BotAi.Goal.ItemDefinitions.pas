{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotItemDefinitions, iteminfo_struct                   }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): iteminfo_fields and }
{  iteminfo_struct of code\botlib\be_ai_goal.c. Based on the Quake III Arena   }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.ItemDefinitions;

interface

uses
  DelphiDoom.BotAi.Struct.Types;

type
  /// <summary>The description of <c>iteminfo_t</c> for the structure reader</summary>
  TBotItemDefinitions = class
  strict private
    FItem: TBotStructDefinition;
  public
    constructor Create;
    destructor Destroy; override;
    property Item: TBotStructDefinition read FItem;
  end;

implementation

uses
  DelphiDoom.BotAi.Goal.Types;

{ TBotItemDefinitions }

constructor TBotItemDefinitions.Create;
var
  LInfo: TBotItemInfo;
  LFields: TArray<TBotFieldDefinition>;

  // ITEMINFO_OFS(x): the offset of a field of the item structure
  function Offset(const AField): Integer;
  begin
    Result := NativeInt(@AField) - NativeInt(@LInfo);
  end;

begin
  inherited Create;
  LInfo := Default(TBotItemInfo);
  LFields := [
    TBotFieldDefinition.Make('name', Offset(LInfo.Name), FT_STRING),
    TBotFieldDefinition.Make('model', Offset(LInfo.Model), FT_STRING),
    TBotFieldDefinition.Make('modelindex', Offset(LInfo.ModelIndex), FT_INT),
    TBotFieldDefinition.Make('type', Offset(LInfo.ItemType), FT_INT),
    TBotFieldDefinition.Make('index', Offset(LInfo.Index), FT_INT),
    TBotFieldDefinition.Make('respawntime', Offset(LInfo.RespawnTime), FT_FLOAT),
    TBotFieldDefinition.Make('mins', Offset(LInfo.Mins), FT_FLOAT or FT_ARRAY, 3),
    TBotFieldDefinition.Make('maxs', Offset(LInfo.Maxs), FT_FLOAT or FT_ARRAY, 3)];
  FItem := TBotStructDefinition.Create(SizeOf(TBotItemInfo), LFields);
end;

destructor TBotItemDefinitions.Destroy;
begin
  FItem.Free;
  inherited Destroy;
end;

end.
