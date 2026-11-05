{******************************************************************************}
{                                                                              }
{  DelphiDoom: libsndfile - where the engine gets its ISndfile from                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sndfile.Provider;

interface

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Sndfile.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TSndfileClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on TSndfileEngine linked in the executable, so
  ///   no DLL is needed. To use DDSndfile.dll (or a fake in the tests) call Use
  ///   with the ISndfile obtained from TSndfileLoader before the first use
  /// </remarks>
  TSndfileProvider = class
  private
    class var FSndfile: ISndfile;
    class var FClient: TSndfileClient;
  public
    /// <summary>
    ///   The client shared by the engine; created on first use
    /// </summary>
    class function Client: TSndfileClient; static;

    /// <summary>
    ///   Replaces the libsndfile implementation (DLL or fake). Pass nil to go back
    ///   to the engine linked in the executable
    /// </summary>
    class procedure Use(const ASndfile: ISndfile); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Sound.Factory;

{ TSndfileProvider }

class function TSndfileProvider.Client: TSndfileClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FSndfile) then
      // the decoders in Pascal; TSndfileProvider.Use gives another engine (the C one, a fake)
      FSndfile := TSoundFactory.CreateEngine;
    FClient := TSndfileClient.Create(FSndfile);
  end;
  Result := FClient;
end;

class procedure TSndfileProvider.Use(const ASndfile: ISndfile);
begin
  FreeAndNil(FClient);
  FSndfile := ASndfile;
end;

class procedure TSndfileProvider.Release;
begin
  FreeAndNil(FClient);
  FSndfile := nil;
end;

initialization

finalization
  TSndfileProvider.Release;

end.
