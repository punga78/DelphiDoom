{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the commands of the AI see                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (the WarContext and WarPlayerInfo      }
{  that the wai_execute* functions receive; logWarning), (c) 2019 Alejandro    }
{  Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Environment;

interface

uses
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.World;

type
  /// <summary>
  ///   The world, the player the AI plays and the warnings it gives (logWarning of the original: a counter and the last
  ///   text, the model has no log). One per computer player
  /// </summary>
  TWarAiEnvironment = class
  strict private
    FWorld: TWarModelWorld;
    FPlayerIndex: Integer;
    FWarnings: Integer;
    FLastWarning: string;
    function GetPlayer: PWarPlayerInfo;
  public
    constructor Create(const AWorld: TWarModelWorld; APlayerIndex: Integer);
    procedure Warn(const AMessage: string);
    property World: TWarModelWorld read FWorld;
    property PlayerIndex: Integer read FPlayerIndex;
    property Player: PWarPlayerInfo read GetPlayer;
    property Warnings: Integer read FWarnings;
    property LastWarning: string read FLastWarning;
  end;

implementation

{ TWarAiEnvironment }

constructor TWarAiEnvironment.Create(const AWorld: TWarModelWorld; APlayerIndex: Integer);
begin
  inherited Create;
  FWorld := AWorld;
  FPlayerIndex := APlayerIndex;
end;

function TWarAiEnvironment.GetPlayer: PWarPlayerInfo;
begin
  Result := FWorld.Context.Players[FPlayerIndex];
end;

procedure TWarAiEnvironment.Warn(const AMessage: string);
begin
  Inc(FWarnings);
  FLastWarning := AMessage;
end;

end.
