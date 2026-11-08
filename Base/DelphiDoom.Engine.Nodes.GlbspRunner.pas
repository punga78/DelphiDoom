{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - runs glBSP to build the GL nodes                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Nodes.GlbspRunner;

interface

uses
  DelphiDoom.Glbsp.Client,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Engine.Nodes.Intf;

type
  /// <summary>
  ///   The glBSP part of the old nd_main: it replaces ND_RunGlbsp and gld_BuildNodes, with the
  ///   Hexen option decided by the composition root instead of an IFDEF
  /// </summary>
  TEngineGlbspRunner = class(TInterfacedObject, IEngineGlbspRunner)
  strict private
    FHexen: Boolean;
    FLog: ILog;
  public
    /// <summary>AHexen: the maps are in the Hexen format and glBSP is told so; EArgumentNilException if ALog is nil</summary>
    constructor Create(AHexen: Boolean; const ALog: ILog);
    function Run(const AWadFile, AGwaFile: string; const AOptions: TGlbspOptions): Boolean;
    function BuildGlFriendly(const AWadFile, AGwaFile: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.Glbsp.Intf,
  DelphiDoom.Glbsp.Provider;

constructor TEngineGlbspRunner.Create(AHexen: Boolean; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FHexen := AHexen;
  FLog := ALog;
end;

function TEngineGlbspRunner.Run(const AWadFile, AGwaFile: string;
  const AOptions: TGlbspOptions): Boolean;
begin
  try
    TGlbspProvider.Client.BuildNodes(AWadFile, AGwaFile, AOptions, GLBSP_MAX_TIMEOUT_MS);
    Result := True;
  except
    on E: EGlbspException do
    begin
      Result := False;
      printf('%s'#13#10, [E.Message]);
    end;
  end;
  if TGlbspProvider.Client.Output <> '' then
    printf('%s', [TGlbspProvider.Client.Output]);
end;

function TEngineGlbspRunner.BuildGlFriendly(const AWadFile, AGwaFile: string): Boolean;
var
  LOptions: TGlbspOptions;
begin
  printf(#13#10'  gld_BuildNodes: Building GL-Friendly nodes for %s'#13#10, [AWadFile]);
  LOptions := [goQuiet, goNoProgress];
  if FHexen then
    Include(LOptions, goHexen);
  Result := Run(AWadFile, AGwaFile, LOptions);
  printf(#13#10);
  if not Result then
    FLog.Warning(Format('gld_BuildNodes(): Failed to build GL-Friendly nodes for %s'#13#10,
      [AWadFile]));
end;

end.
