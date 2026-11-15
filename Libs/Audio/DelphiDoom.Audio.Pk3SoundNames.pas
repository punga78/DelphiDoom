{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the sounds of a PK3 that have no lump            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Pk3SoundNames;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Audio.Sound.Intf;

type
  /// <summary>
  ///   S_AddFileName of s_pk3sounds.pas: from the names of the files of the PK3 it keeps the
  ///   lump names of the sounds that no loaded file has (with or without the "DS" prefix),
  ///   each one once and in the order in which they come; the engine adds a stub lump for
  ///   each of them
  /// </summary>
  TPk3SoundNames = class
  strict private
    FFinder: TSoundLumpFinder;
    FNames: TList<string>;
  public
    /// <summary>EArgumentNilException if AFinder is missing</summary>
    constructor Create(const AFinder: TSoundLumpFinder);
    destructor Destroy; override;
    /// <summary>
    ///   A file of the PK3: only the sound files (.WAV .OGG .FLAC .OGA .AU .VOC .SND) count;
    ///   the lump name is the file name up to the first dot, without "DS", if it has at most 8 characters
    /// </summary>
    procedure AddFile(const AFileName: string);
    /// <summary>The lump names kept so far</summary>
    function Names: TArray<string>;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Audio.SoundNames;

{ TPk3SoundNames }

constructor TPk3SoundNames.Create(const AFinder: TSoundLumpFinder);
begin
  inherited Create;
  if not Assigned(AFinder) then
    raise EArgumentNilException.Create('AFinder');
  FFinder := AFinder;
  FNames := TList<string>.Create;
end;

destructor TPk3SoundNames.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

procedure TPk3SoundNames.AddFile(const AFileName: string);
var
  LCheck: string;
  LName: string;
  LExtension: string;
  LDot: Integer;
  LAdd: Boolean;
begin
  LCheck := TSoundNames.Upper(AFileName);
  LExtension := ExtractFileExt(LCheck);
  if (LExtension <> '.WAV') and (LExtension <> '.OGG') and (LExtension <> '.FLAC') and
    (LExtension <> '.OGA') and (LExtension <> '.AU') and (LExtension <> '.VOC') and
    (LExtension <> '.SND') then
    Exit;

  LCheck := ExtractFileName(LCheck);
  LDot := Pos('.', LCheck);
  if LDot = 0 then
    LName := LCheck
  else
    LName := Copy(LCheck, 1, LDot - 1);
  if (Length(LName) > 2) and TSoundNames.HasPrefix('DS', LName) then
    Delete(LName, 1, 2);
  if (Length(LName) > 8) or (FNames.IndexOf(LName) >= 0) then
    Exit;

  LAdd := True;
  if FFinder(LName) >= 0 then
    LAdd := False
  else if Length(LName) <= 6 then
  begin
    LName := 'DS' + LName;
    if FFinder(LName) >= 0 then
      LAdd := False;
  end;
  // 'pistol.wav' and 'pistol.ogg' give the same lump: once is enough (the list keeps
  // the name with the 'DS' prefix, so the first test did not see it)
  if LAdd and (FNames.IndexOf(LName) < 0) then
    FNames.Add(LName);
end;

function TPk3SoundNames.Names: TArray<string>;
begin
  Result := FNames.ToArray;
end;

end.
