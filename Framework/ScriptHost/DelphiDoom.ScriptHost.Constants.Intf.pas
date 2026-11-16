{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the contracts of the constants of the scripts     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Constants.Intf;

interface

type
  /// <summary>Where a provider writes the constants that every script can read</summary>
  IScriptConstantTable = interface
    ['{A4C7E2B9-6D13-4F58-9B0A-1E85D3C672F4}']
    /// <summary>A constant of the script type integer</summary>
    procedure AddInteger(const AName: string; const AValue: Integer);
    /// <summary>A constant of the script type longword</summary>
    procedure AddLongWord(const AName: string; const AValue: Cardinal);
    /// <summary>
    ///   A constant of the script type extended. The value is an Extended: a Double would round
    ///   the constants of the tables (D_PI) and the compiled scripts would change
    /// </summary>
    procedure AddExtended(const AName: string; const AValue: Extended);
  end;

  /// <summary>
  ///   A part of the constants of the unit SYSTEM. The providers are asked in order: the order of
  ///   the constants is the one that the compiler of the scripts shows to the tools
  /// </summary>
  IScriptConstantProvider = interface
    ['{5E19B7D3-C082-4A64-8F7D-B3D6A2E40195}']
    procedure Describe(const ATable: IScriptConstantTable);
  end;

implementation

end.
