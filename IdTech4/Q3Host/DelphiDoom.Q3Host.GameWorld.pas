{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the world of the server game           }
{                                                                              }
{  Port of sv_world.c and of the entity functions of sv_game.c (SV_LinkEntity, }
{  SV_UnlinkEntity, SV_AreaEntities, SV_Trace, SV_ClipToEntity,                }
{  SV_ClipMoveToEntities, SV_PointContents, SV_EntityContact,                  }
{  SV_SetBrushModel, SV_inPVS, SV_AdjustAreaPortalState, SV_LocateGameData)    }
{  of the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.GameWorld;

// Overflow and range checks are off: addresses and counters are 32 bit words, as in the C.

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf,
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>
  ///   The entities of the game as the server sees them: the sharedEntity_t array that the module reports with
  ///   G_LOCATE_GAME_DATA lives in the data of the program, the server keeps beside it the svEntity_t of each (areas,
  ///   clusters, the sector of the world tree). The sector tree is the one of sv_world.c (AREA_DEPTH 4, 64
  ///   nodes), so the entities come out of G_ENTITIES_IN_BOX in the same order. The map is the shared clipmap
  ///   (the world tree is built again when the map changes). Every method takes the memory of the machine of
  ///   the module: the entity pointers are addresses in it. Reads outside the data of the program raise
  ///   EQvmExecutionException where the C would read the memory of the host
  /// </summary>
  TQ3GameWorld = class
  public
    const
      MAX_GENTITIES = 1024;
      ENTITYNUM_NONE = 1023;
      ENTITYNUM_WORLD = 1022;
      SVF_CAPSULE = $400;
      SVF_BOT = 8;
      SOLID_BMODEL = $FFFFFF;
      CONTENTS_SOLID = 1;
      CONTENTS_BODY = $2000000;
      AREA_DEPTH = 4;
      AREA_NODES = 64;
      MAX_ENT_CLUSTERS = 16;
      MAX_TOTAL_ENT_LEAFS = 128;
      // the layout of sharedEntity_t (Tests\Data\Q3Host\layout.golden.txt; entityShared_t starts with its own
      // entityState_t in g_public.h, so r.linked is at 208 + 208)
      OFFSET_NUMBER = 0;
      OFFSET_ORIGIN = 92;
      OFFSET_ANGLES = 116;
      OFFSET_MODELINDEX = 160;
      OFFSET_SOLID = 176;
      OFFSET_LINKED = 416;
      OFFSET_LINKCOUNT = 420;
      OFFSET_SVFLAGS = 424;
      OFFSET_BMODEL = 432;
      OFFSET_MINS = 436;
      OFFSET_MAXS = 448;
      OFFSET_CONTENTS = 460;
      OFFSET_ABSMIN = 464;
      OFFSET_ABSMAX = 476;
      OFFSET_CURRENTORIGIN = 488;
      OFFSET_CURRENTANGLES = 500;
      OFFSET_OWNERNUM = 512;
    type
      /// <summary>svEntity_t: what the server knows of an entity beyond what the game shares</summary>
      TSvEntity = record
        NumClusters: Integer;
        ClusterNums: array[0..MAX_ENT_CLUSTERS - 1] of Integer;
        LastCluster: Integer;
        AreaNum, AreaNum2: Integer;
        Sector: Integer;
        NextInSector: Integer;
      end;
  strict private
    type
      TSector = record
        Axis: Integer;
        Dist: Single;
        Children: array[0..1] of Integer;
        FirstEntity: Integer;
      end;
    var
      FClipMap: IQ3HostClipMap;
      FConsole: IQ3HostConsole;
      FEntities, FEntityCount, FEntitySize, FClients, FClientSize: Integer;
      FSv: array[0..MAX_GENTITIES - 1] of TSvEntity;
      FSectors: array[0..AREA_NODES - 1] of TSector;
      FSectorCount: Integer;
      FBuiltFor: IQ3CollisionModel;
    function Model: IQ3CollisionModel;
    procedure ResetEntities;
    function EntityAddress(ANumber: Integer): Integer;
    function NumberOf(const AMemory: IQvmMemory; AAddress: Integer): Integer;
    function ReadFloat(const AMemory: IQvmMemory; AAddress: Integer): Single;
    function ReadVec(const AMemory: IQvmMemory; AAddress: Integer): TQ3Vec3;
    procedure WriteVec(const AMemory: IQvmMemory; AAddress: Integer; const AValue: TQ3Vec3);
    procedure Print(const AText: AnsiString);
    function CreateSector(ADepth: Integer; const AMins, AMaxs: TQ3Vec3): Integer;
    procedure EnsureWorld;
    function ClipHandleForEntity(const AMemory: IQvmMemory; AAddress: Integer): Integer;
    procedure AreaEntitiesRecursive(const AMemory: IQvmMemory; ANode: Integer; const AMins, AMaxs: TQ3Vec3;
      AMaxCount: Integer; var AList: TArray<Integer>; var ACount: Integer);
    procedure UnlinkNumber(const AMemory: IQvmMemory; ANumber: Integer);
  public
    constructor Create(const AClipMap: IQ3HostClipMap; const AConsole: IQ3HostConsole);
    /// <summary>SV_LocateGameData</summary>
    procedure LocateGameData(AEntities, AEntityCount, AEntitySize, AClients, AClientSize: Integer);
    /// <summary>SV_ClearWorld: the sector tree of the map; also done by itself when the map changed</summary>
    procedure ClearWorld;
    /// <summary>SV_LinkEntity</summary>
    procedure LinkEntity(const AMemory: IQvmMemory; AAddress: Integer);
    /// <summary>SV_UnlinkEntity</summary>
    procedure UnlinkEntity(const AMemory: IQvmMemory; AAddress: Integer);
    /// <summary>SV_AreaEntities: the numbers of the entities whose absmin / absmax touch the box, in the order of the tree</summary>
    function AreaEntities(const AMemory: IQvmMemory; const AMins, AMaxs: TQ3Vec3;
      AMaxCount: Integer): TArray<Integer>;
    /// <summary>SV_Trace: the box moves through the world and the linked entities; mins and maxs are the zero vector when null</summary>
    function Trace(const AMemory: IQvmMemory; const AStart, AMins, AMaxs, AEnd: TQ3Vec3; APassEntityNum,
      AContentMask: Integer; ACapsule: Boolean): TQ3Trace;
    /// <summary>SV_PointContents</summary>
    function PointContents(const AMemory: IQvmMemory; const APoint: TQ3Vec3; APassEntityNum: Integer): Integer;
    /// <summary>SV_EntityContact: the box (mins, maxs at the origin) starts inside the entity</summary>
    function EntityContact(const AMemory: IQvmMemory; const AMins, AMaxs: TQ3Vec3; AEntityAddress: Integer;
      ACapsule: Boolean): Boolean;
    /// <summary>SV_SetBrushModel: "*n" is the inline model n; the entity is linked</summary>
    procedure SetBrushModel(const AMemory: IQvmMemory; AEntityAddress: Integer; const AName: AnsiString);
    /// <summary>SV_inPVS and SV_inPVSIgnorePortals (AIgnorePortals True)</summary>
    function InPvs(const AFirst, ASecond: TQ3Vec3; AIgnorePortals: Boolean): Boolean;
    /// <summary>SV_AdjustAreaPortalState</summary>
    procedure AdjustAreaPortalState(const AMemory: IQvmMemory; AEntityAddress: Integer; AOpen: Boolean);
    /// <summary>cl->gentity = SV_GentityNum( i ); cl->gentity->s.number = i (SV_BotAllocateClient)</summary>
    procedure SetEntityNumber(const AMemory: IQvmMemory; AClient: Integer);
    /// <summary>cl->gentity->r.svFlags &= ~SVF_BOT (SV_BotFreeClient)</summary>
    procedure ClearBotFlag(const AMemory: IQvmMemory; AClient: Integer);
    /// <summary>The svEntity of an entity number (areas and clusters), for tests</summary>
    function SvEntity(ANumber: Integer): TSvEntity;
  end;

implementation

uses
  System.Math, DelphiDoom.Qvm.Types, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.TraceMemory;

resourcestring
  SBadEntity = 'SV_SvEntityForGentity: bad gEnt';
  SNullBrushName = 'SV_SetBrushModel: NULL';
  SNotBrushModel = 'SV_SetBrushModel: %s isn''t a brush model';
  SNoMapLoaded = 'The world was used before a map was loaded';

function Narrow(AValue: Double): Single; inline;
begin
  Result := AValue;
end;

function Atoi(const AText: AnsiString): Integer;
var
  LIndex: Integer;
  LNegative: Boolean;
  LValue: Int64;
begin
  LIndex := 1;
  while (LIndex <= Length(AText)) and (AText[LIndex] in [#9..#13, ' ']) do
    Inc(LIndex);
  LNegative := False;
  if (LIndex <= Length(AText)) and (AText[LIndex] in ['+', '-']) then
  begin
    LNegative := AText[LIndex] = '-';
    Inc(LIndex);
  end;
  LValue := 0;
  while (LIndex <= Length(AText)) and (AText[LIndex] in ['0'..'9']) do
  begin
    LValue := LValue * 10 + (Ord(AText[LIndex]) - Ord('0'));
    if LValue > High(Cardinal) then
      LValue := LValue and High(Cardinal);
    Inc(LIndex);
  end;
  if LNegative then
    LValue := -LValue;
  Result := Integer(LValue and High(Cardinal));
end;

constructor TQ3GameWorld.Create(const AClipMap: IQ3HostClipMap; const AConsole: IQ3HostConsole);
begin
  inherited Create;
  FClipMap := AClipMap;
  FConsole := AConsole;
  ResetEntities;
end;

procedure TQ3GameWorld.ResetEntities;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_GENTITIES - 1 do
  begin
    FSv[LIndex] := Default(TSvEntity);
    FSv[LIndex].Sector := -1;
    FSv[LIndex].NextInSector := -1;
    FSv[LIndex].AreaNum := -1;
    FSv[LIndex].AreaNum2 := -1;
  end;
end;

function TQ3GameWorld.Model: IQ3CollisionModel;
begin
  Result := FClipMap.Model;
  if not Assigned(Result) then
    raise EQ3HostException.Create(SNoMapLoaded);
end;

procedure TQ3GameWorld.Print(const AText: AnsiString);
begin
  if Assigned(FConsole) then
    FConsole.Print(AText);
end;

function TQ3GameWorld.EntityAddress(ANumber: Integer): Integer;
begin
  Result := FEntities + FEntitySize * ANumber;
end;

function TQ3GameWorld.NumberOf(const AMemory: IQvmMemory; AAddress: Integer): Integer;
begin
  Result := AMemory.ReadInt32(AAddress + OFFSET_NUMBER);
  if (Result < 0) or (Result >= MAX_GENTITIES) then
    raise EQ3HostException.Create(SBadEntity);
end;

function TQ3GameWorld.ReadFloat(const AMemory: IQvmMemory; AAddress: Integer): Single;
var
  LBits: Integer;
begin
  LBits := AMemory.ReadInt32(AAddress);
  Result := PSingle(@LBits)^;
end;

function TQ3GameWorld.ReadVec(const AMemory: IQvmMemory; AAddress: Integer): TQ3Vec3;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    Result[LIndex] := ReadFloat(AMemory, AAddress + 4 * LIndex);
end;

procedure TQ3GameWorld.WriteVec(const AMemory: IQvmMemory; AAddress: Integer; const AValue: TQ3Vec3);
begin
  TQ3TraceMemory.WriteVec3(AMemory, AAddress, AValue);
end;

procedure TQ3GameWorld.LocateGameData(AEntities, AEntityCount, AEntitySize, AClients, AClientSize: Integer);
begin
  FEntities := AEntities;
  FEntityCount := AEntityCount;
  FEntitySize := AEntitySize;
  FClients := AClients;
  FClientSize := AClientSize;
end;

// SV_CreateworldSector: a uniformly subdivided tree for the size of the world
function TQ3GameWorld.CreateSector(ADepth: Integer; const AMins, AMaxs: TQ3Vec3): Integer;
var
  LNode, LAxis: Integer;
  LMins1, LMaxs1, LMins2, LMaxs2: TQ3Vec3;
begin
  LNode := FSectorCount;
  Inc(FSectorCount);
  FSectors[LNode].FirstEntity := -1;
  if ADepth = AREA_DEPTH then
  begin
    FSectors[LNode].Axis := -1;
    FSectors[LNode].Children[0] := -1;
    FSectors[LNode].Children[1] := -1;
    Exit(LNode);
  end;
  if (AMaxs[0] - AMins[0]) > (AMaxs[1] - AMins[1]) then
    LAxis := 0
  else
    LAxis := 1;
  FSectors[LNode].Axis := LAxis;
  FSectors[LNode].Dist := Narrow(0.5 * (Double(AMaxs[LAxis]) + Double(AMins[LAxis])));
  LMins1 := AMins;
  LMins2 := AMins;
  LMaxs1 := AMaxs;
  LMaxs2 := AMaxs;
  LMaxs1[LAxis] := FSectors[LNode].Dist;
  LMins2[LAxis] := FSectors[LNode].Dist;
  FSectors[LNode].Children[0] := CreateSector(ADepth + 1, LMins2, LMaxs2);
  FSectors[LNode].Children[1] := CreateSector(ADepth + 1, LMins1, LMaxs1);
  Result := LNode;
end;

procedure TQ3GameWorld.ClearWorld;
var
  LMins, LMaxs: TQ3Vec3;
begin
  FSectorCount := 0;
  ResetEntities;
  Model.ModelBounds(Model.InlineModel(0), LMins, LMaxs);
  CreateSector(0, LMins, LMaxs);
  FBuiltFor := Model;
end;

procedure TQ3GameWorld.EnsureWorld;
begin
  if FBuiltFor <> Model then
    ClearWorld;
end;

procedure TQ3GameWorld.UnlinkNumber(const AMemory: IQvmMemory; ANumber: Integer);
var
  LSector, LScan: Integer;
begin
  AMemory.WriteInt32(EntityAddress(ANumber) + OFFSET_LINKED, 0);
  LSector := FSv[ANumber].Sector;
  if LSector < 0 then
    Exit;
  FSv[ANumber].Sector := -1;
  if FSectors[LSector].FirstEntity = ANumber then
  begin
    FSectors[LSector].FirstEntity := FSv[ANumber].NextInSector;
    Exit;
  end;
  LScan := FSectors[LSector].FirstEntity;
  while LScan >= 0 do
  begin
    if FSv[LScan].NextInSector = ANumber then
    begin
      FSv[LScan].NextInSector := FSv[ANumber].NextInSector;
      Exit;
    end;
    LScan := FSv[LScan].NextInSector;
  end;
  Print('WARNING: SV_UnlinkEntity: not found in worldSector'#10);
end;

procedure TQ3GameWorld.UnlinkEntity(const AMemory: IQvmMemory; AAddress: Integer);
begin
  UnlinkNumber(AMemory, NumberOf(AMemory, AAddress));
end;

procedure TQ3GameWorld.LinkEntity(const AMemory: IQvmMemory; AAddress: Integer);
var
  LNumber, LNode, LIndex, LArea, LCluster, LCountLeafs, LLastLeaf, LI, LJ, LK: Integer;
  LMins, LMaxs, LOrigin, LAngles, LAbsMin, LAbsMax: TQ3Vec3;
  LLeafs: TArray<Integer>;
  LBModel: Boolean;
  LContents: Integer;
  LRadius, LCornerA, LCornerB: Single;
  LCorner: TQ3Vec3;
begin
  EnsureWorld;
  LNumber := NumberOf(AMemory, AAddress);
  if FSv[LNumber].Sector >= 0 then
    // unlink from the old position
    UnlinkNumber(AMemory, LNumber);

  LMins := ReadVec(AMemory, AAddress + OFFSET_MINS);
  LMaxs := ReadVec(AMemory, AAddress + OFFSET_MAXS);
  LBModel := AMemory.ReadInt32(AAddress + OFFSET_BMODEL) <> 0;
  LContents := AMemory.ReadInt32(AAddress + OFFSET_CONTENTS);

  // encode the size into the entityState_t for client prediction
  if LBModel then
    AMemory.WriteInt32(AAddress + OFFSET_SOLID, SOLID_BMODEL)
  else if (LContents and (CONTENTS_SOLID or CONTENTS_BODY)) <> 0 then
  begin
    // x/y are symmetric, z is not; z maxs can be negative
    LI := Trunc(LMaxs[0]);
    if LI < 1 then
      LI := 1;
    if LI > 255 then
      LI := 255;
    LJ := Trunc(-LMins[2]);
    if LJ < 1 then
      LJ := 1;
    if LJ > 255 then
      LJ := 255;
    LK := Trunc(Double(LMaxs[2]) + 32);
    if LK < 1 then
      LK := 1;
    if LK > 255 then
      LK := 255;
    AMemory.WriteInt32(AAddress + OFFSET_SOLID, (LK shl 16) or (LJ shl 8) or LI);
  end
  else
    AMemory.WriteInt32(AAddress + OFFSET_SOLID, 0);

  LOrigin := ReadVec(AMemory, AAddress + OFFSET_CURRENTORIGIN);
  LAngles := ReadVec(AMemory, AAddress + OFFSET_CURRENTANGLES);

  // set the abs box
  if LBModel and ((LAngles[0] <> 0) or (LAngles[1] <> 0) or (LAngles[2] <> 0)) then
  begin
    // expand for rotation: RadiusFromBounds
    for LIndex := 0 to 2 do
    begin
      LCornerA := Abs(LMins[LIndex]);
      LCornerB := Abs(LMaxs[LIndex]);
      if LCornerA > LCornerB then
        LCorner[LIndex] := LCornerA
      else
        LCorner[LIndex] := LCornerB;
    end;
    LRadius := Narrow(System.Sqrt(Double(LCorner[0]) * LCorner[0] + Double(LCorner[1]) * LCorner[1] +
      Double(LCorner[2]) * LCorner[2]));
    for LIndex := 0 to 2 do
    begin
      LAbsMin[LIndex] := Narrow(Double(LOrigin[LIndex]) - LRadius);
      LAbsMax[LIndex] := Narrow(Double(LOrigin[LIndex]) + LRadius);
    end;
  end
  else
    for LIndex := 0 to 2 do
    begin
      LAbsMin[LIndex] := Narrow(Double(LOrigin[LIndex]) + LMins[LIndex]);
      LAbsMax[LIndex] := Narrow(Double(LOrigin[LIndex]) + LMaxs[LIndex]);
    end;

  // movement is clipped an epsilon away from an edge: the box is one unit larger
  for LIndex := 0 to 2 do
  begin
    LAbsMin[LIndex] := Narrow(Double(LAbsMin[LIndex]) - 1);
    LAbsMax[LIndex] := Narrow(Double(LAbsMax[LIndex]) + 1);
  end;
  WriteVec(AMemory, AAddress + OFFSET_ABSMIN, LAbsMin);
  WriteVec(AMemory, AAddress + OFFSET_ABSMAX, LAbsMax);

  // link to PVS leafs
  FSv[LNumber].NumClusters := 0;
  FSv[LNumber].LastCluster := 0;
  FSv[LNumber].AreaNum := -1;
  FSv[LNumber].AreaNum2 := -1;

  // all the leafs, including solids
  LCountLeafs := Model.BoxLeafnums(LAbsMin, LAbsMax, MAX_TOTAL_ENT_LEAFS, LLeafs, LLastLeaf);
  // none inside the map: the entity is outside the world and is considered unlinked
  if LCountLeafs = 0 then
    Exit;

  for LIndex := 0 to LCountLeafs - 1 do
  begin
    LArea := Model.LeafArea(LLeafs[LIndex]);
    if LArea <> -1 then
    begin
      // doors may legally straggle two areas, nothing should ever need more than that
      if (FSv[LNumber].AreaNum <> -1) and (FSv[LNumber].AreaNum <> LArea) then
        FSv[LNumber].AreaNum2 := LArea
      else
        FSv[LNumber].AreaNum := LArea;
    end;
  end;

  // as many explicit clusters as fit
  FSv[LNumber].NumClusters := 0;
  LIndex := 0;
  while LIndex < LCountLeafs do
  begin
    LCluster := Model.LeafCluster(LLeafs[LIndex]);
    if LCluster <> -1 then
    begin
      FSv[LNumber].ClusterNums[FSv[LNumber].NumClusters] := LCluster;
      Inc(FSv[LNumber].NumClusters);
      if FSv[LNumber].NumClusters = MAX_ENT_CLUSTERS then
        Break;
    end;
    Inc(LIndex);
  end;
  // a last cluster if the list was cut
  if LIndex <> LCountLeafs then
    FSv[LNumber].LastCluster := Model.LeafCluster(LLastLeaf);

  AMemory.WriteInt32(AAddress + OFFSET_LINKCOUNT, AMemory.ReadInt32(AAddress + OFFSET_LINKCOUNT) + 1);

  // the first node of the world tree that the box crosses
  LNode := 0;
  while FSectors[LNode].Axis <> -1 do
  begin
    if LAbsMin[FSectors[LNode].Axis] > FSectors[LNode].Dist then
      LNode := FSectors[LNode].Children[0]
    else if LAbsMax[FSectors[LNode].Axis] < FSectors[LNode].Dist then
      LNode := FSectors[LNode].Children[1]
    else
      Break;
  end;

  FSv[LNumber].Sector := LNode;
  FSv[LNumber].NextInSector := FSectors[LNode].FirstEntity;
  FSectors[LNode].FirstEntity := LNumber;
  AMemory.WriteInt32(AAddress + OFFSET_LINKED, 1);
end;

procedure TQ3GameWorld.AreaEntitiesRecursive(const AMemory: IQvmMemory; ANode: Integer; const AMins,
  AMaxs: TQ3Vec3; AMaxCount: Integer; var AList: TArray<Integer>; var ACount: Integer);
var
  LCheck, LNext, LAddress: Integer;
  LAxis: Integer;
begin
  LCheck := FSectors[ANode].FirstEntity;
  while LCheck >= 0 do
  begin
    LNext := FSv[LCheck].NextInSector;
    LAddress := EntityAddress(LCheck);
    if not ((ReadFloat(AMemory, LAddress + OFFSET_ABSMIN) > AMaxs[0])
      or (ReadFloat(AMemory, LAddress + OFFSET_ABSMIN + 4) > AMaxs[1])
      or (ReadFloat(AMemory, LAddress + OFFSET_ABSMIN + 8) > AMaxs[2])
      or (ReadFloat(AMemory, LAddress + OFFSET_ABSMAX) < AMins[0])
      or (ReadFloat(AMemory, LAddress + OFFSET_ABSMAX + 4) < AMins[1])
      or (ReadFloat(AMemory, LAddress + OFFSET_ABSMAX + 8) < AMins[2])) then
    begin
      if ACount = AMaxCount then
      begin
        Print('SV_AreaEntities: MAXCOUNT'#10);
        Exit;
      end;
      AList[ACount] := LCheck;
      Inc(ACount);
    end;
    LCheck := LNext;
  end;

  LAxis := FSectors[ANode].Axis;
  // terminal node
  if LAxis = -1 then
    Exit;
  // recurse down both sides
  if AMaxs[LAxis] > FSectors[ANode].Dist then
    AreaEntitiesRecursive(AMemory, FSectors[ANode].Children[0], AMins, AMaxs, AMaxCount, AList, ACount);
  if AMins[LAxis] < FSectors[ANode].Dist then
    AreaEntitiesRecursive(AMemory, FSectors[ANode].Children[1], AMins, AMaxs, AMaxCount, AList, ACount);
end;

function TQ3GameWorld.AreaEntities(const AMemory: IQvmMemory; const AMins, AMaxs: TQ3Vec3;
  AMaxCount: Integer): TArray<Integer>;
var
  LList: TArray<Integer>;
  LCount: Integer;
begin
  EnsureWorld;
  if AMaxCount < 0 then
    AMaxCount := 0;
  SetLength(LList, AMaxCount);
  LCount := 0;
  AreaEntitiesRecursive(AMemory, 0, AMins, AMaxs, AMaxCount, LList, LCount);
  SetLength(LList, LCount);
  Result := LList;
end;

function TQ3GameWorld.ClipHandleForEntity(const AMemory: IQvmMemory; AAddress: Integer): Integer;
begin
  if AMemory.ReadInt32(AAddress + OFFSET_BMODEL) <> 0 then
    // explicit hulls in the BSP model
    Exit(Model.InlineModel(AMemory.ReadInt32(AAddress + OFFSET_MODELINDEX)));
  // a temp tree (box or capsule) from the bounding box sizes
  Result := Model.TempBoxModel(ReadVec(AMemory, AAddress + OFFSET_MINS), ReadVec(AMemory, AAddress + OFFSET_MAXS),
    (AMemory.ReadInt32(AAddress + OFFSET_SVFLAGS) and SVF_CAPSULE) <> 0);
end;

function TQ3GameWorld.Trace(const AMemory: IQvmMemory; const AStart, AMins, AMaxs, AEnd: TQ3Vec3;
  APassEntityNum, AContentMask: Integer; ACapsule: Boolean): TQ3Trace;
var
  LClip: TQ3Trace;
  LBoxMins, LBoxMaxs, LOrigin, LAngles, LZero: TQ3Vec3;
  LIndex, LCount, LPassOwner, LTouchNumber, LTouchAddress, LOwner: Integer;
  LTouchList: TArray<Integer>;
  LTrace: TQ3Trace;
  LOldStart: Boolean;
begin
  EnsureWorld;
  LZero[0] := 0;
  LZero[1] := 0;
  LZero[2] := 0;
  // clip to the world
  LClip := Model.BoxTrace(AStart, AEnd, AMins, AMaxs, 0, AContentMask, ACapsule);
  if LClip.Fraction <> 1.0 then
    LClip.EntityNum := ENTITYNUM_WORLD
  else
    LClip.EntityNum := ENTITYNUM_NONE;
  // blocked immediately by the world
  if LClip.Fraction = 0 then
    Exit(LClip);

  // the box of the move, only the part the world did not clip off
  for LIndex := 0 to 2 do
    if AEnd[LIndex] > AStart[LIndex] then
    begin
      LBoxMins[LIndex] := Narrow(Double(AStart[LIndex]) + AMins[LIndex] - 1);
      LBoxMaxs[LIndex] := Narrow(Double(AEnd[LIndex]) + AMaxs[LIndex] + 1);
    end
    else
    begin
      LBoxMins[LIndex] := Narrow(Double(AEnd[LIndex]) + AMins[LIndex] - 1);
      LBoxMaxs[LIndex] := Narrow(Double(AStart[LIndex]) + AMaxs[LIndex] + 1);
    end;

  // SV_ClipMoveToEntities
  LTouchList := AreaEntities(AMemory, LBoxMins, LBoxMaxs, MAX_GENTITIES);
  LCount := Length(LTouchList);
  LPassOwner := -1;
  if APassEntityNum <> ENTITYNUM_NONE then
  begin
    LPassOwner := AMemory.ReadInt32(EntityAddress(APassEntityNum) + OFFSET_OWNERNUM);
    if LPassOwner = ENTITYNUM_NONE then
      LPassOwner := -1;
  end;

  for LIndex := 0 to LCount - 1 do
  begin
    if LClip.AllSolid then
      Break;
    LTouchNumber := LTouchList[LIndex];
    LTouchAddress := EntityAddress(LTouchNumber);
    // ignore the pass entity, its missiles and the missiles of its owner
    if APassEntityNum <> ENTITYNUM_NONE then
    begin
      if LTouchNumber = APassEntityNum then
        Continue;
      LOwner := AMemory.ReadInt32(LTouchAddress + OFFSET_OWNERNUM);
      if LOwner = APassEntityNum then
        Continue;
      if LOwner = LPassOwner then
        Continue;
    end;
    // no brushes of a type that is looked for
    if (AContentMask and AMemory.ReadInt32(LTouchAddress + OFFSET_CONTENTS)) = 0 then
      Continue;

    LOrigin := ReadVec(AMemory, LTouchAddress + OFFSET_CURRENTORIGIN);
    LAngles := ReadVec(AMemory, LTouchAddress + OFFSET_CURRENTANGLES);
    // boxes do not rotate
    if AMemory.ReadInt32(LTouchAddress + OFFSET_BMODEL) = 0 then
      LAngles := LZero;
    LTrace := Model.TransformedBoxTrace(AStart, AEnd, AMins, AMaxs, ClipHandleForEntity(AMemory, LTouchAddress),
      AContentMask, LOrigin, LAngles, ACapsule);
    if LTrace.AllSolid then
    begin
      LClip.AllSolid := True;
      LTrace.EntityNum := AMemory.ReadInt32(LTouchAddress + OFFSET_NUMBER);
    end
    else if LTrace.StartSolid then
    begin
      LClip.StartSolid := True;
      LTrace.EntityNum := AMemory.ReadInt32(LTouchAddress + OFFSET_NUMBER);
    end;
    if LTrace.Fraction < LClip.Fraction then
    begin
      // keep a startsolid from a previous trace
      LOldStart := LClip.StartSolid;
      LTrace.EntityNum := AMemory.ReadInt32(LTouchAddress + OFFSET_NUMBER);
      LClip := LTrace;
      LClip.StartSolid := LClip.StartSolid or LOldStart;
    end;
  end;
  Result := LClip;
end;

function TQ3GameWorld.PointContents(const AMemory: IQvmMemory; const APoint: TQ3Vec3;
  APassEntityNum: Integer): Integer;
var
  LTouch: TArray<Integer>;
  LIndex, LHit: Integer;
begin
  EnsureWorld;
  // the world, then the other entities
  Result := Model.PointContents(APoint, 0);
  LTouch := AreaEntities(AMemory, APoint, APoint, MAX_GENTITIES);
  for LIndex := 0 to Length(LTouch) - 1 do
  begin
    if LTouch[LIndex] = APassEntityNum then
      Continue;
    LHit := EntityAddress(LTouch[LIndex]);
    // the origin and the angles of the state, not currentOrigin (as the C)
    Result := Result or Model.TransformedPointContents(APoint, ClipHandleForEntity(AMemory, LHit),
      ReadVec(AMemory, LHit + OFFSET_ORIGIN), ReadVec(AMemory, LHit + OFFSET_ANGLES));
  end;
end;

function TQ3GameWorld.EntityContact(const AMemory: IQvmMemory; const AMins, AMaxs: TQ3Vec3;
  AEntityAddress: Integer; ACapsule: Boolean): Boolean;
var
  LZero: TQ3Vec3;
begin
  LZero[0] := 0;
  LZero[1] := 0;
  LZero[2] := 0;
  Result := Model.TransformedBoxTrace(LZero, LZero, AMins, AMaxs, ClipHandleForEntity(AMemory, AEntityAddress), -1,
    ReadVec(AMemory, AEntityAddress + OFFSET_CURRENTORIGIN), ReadVec(AMemory, AEntityAddress + OFFSET_CURRENTANGLES),
    ACapsule).StartSolid;
end;

procedure TQ3GameWorld.SetBrushModel(const AMemory: IQvmMemory; AEntityAddress: Integer; const AName: AnsiString);
var
  LHandle: Integer;
  LMins, LMaxs: TQ3Vec3;
begin
  if (AName = '') or (AName[1] <> '*') then
    raise EQ3HostException.CreateFmt(SNotBrushModel, [string(AName)]);
  AMemory.WriteInt32(AEntityAddress + OFFSET_MODELINDEX, Atoi(Copy(AName, 2, MaxInt)));
  LHandle := Model.InlineModel(AMemory.ReadInt32(AEntityAddress + OFFSET_MODELINDEX));
  Model.ModelBounds(LHandle, LMins, LMaxs);
  WriteVec(AMemory, AEntityAddress + OFFSET_MINS, LMins);
  WriteVec(AMemory, AEntityAddress + OFFSET_MAXS, LMaxs);
  AMemory.WriteInt32(AEntityAddress + OFFSET_BMODEL, 1);
  // we do not know exactly what is in the brushes
  AMemory.WriteInt32(AEntityAddress + OFFSET_CONTENTS, -1);
  LinkEntity(AMemory, AEntityAddress);
end;

function TQ3GameWorld.InPvs(const AFirst, ASecond: TQ3Vec3; AIgnorePortals: Boolean): Boolean;
var
  LLeaf, LCluster1, LCluster2, LArea1, LArea2: Integer;
  LMask: TBytes;
begin
  LLeaf := Model.PointLeafnum(AFirst);
  LCluster1 := Model.LeafCluster(LLeaf);
  LArea1 := Model.LeafArea(LLeaf);
  LMask := Model.ClusterPVS(LCluster1);
  LLeaf := Model.PointLeafnum(ASecond);
  LCluster2 := Model.LeafCluster(LLeaf);
  LArea2 := Model.LeafArea(LLeaf);
  // the bit of the second cluster in the row of the first (the C reads before the row for a cluster of -1)
  if Length(LMask) > 0 then
  begin
    if (LCluster2 < 0) or ((LCluster2 shr 3) >= Length(LMask)) then
      Exit(False);
    if (LMask[LCluster2 shr 3] and (1 shl (LCluster2 and 7))) = 0 then
      Exit(False);
  end;
  // a door blocks sight
  if (not AIgnorePortals) and (not Model.AreasConnected(LArea1, LArea2)) then
    Exit(False);
  Result := True;
end;

procedure TQ3GameWorld.AdjustAreaPortalState(const AMemory: IQvmMemory; AEntityAddress: Integer; AOpen: Boolean);
var
  LNumber: Integer;
begin
  LNumber := NumberOf(AMemory, AEntityAddress);
  if FSv[LNumber].AreaNum2 = -1 then
    Exit;
  Model.AdjustAreaPortalState(FSv[LNumber].AreaNum, FSv[LNumber].AreaNum2, AOpen);
end;

procedure TQ3GameWorld.SetEntityNumber(const AMemory: IQvmMemory; AClient: Integer);
begin
  AMemory.WriteInt32(EntityAddress(AClient) + OFFSET_NUMBER, AClient);
end;

procedure TQ3GameWorld.ClearBotFlag(const AMemory: IQvmMemory; AClient: Integer);
var
  LAddress: Integer;
begin
  LAddress := EntityAddress(AClient) + OFFSET_SVFLAGS;
  AMemory.WriteInt32(LAddress, AMemory.ReadInt32(LAddress) and not SVF_BOT);
end;

function TQ3GameWorld.SvEntity(ANumber: Integer): TSvEntity;
begin
  Result := FSv[ANumber];
end;

end.
