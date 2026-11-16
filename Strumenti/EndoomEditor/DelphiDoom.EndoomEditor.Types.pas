{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom editor - types and constants                              }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EndoomEditor.Types;

interface

uses
  DelphiDoom.Endoom.Types;

const
  ENDOOM_EDITOR_TITLE = 'ENDTEXT Editor';
  /// <summary>The zoom 0 is the picture of 640x400 pixels; each step adds 8 pixels to the width of a cell</summary>
  ENDOOM_EDITOR_MIN_ZOOM = 0;
  ENDOOM_EDITOR_MAX_ZOOM = 20;
  /// <summary>Pixels of a cell at zoom 0 (the picture is 640x400: the cells are 8x16)</summary>
  ENDOOM_EDITOR_CELL_WIDTH = 8;
  ENDOOM_EDITOR_CELL_HEIGHT = 16;
  /// <summary>Size of the picture of an export (the screen with every row twice)</summary>
  ENDOOM_EDITOR_EXPORT_WIDTH = 640;
  ENDOOM_EDITOR_EXPORT_HEIGHT = 400;
  /// <summary>The first of the characters that the special character tools offer (the blocks and lines of the DOS font)</summary>
  ENDOOM_EDITOR_FIRST_SPECIAL_CODE = $B0;
  /// <summary>The rows that Page Up and Page Down move the cursor</summary>
  ENDOOM_EDITOR_PAGE_ROWS = 5;

  // the sections and names of the settings file of ENDEDIT (ENDEDIT.ini)
  ENDOOM_EDITOR_SECTION_HISTORY = 'File Menu History';
  ENDOOM_EDITOR_SECTION_OPTIONS = 'Options';
  ENDOOM_EDITOR_SETTING_GRID = 'SHOWGRID';
  ENDOOM_EDITOR_SETTING_ZOOM = 'ZOOM';
  ENDOOM_EDITOR_SETTING_METHOD = 'TEXTARTMETHOD';

resourcestring
  SEndoomEditorFileNotFound = 'Can not find file %s';
  SEndoomEditorCannotRead = 'The file %s is not a text screen: it needs %d bytes';
  SEndoomEditorCannotWrite = 'Can not write the file %s';
  SEndoomEditorCannotExport = 'Can not export the picture to %s';
  SEndoomEditorStatus = 'Position: (%d, %d), Background: (#%s), Foreground: (#%s), Text: (#%s)';

type
  /// <summary>What the mouse does on the screen (the buttons of the left panel of ENDEDIT, and a selection)</summary>
  TEndoomEditorTool = (
    /// <summary>Paints the background of the cells the mouse goes through</summary>
    eetFreeDraw,
    eetFloodFill,
    eetRectangle,
    eetFilledRectangle,
    eetLine,
    /// <summary>Takes away the character of a cell</summary>
    eetEraseText,
    /// <summary>Puts the cursor in a cell: what is typed goes there</summary>
    eetText,
    eetEllipse,
    eetFilledEllipse,
    /// <summary>Background, foreground and the first special character</summary>
    eetSpecialCharacterWithBackground,
    /// <summary>Foreground and the second special character</summary>
    eetSpecialCharacter,
    /// <summary>Only the foreground of a cell</summary>
    eetTextColor,
    eetFrameSingle,
    eetFrameDoubleHorizontal,
    eetFrameDoubleVertical,
    eetFrameDouble,
    eetFrameBlock,
    eetBlinkOn,
    eetBlinkOff,
    /// <summary>Chooses a rectangle of cells to copy, cut, paste over or fill</summary>
    eetSelect
  );

  /// <summary>The keys that the editor moves the cursor with</summary>
  TEndoomEditorKey = (
    eekLeft, eekRight, eekUp, eekDown, eekHome, eekEnd, eekPageUp, eekPageDown, eekDelete
  );

  /// <summary>The answer to "do you want to save the changes?"</summary>
  TEndoomConfirmation = (ecYes, ecNo, ecCancel);

  /// <summary>What the window draws over the picture of the screen</summary>
  TEndoomEditorOverlay = record
    Zoom: Integer;
    ShowGrid: Boolean;
    CursorVisible: Boolean;
    /// <summary>The cursor is drawn white and black in turn</summary>
    CursorInverted: Boolean;
    CursorX: Integer;
    CursorY: Integer;
    /// <summary>The rectangle of the selection tool, when there is one</summary>
    SelectionVisible: Boolean;
    Selection: TEndoomRect;
  end;

  /// <summary>Which commands the window shows as available</summary>
  TEndoomEditorState = record
    CanUndo: Boolean;
    CanRedo: Boolean;
    CanPaste: Boolean;
    CanZoomIn: Boolean;
    CanZoomOut: Boolean;
    HasSelection: Boolean;
    HasBlock: Boolean;
  end;

implementation

end.
