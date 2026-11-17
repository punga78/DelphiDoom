{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the cinematic calls on the RoQ player   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cin.c         }
{  (CIN_PlayCinematic, CIN_StopCinematic, CIN_RunCinematic, CIN_DrawCinematic,  }
{  CIN_SetExtents, CIN_HandleForVideo). Copyright (C) 1999-2005 Id Software,    }
{  Inc. This unit is derived from the Quake III Arena source code and is        }
{  therefore available under the GNU General Public License, version 2 or (at   }
{  your option) any later version.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientRoqCinematics;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Cinematic.Intf, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   What CIN_DrawCinematic hands to the renderer (re.DrawStretchRaw): the frame and the rectangle of the
  ///   cinematic on the 640 x 480 screen
  /// </summary>
  TQ3CinematicDraw = reference to procedure(AHandle, AX, AY, AWidth, AHeight: Integer; const AImage: TRoqPlayerImage);

  /// <summary>
  ///   IQ3HostCinematics on the RoQ decoder and player of Framework\Cinematic: 16 handles, the file read from the
  ///   game file system ("video/name" when the name has no slash), the frame chosen from the time of the clock of the
  ///   host. Differences from cl_cin.c: a cinematic that wants the game state (CIN_system) does not close the menu or
  ///   change cls.state; the sound goes nowhere (the decoder gets no audio sink); the clock is the one of the host,
  ///   not the scaled milliseconds of the client, so com_timescale does not change the speed
  /// </summary>
  TQ3RoqCinematics = class(TInterfacedObject, IQ3HostCinematics)
  strict private
    const
      MAX_VIDEO_HANDLES = 16;
      CIN_SYSTEM = 1;
      CIN_LOOP = 2;
      CIN_HOLD = 4;
    type
      TSlot = record
        FileName: string;
        Player: IRoqPlayer;
        Status: Integer;
        StartTime: Integer;
        Hold: Boolean;
        X, Y, Width, Height: Integer;
      end;
    var
      FFiles: IGameFileSystem;
      FTime: IQ3HostTime;
      FOnDraw: TQ3CinematicDraw;
      FSlots: array[0..MAX_VIDEO_HANDLES - 1] of TSlot;
    function Valid(AHandle: Integer): Boolean;
  public
    constructor Create(const AFiles: IGameFileSystem; const ATime: IQ3HostTime);
    function Play(const AName: AnsiString; AX, AY, AWidth, AHeight, ASystemBits: Integer): Integer;
    function Stop(AHandle: Integer): Integer;
    function Run(AHandle: Integer): Integer;
    procedure Draw(AHandle: Integer);
    procedure SetExtents(AHandle, AX, AY, AWidth, AHeight: Integer);
    property OnDraw: TQ3CinematicDraw read FOnDraw write FOnDraw;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types, DelphiDoom.Cinematic.Factory, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Client.Types;

resourcestring
  SNoFreeVideo = 'CIN_HandleForVideo: none free';

constructor TQ3RoqCinematics.Create(const AFiles: IGameFileSystem; const ATime: IQ3HostTime);
begin
  inherited Create;
  FFiles := AFiles;
  FTime := ATime;
end;

function TQ3RoqCinematics.Valid(AHandle: Integer): Boolean;
begin
  // a handle out of range, one that was never played and one that finished are "nothing": FMV_EOF in the C
  Result := (AHandle >= 0) and (AHandle < MAX_VIDEO_HANDLES) and Assigned(FSlots[AHandle].Player);
end;

function TQ3RoqCinematics.Play(const AName: AnsiString; AX, AY, AWidth, AHeight, ASystemBits: Integer): Integer;
var
  LName: string;
  LIndex: Integer;
  LData: TBytes;
  LDecoder: IRoqDecoder;
begin
  if (Pos('/', string(AName)) = 0) and (Pos('\', string(AName)) = 0) then
    LName := 'video/' + string(AName)
  else
    LName := string(AName);

  // the same file asked twice, with no game state involved: the handle it already has
  if (ASystemBits and CIN_SYSTEM) = 0 then
    for LIndex := 0 to MAX_VIDEO_HANDLES - 1 do
      if FSlots[LIndex].FileName = LName then
        Exit(LIndex);

  Result := -1;
  for LIndex := 0 to MAX_VIDEO_HANDLES - 1 do
    if FSlots[LIndex].FileName = '' then
    begin
      Result := LIndex;
      Break;
    end;
  if Result < 0 then
    raise EQ3HostException.Create(SNoFreeVideo);

  // a file that is not there, or that is not a RoQ file: -1 and the slot stays free
  if not FFiles.ReadFile(LName, LData) or (Length(LData) = 0) then
    Exit(-1);
  try
    LDecoder := TCinematicFactory.CreateDecoder(TCinematicFactory.CreateMemorySource(LData), nil);
  except
    on ECinematicException do
      Exit(-1);
  end;

  FSlots[Result].FileName := LName;
  FSlots[Result].Player := TCinematicFactory.CreatePlayer(LDecoder, (ASystemBits and CIN_LOOP) <> 0);
  FSlots[Result].Status := Q3_FMV_PLAY;
  FSlots[Result].StartTime := FTime.Milliseconds;
  FSlots[Result].Hold := (ASystemBits and CIN_HOLD) <> 0;
  FSlots[Result].X := AX;
  FSlots[Result].Y := AY;
  FSlots[Result].Width := AWidth;
  FSlots[Result].Height := AHeight;
end;

function TQ3RoqCinematics.Stop(AHandle: Integer): Integer;
begin
  if Valid(AHandle) then
  begin
    FSlots[AHandle].Status := Q3_FMV_EOF;
    FSlots[AHandle].FileName := '';
    FSlots[AHandle].Player := nil;
  end;
  Result := Q3_FMV_EOF;
end;

function TQ3RoqCinematics.Run(AHandle: Integer): Integer;
var
  LImage: TRoqPlayerImage;
begin
  if not Valid(AHandle) then
    Exit(Q3_FMV_EOF);
  if FSlots[AHandle].Status = Q3_FMV_PLAY then
  begin
    LImage := FSlots[AHandle].Player.ImageForTime(FTime.Milliseconds - FSlots[AHandle].StartTime);
    if LImage.Status = rpsEnded then
    begin
      // the end of the file: held on the last frame (FMV_IDLE) or over (FMV_EOF and the slot is free again)
      if FSlots[AHandle].Hold then
        FSlots[AHandle].Status := Q3_FMV_IDLE
      else
        Stop(AHandle);
    end;
  end;
  if not Valid(AHandle) then
    Exit(Q3_FMV_EOF);
  Result := FSlots[AHandle].Status;
end;

procedure TQ3RoqCinematics.Draw(AHandle: Integer);
var
  LImage: TRoqPlayerImage;
begin
  if not Valid(AHandle) or not Assigned(FOnDraw) then
    Exit;
  LImage := FSlots[AHandle].Player.ImageForTime(FTime.Milliseconds - FSlots[AHandle].StartTime);
  if Length(LImage.Pixels) = 0 then
    Exit;
  FOnDraw(AHandle, FSlots[AHandle].X, FSlots[AHandle].Y, FSlots[AHandle].Width, FSlots[AHandle].Height, LImage);
end;

procedure TQ3RoqCinematics.SetExtents(AHandle, AX, AY, AWidth, AHeight: Integer);
begin
  if not Valid(AHandle) then
    Exit;
  FSlots[AHandle].X := AX;
  FSlots[AHandle].Y := AY;
  FSlots[AHandle].Width := AWidth;
  FSlots[AHandle].Height := AHeight;
end;

end.
