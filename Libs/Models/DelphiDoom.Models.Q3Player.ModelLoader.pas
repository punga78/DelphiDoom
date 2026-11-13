{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, loading a player   }
{                                                                              }
{  Port of CG_RegisterClientSkin and CG_RegisterClientModelname of cgame\      }
{  cg_players.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.ModelLoader;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>
  ///   The legs, torso and head models ("lower", "upper", "head" in the folder of the player or in
  ///   "characters/" or "heads/"), their skins, the animation.cfg and the icon, in the order and
  ///   with the retries of the original: a failed skin of a team is tried again with the team
  ///   "Stroggs/" or "Pagans/" and keeps what the first try found. The same registry of skins is
  ///   used by every player, as the renderer of the original.
  /// </summary>
  TQ3PlayerModelLoader = class(TInterfacedObject, IQ3PlayerModelLoader)
  strict private
    FModels: IQ3ModelSource;
    FSkins: IQ3SkinRegistry;
    FFinder: IQ3PlayerFileFinder;
    FAnimations: IQ3AnimationLoader;
    FLog: ILog;
    procedure Warn(const AMessage: string);
    function RegisterSkins(const ARequest: TQ3PlayerModelRequest; const ATeamName, AHeadName: AnsiString;
      var ALegs, ATorso, AHead: Integer): Boolean;
  public
    constructor Create(const AModels: IQ3ModelSource; const ASkins: IQ3SkinRegistry;
      const AFinder: IQ3PlayerFileFinder; const AAnimations: IQ3AnimationLoader; const ALog: ILog);
    function Load(const ARequest: TQ3PlayerModelRequest; out AModel: IQ3PlayerModel): Boolean;
  end;

implementation

uses
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.PlayerModel;

constructor TQ3PlayerModelLoader.Create(const AModels: IQ3ModelSource; const ASkins: IQ3SkinRegistry;
  const AFinder: IQ3PlayerFileFinder; const AAnimations: IQ3AnimationLoader; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AModels) then
    raise EArgumentNilException.Create('AModels');
  if not Assigned(ASkins) then
    raise EArgumentNilException.Create('ASkins');
  if not Assigned(AFinder) then
    raise EArgumentNilException.Create('AFinder');
  if not Assigned(AAnimations) then
    raise EArgumentNilException.Create('AAnimations');
  FModels := AModels;
  FSkins := ASkins;
  FFinder := AFinder;
  FAnimations := AAnimations;
  FLog := ALog;
end;

procedure TQ3PlayerModelLoader.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

// CG_RegisterClientSkin: the handles are those of the clientInfo_t, they stay between two tries
function TQ3PlayerModelLoader.RegisterSkins(const ARequest: TQ3PlayerModelRequest; const ATeamName,
  AHeadName: AnsiString; var ALegs, ATorso, AHead: Integer): Boolean;
var
  LFileName: AnsiString;
begin
  if FFinder.FindModelFile(ARequest.Context, ATeamName, ARequest.ModelName, ARequest.SkinName, 'lower',
    'skin', LFileName) then
    ALegs := FSkins.RegisterSkin(LFileName);
  if ALegs = 0 then
    Warn(Format(SQ3LegsSkinFailure, [string(LFileName)]));

  if FFinder.FindModelFile(ARequest.Context, ATeamName, ARequest.ModelName, ARequest.SkinName, 'upper',
    'skin', LFileName) then
    ATorso := FSkins.RegisterSkin(LFileName);
  if ATorso = 0 then
    Warn(Format(SQ3TorsoSkinFailure, [string(LFileName)]));

  if FFinder.FindHeadFile(ARequest.Context, ATeamName, AHeadName, ARequest.HeadSkinName, 'head', 'skin',
    LFileName) then
    AHead := FSkins.RegisterSkin(LFileName);
  if AHead = 0 then
    Warn(Format(SQ3HeadSkinFailure, [string(LFileName)]));

  Result := (ALegs <> 0) and (ATorso <> 0) and (AHead <> 0);
end;

function TQ3PlayerModelLoader.Load(const ARequest: TQ3PlayerModelRequest; out AModel: IQ3PlayerModel): Boolean;
var
  LHeadName, LFileName, LNewTeamName, LIconFile: AnsiString;
  LLegs, LTorso, LHead: IMd3Model;
  LLegsSkin, LTorsoSkin, LHeadSkin: Integer;
  LAnimation: IQ3AnimationConfig;

  function FindModel(const AFileName: AnsiString): IMd3Model;
  begin
    LFileName := AFileName;
    Result := FModels.RegisterModel(LFileName);
  end;

  function LoadAnimation(const AFileName: AnsiString): Boolean;
  begin
    try
      LAnimation := FAnimations.Load(string(AFileName));
      Result := True;
    except
      on EQ3AnimationMissingException do
        Result := False;
    end;
  end;

begin
  AModel := nil;
  Result := False;
  LLegsSkin := 0;
  LTorsoSkin := 0;
  LHeadSkin := 0;
  if ARequest.HeadModelName = '' then
    LHeadName := ARequest.ModelName
  else
    LHeadName := ARequest.HeadModelName;

  LLegs := FindModel(AnsiString(Format('models/players/%s/lower.md3', [string(ARequest.ModelName)])));
  if not Assigned(LLegs) then
  begin
    LLegs := FindModel(AnsiString(Format('models/players/characters/%s/lower.md3', [string(ARequest.ModelName)])));
    if not Assigned(LLegs) then
    begin
      Warn(Format(SQ3ModelFileFailure, [string(LFileName)]));
      Exit;
    end;
  end;

  LTorso := FindModel(AnsiString(Format('models/players/%s/upper.md3', [string(ARequest.ModelName)])));
  if not Assigned(LTorso) then
  begin
    LTorso := FindModel(AnsiString(Format('models/players/characters/%s/upper.md3', [string(ARequest.ModelName)])));
    if not Assigned(LTorso) then
    begin
      Warn(Format(SQ3ModelFileFailure, [string(LFileName)]));
      Exit;
    end;
  end;

  // the star takes the folder of the heads, and the name is the one of the request (as the original)
  if (LHeadName <> '') and (LHeadName[1] = '*') then
    LHead := FindModel(AnsiString(Format('models/players/heads/%s/%s.md3',
      [Copy(string(ARequest.HeadModelName), 2, MaxInt), Copy(string(ARequest.HeadModelName), 2, MaxInt)])))
  else
    LHead := FindModel(AnsiString(Format('models/players/%s/head.md3', [string(LHeadName)])));
  // if the head model could not be found and we didn't load from the heads folder try to load from there
  if (not Assigned(LHead)) and not ((LHeadName <> '') and (LHeadName[1] = '*')) then
    LHead := FindModel(AnsiString(Format('models/players/heads/%s/%s.md3',
      [string(ARequest.HeadModelName), string(ARequest.HeadModelName)])));
  if not Assigned(LHead) then
  begin
    Warn(Format(SQ3ModelFileFailure, [string(LFileName)]));
    Exit;
  end;

  // if any skins failed to load, return failure
  if not RegisterSkins(ARequest, ARequest.TeamName, LHeadName, LLegsSkin, LTorsoSkin, LHeadSkin) then
  begin
    if ARequest.TeamName <> '' then
    begin
      Warn(Format(SQ3SkinFileFailureTeam, [string(ARequest.TeamName), string(ARequest.ModelName),
        string(ARequest.SkinName), string(LHeadName), string(ARequest.HeadSkinName)]));
      if ARequest.Context.Team = qtBlue then
        LNewTeamName := AnsiString(Q3_DEFAULT_BLUE_TEAM_NAME + '/')
      else
        LNewTeamName := AnsiString(Q3_DEFAULT_RED_TEAM_NAME + '/');
      if not RegisterSkins(ARequest, LNewTeamName, LHeadName, LLegsSkin, LTorsoSkin, LHeadSkin) then
      begin
        Warn(Format(SQ3SkinFileFailureTeam, [string(LNewTeamName), string(ARequest.ModelName),
          string(ARequest.SkinName), string(LHeadName), string(ARequest.HeadSkinName)]));
        Exit;
      end;
    end
    else
    begin
      Warn(Format(SQ3SkinFileFailure, [string(ARequest.ModelName), string(ARequest.SkinName),
        string(LHeadName), string(ARequest.HeadSkinName)]));
      Exit;
    end;
  end;

  // load the animations
  LFileName := AnsiString(Format('models/players/%s/animation.cfg', [string(ARequest.ModelName)]));
  if not LoadAnimation(LFileName) then
  begin
    LFileName := AnsiString(Format('models/players/characters/%s/animation.cfg', [string(ARequest.ModelName)]));
    if not LoadAnimation(LFileName) then
    begin
      Warn(Format(SQ3AnimationFileFailure, [string(LFileName)]));
      Exit;
    end;
  end;

  // the icon (the original registers a shader: here the file is what makes it exist)
  if not FFinder.FindHeadFile(ARequest.Context, ARequest.TeamName, LHeadName, ARequest.HeadSkinName, 'icon',
    'skin', LIconFile) then
    if not FFinder.FindHeadFile(ARequest.Context, ARequest.TeamName, LHeadName, ARequest.HeadSkinName, 'icon',
      'tga', LIconFile) then
      Exit;

  AModel := TQ3PlayerModel.Create(LLegs, LTorso, LHead, FSkins.GetSkin(LLegsSkin), FSkins.GetSkin(LTorsoSkin),
    FSkins.GetSkin(LHeadSkin), LAnimation, LIconFile);
  Result := True;
end;

end.
