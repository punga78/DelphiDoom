{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotScriptLog, the log of the script parser            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  ScriptWarning and SourceWarning of code\botlib\l_script.c and l_precomp.c.  }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ScriptLog;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>The warnings of the parser ("file F, line N: text") go to botimport.Print as PRT_WARNING</summary>
  TBotScriptLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FImport: IBotImport;
  public
    constructor Create(const AImport: IBotImport);
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

implementation

uses
  DelphiDoom.BotAi.Types;

{ TBotScriptLog }

constructor TBotScriptLog.Create(const AImport: IBotImport);
begin
  inherited Create;
  FImport := AImport;
end;

procedure TBotScriptLog.Printf(const AMessage: string);
begin
  FImport.Print(PRT_MESSAGE, AnsiString(AMessage));
end;

procedure TBotScriptLog.Warning(const AMessage: string);
begin
  FImport.Print(PRT_WARNING, AnsiString(AMessage) + #10);
end;

end.
