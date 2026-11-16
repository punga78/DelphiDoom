{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the parts of a     }
{  player                                                                      }
{                                                                              }
{  The model fields of clientInfo_t of cgame\cg_local.h. Based on the Quake    }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.PlayerModel;

interface

uses
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>Legs, torso and head with their skins, the animations and the icon</summary>
  TQ3PlayerModel = class(TInterfacedObject, IQ3PlayerModel)
  strict private
    FLegsModel: IMd3Model;
    FTorsoModel: IMd3Model;
    FHeadModel: IMd3Model;
    FLegsSkin: IQ3Skin;
    FTorsoSkin: IQ3Skin;
    FHeadSkin: IQ3Skin;
    FAnimation: IQ3AnimationConfig;
    FIconFile: AnsiString;
  public
    constructor Create(const ALegsModel, ATorsoModel, AHeadModel: IMd3Model;
      const ALegsSkin, ATorsoSkin, AHeadSkin: IQ3Skin; const AAnimation: IQ3AnimationConfig;
      const AIconFile: AnsiString);
    function GetLegsModel: IMd3Model;
    function GetTorsoModel: IMd3Model;
    function GetHeadModel: IMd3Model;
    function GetLegsSkin: IQ3Skin;
    function GetTorsoSkin: IQ3Skin;
    function GetHeadSkin: IQ3Skin;
    function GetAnimation: IQ3AnimationConfig;
    function GetIconFile: AnsiString;
  end;

implementation

constructor TQ3PlayerModel.Create(const ALegsModel, ATorsoModel, AHeadModel: IMd3Model;
  const ALegsSkin, ATorsoSkin, AHeadSkin: IQ3Skin; const AAnimation: IQ3AnimationConfig;
  const AIconFile: AnsiString);
begin
  inherited Create;
  FLegsModel := ALegsModel;
  FTorsoModel := ATorsoModel;
  FHeadModel := AHeadModel;
  FLegsSkin := ALegsSkin;
  FTorsoSkin := ATorsoSkin;
  FHeadSkin := AHeadSkin;
  FAnimation := AAnimation;
  FIconFile := AIconFile;
end;

function TQ3PlayerModel.GetLegsModel: IMd3Model;
begin
  Result := FLegsModel;
end;

function TQ3PlayerModel.GetTorsoModel: IMd3Model;
begin
  Result := FTorsoModel;
end;

function TQ3PlayerModel.GetHeadModel: IMd3Model;
begin
  Result := FHeadModel;
end;

function TQ3PlayerModel.GetLegsSkin: IQ3Skin;
begin
  Result := FLegsSkin;
end;

function TQ3PlayerModel.GetTorsoSkin: IQ3Skin;
begin
  Result := FTorsoSkin;
end;

function TQ3PlayerModel.GetHeadSkin: IQ3Skin;
begin
  Result := FHeadSkin;
end;

function TQ3PlayerModel.GetAnimation: IQ3AnimationConfig;
begin
  Result := FAnimation;
end;

function TQ3PlayerModel.GetIconFile: AnsiString;
begin
  Result := FIconFile;
end;

end.
