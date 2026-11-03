{******************************************************************************}
{                                                                              }
{  DelphiDoom: script - minimal stand-in for Common\d_delphi.pas               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit d_delphi;

// The core of Pascal Script (ps_utils, ps_compiler, ps_runtime) has
// "uses d_delphi" in its implementation section but needs a single routine:
// CharPos. This unit has the same name as the engine unit so that the core
// compiles unchanged, but it replaces it: the projects that use it (DDScript,
// the tests) must NOT have the folder Common in their unit search path, and the
// two units can never be linked in the same executable.
//
// The original CharPos takes Char and string; the core always calls it with
// TbtChar (AnsiChar) and TbtString (AnsiString), so this version works on
// AnsiString directly: no conversion through UnicodeString, which would change
// the positions of the bytes with a multi-byte code page.

interface

/// <summary>
///   Position (1 based) of the first occurrence of ch in s; 0 if not found
/// </summary>
function CharPos(const ch: AnsiChar; const s: AnsiString): Integer;

implementation

function CharPos(const ch: AnsiChar; const s: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(s) do
    if s[LIndex] = ch then
      Exit(LIndex);

  Result := 0;
end;

end.
