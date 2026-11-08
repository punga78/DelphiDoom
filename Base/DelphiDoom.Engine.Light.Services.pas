{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the services that the lights of the game use           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Light.Services;

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Light.Types,
  DelphiDoom.Thinkers.Light.Intf;

//==============================================================================
//
// P_ConfigureLights
//
// Gives the lights what they need from the rest of the engine (the composition
// root calls it); until it is called the lights give an I_Error
//
//==============================================================================
procedure P_ConfigureLights(const ARandom: IGameRandom; const AFlickerRules: ILightFlickerRules;
  const AProfile: TLightSequenceProfile; const APhaseSpawner: ILightPhaseSpawner);

//==============================================================================
//
// LightRandom
//
// The random of the game (the same object as P_Random uses)
//
//==============================================================================
function LightRandom: IGameRandom;

//==============================================================================
//
// LightFlickerRules
//
//==============================================================================
function LightFlickerRules: ILightFlickerRules;

//==============================================================================
//
// LightSequenceProfile
//
//==============================================================================
function LightSequenceProfile: TLightSequenceProfile;

//==============================================================================
//
// LightPhaseSpawner
//
//==============================================================================
function LightPhaseSpawner: ILightPhaseSpawner;

implementation

uses
  i_system;

var
  light_random: IGameRandom;
  light_flicker_rules: ILightFlickerRules;
  light_sequence_profile: TLightSequenceProfile;
  light_phase_spawner: ILightPhaseSpawner;

//==============================================================================
//
// LightsNotConfigured
//
//==============================================================================
procedure LightsNotConfigured;
begin
  I_Error('P_ConfigureLights(): the services of the lights were not given');
end;

//==============================================================================
//
// P_ConfigureLights
//
//==============================================================================
procedure P_ConfigureLights(const ARandom: IGameRandom; const AFlickerRules: ILightFlickerRules;
  const AProfile: TLightSequenceProfile; const APhaseSpawner: ILightPhaseSpawner);
begin
  light_random := ARandom;
  light_flicker_rules := AFlickerRules;
  light_sequence_profile := AProfile;
  light_phase_spawner := APhaseSpawner;
end;

//==============================================================================
//
// LightRandom
//
//==============================================================================
function LightRandom: IGameRandom;
begin
  if light_random = nil then
    LightsNotConfigured;
  result := light_random;
end;

//==============================================================================
//
// LightFlickerRules
//
//==============================================================================
function LightFlickerRules: ILightFlickerRules;
begin
  if light_flicker_rules = nil then
    LightsNotConfigured;
  result := light_flicker_rules;
end;

//==============================================================================
//
// LightSequenceProfile
//
//==============================================================================
function LightSequenceProfile: TLightSequenceProfile;
begin
  if light_phase_spawner = nil then
    LightsNotConfigured;
  result := light_sequence_profile;
end;

//==============================================================================
//
// LightPhaseSpawner
//
//==============================================================================
function LightPhaseSpawner: ILightPhaseSpawner;
begin
  if light_phase_spawner = nil then
    LightsNotConfigured;
  result := light_phase_spawner;
end;

end.
