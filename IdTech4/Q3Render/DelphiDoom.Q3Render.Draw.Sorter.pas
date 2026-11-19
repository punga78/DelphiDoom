{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the sort of the  }
{  drawSurfs                                                                   }
{                                                                              }
{  qsortFast and shortsort of renderer\tr_main.c, step by step: the sort is    }
{  not stable and many surfaces share a key (the same shader, fog and entity), }
{  so the order of those is the order of this algorithm, which the backend     }
{  draws. Based on the Quake III Arena GPL Source Code (id Software).          }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Draw.Sorter;

interface

uses
  System.SysUtils, DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>qsortFast for drawSurf_t: a quick sort that falls back to a selection sort for 8 elements or fewer</summary>
  TQ3DrawSurfSorter = class sealed
  strict private
    class procedure Swap(var ASurfaces: TArray<TQ3DrawSurf>; AFirst, ASecond: Integer); static;
    class procedure ShortSort(var ASurfaces: TArray<TQ3DrawSurf>; ALow, AHigh: Integer); static;
  public
    /// <summary>Sorts the ACount surfaces from AFirst by the sort key, ascending</summary>
    class procedure Sort(var ASurfaces: TArray<TQ3DrawSurf>; AFirst, ACount: Integer); static;
  end;

implementation

const
  // CUTOFF of the original: an array this long or shorter is sorted by selection
  Cutoff = 8;

class procedure TQ3DrawSurfSorter.Swap(var ASurfaces: TArray<TQ3DrawSurf>; AFirst, ASecond: Integer);
var
  LTemporary: TQ3DrawSurf;
begin
  LTemporary := ASurfaces[AFirst];
  ASurfaces[AFirst] := ASurfaces[ASecond];
  ASurfaces[ASecond] := LTemporary;
end;

class procedure TQ3DrawSurfSorter.ShortSort(var ASurfaces: TArray<TQ3DrawSurf>; ALow, AHigh: Integer);
var
  LPosition, LMax: Integer;
begin
  while AHigh > ALow do
  begin
    LMax := ALow;
    for LPosition := ALow + 1 to AHigh do
      if ASurfaces[LPosition].Sort > ASurfaces[LMax].Sort then
        LMax := LPosition;
    Swap(ASurfaces, LMax, AHigh);
    Dec(AHigh);
  end;
end;

class procedure TQ3DrawSurfSorter.Sort(var ASurfaces: TArray<TQ3DrawSurf>; AFirst, ACount: Integer);
var
  LLowStack, LHighStack: array[0..29] of Integer;
  LStackPointer, LLow, LHigh, LSize, LMiddle, LLowGuy, LHighGuy: Integer;
  LRecurse: Boolean;
begin
  if ACount < 2 then
    Exit;
  LStackPointer := 0;
  LLow := AFirst;
  LHigh := AFirst + ACount - 1;
  while True do
  begin
    LRecurse := False;
    LSize := LHigh - LLow + 1;
    if LSize <= Cutoff then
      ShortSort(ASurfaces, LLow, LHigh)
    else
    begin
      // the middle element is the one to partition by: it goes to the start
      LMiddle := LLow + LSize div 2;
      Swap(ASurfaces, LMiddle, LLow);
      LLowGuy := LLow;
      LHighGuy := LHigh + 1;
      while True do
      begin
        repeat
          Inc(LLowGuy);
        until not ((LLowGuy <= LHigh) and (ASurfaces[LLowGuy].Sort <= ASurfaces[LLow].Sort));
        repeat
          Dec(LHighGuy);
        until not ((LHighGuy > LLow) and (ASurfaces[LHighGuy].Sort >= ASurfaces[LLow].Sort));
        if LHighGuy < LLowGuy then
          Break;
        Swap(ASurfaces, LLowGuy, LHighGuy);
      end;
      // the element of the partition in place
      Swap(ASurfaces, LLow, LHighGuy);
      // the smaller part now, the bigger one from the stack later
      if LHighGuy - 1 - LLow >= LHigh - LLowGuy then
      begin
        if LLow + 1 < LHighGuy then
        begin
          LLowStack[LStackPointer] := LLow;
          LHighStack[LStackPointer] := LHighGuy - 1;
          Inc(LStackPointer);
        end;
        if LLowGuy < LHigh then
        begin
          LLow := LLowGuy;
          LRecurse := True;
        end;
      end
      else
      begin
        if LLowGuy < LHigh then
        begin
          LLowStack[LStackPointer] := LLowGuy;
          LHighStack[LStackPointer] := LHigh;
          Inc(LStackPointer);
        end;
        if LLow + 1 < LHighGuy then
        begin
          LHigh := LHighGuy - 1;
          LRecurse := True;
        end;
      end;
    end;
    if LRecurse then
      Continue;
    // sorted but for what is on the stack
    Dec(LStackPointer);
    if LStackPointer < 0 then
      Break;
    LLow := LLowStack[LStackPointer];
    LHigh := LHighStack[LStackPointer];
  end;
end;

end.
