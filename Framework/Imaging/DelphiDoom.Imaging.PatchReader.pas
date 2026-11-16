{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - decodes the lump of a patch                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.PatchReader;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   Decodes a patch of Doom: a header of four 16 bit numbers, a table with the offset of
  ///   each column and the columns as lists of posts. The posts are painted with the
  ///   rules of the engine for a texture made of a single patch (IImagingColumnPainter), so
  ///   a pixel is as the engine would have it, and the opaque ones are marked
  /// </summary>
  TImagingPatchReader = class(TInterfacedObject, IImagingPatchReader)
  private
    FPainter: IImagingColumnPainter;
  public
    constructor Create(const APainter: IImagingColumnPainter);
    function Read(const ALump: TBytes): TImagingPatchImage;
  end;

implementation

{ TImagingPatchReader }

constructor TImagingPatchReader.Create(const APainter: IImagingColumnPainter);
begin
  inherited Create;
  FPainter := APainter;
end;

function TImagingPatchReader.Read(const ALump: TBytes): TImagingPatchImage;
var
  LHeader: TImagingPatchHeader;
  LColumn: Integer;
  LOffset: Integer;
  LRow: Integer;
  LPixels: TBytes;
  LMarks: TBytes;
begin
  if Length(ALump) < SizeOf(TImagingPatchHeader) then
    raise EImagingException.Create(SImagingPatchTruncated);
  Move(ALump[0], LHeader, SizeOf(LHeader));
  if (LHeader.Width < 0) or (LHeader.Height < 0) then
    raise EImagingException.Create(SImagingPatchBadSize);
  if SizeOf(TImagingPatchHeader) + LHeader.Width * SizeOf(Integer) > Length(ALump) then
    raise EImagingException.Create(SImagingPatchTruncated);

  Result.Width := LHeader.Width;
  Result.Height := LHeader.Height;
  Result.LeftOffset := LHeader.LeftOffset;
  Result.TopOffset := LHeader.TopOffset;
  SetLength(Result.Pixels, Result.Width * Result.Height);
  SetLength(Result.Opaque, Result.Width * Result.Height);
  if Length(Result.Pixels) = 0 then
    Exit;
  // every cell is written below, but SetLength does not clear them: a patch is made of its posts
  FillChar(Result.Pixels[0], Length(Result.Pixels), 0);
  FillChar(Result.Opaque[0], Length(Result.Opaque), 0);

  // each column is painted alone, then it goes to its place in the rows
  SetLength(LPixels, Result.Height);
  SetLength(LMarks, Result.Height);
  for LColumn := 0 to Result.Width - 1 do
  begin
    Move(ALump[SizeOf(TImagingPatchHeader) + LColumn * SizeOf(Integer)], LOffset, SizeOf(Integer));
    if (LOffset < 0) or (LOffset >= Length(ALump)) then
      raise EImagingException.Create(SImagingPatchBadColumn);
    FillChar(LPixels[0], Result.Height, 0);
    FillChar(LMarks[0], Result.Height, 0);
    FPainter.Paint(ALump, LOffset, LPixels, 0, 0, Result.Height, LMarks, 0);
    for LRow := 0 to Result.Height - 1 do
    begin
      Result.Pixels[LRow * Result.Width + LColumn] := LPixels[LRow];
      Result.Opaque[LRow * Result.Width + LColumn] := LMarks[LRow];
    end;
  end;
end;

end.
