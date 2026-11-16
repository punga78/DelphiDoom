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
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  /// <summary>The games of the {$IFDEF} of S_GetSoundNumForName (Radix and Speed are Doom)</summary>
  TOldSoundGame = (osgDoom, osgHeretic, osgHexen, osgStrife);

  PSfxRecord = ^TSfxRecord;

  /// <summary>
  ///   The fields of the sfxinfo_t of the four games together: the writes of the old code
  ///   that a game does not have are simply not made for it
  /// </summary>
  TSfxRecord = record
    Name: string;
    TagName: string;
    Singularity: Boolean;
    Priority: Integer;
    HasLink: Boolean;
    Pitch: Integer;
    Volume: Integer;
    HasData: Boolean;
    Usefulness: Integer;
    LumpNum: Integer;
    NumChannels: Integer;
    ChangePitch: Boolean;
    RandomList: TList<Integer>;
  end;

  /// <summary>
  ///   Copy of S_GetMusicNumForName of IdTech1\Base\sounds.pas and of S_AddFileName of
  ///   IdTech1\Base\s_pk3sounds.pas at 107c7c4b4 (issue #243), on tables and lumps that the test
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
    function IntToStrZfill(const z: Integer; const x: Integer): string;
    function S_SoundAlias(const snd: string): string;
  public
    // the sounds: table, game and the aliases of SNDINFO
    Sfxs: array of TSfxRecord;
    numsfx: Integer;
    MAX_NUMSFX: Integer;
    Game: TOldSoundGame;
    DefaultSfx: Integer;
    lastfreesfx: Integer;
    Aliases: TStringList;
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
    /// <summary>The sounds table, with its game, size and default sound</summary>
    procedure InitSounds(AGame: TOldSoundGame; AMaxSounds, AUsed, ADefault: Integer);
    /// <summary>The alias of a name (what sounds.pas asked of the sound aliases of SNDINFO)</summary>
    function Resolve(const snd: string): string;
    function S_GetSoundNumForName(const sfx_name: string): Integer;
    function S_GetSoundNameForNum(const sfx_num: Integer): string;
    function S_GetRandomSoundList(const sfx_num: Integer): TList<Integer>;
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
  Aliases := TStringList.Create;
end;

procedure TOldSoundTables.InitSounds(AGame: TOldSoundGame; AMaxSounds, AUsed, ADefault: Integer);
var
  LIndex: Integer;
begin
  Game := AGame;
  MAX_NUMSFX := AMaxSounds;
  numsfx := AUsed;
  DefaultSfx := ADefault;
  lastfreesfx := 1;
  SetLength(Sfxs, AMaxSounds);
  for LIndex := 0 to AUsed - 1 do
  begin
    Sfxs[LIndex].Name := Format('snd%d', [LIndex]);
    Sfxs[LIndex].LumpNum := LIndex;
    Sfxs[LIndex].Priority := 64;
    // a few empty slots for the games that look for them, the DEHEXTRA names of Doom
    if (AGame = osgDoom) and (LIndex mod 7 = 5) then
      Sfxs[LIndex].Name := '';
  end;
end;

function TOldSoundTables.IntToStrZfill(const z: Integer; const x: Integer): string;
var
  i: Integer;
  len: Integer;
begin
  result := itoa(x);
  len := Length(result);
  for i := len + 1 to z do
    result := '0' + result;
end;

// the aliases of SNDINFO: the test gives lines name=value, a name without one is its own alias
function TOldSoundTables.S_SoundAlias(const snd: string): string;
var
  LIndex: Integer;
begin
  LIndex := Aliases.IndexOfName(snd);
  if LIndex >= 0 then
    Result := Aliases.ValueFromIndex[LIndex]
  else
    Result := snd;
end;

destructor TOldSoundTables.Destroy;
begin
  LumpNames.Free;
  Warnings.Free;
  Aliases.Free;
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

function TOldSoundTables.Resolve(const snd: string): string;
begin
  Result := S_SoundAlias(snd);
end;

function TOldSoundTables.S_GetSoundNumForName(const sfx_name: string): Integer;
var
  i: Integer;
  name: string;
  check: string;
  sfx: PSfxRecord;
  isnumber: Boolean;

  procedure ResetSfx(ASfx: PSfxRecord);
  begin
    ASfx.Singularity := False;
    ASfx.Priority := 72;
    ASfx.HasLink := False;
    ASfx.Pitch := -1;
    ASfx.Volume := -1;
    ASfx.HasData := False;
    ASfx.Usefulness := 0;
    ASfx.LumpNum := -1;
    ASfx.RandomList := nil;
  end;

  function DefaultResult: Integer;
  begin
    Result := DefaultSfx;
  end;

