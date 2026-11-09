{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the views of the cube                             }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Views;

interface

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The six views of the cube (vox_getviewbuffer and its friends of the unit voxels of DD_VOXEL): what is seen
  ///   when the cube is looked at from the front, the back, the left, the right, the top or from below. The
  ///   pointers of the old code into the cube are indexes of its cells here
  /// </summary>
  TVoxelEditorViews = class sealed
  public
    /// <summary>The picture of a view: the color of the first voxel that each ray meets (0 if none)</summary>
    class function GetView(const AModel: TVoxelEditorModel; AView: TVoxelEditorView): TVoxelEditorImage; static;
    /// <summary>
    ///   Paints a picture on a view: for each ray the first voxel it meets takes the color of the picture (a ray
    ///   that meets none puts the color on the last cell of the cube in the front, back, left, right and top views,
    ///   and nowhere in the view from below), as the old editor did
    /// </summary>
    class procedure SetView(const AModel: TVoxelEditorModel; AView: TVoxelEditorView;
      const AImage: TVoxelEditorImage); static;
    /// <summary>Like GetView, with the depth of the voxel and the cell in front of it</summary>
    class function GetDepthView(const AModel: TVoxelEditorModel; AView: TVoxelEditorView): TArray<TVoxelEditorDepthItem>; static;
    /// <summary>The cell of the first voxel at (AX, AY) of a view, or the cell at the far end of the ray if there is none</summary>
    class function DepthIndexAtXY(const AModel: TVoxelEditorModel; AX, AY: Integer; AView: TVoxelEditorView): Integer; static;
    /// <summary>The cell of a view at (AX, AY) and the depth AZ (the coordinates are kept inside the cube)</summary>
    class function DepthIndexAtXYZ(const AModel: TVoxelEditorModel; AX, AY, AZ: Integer; AView: TVoxelEditorView): Integer; static;
  end;

implementation

uses
  System.Math;

function Clamp(AValue, ASize: Integer): Integer; inline;
begin
  if AValue < 0 then
    Result := 0
  else if AValue >= ASize then
    Result := ASize - 1
  else
    Result := AValue;
end;

{ TVoxelEditorViews }

class function TVoxelEditorViews.GetView(const AModel: TVoxelEditorModel; AView: TVoxelEditorView): TVoxelEditorImage;
var
  LSize, LA, LB, LC: Integer;
  LColor: Cardinal;
begin
  LSize := AModel.Size;
  SetLength(Result, LSize * LSize);
  if Length(Result) > 0 then
    FillChar(Result[0], Length(Result) * SizeOf(Cardinal), 0);
  case AView of
    vevFront:
      for LA := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
        begin
          LColor := 0;
          for LC := 0 to LSize - 1 do
            if AModel.Get(LA, LB, LC) <> 0 then
            begin
              LColor := AModel.Get(LA, LB, LC);
              Break;
            end;
          Result[LA * LSize + LB] := LColor;
        end;
    vevBack:
      for LA := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
        begin
          LColor := 0;
          for LC := LSize - 1 downto 0 do
            if AModel.Get(LA, LB, LC) <> 0 then
            begin
              LColor := AModel.Get(LA, LB, LC);
              Break;
            end;
          Result[LA * LSize + LB] := LColor;
        end;
    vevLeft:
      for LC := 0 to LSize - 1 do // z
        for LB := 0 to LSize - 1 do // y
        begin
          LColor := 0;
          for LA := 0 to LSize - 1 do // x
            if AModel.Get(LA, LB, LC) <> 0 then
            begin
              LColor := AModel.Get(LA, LB, LC);
              Break;
            end;
          Result[(LSize - 1 - LC) * LSize + LB] := LColor;
        end;
    vevRight:
      for LC := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
        begin
          LColor := 0;
          for LA := LSize - 1 downto 0 do
            if AModel.Get(LA, LB, LC) <> 0 then
            begin
              LColor := AModel.Get(LA, LB, LC);
              Break;
            end;
          Result[LC * LSize + LB] := LColor;
        end;
    vevTop:
      for LA := 0 to LSize - 1 do // x
        for LC := 0 to LSize - 1 do // z
        begin
          LColor := 0;
          for LB := 0 to LSize - 1 do // y
            if AModel.Get(LA, LB, LC) <> 0 then
            begin
              LColor := AModel.Get(LA, LB, LC);
              Break;
            end;
          Result[LA * LSize + (LSize - 1 - LC)] := LColor;
        end;
    vevDown:
      for LA := 0 to LSize - 1 do
        for LC := 0 to LSize - 1 do
        begin
          LColor := 0;
          for LB := LSize - 1 downto 0 do
            if AModel.Get(LA, LB, LC) <> 0 then
            begin
              LColor := AModel.Get(LA, LB, LC);
              Break;
            end;
          Result[LA * LSize + LC] := LColor;
        end;
  end;
