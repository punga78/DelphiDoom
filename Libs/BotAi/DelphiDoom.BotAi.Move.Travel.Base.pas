{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotTravelBase, the base of the travel types           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the             }
{  BotTravel_* functions of code\botlib\be_ai_move.c. Copyright (C) 1999-2005  }
{  Id Software, Inc. This unit is derived from the Quake III Arena source     }
{  code and is therefore available under the GNU General Public License,       }
{  version 2 or (at your option) any later version.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Base;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State,
  DelphiDoom.BotAi.Move.Context, DelphiDoom.BotAi.Move.Basics, DelphiDoom.BotAi.Move.Movers,
  DelphiDoom.BotAi.Move.Travel.Intf;

type
  /// <summary>
  ///   The context, the building blocks and the helpers that every travel type uses. The result of a travel starts
  ///   cleared (BotClearMoveResult); a travel type for which the original does nothing in the air keeps the empty
  ///   result.
  /// </summary>
  TBotTravelBase = class(TInterfacedObject, IBotTravelType)
  strict protected
    FContext: TBotMoveContext;
    FBasics: TBotMoveBasics;
    FMovers: TBotMovers;
    /// <summary>
    ///   <c>a - (b - k * x)</c> as the original calculates it: every operation of the float expression is rounded
    /// </summary>
    class function Ramp(const AFirst, ASecond: Single; const AFactor: Integer; const ADist: Single): Single; static;
    /// <summary>The direction of the first minus the second without the height: <c>{a[0] - b[0], a[1] - b[1], 0}</c></summary>
    class function HorizontalDelta(const AFirst, ASecond: TVec3): TVec3; static;
  public
    constructor Create(const AContext: TBotMoveContext; const ABasics: TBotMoveBasics; const AMovers: TBotMovers);
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; virtual;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; virtual;
  end;

implementation

{ TBotTravelBase }

constructor TBotTravelBase.Create(const AContext: TBotMoveContext; const ABasics: TBotMoveBasics;
  const AMovers: TBotMovers);
begin
  inherited Create;
  FContext := AContext;
  FBasics := ABasics;
  FMovers := AMovers;
end;

class function TBotTravelBase.Ramp(const AFirst, ASecond: Single; const AFactor: Integer;
  const ADist: Single): Single;
var
  LProduct: Single;
  LInner: Single;
begin
  LProduct := AFactor * ADist;
  LInner := ASecond - LProduct;
  Result := AFirst - LInner;
end;

class function TBotTravelBase.HorizontalDelta(const AFirst, ASecond: TVec3): TVec3;
begin
  Result[0] := AFirst[0] - ASecond[0];
  Result[1] := AFirst[1] - ASecond[1];
  Result[2] := 0;
end;

function TBotTravelBase.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
begin
  Result := Default(TBotMoveResult);
end;

function TBotTravelBase.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
begin
  Result := Default(TBotMoveResult);
end;

end.
