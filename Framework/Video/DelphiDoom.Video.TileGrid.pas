{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the grid of tiles of a patch on a page          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.TileGrid;

interface

type
  /// <summary>Where a copy of the patch is drawn on the page</summary>
  TVideoTilePosition = record
    X: Integer;
    Y: Integer;
  end;

  /// <summary>
  ///   Pure rule of V_TileScreen8 (v_video): where the copies of a patch go when a page is
  ///   filled with it. Cold (once per page), static functions, no state
  /// </summary>
  TVideoTileGrid = class sealed
  public
    /// <summary>
    ///   First coordinate of a row or column of tiles: 0 when the patch has no offset, minus its size
    ///   otherwise (the first tile starts outside of the page)
    /// </summary>
    class function Start(const AOffset, ASize: Integer): Integer; static;
    /// <summary>
    ///   The positions of the tiles that fill AAreaWidth x AAreaHeight, column by column (x is the outer
    ///   loop, as in the old code). Empty when the patch has no size
    /// </summary>
    class function Positions(const APatchWidth, APatchHeight, ALeftOffset, ATopOffset: Integer;
      const AAreaWidth, AAreaHeight: Integer): TArray<TVideoTilePosition>; static;
  end;

implementation

class function TVideoTileGrid.Start(const AOffset, ASize: Integer): Integer;
begin
  if AOffset = 0 then
    Result := 0
  else
    Result := -ASize;
end;

class function TVideoTileGrid.Positions(const APatchWidth, APatchHeight, ALeftOffset, ATopOffset: Integer;
  const AAreaWidth, AAreaHeight: Integer): TArray<TVideoTilePosition>;
var
  LX: Integer;
  LY: Integer;
  LStartY: Integer;
  LCount: Integer;
begin
  Result := nil;
  if (APatchWidth <= 0) or (APatchHeight <= 0) then
    Exit;
  LStartY := Start(ATopOffset, APatchHeight);
  LCount := 0;
  LX := Start(ALeftOffset, APatchWidth);
  while LX < AAreaWidth do
  begin
    LY := LStartY;
    while LY < AAreaHeight do
    begin
      SetLength(Result, LCount + 1);
      Result[LCount].X := LX;
      Result[LCount].Y := LY;
      Inc(LCount);
      LY := LY + APatchHeight;
    end;
    LX := LX + APatchWidth;
  end;
end;

end.
