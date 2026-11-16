{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMoveFactory, the composition of the movement AI    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Ea.Intf,
  DelphiDoom.BotAi.Move.Intf;

type
  /// <summary>The only place that knows the classes of the movement AI</summary>
  TBotMoveFactory = class
  public
    /// <summary>
    ///   The movement AI over the AAS of the world; the elementary actions are the bot input of the game and the
    ///   generator gives <c>crandom()</c> of the water jump; ADeveloper is <c>bot_developer</c>
    /// </summary>
    class function CreateMoveSystem(const AImport: IBotImport; const ALibVars: IBotLibVarStore;
      const AWorld: IBotAasWorld; const AActions: IBotElementaryActions; const ARandom: IBotRandom;
      const ADeveloper: Boolean): IBotMoveSystem; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Vars, DelphiDoom.BotAi.Move.ModelTypes,
  DelphiDoom.BotAi.Move.Context, DelphiDoom.BotAi.Move.Basics, DelphiDoom.BotAi.Move.Movers,
  DelphiDoom.BotAi.Move.Locator, DelphiDoom.BotAi.Move.ReachChooser, DelphiDoom.BotAi.Move.Predictor,
  DelphiDoom.BotAi.Move.Travel.Intf, DelphiDoom.BotAi.Move.Travel.Walk, DelphiDoom.BotAi.Move.Travel.Crouch,
  DelphiDoom.BotAi.Move.Travel.BarrierJump, DelphiDoom.BotAi.Move.Travel.Ladder,
  DelphiDoom.BotAi.Move.Travel.WalkOffLedge, DelphiDoom.BotAi.Move.Travel.Jump, DelphiDoom.BotAi.Move.Travel.Swim,
  DelphiDoom.BotAi.Move.Travel.WaterJump, DelphiDoom.BotAi.Move.Travel.Teleport,
  DelphiDoom.BotAi.Move.Travel.Elevator, DelphiDoom.BotAi.Move.Travel.Grapple,
  DelphiDoom.BotAi.Move.Travel.RocketJump, DelphiDoom.BotAi.Move.Travel.BfgJump,
  DelphiDoom.BotAi.Move.Travel.JumpPad, DelphiDoom.BotAi.Move.Travel.FuncBob, DelphiDoom.BotAi.Move.System;

{ TBotMoveFactory }

class function TBotMoveFactory.CreateMoveSystem(const AImport: IBotImport; const ALibVars: IBotLibVarStore;
  const AWorld: IBotAasWorld; const AActions: IBotElementaryActions; const ARandom: IBotRandom;
  const ADeveloper: Boolean): IBotMoveSystem;
var
  LVars: TBotMoveVars;
  LModelTypes: TBotBrushModelTypes;
  LContext: TBotMoveContext;
  LBasics: TBotMoveBasics;
  LMovers: TBotMovers;
  LChooser: TBotReachabilityChooser;
  LPredictor: TBotMovePredictor;
  LLocator: IBotReachabilityLocator;
  LGrappleObject: TBotGrappleTravel;
  LGrapple: IBotTravelType;
  LGrappleReset: IBotGrappleReset;
  LTravelTypes: TDictionary<Integer, IBotTravelType>;
begin
  LVars := TBotMoveVars.Create(ALibVars);
  LModelTypes := TBotBrushModelTypes.Create(AImport);
  LContext := TBotMoveContext.Create(AImport, AWorld, AActions, LVars, LModelTypes, ARandom, ADeveloper);
  LBasics := TBotMoveBasics.Create(LContext);
  LMovers := TBotMovers.Create(LContext);
  LChooser := TBotReachabilityChooser.Create(LContext);
  LPredictor := TBotMovePredictor.Create(LContext, LChooser);
  LLocator := TBotReachabilityLocator.Create(AImport, AWorld, LModelTypes);
  LGrappleObject := TBotGrappleTravel.Create(LContext, LBasics, LMovers);
  LGrapple := LGrappleObject;
  LGrappleReset := LGrappleObject;
  LTravelTypes := TDictionary<Integer, IBotTravelType>.Create;
  LTravelTypes.Add(TRAVEL_WALK, TBotWalkTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_CROUCH, TBotCrouchTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_BARRIERJUMP, TBotBarrierJumpTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_LADDER, TBotLadderTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_WALKOFFLEDGE, TBotWalkOffLedgeTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_JUMP, TBotJumpTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_SWIM, TBotSwimTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_WATERJUMP, TBotWaterJumpTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_TELEPORT, TBotTeleportTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_ELEVATOR, TBotElevatorTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_GRAPPLEHOOK, LGrapple);
  LTravelTypes.Add(TRAVEL_ROCKETJUMP, TBotRocketJumpTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_BFGJUMP, TBotBfgJumpTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_JUMPPAD, TBotJumpPadTravel.Create(LContext, LBasics, LMovers));
  LTravelTypes.Add(TRAVEL_FUNCBOB, TBotFuncBobTravel.Create(LContext, LBasics, LMovers));
  // the system owns the context and the classes that use it; the model types and the variables are the context's
  Result := TBotMoveSystem.Create(LContext, LBasics, LMovers, LChooser, LPredictor, LLocator, LGrappleReset,
    LTravelTypes);
end;

end.
