{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - TGA files        }
{                                                                              }
{  Port of LoadTGA of renderer\tr_image.c. Based on the Quake III Arena GPL    }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Image.TgaReader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Q3Render.Types;

type
  /// <summary>
  ///   LoadTGA: types 2 (RGB), 3 (gray) and 10 (RLE RGB), 24 and 32 bit (8 bit for type 3), no colour maps. The file
  ///   goes into the buffer with its first row as the last row of the buffer, whatever bit 5 of the descriptor says
  ///   (the C only warns "declares top-down image, ignoring"; the warning goes to the log)
  /// </summary>
  /// <remarks>
  ///   Kept from the C: type 3 works with any pixel size that has a case (8, 24, 32); a run of an RLE packet
  ///   may span rows; a run that ends past the last row stops the image; the pixels never written stay zero (the C
  ///   buffer comes from ri.Malloc, uninitialised: here zero). Differences: a file that ends before the image is an
  ///   EQ3RenderException (the C reads past the buffer); the header width and height are signed 16 bit numbers
  ///   in the C: a negative or an oversized one (above Q3_RENDER_MAX_IMAGE_SIDE) is an EQ3RenderException
  /// </remarks>
  TQ3TgaReader = class sealed
  strict private
    FLog: ILog;
  public
    constructor Create(const ALog: ILog = nil);
    /// <summary>The name is only used in the messages</summary>
    function Read(const AName: AnsiString; const AData: TBytes): TQ3RenderImage;
  end;

implementation

type
  TByteCursor = record
    Data: TBytes;
    Position: Integer;
    Name: string;
    function Next: Byte;
    function NextShort: SmallInt;
  end;

function TByteCursor.Next: Byte;
begin
  if Position >= Length(Data) then
    raise EQ3RenderException.CreateFmt(SQ3RenderTruncated, [Name]);
  Result := Data[Position];
  Inc(Position);
end;

function TByteCursor.NextShort: SmallInt;
var
  LLow, LHigh: Byte;
begin
  LLow := Next;
  LHigh := Next;
  Result := SmallInt(Word(LLow) or (Word(LHigh) shl 8));
end;

{ TQ3TgaReader }

constructor TQ3TgaReader.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

function TQ3TgaReader.Read(const AName: AnsiString; const AData: TBytes): TQ3RenderImage;
var
  LCursor: TByteCursor;
  LIdLength, LColormapType, LImageType, LPixelSize, LAttributes: Byte;
  LWidth, LHeight, LRow, LColumn: Integer;
  LRed, LGreen, LBlue, LAlpha, LPacketHeader: Byte;
  LPacketSize, LIndex: Integer;
  LDone: Boolean;

  procedure ReadPixel(AAllowGray: Boolean);
  begin
    case LPixelSize of
      8:
        if AAllowGray then
        begin
          LBlue := LCursor.Next;
          LGreen := LBlue;
          LRed := LBlue;
          LAlpha := 255;
        end
        else
          raise EQ3RenderException.CreateFmt('LoadTGA: illegal pixel_size ''%d'' in file ''%s''',
            [LPixelSize, string(AName)]);
      24:
        begin
          LBlue := LCursor.Next;
          LGreen := LCursor.Next;
          LRed := LCursor.Next;
          LAlpha := 255;
        end;
      32:
        begin
          LBlue := LCursor.Next;
          LGreen := LCursor.Next;
          LRed := LCursor.Next;
          LAlpha := LCursor.Next;
        end;
    else
      raise EQ3RenderException.CreateFmt('LoadTGA: illegal pixel_size ''%d'' in file ''%s''',
        [LPixelSize, string(AName)]);
    end;
  end;

  procedure PutPixel(ARowIndex, AColumnIndex: Integer);
  var
    LOffset: Integer;
  begin
    LOffset := (ARowIndex * LWidth + AColumnIndex) * 4;
    Result.Pixels[LOffset] := LRed;
    Result.Pixels[LOffset + 1] := LGreen;
    Result.Pixels[LOffset + 2] := LBlue;
    Result.Pixels[LOffset + 3] := LAlpha;
  end;

