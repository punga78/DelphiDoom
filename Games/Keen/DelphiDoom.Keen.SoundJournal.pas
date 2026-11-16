{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - which sounds a game asked for                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SoundJournal;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   A sound manager that counts the sounds the game asks it to play and gives every call to another manager.
  ///   The count says what happened in a game without ears and without a picture: a sound is a fact of the game
  ///   (Keen jumped, took a bonus, an enemy became a flower, a level was entered)
  /// </summary>
  TKeenSoundJournal = class(TInterfacedObject, IKeenSoundManager)
  strict private
    FInner: IKeenSoundManager;
    FCounts: array[0..KEEN_NUMSOUNDS - 1] of Integer;
  public
    constructor Create(const AInner: IKeenSoundManager);
    function GetMode: TKeenSoundMode;
    procedure SetMode(AMode: TKeenSoundMode);
    procedure PlaySound(ASound: Integer);
    procedure StopSound;
    function SoundPlaying: Integer;
    procedure Service;
    procedure WaitSoundDone;
    function AdLibPresent: Boolean;
    function TrySetMode(AMode: TKeenSoundMode): Boolean;
    procedure SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
    /// <summary>How many times the sound was asked for (also when a sound of a higher priority kept it from playing)</summary>
    function Count(ASound: Integer): Integer;
    /// <summary>The sounds that were asked for as "number x times", in the order of their numbers; empty for none</summary>
    function Summary: string;
  end;

implementation

{ TKeenSoundJournal }

constructor TKeenSoundJournal.Create(const AInner: IKeenSoundManager);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner');
  FInner := AInner;
end;

function TKeenSoundJournal.GetMode: TKeenSoundMode;
begin
  Result := FInner.Mode;
end;

procedure TKeenSoundJournal.SetMode(AMode: TKeenSoundMode);
begin
  FInner.Mode := AMode;
end;

procedure TKeenSoundJournal.PlaySound(ASound: Integer);
begin
  if (ASound >= Low(FCounts)) and (ASound <= High(FCounts)) then
    Inc(FCounts[ASound]);
  FInner.PlaySound(ASound);
end;

procedure TKeenSoundJournal.StopSound;
begin
  FInner.StopSound;
end;

function TKeenSoundJournal.SoundPlaying: Integer;
begin
  Result := FInner.SoundPlaying;
end;

procedure TKeenSoundJournal.Service;
begin
  FInner.Service;
end;

procedure TKeenSoundJournal.WaitSoundDone;
begin
  FInner.WaitSoundDone;
end;

function TKeenSoundJournal.AdLibPresent: Boolean;
begin
  Result := FInner.AdLibPresent;
end;

function TKeenSoundJournal.TrySetMode(AMode: TKeenSoundMode): Boolean;
begin
  Result := FInner.TrySetMode(AMode);
end;

procedure TKeenSoundJournal.SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
begin
  FInner.SetDefault(AGotIt, AMode);
end;

function TKeenSoundJournal.Count(ASound: Integer): Integer;
begin
  if (ASound >= Low(FCounts)) and (ASound <= High(FCounts)) then
    Result := FCounts[ASound]
  else
    Result := 0;
end;

function TKeenSoundJournal.Summary: string;
var
  LSound: Integer;
begin
  Result := '';
  for LSound := Low(FCounts) to High(FCounts) do
    if FCounts[LSound] > 0 then
    begin
      if Result <> '' then
        Result := Result + ' ';
      Result := Result + Format('%dx%d', [LSound, FCounts[LSound]]);
    end;
end;

end.
