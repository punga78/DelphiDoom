{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - where the options are kept (options.cfg)  }
{  Derived from OpenXcom (the OpenXcom Developers), available under the GNU    }
{  General Public License, version 3 or (at your option) any later version;    }
{  see Games\XcomFormats\README.md for the license of this unit                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.OptionsStore.Intf;

interface

uses
  DelphiDoom.XcomEngine.Options;

type
  /// <summary>Options::load and Options::save: reads the options from where they are kept and writes them back</summary>
  IXcomOptionsStore = interface
    ['{C8E2A476-5D19-4F03-86B7-1A9E3D40F5B2}']
    /// <summary>Options::load: the options the file has replace the ones of the instance (a missing file changes nothing)</summary>
    procedure Load(AOptions: TXcomOptions; const AReason: string = '');
    /// <summary>Options::save</summary>
    procedure Save(AOptions: TXcomOptions; const AReason: string = '');
  end;

implementation

end.
