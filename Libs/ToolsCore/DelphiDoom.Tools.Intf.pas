{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - the contracts                               }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The files the tools touch. Nothing here raises: a call that fails gives false and the
  ///   caller decides what to tell the user (as the old tools did)
  /// </summary>
  IToolFileSystem = interface
    ['{4C1D7E92-A3B5-4F08-9D6E-2B8A05C3F711}']
    function FileExists(const APath: string): Boolean;
    /// <summary>Reads every byte of a file</summary>
    function TryReadAllBytes(const APath: string; out ABytes: TBytes): Boolean;
    /// <summary>Writes every byte, replacing the file</summary>
    function TryWriteAllBytes(const APath: string; const ABytes: TBytes): Boolean;
    /// <summary>Copies a file over the target (an existing target is replaced)</summary>
    function TryCopyFile(const ASource, ATarget: string): Boolean;
  end;

  /// <summary>
  ///   The snapshots of a document for undo and redo. A snapshot is the whole state of the
  ///   document as bytes (a text screen is 4000 of them): it is the generic form of the old undo
  ///   managers of the three tools (stacks of compressed streams)
  /// </summary>
  IToolUndoHistory = interface
    ['{9E3A5B60-1D47-4C82-B0F9-7A6C21D84E02}']
    procedure Clear;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
    /// <summary>Remembers the state the document has now, before a change; it clears the redo</summary>
    procedure Save(const ACurrent: TBytes);
    /// <summary>Gives the state to go back to (the current one can be redone)</summary>
    function Undo(const ACurrent: TBytes): TBytes;
    /// <summary>Gives the state to go forward to (the current one can be undone)</summary>
    function Redo(const ACurrent: TBytes): TBytes;
  end;

  /// <summary>
  ///   The settings of a tool: values with a name inside sections, kept in a text file of lines
  ///   Name=Value under [Section] headers. Names and sections do not care about the case
  /// </summary>
  ISettingsStore = interface
    ['{D70B2F48-5C19-4A3E-8E61-F3A9C0B7D503}']
    function ReadString(const ASection, AName, ADefault: string): string;
    function ReadInteger(const ASection, AName: string; ADefault: Integer): Integer;
    function ReadBoolean(const ASection, AName: string; ADefault: Boolean): Boolean;
    procedure WriteString(const ASection, AName, AValue: string);
    procedure WriteInteger(const ASection, AName: string; AValue: Integer);
    procedure WriteBoolean(const ASection, AName: string; AValue: Boolean);
    /// <summary>Reads the file: false if it is missing or cannot be read. Existing values are kept</summary>
    function Load: Boolean;
    /// <summary>Writes the file: false if it cannot be written</summary>
    function Save: Boolean;
  end;

  /// <summary>
  ///   The list of the last files a tool opened or saved, newest first, with no repeated file
  ///   (the case of a path does not count)
  /// </summary>
  IRecentFiles = interface
    ['{2A84C6D9-E0B3-47F1-9C52-18D7B4A6E904}']
    function GetCount: Integer;
    function GetItem(AIndex: Integer): string;
    /// <summary>The file goes to the top of the list; a blank name is ignored</summary>
    procedure Add(const APath: string);
    procedure Remove(const APath: string);
    procedure Clear;
    /// <summary>The caption of an item of a menu: "&amp;1. name" with the name shortened</summary>
    function MenuCaption(AIndex: Integer): string;
    /// <summary>Takes the list from the settings (what a previous SaveTo wrote)</summary>
    procedure LoadFrom(const ASettings: ISettingsStore; const ASection: string);
    procedure SaveTo(const ASettings: ISettingsStore; const ASection: string);
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: string read GetItem; default;
  end;

  /// <summary>Who shows the progress of a long job</summary>
  IProgressObserver = interface
    ['{6B5E8A13-C4D2-4097-A1F6-0E39D8C27B05}']
    procedure ProgressChanged(const AText: string; APercent: Integer);
  end;

  /// <summary>The progress of a long job (an export, a conversion); the job may be cancelled</summary>
  IProgressReporter = interface
    ['{F1C94D27-8A06-4B5E-93D0-6E2B7A18C406}']
    /// <summary>A job of ATotal steps starts (zero if it has no known length)</summary>
    procedure Start(const AText: string; ATotal: Integer);
    procedure Advance(AStep: Integer);
    procedure Finish;
    /// <summary>Asks the job to stop; the job looks at IsCancelled</summary>
    procedure Cancel;
    function IsCancelled: Boolean;
    function Percent: Integer;
  end;

  /// <summary>Keeps a copy of a file before it is overwritten</summary>
  IToolFileBackup = interface
    ['{83A0E5B7-2D6C-4F19-AE48-B1C7D3095F07}']
    /// <summary>
    ///   Copies the file to the same name with the suffix _bak. A file that does not exist is
    ///   nothing to save and gives true; false if the copy fails
    /// </summary>
    function Backup(const APath: string): Boolean;
  end;

implementation

end.
