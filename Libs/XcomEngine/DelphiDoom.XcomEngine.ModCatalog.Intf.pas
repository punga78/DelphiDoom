{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the mods that are installed (the           }
{  scanning of Options::refreshMods and the ModInfo of each mod)                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ModCatalog.Intf;

interface

uses
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.ModInfo;

type
  /// <summary>The mods of the data folders and what the options say about them</summary>
  IXcomModCatalog = interface
    ['{C71E5A38-0D94-4F62-B3A1-86E9D04C7B25}']
    /// <summary>
    ///   Options::refreshMods: scans the mods, drops from the list those that are gone, adds the new ones (the masters
    ///   in front, the others at the end, in order of id, not active) and makes sure that exactly one master is
    ///   active. EXcomEngineException when there is no master (no game installed)
    /// </summary>
    procedure Refresh(var AMods: TArray<TXcomModSetting>);
    /// <summary>Options::getModInfo: the description of a mod of the last scan; owned by the catalog</summary>
    function TryGetInfo(const AId: string; out AInfo: TXcomModInfo): Boolean;
    /// <summary>Options::getActiveMaster: the master that is active after the last Refresh</summary>
    function ActiveMaster: string;
  end;

implementation

end.
