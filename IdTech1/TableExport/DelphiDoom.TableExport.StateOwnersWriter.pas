{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - which things own which states             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.StateOwnersWriter;

interface

uses
  DelphiDoom.TableExport.Intf;

type
  /// <summary>
  ///   Writes a line "S_NAME="Owner" "Owner"" for every state of the game
  /// </summary>
  TExportStateOwnersWriter = class(TInterfacedObject, IExportStateOwnersWriter)
  strict private
    FStates: IExportStateSource;
    FLookups: IExportLookups;
  public
    /// <exception cref="EArgumentNilException">A source is nil</exception>
    constructor Create(const AStates: IExportStateSource; const ALookups: IExportLookups);
    function Write: string;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Text;

{ TExportStateOwnersWriter }

constructor TExportStateOwnersWriter.Create(const AStates: IExportStateSource;
  const ALookups: IExportLookups);
begin
  inherited Create;
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(ALookups) then
    raise EArgumentNilException.Create('ALookups');
  FStates := AStates;
  FLookups := ALookups;
end;

function TExportStateOwnersWriter.Write: string;
var
  LIndex: Integer;
  LOwner: Integer;
  LOwners: string;
begin
  Result := '';
  for LIndex := 0 to FStates.Count - 1 do
  begin
    LOwners := '';
    for LOwner in FStates.Owners(LIndex) do
      LOwners := LOwners + '"' + TExportText.Trim(FLookups.ThingName(LOwner)) + '" ';
    LOwners := TExportText.Trim(LOwners);
    Result := Result + FStates.StateName(LIndex) + '=' + LOwners + #13#10;
  end;
end;

end.
