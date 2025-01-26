unit frenamer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, Spin, Arrow, ComCtrls;

type
  rTask = record
    Directory,
    CurrentFilename,
    TemporaryFilename,
    FinalFilename,
    TaskResult : string;
  end;

  { TfrmBulkRenamer }

  TfrmBulkRenamer = class(TForm)
    btnOverwriteFromLeft: TArrow;
    btnOverwriteFromRight: TArrow;
    btnInsertPositionLeft: TArrow;
    btnInsertPositionRight: TArrow;
    btnRemoveToLeft: TArrow;
    btnRemoveToRight: TArrow;
    btnRemoveFromLeft: TArrow;
    btnRemoveFromRight: TArrow;
    btnApply: TBitBtn;
    btnClose: TBitBtn;
    btnRunFilter: TBitBtn;
    btnAdd: TBitBtn;
    btnRemove: TBitBtn;
    btnClear: TBitBtn;
    chkOverwriteAppend: TCheckBox;
    cmbMode: TComboBox;
    cmbChangeCase: TComboBox;
    cmbNumberFormat: TComboBox;
    cmbExtension: TComboBox;
    lstFileList: TListView;
    odSelectFiles: TOpenDialog;
    txtOverwriteText: TEdit;
    txtOverwriteFromSide: TEdit;
    labOverwriteText: TLabel;
    labOverwriteFrom: TLabel;
    txtOverwriteFromPosition: TSpinEdit;
    txtNumberStartWith: TEdit;
    txtNumberText: TEdit;
    labNumberDigits: TLabel;
    labNumberStartWith: TLabel;
    labNumberStep: TLabel;
    labNumberFormat: TLabel;
    labNumberText: TLabel;
    txtNumberDigits: TSpinEdit;
    txtNumberStep: TSpinEdit;
    txtInsertText: TEdit;
    txtInsertPositionSide: TEdit;
    labInsertText: TLabel;
    labInsertPosition: TLabel;
    txtInsertPosition: TSpinEdit;
    txtRemoveToSide: TEdit;
    labRemoveToPosition: TLabel;
    txtRemoveTo: TSpinEdit;
    txtRemoveFromSide: TEdit;
    labCaseTo: TLabel;
    labRemoveFrom: TLabel;
    ntModes: TNotebook;
    pgChangeCase: TPage;
    pgDelete: TPage;
    pgInsert: TPage;
    pgNumbering: TPage;
    pgOverwrite: TPage;
    panToolbar: TPanel;
    txtRemoveFrom: TSpinEdit;
    procedure btnAddClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnInsertPositionLeftClick(Sender: TObject);
    procedure btnInsertPositionRightClick(Sender: TObject);
    procedure btnOverwriteFromLeftClick(Sender: TObject);
    procedure btnOverwriteFromRightClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnRemoveFromLeftClick(Sender: TObject);
    procedure btnRemoveFromRightClick(Sender: TObject);
    procedure btnRemoveToLeftClick(Sender: TObject);
    procedure btnRemoveToRightClick(Sender: TObject);
    procedure btnRunFilterClick(Sender: TObject);
    procedure cmbModeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lstFileListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure txtNumberStartWithKeyPress(Sender: TObject; var Key: char);
  private
    Base62Counter : array [0..7] of byte;
    procedure IncrementCounter;
    procedure SplitFilename (var input, basename, ext : string);
    procedure ChangeCaseFilter;
    procedure DeleteFilter;
    procedure InsertFilter;
    procedure NumberingFilter;
    procedure OverwriteFilter;
    function SafeFilename (TargetDir : string) : string;
  public

  end;

var
  frmBulkRenamer: TfrmBulkRenamer;

implementation

const
  CHAR_CHECK = '✓';
  CHAR_CROSS = '✗';

{$R *.lfm}

{ TfrmBulkRenamer }

procedure TfrmBulkRenamer.FormCreate(Sender: TObject);
var
  index : integer;
begin
  Left := (Screen.Width - Width) div 2;
  Top := (Screen.Height - Height) div 2;

  // Populate Modes
  cmbMode.Items.Clear;
  for index := 0 to ntModes.Pages.Count - 1 do begin
    cmbMode.Items.Add (ntModes.Page [index].Hint);
  end;

  cmbMode.ItemIndex := 0;
  ntModes.PageIndex := 0;

  for index := 0 to 7 do
    Base62Counter [index] := 1;
