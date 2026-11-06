{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - paints a column of posts into a column        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ColumnPainter;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   R_DrawColumnInCache and R_DrawColumnInCacheMultipatch of r_data.pas on arrays of bytes.
  ///   The data are checked: a column that does not end, or a post that goes past the end of
  ///   the bytes, is an EImagingException (the old code read whatever came next in memory)
  /// </summary>
  /// <remarks>
  ///   Kept as in the old code: when a post starts above the top of the cache, the pixels that
  ///   are copied are the first ones of the post, not the ones that are inside (the old code
  ///   moved the destination and not the source). The old "tall patch" flag did not change
  ///   what was painted, so it is not here
  /// </remarks>
  TImagingColumnPainter = class(TInterfacedObject, IImagingColumnPainter)
  public
    procedure Paint(const ASource: TBytes; ASourceOffset: Integer; var ACache: TBytes;
      ACacheOffset, AOriginY, ACacheHeight: Integer; const AMarks: TBytes;
      AMarksOffset: Integer);
  end;

implementation

{ TImagingColumnPainter }

procedure TImagingColumnPainter.Paint(const ASource: TBytes; ASourceOffset: Integer;
  var ACache: TBytes; ACacheOffset, AOriginY, ACacheHeight: Integer; const AMarks: TBytes;
  AMarksOffset: Integer);
var
  LOffset: Integer;
  LCount: Integer;
  LLength: Integer;
  LPosition: Integer;
begin
  if (ACacheHeight < 0) or (ACacheOffset < 0) or (ACacheOffset + ACacheHeight > Length(ACache)) then
    raise EImagingException.Create(SImagingCacheTooSmall);
  if (Length(AMarks) > 0) and ((AMarksOffset < 0) or (AMarksOffset + ACacheHeight > Length(AMarks))) then
    raise EImagingException.Create(SImagingMarksTooSmall);

  LOffset := ASourceOffset;
  while True do
  begin
    if (LOffset < 0) or (LOffset >= Length(ASource)) then
      raise EImagingException.Create(SImagingColumnWithoutEnd);
    if ASource[LOffset] = IMAGING_POST_END then
      Break;
    if LOffset + 2 >= Length(ASource) then
      raise EImagingException.Create(SImagingPostTruncated);
    LLength := ASource[LOffset + 1];
    if LOffset + 3 + LLength > Length(ASource) then
      raise EImagingException.Create(SImagingPostTruncated);

    LCount := LLength;
    LPosition := AOriginY + ASource[LOffset];
    if LPosition < 0 then
    begin
      LCount := LCount + LPosition;
      LPosition := 0;
    end;
    if LPosition + LCount > ACacheHeight then
      LCount := ACacheHeight - LPosition;

    if LCount > 0 then
    begin
      Move(ASource[LOffset + 3], ACache[ACacheOffset + LPosition], LCount);
      if Length(AMarks) > 0 then
        FillChar(AMarks[AMarksOffset + LPosition], LCount, $FF);
    end;

    LOffset := LOffset + LLength + 4;
  end;
end;

end.
