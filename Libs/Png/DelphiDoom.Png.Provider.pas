{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - where the engine gets its IPng from                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Provider;

interface

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TPngClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on TPngEngine linked in the executable, so
  ///   no DLL is needed. To use DDPng.dll (or a fake in the tests) call Use
  ///   with the IPng obtained from TPngLoader before the first use
  /// </remarks>
  TPngProvider = class
  private
    class var FPng: IPng;
    class var FClient: TPngClient;
  public
    /// <summary>
    ///   The client shared by the engine; created on first use
    /// </summary>
    class function Client: TPngClient; static;

    /// <summary>
    ///   Replaces the PNG implementation (DLL or fake). Pass nil to go back
    ///   to the engine linked in the executable
    /// </summary>
    class procedure Use(const APng: IPng); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Zlib.Provider, DelphiDoom.Png.Engine;

{ TPngProvider }

class function TPngProvider.Client: TPngClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FPng) then
      FPng := TPngEngine.Create(TZlibProvider.Zlib);
    FClient := TPngClient.Create(FPng);
  end;
  Result := FClient;
end;

class procedure TPngProvider.Use(const APng: IPng);
begin
  FreeAndNil(FClient);
  FPng := APng;
end;

class procedure TPngProvider.Release;
begin
  FreeAndNil(FClient);
  FPng := nil;
end;

initialization

finalization
  TPngProvider.Release;

end.
