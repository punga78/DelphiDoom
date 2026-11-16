{******************************************************************************}
{                                                                              }
{  DD_Tools: the choice of the method of the text art                           }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit frm_textartmethod;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  DelphiDoom.Endoom.TextArt.Types;

type
  /// <summary>
  ///   The dialog that asks how a picture becomes text (frm_imgconvertmethod of ENDEDIT): a group of radio buttons
  ///   and OK and Cancel. It has no .dfm: the controls are made here
  /// </summary>
  TTextArtMethodForm = class(TForm)
  strict private
    FGroup: TRadioGroup;
  public
    constructor Create(AOwner: TComponent); override;
    /// <summary>Asks the user: false if he cancels, otherwise AKind is the method he chose</summary>
    class function Choose(var AKind: TEndoomTextArtKind): Boolean;
  end;

implementation

{ TTextArtMethodForm }

constructor TTextArtMethodForm.Create(AOwner: TComponent);
var
  LKind: TEndoomTextArtKind;
  LOk: TButton;
  LCancel: TButton;
begin
  inherited CreateNew(AOwner);
  Caption := 'Convert the image to text';
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 300;
  ClientHeight := 210;
  FGroup := TRadioGroup.Create(Self);
  FGroup.Parent := Self;
  FGroup.SetBounds(8, 8, 284, 150);
  FGroup.Caption := 'Method';
  for LKind := Low(TEndoomTextArtKind) to High(TEndoomTextArtKind) do
    FGroup.Items.Add(ENDOOM_TEXT_ART_NAMES[LKind]);
  FGroup.ItemIndex := 0;
  LOk := TButton.Create(Self);
  LOk.Parent := Self;
  LOk.SetBounds(130, 172, 75, 25);
  LOk.Caption := 'OK';
  LOk.Default := True;
  LOk.ModalResult := mrOk;
  LCancel := TButton.Create(Self);
  LCancel.Parent := Self;
  LCancel.SetBounds(217, 172, 75, 25);
  LCancel.Caption := 'Cancel';
  LCancel.Cancel := True;
  LCancel.ModalResult := mrCancel;
end;

class function TTextArtMethodForm.Choose(var AKind: TEndoomTextArtKind): Boolean;
var
  LForm: TTextArtMethodForm;
begin
  LForm := TTextArtMethodForm.Create(nil);
  try
    LForm.FGroup.ItemIndex := Ord(AKind);
    Result := LForm.ShowModal = mrOk;
    if Result then
      AKind := TEndoomTextArtKind(LForm.FGroup.ItemIndex);
  finally
    LForm.Free;
  end;
end;

end.
