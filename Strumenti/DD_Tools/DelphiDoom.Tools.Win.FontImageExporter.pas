{******************************************************************************}
{                                                                              }
{  DD_Tools: writes the grid of a font as a picture                             }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.FontImageExporter;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types,
  DelphiDoom.FontEditor.Intf;

type
  /// <summary>
  ///   IFontEditorImageExporter on the exporter of the endoom editor (PNG, JPEG or BMP by the extension of the
  ///   name): the grid is a picture of $00RRGGBB pixels like the screen of ENDEDIT
  /// </summary>
  TVclFontImageExporter = class(TInterfacedObject, IFontEditorImageExporter)
  public
    function Export(const AFileName: string; const AImage: TFontImage): Boolean;
  end;

implementation

uses
  DelphiDoom.EndoomEditor.Intf,
  DelphiDoom.Tools.Win.ImageExporter;

{ TVclFontImageExporter }

function TVclFontImageExporter.Export(const AFileName: string; const AImage: TFontImage): Boolean;
var
  LExporter: IEndoomEditorImageExporter;
begin
  LExporter := TVclEndoomImageExporter.Create;
  Result := AImage.IsValid and LExporter.Export(AFileName, AImage.Pixels, AImage.Width, AImage.Height);
end;

end.
