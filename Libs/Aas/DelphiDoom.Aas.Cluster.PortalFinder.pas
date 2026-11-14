{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - possible cluster portals (be_aas_cluster.c)       }
{                                                                              }
{  Port of AAS_ConnectedAreas, AAS_GetAdjacentAreasWithLessPresenceTypes_r,    }
{  AAS_CheckAreaForPossiblePortals and AAS_FindPossiblePortals. Based on the   }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Cluster.PortalFinder;

interface

uses
  System.SysUtils, DelphiDoom.Aas.Cluster.World;

type
  /// <summary>
  ///   Finds the grounded areas (with the adjacent areas that have fewer presence types) that close a space between
  ///   two sets of faces on two parallel planes, and marks them as cluster portals. The world is not owned
  /// </summary>
  TAasPortalFinder = class
  strict private
    FWorld: TAasClusterWorld;
    procedure ConnectedAreasFrom(const AAreaNums: TArray<Integer>; const ANumAreas: Integer;
      var AConnected: TArray<Boolean>; const ACurArea: Integer);
    function ConnectedAreas(const AAreaNums: TArray<Integer>; const ANumAreas: Integer): Boolean;
    function GetAdjacentAreasWithLessPresenceTypes(var AAreaNums: TArray<Integer>; const ANumAreas,
      ACurAreaNum: Integer): Integer;
  public
    constructor Create(const AWorld: TAasClusterWorld);
    /// <summary>
    ///   The number of areas that became cluster portals for the area (0 if none): AAS_CheckAreaForPossiblePortals.
    ///   A list that gets longer than MAX_PORTALAREAS is an EAasClusterException (the C writes past its arrays)
    /// </summary>
    function CheckAreaForPossiblePortals(const AAreaNum: Integer): Integer;
    /// <summary>The portals of every area; prints how many (AAS_FindPossiblePortals)</summary>
    procedure FindPossiblePortals;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Cluster.Types;

resourcestring
  STooManyFaces = 'AAS clustering: a possible portal has more than %d faces or areas';

{ TAasPortalFinder }

constructor TAasPortalFinder.Create(const AWorld: TAasClusterWorld);
begin
  inherited Create;
  FWorld := AWorld;
end;

procedure TAasPortalFinder.ConnectedAreasFrom(const AAreaNums: TArray<Integer>; const ANumAreas: Integer;
  var AConnected: TArray<Boolean>; const ACurArea: Integer);
var
  LIndex, LJ, LOther, LFaceNum: Integer;
  LArea: TAasArea;
begin
  AConnected[ACurArea] := True;
  LArea := FWorld.Areas[AAreaNums[ACurArea]];
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := Abs(FWorld.FaceIndex[LArea.FirstFace + LIndex]);
    // if the face is solid
    if (FWorld.Faces[LFaceNum].FaceFlags and FACE_SOLID) <> 0 then
      Continue;
    // get the area at the other side of the face
    if FWorld.Faces[LFaceNum].FrontArea <> AAreaNums[ACurArea] then
      LOther := FWorld.Faces[LFaceNum].FrontArea
    else
      LOther := FWorld.Faces[LFaceNum].BackArea;
    // check if the face is leading to one of the other areas
    LJ := 0;
    while LJ < ANumAreas do
    begin
      if AAreaNums[LJ] = LOther then
        Break;
      Inc(LJ);
    end;
    // if the face isn't leading to one of the other areas
    if LJ = ANumAreas then
      Continue;
    // if the other area is already connected
    if AConnected[LJ] then
      Continue;
    ConnectedAreasFrom(AAreaNums, ANumAreas, AConnected, LJ);
  end;
end;

function TAasPortalFinder.ConnectedAreas(const AAreaNums: TArray<Integer>; const ANumAreas: Integer): Boolean;
var
  LConnected: TArray<Boolean>;
  LIndex: Integer;
begin
  if ANumAreas < 1 then
    Exit(False);
  if ANumAreas = 1 then
    Exit(True);
  SetLength(LConnected, MAX_PORTALAREAS);
  ConnectedAreasFrom(AAreaNums, ANumAreas, LConnected, 0);
  for LIndex := 0 to ANumAreas - 1 do
    if not LConnected[LIndex] then
      Exit(False);
  Result := True;
end;

function TAasPortalFinder.GetAdjacentAreasWithLessPresenceTypes(var AAreaNums: TArray<Integer>; const ANumAreas,
  ACurAreaNum: Integer): Integer;
var
  LIndex, LJ, LPresence, LOtherPresence, LOther, LFaceNum: Integer;
  LArea: TAasArea;
