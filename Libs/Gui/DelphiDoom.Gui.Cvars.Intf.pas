{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - the console variables the windows read and write  }
{                                                                              }
{  The part of cvarSystem and idCVar that ui\*.cpp of Doom 3 (id Software,     }
{  GPL v3) uses: find a variable by name, read and write its value as a        }
{  string, an integer, a float or a boolean.                                   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Cvars.Intf;

interface

type
  /// <summary>
  ///   The console variables of the engine as the windows see them. A name that does not exist reads as
  ///   an empty string, 0 and false (what an <c>idCVar</c> that is not found would be, were it asked).
  /// </summary>
  IGuiCvars = interface
    ['{4C8E2B71-9D35-4F0A-B6E4-71A3D05C8F31}']
    /// <summary>cvarSystem->Find(name) &lt;&gt; NULL</summary>
    function Exists(const AName: AnsiString): Boolean;
    function GetString(const AName: AnsiString): AnsiString;
    /// <summary>idCVar::GetInteger: atoi of the value</summary>
    function GetInteger(const AName: AnsiString): Integer;
    /// <summary>idCVar::GetFloat: atof of the value, as a float</summary>
    function GetFloat(const AName: AnsiString): Single;
    /// <summary>idCVar::GetBool: the integer value is not zero</summary>
    function GetBool(const AName: AnsiString): Boolean;
    procedure SetString(const AName, AValue: AnsiString);
    procedure SetInteger(const AName: AnsiString; const AValue: Integer);
    procedure SetFloat(const AName: AnsiString; const AValue: Single);
    procedure SetBool(const AName: AnsiString; const AValue: Boolean);
  end;

implementation

end.
