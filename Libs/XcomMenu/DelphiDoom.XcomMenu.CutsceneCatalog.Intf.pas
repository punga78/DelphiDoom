{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - what the cutscenes ask of the loaded mod     }
{  (the rules of the videos and the files of the game)                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.CutsceneCatalog.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.RuleVideo;

type
  /// <summary>
  ///   Mod::getVideo and the FileMap as CutsceneState, SlideshowState and VideoState use them. The paths are the
  ///   virtual ones of the rules ("FLOP_INT/INT00.LBM"), without distinction of case
  /// </summary>
  IXcomCutsceneCatalog = interface
    ['{8C41F0A7-2D95-4B6E-A3C1-5E7F92D0B846}']
    /// <summary>The rule of the cutscene; nil when the mod has none with this id. The catalog owns it</summary>
    function FindCutscene(const AId: string): TXcomRuleVideo;
    /// <summary>CrossPlatform::fileExists(FileMap::getFilePath(path))</summary>
    function FileExists(const AVirtualPath: string): Boolean;
    function LoadBytes(const AVirtualPath: string): TBytes;
  end;

implementation

end.