end;

procedure TfrmBulkRenamer.FormResize(Sender: TObject);
var
  ColWidth : integer;
begin
  ColWidth := (lstFileList.Width - 40) div 2;
  lstFileList.Column[0].Width := ColWidth;
  lstFileList.Column[2].Width := ColWidth;
end;

procedure TfrmBulkRenamer.lstFileListSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  btnRemove.Enabled := Selected;
end;

procedure TfrmBulkRenamer.txtNumberStartWithKeyPress(Sender: TObject;
  var Key: char);
begin
  if not (Key in ['0'..'9', #8]) then
    Key := #0;
end;

procedure TfrmBulkRenamer.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmBulkRenamer.btnInsertPositionLeftClick(Sender: TObject);
begin
  txtInsertPositionSide.Text := 'From Left';
end;

procedure TfrmBulkRenamer.btnInsertPositionRightClick(Sender: TObject);
begin
  txtInsertPositionSide.Text := 'From Right';
end;

procedure TfrmBulkRenamer.btnOverwriteFromLeftClick(Sender: TObject);
begin
  txtOverwriteFromSide.Text := 'From Left';
end;

procedure TfrmBulkRenamer.btnOverwriteFromRightClick(Sender: TObject);
begin
  txtOverwriteFromSide.Text := 'From Right';
end;

procedure TfrmBulkRenamer.btnRemoveClick(Sender: TObject);
var
  index: integer;
begin
  // Start from the last item and go backward to avoid index shifting issues
  for index := lstFileList.Items.Count - 1 downto 0 do
  begin
    if lstFileList.Items[index].Selected then
      lstFileList.Items.Delete(index);
  end;
end;

procedure TfrmBulkRenamer.btnRemoveFromLeftClick(Sender: TObject);
begin
  txtRemoveFromSide.Text := 'From Left';
end;

procedure TfrmBulkRenamer.btnRemoveFromRightClick(Sender: TObject);
begin
  txtRemoveFromSide.Text := 'From Right';
end;

procedure TfrmBulkRenamer.btnRemoveToLeftClick(Sender: TObject);
begin
  txtRemoveToSide.Text := 'From Left';
end;

procedure TfrmBulkRenamer.btnRemoveToRightClick(Sender: TObject);
begin
  txtRemoveToSide.Text := 'From Right';
end;

procedure TfrmBulkRenamer.btnRunFilterClick(Sender: TObject);
var
  index,
  search : integer;
  filename : string;
  Duplicate : boolean;
begin
  for index := 0 to (lstFileList.Items.Count - 1) do begin
    lstFileList.Items [index].SubItems [0] := CHAR_CROSS;
    lstFileList.Items [index].SubItems [1] := '';
  end;

  case (ntModes.ActivePage) of
    'pgChangeCase':
      ChangeCaseFilter;
    'pgDelete':
      DeleteFilter;
    'pgInsert':
      InsertFilter;
    'pgNumbering':
      NumberingFilter;
    'pgOverwrite':
      OverwriteFilter;
  end;

  // Remove duplicate filenames from result
  for search := 0 to (lstFileList.Items.Count - 1) do begin
    filename := lstFileList.Items [search].SubItems [1];
    if (filename <> '') then begin
      Duplicate := FALSE;
      for index := 0 to (lstFileList.Items.Count - 1) do
        if (index <> search) and (filename = lstFileList.Items [index].SubItems [1]) then begin
          lstFileList.Items [index].SubItems [0] := CHAR_CROSS;
          lstFileList.Items [index].SubItems [1] := '';
          Duplicate := TRUE;
        end;
      if (Duplicate) then begin
        lstFileList.Items [search].SubItems [0] := CHAR_CROSS;
        lstFileList.Items [search].SubItems [1] := '';
      end;
    end;
  end;
end;

procedure TfrmBulkRenamer.btnClearClick(Sender: TObject);
begin
  lstFileList.Items.Clear;
end;

procedure TfrmBulkRenamer.btnAddClick(Sender: TObject);
var
  index: Integer;
  Item: tListItem;
begin
  // Show the OpenDialog to allow file selection
  if odSelectFiles.Execute then
  begin
    // Loop through the selected files
    for index := 0 to odSelectFiles.Files.Count - 1 do
    begin
      // Add a new item to the ListView
      Item := lstFileList.Items.Add;

      // Set the file name as the caption
      Item.Caption := ExtractFileName (odSelectFiles.Files[index]);
      Item.SubItems.Add('');
      Item.SubItems.Add('');
      Item.SubItems.Add(odSelectFiles.Files[index]);
    end;
  end;
end;

procedure TfrmBulkRenamer.btnApplyClick(Sender: TObject);
var
  Tasks : array of rTask;
  CurrentTask,
  index : integer;
  Item : tListItem;
begin
  if (lstFileList.Items.Count = 0) then
    ShowMessage ('No tasks defined!')
  else begin
    SetLength (Tasks, lstFileList.Items.Count);
    for index := 0 to (lstFileList.Items.Count - 1) do
      with (Tasks [index]) do begin
        Directory := ExtractFileDir(lstFileList.Items [index].SubItems [2]);
        CurrentFilename := lstFileList.Items [index].Caption;
        TemporaryFilename := SafeFilename (Directory);
        FinalFilename := lstFileList.Items [index].SubItems [1];
        if (FinalFilename = '') then
          TaskResult := CHAR_CROSS
        else
          TaskResult := 'P';
      end;


    for index := 0 to length (Tasks) - 1 do
      with (Tasks [index]) do
        RenameFile (
          IncludeTrailingPathDelimiter (Directory) + CurrentFilename,
          IncludeTrailingPathDelimiter (Directory) + TemporaryFilename);
    writeln;

    for index := 0 to length (Tasks) - 1 do
      with (Tasks [index]) do begin
        RenameFile (
          IncludeTrailingPathDelimiter (Directory) + TemporaryFilename,
          IncludeTrailingPathDelimiter (Directory) + FinalFilename);
        CurrentFilename := FinalFilename;
        TaskResult := CHAR_CHECK;
      end;
    writeln;

    lstFileList.Items.Clear;
    for index := 0 to (length (Tasks) - 1) do begin
      Item := lstFileList.Items.Add;
      with (Tasks [index]) do begin
        Item.Caption := CurrentFilename;
        Item.SubItems.Add(TaskResult);
        Item.SubItems.Add('');
        Item.SubItems.Add(IncludeTrailingPathDelimiter (Directory) + CurrentFilename);
      end;
    end;
    SetLength (Tasks, 0)
  end;
end;

procedure TfrmBulkRenamer.cmbModeChange(Sender: TObject);
begin
  ntModes.PageIndex := cmbMode.ItemIndex;
end;


procedure TfrmBulkRenamer.SplitFilename (var input, basename, ext : string);
begin
  ext := ExtractFileExt(input);
  if (ext = input) then
    ext := ''
  else
    basename := ChangeFileExt(input, '');
  Delete (ext, 1, 1)
end;

procedure TfrmBulkRenamer.ChangeCaseFilter;
var
  index,
  charptr : integer;
  CaseMode : byte;
  s,
  basename,
  ext : string;
begin
  case (cmbChangeCase.Text) of
    'UPPERCASE' : CaseMode := 0;
    'lowercase' : CaseMode := 1;
    'Title Case' : CaseMode := 2;
    'First letter uppercase' : CaseMode := 3;
  else
    CaseMode := 255
  end;

  if (CaseMode < 255) then
    for index := 0 to (lstFileList.Items.Count - 1) do begin
      // Get relevant portions of filename
      s := lstFileList.Items [index].Caption;
      SplitFilename (s, basename, ext);
      case (cmbExtension.ItemIndex) of
        0 : s := basename;
        2 : s := ext;
      end;

      if (length (s) > 0) then begin
        if (CaseMode = 0) then
          s := UpperCase (s)
        else
          s := LowerCase (s);
        if (CaseMode > 1) then
          s [1] := UpCase (s [1]);
        if ((CaseMode = 2) and (length (s) > 1)) then
          for charptr := 2 to length (s) do
            if (s [charptr - 1] = ' ') then
              s [charptr] := UpCase (s [charptr]);

        case (cmbExtension.ItemIndex) of
          0 :
            if (ext <> '') then
              s := s + '.' + ext;
          2 :
            if (s <> '') then
              s := basename + '.' + s
            else
              s := basename;
        end;

        if (s = lstFileList.Items [index].Caption) then begin
          lstFileList.Items [index].SubItems [0] := CHAR_CHECK;
          lstFileList.Items [index].SubItems [1] := '';
        end else begin
          lstFileList.Items [index].SubItems [0] := '';
          lstFileList.Items [index].SubItems [1] := s;
        end;
      end;
    end;
end;

procedure TfrmBulkRenamer.DeleteFilter;
var
  index : integer;
  DeleteFrom,
  DeleteTo,
  temporary : integer;
  s,
  basename,
  ext : string;
  Valid : boolean;
begin
  for index := 0 to (lstFileList.Items.Count - 1) do begin
    // Get relevant portions of filename
    s := lstFileList.Items [index].Caption;
    SplitFilename (s, basename, ext);

    case (cmbExtension.ItemIndex) of
      0 : s := basename;
      2 : s := ext;
    end;

    // Get range of characters to delete
    DeleteFrom := txtRemoveFrom.Value;
    if (txtRemoveFromSide.Text = 'From Right') then
      DeleteFrom := (length (s) + 1) - DeleteFrom;
    DeleteTo := txtRemoveTo.Value;
    if (txtRemoveToSide.Text = 'From Right') then
      DeleteTo := (length (s) + 1) - DeleteTo;

    // Range Check
    Valid := TRUE;
    if (DeleteFrom > DeleteTo) then begin
      temporary := DeleteFrom;
      DeleteFrom := DeleteTo;
      DeleteTo := temporary
    end;
    if (DeleteFrom < 0) then
      Valid := FALSE;
    if (DeleteFrom > length (s)) then
      Valid := FALSE;
    if (DeleteTo < 0) then
      Valid := FALSE;
    if (DeleteTo > length (s)) then
      Valid := FALSE;

    if (Valid) then begin
      // Perform the operation
      Delete (s, DeleteFrom, DeleteTo);

      case (cmbExtension.ItemIndex) of
        0 :
          if (ext <> '') then
            s := s + '.' + ext;
        2 :
          if (s <> '') then
            s := basename + '.' + s
          else
            s := basename;
      end;

      if (s = lstFileList.Items [index].Caption) then begin
        lstFileList.Items [index].SubItems [0] := CHAR_CHECK;
        lstFileList.Items [index].SubItems [1] := '';
      end else begin
        lstFileList.Items [index].SubItems [0] := '';
        lstFileList.Items [index].SubItems [1] := s;
      end;
    end;
  end;
end;

procedure TfrmBulkRenamer.InsertFilter;
var
  index : integer;
  lengthof,
  InsertAt : integer;
  InsertString,
  s,
  basename,
  ext : string;
begin
  InsertString := txtInsertText.Text;
  for index := 0 to (lstFileList.Items.Count - 1) do begin
    // Get relevant portions of filename
    s := lstFileList.Items [index].Caption;
    SplitFilename (s, basename, ext);

    case (cmbExtension.ItemIndex) of
      0 : s := basename;
      2 : s := ext;
    end;

    InsertAt := txtInsertPosition.Value;
    LengthOf := length (s);
    if (txtInsertPositionSide.Text = 'From Right') then
      InsertAt := (length (s) - InsertAt) + 1;
    if (InsertAt <= length (s)) then
      Insert (InsertString, s, InsertAt)
    else if (InsertAt = (length (s) + 1)) then
      s := s + InsertString;

    case (cmbExtension.ItemIndex) of
      0 :
        if (ext <> '') then
          s := s + '.' + ext;
      2 :
        if (s <> '') then
          s := basename + '.' + s
        else
          s := basename;
    end;

    if (s = lstFileList.Items [index].Caption) then begin
      lstFileList.Items [index].SubItems [0] := CHAR_CHECK;
      lstFileList.Items [index].SubItems [1] := '';
    end else begin
      lstFileList.Items [index].SubItems [0] := '';
      lstFileList.Items [index].SubItems [1] := s;
    end;
  end;
end;

procedure TfrmBulkRenamer.NumberingFilter;
var
  CurrentNumber,
  index : integer;
  Number,
  AppendText,
  s,
  basename,
  ext : string;
  Success : word;
begin
  // Attempt to convert txtNumberStartWith.Text into CurrentNumber
  val(txtNumberStartWith.Text, CurrentNumber, Success);
  if (Success > 0) then begin
    ShowMessage('Invalid starting number.');
    Exit;  // Exit if conversion failed
  end;
  AppendText := txtNumberText.Text;

  for index := 0 to (lstFileList.Items.Count - 1) do begin
    // Get relevant portions of filename
    s := lstFileList.Items [index].Caption;
    SplitFilename (s, basename, ext);

    case (cmbExtension.ItemIndex) of
      0 : s := basename;
      2 : s := ext;
    end;

    // Process Filename
    str (CurrentNumber, Number);
    while (length (Number) < txtNumberDigits.Value) do
      Number := '0' + Number;
    CurrentNumber := CurrentNumber + txtNumberStep.Value;

    case (cmbNumberFormat.Text) of
      'Number - Text':
        s := Number + AppendText;
      'Number - Text - Old Name':
        s := Number + AppendText + s;
      'Old Name - Number - Text':
        s := s + Number + AppendText;
      'Old Name - Text - Number':
        s := s + AppendText + Number;
      'Text - Number':
        s := AppendText + Number;
      'Text - Number - Old Name':
        s := AppendText + Number + s;
    end;

    case (cmbExtension.ItemIndex) of
      0 :
        if (ext <> '') then
          s := s + '.' + ext;
      2 :
        if (s <> '') then
          s := basename + '.' + s
        else
          s := basename;
    end;

    if (s = lstFileList.Items [index].Caption) then begin
      lstFileList.Items [index].SubItems [0] := CHAR_CHECK;
      lstFileList.Items [index].SubItems [1] := '';
    end else begin
      lstFileList.Items [index].SubItems [0] := '';
      lstFileList.Items [index].SubItems [1] := s;
    end;
  end;
end;


procedure TfrmBulkRenamer.OverwriteFilter;
var
  OverwriteAt,
  charptr,
  index : integer;
  OverwriteText,
  s,
  basename,
  ext : string;
  Append : boolean;
begin
  OverwriteText := txtOverwriteText.Text;
  Append := chkOverwriteAppend.Checked;

  for index := 0 to (lstFileList.Items.Count - 1) do begin
    // Get relevant portions of filename
    s := lstFileList.Items [index].Caption;
    SplitFilename (s, basename, ext);

    case (cmbExtension.ItemIndex) of
      0 : s := basename;
      2 : s := ext;
    end;

    OverwriteAt := txtOverwriteFromPosition.Value;
    if (txtOverwriteFromSide.Text = 'From Right') then
      OverwriteAt := (length (s) - OverwriteAt) + 1;

    charptr := 0;
    while (charptr < length (OverwriteText)) do begin
      if (charptr + OverwriteAt <= length (s)) then
        s [charptr + OverwriteAt] := OverwriteText [charptr + 1]
      else
        if (Append) then
          s := s + OverwriteText [charptr + 1];
      inc (charptr)
    end;

    case (cmbExtension.ItemIndex) of
      0 :
        if (ext <> '') then
          s := s + '.' + ext;
      2 :
        if (s <> '') then
          s := basename + '.' + s
        else
          s := basename;
    end;

    if (s = lstFileList.Items [index].Caption) then begin
      lstFileList.Items [index].SubItems [0] := CHAR_CHECK;
      lstFileList.Items [index].SubItems [1] := '';
    end else begin
      lstFileList.Items [index].SubItems [0] := '';
      lstFileList.Items [index].SubItems [1] := s;
    end;
  end;
end;


function TfrmBulkRenamer.SafeFilename (TargetDir : string) : string;
const
  USABLE_CHARS : string = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
var
  Filename : string;
  index : integer;
begin
  Filename := '';
  repeat
    for index := 0 to 7 do
      Filename := Filename + USABLE_CHARS [Base62Counter [index]];
    IncrementCounter;
  until (FileExists (IncludeTrailingPathDelimiter(TargetDir) + Filename) = FALSE);
  SafeFilename := Filename;
end;

procedure TfrmBulkRenamer.IncrementCounter;
var
  digit : byte;
begin
  digit := 0;
  repeat
    // Check if the current digit exceeds the base-62 range
    if Base62Counter[digit] = 62 then begin
      Base62Counter[digit] := 1;  // Reset the current digit to 1
      inc(digit);  // Move to the next digit
    end;

    // If we've moved past the 7th digit, we loop back to the first digit
    if digit > 7 then
      digit := 0;

    // Increment the next digit (or the first one if we wrapped around)
    inc(Base62Counter[digit]);
  until Base62Counter [digit] < 63;
end;

end.

