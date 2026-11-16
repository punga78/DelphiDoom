{******************************************************************************}
{                                                                              }
{  DelphiDoom: tells whether a lump of music is a module (MOD, S3M, XM, IT)    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.ModuleDetector;

interface

type
  /// <summary>
  ///   Looks at the first bytes of a lump of music and says whether it is a
  ///   module that the tracker can play
  /// </summary>
  TModuleDetector = class
  public
    /// <param name="AData">The lump; it is only read</param>
    /// <param name="ASize">Its size in bytes</param>
    class function IsModule(const AData: Pointer; const ASize: Integer): Boolean; static;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  DelphiDoom.Tracker.Loader.It,
  DelphiDoom.Tracker.Loader.ProTracker,
  DelphiDoom.Tracker.Loader.S3m,
  DelphiDoom.Tracker.Loader.Xm;

const
  // The longest signature is that of the MOD, at 1080 for 4 bytes; the headers of the
  // others, up to the one of the IT, are shorter than this
  HEADER_SIZE = 1084;

{ TModuleDetector }

class function TModuleDetector.IsModule(const AData: Pointer; const ASize: Integer): Boolean;
var
  LHeader: TBytes;
begin
  if not Assigned(AData) or (ASize <= 0) then
    Exit(False);

  SetLength(LHeader, Min(ASize, HEADER_SIZE));
  Move(AData^, LHeader[0], Length(LHeader));

  Result := TTrackerXmLoader.Detect(LHeader) or TTrackerItLoader.Detect(LHeader) or
    TTrackerS3mLoader.Detect(LHeader) or TTrackerModLoader.Detect(LHeader);
end;

end.
