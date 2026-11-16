{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixBriefingPlayer                            }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the RB_Cmd* procedures and of RB_Ticker (radix_briefing.pas of      }
{  Rad-X)                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Briefing.Player;

interface

uses
  DelphiDoom.Radix.Briefing.Types;

type
  /// <summary>
  ///   Runs the commands of a mission briefing, one call of Tick for every tic of the game. At
  ///   every tic the commands that are still active run from the first one, until one of them
  ///   waits (a text that is being typed, a delay, the wait for the pilot); when none waits the
  ///   briefing is finished. The pilot (fire or use) completes the text or the delay that is
  ///   waiting, or ends the wait. The commands for the map go to the IRadixBriefingMap given to
  ///   the constructor (it may be nil: a briefing without a map)
  /// </summary>
  TRadixBriefingPlayer = class
  public const
    TICS_PER_SECOND = 35;
    DEFAULT_SCROLL_SPEED = 128;
    MAX_SCROLL_SPEED = 256;
    /// <summary>Nearer than this to its target the map slows down</summary>
    SCROLL_BRAKE_DISTANCE = 1024;
    MIN_SCROLL_SPEED = 16;
    /// <summary>What an animation adds to its clock at every tic</summary>
    ANIMATION_STEP = 3;
  strict private type
    TSlot = record
      Command: TRadixBriefingCommand;
      Tic: Integer;
      Active: Boolean;
    end;
  strict private
    FSlots: TArray<TSlot>;
    FMap: IRadixBriefingMap;
    FMessage: string;
    FPicture: string;
    FMapPosition: Integer;
    FMapTarget: Integer;
    FScrollSpeed: Integer;
    FFinished: Boolean;
    FAccelerate: Boolean;
    procedure ScrollMap;
    /// <summary>False when the command waits: the commands after it do not run at this tic</summary>
    function Run(var ASlot: TSlot): Boolean;
  public
    constructor Create(const ACommands: TArray<TRadixBriefingCommand>; const AMap: IRadixBriefingMap);
    /// <summary>One tic; APilotActs is true at the tic in which fire or use goes down</summary>
    procedure Tick(APilotActs: Boolean);
    /// <summary>What the text window shows (lines end with CR LF)</summary>
    property Message: string read FMessage;
    /// <summary>The picture of the animation window ('' = none)</summary>
    property Picture: string read FPicture;
    /// <summary>Where the map is scrolled to (a coordinate of RADIX.DAT)</summary>
    property MapPosition: Integer read FMapPosition;
    property Finished: Boolean read FFinished;
  end;

implementation

uses
  System.SysUtils;

{ TRadixBriefingPlayer }

constructor TRadixBriefingPlayer.Create(const ACommands: TArray<TRadixBriefingCommand>;
  const AMap: IRadixBriefingMap);
var
  LIndex: Integer;
begin
  inherited Create;
  FMap := AMap;
  FScrollSpeed := DEFAULT_SCROLL_SPEED;
  SetLength(FSlots, Length(ACommands));
  for LIndex := 0 to High(ACommands) do
  begin
    FSlots[LIndex].Command := ACommands[LIndex];
    FSlots[LIndex].Tic := 0;
    FSlots[LIndex].Active := True;
  end;
end;

procedure TRadixBriefingPlayer.ScrollMap;
var
  LSpeed: Integer;
  LDistance: Integer;
begin
  LDistance := Abs(FMapPosition - FMapTarget);
  if LDistance = 0 then
    Exit;
  LSpeed := FScrollSpeed;
  if LDistance < SCROLL_BRAKE_DISTANCE then
  begin
    LSpeed := LSpeed * LDistance div SCROLL_BRAKE_DISTANCE;
    if LSpeed < MIN_SCROLL_SPEED then
      LSpeed := MIN_SCROLL_SPEED;
  end;
  if LSpeed > LDistance then
    LSpeed := LDistance;
  if FMapPosition > FMapTarget then
    Dec(FMapPosition, LSpeed)
  else
    Inc(FMapPosition, LSpeed);
end;

function TRadixBriefingPlayer.Run(var ASlot: TSlot): Boolean;
var
  LFrames: Integer;
  LName: string;
