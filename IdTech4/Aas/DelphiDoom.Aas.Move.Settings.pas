{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the physics settings of the bots                  }
{                                                                              }
{  Port of AAS_InitSettings of be_aas_move.c. Based on the Quake III Arena     }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Move.Settings;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Move.Types;

type
  /// <summary>Reads aassettings from the library variables, with the defaults of the original</summary>
  TAasMoveSettingsReader = class sealed
  public
    class function Read(const ALibVars: IBotLibVars): TAasMoveSettings; static;
  end;

implementation

class function TAasMoveSettingsReader.Read(const ALibVars: IBotLibVars): TAasMoveSettings;
begin
  Result.PhysGravityDirection[0] := 0;
  Result.PhysGravityDirection[1] := 0;
  Result.PhysGravityDirection[2] := -1;
  Result.PhysFriction := ALibVars.GetValueOrCreate('phys_friction', '6');
  Result.PhysStopSpeed := ALibVars.GetValueOrCreate('phys_stopspeed', '100');
  Result.PhysGravity := ALibVars.GetValueOrCreate('phys_gravity', '800');
  Result.PhysWaterFriction := ALibVars.GetValueOrCreate('phys_waterfriction', '1');
  Result.PhysWaterGravity := ALibVars.GetValueOrCreate('phys_watergravity', '400');
  Result.PhysMaxVelocity := ALibVars.GetValueOrCreate('phys_maxvelocity', '320');
  Result.PhysMaxWalkVelocity := ALibVars.GetValueOrCreate('phys_maxwalkvelocity', '320');
  Result.PhysMaxCrouchVelocity := ALibVars.GetValueOrCreate('phys_maxcrouchvelocity', '100');
  Result.PhysMaxSwimVelocity := ALibVars.GetValueOrCreate('phys_maxswimvelocity', '150');
  Result.PhysWalkAccelerate := ALibVars.GetValueOrCreate('phys_walkaccelerate', '10');
  Result.PhysAirAccelerate := ALibVars.GetValueOrCreate('phys_airaccelerate', '1');
  Result.PhysSwimAccelerate := ALibVars.GetValueOrCreate('phys_swimaccelerate', '4');
  Result.PhysMaxStep := ALibVars.GetValueOrCreate('phys_maxstep', '19');
  Result.PhysMaxSteepness := ALibVars.GetValueOrCreate('phys_maxsteepness', '0.7');
  Result.PhysMaxWaterJump := ALibVars.GetValueOrCreate('phys_maxwaterjump', '18');
  Result.PhysMaxBarrier := ALibVars.GetValueOrCreate('phys_maxbarrier', '33');
  Result.PhysJumpVel := ALibVars.GetValueOrCreate('phys_jumpvel', '270');
  Result.PhysFallDelta5 := ALibVars.GetValueOrCreate('phys_falldelta5', '40');
  Result.PhysFallDelta10 := ALibVars.GetValueOrCreate('phys_falldelta10', '60');
  Result.RsWaterJump := ALibVars.GetValueOrCreate('rs_waterjump', '400');
  Result.RsTeleport := ALibVars.GetValueOrCreate('rs_teleport', '50');
  Result.RsBarrierJump := ALibVars.GetValueOrCreate('rs_barrierjump', '100');
  Result.RsStartCrouch := ALibVars.GetValueOrCreate('rs_startcrouch', '300');
  Result.RsStartGrapple := ALibVars.GetValueOrCreate('rs_startgrapple', '500');
  Result.RsStartWalkOffLedge := ALibVars.GetValueOrCreate('rs_startwalkoffledge', '70');
  Result.RsStartJump := ALibVars.GetValueOrCreate('rs_startjump', '300');
  Result.RsRocketJump := ALibVars.GetValueOrCreate('rs_rocketjump', '500');
  Result.RsBfgJump := ALibVars.GetValueOrCreate('rs_bfgjump', '500');
  Result.RsJumpPad := ALibVars.GetValueOrCreate('rs_jumppad', '250');
  Result.RsAirControlledJumpPad := ALibVars.GetValueOrCreate('rs_aircontrolledjumppad', '300');
  Result.RsFuncBob := ALibVars.GetValueOrCreate('rs_funcbob', '300');
  Result.RsStartElevator := ALibVars.GetValueOrCreate('rs_startelevator', '50');
  Result.RsFallDamage5 := ALibVars.GetValueOrCreate('rs_falldamage5', '300');
  Result.RsFallDamage10 := ALibVars.GetValueOrCreate('rs_falldamage10', '500');
  Result.RsMaxFallHeight := ALibVars.GetValueOrCreate('rs_maxfallheight', '0');
  Result.RsMaxJumpFallHeight := ALibVars.GetValueOrCreate('rs_maxjumpfallheight', '450');
end;

end.
