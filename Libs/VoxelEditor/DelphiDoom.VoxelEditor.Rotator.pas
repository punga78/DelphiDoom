{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - turning the cube around the vertical axis         }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.VoxelEditor.Rotator;

interface

uses
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The rotation of the cube around the y axis (VXE_RotateVoxelBuffer and VXE_RotateVoxelBufferHQ of
  ///   vxe_export). The sums of colors are meant to wrap (the unit has range and overflow checks off)
  /// </summary>
  TVoxelEditorRotator = class sealed
  public
    /// <summary>
    ///   Each cell takes the cell that the rotation by ATheta (radians) brings to it; a cell that comes from
    ///   outside the cube is empty. The old code used the nearest cell and so does this
    /// </summary>
    class procedure Rotate(const AModel: TVoxelEditorModel; ATheta: Double); static;
    /// <summary>
    ///   The high quality rotation: each layer is enlarged three times, turned, and each cell takes the mean of its
    ///   3 x 3 block (the center counts twice)
    /// </summary>
    class procedure RotateHighQuality(const AModel: TVoxelEditorModel; ATheta: Double); static;
  end;

implementation

uses
  System.SysUtils;

{ TVoxelEditorRotator }

class procedure TVoxelEditorRotator.Rotate(const AModel: TVoxelEditorModel; ATheta: Double);
var
  LSize, LX, LY, LZ, LNewX, LNewZ: Integer;
  LSin, LCos, LHalf: Double;
  LColor: Cardinal;
  LResult: TArray<Cardinal>;
begin
  LSize := AModel.Size;
  LSin := Sin(ATheta);
  LCos := Cos(ATheta);
  LHalf := LSize / 2;
  SetLength(LResult, Length(AModel.Cells));
  FillChar(LResult[0], Length(LResult) * SizeOf(Cardinal), 0);
  for LY := 0 to LSize - 1 do
    for LX := 0 to LSize - 1 do
      for LZ := 0 to LSize - 1 do
      begin
        LNewX := Round(LHalf + (LX - LHalf) * LCos - (LZ - LHalf) * LSin);
        LNewZ := Round(LHalf + (LX - LHalf) * LSin + (LZ - LHalf) * LCos);
        if (LNewX >= 0) and (LNewX < LSize) and (LNewZ >= 0) and (LNewZ < LSize) then
        begin
          LColor := AModel.Get(LNewX, LY, LNewZ);
          if LColor <> 0 then
            LResult[(LX * LSize + LY) * LSize + LZ] := LColor;
        end;
      end;
  Move(LResult[0], AModel.Cells[0], Length(LResult) * SizeOf(Cardinal));
end;

class procedure TVoxelEditorRotator.RotateHighQuality(const AModel: TVoxelEditorModel; ATheta: Double);
var
  LSize, LBig, LX, LY, LZ, LX3, LZ3, LNewX, LNewZ, LI, LJ: Integer;
  LSin, LCos, LMid: Double;
  LColor: Cardinal;
  LSums, LBlown: TArray<Cardinal>;
  LCounts: TArray<Integer>;
  LNum, LRed, LGreen, LBlue: Cardinal;
  LResult: TArray<Cardinal>;
begin
  LSize := AModel.Size;
  LBig := 3 * LSize;
  LSin := Sin(ATheta);
  LCos := Cos(ATheta);
  LMid := 3 * LSize / 2;
  SetLength(LResult, Length(AModel.Cells));
  FillChar(LResult[0], Length(LResult) * SizeOf(Cardinal), 0);
  SetLength(LSums, LBig * LBig);
  SetLength(LBlown, LBig * LBig);
  SetLength(LCounts, LBig * LBig);
  for LY := 0 to LSize - 1 do
  begin
    FillChar(LSums[0], Length(LSums) * SizeOf(Cardinal), 0);
    FillChar(LBlown[0], Length(LBlown) * SizeOf(Cardinal), 0);
    FillChar(LCounts[0], Length(LCounts) * SizeOf(Integer), 0);
    // each cell of the layer becomes a block of 3 x 3
    for LX := 0 to LSize - 1 do
      for LZ := 0 to LSize - 1 do
      begin
        LColor := AModel.Get(LX, LY, LZ);
        if LColor <> 0 then
          for LI := 0 to 2 do
            for LJ := 0 to 2 do
              LBlown[(LX * 3 + LI) * LBig + LZ * 3 + LJ] := LColor;
      end;
    for LX := 0 to LBig - 1 do
      for LZ := 0 to LBig - 1 do
      begin
        LNewX := Round(LMid + (LX - LMid) * LCos - (LZ - LMid) * LSin);
        LNewZ := Round(LMid + (LX - LMid) * LSin + (LZ - LMid) * LCos);
        if (LNewX >= 0) and (LNewX < LBig) and (LNewZ >= 0) and (LNewZ < LBig) then
        begin
          LColor := LBlown[LNewX * LBig + LNewZ];
          if LColor <> 0 then
          begin
            LSums[LX * LBig + LZ] := LSums[LX * LBig + LZ] + LColor;
            Inc(LCounts[LX * LBig + LZ]);
          end;
        end;
      end;
    for LX := 0 to LSize - 1 do
    begin
      LX3 := LX * 3;
      for LZ := 0 to LSize - 1 do
      begin
        LZ3 := LZ * 3;
        LNum := 0;
        LRed := 0;
        LGreen := 0;
        LBlue := 0;
        for LI := 0 to 2 do
          for LJ := 0 to 2 do
          begin
            LColor := LSums[(LX3 + LI) * LBig + LZ3 + LJ];
            if LColor <> 0 then
            begin
              if (LI = 1) and (LJ = 1) then
              begin
                // the center has double weight
                Inc(LNum, 2 * Cardinal(LCounts[(LX3 + LI) * LBig + LZ3 + LJ]));
                LRed := LRed + 2 * (LColor and $FF);
                LGreen := LGreen + 2 * ((LColor shr 8) and $FF);
                LBlue := LBlue + 2 * ((LColor shr 16) and $FF);
              end
              else
              begin
                Inc(LNum, Cardinal(LCounts[(LX3 + LI) * LBig + LZ3 + LJ]));
                LRed := LRed + (LColor and $FF);
                LGreen := LGreen + ((LColor shr 8) and $FF);
                LBlue := LBlue + ((LColor shr 16) and $FF);
              end;
            end;
          end;
        if LNum > 3 then
        begin
          LRed := LRed div LNum;
          if LRed > 255 then
            LRed := 255;
          LGreen := LGreen div LNum;
          if LGreen > 255 then
            LGreen := 255;
          LBlue := LBlue div LNum;
          if LBlue > 255 then
            LBlue := 255;
          if (LRed <> 0) or (LGreen <> 0) or (LBlue <> 0) then
            LResult[(LX * LSize + LY) * LSize + LZ] := LRed or (LGreen shl 8) or (LBlue shl 16);
        end;
      end;
    end;
  end;
  Move(LResult[0], AModel.Cells[0], Length(LResult) * SizeOf(Cardinal));
end;

end.
