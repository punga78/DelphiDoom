{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the JPEG decoder of Libs\Jpeg for RoQ       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Jpeg.Decoder;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Jpeg.Intf;

type
  /// <summary>
  ///   <c>IRoqJpegDecoder</c> on <c>TJpegDecoder</c> of <c>Libs\Jpeg</c> (libjpeg 6b). The settings are
  ///   those of the library, not the ones of Doom 3 (<c>JDCT_FASTEST</c>, no fancy upsampling): the
  ///   pixels can differ from Doom 3 by a few levels. A gray image (one component) becomes RGB with
  ///   three equal bytes
  /// </summary>
  TRoqJpegDecoder = class(TInterfacedObject, IRoqJpegDecoder)
  public
    function Decode(const AData: TBytes; out AWidth, AHeight: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Decoder;

resourcestring
  SJpegEmpty = 'The JPEG chunk is empty';
  SJpegInvalid = 'The JPEG chunk cannot be decoded (code %d)';
  SJpegComponents = 'The JPEG chunk has %d color components';

{ TRoqJpegDecoder }

function TRoqJpegDecoder.Decode(const AData: TBytes; out AWidth, AHeight: Integer): TBytes;
var
  LInfo: TJpegInfo;
  LCode: Integer;
  LRaw: TBytes;
  LIndex: Integer;
begin
  AWidth := 0;
  AHeight := 0;
  Result := nil;
  if Length(AData) = 0 then
    raise ERoqInvalidDataException.Create(SJpegEmpty);
  LCode := TJpegDecoder.ReadInfo(@AData[0], Length(AData), LInfo);
  if LCode <> DDJPEG_OK then
    raise ERoqInvalidDataException.CreateFmt(SJpegInvalid, [LCode]);
  if (LInfo.Components <> 1) and (LInfo.Components <> 3) then
    raise ERoqInvalidDataException.CreateFmt(SJpegComponents, [LInfo.Components]);
  SetLength(LRaw, LInfo.Width * LInfo.Height * LInfo.Components);
  LCode := TJpegDecoder.Decode(@AData[0], Length(AData), @LRaw[0], Length(LRaw), LInfo);
  if LCode <> DDJPEG_OK then
    raise ERoqInvalidDataException.CreateFmt(SJpegInvalid, [LCode]);
  AWidth := LInfo.Width;
  AHeight := LInfo.Height;
  if LInfo.Components = 3 then
    Result := LRaw
  else
  begin
    SetLength(Result, Length(LRaw) * 3);
    for LIndex := 0 to High(LRaw) do
    begin
      Result[LIndex * 3] := LRaw[LIndex];
      Result[LIndex * 3 + 1] := LRaw[LIndex];
      Result[LIndex * 3 + 2] := LRaw[LIndex];
    end;
  end;
end;

end.
