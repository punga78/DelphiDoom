unit frm_ReplaceText;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, frm_SearchText, DelphiDoom.Ide.SearchHistory;

type
  TTextReplaceDialog = class(TTextSearchDialog)
    Label2: TLabel;
    cbReplaceText: TComboBox;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    function GetReplaceText: string;
    function GetReplaceTextHistory: string;
    procedure SetReplaceText(Value: string);
    procedure SetReplaceTextHistory(Value: string);
  public
    property ReplaceText: string read GetReplaceText write SetReplaceText;
    property ReplaceTextHistory: string read GetReplaceTextHistory
      write SetReplaceTextHistory;
  end;

implementation

{$R *.DFM}

{ TTextReplaceDialog }

//==============================================================================
//
// TTextReplaceDialog.GetReplaceText
//
//==============================================================================
function TTextReplaceDialog.GetReplaceText: string;
begin
  Result := cbReplaceText.Text;
end;

//==============================================================================
//
// TTextReplaceDialog.GetReplaceTextHistory
//
//==============================================================================
function TTextReplaceDialog.GetReplaceTextHistory: string;
var
  LHistory: TIdeSearchHistory;
begin
  LHistory := TIdeSearchHistory.Create;
  try
    LHistory.LoadFromText(cbReplaceText.Items.Text);
    Result := LHistory.AsText;
  finally
    LHistory.Free;
  end;
end;

//==============================================================================
//
// TTextReplaceDialog.SetReplaceText
//
//==============================================================================
procedure TTextReplaceDialog.SetReplaceText(Value: string);
begin
  cbReplaceText.Text := Value;
end;

//==============================================================================
//
// TTextReplaceDialog.SetReplaceTextHistory
//
//==============================================================================
procedure TTextReplaceDialog.SetReplaceTextHistory(Value: string);
begin
  cbReplaceText.Items.Text := Value;
end;

//==============================================================================
//
// TTextReplaceDialog.FormCloseQuery
//
//==============================================================================
procedure TTextReplaceDialog.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  s: string;
  LHistory: TIdeSearchHistory;
begin
  inherited;
  if ModalResult = mrOK then begin
    s := cbReplaceText.Text;
    if s <> '' then begin
      LHistory := TIdeSearchHistory.Create;
      try
        LHistory.LoadFromText(cbReplaceText.Items.Text);
        LHistory.Remember(s);
        cbReplaceText.Items.Text := LHistory.AsText;
      finally
        LHistory.Free;
      end;
      cbReplaceText.Text := s;
    end;
  end;
end;

end.