begin
  result := atoi(sfx_name, -1);
  if Game = osgDoom then
  begin
    isnumber := itoa(result) = sfx_name;
    if isnumber then
    begin
      if (result >= 0) and (result < numsfx) and isnumber then
        if Sfxs[result].Name <> '' then
          exit;

      if (result >= 500) and (result < 700) then
        if Sfxs[result].Name = 'fre' + IntToStrZfill(3, result) then // DEHEXTRA
        begin
          if numsfx <= result then
            numsfx := result + 1;
          sfx := @Sfxs[result];
          sfx.Name := 'fre' + IntToStrZfill(3, result);
          ResetSfx(sfx);
          exit;
        end;
    end;
  end
  else
  begin
    if (result >= 0) and (result < numsfx) and (itoa(result) = sfx_name) then
      exit;
  end;

  if sfx_name = '' then
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
    result := DefaultResult;
    exit;
  end;

  name := strupper(S_SoundAlias(sfx_name));
  for i := 1 to numsfx - 1 do
  begin
    if Game = osgHexen then
    begin
      sfx := @Sfxs[i];
      if (strupper(sfx.TagName) = name) or (strupper(sfx.Name) = name) or ('DS' + strupper(sfx.Name) = name) then
      begin
        result := i;
        exit;
      end;
    end
    else
    begin
      check := strupper(Sfxs[i].Name);
      if (check = name) or ('DS' + check = name) then
      begin
        result := i;
        exit;
      end;
    end;
  end;

  if Game = osgDoom then
  begin
    // JVAL: Not found, trying to find an empty slot
    for i := lastfreesfx to numsfx - 1 do
      if Sfxs[i].Name = '' then
      begin
        result := i;
        lastfreesfx := i + 1;
        sfx := @Sfxs[result];
        sfx.Name := name;
        ResetSfx(sfx);
        exit;
      end;
  end;

  if numsfx >= MAX_NUMSFX - 1 then // JVAL: Limit exceeded, we will use default pistol sound :(
  begin
    I_Warning('S_GetSoundNumForName(): Can not add %s sound, limit of %d sounds exceeded'#13#10, [sfx_name, numsfx]);
    result := DefaultResult;
    exit;
  end;

  // JVAL: Register the new sound

  if Pos1('DS', name) then
    name := Copy(name, 3, Length(name) - 2);
  if name = '' then // JVAL: Normally this should not happen!
  begin
    I_Warning('S_GetSoundNumForName(): No sound name specified, using default'#13#10);
    result := DefaultResult;
    exit;
  end;

  result := numsfx;
  sfx := @Sfxs[result];
  if Game = osgHexen then
    sfx.TagName := sfx_name;
  sfx.Name := name;
  if Game <> osgHexen then
    sfx.Singularity := false;
  sfx.Priority := 72;
  if Game <> osgHexen then
    sfx.HasLink := false;
  sfx.Pitch := -1;
  if Game <> osgHexen then
    sfx.Volume := -1;
  sfx.HasData := false;
  sfx.Usefulness := 0;
  sfx.LumpNum := -1; // JVAL: was = 0;
  if Game = osgHexen then
  begin
    sfx.NumChannels := 1;
    sfx.ChangePitch := false;
  end;
  sfx.RandomList := nil;
  inc(numsfx);
end;

function TOldSoundTables.S_GetSoundNameForNum(const sfx_num: Integer): string;
begin
  if (sfx_num < 0) or (sfx_num >= numsfx) then
  begin
    result := '';
    exit;
  end;

  // JVAL: strupper -> for safety
  result := strupper(Sfxs[sfx_num].Name);
end;

function TOldSoundTables.S_GetRandomSoundList(const sfx_num: Integer): TList<Integer>;
var
  sfxname: string;
  sfxname1: string;
  sfxname2: string;
  sfxname3: string;
  sfxnum: Integer;
  check: Integer;
  c: Char;
begin
  sfxname := S_GetSoundNameForNum(sfx_num);
  if sfxname = '' then
  begin
    result := nil;
    exit;
  end;

  if Sfxs[sfx_num].RandomList = nil then
    Sfxs[sfx_num].RandomList := TList<Integer>.Create;

  result := Sfxs[sfx_num].RandomList;

  if result.Count > 0 then
    exit;

  check := Ord(sfxname[Length(sfxname)]);
  if (check < Ord('0')) or (check > Ord('9')) then
  begin
    result.Add(sfx_num);  // This sound for sure!
    exit;
  end;

  // JVAL: look first for 'ds....' sound names
  if Pos1('DS', sfxname) then
  begin
    sfxname1 := sfxname;
    sfxname2 := Copy(sfxname, 3, Length(sfxname) - 2)
  end
  else
  begin
    sfxname1 := 'DS' + sfxname;
    sfxname2 := sfxname;
  end;
  sfxname3 := '';
  if Length(sfxname1) > 8 then
    SetLength(sfxname1, 8);
  if Length(sfxname2) > 8 then
    SetLength(sfxname2, 8);
  for c := '0' to '9' do
  begin
    sfxname1[Length(sfxname1)] := c;
    check := W_CheckNumForName(sfxname1);
    if check = -1 then
    begin
      sfxname2[Length(sfxname2)] := c;
      check := W_CheckNumForName(sfxname2);
      if check >= 0 then
        sfxname3 := sfxname2;
    end
    else
      sfxname3 := sfxname1;

    if check >= 0 then
    begin
      sfxnum := S_GetSoundNumForName(sfxname3);
      result.Add(sfxnum);
      Sfxs[sfxnum].LumpNum := check; // Save the lump number
      if Sfxs[sfxnum].RandomList = nil then
        Sfxs[sfxnum].RandomList := result;
    end;
  end;
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
