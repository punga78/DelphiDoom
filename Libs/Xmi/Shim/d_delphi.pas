{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF - minimal stand-in for Common\d_delphi.pas              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit d_delphi;

// XMILIB\xmi_core.pas has "uses d_delphi" but needs only the two routines
// below. This unit has the same name as the engine unit so that xmi_core
// compiles unchanged, but it replaces it: the project that uses it (DDXmi,
// the tests) must NOT have the folder Common in its unit search path, and the
// two units can never be linked in the same executable. The routines behave
// as the ones of Common\d_delphi.pas (without the MMX paths).

interface

/// <summary>
///   True if s starts with subs
/// </summary>
function Pos1(const subs, s: string): Boolean;

/// <summary>
///   Fills count0 bytes at dest0 with zeroes
/// </summary>
procedure ZeroMemory(const dest0: Pointer; const count0: Integer);

implementation

function Pos1(const subs, s: string): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(s) >= Length(subs);
  if not Result then
    Exit;

  for LIndex := 1 to Length(subs) do
    if subs[LIndex] <> s[LIndex] then
      Exit(False);
end;

procedure ZeroMemory(const dest0: Pointer; const count0: Integer);
begin
  FillChar(dest0^, count0, 0);
end;

end.
