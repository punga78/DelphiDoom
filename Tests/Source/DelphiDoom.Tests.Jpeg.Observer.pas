{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the JPEG decoder - what an IJpeg answers for a stream  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Observer;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   Asks an IJpeg the same questions for every stream (header, decoding
  ///   into a buffer of the right size, decoding into a buffer that is too
  ///   small) and reduces the answers to one number: the result codes, the
  ///   sizes and, when the decoding works, all the pixels
  /// </summary>
  TJpegObserver = class
  public
    class function Fingerprint(const AJpeg: IJpeg; const AStream: TBytes): UInt64; static;
  end;

implementation

uses
  DelphiDoom.Tests.Jpeg.Digest;

{ TJpegObserver }

class function TJpegObserver.Fingerprint(const AJpeg: IJpeg;
  const AStream: TBytes): UInt64;
var
  LDigest: TJpegDigest;
  LInfo: TJpegInfo;
  LCode: Integer;
  LPixels: TBytes;
  LSmall: array[0..15] of Byte;

  procedure AddInfo;
  begin
    LDigest.AddInt64(LInfo.Width);
    LDigest.AddInt64(LInfo.Height);
    LDigest.AddInt64(LInfo.Components);
  end;

begin
  LDigest := TJpegDigest.Start;

  LCode := AJpeg.GetInfo(Pointer(AStream), Length(AStream), LInfo);
  LDigest.AddInt64(LCode);
  AddInfo;

  // Too small a buffer: the code and the size of the image are still known
  LCode := AJpeg.Decode(Pointer(AStream), Length(AStream), @LSmall[0],
    SizeOf(LSmall), LInfo);
  LDigest.AddInt64(LCode);
  AddInfo;

  if (LInfo.Width > 0) and (LInfo.Height > 0) and (LInfo.Components > 0) then
  begin
    SetLength(LPixels, LInfo.Width * LInfo.Height * LInfo.Components);
    LCode := AJpeg.Decode(Pointer(AStream), Length(AStream), Pointer(LPixels),
      Length(LPixels), LInfo);
    LDigest.AddInt64(LCode);
    AddInfo;
    if LCode = DDJPEG_OK then
      LDigest.AddBuffer(Pointer(LPixels), Length(LPixels));
  end;

  Result := LDigest.Value;
end;

end.
