{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - the available articles (the logic of    }
{  Ufopaedia.cpp of OpenXcom that does not touch the screens)                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.Catalog;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.Intf;

type
  /// <summary>
  ///   The articles of the rules filtered by the research of the saved game. The rules are not owned; the research
  ///   is asked every time (the list changes while the game goes on)
  /// </summary>
  TXcomUfopaediaCatalog = class(TInterfacedObject, IXcomUfopaediaCatalog)
  strict private
    FRules: TXcomRuleset;
    FResearched: TXcomResearchedCheck;
    FSprites: TXcomSpriteSource;
  public
    /// <param name="ARules">The rules (not owned)</param>
    /// <param name="AResearched">SavedGame::isResearched of a list of topics</param>
    /// <param name="ASprites">Mod::getSurfaceSet (nil: no set of sprites)</param>
    constructor Create(ARules: TXcomRuleset; const AResearched: TXcomResearchedCheck;
      const ASprites: TXcomSpriteSource = nil);
    function Rules: TXcomRuleset;
    function Sprites(const AName: string): TXcomSurfaceSet;
    function Sections: TArray<string>;
    function IsArticleAvailable(AArticle: TXcomArticleDefinition): Boolean;
    function AvailableArticles: TArray<TXcomArticleDefinition>;
    function List(const ASection: string): TArray<TXcomArticleDefinition>;
    function ArticleIndex(var AArticleId: string): Integer;
    /// <summary>Ufopaedia::next: the index after ACurrent among ACount articles, the first after the last</summary>
    class function NextIndex(ACurrent, ACount: Integer): Integer; static;
    /// <summary>Ufopaedia::prev: the index before ACurrent among ACount articles, the last before the first</summary>
    class function PreviousIndex(ACurrent, ACount: Integer): Integer; static;
  end;

implementation

uses
  System.Generics.Collections;

{ TXcomUfopaediaCatalog }

constructor TXcomUfopaediaCatalog.Create(ARules: TXcomRuleset; const AResearched: TXcomResearchedCheck;
  const ASprites: TXcomSpriteSource);
begin
  inherited Create;
  FRules := ARules;
  FResearched := AResearched;
  FSprites := ASprites;
end;

function TXcomUfopaediaCatalog.Rules: TXcomRuleset;
begin
  Result := FRules;
end;

function TXcomUfopaediaCatalog.Sprites(const AName: string): TXcomSurfaceSet;
begin
  Result := nil;
  if Assigned(FSprites) then
    Result := FSprites(AName);
end;

function TXcomUfopaediaCatalog.Sections: TArray<string>;
begin
  Result := FRules.ArticleSectionIndex.ToArray;
end;

function TXcomUfopaediaCatalog.IsArticleAvailable(AArticle: TXcomArticleDefinition): Boolean;
begin
  Result := FResearched(AArticle.Requirements);
end;

function TXcomUfopaediaCatalog.AvailableArticles: TArray<TXcomArticleDefinition>;
var
  LList: TList<TXcomArticleDefinition>;
  LName: string;
  LArticle: TXcomArticleDefinition;
begin
  LList := TList<TXcomArticleDefinition>.Create;
  try
    for LName in FRules.Articles.Index do
    begin
      LArticle := FRules.Articles.Find(LName);
      if IsArticleAvailable(LArticle) and (LArticle.Section <> UFOPAEDIA_NOT_AVAILABLE) then
        LList.Add(LArticle);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TXcomUfopaediaCatalog.List(const ASection: string): TArray<TXcomArticleDefinition>;
var
  LList: TList<TXcomArticleDefinition>;
  LArticle: TXcomArticleDefinition;
begin
  LList := TList<TXcomArticleDefinition>.Create;
  try
    for LArticle in AvailableArticles do
      if LArticle.Section = ASection then
        LList.Add(LArticle);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TXcomUfopaediaCatalog.ArticleIndex(var AArticleId: string): Integer;
var
  LArticles: TArray<TXcomArticleDefinition>;
  LUpperCaseId: string;
  LIndex: Integer;
  LRequirement: string;
begin
  LUpperCaseId := AArticleId + '_UC';
  LArticles := AvailableArticles;
  for LIndex := 0 to High(LArticles) do
    if LArticles[LIndex].Id = AArticleId then
      Exit(LIndex);
  for LIndex := 0 to High(LArticles) do
    if LArticles[LIndex].Id = LUpperCaseId then
    begin
      AArticleId := LUpperCaseId;
      Exit(LIndex);
    end;
  for LIndex := 0 to High(LArticles) do
    for LRequirement in LArticles[LIndex].Requirements do
      if AArticleId = LRequirement then
      begin
        AArticleId := LArticles[LIndex].Id;
        Exit(LIndex);
      end;
  Result := -1;
end;

class function TXcomUfopaediaCatalog.NextIndex(ACurrent, ACount: Integer): Integer;
begin
  // the C++ compares size_t values: with no article it walks out of the list
  if ACount <= 0 then
    raise EXcomUfopaediaException.Create(SXcomUfopaediaNoArticles);
  if ACurrent >= ACount - 1 then
    Result := 0
  else
    Result := ACurrent + 1;
end;

class function TXcomUfopaediaCatalog.PreviousIndex(ACurrent, ACount: Integer): Integer;
begin
  if ACount <= 0 then
    raise EXcomUfopaediaException.Create(SXcomUfopaediaNoArticles);
  if ACurrent <= 0 then
    Result := ACount - 1
  else
    Result := ACurrent - 1;
end;

end.
