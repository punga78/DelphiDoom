{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the parameters of the command line of the original}
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  US_CheckParm of id_us.c and the ParmStrings loops of id_in.c, id_rf.c,       }
{  id_sd.c, id_us.c and id_vw.c                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Parameters;

interface

uses
  System.SysUtils;

type
  /// <summary>What the parameters of the command line of the original say, as each manager reads them</summary>
  TKeenOriginalParameters = record
    /// <summary>"nojoys" (IN_Startup): the joysticks are not looked for</summary>
    NoJoysticks: Boolean;
    /// <summary>"nomouse" (IN_Startup): the mouse is not looked for</summary>
    NoMouse: Boolean;
    /// <summary>"comp" (RF_Startup): the screens never go past the end of the video memory</summary>
    Compatibility: Boolean;
    /// <summary>"noal" (SD_Startup): the AdLib card is not detected, so the game has none</summary>
    NoAdLibDetection: Boolean;
    /// <summary>"nosb" (SD_Startup): no SoundBlaster detection. This port has no SoundBlaster, so it changes nothing</summary>
    NoSoundBlasterDetection: Boolean;
    /// <summary>"nodr" (SD_Startup): the drive of the disk is left on. A PC speaker and a card have no drive: nothing changes</summary>
    LeaveDriveOn: Boolean;
    /// <summary>"noss" (SD_Startup): no Sound Source detection. This port has no Sound Source, so it changes nothing</summary>
    NoSoundSourceDetection: Boolean;
    /// <summary>"sst" (SD_Startup): the Sound Source is a Tandy one; nothing changes here</summary>
    SoundSourceTandy: Boolean;
    /// <summary>"ss1", "ss2", "ss3" (SD_Startup): the Sound Source is at LPT1, LPT2 or LPT3; 0 when not said</summary>
    SoundSourcePort: Integer;
    /// <summary>
    ///   "TEDLEVEL n" (US_Startup): launched from the level editor; -1 when not said. The code that uses it
    ///   (TEDDeath and the launch of the level) is compiled out of the game (FRILLS is not defined), and the text
    ///   screen that it silences does not exist here: nothing changes
    /// </summary>
    TedLevel: Integer;
    /// <summary>"HIDDENCARD" (VW_Startup): the video card is taken for an EGA without asking it; nothing changes here</summary>
    HiddenCard: Boolean;
  end;

  /// <summary>
  ///   The parameters that the original reads from its command line, case insensitive and with whatever
  ///   punctuation in front, as US_CheckParm matches them
  /// </summary>
  TKeenParameters = class
  public
    /// <summary>
    ///   US_CheckParm: the index of the first string that AParameter starts with, ignoring the case and what is not
    ///   a letter at the beginning of AParameter ("-NoMouse" and "/nomouse" are "nomouse"); -1 if none. Like the
    ///   C, a string matches when the parameter only begins with it ("nomouse2" is "nomouse"). A string that is
    ///   empty ends the list. Difference from the C: a parameter without a letter (the C runs past its end) is -1
    /// </summary>
    class function Check(const AParameter: string; const AStrings: array of string): Integer; static;
    /// <summary>True if the original reads this parameter</summary>
    class function IsOriginal(const AParameter: string): Boolean; static;
    /// <summary>True if the parameter is followed by a value (TEDLEVEL)</summary>
    class function TakesValue(const AParameter: string): Boolean; static;
    /// <summary>The loops of IN_Startup, RF_Startup, SD_Startup, US_Startup and VW_Startup over the arguments</summary>
    class function Parse(const AArguments: array of string): TKeenOriginalParameters; static;
    /// <summary>
    ///   main of kd_main.c: when the first argument is "/VER" or "/?" (stricmp: any case) the program writes a text and
    ///   ends. Gives the text (lines with LF, as printf writes them), or false for any other argument
    /// </summary>
    class function TryInformation(const AFirstArgument: string; out AText: string): Boolean; static;
  end;

implementation

const
  // the ParmStrings of each manager, in the order of the C
  INPUT_PARAMETERS: array[0..1] of string = ('nojoys', 'nomouse');
  REFRESH_PARAMETERS: array[0..0] of string = ('comp');
  SOUND_PARAMETERS: array[0..7] of string = ('noal', 'nosb', 'nodr', 'noss', 'sst', 'ss1', 'ss2', 'ss3');
  USER_PARAMETERS: array[0..0] of string = ('TEDLEVEL');
  VIDEO_PARAMETERS: array[0..0] of string = ('HIDDENCARD');

// atoi of the C: blanks, a sign, the numerals; what is not a number is 0
function Atoi(const AText: string): Integer;
var
  LIndex: Integer;
  LNegative: Boolean;
begin
  Result := 0;
  LIndex := 1;
  while (LIndex <= Length(AText)) and CharInSet(AText[LIndex], [' ', #9, #10, #11, #12, #13]) do
    Inc(LIndex);
  LNegative := False;
  if (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['+', '-']) then
  begin
    LNegative := AText[LIndex] = '-';
    Inc(LIndex);
  end;
  while (LIndex <= Length(AText)) and (AText[LIndex] >= '0') and (AText[LIndex] <= '9') do
  begin
    Result := Result * 10 + (Ord(AText[LIndex]) - Ord('0'));
    Inc(LIndex);
  end;
  if LNegative then
    Result := -Result;
end;

function IsAscii(ACharacter: Char): Boolean; inline;
begin
  Result := Ord(ACharacter) < 128;
end;

function IsAlpha(ACharacter: Char): Boolean; inline;
begin
  Result := IsAscii(ACharacter) and (((ACharacter >= 'a') and (ACharacter <= 'z')) or
    ((ACharacter >= 'A') and (ACharacter <= 'Z')));
end;

function LowerAscii(ACharacter: Char): Char; inline;
begin
  if (ACharacter >= 'A') and (ACharacter <= 'Z') then
    Result := Char(Ord(ACharacter) + 32)
  else
    Result := ACharacter;
end;

{ TKeenParameters }

class function TKeenParameters.TryInformation(const AFirstArgument: string; out AText: string): Boolean;
begin
  Result := True;
  if SameText(AFirstArgument, '/VER') then
    AText := #10'Keen Dreams version 1.93  (Rev 1)'#10 +
      'developed for use with 100% IBM compatibles'#10 +
      'that have 640K memory, DOS version 3.3 or later,'#10 +
      'and an EGA or VGA display adapter.'#10 +
      'Copyright 1991-1993 Softdisk Publishing.'#10 +
      'Commander Keen is a trademark of Id Software.'#10
  else if SameText(AFirstArgument, '/?') then
    AText := #10'Keen Dreams version 1.93'#10 +
      'Copyright 1991-1993 Softdisk Publishing.'#10#10 +
      'Commander Keen is a trademark of Id Software.'#10 +
      'Type KDREAMS from the DOS prompt to run.'#10#10 +
      'KDREAMS /COMP for SVGA compatibility mode'#10 +
      'KDREAMS /NODR stops program hang with the drive still on'#10 +
      'KDREAMS /NOAL disables AdLib and Sound Blaster detection'#10 +
      'KDREAMS /NOSB disables Sound Blaster detection'#10 +
      'KDREAMS /NOJOYS ignores joystick'#10 +
      'KDREAMS /NOMOUSE ignores mouse'#10 +
      'KDREAMS /HIDDENCARD overrides video card detection'#10 +
      'KDREAMS /VER  for version and compatibility information'#10 +
      'KDREAMS /? for this help information'#10
  else
  begin
    AText := '';
    Result := False;
  end;
end;

class function TKeenParameters.Check(const AParameter: string; const AStrings: array of string): Integer;
var
  LStart: Integer;
  LIndex: Integer;
  LPosition: Integer;
  LMatches: Boolean;
begin
  Result := -1;
  LStart := 1;
  while (LStart <= Length(AParameter)) and not IsAlpha(AParameter[LStart]) do
    Inc(LStart);
  if LStart > Length(AParameter) then
    Exit;
  for LIndex := Low(AStrings) to High(AStrings) do
  begin
    // an empty string is the end of the list
    if AStrings[LIndex] = '' then
      Exit;
    LMatches := True;
    for LPosition := 1 to Length(AStrings[LIndex]) do
      if (LStart + LPosition - 1 > Length(AParameter)) or
        (LowerAscii(AStrings[LIndex][LPosition]) <> LowerAscii(AParameter[LStart + LPosition - 1])) then
      begin
        LMatches := False;
        Break;
      end;
    if LMatches then
      Exit(LIndex - Low(AStrings));
  end;
end;

class function TKeenParameters.IsOriginal(const AParameter: string): Boolean;
begin
  Result := (Check(AParameter, INPUT_PARAMETERS) >= 0) or (Check(AParameter, REFRESH_PARAMETERS) >= 0) or
    (Check(AParameter, SOUND_PARAMETERS) >= 0) or (Check(AParameter, USER_PARAMETERS) >= 0) or
    (Check(AParameter, VIDEO_PARAMETERS) >= 0);
end;

class function TKeenParameters.TakesValue(const AParameter: string): Boolean;
begin
  Result := Check(AParameter, USER_PARAMETERS) >= 0;
end;

class function TKeenParameters.Parse(const AArguments: array of string): TKeenOriginalParameters;
var
  LIndex: Integer;
  LTedDecided: Boolean;
begin
  LTedDecided := False;
  Result := Default(TKeenOriginalParameters);
  Result.TedLevel := -1;
  for LIndex := Low(AArguments) to High(AArguments) do
  begin
    case Check(AArguments[LIndex], INPUT_PARAMETERS) of
      0: Result.NoJoysticks := True;
      1: Result.NoMouse := True;
    end;
    if Check(AArguments[LIndex], REFRESH_PARAMETERS) = 0 then
      Result.Compatibility := True;
    case Check(AArguments[LIndex], SOUND_PARAMETERS) of
      0: Result.NoAdLibDetection := True;
      1: Result.NoSoundBlasterDetection := True;
      2: Result.LeaveDriveOn := True;
      3: Result.NoSoundSourceDetection := True;
      4: Result.SoundSourceTandy := True;
      5: Result.SoundSourcePort := 1;
      6: Result.SoundSourcePort := 2;
      7: Result.SoundSourcePort := 3;
    end;
    // US_Startup: the number after TEDLEVEL, atoi, and a negative one is no level; the first TEDLEVEL decides
    if (Check(AArguments[LIndex], USER_PARAMETERS) = 0) and not LTedDecided and (LIndex < High(AArguments)) then
    begin
      // a negative number ends the search (the C breaks out of its loop)
      LTedDecided := True;
      if Atoi(AArguments[LIndex + 1]) >= 0 then
        Result.TedLevel := Atoi(AArguments[LIndex + 1]);
    end;
    if Check(AArguments[LIndex], VIDEO_PARAMETERS) = 0 then
      Result.HiddenCard := True;
  end;
end;

end.
