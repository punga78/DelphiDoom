{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - types and exceptions                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Base of the errors of the platform library</summary>
  EPlatformException = class(Exception);

  /// <summary>The family of the operating system, as the system reports it</summary>
  TOperatingSystemFamily = (osfUnknown, osfWindows9x, osfWindowsNT);

  /// <summary>The kind of system the engine tells apart (the old osplatform_t)</summary>
  TOperatingSystemKind = (oskUnknown, oskWindows95, oskWindowsNT4, oskWindows2000);

  /// <summary>The version numbers an operating system reports</summary>
  TOperatingSystemVersion = record
    Family: TOperatingSystemFamily;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    BuildNumber: Cardinal;
    /// <summary>The service pack text; empty when there is none</summary>
    ServicePack: string;
  end;

  /// <summary>What the engine knows of the operating system and prints at startup</summary>
  TOperatingSystemDescription = record
    /// <summary>The marketing name ('XP', '7', ...); empty when it is not known</summary>
    Name: string;
    Kind: TOperatingSystemKind;
    /// <summary>True for Windows Vista and newer (and for a system nobody knows)</summary>
    IsVistaOrNewer: Boolean;
    /// <summary>The lines of the startup banner: the system, then the service pack if any</summary>
    Lines: TArray<string>;
  end;

  /// <summary>A function that gets text printed as it arrives from a program</summary>
  TProcessOutputEvent = reference to procedure(const AText: AnsiString);

resourcestring
  SPlatformFileNotRead = 'Could not read file %s';

implementation

end.
