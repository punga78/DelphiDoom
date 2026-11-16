{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the texture functions of PS_GAME                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  GetTextureWidth, GetTextureHeight and IsValidTexture (the PS_*Texture* of   }
{  psi_game.pas).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Game.Textures;

interface

uses
  DelphiDoom.ScriptHost.Game.Intf,
  DelphiDoom.ScriptHost.Intf;

type
  /// <summary>The functions of the textures of the unit PS_GAME (called with the object as Self)</summary>
  TScriptTextures = class(TInterfacedObject, IScriptFunctionSection)
  strict private
    FSource: IScriptTextureSource;
    /// <summary>The number of the texture, or 0 if it is not a valid one (0 is the empty texture)</summary>
    function ValidId(const AName: string): Integer;
  public
    /// <exception cref="EArgumentNilException">If the source is nil</exception>
    constructor Create(const ASource: IScriptTextureSource);
    procedure Describe(const ATable: IScriptFunctionTable);
    function GetTextureWidth(const ATexture: string): Integer;
    function GetTextureHeight(const ATexture: string): Integer;
    function IsValidTexture(const ATexture: string): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TScriptTextures }

constructor TScriptTextures.Create(const ASource: IScriptTextureSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
end;

procedure TScriptTextures.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethod('function GetTextureWidth(const tex: string): Integer;', Self,
    @TScriptTextures.GetTextureWidth);
  ATable.AddMethod('function GetTextureHeight(const tex: string): Integer;', Self,
    @TScriptTextures.GetTextureHeight);
  ATable.AddMethod('function IsValidTexture(const tex: string): boolean;', Self,
    @TScriptTextures.IsValidTexture);
end;

function TScriptTextures.ValidId(const AName: string): Integer;
var
  LId: Integer;
begin
  LId := FSource.TextureId(AName);
  if (LId > 0) and (LId < FSource.TextureCount) then
    Result := LId
  else
    Result := 0;
end;

function TScriptTextures.GetTextureWidth(const ATexture: string): Integer;
var
  LId: Integer;
begin
  LId := ValidId(ATexture);
  if LId > 0 then
    Result := FSource.TextureWidth(LId)
  else
    Result := 0;
end;

function TScriptTextures.GetTextureHeight(const ATexture: string): Integer;
var
  LId: Integer;
begin
  LId := ValidId(ATexture);
  if LId > 0 then
    Result := FSource.TextureHeight(LId)
  else
    Result := 0;
end;

function TScriptTextures.IsValidTexture(const ATexture: string): Boolean;
begin
  Result := ValidId(ATexture) > 0;
end;

end.
