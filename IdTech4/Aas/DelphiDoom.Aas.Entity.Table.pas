{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the table of the entities                          }
{                                                                              }
{  Port of be_aas_entity.c. Based on the Quake III Arena GPL Source Code (id    }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived    }
{  from the Quake III Arena source code and is therefore available under the    }
{  GNU General Public License, version 2 or (at your option) any later          }
{  version.                                                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Entity.Table;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Links, DelphiDoom.Aas.Bsp.Intf,
  DelphiDoom.Aas.Main.Intf, DelphiDoom.Aas.Entity.Types;

type
  /// <summary>
  ///   AAS_BestReachableLinkArea of be_aas_reach.c: the area of a list of links that the bot should go to (the
  ///   reachabilities are calculated by another class, so the entity table asks for it)
  /// </summary>
  TAasBestLinkArea = reference to function(const AHead: Integer): Integer;

  /// <summary>
  ///   The entities that the game tells the bots about: their information and the areas they are linked into
  ///   (aasworld.entities). The leaves of the BSP are not linked (the functions of the original are empty). The
  ///   frame state, the links, the models and the import are not owned
  /// </summary>
  TAasEntityTable = class
  strict private
    FImport: IBotImport;
    [weak] FState: IAasFrameState;
    FLinks: TAasEntityLinks;
    FModels: IAasBspModels;
    FBestLinkArea: TAasBestLinkArea;
    FInfo: TArray<TAasEntityInfo>;
    FAreas: TArray<Integer>;
    function InRange(const AEntNum: Integer): Boolean;
    procedure CheckIndex(const AEntNum: Integer);
    procedure DoUnlink(const AHead: Integer);
  public
    /// <summary>AAS_Setup allocated maxentities entities and invalidated them</summary>
    constructor Create(const AImport: IBotImport; const AState: IAasFrameState;
      const AModels: IAasBspModels; const AMaxEntities: Integer; const ABestLinkArea: TAasBestLinkArea);
    /// <summary>
    ///   The links of the map that is loaded (not owned); nil until a map is loaded, when no entity can be
    ///   updated either
    /// </summary>
    property Links: TAasEntityLinks read FLinks write FLinks;
    /// <summary>
    ///   AAS_UpdateEntity: AState nil unlinks the entity. BLERR_NOAASFILE (with a message) if no file is loaded; an
    ///   entity number outside the table is an EAasEntityException (the original writes past the array)
    /// </summary>
    function UpdateEntity(const AEntNum: Integer; const AState: PBotEntityState): Integer;
    /// <summary>AAS_EntityInfo: zeroed, with a message, if not initialized or out of range</summary>
    function EntityInfo(const AEntNum: Integer): TAasEntityInfo;
    /// <summary>AAS_EntityOrigin: zero, with a message, out of range</summary>
    function EntityOrigin(const AEntNum: Integer): TVec3;
    function EntityModelIndex(const AEntNum: Integer): Integer;
    function EntityType(const AEntNum: Integer): Integer;
    function EntityModelNum(const AEntNum: Integer): Integer;
    /// <summary>AAS_OriginOfMoverWithModelNum: True with the origin of the first mover that has the model</summary>
    function OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
    procedure EntitySize(const AEntNum: Integer; out AMins, AMaxs: TVec3);
    /// <summary>AAS_EntityBSPData</summary>
    procedure EntityBspData(const AEntNum: Integer; out AOrigin, AAngles, AAbsMins, AAbsMaxs: TVec3;
      out ASolid, AModelNum: Integer);
    /// <summary>AAS_ResetEntityLinks</summary>
    procedure ResetEntityLinks;
    /// <summary>AAS_InvalidateEntities</summary>
    procedure InvalidateEntities;
    /// <summary>AAS_UnlinkInvalidEntities</summary>
    procedure UnlinkInvalidEntities;
    /// <summary>AAS_NearestEntity: the entity with the model within 40 units in x and y, 0 if none</summary>
    function NearestEntity(const AOrigin: TVec3; const AModelIndex: Integer): Integer;
    /// <summary>AAS_BestReachableEntityArea</summary>
    function BestReachableEntityArea(const AEntNum: Integer): Integer;
    /// <summary>AAS_NextEntity: the next valid entity after the number, 0 when there are no more</summary>
    function NextEntity(const AEntNum: Integer): Integer;
    /// <summary>The number of entities (maxentities)</summary>
    function Count: Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath;

resourcestring
  SNotLoaded = 'AAS_UpdateEntity: not loaded'#10;
  SNotInitialized = 'AAS_EntityInfo: aasworld not initialized'#10;
  SOutOfRange = '%s: entnum %d out of range'#10;
  SBadEntity = 'AAS entity table: the entity %d is not in the table';

function SameVector(const AFirst, ASecond: TVec3): Boolean;
begin
  Result := (AFirst[0] = ASecond[0]) and (AFirst[1] = ASecond[1]) and (AFirst[2] = ASecond[2]);
end;

{ TAasEntityTable }

constructor TAasEntityTable.Create(const AImport: IBotImport; const AState: IAasFrameState;
  const AModels: IAasBspModels; const AMaxEntities: Integer; const ABestLinkArea: TAasBestLinkArea);
var
  LIndex, LCount: Integer;
begin
  inherited Create;
  FImport := AImport;
  FState := AState;
  FLinks := nil;
  FModels := AModels;
  FBestLinkArea := ABestLinkArea;
  LCount := AMaxEntities;
  if LCount < 0 then
    LCount := 0;
  SetLength(FInfo, LCount);
  SetLength(FAreas, LCount);
  for LIndex := 0 to LCount - 1 do
    FAreas[LIndex] := AAS_NO_LINK;
  InvalidateEntities;
end;

function TAasEntityTable.Count: Integer;
begin
  Result := Length(FInfo);
end;

function TAasEntityTable.InRange(const AEntNum: Integer): Boolean;
begin
  Result := (AEntNum >= 0) and (AEntNum < Length(FInfo));
end;

procedure TAasEntityTable.CheckIndex(const AEntNum: Integer);
begin
  if not InRange(AEntNum) then
    raise EAasEntityException.CreateFmt(SBadEntity, [AEntNum]);
end;

procedure TAasEntityTable.DoUnlink(const AHead: Integer);
begin
  if (AHead <> AAS_NO_LINK) and Assigned(FLinks) then
    FLinks.Unlink(AHead);
end;

function TAasEntityTable.UpdateEntity(const AEntNum: Integer; const AState: PBotEntityState): Integer;
var
  LRelink: Boolean;
  LAbsMins, LAbsMaxs, LOrigin: TVec3;
  LIndex: Integer;
begin
  if not FState.Loaded then
  begin
    TAasPrinter.Print(FImport, PRT_MESSAGE, SNotLoaded);
    Exit(AAS_BLERR_NOAASFILE);
  end;
  CheckIndex(AEntNum);
  if AState = nil then
  begin
    // unlink the entity from the areas (the BSP leaves are not linked)
    DoUnlink(FAreas[AEntNum]);
    FAreas[AEntNum] := AAS_NO_LINK;
    Exit(BLERR_NOERROR);
  end;
  FInfo[AEntNum].UpdateTime := FState.Time - FInfo[AEntNum].LocalTime;
  FInfo[AEntNum].EntityType := AState^.EntityType;
  FInfo[AEntNum].Flags := AState^.Flags;
  FInfo[AEntNum].LocalTime := FState.Time;
  FInfo[AEntNum].LastVisOrigin := FInfo[AEntNum].Origin;
  FInfo[AEntNum].OldOrigin := AState^.OldOrigin;
  FInfo[AEntNum].Solid := AState^.Solid;
  FInfo[AEntNum].GroundEnt := AState^.GroundEnt;
  FInfo[AEntNum].ModelIndex := AState^.ModelIndex;
  FInfo[AEntNum].ModelIndex2 := AState^.ModelIndex2;
  FInfo[AEntNum].Frame := AState^.Frame;
  FInfo[AEntNum].Event := AState^.Event;
  FInfo[AEntNum].EventParm := AState^.EventParm;
  FInfo[AEntNum].Powerups := AState^.Powerups;
  FInfo[AEntNum].Weapon := AState^.Weapon;
  FInfo[AEntNum].LegsAnim := AState^.LegsAnim;
  FInfo[AEntNum].TorsoAnim := AState^.TorsoAnim;
  FInfo[AEntNum].Number := AEntNum;
  FInfo[AEntNum].Valid := True;
  // everything is linked the first frame
  LRelink := FState.NumFrames = 1;
  if FInfo[AEntNum].Solid = AAS_SOLID_BSP then
  begin
    if not SameVector(AState^.Angles, FInfo[AEntNum].Angles) then
    begin
      FInfo[AEntNum].Angles := AState^.Angles;
      LRelink := True;
    end;
    // the mins and maxs of the model (the original does not rotate them)
    FModels.ModelMinsMaxsOrigin(FInfo[AEntNum].ModelIndex, FInfo[AEntNum].Angles, FInfo[AEntNum].Mins,
      FInfo[AEntNum].Maxs, LOrigin);
  end
  else if FInfo[AEntNum].Solid = AAS_SOLID_BBOX then
  begin
    if not SameVector(AState^.Mins, FInfo[AEntNum].Mins) or not SameVector(AState^.Maxs, FInfo[AEntNum].Maxs) then
    begin
      FInfo[AEntNum].Mins := AState^.Mins;
      FInfo[AEntNum].Maxs := AState^.Maxs;
      LRelink := True;
    end;
    FInfo[AEntNum].Angles := AState^.Angles;
  end;
  if not SameVector(AState^.Origin, FInfo[AEntNum].Origin) then
  begin
    FInfo[AEntNum].Origin := AState^.Origin;
    LRelink := True;
  end;
  // the world model is not linked
  if LRelink and (AEntNum <> AAS_ENTITYNUM_WORLD) then
  begin
    for LIndex := 0 to 2 do
    begin
      LAbsMins[LIndex] := FInfo[AEntNum].Mins[LIndex] + FInfo[AEntNum].Origin[LIndex];
      LAbsMaxs[LIndex] := FInfo[AEntNum].Maxs[LIndex] + FInfo[AEntNum].Origin[LIndex];
    end;
    DoUnlink(FAreas[AEntNum]);
    // the largest box of the client
    FAreas[AEntNum] := FLinks.LinkEntityClientBBox(LAbsMins, LAbsMaxs, AEntNum, PRESENCE_NORMAL);
  end;
  Result := BLERR_NOERROR;
end;

function TAasEntityTable.EntityInfo(const AEntNum: Integer): TAasEntityInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FState.Initialized then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, SNotInitialized);
    Exit;
  end;
  if not InRange(AEntNum) then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SOutOfRange, ['AAS_EntityInfo', AEntNum]));
    Exit;
  end;
  Result := FInfo[AEntNum];
