{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the web pages of the console commands                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.Browser;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Leaves the exclusive full screen (the page would open behind the game) and opens the
  ///   address with I_GoToWebPage: the old C_CmdGoToWebPage
  /// </summary>
  TEngineConsoleBrowser = class(TInterfacedObject, IConsoleBrowser)
  public
    procedure OpenWebPage(const AAddress: string);
  end;

implementation

uses
  d_delphi,
  doomdef,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_video,
{$ENDIF}
  DelphiDoom.Video.Types,
  i_system;

{ TEngineConsoleBrowser }

procedure TEngineConsoleBrowser.OpenWebPage(const AAddress: string);
begin
  if fullscreen {$IFNDEF OPENGL}= FULLSCREEN_EXCLUSIVE {$ENDIF} then
  {$IFDEF OPENGL}
    GL_ChangeFullScreen(false);
  {$ELSE}
    I_ChangeFullScreen(FULLSCREEN_SHARED);
  {$ENDIF}
  I_GoToWebPage(AAddress);
end;

end.