begin
  Result := True;
  case ASlot.Command.Kind of
    bckClearAnimWindow:
      begin
        FPicture := '';
        ASlot.Active := False;
      end;
    bckClearTextWindow:
      begin
        FMessage := '';
        ASlot.Active := False;
      end;
    bckDelay:
      begin
        if FAccelerate then
        begin
          ASlot.Tic := ASlot.Command.Numbers[0];
          FAccelerate := False;
        end;
        if ASlot.Tic < ASlot.Command.Numbers[0] then
          Inc(ASlot.Tic);
        ASlot.Active := ASlot.Tic < ASlot.Command.Numbers[0];
        Result := not ASlot.Active;
      end;
    bckDisplayAnimation:
      begin
        // Numbers[2] is the picture that is shown, from 1 (-1 in the script: not started). The
        // command stays active: the animation goes on while the commands after it run
        if ASlot.Command.Numbers[2] = -1 then
          ASlot.Command.Numbers[2] := 1;
        if ASlot.Tic < ASlot.Command.Numbers[1] then
          Inc(ASlot.Tic, ANIMATION_STEP)
        else
        begin
          ASlot.Tic := 0;
          LFrames := ASlot.Command.Numbers[0];
          if LFrames > 0 then
          begin
            if ASlot.Command.Numbers[2] >= LFrames then
              ASlot.Command.Numbers[2] := 1
            else
              Inc(ASlot.Command.Numbers[2]);
          end;
        end;
        // the name of the first picture ends with 1: the number of the picture takes its place
        LName := ASlot.Command.Text;
        SetLength(LName, Length(LName) - 1);
        FPicture := LName + IntToStr(ASlot.Command.Numbers[2]);
      end;
    bckDisplayImage:
      FPicture := ASlot.Command.Text;
    bckMapPrint:
      if Assigned(FMap) and FMap.IsReady then
      begin
        FMap.Print(ASlot.Command.Numbers[0], ASlot.Command.Numbers[1], ASlot.Command.Text);
        ASlot.Active := False;
      end;
    bckPointMap:
      if Assigned(FMap) and FMap.IsReady then
      begin
        FMap.MarkPoint(ASlot.Command.Numbers[0], ASlot.Command.Numbers[1], ASlot.Command.Numbers[2],
          ASlot.Command.Numbers[3], ASlot.Command.Numbers[4]);
        ASlot.Active := False;
      end;
    bckPrint:
      begin
        if FAccelerate then
        begin
          // the text all at once (what was typed of it so far is replaced, as in Rad-X)
          ASlot.Tic := Length(ASlot.Command.Text);
          FMessage := ASlot.Command.Text;
          FAccelerate := False;
        end;
        if ASlot.Tic < Length(ASlot.Command.Text) then
        begin
          Inc(ASlot.Tic);
          FMessage := FMessage + ASlot.Command.Text[ASlot.Tic];
          ASlot.Active := True;
        end
        else
          ASlot.Active := False;
        Result := not ASlot.Active;
      end;
    bckScrollMapX:
      begin
        FMapTarget := ASlot.Command.Numbers[0];
        FScrollSpeed := Abs(FMapPosition - FMapTarget) div (2 * TICS_PER_SECOND);
        if FScrollSpeed > MAX_SCROLL_SPEED then
          FScrollSpeed := MAX_SCROLL_SPEED;
        ASlot.Active := False;
      end;
    bckWaitAction:
      if FAccelerate then
      begin
        FAccelerate := False;
        ASlot.Active := False;
      end
      else
        Result := False;
  else
    // bckNextPoint, bckShowScreen: nothing to do (they stay active, as in Rad-X)
  end;
end;

procedure TRadixBriefingPlayer.Tick(APilotActs: Boolean);
var
  LIndex: Integer;
begin
  if FFinished then
    Exit;
  if APilotActs then
    FAccelerate := True;
  ScrollMap;
  for LIndex := 0 to High(FSlots) do
    if FSlots[LIndex].Active then
      if not Run(FSlots[LIndex]) then
        Exit;
  FFinished := True;
end;

end.
