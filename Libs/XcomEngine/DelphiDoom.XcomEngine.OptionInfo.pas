{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the description of an option (OptionInfo)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.OptionInfo;

interface

type
  /// <summary>OptionType: how the value of an option is stored in options.cfg and shown in the screens</summary>
  TXcomOptionKind = (okBool, okInt, okKey, okString);

  /// <summary>
  ///   OptionInfo without the pointer to the value: the id written in options.cfg, the kind, the default, and the
  ///   language string of the description and of the category (empty for the options that no screen lists).
  ///   A key is the SDL 1.2 code of the key
  /// </summary>
  TXcomOptionInfo = record
    Id: string;
    Kind: TXcomOptionKind;
    /// <summary>The default of a bool (0 or 1), an int or a key</summary>
    DefaultValue: Integer;
    DefaultText: string;
    Description: string;
    Category: string;
  end;

implementation

end.