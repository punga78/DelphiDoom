{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedLevelBuilder                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_CreateDoomLevel (speed_level.pas)                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.LevelBuilder;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf, DelphiDoom.GameData.Intf, DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   A circuit is a flat picture (the floor of a sector 4096 units wide), walls drawn as lines
  ///   with a texture, things (obstacles, the cars, the start) and the path of the race. This class
  ///   makes the Doom level around them: a big sector with the picture as its floor, the walls as
  ///   two sided lines, and a sector outside that closes the map. The lumps SEGS, SSECTORS, NODES,
  ///   REJECT and BLOCKMAP are empty (the nodes builder fills them when the level is loaded)
  /// </summary>
  TSpeedLevelBuilder = class(TInterfacedObject, ISpeedLevelBuilder)
  strict private
    FLog: ILog;
  public
    /// <param name="ALog">Receives the warnings; EArgumentNilException when nil</param>
    constructor Create(const ALog: ILog);
    function Build(const ALevelName, APrefix: string; const AMapData, ASectorData, APathData: TBytes;
      AScale: Integer; const AExtraFlat: string; const AWad: IGameWadComposer): Boolean;
  end;

implementation

uses
  System.Generics.Collections,
  DelphiDoom.MathCore.Crc32, DelphiDoom.Wad.Level.Types, DelphiDoom.Scanner.Scanner,
  DelphiDoom.Speed.Names;

const
  // the flags of the lines
  ML_BLOCKING = 1;
  ML_TWOSIDED = 4;
  ML_DONTPEGBOTTOM = 16;
  ML_MAPPED = 256;
  ML_AUTOMAPIGNOGE = 2048;

  THING_RACE_START = 500;
  THING_PATH = 512;
  THING_STAR_POSITION = 241;
  THING_PLAYER_START = 1;
  THING_OPTIONS = 7;

  PATH_HEADER_SIZE = $100;
  PATH_COUNT_OFFSET = 196;
  EXTRA_SECTOR_OFFSET = 2048;
  MAP_SIDE = 4096;

type
  TSpeedWallLine = record
    Vertex1: Integer;
    Vertex2: Integer;
    Texture: string;
  end;

  /// <summary>The Doom level that is being made from the files of one circuit</summary>
  TLevelAssembly = class
  strict private
    FScale: Integer;
    FThings: TList<TWadThing>;
    FLines: TList<TWadLinedef>;
    FSides: TList<TWadSidedef>;
    FVertices: TList<TWadVertex>;
    FSectors: TList<TWadSector>;
    FMainSector: Integer;
    function Name8(const AName: string): TWadName8;
  public
    constructor Create(AScale: Integer);
    destructor Destroy; override;
    procedure AddThing(AX, AY, AAngle: Integer; AThingType: Word);
    procedure AddThingUntranslated(AX, AY, AAngle: Integer; AThingType: Word);
    function AddSector(AFloorHeight, ACeilingHeight: Integer; const AFloorTexture, ACeilingTexture: string): Integer;
    function AddVertex(AX, AY: Integer): Integer;
    function AddSide(const ATop, ABottom, AMiddle: string; ASector: Integer): Integer;
    function AddLine(AX1, AY1, AX2, AY2: Integer): Integer;
    procedure SetLineFlags(ALine, AFlags: Integer);
    procedure SetLineSide(ALine, ASide, ASideNumber: Integer);
    procedure MakeMainSector(const APrefix: string);
    procedure MakeExtraSector(const AExtraFlat: string);
    procedure ReadMapFile(const AData: TBytes);
    procedure ReadPathFile(const AData: TBytes; ACount: Integer);
    procedure ReadSectorFile(const AData: TBytes; const ALog: ILog);
    procedure MoveThing(AOldX, AOldY, ANewX, ANewY: Integer);
    procedure MoveVertex(AOldX, AOldY, ANewX, ANewY: Integer);
    procedure ApplyFixes(const ALevelName: string);
    function ToBytes<T: record>(const AList: TList<T>): TBytes;
    property Things: TList<TWadThing> read FThings;
    property Lines: TList<TWadLinedef> read FLines;
    property Sides: TList<TWadSidedef> read FSides;
    property Vertices: TList<TWadVertex> read FVertices;
    property Sectors: TList<TWadSector> read FSectors;
  end;

  /// <summary>The CRCs of the files .DAT of the original circuits E1M1..E1M8, which the fixes are for</summary>
  TOriginalCircuits = class
  public
    class function IsOriginal(const ALevelName: string; ACrc: Cardinal): Boolean; static;
  end;

{ TOriginalCircuits }

class function TOriginalCircuits.IsOriginal(const ALevelName: string; ACrc: Cardinal): Boolean;
begin
  if SameText(ALevelName, 'E1M1') then
    Result := ACrc = $46FC71D9
  else if SameText(ALevelName, 'E1M2') then
    Result := ACrc = $94F91B53
  else if SameText(ALevelName, 'E1M3') then
    Result := ACrc = $75100E6E
  else if SameText(ALevelName, 'E1M4') then
    Result := ACrc = $30E731A9
  else if SameText(ALevelName, 'E1M5') then
    Result := ACrc = $876CC30C
  else if SameText(ALevelName, 'E1M6') then
    Result := ACrc = $AF4B978F
  else if SameText(ALevelName, 'E1M7') then
    Result := ACrc = $9308DFE6
  else if SameText(ALevelName, 'E1M8') then
    Result := ACrc = $EE9E2AA1
  else
    Result := False;
end;

{ TLevelAssembly }

constructor TLevelAssembly.Create(AScale: Integer);
begin
  inherited Create;
  FScale := AScale;
  FThings := TList<TWadThing>.Create;
  FLines := TList<TWadLinedef>.Create;
  FSides := TList<TWadSidedef>.Create;
  FVertices := TList<TWadVertex>.Create;
  FSectors := TList<TWadSector>.Create;
end;

destructor TLevelAssembly.Destroy;
begin
  FSectors.Free;
  FVertices.Free;
  FSides.Free;
  FLines.Free;
  FThings.Free;
  inherited Destroy;
end;

function TLevelAssembly.Name8(const AName: string): TWadName8;
var
  LIndex: Integer;
begin
  if Length(AName) > SizeOf(TWadName8) then
    raise ESpeedException.CreateFmt('The name %s is longer than 8 characters', [AName]);
  FillChar(Result, SizeOf(Result), 0);
  for LIndex := 1 to Length(AName) do
    Result[LIndex - 1] := AnsiChar(Ord(AName[LIndex]) and $FF);
end;

procedure TLevelAssembly.AddThing(AX, AY, AAngle: Integer; AThingType: Word);
begin
  AddThingUntranslated(FScale * AX, FScale * AY, AAngle, AThingType);
end;

procedure TLevelAssembly.AddThingUntranslated(AX, AY, AAngle: Integer; AThingType: Word);
var
  LThing: TWadThing;
begin
  // the coordinates are 16 bits in the lump, as they were in the old record
  LThing.X := SmallInt(AX);
  LThing.Y := SmallInt(AY);
  LThing.Angle := SmallInt(AAngle);
  LThing.ThingType := SmallInt(AThingType);
  LThing.Options := THING_OPTIONS;
  FThings.Add(LThing);
end;

function TLevelAssembly.AddSector(AFloorHeight, ACeilingHeight: Integer; const AFloorTexture,
  ACeilingTexture: string): Integer;
var
  LSector: TWadSector;
begin
  LSector.FloorHeight := SmallInt(AFloorHeight);
  LSector.CeilingHeight := SmallInt(ACeilingHeight);
  LSector.FloorTexture := Name8(AFloorTexture);
  LSector.CeilingTexture := Name8(ACeilingTexture);
  LSector.LightLevel := 255;
  LSector.Special := 0;
  LSector.Tag := 0;
  Result := FSectors.Add(LSector);
end;

function TLevelAssembly.AddVertex(AX, AY: Integer): Integer;
var
  LIndex: Integer;
  LScaledX: Integer;
  LScaledY: Integer;
  LVertex: TWadVertex;
begin
  LScaledX := SmallInt(AX) * FScale;
  LScaledY := SmallInt(AY) * FScale;
  for LIndex := 0 to FVertices.Count - 1 do
    if (FVertices[LIndex].X = LScaledX) and (FVertices[LIndex].Y = LScaledY) then
      Exit(LIndex);
  LVertex.X := SmallInt(LScaledX);
  LVertex.Y := SmallInt(LScaledY);
  Result := FVertices.Add(LVertex);
end;

function TLevelAssembly.AddSide(const ATop, ABottom, AMiddle: string; ASector: Integer): Integer;

  function OrDash(const AName: string): string;
  begin
    if AName = '' then
      Result := '-'
    else
      Result := AName;
  end;

var
  LSide: TWadSidedef;
begin
  LSide.TextureOffset := 0;
  LSide.RowOffset := 0;
  LSide.TopTexture := Name8(OrDash(ATop));
  LSide.BottomTexture := Name8(OrDash(ABottom));
  LSide.MiddleTexture := Name8(OrDash(AMiddle));
  LSide.Sector := SmallInt(ASector);
  Result := FSides.Add(LSide);
end;

function TLevelAssembly.AddLine(AX1, AY1, AX2, AY2: Integer): Integer;
var
  LIndex: Integer;
  LVertex1: Integer;
  LVertex2: Integer;
  LLine: TWadLinedef;
begin
  LVertex1 := AddVertex(AX1, AY1);
  LVertex2 := AddVertex(AX2, AY2);
  // a line that joins the same two vertices, in either direction, is the same line
  for LIndex := 0 to FLines.Count - 1 do
  begin
    if (FLines[LIndex].Vertex1 = LVertex1) and (FLines[LIndex].Vertex2 = LVertex2) then
      Exit(LIndex);
    if (FLines[LIndex].Vertex1 = LVertex2) and (FLines[LIndex].Vertex2 = LVertex1) then
      Exit(LIndex);
  end;
  LLine.Vertex1 := SmallInt(LVertex1);
  LLine.Vertex2 := SmallInt(LVertex2);
  LLine.Flags := ML_MAPPED;
  LLine.Special := 0;
  LLine.Tag := 0;
  LLine.SideNumber[0] := -1;
  LLine.SideNumber[1] := -1;
  Result := FLines.Add(LLine);
end;

procedure TLevelAssembly.SetLineFlags(ALine, AFlags: Integer);
var
  LLine: TWadLinedef;
begin
  LLine := FLines[ALine];
  LLine.Flags := SmallInt(AFlags);
  FLines[ALine] := LLine;
end;

procedure TLevelAssembly.SetLineSide(ALine, ASide, ASideNumber: Integer);
var
  LLine: TWadLinedef;
begin
  LLine := FLines[ALine];
  LLine.SideNumber[ASide] := SmallInt(ASideNumber);
  FLines[ALine] := LLine;
end;

procedure TLevelAssembly.MakeMainSector(const APrefix: string);
var
  LLine: Integer;
  LLines: array[0..3] of Integer;
begin
  FMainSector := AddSector(0, 256, 'FMAP' + APrefix, 'F_SKY1');
  LLines[0] := AddLine(0, 0, 0, MAP_SIDE);
  LLines[1] := AddLine(0, MAP_SIDE, MAP_SIDE, MAP_SIDE);
  LLines[2] := AddLine(MAP_SIDE, MAP_SIDE, MAP_SIDE, 0);
  LLines[3] := AddLine(MAP_SIDE, 0, 0, 0);
  for LLine := 0 to 3 do
  begin
    SetLineFlags(LLines[LLine], ML_MAPPED or ML_AUTOMAPIGNOGE);
    SetLineSide(LLines[LLine], 0, AddSide('', '', '', FMainSector));
  end;
end;

procedure TLevelAssembly.MakeExtraSector(const AExtraFlat: string);
var
  LSector: Integer;
  LLine: Integer;
  LInner: array[0..3] of Integer;
  LOuter: array[0..3] of Integer;
begin
  LSector := AddSector(0, 0, AExtraFlat, 'F_SKY1');
  LInner[0] := AddLine(0, 0, 0, MAP_SIDE);
  LInner[1] := AddLine(0, MAP_SIDE, MAP_SIDE, MAP_SIDE);
  LInner[2] := AddLine(MAP_SIDE, MAP_SIDE, MAP_SIDE, 0);
  LInner[3] := AddLine(MAP_SIDE, 0, 0, 0);
  for LLine := 0 to 3 do
    SetLineSide(LInner[LLine], 1, AddSide('', '', '', LSector));
  for LLine := 0 to 3 do
    SetLineFlags(LInner[LLine], ML_BLOCKING or ML_TWOSIDED or ML_AUTOMAPIGNOGE);

  LOuter[0] := AddLine(-EXTRA_SECTOR_OFFSET, -EXTRA_SECTOR_OFFSET, -EXTRA_SECTOR_OFFSET,
    MAP_SIDE + EXTRA_SECTOR_OFFSET);
  LOuter[1] := AddLine(-EXTRA_SECTOR_OFFSET, MAP_SIDE + EXTRA_SECTOR_OFFSET,
    MAP_SIDE + EXTRA_SECTOR_OFFSET, MAP_SIDE + EXTRA_SECTOR_OFFSET);
  LOuter[2] := AddLine(MAP_SIDE + EXTRA_SECTOR_OFFSET, MAP_SIDE + EXTRA_SECTOR_OFFSET,
    MAP_SIDE + EXTRA_SECTOR_OFFSET, -EXTRA_SECTOR_OFFSET);
  LOuter[3] := AddLine(MAP_SIDE + EXTRA_SECTOR_OFFSET, -EXTRA_SECTOR_OFFSET, -EXTRA_SECTOR_OFFSET,
    -EXTRA_SECTOR_OFFSET);
  for LLine := 0 to 3 do
  begin
    SetLineFlags(LOuter[LLine], FLines[LOuter[LLine]].Flags or ML_AUTOMAPIGNOGE);
    SetLineSide(LOuter[LLine], 0, AddSide('', '', '', LSector));
  end;
end;

procedure TLevelAssembly.ReadMapFile(const AData: TBytes);
var
  LThing: TWadThing;
  LDisk: TSpeedDiskThing;
  LCount: Integer;
  LIndex: Integer;
  LType: Integer;
  LAngle: Integer;
begin
  LCount := (Length(AData) - SizeOf(TSpeedDiskMap)) div SizeOf(TSpeedDiskThing);
  for LIndex := 0 to LCount - 1 do
  begin
    Move(AData[SizeOf(TSpeedDiskMap) + LIndex * SizeOf(TSpeedDiskThing)], LDisk, SizeOf(LDisk));
    LType := LDisk.ThingType;
    if LType > 240 shl 8 then
      LType := (LType and $FF00) shr 8
    else
      LType := ((LType and $FF00) shr 4) + (LType and $0F);
    LAngle := 360 - Round((LDisk.Angle / 65536) * 360);
    if LAngle < 0 then
      LAngle := LAngle + 360;
    AddThing(MAP_SIDE - LDisk.Y, MAP_SIDE - LDisk.X, LAngle, Word(LType));
  end;
  // the first star position is the start of the player
  for LIndex := 0 to FThings.Count - 1 do
    if Word(FThings[LIndex].ThingType) = THING_STAR_POSITION then
    begin
      LThing := FThings[LIndex];
      LThing.ThingType := THING_PLAYER_START;
      FThings[LIndex] := LThing;
      Break;
    end;
end;

procedure TLevelAssembly.ReadPathFile(const AData: TBytes; ACount: Integer);
var
  LPoint: TSpeedPathPoint;
  LIndex: Integer;
  LAngle: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    Move(AData[PATH_HEADER_SIZE + LIndex * SizeOf(TSpeedPathPoint)], LPoint, SizeOf(LPoint));
    LAngle := Round((LPoint.Direction / 65536) * 360) - 90;
    if LAngle < 0 then
      LAngle := LAngle + 360;
    AddThing(Integer(MAP_SIDE - Int64(LPoint.Y div 1048576)), Integer(MAP_SIDE - Int64(LPoint.X div 1048576)),
      LAngle, THING_PATH);
  end;
end;

procedure TLevelAssembly.ReadSectorFile(const AData: TBytes; const ALog: ILog);
var
  LText: string;
  LIndex: Integer;
  LScanner: TScriptScanner;
  LVertexCount: Integer;
  LSectorCount: Integer;
  LLineCount: Integer;
  LVertexX: TArray<Integer>;
  LVertexY: TArray<Integer>;
  LLines: TArray<TSpeedWallLine>;
  LLineIndex: Integer;
  LSector: Integer;
  LSectorLines: Integer;
  LInSector: Integer;
  LLine: Integer;
  LAdded: Integer;
  LV1: Integer;
  LV2: Integer;

  function NextString: string;
  begin
    if not LScanner.MustGetString then
      raise ESpeedException.Create('The sectors file ends too early');
    Result := LScanner.AsString;
  end;

  function NextInteger: Integer;
  begin
    Result := TSpeedNames.ToInteger(NextString);
  end;

begin
  // an empty string "" is made "-": the scanner would skip a word that has nothing in it
  LText := '';
  for LIndex := 0 to High(AData) do
  begin
    if (AData[LIndex] = Ord('"')) and (LIndex > 0) and (AData[LIndex - 1] = Ord('"')) then
      LText := LText + '-';
    if AData[LIndex] = 0 then
      LText := LText + ' '
    else
      LText := LText + Char(AData[LIndex]);
  end;

  LScanner := TScriptScanner.Create(LText, ALog);
  try
    if not LScanner.MustGetInteger then
      raise ESpeedException.Create('The sectors file has no number of vertices');
    LVertexCount := LScanner.AsInteger;
    if not LScanner.MustGetInteger then
      raise ESpeedException.Create('The sectors file has no number of sectors');
    LSectorCount := LScanner.AsInteger;
    if not LScanner.MustGetInteger then
      raise ESpeedException.Create('The sectors file has no number of lines');
    LLineCount := LScanner.AsInteger;
    if (LVertexCount < 0) or (LSectorCount < 0) or (LLineCount < 0) then
      raise ESpeedException.Create('The sectors file has a negative count');
    SetLength(LVertexX, LVertexCount);
    SetLength(LVertexY, LVertexCount);
    SetLength(LLines, LLineCount);

    NextString; // Vertices
    for LIndex := 0 to LVertexCount - 1 do
    begin
      // the first number is the y, the second the x, in 1/16 of a unit and mirrored
      LVertexY[LIndex] := MAP_SIDE - NextInteger div 16;
      LVertexX[LIndex] := MAP_SIDE - NextInteger div 16;
    end;

    NextString; // Sectors
    LLineIndex := 0;
    for LSector := 0 to LSectorCount - 1 do
    begin
      LSectorLines := NextInteger;
      NextInteger; // the flags of the sector
      for LInSector := 0 to LSectorLines - 1 do
      begin
        if LLineIndex >= LLineCount then
          raise ESpeedException.Create('The sectors file has more lines than it says');
        LLines[LLineIndex].Vertex1 := NextInteger;
        LLines[LLineIndex].Vertex2 := NextInteger;
        LLines[LLineIndex].Texture := NextString;
        NextInteger; // the other side of the line
        Inc(LLineIndex);
      end;
    end;
  finally
    LScanner.Free;
  end;

  // only the lines that the file has (the count of its header may be bigger)
  for LLine := 0 to LLineIndex - 1 do
    if LLines[LLine].Texture <> '-' then
    begin
      LV1 := LLines[LLine].Vertex1;
      LV2 := LLines[LLine].Vertex2;
      if (LV1 < 0) or (LV1 >= LVertexCount) or (LV2 < 0) or (LV2 >= LVertexCount) then
        raise ESpeedException.Create('A line of the sectors file joins a vertex that does not exist');
      LAdded := AddLine(LVertexX[LV1], LVertexY[LV1], LVertexX[LV2], LVertexY[LV2]);
      SetLineSide(LAdded, 0, AddSide('', '', SPEED_WALL_PREFIX + LLines[LLine].Texture, FMainSector));
      SetLineSide(LAdded, 1, AddSide('', '', SPEED_WALL_PREFIX + LLines[LLine].Texture, FMainSector));
      SetLineFlags(LAdded, ML_BLOCKING or ML_TWOSIDED or ML_DONTPEGBOTTOM or ML_MAPPED);
    end;
end;

procedure TLevelAssembly.MoveThing(AOldX, AOldY, ANewX, ANewY: Integer);
var
  LIndex: Integer;
  LThing: TWadThing;
begin
  for LIndex := 0 to FThings.Count - 1 do
    if (FThings[LIndex].X = AOldX) and (FThings[LIndex].Y = AOldY) then
    begin
      LThing := FThings[LIndex];
      LThing.X := SmallInt(ANewX);
      LThing.Y := SmallInt(ANewY);
      FThings[LIndex] := LThing;
    end;
end;

procedure TLevelAssembly.MoveVertex(AOldX, AOldY, ANewX, ANewY: Integer);
var
  LIndex: Integer;
  LVertex: TWadVertex;
begin
  for LIndex := 0 to FVertices.Count - 1 do
    if (FVertices[LIndex].X = AOldX) and (FVertices[LIndex].Y = AOldY) then
    begin
      LVertex := FVertices[LIndex];
      LVertex.X := SmallInt(ANewX);
      LVertex.Y := SmallInt(ANewY);
      FVertices[LIndex] := LVertex;
    end;
end;

procedure TLevelAssembly.ApplyFixes(const ALevelName: string);
begin
  if ALevelName = 'E1M1' then
  begin
    // spectators (the start)
    MoveThing(3656, 716, 3604, 716);
    MoveThing(3904, 712, 3808, 716);
    MoveThing(4160, 712, 4010, 716);
    MoveThing(4416, 712, 4214, 716);
    MoveThing(4672, 712, 4418, 716);
    MoveThing(4936, 712, 4622, 716);
    MoveThing(5184, 712, 4826, 716);
    MoveThing(5448, 712, 5030, 716);
    // more spectators
    AddThingUntranslated(5234, 716, 90, 82);
    AddThingUntranslated(5438, 716, 90, 82);
    // spectators
    MoveThing(6528, 5696, 6592, 5760);
    MoveThing(6700, 5500, 6778, 5574);
    MoveThing(6880, 5320, 6964, 5388);
    // trees (behind the spectators)
    MoveThing(7136, 5520, 7216, 5586);
    MoveThing(7048, 5552, 7040, 5760);
    MoveThing(6944, 5672, 6944, 5856);
    MoveThing(6848, 5760, 6848, 5952);
    MoveThing(6792, 5840, 6752, 6048);
    // white buildings (length = 244)
    MoveThing(5848, 6232, 5856, 6240);
    MoveThing(5600, 6216, 5612, 6240);
    MoveThing(5320, 6216, 5368, 6240);
    // advertisement
    MoveThing(4568, 5920, 4576, 5920);
    MoveThing(4440, 5792, 4384, 5728);
    MoveThing(4168, 5544, 4192, 5536);
    // white buildings (length = 244)
    MoveThing(3408, 4168, 3392, 4192);
    MoveThing(3656, 4176, 3636, 4192);
    MoveThing(3904, 4168, 3880, 4192);
    MoveThing(4144, 4176, 4124, 4192);
    // spectators
    MoveThing(2472, 5200, 2432, 5280);
    MoveThing(2612, 5076, 2618, 5094);
    MoveThing(2720, 4960, 2804, 4908);
    MoveVertex(2376, 5586, 2400, 5600);
    // advertisements
    MoveVertex(424, 1954, 424, 1980);
    MoveVertex(616, 984, 620, 970);
    MoveVertex(970, 902, 1211, 832);
    // white buildings (length = 244)
    MoveThing(1728, 712, 1732, 712);
    MoveThing(436, 704, 452, 712);
  end
  else if ALevelName = 'E1M8' then
  begin
    // move the race path to the correct place
    MoveThing(1776, 3210, 1792, 3072);
    MoveThing(1776, 3550, 1766, 3364);
  end;
end;

function TLevelAssembly.ToBytes<T>(const AList: TList<T>): TBytes;
var
  LItems: TArray<T>;
begin
  SetLength(Result, AList.Count * SizeOf(T));
  if AList.Count > 0 then
  begin
  LItems := AList.List;
  Move(LItems[0], Result[0], Length(Result));
  end;
end;

{ TSpeedLevelBuilder }

constructor TSpeedLevelBuilder.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
end;

function TSpeedLevelBuilder.Build(const ALevelName, APrefix: string; const AMapData, ASectorData,
  APathData: TBytes; AScale: Integer; const AExtraFlat: string; const AWad: IGameWadComposer): Boolean;
var
  LAssembly: TLevelAssembly;
  LPathCount: Integer;
  LPathBytes: TBytes;
  LOriginal: Boolean;
begin
  Result := False;
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  if Length(AMapData) < SizeOf(TSpeedDiskMap) then
  begin
    FLog.Warning(Format('Speed: the file of the circuit %s is too short (%d bytes)', [ALevelName, Length(AMapData)]));
    Exit;
  end;

  // the path: the number of points is a word of the header, the points start at $100
  LPathCount := 0;
  if (Length(APathData) >= PATH_HEADER_SIZE) and (PCardinal(@APathData[0])^ = SPEED_PATH_SIGNATURE) then
  begin
    LPathCount := PWord(@APathData[PATH_COUNT_OFFSET])^;
    if PATH_HEADER_SIZE + LPathCount * SizeOf(TSpeedPathPoint) > Length(APathData) then
    begin
      FLog.Warning(Format('Speed: the path of the circuit %s has fewer points than it says', [ALevelName]));
      LPathCount := (Length(APathData) - PATH_HEADER_SIZE) div SizeOf(TSpeedPathPoint);
    end;
  end
  else
    FLog.Warning(Format('Speed: the path of the circuit %s has no signature', [ALevelName]));

  LOriginal := TOriginalCircuits.IsOriginal(ALevelName, TCrc32.Calculate(AMapData[0], Length(AMapData)));
  LAssembly := TLevelAssembly.Create(AScale);
  try
    try
      LAssembly.MakeMainSector(APrefix);
      // the floor of the main sector is the picture of the circuit
      LAssembly.ReadMapFile(AMapData);
      LAssembly.ReadPathFile(APathData, LPathCount);
      LAssembly.ReadSectorFile(ASectorData, FLog);
      LAssembly.MakeExtraSector(AExtraFlat);
    except
      on E: ESpeedException do
      begin
        FLog.Warning(Format('Speed: the circuit %s was left out: %s', [ALevelName, E.Message]));
        Exit;
      end;
    end;
    if LOriginal then
      LAssembly.ApplyFixes(ALevelName);
    // the start of the race
    LAssembly.AddThing(0, 0, 0, THING_RACE_START);

    SetLength(LPathBytes, LPathCount * SizeOf(TSpeedPathPoint));
    if LPathCount > 0 then
      Move(APathData[PATH_HEADER_SIZE], LPathBytes[0], Length(LPathBytes));

    AWad.AddMarker(ALevelName);
    AWad.AddLump(LEVEL_LUMP_THINGS, LAssembly.ToBytes<TWadThing>(LAssembly.Things));
    AWad.AddLump(LEVEL_LUMP_LINEDEFS, LAssembly.ToBytes<TWadLinedef>(LAssembly.Lines));
    AWad.AddLump(LEVEL_LUMP_SIDEDEFS, LAssembly.ToBytes<TWadSidedef>(LAssembly.Sides));
    AWad.AddLump(LEVEL_LUMP_VERTEXES, LAssembly.ToBytes<TWadVertex>(LAssembly.Vertices));
    AWad.AddMarker(LEVEL_LUMP_SEGS);
    AWad.AddMarker(LEVEL_LUMP_SSECTORS);
    AWad.AddMarker(LEVEL_LUMP_NODES);
    AWad.AddLump(LEVEL_LUMP_SECTORS, LAssembly.ToBytes<TWadSector>(LAssembly.Sectors));
    AWad.AddMarker(LEVEL_LUMP_REJECT);
    AWad.AddMarker(LEVEL_LUMP_BLOCKMAP);
    AWad.AddLump('PATH', LPathBytes);
  finally
    LAssembly.Free;
  end;
  Result := True;
end;

end.
