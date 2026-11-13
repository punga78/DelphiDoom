{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the ASE loader               }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic::LoadASE). Copyright (C) 1999-2011 id Software LLC,    }
{  a ZeniMax Media company. This unit is derived from the Doom 3 GPL source    }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ase.Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Ase.Types;

type
  /// <summary>The bytes of an .ase file to a static model: the parser and the converter in a row</summary>
  TAseModelLoader = class(TInterfacedObject, IStaticModelLoader)
  strict private
    FOptions: TStaticLoadOptions;
    FResolver: TStaticPathResolver;
  public
    /// <summary>The resolver turns the bitmap paths into material names (nil keeps the path)</summary>
    constructor Create(const AOptions: TStaticLoadOptions; const AResolver: TStaticPathResolver = nil);
    function Load(const AData: TBytes; const AName: string): IStaticModel;
  end;

implementation

uses
  DelphiDoom.Models.Static.Ase.Parser,
  DelphiDoom.Models.Static.Ase.Converter;

{ TAseModelLoader }

constructor TAseModelLoader.Create(const AOptions: TStaticLoadOptions; const AResolver: TStaticPathResolver);
begin
  inherited Create;
  FOptions := AOptions;
  FResolver := AResolver;
end;

function TAseModelLoader.Load(const AData: TBytes; const AName: string): IStaticModel;
var
  LParser: TAseParser;
  LConverter: TAseConverter;
  LText: AnsiString;
begin
  SetString(LText, PAnsiChar(AData), Length(AData));
  LParser := TAseParser.Create(FResolver);
  try
    LConverter := TAseConverter.Create(FOptions);
    try
      Result := LConverter.Convert(LParser.Parse(LText), AName);
    finally
      LConverter.Free;
    end;
  finally
    LParser.Free;
  end;
end;

end.
