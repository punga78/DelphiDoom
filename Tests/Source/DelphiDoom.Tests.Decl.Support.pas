{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - the shared setup             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Support;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Memory,
  DelphiDoom.Tests.Scanner.IdFakes;

type
  /// <summary>A manager with the standard types over files in memory, and the log it writes to</summary>
  TDeclKit = class
  strict private
    FSource: TDeclMemorySource;
    FSourceIntf: IInterface;
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FManager: IDeclManager;
  public
    constructor Create(const AStandard: Boolean = True);
    destructor Destroy; override;
    /// <summary>Builds the manager after the files are added (a folder is read when it is registered)</summary>
    procedure Start(const AStandard: Boolean = True; const ALoadFolders: Boolean = True);
    property Source: TDeclMemorySource read FSource;
    property Manager: IDeclManager read FManager;
    function Lines: TStrings;
    function LogText: string;
  end;

implementation

uses
  DelphiDoom.Decl.Factory;

{ TDeclKit }

constructor TDeclKit.Create(const AStandard: Boolean);
begin
  inherited Create;
  FSource := TDeclMemorySource.Create;
  FSourceIntf := FSource;
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
end;

destructor TDeclKit.Destroy;
begin
  FManager := nil;
  FLog := nil;
  FSourceIntf := nil;
  inherited Destroy;
end;

procedure TDeclKit.Start(const AStandard: Boolean; const ALoadFolders: Boolean);
begin
  if AStandard then
    FManager := TDeclFactory.CreateStandardManager(FSource, FLog, ALoadFolders)
  else
    FManager := TDeclFactory.CreateManager(FSource, FLog);
end;

function TDeclKit.Lines: TStrings;
begin
  Result := FLogObject.Lines;
end;

function TDeclKit.LogText: string;
begin
  Result := FLogObject.Lines.Text;
end;

end.
