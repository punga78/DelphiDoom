{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, a skin             }
{                                                                              }
{  Port of skin_t of renderer\tr_local.h. Based on the Quake III Arena GPL     }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Skin.Skin;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>The surfaces of a skin and their shaders</summary>
  TQ3Skin = class(TInterfacedObject, IQ3Skin)
  strict private
    FName: AnsiString;
    FSurfaces: TArray<TQ3SkinSurface>;
  public
    constructor Create(const AName: AnsiString; const ASurfaces: TArray<TQ3SkinSurface>);
    function GetName: AnsiString;
    function GetSurfaceCount: Integer;
    /// <summary>Raises EArgumentOutOfRangeException for an index that does not exist</summary>
    function GetSurface(const AIndex: Integer): TQ3SkinSurface;
    function FindShader(const ASurfaceName: AnsiString; out AShader: AnsiString): Boolean;
  end;

implementation

constructor TQ3Skin.Create(const AName: AnsiString; const ASurfaces: TArray<TQ3SkinSurface>);
begin
  inherited Create;
  FName := AName;
  FSurfaces := ASurfaces;
end;

function TQ3Skin.GetName: AnsiString;
begin
  Result := FName;
end;

function TQ3Skin.GetSurfaceCount: Integer;
begin
  Result := Length(FSurfaces);
end;

function TQ3Skin.GetSurface(const AIndex: Integer): TQ3SkinSurface;
begin
  if (AIndex < 0) or (AIndex >= Length(FSurfaces)) then
    raise EArgumentOutOfRangeException.CreateFmt('Skin surface %d', [AIndex]);
  Result := FSurfaces[AIndex];
end;

function TQ3Skin.FindShader(const ASurfaceName: AnsiString; out AShader: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FSurfaces) do
    if FSurfaces[LIndex].Name = ASurfaceName then
    begin
      AShader := FSurfaces[LIndex].Shader;
      Exit(True);
    end;
  AShader := '';
  Result := False;
end;

end.
