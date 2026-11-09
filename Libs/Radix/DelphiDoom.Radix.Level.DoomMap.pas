{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixDoomMap                                   }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Doom map that RX_CreateDoomLevel of radix_level.pas built (the          }
{  AddThingToWad, AddSectorToWAD, AddVertexToWAD, AddSidedefToWAD and          }
{  AddWallToWAD of it), with the script of the extra data (lump RMAP)          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.DoomMap;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.Level.Data, DelphiDoom.Radix.Level.Table,
  DelphiDoom.Radix.Level.Coordinates;

type
  /// <summary>Called when a sector uses the flat with this number (the flats of Radix start at 1)</summary>
  TRadixFlatMarker = reference to procedure(AFlat: Integer);

  TRadixDoomMap = class
  strict private
    FLevel: TRadixLevelData;
    FCoordinates: TRadixLevelCoordinates;
    FPositions: TArray<TRadixSectorPosition>;
    FMarkFlat: TRadixFlatMarker;
    FEpisode: Integer;
    FThings: TRadixLevelTable<TRadixDoomThing>;
    FThingExtras: TRadixLevelTable<TRadixDoomThingExtra>;
    FLineDefs: TRadixLevelTable<TRadixDoomLineDef>;
    FSideDefs: TRadixLevelTable<TRadixDoomSideDef>;
    FVertexes: TRadixLevelTable<TRadixDoomVertex>;
    FSectors: TRadixLevelTable<TRadixDoomSector>;
    FScript: TStringList;
    function FlatName(AFlat: Integer): TRadixName8;
    class function RadixSkillToDoomSkill(ASkill: Integer): Integer; static;
    procedure AddSideDefWithTextures(const AWall: TRadixLevelWall; ASector: Integer; out ASideDef: Integer;
      out AIsNew: Boolean);
  public
    constructor Create(const ALevel: TRadixLevelData; const ACoordinates: TRadixLevelCoordinates;
      const APositions: TArray<TRadixSectorPosition>; const AMarkFlat: TRadixFlatMarker);
    destructor Destroy; override;
    /// <summary>The four starts of the players and the four of the deathmatch (AddPlayerStarts)</summary>
    procedure AddPlayerStarts;
    /// <summary>A thing of Radix: the position is converted, the extra data goes in RTHINGS</summary>
    procedure AddThing(AX, AY, AZ, ASpeed, AHeightSpeed, AAngle: Integer; AType: Word; AOptions: Integer;
      ARadixSkill, ARadixId: Integer);
    /// <summary>A thing that is not of Radix (the position is a Doom one)</summary>
    procedure AddDoomThing(AX, AY, AAngle: Integer; AType: Word; AOptions: Integer);
    /// <summary>All the things of the level that have a key and a type</summary>
    procedure AddRadixThings;
    procedure AddSector(const ASector: TRadixLevelSector);
    function AddVertex(AX, AY: Integer): Integer;
    /// <summary>The side that is not found in the sides already there (they are never merged: the triggers need them)</summary>
    function AddSideDef(AOffset: Integer; const ATop, ABottom, AMiddle: TRadixName8; ASector: Integer): Integer;
    procedure AddWall(const AWall: TRadixLevelWall);
    /// <summary>The lump RMAP: the lines of the script, one after the other, CRLF at the end of each</summary>
    function ScriptText: string;
    property Level: TRadixLevelData read FLevel;
    property Things: TRadixLevelTable<TRadixDoomThing> read FThings;
    property ThingExtras: TRadixLevelTable<TRadixDoomThingExtra> read FThingExtras;
    property LineDefs: TRadixLevelTable<TRadixDoomLineDef> read FLineDefs;
    property SideDefs: TRadixLevelTable<TRadixDoomSideDef> read FSideDefs;
    property Vertexes: TRadixLevelTable<TRadixDoomVertex> read FVertexes;
    property Sectors: TRadixLevelTable<TRadixDoomSector> read FSectors;
    /// <summary>For the corrections of a version, that add lines to the script</summary>
    property Script: TStringList read FScript;
  end;

implementation

{$Q-}
{$R-}

{ TRadixDoomMap }

constructor TRadixDoomMap.Create(const ALevel: TRadixLevelData; const ACoordinates: TRadixLevelCoordinates;
  const APositions: TArray<TRadixSectorPosition>; const AMarkFlat: TRadixFlatMarker);
