{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the voxel files that become sprites             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.SpriteNames;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Voxel.Intf;

const
  /// <summary>The folder of the voxels in the file system of the game (a file without extension there is a KVX)</summary>
  VOXEL_SPRITE_FOLDER = 'VOXELS';
  /// <summary>The characters of a sprite name and its frame</summary>
  VOXEL_SPRITE_FRAME_LENGTH = 5;

type
  /// <summary>
  ///   The choice of the old VX_VoxelToSprite (vx_voxelsprite.pas) of the voxel files that become
  ///   sprites, without the file system and the WAD. The rules are the old ones, also where they
  ///   look odd: a file is not kept twice only if it has no extension (the old list compared the
  ///   name with the names and extensions it had kept), and a sprite is in the game if a lump of a
  ///   sprite section starts with its five characters, in capital letters as the lump has it.
  /// </summary>
  TVoxelSpriteNames = class(TInterfacedObject, IVoxelSpriteNames)
  strict private
    FLumps: IVoxelLumpNames;
    FEntries: TStringList;
    FSpriteLumps: TArray<string>;
    FSpriteLumpsRead: Boolean;
    class function NameBeforeDot(const AText: string): string; static;
    class function FixPathName(const APath: string): string; static;
    function IsKnownEntry(const AName: string): Boolean;
    function SpriteExistsInGame(const AName: string): Boolean;
    procedure ReadSpriteLumps;
  public
    constructor Create(const ALumps: IVoxelLumpNames);
    destructor Destroy; override;
    /// <summary>True if the extension (with the dot, in capital letters) is one of a voxel sprite</summary>
    class function IsVoxelExtension(const AExtension: string): Boolean; static;
    procedure AddFileName(const AFileName: string);
    function Count: Integer;
    function Entry(const AIndex: Integer): string;
    function SpriteName(const AIndex: Integer): string;
  end;

implementation

uses
  System.Generics.Collections;

const
  SPRITE_START_MARKERS: array[0..1] of string = ('S_START', 'SS_START');
  SPRITE_END_MARKERS: array[0..1] of string = ('S_END', 'SS_END');

{ TVoxelSpriteNames }

constructor TVoxelSpriteNames.Create(const ALumps: IVoxelLumpNames);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
  FEntries := TStringList.Create;
end;

destructor TVoxelSpriteNames.Destroy;
begin
  FEntries.Free;
  inherited;
end;

class function TVoxelSpriteNames.IsVoxelExtension(const AExtension: string): Boolean;
begin
  Result := (AExtension = '.DDVOX') or (AExtension = '.DDMESH') or (AExtension = '.KVX') or
    (AExtension = '.VOX');
end;

class function TVoxelSpriteNames.NameBeforeDot(const AText: string): string;
var
  LDot: Integer;
begin
  LDot := Pos('.', AText);
  if LDot > 0 then
    Result := Copy(AText, 1, LDot - 1)
  else
    Result := AText;
end;

class function TVoxelSpriteNames.FixPathName(const APath: string): string;
var
  LIndex: Integer;
  LChar, LLast: Char;
begin
  // the old fixpathname of d_delphi: / is \ and two \ in a row are one
  Result := '';
  LLast := #0;
  for LIndex := 1 to Length(APath) do
  begin
    LChar := APath[LIndex];
    if LChar = '/' then
      LChar := '\';
    if (LLast <> '\') or (LChar <> '\') then
      Result := Result + LChar;
    LLast := LChar;
  end;
end;

function TVoxelSpriteNames.IsKnownEntry(const AName: string): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FEntries.Count - 1 do
    if AnsiCompareText(FEntries[LIndex], AName) = 0 then
      Exit(True);
  Result := False;
end;

procedure TVoxelSpriteNames.ReadSpriteLumps;
var
  LIndex: Integer;
  LName: string;
  LInSection: Boolean;
  LList: TList<string>;
begin
  // the directory does not change while the files are looked at: one pass is enough
  FSpriteLumpsRead := True;
  LList := TList<string>.Create;
  try
    LInSection := False;
    for LIndex := 0 to FLumps.LumpCount - 1 do
    begin
      LName := FLumps.LumpName(LIndex);
      if (LName = SPRITE_START_MARKERS[0]) or (LName = SPRITE_START_MARKERS[1]) then
        LInSection := True
      else if (LName = SPRITE_END_MARKERS[0]) or (LName = SPRITE_END_MARKERS[1]) then
        LInSection := False
      else if LInSection and (Length(LName) >= VOXEL_SPRITE_FRAME_LENGTH) then
        LList.Add(Copy(LName, 1, VOXEL_SPRITE_FRAME_LENGTH));
    end;
    FSpriteLumps := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TVoxelSpriteNames.SpriteExistsInGame(const AName: string): Boolean;
var
  LPrefix: string;
  LLump: string;
begin
  if not FSpriteLumpsRead then
    ReadSpriteLumps;
  LPrefix := Copy(AName, 1, VOXEL_SPRITE_FRAME_LENGTH);
  for LLump in FSpriteLumps do
    if LLump = LPrefix then
      Exit(True);
  Result := False;
end;

procedure TVoxelSpriteNames.AddFileName(const AFileName: string);
var
  LUpper: string;
  LExtension: string;
  LName: string;
begin
  LUpper := UpperCase(AFileName);
  LExtension := ExtractFileExt(LUpper);
  if not (IsVoxelExtension(LExtension) or ((LExtension = '') and
    (Pos(VOXEL_SPRITE_FOLDER + '\', FixPathName(LUpper)) > 0))) then
    Exit;

  LName := NameBeforeDot(ExtractFileName(LUpper));
  if (Length(LName) <> VOXEL_SPRITE_FRAME_LENGTH) and
    not ((Length(LName) = VOXEL_SPRITE_FRAME_LENGTH + 1) and (LName[VOXEL_SPRITE_FRAME_LENGTH + 1] = '0')) then
    Exit;

  if IsKnownEntry(LName) or SpriteExistsInGame(LName) then
    Exit;

  FEntries.Add(LName + LExtension);
end;

function TVoxelSpriteNames.Count: Integer;
begin
  Result := FEntries.Count;
end;

function TVoxelSpriteNames.Entry(const AIndex: Integer): string;
begin
  Result := FEntries[AIndex];
end;

function TVoxelSpriteNames.SpriteName(const AIndex: Integer): string;
begin
  Result := NameBeforeDot(FEntries[AIndex]);
  if Length(Result) = VOXEL_SPRITE_FRAME_LENGTH then
    Result := Result + '0';
end;

end.
