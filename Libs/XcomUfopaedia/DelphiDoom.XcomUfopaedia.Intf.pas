{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - what a screen of the Ufopaedia asks     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.Intf;

interface

uses
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.ArticleDefinition;

type
  /// <summary>
  ///   The articles that the player can read now (the static functions of Ufopaedia that only look at the saved
  ///   game and at the rules). No method changes the state
  /// </summary>
  IXcomUfopaediaCatalog = interface
    ['{6B1E3C52-4D0A-4E7B-9A31-5C2F8E7D1A40}']
    /// <summary>The rules that the articles describe (not owned)</summary>
    function Rules: TXcomRuleset;
    /// <summary>Mod::getSurfaceSet: nil when the program does not have the set</summary>
    function Sprites(const AName: string): TXcomSurfaceSet;
    /// <summary>Mod::getUfopaediaCategoryList: the sections in the order of the buttons</summary>
    function Sections: TArray<string>;
    /// <summary>Ufopaedia::isArticleAvailable: the research that the article requires is done</summary>
    function IsArticleAvailable(AArticle: TXcomArticleDefinition): Boolean;
    /// <summary>Ufopaedia::getAvailableArticles: the available articles that have a section, in the order of the rules</summary>
    function AvailableArticles: TArray<TXcomArticleDefinition>;
    /// <summary>Ufopaedia::list: the available articles of a section</summary>
    function List(const ASection: string): TArray<TXcomArticleDefinition>;
    /// <summary>
    ///   Ufopaedia::getArticleIndex: the index of an article among the available ones, or -1. The article is looked
    ///   for by its id, then by its id with _UC, then by the research it requires: AArticleId becomes the id found
    /// </summary>
    function ArticleIndex(var AArticleId: string): Integer;
  end;

  /// <summary>
  ///   The moves between the screens of the Ufopaedia (Ufopaedia::open, openArticle, next, prev): the object creates
  ///   the state of each article and gives it to the game
  /// </summary>
  IXcomUfopaediaNavigator = interface
    ['{0F4C9D17-8A25-4B6E-B3D9-71E6A2C5F083}']
    /// <summary>Ufopaedia::open: the screen with the buttons of the sections</summary>
    procedure Open;
    /// <summary>The list of the articles of a section (UfopaediaSelectState)</summary>
    procedure OpenSection(const ASection: string);
    /// <summary>Ufopaedia::openArticle(id): opens the article if it is available; otherwise nothing</summary>
    procedure OpenArticle(const AArticleId: string); overload;
    /// <summary>Ufopaedia::openArticle(definition)</summary>
    procedure OpenArticle(AArticle: TXcomArticleDefinition); overload;
    /// <summary>Ufopaedia::next: replaces the article on the screen with the next available one (the first after the last)</summary>
    procedure Next;
    /// <summary>Ufopaedia::prev: replaces the article on the screen with the previous available one</summary>
    procedure Prev;
  end;

implementation

end.
