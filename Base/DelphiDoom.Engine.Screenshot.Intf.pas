{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the screenshots of the game                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Screenshot.Intf;

{$I Doom32.inc}

interface

type
  /// <summary>
  ///   Takes a picture of the screen in the format of the option screenshotformat. The
  ///   composition root gives it to the main loop (d_main, -shot), to the game (g_game, the key
  ///   and the command "screenshot") and to the menus (the format). It was the facade m_misc.pas
  /// </summary>
  IEngineScreenshot = interface
    ['{C3A5E7F1-0B92-4D68-8E4A-6F1B2D9C7E35}']
    /// <summary>
    ///   Writes the screen to a file: AFileName (the extension says the format) or a new name in
    ///   the folder of the format; the message of the player says if it worked, unless ASilent
    ///   (M_ScreenShot)
    /// </summary>
    procedure Take(const AFileName: string = ''; const ASilent: Boolean = False);
    /// <summary>The option screenshotformat in upper case, PNG if it is not PNG, JPG or TGA (M_FixScreenshotFormat)</summary>
    procedure FixFormat;
  end;

implementation

end.
