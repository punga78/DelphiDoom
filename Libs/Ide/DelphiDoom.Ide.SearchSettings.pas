{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - what the user asked for in the search dialogs     }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.SearchSettings;

interface

uses
  DelphiDoom.Ide.SearchHistory;

type
  /// <summary>
  ///   The options and the texts of the last search and replace, shared by all the script editors
  ///   (the old unit kept them in global variables). The composition root makes one and gives it
  ///   to every editor
  /// </summary>
  TIdeSearchSettings = class
  strict private
    FSearchHistory: TIdeSearchHistory;
    FReplaceHistory: TIdeSearchHistory;
  public
    Backwards: Boolean;
    CaseSensitive: Boolean;
    FromCaret: Boolean;
    SelectionOnly: Boolean;
    /// <summary>Starts the dialog with the word at the caret (or the selection) as text</summary>
    TextAtCaret: Boolean;
    WholeWords: Boolean;
    RegularExpression: Boolean;
    SearchText: string;
    ReplaceText: string;
    constructor Create;
    destructor Destroy; override;
    property SearchHistory: TIdeSearchHistory read FSearchHistory;
    property ReplaceHistory: TIdeSearchHistory read FReplaceHistory;
  end;

implementation

{ TIdeSearchSettings }

constructor TIdeSearchSettings.Create;
begin
  inherited Create;
  FSearchHistory := TIdeSearchHistory.Create;
  FReplaceHistory := TIdeSearchHistory.Create;
end;

destructor TIdeSearchSettings.Destroy;
begin
  FReplaceHistory.Free;
  FSearchHistory.Free;
  inherited Destroy;
end;

end.
