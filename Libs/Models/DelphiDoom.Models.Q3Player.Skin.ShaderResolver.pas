{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the shaders of     }
{  the surfaces                                                                }
{                                                                              }
{  Port of the choice of the shader in R_AddMD3Surfaces of renderer\tr_mesh.c. }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Skin.ShaderResolver;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Static.Md3.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>
  ///   With a skin, the shader of the surface of the same name or the default shader (empty name);
  ///   without a skin, the shader of the file of the model at "skin number mod the shaders" (the
  ///   default one if the surface has none). The names of the surfaces of an MD3 are already
  ///   lowercase, as the ones of a skin.
  /// </summary>
  TQ3SkinShaderResolver = class(TInterfacedObject, IQ3SkinShaderResolver)
  public
    function Resolve(const AModel: IMd3Model; const ASkin: IQ3Skin; const ASkinNumber: Integer): TArray<AnsiString>;
  end;

implementation

function TQ3SkinShaderResolver.Resolve(const AModel: IMd3Model; const ASkin: IQ3Skin;
  const ASkinNumber: Integer): TArray<AnsiString>;
var
  LIndex: Integer;
  LSurface: TMd3Surface;
  LShader: AnsiString;
begin
  if not Assigned(AModel) then
    raise EArgumentNilException.Create('AModel');
  if ASkinNumber < 0 then
    raise EArgumentOutOfRangeException.CreateFmt('Skin number %d', [ASkinNumber]);
  SetLength(Result, AModel.NumSurfaces);
  for LIndex := 0 to AModel.NumSurfaces - 1 do
  begin
    LSurface := AModel.Surfaces[LIndex];
    Result[LIndex] := '';
    if Assigned(ASkin) then
    begin
      if ASkin.FindShader(LSurface.Name, LShader) then
        Result[LIndex] := LShader;
    end
    else if Length(LSurface.Shaders) > 0 then
      Result[LIndex] := LSurface.Shaders[ASkinNumber mod Length(LSurface.Shaders)];
  end;
end;

end.
