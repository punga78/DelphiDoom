{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - the contracts                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types;

type
  /// <summary>Turns the screen into the bytes of a file of one format</summary>
  IScreenshotEncoder = interface
    ['{3B7E1D52-94A8-4C60-B2F5-6A0D8E31C947}']
    function GetFormat: TScreenshotFormat;
    /// <summary>
    ///   APixels holds AHeight rows of AWidth pixels of 4 bytes (B, G, R and one that is
    ///   ignored), as the screen readers of the engine give them. With ABottomUp the first
    ///   row is the bottom one of the image (OpenGL reads the screen from the bottom)
    /// </summary>
    /// <exception cref="EScreenshotException">The pixels or the size are not valid, or the encoder fails</exception>
    function Encode(APixels: Pointer; AWidth, AHeight: Integer; ABottomUp: Boolean): TBytes;
    property Format: TScreenshotFormat read GetFormat;
  end;

  /// <summary>Puts the bytes of a file on disk</summary>
  IScreenshotFileSink = interface
    ['{C8052A6E-1F37-4D9B-8E40-B5D9713A62FC}']
    /// <summary>False when the file cannot be written or the content is empty</summary>
    function Write(const APath: string; const AContent: TBytes): Boolean;
  end;

  /// <summary>Writes a screenshot in its format and, when asked, a JPEG copy of it</summary>
  IScreenshotWriter = interface
    ['{5E91B3A7-60C2-4F18-A7D4-E2380C65F91B}']
    /// <summary>
    ///   Writes the file of ATarget.Format. With AJpegCopy a JPEG file is written too (unless
    ///   the screenshot is a JPEG already); its failure does not change the result
    /// </summary>
    /// <returns>True when the file of the format that was asked for has been written</returns>
    function Save(const ATarget: TScreenshotTarget; APixels: Pointer;
      AWidth, AHeight: Integer; ABottomUp, AJpegCopy: Boolean): Boolean;
  end;

  /// <summary>Where the engine keeps its files</summary>
  IScreenshotFolders = interface
    ['{A41D68F0-2B9C-47E3-95A1-D07F3E8C5B26}']
    /// <summary>The path of a file or folder of the game (M_SaveFileName)</summary>
    function PathOf(const ARelativeName: string): string;
  end;

  /// <summary>Chooses the names of the files of a screenshot</summary>
  IScreenshotTargets = interface
    ['{7D3A95C2-E814-4B06-8F27-19C6A0B4D53E}']
    /// <summary>
    ///   The names for a screenshot with no name given: SSHOT_[game]_[stamp] in the folder of
    ///   every format
    /// </summary>
    function ForGenerated(const AGameName, AStamp: string;
      AFormat: TScreenshotFormat): TScreenshotTarget;
    /// <summary>
    ///   The names for a screenshot that has a name: the extension (.tga, .jpg, .png) says the
    ///   format (PNG when there is none); a name with no folder goes in the one of its format
    /// </summary>
    function ForFileName(const AFileName: string): TScreenshotTarget;
  end;

implementation

end.
