{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the skins of the   }
{  renderer                                                                    }
{                                                                              }
{  Port of RE_RegisterSkin, R_InitSkins and R_GetSkinByHandle of renderer\     }
{  tr_image.c. Based on the Quake III Arena GPL Source Code (id Software).      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.Skin.Registry;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf;

type
  /// <summary>
  ///   The skins of the renderer by handle: handle 0 is the default skin; a name already
  ///   registered (any case) gives its handle, or 0 if it gave no surface; a name that does not end
  ///   in ".skin" is a single shader; every new name takes a handle, even when it fails. The
  ///   parser, the text source and the log (may be nil) come from the constructor.
  /// </summary>
  TQ3SkinRegistry = class(TInterfacedObject, IQ3SkinRegistry)
  strict private
    type
      TEntry = record
        Name: AnsiString;
        Skin: IQ3Skin;
      end;
  strict private
    FSource: IQ3TextSource;
    FParser: IQ3SkinParser;
    FLog: ILog;
    FEntries: TList<TEntry>;
    procedure Warn(const AMessage: string);
  public
    constructor Create(const ASource: IQ3TextSource; const AParser: IQ3SkinParser; const ALog: ILog);
    destructor Destroy; override;
    function GetSkinCount: Integer;
    function RegisterSkin(const AName: AnsiString): Integer;
    function GetSkin(const AHandle: Integer): IQ3Skin;
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.TokenReader,
  DelphiDoom.Models.Q3Player.Skin.Skin;

const
  DEFAULT_SKIN_NAME = '<default skin>';
  SKIN_EXTENSION = '.skin';

constructor TQ3SkinRegistry.Create(const ASource: IQ3TextSource; const AParser: IQ3SkinParser; const ALog: ILog);
var
  LEntry: TEntry;
  LSurfaces: TArray<TQ3SkinSurface>;
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(AParser) then
    raise EArgumentNilException.Create('AParser');
  FSource := ASource;
  FParser := AParser;
  FLog := ALog;
  FEntries := TList<TEntry>.Create;
  // R_InitSkins: the default skin has one surface and the default shader
  SetLength(LSurfaces, 1);
  LSurfaces[0].Name := '';
  LSurfaces[0].Shader := '';
  LEntry.Name := DEFAULT_SKIN_NAME;
  LEntry.Skin := TQ3Skin.Create(DEFAULT_SKIN_NAME, LSurfaces);
  FEntries.Add(LEntry);
end;

destructor TQ3SkinRegistry.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TQ3SkinRegistry.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TQ3SkinRegistry.GetSkinCount: Integer;
begin
  Result := FEntries.Count;
end;

function TQ3SkinRegistry.RegisterSkin(const AName: AnsiString): Integer;
var
  LHandle: Integer;
  LEntry: TEntry;
  LText: AnsiString;
  LSurfaces: TArray<TQ3SkinSurface>;
begin
  Result := 0;
  if AName = '' then
  begin
    Warn(SQ3SkinEmptyName);
    Exit;
  end;
  if Length(AName) >= Q3_MAX_QPATH then
  begin
    Warn(SQ3SkinNameTooLong);
    Exit;
  end;

  // see if the skin is already loaded
  for LHandle := 1 to FEntries.Count - 1 do
    if TQ3TokenReader.SameWord(FEntries[LHandle].Name, AName) then
    begin
      if Assigned(FEntries[LHandle].Skin) then
        Result := LHandle;
      Exit;
    end;

  if FEntries.Count = Q3_MAX_SKINS then
  begin
    Warn(Format(SQ3SkinMaxSkins, [string(AName)]));
    Exit;
  end;

  // a new skin takes its handle even if it fails: it stays in the list as a skin without surfaces
  LHandle := FEntries.Count;
  LEntry.Name := AName;
  LEntry.Skin := nil;
  FEntries.Add(LEntry);

  // not a .skin file: a single shader (strcmp, so the case counts)
  if (Length(AName) < Length(SKIN_EXTENSION)) or
    (Copy(AName, Length(AName) - Length(SKIN_EXTENSION) + 1, Length(SKIN_EXTENSION)) <> SKIN_EXTENSION) then
  begin
    SetLength(LSurfaces, 1);
    LSurfaces[0].Name := '';
    LSurfaces[0].Shader := AName;
    LEntry.Skin := TQ3Skin.Create(AName, LSurfaces);
    FEntries[LHandle] := LEntry;
    Exit(LHandle);
  end;

  LText := FSource.ReadText(string(AName));
  if LText = '' then
    Exit;
  LEntry.Skin := FParser.Parse(AName, LText);
  if not Assigned(LEntry.Skin) then
    Exit;
  FEntries[LHandle] := LEntry;
  Result := LHandle;
end;

function TQ3SkinRegistry.GetSkin(const AHandle: Integer): IQ3Skin;
begin
  if (AHandle < 1) or (AHandle >= FEntries.Count) or not Assigned(FEntries[AHandle].Skin) then
    Result := FEntries[0].Skin
  else
    Result := FEntries[AHandle].Skin;
end;

end.
