{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the folder of the data of a program           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.DataFolder;

interface

uses
  System.SysUtils, DelphiDoom.Platform.DataFolder.Intf;

type
  /// <summary>
  ///   IDataFolderLocator on the layout of the outputs: bin\Win32|Win64\Debug|Release\Area for the executables,
  ///   bin\Area for the data (bin itself for the programs that have no area, like the Launcher)
  /// </summary>
  TDataFolderLocator = class(TInterfacedObject, IDataFolderLocator)
  strict private
    FProbe: IDataFolderProbe;
    class function IsPlatform(const ASegment: string): Boolean; static;
    class function IsConfiguration(const ASegment: string): Boolean; static;
    /// <summary>
    ///   The folder bin\Area of the executable folder, or empty when the executable is not in
    ///   bin\Platform\Configuration\Area
    /// </summary>
    class function DataFolderOfLayout(const AExecutableFolder: string): string; static;
  public
    constructor Create(const AProbe: IDataFolderProbe);
    function Locate(const AExecutableFolder, ARequestedFolder: string): string;
  end;

implementation

uses
  System.Classes;

const
  SProbeIsNil = 'TDataFolderLocator: the probe of the disk is nil';
  SRequestedFolderMissing = 'The data folder %s (option -data) does not exist';
  BIN_FOLDER_NAME = 'bin';

constructor TDataFolderLocator.Create(const AProbe: IDataFolderProbe);
begin
  inherited Create;
  if not Assigned(AProbe) then
    raise EArgumentNilException.Create(SProbeIsNil);
  FProbe := AProbe;
end;

class function TDataFolderLocator.IsPlatform(const ASegment: string): Boolean;
begin
  Result := SameText(ASegment, 'Win32') or SameText(ASegment, 'Win64');
end;

class function TDataFolderLocator.IsConfiguration(const ASegment: string): Boolean;
begin
  Result := SameText(ASegment, 'Debug') or SameText(ASegment, 'Release');
end;

class function TDataFolderLocator.DataFolderOfLayout(const AExecutableFolder: string): string;
var
  LSegments: TStringList;
  LIndex: Integer;
  LCopy: Integer;
begin
  Result := '';
  LSegments := TStringList.Create;
  try
    LSegments.Delimiter := PathDelim;
    LSegments.StrictDelimiter := True;
    LSegments.DelimitedText := ExcludeTrailingPathDelimiter(AExecutableFolder);
    // from the end: the nearest bin\Platform\Configuration is the one of this executable
    for LIndex := LSegments.Count - 2 downto 1 do
    begin
      if SameText(LSegments[LIndex - 1], BIN_FOLDER_NAME) and IsPlatform(LSegments[LIndex]) and
        IsConfiguration(LSegments[LIndex + 1]) then
      begin
        // everything up to bin, then the area (the folders after the configuration)
        for LCopy := 0 to LIndex - 1 do
          Result := Result + LSegments[LCopy] + PathDelim;
        for LCopy := LIndex + 2 to LSegments.Count - 1 do
          Result := Result + LSegments[LCopy] + PathDelim;
        Break;
      end;
    end;
  finally
    LSegments.Free;
  end;
end;

function TDataFolderLocator.Locate(const AExecutableFolder, ARequestedFolder: string): string;
var
  LLayoutFolder: string;
begin
  if ARequestedFolder <> '' then
  begin
    Result := IncludeTrailingPathDelimiter(FProbe.FullPath(ARequestedFolder));
    if not FProbe.FolderExists(Result) then
      raise EDataFolderException.CreateFmt(SRequestedFolderMissing, [Result]);
    Exit;
  end;

  Result := IncludeTrailingPathDelimiter(AExecutableFolder);
  // a program copied with its data (or built before the layout) keeps working where it is
  if FProbe.HasGameFiles(Result) then
    Exit;
  LLayoutFolder := DataFolderOfLayout(Result);
  if (LLayoutFolder <> '') and FProbe.FolderExists(LLayoutFolder) then
    Result := LLayoutFolder;
end;

end.
