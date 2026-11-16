{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - JPEG encoder                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.JpegEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.EncoderBase,
  DelphiDoom.Jpeg.Client;

type
  /// <summary>
  ///   A baseline JPEG written straight from the pixels of the screen. The old code wrote a TGA
  ///   file and converted it with the JPEG unit of the VCL; the image is the same, the bytes
  ///   are not (another encoder)
  /// </summary>
  TScreenshotJpegEncoder = class(TScreenshotEncoderBase)
  private
    FJpeg: TJpegClient;
    FQuality: Integer;
  protected
    function GetFormat: TScreenshotFormat; override;
    function DoEncode(APixels: Pointer; AWidth, AHeight: Integer;
      ABottomUp: Boolean): TBytes; override;
  public
    /// <param name="AJpeg">The JPEG library; the encoder does not own it</param>
    constructor Create(const AJpeg: TJpegClient; AQuality: Integer = SCREENSHOT_JPEG_QUALITY);
  end;

implementation

uses
  DelphiDoom.Jpeg.Intf;

{ TScreenshotJpegEncoder }

constructor TScreenshotJpegEncoder.Create(const AJpeg: TJpegClient; AQuality: Integer);
begin
  inherited Create;
  if not Assigned(AJpeg) then
    raise EArgumentNilException.Create('AJpeg');
  FJpeg := AJpeg;
  FQuality := AQuality;
end;

function TScreenshotJpegEncoder.GetFormat: TScreenshotFormat;
begin
  Result := TScreenshotFormat.Jpg;
end;

function TScreenshotJpegEncoder.DoEncode(APixels: Pointer; AWidth, AHeight: Integer;
  ABottomUp: Boolean): TBytes;
var
  LRgb: TBytes;
  LSource: PByte;
  LTarget: PByte;
  LRow: Integer;
  LColumn: Integer;
  LSourceRow: Integer;
begin
  // the encoder wants three bytes per pixel, from the top row down
  SetLength(LRgb, AWidth * AHeight * 3);
  LTarget := @LRgb[0];
  for LRow := 0 to AHeight - 1 do
  begin
    if ABottomUp then
      LSourceRow := AHeight - 1 - LRow
    else
      LSourceRow := LRow;
    LSource := PByte(APixels) + LSourceRow * AWidth * 4;
    for LColumn := 0 to AWidth - 1 do
    begin
      LTarget[0] := LSource[0];
      LTarget[1] := LSource[1];
      LTarget[2] := LSource[2];
      Inc(LTarget, 3);
      Inc(LSource, 4);
    end;
  end;

  try
    Result := FJpeg.Encode(LRgb, AWidth, AHeight, 3, FQuality);
  except
    on E: EJpegException do
      raise EScreenshotException.Create(E.Message);
  end;
end;

end.
