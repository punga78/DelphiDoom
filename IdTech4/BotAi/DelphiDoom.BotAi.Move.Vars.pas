{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMoveVars, the library variables of the movement    }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): sv_maxstep,         }
{  sv_maxbarrier, sv_gravity, weapindex_*, entitytypemissile, offhandgrapple,  }
{  cmd_grappleon and cmd_grappleoff of code\botlib\be_ai_move.c (libvar_t      }
{  pointers whose value is read each time). Based on the Quake III Arena GPL   }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Vars;

interface

uses
  DelphiDoom.BotAi.LibVars.Intf;

type
  /// <summary>
  ///   The variables that BotSetupMoveAI makes; the value is read from the table of variables each time, so a
  ///   change of a variable (LibVarSet) is seen at once, as with the pointers of the original
  /// </summary>
  TBotMoveVars = class
  strict private
    FLibVars: IBotLibVarStore;
  public
    constructor Create(const ALibVars: IBotLibVarStore);
    /// <summary>The LibVar calls of BotSetupMoveAI: the variables with their defaults</summary>
    procedure Setup;
    /// <summary>sv_maxstep (the variable sv_step)</summary>
    function MaxStep: Single;
    /// <summary>sv_maxbarrier</summary>
    function MaxBarrier: Single;
    /// <summary>sv_gravity</summary>
    function Gravity: Single;
    /// <summary>weapindex_rocketlauncher, as the int the original uses</summary>
    function WeaponIndexRocketLauncher: Integer;
    /// <summary>weapindex_bfg10k</summary>
    function WeaponIndexBfg: Integer;
    /// <summary>weapindex_grapple</summary>
    function WeaponIndexGrapple: Integer;
    /// <summary>entitytypemissile</summary>
    function EntityTypeMissile: Integer;
    /// <summary>offhandgrapple: the value (0 or not)</summary>
    function OffhandGrapple: Single;
    /// <summary>cmd_grappleon</summary>
    function GrappleOnCommand: AnsiString;
    /// <summary>cmd_grappleoff</summary>
    function GrappleOffCommand: AnsiString;
  end;

implementation

{ TBotMoveVars }

constructor TBotMoveVars.Create(const ALibVars: IBotLibVarStore);
begin
  inherited Create;
  FLibVars := ALibVars;
end;

procedure TBotMoveVars.Setup;
begin
  FLibVars.GetValueOrCreate('sv_step', '18');
  FLibVars.GetValueOrCreate('sv_maxbarrier', '32');
  FLibVars.GetValueOrCreate('sv_gravity', '800');
  FLibVars.GetValueOrCreate('weapindex_rocketlauncher', '5');
  FLibVars.GetValueOrCreate('weapindex_bfg10k', '9');
  FLibVars.GetValueOrCreate('weapindex_grapple', '10');
  FLibVars.GetValueOrCreate('entitytypemissile', '3');
  FLibVars.GetValueOrCreate('offhandgrapple', '0');
  FLibVars.GetStringOrCreate('cmd_grappleon', 'grappleon');
  FLibVars.GetStringOrCreate('cmd_grappleoff', 'grappleoff');
end;

function TBotMoveVars.MaxStep: Single;
begin
  Result := FLibVars.GetValue('sv_step');
end;

function TBotMoveVars.MaxBarrier: Single;
begin
  Result := FLibVars.GetValue('sv_maxbarrier');
end;

function TBotMoveVars.Gravity: Single;
begin
  Result := FLibVars.GetValue('sv_gravity');
end;

function TBotMoveVars.WeaponIndexRocketLauncher: Integer;
begin
  Result := Trunc(FLibVars.GetValue('weapindex_rocketlauncher'));
end;

function TBotMoveVars.WeaponIndexBfg: Integer;
begin
  Result := Trunc(FLibVars.GetValue('weapindex_bfg10k'));
end;

function TBotMoveVars.WeaponIndexGrapple: Integer;
begin
  Result := Trunc(FLibVars.GetValue('weapindex_grapple'));
end;

function TBotMoveVars.EntityTypeMissile: Integer;
begin
  Result := Trunc(FLibVars.GetValue('entitytypemissile'));
end;

function TBotMoveVars.OffhandGrapple: Single;
begin
  Result := FLibVars.GetValue('offhandgrapple');
end;

function TBotMoveVars.GrappleOnCommand: AnsiString;
begin
  Result := FLibVars.GetString('cmd_grappleon');
end;

function TBotMoveVars.GrappleOffCommand: AnsiString;
begin
  Result := FLibVars.GetString('cmd_grappleoff');
end;

end.
