{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, known sounds and handles       }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.SfxRegistry;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Audio.Q3.Sfx, DelphiDoom.Audio.Q3.Intf, DelphiDoom.Audio.Q3.State,
  DelphiDoom.Audio.Q3.Loader;

type
  /// <summary>
  ///   s_knownSfx and the handles of Quake III: S_FindName, S_RegisterSound, S_memoryLoad.
  ///   A handle is the position in the table, so the first sound has handle 0, which is
  ///   also what S_RegisterSound answers for a sound that could not be loaded (as in the C)
  /// </summary>
  /// <remarks>
  ///   The lookup is a dictionary on the lower-cased name, not the 128-entry hash chains of
  ///   the C (same answers: names are compared without regard to case)
  /// </remarks>
  TQ3SfxRegistry = class
  strict private
    FState: TQ3SoundState;
    FLoader: TQ3SoundLoader;
    FSource: IQ3SoundFileSource;
    FSounds: TObjectList<TQ3Sfx>;
    FByName: TDictionary<string, TQ3Sfx>;
    function FindName(const AName: string): TQ3Sfx;
    function HandleOf(ASfx: TQ3Sfx): Integer;
  public
    /// <summary>The loader and the source may be nil if the sounds are only added with AddSound</summary>
    constructor Create(AState: TQ3SoundState; ALoader: TQ3SoundLoader;
      const ASource: IQ3SoundFileSource);
    destructor Destroy; override;
    /// <summary>S_RegisterSound: 0 if not started, name too long, or not loadable</summary>
    function RegisterSound(const AName: string): Integer;
    /// <summary>Adds a sound whose samples are already at the rate of the device</summary>
    function AddSound(const AName: string; const ASamples: TArray<SmallInt>;
      ALength: Integer): Integer;
    /// <summary>S_memoryLoad: loads the file if it was not tried yet</summary>
    procedure EnsureLoaded(ASfx: TQ3Sfx);
    function Count: Integer;
    /// <summary>nil if the handle is out of range (the C prints a warning and returns)</summary>
    function SfxOf(AHandle: Integer): TQ3Sfx;
  end;

implementation

uses
  DelphiDoom.Audio.Q3.Types;

const
  MAX_QPATH = 64;
  MAX_SFX = 4096;

{ TQ3SfxRegistry }

constructor TQ3SfxRegistry.Create(AState: TQ3SoundState; ALoader: TQ3SoundLoader;
  const ASource: IQ3SoundFileSource);
begin
  inherited Create;
  FState := AState;
  FLoader := ALoader;
  FSource := ASource;
  FSounds := TObjectList<TQ3Sfx>.Create(True);
  FByName := TDictionary<string, TQ3Sfx>.Create;
end;

destructor TQ3SfxRegistry.Destroy;
begin
  FByName.Free;
  FSounds.Free;
  inherited Destroy;
end;

function TQ3SfxRegistry.FindName(const AName: string): TQ3Sfx;
var
  LKey: string;
begin
  if AName = '' then
    raise EQ3SoundException.Create('S_FindName: empty name');
  if Length(AName) >= MAX_QPATH then
    raise EQ3SoundException.CreateFmt('Sound name too long: %s', [AName]);
  LKey := LowerCase(AName);
  if FByName.TryGetValue(LKey, Result) then
    Exit;
  if FSounds.Count = MAX_SFX then
    raise EQ3SoundException.Create('S_FindName: out of sfx_t');
  Result := TQ3Sfx.Create(AName);
  FSounds.Add(Result);
  FByName.Add(LKey, Result);
end;

function TQ3SfxRegistry.HandleOf(ASfx: TQ3Sfx): Integer;
begin
  Result := FSounds.IndexOf(ASfx);
end;

procedure TQ3SfxRegistry.EnsureLoaded(ASfx: TQ3Sfx);
var
  LBytes: TBytes;
  LSamples: TArray<SmallInt>;
  LLoaded: Boolean;
begin
  LLoaded := False;
  // player specific sounds ('*') are never loaded directly
  if (ASfx.Name <> '') and (ASfx.Name[1] <> '*') and Assigned(FLoader) and
    Assigned(FSource) and FSource.ReadFile(ASfx.Name, LBytes) then
    LLoaded := FLoader.Load(LBytes, FState.Dma.Speed, LSamples);
  if LLoaded then
  begin
    ASfx.SetSamples(LSamples, Length(LSamples));
    ASfx.LastTimeUsed := 0;
  end
  else
    ASfx.DefaultSound := True;
  ASfx.InMemory := True;
end;

function TQ3SfxRegistry.RegisterSound(const AName: string): Integer;
var
  LSfx: TQ3Sfx;
begin
  Result := 0;
  if not FState.SoundStarted then
    Exit;
  if Length(AName) >= MAX_QPATH then
    Exit;
  LSfx := FindName(AName);
  if Length(LSfx.Samples) > 0 then
  begin
    if not LSfx.DefaultSound then
      Result := HandleOf(LSfx);
    Exit;
  end;
  LSfx.InMemory := False;
  EnsureLoaded(LSfx);
  if not LSfx.DefaultSound then
    Result := HandleOf(LSfx);
end;

function TQ3SfxRegistry.AddSound(const AName: string; const ASamples: TArray<SmallInt>;
  ALength: Integer): Integer;
var
  LSfx: TQ3Sfx;
begin
  LSfx := FindName(AName);
  LSfx.SetSamples(ASamples, ALength);
  LSfx.InMemory := True;
  LSfx.DefaultSound := False;
  Result := HandleOf(LSfx);
end;

function TQ3SfxRegistry.Count: Integer;
begin
  Result := FSounds.Count;
end;

function TQ3SfxRegistry.SfxOf(AHandle: Integer): TQ3Sfx;
begin
  if (AHandle < 0) or (AHandle >= FSounds.Count) then
    Result := nil
  else
    Result := FSounds[AHandle];
end;

end.
