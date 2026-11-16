{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - contract of the serializer of the script state    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Serializer.Intf;

{$I PascalScript.inc}

interface

uses
  System.Classes,
  ps_defs,
  ps_utils;

const
  /// <summary>The types of the global variables of a script that the serializer saves</summary>
  SCRIPT_SERIALIZABLE_TYPES: set of TPSBaseType = [
    btU8,             // Byte, Boolean, Enums
    btS8,
    btU16,
    btS16,
    btU32,            // LongWord
    btS32,            // Integer
    {$IFNDEF PS_NOINT64}
    btS64,
    {$ENDIF}
    btChar,
    btSingle,         // Single
    btDouble,         // Double
    btExtended,       // Extended
    btCurrency,       // Currency
    btString,         // AnsiString
    btWideString,     // WideString
    btUnicodeString,  // UnicodeString
    btStaticArray,    // Static Array
    btArray,          // Dynamic Array
    btRecord,         // Records
    btSet             // Sets
  ];

type
  /// <summary>
  ///   Saves and loads the global variables of the script that an interpreter has loaded (the
  ///   state of the script in the savegames). The functions give false when the state can not be
  ///   saved or loaded (a load that does not match the script is a warning)
  /// </summary>
  IScriptSerializer = interface
    ['{4A9E31C7-2D58-4B60-8F1A-D3E70C65B924}']
    function SaveToFile(const AName: string): Boolean;
    function AppendToFile(const AName: string): Boolean;
    function LoadFromFile(const AName: string): Boolean;
    /// <summary>Loads from the position in the file; the position is the end of what was read</summary>
    function LoadFromFilePos(const AName: string; var APosition: Integer): Boolean;
    /// <summary>The state: its length (4 bytes), the number of variables and each variable</summary>
    function SaveToStream(const AStream: TStream): Boolean;
    function LoadFromStream(const AStream: TStream): Boolean;
    /// <summary>The bytes that SaveToStream writes, 0 if it fails</summary>
    function SaveSize: Integer;
  end;

implementation

end.
