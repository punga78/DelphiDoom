{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the heap of the temporary reachabilities          }
{                                                                              }
{  Port of AAS_SetupReachabilityHeap, AAS_AllocReachability,                   }
{  AAS_FreeReachability, AAS_ReachabilityExists and of the lists of            }
{  reachabilities of the areas (areareachability) of be_aas_reach.c. Based on  }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C)            }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Heap;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Reach.Types;

type
  /// <summary>
  ///   The heap of links of the reachabilities, as the original keeps it: an array with the free links in a list
  ///   (Next), the last link is given out with an error message and the one after it is NULL. The pointers point into
  ///   the array, which is never resized. The import is not owned
  /// </summary>
  TAasReachHeap = class
  strict private
    FImport: IBotImport;
    FItems: TArray<TAasLinkedReach>;
    FNextFree: PAasLinkedReach;
    FCount: Integer;
    FAreaReach: TArray<PAasLinkedReach>;
  public
    /// <summary>AAS_SetupReachabilityHeap and the allocation of areareachability: AHeapSize links, AAreaCount lists</summary>
    constructor Create(const AImport: IBotImport; const AAreaCount: Integer;
      const AHeapSize: Integer = AAS_MAX_REACHABILITYSIZE);
    /// <summary>AAS_AllocReachability: a zeroed link, nil when the heap is empty</summary>
    function Allocate: PAasLinkedReach;
    /// <summary>AAS_FreeReachability: clears the link and puts it back at the head of the free list</summary>
    procedure Release(const ALink: PAasLinkedReach);
    /// <summary>AAS_ReachabilityExists: True if the list of the area has a link to the other area</summary>
    function Exists(const AFromArea, AToArea: Integer): Boolean;
    /// <summary>Links the reachability at the head of the list of the area (areareachability[area] = lreach)</summary>
    procedure Push(const AAreaNum: Integer; const ALink: PAasLinkedReach);
    /// <summary>The head of the list of the area</summary>
    function Head(const AAreaNum: Integer): PAasLinkedReach;
    /// <summary>numlreachabilities: the links that are given out</summary>
    property Count: Integer read FCount;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Printer;

{ TAasReachHeap }

constructor TAasReachHeap.Create(const AImport: IBotImport; const AAreaCount, AHeapSize: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FImport := AImport;
  SetLength(FItems, AHeapSize);
  for LIndex := 0 to AHeapSize - 2 do
    FItems[LIndex].Next := @FItems[LIndex + 1];
  if AHeapSize > 0 then
  begin
    FItems[AHeapSize - 1].Next := nil;
    FNextFree := @FItems[0];
  end
  else
    FNextFree := nil;
  FCount := 0;
  SetLength(FAreaReach, AAreaCount);
end;

function TAasReachHeap.Allocate: PAasLinkedReach;
begin
  Result := FNextFree;
  if Result = nil then
    Exit;
  // the error shows up once, when the last link is given out
  if Result^.Next = nil then
    TAasPrinter.Print(FImport, PRT_FATAL, 'AAS_MAX_REACHABILITYSIZE');
  FNextFree := Result^.Next;
  Inc(FCount);
end;

procedure TAasReachHeap.Release(const ALink: PAasLinkedReach);
begin
  FillChar(ALink^, SizeOf(TAasLinkedReach), 0);
  ALink^.Next := FNextFree;
  FNextFree := ALink;
  Dec(FCount);
end;

function TAasReachHeap.Exists(const AFromArea, AToArea: Integer): Boolean;
var
  LLink: PAasLinkedReach;
begin
  LLink := FAreaReach[AFromArea];
  while LLink <> nil do
  begin
    if LLink^.AreaNum = AToArea then
      Exit(True);
    LLink := LLink^.Next;
  end;
  Result := False;
end;

procedure TAasReachHeap.Push(const AAreaNum: Integer; const ALink: PAasLinkedReach);
begin
  ALink^.Next := FAreaReach[AAreaNum];
  FAreaReach[AAreaNum] := ALink;
end;

function TAasReachHeap.Head(const AAreaNum: Integer): PAasLinkedReach;
begin
  Result := FAreaReach[AAreaNum];
end;

end.
