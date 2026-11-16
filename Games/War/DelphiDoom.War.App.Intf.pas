{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the contracts of the program Warcraft32           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>Where the pictures of the game go: a window, or nowhere (a run with no window has none)</summary>
  IWarFramePresenter = interface
    ['{3E81B5D7-0A42-4C96-8F13-A7D96C0E5B24}']
    /// <summary>Shows the picture (AWidth x AHeight, one $FFRRGGBB value per pixel, rows from the top)</summary>
    procedure Present(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
    /// <summary>Says something to the player (the title of the window): "Game saved", the file that was loaded...</summary>
    procedure SetStatus(const AText: string);
  end;

  /// <summary>Where the saved game of the quick slot is kept (a file next to the program, or the memory of a test)</summary>
  IWarSaveStorage = interface
    ['{91D0E6A4-5B73-4F28-A6C1-2E8F40D7B359}']
    procedure Write(const ABytes: TBytes);
    /// <summary>False when the slot is empty</summary>
    function TryRead(out ABytes: TBytes): Boolean;
  end;

  /// <summary>Reads the messages of the window; False once the player has closed it</summary>
  TWarPump = reference to function: Boolean;

implementation

end.
