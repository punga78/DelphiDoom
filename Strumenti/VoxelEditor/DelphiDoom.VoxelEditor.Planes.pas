{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - reading and writing the plane that is edited      }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Planes;

interface

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The picture of the plane that the user edits. DD_VOXEL had the same four-way choice (the slice at x, at y,
  ///   at z, or a view) copied in each of its handlers; here it is in one place
  /// </summary>
  TVoxelEditorPlanes = class sealed
  public
    /// <summary>
    ///   The picture of the plane: for a slice the colors of its cells (x: (y, z); y: (x, z); z: (x, y)), for a view
    ///   the colors that are seen. With no plane it is all zeros
    /// </summary>
    class function Read(const AModel: TVoxelEditorModel; const APlane: TVoxelEditorPlane): TVoxelEditorImage; static;
    /// <summary>Puts a picture on a plane (on a view only the first voxel of each ray changes); false if there is no plane</summary>
    class function Write(const AModel: TVoxelEditorModel; const APlane: TVoxelEditorPlane;
      const AImage: TVoxelEditorImage): Boolean; static;
    /// <summary>Empties the plane (what Clear and Cut do)</summary>
    class procedure Erase(const AModel: TVoxelEditorModel; const APlane: TVoxelEditorPlane); static;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Views;

{ TVoxelEditorPlanes }

class function TVoxelEditorPlanes.Read(const AModel: TVoxelEditorModel;
  const APlane: TVoxelEditorPlane): TVoxelEditorImage;
var
  LSize, LI, LJ: Integer;
begin
  LSize := AModel.Size;
  SetLength(Result, LSize * LSize);
  if Length(Result) > 0 then
    FillChar(Result[0], Length(Result) * SizeOf(Cardinal), 0);
  case APlane.Axis of
    veaX:
      for LI := 0 to LSize - 1 do
        for LJ := 0 to LSize - 1 do
          Result[LI * LSize + LJ] := AModel.Get(APlane.Level, LI, LJ);
    veaY:
      for LI := 0 to LSize - 1 do
        for LJ := 0 to LSize - 1 do
          Result[LI * LSize + LJ] := AModel.Get(LI, APlane.Level, LJ);
    veaZ:
      for LI := 0 to LSize - 1 do
        for LJ := 0 to LSize - 1 do
          Result[LI * LSize + LJ] := AModel.Get(LI, LJ, APlane.Level);
  else
    if APlane.View <> vevNone then
      Result := TVoxelEditorViews.GetView(AModel, APlane.View);
  end;
end;

class function TVoxelEditorPlanes.Write(const AModel: TVoxelEditorModel; const APlane: TVoxelEditorPlane;
  const AImage: TVoxelEditorImage): Boolean;
var
  LSize, LI, LJ: Integer;
begin
  LSize := AModel.Size;
  Result := True;
  case APlane.Axis of
    veaX:
      for LI := 0 to LSize - 1 do
        for LJ := 0 to LSize - 1 do
          AModel.Put(APlane.Level, LI, LJ, AImage[LI * LSize + LJ]);
    veaY:
      for LI := 0 to LSize - 1 do
        for LJ := 0 to LSize - 1 do
          AModel.Put(LI, APlane.Level, LJ, AImage[LI * LSize + LJ]);
    veaZ:
      for LI := 0 to LSize - 1 do
        for LJ := 0 to LSize - 1 do
          AModel.Put(LI, LJ, APlane.Level, AImage[LI * LSize + LJ]);
  else
    if APlane.View <> vevNone then
      TVoxelEditorViews.SetView(AModel, APlane.View, AImage)
    else
      Result := False;
  end;
end;

class procedure TVoxelEditorPlanes.Erase(const AModel: TVoxelEditorModel; const APlane: TVoxelEditorPlane);
var
  LBlank: TVoxelEditorImage;
begin
  SetLength(LBlank, AModel.Size * AModel.Size);
  FillChar(LBlank[0], Length(LBlank) * SizeOf(Cardinal), 0);
  Write(AModel, APlane, LBlank);
end;

end.
