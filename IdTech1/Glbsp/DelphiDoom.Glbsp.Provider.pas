{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - where the engine gets its IGlbsp from                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Provider;

interface

uses
  DelphiDoom.Glbsp.Intf, DelphiDoom.Glbsp.Client;

type
  /// <summary>
  ///   Gives the rest of the engine one shared TGlbspClient
  /// </summary>
  /// <remarks>
  ///   By default the client works on TGlbspEngine linked in the executable, so
  ///   no DLL is needed. To use DDGlbsp.dll (or a fake in the tests) call Use
  ///   with the IGlbsp obtained from TGlbspLoader before the first use
  /// </remarks>
  TGlbspProvider = class
  private
    class var FGlbsp: IGlbsp;
    class var FClient: TGlbspClient;
  public
    /// <summary>
    ///   The client shared by the engine; created on first use
    /// </summary>
    class function Client: TGlbspClient; static;

    /// <summary>
    ///   Replaces the glbsp implementation (DLL or fake). Pass nil to go back
    ///   to the engine linked in the executable
    /// </summary>
    class procedure Use(const AGlbsp: IGlbsp); static;

    /// <summary>
    ///   Frees the shared client; called at shutdown
    /// </summary>
    class procedure Release; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Glbsp.Engine;

{ TGlbspProvider }

class function TGlbspProvider.Client: TGlbspClient;
begin
  if not Assigned(FClient) then
  begin
    if not Assigned(FGlbsp) then
      FGlbsp := TGlbspEngine.Create;
    FClient := TGlbspClient.Create(FGlbsp);
  end;
  Result := FClient;
end;

class procedure TGlbspProvider.Use(const AGlbsp: IGlbsp);
begin
  FreeAndNil(FClient);
  FGlbsp := AGlbsp;
end;

class procedure TGlbspProvider.Release;
begin
  FreeAndNil(FClient);
  FGlbsp := nil;
end;

initialization

finalization
  TGlbspProvider.Release;

end.
