{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - the moves between the screens of the    }
{  Ufopaedia (Ufopaedia::open, openArticle, next, prev, createArticleState)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.Navigator;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>
  ///   Creates the screens of the Ufopaedia and gives them to the game; it keeps the index of the article on the
  ///   screen among the available ones (the static _current_index of the C++), so the screens of one visit share
  ///   one navigator. The host is not owned and must outlive the navigator
  /// </summary>
  TXcomUfopaediaNavigator = class(TInterfacedObject, IXcomUfopaediaNavigator)
  strict private
    FHost: TXcomStateHost;
    FCatalog: IXcomUfopaediaCatalog;
    FCurrentIndex: Integer;
    function CreateArticleState(AArticle: TXcomArticleDefinition): TXcomArticleState;
    procedure Replace(AIndex: Integer; const AArticles: TArray<TXcomArticleDefinition>);
  public
    constructor Create(AHost: TXcomStateHost; const ACatalog: IXcomUfopaediaCatalog);
    /// <summary>Ufopaedia::createArticleState: the class of the state of a kind of article (nil: no class)</summary>
    class function StateClassOf(AKind: Integer): TXcomArticleStateClass; static;
    procedure Open;
    procedure OpenSection(const ASection: string);
    procedure OpenArticle(const AArticleId: string); overload;
    procedure OpenArticle(AArticle: TXcomArticleDefinition); overload;
    procedure Next;
    procedure Prev;
    /// <summary>The index of the last article opened among the available ones (-1: the last one asked was not available)</summary>
    property CurrentIndex: Integer read FCurrentIndex;
  end;

implementation

uses
  DelphiDoom.XcomUfopaedia.Catalog, DelphiDoom.XcomUfopaedia.StartState, DelphiDoom.XcomUfopaedia.SelectState,
  DelphiDoom.XcomUfopaedia.ArticleStateText, DelphiDoom.XcomUfopaedia.ArticleStateTextImage,
  DelphiDoom.XcomUfopaedia.ArticleStateArmor, DelphiDoom.XcomUfopaedia.ArticleStateBaseFacility,
  DelphiDoom.XcomUfopaedia.ArticleStateCraft, DelphiDoom.XcomUfopaedia.ArticleStateCraftWeapon,
  DelphiDoom.XcomUfopaedia.ArticleStateItem, DelphiDoom.XcomUfopaedia.ArticleStateUfo,
  DelphiDoom.XcomUfopaedia.ArticleStateVehicle, DelphiDoom.XcomUfopaedia.ArticleStateTftd,
  DelphiDoom.XcomUfopaedia.ArticleStateTftdArmor, DelphiDoom.XcomUfopaedia.ArticleStateTftdCraft,
  DelphiDoom.XcomUfopaedia.ArticleStateTftdCraftWeapon, DelphiDoom.XcomUfopaedia.ArticleStateTftdFacility,
  DelphiDoom.XcomUfopaedia.ArticleStateTftdItem, DelphiDoom.XcomUfopaedia.ArticleStateTftdUso,
  DelphiDoom.XcomUfopaedia.ArticleStateTftdVehicle;

const
  // UfopaediaTypeId: the TFTD kinds between the plain article (10) and the alien submarine (17)
  UFOPAEDIA_TYPE_TFTD_CRAFT = 11;
  UFOPAEDIA_TYPE_TFTD_CRAFT_WEAPON = 12;
  UFOPAEDIA_TYPE_TFTD_VEHICLE = 13;
  UFOPAEDIA_TYPE_TFTD_ITEM = 14;
  UFOPAEDIA_TYPE_TFTD_ARMOR = 15;
  UFOPAEDIA_TYPE_TFTD_BASE_FACILITY = 16;

{ TXcomUfopaediaNavigator }

constructor TXcomUfopaediaNavigator.Create(AHost: TXcomStateHost; const ACatalog: IXcomUfopaediaCatalog);
begin
  inherited Create;
  FHost := AHost;
  FCatalog := ACatalog;
end;

class function TXcomUfopaediaNavigator.StateClassOf(AKind: Integer): TXcomArticleStateClass;
begin
  case AKind of
    TXcomArticleDefinition.UFOPAEDIA_TYPE_CRAFT:
      Result := TXcomArticleStateCraft;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_CRAFT_WEAPON:
      Result := TXcomArticleStateCraftWeapon;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_VEHICLE:
      Result := TXcomArticleStateVehicle;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_ITEM:
      Result := TXcomArticleStateItem;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_ARMOR:
      Result := TXcomArticleStateArmor;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_BASE_FACILITY:
      Result := TXcomArticleStateBaseFacility;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_TEXT:
      Result := TXcomArticleStateText;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_TEXTIMAGE:
      Result := TXcomArticleStateTextImage;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_UFO:
      Result := TXcomArticleStateUfo;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_TFTD:
      Result := TXcomArticleStateTftd;
    UFOPAEDIA_TYPE_TFTD_CRAFT:
      Result := TXcomArticleStateTftdCraft;
    UFOPAEDIA_TYPE_TFTD_CRAFT_WEAPON:
      Result := TXcomArticleStateTftdCraftWeapon;
    UFOPAEDIA_TYPE_TFTD_VEHICLE:
      Result := TXcomArticleStateTftdVehicle;
    UFOPAEDIA_TYPE_TFTD_ITEM:
      Result := TXcomArticleStateTftdItem;
    UFOPAEDIA_TYPE_TFTD_ARMOR:
      Result := TXcomArticleStateTftdArmor;
    UFOPAEDIA_TYPE_TFTD_BASE_FACILITY:
      Result := TXcomArticleStateTftdFacility;
    TXcomArticleDefinition.UFOPAEDIA_TYPE_TFTD_USO:
      Result := TXcomArticleStateTftdUso;
  else
    Result := nil;
  end;
end;

function TXcomUfopaediaNavigator.CreateArticleState(AArticle: TXcomArticleDefinition): TXcomArticleState;
var
  LClass: TXcomArticleStateClass;
begin
  LClass := StateClassOf(AArticle.Kind);
  // the C++ pushes a null state for an unknown kind; the rules refuse those kinds when they load
  if not Assigned(LClass) then
    Exit(nil);
  Result := LClass.Create(FHost, Self, FCatalog, AArticle);
end;

procedure TXcomUfopaediaNavigator.Open;
begin
  FHost.PushState(TXcomUfopaediaStartState.Create(FHost, Self, FCatalog.Sections));
end;

procedure TXcomUfopaediaNavigator.OpenSection(const ASection: string);
begin
  FHost.PushState(TXcomUfopaediaSelectState.Create(FHost, Self, FCatalog.List(ASection)));
end;

procedure TXcomUfopaediaNavigator.OpenArticle(AArticle: TXcomArticleDefinition);
var
  LId: string;
  LState: TXcomArticleState;
begin
  LId := AArticle.Id;
  FCurrentIndex := FCatalog.ArticleIndex(LId);
  if FCurrentIndex = -1 then
    Exit;
  LState := CreateArticleState(AArticle);
  if Assigned(LState) then
    FHost.PushState(LState);
end;

procedure TXcomUfopaediaNavigator.OpenArticle(const AArticleId: string);
var
  LId: string;
  LState: TXcomArticleState;
begin
  LId := AArticleId;
  FCurrentIndex := FCatalog.ArticleIndex(LId);
  if FCurrentIndex = -1 then
    Exit;
  LState := CreateArticleState(FCatalog.Rules.Articles.Find(LId));
  if Assigned(LState) then
    FHost.PushState(LState);
end;

procedure TXcomUfopaediaNavigator.Replace(AIndex: Integer; const AArticles: TArray<TXcomArticleDefinition>);
var
  LState: TXcomArticleState;
begin
  FCurrentIndex := AIndex;
  // the new article is made before the old one leaves: an article that cannot be made leaves the screen as it is
  LState := CreateArticleState(AArticles[FCurrentIndex]);
  FHost.PopState;
  if Assigned(LState) then
    FHost.PushState(LState);
end;

procedure TXcomUfopaediaNavigator.Next;
var
  LArticles: TArray<TXcomArticleDefinition>;
begin
  LArticles := FCatalog.AvailableArticles;
  Replace(TXcomUfopaediaCatalog.NextIndex(FCurrentIndex, Length(LArticles)), LArticles);
end;

procedure TXcomUfopaediaNavigator.Prev;
var
  LArticles: TArray<TXcomArticleDefinition>;
begin
  LArticles := FCatalog.AvailableArticles;
  Replace(TXcomUfopaediaCatalog.PreviousIndex(FCurrentIndex, Length(LArticles)), LArticles);
end;

end.
