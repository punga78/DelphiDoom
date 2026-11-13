{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info and script tables - the old token lists       }
{  and constants                                                               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// The code of Base\sc_tokens.pas and of the table of constants of Base\sc_consts.pas as it was
// before issue #185 (commit 63a151cc), copied line by line. The warnings that went to
// I_Warning are collected in LegacyConstWarnings.
unit DelphiDoom.Tests.InfoTables.LegacyTokens;

interface

uses
  d_delphi;

type
  TLegacyTokenList = class(TDStringList)
  public
    function IndexOfToken(const S: string): Integer; virtual;
    function AllTokensWithIndex: TDStringList;
  end;

function Legacy_EvalueateIntToken(const token: string; const A: array of string): integer;

procedure Legacy_InitConsts;
procedure Legacy_ShutDownConsts;
function Legacy_AddConst(const name: string; const value: integer): boolean;
function Legacy_GetConst(const name: string; var value: integer): boolean;

var
  LegacyConstWarnings: TDStringList;

implementation

const
  CONSTSHASHSIZE = 16;

var
  constshashtable: array[0..CONSTSHASHSIZE - 1] of TDStringList;

function TLegacyTokenList.IndexOfToken(const S: string): Integer;
var
  i, j: integer;
  list: TDStringList;
  stmp, stmp2: string;
begin
  result := IndexOf(S);
  if result > -1 then
    exit;

  list := TDStringList.Create;

  for i := 0 to Count - 1 do
  begin
    stmp := Strings[i];
    if CharPos(',', stmp) > 0 then
    begin
      stmp2 := '';
      for j := 1 to Length(stmp) do
        if stmp[j] = ',' then
          stmp2 := stmp2 + #13#10
        else
          stmp2 := stmp2 + stmp[j];
      stmp := strtrim(stmp2);
      if stmp <> '' then
      begin
        list.Text := stmp;
        for j := 0 to list.Count - 1 do
          list.Strings[j] := strtrim(list.Strings[j]);
        if list.IndexOf(S) > -1 then
        begin
          list.Free;
          result := i;
          exit;
        end;
      end;
    end;
  end;
  list.Free;
end;

function TLegacyTokenList.AllTokensWithIndex: TDStringList;
var
  i, j: integer;
  list: TDStringList;
  stmp, stmp2: string;
begin
  Result := TDStringList.Create;

  list := TDStringList.Create;
  for i := 0 to Count - 1 do
  begin
    stmp := Strings[i];
    if CharPos(',', stmp) = 0 then
      Result.AddObject(strtrim(stmp), TInteger.Create(i))
    else
    begin
      stmp2 := '';
      for j := 1 to Length(stmp) do
        if stmp[j] = ',' then
          stmp2 := stmp2 + #13#10
        else
          stmp2 := stmp2 + stmp[j];
      stmp := strtrim(stmp2);
      if stmp <> '' then
      begin
        list.Text := stmp;
        for j := 0 to list.Count - 1 do
          Result.AddObject(strtrim(list.Strings[j]), TInteger.Create(i));
      end;
    end;
  end;
  list.Free;
end;

function Legacy_EvalueateIntToken(const token: string; const A: array of string): integer;
var
  i: integer;
  tt: TLegacyTokenList;
begin
  i := atoi(token);
  if itoa(i) = token then
  begin
    result := i;
    exit;
  end;

  tt := TLegacyTokenList.Create;
  for i := Low(A) to High(A) do
    tt.Add(A[i]);
  result := tt.IndexOfToken(token);
  tt.Free;
end;

function _hash(const s: string): integer;
var
  len: integer;
begin
  len := Length(s);
  result := (len + Ord(s[1]) + Ord(s[len])) and (CONSTSHASHSIZE - 1);
end;

procedure Legacy_InitConsts;
var
  i: integer;
begin
  for i := 0 to CONSTSHASHSIZE - 1 do
    constshashtable[i] := TDStringList.Create;
  LegacyConstWarnings := TDStringList.Create;
end;

procedure Legacy_ShutDownConsts;
var
  i, j: integer;
begin
  for i := 0 to CONSTSHASHSIZE - 1 do
  begin
    for j := 0 to constshashtable[i].Count - 1 do
      constshashtable[i].Objects[j].Free;
    constshashtable[i].Free;
  end;
  LegacyConstWarnings.Free;
end;

function Legacy_AddConst(const name: string; const value: integer): boolean;
var
  uToken: string;
  hash: integer;
begin
  uToken := strupper(strtrim(name));
  if uToken = '' then
  begin
    LegacyConstWarnings.Add('empty ' + itoa(value));
    result := false;
    exit;
  end;

  hash := _hash(uToken);
  if constshashtable[hash].IndexOf(uToken) >= 0 then
  begin
    LegacyConstWarnings.Add('twice ' + name + ' ' + itoa(value));
    result := false;
    exit;
  end;

  constshashtable[hash].AddObject(uToken, TInteger.Create(value));
  result := true;
end;

function Legacy_GetConst(const name: string; var value: integer): boolean;
var
  uToken: string;
  hash: integer;
  idx: integer;
begin
  uToken := strupper(strtrim(name));
  if uToken = '' then
  begin
    result := false;
    exit;
  end;

  hash := _hash(uToken);
  idx := constshashtable[hash].IndexOf(uToken);
  if idx >= 0 then
  begin
    value := (constshashtable[hash].Objects[idx] as TInteger).intnum;
    result := true;
    exit;
  end;

  result := false;
end;

end.
