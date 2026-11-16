{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the constants of the world, for scripts                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Constants.World;

interface

uses
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>The invalid values of the numbers, the units of the position and the angles, as constants of the scripts</summary>
  TEngineScriptWorldConstants = class(TInterfacedObject, IScriptConstantProvider)
  public
    procedure Describe(const ATable: IScriptConstantTable);
  end;

implementation

uses
  d_delphi,
  deh_main,
  doomdef,
{$IFDEF DOOM_OR_STRIFE}
  d_items,
{$ENDIF}
  info_h,
  info_common,
  p_gender,
  p_local,
  r_renderstyle,
  sc_states,
  tables,
  m_fixed,
  p_mobj_h,
  psi_game,
  TypInfo;

{ TEngineScriptWorldConstants }

procedure TEngineScriptWorldConstants.Describe(const ATable: IScriptConstantTable);
begin
  // consts p_local
  ATable.AddInteger('ONFLOORZ', ONFLOORZ);
  ATable.AddInteger('FLOORZ', ONFLOORZ);
  ATable.AddInteger('ONCEILINGZ', ONCEILINGZ);
  ATable.AddInteger('CEILINGZ', ONCEILINGZ);
  ATable.AddInteger('ONFLOATZ', {$IFDEF HEXEN}FLOATRANDZ{$ELSE}ONFLOATZ{$ENDIF});
  ATable.AddInteger('FLOATZ', {$IFDEF HEXEN}FLOATRANDZ{$ELSE}ONFLOATZ{$ENDIF});
{$IFDEF HEXEN}
  ATable.AddInteger('FLOATRANDZ', FLOATRANDZ);
{$ENDIF}
  ATable.AddInteger('TICRATE', TICRATE);
  ATable.AddInteger('FRACUNIT', FRACUNIT);
  ATable.AddInteger('ACTOR_INVALID', ACTOR_INVALID);
  ATable.AddInteger('PLAYER_INVALID', PLAYER_INVALID);
  ATable.AddInteger('MOBJTYPE_INVALID', MOBJTYPE_INVALID);
  ATable.AddInteger('STATE_INVALID', STATE_INVALID);
  ATable.AddInteger('EDITORNUMBER_INVALID', EDITORNUMBER_INVALID);
  ATable.AddInteger('EDITORNUMBER_UNKNOWN', EDITORNUMBER_UNKNOWN);
  ATable.AddInteger('TEXTURE_INVALID', TEXTURE_INVALID);
  ATable.AddInteger('FLAT_INVALID', FLAT_INVALID);
  ATable.AddInteger('SECTOR_INVALID', SECTOR_INVALID);
  ATable.AddInteger('LINE_INVALID', LINE_INVALID);
  ATable.AddInteger('SIDE_INVALID', SIDE_INVALID);
  ATable.AddInteger('VERTEX_INVALID', VERTEX_INVALID);
  ATable.AddInteger('LIGHTLEVEL_INVALID', LIGHTLEVEL_INVALID);

  // consts tables
  ATable.AddExtended('D_PI', D_PI);
  ATable.AddExtended('ANGLE_T_TO_RAD', ANGLE_T_TO_RAD);
  ATable.AddLongWord('ANGLETOFINESHIFT', ANGLETOFINESHIFT);
  ATable.AddLongWord('ANGLETOFINEUNIT', ANGLETOFINEUNIT);
  ATable.AddLongWord('FINEANGLES', FINEANGLES);
  ATable.AddLongWord('FINEMASK', FINEMASK);
  ATable.AddLongWord('DIR256ANGLES', DIR256ANGLES);
  ATable.AddLongWord('DIR256TOANGLEUNIT', DIR256TOANGLEUNIT);
  ATable.AddLongWord('DIR256TOANGLESHIFT', DIR256TOANGLESHIFT);
  ATable.AddLongWord('ANG1', ANG1);
{    for i := 2 to 4 do
    ATable.AddLongWord('ANG' + itoa(i), ANG1 * i);}
  ATable.AddLongWord('ANG5', ANG5);
  ATable.AddLongWord('ANG30', ANG60 div 2);
  ATable.AddLongWord('ANG45', ANG45);
  ATable.AddLongWord('ANG60', ANG60);
  ATable.AddLongWord('ANG90', ANG90);
  ATable.AddLongWord('ANG120', ANG120);
  ATable.AddLongWord('ANG180', ANG180);
  ATable.AddLongWord('ANG240', ANG240);
  ATable.AddLongWord('ANG270', ANG270);
  ATable.AddLongWord('ANG300', ANG300);
  ATable.AddLongWord('ANG315', ANG315);
  ATable.AddLongWord('ANG355', ANG355);
  ATable.AddLongWord('ANGLE_MAX', ANGLE_MAX);
  ATable.AddLongWord('SLOPEBITS', SLOPEBITS);
  ATable.AddLongWord('SLOPERANGE', SLOPERANGE);
  ATable.AddLongWord('DBITS', DBITS);
  ATable.AddLongWord('DRANGE', DRANGE);
end;

end.
