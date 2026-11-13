{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - contracts of the image program                }
{                                                                              }
{  The image program of idTech 4 (renderer\Image_program.cpp) asks R_LoadImage }
{  for the images that its expressions name; here that is a small interface    }
{  that a test can fake and the engine can implement on its file system.       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ImageProgram.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Rgba.Image;

const
  /// <summary>The timestamp of an image that does not exist (the C++ tests for -1)</summary>
  IMAGING_TIMESTAMP_NOT_FOUND = -1;

type
  /// <summary>Gives the images that an image program names, by name</summary>
  IImagingProgramSource = interface
    ['{6C1D4E7A-2B93-4F58-A0E6-83D5B19C72F4}']
    /// <summary>
    ///   Finds the image AName (R_LoadImage with makePowerOf2 = true: the source decides the
    ///   extension and the size). AImage is filled only when AWantPixels is true; ATimestamp is
    ///   set in both cases. False when there is no such image (ATimestamp is then
    ///   IMAGING_TIMESTAMP_NOT_FOUND)
    /// </summary>
    function TryLoad(const AName: string; const AWantPixels: Boolean; out AImage: TImagingRgbaImage;
      out ATimestamp: Int64): Boolean;
  end;

implementation

end.
