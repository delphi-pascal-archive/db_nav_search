unit DBSearch;

{$B-,R-,H+,X+}

interface

uses
  SysUtils, WinTypes, {WinProcs,} Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TSearchForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    IgnoreCase: TCheckBox;
    AllowPartial: TCheckBox;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure CheckBoxClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    procedure ActiveControlChanged(Sender: TObject);
    procedure EditEnter(Sender: TObject);
    procedure EditChanged(Sender: TObject);
    procedure CheckBoxChanged(Sender: TObject);
  public
    { Public declarations }
  end;

var
  SearchForm: TSearchForm; SaveControl: TWinControl;
  saveHKL: HKL;

implementation

uses DBNavSch;

{$R *.DFM}

procedure TSearchForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_DOWN) and (Shift = []) then
    begin
    Key := 0; SelectNext(ActiveControl, True, True);
    end;
  if (Key = VK_UP) and (Shift = []) then
    begin
    Key := 0; SelectNext(ActiveControl, False, True);
    end;
  if (Key = VK_RETURN) and (Shift = []) then
    begin
    Key := 0; BitBtn1.Click;
    end;
end;

procedure TSearchForm.FormCreate(Sender: TObject);
var
  SysMenu: hMenu; WorkArea: TRect;
begin
  SysMenu := GetSystemMenu(TForm(Sender).Handle, False);
  RemoveMenu(SysMenu, SC_SIZE, MF_BYCOMMAND);
  RemoveMenu(SysMenu, SC_RESTORE, MF_BYCOMMAND);
  RemoveMenu(SysMenu, SC_MAXIMIZE, MF_BYCOMMAND);
  RemoveMenu(SysMenu, SC_MINIMIZE, MF_BYCOMMAND);
  SystemParametersInfo(SPI_GETWORKAREA, 0, @WorkArea, 0);
  with TForm(Sender) do
    begin
    Left := WorkArea.Right - Width; Top := WorkArea.Top;
    end;
  Screen.OnActiveControlChange := ActiveControlChanged;
  SaveControl := TWinControl(ScrollBox1);
end;

procedure TSearchForm.FormDestroy(Sender: TObject);
begin
  Screen.OnActiveControlChange := nil;
end;

procedure TSearchForm.FormShow(Sender: TObject);
var
  i: integer; ruHKL: HKL;
begin
//  saveHKL := Screen.DefaultKbLayout;
  saveHKL := GetKeyboardLayout(0);
  if RusKbLayout then
    begin
{
    while (GetKeyboardLayout(0) <> $04190419) do
      begin
      ActivateKeyboardLayout(HKL_NEXT, KLF_ACTIVATE);
      if GetKeyboardLayout(0) = saveHKL then
        break;
      end;
}
//    if (GetKeyboardLayout(0) <> $04190419) then
    if (GetKeyboardLayout(0) <> 68748313) then
      begin
//      ruHKL := LoadKeyboardLayout(PChar('04190419'), KLF_ACTIVATE);
      ruHKL := LoadKeyboardLayout(PChar('00000419'), 0);
      ActivateKeyboardLayout(ruHKL, KLF_REORDER);
      end;
    end;
  for i := 0 to Pred(ScrollBox1.ComponentCount) do
    if (ScrollBox1.Components[i] is TEdit) then
      begin
      TEdit(ScrollBox1.Components[i]).OnEnter := EditEnter;
      TEdit(ScrollBox1.Components[i]).OnChange := EditChanged;
      end
    else if (ScrollBox1.Components[i] is TCheckBox) then
      TCheckBox(ScrollBox1.Components[i]).OnClick := CheckBoxChanged;
  FocusControl(SaveControl);
  if SaveControl.Name = 'ScrollBox1' then
    SelectNext(ActiveControl, True, True);
end;

procedure TSearchForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = VK_ESCAPE then
    begin
    Key := #0; Close;
    end;
end;

procedure TSearchForm.ActiveControlChanged(Sender: TObject);
var
  i: integer;
begin
  if Screen.ActiveForm.Name = 'SearchForm' then
    for i := 0 to Pred(ScrollBox1.ComponentCount) do
      if ((ScrollBox1.Components[i] is TEdit) and
          (ScrollBox1.Components[i] as TEdit).Focused) or
         ((ScrollBox1.Components[i] is TCheckBox) and
          (ScrollBox1.Components[i] as TCheckBox).Focused) then
        SaveControl := TWinControl(ScrollBox1.Components[i]);
end;

procedure TSearchForm.EditEnter(Sender: TObject);
begin
  if ScrollBox1.HorzScrollBar.Visible then
    ScrollBox1.HorzScrollBar.Position := 0;
end;

procedure TSearchForm.EditChanged(Sender: TObject);
begin
  if TEdit(Sender).Modified then
    begin
    BitBtn1.Caption := 'Найти'; LocateFound := True;
    BitBtn1.Default := True; FirstLocate := True;
    end;
end;

procedure TSearchForm.CheckBoxChanged(Sender: TObject);
begin
  BitBtn1.Caption := 'Найти'; LocateFound := True;
  BitBtn1.Default := True; FirstLocate := True;
end;

procedure TSearchForm.CheckBoxClick(Sender: TObject);
begin
  BitBtn1.Caption := 'Найти'; LocateFound := True;
  BitBtn1.Default := True; FirstLocate := True;
  FocusControl(SaveControl);
end;

procedure TSearchForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  enHKL: HKL;
begin
  if RusKbLayout then
{
    while (GetKeyboardLayout(0) <> saveHKL) do
      ActivateKeyboardLayout(HKL_NEXT, KLF_ACTIVATE);
}
    if (GetKeyboardLayout(0) <> saveHKL) then
      begin
//      enHKL := LoadKeyboardLayout(PChar('04090409'), KLF_ACTIVATE);
      enHKL := LoadKeyboardLayout(PChar('00000409'), 0);
      ActivateKeyboardLayout(enHKL, KLF_REORDER);
      end;
end;

end.
