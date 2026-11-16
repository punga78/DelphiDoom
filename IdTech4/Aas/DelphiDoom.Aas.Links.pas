{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the entities linked into the areas                 }
{                                                                              }
{  Port of AAS_InitAASLinkHeap, AAS_AllocAASLink, AAS_AASLinkEntity,            }
{  AAS_LinkEntityClientBBox and AAS_UnlinkFromAreas of be_aas_sample.c. Based   }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)          }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena    }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Links;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf;

const
  /// <summary>The value of "no link" (the NULL pointer of the original)</summary>
  AAS_NO_LINK = -1;
  /// <summary>The default of the library variable max_aaslinks</summary>
  AAS_DEFAULT_MAX_LINKS = 6144;

type
  /// <summary>A link or area number that is not in the heap or in the file (the original reads past its arrays)</summary>
  EAasLinkException = class(System.SysUtils.Exception);

  /// <summary>
  ///   The entities that are linked to the areas they touch: the heap of links of the original (the free links are
  ///   a list through <c>next_ent</c>), the list of links of each area and the list of links of an entity (through
  ///   <c>next_area</c>). A link is an index into the heap; <c>AAS_NO_LINK</c> is the NULL pointer. The file and the
  ///   import are not owned
  /// </summary>
  TAasEntityLinks = class
  strict private
    type
      TLink = record
        EntNum: Integer;
        AreaNum: Integer;
        PrevArea, NextArea: Integer;
        PrevEnt, NextEnt: Integer;
      end;
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
    FDeveloper: Boolean;
    FHeap: TArray<TLink>;
    FFreeLinks: Integer;
    FNumFree: Integer;
    FAreaLinkedEntities: TArray<Integer>;
    function Allocate: Integer;
    procedure Deallocate(const ALink: Integer);
    function GetLink(const AIndex: Integer): TLink;
  public
    /// <summary>
    ///   AAS_InitAASLinkHeap and AAS_InitAASLinkedEntities: the heap has AMaxLinks links (max_aaslinks, 0 if
    ///   negative); an AMaxLinks of 1 or 2 is made of that many links, with the same wiring as the original
    /// </summary>
    constructor Create(const AFile: IAasFile; const AImport: IBotImport; const AMaxLinks: Integer;
      const ADeveloper: Boolean);
    /// <summary>
    ///   AAS_AASLinkEntity: links the entity to every area the box touches; the first link of the list of the
    ///   entity (the area found last), or AAS_NO_LINK
    /// </summary>
    function LinkEntity(const AAbsMins, AAbsMaxs: TVec3; const AEntNum: Integer): Integer;
    /// <summary>AAS_LinkEntityClientBBox: the box is enlarged by the box of the presence type</summary>
    function LinkEntityClientBBox(const AAbsMins, AAbsMaxs: TVec3; const AEntNum, APresenceType: Integer): Integer;
    /// <summary>AAS_UnlinkFromAreas: gives the whole list of the entity back to the heap</summary>
    procedure Unlink(const AHead: Integer);
    /// <summary>The next link in the list of the entity</summary>
    function NextArea(const ALink: Integer): Integer;
    /// <summary>The area of the link</summary>
    function AreaNum(const ALink: Integer): Integer;
    /// <summary>The entity of the link</summary>
    function EntNum(const ALink: Integer): Integer;
    /// <summary>The first link of the entities that touch the area (the one linked last), or AAS_NO_LINK</summary>
    function AreaHead(const AAreaNum: Integer): Integer;
    /// <summary>The next link in the list of the area</summary>
    function NextEnt(const ALink: Integer): Integer;
    /// <summary>numaaslinks</summary>
    property FreeCount: Integer read FNumFree;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.BoxMath, DelphiDoom.Aas.Printer,
  DelphiDoom.Aas.VectorMath;

resourcestring
  SHeapEmpty = 'empty aas link heap'#10;
  SLinkStackOverflow = 'AAS_LinkEntity: stack overflow'#10;
  SLinkBadNode = 'AAS_LinkEntity: the node %d or its plane is out of range'#10;
  SLinkBadLink = 'AAS link: the link %d is out of range';

const
  LINK_STACK_SIZE = 128;

{ TAasEntityLinks }

constructor TAasEntityLinks.Create(const AFile: IAasFile; const AImport: IBotImport; const AMaxLinks: Integer;
  const ADeveloper: Boolean);
