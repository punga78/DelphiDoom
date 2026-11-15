{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotAiBundle, the systems of the bot AI together       }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Facade.Bundle;

interface

uses
  DelphiDoom.BotAi.Character.Intf, DelphiDoom.BotAi.Chat.Intf, DelphiDoom.BotAi.Weapon.Intf,
  DelphiDoom.BotAi.Weight.Intf, DelphiDoom.BotAi.Goal.Intf, DelphiDoom.BotAi.Move.Intf, DelphiDoom.BotAi.Gen.Intf,
  DelphiDoom.BotAi.Ea.Intf, DelphiDoom.BotAi.Facade.Intf;

type
  /// <summary>The systems of <c>IBotAi</c> held together; made by <c>TBotAiFactory</c></summary>
  TBotAiBundle = class(TInterfacedObject, IBotAi)
  strict private
    FCharacters: IBotCharacterSystem;
    FChat: IBotChatSystem;
    FWeights: IBotWeightCache;
    FWeapons: IBotWeaponSystem;
    FGoals: IBotGoalSystem;
    FMoves: IBotMoveSystem;
    FGenetics: IBotGenetics;
    FActions: IBotElementaryActions;
  public
    constructor Create(const ACharacters: IBotCharacterSystem; const AChat: IBotChatSystem;
      const AWeights: IBotWeightCache; const AWeapons: IBotWeaponSystem; const AGoals: IBotGoalSystem;
      const AMoves: IBotMoveSystem; const AGenetics: IBotGenetics; const AActions: IBotElementaryActions);
    function Characters: IBotCharacterSystem;
    function Chat: IBotChatSystem;
    function Weights: IBotWeightCache;
    function Weapons: IBotWeaponSystem;
    function Goals: IBotGoalSystem;
    function Moves: IBotMoveSystem;
    function Genetics: IBotGenetics;
    function Actions: IBotElementaryActions;
  end;

implementation

{ TBotAiBundle }

constructor TBotAiBundle.Create(const ACharacters: IBotCharacterSystem; const AChat: IBotChatSystem;
  const AWeights: IBotWeightCache; const AWeapons: IBotWeaponSystem; const AGoals: IBotGoalSystem;
  const AMoves: IBotMoveSystem; const AGenetics: IBotGenetics; const AActions: IBotElementaryActions);
begin
  inherited Create;
  FCharacters := ACharacters;
  FChat := AChat;
  FWeights := AWeights;
  FWeapons := AWeapons;
  FGoals := AGoals;
  FMoves := AMoves;
  FGenetics := AGenetics;
  FActions := AActions;
end;

function TBotAiBundle.Characters: IBotCharacterSystem;
begin
  Result := FCharacters;
end;

function TBotAiBundle.Chat: IBotChatSystem;
begin
  Result := FChat;
end;

function TBotAiBundle.Weights: IBotWeightCache;
begin
  Result := FWeights;
end;

function TBotAiBundle.Weapons: IBotWeaponSystem;
begin
  Result := FWeapons;
end;

function TBotAiBundle.Goals: IBotGoalSystem;
begin
  Result := FGoals;
end;

function TBotAiBundle.Moves: IBotMoveSystem;
begin
  Result := FMoves;
end;

function TBotAiBundle.Genetics: IBotGenetics;
begin
  Result := FGenetics;
end;

function TBotAiBundle.Actions: IBotElementaryActions;
begin
  Result := FActions;
end;

end.
