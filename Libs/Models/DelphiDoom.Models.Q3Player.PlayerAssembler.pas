{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, legs, torso and    }
{  head together                                                               }
{                                                                              }
{  Port of the placing of the parts in CG_Player of cgame\cg_players.c and of  }
{  the weapon in CG_AddPlayerWeapon of cgame\cg_weapons.c. Based on the        }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.PlayerAssembler;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>
  ///   The three models of a player: the legs stand at the origin of the player; the torso is on
  ///   "tag_torso" of the legs model; the head on "tag_head" of the torso model.
  /// </summary>
  TQ3PlayerAssembler = class(TInterfacedObject, IQ3PlayerAssembler)
  strict private
    FPositioner: IQ3TagPositioner;
  public
    constructor Create(const APositioner: IQ3TagPositioner);
    procedure Assemble(const ALegsModel, ATorsoModel: IMd3Model; const AOrigin: TIdVec3;
      const ALegsAxis, ATorsoAxis, AHeadAxis: TQ3Axis; const AFrames: TQ3PlayerFrames;
      out ALegs, ATorso, AHead: TQ3Entity);
    procedure PositionWeapon(const ATorso: TQ3Entity; const ATorsoModel: IMd3Model; out AGun: TQ3Entity);
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.FloatMath;

constructor TQ3PlayerAssembler.Create(const APositioner: IQ3TagPositioner);
begin
  inherited Create;
  FPositioner := APositioner;
end;

procedure TQ3PlayerAssembler.Assemble(const ALegsModel, ATorsoModel: IMd3Model; const AOrigin: TIdVec3;
  const ALegsAxis, ATorsoAxis, AHeadAxis: TQ3Axis; const AFrames: TQ3PlayerFrames;
  out ALegs, ATorso, AHead: TQ3Entity);
begin
  FillChar(ALegs, SizeOf(ALegs), 0);
  FillChar(ATorso, SizeOf(ATorso), 0);
  FillChar(AHead, SizeOf(AHead), 0);

  ALegs.Axis := ALegsAxis;
  ALegs.OldFrame := AFrames.LegsOld;
  ALegs.Frame := AFrames.Legs;
  ALegs.BackLerp := AFrames.LegsBackLerp;
  ALegs.Origin := AOrigin;

  ATorso.Axis := ATorsoAxis;
  ATorso.OldFrame := AFrames.TorsoOld;
  ATorso.Frame := AFrames.Torso;
  ATorso.BackLerp := AFrames.TorsoBackLerp;
  FPositioner.PositionRotatedEntityOnTag(ATorso, ALegs, ALegsModel, 'tag_torso');

  AHead.Axis := AHeadAxis;
  FPositioner.PositionRotatedEntityOnTag(AHead, ATorso, ATorsoModel, 'tag_head');
end;

procedure TQ3PlayerAssembler.PositionWeapon(const ATorso: TQ3Entity; const ATorsoModel: IMd3Model;
  out AGun: TQ3Entity);
begin
  FillChar(AGun, SizeOf(AGun), 0);
  TQ3FloatMath.AxisClear(AGun.Axis);
  FPositioner.PositionEntityOnTag(AGun, ATorso, ATorsoModel, 'tag_weapon');
end;

end.
