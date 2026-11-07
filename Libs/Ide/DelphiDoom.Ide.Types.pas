{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - shared types                                      }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The version written in the first line of a project file</summary>
  IDE_PROJECT_VERSION = '1.0';

  /// <summary>How many search or replace texts the dialogs remember</summary>
  IDE_SEARCH_HISTORY_LIMIT = 10;

  /// <summary>How many lines the message list keeps</summary>
  IDE_MESSAGE_LIMIT = 256;

  /// <summary>How many snapshots the undo history keeps</summary>
  IDE_UNDO_LIMIT = 100;

type
  /// <summary>What a project item is</summary>
  TIdeItemKind = (ikScript, ikCompiledScript, ikActor, ikProject, ikNone);

  /// <summary>The colour class of a line in the message list</summary>
  TIdeMessageKind = (mkNormal, mkInfo, mkWarning, mkError);

  /// <summary>The answer to a yes, no or cancel question</summary>
  TIdeConfirmation = (cfYes, cfNo, cfCancel);

  /// <summary>One line of a project file after the version line</summary>
  TIdeProjectDirective = record
    /// <summary>True for a "game|name" line, false for an item line</summary>
    IsGame: Boolean;
    /// <summary>The game name (lower case, not validated) or the item path</summary>
    Value: string;
    /// <summary>The kind of the item (only for an item line)</summary>
    Kind: TIdeItemKind;
  end;

  /// <summary>One item of a project as the project file writes it</summary>
  TIdeProjectEntry = record
    Kind: TIdeItemKind;
    /// <summary>The path, relative to the project file</summary>
    RelativePath: string;
  end;

  /// <summary>A position in a script, both numbers are one based</summary>
  TIdeSourceLocation = record
    Line: Integer;
    Column: Integer;
  end;

  /// <summary>The functions of one unit of the script library</summary>
  TIdeUnitDeclarations = record
    UnitName: string;
    Declarations: TArray<string>;
  end;

  /// <summary>Which list of the compiler library is asked for</summary>
  TIdeLibraryData = (
    ldConstants,
    ldVariables,
    ldTypes,
    ldClasses,
    ldEvents,
    ldActorDefFunctions,
    ldMobjinfoCsv,
    ldStatesCsv,
    ldSpritesCsv
  );

  /// <summary>Base of the errors of the ide library</summary>
  EIdeException = class(Exception);

implementation

end.
