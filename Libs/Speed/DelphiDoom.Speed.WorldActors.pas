{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - the scenery and the particles as ACTORDEF       }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The actors of WADSRC/SPEED/BASEDECORATIONS.txt and PARTICLES.txt of the     }
{  fork whose pictures are lumps of SPEEDH.JCL (S020..S02F, SMOK, SPRK, GND)   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.WorldActors;

interface

uses
  System.SysUtils, DelphiDoom.GameData.Intf, DelphiDoom.Racing.Types;

const
  /// <summary>The name of the actor of a kind of particle (SpeedParticleSpark...)</summary>
  SPEED_PARTICLE_ACTOR_PREFIX = 'SpeedParticle';

type
  TSpeedWorldActors = class
  public
    /// <summary>
    ///   The ACTORDEF text of the trees, the lamps and the other scenery that has a picture in the WAD,
    ///   with the radius, the height, the scale and whether it blocks, as in BASEDECORATIONS.txt
    /// </summary>
    /// <exception cref="EArgumentNilException">AWad is nil</exception>
    class function Scenery(const AWad: IGameWadComposer): string; static;
    /// <summary>The ACTORDEF text of the actors of the particles whose pictures the WAD has</summary>
    /// <exception cref="EArgumentNilException">AWad is nil</exception>
    class function Particles(const AWad: IGameWadComposer): string; static;
    /// <summary>The name of the actor of a kind of particle</summary>
    class function ParticleActorName(AKind: TRacingParticleKind): string; static;
  end;

implementation

type
  TSceneryItem = record
    ThingType: Integer;
    Sprite: string;
    Radius: Integer;
    Height: Integer;
    Scale: string;
    Solid: Boolean;
  end;

const
  // BASEDECORATIONS.txt of the fork (the tree of the type 2160 uses the picture of the type 34)
  SCENERY_ITEMS: array[0..16] of TSceneryItem = (
    (ThingType: 32; Sprite: 'S020'; Radius: 16; Height: 120; Scale: '2'; Solid: True),
    (ThingType: 33; Sprite: 'S021'; Radius: 24; Height: 76; Scale: '2'; Solid: True),
    (ThingType: 34; Sprite: 'S022'; Radius: 16; Height: 100; Scale: '2'; Solid: True),
    (ThingType: 2160; Sprite: 'S022'; Radius: 12; Height: 75; Scale: '1.5'; Solid: True),
    (ThingType: 35; Sprite: 'S023'; Radius: 16; Height: 76; Scale: '2'; Solid: True),
    (ThingType: 36; Sprite: 'S024'; Radius: 8; Height: 196; Scale: '2'; Solid: True),
    (ThingType: 37; Sprite: 'S025'; Radius: 8; Height: 196; Scale: '2'; Solid: True),
    (ThingType: 38; Sprite: 'S026'; Radius: 16; Height: 76; Scale: '2'; Solid: True),
    (ThingType: 39; Sprite: 'S027'; Radius: 16; Height: 76; Scale: '2'; Solid: True),
    (ThingType: 40; Sprite: 'S028'; Radius: 16; Height: 64; Scale: '2'; Solid: True),
    (ThingType: 41; Sprite: 'S029'; Radius: 16; Height: 76; Scale: '2'; Solid: True),
    (ThingType: 42; Sprite: 'S02A'; Radius: 32; Height: 144; Scale: '2'; Solid: True),
    (ThingType: 43; Sprite: 'S02B'; Radius: 64; Height: 64; Scale: '2'; Solid: True),
    (ThingType: 44; Sprite: 'S02C'; Radius: 16; Height: 96; Scale: '2'; Solid: True),
    (ThingType: 45; Sprite: 'S02D'; Radius: 20; Height: 24; Scale: '2'; Solid: False),
    (ThingType: 46; Sprite: 'S02E'; Radius: 12; Height: 16; Scale: '2'; Solid: False),
    (ThingType: 47; Sprite: 'S02F'; Radius: 20; Height: 24; Scale: '2'; Solid: True));

  // the particles: the kind, the sprite of the fork and how long a picture stays (PARTICLES.txt)
  PARTICLE_SPRITES: array[TRacingParticleKind] of string = ('SPRK', 'SMOK', 'GND2', 'GND1', 'GND0');
  PARTICLE_NAMES: array[TRacingParticleKind] of string = ('Spark', 'Smoke', 'Grass', 'Dirt', 'Sand');
  FRAMES = 'ABCDEF';
  FRAME_TICS = 5;

{ TSpeedWorldActors }

class function TSpeedWorldActors.Scenery(const AWad: IGameWadComposer): string;
var
  LItem: TSceneryItem;
  LBuilder: TStringBuilder;
begin
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  LBuilder := TStringBuilder.Create;
  try
    for LItem in SCENERY_ITEMS do
    begin
      if AWad.IndexOf(LItem.Sprite + 'A0') < 0 then
        Continue;
      LBuilder.Append('ACTOR SpeedScenery').Append(LItem.ThingType).Append(' ').Append(LItem.ThingType).Append(#13#10);
      LBuilder.Append('{'#13#10);
      LBuilder.Append('  Radius ').Append(LItem.Radius).Append(#13#10);
      LBuilder.Append('  Height ').Append(LItem.Height).Append(#13#10);
      LBuilder.Append('  Scale ').Append(LItem.Scale).Append(#13#10);
      if LItem.Solid then
        LBuilder.Append('  +SOLID'#13#10);
      LBuilder.Append('  States'#13#10'  {'#13#10'  Spawn:'#13#10'    ').Append(LItem.Sprite).Append(' A -1'#13#10);
      LBuilder.Append('    Stop'#13#10'  }'#13#10'}'#13#10);
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

class function TSpeedWorldActors.ParticleActorName(AKind: TRacingParticleKind): string;
begin
  Result := SPEED_PARTICLE_ACTOR_PREFIX + PARTICLE_NAMES[AKind];
end;

class function TSpeedWorldActors.Particles(const AWad: IGameWadComposer): string;
var
  LKind: TRacingParticleKind;
  LBuilder: TStringBuilder;
  LFrame: Integer;
begin
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  LBuilder := TStringBuilder.Create;
  try
    for LKind := Low(TRacingParticleKind) to High(TRacingParticleKind) do
    begin
      if AWad.IndexOf(PARTICLE_SPRITES[LKind] + 'A0') < 0 then
        Continue;
      LBuilder.Append('ACTOR ').Append(ParticleActorName(LKind)).Append(#13#10);
      LBuilder.Append('{'#13#10'  Radius 8'#13#10'  Height 8'#13#10'  +NOBLOCKMAP'#13#10'  +NOGRAVITY'#13#10);
      LBuilder.Append('  States'#13#10'  {'#13#10'  Spawn:'#13#10);
      for LFrame := 1 to Length(FRAMES) do
        LBuilder.Append('    ').Append(PARTICLE_SPRITES[LKind]).Append(' ').Append(FRAMES[LFrame]).Append(' ')
          .Append(FRAME_TICS).Append(#13#10);
      LBuilder.Append('    Stop'#13#10'  }'#13#10'}'#13#10);
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