end;

function TAasEntityTable.EntityOrigin(const AEntNum: Integer): TVec3;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not InRange(AEntNum) then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SOutOfRange, ['AAS_EntityOrigin', AEntNum]));
    Exit;
  end;
  Result := FInfo[AEntNum].Origin;
end;

function TAasEntityTable.EntityModelIndex(const AEntNum: Integer): Integer;
begin
  Result := 0;
  if not InRange(AEntNum) then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SOutOfRange, ['AAS_EntityModelindex', AEntNum]));
    Exit;
  end;
  Result := FInfo[AEntNum].ModelIndex;
end;

function TAasEntityTable.EntityType(const AEntNum: Integer): Integer;
begin
  Result := 0;
  if not FState.Initialized then
    Exit;
  if not InRange(AEntNum) then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SOutOfRange, ['AAS_EntityType', AEntNum]));
    Exit;
  end;
  Result := FInfo[AEntNum].EntityType;
end;

function TAasEntityTable.EntityModelNum(const AEntNum: Integer): Integer;
begin
  Result := 0;
  if not FState.Initialized then
    Exit;
  if not InRange(AEntNum) then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SOutOfRange, ['AAS_EntityModelNum', AEntNum]));
    Exit;
  end;
  Result := FInfo[AEntNum].ModelIndex;
