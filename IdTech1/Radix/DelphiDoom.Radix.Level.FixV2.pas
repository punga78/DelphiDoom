{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelFixV2                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of fix_radix_level_v2 and fix_doom_level_v2 of radix_level.pas:        }
{  the corrections of the levels of Radix 2.0 (REMIX)                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.FixV2;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.Level.Data, DelphiDoom.Radix.Level.DoomMap,
  DelphiDoom.Radix.Level.Intf;

type
  TRadixLevelFixV2 = class(TInterfacedObject, IRadixLevelFix)
  strict private
    class procedure FixE1M1(const AMap: TRadixDoomMap); static;
    class procedure FixE1M2(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData); static;
    class procedure FixE1M6(const AMap: TRadixDoomMap); static;
    class procedure FixE2M7(const AMap: TRadixDoomMap); static;
    class procedure FixE3M1(const AMap: TRadixDoomMap); static;
    class procedure FixE3M2(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData); static;
    class procedure FixE3M3(const AMap: TRadixDoomMap); static;
    class procedure FixE3M7(const AMap: TRadixDoomMap); static;
  public
    procedure FixRadix(const ALevel: TRadixLevelData);
    procedure FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
  end;

implementation

uses
  DelphiDoom.Radix.Level.FixOps;

{$Q-}
{$R-}

const
  SkyName = 'F_SKY1';
  E3M2DeltaX = RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD;
  E3M2DeltaY = RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD;

procedure SetTextureOffset(const AMap: TRadixDoomMap; ASide, AOffset: Integer);
begin
  AMap.SideDefs[ASide].TextureOffset := SmallInt(AOffset);
end;

{ TRadixLevelFixV2 }

procedure TRadixLevelFixV2.FixRadix(const ALevel: TRadixLevelData);
begin
  if ALevel.Name = 'E1M6' then
  begin
    Inc(ALevel.Sectors[156].CeilingHeights[0], 64);
    Inc(ALevel.Sectors[156].CeilingHeights[1], 64);
    Inc(ALevel.Sectors[156].CeilingHeights[2], 64);
    ALevel.Sectors[157].CeilingHeight := ALevel.Sectors[157].CeilingHeight + 64;
  end
  else if ALevel.Name = 'E3M2' then
    ALevel.Sectors[143].Flags := ALevel.Sectors[142].Flags and not (RSF_FLOORSLOPE or RSF_CEILINGSLOPE);
end;

class procedure TRadixLevelFixV2.FixE1M1(const AMap: TRadixDoomMap);
begin
  TRadixLevelFixOps.SlideLine(AMap, 172);
  TRadixLevelFixOps.SlideLine(AMap, 198);
  TRadixLevelFixOps.SlideLine(AMap, 146);
  TRadixLevelFixOps.SlideLine(AMap, 269);
  TRadixLevelFixOps.ReplaceSideSector(AMap, 206, 0);
  TRadixLevelFixOps.ReplaceSideSector(AMap, 211, 212);
  // blocking lines
  TRadixLevelFixOps.MakeBlockingLine(AMap, 44);
  TRadixLevelFixOps.MakeBlockingLine(AMap, 45);
  TRadixLevelFixOps.MakeBlockingLine(AMap, 639);
  // slide lines
  TRadixLevelFixOps.MakeSlideLine(AMap, 1);
  TRadixLevelFixOps.MakeSlideLine(AMap, 3);
  TRadixLevelFixOps.MakeSlideLine(AMap, 4);
  TRadixLevelFixOps.MakeSlideLine(AMap, 5);
  TRadixLevelFixOps.MakeSlideLine(AMap, 6);
  TRadixLevelFixOps.MakeSlideLine(AMap, 41);
  TRadixLevelFixOps.MakeSlideLine(AMap, 44);
  TRadixLevelFixOps.MakeSlideLine(AMap, 45);
  TRadixLevelFixOps.MakeSlideLine(AMap, 48);
  TRadixLevelFixOps.MakeSlideLine(AMap, 47);
  TRadixLevelFixOps.MakeSlideLine(AMap, 49);
  TRadixLevelFixOps.MakeSlideLine(AMap, 379);
  TRadixLevelFixOps.MakeSlideLine(AMap, 632);
  TRadixLevelFixOps.MakeSlideLine(AMap, 636);
  TRadixLevelFixOps.MakeSlideLine(AMap, 639);
end;

class procedure TRadixLevelFixV2.FixE1M2(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
const
  Easy = MTF_EASY or MTF_NORMAL or MTF_HARD;
  SlideLines: array[0..6] of Integer = (103, 108, 107, 113, 112, 116, 118);
  SlideFlags: array[0..7] of Integer = (104, 106, 109, 111, 115, 117, 401, 449);
var
  LIndex: Integer;
begin
  AMap.AddDoomThing(-28735, -1376, 0, MT_PLAYERFLOORSLIDE64, Easy);
  AMap.AddDoomThing(-28735, -1312, 0, MT_PLAYERFLOORSLIDE64, Easy);
  AMap.AddDoomThing(-28415, -1376, 0, MT_PLAYERFLOORSLIDE64, Easy);
  AMap.AddDoomThing(-28415, -1312, 0, MT_PLAYERFLOORSLIDE64, Easy);
  for LIndex := 0 to High(SlideLines) do
    TRadixLevelFixOps.SlideLine(AMap, SlideLines[LIndex]);
  for LIndex := 0 to High(SlideFlags) do
    TRadixLevelFixOps.MakeSlideLine(AMap, SlideFlags[LIndex]);
  // F_TranspotoSecondary
  ALevel.Actions[273].Params[4] := 528;
end;

class procedure TRadixLevelFixV2.FixE1M6(const AMap: TRadixDoomMap);
begin
  TRadixLevelFixOps.MoveVertex(AMap, -27583, -2624, -27584, -2592);
  TRadixLevelFixOps.MoveVertex(AMap, -27583, -2560, -27584, -2560);
  TRadixLevelFixOps.MoveVertex(AMap, -27583, -2688, -27584, -2688);
  TRadixLevelFixOps.MoveVertex(AMap, -27583, -2752, -27584, -2752);
  SetTextureOffset(AMap, 758, 42);
  SetTextureOffset(AMap, 1365, 0);
  TRadixLevelFixOps.SlideCorridor(AMap, 427, 431);
end;

class procedure TRadixLevelFixV2.FixE2M7(const AMap: TRadixDoomMap);
var
  LSide: Integer;
begin
  TRadixLevelFixOps.ReplaceSideSector(AMap, 102, 52);
  TRadixLevelFixOps.ChangeVertexes(AMap, -19135, -4096, -19135, -4160);
  LSide := AMap.LineDefs[19].SideNum[1];
  if LSide >= 0 then
    AMap.SideDefs[LSide].TopTexture := AMap.SideDefs[LSide].BottomTexture;
end;

class procedure TRadixLevelFixV2.FixE3M1(const AMap: TRadixDoomMap);
const
  Lines: array[0..5] of Integer = (31, 37, 39, 43, 85, 86);
var
  LSide: Integer;
  LIndex: Integer;
begin
  LSide := AMap.LineDefs[45].SideNum[0];
  for LIndex := 0 to High(Lines) do
    TRadixLevelFixOps.MakeOneSided(AMap, Lines[LIndex], LSide);
end;

class procedure TRadixLevelFixV2.FixE3M2(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
const
  BriefingLines: array[0..13] of Integer = (184, 429, 534, 665, 1166, 1167, 1168, 1169, 1170, 1171, 1172, 1173,
    1174, 1175);
  MovedThings: array[0..5, 0..3] of Integer = (
    (14200, -1506, 13120, -544), (14823, -1501, 13248, -256), (-17140, -5602, -14208, -4576),
    (-16380, -5576, -13856, -4576), (-16180, -5610, -13888, -5472), (-15860, -5610, -12640, -5472));
var
  LIndex: Integer;
  LMoved: Integer;
  LSide: Integer;
  LVertex: Integer;
  LVertex1: Integer;
  LVertex2: Integer;
  LLine: TRadixDoomLineDef;
  LName: TRadixName8;
begin
  TRadixLevelFixOps.ChangeVertexes(AMap, 10112, -4160, 10176, -4160);
  TRadixLevelFixOps.ChangeVertexes(AMap, 13120, -4160, 13056, -4160);

  // sector 142
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 184, E3M2DeltaX, E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 429, E3M2DeltaX, E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 534, E3M2DeltaX, E3M2DeltaY);
  // clone of the sector 141 (the wall 665 twice, as the old code did)
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 665, E3M2DeltaX, E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 665, E3M2DeltaX, E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 536, E3M2DeltaX, E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 538, E3M2DeltaX, E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 535, E3M2DeltaX, E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 537, E3M2DeltaX, E3M2DeltaY);
  // clone of the sector 143
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 573, -E3M2DeltaX, -E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 610, -E3M2DeltaX, -E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 570, -E3M2DeltaX, -E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 574, -E3M2DeltaX, -E3M2DeltaY);
  TRadixLevelFixOps.CloneAndMoveWall(AMap, 609, -E3M2DeltaX, -E3M2DeltaY);

  // sky of the arena
  AMap.Sectors[291].CeilingPic := TRadixName8.Make(SkyName);
  AMap.Sectors[292].CeilingPic := TRadixName8.Make(SkyName);
  AMap.Sectors[293].CeilingPic := TRadixName8.Make(SkyName);
  AMap.Sectors[295].CeilingPic := TRadixName8.Make(SkyName);
  // secondary target room
  AMap.Sectors[323].CeilingHeight := 1280;
  AMap.Sectors[324].CeilingHeight := 1280;

  // ending line of the sector 143 (line 1174)
  AMap.LineDefs[1174].SideNum[1] := -1;
  AMap.SideDefs[AMap.LineDefs[1174].SideNum[0]].MidTexture := AMap.SideDefs[AMap.LineDefs[1174].SideNum[0]].BottomTexture;
  AMap.LineDefs[1174].Flags := AMap.LineDefs[1174].Flags or ML_BLOCKING;
  AMap.LineDefs[1174].Flags := AMap.LineDefs[1174].Flags and not ML_TWOSIDED;

  // ending line of the sector 141 (line 1169)
  LVertex := AMap.LineDefs[1169].V1;
  AMap.LineDefs[1169].V1 := AMap.LineDefs[1169].V2;
  AMap.LineDefs[1169].V2 := SmallInt(LVertex);
  AMap.LineDefs[1169].SideNum[0] := AMap.LineDefs[1169].SideNum[1];
  AMap.LineDefs[1169].SideNum[1] := -1;
  AMap.SideDefs[AMap.LineDefs[1169].SideNum[0]].MidTexture := AMap.SideDefs[AMap.LineDefs[1169].SideNum[0]].BottomTexture;
  AMap.LineDefs[1169].Flags := AMap.LineDefs[1169].Flags or ML_BLOCKING;
  AMap.LineDefs[1169].Flags := AMap.LineDefs[1169].Flags and not ML_TWOSIDED;

  // briefing screens
  for LIndex := 0 to High(BriefingLines) do
    AMap.Script.Add('wallid ' + IntToStr(BriefingLines[LIndex]) + ' LINEBRIEFINGIGNORE');

  // no monsters in the trans-corridor
  AMap.LineDefs[537].Flags := AMap.LineDefs[537].Flags or ML_BLOCKMONSTERS;
  AMap.LineDefs[609].Flags := AMap.LineDefs[609].Flags or ML_BLOCKMONSTERS;

  // things of the trans-corridor
  for LIndex := 0 to AMap.Things.Count - 1 do
    for LMoved := 0 to High(MovedThings) do
      if (AMap.Things[LIndex].X = MovedThings[LMoved, 0]) and (AMap.Things[LIndex].Y = MovedThings[LMoved, 1]) then
      begin
        AMap.Things[LIndex].X := SmallInt(MovedThings[LMoved, 2]);
        AMap.Things[LIndex].Y := SmallInt(MovedThings[LMoved, 3]);
        Break;
      end;

  LName := TRadixName8.Make('RDXW0194');
  AMap.SideDefs[AMap.LineDefs[609].SideNum[0]].TopTexture := LName;
  AMap.SideDefs[AMap.LineDefs[609].SideNum[0]].BottomTexture := LName;
  AMap.SideDefs[AMap.LineDefs[609].SideNum[1]].TopTexture := LName;
  AMap.SideDefs[AMap.LineDefs[609].SideNum[1]].BottomTexture := LName;
  AMap.SideDefs[AMap.LineDefs[1174].SideNum[0]].TopTexture := LName;
  AMap.SideDefs[AMap.LineDefs[1174].SideNum[0]].MidTexture := LName;
  AMap.SideDefs[AMap.LineDefs[1174].SideNum[0]].BottomTexture := LName;

  // silent teleports
  LSide := AMap.AddSideDef(0, TRadixName8.Make('-'), TRadixName8.Make('-'), TRadixName8.Make('-'), 142);
  LVertex1 := AMap.AddVertex(15393, -1345);
  LVertex2 := AMap.AddVertex(15393, -1663);
  LLine.V1 := SmallInt(LVertex1);
  LLine.V2 := SmallInt(LVertex2);
  LLine.Flags := ML_TWOSIDED;
  LLine.Special := 244;
  LLine.Tag := 1;
  LLine.SideNum[0] := SmallInt(LSide);
  LLine.SideNum[1] := SmallInt(LSide);
  AMap.LineDefs.Add(LLine);
  LVertex1 := AMap.AddVertex(-17376, -5759);
  LVertex2 := AMap.AddVertex(-17376, -5441);
  LLine.V1 := SmallInt(LVertex1);
  LLine.V2 := SmallInt(LVertex2);
  AMap.LineDefs.Add(LLine);

  // animated textures
  ALevel.Actions[67].Enabled := 1;
  ALevel.Actions[68].Enabled := 1;
  ALevel.Actions[69].Enabled := 1;
