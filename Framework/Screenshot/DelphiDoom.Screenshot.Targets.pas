{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - names of the files                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.Targets;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.Intf;

type
  /// <summary>
  ///   The naming rules of M_ScreenShot
  /// </summary>
  /// <remarks>
  ///   Difference from the old code, which is a defect that was fixed: for a name with no folder
  ///   and no extension (or with the extension .png) the folder of the PNG files was put on the
  ///   name of the JPEG file, so the PNG went to the current folder and the JPEG to the folder of
  ///   the PNG files. Every name gets the folder of its own format
  /// </remarks>
  TScreenshotTargets = class(TInterfacedObject, IScreenshotTargets)
  strict private
    FFolders: IScreenshotFolders;
    function WithFolder(const AName: string; AFormat: TScreenshotFormat): string;
    class function ReplaceExtension(const AFileName: string;
      AFormat: TScreenshotFormat): string; static;
  public
    constructor Create(const AFolders: IScreenshotFolders);
    function ForGenerated(const AGameName, AStamp: string;
      AFormat: TScreenshotFormat): TScreenshotTarget;
    function ForFileName(const AFileName: string): TScreenshotTarget;
  end;

implementation

uses
  DelphiDoom.Screenshot.Formats;

{ TScreenshotTargets }

constructor TScreenshotTargets.Create(const AFolders: IScreenshotFolders);
begin
  inherited Create;
  if not Assigned(AFolders) then
    raise EArgumentNilException.Create('AFolders');
  FFolders := AFolders;
end;

function TScreenshotTargets.WithFolder(const AName: string;
  AFormat: TScreenshotFormat): string;
begin
  if (Pos('/', AName) = 0) and (Pos('\', AName) = 0) then
    Result := FFolders.PathOf(TScreenshotFormats.FolderOf(AFormat) + '\' + AName)
  else
    Result := AName;
end;

class function TScreenshotTargets.ReplaceExtension(const AFileName: string;
  AFormat: TScreenshotFormat): string;
begin
  // the old code overwrote the last three characters of the name
  Result := Copy(AFileName, 1, Length(AFileName) - 3) +
    Copy(TScreenshotFormats.ExtensionOf(AFormat), 2, 3);
end;

function TScreenshotTargets.ForGenerated(const AGameName, AStamp: string;
  AFormat: TScreenshotFormat): TScreenshotTarget;
var
  LBaseName: string;
  LFormat: TScreenshotFormat;
  LPaths: array[TScreenshotFormat] of string;
begin
  LBaseName := 'SSHOT_' + AGameName + '_';
  for LFormat := Low(TScreenshotFormat) to High(TScreenshotFormat) do
    LPaths[LFormat] := FFolders.PathOf(TScreenshotFormats.FolderOf(LFormat) + '\' +
      LBaseName) + AStamp + TScreenshotFormats.ExtensionOf(LFormat);
  Result.Format := AFormat;
  Result.TgaPath := LPaths[TScreenshotFormat.Tga];
  Result.JpgPath := LPaths[TScreenshotFormat.Jpg];
  Result.PngPath := LPaths[TScreenshotFormat.Png];
end;

function TScreenshotTargets.ForFileName(const AFileName: string): TScreenshotTarget;
var
  LExtension: string;
begin
  LExtension := UpperCase(ExtractFileExt(AFileName));
  if LExtension = '.TGA' then
    Result.Format := TScreenshotFormat.Tga
  else if LExtension = '.JPG' then
    Result.Format := TScreenshotFormat.Jpg
  else if LExtension = '.PNG' then
    Result.Format := TScreenshotFormat.Png
  else
    Result.Format := TScreenshotFormat.Png;

  if (LExtension = '.TGA') or (LExtension = '.JPG') or (LExtension = '.PNG') then
  begin
    Result.TgaPath := ReplaceExtension(AFileName, TScreenshotFormat.Tga);
    Result.JpgPath := ReplaceExtension(AFileName, TScreenshotFormat.Jpg);
    Result.PngPath := ReplaceExtension(AFileName, TScreenshotFormat.Png);
    // the name that was given keeps its spelling
    case Result.Format of
      TScreenshotFormat.Tga:
        Result.TgaPath := AFileName;
      TScreenshotFormat.Jpg:
        Result.JpgPath := AFileName;
    else
      Result.PngPath := AFileName;
    end;
  end
  else
  begin
    Result.TgaPath := AFileName + '.tga';
    Result.JpgPath := AFileName + '.jpg';
    Result.PngPath := AFileName + '.png';
  end;

  Result.TgaPath := WithFolder(Result.TgaPath, TScreenshotFormat.Tga);
  Result.JpgPath := WithFolder(Result.JpgPath, TScreenshotFormat.Jpg);
  Result.PngPath := WithFolder(Result.PngPath, TScreenshotFormat.Png);
end;

end.
