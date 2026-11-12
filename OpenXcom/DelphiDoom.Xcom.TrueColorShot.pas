{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - a frame of colors saved as a PNG file (the screenshots  }
{  of the true color path, issue 183)                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.TrueColorShot;

interface

uses
  System.SysUtils, DelphiDoom.Png.Client, DelphiDoom.Platform.Intf, DelphiDoom.XcomEngine.TrueColor.Intf;

type
  /// <summary>
  ///   Writes a frame of colors ($FFRRGGBB per pixel) as an 8 bit RGB PNG: the encoder of Libs\Png makes the bytes
  ///   and the file store of the platform library writes them
  /// </summary>
  TXcomTrueColorShot = class
  strict private
    FPng: TPngClient;
    FFiles: IFileStore;
  public
    /// <param name="APng">The PNG encoder; not owned</param>
    constructor Create(APng: TPngClient; const AFiles: IFileStore);
    /// <summary>EXcomException when the file cannot be written</summary>
    procedure Save(const AFileName: string; const APixels: TXcomTrueColorPixels; AWidth, AHeight: Integer);
  end;

implementation

uses
  DelphiDoom.Png.Intf, DelphiDoom.Xcom.Types;

constructor TXcomTrueColorShot.Create(APng: TPngClient; const AFiles: IFileStore);
begin
  inherited Create;
  if not Assigned(APng) then
    raise EArgumentNilException.Create('APng');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FPng := APng;
  FFiles := AFiles;
end;

procedure TXcomTrueColorShot.Save(const AFileName: string; const APixels: TXcomTrueColorPixels; AWidth,
  AHeight: Integer);
var
  LBytes: TBytes;
begin
  if (AWidth <= 0) or (AHeight <= 0) or (Length(APixels) < AWidth * AHeight) then
    raise EArgumentException.Create('TXcomTrueColorShot: no frame to save');
  // blue, green, red and a byte that is not written
  LBytes := FPng.Encode(Pointer(@APixels[0]), AWidth, AHeight, DDPNG_FORMAT_BGRX);
  if not FFiles.Write(AFileName, @LBytes[0], Length(LBytes)) then
    raise EXcomException.CreateFmt(SXcomFileNotWritten, [AFileName]);
end;

end.
