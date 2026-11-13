{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the frame commands of an animation          }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim_Blend.cpp }
{  (idAnim::AddFrameCommand). Copyright (C) 1999-2011 id Software LLC, a       }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.FrameCommandParser;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Intf;

type
  /// <summary>
  ///   Reads the command that follows <c>frame N</c> in an anim block of a MODELDEF (the part of
  ///   <c>idAnim::AddFrameCommand</c> after the frame range check). The command is read on the
  ///   line of the keyword; what it refers to is asked to the game lookup.
  /// </summary>
  TAnimFrameCommandParser = class
  strict private
    FLookup: IModelDefGameLookup;
    FLog: IIdLibLog;
    function ReadArgument(const ALexer: TIdLexer; out AText: AnsiString): Boolean;
    procedure WarnSound(const AName: AnsiString);
  public
    /// <summary>The log is optional (the sounds that do not exist are only warnings)</summary>
    constructor Create(const ALookup: IModelDefGameLookup; const ALog: IIdLibLog);
    /// <summary>
    ///   Reads one command. The answer is the error message of the original, empty if all is
    ///   well; on an error the command is not valid.
    /// </summary>
    function Parse(const ALexer: TIdLexer; const AModelDef: IModelDef; out ACommand: TAnimFrameCommand): string;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token,
  DelphiDoom.Models.Static.Numbers;

type
  TArgumentKind = (akNone, akSound, akFunction, akObjectFunction, akEvent, akSkin, akFx, akText, akEntityDef,
    akJointOptional, akJoint, akJointAndTarget, akNumber, akOptionalText);

  TCommandInfo = record
    Name: AnsiString;
    CommandType: TAnimFrameCommandType;
    Kind: TArgumentKind;
  end;

const
  COMMANDS: array[0..39] of TCommandInfo = (
    (Name: 'call'; CommandType: fcScriptFunction; Kind: akFunction),
    (Name: 'object_call'; CommandType: fcScriptFunctionObject; Kind: akObjectFunction),
    (Name: 'event'; CommandType: fcEventFunction; Kind: akEvent),
    (Name: 'sound'; CommandType: fcSound; Kind: akSound),
    (Name: 'sound_voice'; CommandType: fcSoundVoice; Kind: akSound),
    (Name: 'sound_voice2'; CommandType: fcSoundVoice2; Kind: akSound),
    (Name: 'sound_body'; CommandType: fcSoundBody; Kind: akSound),
    (Name: 'sound_body2'; CommandType: fcSoundBody2; Kind: akSound),
    (Name: 'sound_body3'; CommandType: fcSoundBody3; Kind: akSound),
    (Name: 'sound_weapon'; CommandType: fcSoundWeapon; Kind: akSound),
    (Name: 'sound_global'; CommandType: fcSoundGlobal; Kind: akSound),
    (Name: 'sound_item'; CommandType: fcSoundItem; Kind: akSound),
    (Name: 'sound_chatter'; CommandType: fcSoundChatter; Kind: akSound),
    (Name: 'skin'; CommandType: fcSkin; Kind: akSkin),
    (Name: 'fx'; CommandType: fcFx; Kind: akFx),
    (Name: 'trigger'; CommandType: fcTrigger; Kind: akText),
    (Name: 'triggerSmokeParticle'; CommandType: fcTriggerSmokeParticle; Kind: akText),
    (Name: 'melee'; CommandType: fcMelee; Kind: akEntityDef),
    (Name: 'direct_damage'; CommandType: fcDirectDamage; Kind: akEntityDef),
    (Name: 'attack_begin'; CommandType: fcBeginAttack; Kind: akEntityDef),
    (Name: 'attack_end'; CommandType: fcEndAttack; Kind: akNone),
    (Name: 'muzzle_flash'; CommandType: fcMuzzleFlash; Kind: akJointOptional),
    (Name: 'create_missile'; CommandType: fcCreateMissile; Kind: akJoint),
    (Name: 'launch_missile'; CommandType: fcLaunchMissile; Kind: akJoint),
    (Name: 'fire_missile_at_target'; CommandType: fcFireMissileAtTarget; Kind: akJointAndTarget),
    (Name: 'footstep'; CommandType: fcFootstep; Kind: akNone),
    (Name: 'leftfoot'; CommandType: fcLeftFoot; Kind: akNone),
    (Name: 'rightfoot'; CommandType: fcRightFoot; Kind: akNone),
    (Name: 'enableEyeFocus'; CommandType: fcEnableEyeFocus; Kind: akNone),
    (Name: 'disableEyeFocus'; CommandType: fcDisableEyeFocus; Kind: akNone),
    (Name: 'disableGravity'; CommandType: fcDisableGravity; Kind: akNone),
    (Name: 'enableGravity'; CommandType: fcEnableGravity; Kind: akNone),
    (Name: 'jump'; CommandType: fcJump; Kind: akNone),
    (Name: 'enableClip'; CommandType: fcEnableClip; Kind: akNone),
    (Name: 'disableClip'; CommandType: fcDisableClip; Kind: akNone),
    (Name: 'enableWalkIK'; CommandType: fcEnableWalkIk; Kind: akNone),
    (Name: 'disableWalkIK'; CommandType: fcDisableWalkIk; Kind: akNone),
    (Name: 'enableLegIK'; CommandType: fcEnableLegIk; Kind: akNumber),
    (Name: 'disableLegIK'; CommandType: fcDisableLegIk; Kind: akNumber),
    (Name: 'recordDemo'; CommandType: fcRecordDemo; Kind: akOptionalText));
  // the last command, aviGame, is handled with recordDemo below
  AVI_GAME = 'aviGame';

