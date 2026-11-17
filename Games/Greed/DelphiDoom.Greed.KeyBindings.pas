{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the keys that the player chose                   }
{  Port of xGreed (Jim Valavanis): scanbuttons of d_ints.pas, loaded by the     }
{  bt_* settings of m_defs.pas                                                  }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.KeyBindings;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Settings.Intf,
  DelphiDoom.Greed.KeyBindings.Intf;

type
  /// <summary>
  ///   IGreedKeyBindings on the settings of the game: the scan codes of bt_north ... bt_motionmode are read once, when
  ///   the object is made (the original has no menu that changes them: only xGreed.ini does, before the game starts),
  ///   and turned into virtual keys by TGreedScanCodes
  /// </summary>
  TGreedKeyBindings = class(TInterfacedObject, IGreedKeyBindings)
  strict private
    FVirtualKeys: array[gcNorth..gcMotionMode] of Integer;
  public
    /// <summary>EArgumentNilException if ASettings is nil</summary>
    constructor Create(const ASettings: IGreedSettings);
    function IsBindable(ACommand: TGreedCommand): Boolean;
    function VirtualKeyOf(ACommand: TGreedCommand): Integer;
    /// <summary>The name in the file of the button of a bindable command (bt_north ... bt_motionmode)</summary>
    class function SettingNameOf(ACommand: TGreedCommand): string; static;
  end;

implementation

uses
  DelphiDoom.Greed.ScanCodes;

const
  SETTING_NAMES: array[gcNorth..gcMotionMode] of string = (
    'bt_north', 'bt_east', 'bt_south', 'bt_west', 'bt_fire', 'bt_straf', 'bt_use', 'bt_run', 'bt_jump',
    'bt_useitem', 'bt_asscam', 'bt_lookup', 'bt_lookdown', 'bt_centerview', 'bt_slideleft', 'bt_slideright',
    'bt_invleft', 'bt_invright', 'bt_motionmode');

{ TGreedKeyBindings }

constructor TGreedKeyBindings.Create(const ASettings: IGreedSettings);
var
  LCommand: TGreedCommand;
begin
  inherited Create;
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  for LCommand := Low(FVirtualKeys) to High(FVirtualKeys) do
    FVirtualKeys[LCommand] := TGreedScanCodes.ToVirtualKey(ASettings.GetInteger(SETTING_NAMES[LCommand]));
end;

function TGreedKeyBindings.IsBindable(ACommand: TGreedCommand): Boolean;
begin
  Result := (ACommand >= Low(FVirtualKeys)) and (ACommand <= High(FVirtualKeys));
end;

function TGreedKeyBindings.VirtualKeyOf(ACommand: TGreedCommand): Integer;
begin
  if IsBindable(ACommand) then
    Result := FVirtualKeys[ACommand]
  else
    Result := 0;
end;

class function TGreedKeyBindings.SettingNameOf(ACommand: TGreedCommand): string;
begin
  if (ACommand < Low(SETTING_NAMES)) or (ACommand > High(SETTING_NAMES)) then
    Result := ''
  else
    Result := SETTING_NAMES[ACommand];
end;

end.
