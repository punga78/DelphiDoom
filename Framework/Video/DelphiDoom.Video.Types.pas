{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - shared types                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.Types;

interface

const
  /// <summary>
  ///   The ways the software video uses the screen (the "fullscreen" option, kept in the
  ///   configuration file with these numbers): the window as big as the screen, the screen
  ///   taken by DirectDraw, a window
  /// </summary>
  FULLSCREEN_SHARED = 0;
  FULLSCREEN_EXCLUSIVE = 1;
  FULLSCREEN_OFF = 2;
  NUMFULLSCREEN_MODES = 3;

type
  /// <summary>A screen mode of the computer: size in pixels and bits per pixel</summary>
  TDisplayMode = record
    Width: Integer;
    Height: Integer;
    BitsPerPixel: Integer;
  end;

  /// <summary>The smallest and the biggest size of the rendering screen that the game accepts</summary>
  TScreenSizeLimits = record
    MinWidth: Integer;
    MinHeight: Integer;
    MaxWidth: Integer;
    MaxHeight: Integer;
  end;

implementation

end.
