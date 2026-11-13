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
  DelphiDoom.Sndfile.Intf, DelphiDoom.Sndfile.Factory.Intf,
  DelphiDoom.Sndfile.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TSndfileClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on the engine built by the ISndfileFactory given with UseFactory
  ///   (Libs\Sound registers the Pascal engine, so no DLL is needed). The provider does not know
  ///   Libs\Sound: the dependency goes only from Sound to Sndfile. To use DDSndfile.dll (or a fake in the tests) call Use
  ///   with the ISndfile obtained from TSndfileLoader before the first use
  /// </remarks>
  TSndfileProvider = class
  private
    class var FSndfile: ISndfile;
    class var FFactory: ISndfileFactory;
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
    ///   Gives the factory of the default engine, used when Use was not called
    /// </summary>
    class procedure UseFactory(const AFactory: ISndfileFactory); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils;

{ TSndfileProvider }

class function TSndfileProvider.Client: TSndfileClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FSndfile) then
    begin
      // the factory is registered by Libs\Sound (the decoders in Pascal);
      // TSndfileProvider.Use gives another engine (the C one, a fake)
      if not Assigned(FFactory) then
        raise ESndfileException.CreateCodeDetail(SNDFILE_ERR_INVALID_ARGUMENT,
          'no engine factory registered (ISndfileFactory)');
      FSndfile := FFactory.CreateEngine;
    end;
    FClient := TSndfileClient.Create(FSndfile);
  end;
  Result := FClient;
end;

class procedure TSndfileProvider.Use(const ASndfile: ISndfile);
begin
  FreeAndNil(FClient);
  FSndfile := ASndfile;
end;

class procedure TSndfileProvider.UseFactory(const AFactory: ISndfileFactory);
begin
  FFactory := AFactory;
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
