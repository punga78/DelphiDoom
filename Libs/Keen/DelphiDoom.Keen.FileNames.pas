{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the names of the files of the game                }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.FileNames;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Which files hold the game. The shareware 1.13 and the 1.93 of the source code both open KDREAMS.EGA,
  ///   KDREAMS.MAP and KDREAMS.AUD (id_ca.c), and have the headers and the dictionaries linked into the
  ///   program as the .KDR files of the folder "static": here they are files next to the data. The
  ///   alternatives (the names the id engine of the next games gave to the same files) are tried after
  /// </summary>
  /// <remarks>
  ///   EGAHEAD, EGADICT, AUDIOHHD and AUDIODCT of the version 1.13 and of the source code (1.93) are the
  ///   same. MAPHEAD and MAPDICT are not: the maps of the 1.13 need the ones of the 1.13
  /// </remarks>
  TKeenFileNames = class
  public
    class function GraphicsData: TArray<string>; static;
    class function GraphicsHeader: TArray<string>; static;
    class function GraphicsDictionary: TArray<string>; static;
    class function MapData: TArray<string>; static;
    class function MapHeader: TArray<string>; static;
    class function MapDictionary: TArray<string>; static;
    class function AudioData: TArray<string>; static;
    class function AudioHeader: TArray<string>; static;
    class function AudioDictionary: TArray<string>; static;
    /// <summary>The first of the names that exists; EKeenFileNotFoundException if none does</summary>
    class function Resolve(const AFiles: IKeenDataFiles; const ACandidates: TArray<string>): string; static;
  end;

implementation

{ TKeenFileNames }

class function TKeenFileNames.GraphicsData: TArray<string>;
begin
  Result := ['KDREAMS.EGA', 'EGAGRAPH.KDR'];
end;

class function TKeenFileNames.GraphicsHeader: TArray<string>;
begin
  Result := ['EGAHEAD.KDR'];
end;

class function TKeenFileNames.GraphicsDictionary: TArray<string>;
begin
  Result := ['EGADICT.KDR'];
end;

class function TKeenFileNames.MapData: TArray<string>;
begin
  Result := ['KDREAMS.MAP', 'GAMEMAPS.KDR'];
end;

class function TKeenFileNames.MapHeader: TArray<string>;
begin
  Result := ['MAPHEAD.KDR'];
end;

class function TKeenFileNames.MapDictionary: TArray<string>;
begin
  Result := ['MAPDICT.KDR'];
end;

class function TKeenFileNames.AudioData: TArray<string>;
begin
  Result := ['KDREAMS.AUD', 'AUDIOT.KDR'];
end;

class function TKeenFileNames.AudioHeader: TArray<string>;
begin
  Result := ['AUDIOHHD.KDR'];
end;

class function TKeenFileNames.AudioDictionary: TArray<string>;
begin
  Result := ['AUDIODCT.KDR'];
end;

class function TKeenFileNames.Resolve(const AFiles: IKeenDataFiles;
  const ACandidates: TArray<string>): string;
var
  LName: string;
begin
  for LName in ACandidates do
    if AFiles.Exists(LName) then
      Exit(LName);
  if Length(ACandidates) = 1 then
    raise EKeenFileNotFoundException.CreateFmt(SKeenFileMissing, [ACandidates[0]]);
  raise EKeenFileNotFoundException.CreateFmt(SKeenFileMissingAny,
    [string.Join(', ', ACandidates)]);
end;

end.
