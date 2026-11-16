{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL context - the list of the extensions of the driver       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlContext.ExtensionList;

interface

type
  /// <summary>The text GL_EXTENSIONS of the driver, ready to be searched by name</summary>
  TGlExtensionList = class sealed
  public
    /// <summary>
    ///   One extension per line (lines end with CR LF), in capital letters: every space of the driver text
    ///   becomes a line break, as gld_Init of gl_render.pas did before the list was searched with IndexOf
    /// </summary>
    class function Normalize(const AExtensions: string): string; static;
  end;

implementation

{ TGlExtensionList }

class function TGlExtensionList.Normalize(const AExtensions: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AExtensions) do
  begin
    if AExtensions[LIndex] = ' ' then
      Result := Result + #13#10
    else
      Result := Result + UpCase(AExtensions[LIndex]);
  end;
end;

end.