begin
  Result := ANumAreas;
  AAreaNums[Result] := ACurAreaNum;
  Inc(Result);
  LArea := FWorld.Areas[ACurAreaNum];
  LPresence := FWorld.AreaSettings[ACurAreaNum].PresenceType;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := Abs(FWorld.FaceIndex[LArea.FirstFace + LIndex]);
    // if the face is solid
    if (FWorld.Faces[LFaceNum].FaceFlags and FACE_SOLID) <> 0 then
      Continue;
    // the area at the other side of the face
    if FWorld.Faces[LFaceNum].FrontArea <> ACurAreaNum then
      LOther := FWorld.Faces[LFaceNum].FrontArea
    else
      LOther := FWorld.Faces[LFaceNum].BackArea;
    LOtherPresence := FWorld.AreaSettings[LOther].PresenceType;
    // if the other area has less presence types
    if ((LPresence and not LOtherPresence) <> 0) and ((LOtherPresence and not LPresence) = 0) then
    begin
      // check if the other area isn't already in the list
      LJ := 0;
      while LJ < Result do
      begin
        if LOther = AAreaNums[LJ] then
          Break;
        Inc(LJ);
      end;
      // if the other area isn't already in the list
      if LJ = Result then
      begin
        if Result >= MAX_PORTALAREAS then
        begin
          FWorld.Error('MAX_PORTALAREAS');
          Exit;
        end;
        Result := GetAdjacentAreasWithLessPresenceTypes(AAreaNums, Result, LOther);
      end;
    end;
  end;
end;

function TAasPortalFinder.CheckAreaForPossiblePortals(const AAreaNum: Integer): Integer;
var
  LIndex, LJ, LK, LFen, LBen, LFrontEdgeNum, LBackEdgeNum, LFaceNum: Integer;
  LAreaNums, LNumAreaFrontFaces, LNumAreaBackFaces, LFrontFaceNums, LBackFaceNums, LFrontAreaNums,
    LBackAreaNums: TArray<Integer>;
  LNumAreas, LOtherArea, LNumFrontFaces, LNumBackFaces, LNumFrontAreas, LNumBackAreas: Integer;
  LFrontPlane, LBackPlane, LFacePlane: Integer;
  LArea: TAasArea;
  LFrontFace, LBackFace, LFace: TAasFace;
