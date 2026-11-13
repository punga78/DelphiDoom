{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeaponFactory, the composition of the weapon AI    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_weap.c. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Weight.Intf,
  DelphiDoom.BotAi.Weapon.Intf;

type
  /// <summary>The only place that knows the classes of the weapon AI</summary>
  TBotWeaponFactory = class
  public
    /// <summary>The weapon AI over the weight library (the weights of the weapon files are read through it)</summary>
    class function CreateWeaponSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
      const ALibVars: IBotLibVarStore; const AWeights: IBotWeightCache): IBotWeaponSystem; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Weapon.System;

{ TBotWeaponFactory }

class function TBotWeaponFactory.CreateWeaponSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVarStore; const AWeights: IBotWeightCache): IBotWeaponSystem;
begin
  Result := TBotWeaponSystem.Create(AImport, AFiles, ALibVars, AWeights);
end;

end.
