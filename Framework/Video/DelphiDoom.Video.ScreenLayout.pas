{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the sizes of the screens of the engine           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.ScreenLayout;

interface

type
  /// <summary>The size of the drawing area and of its texture in the OpenGL renderers</summary>
  TVideoGlDrawSize = record
    Width: Integer;
    Height: Integer;
    TextureWidth: Integer;
    TextureHeight: Integer;
  end;

  /// <summary>
  ///   Pure rules of v_video for the sizes of its screens (cold: they run when the video mode
  ///   changes). Static functions, no state
  /// </summary>
  TVideoScreenLayout = class sealed
  public
    /// <summary>A fixed dimension, or the default one when the fixed one is -1</summary>
    class function Resolve(const AFixed: Integer; const ADefault: Integer): Integer; static;
    /// <summary>Bytes of a screen: its fixed (or default, if -1) size times the bytes per pixel</summary>
    class function ByteSize(const AFixedWidth, AFixedHeight, ADepth: Integer;
      const ADefaultWidth, ADefaultHeight: Integer): Integer; static;
    /// <summary>The OpenGL drawing area: 512 wide below 1024 pixels of screen, 1024 otherwise</summary>
    class function GlDrawSize(const AScreenWidth, AScreenHeight: Integer): TVideoGlDrawSize; static;
    /// <summary>
    ///   Bytes of the 32 bit frame that the software video presents: 20 rows of padding under the screen, a
    ///   multiple of 4096 (the padding may give up to 4% of speed)
    /// </summary>
    class function FrameBufferSize(const AScreenWidth, AScreenHeight: Integer): Integer; static;
  end;

implementation

{ TVideoScreenLayout }

class function TVideoScreenLayout.Resolve(const AFixed: Integer; const ADefault: Integer): Integer;
begin
  if AFixed = -1 then
    Result := ADefault
  else
    Result := AFixed;
end;

class function TVideoScreenLayout.ByteSize(const AFixedWidth, AFixedHeight, ADepth: Integer;
  const ADefaultWidth, ADefaultHeight: Integer): Integer;
begin
  Result := Resolve(AFixedWidth, ADefaultWidth) * Resolve(AFixedHeight, ADefaultHeight) * ADepth;
end;

class function TVideoScreenLayout.GlDrawSize(const AScreenWidth, AScreenHeight: Integer): TVideoGlDrawSize;
var
  LSide: Integer;
begin
  if AScreenWidth < 1024 then
    LSide := 512
  else
    LSide := 1024;
  Result.Width := LSide;
  if AScreenWidth <= AScreenHeight then
    Result.Height := LSide
  else
    Result.Height := Round(AScreenHeight * LSide / AScreenWidth);
  Result.TextureWidth := LSide;
  Result.TextureHeight := LSide;
end;

class function TVideoScreenLayout.FrameBufferSize(const AScreenWidth, AScreenHeight: Integer): Integer;
const
  ERROR_OFFSET = 20;
begin
  Result := AScreenWidth * (AScreenHeight + ERROR_OFFSET) * SizeOf(LongWord) and not (4095);
end;

end.
