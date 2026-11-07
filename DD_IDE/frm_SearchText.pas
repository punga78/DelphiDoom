unit frm_SearchText;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, DelphiDoom.Ide.SearchHistory;

type
  /// <summary>The "Find" dialog; its drop down list is kept by TIdeSearchHistory</summary>
  TTextSearchDialog = class(TForm)
    Label1: TLabel;
    cbSearchText: TComboBox;
    rgSearchDirection: TRadioGroup;
    gbSearchOptions: TGroupBox;
    cbSearchCaseSensitive: TCheckBox;
    cbSearchWholeWords: TCheckBox;
    cbSearchFromCursor: TCheckBox;
    cbSearchSelectedOnly: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    cbRegularExpression: TCheckBox;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    function GetSearchBackwards: boolean;
    function GetSearchCaseSensitive: boolean;
    function GetSearchFromCursor: boolean;
    function GetSearchInSelection: boolean;
    function GetSearchText: string;
    function GetSearchTextHistory: string;
    function GetSearchWholeWords: boolean;
    procedure SetSearchBackwards(Value: boolean);
    procedure SetSearchCaseSensitive(Value: boolean);
    procedure SetSearchFromCursor(Value: boolean);
    procedure SetSearchInSelection(Value: boolean);
    procedure SetSearchText(Value: string);
    procedure SetSearchTextHistory(Value: string);
    procedure SetSearchWholeWords(Value: boolean);
    procedure SetSearchRegularExpression(const Value: boolean);
    function GetSearchRegularExpression: boolean;
  public
    property SearchBackwards: boolean read GetSearchBackwards
      write SetSearchBackwards;
    property SearchCaseSensitive: boolean read GetSearchCaseSensitive
      write SetSearchCaseSensitive;
    property SearchFromCursor: boolean read GetSearchFromCursor
      write SetSearchFromCursor;
    property SearchInSelectionOnly: boolean read GetSearchInSelection
      write SetSearchInSelection;
    property SearchText: string read GetSearchText write SetSearchText;
    property SearchTextHistory: string read GetSearchTextHistory
      write SetSearchTextHistory;
    property SearchWholeWords: boolean read GetSearchWholeWords
      write SetSearchWholeWords;
    property SearchRegularExpression: boolean read GetSearchRegularExpression
      write SetSearchRegularExpression;
  end;

implementation

{$R *.DFM}

{ TTextSearchDialog }

//==============================================================================
//
// TTextSearchDialog.GetSearchBackwards
//
//==============================================================================
function TTextSearchDialog.GetSearchBackwards: boolean;
begin
  Result := rgSearchDirection.ItemIndex = 1;
end;

//==============================================================================
//
// TTextSearchDialog.GetSearchCaseSensitive
//
//==============================================================================
function TTextSearchDialog.GetSearchCaseSensitive: boolean;
begin
  Result := cbSearchCaseSensitive.Checked;
end;

//==============================================================================
//
// TTextSearchDialog.GetSearchFromCursor
//
//==============================================================================
function TTextSearchDialog.GetSearchFromCursor: boolean;
begin
  Result := cbSearchFromCursor.Checked;
end;

//==============================================================================
//
// TTextSearchDialog.GetSearchInSelection
//
//==============================================================================
function TTextSearchDialog.GetSearchInSelection: boolean;
begin
  Result := cbSearchSelectedOnly.Checked;
end;

//==============================================================================
//
// TTextSearchDialog.GetSearchRegularExpression
//
//==============================================================================
function TTextSearchDialog.GetSearchRegularExpression: boolean;
begin
  Result := cbRegularExpression.Checked;
end;

//==============================================================================
//
// TTextSearchDialog.GetSearchText
//
//==============================================================================
function TTextSearchDialog.GetSearchText: string;
begin
  Result := cbSearchText.Text;
end;

//==============================================================================
//
// TTextSearchDialog.GetSearchTextHistory
//
//==============================================================================
function TTextSearchDialog.GetSearchTextHistory: string;
var
  LHistory: TIdeSearchHistory;
begin
  LHistory := TIdeSearchHistory.Create;
  try
    LHistory.LoadFromText(cbSearchText.Items.Text);
    Result := LHistory.AsText;
  finally
    LHistory.Free;
  end;
end;

//==============================================================================
//
// TTextSearchDialog.GetSearchWholeWords
//
//==============================================================================
function TTextSearchDialog.GetSearchWholeWords: boolean;
begin
  Result := cbSearchWholeWords.Checked;
end;

//==============================================================================
//
// TTextSearchDialog.SetSearchBackwards
//
//==============================================================================
procedure TTextSearchDialog.SetSearchBackwards(Value: boolean);
begin
  rgSearchDirection.ItemIndex := Ord(Value);
end;

//==============================================================================
//
// TTextSearchDialog.SetSearchCaseSensitive
//
//==============================================================================
procedure TTextSearchDialog.SetSearchCaseSensitive(Value: boolean);
begin
  cbSearchCaseSensitive.Checked := Value;
end;

//==============================================================================
//
// TTextSearchDialog.SetSearchFromCursor
//
//==============================================================================
procedure TTextSearchDialog.SetSearchFromCursor(Value: boolean);
begin
  cbSearchFromCursor.Checked := Value;
end;

//==============================================================================
//
// TTextSearchDialog.SetSearchInSelection
//
//==============================================================================
procedure TTextSearchDialog.SetSearchInSelection(Value: boolean);
begin
  cbSearchSelectedOnly.Checked := Value;
end;

//==============================================================================
//
// TTextSearchDialog.SetSearchText
//
//==============================================================================
procedure TTextSearchDialog.SetSearchText(Value: string);
begin
  cbSearchText.Text := Value;
end;

//==============================================================================
//
// TTextSearchDialog.SetSearchTextHistory
//
//==============================================================================
procedure TTextSearchDialog.SetSearchTextHistory(Value: string);
begin
  cbSearchText.Items.Text := Value;
end;

//==============================================================================
//
// TTextSearchDialog.SetSearchWholeWords
//
//==============================================================================
procedure TTextSearchDialog.SetSearchWholeWords(Value: boolean);
begin
  cbSearchWholeWords.Checked := Value;
end;

procedure TTextSearchDialog.SetSearchRegularExpression(
  const Value: boolean);
begin
  cbRegularExpression.Checked := Value;
end;

{ event handlers }

//==============================================================================
//
// TTextSearchDialog.FormCloseQuery
//
//==============================================================================
procedure TTextSearchDialog.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  s: string;
  LHistory: TIdeSearchHistory;
begin
  if ModalResult = mrOK then begin
    s := cbSearchText.Text;
    if s <> '' then begin
      // the text goes to the front of the list (once), then the box shows it again
      LHistory := TIdeSearchHistory.Create;
      try
        LHistory.LoadFromText(cbSearchText.Items.Text);
        LHistory.Remember(s);
        cbSearchText.Items.Text := LHistory.AsText;
      finally
        LHistory.Free;
      end;
      cbSearchText.Text := s;
    end;
  end;
end;

end.

