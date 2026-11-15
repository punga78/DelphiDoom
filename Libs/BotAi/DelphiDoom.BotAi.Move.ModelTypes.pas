{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotBrushModelTypes, the type of the brush models      }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): modeltypes and      }
{  BotSetBrushModelTypes of code\botlib\be_ai_move.c. Based on the Quake III   }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc.                                                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.ModelTypes;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Move.Types;

type
  /// <summary>
  ///   The type (func_plat, func_bobbing, func_door, func_static or none) of each brush model of the map, from the
  ///   entities of the map. Difference from the original (a defect): a model number equal to <c>MAX_MODELS</c>
  ///   passed the check of the original and wrote after the table; it is out of range here.
  /// </summary>
  TBotBrushModelTypes = class
  strict private
    FImport: IBotImport;
    FTypes: array[0..BOT_MAX_MODELS - 1] of Integer;
  public
    constructor Create(const AImport: IBotImport);
    /// <summary>BotSetBrushModelTypes</summary>
    procedure Find(const AWorld: IBotAasWorld);
    /// <summary>modeltypes[modelnum]; a number outside the table is 0 (the original reads outside)</summary>
    function ModelType(const AModelNum: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Bsp.CNumbers, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Text;

const
  MAX_EPAIRKEY = 128;

{ TBotBrushModelTypes }

constructor TBotBrushModelTypes.Create(const AImport: IBotImport);
begin
  inherited Create;
  FImport := AImport;
end;

procedure TBotBrushModelTypes.Find(const AWorld: IBotAasWorld);
var
  LEntities: IAasBspEntities;
  LEntity: Integer;
  LClassName: AnsiString;
  LModel: AnsiString;
  LModelNum: Integer;
  LIndex: Integer;
begin
  for LIndex := 0 to BOT_MAX_MODELS - 1 do
    FTypes[LIndex] := 0;
  LEntities := AWorld.BspEntities;
  LEntity := LEntities.NextEntity(0);
  while LEntity <> 0 do
  begin
    if LEntities.ValueForKey(LEntity, 'classname', LClassName, MAX_EPAIRKEY) and
      LEntities.ValueForKey(LEntity, 'model', LModel, MAX_EPAIRKEY) then
    begin
      if Length(LModel) > 0 then
        LModelNum := TAasCNumbers.AtoI(Copy(LModel, 2, MaxInt))
      else
        LModelNum := 0;
      if (LModelNum < 0) or (LModelNum >= BOT_MAX_MODELS) then
        FImport.Print(PRT_MESSAGE, 'entity ' + LClassName + ' model number out of range'#10)
      else if TBotChatText.SameTextAscii(LClassName, 'func_bobbing') then
        FTypes[LModelNum] := MODELTYPE_FUNC_BOB
      else if TBotChatText.SameTextAscii(LClassName, 'func_plat') then
        FTypes[LModelNum] := MODELTYPE_FUNC_PLAT
      else if TBotChatText.SameTextAscii(LClassName, 'func_door') then
        FTypes[LModelNum] := MODELTYPE_FUNC_DOOR
      else if TBotChatText.SameTextAscii(LClassName, 'func_static') then
        FTypes[LModelNum] := MODELTYPE_FUNC_STATIC;
    end;
    LEntity := LEntities.NextEntity(LEntity);
  end;
end;

function TBotBrushModelTypes.ModelType(const AModelNum: Integer): Integer;
begin
  if (AModelNum < 0) or (AModelNum >= BOT_MAX_MODELS) then
    Exit(0);
  Result := FTypes[AModelNum];
end;

end.
