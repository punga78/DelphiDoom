{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the messages to the game                          }
{                                                                              }
{  Replaces botimport.Print for the AAS code. Based on the Quake III Arena     }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Printer;

interface

uses
  DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>Sends a message to the game if there is one (the import is optional)</summary>
  TAasPrinter = class
  public
    /// <summary>botimport.Print: the message carries its own line feed, as in the original</summary>
    class procedure Print(const AImport: IBotImport; const ALevel: Integer; const AMessage: string); static;
  end;

implementation

{ TAasPrinter }

class procedure TAasPrinter.Print(const AImport: IBotImport; const ALevel: Integer; const AMessage: string);
begin
  if Assigned(AImport) then
    AImport.Print(ALevel, AnsiString(AMessage));
end;

end.