end;

class procedure TVoxelEditorViews.SetView(const AModel: TVoxelEditorModel; AView: TVoxelEditorView;
  const AImage: TVoxelEditorImage);
var
  LSize, LA, LB, LC: Integer;
begin
  LSize := AModel.Size;
  case AView of
    vevFront:
      for LA := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
          for LC := 0 to LSize - 1 do
            if (AModel.Get(LA, LB, LC) <> 0) or (LC = LSize - 1) then
            begin
              AModel.Put(LA, LB, LC, AImage[LA * LSize + LB]);
              Break;
            end;
    vevBack:
      for LA := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
          for LC := LSize - 1 downto 0 do
            if (AModel.Get(LA, LB, LC) <> 0) or (LC = 0) then
            begin
              AModel.Put(LA, LB, LC, AImage[LA * LSize + LB]);
              Break;
            end;
    vevLeft:
      for LC := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
          for LA := 0 to LSize - 1 do
            if (AModel.Get(LA, LB, LC) <> 0) or (LA = LSize - 1) then
            begin
              AModel.Put(LA, LB, LC, AImage[(LSize - 1 - LC) * LSize + LB]);
              Break;
            end;
    vevRight:
      for LC := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
          for LA := LSize - 1 downto 0 do
            if (AModel.Get(LA, LB, LC) <> 0) or (LA = 0) then
            begin
              AModel.Put(LA, LB, LC, AImage[LC * LSize + LB]);
              Break;
            end;
    vevTop:
      for LA := 0 to LSize - 1 do
        for LC := 0 to LSize - 1 do
          for LB := 0 to LSize - 1 do
            if (AModel.Get(LA, LB, LC) <> 0) or (LB = LSize - 1) then
            begin
              AModel.Put(LA, LB, LC, AImage[LA * LSize + (LSize - 1 - LC)]);
              Break;
            end;
    vevDown:
      for LA := 0 to LSize - 1 do
        for LC := 0 to LSize - 1 do
          for LB := LSize - 1 downto 0 do
            if AModel.Get(LA, LB, LC) <> 0 then
            begin
              AModel.Put(LA, LB, LC, AImage[LA * LSize + LC]);
              Break;
            end;
  end;
end;

class function TVoxelEditorViews.GetDepthView(const AModel: TVoxelEditorModel;
  AView: TVoxelEditorView): TArray<TVoxelEditorDepthItem>;
var
  LSize, LA, LB, LC, LTarget, LIndex: Integer;
  LItem: TVoxelEditorDepthItem;
