{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - a small fake world for the scripts   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.FakeWorld;

interface

uses
  System.SysUtils, System.Classes;

type
  PFakeSector = ^TFakeSector;
  /// <summary>The sound origin is the first field: a pointer to the sector is its origin</summary>
  TFakeSector = record
    SoundOrg: Integer;
    Tag: Integer;
    FloorPic: Integer;
    CeilingPic: Integer;
    Busy: Boolean;
  end;

  PFakeLine = ^TFakeLine;
  TFakeLine = record
    Special: Integer;
    Tag: Integer;
    Flags: Integer;
    Args: array[0..4] of Integer;
    SideNumbers: array[0..1] of Integer;
    FrontSector: PFakeSector;
  end;

  TFakeSide = record
    TopTexture: Integer;
    MiddleTexture: Integer;
    BottomTexture: Integer;
  end;

  PFakeThing = ^TFakeThing;
  TFakeThing = record
    Tid: Integer;
    ThingType: Integer;
    Dead: Boolean;
  end;

const
  FAKE_SECTOR_COUNT = 4;
  FAKE_LINE_COUNT = 5;
  FAKE_SIDE_COUNT = 10;
  FAKE_THING_COUNT = 6;
  FAKE_POLYOBJECT_COUNT = 3;
  FAKE_BLOCKING = 1;

type
  /// <summary>
  ///   A little world with sectors, lines, sides and things that the old interpreter and the new
  ///   host both act on, and a trace of everything that happens to it. The old interpreter (a copy
  ///   of the code of the engine) and the new one write the same lines to the trace and have to
  ///   leave the world in the same state
  /// </summary>
  TFakeWorld = class
  strict private
    FTrace: TStringList;
    FSectors: array[0..FAKE_SECTOR_COUNT - 1] of TFakeSector;
    FLines: array[0..FAKE_LINE_COUNT - 1] of TFakeLine;
    FSides: array[0..FAKE_SIDE_COUNT - 1] of TFakeSide;
    FThings: array[0..FAKE_THING_COUNT - 1] of TFakeThing;
    FPolyobjectBusy: array[0..FAKE_POLYOBJECT_COUNT - 1] of Boolean;
    FMap: Integer;
    FLevelTime: Integer;
    FSkill: Integer;
    FGameType: Integer;
    FPlayerCount: Integer;
    FRandomIndex: Integer;
    FRandomValues: TArray<Integer>;
    function GetSector(AIndex: Integer): PFakeSector;
    function GetLine(AIndex: Integer): PFakeLine;
    function GetThing(AIndex: Integer): PFakeThing;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Trace: TStringList read FTrace;
    procedure Log(const AText: string);
    property Sectors[AIndex: Integer]: PFakeSector read GetSector;
    property Lines[AIndex: Integer]: PFakeLine read GetLine;
    property Things[AIndex: Integer]: PFakeThing read GetThing;
    property Map: Integer read FMap write FMap;
    property LevelTime: Integer read FLevelTime write FLevelTime;
    property Skill: Integer read FSkill write FSkill;
    property GameType: Integer read FGameType write FGameType;
    property PlayerCount: Integer read FPlayerCount write FPlayerCount;
    procedure SetRandomValues(const AValues: TArray<Integer>);
    function NextRandom: Integer;
    procedure SetSectorBusy(AIndex: Integer; ABusy: Boolean);
    procedure SetPolyobjectBusy(AIndex: Integer; ABusy: Boolean);
    function IsPolyobjectBusy(AIndex: Integer): Boolean;
    function IsTagBusy(ATag: Integer): Boolean;
    /// <summary>The next sector with the tag after the position; -1 at the end (the position starts at -1)</summary>
    function FindSector(ATag: Integer; var APosition: Integer): Integer;
    /// <summary>The next line with the tag; nil at the end</summary>
    function FindLine(ATag: Integer; var APosition: Integer): PFakeLine;
    /// <summary>The next thing with the tid; nil at the end</summary>
    function FindThing(ATid: Integer; var APosition: Integer): PFakeThing;
    function SectorIndexOf(AOrigin: Pointer): Integer;
    function LineIndexOf(ALine: Pointer): Integer;
    function ThingIndexOf(AThing: Pointer): Integer;
    /// <summary>What a pointer given to the script is, for the trace: "nil", "line 2", "thing 1" ...</summary>
    function Describe(APointer: Pointer): string;
    function CountThings(AThingType, ATid: Integer): Integer;
    /// <summary>A number for a name (a flat, a texture, a sound): the same for the same name</summary>
    class function NameNumber(const AName: string): Integer; static;
    function SideOf(ALine: PFakeLine; ASide: Integer): Integer;
    procedure SetSideTexture(ASide, APosition, ATexture: Integer);
    /// <summary>The whole state of the world, in a few lines</summary>
    function Dump: string;
  end;

implementation

const
  SectorTags: array[0..FAKE_SECTOR_COUNT - 1] of Integer = (1, 2, 2, 3);
  LineTags: array[0..FAKE_LINE_COUNT - 1] of Integer = (1, 2, 2, 3, 0);
  ThingTids: array[0..FAKE_THING_COUNT - 1] of Integer = (5, 5, 6, 0, 0, 7);
  ThingTypes: array[0..FAKE_THING_COUNT - 1] of Integer = (1, 2, 1, 1, 3, 2);

{ TFakeWorld }

constructor TFakeWorld.Create;
begin
  inherited Create;
  FTrace := TStringList.Create;
  Reset;
end;

destructor TFakeWorld.Destroy;
begin
  FTrace.Free;
  inherited Destroy;
end;

procedure TFakeWorld.Reset;
var
  LIndex: Integer;
begin
  FTrace.Clear;
  FillChar(FSectors, SizeOf(FSectors), 0);
  FillChar(FLines, SizeOf(FLines), 0);
  FillChar(FSides, SizeOf(FSides), 0);
  FillChar(FThings, SizeOf(FThings), 0);
  FillChar(FPolyobjectBusy, SizeOf(FPolyobjectBusy), 0);
  for LIndex := 0 to FAKE_SECTOR_COUNT - 1 do
  begin
    FSectors[LIndex].Tag := SectorTags[LIndex];
    FSectors[LIndex].FloorPic := 10 + LIndex;
    FSectors[LIndex].CeilingPic := 20 + LIndex;
  end;
  for LIndex := 0 to FAKE_LINE_COUNT - 1 do
  begin
    FLines[LIndex].Tag := LineTags[LIndex];
    FLines[LIndex].Special := 100 + LIndex;
    FLines[LIndex].SideNumbers[0] := LIndex * 2;
    FLines[LIndex].SideNumbers[1] := LIndex * 2 + 1;
    FLines[LIndex].FrontSector := @FSectors[LIndex mod FAKE_SECTOR_COUNT];
  end;
  for LIndex := 0 to FAKE_THING_COUNT - 1 do
  begin
    FThings[LIndex].Tid := ThingTids[LIndex];
    FThings[LIndex].ThingType := ThingTypes[LIndex];
    FThings[LIndex].Dead := LIndex = 1;
  end;
  FMap := 1;
  FLevelTime := 0;
  FSkill := 2;
  FGameType := 0;
  FPlayerCount := 1;
  FRandomIndex := 0;
  FRandomValues := nil;
end;

procedure TFakeWorld.Log(const AText: string);
begin
  FTrace.Add(AText);
end;

function TFakeWorld.GetSector(AIndex: Integer): PFakeSector;
begin
  Result := @FSectors[AIndex];
end;

function TFakeWorld.GetLine(AIndex: Integer): PFakeLine;
begin
  Result := @FLines[AIndex];
end;

function TFakeWorld.GetThing(AIndex: Integer): PFakeThing;
begin
  Result := @FThings[AIndex];
end;

procedure TFakeWorld.SetRandomValues(const AValues: TArray<Integer>);
begin
  FRandomValues := AValues;
  FRandomIndex := 0;
end;

function TFakeWorld.NextRandom: Integer;
begin
  if Length(FRandomValues) = 0 then
    Result := (FRandomIndex * 37 + 11) and 255
  else
    Result := FRandomValues[FRandomIndex mod Length(FRandomValues)];
  Inc(FRandomIndex);
end;

procedure TFakeWorld.SetSectorBusy(AIndex: Integer; ABusy: Boolean);
begin
  FSectors[AIndex].Busy := ABusy;
end;

procedure TFakeWorld.SetPolyobjectBusy(AIndex: Integer; ABusy: Boolean);
begin
  FPolyobjectBusy[AIndex] := ABusy;
end;

function TFakeWorld.IsPolyobjectBusy(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FAKE_POLYOBJECT_COUNT) and FPolyobjectBusy[AIndex];
end;

function TFakeWorld.IsTagBusy(ATag: Integer): Boolean;
var
  LPosition: Integer;
begin
  LPosition := -1;
  while FindSector(ATag, LPosition) >= 0 do
    if FSectors[LPosition].Busy then
      Exit(True);
  Result := False;
end;

function TFakeWorld.FindSector(ATag: Integer; var APosition: Integer): Integer;
begin
  Inc(APosition);
  while (APosition < FAKE_SECTOR_COUNT) and (FSectors[APosition].Tag <> ATag) do
    Inc(APosition);
  if APosition >= FAKE_SECTOR_COUNT then
  begin
    APosition := -1;
    Result := -1;
  end
  else
    Result := APosition;
end;

function TFakeWorld.FindLine(ATag: Integer; var APosition: Integer): PFakeLine;
begin
  Inc(APosition);
  while (APosition < FAKE_LINE_COUNT) and (FLines[APosition].Tag <> ATag) do
    Inc(APosition);
  if APosition >= FAKE_LINE_COUNT then
    Result := nil
  else
    Result := @FLines[APosition];
end;

function TFakeWorld.FindThing(ATid: Integer; var APosition: Integer): PFakeThing;
begin
  Inc(APosition);
  while (APosition < FAKE_THING_COUNT) and (FThings[APosition].Tid <> ATid) do
    Inc(APosition);
  if APosition >= FAKE_THING_COUNT then
    Result := nil
  else
    Result := @FThings[APosition];
end;

function TFakeWorld.SectorIndexOf(AOrigin: Pointer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FAKE_SECTOR_COUNT - 1 do
    if AOrigin = @FSectors[LIndex] then
      Exit(LIndex);
  Result := -1;
end;

function TFakeWorld.LineIndexOf(ALine: Pointer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FAKE_LINE_COUNT - 1 do
    if ALine = @FLines[LIndex] then
      Exit(LIndex);
  Result := -1;
end;

function TFakeWorld.ThingIndexOf(AThing: Pointer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FAKE_THING_COUNT - 1 do
    if AThing = @FThings[LIndex] then
      Exit(LIndex);
  Result := -1;
end;

function TFakeWorld.Describe(APointer: Pointer): string;
begin
  if APointer = nil then
    Exit('nil');
  if LineIndexOf(APointer) >= 0 then
    Exit('line ' + IntToStr(LineIndexOf(APointer)));
  if SectorIndexOf(APointer) >= 0 then
    Exit('sector ' + IntToStr(SectorIndexOf(APointer)));
  if ThingIndexOf(APointer) >= 0 then
    Exit('thing ' + IntToStr(ThingIndexOf(APointer)));
  Result := 'unknown';
end;

function TFakeWorld.CountThings(AThingType, ATid: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to FAKE_THING_COUNT - 1 do
    if ((ATid = 0) or (FThings[LIndex].Tid = ATid)) and
      ((AThingType = 0) or (FThings[LIndex].ThingType = AThingType)) and
      not FThings[LIndex].Dead then
      Inc(Result);
end;

class function TFakeWorld.NameNumber(const AName: string): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to Length(AName) do
    Result := (Result * 31 + Ord(AName[LIndex])) and $FFFF;
end;

function TFakeWorld.SideOf(ALine: PFakeLine; ASide: Integer): Integer;
begin
  Result := ALine.SideNumbers[ASide and 1];
end;

procedure TFakeWorld.SetSideTexture(ASide, APosition, ATexture: Integer);
begin
  case APosition of
    1: FSides[ASide].MiddleTexture := ATexture;
    2: FSides[ASide].BottomTexture := ATexture;
  else
    FSides[ASide].TopTexture := ATexture;
  end;
end;

function TFakeWorld.Dump: string;
var
  LIndex: Integer;
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create;
  try
    for LIndex := 0 to FAKE_SECTOR_COUNT - 1 do
      LBuilder.AppendFormat('sector %d floor=%d ceiling=%d'#10,
        [LIndex, FSectors[LIndex].FloorPic, FSectors[LIndex].CeilingPic]);
    for LIndex := 0 to FAKE_LINE_COUNT - 1 do
      LBuilder.AppendFormat('line %d special=%d flags=%d args=%d,%d,%d,%d,%d'#10,
        [LIndex, FLines[LIndex].Special, FLines[LIndex].Flags, FLines[LIndex].Args[0],
        FLines[LIndex].Args[1], FLines[LIndex].Args[2], FLines[LIndex].Args[3],
        FLines[LIndex].Args[4]]);
    for LIndex := 0 to FAKE_SIDE_COUNT - 1 do
      LBuilder.AppendFormat('side %d top=%d middle=%d bottom=%d'#10,
        [LIndex, FSides[LIndex].TopTexture, FSides[LIndex].MiddleTexture,
        FSides[LIndex].BottomTexture]);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
