{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the palette registers of the EGA and the fades    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  colors[][], VW_SetDefaultColors, VW_FadeOut, VW_FadeIn, VW_FadeUp and        }
{  VW_FadeDown of id_vw.c                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Fader;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf;

const
  /// <summary>The levels of colors[][]: 0 all black, 3 the colors of the game, 5 all white</summary>
  KEEN_FADE_LEVELS = 6;
  KEEN_FADE_DEFAULT = 3;
  /// <summary>The vertical blanks that a step of a fade lasts</summary>
  KEEN_FADE_STEP_TICS = 6;

type
  /// <summary>
  ///   The fades of the EGA: the card has no brightness, so a fade loads the 16 palette registers with darker (or
  ///   lighter) colors in a few steps, six tics apart
  /// </summary>
  TKeenFader = class(TInterfacedObject, IKeenFader)
  strict private
    FClock: IKeenClock;
    FLevel: Integer;
    FFaded: Boolean;
    procedure SetLevel(ALevel: Integer; AWait: Boolean);
  public
    /// <param name="AClock">TimeCount: the steps of a fade wait on it</param>
    constructor Create(const AClock: IKeenClock);
    function Registers: TKeenPaletteRegisters;
    function IsFaded: Boolean;
    procedure SetDefaultColors;
    procedure FadeOut;
    procedure FadeIn;
    procedure FadeUp;
    procedure FadeDown;
    /// <summary>The registers of a level of colors[][]</summary>
    class function LevelRegisters(ALevel: Integer): TKeenPaletteRegisters; static;
    /// <summary>
    ///   The color that a value of a palette register shows in the 200 line modes, as $00RRGGBB: the bits 0..2 are
    ///   blue, green and red, the bit 4 is the intensity and the dark yellow is brown
    /// </summary>
    class function RegisterColor(AValue: Byte): Cardinal; static;
  end;

implementation

const
  COLORS: array[0..KEEN_FADE_LEVELS - 1] of TKeenPaletteRegisters = (
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7),
    (0, 0, 0, 0, 0, 0, 0, 0, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F),
    (0, 1, 2, 3, 4, 5, 6, 7, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F),
    (0, 1, 2, 3, 4, 5, 6, 7, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F),
    ($1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F)
  );

{ TKeenFader }

constructor TKeenFader.Create(const AClock: IKeenClock);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FClock := AClock;
  FLevel := KEEN_FADE_DEFAULT;
end;

class function TKeenFader.LevelRegisters(ALevel: Integer): TKeenPaletteRegisters;
begin
  if (ALevel < 0) or (ALevel >= KEEN_FADE_LEVELS) then
    raise EArgumentOutOfRangeException.Create('ALevel');
  Result := COLORS[ALevel];
end;

class function TKeenFader.RegisterColor(AValue: Byte): Cardinal;
var
  LRed: Cardinal;
  LGreen: Cardinal;
  LBlue: Cardinal;
begin
  LRed := 0;
  LGreen := 0;
  LBlue := 0;
  if (AValue and 4) <> 0 then
    LRed := $AA;
  if (AValue and 2) <> 0 then
    LGreen := $AA;
  if (AValue and 1) <> 0 then
    LBlue := $AA;
  if (AValue and $10) <> 0 then
  begin
    Inc(LRed, $55);
    Inc(LGreen, $55);
    Inc(LBlue, $55);
  end
  else if (AValue and 7) = 6 then
    LGreen := $55; // the brown of the color monitors
  Result := (LRed shl 16) or (LGreen shl 8) or LBlue;
end;

function TKeenFader.Registers: TKeenPaletteRegisters;
begin
  Result := COLORS[FLevel];
end;

function TKeenFader.IsFaded: Boolean;
begin
  Result := FFaded;
end;

procedure TKeenFader.SetLevel(ALevel: Integer; AWait: Boolean);
var
  LEnd: Integer;
begin
  FLevel := ALevel;
  if not AWait then
    Exit;
  // VW_WaitVBL(6)
  LEnd := FClock.TimeCount + KEEN_FADE_STEP_TICS;
  while FClock.TimeCount < LEnd do
    FClock.Idle;
end;

procedure TKeenFader.SetDefaultColors;
begin
  SetLevel(KEEN_FADE_DEFAULT, False);
  FFaded := False;
end;

procedure TKeenFader.FadeOut;
var
  LLevel: Integer;
begin
  for LLevel := 3 downto 0 do
    SetLevel(LLevel, True);
  FFaded := True;
end;

procedure TKeenFader.FadeIn;
var
  LLevel: Integer;
begin
  for LLevel := 0 to 3 do
    SetLevel(LLevel, True);
  FFaded := False;
end;

procedure TKeenFader.FadeUp;
var
  LLevel: Integer;
begin
  for LLevel := 3 to 5 do
    SetLevel(LLevel, True);
  FFaded := True;
end;

procedure TKeenFader.FadeDown;
var
  LLevel: Integer;
begin
  for LLevel := 5 downto 3 do
    SetLevel(LLevel, True);
  FFaded := False;
end;

end.
