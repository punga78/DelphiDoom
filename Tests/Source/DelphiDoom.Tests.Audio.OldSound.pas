{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - the sound rules of s_sound.pas as they were before the  }
{  classes of Framework\Audio                                                  }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.OldSound;

// Angles and seeds wrap around, as in the engine (Doom32.inc has no overflow checks)
{$Q-}
{$R-}

interface

const
  OLD_FRACUNIT = 1 shl 16;
  OLD_S_CLIPPING_DIST = 1200 * $10000;
  OLD_S_CLOSE_DIST = 160 * $10000;
  OLD_S_ATTENUATOR = (OLD_S_CLIPPING_DIST - OLD_S_CLOSE_DIST) div OLD_FRACUNIT;
  OLD_NORM_SEP = 128;
  OLD_S_STEREO_SWING = 96 * $10000;
  OLD_ANGLETOFINESHIFT = 19;

type
  /// <summary>The {$IF DEFINED(DOOM)} / {$ELSEIF DEFINED(HERETIC)} / {$ELSE} of the old code</summary>
  TOldSoundGame = (osgDoom, osgHeretic, osgOther);

  /// <summary>The fields of mobj_t that the old code read</summary>
  TOldMobj = record
    x, y: Integer;
    angle, viewangle: Cardinal;
  end;
  POldMobj = ^TOldMobj;

  /// <summary>The field of sfxinfo_t that the old code read</summary>
  TOldSfxInfo = record
    priority: Integer;
    usefulness: Integer;
  end;
  POldSfxInfo = ^TOldSfxInfo;

  TOldChannel = record
    sfxinfo: POldSfxInfo;
    origin: Pointer;
    handle: Integer;
  end;

  TOldAngleFunction = function(const x1: Integer; const y1: Integer; const x2: Integer;
    const y2: Integer): Cardinal;

  /// <summary>
  ///   Copy of S_AdjustSoundParams, S_GetChannel and of the pitch hacks of
  ///   S_StartSoundAtVolume of IdTech1\Base\s_sound.pas at c4ce14f1 (issue #185). The globals of the
  ///   engine are fields; the three compilations of the game are the Game field; FixedMul is
  ///   written with a floor division; S_StopChannel only frees the channel and counts
  /// </summary>
  TOldSound = class(TObject)
  public
    Game: TOldSoundGame;
    gamemap: Integer;
    NeedsCompatibilityMode: Boolean;
    snd_SfxVolume: Integer;
    finesine: array[0..8191] of Integer;
    R_PointToAngle2: TOldAngleFunction;
    numChannels: Integer;
    channels: array of TOldChannel;
    /// <summary>players[consoleplayer].mo</summary>
    ConsolePlayerMo: Pointer;
    /// <summary>The channels that S_StopChannel was called for, in order</summary>
    Stopped: TArray<Integer>;
    function FixedMul(a, b: Integer): Integer;
    procedure S_StopChannel(cnum: Integer);
    function S_AdjustSoundParams(listener: POldMobj; source: POldMobj; vol: PInteger;
      sep: PInteger; pitch: PInteger): Boolean;
    function S_GetChannel(origin: Pointer; sfxinfo: POldSfxInfo): Integer;
    /// <summary>pitch := pitch + 8 - (M_Random and 15) with its limits</summary>
    function PitchSaw(pitch, random: Integer): Integer;
    /// <summary>pitch := pitch + 16 - (M_Random and 31) with its limits</summary>
    function PitchOther(pitch, random: Integer): Integer;
  end;

implementation

{ TOldSound }

function TOldSound.FixedMul(a, b: Integer): Integer;
var
  LProduct: Int64;
begin
  // the asm of m_fixed (imul, shrd 16): the floor of the product divided by 65536
  LProduct := Int64(a) * Int64(b);
  if LProduct >= 0 then
    Result := Integer(LProduct div OLD_FRACUNIT)
  else
    Result := Integer(-((-LProduct + (OLD_FRACUNIT - 1)) div OLD_FRACUNIT));
end;

procedure TOldSound.S_StopChannel(cnum: Integer);
begin
  if channels[cnum].sfxinfo <> nil then
  begin
    SetLength(Stopped, Length(Stopped) + 1);
    Stopped[High(Stopped)] := cnum;
    channels[cnum].sfxinfo.usefulness := channels[cnum].sfxinfo.usefulness - 1;
    channels[cnum].sfxinfo := nil;
  end;
end;

function TOldSound.S_AdjustSoundParams(listener: POldMobj; source: POldMobj; vol: PInteger;
  sep: PInteger; pitch: PInteger): Boolean;
var
  approx_dist: Integer;
  adx: Integer;
  ady: Integer;
  ad: Integer;
  angle: Cardinal;
  langle: Cardinal;
  clipped: Boolean;
