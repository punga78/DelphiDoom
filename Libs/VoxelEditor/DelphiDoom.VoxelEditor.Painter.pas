{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the tools that paint on a plane                   }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Painter;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The mouse tools of the plane (PaintBox1MouseDown and the responders of the main window of DD_VOXEL): free
  ///   draw, erase, elevate, flood fill and the color picker. The window gives the mouse in pixels of the picture
  ///   of the plane (Zoom pixels for each cell); the painter changes the cube. A stroke between two mouse events is
  ///   a line of pixels, as in the old editor. On a view the depth of each cell is the one of the start of the
  ///   stroke (RefreshDepth), so a stroke does not dig into the voxels it has just painted
  /// </summary>
  TVoxelEditorPainter = class
  strict private
    FModel: TVoxelEditorModel;
    FPlane: TVoxelEditorPlane;
    FZoom: Integer;
    FTool: TVoxelEditorTool;
    FColor1: Cardinal;
    FColor2: Cardinal;
    FDepth: TArray<TVoxelEditorDepthItem>;
    FButton: TVoxelEditorMouseButton;
    FIsDown: Boolean;
    FRoverX, FRoverY: Integer;
    FChanged: Boolean;
    FBeforeChange: TProc;
    procedure NotifyBeforeChange;
    function CellOf(APixel: Integer): Integer;
    function StrokeColor: Cardinal;
    procedure PaintCell(AX, AY: Integer; AColor: Cardinal);
    procedure ElevateCell(AX, AY: Integer; AColor: Cardinal);
    procedure FreePaint(AX, AY: Integer; AIsDown: Boolean);
    procedure Eraser(AX, AY: Integer; AIsDown: Boolean);
    procedure Elevate(AX, AY: Integer; AIsDown: Boolean);
    procedure FloodFill(AX, AY: Integer);
    procedure PickColor(AX, AY: Integer);
    procedure Respond(AX, AY: Integer; AIsDown: Boolean);
  public
    constructor Create(const AModel: TVoxelEditorModel);
    /// <summary>The depths of the view are read again from the cube (after any change that is not a stroke)</summary>
    procedure RefreshDepth;
    procedure MouseDown(AButton: TVoxelEditorMouseButton; AX, AY: Integer);
    procedure MouseMove(AX, AY: Integer);
    procedure MouseUp;
    /// <summary>What the status bar says about the pixel under the mouse: "x=1, y=2, depth=3, color=(r, g, b)"; empty if no plane</summary>
    function StatusAt(AX, AY: Integer): string;
    /// <summary>The cube the painter works on; it is not owned (the editor can change it)</summary>
    property Model: TVoxelEditorModel read FModel write FModel;
    property Plane: TVoxelEditorPlane read FPlane write FPlane;
    property Zoom: Integer read FZoom write FZoom;
    property Tool: TVoxelEditorTool read FTool write FTool;
    property Color1: Cardinal read FColor1 write FColor1;
    property Color2: Cardinal read FColor2 write FColor2;
    /// <summary>True if a stroke changed the cube since the flag was cleared</summary>
    property Changed: Boolean read FChanged write FChanged;
    /// <summary>
    ///   Called just before the first change of a stroke (the old editor saved its undo at that moment): the
    ///   editor stores a snapshot of the cube
    /// </summary>
    property OnBeforeChange: TProc read FBeforeChange write FBeforeChange;
    property Depth: TArray<TVoxelEditorDepthItem> read FDepth;
  end;

implementation

uses
  System.Math,
  DelphiDoom.VoxelEditor.Views,
  DelphiDoom.VoxelEditor.Planes;

{ TVoxelEditorPainter }

constructor TVoxelEditorPainter.Create(const AModel: TVoxelEditorModel);
begin
  inherited Create;
  if not Assigned(AModel) then
    raise EArgumentNilException.Create('AModel');
  FModel := AModel;
  FZoom := 4;
  FColor1 := $FFFFFF;
  FRoverX := -1;
  FRoverY := -1;
  FPlane := TVoxelEditorPlane.OfView(vevTop);
end;

procedure TVoxelEditorPainter.NotifyBeforeChange;
begin
  if Assigned(FBeforeChange) then
    FBeforeChange();