begin
  LSize := AModel.Size;
  SetLength(Result, LSize * LSize);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Color := 0;
    Result[LIndex].Depth := LSize;
    Result[LIndex].Previous := -1;
  end;
  if AView = vevNone then
    Exit;
  // each ray is (a, b) in the picture and runs along the depth axis; the loops are the ones of the old code
  case AView of
    vevFront, vevBack:
      for LA := 0 to LSize - 1 do
        for LB := 0 to LSize - 1 do
        begin
          LItem.Color := 0;
          LItem.Depth := LSize;
          if AView = vevFront then
          begin
            LItem.Previous := AModel.IndexOf(LA, LB, LSize - 1);
            for LC := 0 to LSize - 1 do
              if AModel.Get(LA, LB, LC) <> 0 then
              begin
                LItem.Color := AModel.Get(LA, LB, LC);
                LItem.Previous := AModel.IndexOf(LA, LB, Max(LC - 1, 0));
                LItem.Depth := LC;
                Break;
              end;
          end
          else
          begin
            LItem.Previous := AModel.IndexOf(LA, LB, 0);
            for LC := LSize - 1 downto 0 do
              if AModel.Get(LA, LB, LC) <> 0 then
              begin
                LItem.Color := AModel.Get(LA, LB, LC);
                LItem.Previous := AModel.IndexOf(LA, LB, Min(LC + 1, LSize - 1));
                LItem.Depth := LC;
                Break;
              end;
          end;
          Result[LA * LSize + LB] := LItem;
        end;
    vevLeft, vevRight:
      for LC := 0 to LSize - 1 do // z
        for LB := 0 to LSize - 1 do // y
        begin
          LItem.Color := 0;
          LItem.Depth := LSize;
          if AView = vevLeft then
          begin
            LItem.Previous := AModel.IndexOf(LSize - 1, LB, LC);
            for LA := 0 to LSize - 1 do
              if AModel.Get(LA, LB, LC) <> 0 then
              begin
                LItem.Color := AModel.Get(LA, LB, LC);
                LItem.Previous := AModel.IndexOf(Max(LA - 1, 0), LB, LC);
                LItem.Depth := LA;
                Break;
              end;
            LTarget := (LSize - 1 - LC) * LSize + LB;
          end
          else
          begin
            LItem.Previous := AModel.IndexOf(0, LB, LC);
            for LA := LSize - 1 downto 0 do
              if AModel.Get(LA, LB, LC) <> 0 then
              begin
                LItem.Color := AModel.Get(LA, LB, LC);
                LItem.Previous := AModel.IndexOf(Min(LA + 1, LSize - 1), LB, LC);
                LItem.Depth := LA;
                Break;
              end;
            LTarget := LC * LSize + LB;
          end;
          Result[LTarget] := LItem;
        end;
    vevTop, vevDown:
      for LA := 0 to LSize - 1 do // x
        for LC := 0 to LSize - 1 do // z
        begin
          LItem.Color := 0;
          LItem.Depth := LSize;
          if AView = vevTop then
          begin
            LItem.Previous := AModel.IndexOf(LA, LSize - 1, LC);
            for LB := 0 to LSize - 1 do
              if AModel.Get(LA, LB, LC) <> 0 then
              begin
                LItem.Color := AModel.Get(LA, LB, LC);
                LItem.Previous := AModel.IndexOf(LA, Max(LB - 1, 0), LC);
                LItem.Depth := LB;
                Break;
              end;
            LTarget := LA * LSize + (LSize - 1 - LC);
          end
          else
          begin
            LItem.Previous := AModel.IndexOf(LA, 0, LC);
            for LB := LSize - 1 downto 0 do
              if AModel.Get(LA, LB, LC) <> 0 then
              begin
                LItem.Color := AModel.Get(LA, LB, LC);
                LItem.Previous := AModel.IndexOf(LA, Min(LB + 1, LSize - 1), LC);
                LItem.Depth := LB;
                Break;
              end;
            LTarget := LA * LSize + LC;
          end;
          Result[LTarget] := LItem;
        end;
  end;
end;

class function TVoxelEditorViews.DepthIndexAtXY(const AModel: TVoxelEditorModel; AX, AY: Integer;
  AView: TVoxelEditorView): Integer;
