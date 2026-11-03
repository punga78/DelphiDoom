{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - where the engine gets its IZlib from                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Provider;

interface

uses
  DelphiDoom.Zlib.Intf, DelphiDoom.Zlib.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TZlibClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on TZlibEngine linked in the executable, so
  ///   no DLL is needed. To use DDZlib.dll (or a fake in the tests) call Use
  ///   with the IZlib obtained from TZlibLoader before the first use
  /// </remarks>
  TZlibProvider = class
  private
    class var FZlib: IZlib;
    class var FClient: TZlibClient;
  public
    /// <summary>
    ///   The client shared by the engine; created on first use
    /// </summary>
    class function Client: TZlibClient; static;

    /// <summary>
    ///   Replaces the zlib implementation (DLL or fake). Pass nil to go back
    ///   to the engine linked in the executable
    /// </summary>
    class procedure Use(const AZlib: IZlib); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Zlib.Engine;

{ TZlibProvider }

class function TZlibProvider.Client: TZlibClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FZlib) then
      FZlib := TZlibEngine.Create;
    FClient := TZlibClient.Create(FZlib);
  end;
  Result := FClient;
end;

class procedure TZlibProvider.Use(const AZlib: IZlib);
begin
  FreeAndNil(FClient);
  FZlib := AZlib;
end;

class procedure TZlibProvider.Release;
begin
  FreeAndNil(FClient);
  FZlib := nil;
end;

initialization

finalization
  TZlibProvider.Release;

end.
