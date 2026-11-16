{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the game that the functions of scripts describe        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.GameInfo;

interface

uses
  DelphiDoom.ScriptHost.Game.Intf;

type
  /// <summary>
  ///   The name, skill, map and episode of the game and the earthquakes, for the scripts. The
  ///   only class that reads these globals (they were in psi_game.pas); the earthquakes are the
  ///   old PS_GlobalEarthQuake and PS_LocalEarthQuake, unchanged
  /// </summary>
  TEngineScriptGameInfo = class(TInterfacedObject, IScriptGameInfoSource)
  public
    function GameName: string;
    function Skill: Integer;
    function MapNumber: Integer;
    function Episode: Integer;
    procedure GlobalEarthQuake(const ATics: Integer);
    procedure LocalEarthQuake(const X, Y, Z: Integer; const ATics: Integer; const AIntensity: Integer;
      const AMaxDistance: Integer);
  end;

implementation

uses
  doomdef,
  d_player,
  g_game,
  m_base,
  m_fixed,
  p_maputl,
  tables;

{ TEngineScriptGameInfo }

function TEngineScriptGameInfo.GameName: string;
begin
  Result := _GAME;
end;

function TEngineScriptGameInfo.Skill: Integer;
begin
  Result := Ord(g_game.gameskill);
end;

function TEngineScriptGameInfo.MapNumber: Integer;
begin
  Result := g_game.gamemap;
end;

function TEngineScriptGameInfo.Episode: Integer;
begin
{$IFDEF DOOM_OR_HERETIC}
  Result := g_game.gameepisode;
{$ELSE}
  // Hexen and Strife have no episodes: scripts do not have the function
  Result := 0;
{$ENDIF}
end;

procedure TEngineScriptGameInfo.GlobalEarthQuake(const ATics: Integer);
var
  LTics: Integer;
  LPlayer: Integer;
begin
  LTics := ATics * FRACUNIT;
  for LPlayer := 0 to MAXPLAYERS - 1 do
    if playeringame[LPlayer] then
    begin
      players[LPlayer].quaketics := LTics;
      players[LPlayer].quakeintensity := FRACUNIT;
    end;
end;

procedure TEngineScriptGameInfo.LocalEarthQuake(const X, Y, Z: Integer; const ATics: Integer;
  const AIntensity: Integer; const AMaxDistance: Integer);
var
  LPlayer: Integer;
  LDistance: fixed_t;
  LFraction: fixed_t;
  LIntensity: fixed_t;
begin
  for LPlayer := 0 to MAXPLAYERS - 1 do
    if playeringame[LPlayer] then
    begin
      LDistance := P_AproxDistance(X - players[LPlayer].mo.x, Y - players[LPlayer].mo.y);
      LDistance := P_AproxDistance(Z - players[LPlayer].mo.z, LDistance); // 3d distance
      if LDistance <= AMaxDistance then
      begin
        if players[LPlayer].quaketics < ATics then
          players[LPlayer].quaketics := ATics;
        LFraction := FixedDiv(LDistance, AMaxDistance) * (FINEANGLES div 4);
        LIntensity := FixedMul(finecosine[LFraction shr ANGLETOFINESHIFT], AIntensity); // JVAL: 20200508 - Curved
        if players[LPlayer].quakeintensity < LIntensity then
          players[LPlayer].quakeintensity := LIntensity;
      end;
    end;
end;

end.
