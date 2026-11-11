{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - the Ufopaedia of the game in progress   }
{  (the composition of the library)                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.Factory;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUfopaedia.Intf;

type
  /// <summary>
  ///   Assembles the catalog and the navigator on the saved game and the rules of a host. The only unit of the
  ///   library that knows where the saved game is
  /// </summary>
  TXcomUfopaediaFactory = class
  public
    /// <summary>The available articles of the game of the host; the saved game is asked at every question</summary>
    class function CreateCatalog(AHost: TXcomStateHost): IXcomUfopaediaCatalog; static;
    /// <summary>A navigator for one visit of the Ufopaedia (Open, or OpenArticle from another screen)</summary>
    class function CreateNavigator(AHost: TXcomStateHost): IXcomUfopaediaNavigator; static;
  end;

implementation

uses
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomUfopaedia.Catalog,
  DelphiDoom.XcomUfopaedia.Navigator;

{ TXcomUfopaediaFactory }

class function TXcomUfopaediaFactory.CreateCatalog(AHost: TXcomStateHost): IXcomUfopaediaCatalog;
begin
  Result := TXcomUfopaediaCatalog.Create(TXcomStrategy.Ruleset(AHost),
    function(const ARequirements: TArray<string>): Boolean
    begin
      Result := TXcomStrategy.SavedGame(AHost).IsResearched(ARequirements);
    end,
    function(const AName: string): TXcomSurfaceSet
    begin
      Result := TXcomStrategy.Rules(AHost).GetSurfaceSet(AName);
    end);
end;

class function TXcomUfopaediaFactory.CreateNavigator(AHost: TXcomStateHost): IXcomUfopaediaNavigator;
begin
  Result := TXcomUfopaediaNavigator.Create(AHost, CreateCatalog(AHost));
end;

end.
