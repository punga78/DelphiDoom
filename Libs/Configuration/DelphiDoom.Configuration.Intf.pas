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

implementation

end.
