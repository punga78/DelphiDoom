{******************************************************************************}
{                                                                              }
{  DelphiDoom: MikMod - where the engine gets its IMikMod from                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mikmod.Provider;

interface

uses
  DelphiDoom.Mikmod.Intf, DelphiDoom.Mikmod.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TMikModClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on TMikModEngine linked in the executable, so
  ///   no DLL is needed. To use DDMikmod.dll (or a fake in the tests) call Use
  ///   with the IMikMod obtained from TMikModLoader before the first use
  /// </remarks>
  TMikModProvider = class
  private
    class var FMikMod: IMikMod;
    class var FClient: TMikModClient;
  public
    /// <summary>
    ///   The client shared by the engine; created on first use
    /// </summary>
    class function Client: TMikModClient; static;

    /// <summary>
    ///   Replaces the MikMod implementation (DLL or fake). Pass nil to go back
    ///   to the engine linked in the executable
    /// </summary>
    class procedure Use(const AMikMod: IMikMod); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Mikmod.Engine;

{ TMikModProvider }

class function TMikModProvider.Client: TMikModClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FMikMod) then
      FMikMod := TMikModEngine.Create;
    FClient := TMikModClient.Create(FMikMod);
  end;
  Result := FClient;
end;

class procedure TMikModProvider.Use(const AMikMod: IMikMod);
begin
  FreeAndNil(FClient);
  FMikMod := AMikMod;
end;

class procedure TMikModProvider.Release;
begin
  FreeAndNil(FClient);
  FMikMod := nil;
end;

initialization

finalization
  TMikModProvider.Release;

end.
