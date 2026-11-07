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

type
  /// <summary>A screen mode of the computer: size in pixels and bits per pixel</summary>
  TDisplayMode = record
    Width: Integer;
    Height: Integer;
    BitsPerPixel: Integer;
  end;

implementation

end.
