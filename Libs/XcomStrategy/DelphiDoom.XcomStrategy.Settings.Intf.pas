{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the options that the strategic logic    }
{  reads (Options::...)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Settings.Intf;

interface

type
  /// <summary>
  ///   The options of the game that the simulation of the geoscape reads (the C++ reads them from Options). The
  ///   engine gives its options; the default is the default configuration of OpenXcom
  /// </summary>
  IXcomStrategySettings = interface
    ['{6F2B4C1D-9A3E-4B75-8D10-176000000103}']
    /// <summary>Options::aggressiveRetaliation: any UFO scans for bases, not only the retaliation ones</summary>
    function AggressiveRetaliation: Boolean;
    /// <summary>Options::storageLimitsEnforced</summary>
    function StorageLimitsEnforced: Boolean;
    /// <summary>Options::anytimePsiTraining: psionic training every day instead of the monthly one</summary>
    function AnytimePsiTraining: Boolean;
    /// <summary>Options::autosave</summary>
    function Autosave: Boolean;
  end;

implementation

end.
