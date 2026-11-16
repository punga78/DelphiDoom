{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom editor - the contracts with the system and with the window }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EndoomEditor.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.EndoomEditor.Types,
  DelphiDoom.Endoom.TextArt.Types;

type
  /// <summary>
  ///   The window of the editor: it draws what the presenter says and tells the presenter what the user does
  ///   (mouse, keys, menus, timers). It does not decide anything: no tool, no file, no zoom
  /// </summary>
  IEndoomEditorView = interface
    ['{4E91B7C0-2A5D-4F36-8B14-D0C97E3A6F58}']
    /// <summary>
    ///   The picture of the screen: 640x200 pixels $FFRRGGBB, to be stretched to 640+80*zoom by 400+50*zoom,
    ///   with the grid, the cursor and the selection that the overlay asks for
    /// </summary>
    procedure ShowPicture(const APixels: TArray<Cardinal>; const AOverlay: TEndoomEditorOverlay);
    procedure ShowTitle(const ATitle: string);
    procedure ShowStatus(const AText: string);
    procedure ShowState(const AState: TEndoomEditorState);
    /// <summary>The captions of the items of the recent files menu, newest first</summary>
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    /// <summary>The colors and characters that are chosen now: the palettes mark them</summary>
    procedure ShowChoices(ATool: TEndoomEditorTool; AForeground, ABackground, ASpecial1, ASpecial2: Integer);
    procedure CloseWindow;
  end;

  /// <summary>The questions and the files of the user</summary>
  IEndoomEditorDialogs = interface
    ['{A3D50E68-97B1-4C2F-85E4-1F6B2C8D7390}']
    function PickFileToOpen(out AFileName: string): Boolean;
    function PickFileToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    /// <summary>The file of an export; the extension tells the format (.png, .jpg, .bmp)</summary>
    function PickImageToExport(out AFileName: string): Boolean;
    /// <summary>The method of the conversion of a picture; false if the user cancels</summary>
    function PickTextArtMethod(var AKind: TEndoomTextArtKind): Boolean;
    function AskSaveChanges: TEndoomConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

  /// <summary>The clipboard of Windows: pictures and text</summary>
  IEndoomEditorClipboard = interface
    ['{7B28F4D1-5C03-49A6-9E17-B8A0D63C1F24}']
    function HasText: Boolean;
    function HasImage: Boolean;
    function GetText: string;
    /// <summary>The picture on the clipboard as $xxRRGGBB pixels; false if there is none</summary>
    function TryGetImage(out APixels: TArray<Cardinal>; out AWidth, AHeight: Integer): Boolean;
    procedure SetImage(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
  end;

  /// <summary>Writes a picture to a file, by the extension of its name</summary>
  IEndoomEditorImageExporter = interface
    ['{D9C61A35-0E78-4B2D-A4F9-3E5B17C80D62}']
    function Export(const AFileName: string; const APixels: TArray<Cardinal>; AWidth, AHeight: Integer): Boolean;
  end;

implementation

end.
