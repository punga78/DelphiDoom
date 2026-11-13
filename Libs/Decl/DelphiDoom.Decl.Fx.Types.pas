{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - types of the "fx" declaration             }
{                                                                              }
{  Port of the effects of Doom 3 (id Software, GPL v3): framework\DeclFX.h.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Fx.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Decl.Types;

const
  /// <summary>The kinds of action (the anonymous enum of DeclFX.h); an action that was not given a kind has -1</summary>
  FX_NONE = -1;
  FX_LIGHT = 0;
  FX_PARTICLE = 1;
  FX_DECAL = 2;
  FX_MODEL = 3;
  FX_SOUND = 4;
  FX_SHAKE = 5;
  FX_ATTACHLIGHT = 6;
  FX_ATTACHENTITY = 7;
  FX_LAUNCH = 8;
  FX_SHOCKWAVE = 9;

type
  /// <summary>A problem found while reading or using an effect declaration</summary>
  EDeclFxException = class(EDeclException);

  /// <summary>
  ///   idFXSingleAction: one action of an effect. <c>Data</c> is the name of what it uses (a sound, a light
  ///   material, a model, a particle, a decal material, an entity def). <c>SoundStarted</c> and <c>ShakeStarted</c> are
  ///   state of the game while the effect plays, and start false.
  /// </summary>
  TFxAction = record
    ActionType: Integer;
    /// <summary>The index of the earlier action a <c>uselight</c> or <c>useModel</c> refers to, -1 if none</summary>
    Sibling: Integer;
    Data: AnsiString;
    Name: AnsiString;
    Fire: AnsiString;
    Delay: Single;
    Duration: Single;
    Restart: Single;
    Size: Single;
    FadeInTime: Single;
    FadeOutTime: Single;
    ShakeTime: Single;
    ShakeAmplitude: Single;
    ShakeDistance: Single;
    ShakeImpulse: Single;
    LightRadius: Single;
    Rotate: Single;
    Random1: Single;
    Random2: Single;
    LightColor: TIdVec3;
    Offset: TIdVec3;
    Axis: TIdMat3;
    SoundStarted: Boolean;
    ShakeStarted: Boolean;
    ShakeFalloff: Boolean;
    ShakeIgnoreMaster: Boolean;
    BindParticles: Boolean;
    ExplicitAxis: Boolean;
    NoShadows: Boolean;
    ParticleTrackVelocity: Boolean;
    TrackOrigin: Boolean;
    /// <summary>The action <c>ParseSingleFXAction</c> starts from: no type, <c>&lt;none&gt;</c> names, zeros, identity axis</summary>
    class function Create: TFxAction; static;
  end;

implementation

{ TFxAction }

class function TFxAction.Create: TFxAction;
begin
  Result.ActionType := FX_NONE;
  Result.Sibling := -1;
  Result.Data := '<none>';
  Result.Name := '<none>';
  Result.Fire := '<none>';
  Result.Delay := 0.0;
  Result.Duration := 0.0;
  Result.Restart := 0.0;
  Result.Size := 0.0;
  Result.FadeInTime := 0.0;
  Result.FadeOutTime := 0.0;
  Result.ShakeTime := 0.0;
  Result.ShakeAmplitude := 0.0;
  Result.ShakeDistance := 0.0;
  Result.ShakeImpulse := 0.0;
  Result.LightRadius := 0.0;
  Result.Rotate := 0.0;
  Result.Random1 := 0.0;
  Result.Random2 := 0.0;
  Result.LightColor.Zero;
  Result.Offset.Zero;
  Result.Axis := TIdMat3.Identity;
  Result.SoundStarted := False;
  Result.ShakeStarted := False;
  Result.ShakeFalloff := False;
  Result.ShakeIgnoreMaster := False;
  Result.BindParticles := False;
  Result.ExplicitAxis := False;
  Result.NoShadows := False;
  Result.ParticleTrackVelocity := False;
  Result.TrackOrigin := False;
end;

end.
