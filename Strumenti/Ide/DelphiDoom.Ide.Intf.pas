{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the contracts with the system                     }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Ide.Types;

type
  /// <summary>
  ///   The files and folders the ide touches. Nothing here raises: a call that fails gives false,
  ///   and the caller writes the message (as the old code did)
  /// </summary>
  IIdeFileSystem = interface
    ['{5B2E6C1A-7D34-4F6B-9A0E-3C41D8E2F701}']
    function FileExists(const APath: string): Boolean;
    function DirectoryExists(const APath: string): Boolean;
    /// <summary>Gives the full path, relative to the current folder of the ide</summary>
    function ExpandFileName(const APath: string): string;
    /// <summary>Creates an empty file (or empties it)</summary>
    function TryCreateEmptyFile(const APath: string): Boolean;
    /// <summary>Reads every byte of a file</summary>
    function TryReadAllText(const APath: string; out AText: AnsiString): Boolean;
    /// <summary>Writes every byte, replacing the file</summary>
    function TryWriteAllText(const APath: string; const AText: AnsiString): Boolean;
    /// <summary>Copies a file; a missing source gives an empty target</summary>
    function TryCopyFile(const ASource, ATarget: string): Boolean;
    /// <summary>Changes the current folder, on which the relative paths of the project rest</summary>
    function TrySetCurrentDirectory(const APath: string): Boolean;
    function TryCreateDirectory(const APath: string): Boolean;
    /// <summary>Loads a text file the way a string list does (line breaks become CR LF)</summary>
    function TryLoadTextFile(const APath: string; out AText: string): Boolean;
    /// <summary>Saves a text file the way a string list does</summary>
    function TrySaveTextFile(const APath: string; const AText: string): Boolean;
    /// <summary>The folder of the program, with the trailing separator</summary>
    function ProgramFolder: string;
  end;

  /// <summary>The message list of the ide</summary>
  IIdeLog = interface
    ['{0F8A3D52-91C6-4E07-B4A8-62D5E9C13B04}']
    procedure Write(const AKind: TIdeMessageKind; const AText: string);
    procedure WriteFormat(const AKind: TIdeMessageKind; const AFormat: string;
      const AArguments: array of const);
  end;

  /// <summary>The time of the day (the backup of a file carries the date)</summary>
  IIdeClock = interface
    ['{A4C7E190-3B5D-42F8-8E6A-71D0B3F9C205}']
    function Now: TDateTime;
  end;

  /// <summary>The "please wait" cursor</summary>
  IIdeBusy = interface
    ['{D3916B7E-5A02-4C48-B1F3-8E7A2C0D6406}']
    procedure Enter;
    procedure Leave;
  end;

  /// <summary>The questions and the notices the ide puts to the user</summary>
  IIdeMessageDialogs = interface
    ['{7E01B5A3-C842-4D69-9F17-A3D6850E2B07}']
    function AskSaveChanges(const AQuestion: string): TIdeConfirmation;
    procedure ShowAbout(const AText: string);
  end;

  /// <summary>The file pickers; each gives false if the user cancels</summary>
  IIdeFileDialogs = interface
    ['{19B8F4D6-2E73-4A51-8C0D-5F9E7A1B3808}']
    function PickProjectToOpen(out AFileName: string): Boolean;
    function PickProjectToSave(out AFileName: string): Boolean;
    function PickItemsToAdd(const AKind: TIdeItemKind; out AFileNames: TArray<string>): Boolean;
    function PickPk3ToSave(out AFileName: string): Boolean;
    function PickMessagesFileToSave(out AFileName: string): Boolean;
  end;

  /// <summary>The file picker of the compiled code of a script (each editor has its own)</summary>
  IIdePCodeDialog = interface
    ['{F1A47C8E-2D95-4B03-86E7-0C5B3D9A1E0F}']
    function PickPCodeFileToSave(const ADefaultName: string; out AFileName: string): Boolean;
  end;

  /// <summary>The clipboard</summary>
  IIdeClipboard = interface
    ['{6C3D9A02-F5B1-4E84-A7D3-0B28E1C94909}']
    procedure SetText(const AText: string);
  end;

  /// <summary>A zip (pk3) file that is being built</summary>
  IIdeArchive = interface
    ['{B2F7A0E4-8D19-4C36-95A2-E4C3D6107A0A}']
    procedure AddFile(const AName: string; const AData: AnsiString; const ADate: TDateTime);
    procedure SaveToFile(const AFileName: string);
  end;

  /// <summary>Makes an empty archive</summary>
  TIdeArchiveFactory = reference to function: IIdeArchive;

  /// <summary>The script compiler (the ddc_*.dll of the game)</summary>
  IIdeScriptCompiler = interface
    ['{E8A5C13F-4B72-4D90-A6E1-93F0B2D58C0B}']
    /// <summary>Compiles a script. The messages hold the warnings or the errors, one per line</summary>
    function Compile(const AGame, ASource: string; out APCode, AMessages: string): Boolean;
    /// <summary>Turns the compiled code back into text</summary>
    function Disassemble(const AGame, APCode: string): string;
  end;

  /// <summary>
  ///   What the compiler library of a game knows: its functions, constants, classes, actors
  ///   and sprites. A game that is not available gives false
  /// </summary>
  IIdeGameLibrary = interface
    ['{3A9E7D05-B1C8-4F2A-8D64-C07E5B93F10C}']
    /// <summary>Keeps the library of a game loaded until Close, for the calls that follow</summary>
    procedure Open(const AGame: string);
    procedure Close;
    function TryGetLines(const AData: TIdeLibraryData; const AGame: string;
      out ALines: TArray<string>): Boolean;
    function TryGetUnitFunctions(const AGame: string;
      out AUnits: TArray<TIdeUnitDeclarations>): Boolean;
  end;

  /// <summary>Who shows a document: it is told when the text changes</summary>
  IIdeDocumentObserver = interface
    ['{C5B09E27-6A3F-4D18-BE72-1F84D0A6350D}']
    procedure DocumentChanged(const AData: AnsiString);
  end;

  /// <summary>What an item of a project asks of the project that holds it</summary>
  IIdeProjectContext = interface
    ['{84D1E6B9-0C57-4A23-9E8F-5D2B7A63C10E}']
    function GetFileName: string;
    function GetGame: string;
    property FileName: string read GetFileName;
    property Game: string read GetGame;
  end;

implementation

end.
