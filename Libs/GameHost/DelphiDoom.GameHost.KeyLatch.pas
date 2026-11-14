{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - keys read at the pace of the game            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.KeyLatch;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   The keys of a key state for a game that reads them now and then (once a tic, once every two tics): a key
  ///   that went down and up again between two readings is still seen as down by the reading that follows, once.
  ///   Each reader of the keys has its own latch, so that one does not take the presses of another. With a key
  ///   state that does not count the presses (no IGameHostKeyPresses) it answers what the key state answers
  /// </summary>
  TGameHostKeyLatch = class
  strict private
    const
      KEY_COUNT = 256;
    var
      FKeys: IGameHostKeyState;
      FPresses: IGameHostKeyPresses;
      FSeen: array[0..KEY_COUNT - 1] of Cardinal;
      FSampled: array[0..KEY_COUNT - 1] of Boolean;
  public
    /// <summary>EArgumentNilException if AKeys is nil</summary>
    constructor Create(const AKeys: IGameHostKeyState);
    /// <summary>
    ///   The key is down now, or it was pressed since the Take (or the Sample) before; false for a code that is not
    ///   a key
    /// </summary>
    function Take(AVirtualKey: Integer): Boolean;
    /// <summary>Takes every key: IsDown answers for this moment until the next Sample</summary>
    procedure Sample;
    /// <summary>What Take answered for the key in the last Sample</summary>
    function IsDown(AVirtualKey: Integer): Boolean;
  end;

implementation

constructor TGameHostKeyLatch.Create(const AKeys: IGameHostKeyState);
var
  LKey: Integer;
begin
  inherited Create;
  if not Assigned(AKeys) then
    raise EArgumentNilException.Create('AKeys');
  FKeys := AKeys;
  Supports(AKeys, IGameHostKeyPresses, FPresses);
  // what was pressed before the reader existed is not its business
  if Assigned(FPresses) then
    for LKey := 0 to KEY_COUNT - 1 do
      FSeen[LKey] := FPresses.PressCount(LKey);
end;

function TGameHostKeyLatch.Take(AVirtualKey: Integer): Boolean;
var
  LCount: Cardinal;
begin
  if (AVirtualKey < 0) or (AVirtualKey >= KEY_COUNT) then
    Exit(False);
  Result := FKeys.IsDown(AVirtualKey);
  if Assigned(FPresses) then
  begin
    LCount := FPresses.PressCount(AVirtualKey);
    if LCount <> FSeen[AVirtualKey] then
    begin
      FSeen[AVirtualKey] := LCount;
      Result := True;
    end;
  end;
end;

procedure TGameHostKeyLatch.Sample;
var
  LKey: Integer;
begin
  for LKey := 0 to KEY_COUNT - 1 do
    FSampled[LKey] := Take(LKey);
end;

function TGameHostKeyLatch.IsDown(AVirtualKey: Integer): Boolean;
begin
  Result := (AVirtualKey >= 0) and (AVirtualKey < KEY_COUNT) and FSampled[AVirtualKey];
end;

end.
