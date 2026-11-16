{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - what the presenters ask of the windows            }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Views.Intf;

interface

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.ProjectItem;

type
  /// <summary>The main window: the tabs of the editors and the panels of the library</summary>
  IIdeMainView = interface
    ['{2D6A9B41-7C03-4E85-A1F9-B30E58D4C711}']
    /// <summary>Closes the tabs of all the scripts that are open</summary>
    procedure CloseAllEditors;
    /// <summary>
    ///   The project manager shows this project from now on (and shows it at once). A nil project
    ///   makes it let go of the old one, which is about to be freed
    /// </summary>
    procedure ShowProject(const AProject: TIdeProject);
    /// <summary>The title of the window and the caption of the tab of the project</summary>
    procedure SetCaptions(const AWindowCaption, ATabCaption: string);
    /// <summary>Shows the editor of an item: a new tab, or the one that is already open</summary>
    procedure OpenEditor(const AItem: TIdeProjectItem);
    /// <summary>Closes the tab of an item, if it has one</summary>
    procedure CloseEditor(const AItem: TIdeProjectItem);
    function HasEditor(const AItem: TIdeProjectItem): Boolean;
    /// <summary>Brings the tab of an item to the front and gives it a new caption</summary>
    procedure ActivateEditor(const AItem: TIdeProjectItem; const ACaption: string);
    /// <summary>The panels of the library show the data of another game</summary>
    procedure UpdateLibraryGame(const AGame: string);
  end;

  /// <summary>The window of a script: the text, the buttons, the hint, the dialogs of the search</summary>
  IIdeScriptEditorView = interface
    ['{91E5C2A8-0B64-4F3D-8A17-5D9E2C60B812}']
    /// <summary>The text of the script as it is in the editor</summary>
    function EditorText: string;
    /// <summary>The caret goes to a place in the script and the editor takes the focus</summary>
    procedure MoveCaretTo(const ALocation: TIdeSourceLocation);
    /// <summary>The editor shows this text and nothing else changes</summary>
    procedure ShowText(const AText: string);
    /// <summary>Which of the tools the item allows (compile, events, edit)</summary>
    procedure ShowTools(const AKind: TIdeItemKind);
  end;

implementation

end.
