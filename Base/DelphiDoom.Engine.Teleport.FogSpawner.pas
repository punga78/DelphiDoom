{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the teleport fog                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Teleport.FogSpawner;

interface

uses
  DelphiDoom.Thinkers.Teleport.Intf;

type
  /// <summary>
  ///   Makes the teleport fog in the level (an MT_TFOG object, P_SpawnMobj) and plays the teleport
  ///   sound at it
  /// </summary>
  TEngineTeleportFogSpawner = class(TInterfacedObject, ITeleportFogSpawner)
  public
    procedure SpawnFog(AX, AY, AZ: Integer; ASound: Boolean);
  end;

implementation

uses
  p_mobj_h,
  p_mobj,
  info_h,
  s_sound,
  sounddata;

{ TEngineTeleportFogSpawner }

procedure TEngineTeleportFogSpawner.SpawnFog(AX, AY, AZ: Integer; ASound: Boolean);
var
  fog: Pmobj_t;
begin
  fog := P_SpawnMobj(AX, AY, AZ, Ord(MT_TFOG));
  if ASound then
{$IFDEF HEXEN}
    S_StartSound(fog, Ord(SFX_TELEPORT));
{$ELSE}
    S_StartSound(fog, Ord(sfx_telept));
{$ENDIF}
end;

end.
