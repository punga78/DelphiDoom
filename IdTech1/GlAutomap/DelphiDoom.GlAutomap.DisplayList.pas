{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL automap - the items of a frame                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of the buffer of OPENGL\gl_automap.pas (gld_ClearAMBuffer,             }
{  gld_AddAutomapLine, gld_AddAutomapPatch, gld_AddAutomapTriangle)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlAutomap.DisplayList;

interface

uses
  DelphiDoom.GlAutomap.Types,
  DelphiDoom.GlAutomap.Intf;

type
  /// <summary>The items of the automap of one frame, kept in one block that grows and is never shrunk by Clear</summary>
  /// <remarks>
  ///   The conversions (colour to three floats, fixed point to flats, angle to degrees) are the expressions of the
  ///   old code, in the same order: the numbers given to OpenGL are the same bit by bit
  /// </remarks>
  TGlAutomapDisplayList = class(TInterfacedObject, IGlAutomapDisplayList)
  strict private
    const
      GROW_STEP = 64;
      FIXED_UNIT = 1 shl 16;
      FLAT_SIZE = 64;
      FULL_CIRCLE = $FFFFFFFF;
      FLAT_FIXED_SIZE = FIXED_UNIT * 64.0;
  strict private
    FItems: TArray<TGlAutomapItem>;
    FCount: Integer;
    function NewItem(const AKind: TGlAutomapItemKind): PGlAutomapItem;
    class procedure SetColor(const AItem: PGlAutomapItem; const AColor: Cardinal); static;
  public
    procedure AddBackground(const AWidth, AHeight: Integer; const AColor: Cardinal);
    procedure AddLine(const AX1, AY1, AX2, AY2: Integer; const AColor: Cardinal);
    procedure AddPatch(const AX, AY, ALump: Integer);
    procedure AddTriangle(const AX1, AY1, AU1, AV1, AX2, AY2, AU2, AV2, AX3, AY3, AU3, AV3: Integer;
      const AColor: Cardinal; const ALump: Integer; const AFloor: TGlAutomapFloor);
    function Count: Integer;
    function First: PGlAutomapItem;
    procedure Clear;
    procedure Release;
  end;

implementation

{ TGlAutomapDisplayList }

function TGlAutomapDisplayList.NewItem(const AKind: TGlAutomapItemKind): PGlAutomapItem;
begin
  if FCount >= Length(FItems) then
    SetLength(FItems, Length(FItems) + GROW_STEP);
  Result := @FItems[FCount];
  Result.Kind := AKind;
  Inc(FCount);
end;

class procedure TGlAutomapDisplayList.SetColor(const AItem: PGlAutomapItem; const AColor: Cardinal);
begin
  AItem.Red := ((AColor shr 16) and $FF) / 255;
  AItem.Green := ((AColor shr 8) and $FF) / 255;
  AItem.Blue := (AColor and $FF) / 255;
end;

procedure TGlAutomapDisplayList.AddBackground(const AWidth, AHeight: Integer; const AColor: Cardinal);
var
  LItem: PGlAutomapItem;
begin
  LItem := NewItem(gakBackground);
  LItem.X1 := 0;
  LItem.Y1 := 0;
  LItem.X2 := AWidth;
  LItem.Y2 := AHeight;
  SetColor(LItem, AColor);
end;

procedure TGlAutomapDisplayList.AddLine(const AX1, AY1, AX2, AY2: Integer; const AColor: Cardinal);
var
  LItem: PGlAutomapItem;
begin
  LItem := NewItem(gakLine);
  LItem.X1 := AX1;
  LItem.Y1 := AY1;
  LItem.X2 := AX2;
  LItem.Y2 := AY2;
  SetColor(LItem, AColor);
end;

procedure TGlAutomapDisplayList.AddPatch(const AX, AY, ALump: Integer);
var
  LItem: PGlAutomapItem;
begin
  LItem := NewItem(gakPatch);
  LItem.X1 := AX;
  LItem.Y1 := AY;
  LItem.Lump := ALump;
end;

procedure TGlAutomapDisplayList.AddTriangle(const AX1, AY1, AU1, AV1, AX2, AY2, AU2, AV2, AX3, AY3, AU3,
  AV3: Integer; const AColor: Cardinal; const ALump: Integer; const AFloor: TGlAutomapFloor);
var
  LItem: PGlAutomapItem;
begin
  LItem := NewItem(gakTriangle);

  LItem.X1 := AX1;
  LItem.Y1 := AY1;
  LItem.U1 := AU1 / FIXED_UNIT / FLAT_SIZE;
  LItem.V1 := AV1 / FIXED_UNIT / FLAT_SIZE;

  LItem.X2 := AX2;
  LItem.Y2 := AY2;
  LItem.U2 := AU2 / FIXED_UNIT / FLAT_SIZE;
  LItem.V2 := AV2 / FIXED_UNIT / FLAT_SIZE;

  LItem.X3 := AX3;
  LItem.Y3 := AY3;
  LItem.U3 := AU3 / FIXED_UNIT / FLAT_SIZE;
  LItem.V3 := AV3 / FIXED_UNIT / FLAT_SIZE;

  SetColor(LItem, AColor);

  LItem.Lump := ALump;
  LItem.Flat := AFloor.Flat;
  LItem.Ripples := AFloor.Ripples;
  LItem.OffsetX := AFloor.OffsetX;
  LItem.OffsetY := AFloor.OffsetY;

  LItem.HasAngle := AFloor.Angle <> 0;
  if LItem.HasAngle then
  begin
    LItem.Angle := (AFloor.Angle / FULL_CIRCLE) * 360.0;
    LItem.AngleX := AFloor.AngleX / FLAT_FIXED_SIZE;
    LItem.AngleY := AFloor.AngleY / FLAT_FIXED_SIZE;
  end;
end;

function TGlAutomapDisplayList.Count: Integer;
begin
  Result := FCount;
end;

function TGlAutomapDisplayList.First: PGlAutomapItem;
begin
  if FCount = 0 then
    Result := nil
  else
    Result := @FItems[0];
end;

procedure TGlAutomapDisplayList.Clear;
begin
  FCount := 0;
end;

procedure TGlAutomapDisplayList.Release;
begin
  FCount := 0;
  FItems := nil;
end;

end.
