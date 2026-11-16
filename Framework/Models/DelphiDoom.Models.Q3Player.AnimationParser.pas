{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, animation.cfg      }
{                                                                              }
{  Port of CG_ParseAnimationFile of cgame\cg_players.c. Based on the Quake III }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.AnimationParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>
  ///   CG_ParseAnimationFile: the optional parameters (footsteps, headoffset, sex, fixedlegs,
  ///   fixedtorso) and a line "first num looping fps" for each animation up to TORSO_NEGATIVE.
  ///   The animations of the legs count the frames from the first of the legs (the frames of the
  ///   torso only, which the file lists first, are subtracted); the flag animations of the torso may
  ///   be missing (they copy TORSO_GESTURE); the backward and flag animations are derived.
  ///   The warnings of the original (a wrong footsteps word, an unknown word) go to the log; a
  ///   file that cannot be read is an EQ3PlayerException.
  /// </summary>
  TQ3AnimationParser = class(TInterfacedObject, IQ3AnimationParser)
  strict private
    FLog: ILog;
  public
    constructor Create(const ALog: ILog);
    function Parse(const AText: AnsiString; const AFileName: string): IQ3AnimationConfig;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Numbers,
  DelphiDoom.Models.Q3Player.AnimationConfig,
  DelphiDoom.Models.Q3Player.FloatMath,
  DelphiDoom.Models.Q3Player.TokenReader;

const
  // sizeof(text) of the original: the file has to be shorter than this minus one
  MAX_TEXT_SIZE = 20000;

constructor TQ3AnimationParser.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

function TQ3AnimationParser.Parse(const AText: AnsiString; const AFileName: string): IQ3AnimationConfig;
var
  LConfig: TQ3AnimationConfig;
  LReader: TQ3TokenReader;
  LPrevious: TQ3TokenState;
  LToken: AnsiString;
  LAnimations: array[0..Q3_MAX_TOTAL_ANIMATIONS - 1] of TQ3Animation;
  LOffset: TIdVec3;
  LIndex, LSkip, LCoordinate: Integer;
  LFps, LQuotient: Single;
  LGesture: TQ3Animation;
  LFlag: TQ3Animation;
  procedure ParseFailure(const AMessage: string);
  begin
    raise EQ3PlayerException.CreateAtLine(AMessage, LReader.Line);
  end;
  procedure Warn(const AMessage: string);
  begin
    if Assigned(FLog) then
      FLog.Warning(AMessage);
  end;
