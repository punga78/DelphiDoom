{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialImageNames                       }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Image_init.cpp (the first lines of idImageManager::ImageFromFile)  }
{  and the tests of Material.cpp. Copyright (C) 1999-2011 id Software LLC, a   }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.ImageNames;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   How the image manager of the original names an image: ".tga" is taken out of the text (also inside the
  ///   parameters of an image program), backslashes become slashes, and "", "default" and "_default" are the
  ///   default image. A material only needs the names (the images are not loaded here).
  /// </summary>
  TMaterialImageNames = class sealed
  public
    /// <summary>The name without ".tga" (case sensitive, as <c>idStr::Replace</c>) and with slashes</summary>
    class function Canonicalize(const AName: AnsiString): AnsiString; static;
    /// <summary>"", "default" or "_default" (case is ignored): the image manager answers its default image</summary>
    class function IsDefault(const AName: AnsiString): Boolean; static;
    /// <summary>The image the screen was copied to (<c>_currentRender</c>): a material that uses it is a post process</summary>
    class function IsCurrentRender(const AName: AnsiString): Boolean; static;
    /// <summary>The name of the image <c>ImageFromFile</c> gives: "_default" for the default image, else the canonical name</summary>
    class function ResolvedName(const AName: AnsiString): AnsiString; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TMaterialImageNames }

class function TMaterialImageNames.Canonicalize(const AName: AnsiString): AnsiString;
begin
  Result := AnsiString(StringReplace(string(AName), '.tga', '', [rfReplaceAll]));
  Result := AnsiString(StringReplace(string(Result), '\', '/', [rfReplaceAll]));
end;

class function TMaterialImageNames.IsDefault(const AName: AnsiString): Boolean;
begin
  Result := (AName = '') or (TIdStrings.Icmp(AName, 'default') = 0) or (TIdStrings.Icmp(AName, '_default') = 0);
end;

class function TMaterialImageNames.IsCurrentRender(const AName: AnsiString): Boolean;
begin
  Result := (not IsDefault(AName)) and (TIdStrings.Icmp(Canonicalize(AName), '_currentRender') = 0);
end;

class function TMaterialImageNames.ResolvedName(const AName: AnsiString): AnsiString;
begin
  if IsDefault(AName) then
    Result := '_default'
  else
    Result := Canonicalize(AName);
end;

end.
