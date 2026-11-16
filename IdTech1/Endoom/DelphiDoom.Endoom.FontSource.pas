{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the font that comes with the editor             }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.FontSource;

interface

uses
  System.SysUtils,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>The font of ENDEDIT (ENDOOM_EDITOR_FONT), built into the program</summary>
  TEndoomEmbeddedFontSource = class(TInterfacedObject, IEndoomFontSource)
  public
    function GetFont: TBytes;
  end;

implementation

uses
  DelphiDoom.Endoom.DosFont;

{ TEndoomEmbeddedFontSource }

function TEndoomEmbeddedFontSource.GetFont: TBytes;
begin
  SetLength(Result, SizeOf(ENDOOM_EDITOR_FONT));
  Move(ENDOOM_EDITOR_FONT[0], Result[0], SizeOf(ENDOOM_EDITOR_FONT));
end;

end.
