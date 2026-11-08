{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - whole files over the store of Libs\Platform            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Platform.Files;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  DelphiDoom.Platform.Intf,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Engine.Platform.Intf;

type
  /// <summary>
  ///   M_WriteFile, M_AppendFile and M_ReadFile of the old m_misc.pas over the IFileStore of
  ///   Libs\Platform: what is read goes to the zone memory, a file that can not be read is an
  ///   I_Error
  /// </summary>
  TEngineFiles = class(TInterfacedObject, IEngineFiles)
  strict private
    FStore: IFileStore;
    FZone: IZoneAllocator;
  public
    /// <param name="AZone">Holds what ReadFile reads</param>
    /// <remarks>Raises EArgumentNilException if AStore or AZone is nil</remarks>
    constructor Create(const AStore: IFileStore; const AZone: IZoneAllocator);
    function WriteFile(const AName: string; const ASource: Pointer; const ALength: Integer): Boolean;
    function AppendFile(const AName: string; const ASource: Pointer; const ALength: Integer): Integer;
    function ReadFile(const AName: string; var ABuffer: Pointer): Integer;
  end;

implementation

uses
  i_system,
  DelphiDoom.Zone.Types,
  DelphiDoom.Platform.Types;

const
  SStoreIsNil = 'TEngineFiles: the store of the files is nil';
  SReadFailed = 'M_ReadFile(): Could not read file %s';

{ TEngineFiles }

constructor TEngineFiles.Create(const AStore: IFileStore; const AZone: IZoneAllocator);
begin
  inherited Create;
  if not Assigned(AStore) then
    raise EArgumentNilException.Create(SStoreIsNil);
  if not Assigned(AZone) then
    raise EArgumentNilException.Create('AZone');
  FStore := AStore;
  FZone := AZone;
end;

function TEngineFiles.WriteFile(const AName: string; const ASource: Pointer;
  const ALength: Integer): Boolean;
begin
  Result := FStore.Write(AName, ASource, ALength);
end;

function TEngineFiles.AppendFile(const AName: string; const ASource: Pointer;
  const ALength: Integer): Integer;
begin
  Result := FStore.Append(AName, ASource, ALength);
end;

function TEngineFiles.ReadFile(const AName: string; var ABuffer: Pointer): Integer;
var
  LData: TBytes;
begin
  try
    LData := FStore.Read(AName);
  except
    on EPlatformException do
      I_Error(SReadFailed, [AName]);
  end;

  Result := Length(LData);
  // the callers free it with Z_Free (the zone is the one of z_zone)
  ABuffer := FZone.Allocate(Result, ZONE_TAG_STATIC, nil);
  if Result > 0 then
    Move(LData[0], ABuffer^, Result);
end;

end.