end;

procedure TVoxelEditorPainter.RefreshDepth;
begin
  FDepth := TVoxelEditorViews.GetDepthView(FModel, FPlane.View);
end;

function TVoxelEditorPainter.CellOf(APixel: Integer): Integer;
begin
  Result := EnsureRange(APixel div FZoom, 0, FModel.Size - 1);
end;

function TVoxelEditorPainter.StrokeColor: Cardinal;
begin
  if FButton = vebLeft then
    Result := FColor1
  else
    Result := FColor2;
end;

procedure TVoxelEditorPainter.PaintCell(AX, AY: Integer; AColor: Cardinal);
var
  LX, LY, LZ, LIndex: Integer;
begin
  case FPlane.Axis of
    veaX:
      begin
        LX := FPlane.Level;
        LY := AX div FZoom;
        LZ := AY div FZoom;
      end;
    veaY:
      begin
        LX := AX div FZoom;
        LY := FPlane.Level;
        LZ := AY div FZoom;
      end;
    veaZ:
      begin
        LX := AX div FZoom;
        LY := AY div FZoom;
        LZ := FPlane.Level;
      end;
  else
    if FPlane.View = vevNone then
      Exit;
    LX := AX div FZoom;
    LY := AY div FZoom;
    LZ := 0;
  end;
  LX := EnsureRange(LX, 0, FModel.Size - 1);
  LY := EnsureRange(LY, 0, FModel.Size - 1);
  LZ := EnsureRange(LZ, 0, FModel.Size - 1);
  if FPlane.View <> vevNone then
  begin
    LIndex := TVoxelEditorViews.DepthIndexAtXYZ(FModel, LX, LY, Integer(FDepth[LX * FModel.Size + LY].Depth), FPlane.View);
    FModel.Cells[LIndex] := AColor;
  end
  else
    FModel.Put(LX, LY, LZ, AColor);
  FChanged := True;
end;

procedure TVoxelEditorPainter.ElevateCell(AX, AY: Integer; AColor: Cardinal);
var
  LX, LY, LIndex: Integer;
begin
  if (AColor = 0) or (FPlane.View = vevNone) or (FPlane.Axis <> veaNone) then
    Exit;
  LX := CellOf(AX);
  LY := CellOf(AY);
  LIndex := FDepth[LX * FModel.Size + LY].Previous;
  if LIndex < 0 then
    Exit;
  FModel.Cells[LIndex] := AColor;
  FChanged := True;
end;

// the line of pixels between the last point of the stroke and this one: a cell is painted at each step
procedure TVoxelEditorPainter.FreePaint(AX, AY: Integer; AIsDown: Boolean);
var
  LColor: Cardinal;
  LDX, LDY: Double;
  LLength, LStep, LAX, LAY, LLastX, LLastY: Integer;
begin
  LColor := StrokeColor;
  LLastX := FRoverX;
  LLastY := FRoverY;
  if AIsDown or (FRoverX = -1) or (FRoverY = -1) then
    PaintCell(AX, AY, LColor)
  else
  begin
    LLength := Round(Sqrt((AX - FRoverX) * (AX - FRoverX) + (AY - FRoverY) * (AY - FRoverY)));
    if LLength > 0 then
    begin
      LDX := (FRoverX - AX) / LLength;
      LDY := (FRoverY - AY) / LLength;
      for LStep := 0 to LLength - 1 do
      begin
        LAX := Round(AX + LDX * LStep);
        LAY := Round(AY + LDY * LStep);
        if (LAX <> LLastX) or (LAY <> LLastY) then
        begin
          PaintCell(LAX, LAY, LColor);
          LLastX := LAX;
          LLastY := LAY;
        end;
      end;
      if (AX <> LLastX) or (AY <> LLastY) then
        PaintCell(AX, AY, LColor);
    end;
  end;
end;

procedure TVoxelEditorPainter.Eraser(AX, AY: Integer; AIsDown: Boolean);
var
  LDX, LDY: Double;
  LLength, LStep, LAX, LAY, LLastX, LLastY: Integer;
