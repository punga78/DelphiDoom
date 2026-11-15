{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMoveContext, what the movement code shares         }
{                                                                              }
{  The globals of code\botlib\be_ai_move.c (the library variables and          }
{  modeltypes) and what its functions call (botimport, the AAS, the            }
{  elementary actions, crandom) as one object. Based on the Quake III Arena    }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Context;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Ea.Intf, DelphiDoom.BotAi.Move.Vars,
  DelphiDoom.BotAi.Move.ModelTypes;

type
  /// <summary>The things every travel type, and the movement system, work with; it owns the variables and the model types</summary>
  TBotMoveContext = class
  strict private
    FImport: IBotImport;
    FWorld: IBotAasWorld;
    FActions: IBotElementaryActions;
    FVars: TBotMoveVars;
    FModelTypes: TBotBrushModelTypes;
    FRandom: IBotRandom;
    FDeveloper: Boolean;
  public
    constructor Create(const AImport: IBotImport; const AWorld: IBotAasWorld; const AActions: IBotElementaryActions;
      const AVars: TBotMoveVars; const AModelTypes: TBotBrushModelTypes; const ARandom: IBotRandom;
      const ADeveloper: Boolean);
    destructor Destroy; override;
    property Import: IBotImport read FImport;
    property World: IBotAasWorld read FWorld;
    property Actions: IBotElementaryActions read FActions;
    property Vars: TBotMoveVars read FVars;
    property ModelTypes: TBotBrushModelTypes read FModelTypes;
    /// <summary>bot_developer</summary>
    property Developer: Boolean read FDeveloper;
    /// <summary>crandom() of q_shared.h: <c>2.0 * (random() - 0.5)</c>, a double in [-1, 1]</summary>
    function CRandom: Double;
  end;

implementation

{ TBotMoveContext }

constructor TBotMoveContext.Create(const AImport: IBotImport; const AWorld: IBotAasWorld;
  const AActions: IBotElementaryActions; const AVars: TBotMoveVars; const AModelTypes: TBotBrushModelTypes;
  const ARandom: IBotRandom; const ADeveloper: Boolean);
begin
  inherited Create;
  FImport := AImport;
  FWorld := AWorld;
  FActions := AActions;
  FVars := AVars;
  FModelTypes := AModelTypes;
  FRandom := ARandom;
  FDeveloper := ADeveloper;
end;

destructor TBotMoveContext.Destroy;
begin
  FModelTypes.Free;
  FVars.Free;
  inherited Destroy;
end;

function TBotMoveContext.CRandom: Double;
var
  LRandom: Single;
begin
  LRandom := FRandom.NextFloat;
  // 2.0 * (random() - 0.5): the float is promoted to a double by the double literal 0.5
  Result := 2.0 * (Double(LRandom) - 0.5);
end;

end.
