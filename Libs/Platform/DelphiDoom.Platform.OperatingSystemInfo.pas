{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the operating system in words                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.OperatingSystemInfo;

interface

uses
  DelphiDoom.Platform.Intf, DelphiDoom.Platform.Types;

type
  /// <summary>
  ///   Turns the version numbers of the system into the name, the kind and the startup lines
  ///   the engine always had (the old I_DetectOS)
  /// </summary>
  TOperatingSystemInfo = class(TInterfacedObject, IOperatingSystemInfo)
  strict private
    FSource: IOperatingSystemSource;
    class function NameOf(const AVersion: TOperatingSystemVersion): string; static;
  public
    constructor Create(const ASource: IOperatingSystemSource);
    function Describe: TOperatingSystemDescription;
  end;

implementation

uses
  System.SysUtils;

{ TOperatingSystemInfo }

constructor TOperatingSystemInfo.Create(const ASource: IOperatingSystemSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
end;

class function TOperatingSystemInfo.NameOf(const AVersion: TOperatingSystemVersion): string;
begin
  Result := '';
  case AVersion.Family of
    osfWindows9x:
      begin
        if AVersion.MinorVersion < 10 then
          Result := '95'
        else if AVersion.MinorVersion < 90 then
          Result := '98'
        else
          Result := 'Me';
      end;
    osfWindowsNT:
      begin
        if AVersion.MajorVersion < 5 then
          Result := 'NT'
        else if AVersion.MajorVersion = 5 then
        begin
          if AVersion.MinorVersion = 0 then
            Result := '2000'
          else if AVersion.MinorVersion = 1 then
            Result := 'XP'
          else if AVersion.MinorVersion = 2 then
            Result := 'Server 2003';
        end
        else if AVersion.MajorVersion = 6 then
        begin
          case AVersion.MinorVersion of
            0: Result := 'Vista';
            1: Result := '7';
            2: Result := '8';
            3: Result := '8.1';
          end;
        end
        else if AVersion.MajorVersion = 10 then
        begin
          if AVersion.BuildNumber >= 22000 then
            Result := '11'
          else
            Result := '10';
        end;
      end;
  else
    Result := 'Unknown OS';
  end;
end;

function TOperatingSystemInfo.Describe: TOperatingSystemDescription;
var
  LVersion: TOperatingSystemVersion;
  LBuild: Cardinal;
begin
  LVersion := FSource.Read;
  Result.Name := NameOf(LVersion);
  case LVersion.Family of
    osfWindows9x:
      begin
        Result.Kind := oskWindows95;
        Result.IsVistaOrNewer := False;
      end;
    osfWindowsNT:
      begin
        if LVersion.MajorVersion < 5 then
          Result.Kind := oskWindowsNT4
        else
          Result.Kind := oskWindows2000;
        Result.IsVistaOrNewer := LVersion.MajorVersion >= 6;
      end;
  else
    Result.Kind := oskUnknown;
    // the engine takes a system it does not know for a modern one
    Result.IsVistaOrNewer := True;
  end;

  // on Windows 9x the high word of the build number is the version
  if Result.Kind = oskWindows95 then
    LBuild := LVersion.BuildNumber and $FFFF
  else
    LBuild := LVersion.BuildNumber;
  SetLength(Result.Lines, 1);
  Result.Lines[0] := Format(' OS: Windows %s %u.%u (Build %u)',
    [Result.Name, LVersion.MajorVersion, LVersion.MinorVersion, LBuild]);
  if LVersion.ServicePack <> '' then
  begin
    SetLength(Result.Lines, 2);
    Result.Lines[1] := '     ' + LVersion.ServicePack;
  end;
end;

end.
