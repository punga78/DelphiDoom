{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - JPEG files       }
{                                                                              }
{  Port of LoadJPG of renderer\tr_image.c (the decoding is Framework\Jpeg).    }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Image.JpegReader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Q3Render.Types;

type
  /// <summary>
  ///   LoadJPG: the jpeg-6 of Quake III (JDCT_FLOAT is its default, plain libjpeg upsampling with the triangle
  ///   filter, red-green-blue) into RGBA with alpha 255 ("clear all the alphas to 255")
  /// </summary>
  /// <remarks>
  ///   Differences from the C: a grayscale JPEG leaves the C with 1 byte per pixel in a buffer that the alpha loop
  ///   then writes as 4 (a heap overflow); here the gray goes to R = G = B. A stream that is damaged or ends too
  ///   soon is a False (the C error handler calls exit)
  /// </remarks>
  TQ3JpegReader = class sealed
  strict private
    FLog: ILog;
  public
    constructor Create(const ALog: ILog = nil);
    function Read(const AName: AnsiString; const AData: TBytes; out AImage: TQ3RenderImage): Boolean;
  end;

implementation

uses
  DelphiDoom.Jpeg.Intf, DelphiDoom.Jpeg.Types, DelphiDoom.Jpeg.Decoder;

constructor TQ3JpegReader.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

function TQ3JpegReader.Read(const AName: AnsiString; const AData: TBytes; out AImage: TQ3RenderImage): Boolean;
var
  LInfo: TJpegInfo;
  LOptions: TJpegDecodeOptions;
  LCode, LCount, LIndex: Integer;
  LPlain: TBytes;
begin
  AImage := Default(TQ3RenderImage);
  Result := False;
  if Length(AData) = 0 then
    Exit;
  LOptions := TJpegDecodeOptions.Default;
  LOptions.FastInverseDct := True;
  LOptions.RgbOrder := True;
  LCode := TJpegDecoder.ReadInfo(@AData[0], Length(AData), LInfo);
  if (LCode <> DDJPEG_OK) or (LInfo.Width <= 0) or (LInfo.Height <= 0) or (LInfo.Width > Q3_RENDER_MAX_IMAGE_SIDE) or
    (LInfo.Height > Q3_RENDER_MAX_IMAGE_SIDE) or not (LInfo.Components in [1, 3]) then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('LoadJPG: %s is not a JPEG that can be read (%d)', [string(AName), LCode]));
    Exit;
  end;
  SetLength(LPlain, LInfo.Width * LInfo.Height * LInfo.Components);
  LCode := TJpegDecoder.Decode(@AData[0], Length(AData), @LPlain[0], Length(LPlain), LInfo, LOptions);
  if LCode <> DDJPEG_OK then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('LoadJPG: %s could not be decoded (%d)', [string(AName), LCode]));
    Exit;
  end;
  AImage.Width := LInfo.Width;
  AImage.Height := LInfo.Height;
  LCount := LInfo.Width * LInfo.Height;
  SetLength(AImage.Pixels, LCount * 4);
  for LIndex := 0 to LCount - 1 do
  begin
    if LInfo.Components = 3 then
    begin
      AImage.Pixels[LIndex * 4] := LPlain[LIndex * 3];
      AImage.Pixels[LIndex * 4 + 1] := LPlain[LIndex * 3 + 1];
      AImage.Pixels[LIndex * 4 + 2] := LPlain[LIndex * 3 + 2];
    end
    else
    begin
      AImage.Pixels[LIndex * 4] := LPlain[LIndex];
      AImage.Pixels[LIndex * 4 + 1] := LPlain[LIndex];
      AImage.Pixels[LIndex * 4 + 2] := LPlain[LIndex];
    end;
    AImage.Pixels[LIndex * 4 + 3] := 255;
  end;
  Result := True;
end;

end.
