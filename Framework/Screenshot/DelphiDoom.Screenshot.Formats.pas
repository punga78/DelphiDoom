{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - names of the formats                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.Formats;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types;

type
  /// <summary>Names, extensions and folders of the formats of a screenshot</summary>
  TScreenshotFormats = class sealed
  public
    /// <summary>The format of a name as the configuration writes it (TGA, JPG, PNG, upper case)</summary>
    class function TryParse(const AName: string; out AFormat: TScreenshotFormat): Boolean; static;
    /// <summary>The name of the format in the configuration (TGA, JPG, PNG)</summary>
    class function NameOf(AFormat: TScreenshotFormat): string; static;
    /// <summary>The extension of the files, with the point and in lower case</summary>
    class function ExtensionOf(AFormat: TScreenshotFormat): string; static;
    /// <summary>The folder of the files, from the folder of the game (DATA\SCREENSHOTS\PNG ...)</summary>
    class function FolderOf(AFormat: TScreenshotFormat): string; static;
    /// <summary>The folder that holds the one of every format</summary>
    class function RootFolder: string; static;
  end;

implementation

{ TScreenshotFormats }

class function TScreenshotFormats.TryParse(const AName: string;
  out AFormat: TScreenshotFormat): Boolean;
begin
  Result := True;
  if AName = 'TGA' then
    AFormat := TScreenshotFormat.Tga
  else if AName = 'PNG' then
    AFormat := TScreenshotFormat.Png
  else if AName = 'JPG' then
    AFormat := TScreenshotFormat.Jpg
  else
  begin
    AFormat := TScreenshotFormat.Png;
    Result := False;
  end;
end;

class function TScreenshotFormats.NameOf(AFormat: TScreenshotFormat): string;
begin
  case AFormat of
    TScreenshotFormat.Tga:
      Result := 'TGA';
    TScreenshotFormat.Png:
      Result := 'PNG';
  else
    Result := 'JPG';
  end;
end;

class function TScreenshotFormats.ExtensionOf(AFormat: TScreenshotFormat): string;
begin
  Result := '.' + LowerCase(NameOf(AFormat));
end;

class function TScreenshotFormats.FolderOf(AFormat: TScreenshotFormat): string;
begin
  Result := RootFolder + '\' + NameOf(AFormat);
end;

class function TScreenshotFormats.RootFolder: string;
begin
  Result := 'DATA\SCREENSHOTS';
end;

end.
