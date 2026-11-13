{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the LWO loader               }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic::LoadLWO). Copyright (C) 1999-2011 id Software LLC,    }
{  a ZeniMax Media company. This unit is derived from the Doom 3 GPL source    }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Lwo.Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf;

type
  /// <summary>The bytes of a .lwo file to a static model: the reader and the converter in a row</summary>
  TLwoModelLoader = class(TInterfacedObject, IStaticModelLoader)
  strict private
    FOptions: TStaticLoadOptions;
  public
    constructor Create(const AOptions: TStaticLoadOptions);
    function Load(const AData: TBytes; const AName: string): IStaticModel;
  end;

implementation

uses
  DelphiDoom.Models.Static.Lwo.Types,
  DelphiDoom.Models.Static.Lwo.Reader,
  DelphiDoom.Models.Static.Lwo.Converter;

{ TLwoModelLoader }

constructor TLwoModelLoader.Create(const AOptions: TStaticLoadOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TLwoModelLoader.Load(const AData: TBytes; const AName: string): IStaticModel;
var
  LReader: TLwoReader;
  LConverter: TLwoConverter;
begin
  LReader := TLwoReader.Create;
  try
    LConverter := TLwoConverter.Create(FOptions);
    try
      Result := LConverter.Convert(LReader.Read(AData), AName);
    finally
      LConverter.Free;
    end;
  finally
    LReader.Free;
  end;
end;

end.
