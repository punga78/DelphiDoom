{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - the names of songs and PK3 sounds as they were before    }
{  TMusicNumberResolver and TPk3SoundNames                                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.OldSoundTables;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Copy of S_GetMusicNumForName of Base\sounds.pas and of S_AddFileName of
  ///   Base\s_pk3sounds.pas at 107c7c4b4 (issue #243), on tables and lumps that the test
  ///   fills (the globals and W_CheckNumForName of the engine), with the helpers of d_delphi
  ///   that they used (atoi, itoa, strupper, Pos1, CharPos, firstword_ch, fext, fname) copied
  ///   as they were
  /// </summary>
  TOldSoundTables = class(TObject)
  private
    class function itoa(i: Integer): string; static;
    class function strupper(const S: string): string; static;
    class function Pos1(const subs, s: string): Boolean; static;
    class function CharPos(const ch: Char; const s: string): Integer; static;
    class function atoi(const s: string; const default: Integer): Integer; static;
    class function firstword_ch(const inp: string; const splitter: Char): string; static;
    procedure I_Warning(const warning: string; const Args: array of const); overload;
    procedure I_Warning(const warning: string); overload;
  public
    MusicNames: array of string;
    MusicLumps: array of Integer;
    nummusic: Integer;
    MAX_MUS: Integer;
    LumpNames: TStringList;
    Warnings: TStringList;
    constructor Create(AMaxMusic: Integer);
    destructor Destroy; override;
    function W_CheckNumForName(const AName: string): Integer;
    function S_GetMusicNumForName(const mus_name: string): Integer;
    procedure S_AddFileName(const filename: string; s_names: TStringList);
  end;

implementation

{ TOldSoundTables }

constructor TOldSoundTables.Create(AMaxMusic: Integer);
begin
  inherited Create;
  MAX_MUS := AMaxMusic;
  SetLength(MusicNames, AMaxMusic);
  SetLength(MusicLumps, AMaxMusic);
  LumpNames := TStringList.Create;
  Warnings := TStringList.Create;
end;

destructor TOldSoundTables.Destroy;
begin
  LumpNames.Free;
  Warnings.Free;
  inherited Destroy;
end;

class function TOldSoundTables.itoa(i: Integer): string;
begin
  Result := Format('%d', [i]);
end;

class function TOldSoundTables.strupper(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then
      Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

class function TOldSoundTables.Pos1(const subs, s: string): Boolean;
var
  len1: Integer;
begin
  len1 := Length(subs);
  if Length(s) < len1 then
  begin
    Result := False;
    Exit;
  end;
  Result := CompareMem(PChar(subs), PChar(s), len1 * SizeOf(Char));
end;

class function TOldSoundTables.CharPos(const ch: Char; const s: string): Integer;
var
  i: Integer;
begin
  for i := 1 to Length(s) do
    if s[i] = ch then
    begin
      Result := i;
      Exit;
    end;
  Result := 0;
end;

class function TOldSoundTables.atoi(const s: string; const default: Integer): Integer;
var
  code: Integer;
  ret2: Integer;
begin
  val(s, Result, code);
  if code <> 0 then
  begin
    ret2 := default;
    if Pos1('0x', s) then
      val('$' + Copy(s, 3, Length(s) - 2), ret2, code)
    else if Pos1('-0x', s) then
    begin
      val('$' + Copy(s, 4, Length(s) - 3), ret2, code);
      ret2 := -ret2;
    end
    else if CharPos('#', s) = 1 then
      val(Copy(s, 2, Length(s) - 1), ret2, code);
    if code = 0 then
      Result := ret2
    else
      Result := default;
  end;
end;

class function TOldSoundTables.firstword_ch(const inp: string; const splitter: Char): string;
var
  p, len: Integer;
begin
  p := 1;
  len := Length(inp);
  SetLength(Result, len);
  while p <= len do
  begin
    if inp[p] = splitter then
      Break;
    Result[p] := inp[p];
    Inc(p);
  end;
  SetLength(Result, p - 1);
end;

procedure TOldSoundTables.I_Warning(const warning: string; const Args: array of const);
begin
  I_Warning(Format(warning, Args));
end;

procedure TOldSoundTables.I_Warning(const warning: string);
begin
  Warnings.Add(warning);
end;

function TOldSoundTables.W_CheckNumForName(const AName: string): Integer;
begin
  Result := LumpNames.IndexOf(AName);
end;

function TOldSoundTables.S_GetMusicNumForName(const mus_name: string): Integer;
var
  i: Integer;
  name: string;
  check: string;
begin
  result := atoi(mus_name, -1);
  if (result >= 0) and (result < nummusic) and (itoa(result) = mus_name) then
    exit;

  if mus_name = '' then
  begin
    I_Warning('S_GetMusicNumForName(): No music name specified, using default'#13#10);
    result := 0;
    exit;
  end;

  name := strupper(mus_name);
  for i := 1 to nummusic - 1 do
  begin
    check := strupper(MusicNames[i]);
    if (check = name) or ('D_' + check = name) then
    begin
      result := i;
      exit;
    end;
  end;

  // JVAL: Not found, we will add a new sound

  if nummusic >= MAX_MUS - 1 then // JVAL: Limit exceeded, we will use default music :(
  begin
    I_Warning('S_GetMusicNumForName(): Can not add "%s" music, limit of %d music lumps exceeded'#13#10, [mus_name, nummusic]);
    result := 0;
    exit;
  end;

  // JVAL: Register the new music

  if Pos1('D_', name) then
    name := Copy(name, 3, Length(name) - 2);
  if name = '' then // JVAL: Normally this should not happen!
  begin
    I_Warning('S_GetMusicNumForName(): No sound name specified, using default'#13#10);
    result := 0;
    exit;
  end;

  result := nummusic;
  MusicNames[result] := name;
  MusicLumps[result] := W_CheckNumForName('D_' + name);
  if MusicLumps[result] < 0 then
    MusicLumps[result] := W_CheckNumForName(name);
  inc(nummusic);
end;

procedure TOldSoundTables.S_AddFileName(const filename: string; s_names: TStringList);
var
  check: string;
  name: string;
  ext: string;
  doadd: Boolean;
begin
  check := strupper(filename);
  ext := ExtractFileExt(check);
  if (ext = '.WAV') or (ext = '.OGG') or (ext = '.FLAC') or (ext = '.OGA') or
    (ext = '.AU') or (ext = '.VOC') or (ext = '.SND') then
  begin
    check := ExtractFileName(check);
    name := firstword_ch(check, '.');
    if Length(name) > 2 then
      if Pos1('DS', name) then
        Delete(name, 1, 2);
    if Length(name) <= 8 then
      if s_names.IndexOf(name) < 0 then
      begin
        doadd := true;
        if W_CheckNumForName(name) >= 0 then
          doadd := false
        else if Length(name) <= 6 then
        begin
          name := 'DS' + name;
          if W_CheckNumForName(name) >= 0 then
            doadd := false;
        end;
        if doadd then
          if s_names.IndexOf(name) < 0 then
            s_names.Add(name);
      end;
  end;
end;

end.