begin
  inherited Create;
  if not Assigned(ALevel) then
    raise EArgumentNilException.Create('ALevel');
  if not Assigned(ACoordinates) then
    raise EArgumentNilException.Create('ACoordinates');
  FLevel := ALevel;
  FCoordinates := ACoordinates;
  FPositions := APositions;
  FMarkFlat := AMarkFlat;
  FEpisode := 0;
  if (Length(ALevel.Name) = 4) and (ALevel.Name[1] = 'E') and (ALevel.Name[3] = 'M') then
    FEpisode := StrToIntDef(ALevel.Name[2], 0);
  FThings := TRadixLevelTable<TRadixDoomThing>.Create;
  FThingExtras := TRadixLevelTable<TRadixDoomThingExtra>.Create;
  FLineDefs := TRadixLevelTable<TRadixDoomLineDef>.Create;
  FSideDefs := TRadixLevelTable<TRadixDoomSideDef>.Create;
  FVertexes := TRadixLevelTable<TRadixDoomVertex>.Create;
  FSectors := TRadixLevelTable<TRadixDoomSector>.Create;
  FScript := TStringList.Create;
end;

destructor TRadixDoomMap.Destroy;
begin
  FScript.Free;
  FSectors.Free;
  FVertexes.Free;
  FSideDefs.Free;
  FLineDefs.Free;
  FThingExtras.Free;
  FThings.Free;
  inherited Destroy;
end;

function TRadixDoomMap.ScriptText: string;
var
  LLine: string;
begin
  Result := '';
  for LLine in FScript do
    Result := Result + LLine + #13#10;
end;

class function TRadixDoomMap.RadixSkillToDoomSkill(ASkill: Integer): Integer;
begin
  if (ASkill = 0) or (ASkill = 1) then
    Result := MTF_EASY or MTF_NORMAL or MTF_HARD
  else if ASkill = 2 then
    Result := MTF_NORMAL or MTF_HARD
  else if ASkill = 3 then
    Result := MTF_HARD
  else
    Result := MTF_EASY or MTF_NORMAL or MTF_HARD or MTF_NOTSINGLE;
end;

function TRadixDoomMap.FlatName(AFlat: Integer): TRadixName8;
begin
  Result := TRadixName8.Make(RADIX_FLAT_PREFIX + Format('%.4d', [AFlat + 1]));
  if Assigned(FMarkFlat) then
    FMarkFlat(AFlat + 1);
end;

procedure TRadixDoomMap.AddThing(AX, AY, AZ, ASpeed, AHeightSpeed, AAngle: Integer; AType: Word;
  AOptions: Integer; ARadixSkill, ARadixId: Integer);
var
  LThing: TRadixDoomThing;
  LExtra: TRadixDoomThingExtra;
begin
  FCoordinates.Convert(AX, AY);
  LThing.X := SmallInt(AX);
  LThing.Y := SmallInt(AY);
  LThing.Angle := SmallInt(Round((AAngle / 256) * 360));
  LThing.ThingType := AType;
  LThing.Options := SmallInt(AOptions);
  if FEpisode = 1 then
    if (AType = MT_DEFENCEDRONE_STUB1) or (AType = MT_DEFENCEDRONE_STUB2) or
      (AType = MT_DEFENCEDRONE_STUB3) then
      LThing.Options := LThing.Options or MTF_INACTIVE;
  FThings.Add(LThing);
  LExtra.Z := SmallInt(AZ);
  LExtra.Speed := SmallInt(ASpeed);
  LExtra.HeightSpeed := SmallInt(AHeightSpeed);
  LExtra.RadixSkill := SmallInt(ARadixSkill);
  LExtra.RadixId := SmallInt(ARadixId);
  FThingExtras.Add(LExtra);
end;

procedure TRadixDoomMap.AddDoomThing(AX, AY, AAngle: Integer; AType: Word; AOptions: Integer);
var
  LThing: TRadixDoomThing;
  LExtra: TRadixDoomThingExtra;
begin
  LThing.X := SmallInt(AX);
  LThing.Y := SmallInt(AY);
  LThing.Angle := SmallInt(AAngle);
  LThing.ThingType := AType;
  LThing.Options := SmallInt(AOptions);
  FThings.Add(LThing);
  LExtra.Z := 0;
  LExtra.Speed := 0;
  LExtra.HeightSpeed := 0;
  LExtra.RadixSkill := -1;
  LExtra.RadixId := -1;
  FThingExtras.Add(LExtra);
