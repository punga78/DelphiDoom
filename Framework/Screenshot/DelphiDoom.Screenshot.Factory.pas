{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - the factory: the composition root          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.Factory;

interface

uses
  DelphiDoom.Png.Client, DelphiDoom.Jpeg.Client, DelphiDoom.Screenshot.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TScreenshotFactory = class sealed
  public
    class function CreateTgaEncoder: IScreenshotEncoder; static;
    /// <param name="APng">The PNG library (not owned)</param>
    class function CreatePngEncoder(const APng: TPngClient): IScreenshotEncoder; static;
    /// <param name="AJpeg">The JPEG library (not owned)</param>
    class function CreateJpegEncoder(const AJpeg: TJpegClient): IScreenshotEncoder; static;
    class function CreateFileSink: IScreenshotFileSink; static;
    /// <summary>A writer with the encoders of the three formats, writing on disk</summary>
    class function CreateWriter(const APng: TPngClient;
      const AJpeg: TJpegClient): IScreenshotWriter; static;
    class function CreateTargets(const AFolders: IScreenshotFolders): IScreenshotTargets; static;
  end;

implementation

uses
  DelphiDoom.Screenshot.TgaEncoder, DelphiDoom.Screenshot.PngEncoder,
  DelphiDoom.Screenshot.JpegEncoder, DelphiDoom.Screenshot.FileSink,
  DelphiDoom.Screenshot.Writer, DelphiDoom.Screenshot.Targets;

{ TScreenshotFactory }

class function TScreenshotFactory.CreateTgaEncoder: IScreenshotEncoder;
begin
  Result := TScreenshotTgaEncoder.Create;
end;

class function TScreenshotFactory.CreatePngEncoder(const APng: TPngClient): IScreenshotEncoder;
begin
  Result := TScreenshotPngEncoder.Create(APng);
end;

class function TScreenshotFactory.CreateJpegEncoder(const AJpeg: TJpegClient): IScreenshotEncoder;
begin
  Result := TScreenshotJpegEncoder.Create(AJpeg);
end;

class function TScreenshotFactory.CreateFileSink: IScreenshotFileSink;
begin
  Result := TScreenshotFileSink.Create;
end;

class function TScreenshotFactory.CreateWriter(const APng: TPngClient;
  const AJpeg: TJpegClient): IScreenshotWriter;
begin
  Result := TScreenshotWriter.Create(
    TArray<IScreenshotEncoder>.Create(CreateTgaEncoder, CreatePngEncoder(APng),
      CreateJpegEncoder(AJpeg)),
    CreateFileSink);
end;

class function TScreenshotFactory.CreateTargets(
  const AFolders: IScreenshotFolders): IScreenshotTargets;
begin
  Result := TScreenshotTargets.Create(AFolders);
end;

end.
