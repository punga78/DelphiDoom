{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the sprite definitions                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_InstallSpriteLump and R_InitSpriteDefs of r_things.pas (from      }
{  r_things.c of Linux Doom)                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.SpriteDefs;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf,
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Builds the rotation matrixes of the sprites that account for the horizontally flipped
  ///   lumps. A lump is named with four characters for the actor, a letter for the frame and
  ///   a character for the rotation (0 for no rotations), optionally followed by the frame
  ///   and rotation of the flipped use of the same lump
  /// </summary>
  TRendererSpriteDefs = class(TInterfacedObject, IRendererSpriteDefs)
  strict private
    const
      MAX_FRAMES = 29;
    type
      /// <summary>The lump that the scan found, with the first four characters of its name</summary>
      TNamedLump = record
        Lump: Integer;
        Prefix: Integer;
        Name: TRendererLumpName;
      end;
  strict private
    FSource: IRendererSpriteSource;
    FLog: ILog;
    FFrames: array[0..MAX_FRAMES - 1] of TRendererSpriteFrame;
    FMaxFrame: Integer;
    FSpriteName: string;
    FFirstLump: Integer;
    procedure ResetFrames;
    class function RotationFromChar(const ACharacter: AnsiChar): Integer; static;
    function FrameLetter(AFrame: Integer): string;
    procedure ReportDeveloperError(const AText: string);
    procedure InstallLump(ALump, AFrame, ARotation: Integer; AFlipped: Boolean);
    procedure CheckFrames(AFrameCount: Integer);
    procedure CheckRotations(AFrame, ARotationCount: Integer);
    function ScanLumps: TArray<TNamedLump>;
  public
    constructor Create(const ASource: IRendererSpriteSource; const ALog: ILog);
    function Build(const ANames: TArray<Integer>): TArray<TRendererSpriteDefinition>;
  end;

implementation

const
  SWarningMultipleZeroRotation =
    'R_InitSprites(): Sprite %s frame %s has multip rot=0 lump'#13#10;
  SWarningRotationsAndZero =
    'R_InitSprites(): Sprite %s frame %s has rotations and a rot=0 lump'#13#10;
  SWarningTwoLumps =
    'R_InitSprites(): Sprite %s : %s : %s has two lumps mapped to it'#13#10;
  SWarningNoPatches = 'R_InitSprites(): No patches found for %s frame %s'#13#10;
  SErrorBadFrame =
    'R_InstallSpriteLump(): Bad frame characters in lump %d (frame = %d, rotation = %d)'#13#10;
  SErrorMissingRotations = 'R_InitSprites(): Sprite %s frame %s is missing rotations';
  SDeveloperHint =
    #13#10#13#10'Specify -devparm from the command line if you want this error to be ignored';

{ TRendererSpriteDefs }

constructor TRendererSpriteDefs.Create(const ASource: IRendererSpriteSource;
  const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FSource := ASource;
  FLog := ALog;
end;

procedure TRendererSpriteDefs.ResetFrames;
var
  LFrame: Integer;
  LRotation: Integer;
begin
  for LFrame := 0 to MAX_FRAMES - 1 do
  begin
    FFrames[LFrame].Rotate := -1;
    for LRotation := 0 to 31 do
    begin
      FFrames[LFrame].Lump[LRotation] := -1;
      FFrames[LFrame].Flip[LRotation] := False;
    end;
  end;
end;

class function TRendererSpriteDefs.RotationFromChar(const ACharacter: AnsiChar): Integer;
begin
  if ACharacter in ['0'..'9'] then
    Result := Ord(ACharacter) - Ord('0')
  else if ACharacter in ['A'..'W'] then
    Result := Ord(ACharacter) - Ord('A') + 10
  else
    Result := 33; // will trigger the error
end;

function TRendererSpriteDefs.FrameLetter(AFrame: Integer): string;
begin
  Result := Chr(Ord('A') + AFrame);
end;

procedure TRendererSpriteDefs.ReportDeveloperError(const AText: string);
begin
  if FSource.DeveloperMode then
    FLog.Warning(AText)
  else
    raise ERendererException.Create(AText + SDeveloperHint);
end;

procedure TRendererSpriteDefs.InstallLump(ALump, AFrame, ARotation: Integer;
  AFlipped: Boolean);
var
  LIndex: Integer;
  LRotationName: string;
begin
  if (AFrame < 0) or (AFrame >= MAX_FRAMES) or (ARotation < 0) or (ARotation > 32) then
  begin
    ReportDeveloperError(Format(SErrorBadFrame, [ALump, AFrame, ARotation]));
    // the old code went on and wrote outside of the table of the frames; the lump is skipped
    Exit;
  end;

  if AFrame > FMaxFrame then
    FMaxFrame := AFrame;

  if ARotation = 0 then
  begin
    // the lump should be used for all rotations
    if FFrames[AFrame].Rotate = 0 then
      FLog.DevWarning(Format(SWarningMultipleZeroRotation,
        [FSpriteName, FrameLetter(AFrame)]));

    if FFrames[AFrame].Rotate in [1..3] then
      FLog.DevWarning(Format(SWarningRotationsAndZero,
        [FSpriteName, FrameLetter(AFrame)]));

    FFrames[AFrame].Rotate := 0;
    for LIndex := 0 to 7 do
    begin
      FFrames[AFrame].Lump[LIndex] := ALump - FFirstLump;
      FFrames[AFrame].Flip[LIndex] := AFlipped;
    end;
    Exit;
  end;

  // the lump is only used for one rotation
  if FFrames[AFrame].Rotate = 0 then
    FLog.DevWarning(Format(SWarningRotationsAndZero, [FSpriteName, FrameLetter(AFrame)]));

  if ARotation in [1..8] then
    if FFrames[AFrame].Rotate = -1 then
      FFrames[AFrame].Rotate := 1;

  if ARotation in [9..16] then
    if (FFrames[AFrame].Rotate = -1) or (FFrames[AFrame].Rotate = 1) then
      FFrames[AFrame].Rotate := 2;

  if ARotation in [17..32] then
    if (FFrames[AFrame].Rotate = -1) or (FFrames[AFrame].Rotate = 1) or
      (FFrames[AFrame].Rotate = 2) then
      FFrames[AFrame].Rotate := 3;

  // make it 0 based
  Dec(ARotation);
  if FFrames[AFrame].Lump[ARotation] <> -1 then
  begin
    if ARotation > 9 then
      LRotationName := Chr(Ord('A') + ARotation - 10)
    else
      LRotationName := Chr(Ord('1') + ARotation);
    FLog.DevWarning(Format(SWarningTwoLumps,
      [FSpriteName, FrameLetter(AFrame), LRotationName]));
  end;

  FFrames[AFrame].Lump[ARotation] := ALump - FFirstLump;
  FFrames[AFrame].Flip[ARotation] := AFlipped;
end;

procedure TRendererSpriteDefs.CheckRotations(AFrame, ARotationCount: Integer);
var
  LRotation: Integer;
begin
  for LRotation := 0 to ARotationCount - 1 do
    if FFrames[AFrame].Lump[LRotation] = -1 then
      raise ERendererException.Create(Format(SErrorMissingRotations,
        [FSpriteName, FrameLetter(AFrame)]));
end;

procedure TRendererSpriteDefs.CheckFrames(AFrameCount: Integer);
var
  LFrame: Integer;
begin
  for LFrame := 0 to AFrameCount - 1 do
  begin
    case FFrames[LFrame].Rotate of
      -1:
        // no rotations were found for that frame at all
        FLog.Warning(Format(SWarningNoPatches, [FSpriteName, FrameLetter(LFrame)]));
      0:
        ; // only the first rotation is needed
      1:
        CheckRotations(LFrame, 8);
      2:
        CheckRotations(LFrame, 16);
      3:
        CheckRotations(LFrame, 32);
    end;
  end;
end;

function TRendererSpriteDefs.ScanLumps: TArray<TNamedLump>;
var
  LLump: Integer;
  LCount: Integer;
begin
  // the names are read once: the old code asked for them once per sprite
  SetLength(Result, FSource.LastLump - FFirstLump + 1);
  LCount := 0;
  for LLump := FFirstLump to FSource.LastLump do
  begin
    if FSource.IsPresent(LLump) then
    begin
      Result[LCount].Lump := LLump;
      Result[LCount].Name := FSource.LumpName(LLump);
      Result[LCount].Prefix := Integer(Cardinal(Byte(Result[LCount].Name[0])) or
        (Cardinal(Byte(Result[LCount].Name[1])) shl 8) or
        (Cardinal(Byte(Result[LCount].Name[2])) shl 16) or
        (Cardinal(Byte(Result[LCount].Name[3])) shl 24));
      Inc(LCount);
    end;
  end;
  SetLength(Result, LCount);
end;

function TRendererSpriteDefs.Build(const ANames: TArray<Integer>): TArray<TRendererSpriteDefinition>;
var
  LNamedLumps: TArray<TNamedLump>;
  LSprite: Integer;
  LIndex: Integer;
  LName: Integer;
  LFrame: Integer;
  LRotation: Integer;
begin
  SetLength(Result, Length(ANames));
  if Length(ANames) = 0 then
    Exit;

  FFirstLump := FSource.FirstLump;
  LNamedLumps := ScanLumps;

  // scan all the lump names for each of the names, noting the highest frame letter
  for LSprite := 0 to High(ANames) do
  begin
    LName := ANames[LSprite];
    FSpriteName := Chr(LName and $FF) + Chr((LName shr 8) and $FF) +
      Chr((LName shr 16) and $FF) + Chr((LName shr 24) and $FF);
    ResetFrames;
    FMaxFrame := -1;

    // scan the lumps, filling in the frames for whatever is found
    for LIndex := 0 to High(LNamedLumps) do
    begin
      if LNamedLumps[LIndex].Prefix <> LName then
        Continue;

      LFrame := Ord(LNamedLumps[LIndex].Name[4]) - Ord('A');
      LRotation := RotationFromChar(LNamedLumps[LIndex].Name[5]);
      InstallLump(FSource.PatchedLump(LNamedLumps[LIndex].Lump), LFrame, LRotation, False);

      if LNamedLumps[LIndex].Name[6] <> #0 then
      begin
        LFrame := Ord(LNamedLumps[LIndex].Name[6]) - Ord('A');
        LRotation := RotationFromChar(LNamedLumps[LIndex].Name[7]);
        InstallLump(LNamedLumps[LIndex].Lump, LFrame, LRotation, True);
      end;
    end;

    // check the frames that were found for completeness
    if FMaxFrame = -1 then
      Continue;

    Inc(FMaxFrame);
    CheckFrames(FMaxFrame);

    // keep the frames present
    SetLength(Result[LSprite].Frames, FMaxFrame);
    for LFrame := 0 to FMaxFrame - 1 do
      Result[LSprite].Frames[LFrame] := FFrames[LFrame];
  end;
end;

end.