end;

procedure TRadixDoomMap.AddPlayerStarts;
var
  LIndex: Integer;
begin
  // player starts: DoomEdNum 1 to 4; deathmatch starts: DoomEdNum 11
  for LIndex := 0 to 3 do
    with FLevel.PlayerStarts[LIndex] do
      AddThing(X, Y, Z, 0, 0, Angle, LIndex + 1, 7, -1, -1);
  for LIndex := 4 to RADIX_PLAYER_STARTS - 1 do
    with FLevel.PlayerStarts[LIndex] do
      AddThing(X, Y, Z, 0, 0, Angle, 11, 7, -1, -1);
end;

procedure TRadixDoomMap.AddRadixThings;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FLevel.Things) do
    with FLevel.Things[LIndex] do
      if (ThingKey >= 0) and (RadixType >= 0) then
        AddThing(X, Y, Ground, Speed, HeightSpeed, Angle, Word(RadixType + RADIX_THING_OFFSET),
          RadixSkillToDoomSkill(Skill), Skill, ThingKey);
end;

procedure TRadixDoomMap.AddSector(const ASector: TRadixLevelSector);
var
  LSector: TRadixDoomSector;
  LIndex: Integer;
  LPosition: TRadixSectorPosition;
begin
  LIndex := FSectors.Count;
  LSector.FloorHeight := ASector.FloorHeight;
  LSector.CeilingHeight := ASector.CeilingHeight;
  if ASector.Flags and RSF_FLOORSKY <> 0 then
    LSector.FloorPic := TRadixName8.Make('F_SKY1')
  else
    LSector.FloorPic := FlatName(ASector.FloorTexture);
  if ASector.Flags and RSF_CEILINGSKY <> 0 then
    LSector.CeilingPic := TRadixName8.Make('F_SKY1')
  else
    LSector.CeilingPic := FlatName(ASector.CeilingTexture);
  if ASector.Flags and (RSF_FOG or RSF_DARKNESS) = 0 then
    LSector.LightLevel := Byte(200 + ASector.LightLevel div 2)
  else if ASector.LightLevel >= RADIX_MAX_LIGHT_LEVEL then
    LSector.LightLevel := 255
  else
    LSector.LightLevel := Byte(ASector.LightLevel * 4 + 2);
  LSector.Special := 0;
  LSector.Tag := 0;
  FSectors.Add(LSector);

  // the extra data goes in the header of the map
  LPosition := FPositions[LIndex];
  FScript.Add('sectorid ' + IntToStr(LIndex));
  FScript.Add('xmul ' + IntToStr(LPosition.XMul));
  FScript.Add('xadd ' + IntToStr(LPosition.XAdd));
  FScript.Add('ymul ' + IntToStr(LPosition.YMul));
  FScript.Add('yadd ' + IntToStr(LPosition.YAdd));
  FScript.Add('sectorflags ' + IntToStr(Integer(ASector.Flags or RSF_RADIXSECTOR)));
  if ASector.Flags and RSF_FLOORSLOPE <> 0 then
    FScript.Add('floorslope ' + IntToStr(ASector.FloorA) + ' ' + IntToStr(ASector.FloorB) + ' ' +
      IntToStr(ASector.FloorC) + ' ' + IntToStr(ASector.FloorD));
  if ASector.Flags and RSF_CEILINGSLOPE <> 0 then
    FScript.Add('ceilingslope ' + IntToStr(ASector.CeilingA) + ' ' + IntToStr(ASector.CeilingB) + ' ' +
      IntToStr(ASector.CeilingC) + ' ' + IntToStr(ASector.CeilingD));
  if ASector.Flags and (RSF_FLOORSLOPE or RSF_CEILINGSLOPE) <> 0 then
  begin
    FScript.Add('heightnodesx ' + IntToStr(ASector.HeightNodesX[0]) + ' ' + IntToStr(ASector.HeightNodesX[1]) +
      ' ' + IntToStr(ASector.HeightNodesX[2]));
    FScript.Add('heightnodesy ' + IntToStr(ASector.HeightNodesY[0]) + ' ' + IntToStr(ASector.HeightNodesY[1]) +
      ' ' + IntToStr(ASector.HeightNodesY[2]));
    if ASector.Flags and RSF_FLOORSLOPE <> 0 then
      FScript.Add('floorheights ' + IntToStr(ASector.FloorHeights[0]) + ' ' + IntToStr(ASector.FloorHeights[1]) +
        ' ' + IntToStr(ASector.FloorHeights[2]));
    if ASector.Flags and RSF_CEILINGSLOPE <> 0 then
      FScript.Add('ceilingheights ' + IntToStr(ASector.CeilingHeights[0]) + ' ' +
        IntToStr(ASector.CeilingHeights[1]) + ' ' + IntToStr(ASector.CeilingHeights[2]));
  end;
  if ASector.FloorAngle <> 0 then
  begin
    // the old code wrote the angles with itoa of an Integer: a LongWord past 2^31 is negative
    FScript.Add('floorangle ' + IntToStr(Integer(ASector.FloorAngle)));
    FScript.Add('floorangle_x ' + IntToStr(ASector.FloorAngleX));
    FScript.Add('floorangle_y ' + IntToStr(ASector.FloorAngleY));
  end;
  if ASector.CeilingAngle <> 0 then
  begin
    FScript.Add('ceilingangle ' + IntToStr(Integer(ASector.CeilingAngle)));
    FScript.Add('ceilingangle_x ' + IntToStr(ASector.CeilingAngleX));
    FScript.Add('ceilingangle_y ' + IntToStr(ASector.CeilingAngleY));
  end;
  FScript.Add('');
