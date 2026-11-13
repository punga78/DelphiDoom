{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the MD3 loader               }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md3.cpp.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore            }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Md3.Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Md3.Intf;

type
  /// <summary>
  ///   The bytes of an .md3 file: <c>Read</c> gives the model with all its frames, <c>Load</c>
  ///   (IStaticModelLoader) the static model of the first frame
  /// </summary>
  TMd3ModelLoader = class(TInterfacedObject, IStaticModelLoader, IMd3Reader)
  public
    function Read(const AData: TBytes; const AName: string): IMd3Model;
    function Load(const AData: TBytes; const AName: string): IStaticModel;
  end;

implementation

uses
  DelphiDoom.Models.Static.Md3.Types,
  DelphiDoom.Models.Static.Md3.Reader,
  DelphiDoom.Models.Static.Md3.Model;

{ TMd3ModelLoader }

function TMd3ModelLoader.Read(const AData: TBytes; const AName: string): IMd3Model;
var
  LReader: TMd3Reader;
begin
  LReader := TMd3Reader.Create;
  try
    Result := TMd3ModelData.Create(LReader.Read(AData, AnsiString(AName)));
  finally
    LReader.Free;
  end;
end;

function TMd3ModelLoader.Load(const AData: TBytes; const AName: string): IStaticModel;
begin
  Result := Read(AData, AName).Instantiate(0, 0, 0);
end;

end.
