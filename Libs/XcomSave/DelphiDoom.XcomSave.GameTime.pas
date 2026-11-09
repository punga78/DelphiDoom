{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the date and time of the game          }
{  (GameTime)                                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.GameTime;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>TimeTrigger: what the clock reached when it advanced</summary>
  TXcomTimeTrigger = (ttFiveSeconds, ttTenMinutes, ttThirtyMinutes, ttHour, ttDay, ttMonth);

  /// <summary>
  ///   The date and time of the game, advanced five seconds at a time (GameTime). The values are plain numbers
  ///   that a saved game can hold out of range; the functions that index a table (the names of the weekday and of
  ///   the month, advance) raise EXcomSaveRangeException then (undefined in the C++)
  /// </summary>
  TXcomGameTime = class
  strict private
    FSecond: Integer;
    FMinute: Integer;
    FHour: Integer;
    FWeekday: Integer;
    FDay: Integer;
    FMonth: Integer;
    FYear: Integer;
  public
    constructor Create(AWeekday, ADay, AMonth, AYear, AHour, AMinute, ASecond: Integer);
    procedure Load(const ANode: IYamlNode);
    /// <summary>The node of the saved game</summary>
    function Save: IYamlNode;
    /// <summary>
    ///   advance: five seconds more; the result says the biggest unit that changed. A month outside 1..12
    ///   is EXcomSaveRangeException
    /// </summary>
    function Advance: TXcomTimeTrigger;
    property Second: Integer read FSecond;
    property Minute: Integer read FMinute;
    property Hour: Integer read FHour;
    property Weekday: Integer read FWeekday;
    property Day: Integer read FDay;
    property Month: Integer read FMonth;
    property Year: Integer read FYear;
    /// <summary>The key of the text of the weekday (STR_SUNDAY...)</summary>
    function WeekdayString: string;
    /// <summary>The key of the text of the month (STR_JAN...)</summary>
    function MonthString: string;
    /// <summary>The key of the text of the day (STR_DATE_FIRST...), to be formatted with the number of the day</summary>
    function DayStringKey: string;
    /// <summary>getDaylight: the fraction of the day since 6 in the morning, 0..1</summary>
    function Daylight: Double;
  end;

  /// <summary>An index that the game uses to read a table is outside it</summary>
  EXcomSaveRangeException = class(Exception);

implementation

const
  WEEKDAYS: array[0..6] of string = ('STR_SUNDAY', 'STR_MONDAY', 'STR_TUESDAY', 'STR_WEDNESDAY', 'STR_THURSDAY',
    'STR_FRIDAY', 'STR_SATURDAY');
  MONTHS: array[0..11] of string = ('STR_JAN', 'STR_FEB', 'STR_MAR', 'STR_APR', 'STR_MAY', 'STR_JUN', 'STR_JUL',
    'STR_AUG', 'STR_SEP', 'STR_OCT', 'STR_NOV', 'STR_DEC');
  SBadMonth = 'Xcom: the month %d is not between 1 and 12';
  SBadWeekday = 'Xcom: the weekday %d is not between 1 and 7';

{ TXcomGameTime }

constructor TXcomGameTime.Create(AWeekday, ADay, AMonth, AYear, AHour, AMinute, ASecond: Integer);
begin
  inherited Create;
  FWeekday := AWeekday;
  FDay := ADay;
  FMonth := AMonth;
  FYear := AYear;
  FHour := AHour;
  FMinute := AMinute;
  FSecond := ASecond;
end;

procedure TXcomGameTime.Load(const ANode: IYamlNode);
begin
  FSecond := TXcomNodeReader.ReadInteger(ANode, 'second', FSecond);
  FMinute := TXcomNodeReader.ReadInteger(ANode, 'minute', FMinute);
  FHour := TXcomNodeReader.ReadInteger(ANode, 'hour', FHour);
  FWeekday := TXcomNodeReader.ReadInteger(ANode, 'weekday', FWeekday);
  FDay := TXcomNodeReader.ReadInteger(ANode, 'day', FDay);
  FMonth := TXcomNodeReader.ReadInteger(ANode, 'month', FMonth);
  FYear := TXcomNodeReader.ReadInteger(ANode, 'year', FYear);
end;

function TXcomGameTime.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'second', FSecond);
  TXcomNodeWriter.SetInteger(Result, 'minute', FMinute);
  TXcomNodeWriter.SetInteger(Result, 'hour', FHour);
  TXcomNodeWriter.SetInteger(Result, 'weekday', FWeekday);
  TXcomNodeWriter.SetInteger(Result, 'day', FDay);
  TXcomNodeWriter.SetInteger(Result, 'month', FMonth);
  TXcomNodeWriter.SetInteger(Result, 'year', FYear);
