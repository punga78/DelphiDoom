{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatFactory                                        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Intf;

type
  /// <summary>The one place that knows the classes of the chat: gives an IBotChatSystem</summary>
  TBotChatFactory = class
  public
    /// <summary>A chat system on the game (import), the files of the bots, the library variables and a generator</summary>
    class function CreateChatSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
      const ALibVars: IBotLibVars; const ARandom: IBotRandom): IBotChatSystem; static;
  end;

implementation

uses
  DelphiDoom.BotAi.Chat.System;

{ TBotChatFactory }

class function TBotChatFactory.CreateChatSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVars; const ARandom: IBotRandom): IBotChatSystem;
begin
  Result := TBotChatSystem.Create(AImport, AFiles, ALibVars, ARandom);
end;

end.
