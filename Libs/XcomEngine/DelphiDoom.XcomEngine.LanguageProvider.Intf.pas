{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the languages that can be chosen           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.LanguageProvider.Intf;

interface

uses
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Resources.Intf;

type
  /// <summary>Language::getList and the loading of a language (Game::loadLanguages)</summary>
  IXcomLanguageProvider = interface
    ['{6B91E0D3-A247-4C58-BF16-D5307A8E92C4}']
    /// <summary>The ids of the languages that have a file (en-US, it...), sorted like the files; AName is how the menu shows them</summary>
    procedure List(out ACodes, ANames: TArray<string>);
    /// <summary>
    ///   The strings of a language: the common file and the one of the mod, over en-US, and the extra strings of the
    ///   rulesets (AResources may be nil: no extra strings). The caller owns the result
    /// </summary>
    function Load(const ALanguageId: string; AWordwrap: TXcomTextWrapping;
      const AResources: IXcomResources): TXcomLanguage;
  end;

implementation

end.