begin
  // haleyjd 08/12/04: we cannot adjust a sound for a NULL listener
  if listener = nil then
  begin
    result := true;
    exit;
  end;

  // calculate the distance to sound origin
  //  and clip it if necessary
  adx := abs(listener.x - source.x);
  ady := abs(listener.y - source.y);

  if adx < ady then
    ad := adx
  else
    ad := ady;
  // From _GG1_ p.428. Appox. eucledian distance fast.
  approx_dist := adx + ady - ad div 2;

  // killough 11/98: handle zero-distance as special case
  if approx_dist = 0 then
  begin
    sep^ := OLD_NORM_SEP;
    vol^ := snd_SfxVolume;
    result := vol^ > 0;
    exit;
  end;

  case Game of
    osgDoom:
      clipped := ((gamemap <> 8) or not NeedsCompatibilityMode) and
        (approx_dist > OLD_S_CLIPPING_DIST);
    osgHeretic:
      clipped := (gamemap <> 8) and
        (approx_dist > OLD_S_CLIPPING_DIST);
  else
    clipped := approx_dist > OLD_S_CLIPPING_DIST;
  end;
  if clipped then
  begin
    result := false;
    exit;
  end;

  // angle of source to listener
  angle := R_PointToAngle2(listener.x, listener.y, source.x, source.y);

  langle := listener.angle + listener.viewangle;
  if angle > langle then
    angle := angle - langle
  else
    angle := angle + ($ffffffff - langle);

  angle := angle shr OLD_ANGLETOFINESHIFT;

  // stereo separation
  sep^ := OLD_NORM_SEP - (FixedMul(OLD_S_STEREO_SWING, finesine[angle]) div OLD_FRACUNIT);

  // volume calculation
  if approx_dist < OLD_S_CLOSE_DIST then
  begin
    vol^ := snd_SfxVolume;
  end
  else if ((Game = osgDoom) and (gamemap = 8) and NeedsCompatibilityMode) or
    ((Game = osgHeretic) and (gamemap = 8)) then
  begin
    if approx_dist > OLD_S_CLIPPING_DIST then
      approx_dist := OLD_S_CLIPPING_DIST;

    vol^ := 15 + ((snd_SfxVolume - 15) *
      ((OLD_S_CLIPPING_DIST - approx_dist) div OLD_FRACUNIT)) div OLD_S_ATTENUATOR;
  end
  else
  begin
    // distance effect
    vol^ := (snd_SfxVolume * ((OLD_S_CLIPPING_DIST - approx_dist) div OLD_FRACUNIT)) div
              OLD_S_ATTENUATOR;
  end;

  result := vol^ > 0;
end;

function TOldSound.S_GetChannel(origin: Pointer; sfxinfo: POldSfxInfo): Integer;
var
  // channel number to use
  cnum: integer;
  listener: pointer;
begin
  // Find an open channel
  cnum := 0;
  while cnum < numChannels do
  begin
    if channels[cnum].sfxinfo = nil then
      break
    else if (origin <> nil) and (channels[cnum].origin = origin) then
    begin
      S_StopChannel(cnum);
      break;
    end;
    inc(cnum);
  end;

  // None available
  if cnum = numChannels then
  begin
    // Look for lower priority
    cnum := 0;
    while cnum < numChannels do
    begin
      if channels[cnum].sfxinfo.priority > sfxinfo.priority then
        break;
      inc(cnum);
    end;

    if cnum = numChannels then
    begin
      cnum := 0;
      while cnum < numChannels do
      begin
        if channels[cnum].sfxinfo.priority = sfxinfo.priority then
          break;
        inc(cnum);
      end;
    end;

    if cnum = numChannels then
    begin
      listener := ConsolePlayerMo;
      if (origin = listener) or (origin = nil) then
      begin
        cnum := 0;
        while cnum < numChannels do
        begin
          if (channels[cnum].origin <> nil) and (channels[cnum].origin <> listener) then
            break;
          inc(cnum);
        end;
      end;
    end;

    if cnum = numChannels then
    begin
      // FUCK!  No lower priority.  Sorry, Charlie.
      result := -1;
      exit;
    end
    else
    begin
      // Otherwise, kick out lower priority.
      S_StopChannel(cnum);
    end;
  end;

  // channel is decided to be cnum.
  channels[cnum].sfxinfo := sfxinfo;
  channels[cnum].origin := origin;

  result := cnum;
end;

function TOldSound.PitchSaw(pitch, random: Integer): Integer;
begin
  pitch := pitch + 8 - (random and 15);

  if pitch < 0 then
    pitch := 0
  else if pitch > 255 then
    pitch := 255;
  Result := pitch;
end;

function TOldSound.PitchOther(pitch, random: Integer): Integer;
begin
  pitch := pitch + 16 - (random and 31);

  if pitch < 0 then
    pitch := 0
  else if pitch > 255 then
    pitch := 255;
  Result := pitch;
end;

end.