end;

class procedure TRadixLevelFixV2.FixE3M3(const AMap: TRadixDoomMap);
const
  Lines: array[0..3] of Integer = (320, 321, 587, 590);
var
  LSide: Integer;
  LIndex: Integer;
begin
  for LIndex := 0 to High(Lines) do
  begin
    LSide := AMap.LineDefs[Lines[LIndex]].SideNum[0];
    if LSide >= 0 then
      AMap.SideDefs[LSide].Sector := 48;
  end;
end;

class procedure TRadixLevelFixV2.FixE3M7(const AMap: TRadixDoomMap);
var
  LSide: Integer;
begin
  TRadixLevelFixOps.ChangeVertexes(AMap, -32703, -3520, -32703, -3584);
  // as the old code: the flags of the line 86 (not the ones of the line itself) are used, and
  // the second assignment replaces the first
  AMap.LineDefs[410].SideNum[1] := -1;
  AMap.LineDefs[410].Flags := AMap.LineDefs[86].Flags and not ML_TWOSIDED;
  AMap.LineDefs[410].Flags := AMap.LineDefs[86].Flags or ML_BLOCKING;
  LSide := AMap.LineDefs[410].SideNum[0];
  if LSide >= 0 then
    AMap.SideDefs[LSide].MidTexture := AMap.SideDefs[LSide].BottomTexture;
  AMap.LineDefs[411].SideNum[1] := -1;
  AMap.LineDefs[411].Flags := AMap.LineDefs[86].Flags and not ML_TWOSIDED;
  AMap.LineDefs[411].Flags := AMap.LineDefs[86].Flags or ML_BLOCKING;
  LSide := AMap.LineDefs[411].SideNum[0];
  if LSide >= 0 then
    AMap.SideDefs[LSide].MidTexture := AMap.SideDefs[LSide].BottomTexture;
