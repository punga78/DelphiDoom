{******************************************************************************}
{                                                                              }
{  DelphiDoom: font editor - types and constants                                }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.FontEditor.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types;

const
  FONT_EDITOR_TITLE = 'Doom Font Creator';
  /// <summary>The file of a project of the tool: the text of the settings of the font (the lump DDFONT of a WAD)</summary>
  FONT_EDITOR_PROJECT_EXTENSION = '.ddp';
  /// <summary>The picture of the grid is stretched up to 1 + 3 times as much, in MAX_ZOOM steps</summary>
  FONT_EDITOR_MIN_ZOOM = 0;
  FONT_EDITOR_MAX_ZOOM = 10;
  /// <summary>The size of the cell of a character, as the sliders of DD_FONT allowed it</summary>
  FONT_EDITOR_MIN_CELL = 5;
  FONT_EDITOR_MAX_CELL = 32;

  // the sections and names of the settings file of DD_FONT (DD_FONT.ini); the history has its own section so that
  // the tools of DD_Tools do not share their lists
  FONT_EDITOR_SECTION_HISTORY = 'Font Menu History';
  FONT_EDITOR_SECTION_OPTIONS = 'General Options';
  FONT_EDITOR_SECTION_FONT = 'Generate Font Options';
  FONT_EDITOR_SETTING_GRID = 'SHOWGRID';
  FONT_EDITOR_SETTING_ZOOM = 'ZOOM';
  FONT_EDITOR_SETTING_DRAW_WIDTH = 'DRAWWIDTH';
  FONT_EDITOR_SETTING_DRAW_HEIGHT = 'DRAWHEIGHT';
  FONT_EDITOR_SETTING_FONT_SIZE = 'FONTSIZE';
  FONT_EDITOR_SETTING_FONT_NAME = 'FONTNAME';
  FONT_EDITOR_SETTING_BOLD = 'BOLD';
  FONT_EDITOR_SETTING_ITALIC = 'ITALIC';
  FONT_EDITOR_SETTING_UNDERLINE = 'UNDERLINE';
  FONT_EDITOR_SETTING_STRIKEOUT = 'STRIKEOUT';
  FONT_EDITOR_SETTING_FRONT_COLOR = 'FGCOLOR';
  FONT_EDITOR_SETTING_BACK_COLOR = 'BKCOLOR';
  FONT_EDITOR_SETTING_FIXED_PITCH = 'FIXEDPITCH';
  FONT_EDITOR_SETTING_PERLIN_NOISE = 'PERLINNOISE';
  FONT_EDITOR_SETTING_PALETTE = 'PALETTE';
  FONT_EDITOR_SETTING_EXTERNAL_PALETTE = 'EXTERNALPALETTE';
  FONT_EDITOR_SETTING_TEXT = 'TEXTEXPORTSTRING';
  FONT_EDITOR_SETTING_CHARACTER_PREFIX = 'FONTSEQUENCEPREFIX';
  FONT_EDITOR_SETTING_DIGIT_PREFIX = 'NUMBERSEQUENCEPREFIX';
  /// <summary>The name that the palette of a file is saved with</summary>
  FONT_EDITOR_PALETTE_OTHER_NAME = 'OTHER';

resourcestring
  SFontEditorFileNotFound = 'Can not find file %s';
  SFontEditorCannotRead = 'The file %s is not a font project';
  SFontEditorCannotWrite = 'Can not write the file %s';
  SFontEditorCannotExport = 'Can not export the picture to %s';
  SFontEditorFontAlreadyLoaded = '"%s"'#13#10'already loaded';
  SFontEditorCannotInstall = 'Can not load the font %s';
  SFontEditorWadWritten = 'The WAD has %d lumps';
  SFontEditorInfo = 'Image Size: %dx%d   Character Rect Size: %dx%d';

type
  /// <summary>The palettes that the patches of a font can be made with: the six that the tool knows and a file</summary>
  TFontEditorPalette = (epDoom, epHeretic, epHexen, epStrife, epRadix, epGLSpeed, epOther);

  /// <summary>The answer to "do you want to save the changes?"</summary>
  TFontEditorConfirmation = (fcYes, fcNo, fcCancel);

  /// <summary>What the window shows of the settings of the font and of what a WAD is made of</summary>
  TFontEditorDisplay = record
    FontName: string;
    FontSize: Integer;
    Bold: Boolean;
    Italic: Boolean;
    Underline: Boolean;
    StrikeOut: Boolean;
    DrawWidth: Integer;
    DrawHeight: Integer;
    FrontColor: Integer;
    BackColor: Integer;
    ShowGrid: Boolean;
    Zoom: Integer;
    /// <summary>"Image Size: 256x256   Character Rect Size: 16x16"</summary>
    Info: string;
    Kind: TFontSequenceKind;
    Text: string;
    CharacterPrefix: string;
    DigitPrefix: string;
    FixedPitch: Boolean;
    PerlinNoise: Boolean;
    Palette: TFontEditorPalette;
    ExternalPalette: string;
  end;

  /// <summary>Which commands the window shows as available</summary>
  TFontEditorState = record
    CanUndo: Boolean;
    CanRedo: Boolean;
    CanZoomIn: Boolean;
    CanZoomOut: Boolean;
    /// <summary>A WAD can be made: the text of the first mode has something that is not a space</summary>
    CanGenerate: Boolean;
    /// <summary>The choice of the file of the palette is the one that counts</summary>
    ExternalPaletteVisible: Boolean;
  end;

implementation

end.
