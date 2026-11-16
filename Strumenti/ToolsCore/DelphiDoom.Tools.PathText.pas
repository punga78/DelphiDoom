{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - short names of files for the menus          }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.PathText;

interface

type
  /// <summary>The text of a path as a menu or a title shows it</summary>
  TToolPathText = class
  public
    /// <summary>
    ///   A name shorter than AMaxLength is kept; a longer one keeps its first 3 characters, then
    ///   "..." and the last AMaxLength - 5 (the old MkShortName, with the limit of 30)
    /// </summary>
    class function Shorten(const AFileName: string; AMaxLength: Integer): string; static;
  end;

implementation

{ TToolPathText }

class function TToolPathText.Shorten(const AFileName: string; AMaxLength: Integer): string;
var
  LTailLength: Integer;
begin
  Result := AFileName;
  if (AMaxLength < 6) or (Length(AFileName) < AMaxLength) then
    Exit;
  LTailLength := AMaxLength - 5;
  Result := Copy(AFileName, 1, 3) + '...' +
    Copy(AFileName, Length(AFileName) - LTailLength + 1, LTailLength);
end;

end.