var
  LSize, LX, LY, LZ: Integer;
begin
  LSize := AModel.Size;
  Result := -1;
  case AView of
    vevFront, vevBack:
      begin
        LX := Clamp(AX, LSize);
        LY := Clamp(AY, LSize);
        if AView = vevFront then
        begin
          for LZ := 0 to LSize - 1 do
            if AModel.Get(LX, LY, LZ) <> 0 then
              Exit(AModel.IndexOf(LX, LY, LZ));
          Result := AModel.IndexOf(LX, LY, LSize - 1);
        end
        else
        begin
          for LZ := LSize - 1 downto 0 do
            if AModel.Get(LX, LY, LZ) <> 0 then
              Exit(AModel.IndexOf(LX, LY, LZ));
          Result := AModel.IndexOf(LX, LY, 0);
        end;
      end;
    vevLeft, vevRight:
      begin
        LZ := Clamp(IfThen(AView = vevLeft, LSize - 1 - AX, AX), LSize);
        LY := Clamp(AY, LSize);
        if AView = vevLeft then
        begin
          for LX := 0 to LSize - 1 do
            if AModel.Get(LX, LY, LZ) <> 0 then
              Exit(AModel.IndexOf(LX, LY, LZ));
          Result := AModel.IndexOf(LSize - 1, LY, LZ);
        end
        else
        begin
          for LX := LSize - 1 downto 0 do
            if AModel.Get(LX, LY, LZ) <> 0 then
              Exit(AModel.IndexOf(LX, LY, LZ));
          Result := AModel.IndexOf(0, LY, LZ);
        end;
      end;
    vevTop, vevDown:
      begin
        LX := Clamp(AX, LSize);
        LZ := Clamp(IfThen(AView = vevTop, LSize - 1 - AY, AY), LSize);
        if AView = vevTop then
        begin
          for LY := 0 to LSize - 1 do
            if AModel.Get(LX, LY, LZ) <> 0 then
              Exit(AModel.IndexOf(LX, LY, LZ));
          Result := AModel.IndexOf(LX, LSize - 1, LZ);
        end
        else
        begin
          for LY := LSize - 1 downto 0 do
            if AModel.Get(LX, LY, LZ) <> 0 then
              Exit(AModel.IndexOf(LX, LY, LZ));
          Result := AModel.IndexOf(LX, 0, LZ);
        end;
      end;
  end;
end;

class function TVoxelEditorViews.DepthIndexAtXYZ(const AModel: TVoxelEditorModel; AX, AY, AZ: Integer;
  AView: TVoxelEditorView): Integer;
var
  LSize, LX, LY, LZ: Integer;
begin
  LSize := AModel.Size;
  Result := -1;
  case AView of
    vevFront, vevBack:
      Result := AModel.IndexOf(Clamp(AX, LSize), Clamp(AY, LSize), Clamp(AZ, LSize));
    vevLeft:
      begin
        LZ := Clamp(LSize - 1 - AX, LSize);
        LY := Clamp(AY, LSize);
        LX := Clamp(AZ, LSize);
        Result := AModel.IndexOf(LX, LY, LZ);
      end;
    vevRight:
      begin
        LZ := Clamp(AX, LSize);
        LY := Clamp(AY, LSize);
        LX := Clamp(AZ, LSize);
        Result := AModel.IndexOf(LX, LY, LZ);
      end;
    vevTop:
      begin
        LX := Clamp(AX, LSize);
        LY := Clamp(AZ, LSize);
        LZ := Clamp(LSize - 1 - AY, LSize);
        Result := AModel.IndexOf(LX, LY, LZ);
      end;
    vevDown:
      begin
        LX := Clamp(AX, LSize);
        LY := Clamp(AZ, LSize);
        LZ := Clamp(AY, LSize);
        Result := AModel.IndexOf(LX, LY, LZ);
      end;
  end;
end;

end.
