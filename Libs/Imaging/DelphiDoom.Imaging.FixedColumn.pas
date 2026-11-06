{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - columns of a fixed height (tutti frutti fix)  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.FixedColumn;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   The two ways that r_patch.pas (R_GetFixedColumn) has to give the renderer a column that
  ///   does not wrap: the column repeated to 128 pixels, and the posts laid out in a column
  ///   of the height of the texture. The cache of columns stays in the engine
  /// </summary>
  /// <remarks>
  ///   The pixels where no post writes are 0; the old code left there what the memory had
  /// </remarks>
  TImagingFixedColumnBuilder = class(TInterfacedObject, IImagingFixedColumnBuilder)
  public
    function Repeat128(const ASource: TBytes; ASourceOffset, AHeight: Integer): TBytes;
    function FromPosts(const AColumn: TBytes; AColumnOffset, AHeight: Integer): TBytes;
  end;

implementation

const
  REPEATED_HEIGHT = 128;

{ TImagingFixedColumnBuilder }

function TImagingFixedColumnBuilder.Repeat128(const ASource: TBytes; ASourceOffset,
  AHeight: Integer): TBytes;
var
  LIndex: Integer;
begin
  if (AHeight < 1) or (AHeight > REPEATED_HEIGHT) then
    raise EImagingException.Create(SImagingBadHeight);
  if (ASourceOffset < 0) or (ASourceOffset + AHeight > Length(ASource)) then
    raise EImagingException.Create(SImagingPostTruncated);

  SetLength(Result, REPEATED_HEIGHT);
  Move(ASource[ASourceOffset], Result[0], AHeight);
  for LIndex := AHeight to REPEATED_HEIGHT - 1 do
    Result[LIndex] := Result[LIndex - AHeight];
end;

function TImagingFixedColumnBuilder.FromPosts(const AColumn: TBytes; AColumnOffset,
  AHeight: Integer): TBytes;
var
  LOffset: Integer;
  LDelta: Integer;
  LPrevious: Integer;
  LTall: Boolean;
  LLength: Integer;
  LIndex: Integer;
  LPosition: Integer;
begin
  if AHeight < 0 then
    raise EImagingException.Create(SImagingBadHeight);
  SetLength(Result, AHeight);
  // SetLength does not clear the new bytes
  if AHeight > 0 then
    FillChar(Result[0], AHeight, 0);
  LOffset := AColumnOffset;
  LDelta := 0;
  LTall := False;
  while True do
  begin
    if (LOffset < 0) or (LOffset >= Length(AColumn)) then
      raise EImagingException.Create(SImagingColumnWithoutEnd);
    if AColumn[LOffset] = IMAGING_POST_END then
      Break;
    if LOffset + 1 >= Length(AColumn) then
      raise EImagingException.Create(SImagingPostTruncated);
    LLength := AColumn[LOffset + 1];
    if LOffset + 3 + LLength > Length(AColumn) then
      raise EImagingException.Create(SImagingPostTruncated);

    LDelta := LDelta + AColumn[LOffset];
    for LIndex := 0 to LLength - 1 do
    begin
      LPosition := LDelta + LIndex;
      if (LPosition >= 0) and (LPosition < AHeight) then
        Result[LPosition] := AColumn[LOffset + 3 + LIndex];
    end;

    if not LTall then
    begin
      LPrevious := AColumn[LOffset];
      LOffset := LOffset + LLength + 4;
      // the offsets are absolute while they grow; when one does not, the column is a tall one
      // and from then on they add up
      if (LOffset >= 0) and (LOffset < Length(AColumn)) and (AColumn[LOffset] > LPrevious) then
        LDelta := 0
      else
        LTall := True;
    end
    else
      LOffset := LOffset + LLength + 4;
  end;
end;

end.
