{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the settings                                     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): m_defs.pas                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Settings;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf;

type
  /// <summary>
  ///   The table of defaults of m_defs.pas as values of an object instead of pointers to the globals of the game: the
  ///   game reads its options from here. The file is read as the original does, with a TStringList (the first
  ///   line with a name wins, a name is only found with the same case)
  /// </summary>
  TGreedSettings = class(TInterfacedObject, IGreedSettings)
  strict private
    FIntegers: TArray<Integer>;
    FStrings: TArray<string>;
    function IndexOf(const AName: string; AKind: TGreedSettingKind): Integer;
    function FindName(const AName: string): Integer;
  public
    constructor Create;
    function GetCount: Integer;
    function NameOf(AIndex: Integer): string;
    function KindOf(const AName: string): TGreedSettingKind;
    function GetInteger(const AName: string): Integer;
    function GetBoolean(const AName: string): Boolean;
    function GetString(const AName: string): string;
    procedure SetInteger(const AName: string; AValue: Integer);
    procedure SetBoolean(const AName: string; AValue: Boolean);
    procedure SetString(const AName: string; const AValue: string);
    procedure Reset;
    function LoadFromText(const AText: string): Boolean;
    function SaveToText: string;
    function GetEpisode: Integer;
    procedure SetEpisode(AValue: Integer);
    function GetGameVariant: TGreedGameVariant;
    procedure ApplyCommandLineGame(AGame: Integer);
    /// <summary>atoi of g_delphi: decimal, $hex, 0x and -0x hex, #decimal; 0 for anything else</summary>
    class function ParseInteger(const AText: string): Integer; static;
  end;

implementation

uses
  System.Classes;

type
  TSettingEntry = record
    Name: string;
    Kind: TGreedSettingKind;
    DefaultValue: Integer;
  end;

