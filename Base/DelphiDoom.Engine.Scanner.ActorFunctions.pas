{******************************************************************************}
{                                                                              }
{  DelphiDoom: the functions of the expressions of the actor parameters         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.ActorFunctions;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Scanner.ContextEvaluator.Intf;

type
  /// <summary>
  ///   Port of the PF_* functions of TActorEvaluator (sc_evaluate_actor.pas): what an
  ///   expression in the parameters of an actor can read (random numbers, the level, the
  ///   position, the properties and the states of the actor, the PascalScript variables, the
  ///   custom parameters). The context of each function is the Pmobj_t of the actor
  /// </summary>
  TEngineActorExpressionFunctions = class
  strict private
    /// <summary>A parameter as TDStringList gave it: an empty text out of the list</summary>
    class function Param(const AParams: TArray<string>; AIndex: Integer): string; static;
    // Random functions
    class function PF_rand(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_sysrand(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_random(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_random2(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_frandom(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_randompick(AContext: Pointer; const p: TArray<string>): string; static;
    // General
    class function PF_leveltime(AContext: Pointer; const p: TArray<string>): string; static;
{$IFDEF DOOM_OR_HERETIC}
    class function PF_gameepisode(AContext: Pointer; const p: TArray<string>): string; static;
{$ENDIF}
    class function PF_gamemap(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_levelname(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_gameskill(AContext: Pointer; const p: TArray<string>): string; static;
    // Actor position and movement
    class function PF_X(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_Y(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_Z(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MOMX(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MOMY(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MOMZ(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_FLOORZ(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_CEILINGZ(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_ANGLE(AContext: Pointer; const p: TArray<string>): string; static;
    // Actor properties
    class function PF_flag(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_radius(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_height(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_alpha(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_health(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_reactiontime(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_threshold(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_fastchasetics(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_key(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_floorclip(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_gravity(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_pushfactor(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_friction(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_scale(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_mass(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_special(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_arg1(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_arg2(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_arg3(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_arg4(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_arg5(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_WeaveIndexXY(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_WeaveIndexZ(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_SpriteDX(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_SpriteDY(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_PainChance(AContext: Pointer; const p: TArray<string>): string; static;
    // MBF21
    class function PF_InfightingGroup(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_ProjectileGroup(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_SplashGroup(AContext: Pointer; const p: TArray<string>): string; static;
    // Pascalscript map & world variables
    class function PF_MAPSTR(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_WORLDSTR(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MAPINT(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_WORLDINT(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MAPFLOAT(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_WORLDFLOAT(AContext: Pointer; const p: TArray<string>): string; static;
    // Custom params
    class function PF_CUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_TARGETCUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MASTERCUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_TRACERCUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string; static;
    // States
    class function PF_SPAWN(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_SEE(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MELEE(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_MISSILE(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_PAIN(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_DEATH(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_XDEATH(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_HEAL(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_CRASH(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_CRUSH(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_INTERACT(AContext: Pointer; const p: TArray<string>): string; static;
    class function PF_RAISE(AContext: Pointer; const p: TArray<string>): string; static;
    // Special
    class function PF_EVAL(AContext: Pointer; const p: TArray<string>): string; static;
  public
    /// <summary>Adds every function, with the names and the number of arguments of the old code</summary>
    class procedure Register(const ARegistry: IContextFunctionRegistry); static;
  end;

implementation

uses
  d_delphi,
  Math,
  g_game,
  m_fixed,
  {$IFDEF HERETIC}
  r_defs,
  {$ENDIF}
  p_common,
  p_mobj_h,
  p_params,
  p_setup,
  p_tick,
  psi_globals,
  m_rnd;

//==============================================================================
//
// TEngineActorExpressionFunctions.Register
//
//==============================================================================
class procedure TEngineActorExpressionFunctions.Register(const ARegistry: IContextFunctionRegistry);
begin
  // Random functions
  ARegistry.AddFunction('RAND', PF_rand, 0);
  ARegistry.AddFunction('SYSRAND', PF_sysrand, -1);
  ARegistry.AddFunction('RANDOM', PF_random, -1);
  ARegistry.AddFunction('RANDOM2', PF_random2, -1);
  ARegistry.AddFunction('FLOATRANDOM', PF_frandom, -1);
  ARegistry.AddFunction('FRANDOM', PF_frandom, -1);
  ARegistry.AddFunction('RANDOMPICK', PF_randompick, -1);
  ARegistry.AddFunction('FRANDOMPICK', PF_randompick, -1);
  // General
  ARegistry.AddFunction('LEVELTIME', PF_leveltime, -1);
{$IFDEF DOOM_OR_HERETIC}
  ARegistry.AddFunction('GAMEEPISODE', PF_gameepisode, -1);
{$ENDIF}
  ARegistry.AddFunction('GAMEMAP', PF_gamemap, -1);
  ARegistry.AddFunction('LEVELNAME', PF_levelname, -1);
  ARegistry.AddFunction('GAMESKILL', PF_gameskill, -1);
  // Actor position and movement
  ARegistry.AddFunction('X', PF_X, 0);
  ARegistry.AddFunction('Y', PF_Y, 0);
  ARegistry.AddFunction('Z', PF_Z, 0);
  ARegistry.AddFunction('MOMX', PF_MOMX, 0);
  ARegistry.AddFunction('VELX', PF_MOMX, 0);
  ARegistry.AddFunction('MOMY', PF_MOMY, 0);
  ARegistry.AddFunction('VELY', PF_MOMY, 0);
  ARegistry.AddFunction('MOMZ', PF_MOMZ, 0);
  ARegistry.AddFunction('VELZ', PF_MOMZ, 0);
  ARegistry.AddFunction('FLOORZ', PF_FLOORZ, 0);
  ARegistry.AddFunction('CEILINGZ', PF_CEILINGZ, 0);
  ARegistry.AddFunction('ANGLE', PF_ANGLE, 0);
  // Actor properties
  ARegistry.AddFunction('FLAG', PF_flag, 1);
  ARegistry.AddFunction('RADIUS', PF_radius, 0);
  ARegistry.AddFunction('HEIGHT', PF_height, 0);
  ARegistry.AddFunction('ALPHA', PF_alpha, 0);
  ARegistry.AddFunction('HEALTH', PF_health, 0);
  ARegistry.AddFunction('REACTIONTIME', PF_reactiontime, 0);
  ARegistry.AddFunction('THRESHOLD', PF_threshold, 0);
  ARegistry.AddFunction('FASTCHASETICS', PF_fastchasetics, 0);
  ARegistry.AddFunction('KEY', PF_key, 0);
  ARegistry.AddFunction('FLOORCLIP', PF_floorclip, 0);
  ARegistry.AddFunction('GRAVITY', PF_gravity, 0);
  ARegistry.AddFunction('PUSHFACTOR', PF_pushfactor, 0);
  ARegistry.AddFunction('FRICTION', PF_friction, 0);
  ARegistry.AddFunction('SCALE', PF_scale, 0);
  ARegistry.AddFunction('MASS', PF_mass, 0);
  ARegistry.AddFunction('SPECIAL', PF_special, 0);
  ARegistry.AddFunction('ARG1', PF_arg1, 0);
  ARegistry.AddFunction('ARG2', PF_arg2, 0);
  ARegistry.AddFunction('ARG3', PF_arg3, 0);
  ARegistry.AddFunction('ARG4', PF_arg4, 0);
  ARegistry.AddFunction('ARG5', PF_arg5, 0);
  ARegistry.AddFunction('WEAVEINDEXXY', PF_WeaveIndexXY, 0);
  ARegistry.AddFunction('WEAVEINDEXZ', PF_WeaveIndexZ, 0);
  ARegistry.AddFunction('SPRITEDX', PF_SpriteDX, 0);
  ARegistry.AddFunction('SPRITEDY', PF_SpriteDY, 0);
  ARegistry.AddFunction('PAINCHANCE', PF_PainChance, 0);
  // MBF21
  ARegistry.AddFunction('INFIGHTINGGROUP', PF_InfightingGroup, 0);
  ARegistry.AddFunction('PROJECTILEGROUP', PF_ProjectileGroup, 0);
  ARegistry.AddFunction('SPLASHGROUP', PF_SplashGroup, 0);
  // Pascalscript map & world variables
  ARegistry.AddFunction('MAPSTR', PF_MAPSTR, 1);
  ARegistry.AddFunction('WORLDSTR', PF_WORLDSTR, 1);
  ARegistry.AddFunction('MAPINT', PF_MAPINT, 1);
  ARegistry.AddFunction('WORLDINT', PF_WORLDINT, 1);
  ARegistry.AddFunction('MAPFLOAT', PF_MAPFLOAT, 1);
  ARegistry.AddFunction('WORLDFLOAT', PF_WORLDFLOAT, 1);
  // Custom params
  ARegistry.AddFunction('CUSTOMPARAM', PF_CUSTOMPARAM, 1);
  ARegistry.AddFunction('PARAM', PF_CUSTOMPARAM, 1);
  ARegistry.AddFunction('TARGETCUSTOMPARAM', PF_TARGETCUSTOMPARAM, 1);
  ARegistry.AddFunction('TARGETPARAM', PF_TARGETCUSTOMPARAM, 1);
  ARegistry.AddFunction('MASTERCUSTOMPARAM', PF_MASTERCUSTOMPARAM, 1);
  ARegistry.AddFunction('MASTERPARAM', PF_MASTERCUSTOMPARAM, 1);
  ARegistry.AddFunction('TRACERCUSTOMPARAM', PF_TRACERCUSTOMPARAM, 1);
  ARegistry.AddFunction('TRACERPARAM', PF_TRACERCUSTOMPARAM, 1);
  // States
  ARegistry.AddFunction('SPAWN', PF_SPAWN, 0);
  ARegistry.AddFunction('SEE', PF_SEE, 0);
  ARegistry.AddFunction('MELEE', PF_MELEE, 0);
  ARegistry.AddFunction('MISSILE', PF_MISSILE, 0);
  ARegistry.AddFunction('PAIN', PF_PAIN, 0);
  ARegistry.AddFunction('DEATH', PF_DEATH, 0);
  ARegistry.AddFunction('XDEATH', PF_XDEATH, 0);
  ARegistry.AddFunction('HEAL', PF_HEAL, 0);
  ARegistry.AddFunction('CRASH', PF_CRASH, 0);
  ARegistry.AddFunction('CRUSH', PF_CRUSH, 0);
  ARegistry.AddFunction('INTERACT', PF_INTERACT, 0);
  ARegistry.AddFunction('RAISE', PF_RAISE, 0);
  ARegistry.AddFunction('EVAL', PF_EVAL, -1);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.Param
//
//==============================================================================
class function TEngineActorExpressionFunctions.Param(const AParams: TArray<string>; AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < Length(AParams)) then
    Result := AParams[AIndex]
  else
    Result := '';
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_rand
//
// Ramdom functions
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_rand(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(P_Random / 255);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_sysrand
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_sysrand(AContext: Pointer; const p: TArray<string>): string;
var
  f1, f2: float;
begin
  if Length(p) = 0 then
    result := itoa(Sys_Random)
  else if Length(p) = 1 then
  begin
    f1 := atof(Param(p, 0));
    result := itoa(Sys_Random * round(f1) div 256)
  end
  else
  begin
    f1 := atof(Param(p, 0));
    f2 := atof(Param(p, 1));
    result := itoa(round(f1) + Sys_Random * (round(f2) - round(f1) + 1) div 256);
  end;
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_random
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_random(AContext: Pointer; const p: TArray<string>): string;
var
  f1, f2: float;
begin
  if Length(p) = 0 then
    result := itoa(N_Random)
  else if Length(p) = 1 then
  begin
    f1 := atof(Param(p, 0));
    result := itoa(N_Random * round(f1) div 256)
  end
  else
  begin
    f1 := atof(Param(p, 0));
    f2 := atof(Param(p, 1));
    result := itoa(round(f1) + N_Random * (round(f2) - round(f1) + 1) div 256);
  end;
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_random2
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_random2(AContext: Pointer; const p: TArray<string>): string;
var
  mask: integer;
begin
  if Length(p) > 0 then
    mask := round(atof(Param(p, 0)))
  else
    mask := 255;
  result := itoa((N_Random and mask) - (N_Random and mask));
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_frandom
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_frandom(AContext: Pointer; const p: TArray<string>): string;
var
  f1, f2: float;
begin
  if Length(p) = 0 then
    result := ftoa(N_Random)
  else if Length(p) = 1 then
  begin
    f1 := atof(Param(p, 0));
    result := ftoa(N_Random / 255 * f1)
  end
  else
  begin
    f1 := atof(Param(p, 0));
    f2 := atof(Param(p, 1));
    result := ftoa(f1 + N_Random / 255 * (f2 - f1 + 1));
  end;
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_randompick
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_randompick(AContext: Pointer; const p: TArray<string>): string;
begin
  if Length(p) = 0 then
  begin
    result := '';
    exit;
  end;
  result := Param(p, N_Random mod Length(p));
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_leveltime
//
// General
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_leveltime(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(leveltime);
end;

{$IFDEF DOOM_OR_HERETIC}

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_gameepisode
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_gameepisode(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(gameepisode);
end;
{$ENDIF}

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_gamemap
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_gamemap(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(gamemap);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_levelname
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_levelname(AContext: Pointer; const p: TArray<string>): string;
begin
  result := P_GetMapName({$IFDEF DOOM_OR_HERETIC}gameepisode, {$ENDIF}gamemap);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_gameskill
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_gameskill(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Ord(gameskill));
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_X
//
// Actor position and movement
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_X(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).x / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_Y
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_Y(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).y / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_Z
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_Z(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).z / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MOMX
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MOMX(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).momx / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MOMY
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MOMY(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).momy / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MOMZ
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MOMZ(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).momz / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_FLOORZ
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_FLOORZ(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).floorz / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_CEILINGZ
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_CEILINGZ(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).ceilingz / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_ANGLE
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_ANGLE(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).angle / $FFFFFFFF * 360);
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_flag
//
// Actor properties
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_flag(AContext: Pointer; const p: TArray<string>): string;
begin
  if Length(p) = 0 then
  begin
    result := 'FALSE';
    exit;
  end;
  if P_CheckFlag(Pmobj_t(AContext), Param(p, 0)) then
    result := 'TRUE'
  else
    result := 'FALSE';
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_radius
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_radius(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).radius / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_height
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_height(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).height / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_alpha
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_alpha(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).alpha / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_health
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_health(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).health);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_reactiontime
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_reactiontime(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).reactiontime);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_threshold
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_threshold(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).threshold);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_fastchasetics
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_fastchasetics(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).fastchasetics);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_key
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_key(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).key);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_floorclip
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_floorclip(AContext: Pointer; const p: TArray<string>): string;
begin
{$IFDEF HERETIC}
  if (Pmobj_t(AContext).flags2 and MF2_FEETARECLIPPED <> 0) and (Pmobj_t(AContext).z <=
    Psubsector_t(Pmobj_t(AContext).subsector).sector.floorheight) then
    result := '10.0'
  else
    result := '0.0';
{$ELSE}
  result := ftoa(Pmobj_t(AContext).floorclip / FRACUNIT);
{$ENDIF}
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_gravity
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_gravity(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).gravity / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_pushfactor
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_pushfactor(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).pushfactor / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_friction
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_friction(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).friction / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_scale
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_scale(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(Pmobj_t(AContext).scale / FRACUNIT);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_mass
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_mass(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).mass);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_special
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_special(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).special);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_arg1
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_arg1(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).args[0]);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_arg2
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_arg2(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).args[1]);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_arg3
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_arg3(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).args[2]);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_arg4
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_arg4(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).args[3]);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_arg5
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_arg5(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).args[4]);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_WeaveIndexXY
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_WeaveIndexXY(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).WeaveIndexXY);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_WeaveIndexZ
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_WeaveIndexZ(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).WeaveIndexZ);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_SpriteDX
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_SpriteDX(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).spriteDX);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_SpriteDY
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_SpriteDY(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).spriteDY);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_PainChance
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_PainChance(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).painchance);
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_InfightingGroup
//
// MBF21
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_InfightingGroup(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).infighting_group);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_ProjectileGroup
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_ProjectileGroup(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).projectile_group);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_SplashGroup
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_SplashGroup(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).splash_group);
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_MAPSTR
//
// Pascalscript map & world variables
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MAPSTR(AContext: Pointer; const p: TArray<string>): string;
begin
  result := PS_GetMapStr(Param(p, 0));
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_WORLDSTR
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_WORLDSTR(AContext: Pointer; const p: TArray<string>): string;
begin
  result := PS_GetWorldStr(Param(p, 0));
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MAPINT
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MAPINT(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(PS_GetMapInt(Param(p, 0)));
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_WORLDINT
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_WORLDINT(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(PS_GetWorldInt(Param(p, 0)));
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MAPFLOAT
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MAPFLOAT(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(PS_GetMapFloat(Param(p, 0)));
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_WORLDFLOAT
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_WORLDFLOAT(AContext: Pointer; const p: TArray<string>): string;
begin
  result := ftoa(PS_GetWorldFloat(Param(p, 0)));
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_CUSTOMPARAM
//
// Custom params
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_CUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string;
var
  parm: Pmobjcustomparam_t;
begin
  parm := P_GetMobjCustomParam(Pmobj_t(AContext), Param(p, 0));
  if parm <> nil then
    result := itoa(parm.value)
  else
    result := '0';
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_TARGETCUSTOMPARAM
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_TARGETCUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string;
var
  parm: Pmobjcustomparam_t;
begin
  if Pmobj_t(AContext).target <> nil then
  begin
    parm := P_GetMobjCustomParam(Pmobj_t(AContext).target, Param(p, 0));
    if parm <> nil then
    begin
      result := itoa(parm.value);
      exit;
    end;
  end;
  result := '0';
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MASTERCUSTOMPARAM
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MASTERCUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string;
var
  parm: Pmobjcustomparam_t;
begin
  if Pmobj_t(AContext).master <> nil then
  begin
    parm := P_GetMobjCustomParam(Pmobj_t(AContext).master, Param(p, 0));
    if parm <> nil then
    begin
      result := itoa(parm.value);
      exit;
    end;
  end;
  result := '0';
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_TRACERCUSTOMPARAM
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_TRACERCUSTOMPARAM(AContext: Pointer; const p: TArray<string>): string;
var
  parm: Pmobjcustomparam_t;
begin
  if Pmobj_t(AContext).tracer <> nil then
  begin
    parm := P_GetMobjCustomParam(Pmobj_t(AContext).tracer, Param(p, 0));
    if parm <> nil then
    begin
      result := itoa(parm.value);
      exit;
    end;
  end;
  result := '0';
end;

//==============================================================================
// TEngineActorExpressionFunctions.PF_SPAWN
//
// States
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_SPAWN(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.spawnstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_SEE
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_SEE(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.seestate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MELEE
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MELEE(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.meleestate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_MISSILE
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_MISSILE(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.missilestate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_PAIN
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_PAIN(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.painstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_DEATH
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_DEATH(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.deathstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_XDEATH
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_XDEATH(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.xdeathstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_HEAL
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_HEAL(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.healstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_CRASH
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_CRASH(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.crashstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_CRUSH
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_CRUSH(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.crushstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_INTERACT
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_INTERACT(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.interactstate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_RAISE
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_RAISE(AContext: Pointer; const p: TArray<string>): string;
begin
  result := itoa(Pmobj_t(AContext).info.raisestate);
end;

//==============================================================================
//
// TEngineActorExpressionFunctions.PF_EVAL
//
//==============================================================================
class function TEngineActorExpressionFunctions.PF_EVAL(AContext: Pointer; const p: TArray<string>): string;
begin
  if Length(p) = 0 then
  begin
    result := '0';
    exit;
  end;

  result := Param(p, N_Random mod Length(p));
end;

end.
