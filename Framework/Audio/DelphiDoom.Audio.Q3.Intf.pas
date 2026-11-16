{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, injected contracts             }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Audio.Q3.Types;

type
  /// <summary>
  ///   The time of the sound system: Com_Milliseconds and the frame counter of the client
  ///   (cls.framecount), given from outside so that a test controls them
  /// </summary>
  IQ3SoundClock = interface
    ['{5A1C7E32-8B64-4D09-A3F1-62E7C0D95B18}']
    function GetMilliseconds: Integer;
    function GetFrameCount: Integer;
    property Milliseconds: Integer read GetMilliseconds;
    property FrameCount: Integer read GetFrameCount;
  end;

  /// <summary>
  ///   The device that plays the DMA buffer (SNDDMA_*): what Quake III asks of the
  ///   platform, nothing else
  /// </summary>
  IQ3SoundDevice = interface
    ['{C3E4B906-1D7A-4F58-9B20-A8F6D13E4C75}']
    /// <summary>The format of the buffer (after SNDDMA_Init)</summary>
    function GetDma: TQ3DmaInfo;
    /// <summary>The buffer that the mixer writes: Samples * SampleBits / 8 bytes</summary>
    function GetBuffer: PByte;
    /// <summary>SNDDMA_GetDMAPos: the position of the device, in samples of the buffer</summary>
    function GetPosition: Integer;
    procedure BeginPainting;
    procedure Submit;
    property Dma: TQ3DmaInfo read GetDma;
  end;

  /// <summary>Where the files of sounds come from (FS_ReadFile)</summary>
  IQ3SoundFileSource = interface
    ['{E8A2D571-3F96-4B0C-8D14-7C5B9A0F2E63}']
    /// <summary>The bytes of the file; False if it does not exist</summary>
    function ReadFile(const AName: string; out ABytes: TBytes): Boolean;
  end;

implementation

end.