const
  // the scan codes of d_ints_h.pas
  SC_SPACE = $39;
  SC_ALT = $38;
  SC_CONTROL = $1D;
  SC_LSHIFT = $2A;
  SC_UPARROW = $48;
  SC_DOWNARROW = $50;
  SC_LEFTARROW = $4B;
  SC_RIGHTARROW = $4D;
  SC_INSERT = $52;
  SC_DELETE = $53;
  SC_HOME = $47;
  SC_PGUP = $49;
  SC_PGDN = $51;
  SC_COMMA = $33;
  SC_PERIOD = $34;
  SC_A = $1E;
  SC_S = $1F;
  SC_X = $2D;
  SC_Z = $2C;
  // AMBIENTLIGHT of protos_h.pas
  AMBIENT_LIGHT = 2048;

  ENTRIES: array[0..41] of TSettingEntry = (
    (Name: 'ambientlight'; Kind: gskInteger; DefaultValue: AMBIENT_LIGHT),
    (Name: 'violence'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'animation'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'musicvol'; Kind: gskInteger; DefaultValue: 100),
    (Name: 'sfxvol'; Kind: gskInteger; DefaultValue: 128),
    (Name: 'bt_north'; Kind: gskInteger; DefaultValue: SC_UPARROW),
    (Name: 'bt_east'; Kind: gskInteger; DefaultValue: SC_RIGHTARROW),
    (Name: 'bt_south'; Kind: gskInteger; DefaultValue: SC_DOWNARROW),
    (Name: 'bt_west'; Kind: gskInteger; DefaultValue: SC_LEFTARROW),
    (Name: 'bt_fire'; Kind: gskInteger; DefaultValue: SC_CONTROL),
    (Name: 'bt_straf'; Kind: gskInteger; DefaultValue: SC_ALT),
    (Name: 'bt_use'; Kind: gskInteger; DefaultValue: SC_SPACE),
    (Name: 'bt_run'; Kind: gskInteger; DefaultValue: SC_LSHIFT),
    (Name: 'bt_jump'; Kind: gskInteger; DefaultValue: SC_Z),
    (Name: 'bt_useitem'; Kind: gskInteger; DefaultValue: SC_X),
    (Name: 'bt_asscam'; Kind: gskInteger; DefaultValue: SC_A),
    (Name: 'bt_lookup'; Kind: gskInteger; DefaultValue: SC_PGUP),
    (Name: 'bt_lookdown'; Kind: gskInteger; DefaultValue: SC_PGDN),
    (Name: 'bt_centerview'; Kind: gskInteger; DefaultValue: SC_HOME),
    (Name: 'bt_slideleft'; Kind: gskInteger; DefaultValue: SC_COMMA),
    (Name: 'bt_slideright'; Kind: gskInteger; DefaultValue: SC_PERIOD),
    (Name: 'bt_invleft'; Kind: gskInteger; DefaultValue: SC_INSERT),
    (Name: 'bt_invright'; Kind: gskInteger; DefaultValue: SC_DELETE),
    (Name: 'bt_motionmode'; Kind: gskInteger; DefaultValue: SC_S),
    (Name: 'gameepisode'; Kind: gskInteger; DefaultValue: 1),
    (Name: 'screensize'; Kind: gskInteger; DefaultValue: 4),
    (Name: 'camdelay'; Kind: gskInteger; DefaultValue: 35),
    (Name: 'headbobon'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'weapbobon'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'vid_pillarbox_pct'; Kind: gskInteger; DefaultValue: 17),
    (Name: 'slopeprecise'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'interpolate'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'doubleblit'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'lowresolution'; Kind: gskBoolean; DefaultValue: 0),
    (Name: 'mouse'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'menumouse'; Kind: gskBoolean; DefaultValue: 1),
    (Name: 'mousesensitivity'; Kind: gskInteger; DefaultValue: 10),
    (Name: 'mousesensitivityx'; Kind: gskInteger; DefaultValue: 10),
    (Name: 'mousesensitivityy'; Kind: gskInteger; DefaultValue: 5),
    (Name: 'invertmouseturn'; Kind: gskBoolean; DefaultValue: 0),
    (Name: 'invertmouselook'; Kind: gskBoolean; DefaultValue: 0),
    (Name: 'maindatafile'; Kind: gskString; DefaultValue: 0));

  EPISODE_NAME = 'gameepisode';

{ TGreedSettings }

constructor TGreedSettings.Create;
begin
  inherited Create;
  SetLength(FIntegers, Length(ENTRIES));
  SetLength(FStrings, Length(ENTRIES));
  Reset;
end;

function TGreedSettings.GetCount: Integer;
begin
  Result := Length(ENTRIES);
end;

function TGreedSettings.NameOf(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex > High(ENTRIES)) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [AIndex, 'the setting', 0, High(ENTRIES)]);
  Result := ENTRIES[AIndex].Name;
end;

function TGreedSettings.FindName(const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ENTRIES) do
    if ENTRIES[LIndex].Name = AName then
      Exit(LIndex);
  Result := -1;
end;

function TGreedSettings.IndexOf(const AName: string; AKind: TGreedSettingKind): Integer;
begin
  Result := FindName(AName);
  if (Result < 0) or (ENTRIES[Result].Kind <> AKind) then
    raise EGreedNotFoundException.CreateFmt(SGreedSettingUnknown, [AName]);
end;

function TGreedSettings.KindOf(const AName: string): TGreedSettingKind;
var
  LIndex: Integer;
begin
  LIndex := FindName(AName);
  if LIndex < 0 then
    raise EGreedNotFoundException.CreateFmt(SGreedSettingUnknown, [AName]);
  Result := ENTRIES[LIndex].Kind;
end;

function TGreedSettings.GetInteger(const AName: string): Integer;
begin
  Result := FIntegers[IndexOf(AName, gskInteger)];
end;

function TGreedSettings.GetBoolean(const AName: string): Boolean;
begin
  Result := FIntegers[IndexOf(AName, gskBoolean)] <> 0;