end;

function TXcomGameTime.Advance: TXcomTimeTrigger;
var
  LMonthDays: array[0..11] of Integer;
begin
  LMonthDays[0] := 31;
  LMonthDays[1] := 28;
  LMonthDays[2] := 31;
  LMonthDays[3] := 30;
  LMonthDays[4] := 31;
  LMonthDays[5] := 30;
  LMonthDays[6] := 31;
  LMonthDays[7] := 31;
  LMonthDays[8] := 30;
  LMonthDays[9] := 31;
  LMonthDays[10] := 30;
  LMonthDays[11] := 31;
  Result := ttFiveSeconds;
  // leap year
  if (FYear mod 4 = 0) and not ((FYear mod 100 = 0) and (FYear mod 400 <> 0)) then
    Inc(LMonthDays[1]);
  Inc(FSecond, 5);
  if FSecond >= 60 then
  begin
    Inc(FMinute);
    FSecond := 0;
    if FMinute mod 10 = 0 then
      Result := ttTenMinutes;
    if FMinute mod 30 = 0 then
      Result := ttThirtyMinutes;
  end;
  if FMinute >= 60 then
  begin
    Inc(FHour);
    FMinute := 0;
    Result := ttHour;
  end;
  if FHour >= 24 then
  begin
    Inc(FDay);
    Inc(FWeekday);
    FHour := 0;
    Result := ttDay;
  end;
  if FWeekday > 7 then
    FWeekday := 1;
  if (FMonth < 1) or (FMonth > 12) then
    raise EXcomSaveRangeException.CreateFmt(SBadMonth, [FMonth]);
  if FDay > LMonthDays[FMonth - 1] then
  begin
    FDay := 1;
    Inc(FMonth);
    Result := ttMonth;
  end;
  if FMonth > 12 then
  begin
    FMonth := 1;
    Inc(FYear);
  end;
end;

function TXcomGameTime.WeekdayString: string;
begin
  if (FWeekday < 1) or (FWeekday > 7) then
    raise EXcomSaveRangeException.CreateFmt(SBadWeekday, [FWeekday]);
  Result := WEEKDAYS[FWeekday - 1];
end;

function TXcomGameTime.MonthString: string;
begin
  if (FMonth < 1) or (FMonth > 12) then
    raise EXcomSaveRangeException.CreateFmt(SBadMonth, [FMonth]);
  Result := MONTHS[FMonth - 1];
end;

function TXcomGameTime.DayStringKey: string;
begin
  case FDay of
    1, 21, 31:
      Result := 'STR_DATE_FIRST';
    2, 22:
      Result := 'STR_DATE_SECOND';
    3, 23:
      Result := 'STR_DATE_THIRD';
  else
    Result := 'STR_DATE_FOURTH';
  end;
end;

function TXcomGameTime.Daylight: Double;
var
  LSeconds: Integer;
begin
  LSeconds := (((FHour + 18) mod 24) * 60 + FMinute) * 60 + FSecond;
  Result := Double(LSeconds) / (60 * 60 * 24);
end;

end.
