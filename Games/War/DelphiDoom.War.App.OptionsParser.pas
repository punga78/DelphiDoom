{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - reads the command line of Warcraft32              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.OptionsParser;

interface

uses
  System.SysUtils, DelphiDoom.War.App.Options;

type
  /// <summary>
  ///   Turns the arguments of the program (without its name) into TWarAppOptions. A mistake is not an exception: the
  ///   program writes the usage and ends with code 2, so the parser says what is wrong and returns False
  /// </summary>
  TWarAppOptionsParser = class
  strict private
    class function TryNumber(const AText: string; AMinimum, AMaximum: Int64; out AValue: Int64): Boolean; static;
  public
    /// <summary>
    ///   False when an option is unknown, lacks its value or has a value that is not allowed; AError says which.
    ///   The names of the options are not case sensitive
    /// </summary>
    class function TryParse(const AArguments: TArray<string>; out AOptions: TWarAppOptions;
      out AError: string): Boolean; static;
  end;

implementation

uses
  DelphiDoom.War.Level.Types;

resourcestring
  SWarOptionUnknown = 'Unknown option %s';
  SWarOptionNeedsValue = 'The option %s needs a value';
  SWarOptionBadNumber = 'The option %s needs a whole number from %d to %d, not "%s"';
  SWarOptionBadMusic = 'The option -music needs midi or none, not "%s"';
  SWarOptionBadRace ='The option -play needs human or orc and the number of the mission (1..12), not "%s"';

{ TWarAppOptionsParser }

class function TWarAppOptionsParser.TryNumber(const AText: string; AMinimum, AMaximum: Int64;
  out AValue: Int64): Boolean;
begin
  Result := TryStrToInt64(AText, AValue) and (AValue >= AMinimum) and (AValue <= AMaximum);
end;

class function TWarAppOptionsParser.TryParse(const AArguments: TArray<string>; out AOptions: TWarAppOptions;
  out AError: string): Boolean;
var
  LIndex: Integer;
  LName: string;
  LNumber: Int64;

  function TakeValue(out AValue: string): Boolean;
  begin
    AValue := '';
    Result := LIndex < High(AArguments);
    if Result then
    begin
      Inc(LIndex);
      AValue := AArguments[LIndex];
    end
    else
      AError := Format(SWarOptionNeedsValue, [LName]);
  end;

  function TakeNumber(AMinimum, AMaximum: Int64): Boolean;
  var
    LText: string;
  begin
    Result := TakeValue(LText);
    if Result then
    begin
      Result := TryNumber(LText, AMinimum, AMaximum, LNumber);
      if not Result then
        AError := Format(SWarOptionBadNumber, [LName, AMinimum, AMaximum, LText]);
    end;
  end;

  function TakeText(var ATarget: string): Boolean;
  var
    LText: string;
  begin
    Result := TakeValue(LText);
    if Result then
      ATarget := LText;
  end;

  function TakePlay: Boolean;
  var
    LRace: string;
    LMission: string;
  begin
    Result := TakeValue(LRace) and TakeValue(LMission);
    if not Result then
      Exit;
    LRace := LRace.ToLowerInvariant;
    if (LRace = 'human') or (LRace = 'humans') then
      AOptions.PlayRace := wraHumans
    else if (LRace = 'orc') or (LRace = 'orcs') then
      AOptions.PlayRace := wraOrcs
    else
      Result := False;
    if Result then
      Result := TryNumber(LMission, 1, 12, LNumber);
    if Result then
      AOptions.PlayMission := Integer(LNumber)
    else
      AError := Format(SWarOptionBadRace, [LRace + ' ' + LMission]);
  end;

  function TakeMusic: Boolean;
  var
    LMode: string;
  begin
    Result := TakeValue(LMode);
    if not Result then
      Exit;
    LMode := LMode.ToLowerInvariant;
    if LMode = 'midi' then
      AOptions.Music := wmmMidi
    else if LMode = 'none' then
      AOptions.Music := wmmNone
    else
    begin
      Result := False;
      AError := Format(SWarOptionBadMusic, [LMode]);
    end;
  end;

begin
  AOptions := TWarAppOptions.Standard;
  AError := '';
  LIndex := 0;
  Result := True;
  while Result and (LIndex <= High(AArguments)) do
  begin
    LName := AArguments[LIndex].ToLowerInvariant;
    if LName = '-data' then
      Result := TakeText(AOptions.DataFolder)
    else if LName = '-fonts' then
      Result := TakeText(AOptions.FontFolder)
    else if LName = '-script' then
      Result := TakeText(AOptions.ScriptPath)
    else if LName = '-shot' then
      Result := TakeText(AOptions.ShotPath)
    else if LName = '-load' then
      Result := TakeText(AOptions.LoadPath)
    else if LName = '-save' then
      Result := TakeText(AOptions.SavePath)
    else if LName = '-play' then
      Result := TakePlay
    else if LName = '-music' then
      Result := TakeMusic
    else if LName = '-seed' then
    begin
      Result := TakeNumber(0, High(Cardinal));
      if Result then
        AOptions.Seed := Cardinal(LNumber);
    end
    else if LName = '-quitafter' then
    begin
      Result := TakeNumber(0, High(Integer));
      if Result then
        AOptions.QuitAfterFrames := Integer(LNumber);
    end
    else if LName = '-scale' then
    begin
      Result := TakeNumber(1, WAR_APP_MAX_SCALE);
      if Result then
        AOptions.Scale := Integer(LNumber);
    end
    else if LName = '-headless' then
      AOptions.Headless := True
    else if LName = '-nosound' then
      AOptions.NoSound := True
    else if LName = '-nointro' then
      AOptions.NoIntroduction := True
    else if LName = '-audiostats' then
      AOptions.AudioStatistics := True
    else if (LName = '-help') or (LName = '-?') or (LName = '/?') then
      AOptions.ShowHelp := True
    else
    begin
      AError := Format(SWarOptionUnknown, [AArguments[LIndex]]);
      Result := False;
    end;
    Inc(LIndex);
  end;
end;

end.
