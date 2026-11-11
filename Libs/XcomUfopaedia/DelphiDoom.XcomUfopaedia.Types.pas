{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - shared types                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.Types;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.SurfaceSet;

const
  /// <summary>
  ///   UFOPAEDIA_NOT_AVAILABLE: the section of the articles that must be released but have no entry of their own in
  ///   a list (the ammunition)
  /// </summary>
  UFOPAEDIA_NOT_AVAILABLE = 'STR_NOT_AVAILABLE';

type
  /// <summary>An article cannot be shown (no available article, a rule that the article needs is missing)</summary>
  EXcomUfopaediaException = class(Exception);

  /// <summary>SavedGame::isResearched(list): whether every topic of the list is discovered</summary>
  TXcomResearchedCheck = reference to function(const ARequirements: TArray<string>): Boolean;

  /// <summary>Mod::getSurfaceSet: the set of sprites with a name, or nil when the program does not have it</summary>
  TXcomSpriteSource = reference to function(const AName: string): TXcomSurfaceSet;

  /// <summary>
  ///   A row of a list of statistics of an article: the id of the label, and the value as it is shown (or the id
  ///   of its text when ValueIsId). A blank row separates the groups
  /// </summary>
  TXcomArticleRow = record
    LabelId: string;
    Value: string;
    ValueIsId: Boolean;
    Blank: Boolean;
    class function Make(const ALabelId, AValue: string; AValueIsId: Boolean = False): TXcomArticleRow; static;
    class function MakeBlank: TXcomArticleRow; static;
  end;

  /// <summary>A row of the table of the shots of a firearm: kind of shot, accuracy and cost in time units</summary>
  TXcomArticleShot = record
    LabelId: string;
    Accuracy: string;
    Cost: string;
  end;

resourcestring
  SXcomUfopaediaNoArticles = 'The Ufopaedia has no available article';
  SXcomUfopaediaNoRule = 'The Ufopaedia article %s needs the rule %s that does not exist';

implementation

class function TXcomArticleRow.Make(const ALabelId, AValue: string; AValueIsId: Boolean): TXcomArticleRow;
begin
  Result.LabelId := ALabelId;
  Result.Value := AValue;
  Result.ValueIsId := AValueIsId;
  Result.Blank := False;
end;

class function TXcomArticleRow.MakeBlank: TXcomArticleRow;
begin
  Result.LabelId := '';
  Result.Value := '';
  Result.ValueIsId := False;
  Result.Blank := True;
end;

end.
