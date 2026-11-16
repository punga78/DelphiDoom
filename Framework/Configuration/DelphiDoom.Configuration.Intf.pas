{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - contracts                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Intf;

interface

uses
  DelphiDoom.Configuration.Types;

type
  /// <summary>
  ///   A configuration file that was read: the first line (the header with the version of the
  ///   engine that wrote it) and the lines after it, each "name=value", "[group]" or empty
  /// </summary>
  IConfigurationDocument = interface
    ['{8A5D1C37-0E92-4B6F-B3A8-7C4F29E1D058}']
    function GetHeader: string;
    function GetCount: Integer;
    property Header: string read GetHeader;
    /// <summary>The lines after the header</summary>
    property Count: Integer read GetCount;
    /// <summary>
    ///   The name of the line AIndex in lower case; empty for a line with no "="
    ///   (a group, a blank line, a comment). Raises EConfigurationException for a bad position
    /// </summary>
    function NameAt(AIndex: Integer): string;
    /// <summary>
    ///   The value of the first line with that name (case insensitive); empty when there is none.
    ///   Like the old reader: when a name repeats, every repeat gets the first value
    /// </summary>
    function ValueOf(const AName: string): string;
  end;

  /// <summary>Collects the lines of a configuration file to write</summary>
  IConfigurationWriter = interface
    ['{F2B96E40-5D13-4A87-9C0E-1A3D75B8C264}']
    /// <summary>A blank line and "[AName]"</summary>
    procedure AddGroup(const AName: string);
    /// <summary>"AName=AValue"</summary>
    procedure AddValue(const AName, AValue: string);
    /// <summary>The header and what was added, one string per line</summary>
    function Lines: TArray<string>;
  end;

  /// <summary>
  ///   How the engine writes and reads its configuration file: the header with the version,
  ///   which versions are accepted, and the values of the lines
  /// </summary>
  IConfigurationFormat = interface
    ['{19E3C8A2-6B74-4D05-8F91-C0A5B2D7E683}']
    /// <summary>'[Delphi Doom ver 2.07]' for ('Delphi Doom', 207)</summary>
    function FormatHeader(const AApplicationTitle: string; AVersionNumber: Integer): string;
    /// <summary>
    ///   True when the header says a version of the engine up to the next one after
    ///   ACurrentVersion (a configuration written by a newer build is still read) and no older than 1.10
    /// </summary>
    function AcceptsHeader(const AHeader: string; ACurrentVersion: Integer): Boolean;
    function Parse(const ALines: TArray<string>): IConfigurationDocument;
    function CreateWriter(const AHeader: string): IConfigurationWriter;
    /// <summary>
    ///   The number of a value: decimal, hexadecimal (0x, $) or with #; a character in quotes
    ///   ('a' or "a") or a lone character that is not a digit gives its code; else 0
    /// </summary>
    function ParseInteger(const AText: string): Integer;
    function ParseBoolean(const AText: string): Boolean;
    function FormatInteger(AValue: Integer): string;
    function FormatBoolean(AValue: Boolean): string;
  end;

  /// <summary>
  ///   How a row of the table reaches the variable it describes. The library does not know
  ///   where the variable is: the composition root (or an adapter of the engine) gives this
  ///   small object. Only the methods of the kind of the row are called
  /// </summary>
  IConfigurationValueAccess = interface
    ['{4C61B0E2-93A7-4F18-8D5C-2E7A90F3B416}']
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
  end;

  /// <summary>
  ///   A row of the table of the options (a default_t of m_defs): its name, kind, who can change
  ///   it, the values it starts with and its variable.
  ///   A forced row (Force*: #CVARFORCE, the scripts) keeps the forced value in the variable and
  ///   is closed: the file, the console and a reset see and change the value it had before the
  ///   force, which is kept in the row as its default (that is what the old table did by moving
  ///   its pointer to its own default)
  /// </summary>
  IConfigurationItem = interface
    ['{B7D24F96-1E3C-4A05-A8F2-63C91D7E05B8}']
    function Name: string;
    function Kind: TConfigurationItemKind;
    /// <summary>CONFIGURATION_SET_* flags; CONFIGURATION_SET_NEVER after a force</summary>
    function Setable: Byte;
    function Defaults: TConfigurationDefaults;
    function IsForced: Boolean;
    /// <summary>The value seen by the file and the console (before a force: the variable)</summary>
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
    /// <summary>The value of the variable itself (after a force: the forced value)</summary>
    function ActualInteger: Integer;
    function ActualBoolean: Boolean;
    function ActualString: string;
    /// <summary>The value takes the default of the row; nothing for a group</summary>
    procedure ResetToDefault;
    /// <summary>
    ///   The first force closes the row and moves its value to its default; the next ones
    ///   only write the variable. Raises EConfigurationException for a row of another kind
    /// </summary>
    procedure ForceInteger(AValue: Integer);
    procedure ForceBoolean(AValue: Boolean);
    procedure ForceString(const AValue: string);
  end;

  /// <summary>The rows of the options in the order of the file</summary>
  IConfigurationTable = interface
    ['{2E95A1C7-6D48-4B30-9F17-C85B3A04D2E9}']
    function Count: Integer;
    /// <summary>Raises EConfigurationException for a bad position</summary>
    function Item(AIndex: Integer): IConfigurationItem;
    /// <summary>The position of the first row with that name (any kind, case sensitive); -1</summary>
    function IndexOf(const AName: string): Integer;
    /// <summary>The first row with that name that is not a group; nil when there is none</summary>
    function FindValue(const AName: string): IConfigurationItem;
  end;

  /// <summary>
  ///   What the caller of IConfigurationTableStore.Reset does when a row is reset: the messages
  ///   and the console stay in the engine
  /// </summary>
  IConfigurationResetSink = interface
    ['{6A0E3B57-C819-4D2F-9E64-B13F70A82DC5}']
    /// <summary>The row took its default (the caller shows the new value)</summary>
    procedure ValueReset(const AName, ALowerName: string);
    /// <summary>True when the console has a command with that name</summary>
    function HasCommand(const ALowerName: string): Boolean;
    /// <summary>
    ///   The row can not be changed but has a command: the caller runs the command with the
    ///   default of the row
    /// </summary>
    procedure CommandReset(const AName, ALowerName: string; const AItem: IConfigurationItem);
  end;

  /// <summary>
  ///   What M_LoadDefaults, M_SaveDefaults and M_ForceDefault* did with the table: the steps
  ///   that do not depend on the engine (the file on disk, the command line, the messages and
  ///   the console stay with the caller)
  /// </summary>
  IConfigurationTableStore = interface
    ['{93F0C5D8-2A61-4E7B-B4C9-1D08E6A57F32}']
    /// <summary>Every row takes its default (the first step of M_LoadDefaults)</summary>
    procedure ResetAll;
    /// <summary>
    ///   Every line of the document whose name is a row (the first row with that name) gives
    ///   the row its value; lines with an unknown name and rows that are groups are skipped
    /// </summary>
    procedure Apply(const ADocument: IConfigurationDocument);
    /// <summary>Every row to the writer, in order: a group as a group, the others as values</summary>
    procedure Write(const AWriter: IConfigurationWriter);
    /// <summary>
    ///   Forces every row with that name (in lower case) and that kind; False if there is none
    /// </summary>
    function ForceInteger(const AName: string; AValue: Integer): Boolean;
    function ForceBoolean(const AName: string; AValue: Boolean): Boolean;
    function ForceString(const AName: string; const AValue: string): Boolean;
    /// <summary>The names of the rows that are not groups, in order</summary>
    function Names: TArray<string>;
    /// <summary>
    ///   M_SetDefault for one name (no mask): every row with the name in lower case that
    ///   ASetFlags allows to change takes its default (ASink.ValueReset); one that can not be
    ///   changed but has a command goes to ASink.CommandReset. A group with the name stops the
    ///   loop, as in the old code
    /// </summary>
    procedure Reset(const AName: string; ASetFlags: Byte; const ASink: IConfigurationResetSink);
  end;

implementation

end.