begin
  // if it isn't already a portal
  if (FWorld.AreaSettings[AAreaNum].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
    Exit(0);
  // it must be a grounded area
  if (FWorld.AreaSettings[AAreaNum].AreaFlags and AREA_GROUNDED) = 0 then
    Exit(0);
  SetLength(LAreaNums, MAX_PORTALAREAS);
  SetLength(LNumAreaFrontFaces, MAX_PORTALAREAS);
  SetLength(LNumAreaBackFaces, MAX_PORTALAREAS);
  SetLength(LFrontFaceNums, MAX_PORTALAREAS);
  SetLength(LBackFaceNums, MAX_PORTALAREAS);
  SetLength(LFrontAreaNums, MAX_PORTALAREAS);
  SetLength(LBackAreaNums, MAX_PORTALAREAS);
  LNumFrontFaces := 0;
  LNumBackFaces := 0;
  LNumFrontAreas := 0;
  LNumBackAreas := 0;
  LFrontPlane := -1;
  LBackPlane := -1;
  // add any adjacent areas with less presence types
  LNumAreas := GetAdjacentAreasWithLessPresenceTypes(LAreaNums, 0, AAreaNum);

  for LIndex := 0 to LNumAreas - 1 do
  begin
    LArea := FWorld.Areas[LAreaNums[LIndex]];
    for LJ := 0 to LArea.NumFaces - 1 do
    begin
      LFaceNum := Abs(FWorld.FaceIndex[LArea.FirstFace + LJ]);
      LFace := FWorld.Faces[LFaceNum];
      // if the face is solid
      if (LFace.FaceFlags and FACE_SOLID) <> 0 then
        Continue;
      // check if the face is shared with one of the other areas
      LK := 0;
      while LK < LNumAreas do
      begin
        if LK <> LIndex then
          if (LFace.FrontArea = LAreaNums[LK]) or (LFace.BackArea = LAreaNums[LK]) then
            Break;
        Inc(LK);
      end;
      // if the face is shared
      if LK <> LNumAreas then
        Continue;
      // the number of the area at the other side of the face
      if LFace.FrontArea = LAreaNums[LIndex] then
        LOtherArea := LFace.BackArea
      else
        LOtherArea := LFace.FrontArea;
      // if the other area already is a cluter portal
      if (FWorld.AreaSettings[LOtherArea].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
        Exit(0);
      // number of the plane of the area
      LFacePlane := LFace.PlaneNum and not 1;
      if (LFrontPlane < 0) or (LFacePlane = LFrontPlane) then
      begin
        LFrontPlane := LFacePlane;
        if (LNumFrontFaces >= MAX_PORTALAREAS) or (LNumFrontAreas >= MAX_PORTALAREAS) then
          raise EAasClusterException.Create(Format(STooManyFaces, [MAX_PORTALAREAS]));
        LFrontFaceNums[LNumFrontFaces] := LFaceNum;
        Inc(LNumFrontFaces);
        LK := 0;
        while LK < LNumFrontAreas do
        begin
          if LFrontAreaNums[LK] = LOtherArea then
            Break;
          Inc(LK);
        end;
        if LK = LNumFrontAreas then
        begin
          LFrontAreaNums[LNumFrontAreas] := LOtherArea;
          Inc(LNumFrontAreas);
        end;
        Inc(LNumAreaFrontFaces[LIndex]);
      end
      else if (LBackPlane < 0) or (LFacePlane = LBackPlane) then
      begin
        LBackPlane := LFacePlane;
        if (LNumBackFaces >= MAX_PORTALAREAS) or (LNumBackAreas >= MAX_PORTALAREAS) then
          raise EAasClusterException.Create(Format(STooManyFaces, [MAX_PORTALAREAS]));
        LBackFaceNums[LNumBackFaces] := LFaceNum;
        Inc(LNumBackFaces);
        LK := 0;
        while LK < LNumBackAreas do
        begin
          if LBackAreaNums[LK] = LOtherArea then
            Break;
          Inc(LK);
        end;
        if LK = LNumBackAreas then
        begin
          LBackAreaNums[LNumBackAreas] := LOtherArea;
          Inc(LNumBackAreas);
        end;
        Inc(LNumAreaBackFaces[LIndex]);
      end
      else
        Exit(0);
    end;
  end;
  // every area should have at least one front face and one back face
  for LIndex := 0 to LNumAreas - 1 do
    if (LNumAreaFrontFaces[LIndex] = 0) or (LNumAreaBackFaces[LIndex] = 0) then
      Exit(0);
  // the front areas should all be connected
  if not ConnectedAreas(LFrontAreaNums, LNumFrontAreas) then
    Exit(0);
  // the back areas should all be connected
  if not ConnectedAreas(LBackAreaNums, LNumBackAreas) then
    Exit(0);
  // none of the front faces should have a shared edge with a back face
  LIndex := 0;
  while LIndex < LNumFrontFaces do
  begin
    LFrontFace := FWorld.Faces[LFrontFaceNums[LIndex]];
    LFen := 0;
    while LFen < LFrontFace.NumEdges do
    begin
      LFrontEdgeNum := Abs(FWorld.EdgeIndex[LFrontFace.FirstEdge + LFen]);
      LJ := 0;
      while LJ < LNumBackFaces do
      begin
        LBackFace := FWorld.Faces[LBackFaceNums[LJ]];
        LBen := 0;
        while LBen < LBackFace.NumEdges do
        begin
          LBackEdgeNum := Abs(FWorld.EdgeIndex[LBackFace.FirstEdge + LBen]);
          if LFrontEdgeNum = LBackEdgeNum then
            Break;
          Inc(LBen);
        end;
        if LBen <> LBackFace.NumEdges then
          Break;
        Inc(LJ);
      end;
      if LJ <> LNumBackFaces then
        Break;
      Inc(LFen);
    end;
    if LFen <> LFrontFace.NumEdges then
      Break;
    Inc(LIndex);
  end;
  if LIndex <> LNumFrontFaces then
    Exit(0);
  // set the cluster portal contents
  for LIndex := 0 to LNumAreas - 1 do
  begin
    FWorld.AreaSettings[LAreaNums[LIndex]].Contents := FWorld.AreaSettings[LAreaNums[LIndex]].Contents or
      AREACONTENTS_CLUSTERPORTAL;
    // this area can be used as a route portal
    FWorld.AreaSettings[LAreaNums[LIndex]].Contents := FWorld.AreaSettings[LAreaNums[LIndex]].Contents or
      AREACONTENTS_ROUTEPORTAL;
    FWorld.LogWrite(Format('possible portal: %d'#13#10, [LAreaNums[LIndex]]));
  end;
  Result := LNumAreas;
end;

procedure TAasPortalFinder.FindPossiblePortals;
var
  LIndex, LNumPossiblePortals: Integer;
begin
  LNumPossiblePortals := 0;
  for LIndex := 1 to FWorld.NumAreas - 1 do
    Inc(LNumPossiblePortals, CheckAreaForPossiblePortals(LIndex));
  FWorld.Print(PRT_MESSAGE, Format(#13'%6d possible portal areas'#10, [LNumPossiblePortals]));
end;

end.
