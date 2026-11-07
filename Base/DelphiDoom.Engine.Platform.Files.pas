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
  public
    /// <remarks>Raises EArgumentNilException if AStore is nil</remarks>
    constructor Create(const AStore: IFileStore);
    function WriteFile(const AName: string; const ASource: Pointer; const ALength: Integer): Boolean;
    function AppendFile(const AName: string; const ASource: Pointer; const ALength: Integer): Integer;
    function ReadFile(const AName: string; var ABuffer: Pointer): Integer;
  end;

implementation

uses
  i_system,
  z_zone,
  DelphiDoom.Platform.Types;

const
  SStoreIsNil = 'TEngineFiles: the store of the files is nil';
  SReadFailed = 'M_ReadFile(): Could not read file %s';

{ TEngineFiles }

constructor TEngineFiles.Create(const AStore: IFileStore);
begin
  inherited Create;
  if not Assigned(AStore) then
    raise EArgumentNilException.Create(SStoreIsNil);
  FStore := AStore;
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
  // the callers free it with Z_Free
  ABuffer := Z_Malloc(Result, PU_STATIC, nil);
  if Result > 0 then
    Move(LData[0], ABuffer^, Result);
end;

end.
