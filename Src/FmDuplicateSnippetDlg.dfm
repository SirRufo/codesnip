inherited DuplicateSnippetDlg: TDuplicateSnippetDlg
  Caption = 'DuplicateSnippetDlg'
  ExplicitWidth = 474
  ExplicitHeight = 375
  PixelsPerInch = 96
  TextHeight = 13
  inherited pnlBody: TPanel
    Width = 222
    Height = 185
    ExplicitWidth = 222
    ExplicitHeight = 185
    object lblCategory: TLabel
      Left = 0
      Top = 58
      Width = 49
      Height = 13
      Caption = '&Category:'
      FocusControl = cbCategory
    end
    object lblDisplayName: TLabel
      Left = 0
      Top = 2
      Width = 67
      Height = 13
      Caption = '&Display name:'
      FocusControl = edDisplayName
    end
    object cbCategory: TComboBox
      Left = 0
      Top = 77
      Width = 222
      Height = 21
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
    end
    object edDisplayName: TEdit
      Left = 0
      Top = 21
      Width = 222
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object chkEdit: TCheckBox
      Left = 0
      Top = 114
      Width = 222
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Caption = '&Edit in Snippets Editor'
      TabOrder = 2
    end
  end
  inherited btnHelp: TButton
    Left = 313
    ExplicitLeft = 313
  end
  inherited btnOK: TButton
    OnClick = btnOKClick
  end
end
