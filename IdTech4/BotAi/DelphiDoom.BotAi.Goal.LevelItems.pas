{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotLevelItems, the items of the level                 }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): levelitemheap,      }
{  freelevelitems, levelitems, InitLevelItemHeap, AllocLevelItem,              }
{  FreeLevelItem, AddLevelItemToList and RemoveLevelItemFromList of            }
{  code\botlib\be_ai_goal.c. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.LevelItems;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Goal.Types;

type
  PBotLevelItem = ^TBotLevelItem;

  /// <summary>
  ///   The heap of level items (an array whose free entries are a list, as in the original) and the list of the
  ///   items of the level. The links are indexes in the heap; <c>NoItem</c> (-1) is NULL. The order of the list
  ///   matters: new items go at the head and the choice of a goal takes the first of the best.
  /// </summary>
  TBotLevelItems = class
  strict private
    FImport: IBotImport;
    FHeap: TArray<TBotLevelItem>;
    FFree: Integer;
    FHead: Integer;
  public
    const
      NoItem = -1;
    constructor Create(const AImport: IBotImport);
    /// <summary>
    ///   InitLevelItemHeap: AMaxItems entries, all free (the original with 0 entries writes before the heap: here
    ///   the heap is empty)
    /// </summary>
    procedure Init(const AMaxItems: Integer);
    /// <summary>
    ///   AllocLevelItem: a cleared item; NoItem, with "out of level items" printed, if there are none left
    /// </summary>
    function Alloc: Integer;
    /// <summary>FreeLevelItem</summary>
    procedure Release(const AIndex: Integer);
    /// <summary>AddLevelItemToList: at the head</summary>
    procedure AddToList(const AIndex: Integer);
    /// <summary>RemoveLevelItemFromList</summary>
    procedure RemoveFromList(const AIndex: Integer);
    /// <summary>The first item of the list (levelitems), NoItem if the list is empty</summary>
    property Head: Integer read FHead;
    /// <summary>Forgets the list (levelitems = NULL); the heap stays as it is</summary>
    procedure ClearList;
    /// <summary>Forgets the heap and the list (BotShutdownGoalAI)</summary>
    procedure Reset;
    /// <summary>The item at the index of the heap</summary>
    function Item(const AIndex: Integer): PBotLevelItem;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Exceptions;

resourcestring
  SItemOutOfRange = 'The heap of level items has no entry %d';

{ TBotLevelItems }

constructor TBotLevelItems.Create(const AImport: IBotImport);
begin
  inherited Create;
  FImport := AImport;
  FFree := NoItem;
  FHead := NoItem;
end;

procedure TBotLevelItems.Init(const AMaxItems: Integer);
var
  LIndex: Integer;
begin
  SetLength(FHeap, 0);
  if AMaxItems > 0 then
  begin
    SetLength(FHeap, AMaxItems);
    for LIndex := 0 to AMaxItems - 2 do
      FHeap[LIndex].Next := LIndex + 1;
    FHeap[AMaxItems - 1].Next := NoItem;
    FHeap[0].Prev := NoItem;
    FFree := 0;
  end
  else
    FFree := NoItem;
end;

function TBotLevelItems.Alloc: Integer;
begin
  Result := FFree;
  if Result = NoItem then
  begin
    FImport.Print(PRT_FATAL, 'out of level items'#10);
    Exit;
  end;
  FFree := FHeap[Result].Next;
  FHeap[Result] := Default(TBotLevelItem);
  FHeap[Result].Prev := NoItem;
  FHeap[Result].Next := NoItem;
end;

procedure TBotLevelItems.Release(const AIndex: Integer);
begin
  FHeap[AIndex].Next := FFree;
  FFree := AIndex;
end;

procedure TBotLevelItems.AddToList(const AIndex: Integer);
begin
  if FHead <> NoItem then
    FHeap[FHead].Prev := AIndex;
  FHeap[AIndex].Prev := NoItem;
  FHeap[AIndex].Next := FHead;
  FHead := AIndex;
end;

procedure TBotLevelItems.RemoveFromList(const AIndex: Integer);
begin
  if FHeap[AIndex].Prev <> NoItem then
    FHeap[FHeap[AIndex].Prev].Next := FHeap[AIndex].Next
  else
    FHead := FHeap[AIndex].Next;
  if FHeap[AIndex].Next <> NoItem then
    FHeap[FHeap[AIndex].Next].Prev := FHeap[AIndex].Prev;
end;

procedure TBotLevelItems.ClearList;
begin
  FHead := NoItem;
end;

procedure TBotLevelItems.Reset;
begin
  SetLength(FHeap, 0);
  FFree := NoItem;
  FHead := NoItem;
end;

function TBotLevelItems.Item(const AIndex: Integer): PBotLevelItem;
begin
  if (AIndex < 0) or (AIndex >= Length(FHeap)) then
    raise EBotAiException.CreateFmt(SItemOutOfRange, [AIndex]);
  Result := @FHeap[AIndex];
end;

end.
