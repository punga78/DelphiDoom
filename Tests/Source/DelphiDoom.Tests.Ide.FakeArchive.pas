{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - a pk3 archive in memory              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FakeArchive;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Ide.Intf;

type
  /// <summary>Remembers the files that were added and the name it was saved with</summary>
  TFakeIdeArchive = class(TInterfacedObject, IIdeArchive)
  public
    Names: TStringList;
    Contents: TStringList;
    Dates: array of TDateTime;
    SavedAs: string;
    FailOnSave: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(const AName: string; const AData: AnsiString; const ADate: TDateTime);
    procedure SaveToFile(const AFileName: string);
  end;

implementation

{ TFakeIdeArchive }

constructor TFakeIdeArchive.Create;
begin
  inherited Create;
  Names := TStringList.Create;
  Contents := TStringList.Create;
end;

destructor TFakeIdeArchive.Destroy;
begin
  Contents.Free;
  Names.Free;
  inherited Destroy;
end;

procedure TFakeIdeArchive.AddFile(const AName: string; const AData: AnsiString;
  const ADate: TDateTime);
begin
  Names.Add(AName);
  // the text is kept with the line breaks escaped, so that one file is one line
  Contents.Add(StringReplace(StringReplace(string(AData), #13, '\r', [rfReplaceAll]), #10, '\n', [rfReplaceAll]));
  SetLength(Dates, Length(Dates) + 1);
  Dates[High(Dates)] := ADate;
end;

procedure TFakeIdeArchive.SaveToFile(const AFileName: string);
begin
  if FailOnSave then
    raise EInOutError.Create('disk full');
  SavedAs := AFileName;
end;

end.
