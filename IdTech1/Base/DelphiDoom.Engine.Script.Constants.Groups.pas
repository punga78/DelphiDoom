{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the groups of the mobjs, for scripts                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Constants.Groups;

interface

uses
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>The infighting, projectile and splash groups and the flags of the weapons of MBF21, as constants of the scripts</summary>
  TEngineScriptGroupConstants = class(TInterfacedObject, IScriptConstantProvider)
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

{ TEngineScriptGroupConstants }

procedure TEngineScriptGroupConstants.Describe(const ATable: IScriptConstantTable);
var
  I: Integer;
begin
  // MBF21 groups
  // infighting groups
  ATable.AddInteger('IG_INVALID', IG_INVALID);
  for I := 0 to infighting_groups.Count - 1 do
    ATable.AddInteger(infighting_groups.Strings[I], I);
  ATable.AddInteger('IG_END', IG_END);

  // projectile groups
  ATable.AddInteger('PG_INVALID', PG_INVALID);
  ATable.AddInteger('PG_GROUPLESS', PG_GROUPLESS);
  for I := 0 to projectile_groups.Count - 1 do
    ATable.AddInteger(projectile_groups.Strings[I], I);
  ATable.AddInteger('PG_END', PG_END);

  // Splash groups
  ATable.AddInteger('SG_INVALID', SG_INVALID);
  for I := 0 to splash_groups.Count - 1 do
    ATable.AddInteger(splash_groups.Strings[I], I);
  ATable.AddInteger('SG_END', SG_END);

  // MBF21 Weapon Flags
  ATable.AddInteger('WPF_NOFLAG', WPF_NOFLAG);
  ATable.AddInteger('WPF_NOTHRUST', WPF_NOTHRUST);
  ATable.AddInteger('WPF_SILENT', WPF_SILENT);
  ATable.AddInteger('WPF_NOAUTOFIRE', WPF_NOAUTOFIRE);
  ATable.AddInteger('WPF_FLEEMELEE', WPF_FLEEMELEE);
  ATable.AddInteger('WPF_AUTOSWITCHFROM', WPF_AUTOSWITCHFROM);
  ATable.AddInteger('WPF_NOAUTOSWITCHTO', WPF_NOAUTOSWITCHTO);
end;

end.
