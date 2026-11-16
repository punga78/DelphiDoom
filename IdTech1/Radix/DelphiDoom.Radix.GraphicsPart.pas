{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixGraphicsPart                              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateMainGraphics, GenerateAdditionalGraphics and the helpers    }
{  GenerateGraphicWith(Out)Palette of radix_xlat_wad.pas                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.GraphicsPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Context;

type
  /// <summary>
  ///   The pictures of the menus, the status bar and the screens: some are stored with the palette
  ///   of their own (they are matched to the palette of the game), some without. The names of the
  ///   lumps of the WAD are HELPnn, TITLEPIC, M_RADIX, M_BRIEF, RADIXnnn and OBJnnPRI/SEC; the PK3
  ///   entry says which picture is which
  /// </summary>
  TRadixGraphicsPart = class(TInterfacedObject, IRadixPart)
  strict private
    FPatchId: Integer;
    function AddWithoutPalette(const AContext: TRadixTranslationContext; const ARadixName,
      AWadName: string; ASolid: Boolean; AOpaqueIndex: Integer): Boolean;
    function AddWithPalette(const AContext: TRadixTranslationContext; const ARadixName,
      AWadName: string; ASolid: Boolean): Boolean;
    function AddOpaque(const AContext: TRadixTranslationContext; const ARadixName,
      AWadName: string; ABackground: Integer): Boolean;
    procedure AddNumbered(const AContext: TRadixTranslationContext; const ARadixName: string);
    procedure AddWeaponNumbers(const AContext: TRadixTranslationContext; const ALumpName: string);
    procedure BuildMain(const AContext: TRadixTranslationContext);
    procedure BuildAdditional(const AContext: TRadixTranslationContext);
    class function Word16(const ABytes: TBytes; AOffset: Integer): Integer; static;
  public
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.Container;

const
  WithPalette: array[0..37] of string = (
    'SelectSkill', 'SkillButton1', 'SkillButton2', 'SkillButton3', 'SkillButton4',
    'PlayerNameBox', 'SelectEpisode', 'EpisodeButton1', 'EpisodeButton2', 'EpisodeButton3',
    'SkillPicture1', 'SkillPicture2', 'SkillPicture3', 'SkillPicture4', 'TopTenScreen',
    'NetworkMenu', 'NetworkMenuOverlay', 'StatsScreen', 'DebriefScreen1', 'DebriefScreen2',
    'DebriefScreen3', 'NetDebriefScreen', 'NetFlag', 'StartLogo', 'MainMenu',
    'MainMenuButton1', 'MainMenuButton2', 'MainMenuButton3', 'MainMenuButton4',
    'MainMenuButton5', 'MainMenuButton6', 'MainMenuButton7', 'MainMenuButton8', 'OptionMenu',
    'Option1', 'Option2', 'Option3', 'NeuralLogo');

type
  TRadixPlainPicture = record
    Name: string;
    // the index that is turned to a hole, -1 for none
    OpaqueIndex: Integer;
  end;

function Plain(const AName: string; AOpaqueIndex: Integer = -1): TRadixPlainPicture;
begin
  Result.Name := AName;
  Result.OpaqueIndex := AOpaqueIndex;
end;

function PlainPictures: TArray<TRadixPlainPicture>;
begin
  Result := [
    Plain('ArmourBar'), Plain('BackViewOn', 0), Plain('CockpitNumOn', 0),
    Plain('CockpitNumUse', 0), Plain('CockPitRadar'), Plain('CrossHair', 0),
    Plain('CrossLock1', 0), Plain('CrossLock2', 0), Plain('CrossLock3', 0),
    Plain('CrossLock4', 0), Plain('CrossLock5', 0), Plain('CrossLock6', 0),
    Plain('EnergyBar'), Plain('EnhancedEPCWeaponPicture'), Plain('HelpScreen'),
    Plain('HelpScreen2'), Plain('LeftArrow', 0), Plain('MissionBack'), Plain('MissionBegin'),
    Plain('MissionForward'), Plain('MissionLoad'), Plain('MissionPause'), Plain('MissionQuit'),
    Plain('MissionReverse'), Plain('MissionSave'), Plain('MissionScreen'),
    Plain('MissionStats'), Plain('NetworkChatScreen'), Plain('PlasmaIcon', 0),
    Plain('PowerUpIcon[1]', 0), Plain('PowerUpIcon[2]', 0), Plain('PowerUpIcon[3]', 0),
    Plain('PowerUpIcon[4]', 0), Plain('PowerUpIcon[5]', 0), Plain('RadarOverlay'),
    Plain('RightArrow', 0), Plain('SaveLoadScreen'), Plain('ShieldBar'),
    Plain('SmallCrossHair', 0), Plain('SmallCrossLock', 0), Plain('StatAmmo1'),
    Plain('StatAmmo2'), Plain('StatAmmo3'), Plain('StatAmmo4'), Plain('StatAmmo5'),
    Plain('StatAmmo6'), Plain('StatAmmo7'), Plain('StatAmmo8'), Plain('StatusBarFlag'),
    Plain('StatusBarImage'), Plain('StatusBarKill'), Plain('SuperEPCWeaponPicture'),
    Plain('ThreatOffMap'), Plain('ThreatOnMap'), Plain('TileBitmap'), Plain('Weapon1Image'),
    Plain('Weapon2Image'), Plain('Weapon3Image'), Plain('Weapon4Image'), Plain('Weapon5Image'),
    Plain('Weapon6Image'), Plain('Weapon7Image'), Plain('WeaponNumOff'), Plain('WeaponNumOn'),
    Plain('WeaponNumUse')];
end;

{ TRadixGraphicsPart }

class function TRadixGraphicsPart.Word16(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := SmallInt(ABytes[AOffset] or (ABytes[AOffset + 1] shl 8));
end;

function TRadixGraphicsPart.AddWithoutPalette(const AContext: TRadixTranslationContext;
  const ARadixName, AWadName: string; ASolid: Boolean; AOpaqueIndex: Integer): Boolean;
var
  LLump: TBytes;
  LImage: TBytes;
  LWidth: Integer;
  LHeight: Integer;
  LIndex: Integer;
begin
  Result := AContext.Container.TryRead(ARadixName, LLump);
  if not Result then
    Exit;
  LWidth := Word16(LLump, 0);
  LHeight := Word16(LLump, 2);
  LImage := Copy(LLump, 4, Length(LLump) - 4);
  if (not ASolid) and (AOpaqueIndex >= 0) then
    for LIndex := 0 to High(LImage) do
      if LImage[LIndex] = AOpaqueIndex then
        LImage[LIndex] := 254
      else if LImage[LIndex] = 254 then
        LImage[LIndex] := 252;
  AContext.Wad.AddLump(AWadName, AContext.Patches.FromRows(LImage, LWidth, LHeight, ASolid));
end;

function TRadixGraphicsPart.AddWithPalette(const AContext: TRadixTranslationContext;
  const ARadixName, AWadName: string; ASolid: Boolean): Boolean;
var
  LLump: TBytes;
begin
  Result := AContext.Container.TryRead(ARadixName, LLump);
  if not Result then
    Exit;
  // width and height, then the palette at 32 and the pixels at 800
  AContext.Wad.AddLump(AWadName, AContext.Patches.FromPalettedRows(
    Copy(LLump, 800, Length(LLump) - 800), Word16(LLump, 2), Word16(LLump, 4),
    Copy(LLump, 32, 768), ASolid, AContext.PaletteColors));
end;

function TRadixGraphicsPart.AddOpaque(const AContext: TRadixTranslationContext;
  const ARadixName, AWadName: string; ABackground: Integer): Boolean;
var
  LLump: TBytes;
begin
  Result := AContext.Container.TryRead(ARadixName, LLump);
  if not Result then
    Exit;
  AContext.Wad.AddLump(AWadName, AContext.Patches.FromPalettedRowsWithBackground(
    Copy(LLump, 800, Length(LLump) - 800), Word16(LLump, 2), Word16(LLump, 4),
    Copy(LLump, 32, 768), ABackground, AContext.PaletteColors));
end;

procedure TRadixGraphicsPart.BuildMain(const AContext: TRadixTranslationContext);
var
  LIndex: Integer;
  LName: string;
  LLump: Integer;
  LEntry: TRadixPakEntry;
begin
  for LIndex := 1 to 99 do
  begin
    LName := 'HELP' + Format('%.2d', [LIndex]);
    if not AddWithoutPalette(AContext, 'OrderInfo[' + IntToStr(LIndex) + ']', LName, True, -1) then
      Break;
    AContext.AddAlias(LName, 'OrderInfo[' + IntToStr(LIndex) + ']');
  end;

  AddWithPalette(AContext, 'MainTitle', 'TITLEPIC', True);
  LLump := AContext.Container.IndexOf('MainTitle');
  if LLump >= 0 then
  begin
    LEntry.Position := AContext.Container.Infos[LLump].Position;
    LEntry.Size := AContext.Container.Infos[LLump].Length;
    LEntry.Name := 'TITLEPIC' + RADIX_PAK_EXTENSION;
    AContext.PakEntries.Add(LEntry);
  end;
  AContext.AddAlias('TITLEPIC', 'MainTitle');

  AddOpaque(AContext, 'DemoDecal', 'M_RADIX', 0);
  AContext.AddAlias('M_RADIX', 'DemoDecal');

  AddOpaque(AContext, 'BriefScreen', 'M_BRIEF', 0);
  AContext.AddAlias('M_BRIEF', 'BriefScreen');
end;

procedure TRadixGraphicsPart.AddNumbered(const AContext: TRadixTranslationContext;
  const ARadixName: string);
var
  LName: string;
begin
  LName := 'RADIX' + Format('%.3d', [FPatchId]);
  if AddWithPalette(AContext, ARadixName, LName, True) then
  begin
    AContext.AddAlias(LName, ARadixName);
    Inc(FPatchId);
  end;
end;

procedure TRadixGraphicsPart.AddWeaponNumbers(const AContext: TRadixTranslationContext;
  const ALumpName: string);
var
  LLump: TBytes;
  LImage: TBytes;
  LColumns: TBytes;
  LGlyph: TBytes;
  LColumn: Integer;
  LRow: Integer;
  LIndex: Integer;
  LName: string;
begin
  if not AContext.Container.TryRead(ALumpName, LLump) then
    Exit;
  if Length(LLump) <> 508 then
    Exit;
  // 7 digits of 8 x 9: the image is 56 x 9 by rows, the patches want columns
  LImage := Copy(LLump, 4, 504);
  for LIndex := 0 to High(LImage) do
    if LImage[LIndex] = 254 then
      LImage[LIndex] := 252;
  SetLength(LColumns, 56 * 9);
  for LColumn := 0 to 55 do
    for LRow := 0 to 8 do
      LColumns[LColumn * 9 + LRow] := LImage[LRow * 56 + LColumn];
  SetLength(LGlyph, 8 * 9);
  for LIndex := 1 to 7 do
  begin
    Move(LColumns[(LIndex - 1) * 8 * 9], LGlyph[0], 8 * 9);
    LName := 'RADIX' + Format('%.3d', [FPatchId]);
    Inc(FPatchId);
    AContext.Wad.AddLump(LName, AContext.Patches.FromColumns(LGlyph, 8, 9, False, 0, 0));
    AContext.AddAlias(LName, ALumpName + IntToStr(LIndex));
  end;
end;

procedure TRadixGraphicsPart.BuildAdditional(const AContext: TRadixTranslationContext);
var
  LName: string;
  LPicture: TRadixPlainPicture;
  LEpisode: Integer;
  LMission: Integer;
  LWadName: string;
begin
  FPatchId := 1;
  for LName in WithPalette do
    AddNumbered(AContext, LName);

  for LPicture in PlainPictures do
  begin
    LWadName := 'RADIX' + Format('%.3d', [FPatchId]);
    if AddWithoutPalette(AContext, LPicture.Name, LWadName, False, LPicture.OpaqueIndex) then
    begin
      AContext.AddAlias(LWadName, LPicture.Name);
      Inc(FPatchId);
    end;
  end;

  for LEpisode := 1 to 3 do
    for LMission := 1 to 9 do
    begin
      LName := 'MissionPrimary[' + IntToStr(LEpisode) + '][' + IntToStr(LMission) + ']';
      LWadName := 'OBJ' + IntToStr(LEpisode) + IntToStr(LMission) + 'PRI';
      if AddWithoutPalette(AContext, LName, LWadName, False, -1) then
      begin
        AContext.AddAlias(LWadName, LName);
        Inc(FPatchId);
      end;
      LName := 'MissionSecondary[' + IntToStr(LEpisode) + '][' + IntToStr(LMission) + ']';
      LWadName := 'OBJ' + IntToStr(LEpisode) + IntToStr(LMission) + 'SEC';
      if AddWithoutPalette(AContext, LName, LWadName, False, -1) then
      begin
        AContext.AddAlias(LWadName, LName);
        Inc(FPatchId);
      end;
    end;

  AddWeaponNumbers(AContext, 'WeaponNumOn');
  AddWeaponNumbers(AContext, 'WeaponNumOff');
  AddWeaponNumbers(AContext, 'WeaponNumUse');
end;

procedure TRadixGraphicsPart.Build(const AContext: TRadixTranslationContext);
begin
  BuildMain(AContext);
  BuildAdditional(AContext);
end;

end.