var
  LIndex, LMax: Integer;
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
  FDeveloper := ADeveloper;
  LMax := AMaxLinks;
  if LMax < 0 then
    LMax := 0;
  SetLength(FHeap, LMax);
  for LIndex := 0 to LMax - 1 do
  begin
    FHeap[LIndex].PrevEnt := LIndex - 1;
    FHeap[LIndex].NextEnt := LIndex + 1;
    FHeap[LIndex].PrevArea := AAS_NO_LINK;
    FHeap[LIndex].NextArea := AAS_NO_LINK;
    FHeap[LIndex].EntNum := 0;
    FHeap[LIndex].AreaNum := 0;
  end;
  if LMax > 0 then
  begin
    FHeap[0].PrevEnt := AAS_NO_LINK;
    FHeap[LMax - 1].NextEnt := AAS_NO_LINK;
    FFreeLinks := 0;
  end
  else
    FFreeLinks := AAS_NO_LINK;
  FNumFree := LMax;
  SetLength(FAreaLinkedEntities, Length(FFile.AreaSettings));
  for LIndex := 0 to High(FAreaLinkedEntities) do
    FAreaLinkedEntities[LIndex] := AAS_NO_LINK;
end;

function TAasEntityLinks.Allocate: Integer;
begin
  Result := FFreeLinks;
  if Result = AAS_NO_LINK then
  begin
    if FDeveloper then
      TAasPrinter.Print(FImport, PRT_FATAL, SHeapEmpty);
    Exit;
  end;
  FFreeLinks := FHeap[Result].NextEnt;
  if FFreeLinks <> AAS_NO_LINK then
    FHeap[FFreeLinks].PrevEnt := AAS_NO_LINK;
  Dec(FNumFree);
end;

procedure TAasEntityLinks.Deallocate(const ALink: Integer);
begin
  if FFreeLinks <> AAS_NO_LINK then
    FHeap[FFreeLinks].PrevEnt := ALink;
  FHeap[ALink].PrevEnt := AAS_NO_LINK;
  FHeap[ALink].NextEnt := FFreeLinks;
  FHeap[ALink].PrevArea := AAS_NO_LINK;
  FHeap[ALink].NextArea := AAS_NO_LINK;
  FFreeLinks := ALink;
  Inc(FNumFree);
end;

function TAasEntityLinks.GetLink(const AIndex: Integer): TLink;
begin
  if (AIndex < 0) or (AIndex >= Length(FHeap)) then
    raise EAasLinkException.CreateFmt(SLinkBadLink, [AIndex]);
  Result := FHeap[AIndex];
end;

function TAasEntityLinks.LinkEntity(const AAbsMins, AAbsMaxs: TVec3; const AEntNum: Integer): Integer;
var
  LStack: array[0..LINK_STACK_SIZE - 1] of Integer;
  LTop, LNodeNum, LSide, LBudget, LLink, LAreas: Integer;
  LNodes: TArray<TAasNode>;
  LPlanes: TArray<TAasPlane>;
  LNode: TAasNode;