{ TAnimFrameCommandParser }

constructor TAnimFrameCommandParser.Create(const ALookup: IModelDefGameLookup; const ALog: IIdLibLog);
begin
  inherited Create;
  FLookup := ALookup;
  FLog := ALog;
end;

function TAnimFrameCommandParser.ReadArgument(const ALexer: TIdLexer; out AText: AnsiString): Boolean;
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  Result := ALexer.ReadTokenOnLine(LToken);
  if Result then
    AText := LToken.Text
  else
    AText := '';
end;

procedure TAnimFrameCommandParser.WarnSound(const AName: AnsiString);
begin
  if Assigned(FLog) and FLookup.IsSoundDefaulted(AName) then
    FLog.Warning(Format('Sound ''%s'' not found', [string(AName)]));
end;

function TAnimFrameCommandParser.Parse(const ALexer: TIdLexer; const AModelDef: IModelDef;
  out ACommand: TAnimFrameCommand): string;
var
  LToken, LArgument: AnsiString;
  LInfo: TCommandInfo;
  LFound: Boolean;
  LIndex, LArgumentCount, LJoint: Integer;
begin
  Result := '';
  ACommand := Default(TAnimFrameCommand);
  if not ReadArgument(ALexer, LToken) then
    Exit(SAnimEndOfLine);
  LFound := False;
  for LIndex := 0 to High(COMMANDS) do
    if COMMANDS[LIndex].Name = LToken then
    begin
      LInfo := COMMANDS[LIndex];
      LFound := True;
      Break;
    end;
  if not LFound and (LToken = AVI_GAME) then
  begin
    LInfo.Name := AVI_GAME;
    LInfo.CommandType := fcAviGame;
    LInfo.Kind := akOptionalText;
    LFound := True;
  end;
  if not LFound then
    Exit(Format(SAnimUnknownCommand, [string(LToken)]));
  ACommand.CommandType := LInfo.CommandType;
  case LInfo.Kind of
    akNone:
      ;
    akOptionalText:
      if ReadArgument(ALexer, LArgument) then
      begin
        ACommand.Text := LArgument;
        ACommand.HasText := True;
      end;
  else
    if not ReadArgument(ALexer, LArgument) then
      Exit(SAnimEndOfLine);
    ACommand.Text := LArgument;
    case LInfo.Kind of
      akFunction:
        if not FLookup.FindScriptFunction(LArgument) then
          Exit(Format(SAnimFunctionNotFound, [string(LArgument)]));
      akObjectFunction, akText:
        ACommand.HasText := True;
      akEvent:
        begin
          if not FLookup.FindEvent(LArgument, LArgumentCount) then
            Exit(Format(SAnimEventNotFound, [string(LArgument)]));
          if LArgumentCount <> 0 then
            Exit(Format(SAnimEventArguments, [string(LArgument)]));
          ACommand.HasText := True;
        end;
      akSound:
        if Copy(LArgument, 1, 4) = 'snd_' then
          ACommand.HasText := True
        else
          WarnSound(LArgument);
      akSkin:
        if LArgument = 'none' then
          ACommand.Text := ''
        else if not FLookup.FindSkin(LArgument) then
          Exit(Format(SAnimSkinNotFound, [string(LArgument)]));
      akFx:
        begin
          if not FLookup.FindFx(LArgument) then
            Exit(Format(SAnimFxNotFound, [string(LArgument)]));
          ACommand.HasText := True;
        end;
      akEntityDef:
        begin
          if not FLookup.FindEntityDef(LArgument) then
            Exit(Format(SAnimEntityDefNotFound, [string(LArgument)]));
          ACommand.HasText := True;
        end;
      akJointOptional, akJoint, akJointAndTarget:
        begin
          LJoint := AModelDef.FindJoint(LArgument);
          if ((LInfo.Kind <> akJointOptional) or (LArgument <> '')) and (LJoint < 0) then
            Exit(Format(SAnimJointNotFound, [string(LArgument)]));
          ACommand.HasText := True;
          if LInfo.Kind = akJointAndTarget then
          begin
            ACommand.Index := LJoint;
            if not ReadArgument(ALexer, LArgument) then
              Exit(SAnimEndOfLine);
            ACommand.Text := LArgument;
          end;
        end;
      akNumber:
        ACommand.Index := TStaticNumbers.Atoi(LArgument);
    end;
  end;
end;

end.
