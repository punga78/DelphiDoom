{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - how a search in a script is done                  }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.SearchPlan;

interface

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.SearchSettings;

type
  /// <summary>What the editor has to do: the flags and which search engine to use</summary>
  TIdeSearchPlan = record
    Flags: TIdeSearchFlags;
    /// <summary>True for the regular expression engine, false for the plain text one</summary>
    UseRegularExpression: Boolean;
  end;

  /// <summary>Turns the options of the user into the plan of a search or replace</summary>
  TIdeSearchPlans = class
  public
    /// <summary>
    ///   The plan for the "Find" and "Replace" dialogs. A replace asks before each change and
    ///   goes on to all the occurrences. Without "from caret" the search starts from the top
    /// </summary>
    class function ForDialog(const ASettings: TIdeSearchSettings; const AReplace, AFromCaret: Boolean): TIdeSearchPlan; static;
    /// <summary>The plan for "Search again": it never starts from the top and never replaces</summary>
    class function ForSearchAgain(const ASettings: TIdeSearchSettings): TIdeSearchPlan; static;
  end;

implementation

{ TIdeSearchPlans }

class function TIdeSearchPlans.ForDialog(const ASettings: TIdeSearchSettings; const AReplace,
  AFromCaret: Boolean): TIdeSearchPlan;
begin
  Result.Flags := [];
  if AReplace then
    Result.Flags := [sfPrompt, sfReplace, sfReplaceAll];
  if ASettings.Backwards then
    Include(Result.Flags, sfBackwards);
  if ASettings.CaseSensitive then
    Include(Result.Flags, sfMatchCase);
  if not AFromCaret then
    Include(Result.Flags, sfEntireScope);
  if ASettings.SelectionOnly then
    Include(Result.Flags, sfSelectedOnly);
  if ASettings.WholeWords then
    Include(Result.Flags, sfWholeWord);
  Result.UseRegularExpression := ASettings.RegularExpression;
end;

class function TIdeSearchPlans.ForSearchAgain(const ASettings: TIdeSearchSettings): TIdeSearchPlan;
begin
  Result.Flags := [];
  if ASettings.Backwards then
    Include(Result.Flags, sfBackwards);
  if ASettings.CaseSensitive then
    Include(Result.Flags, sfMatchCase);
  if ASettings.SelectionOnly then
    Include(Result.Flags, sfSelectedOnly);
  if ASettings.WholeWords then
    Include(Result.Flags, sfWholeWord);
  Result.UseRegularExpression := ASettings.RegularExpression;
end;

end.
