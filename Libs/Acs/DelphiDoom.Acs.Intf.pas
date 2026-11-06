{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the contracts                           }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>Where the files that a script includes come from</summary>
  IAcsSourceProvider = interface
    ['{8A3D5C71-E204-4B96-A1F7-5C0E92B3D648}']
    /// <summary>The bytes of an included file; false if there is no such file</summary>
    function TryLoad(const AName: string; out AText: TBytes): Boolean;
  end;

  /// <summary>Where the compiler is in the text: for the messages of the errors</summary>
  IAcsSourcePosition = interface
    ['{19E4B7A6-3C58-4D20-8B91-F6A2D05C7E43}']
    function GetLine: Integer;
    function GetSourceName: string;
    property Line: Integer read GetLine;
    property SourceName: string read GetSourceName;
  end;

  IAcsCompiler = interface
    ['{C07F2B94-61DA-4E85-9A3C-48D1E7B05F26}']
    /// <summary>
    ///   Compiles the text of a script to the object code (the BEHAVIOR of a map).
    ///   Raises EAcsCompileException if the script is wrong
    /// </summary>
    function Compile(const ASourceName: string; const ASource: TBytes): TBytes;
  end;

implementation

end.