{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TFxActionParser, one action of an effect  }
{                                                                              }
{  Port of the effects of Doom 3 (id Software, GPL v3): framework\DeclFX.cpp   }
{  (idDeclFX::ParseSingleFXAction) and idVec3::ToMat3 of idlib\math.           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Fx.ActionParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Fx.Types;

type
  /// <summary>
  ///   Reads the text between the braces of one action (<c>sound x / delay 0.5 / ...</c>). Like the original it
  ///   warns about a word it does not know and goes on. It looks up (and so creates the default of) the materials, sounds
  ///   and entity defs the action names, as the original does to precache them; the models and
  ///   particles it names are not looked up (the render model manager is not ported).
  /// </summary>
  TFxActionParser = class
  strict private
    FFinder: IDeclFinder;
    class function VectorToMat3(const AVector: TIdVec3): TIdMat3; static;
    procedure ExpectComma(const ASource: TIdLexer);
  public
    constructor Create(const AFinder: IDeclFinder);
    /// <summary>
    ///   idDeclFX::ParseSingleFXAction: <c>ASource</c> is just after the opening brace. <c>AEvents</c> are the actions
    ///   read before this one (<c>uselight</c> and <c>useModel</c> look their name up in them).
    /// </summary>
    function ParseAction(const ASource: TIdLexer; const AEvents: TArray<TFxAction>): TFxAction;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.Conversions, DelphiDoom.Decl.Types;

{ TFxActionParser }

constructor TFxActionParser.Create(const AFinder: IDeclFinder);
begin
  inherited Create;
  if not Assigned(AFinder) then
    raise EDeclFxException.Create('an effect action parser needs a finder of declarations');
  FFinder := AFinder;
end;

// idVec3::ToMat3: the vector is the first row, the second is horizontal and perpendicular to it, the third is their cross
class function TFxActionParser.VectorToMat3(const AVector: TIdVec3): TIdMat3;
var
  LDistance: Single;
begin
  Result.Rows[0] := AVector;
  LDistance := AVector.X * AVector.X + AVector.Y * AVector.Y;
  if LDistance = 0 then
    Result.Rows[1].SetValues(1.0, 0.0, 0.0)
  else
  begin
    LDistance := TIdMath.InvSqrt(LDistance);
    Result.Rows[1].SetValues(-AVector.Y * LDistance, AVector.X * LDistance, 0.0);
  end;
  Result.Rows[2] := AVector.Cross(Result.Rows[1]);
end;

procedure TFxActionParser.ExpectComma(const ASource: TIdLexer);
begin
  ASource.ExpectTokenString(',');
end;

function TFxActionParser.ParseAction(const ASource: TIdLexer; const AEvents: TArray<TFxAction>): TFxAction;
var
  LToken: TIdToken;
  LKeyword: AnsiString;
  LVector: TIdVec3;
  LAngles: TIdAngles;
  LIndex: Integer;

  function Keyword(const AName: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LKeyword, AName) = 0;
  end;

  // the name that follows a keyword: the result of ReadToken is not checked in the original
  function ReadName: AnsiString;
  begin
    ASource.ReadToken(LToken);
    Result := LToken.Text;
  end;

  procedure Precache(const AType: Integer; const AName: AnsiString);
  begin
    FFinder.FindType(AType, AName);
  end;

begin
  LToken := TIdToken.Create;
  Result := TFxAction.Create;

  while True do
  begin
    if not ASource.ReadToken(LToken) then
      Break;
    LKeyword := LToken.Text;

    if Keyword('}') then
      Break;

    if Keyword('shake') then
    begin
      Result.ActionType := FX_SHAKE;
      Result.ShakeTime := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.ShakeAmplitude := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.ShakeDistance := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.ShakeFalloff := ASource.ParseBool;
      ExpectComma(ASource);
      Result.ShakeImpulse := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('noshadows') then
    begin
      Result.NoShadows := True;
      Continue;
    end;

    if Keyword('name') then
    begin
      Result.Name := ReadName;
      Continue;
    end;

    if Keyword('fire') then
    begin
      Result.Fire := ReadName;
      Continue;
    end;

    if Keyword('random') then
    begin
      Result.Random1 := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.Random2 := ASource.ParseFloat;
      Result.Delay := 0.0; // check random
      Continue;
    end;

    if Keyword('delay') then
    begin
      Result.Delay := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('rotate') then
    begin
      Result.Rotate := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('duration') then
    begin
      Result.Duration := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('trackorigin') then
    begin
      Result.TrackOrigin := ASource.ParseBool;
      Continue;
    end;

    if Keyword('restart') then
    begin
      Result.Restart := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('fadeIn') then
    begin
      Result.FadeInTime := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('fadeOut') then
    begin
      Result.FadeOutTime := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('size') then
    begin
      Result.Size := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('offset') then
    begin
      Result.Offset.X := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.Offset.Y := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.Offset.Z := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('axis') then
    begin
      LVector.X := ASource.ParseFloat;
      ExpectComma(ASource);
      LVector.Y := ASource.ParseFloat;
      ExpectComma(ASource);
      LVector.Z := ASource.ParseFloat;
      LVector.Normalize;
      Result.Axis := VectorToMat3(LVector);
      Result.ExplicitAxis := True;
      Continue;
    end;

    if Keyword('angle') then
    begin
      LAngles.Pitch := ASource.ParseFloat;
      ExpectComma(ASource);
      LAngles.Yaw := ASource.ParseFloat;
      ExpectComma(ASource);
      LAngles.Roll := ASource.ParseFloat;
      Result.Axis := TIdRotationConversions.AnglesToMat(LAngles);
      Result.ExplicitAxis := True;
      Continue;
    end;

    if Keyword('uselight') then
    begin
      Result.Data := ReadName;
      for LIndex := 0 to High(AEvents) do
        if TIdStrings.Icmp(AEvents[LIndex].Name, Result.Data) = 0 then
        begin
          Result.Sibling := LIndex;
          Result.LightColor := AEvents[LIndex].LightColor;
          Result.LightRadius := AEvents[LIndex].LightRadius;
        end;
      Result.ActionType := FX_LIGHT;
      // precache the light material
      Precache(DECL_MATERIAL, Result.Data);
      Continue;
    end;

    if Keyword('attachlight') then
    begin
      Result.Data := ReadName;
      Result.ActionType := FX_ATTACHLIGHT;
      // precache it
      Precache(DECL_MATERIAL, Result.Data);
      Continue;
    end;

    if Keyword('attachentity') then
    begin
      Result.Data := ReadName;
      Result.ActionType := FX_ATTACHENTITY;
      // the original precaches the model here (renderModelManager->FindModel)
      Continue;
    end;

    if Keyword('launch') then
    begin
      Result.Data := ReadName;
      Result.ActionType := FX_LAUNCH;
      // precache the entity def
      Precache(DECL_ENTITYDEF, Result.Data);
      Continue;
    end;

    if Keyword('useModel') then
    begin
      Result.Data := ReadName;
      for LIndex := 0 to High(AEvents) do
        if TIdStrings.Icmp(AEvents[LIndex].Name, Result.Data) = 0 then
          Result.Sibling := LIndex;
      Result.ActionType := FX_MODEL;
      Continue;
    end;

    if Keyword('light') then
    begin
      Result.Data := ReadName;
      ExpectComma(ASource);
      Result.LightColor.X := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.LightColor.Y := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.LightColor.Z := ASource.ParseFloat;
      ExpectComma(ASource);
      Result.LightRadius := ASource.ParseFloat;
      Result.ActionType := FX_LIGHT;
      // precache the light material
      Precache(DECL_MATERIAL, Result.Data);
      Continue;
    end;

    if Keyword('model') then
    begin
      Result.Data := ReadName;
      Result.ActionType := FX_MODEL;
      Continue;
    end;

    if Keyword('particle') then
    begin
      // FIXME in the original: now the same as model
      Result.Data := ReadName;
      Result.ActionType := FX_PARTICLE;
      Continue;
    end;

    if Keyword('decal') then
    begin
      Result.Data := ReadName;
      Result.ActionType := FX_DECAL;
      // precache it
      Precache(DECL_MATERIAL, Result.Data);
      Continue;
    end;

    if Keyword('particleTrackVelocity') then
    begin
      Result.ParticleTrackVelocity := True;
      Continue;
    end;

    if Keyword('sound') then
    begin
      Result.Data := ReadName;
      Result.ActionType := FX_SOUND;
      // precache it
      Precache(DECL_SOUND, Result.Data);
      Continue;
    end;

    if Keyword('ignoreMaster') then
    begin
      Result.ShakeIgnoreMaster := True;
      Continue;
    end;

    if Keyword('shockwave') then
    begin
      Result.Data := ReadName;
      Result.ActionType := FX_SHOCKWAVE;
      // precache the entity def
      Precache(DECL_ENTITYDEF, Result.Data);
      Continue;
    end;

    ASource.Warning('FX File: bad token', []);
  end;
end;

end.
