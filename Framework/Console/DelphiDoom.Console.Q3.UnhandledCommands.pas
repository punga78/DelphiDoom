{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, what follows a line that   }
{  is neither a command nor a variable                                         }
{                                                                              }
{  The end of Cmd_ExecuteString: the client game, the server game, the ui and  }
{  the forwarding to the server, in the order and with the conditions of the   }
{  original.                                                                   }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.UnhandledCommands;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   A handler of the game: reads the tokens of the line (the console arguments) and says if it
  ///   took the line (<c>CL_GameCommand</c>, <c>SV_GameCommand</c>, <c>UI_GameCommand</c>)
  /// </summary>
  TQ3GameCommandHandler = reference to function: Boolean;

  /// <summary>
  ///   <c>IQ3UnhandledCommands</c> as <c>Cmd_ExecuteString</c> ends: with the client running, the client
  ///   game may take the line; with the server running, the server game; with the client running, the
  ///   ui; else the line is forwarded to the server (<c>CL_ForwardCommandToServer</c>, usually a chat
  ///   message). A handler or a condition that is nil counts as "no" (in the original
  ///   <c>com_cl_running</c> and <c>com_sv_running</c> may be NULL)
  /// </summary>
  TQ3UnhandledCommands = class(TInterfacedObject, IQ3UnhandledCommands)
  strict private
    FIsClientRunning: TFunc<Boolean>;
    FIsServerRunning: TFunc<Boolean>;
    FClientGame: TQ3GameCommandHandler;
    FServerGame: TQ3GameCommandHandler;
    FUserInterface: TQ3GameCommandHandler;
    FForward: TProc<AnsiString>;
    class function Takes(const ACondition: TFunc<Boolean>; const AHandler: TQ3GameCommandHandler): Boolean; static;
  public
    constructor Create(const AIsClientRunning, AIsServerRunning: TFunc<Boolean>;
      const AClientGame, AServerGame, AUserInterface: TQ3GameCommandHandler; const AForward: TProc<AnsiString>);
    /// <summary>The result is True when a game handler took the line; a forwarded line gives False</summary>
    function Execute(const AText: AnsiString): Boolean;
  end;

implementation

{ TQ3UnhandledCommands }

constructor TQ3UnhandledCommands.Create(const AIsClientRunning, AIsServerRunning: TFunc<Boolean>;
  const AClientGame, AServerGame, AUserInterface: TQ3GameCommandHandler; const AForward: TProc<AnsiString>);
begin
  inherited Create;
  FIsClientRunning := AIsClientRunning;
  FIsServerRunning := AIsServerRunning;
  FClientGame := AClientGame;
  FServerGame := AServerGame;
  FUserInterface := AUserInterface;
  FForward := AForward;
end;

class function TQ3UnhandledCommands.Takes(const ACondition: TFunc<Boolean>;
  const AHandler: TQ3GameCommandHandler): Boolean;
begin
  Result := Assigned(ACondition) and ACondition() and Assigned(AHandler) and AHandler();
end;

function TQ3UnhandledCommands.Execute(const AText: AnsiString): Boolean;
begin
  Result := True;
  if Takes(FIsClientRunning, FClientGame) then
    Exit;
  if Takes(FIsServerRunning, FServerGame) then
    Exit;
  if Takes(FIsClientRunning, FUserInterface) then
    Exit;
  Result := False;
  if Assigned(FForward) then
    FForward(AText);
end;

end.