begin
  LAreas := AAS_NO_LINK;
  Result := LAreas;
  LNodes := FFile.Nodes;
  LPlanes := FFile.Planes;
  LBudget := (Length(LNodes) + 1) * LINK_STACK_SIZE + 1024;
  // node 1 is the root, node zero a dummy for a solid leaf
  LStack[0] := 1;
  LTop := 1;
  while True do
  begin
    Dec(LTop);
    if LTop < 0 then
      Break;
    Dec(LBudget);
    if LBudget < 0 then
      Break;
    LNodeNum := LStack[LTop];
    if LNodeNum < 0 then
    begin
      if -LNodeNum >= Length(FAreaLinkedEntities) then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, Format(SLinkBadNode, [LNodeNum]));
        Break;
      end;
      // the entity might have been linked into this area already: several children can point to one area
      LLink := FAreaLinkedEntities[-LNodeNum];
      while (LLink <> AAS_NO_LINK) and (FHeap[LLink].EntNum <> AEntNum) do
        LLink := FHeap[LLink].NextEnt;
      if LLink <> AAS_NO_LINK then
        Continue;
      LLink := Allocate;
      if LLink = AAS_NO_LINK then
      begin
        Result := LAreas;
        Exit;
      end;
      FHeap[LLink].EntNum := AEntNum;
      FHeap[LLink].AreaNum := -LNodeNum;
      // the double linked list of the areas of the entity
      FHeap[LLink].PrevArea := AAS_NO_LINK;
      FHeap[LLink].NextArea := LAreas;
      if LAreas <> AAS_NO_LINK then
        FHeap[LAreas].PrevArea := LLink;
      LAreas := LLink;
      // the double linked list of the entities of the area
      FHeap[LLink].PrevEnt := AAS_NO_LINK;
      FHeap[LLink].NextEnt := FAreaLinkedEntities[-LNodeNum];
      if FAreaLinkedEntities[-LNodeNum] <> AAS_NO_LINK then
        FHeap[FAreaLinkedEntities[-LNodeNum]].PrevEnt := LLink;
      FAreaLinkedEntities[-LNodeNum] := LLink;
      Continue;
    end;
    if LNodeNum = 0 then
      Continue;
    if (LNodeNum >= Length(LNodes)) or (LNodes[LNodeNum].PlaneNum < 0) or
       (LNodes[LNodeNum].PlaneNum >= Length(LPlanes)) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, Format(SLinkBadNode, [LNodeNum]));
      Break;
    end;
    LNode := LNodes[LNodeNum];
    LSide := TAasBoxMath.BoxOnPlaneSide2(AAbsMins, AAbsMaxs, LPlanes[LNode.PlaneNum]);
    if (LSide and 1) <> 0 then
    begin
      LStack[LTop] := LNode.Children[0];
      Inc(LTop);
    end;
    if LTop >= LINK_STACK_SIZE - 1 then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, SLinkStackOverflow);
      Break;
    end;
    if (LSide and 2) <> 0 then
    begin
      LStack[LTop] := LNode.Children[1];
      Inc(LTop);
    end;
    if LTop >= LINK_STACK_SIZE - 1 then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, SLinkStackOverflow);
      Break;
    end;
  end;
  Result := LAreas;
end;

function TAasEntityLinks.LinkEntityClientBBox(const AAbsMins, AAbsMaxs: TVec3; const AEntNum,
  APresenceType: Integer): Integer;
var
  LMins, LMaxs, LNewMins, LNewMaxs: TVec3;
  LIndex: Integer;
begin
  TAasBoxMath.PresenceTypeBoundingBox(FImport, APresenceType, LMins, LMaxs);
  for LIndex := 0 to 2 do
  begin
    LNewMins[LIndex] := AAbsMins[LIndex] - LMaxs[LIndex];
    LNewMaxs[LIndex] := AAbsMaxs[LIndex] - LMins[LIndex];
  end;
  Result := LinkEntity(LNewMins, LNewMaxs, AEntNum);
end;

procedure TAasEntityLinks.Unlink(const AHead: Integer);
var
  LLink, LNext: Integer;
begin
  LLink := AHead;
  while LLink <> AAS_NO_LINK do
  begin
    GetLink(LLink);
    LNext := FHeap[LLink].NextArea;
    // remove the entity from the list of the area
    if FHeap[LLink].PrevEnt <> AAS_NO_LINK then
      FHeap[FHeap[LLink].PrevEnt].NextEnt := FHeap[LLink].NextEnt
    else
      FAreaLinkedEntities[FHeap[LLink].AreaNum] := FHeap[LLink].NextEnt;
    if FHeap[LLink].NextEnt <> AAS_NO_LINK then
      FHeap[FHeap[LLink].NextEnt].PrevEnt := FHeap[LLink].PrevEnt;
    Deallocate(LLink);
    LLink := LNext;
  end;
end;

function TAasEntityLinks.NextArea(const ALink: Integer): Integer;
begin
  Result := GetLink(ALink).NextArea;
end;

function TAasEntityLinks.AreaNum(const ALink: Integer): Integer;
begin
  Result := GetLink(ALink).AreaNum;
end;

function TAasEntityLinks.EntNum(const ALink: Integer): Integer;
begin
  Result := GetLink(ALink).EntNum;
end;

function TAasEntityLinks.AreaHead(const AAreaNum: Integer): Integer;
begin
  if (AAreaNum < 0) or (AAreaNum >= Length(FAreaLinkedEntities)) then
    raise EAasLinkException.CreateFmt(SLinkBadLink, [AAreaNum]);
  Result := FAreaLinkedEntities[AAreaNum];
end;

function TAasEntityLinks.NextEnt(const ALink: Integer): Integer;
begin
  Result := GetLink(ALink).NextEnt;
end;

end.
