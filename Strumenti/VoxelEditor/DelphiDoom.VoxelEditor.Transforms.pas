{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - flips and turns of a picture                      }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Transforms;

interface

uses
  DelphiDoom.VoxelEditor.Types;

type
  /// <summary>The changes of the picture of a plane (the flip and rotate buttons of DD_VOXEL), on a square picture</summary>
  TVoxelEditorTransforms = class sealed
  public
    /// <summary>The first index of the picture is reversed (the left and the right sides change places)</summary>
    class function FlipHorizontal(const AImage: TVoxelEditorImage; ASize: Integer): TVoxelEditorImage; static;
    /// <summary>The second index is reversed (the top and the bottom change places)</summary>
    class function FlipVertical(const AImage: TVoxelEditorImage; ASize: Integer): TVoxelEditorImage; static;
    class function RotateCounterClockwise(const AImage: TVoxelEditorImage; ASize: Integer): TVoxelEditorImage; static;
    class function RotateClockwise(const AImage: TVoxelEditorImage; ASize: Integer): TVoxelEditorImage; static;
  end;

implementation

{ TVoxelEditorTransforms }

class function TVoxelEditorTransforms.FlipHorizontal(const AImage: TVoxelEditorImage;
  ASize: Integer): TVoxelEditorImage;
var
  LI, LJ: Integer;
begin
  SetLength(Result, Length(AImage));
  for LI := 0 to ASize - 1 do
    for LJ := 0 to ASize - 1 do
      Result[(ASize - 1 - LI) * ASize + LJ] := AImage[LI * ASize + LJ];
end;

class function TVoxelEditorTransforms.FlipVertical(const AImage: TVoxelEditorImage;
  ASize: Integer): TVoxelEditorImage;
var
  LI, LJ: Integer;
begin
  SetLength(Result, Length(AImage));
  for LI := 0 to ASize - 1 do
    for LJ := 0 to ASize - 1 do
      Result[LI * ASize + (ASize - 1 - LJ)] := AImage[LI * ASize + LJ];
end;

class function TVoxelEditorTransforms.RotateCounterClockwise(const AImage: TVoxelEditorImage;
  ASize: Integer): TVoxelEditorImage;
var
  LI, LJ: Integer;
begin
  SetLength(Result, Length(AImage));
  // the pixel (x, y) goes to (y, size - 1 - x)
  for LI := 0 to ASize - 1 do
    for LJ := 0 to ASize - 1 do
      Result[LJ * ASize + (ASize - 1 - LI)] := AImage[LI * ASize + LJ];
end;

class function TVoxelEditorTransforms.RotateClockwise(const AImage: TVoxelEditorImage;
  ASize: Integer): TVoxelEditorImage;
var
  LI, LJ: Integer;
begin
  SetLength(Result, Length(AImage));
  // the pixel (x, y) goes to (size - 1 - y, x)
  for LI := 0 to ASize - 1 do
    for LJ := 0 to ASize - 1 do
      Result[(ASize - 1 - LJ) * ASize + LI] := AImage[LI * ASize + LJ];
end;

end.
