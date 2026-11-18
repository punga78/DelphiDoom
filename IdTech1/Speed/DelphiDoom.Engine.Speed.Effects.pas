{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the particles and the sounds of the cars               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Speed.Effects;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   What the cars make appear and hear, on the engine: the particles are the objects of the actors of
  ///   WorldActors (SMOK, SPRK, GND of the data), the sounds are the ones of SNDINFO (speedhaste/MOTORn_m for
  ///   the engine, speedhaste/DERRAPE.RAW for the brakes) played from the object of the car. It reads the
  ///   historical globals of the engine: this is a class of the engine
  /// </summary>
  TEngineSpeedEffects = class(TInterfacedObject, IRacingEffects)
  strict private
    FFindCar: TFunc<Cardinal, Pointer>;
    FSelected: Cardinal;
    FParticles: Integer;
    FEngineSounds: Integer;
    FBrakeSounds: Integer;
    FParticleTypes: array[TRacingParticleKind] of Integer;
    function DurationOf(const ALump: string): Integer;
  public
    /// <param name="AFindCar">Gives the object (a Pmobj_t) of the car that has a key, or nil</param>
    constructor Create(const AFindCar: TFunc<Cardinal, Pointer>);
    procedure SelectCar(AKey: Cardinal);
    procedure SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX, AMomentumY: TFixed);
    function PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
    function PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
    property Particles: Integer read FParticles;
    property EngineSounds: Integer read FEngineSounds;
    property BrakeSounds: Integer read FBrakeSounds;
  end;

implementation

uses
  info_common,
  p_mobj,
  p_mobj_h,
  s_sound,
  w_wad,
  z_zone,
  DelphiDoom.Speed.WorldActors;

const
  // when a sound is not in the data: a car asks again after this many tics
  DEFAULT_SOUND_TICS = 35;
  TICS_PER_SECOND = 35;
  ENGINE_SOUND_FORMAT = 'speedhaste/MOTOR%d_%d';
  ENGINE_LUMP_FORMAT = 'MOTOR%d_%d';
  BRAKE_SOUND = 'speedhaste/DERRAPE.RAW';
  BRAKE_LUMP = 'DS_00003';

{ TEngineSpeedEffects }

constructor TEngineSpeedEffects.Create(const AFindCar: TFunc<Cardinal, Pointer>);
var
  LKind: TRacingParticleKind;
begin
  inherited Create;
  if not Assigned(AFindCar) then
    raise EArgumentNilException.Create('AFindCar');
  FFindCar := AFindCar;
  for LKind := Low(TRacingParticleKind) to High(TRacingParticleKind) do
    FParticleTypes[LKind] := -2;
end;

procedure TEngineSpeedEffects.SelectCar(AKey: Cardinal);
begin
  FSelected := AKey;
end;

// How long a sound lump lasts in tics: the lumps of sounds are DMX (format 3, rate, number of samples)
function TEngineSpeedEffects.DurationOf(const ALump: string): Integer;
var
  LLump: Integer;
  LHeader: PByteArray;
  LRate, LSamples: Integer;
begin
  Result := DEFAULT_SOUND_TICS;
  LLump := TWadRoutines.W_CheckNumForName(ALump);
  if (LLump < 0) or (TWadRoutines.W_LumpLength(LLump) < 8) then
    Exit;
  LHeader := TWadRoutines.W_CacheLumpNum(LLump, PU_STATIC);
  LRate := LHeader[2] or (LHeader[3] shl 8);
  LSamples := LHeader[4] or (LHeader[5] shl 8) or (LHeader[6] shl 16) or (LHeader[7] shl 24);
  Z_ChangeTag(LHeader, PU_CACHE);
  if (LRate > 0) and (LSamples > 0) then
    Result := LSamples * TICS_PER_SECOND div LRate + 1;
end;

procedure TEngineSpeedEffects.SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX,
  AMomentumY: TFixed);
var
  LMobj: Pmobj_t;
begin
  Inc(FParticles);
  if FParticleTypes[AKind] = -2 then
    FParticleTypes[AKind] := Info_GetMobjNumForName(TSpeedWorldActors.ParticleActorName(AKind));
  if FParticleTypes[AKind] < 0 then
    Exit;
  LMobj := P_SpawnMobj(AX, AY, AZ, FParticleTypes[AKind]);
  if LMobj <> nil then
  begin
    LMobj.momx := AMomentumX;
    LMobj.momy := AMomentumY;
  end;
end;

function TEngineSpeedEffects.PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
var
  LFamily: Integer;
begin
  Inc(FEngineSounds);
  LFamily := Ord(not AFormula);
  TSoundRoutines.S_StartSound(FFindCar(FSelected), Format(ENGINE_SOUND_FORMAT, [LFamily, AFraction]));
  Result := DurationOf(Format(ENGINE_LUMP_FORMAT, [LFamily, AFraction]));
end;

function TEngineSpeedEffects.PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
begin
  Inc(FBrakeSounds);
  TSoundRoutines.S_StartSound(FFindCar(FSelected), BRAKE_SOUND);
  Result := DurationOf(BRAKE_LUMP);
end;

end.
