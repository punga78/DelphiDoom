{******************************************************************************}
{                                                                              }
{  DelphiDoom: Keen32 - the keys of the window of the game host library as the  }
{  bytes of the keyboard of the PC                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.HostEvents;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   The window says "the key with this virtual code went down" (or up); the input manager of the game wants
  ///   what the keyboard interrupt of the PC got: the scan code, with $E0 before it for the keys that have the
  ///   prefix and the bit 7 for a key that goes up, $E1 for the pause key. A key that Windows repeats is a make
  ///   code that comes again, as on the PC. The player closing the window is remembered until someone asks.
  ///   When the window loses the focus the keys that were down go up (the key up message never comes)
  /// </summary>
  TKeenHostEvents = class(TInterfacedObject, IGameHostEventSink)
  strict private
    FKeys: TProc<Byte>;
    FDown: array[0..255] of Boolean;
    FQuit: Boolean;
    procedure Send(AVirtualKey: Integer; ADown: Boolean);
  public
    procedure Post(const AEvent: TGameHostEvent);
    /// <summary>Where the bytes go (IKeenInput.KeyService); nil drops them</summary>
    property Keys: TProc<Byte> read FKeys write FKeys;
    /// <summary>The player closed the window</summary>
    property Quit: Boolean read FQuit;
  end;

implementation

uses
  DelphiDoom.Keen.KeyboardPump;

const
  VK_PAUSE_KEY = $13;

{ TKeenHostEvents }

procedure TKeenHostEvents.Send(AVirtualKey: Integer; ADown: Boolean);
var
  LScan: Byte;
  LExtended: Boolean;
begin
  if (AVirtualKey < Low(FDown)) or (AVirtualKey > High(FDown)) then
    Exit;
  FDown[AVirtualKey] := ADown;
  if not Assigned(FKeys) then
    Exit;
  if AVirtualKey = VK_PAUSE_KEY then
  begin
    if ADown then
      FKeys($E1);
    Exit;
  end;
  LScan := TKeenKeyboardPump.ScanOf(AVirtualKey, LExtended);
  if LScan = 0 then
    Exit;
  if LExtended then
    FKeys($E0);
  if ADown then
    FKeys(LScan)
  else
    FKeys(LScan or $80);
end;

procedure TKeenHostEvents.Post(const AEvent: TGameHostEvent);
var
  LKey: Integer;
begin
  case AEvent.Kind of
    hekQuit:
      FQuit := True;
    hekKeyDown:
      Send(AEvent.VirtualKey, True);
    hekKeyUp:
      Send(AEvent.VirtualKey, False);
    hekActive:
      if not AEvent.Focused then
        for LKey := Low(FDown) to High(FDown) do
          if FDown[LKey] then
            Send(LKey, False);
  end;
end;

end.
