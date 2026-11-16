{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the songs that replace the ones of the WAD       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.ExternalMusicCache;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Audio.Intf;

type
  /// <summary>
  ///   Port of S_TryLoadExternalMusic: a song of the WAD can be replaced by a file of the same
  ///   name outside it (MOD, S3M, IT, XM). Found clips are remembered by name, without
  ///   distinguishing upper and lower case; a file that was not found is searched every time
  /// </summary>
  TExternalMusicCache = class(TInterfacedObject, IExternalMusicCache)
  strict private
    FSource: IExternalMusicSource;
    FExtensions: TArray<string>;
    FClips: TDictionary<string, IExternalMusicClip>;
  public
    /// <summary>AExtensions are tried in order, each with its dot (.MOD)</summary>
    constructor Create(const ASource: IExternalMusicSource; const AExtensions: TArray<string>);
    destructor Destroy; override;
    function Find(const AMusicName: string): IExternalMusicClip;
    procedure Clear;
  end;

implementation

const
  SSourceMissing = 'TExternalMusicCache: the source of the files is nil';

{ TExternalMusicCache }

constructor TExternalMusicCache.Create(const ASource: IExternalMusicSource;
  const AExtensions: TArray<string>);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create(SSourceMissing);
  FSource := ASource;
  FExtensions := Copy(AExtensions);
  FClips := TDictionary<string, IExternalMusicClip>.Create;
end;

destructor TExternalMusicCache.Destroy;
begin
  FClips.Free;
  inherited Destroy;
end;

function TExternalMusicCache.Find(const AMusicName: string): IExternalMusicClip;
var
  LKey: string;
  LExtension: string;
begin
  LKey := UpperCase(AMusicName);
  if FClips.TryGetValue(LKey, Result) then
  begin
    if Result.IsLoaded then
      Exit;
    // the memory went back to the engine: the file is read again
    FClips.Remove(LKey);
  end;

  for LExtension in FExtensions do
  begin
    Result := FSource.TryLoad(AMusicName + LExtension);
    if Assigned(Result) then
    begin
      FClips.AddOrSetValue(LKey, Result);
      Exit;
    end;
  end;
  Result := nil;
end;

procedure TExternalMusicCache.Clear;
begin
  FClips.Clear;
end;

end.
