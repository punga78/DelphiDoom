{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - what the states ask of the rules and the   }
{  surface sets of the loaded mod (the part of Mod that the strategy screens    }
{  use)                                                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Rules.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.ModFiles.Intf;

type
  /// <summary>
  ///   The ruleset and the surface sets of the game. It is a second interface of the object that implements
  ///   IXcomResources (ask with Supports), so IXcomResources and its fakes do not change. The implementation owns
  ///   what it returns
  /// </summary>
  IXcomGameRules = interface
    ['{7D1C5E38-4B92-4A06-8F3D-2E90B1A7C654}']
    /// <summary>The ruleset of the mods (Game::getMod): owned by the implementation</summary>
    function Ruleset: TXcomRuleset;
    /// <summary>The virtual files of the mods</summary>
    function ModFiles: IXcomModFiles;
    /// <summary>Mod::getSurfaceSet: nil when there is no set with the name. The set is loaded the first time it is asked for</summary>
    function GetSurfaceSet(const AName: string): TXcomSurfaceSet;
  end;

  /// <summary>
  ///   The extra sprites of the rules that are one picture (singleImage: InvCopy, InvPaste...), which
  ///   Mod::getSurface gives. An optional interface of the object that implements IXcomGameRules (ask with
  ///   Supports). The implementation owns what it returns
  /// </summary>
  IXcomExtraSurfaces = interface
    ['{7D1C5E38-4B92-4A06-8F3D-2E90B1A7C655}']
    /// <summary>The picture of the name (as the rules write it), nil when the rules have no single image of that name</summary>
    function GetExtraSurface(const AName: string): TXcomSurface;
  end;

implementation

end.
