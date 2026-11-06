{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - rebuilds the posts of a column from marks     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ColumnRebuilder;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   The part of R_GenerateComposite (r_data.pas) that, after the patches of a texture are
  ///   painted, writes the column again as posts: it scans the transparency marks and copies
  ///   the opaque runs. For heights under 255 each run is a post; from 255 on the "tall"
  ///   variant splits the runs in posts of at most 254 pixels
  /// </summary>
  /// <remarks>
  ///   Kept as in the old code, for the tall columns: a run longer than 254 pixels is split in
  ///   posts that all have the same topdelta, and the offsets of a post that starts past 254
  ///   are relative to the start of the previous run. The old code looped forever, writing
  ///   empty posts, when a run starts past 254 and the distance from the previous one is also
  ///   more than 254: here it is an EImagingException. The bytes between the posts (the byte
  ///   after the header and the one after the data) are not written
  /// </remarks>
  TImagingColumnRebuilder = class(TInterfacedObject, IImagingColumnRebuilder)
  private
    const
      MAX_POST_LENGTH = 254;
      MAX_CONVERGENCE_STEPS = 1024;
    procedure CheckPost(const ABlock: TBytes; AColumn, ALength: Integer);
    procedure CheckEnd(const ABlock: TBytes; AColumn: Integer);
    procedure WritePost(var ABlock: TBytes; AColumn, ATopDelta, ALength: Integer;
      const ASource: TBytes; ASourcePosition: Integer);
    procedure RebuildShort(var ABlock: TBytes; AColumnOffset: Integer; const ASource,
      AMarks: TBytes; AMarksOffset, AHeight: Integer);
    procedure RebuildTall(var ABlock: TBytes; AColumnOffset: Integer; const ASource,
      AMarks: TBytes; AMarksOffset, AHeight: Integer);
  public
    procedure Rebuild(var ABlock: TBytes; AColumnOffset: Integer; const AMarks: TBytes;
      AMarksOffset, AHeight: Integer);
  end;

implementation

{ TImagingColumnRebuilder }

procedure TImagingColumnRebuilder.CheckPost(const ABlock: TBytes; AColumn, ALength: Integer);
begin
  if (AColumn < 0) or (AColumn + 3 + ALength > Length(ABlock)) then
    raise EImagingException.Create(SImagingRebuildOverflow);
end;

procedure TImagingColumnRebuilder.CheckEnd(const ABlock: TBytes; AColumn: Integer);
begin
  if (AColumn < 0) or (AColumn >= Length(ABlock)) then
    raise EImagingException.Create(SImagingRebuildOverflow);
end;

procedure TImagingColumnRebuilder.WritePost(var ABlock: TBytes; AColumn, ATopDelta,
  ALength: Integer; const ASource: TBytes; ASourcePosition: Integer);
begin
  CheckPost(ABlock, AColumn, ALength);
  ABlock[AColumn] := Byte(ATopDelta);
  ABlock[AColumn + 1] := Byte(ALength);
  if ALength > 0 then
    Move(ASource[ASourcePosition], ABlock[AColumn + 3], ALength);
end;

procedure TImagingColumnRebuilder.RebuildShort(var ABlock: TBytes; AColumnOffset: Integer;
  const ASource, AMarks: TBytes; AMarksOffset, AHeight: Integer);
var
  LColumn: Integer;
  LRow: Integer;
  LTopDelta: Integer;
begin
  LColumn := AColumnOffset;
  LRow := 0;
  while True do
  begin
    // skip the transparent cells
    while (LRow < AHeight) and (AMarks[AMarksOffset + LRow] = 0) do
      Inc(LRow);
    if LRow >= AHeight then
    begin
      CheckEnd(ABlock, LColumn);
      ABlock[LColumn] := IMAGING_POST_END;
      Break;
    end;
    LTopDelta := LRow;
    while (LRow < AHeight) and (AMarks[AMarksOffset + LRow] <> 0) and
      (LRow - LTopDelta < 255) do
      Inc(LRow);
    WritePost(ABlock, LColumn, LTopDelta, LRow - LTopDelta, ASource, LTopDelta);
    LColumn := LColumn + (LRow - LTopDelta) + 4;
  end;
end;

procedure TImagingColumnRebuilder.RebuildTall(var ABlock: TBytes; AColumnOffset: Integer;
  const ASource, AMarks: TBytes; AMarksOffset, AHeight: Integer);
var
  LColumn: Integer;
  LRow: Integer;
  LLastTopDelta: Integer;
  LTallTopDelta: Integer;
  LTallLength: Integer;
  LRestTopDelta: Integer;
  LSourcePosition: Integer;
  LLength: Integer;
  LSteps: Integer;
begin
  LColumn := AColumnOffset;
  LRow := 0;
  LLastTopDelta := 0;
  while True do
  begin
    while (LRow < AHeight) and (AMarks[AMarksOffset + LRow] = 0) do
      Inc(LRow);
    if LRow >= AHeight then
    begin
      CheckEnd(ABlock, LColumn);
      ABlock[LColumn] := IMAGING_POST_END;
      Break;
    end;

    LTallTopDelta := LRow;
    while (LRow < AHeight) and (AMarks[AMarksOffset + LRow] <> 0) do
      Inc(LRow);
    LTallLength := LRow - LTallTopDelta;

    LSourcePosition := LTallTopDelta;
    repeat
      if LTallTopDelta < 255 then
      begin
        CheckPost(ABlock, LColumn, 0);
        ABlock[LColumn] := Byte(LTallTopDelta);
        LLastTopDelta := LTallTopDelta;
      end
      else
      begin
        LRestTopDelta := LTallTopDelta - LLastTopDelta;
        LSteps := 0;
        repeat
          Inc(LSteps);
          if LSteps > MAX_CONVERGENCE_STEPS then
            raise EImagingException.Create(SImagingRebuildDiverges);
          CheckPost(ABlock, LColumn, 0);
          if LRestTopDelta > MAX_POST_LENGTH then
          begin
            // an empty post that moves the offset: the old code doubled the last one
            ABlock[LColumn] := Byte(LLastTopDelta);
            LLastTopDelta := LLastTopDelta + LLastTopDelta;
            ABlock[LColumn + 1] := 0;
            LColumn := LColumn + 4;
          end
          else
          begin
            ABlock[LColumn] := Byte(LRestTopDelta);
            LLastTopDelta := LTallTopDelta;
          end;
        until LLastTopDelta = LTallTopDelta;
      end;

      if LTallLength > MAX_POST_LENGTH then
      begin
        LLength := MAX_POST_LENGTH;
        LTallLength := LTallLength - MAX_POST_LENGTH;
      end
      else
      begin
        LLength := LTallLength;
        LTallLength := 0;
      end;
      CheckPost(ABlock, LColumn, LLength);
      ABlock[LColumn + 1] := Byte(LLength);
      if LLength > 0 then
        Move(ASource[LSourcePosition], ABlock[LColumn + 3], LLength);
      LSourcePosition := LSourcePosition + LLength;
      LColumn := LColumn + LLength + 4;
    until LTallLength = 0;
  end;
end;

procedure TImagingColumnRebuilder.Rebuild(var ABlock: TBytes; AColumnOffset: Integer;
  const AMarks: TBytes; AMarksOffset, AHeight: Integer);
var
  LSource: TBytes;
begin
  if AHeight <= 0 then
    raise EImagingException.Create(SImagingBadHeight);
  if (AColumnOffset < 0) or (AColumnOffset + 3 + AHeight > Length(ABlock)) then
    raise EImagingException.Create(SImagingRebuildOverflow);
  if (AMarksOffset < 0) or (AMarksOffset + AHeight > Length(AMarks)) then
    raise EImagingException.Create(SImagingMarksTooSmall);

  // the pixels are saved: the posts are written over them
  SetLength(LSource, AHeight);
  Move(ABlock[AColumnOffset + 3], LSource[0], AHeight);

  if AHeight < 255 then
    RebuildShort(ABlock, AColumnOffset, LSource, AMarks, AMarksOffset, AHeight)
  else
    RebuildTall(ABlock, AColumnOffset, LSource, AMarks, AMarksOffset, AHeight);
end;

end.
