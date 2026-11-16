{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - what the game and the control panel tell each     }
{  other                                                                        }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  ingame, abortgame, loadedgame and restartgame of id_us.c                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.UserState;

interface

uses
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.UserIntf;

type
  /// <summary>The four globals of the user manager that the game code reads and writes, as one object</summary>
  TKeenUserState = class(TInterfacedObject, IKeenUserState)
  strict private
    FInGame: Boolean;
    FAbortGame: Boolean;
    FLoadedGame: Boolean;
    FRestartGame: TKeenGameDiff;
  public
    function GetInGame: Boolean;
    procedure SetInGame(AValue: Boolean);
    function GetAbortGame: Boolean;
    procedure SetAbortGame(AValue: Boolean);
    function GetLoadedGame: Boolean;
    procedure SetLoadedGame(AValue: Boolean);
    function GetRestartGame: TKeenGameDiff;
    procedure SetRestartGame(AValue: TKeenGameDiff);
  end;

implementation

{ TKeenUserState }

function TKeenUserState.GetInGame: Boolean;
begin
  Result := FInGame;
end;

procedure TKeenUserState.SetInGame(AValue: Boolean);
begin
  FInGame := AValue;
end;

function TKeenUserState.GetAbortGame: Boolean;
begin
  Result := FAbortGame;
end;

procedure TKeenUserState.SetAbortGame(AValue: Boolean);
begin
  FAbortGame := AValue;
end;

function TKeenUserState.GetLoadedGame: Boolean;
begin
  Result := FLoadedGame;
end;

procedure TKeenUserState.SetLoadedGame(AValue: Boolean);
begin
  FLoadedGame := AValue;
end;

function TKeenUserState.GetRestartGame: TKeenGameDiff;
begin
  Result := FRestartGame;
end;

procedure TKeenUserState.SetRestartGame(AValue: TKeenGameDiff);
begin
  FRestartGame := AValue;
end;

end.
