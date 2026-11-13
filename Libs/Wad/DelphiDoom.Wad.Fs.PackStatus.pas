{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: pak pureness            }
{                                                                              }
{  Port of GetPackStatus and of the pure exclusions of framework\FileSystem.cpp }
{  (id Software, GPL v3). Copyright (C) 1999-2011 id Software LLC, a ZeniMax   }
{  Media company.                                                              }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.PackStatus;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   Tells how a pak counts for a pure server: PURE_NEVER when every file in it is one that a pure server
  ///   does not care about (the exclusion table of the original: folders, .pda, .gui, .pd, .lang, voice over,
  ///   fonts and a few files that shipped in the wrong place), PURE_ALWAYS for a pak whose file name starts with
  ///   "pak", PURE_NEUTRAL for the others. The result is not cached here (the pure server does it).
  /// </summary>
  TGamePackStatus = class sealed
  public
    /// <summary>
    ///   One of the exclusions: a file name (lower case, '/' as separator) that does not make a pak pure. The
    ///   names are compared without case and with '\' and '/' alike, as <c>Icmp</c> and <c>IcmpPrefixPath</c> do
    /// </summary>
    class function IsExcluded(const AName: string): Boolean; static;
    /// <summary>GetPackStatus without the cache; a pak with no files is PURE_NEVER</summary>
    class function Classify(const APack: IGamePack): TGamePureStatus; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

type
  TExclusionKind = (Extension, PathPrefixAndExtension, FullName);

  TExclusion = record
    Kind: TExclusionKind;
    Name: AnsiString;
    Extension: AnsiString;
  end;

const
  // pureExclusions[] with DOOM3_PURE_SPECIAL_CASES defined
  EXCLUSIONS: array[0..22] of TExclusion = (
    (Kind: TExclusionKind.Extension; Name: ''; Extension: '/'),
    (Kind: TExclusionKind.Extension; Name: ''; Extension: '\'),
    (Kind: TExclusionKind.Extension; Name: ''; Extension: '.pda'),
    (Kind: TExclusionKind.Extension; Name: ''; Extension: '.gui'),
    (Kind: TExclusionKind.Extension; Name: ''; Extension: '.pd'),
    (Kind: TExclusionKind.Extension; Name: ''; Extension: '.lang'),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'sound/VO'; Extension: '.ogg'),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'sound/VO'; Extension: '.wav'),
    (Kind: TExclusionKind.FullName; Name: 'sound/ed/marscity/vo_intro_cutscene.ogg'; Extension: ''),
    (Kind: TExclusionKind.FullName; Name: 'sound/weapons/soulcube/energize_01.ogg'; Extension: ''),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'sound/xian/creepy/vocal_fx'; Extension: '.ogg'),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'sound/xian/creepy/vocal_fx'; Extension: '.wav'),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'sound/feedback'; Extension: '.ogg'),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'sound/feedback'; Extension: '.wav'),
    (Kind: TExclusionKind.FullName; Name: 'guis/assets/mainmenu/chnote.tga'; Extension: ''),
    (Kind: TExclusionKind.FullName; Name: 'sound/levels/alphalabs2/uac_better_place.ogg'; Extension: ''),
    (Kind: TExclusionKind.FullName; Name: 'textures/bigchars.tga'; Extension: ''),
    (Kind: TExclusionKind.FullName; Name: 'dds/textures/bigchars.dds'; Extension: ''),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'fonts'; Extension: '.tga'),
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'dds/fonts'; Extension: '.dds'),
    (Kind: TExclusionKind.FullName; Name: 'default.cfg'; Extension: ''),
    // russian zpak001.pk4
    (Kind: TExclusionKind.PathPrefixAndExtension; Name: 'fonts'; Extension: '.dat'),
    (Kind: TExclusionKind.FullName; Name: 'guis/temp.guied'; Extension: '')
  );

function ExtensionMatches(const AName, AExtension: AnsiString): Boolean;
var
  LLength: Integer;
begin
  LLength := Length(AName);
  // l > extLen
  Result := (LLength > Length(AExtension)) and
    (TIdStrings.Icmp(Copy(AName, LLength - Length(AExtension) + 1, MaxInt), AExtension) = 0);
end;

{ TGamePackStatus }

class function TGamePackStatus.IsExcluded(const AName: string): Boolean;
var
  LIndex: Integer;
  LName: AnsiString;
begin
  LName := AnsiString(AName);
  for LIndex := Low(EXCLUSIONS) to High(EXCLUSIONS) do
    case EXCLUSIONS[LIndex].Kind of
      TExclusionKind.Extension:
        if ExtensionMatches(LName, EXCLUSIONS[LIndex].Extension) then
          Exit(True);
      TExclusionKind.PathPrefixAndExtension:
        if (Length(LName) > Length(EXCLUSIONS[LIndex].Name)) and
          ExtensionMatches(LName, EXCLUSIONS[LIndex].Extension) and
          (TIdStrings.IcmpnPath(LName, EXCLUSIONS[LIndex].Name, Length(EXCLUSIONS[LIndex].Name)) = 0) then
          Exit(True);
      TExclusionKind.FullName:
        if (Length(LName) = Length(EXCLUSIONS[LIndex].Name)) and
          (TIdStrings.Icmp(LName, EXCLUSIONS[LIndex].Name) = 0) then
          Exit(True);
    end;
  Result := False;
end;

class function TGamePackStatus.Classify(const APack: IGamePack): TGamePureStatus;
var
  LIndex: Integer;
  LFileName: string;
begin
  // check content for PURE_NEVER: every file is one that does not count
  Result := TGamePureStatus.Never;
  for LIndex := 0 to APack.EntryCount - 1 do
    if not IsExcluded(APack.EntryName(LIndex)) then
    begin
      Result := TGamePureStatus.Neutral;
      Break;
    end;
  if Result = TGamePureStatus.Never then
    Exit;
  // check the pak name for PURE_ALWAYS
  LFileName := ExtractFileName(StringReplace(APack.FileName, '/', '\', [rfReplaceAll]));
  if TIdStrings.IcmpnPath(AnsiString(LFileName), 'pak', 3) = 0 then
    Result := TGamePureStatus.Always;
end;

end.
