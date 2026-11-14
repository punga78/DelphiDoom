{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - importer of the classes of the scripts            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It was the part of ps_import.pas that does not name the engine.             }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit DelphiDoom.ScriptHost.ClassImporter;
{$I PascalScript.inc}

interface

uses
  ps_runtime,
  DelphiDoom.ScriptHost.Services.Intf;

type
  /// <summary>The importer of the classes at runtime: TObject and the classes of the catalog</summary>
  TPSDoomRuntimeClassImporter = class(TPSRuntimeClassImporter)
  private
    FServices: IScriptHostServices;
  public
    constructor CreateDoomImporter(const AServices: IScriptHostServices); virtual;
    property Services: IScriptHostServices read FServices;
  end;

implementation

type
  TRTLObject = class(TObject)
  public
    procedure FakeFree;
  end;

//==============================================================================
//
// TRTLObject.FakeFree
//
//==============================================================================
procedure TRTLObject.FakeFree;
begin
  // JVAL: Do nothing :)
  // Explanation:
  //   Since we can only use imported classes usage of Free procedure inside
  //   script could cause problems. Instead we use a stub method, and we leave
  //   the actual Free of the objects to the calling Application.
end;

//==============================================================================
//
// TPSDoomRuntimeClassImporter.CreateDoomImporter
//
//==============================================================================
constructor TPSDoomRuntimeClassImporter.CreateDoomImporter(const AServices: IScriptHostServices);
begin
  inherited Create;
  FServices := AServices;
  with Add2(TRTLObject, '!TOBJECT') do
  begin
    RegisterConstructor(@TRTLObject.Create, 'Create');
    RegisterMethod(@TRTLObject.FakeFree, 'Free');
  end;
  FServices.Classes.RegisterRuntime(Self);
end;

end.
