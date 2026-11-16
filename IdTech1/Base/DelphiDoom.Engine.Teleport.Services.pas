{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the services that the teleports of the game use        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Teleport.Services;

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Teleport.Intf;

//==============================================================================
//
// P_ConfigureTeleport
//
// Gives the teleports what they need from the rest of the engine (the composition
// root calls it); until it is called the teleports give an I_Error
//
//==============================================================================
procedure P_ConfigureTeleport(const AFogSpawner: ITeleportFogSpawner; const ARandom: IGameRandom);

//==============================================================================
//
// TeleportFogSpawner
//
//==============================================================================
function TeleportFogSpawner: ITeleportFogSpawner;

//==============================================================================
//
// TeleportRandom
//
// The random of the game (the same object as P_Random uses)
//
//==============================================================================
function TeleportRandom: IGameRandom;

implementation

uses
  i_system;

var
  teleport_fog_spawner: ITeleportFogSpawner;
  teleport_random: IGameRandom;

//==============================================================================
//
// P_ConfigureTeleport
//
//==============================================================================
procedure P_ConfigureTeleport(const AFogSpawner: ITeleportFogSpawner; const ARandom: IGameRandom);
begin
  teleport_fog_spawner := AFogSpawner;
  teleport_random := ARandom;
end;

//==============================================================================
//
// TeleportFogSpawner
//
//==============================================================================
function TeleportFogSpawner: ITeleportFogSpawner;
begin
  if teleport_fog_spawner = nil then
    I_Error('P_ConfigureTeleport(): the fog spawner was not given');
  result := teleport_fog_spawner;
end;

//==============================================================================
//
// TeleportRandom
//
//==============================================================================
function TeleportRandom: IGameRandom;
begin
  if teleport_random = nil then
    I_Error('P_ConfigureTeleport(): the random of the game was not given');
  result := teleport_random;
end;

end.
