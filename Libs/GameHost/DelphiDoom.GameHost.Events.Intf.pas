{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the contract of the input events             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Events.Intf;

interface

uses
  DelphiDoom.GameHost.Types;

type
  /// <summary>
  ///   Where the events of the window go: the adapter of a game, which turns them into the events the game reads.
  ///   Called by the thread of the window, while it pumps its messages
  /// </summary>
  IGameHostEventSink = interface
    ['{7C3E91B5-D046-4A8F-B2E7-1F605C9D3A84}']
    procedure Post(const AEvent: TGameHostEvent);
  end;

  /// <summary>The state of the keyboard that the translation of a key message asks for</summary>
  IGameHostKeyboard = interface
    ['{A1D85F27-6B93-4E0C-8D41-E72B0C5F9613}']
    /// <summary>The modifier keys that are down now</summary>
    function Modifiers: TGameHostModifiers;
    /// <summary>
    ///   What a key types with the current layout and shift state: its character when it is one and is not a
    ///   control character, otherwise 0
    /// </summary>
    function CharacterOf(AVirtualKey: Cardinal; AScanCode: Cardinal): Cardinal;
  end;

  /// <summary>Which keys are held, for a game that asks instead of reading events</summary>
  IGameHostKeyState = interface
    ['{4F2A8D61-B370-4C19-9E85-0D6C3A71F2B9}']
    /// <summary>The virtual key of Windows is down; false for a code that is not a key</summary>
    function IsDown(AVirtualKey: Integer): Boolean;
  end;

  /// <summary>
  ///   How many times each key went down, for a game that asks at its own pace: a key that went down and up
  ///   between two questions is not seen by IsDown, but its count has changed. Optional: asked with Supports
  /// </summary>
  IGameHostKeyPresses = interface
    ['{2B7D4E90-51C8-4F3A-A6E2-93D0B8C14F75}']
    /// <summary>
    ///   The times the virtual key went from up to down since the state was made (the repeats of a held key are
    ///   not counted; the number wraps); 0 for a code that is not a key
    /// </summary>
    function PressCount(AVirtualKey: Integer): Cardinal;
  end;

  /// <summary>Reads the messages of the window of the game; false once the player has closed it</summary>
  TGameHostPump = reference to function: Boolean;

implementation

end.
