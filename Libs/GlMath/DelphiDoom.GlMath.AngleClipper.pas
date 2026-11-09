{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL math library - the clipper of angles                     }
{  Port of Libs\OpenGl\Legacy\gl_clipper.pas, loosely based on the JDoom clipper.          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
//
// The algorithm of the clipper is the one of the original, with this notice:
//
// Copyright 2003 Tim Stump
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
unit DelphiDoom.GlMath.AngleClipper;

interface

uses
  DelphiDoom.GlMath.Types,
  DelphiDoom.GlMath.Intf;

type
  /// <summary>
  ///   The old gl_clipper: a sorted list of ranges of angles that walls already hide. The nodes
  ///   are in an array and link to each other with indexes (no pointers: the same at 32 and 64
  ///   bit); a node that leaves the list goes to a free list and is used again. The steps of the
  ///   old code are kept one by one, because the list has to end up identical.
  /// </summary>
  TGlAngleClipper = class(TInterfacedObject, IGlAngleClipper)
  strict private
    type
      TClipNode = record
        Prev: Integer;
        Next: Integer;
        Start: TGlAngle;
        Finish: TGlAngle;
      end;
    const
      NO_NODE = -1;
  strict private
    FNodes: TArray<TClipNode>;
    FUsed: Integer;
    FFreeList: Integer;
    FHead: Integer;
    function GetNewNode: Integer;
    function NewRange(const AStart, AFinish: TGlAngle): Integer;
    procedure FreeNode(const ANode: Integer);
    procedure RemoveRange(const ARange: Integer);
  public
    constructor Create;
    procedure Clear;
    procedure Release;
    /// <summary>Adds a range that does not pass over the zero (start less or equal to finish)</summary>
    procedure AddRange(const AStart, AFinish: TGlAngle);
    /// <summary>False if the range (start less or equal to end) is all in the list</summary>
    function IsRangeVisible(const AStartAngle, AEndAngle: TGlAngle): Boolean;
    procedure SafeAddRange(const AStartAngle, AEndAngle: TGlAngle);
    function SafeCheckRange(const AStartAngle, AEndAngle: TGlAngle): Boolean;
    function GetRangeCount: Integer;
    function GetRangeStart(const AIndex: Integer): TGlAngle;
    function GetRangeFinish(const AIndex: Integer): TGlAngle;
  end;

implementation

uses
  System.SysUtils;

{ TGlAngleClipper }

constructor TGlAngleClipper.Create;
begin
  inherited Create;
  FHead := NO_NODE;
  FFreeList := NO_NODE;
end;

function TGlAngleClipper.GetNewNode: Integer;
begin
  if FFreeList <> NO_NODE then
  begin
    Result := FFreeList;
    FFreeList := FNodes[Result].Next;
    Exit;
  end;
  if FUsed >= Length(FNodes) then
  begin
    if Length(FNodes) = 0 then
      SetLength(FNodes, 16)
    else
      SetLength(FNodes, Length(FNodes) * 2);
  end;
  Result := FUsed;
  Inc(FUsed);
end;

function TGlAngleClipper.NewRange(const AStart, AFinish: TGlAngle): Integer;
begin
  Result := GetNewNode;
  FNodes[Result].Start := AStart;
  FNodes[Result].Finish := AFinish;
  FNodes[Result].Next := NO_NODE;
  FNodes[Result].Prev := NO_NODE;
end;

procedure TGlAngleClipper.FreeNode(const ANode: Integer);
begin
  FNodes[ANode].Next := FFreeList;
  FFreeList := ANode;
end;

procedure TGlAngleClipper.RemoveRange(const ARange: Integer);
begin
  if ARange = FHead then
    FHead := FNodes[FHead].Next
  else
  begin
    if FNodes[ARange].Prev <> NO_NODE then
      FNodes[FNodes[ARange].Prev].Next := FNodes[ARange].Next;
    if FNodes[ARange].Next <> NO_NODE then
      FNodes[FNodes[ARange].Next].Prev := FNodes[ARange].Prev;
  end;
  FreeNode(ARange);
end;

function TGlAngleClipper.IsRangeVisible(const AStartAngle, AEndAngle: TGlAngle): Boolean;
var
  LNode: Integer;
begin
  LNode := FHead;

  if AEndAngle = 0 then
    if LNode <> NO_NODE then
      if FNodes[LNode].Start = 0 then
      begin
        Result := False;
        Exit;
      end;

  while (LNode <> NO_NODE) and (FNodes[LNode].Start < AEndAngle) do
  begin
    if (AStartAngle >= FNodes[LNode].Start) and (AEndAngle <= FNodes[LNode].Finish) then
    begin
      Result := False;
      Exit;
    end;
    LNode := FNodes[LNode].Next;
  end;

  Result := True;
end;

procedure TGlAngleClipper.AddRange(const AStart, AFinish: TGlAngle);
var
  LNode, LTemp, LPrevNode: Integer;
begin
  if FHead = NO_NODE then
  begin
    FHead := NewRange(AStart, AFinish);
    Exit;
  end;

  // does the range contain any old range?
  LNode := FHead;
  while (LNode <> NO_NODE) and (FNodes[LNode].Start < AFinish) do
  begin
    if (FNodes[LNode].Start >= AStart) and (FNodes[LNode].Finish <= AFinish) then
    begin
      LTemp := LNode;
      LNode := FNodes[LNode].Next;
      RemoveRange(LTemp);
    end
    else
    begin
      if (FNodes[LNode].Start <= AStart) and (FNodes[LNode].Finish >= AFinish) then
        Exit
      else
        LNode := FNodes[LNode].Next;
    end;
  end;

  // does the range overlap a range (or possibly two)?
  LNode := FHead;
  while LNode <> NO_NODE do
  begin
    if (FNodes[LNode].Start >= AStart) and (FNodes[LNode].Start <= AFinish) then
    begin
      FNodes[LNode].Start := AStart;
      Exit;
    end;
    if (FNodes[LNode].Finish >= AStart) and (FNodes[LNode].Finish <= AFinish) then
    begin
      // check for a possible merger
      if (FNodes[LNode].Next <> NO_NODE) and (FNodes[FNodes[LNode].Next].Start <= AFinish) then
      begin
        FNodes[LNode].Finish := FNodes[FNodes[LNode].Next].Finish;
        RemoveRange(FNodes[LNode].Next);
      end
      else
        FNodes[LNode].Finish := AFinish;
      Exit;
    end;
    LNode := FNodes[LNode].Next;
  end;

  // just add the range
  LNode := FHead;
  LPrevNode := NO_NODE;
  LTemp := NewRange(AStart, AFinish);
  while (LNode <> NO_NODE) and (FNodes[LNode].Start < AFinish) do
  begin
    LPrevNode := LNode;
    LNode := FNodes[LNode].Next;
  end;
  FNodes[LTemp].Next := LNode;
  if LNode = NO_NODE then
  begin
    FNodes[LTemp].Prev := LPrevNode;
    if LPrevNode <> NO_NODE then
      FNodes[LPrevNode].Next := LTemp;
    if FHead = NO_NODE then
      FHead := LTemp;
  end
  else
  begin
    if LNode = FHead then
    begin
      FNodes[FHead].Prev := LTemp;
      FHead := LTemp;
    end
    else
    begin
      FNodes[LTemp].Prev := LPrevNode;
      FNodes[LPrevNode].Next := LTemp;
      FNodes[LNode].Prev := LTemp;
    end;
  end;
end;

procedure TGlAngleClipper.SafeAddRange(const AStartAngle, AEndAngle: TGlAngle);
begin
  if AStartAngle > AEndAngle then
  begin
    // the range passes over the zero: it is added in two parts
    AddRange(AStartAngle, GLMATH_ANGLE_MAX);
    AddRange(0, AEndAngle);
  end
  else
    AddRange(AStartAngle, AEndAngle);
end;

function TGlAngleClipper.SafeCheckRange(const AStartAngle, AEndAngle: TGlAngle): Boolean;
begin
  if AStartAngle > AEndAngle then
    Result := IsRangeVisible(AStartAngle, GLMATH_ANGLE_MAX) or IsRangeVisible(0, AEndAngle)
  else
    Result := IsRangeVisible(AStartAngle, AEndAngle);
end;

procedure TGlAngleClipper.Clear;
var
  LNode, LTemp: Integer;
begin
  LNode := FHead;
  while LNode <> NO_NODE do
  begin
    LTemp := LNode;
    LNode := FNodes[LNode].Next;
    FreeNode(LTemp);
  end;
  FHead := NO_NODE;
end;

procedure TGlAngleClipper.Release;
begin
  FNodes := nil;
  FUsed := 0;
  FFreeList := NO_NODE;
  FHead := NO_NODE;
end;

function TGlAngleClipper.GetRangeCount: Integer;
var
  LNode: Integer;
begin
  Result := 0;
  LNode := FHead;
  while LNode <> NO_NODE do
  begin
    Inc(Result);
    LNode := FNodes[LNode].Next;
  end;
end;

function TGlAngleClipper.GetRangeStart(const AIndex: Integer): TGlAngle;
var
  LNode, LStep: Integer;
begin
  LNode := FHead;
  LStep := AIndex;
  while (LNode <> NO_NODE) and (LStep > 0) do
  begin
    LNode := FNodes[LNode].Next;
    Dec(LStep);
  end;
  if (LNode = NO_NODE) or (AIndex < 0) then
    raise EGlMathException.CreateFmt(SGlMathInvalidRangeIndex, [AIndex]);
  Result := FNodes[LNode].Start;
end;

function TGlAngleClipper.GetRangeFinish(const AIndex: Integer): TGlAngle;
var
  LNode, LStep: Integer;
begin
  LNode := FHead;
  LStep := AIndex;
  while (LNode <> NO_NODE) and (LStep > 0) do
  begin
    LNode := FNodes[LNode].Next;
    Dec(LStep);
  end;
  if (LNode = NO_NODE) or (AIndex < 0) then
    raise EGlMathException.CreateFmt(SGlMathInvalidRangeIndex, [AIndex]);
  Result := FNodes[LNode].Finish;
end;

end.
