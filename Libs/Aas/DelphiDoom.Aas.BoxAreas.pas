{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the areas a box touches (be_aas_sample.c)         }
{                                                                              }
{  Port of AAS_BBoxAreas and of the descent of AAS_AASLinkEntity. Based on the }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.BoxAreas;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf;

type
  /// <summary>
  ///   The original links a temporary entity into the areas the box touches through a heap
  ///   of 6144 links and reads the list back; here the areas are collected during the descent
  ///   and given in the order of that list (the last one found first). The heap is not
  ///   modelled: with more than 6144 areas at the same time the original would stop earlier.
  ///   The stack has the 128 entries of the original, and the same checks (done after each
  ///   push, so one entry less is usable).
  /// </summary>
  TAasBoxAreas = class(TInterfacedObject, IAasBoxAreas)
  strict private
    const
      LINK_STACK_SIZE = 128;
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
  public
    constructor Create(const AFile: IAasFile; const AImport: IBotImport);
    function BBoxAreas(const AAbsMins, AAbsMaxs: TVec3; const AMaxAreas: Integer): TArray<Integer>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.BoxMath, DelphiDoom.Aas.Printer;

resourcestring
  SLinkStackOverflow = 'AAS_LinkEntity: stack overflow'#10;
  SLinkBadNode = 'AAS_LinkEntity: the node %d or its plane is out of range'#10;

{ TAasBoxAreas }

constructor TAasBoxAreas.Create(const AFile: IAasFile; const AImport: IBotImport);
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
end;

function TAasBoxAreas.BBoxAreas(const AAbsMins, AAbsMaxs: TVec3; const AMaxAreas: Integer): TArray<Integer>;
var
  LStack: array[0..LINK_STACK_SIZE - 1] of Integer;
  LTop, LNodeNum, LSide, LBudget, LIndex: Integer;
  LNodes: TArray<TAasNode>;
  LPlanes: TArray<TAasPlane>;
  LNode: TAasNode;
  LFound: TArray<Integer>;
  LSeen: TArray<Boolean>;
  LCount: Integer;
begin
  LNodes := FFile.Nodes;
  LPlanes := FFile.Planes;
  SetLength(LSeen, Length(FFile.AreaSettings) + 1);
  LFound := nil;
  LCount := 0;
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
      // a node can have several children that point to the same area
      if (-LNodeNum < Length(LSeen)) and not LSeen[-LNodeNum] then
      begin
        LSeen[-LNodeNum] := True;
        SetLength(LFound, LCount + 1);
        LFound[LCount] := -LNodeNum;
        Inc(LCount);
      end;
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
  // the list of links has the last area found first; AAS_BBoxAreas stops at maxareas
  SetLength(Result, 0);
  if AMaxAreas <= 0 then
    Exit;
  if LCount > AMaxAreas then
    SetLength(Result, AMaxAreas)
  else
    SetLength(Result, LCount);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := LFound[LCount - 1 - LIndex];
end;

end.
