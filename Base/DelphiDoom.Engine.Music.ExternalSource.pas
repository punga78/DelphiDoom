{******************************************************************************}
{                                                                              }
{  DelphiDoom: the files of the external songs, from the directories and PAKs   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Music.ExternalSource;

interface

uses
  System.SysUtils,
  DelphiDoom.Audio.Intf;

type
  /// <summary>
  ///   A song in the zone memory (PU_MUSIC): the zone writes nil in Data when it takes the
  ///   memory back, and the clip frees what is still there when it dies
  /// </summary>
  TEngineExternalMusicClip = class(TInterfacedObject, IExternalMusicClip)
  strict private
    FData: Pointer;
    FSize: Integer;
  public
    constructor Create(const AContent: TBytes);
    destructor Destroy; override;
    function GetData: Pointer;
    function GetSize: Integer;
    function GetIsLoaded: Boolean;
  end;

  /// <summary>Looks for the file as the engine does: preferred directories of the game, then the PAKs</summary>
  TEngineExternalMusicSource = class(TInterfacedObject, IExternalMusicSource)
  public
    function TryLoad(const AFileName: string): IExternalMusicClip;
  end;

implementation

uses
  d_delphi,
  doomdef,
  z_zone,
  w_pak;

{ TEngineExternalMusicClip }

constructor TEngineExternalMusicClip.Create(const AContent: TBytes);
begin
  inherited Create;
  FSize := Length(AContent);
  FData := Z_Malloc(FSize, PU_MUSIC, @FData);
  if FSize > 0 then
    Move(AContent[0], FData^, FSize);
end;

destructor TEngineExternalMusicClip.Destroy;
begin
  if FData <> nil then
    Z_Free(FData);
  inherited Destroy;
end;

function TEngineExternalMusicClip.GetData: Pointer;
begin
  Result := FData;
end;

function TEngineExternalMusicClip.GetSize: Integer;
begin
  Result := FSize;
end;

function TEngineExternalMusicClip.GetIsLoaded: Boolean;
begin
  Result := FData <> nil;
end;

{ TEngineExternalMusicSource }

function TEngineExternalMusicSource.TryLoad(const AFileName: string): IExternalMusicClip;
var
  LStream: TPakStream;
  LContent: TBytes;
begin
  Result := nil;
  LStream := TPakStream.Create(AFileName, pm_prefered, gamedirectories);
  try
    if LStream.IOResult <> 0 then
      Exit;
    LStream.Seek(0, sFromBeginning);
    SetLength(LContent, LStream.Size);
    if Length(LContent) > 0 then
      LStream.Read(LContent[0], Length(LContent));
  finally
    LStream.Free;
  end;
  Result := TEngineExternalMusicClip.Create(LContent);
end;

end.