end;

function TRadixDoomMap.AddVertex(AX, AY: Integer): Integer;
var
  LIndex: Integer;
  LVertex: TRadixDoomVertex;
begin
  for LIndex := 0 to FVertexes.Count - 1 do
    if (FVertexes[LIndex].X = SmallInt(AX)) and (FVertexes[LIndex].Y = SmallInt(AY)) then
      Exit(LIndex);
  LVertex.X := SmallInt(AX);
  LVertex.Y := SmallInt(AY);
  Result := FVertexes.Add(LVertex);
end;

function TRadixDoomMap.AddSideDef(AOffset: Integer; const ATop, ABottom, AMiddle: TRadixName8;
  ASector: Integer): Integer;
var
  LSide: TRadixDoomSideDef;
  LOffset: SmallInt;
begin
  LOffset := SmallInt(AOffset);
  if LOffset < 0 then
    LSide.TextureOffset := LOffset
  else
    LSide.TextureOffset := LOffset mod 128;
  LSide.RowOffset := 0;
  LSide.TopTexture := ATop;
  LSide.BottomTexture := ABottom;
  LSide.MidTexture := AMiddle;
  LSide.Sector := SmallInt(ASector);
  Result := FSideDefs.Add(LSide);
end;

// The textures of the side of a wall (the same for the front and for the back)
procedure TRadixDoomMap.AddSideDefWithTextures(const AWall: TRadixLevelWall; ASector: Integer;
  out ASideDef: Integer; out AIsNew: Boolean);
var
  LTop: TRadixName8;
  LBottom: TRadixName8;
  LMiddle: TRadixName8;
  LFloorTexture: Integer;
  LCeilingTexture: Integer;
  LDash: TRadixName8;
begin
  // 1 is added to compensate for the stub texture RDXW0000
  LFloorTexture := AWall.FloorTexture + 1;
  LCeilingTexture := AWall.CeilingTexture + 1;
  LDash := TRadixName8.Make('-');
  if AWall.Flags and RWF_SINGLESIDED <> 0 then
  begin
    LTop := LDash;
    LBottom := LDash;
    LMiddle := TRadixName8.Make(RADIX_WALL_PREFIX + Format('%.4d', [LFloorTexture]));
  end
  else
  begin
    if AWall.Flags and RWF_FLOORWALL <> 0 then
      LBottom := TRadixName8.Make(RADIX_WALL_PREFIX + Format('%.4d', [LFloorTexture]))
    else
      LBottom := LDash;
    if AWall.Flags and RWF_CEILINGWALL <> 0 then
      LTop := TRadixName8.Make(RADIX_WALL_PREFIX + Format('%.4d', [LCeilingTexture]))
    else
      LTop := LDash;
    if AWall.Flags and RWF_TWOSIDEDCOMPLETE <> 0 then
      LMiddle := TRadixName8.Make(RADIX_WALL_PREFIX + Format('%.4d', [LFloorTexture]))
    else
      LMiddle := LDash;
  end;
  ASideDef := AddSideDef(AWall.BitmapOffset, LTop, LBottom, LMiddle, ASector);
  AIsNew := True;
