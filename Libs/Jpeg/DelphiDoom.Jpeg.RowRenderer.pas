{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the rows of pixels from the planes of the components     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.RowRenderer;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.ColorConverter, DelphiDoom.Jpeg.ComponentBuffers,
  DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.RowUpsampler, DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   Makes the pixels of one row of the image: widens the rows of the
  ///   components that have fewer samples, then converts the colors
  /// </summary>
  /// <remarks>
  ///   Port of the upsampling of jdsample.c of libjpeg 6b (the choice of the
  ///   method for each component: full size, doubled with a triangle filter,
  ///   repeated). libjpeg does it a group of rows at a time with the rows
  ///   that come before and after kept in a ring of buffers; here the planes
  ///   hold the whole image, so a row asks for its neighbours directly: the
  ///   rows above the first and below the last are the first and the last
  ///   (the context rows that libjpeg makes by copying)
  /// </remarks>
  TJpegRowRenderer = class
  private
    FFrame: TJpegFrame;
    FBuffers: TArray<TJpegComponentBuffers>;
    FConverter: IJpegColorConverter;
    FMethods: array[0..JPEG_MAX_COMPONENTS - 1] of IJpegRowUpsampler;
    FSmoothsVertically: array[0..JPEG_MAX_COMPONENTS - 1] of Boolean;
    FVerticalExpansion: array[0..JPEG_MAX_COMPONENTS - 1] of Integer;
    FScratch: array[0..JPEG_MAX_COMPONENTS - 1] of TBytes;
  public
    /// <summary>
    ///   Chooses how each component is widened
    /// </summary>
    /// <exception cref="EJpegDecodeException">
    ///   The sampling factors of a component do not divide those of the largest
    /// </exception>
    constructor Create(AFrame: TJpegFrame; const ABuffers: TArray<TJpegComponentBuffers>;
      const AConverter: IJpegColorConverter);

    /// <summary>
    ///   Writes the pixels of the row ARow of the image into AOutput
    /// </summary>
    procedure RenderRow(ARow: Integer; AOutput: PByte);
  end;

implementation

uses
  DelphiDoom.Jpeg.FancyUpsamplerH2V1, DelphiDoom.Jpeg.FancyUpsamplerH2V2,
  DelphiDoom.Jpeg.ReplicatingUpsampler;

{ TJpegRowRenderer }

constructor TJpegRowRenderer.Create(AFrame: TJpegFrame;
  const ABuffers: TArray<TJpegComponentBuffers>; const AConverter: IJpegColorConverter);
var
  LIndex: Integer;
  LComponent: PJpegComponentInfo;
  LHorizontalOut: Integer;
  LVerticalOut: Integer;
  LScratchSize: Integer;
begin
  inherited Create;
  FFrame := AFrame;
  FBuffers := ABuffers;
  FConverter := AConverter;

  LHorizontalOut := AFrame.MaxHorizontal;
  LVerticalOut := AFrame.MaxVertical;
  // The width of the image rounded up to a multiple of the largest factor:
  // the upsamplers write whole groups
  LScratchSize := (AFrame.ImageWidth + LHorizontalOut - 1) div LHorizontalOut *
    LHorizontalOut + LHorizontalOut;

  for LIndex := 0 to AFrame.ComponentCount - 1 do
  begin
    LComponent := AFrame.ComponentByIndex[LIndex];
    FVerticalExpansion[LIndex] := 1;
    FSmoothsVertically[LIndex] := False;

    if (LComponent^.Horizontal = LHorizontalOut) and
       (LComponent^.Vertical = LVerticalOut) then
      // As big as the image: the rows of the plane are used as they are
      FMethods[LIndex] := nil
    else if (LComponent^.Horizontal * 2 = LHorizontalOut) and
            (LComponent^.Vertical = LVerticalOut) then
    begin
      // Half the width
      if LComponent^.DownsampledWidth > 2 then
        FMethods[LIndex] := TJpegFancyUpsamplerH2V1.Create(LComponent^.DownsampledWidth)
      else
        FMethods[LIndex] := TJpegReplicatingUpsampler.Create(2, AFrame.ImageWidth);
    end
    else if (LComponent^.Horizontal * 2 = LHorizontalOut) and
            (LComponent^.Vertical * 2 = LVerticalOut) then
    begin
      // Half the width and half the height
      FVerticalExpansion[LIndex] := 2;
      if LComponent^.DownsampledWidth > 2 then
      begin
        FMethods[LIndex] := TJpegFancyUpsamplerH2V2.Create(LComponent^.DownsampledWidth);
        FSmoothsVertically[LIndex] := True;
      end
      else
        FMethods[LIndex] := TJpegReplicatingUpsampler.Create(2, AFrame.ImageWidth);
    end
    else if (LHorizontalOut mod LComponent^.Horizontal = 0) and
            (LVerticalOut mod LComponent^.Vertical = 0) then
    begin
      // Any whole number of times
      FVerticalExpansion[LIndex] := LVerticalOut div LComponent^.Vertical;
      FMethods[LIndex] := TJpegReplicatingUpsampler.Create(
        LHorizontalOut div LComponent^.Horizontal, AFrame.ImageWidth);
    end
    else
      EJpegDecodeException.Fail(jdeFractionalSampling);

    if Assigned(FMethods[LIndex]) then
      SetLength(FScratch[LIndex], LScratchSize);
  end;
end;

procedure TJpegRowRenderer.RenderRow(ARow: Integer; AOutput: PByte);
var
  LRows: array[0..JPEG_MAX_COMPONENTS - 1] of PByte;
  LIndex: Integer;
  LComponent: PJpegComponentInfo;
  LGroup: Integer;
  LPosition: Integer;
  LSourceRow: Integer;
  LNeighbour: Integer;
begin
  LGroup := ARow div FFrame.MaxVertical;
  LPosition := ARow mod FFrame.MaxVertical;

  for LIndex := 0 to FFrame.ComponentCount - 1 do
  begin
    LComponent := FFrame.ComponentByIndex[LIndex];
    LSourceRow := LGroup * LComponent^.Vertical + LPosition div FVerticalExpansion[LIndex];

    if not Assigned(FMethods[LIndex]) then
      LRows[LIndex] := FBuffers[LIndex].PlaneRow(LSourceRow)
    else
    begin
      LNeighbour := LSourceRow;
      if FSmoothsVertically[LIndex] then
      begin
        // The first row of a pair takes the row above, the second the row
        // below; before the first and after the last row there are copies
        if LPosition mod 2 = 0 then
          Dec(LNeighbour)
        else
          Inc(LNeighbour);
        if LNeighbour < 0 then
          LNeighbour := 0
        else if LNeighbour >= LComponent^.DownsampledHeight then
          LNeighbour := LComponent^.DownsampledHeight - 1;
      end;
      FMethods[LIndex].UpsampleRow(FBuffers[LIndex].PlaneRow(LSourceRow),
        FBuffers[LIndex].PlaneRow(LNeighbour), @FScratch[LIndex][0]);
      LRows[LIndex] := @FScratch[LIndex][0];
    end;
  end;

  FConverter.ConvertRow(LRows, AOutput, FFrame.ImageWidth);
end;

end.
