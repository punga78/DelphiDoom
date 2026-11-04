{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - builds the REJECT lump                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of reject.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Reject.Builder;

interface

uses
  System.SysUtils,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Wad.Document;

type
  /// <summary>
  ///   Builds a basic REJECT table: it only finds the groups of sectors that
  ///   are isolated from the others (islands surrounded by void space)
  /// </summary>
  TGlbspRejectBuilder = class
  private
    FData: TGlbspLevelData;
    FWad: TGlbspWad;
    procedure InitReject;
    procedure GroupSectors;
    function CreateReject: TBytes;
  public
    /// <param name="AData">Level whose sectors and linedefs are used</param>
    /// <param name="AWad">WAD whose current level receives the lump</param>
    constructor Create(const AData: TGlbspLevelData; const AWad: TGlbspWad);

    /// <summary>
    ///   The matrix as it is written to the lump: a bit for every pair of
    ///   sectors, set when the two are in different groups
    /// </summary>
    function BuildMatrix: TBytes;

    /// <summary>Builds the matrix and writes it to the REJECT lump</summary>
    procedure PutReject;
  end;

implementation

uses
  DelphiDoom.Glbsp.Level.Types;

{ TGlbspRejectBuilder }

constructor TGlbspRejectBuilder.Create(const AData: TGlbspLevelData; const AWad: TGlbspWad);
begin
  inherited Create;
  FData := AData;
  FWad := AWad;
end;

procedure TGlbspRejectBuilder.InitReject;
var
  LIndex: Integer;
  LSector: TGlbspSector;
begin
  // Every sector goes in its own group
  for LIndex := 0 to FData.Sectors.Count - 1 do
  begin
    LSector := FData.Sectors[LIndex];
    LSector.RejGroup := LIndex;
    LSector.RejNext := LSector;
    LSector.RejPrev := LSector;
  end;
end;

procedure TGlbspRejectBuilder.GroupSectors;
var
  LLine: TGlbspLinedef;
  LSector1, LSector2, LTemp: TGlbspSector;
begin
  // Every 2-sectored line merges the groups of its two sectors
  for LLine in FData.Linedefs do
  begin
    if not Assigned(LLine.Right) or not Assigned(LLine.Left) then
      Continue;

    // The standard DOOM engine does not allow sight past lines without the
    // TWOSIDED flag, so they are skipped here too
    if not LLine.TwoSided then
      Continue;

    LSector1 := LLine.Right.Sector;
    LSector2 := LLine.Left.Sector;

    if not Assigned(LSector1) or not Assigned(LSector2) or (LSector1 = LSector2) then
      Continue;

    // Already in the same group?
    if LSector1.RejGroup = LSector2.RejGroup then
      Continue;

    // The smaller group number is kept: sector numbers generally increase
    // over the linedefs, so the small groups tend to join the larger ones
    // and the updates of the group numbers are fewer
    if LSector1.RejGroup > LSector2.RejGroup then
    begin
      LTemp := LSector1;
      LSector1 := LSector2;
      LSector2 := LTemp;
    end;

    // The group numbers of the second group are updated
    LSector2.RejGroup := LSector1.RejGroup;
    LTemp := LSector2.RejNext;
    while LTemp <> LSector2 do
    begin
      LTemp.RejGroup := LSector1.RejGroup;
      LTemp := LTemp.RejNext;
    end;

    // The two rings are merged
    LSector1.RejNext.RejPrev := LSector2;
    LSector2.RejNext.RejPrev := LSector1;

    LTemp := LSector1.RejNext;
    LSector1.RejNext := LSector2.RejNext;
    LSector2.RejNext := LTemp;
  end;
end;

function TGlbspRejectBuilder.CreateReject: TBytes;
var
  LCount, LView, LTarget, LP1, LP2: Integer;
begin
  LCount := FData.Sectors.Count;
  SetLength(Result, (LCount * LCount + 7) div 8);

  for LView := 0 to LCount - 1 do
  begin
    for LTarget := 0 to LView - 1 do
    begin
      if FData.Sectors[LView].RejGroup = FData.Sectors[LTarget].RejGroup then
        Continue;

      // Two bits at a time, for symmetry
      LP1 := LView * LCount + LTarget;
      LP2 := LTarget * LCount + LView;

      Result[LP1 shr 3] := Result[LP1 shr 3] or (1 shl (LP1 and 7));
      Result[LP2 shr 3] := Result[LP2 shr 3] or (1 shl (LP2 and 7));
    end;
  end;
end;

function TGlbspRejectBuilder.BuildMatrix: TBytes;
begin
  InitReject;
  GroupSectors;
  Result := CreateReject;
end;

procedure TGlbspRejectBuilder.PutReject;
var
  LMatrix: TBytes;
begin
  LMatrix := BuildMatrix;
  if Length(LMatrix) > 0 then
    FWad.CreateLevelLump('REJECT').Append(LMatrix[0], Length(LMatrix))
  else
    FWad.CreateLevelLump('REJECT');
end;

end.