end;

procedure TRadixDoomMap.AddWall(const AWall: TRadixLevelWall);
var
  LLine: TRadixDoomLineDef;
  LVertex1: Integer;
  LVertex2: Integer;
  LSide1: Integer;
  LSide2: Integer;
  LNew1: Boolean;
  LNew2: Boolean;
  LSector: ^TRadixLevelSector;
  LDash: TRadixName8;
begin
  LDash := TRadixName8.Make('-');
  LNew1 := True;
  LNew2 := True;
  // front side
  if AWall.FrontSector >= 0 then
  begin
    LSector := @FLevel.Sectors[AWall.FrontSector];
    if (AWall.Flags and RWF_STUBWALL = 0) and (LSector.FloorTexture = 0) and (LSector.CeilingTexture = 0) and
      (LSector.FloorHeight = LSector.CeilingHeight) then
      LSide1 := -1
    else
    begin
      AddSideDefWithTextures(AWall, AWall.FrontSector, LSide1, LNew1);
      LNew1 := LSide1 = FSideDefs.Count - 1;
    end;
  end
  else
    LSide1 := -1;
  // back side
  if AWall.BackSector >= 0 then
  begin
    LSector := @FLevel.Sectors[AWall.BackSector];
    if (LSector.FloorTexture = 0) and (LSector.CeilingTexture = 0) and
      (LSector.FloorHeight = LSector.CeilingHeight) then
      LSide2 := -1
    else
    begin
      AddSideDefWithTextures(AWall, AWall.BackSector, LSide2, LNew2);
      LNew2 := LSide2 = FSideDefs.Count - 1;
    end;
  end
  else
    LSide2 := -1;

  LVertex1 := AddVertex(AWall.V1X, AWall.V1Y);
  LVertex2 := AddVertex(AWall.V2X, AWall.V2Y);

  if LSide1 < 0 then
  begin
    LLine.V1 := SmallInt(LVertex2);
    LLine.V2 := SmallInt(LVertex1);
  end
  else
  begin
    LLine.V1 := SmallInt(LVertex1);
    LLine.V2 := SmallInt(LVertex2);
  end;
  LLine.Flags := 0;
  if (LSide1 >= 0) and (LSide2 >= 0) then
    LLine.Flags := LLine.Flags or ML_TWOSIDED;
  if AWall.Flags and RWF_STUBWALL <> 0 then
    LLine.Flags := LLine.Flags or ML_DONTDRAW or ML_AUTOMAPIGNOGE;
  LLine.Special := 0;
  LLine.Tag := 0;
  if LSide1 < 0 then
  begin
    LLine.SideNum[0] := SmallInt(LSide2);
    LLine.SideNum[1] := -1;
  end
  else
  begin
    LLine.SideNum[0] := SmallInt(LSide1);
    LLine.SideNum[1] := SmallInt(LSide2);
  end;

  if (LLine.Flags and ML_TWOSIDED = 0) and (LLine.SideNum[0] >= 0) then
  begin
    LLine.Flags := LLine.Flags or ML_BLOCKING;
    if FSideDefs[LLine.SideNum[0]].MidTexture = LDash then
    begin
      if LNew1 and LNew2 then
        FSideDefs[LLine.SideNum[0]].MidTexture := FSideDefs[LLine.SideNum[0]].TopTexture
      else
        LLine.SideNum[0] := SmallInt(AddSideDef(AWall.BitmapOffset, LDash, LDash,
          FSideDefs[LLine.SideNum[0]].TopTexture, FSideDefs[LLine.SideNum[0]].Sector));
    end;
  end;

  // the extra data goes in the header of the map
  FScript.Add('wallid ' + IntToStr(FLineDefs.Count));
  FScript.Add('wallflags ' + IntToStr(Integer((AWall.Flags and not Cardinal(RWF_STUBWALL)) or RWF_RADIXWALL)));
  FScript.Add('wallhitpoints ' + IntToStr(AWall.HitPoints));
  FScript.Add('walltrigger ' + IntToStr(AWall.Trigger));
  FScript.Add('');
  FLineDefs.Add(LLine);
end;

end.
