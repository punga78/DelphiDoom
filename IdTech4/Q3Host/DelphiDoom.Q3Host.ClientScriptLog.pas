{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the messages of the precompiler         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): botlib\          }
{  be_interface.c (botimport.Print). Copyright (C) 1999-2005 Id Software,       }
{  Inc. This unit is derived from the Quake III Arena source code and is        }
{  therefore available under the GNU General Public License, version 2 or (at   }
{  your option) any later version.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientScriptLog;

interface

uses
  DelphiDoom.Scanner.Q3.Intf, DelphiDoom.Q3Host.Intf;

type
  /// <summary>botimport.Print of the precompiler goes to the console of the host (Com_Printf)</summary>
  TQ3HostScriptLog = class(TInterfacedObject, IQ3ScriptLog)
  strict private
    FConsole: IQ3HostConsole;
  public
    constructor Create(const AConsole: IQ3HostConsole);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
  end;

implementation

constructor TQ3HostScriptLog.Create(const AConsole: IQ3HostConsole);
begin
  inherited Create;
  FConsole := AConsole;
end;

procedure TQ3HostScriptLog.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  if Assigned(FConsole) then
    FConsole.Print(AMessage);
end;

end.
