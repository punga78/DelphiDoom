{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotCharacterFactory, the composition of the characters}
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_char.c. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Character.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Character.Intf;

type
  /// <summary>The only place that knows the classes of the characters</summary>
  TBotCharacterFactory = class
  public
    class function CreateCharacterSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
      const ALibVars: IBotLibVars): IBotCharacterSystem; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Character.System;

{ TBotCharacterFactory }

class function TBotCharacterFactory.CreateCharacterSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVars): IBotCharacterSystem;
begin
  Result := TBotCharacterSystem.Create(AImport, AFiles, ALibVars);
end;

end.
