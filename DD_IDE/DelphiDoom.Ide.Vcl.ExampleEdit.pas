{******************************************************************************}
{                                                                              }
{  DD_IDE: the editor of the example of a library item                         }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Vcl.ExampleEdit;

interface

uses
  System.SysUtils,
  SynEdit,
  DelphiDoom.Ide.ExampleStore;

type
  /// <summary>
  ///   The small editor under the lists of the library panels. It shows the example of the item that
  ///   is selected and saves the one it leaves, through the example store (one
  ///   class for all the panels; it replaces seven copies of the same code)
  /// </summary>
  TIdeExampleSynEdit = class(TSynEdit)
  strict private
    FStore: TIdeExampleStore;
  public
    destructor Destroy; override;
    /// <summary>Gives the editor its store, which it owns from now on; the text can be changed only if the store allows it</summary>
    procedure UseStore(const AStore: TIdeExampleStore);
    /// <summary>The example of another item is shown</summary>
    procedure SelectExample(const AName: string);
    /// <summary>The text is saved as the example of the current item</summary>
    procedure SaveExample;
  end;

implementation

{ TIdeExampleSynEdit }

destructor TIdeExampleSynEdit.Destroy;
begin
  FreeAndNil(FStore);
  inherited Destroy;
end;

procedure TIdeExampleSynEdit.UseStore(const AStore: TIdeExampleStore);
begin
  FreeAndNil(FStore);
  FStore := AStore;
  ReadOnly := (FStore = nil) or FStore.ReadOnly;
end;

procedure TIdeExampleSynEdit.SelectExample(const AName: string);
var
  LText: string;
begin
  if FStore = nil then
    Exit;
  if FStore.Select(AName, Text, LText) then
    Text := LText;
end;

procedure TIdeExampleSynEdit.SaveExample;
begin
  if FStore <> nil then
    FStore.Save(Text);
end;

end.
