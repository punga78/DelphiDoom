{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotGoalFactory, the composition of the goal AI        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_goal.c. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Weight.Intf,
  DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.Move.Intf, DelphiDoom.BotAi.Goal.Intf;

type
  /// <summary>The only place that knows the classes of the goal AI</summary>
  TBotGoalFactory = class
  public
    /// <summary>
    ///   The goal AI: ALocator gives the area a bot is in (the movement AI), AWeights reads the weight files and
    ///   ADeveloper is <c>bot_developer</c>
    /// </summary>
    class function CreateGoalSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
      const ALibVars: IBotLibVarStore; const AWeights: IBotWeightCache; const AWorld: IBotAasWorld;
      const ALocator: IBotReachabilityLocator; const ARandom: IBotRandom;
      const ADeveloper: Boolean): IBotGoalSystem; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Goal.System;

{ TBotGoalFactory }

class function TBotGoalFactory.CreateGoalSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVarStore; const AWeights: IBotWeightCache; const AWorld: IBotAasWorld;
  const ALocator: IBotReachabilityLocator; const ARandom: IBotRandom; const ADeveloper: Boolean): IBotGoalSystem;
begin
  Result := TBotGoalSystem.Create(AImport, AFiles, ALibVars, AWeights, AWorld, ALocator, ARandom, ADeveloper);
end;

end.
