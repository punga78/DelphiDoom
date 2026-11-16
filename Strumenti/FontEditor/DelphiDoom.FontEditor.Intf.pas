{******************************************************************************}
{                                                                              }
{  DelphiDoom: font editor - the contracts with the system and with the window  }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.FontEditor.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types,
  DelphiDoom.FontEditor.Types;

type
  /// <summary>
  ///   The window of the editor: it draws what the presenter says and tells the presenter what the user does
  ///   (menus, buttons, edits). It does not decide anything: no limit, no file, no font
  /// </summary>
  IFontEditorView = interface
    ['{2C94A7E1-5B30-4D68-9F12-83E6D0B4A759}']
    /// <summary>
    ///   The grid of the characters (the picture that DD_FONT drew) as pixels $00RRGGBB, to be stretched by
    ///   1 + 3 * AZoom / 10 and, if AShowGrid, with the lines between the cells
    /// </summary>
    procedure ShowGrid(const AImage: TFontImage; AShowGrid: Boolean; AZoom, AColumns, ARows: Integer);
    /// <summary>The text of the page that is chosen, drawn in the font and colors of the settings (320 pixels at most)</summary>
    procedure ShowPreview(const AImage: TFontImage);
    procedure ShowTitle(const ATitle: string);
    procedure ShowDisplay(const ADisplay: TFontEditorDisplay);
    procedure ShowState(const AState: TFontEditorState);
    /// <summary>The captions of the items of the recent files menu, newest first</summary>
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    /// <summary>The names of the fonts that the list can offer (the installed ones and the ones that were opened)</summary>
    procedure ShowFontNames(const ANames: TArray<string>);
    procedure CloseWindow;
  end;

  /// <summary>The questions and the files of the user</summary>
  IFontEditorDialogs = interface
    ['{B8105D3A-7F46-4E29-A0C3-1D5E92B67F84}']
    function PickProjectToOpen(out AFileName: string): Boolean;
    function PickProjectToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickWadToSave(out AFileName: string): Boolean;
    /// <summary>The file of an export of the grid; the extension tells the format (.png, .jpg, .bmp)</summary>
    function PickImageToExport(out AFileName: string): Boolean;
    function PickPaletteFile(out AFileName: string): Boolean;
    /// <summary>A file of a font (.ttf, .otf) to be used while the program runs</summary>
    function PickFontFile(out AFileName: string): Boolean;
    /// <summary>The color dialog of Windows; the color is $00BBGGRR. False if the user cancels</summary>
    function PickColor(var AColor: Integer): Boolean;
    function AskSaveChanges: TFontEditorConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

  /// <summary>The fonts of the machine</summary>
  IFontCatalog = interface
    ['{6E0C83D2-A491-4B75-8D1F-52F7B3A0C968}']
    /// <summary>The names of the fonts, sorted, without repetitions</summary>
    function FontNames: TArray<string>;
  end;

  /// <summary>Makes a font file available to the program only (AddFontResourceEx with FR_PRIVATE) for as long as it runs</summary>
  IFontInstaller = interface
    ['{F43B9A06-1D72-4C58-B3E9-A7208C5D6E14}']
    /// <summary>False if Windows does not take the file</summary>
    function Install(const AFileName: string): Boolean;
    /// <summary>Gives back every font that was installed</summary>
    procedure UninstallAll;
  end;

  /// <summary>Writes a picture to a file, by the extension of its name</summary>
  IFontEditorImageExporter = interface
    ['{9D2E71B5-3C08-4A64-87F0-E6A15B4C0D93}']
    function Export(const AFileName: string; const AImage: TFontImage): Boolean;
  end;

implementation

end.
