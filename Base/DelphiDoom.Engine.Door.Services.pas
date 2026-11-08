{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the services that the vertical doors use               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Door.Services;

interface

uses
  DelphiDoom.Thinkers.Door.Intf;

//==============================================================================
//
// P_ConfigureDoors
//
// Gives the doors the classes that run and make them (the composition root
// calls it); until it is called the doors give an I_Error. The classic ones are
// nil in Hexen, which has only the scripted doors
//
//==============================================================================
procedure P_ConfigureDoors(const AClassicRunner: IDoorRunner;
  const AClassicSpawner: IDoorSpawner; const AUdmfRunner: IDoorRunner;
  const AUdmfSpawner: IDoorSpawner);

//==============================================================================
//
// DoorRunner
//
// The runner of the classic doors (AUdmf false) or of the scripted ones
//
//==============================================================================
function DoorRunner(AUdmf: boolean): IDoorRunner;

//==============================================================================
//
// DoorSpawner
//
// The maker of the classic doors (AUdmf false) or of the scripted ones
//
//==============================================================================
function DoorSpawner(AUdmf: boolean): IDoorSpawner;

implementation

uses
  i_system;

var
  door_classic_runner: IDoorRunner;
  door_classic_spawner: IDoorSpawner;
  door_udmf_runner: IDoorRunner;
  door_udmf_spawner: IDoorSpawner;

//==============================================================================
//
// DoorsNotConfigured
//
//==============================================================================
procedure DoorsNotConfigured;
begin
  I_Error('P_ConfigureDoors(): the services of the doors were not given');
end;

//==============================================================================
//
// P_ConfigureDoors
//
//==============================================================================
procedure P_ConfigureDoors(const AClassicRunner: IDoorRunner;
  const AClassicSpawner: IDoorSpawner; const AUdmfRunner: IDoorRunner;
  const AUdmfSpawner: IDoorSpawner);
begin
  door_classic_runner := AClassicRunner;
  door_classic_spawner := AClassicSpawner;
  door_udmf_runner := AUdmfRunner;
  door_udmf_spawner := AUdmfSpawner;
end;

//==============================================================================
//
// DoorRunner
//
//==============================================================================
function DoorRunner(AUdmf: boolean): IDoorRunner;
begin
  if AUdmf then
    result := door_udmf_runner
  else
    result := door_classic_runner;
  if result = nil then
    DoorsNotConfigured;
end;

//==============================================================================
//
// DoorSpawner
//
//==============================================================================
function DoorSpawner(AUdmf: boolean): IDoorSpawner;
begin
  if AUdmf then
    result := door_udmf_spawner
  else
    result := door_classic_spawner;
  if result = nil then
    DoorsNotConfigured;
end;

end.
