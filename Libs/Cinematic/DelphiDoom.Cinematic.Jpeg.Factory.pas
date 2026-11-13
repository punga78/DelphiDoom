{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - where the JPEG decoder of RoQ is made       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Jpeg.Factory;

interface

uses
  DelphiDoom.Cinematic.Jpeg.Intf;

type
  /// <summary>
  ///   The only place that knows <c>TRoqJpegDecoder</c>; apart from <c>TCinematicFactory</c> so that a
  ///   program that does not play RoQ files with JPEG frames does not link <c>Libs\Jpeg</c>
  /// </summary>
  TRoqJpegFactory = class
  public
    class function CreateDecoder: IRoqJpegDecoder; static;
  end;

implementation

uses
  DelphiDoom.Cinematic.Jpeg.Decoder;

{ TRoqJpegFactory }

class function TRoqJpegFactory.CreateDecoder: IRoqJpegDecoder;
begin
  Result := TRoqJpegDecoder.Create;
end;

end.
