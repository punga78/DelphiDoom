{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotAiFactory, the composition root of the bot AI      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Facade.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.World.Intf,
  DelphiDoom.BotAi.Facade.Intf;

type
  /// <summary>
  ///   The one place that knows the classes of the bot AI: it builds the weight cache, the character, chat, weapon,
  ///   goal and move systems, the genetic selection and the elementary actions with the same collaborators, as
  ///   <c>Export_BotLibSetup</c> and <c>BotSetupLibrary</c> do in the original
  /// </summary>
  TBotAiFactory = class
  public
    /// <summary>
    ///   AImport, AFiles (the botfiles of the game), ALibVars (the library variables), ARandom (the generator of the
    ///   game), AWorld (the AAS and the entities), AMaxClients (EA_Setup) and ADeveloper (<c>bot_developer</c>)
    /// </summary>
    class function CreateAi(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVarStore;
      const ARandom: IBotRandom; const AWorld: IBotAasWorld; const AMaxClients: Integer;
      const ADeveloper: Boolean): IBotAi; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Character.Intf, DelphiDoom.BotAi.Weight.Intf, DelphiDoom.BotAi.Move.Intf, DelphiDoom.BotAi.Ea.Intf,
  DelphiDoom.BotAi.Gen.Selector, DelphiDoom.BotAi.Ea.Actions, DelphiDoom.BotAi.Weight.Factory,
  DelphiDoom.BotAi.Character.Factory, DelphiDoom.BotAi.Chat.Factory, DelphiDoom.BotAi.Weapon.Factory,
  DelphiDoom.BotAi.Goal.Factory, DelphiDoom.BotAi.Move.Factory, DelphiDoom.BotAi.Facade.Bundle;

{ TBotAiFactory }

class function TBotAiFactory.CreateAi(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVarStore; const ARandom: IBotRandom; const AWorld: IBotAasWorld; const AMaxClients: Integer;
  const ADeveloper: Boolean): IBotAi;
var
  LWeights: IBotWeightCache;
  LActions: IBotElementaryActions;
  LMoves: IBotMoveSystem;
begin
  LWeights := TBotWeightFactory.CreateWeightCache(AImport, AFiles, ALibVars);
  LActions := TBotElementaryActions.Create(AImport, AMaxClients);
  LMoves := TBotMoveFactory.CreateMoveSystem(AImport, ALibVars, AWorld, LActions, ARandom, ADeveloper);
  Result := TBotAiBundle.Create(
    TBotCharacterFactory.CreateCharacterSystem(AImport, AFiles, ALibVars),
    TBotChatFactory.CreateChatSystem(AImport, AFiles, ALibVars, ARandom),
    LWeights,
    TBotWeaponFactory.CreateWeaponSystem(AImport, AFiles, ALibVars, LWeights),
    TBotGoalFactory.CreateGoalSystem(AImport, AFiles, ALibVars, LWeights, AWorld, LMoves.Locator, ARandom,
      ADeveloper),
    LMoves,
    TBotGeneticSelector.Create(AImport, ARandom),
    LActions);
end;

end.
