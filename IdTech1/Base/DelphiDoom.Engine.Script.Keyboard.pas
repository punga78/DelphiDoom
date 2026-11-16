{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the keyboard that the functions of scripts read        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Keyboard;

interface

uses
  DelphiDoom.GameState.Intf,
  DelphiDoom.ScriptHost.Game.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   The keys, mouse buttons and joystick buttons of g_game, for the keyboard functions of the
  ///   scripts. The only class that reads these globals (they were in psi_game.pas). The keys that
  ///   a game does not have are not in the table of the scripts, so they are never asked for
  /// </summary>
  TEngineScriptKeyboard = class(TInterfacedObject, IScriptKeyboardSource)
  strict private
    FContext: IGameContext;
    // the variable of every action: nil if the game does not have it
    FKeys: array[TScriptKey] of PInteger;
  public
    /// <exception cref="EArgumentNilException">If the context is nil</exception>
    constructor Create(const AContext: IGameContext);
    function IsInputBlocked: Boolean;
    function KeyValue(const AKey: TScriptKey): Integer;
    function KeyCount: Integer;
    function JoyButtonCount: Integer;
    function IsKeyDown(const AIndex: Integer): Boolean;
    function IsMouseButtonDown(const AIndex: Integer): Boolean;
    function IsJoyButtonDown(const AIndex: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils,
  d_event,
  g_game;

{ TEngineScriptKeyboard }

constructor TEngineScriptKeyboard.Create(const AContext: IGameContext);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  FContext := AContext;
  FKeys[skRight] := @key_right;
  FKeys[skLeft] := @key_left;
  FKeys[skUp] := @key_up;
  FKeys[skDown] := @key_down;
  FKeys[skLookUp] := @key_lookup;
  FKeys[skLookDown] := @key_lookdown;
  FKeys[skLookCenter] := @key_lookcenter;
  FKeys[skLookRight] := @key_lookright;
  FKeys[skLookLeft] := @key_lookleft;
{$IFNDEF STRIFE}
  FKeys[skLookForward] := @key_lookforward;
{$ENDIF}
  FKeys[skStrafeLeft] := @key_strafeleft;
  FKeys[skStrafeRight] := @key_straferight;
  FKeys[skFire] := @key_fire;
  FKeys[skUse] := @key_use;
  FKeys[skStrafe] := @key_strafe;
  FKeys[skSpeed] := @key_speed;
  FKeys[skJump] := @key_jump;
  FKeys[skCrouch] := @key_crouch;
  FKeys[skWeapon0] := @key_weapon0;
  FKeys[skWeapon1] := @key_weapon1;
  FKeys[skWeapon2] := @key_weapon2;
  FKeys[skWeapon3] := @key_weapon3;
{$IFNDEF HEXEN}
  FKeys[skWeapon4] := @key_weapon4;
  FKeys[skWeapon5] := @key_weapon5;
  FKeys[skWeapon6] := @key_weapon6;
  FKeys[skWeapon7] := @key_weapon7;
{$ENDIF}
{$IFDEF HERETIC_OR_HEXEN}
  FKeys[skFlyUp] := @key_flyup;
  FKeys[skFlyDown] := @key_flydown;
  FKeys[skFlyCenter] := @key_flycenter;
  FKeys[skInvLeft] := @key_invleft;
  FKeys[skInvRight] := @key_invright;
  FKeys[skUseArtifact] := @key_useartifact;
{$ENDIF}
{$IFDEF STRIFE}
  FKeys[skInvLeft] := @key_invleft;
  FKeys[skInvRight] := @key_invright;
  FKeys[skWeapon8] := @key_weapon8;
  FKeys[skWeapon9] := @key_weapon9;
  FKeys[skUseHealth] := @key_usehealth;
  FKeys[skInvQuery] := @key_invquery;
  FKeys[skMission] := @key_mission;
  FKeys[skInvPop] := @key_invpop;
  FKeys[skInvKey] := @key_invkey;
  FKeys[skInvHome] := @key_invhome;
  FKeys[skInvEnd] := @key_invend;
  FKeys[skInvUse] := @key_invuse;
  FKeys[skInvDrop] := @key_invdrop;
{$ENDIF}
  FKeys[skMouseFire] := @mousebfire;
  FKeys[skMouseStrafe] := @mousebstrafe;
  FKeys[skMouseForward] := @mousebforward;
  FKeys[skJoyFire] := @joybfire;
  FKeys[skJoyStrafe] := @joybstrafe;
  FKeys[skJoyUse] := @joybuse;
  FKeys[skJoySpeed] := @joybspeed;
  FKeys[skJoyJump] := @joybjump;
  FKeys[skJoyCrouch] := @joybcrouch;
  FKeys[skJoyLeft] := @joyblleft;
  FKeys[skJoyRight] := @joyblright;
end;

function TEngineScriptKeyboard.IsInputBlocked: Boolean;
begin
  Result := FContext.IsDemoPlayback or FContext.IsDemoRecording or FContext.IsNetGame;
end;

function TEngineScriptKeyboard.KeyValue(const AKey: TScriptKey): Integer;
begin
  if Assigned(FKeys[AKey]) then
    Result := FKeys[AKey]^
  else
    Result := 0;
end;

function TEngineScriptKeyboard.KeyCount: Integer;
begin
  Result := NUMKEYS;
end;

function TEngineScriptKeyboard.JoyButtonCount: Integer;
begin
  Result := NUMJOYBUTTONS;
end;

function TEngineScriptKeyboard.IsKeyDown(const AIndex: Integer): Boolean;
begin
  Result := gamekeydown[AIndex];
end;

function TEngineScriptKeyboard.IsMouseButtonDown(const AIndex: Integer): Boolean;
begin
  Result := mousebuttons[AIndex];
end;

function TEngineScriptKeyboard.IsJoyButtonDown(const AIndex: Integer): Boolean;
begin
  Result := joybuttons[AIndex];
end;

end.
