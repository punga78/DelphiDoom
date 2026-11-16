{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - PNG encoder                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.PngEncoder;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.EncoderBase,
  DelphiDoom.Png.Client;

type
  /// <summary>
  ///   M_DoScreenShotPNG: the pixels are written as a PNG of 8 bit RGB (the fourth byte is
  ///   ignored); with ABottomUp the last row goes first
  /// </summary>
  TScreenshotPngEncoder = class(TScreenshotEncoderBase)
  private
    FPng: TPngClient;
  protected
    function GetFormat: TScreenshotFormat; override;
    function DoEncode(APixels: Pointer; AWidth, AHeight: Integer;
      ABottomUp: Boolean): TBytes; override;
  public
    /// <param name="APng">The PNG library; the encoder does not own it</param>
    constructor Create(const APng: TPngClient);
  end;

implementation

uses
  DelphiDoom.Png.Intf;

{ TScreenshotPngEncoder }

constructor TScreenshotPngEncoder.Create(const APng: TPngClient);
begin
  inherited Create;
  if not Assigned(APng) then
    raise EArgumentNilException.Create('APng');
  FPng := APng;
end;

function TScreenshotPngEncoder.GetFormat: TScreenshotFormat;
begin
  Result := TScreenshotFormat.Png;
end;

function TScreenshotPngEncoder.DoEncode(APixels: Pointer; AWidth, AHeight: Integer;
  ABottomUp: Boolean): TBytes;
var
  LRowSize: Integer;
  LFlipped: TBytes;
  LRow: Integer;
begin
  LRowSize := AWidth * 4;
  try
    if ABottomUp then
    begin
      SetLength(LFlipped, LRowSize * AHeight);
      for LRow := 0 to AHeight - 1 do
        Move(PByte(APixels)[(AHeight - 1 - LRow) * LRowSize], LFlipped[LRow * LRowSize],
          LRowSize);
      Result := FPng.Encode(LFlipped, AWidth, AHeight, DDPNG_FORMAT_BGRX);
    end
    else
      Result := FPng.Encode(APixels, AWidth, AHeight, DDPNG_FORMAT_BGRX);
  except
    on E: EPngException do
      raise EScreenshotException.Create(E.Message);
  end;
end;

end.