end;

function TAasEntityTable.OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
var
  LIndex: Integer;
begin
  FillChar(AOrigin, SizeOf(AOrigin), 0);
  for LIndex := 0 to High(FInfo) do
    if (FInfo[LIndex].EntityType = AAS_ET_MOVER) and (FInfo[LIndex].ModelIndex = AModelNum) then
    begin
      AOrigin := FInfo[LIndex].Origin;
      Exit(True);
    end;
  Result := False;
end;

procedure TAasEntityTable.EntitySize(const AEntNum: Integer; out AMins, AMaxs: TVec3);
begin
  FillChar(AMins, SizeOf(AMins), 0);
  FillChar(AMaxs, SizeOf(AMaxs), 0);
  if not FState.Initialized then
    Exit;
  if not InRange(AEntNum) then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SOutOfRange, ['AAS_EntitySize', AEntNum]));
    Exit;
  end;
  AMins := FInfo[AEntNum].Mins;
  AMaxs := FInfo[AEntNum].Maxs;
end;

procedure TAasEntityTable.EntityBspData(const AEntNum: Integer; out AOrigin, AAngles, AAbsMins, AAbsMaxs: TVec3;
  out ASolid, AModelNum: Integer);
var
  LIndex: Integer;
begin
  CheckIndex(AEntNum);
  AOrigin := FInfo[AEntNum].Origin;
  AAngles := FInfo[AEntNum].Angles;
  for LIndex := 0 to 2 do
  begin
    AAbsMins[LIndex] := FInfo[AEntNum].Origin[LIndex] + FInfo[AEntNum].Mins[LIndex];
    AAbsMaxs[LIndex] := FInfo[AEntNum].Origin[LIndex] + FInfo[AEntNum].Maxs[LIndex];
  end;
  ASolid := FInfo[AEntNum].Solid;
  AModelNum := FInfo[AEntNum].ModelIndex - 1;
