{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the small interfaces                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Random;

type
  /// <summary>
  ///   What the model reads from the globals of the C++ (the RNG, Options::alienBleeding and the static
  ///   Mod::FIRE_DAMAGE_RANGE): one small object that tiles and units receive from their creator
  /// </summary>
  IXcomBattleContext = interface
    ['{7B1D4E52-3C90-4F68-A2B7-5E6D0C19F834}']
    function Random: IXcomRandom;
    /// <summary>Options::alienBleeding</summary>
    function AlienBleeding: Boolean;
    /// <summary>Options::allowPsionicCapture</summary>
    function AllowPsionicCapture: Boolean;
    /// <summary>Mod::FIRE_DAMAGE_RANGE[AIndex]</summary>
    function FireDamageRange(AIndex: Integer): Integer;
  end;

  /// <summary>The part of AIModule that the saved game needs (AIModule is not ported yet)</summary>
  IXcomUnitAI = interface
    ['{2F8A9C14-6D37-4B05-91E3-A04C7B5D2E68}']
    function Save: IYamlNode;
    procedure Reset;
    procedure FreePatrolTarget;
  end;

implementation

end.