begin
  LLastX := FRoverX;
  LLastY := FRoverY;
  if AIsDown or (FRoverX = -1) or (FRoverY = -1) then
    PaintCell(AX, AY, 0)
  else
  begin
    LLength := Round(Sqrt((AX - FRoverX) * (AX - FRoverX) + (AY - FRoverY) * (AY - FRoverY)));
    if LLength > 0 then
    begin
      LDX := (FRoverX - AX) / LLength;
      LDY := (FRoverY - AY) / LLength;
      for LStep := 0 to LLength - 1 do
      begin
        LAX := Round(AX + LDX * LStep);
        LAY := Round(AY + LDY * LStep);
        if (LAX <> LLastX) or (LAY <> LLastY) then
        begin
          PaintCell(LAX, LAY, 0);
          LLastX := LAX;
          LLastY := LAY;
        end;
      end;
    end;
    // unlike the free draw, the last cell is painted even if the stroke has no length
    if (AX <> LLastX) or (AY <> LLastY) then
      PaintCell(AX, AY, 0);
  end;
end;

procedure TVoxelEditorPainter.Elevate(AX, AY: Integer; AIsDown: Boolean);
var
  LColor: Cardinal;
  LDX, LDY: Double;
  LLength, LStep, LAX, LAY, LLastX, LLastY: Integer;
begin
  LColor := StrokeColor;
  LLastX := FRoverX;
  LLastY := FRoverY;
  if AIsDown or (FRoverX = -1) or (FRoverY = -1) then
    ElevateCell(AX, AY, LColor)
  else
  begin
    LLength := Round(Sqrt((AX - FRoverX) * (AX - FRoverX) + (AY - FRoverY) * (AY - FRoverY)));
    if LLength > 0 then
    begin
      LDX := (FRoverX - AX) / LLength;
      LDY := (FRoverY - AY) / LLength;
      for LStep := 0 to LLength - 1 do
      begin
        LAX := Round(AX + LDX * LStep);
        LAY := Round(AY + LDY * LStep);
        if (LAX <> LLastX) or (LAY <> LLastY) then
        begin
          ElevateCell(LAX, LAY, LColor);
          LLastX := LAX;
          LLastY := LAY;
        end;
      end;
      if (AX <> LLastX) or (AY <> LLastY) then
        ElevateCell(AX, AY, LColor);
    end;
  end;
end;

procedure TVoxelEditorPainter.FloodFill(AX, AY: Integer);
var
  LSize, LX, LY, LCurrent, LNext: Integer;
  LPicture: TVoxelEditorImage;
  LOld, LNew: Cardinal;
  LStack: TArray<Integer>;
  LTop: Integer;

  procedure Push(AIndex: Integer);
  begin
    if LTop >= Length(LStack) then
      SetLength(LStack, Length(LStack) * 2 + 64);
    LStack[LTop] := AIndex;
    Inc(LTop);
  end;

begin
  if not FPlane.IsValid then
    Exit;
  LSize := FModel.Size;
  LPicture := TVoxelEditorPlanes.Read(FModel, FPlane);
  LX := CellOf(AX);
  LY := CellOf(AY);
  LOld := LPicture[LX * LSize + LY];
  LNew := StrokeColor;
  if LOld = LNew then
    Exit;
  NotifyBeforeChange;
  // the cells with the old color that touch each other by a side take the new one
  LTop := 0;
  Push(LX * LSize + LY);
  while LTop > 0 do
  begin
    Dec(LTop);
    LCurrent := LStack[LTop];
    if LPicture[LCurrent] <> LOld then
      Continue;
    LPicture[LCurrent] := LNew;
    LX := LCurrent div LSize;
    LY := LCurrent mod LSize;
    if LX > 0 then
    begin
      LNext := LCurrent - LSize;
      if LPicture[LNext] = LOld then
        Push(LNext);
    end;
    if LX < LSize - 1 then
    begin
      LNext := LCurrent + LSize;
      if LPicture[LNext] = LOld then
        Push(LNext);
    end;
    if LY > 0 then
    begin
      LNext := LCurrent - 1;
      if LPicture[LNext] = LOld then
        Push(LNext);
    end;
    if LY < LSize - 1 then
    begin
      LNext := LCurrent + 1;
      if LPicture[LNext] = LOld then
        Push(LNext);
    end;
  end;
  TVoxelEditorPlanes.Write(FModel, FPlane, LPicture);
  FChanged := True;