begin
  Result := Default(TQ3RenderImage);
  LCursor.Data := AData;
  LCursor.Position := 0;
  LCursor.Name := string(AName);
  LIdLength := LCursor.Next;
  LColormapType := LCursor.Next;
  LImageType := LCursor.Next;
  // colormap_index, colormap_length, colormap_size, x_origin, y_origin: read and ignored as in the C
  LCursor.NextShort;
  LCursor.NextShort;
  LCursor.Next;
  LCursor.NextShort;
  LCursor.NextShort;
  LWidth := LCursor.NextShort;
  LHeight := LCursor.NextShort;
  LPixelSize := LCursor.Next;
  LAttributes := LCursor.Next;

  if (LImageType <> 2) and (LImageType <> 10) and (LImageType <> 3) then
    raise EQ3RenderException.Create('LoadTGA: Only type 2 (RGB), 3 (gray), and 10 (RGB) TGA images supported');
  if LColormapType <> 0 then
    raise EQ3RenderException.Create('LoadTGA: colormaps not supported');
  if ((LPixelSize <> 32) and (LPixelSize <> 24)) and (LImageType <> 3) then
    raise EQ3RenderException.Create('LoadTGA: Only 32 or 24 bit images supported (no colormaps)');
  if (LWidth < 0) or (LHeight < 0) or (LWidth > Q3_RENDER_MAX_IMAGE_SIDE) or (LHeight > Q3_RENDER_MAX_IMAGE_SIDE) then
    raise EQ3RenderException.CreateFmt(SQ3RenderBadImageSize, [string(AName), LWidth, LHeight]);

  Result.Width := LWidth;
  Result.Height := LHeight;
  SetLength(Result.Pixels, LWidth * LHeight * 4);

  // skip the TARGA image comment
  Inc(LCursor.Position, LIdLength);

  if (LImageType = 2) or (LImageType = 3) then
  begin
    // uncompressed RGB or gray scale image
    for LRow := LHeight - 1 downto 0 do
      for LColumn := 0 to LWidth - 1 do
      begin
        ReadPixel(True);
        PutPixel(LRow, LColumn);
      end;
  end
  else
  begin
    // run length encoded RGB images
    LRed := 0;
    LGreen := 0;
    LBlue := 0;
    LAlpha := $FF;
    LRow := LHeight - 1;
    LDone := False;
    while (LRow >= 0) and not LDone do
    begin
      LColumn := 0;
      while (LColumn < LWidth) and not LDone do
      begin
        LPacketHeader := LCursor.Next;
        LPacketSize := 1 + (LPacketHeader and $7F);
        if (LPacketHeader and $80) <> 0 then
        begin
          // run-length packet
          ReadPixel(False);
          for LIndex := 0 to LPacketSize - 1 do
          begin
            PutPixel(LRow, LColumn);
            Inc(LColumn);
            if LColumn = LWidth then
            begin
              // run spans across rows
              LColumn := 0;
              if LRow > 0 then
                Dec(LRow)
              else
              begin
                LDone := True;
                Break;
              end;
            end;
          end;
        end
        else
          // non run-length packet
          for LIndex := 0 to LPacketSize - 1 do
          begin
            ReadPixel(False);
            PutPixel(LRow, LColumn);
            Inc(LColumn);
            if LColumn = LWidth then
            begin
              LColumn := 0;
              if LRow > 0 then
                Dec(LRow)
              else
              begin
                LDone := True;
                Break;
              end;
            end;
          end;
      end;
      // the row loop of the C goes on with row - 1 (after a goto breakOut it ends the image, as LDone does)
      if not LDone then
        Dec(LRow);
    end;
  end;
  if ((LAttributes and $20) <> 0) and Assigned(FLog) then
    FLog.Warning(Format('WARNING: ''%s'' TGA file header declares top-down image, ignoring', [string(AName)]));
end;

end.
