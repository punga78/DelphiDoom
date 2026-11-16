{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - FLIC animations: the contracts (issue #199) }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Flic.Types;

type
  /// <summary>Decodes the frames of a FLI/FLC file one after the other</summary>
  IFlicDecoder = interface
    ['{6D2B9A41-0C73-4E58-B1F6-A83D5E7C0924}']
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetHeaderFrames: Integer;
    function GetFrameCount: Integer;
    function GetFrameIndex: Integer;
    function GetFrameDelay: Integer;
    function GetIsFli: Boolean;
    function GetIndices: TBytes;
    function GetPalette: TFlicPalette;
    function GetFrame: TImagingPixels;
    /// <summary>Decodes the next frame; False when there are no more (the last one stays)</summary>
    function NextFrame: Boolean;
    /// <summary>Starts again from the first frame (picture and palette are cleared)</summary>
    procedure Reset;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
    /// <summary>The number of frames that the header says (the ring frame is not counted)</summary>
    property HeaderFrames: Integer read GetHeaderFrames;
    /// <summary>The frames that NextFrame gives: the ones of the file, without the ring frame unless it was asked for</summary>
    property FrameCount: Integer read GetFrameCount;
    /// <summary>Number of the last frame decoded, from 0; -1 before the first</summary>
    property FrameIndex: Integer read GetFrameIndex;
    /// <summary>Milliseconds that the last frame stays on screen (the header speed, or the delay of the frame in a FLI)</summary>
    property FrameDelay: Integer read GetFrameDelay;
    property IsFli: Boolean read GetIsFli;
    /// <summary>The picture of the last frame, one byte per pixel (Width * Height, no padding); a copy</summary>
    property Indices: TBytes read GetIndices;
    /// <summary>The palette after the last frame</summary>
    property Palette: TFlicPalette read GetPalette;
    /// <summary>The last frame in 32 bits, Width * Height pixels $AABBGGRR (alpha $FF); a copy that stays valid</summary>
    property Frame: TImagingPixels read GetFrame;
  end;

  TFlicPlayerStatus = (fpsPlaying, fpsEnded);

  /// <summary>What the player shows at a time</summary>
  TFlicPlayerImage = record
    Width: Integer;
    Height: Integer;
    /// <summary>Number of the frame shown, from 0</summary>
    FrameIndex: Integer;
    Status: TFlicPlayerStatus;
    Pixels: TImagingPixels;
  end;

  /// <summary>
  ///   Gives the image of an animation for a time that the caller provides: the player
  ///   never reads a clock
  /// </summary>
  IFlicPlayer = interface
    ['{B4E07C93-52A1-4D68-9F3B-1C6A8D2E7F05}']
    /// <summary>The frame that is on screen at AMilliseconds, a time on the clock of the caller</summary>
    function ImageForTime(AMilliseconds: Integer): TFlicPlayerImage;
    /// <summary>The next call to ImageForTime is the start of the animation</summary>
    procedure ResetTime;
  end;

implementation

end.
