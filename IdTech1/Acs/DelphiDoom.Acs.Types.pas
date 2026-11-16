{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the shared types                        }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Types;

interface

uses
  System.SysUtils;

const
  MAX_IDENTIFIER_LENGTH = 32;
  MAX_QUOTED_LENGTH = 256;
  MAX_SCRIPT_COUNT = 64;
  MAX_MAP_VARIABLES = 32;
  MAX_SCRIPT_VARIABLES = 10;
  MAX_WORLD_VARIABLES = 64;
  MAX_STRINGS = 128;
  MAX_NESTED_SOURCES = 16;
  /// <summary>The object code cannot be bigger than this</summary>
  DEFAULT_OBJECT_SIZE = 65536;
  ASCII_SPACE = 32;
  ASCII_QUOTE = 34;
  ASCII_UNDERSCORE = 95;
  /// <summary>The character that ends the text (DEL): it cannot be used in a script</summary>
  EOF_CHARACTER = 127;

type
  /// <summary>
  ///   The script cannot be compiled. The message has the same lines that the old compiler wrote
  ///   in its error file: "Line N in file 'X' ...", "Error #N: text" and the detail
  /// </summary>
  EAcsCompileException = class(Exception)
  private
    FCode: Integer;
    FLine: Integer;
    FSourceName: string;
    FHasPosition: Boolean;
  public
    constructor Create(ACode: Integer; AHasPosition: Boolean; ALine: Integer;
      const ASourceName, AMessage: string);
    /// <summary>One of the ERR_ codes of DelphiDoom.Acs.ErrorCodes</summary>
    property Code: Integer read FCode;
    /// <summary>The line in the source, when HasPosition</summary>
    property Line: Integer read FLine;
    property SourceName: string read FSourceName;
    property HasPosition: Boolean read FHasPosition;
  end;

implementation

{ EAcsCompileException }

constructor EAcsCompileException.Create(ACode: Integer; AHasPosition: Boolean; ALine: Integer;
  const ASourceName, AMessage: string);
begin
  inherited Create(AMessage);
  FCode := ACode;
  FHasPosition := AHasPosition;
  FLine := ALine;
  FSourceName := ASourceName;
end;

end.