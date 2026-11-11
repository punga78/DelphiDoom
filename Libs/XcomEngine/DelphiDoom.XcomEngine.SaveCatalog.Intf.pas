{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the saved games of the user (SavedGame::getList))
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomEngine.SaveCatalog.Intf;

interface

uses
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.SaveInfo;

type
  /// <summary>
  ///   The saved games in the save folder of the user: the list with the brief info of each, the order of the names
  ///   and the deleting of a file. The states of the menus only know this interface
  /// </summary>
  IXcomSaveCatalog = interface
    ['{2D7B5E91-4C36-4A08-B1F4-9E6A3C0D7F15}']
    /// <summary>SavedGame::getList: the saves of the active master mod (also the autosaves and the quick save when asked)</summary>
    function List(ALanguage: TXcomLanguage; AAutoQuick: Boolean): TArray<TXcomSaveInfo>;
    /// <summary>CrossPlatform::deleteFile on a save of the folder; False if it could not be deleted</summary>
    function DeleteSave(const AFileName: string): Boolean;
    /// <summary>Unicode::naturalCompare: A comes before B (numbers inside the names count as numbers)</summary>
    function NameBefore(const AFirst, ASecond: string): Boolean;
  end;

implementation

end.