end;

procedure TVoxelEditorPainter.PickColor(AX, AY: Integer);
var
  LX, LY: Integer;
  LColor: Cardinal;
begin
  LX := CellOf(AX);
  LY := CellOf(AY);
  case FPlane.Axis of
    veaX:
      LColor := FModel.Get(FPlane.Level, LX, LY);
    veaY:
      LColor := FModel.Get(LX, FPlane.Level, LY);
    veaZ:
      LColor := FModel.Get(LX, LY, FPlane.Level);
  else
    if FPlane.View = vevNone then
      Exit;
    LColor := FDepth[LX * FModel.Size + LY].Color;
  end;
  if FButton = vebLeft then
    FColor1 := LColor
  else
    FColor2 := LColor;
end;

procedure TVoxelEditorPainter.Respond(AX, AY: Integer; AIsDown: Boolean);
begin
  if not FPlane.IsValid then
    Exit;
  if not FIsDown then
    Exit;
  case FTool of
    vetFreeDraw:
      FreePaint(AX, AY, AIsDown);
    vetFloodFill:
      FloodFill(AX, AY);
    vetColorPicker:
      PickColor(AX, AY);
    vetEraser:
      Eraser(AX, AY, AIsDown);
    vetElevate:
      Elevate(AX, AY, AIsDown);
  end;
  FRoverX := AX;
  FRoverY := AY;
end;

procedure TVoxelEditorPainter.MouseDown(AButton: TVoxelEditorMouseButton; AX, AY: Integer);
begin
  FRoverX := -1;
  FRoverY := -1;
  FButton := AButton;
  FIsDown := True;
  if FTool in [vetFreeDraw, vetEraser, vetElevate] then
  begin
    NotifyBeforeChange;
    if FPlane.Axis = veaNone then
      RefreshDepth;
  end;
  Respond(AX, AY, True);
end;

procedure TVoxelEditorPainter.MouseMove(AX, AY: Integer);
begin
  Respond(AX, AY, False);
end;

procedure TVoxelEditorPainter.MouseUp;
begin
  FIsDown := False;
  FRoverX := -1;
  FRoverY := -1;
  RefreshDepth;
end;

function TVoxelEditorPainter.StatusAt(AX, AY: Integer): string;
var
  LX, LY, LZ, LDepth: Integer;
  LColor: Cardinal;
  LItem: TVoxelEditorDepthItem;
begin
  Result := '';
  if not FPlane.IsValid then
    Exit;
  case FPlane.Axis of
    veaX:
      begin
        LX := FPlane.Level;
        LY := AX div FZoom;
        LZ := AY div FZoom;
        LDepth := LX;
      end;
    veaY:
      begin
        LX := AX div FZoom;
        LY := FPlane.Level;
        LZ := AY div FZoom;
        LDepth := LY;
      end;
    veaZ:
      begin
        LX := AX div FZoom;
        LY := AY div FZoom;
        LZ := FPlane.Level;
        LDepth := LZ;
      end;
  else
    LX := EnsureRange(AX div FZoom, 0, FModel.Size - 1);
    LY := EnsureRange(AY div FZoom, 0, FModel.Size - 1);
    LItem := FDepth[LX * FModel.Size + LY];
    LZ := Integer(LItem.Depth);
    LDepth := LZ;
  end;
  LX := EnsureRange(LX, 0, FModel.Size - 1);
  LY := EnsureRange(LY, 0, FModel.Size - 1);
  LZ := EnsureRange(LZ, 0, FModel.Size - 1);
  if FPlane.Axis = veaNone then
    LColor := LItem.Color
  else
    LColor := FModel.Get(LX, LY, LZ);
  Result := Format('x=%d, y=%d, depth=%d, color=(%d, %d, %d)',
    [AX div FZoom, AY div FZoom, LDepth, LColor and $FF, (LColor shr 8) and $FF, (LColor shr 16) and $FF]);
end;

end.