end;

procedure TAasEntityTable.ResetEntityLinks;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FAreas) do
    FAreas[LIndex] := AAS_NO_LINK;
end;

procedure TAasEntityTable.InvalidateEntities;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FInfo) do
  begin
    FInfo[LIndex].Valid := False;
    FInfo[LIndex].Number := LIndex;
  end;
end;

procedure TAasEntityTable.UnlinkInvalidEntities;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FInfo) do
    if not FInfo[LIndex].Valid then
    begin
      DoUnlink(FAreas[LIndex]);
      FAreas[LIndex] := AAS_NO_LINK;
    end;
end;

function TAasEntityTable.NearestEntity(const AOrigin: TVec3; const AModelIndex: Integer): Integer;
var
  LIndex: Integer;
  LDist, LBestDist: Single;
  LDir: TVec3;
begin
  Result := 0;
  LBestDist := 99999;
  for LIndex := 0 to High(FInfo) do
  begin
    if FInfo[LIndex].ModelIndex <> AModelIndex then
      Continue;
    LDir[0] := FInfo[LIndex].Origin[0] - AOrigin[0];
    LDir[1] := FInfo[LIndex].Origin[1] - AOrigin[1];
    LDir[2] := FInfo[LIndex].Origin[2] - AOrigin[2];
    // abs() of the C library is the integer one: the float is cut
    if Abs(Trunc(LDir[0])) < 40 then
      if Abs(Trunc(LDir[1])) < 40 then
      begin
        LDist := TAasVectorMath.Length(LDir);
        if LDist < LBestDist then
        begin
          LBestDist := LDist;
          Result := LIndex;
        end;
      end;
  end;
end;

function TAasEntityTable.BestReachableEntityArea(const AEntNum: Integer): Integer;
begin
  CheckIndex(AEntNum);
  Result := FBestLinkArea(FAreas[AEntNum]);
end;

function TAasEntityTable.NextEntity(const AEntNum: Integer): Integer;
var
  LNum: Integer;
begin
  Result := 0;
  if not FState.Loaded then
    Exit;
  LNum := AEntNum;
  if LNum < 0 then
    LNum := -1;
  Inc(LNum);
  while LNum < Length(FInfo) do
  begin
    if FInfo[LNum].Valid then
      Exit(LNum);
    Inc(LNum);
  end;
end;

end.
