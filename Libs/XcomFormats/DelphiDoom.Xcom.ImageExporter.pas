{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - an image saved in a file                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.ImageExporter;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf, DelphiDoom.Platform.Intf;

type
  /// <summary>The encoder makes the bytes of the file and the file store of the platform library writes them</summary>
  TXcomImageExporter = class
  strict private
    FEncoder: IXcomImageEncoder;
    FFiles: IFileStore;
  public
    constructor Create(const AEncoder: IXcomImageEncoder; const AFiles: IFileStore);
    /// <summary>Saves the image as AFileName; EXcomException if the file cannot be written</summary>
    procedure Save(const AImage: TXcomImage; const AFileName: string; ATransparentZero: Boolean);
  end;

implementation

{ TXcomImageExporter }

constructor TXcomImageExporter.Create(const AEncoder: IXcomImageEncoder; const AFiles: IFileStore);
begin
  inherited Create;
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FEncoder := AEncoder;
  FFiles := AFiles;
end;

procedure TXcomImageExporter.Save(const AImage: TXcomImage; const AFileName: string; ATransparentZero: Boolean);
var
  LBytes: TBytes;
begin
  LBytes := FEncoder.Encode(AImage, ATransparentZero);
  if not FFiles.Write(AFileName, @LBytes[0], Length(LBytes)) then
    raise EXcomException.CreateFmt(SXcomFileNotWritten, [AFileName]);
end;

end.
