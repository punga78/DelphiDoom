{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - FLIC animations: the decoder (issue #199)   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  The chunks (COLOR_256, COLOR_64, DELTA_FLC, DELTA_FLI, BYTE_RUN, LITERAL,   }
{  BLACK) are decoded by TXcomFlcDecoder (Libs\XcomFormats), a port of         }
{  FlcPlayer of OpenXcom (GPL v3 or later); this unit is the contract on top   }
{  of it: validation of the file, ring frame, delays, 32 bit pixels. The       }
{  remake of Warcraft (acoto87/war1, zlib) has no FLIC code.                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Decoder;

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Xcom.Types,
  DelphiDoom.Xcom.FlcDecoder,
  DelphiDoom.Cinematic.Flic.Types,
  DelphiDoom.Cinematic.Flic.Intf;

type
  /// <summary>
  ///   Decodes a FLI/FLC file held in memory. The whole file is checked when the object is
  ///   made (header, size of the picture, every frame inside the file, at least one frame), so
  ///   NextFrame cannot loop for ever on a frame of size 0. The last frame of a FLC is the
  ///   "ring frame" (the way back to the first one): it is not given unless asked for
  /// </summary>
  /// <remarks>
  ///   Inherited from the decoder of OpenXcom and not exercised by the files of Warcraft: a
  ///   COLOR_256 chunk with several packets adds the count of the packet before to the skip
  ///   of the next (the format says to add the start and the count), and BLACK clears
  ///   "height" pixels of every row, not "width"
  /// </remarks>
  TFlicDecoder = class(TInterfacedObject, IFlicDecoder)
  strict private
    FBytes: TBytes;
    FIncludeRingFrame: Boolean;
    FCore: TXcomFlcDecoder;
    FWidth: Integer;
    FHeight: Integer;
    FHeaderFrames: Integer;
    FFramesFound: Integer;
    FFrameCount: Integer;
    FFrameIndex: Integer;
    FFrameDelay: Integer;
    FPicture: TBytes;
    FPalette: TFlicPalette;
    FPaletteDirty: Boolean;
    procedure OpenCore;
    procedure ScanFrames;
    procedure PaletteChanged(AFirst, ACount: Integer);
    procedure RefreshPalette;
    procedure ClearPalette;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetHeaderFrames: Integer;
    function GetFrameCount: Integer;
    function GetFrameIndex: Integer;
    function GetFrameDelay: Integer;
    function GetIsFli: Boolean;
    function GetIndices: TBytes;
    function GetPalette: TFlicPalette;
    function GetFrame: TImagingPixels;
  public
    /// <summary>EFlicInvalidDataException if the bytes are not a usable FLI/FLC</summary>
    constructor Create(const ABytes: TBytes; AIncludeRingFrame: Boolean = False);
    destructor Destroy; override;
    function NextFrame: Boolean;
    procedure Reset;
  end;

implementation

uses
  DelphiDoom.Cinematic.Flic.PixelConverter;

const
  SBadFile = 'Not a FLI/FLC animation: %s';
  SNoFrames = 'The FLI/FLC file has no frames';
  SBadSize = 'The FLI/FLC picture is %dx%d pixels';
  SFrameOutside = 'A frame of the FLI/FLC file (offset %d, %d bytes) does not fit in the file';
  SBadChunks = 'The data of a FLI/FLC frame are not valid: %s';
  FRAME_VIDEO = $F1FA;
  FRAME_AUDIO = $AAAA;
  FRAME_PREFIX = $F100;

{ TFlicDecoder }

constructor TFlicDecoder.Create(const ABytes: TBytes; AIncludeRingFrame: Boolean);
begin
  inherited Create;
  FBytes := ABytes;
  FIncludeRingFrame := AIncludeRingFrame;
  OpenCore;
  FWidth := FCore.Width;
  FHeight := FCore.Height;
  FHeaderFrames := FCore.Frames;
  if (FWidth = 0) or (FHeight = 0) or (Int64(FWidth) * FHeight > FLIC_MAX_PIXELS) then
    raise EFlicInvalidDataException.CreateFmt(SBadSize, [FWidth, FHeight]);
  ScanFrames;
  if (not FIncludeRingFrame) and (FHeaderFrames > 0) and (FHeaderFrames < FFramesFound) then
    FFrameCount := FHeaderFrames
  else
    FFrameCount := FFramesFound;
  SetLength(FPicture, FWidth * FHeight);
  ClearPalette;
  FFrameIndex := -1;
end;

destructor TFlicDecoder.Destroy;
begin
  FCore.Free;
  inherited Destroy;
end;

procedure TFlicDecoder.OpenCore;
begin
  FreeAndNil(FCore);
  try
    FCore := TXcomFlcDecoder.Create(FBytes);
  except
    on E: EXcomFlcException do
      raise EFlicInvalidDataException.CreateFmt(SBadFile, [E.Message]);
  end;
  FCore.OnPalette := PaletteChanged;
end;

procedure TFlicDecoder.ScanFrames;
var
  LPosition: Int64;
  LSize: Cardinal;
  LType: Word;
begin
  // the same walk as TXcomFlcDecoder.FindFrame, to count the frames and refuse the sizes that
  // would make it stay where it is
  FFramesFound := 0;
  LPosition := FLIC_HEADER_SIZE;
  while LPosition + 6 <= Length(FBytes) do
  begin
    LSize := FBytes[LPosition] or (Cardinal(FBytes[LPosition + 1]) shl 8) or
      (Cardinal(FBytes[LPosition + 2]) shl 16) or (Cardinal(FBytes[LPosition + 3]) shl 24);
    LType := FBytes[LPosition + 4] or (Word(FBytes[LPosition + 5]) shl 8);
    case LType of
      FRAME_VIDEO, FRAME_PREFIX:
        begin
          if (LSize < FLIC_FRAME_HEADER_SIZE) or (LPosition + LSize > Length(FBytes)) then
            raise EFlicInvalidDataException.CreateFmt(SFrameOutside, [LPosition, LSize]);
          if LType = FRAME_VIDEO then
            Inc(FFramesFound);
          Inc(LPosition, LSize);
        end;
      FRAME_AUDIO:
        Inc(LPosition, Int64(LSize) + FLIC_FRAME_HEADER_SIZE);
    else
      Break;
    end;
  end;
  if FFramesFound = 0 then
    raise EFlicInvalidDataException.Create(SNoFrames);
end;

procedure TFlicDecoder.PaletteChanged(AFirst, ACount: Integer);
begin
  FPaletteDirty := True;
end;

procedure TFlicDecoder.ClearPalette;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FLIC_PALETTE_SIZE - 1 do
    FPalette[LIndex] := TFlicPixelConverter.ColorToPixel(0, 0, 0);
end;

procedure TFlicDecoder.RefreshPalette;
var
  LIndex: Integer;
  LColor: TXcomColor;
begin
  for LIndex := 0 to FLIC_PALETTE_SIZE - 1 do
  begin
    LColor := FCore.Color(LIndex);
    FPalette[LIndex] := TFlicPixelConverter.ColorToPixel(LColor.Red, LColor.Green, LColor.Blue);
  end;
  FPaletteDirty := False;
end;

function TFlicDecoder.NextFrame: Boolean;
var
  LDelay: Cardinal;
begin
  if FFrameIndex + 1 >= FFrameCount then
    Exit(False);
  try
    if not FCore.FindFrame then
      Exit(False);
    LDelay := FCore.FrameDelay(False);
    FCore.DecodeFrame(FPicture, FWidth, 0, False);
  except
    on E: EXcomFlcException do
      raise EFlicInvalidDataException.CreateFmt(SBadChunks, [E.Message]);
  end;
  if LDelay = 0 then
    LDelay := FLIC_DEFAULT_DELAY;
  FFrameDelay := LDelay;
  Inc(FFrameIndex);
  if FPaletteDirty then
    RefreshPalette;
  Result := True;
end;

procedure TFlicDecoder.Reset;
begin
  OpenCore;
  FillChar(FPicture[0], Length(FPicture), 0);
  ClearPalette;
  FPaletteDirty := False;
  FFrameIndex := -1;
  FFrameDelay := 0;
end;

function TFlicDecoder.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TFlicDecoder.GetHeight: Integer;
begin
  Result := FHeight;
end;

function TFlicDecoder.GetHeaderFrames: Integer;
begin
  Result := FHeaderFrames;
end;

function TFlicDecoder.GetFrameCount: Integer;
begin
  Result := FFrameCount;
end;

function TFlicDecoder.GetFrameIndex: Integer;
begin
  Result := FFrameIndex;
end;

function TFlicDecoder.GetFrameDelay: Integer;
begin
  Result := FFrameDelay;
end;

function TFlicDecoder.GetIsFli: Boolean;
begin
  Result := FCore.IsFli;
end;

function TFlicDecoder.GetIndices: TBytes;
begin
  Result := Copy(FPicture);
end;

function TFlicDecoder.GetPalette: TFlicPalette;
begin
  Result := FPalette;
end;

function TFlicDecoder.GetFrame: TImagingPixels;
begin
  Result := TFlicPixelConverter.ToPixels(FPicture, FPalette);
end;

end.
