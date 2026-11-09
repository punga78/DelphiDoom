{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the game information functions of PS_GAME         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  _GAME, GlobalEarthQuake, LocalEarthQuake, GameSkill, GameMap and (Doom and  }
{  Heretic only) GameEpisode: they were PS_Game... in psi_game.pas.            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Game.Info;

interface

uses
  DelphiDoom.ScriptHost.Game.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   The functions of the game of the unit PS_GAME. The interpreter calls its methods with the
  ///   object as Self, so there is no procedure of the engine in between
  /// </summary>
  TScriptGameInfo = class(TInterfacedObject, IScriptFunctionSection)
  strict private
    FSource: IScriptGameInfoSource;
    FGame: TScriptGame;
  public
    /// <exception cref="EArgumentNilException">If the source is nil</exception>
    constructor Create(const ASource: IScriptGameInfoSource; const AGame: TScriptGame);
    procedure Describe(const ATable: IScriptFunctionTable);
    // the methods below are the ones that scripts call: the names of the scripts are in Describe
    function GameName: string;
    procedure GlobalEarthQuake(const ATics: Integer);
    procedure LocalEarthQuake(const X, Y, Z: Integer; const ATics: Integer;
      const AIntensity: Integer; const AMaxDistance: Integer);
    function GameSkill: Integer;
    function GameMap: Integer;
    function GameEpisode: Integer;
  end;

implementation

uses
  System.SysUtils;

{ TScriptGameInfo }

constructor TScriptGameInfo.Create(const ASource: IScriptGameInfoSource; const AGame: TScriptGame);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  FGame := AGame;
end;

procedure TScriptGameInfo.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethod('function _GAME: string;', Self, @TScriptGameInfo.GameName);
  ATable.AddMethod('procedure GlobalEarthQuake(const tics: integer);', Self,
    @TScriptGameInfo.GlobalEarthQuake);
  ATable.AddMethod('procedure LocalEarthQuake(const x, y, z: fixed_t; const tics: integer; ' +
    'const intensity: fixed_t; const maxdist: fixed_t);', Self, @TScriptGameInfo.LocalEarthQuake);
  ATable.AddMethod('function GameSkill: integer;', Self, @TScriptGameInfo.GameSkill);
  ATable.AddMethod('function GameMap: integer;', Self, @TScriptGameInfo.GameMap);
  if FGame in [sgDoom, sgHeretic] then
    ATable.AddMethod('function GameEpisode: integer;', Self, @TScriptGameInfo.GameEpisode);
end;

function TScriptGameInfo.GameName: string;
begin
  Result := FSource.GameName;
end;

procedure TScriptGameInfo.GlobalEarthQuake(const ATics: Integer);
begin
  FSource.GlobalEarthQuake(ATics);
end;

procedure TScriptGameInfo.LocalEarthQuake(const X, Y, Z: Integer; const ATics: Integer;
  const AIntensity: Integer; const AMaxDistance: Integer);
begin
  FSource.LocalEarthQuake(X, Y, Z, ATics, AIntensity, AMaxDistance);
end;

function TScriptGameInfo.GameSkill: Integer;
begin
  Result := FSource.Skill;
end;

function TScriptGameInfo.GameMap: Integer;
begin
  Result := FSource.MapNumber;
end;

function TScriptGameInfo.GameEpisode: Integer;
begin
  Result := FSource.Episode;
end;

end.