end;

function TGreedSettings.GetString(const AName: string): string;
begin
  Result := FStrings[IndexOf(AName, gskString)];
end;

procedure TGreedSettings.SetInteger(const AName: string; AValue: Integer);
begin
  FIntegers[IndexOf(AName, gskInteger)] := AValue;
end;

procedure TGreedSettings.SetBoolean(const AName: string; AValue: Boolean);
begin
  FIntegers[IndexOf(AName, gskBoolean)] := Ord(AValue);
end;

procedure TGreedSettings.SetString(const AName: string; const AValue: string);
begin
  // string255_t of the original: at most 255 characters
  FStrings[IndexOf(AName, gskString)] := Copy(AValue, 1, 255);
end;

procedure TGreedSettings.Reset;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ENTRIES) do
  begin
    FIntegers[LIndex] := ENTRIES[LIndex].DefaultValue;
    FStrings[LIndex] := '';
  end;
end;

class function TGreedSettings.ParseInteger(const AText: string): Integer;
var
  LCode, LValue: Integer;
begin
  Val(AText, Result, LCode);
  if LCode <> 0 then
  begin
    LValue := 0;
    if Pos('0x', AText) = 1 then
      Val('$' + Copy(AText, 3, Length(AText) - 2), LValue, LCode)
    else if Pos('-0x', AText) = 1 then
    begin
      Val('$' + Copy(AText, 4, Length(AText) - 3), LValue, LCode);
      LValue := -LValue;
    end
    else if Pos('#', AText) = 1 then
      Val(Copy(AText, 2, Length(AText) - 1), LValue, LCode);
    if LCode = 0 then
      Result := LValue
    else
      Result := 0;
  end;
end;

function TGreedSettings.LoadFromText(const AText: string): Boolean;
var
  LLines: TStringList;
  LLine: Integer;
  LName, LValue: string;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LLine := 0 to LLines.Count - 1 do
    begin
      LName := LLines.Names[LLine];
      LIndex := FindName(LName);
      if LIndex < 0 then
        Continue;
      LValue := LLines.Values[LName];
      case ENTRIES[LIndex].Kind of
        gskInteger:
          if LValue <> '' then
            FIntegers[LIndex] := ParseInteger(LValue);
        gskBoolean:
          FIntegers[LIndex] := Ord((LValue <> '0') and (LValue <> ''));
        gskString:
          FStrings[LIndex] := Copy(LValue, 1, 255);
      end;
    end;
    Result := LLines.Count > 0;
  finally
    LLines.Free;
  end;
end;

function TGreedSettings.SaveToText: string;
var
  LLines: TStringList;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    for LIndex := 0 to High(ENTRIES) do
      case ENTRIES[LIndex].Kind of
        gskInteger:
          LLines.Add(ENTRIES[LIndex].Name + '=' + IntToStr(FIntegers[LIndex]));
        gskBoolean:
          LLines.Add(ENTRIES[LIndex].Name + '=' + IntToStr(Ord(FIntegers[LIndex] <> 0)));
        gskString:
          LLines.Add(ENTRIES[LIndex].Name + '=' + FStrings[LIndex]);
      end;
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

function TGreedSettings.GetEpisode: Integer;
begin
  Result := FIntegers[FindName(EPISODE_NAME)];
end;

procedure TGreedSettings.SetEpisode(AValue: Integer);
begin
  FIntegers[FindName(EPISODE_NAME)] := AValue;
end;

function TGreedSettings.GetGameVariant: TGreedGameVariant;
begin
  case GetEpisode of
    2: Result := ggvGame2;
    3: Result := ggvGame3;
  else
    Result := ggvGame1;
  end;
end;

procedure TGreedSettings.ApplyCommandLineGame(AGame: Integer);
begin
  if (AGame >= 1) and (AGame <= 3) then
    SetEpisode(AGame);
end;

end.
