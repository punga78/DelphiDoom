{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiDoomFont, a point size of a font of Doom 3    }
{                                                                              }
{  fontInfo_t of renderer\RenderSystem.h (id Software, GPL v3): the glyphs     }
{  of the .dat file and the material of each glyph.                            }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Font.Doom;

interface

uses
  DelphiDoom.Gui.Font, DelphiDoom.Gui.Font.Types, DelphiDoom.Gui.Material.Intf;

type
  /// <summary>
  ///   fontInfo_t of Doom 3: the same glyph table as the one of Quake III (<c>TGuiFont</c>) with the
  ///   material of every glyph (<c>glyphInfo_t::glyph</c> is a pointer there, not a handle).
  /// </summary>
  TGuiDoomFont = class
  strict private
    FInfo: TGuiFont;
    FMaterials: array[0..GUI_GLYPHS_PER_FONT - 1] of IGuiMaterial;
    function GetMaterial(const AIndex: Integer): IGuiMaterial;
    procedure SetMaterial(const AIndex: Integer; const AValue: IGuiMaterial);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The glyphs, the scale and the name</summary>
    property Info: TGuiFont read FInfo;
    property Materials[const AIndex: Integer]: IGuiMaterial read GetMaterial write SetMaterial;
  end;

implementation

constructor TGuiDoomFont.Create;
begin
  inherited Create;
  FInfo := TGuiFont.Create;
end;

destructor TGuiDoomFont.Destroy;
begin
  FInfo.Free;
  inherited Destroy;
end;

function TGuiDoomFont.GetMaterial(const AIndex: Integer): IGuiMaterial;
begin
  Result := FMaterials[AIndex];
end;

procedure TGuiDoomFont.SetMaterial(const AIndex: Integer; const AValue: IGuiMaterial);
begin
  FMaterials[AIndex] := AValue;
end;

end.
