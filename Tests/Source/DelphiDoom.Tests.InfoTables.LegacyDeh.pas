{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info and script tables - the old text routines     }
{  of deh_base                                                                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// DEH_CStringToString, DEH_StringValue and the name rules of DEH_AmmoType, DEH_WeaponType and
// DEH_PlayerClass of Base\deh_base.pas as they were before issue #185 (commit 63a151cc), copied
// line by line; the three type functions take the token list as a parameter instead of a global
unit DelphiDoom.Tests.InfoTables.LegacyDeh;

interface

uses
  System.SysUtils,
  d_delphi;

function Legacy_DEH_CStringToString(const s: string): string;
function Legacy_DEH_StringValue(const s: string): string;
function Legacy_DEH_AmmoType(const str: string; const ammotype_tokens: TDStringList): integer;
function Legacy_DEH_WeaponType(const str: string; const weapontype_tokens: TDStringList): integer;
function Legacy_DEH_PlayerClass(const str: string; const playerclass_tokens: TDStringList): integer;

implementation

function Legacy_DEH_CStringToString(const s: string): string;
var
  i, len: integer;
begin
  result := '';
  if s = '' then
  begin
    exit;
  end;

  result := s[1];

  len := Length(s);
  for i := 2 to len do
  begin
    if s[i] = 'N' then
    begin
      if (Length(result) > 0) and (result[Length(result)] = '\') then
      begin
        result[Length(result)] := #13;
        result := result + #10
      end
      else
        result := result + 'N'
    end
    else if s[i] = 'R' then
    begin
      if (Length(result) > 0) and (result[Length(result)] = '\') then
        SetLength(result, Length(result) - 1)
      else
        result := result + 'R';
    end
    else if s[i] = #10 then
    begin
      if (Length(result) > 0) and (result[Length(result)] <> #13) then
        result := result + #13#10
      else
        result := result + #10;
    end
    else
      result := result + s[i];
  end;
end;

function Legacy_DEH_StringValue(const s: string): string;
var
  i: integer;
begin
  result := '';
  for i := 1 to Length(s) do
  begin
    if toupper(s[i]) in ['A'..'Z', '1'..'9', '0'] then
      result := result + toupper(s[i]);
  end;
end;

function Legacy_DEH_AmmoType(const str: string; const ammotype_tokens: TDStringList): integer;
var
  stmp: string;
begin
  if ammotype_tokens = nil then
  begin
    result := atoi(str, -1);
    exit;
  end;

  if StrIsInteger(str) then
  begin
    result := atoi(str, -1);
    exit;
  end;

  stmp := strupper(str);
  if not Pos1('AM_', stmp) then
    stmp := stmp + 'AM_';

  result := ammotype_tokens.IndexOf(stmp);
end;

function Legacy_DEH_WeaponType(const str: string; const weapontype_tokens: TDStringList): integer;
var
  stmp: string;
begin
  if weapontype_tokens = nil then
  begin
    result := atoi(str, -1);
    exit;
  end;

  if StrIsInteger(str) then
  begin
    result := atoi(str, -1);
    exit;
  end;

  stmp := strupper(str);
  if not Pos1('WP_', stmp) then
    stmp := stmp + 'WP_';

  result := weapontype_tokens.IndexOf(stmp);
end;

function Legacy_DEH_PlayerClass(const str: string; const playerclass_tokens: TDStringList): integer;
var
  stmp: string;
begin
  if playerclass_tokens = nil then
  begin
    result := atoi(str, -1);
    exit;
  end;

  if StrIsInteger(str) then
  begin
    result := atoi(str, -1);
    exit;
  end;

  stmp := strupper(str);
  if not Pos1('PCLASS_', stmp) then
    stmp := stmp + 'PCLASS_';

  result := playerclass_tokens.IndexOf(stmp);
end;

end.