begin
  if System.Length(AText) = 0 then
    raise EQ3AnimationMissingException.CreateAtLine(Format(SQ3AnimationMissing, [AFileName]), 0);
  if System.Length(AText) >= MAX_TEXT_SIZE - 1 then
    raise EQ3PlayerException.CreateAtLine(Format(SQ3AnimationTooLong, [AFileName]), 0);

  LConfig := TQ3AnimationConfig.Create;
  Result := LConfig;
  FillChar(LAnimations, SizeOf(LAnimations), 0);
  LReader := TQ3TokenReader.Create(AText);
  try
    LSkip := 0;
    LOffset.Zero;
    // read optional parameters
    while True do
    begin
      LPrevious := LReader.SaveState;
      LToken := LReader.Next;
      // the original never sees the end of the text here (its test for it is on a pointer that is
      // never null) and loops forever on a file without animations
      if (LToken = '') and LReader.Ended then
        ParseFailure(Format(SQ3AnimationHeaderEnd, [AFileName]));
      if TQ3TokenReader.SameWord(LToken, 'footsteps') then
      begin
        LToken := LReader.Next;
        if TQ3TokenReader.SameWord(LToken, 'default') or TQ3TokenReader.SameWord(LToken, 'normal') then
          LConfig.SetFootsteps(qfNormal)
        else if TQ3TokenReader.SameWord(LToken, 'boot') then
          LConfig.SetFootsteps(qfBoot)
        else if TQ3TokenReader.SameWord(LToken, 'flesh') then
          LConfig.SetFootsteps(qfFlesh)
        else if TQ3TokenReader.SameWord(LToken, 'mech') then
          LConfig.SetFootsteps(qfMech)
        else if TQ3TokenReader.SameWord(LToken, 'energy') then
          LConfig.SetFootsteps(qfEnergy)
        else
          Warn(Format(SQ3BadFootsteps, [AFileName, string(LToken)]));
        Continue;
      end
      else if TQ3TokenReader.SameWord(LToken, 'headoffset') then
      begin
        for LCoordinate := 0 to 2 do
        begin
          LToken := LReader.Next;
          LOffset[LCoordinate] := Single(TStaticNumbers.Atof(LToken));
          LConfig.SetHeadOffset(LOffset);
        end;
        Continue;
      end
      else if TQ3TokenReader.SameWord(LToken, 'sex') then
      begin
        LToken := LReader.Next;
        if (LToken <> '') and ((LToken[1] = 'f') or (LToken[1] = 'F')) then
          LConfig.SetGender(qgFemale)
        else if (LToken <> '') and ((LToken[1] = 'n') or (LToken[1] = 'N')) then
          LConfig.SetGender(qgNeuter)
        else
          LConfig.SetGender(qgMale);
        Continue;
      end
      else if TQ3TokenReader.SameWord(LToken, 'fixedlegs') then
      begin
        LConfig.SetFixedLegs(True);
        Continue;
      end
      else if TQ3TokenReader.SameWord(LToken, 'fixedtorso') then
      begin
        LConfig.SetFixedTorso(True);
        Continue;
      end;

      // if it is a number, start parsing animations
      if (LToken <> '') and (LToken[1] >= '0') and (LToken[1] <= '9') then
      begin
        LReader.RestoreState(LPrevious);
        Break;
      end;
      Warn(Format(SQ3UnknownToken, [string(LToken), AFileName]));
    end;

    // read information for each frame
    LIndex := 0;
    while LIndex < Q3_MAX_ANIMATIONS do
    begin
      LToken := LReader.Next;
      if LToken = '' then
      begin
        if (LIndex >= Q3_TORSO_GETFLAG) and (LIndex <= Q3_TORSO_NEGATIVE) then
        begin
          LGesture := LAnimations[Q3_TORSO_GESTURE];
          LAnimations[LIndex].FirstFrame := LGesture.FirstFrame;
          LAnimations[LIndex].FrameLerp := LGesture.FrameLerp;
          LAnimations[LIndex].InitialLerp := LGesture.InitialLerp;
          LAnimations[LIndex].LoopFrames := LGesture.LoopFrames;
          LAnimations[LIndex].NumFrames := LGesture.NumFrames;
          LAnimations[LIndex].Reversed := False;
          LAnimations[LIndex].Flipflop := False;
          Inc(LIndex);
          Continue;
        end;
        Break;
      end;
      LAnimations[LIndex].FirstFrame := TStaticNumbers.Atoi(LToken);
      // leg only frames are adjusted to not count the upper body only frames
      if LIndex = Q3_LEGS_WALKCR then
        LSkip := LAnimations[Q3_LEGS_WALKCR].FirstFrame - LAnimations[Q3_TORSO_GESTURE].FirstFrame;
      if (LIndex >= Q3_LEGS_WALKCR) and (LIndex < Q3_TORSO_GETFLAG) then
        LAnimations[LIndex].FirstFrame := LAnimations[LIndex].FirstFrame - LSkip;

      LToken := LReader.Next;
      if LToken = '' then
        Break;
      LAnimations[LIndex].NumFrames := TStaticNumbers.Atoi(LToken);

      LAnimations[LIndex].Reversed := False;
      LAnimations[LIndex].Flipflop := False;
      // if numFrames is negative the animation is reversed
      if LAnimations[LIndex].NumFrames < 0 then
      begin
        LAnimations[LIndex].NumFrames := -LAnimations[LIndex].NumFrames;
        LAnimations[LIndex].Reversed := True;
      end;

      LToken := LReader.Next;
      if LToken = '' then
        Break;
      LAnimations[LIndex].LoopFrames := TStaticNumbers.Atoi(LToken);

      LToken := LReader.Next;
      if LToken = '' then
        Break;
      LFps := Single(TStaticNumbers.Atof(LToken));
      if LFps = 0 then
        LFps := 1;
      // 1000 / fps: a float division, truncated to an int
      LQuotient := Single(1000) / LFps;
      LAnimations[LIndex].FrameLerp := TQ3FloatMath.ToInt(Double(LQuotient));
      LAnimations[LIndex].InitialLerp := LAnimations[LIndex].FrameLerp;
      Inc(LIndex);
    end;

    if LIndex <> Q3_MAX_ANIMATIONS then
      ParseFailure(Format(SQ3AnimationParse, [AFileName]));

    // crouch backward animation
    LAnimations[Q3_LEGS_BACKCR] := LAnimations[Q3_LEGS_WALKCR];
    LAnimations[Q3_LEGS_BACKCR].Reversed := True;
    // walk backward animation
    LAnimations[Q3_LEGS_BACKWALK] := LAnimations[Q3_LEGS_WALK];
    LAnimations[Q3_LEGS_BACKWALK].Reversed := True;
    // flag moving fast
    LFlag.FirstFrame := 0;
    LFlag.NumFrames := 16;
    LFlag.LoopFrames := 16;
    LFlag.FrameLerp := 1000 div 15;
    LFlag.InitialLerp := 1000 div 15;
    LFlag.Reversed := False;
    LFlag.Flipflop := LAnimations[Q3_FLAG_RUN].Flipflop;
    LAnimations[Q3_FLAG_RUN] := LFlag;
    // flag not moving or moving slowly
    LFlag.FirstFrame := 16;
    LFlag.NumFrames := 5;
    LFlag.LoopFrames := 0;
    LFlag.FrameLerp := 1000 div 20;
    LFlag.InitialLerp := 1000 div 20;
    LFlag.Reversed := False;
    LFlag.Flipflop := LAnimations[Q3_FLAG_STAND].Flipflop;
    LAnimations[Q3_FLAG_STAND] := LFlag;
    // flag speeding up
    LFlag.FirstFrame := 16;
    LFlag.NumFrames := 5;
    LFlag.LoopFrames := 1;
    LFlag.FrameLerp := 1000 div 15;
    LFlag.InitialLerp := 1000 div 15;
    LFlag.Reversed := True;
    LFlag.Flipflop := LAnimations[Q3_FLAG_STAND2RUN].Flipflop;
    LAnimations[Q3_FLAG_STAND2RUN] := LFlag;

    for LIndex := 0 to Q3_MAX_TOTAL_ANIMATIONS - 1 do
      LConfig.SetAnimation(LIndex, LAnimations[LIndex]);
  finally
    LReader.Free;
  end;
end;

end.
