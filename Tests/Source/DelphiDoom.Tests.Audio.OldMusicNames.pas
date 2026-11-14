{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - the list of mp3 names of s_sound.pas as it was before   }
{  TExternalMusicNames                                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.OldMusicNames;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Copy of S_GetListFromAlias and of the list of S_DoChangeMusic of Base\s_sound.pas at
  ///   54262e7a (issue #185). The TDStringList of d_delphi is a TStringList filled with the
  ///   copy of TDStrings.SetTextStr; the {$IF DEFINED(HERETIC) OR DEFINED(HEXEN)} is the
  ///   AHereticOrHexen argument
  /// </summary>
  TOldMusicNames = class(TObject)
  private
    class procedure SetTextStr(AList: TStringList; const Value: string); static;
    class function toupper(ch: Char): Char; static;
  public
    class function S_GetListFromAlias(const s: string): TStringList; static;
    class function FileNames(const mapname, name, alias: string;
      AHereticOrHexen: Boolean): TArray<string>; static;
  end;

implementation

{ TOldMusicNames }

class function TOldMusicNames.toupper(ch: Char): Char;
begin
  if (ch >= 'a') and (ch <= 'z') then
    result := Char(Ord(ch) - 32)
  else
    result := ch;
end;

class procedure TOldMusicNames.SetTextStr(AList: TStringList; const Value: string);
var
  P, Start: PChar;
  S: string;
begin
  AList.Clear;
  P := Pointer(Value);
  if P <> nil then
    while P^ <> #0 do
    begin
      Start := P;
      while not (CharInSet(P^, [#0, #10, #13])) do inc(P);
      SetString(S, Start, P - Start);
      AList.Add(S);
      if P^ = #13 then inc(P);
      if P^ = #10 then inc(P);
    end;
end;

class function TOldMusicNames.S_GetListFromAlias(const s: string): TStringList;
var
  stmp: string;
  i: integer;
begin
  result := TStringList.Create;
  if s <> '' then
  begin
    stmp := '';
    for i := 1 to Length(s) do
      if CharInSet(s[i], [' ', ',']) then
        stmp := stmp + #13#10
      else
        stmp := stmp + toupper(s[i]);
    SetTextStr(result, stmp);
    for i := result.count - 1 downto 0 do
      if result.strings[i] = '' then
        result.Delete(i);
  end;
end;

class function TOldMusicNames.FileNames(const mapname, name, alias: string;
  AHereticOrHexen: Boolean): TArray<string>;
var
  i: integer;
  aliases, externalmusicfilenames: TStringList;
begin
  externalmusicfilenames := TStringList.Create;
  try
    if mapname <> '' then
    begin
      externalmusicfilenames.Add(mapname + '.mp3');
      if AHereticOrHexen then
        externalmusicfilenames.Add('MUS_' + mapname + '.mp3')
      else
        externalmusicfilenames.Add('d_' + mapname + '.mp3');
    end;
    externalmusicfilenames.Add(name + '.mp3');
    if AHereticOrHexen then
      externalmusicfilenames.Add('MUS_' + name + '.mp3')
    else
    begin
      externalmusicfilenames.Add('d_' + name + '.mp3');

    // JVAL: Add aliases in check list
      aliases := S_GetListFromAlias(alias);
      for i := 0 to aliases.Count - 1 do
      begin
        externalmusicfilenames.Add(aliases.strings[i] + '.mp3');
        externalmusicfilenames.Add('d_' + aliases.strings[i] + '.mp3');
      end;
      aliases.Free;
    end;
    Result := externalmusicfilenames.ToStringArray;
  finally
    externalmusicfilenames.Free;
  end;
end;

end.