end;

procedure TRadixLevelFixV2.FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
var
  LName: string;
  LIndex: Integer;
begin
  LName := ALevel.Name;
  if LName = 'E1M1' then
    FixE1M1(AMap)
  else if LName = 'E1M2' then
    FixE1M2(AMap, ALevel)
  else if LName = 'E1M5' then
    AMap.SideDefs[413].TextureOffset := -16
  else if LName = 'E1M6' then
    FixE1M6(AMap)
  else if LName = 'E1M7' then
  begin
    AMap.Sectors[37].CeilingPic := TRadixName8.Make(SkyName);
    TRadixLevelFixOps.MoveVertex(AMap, -31103, -2496, -31040, -2528);
    TRadixLevelFixOps.MoveVertex(AMap, -31103, -640, -31040, -640);
    SetTextureOffset(AMap, 1800, -32);
  end
  else if LName = 'E1M9' then
  begin
    AMap.Sectors[18].CeilingHeight := 704;
    AMap.Sectors[172].CeilingHeight := 704;
  end
  else if LName = 'E2M1' then
  begin
    TRadixLevelFixOps.ReplaceSideSector(AMap, 64, 65);
    for LIndex in [247, 248, 268, 269] do
      SetTextureOffset(AMap, LIndex, 0);
  end
  else if LName = 'E2M3' then
  begin
    SetTextureOffset(AMap, 329, 0);
    SetTextureOffset(AMap, 330, 0);
  end
  else if LName = 'E2M4' then
  begin
    SetTextureOffset(AMap, 529, 0);
    TRadixLevelFixOps.ChangeVertexes(AMap, 1473, -1344, 1537, -1344);
    // final arena sky
    AMap.Sectors[48].CeilingHeight := 1312;
    AMap.Sectors[49].CeilingHeight := 1312;
  end
  else if LName = 'E2M5' then
  begin
    TRadixLevelFixOps.ReplaceSideSector(AMap, 2, 1);
    AMap.Sectors[140].CeilingHeight := 768;
    AMap.Sectors[160].CeilingPic := TRadixName8.Make(SkyName);
  end
  else if LName = 'E2M7' then
    FixE2M7(AMap)
  else if LName = 'E3M1' then
    FixE3M1(AMap)
  else if LName = 'E3M2' then
    FixE3M2(AMap, ALevel)
  else if LName = 'E3M3' then
    FixE3M3(AMap)
  else if LName = 'E3M7' then
    FixE3M7(AMap);
end;

end.
