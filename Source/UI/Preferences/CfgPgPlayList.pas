unit CfgPgPlayList;

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls, ExtCtrls, Buttons;

type
  TCPPlayList = class(TConfigPageForm)
    rgColor: TRadioGroup;
    lbPList: TListBox;
    rgExternal: TRadioGroup;
    cbNumbers: TCheckBox;
    cbDuration: TCheckBox;
    gbAdvColor: TGroupBox;
    Label1: TLabel;
    cbSelectionColor: TColorBox;
    Label2: TLabel;
    cbBackgroundColor: TColorBox;
    bbFont: TBitBtn;
    cbIntPLState: TCheckBox;
    cbGetNamesFromFileTags: TCheckBox;
    cbEraseOnExit: TCheckBox;
    cbAddInsteadReplacing: TCheckBox;
    cbRepeatFont: TColorBox;
    Label3: TLabel;
    procedure bbFontClick(Sender: TObject);
    procedure backColor_OnChange(Sender: TObject);
    procedure selColor_OnChange(Sender: TObject);
    procedure lbPListMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lbPListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lbPListKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure rgColorClick(Sender: TObject);
  private
    procedure RepaintPList;
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

var
  CPPlayList: TCPPlayList;
  FD:TFontDialog;


implementation

{$R *.dfm}

uses
  LACore, MainUnit, Config;

procedure TCPPlayList.ApplyChanges;
var
  colorString: String;
begin
  INI.Bool['PlayList.ShowNumbers']:=cbNumbers.Checked;
  INI.Bool['PlayList.ShowDuration']:=cbDuration.Checked;
  INI.Bool['PlayList.OpenState.Enabled']:=cbIntPLState.Checked;

  try
    colorString := ColorToString(cbSelectionColor.Selected);
    if (colorString[1] = 'c') and (colorString[2] = 'l') then
      INI.Str['PlayList.SelectionColor'] := colorString
    else
      INI.Int['PlayList.SelectionColor'] := ColorToRGB(cbSelectionColor.Selected);

    colorString := ColorToString(cbBackgroundColor.Selected);
    if (colorString[1] = 'c') and (colorString[2] = 'l') then
      INI.Str['PlayList.BackgroundColor'] := colorString
    else
      INI.Int['PlayList.BackgroundColor'] := ColorToRGB(cbBackgroundColor.Selected);

    colorString := ColorToString(cbRepeatFont.Selected);
    if (colorString[1] = 'c') and (colorString[2] = 'l') then
      INI.Str['PlayList.RepeatFileColor'] := colorString
    else
      INI.Int['PlayList.RepeatFileColor'] := ColorToRGB(cbRepeatFont.Selected);
  except
     INI.Int['PlayList.SelectionColor'] := ColorToRGB(cbSelectionColor.Selected);
     INI.Int['PlayList.BackgroundColor'] := ColorToRGB(cbBackgroundColor.Selected);
     INI.Int['PlayList.RepeatFileColor'] := ColorToRGB(cbRepeatFont.Selected);
  end;

  INI.Bool['PlayList.GetNamesFromFileTags'] := cbGetNamesFromFileTags.Checked;
  
  INI.Int['PlayList.UseSkinColor']:=rgColor.ItemIndex;
  INI.Int['PlayList.External']:=rgExternal.ItemIndex;
  INI.Bool['PlayList.EraseOnExit']:=cbEraseOnExit.Checked;
  INI.Bool['PlayList.AddInsteadReplacing']:=cbAddInsteadReplacing.Checked;
  Core.FntHlp.WriteToINI(lbPList.Font,'PlayList.Font');
  frMain.PlayGrid.NewFont;
  frMain.PlayGrid.NewColors;

  if frMain.pnPlayList.Visible then
  begin
    frMain.ShowPlayList(False);
    frMain.ShowPlayList(True);
  end;
end;

procedure TCPPlayList.bbFontClick(Sender: TObject);
begin
  FD:=TFontDialog.Create(Self);
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(FD.Handle, True);
  {TopPosition(frConfig.Handle, False);
  TopPosition(FD.Handle, True);}
  Core.FntHlp.CopyFont(lbPList.Font,FD.Font);
  if FD.Execute then
  begin
    Core.FntHlp.CopyFont(FD.Font,lbPList.Font);
    RepaintPList;
  end;
  if frConfig.ConfigPageAlwayOnTop.Enabled then frConfig.SwitchCfgTopPos(FD.Handle, False);
  FD.Free;
end;

procedure TCPPlayList.ReadPrefs;
var
  colorString: String;
begin
  Core.FntHlp.ReadFromINI(lbPList.Font,'PlayList.Font');
  RepaintPList;
  rgColor.ItemIndex:=INI.Int['PlayList.UseSkinColor'];
  rgExternal.ItemIndex:=INI.Int['PlayList.External'];
  cbNumbers.Checked:=INI.Bool['PlayList.ShowNumbers'];
  cbDuration.Checked:=INI.Bool['PlayList.ShowDuration'];

  try
    colorString := INI.Str['PlayList.SelectionColor'];
    if (colorString[1] = 'c') and (colorString[2] = 'l') then
      cbSelectionColor.Selected := StringToColor(colorString)
    else
      cbSelectionColor.Selected := INI.Int['PlayList.SelectionColor'];

    colorString := INI.Str['PlayList.BackgroundColor'];
    if (colorString[1] = 'c') and (colorString[2] = 'l') then
      cbBackgroundColor.Selected := StringToColor(colorString)
    else
      cbBackgroundColor.Selected := INI.Int['PlayList.BackgroundColor'];

    colorString := INI.Str['PlayList.RepeatFileColor'];
    if (colorString[1] = 'c') and (colorString[2] = 'l') then
      cbRepeatFont.Selected := StringToColor(colorString)
    else
      cbRepeatFont.Selected := INI.Int['PlayList.RepeatFileColor'];
  except
    cbSelectionColor.Selected := StringToColor(INI.Str['PlayList.SelectionColor']);
    cbBackgroundColor.Selected := StringToColor(INI.Str['PlayList.BackgroundColor']);
    cbRepeatFont.Selected := StringToColor(INI.Str['PlayList.RepeatFileColor']);
  end;

  cbIntPLState.Checked:=INI.Bool['PlayList.OpenState.Enabled'];
  cbGetNamesFromFileTags.Checked := INI.Bool['PlayList.GetNamesFromFileTags'];
  cbEraseOnExit.Checked := INI.Bool['PlayList.EraseOnExit'];
  cbAddInsteadReplacing.Checked := INI.Bool['PlayList.AddInsteadReplacing'];
  if INI.Int['PlayList.UseSkinColor'] = 0 then
    lbPList.Color := cbBackgroundColor.Selected;
  lbPList.Selected[2] := True;
end;

procedure TCPPlayList.RepaintPList;
begin
  lbPList.Hide;
  lbPList.ItemHeight :=5+(lbPList.Font.Size*lbPList.Font.PixelsPerInch) div 72;
  Repaint;
  lbPList.Show;
end;

procedure TCPPlayList.UpdateLang;
begin
  bbFont.Caption:=MS('Config.Font');
  rgColor.Caption:=' '+MS('Config.Color')+' ';
  rgColor.Items[0]:=MS('Config.PlayList.Color.0');
  rgColor.Items[1]:=MS('Config.PlayList.Color.1');

  gbAdvColor.Caption:=' '+MS('Config.PlayList.ColorAddition')+' ';
  Label1.Caption:=MS('Config.PlayList.Color.Cursor');
  Label2.Caption:=MS('Config.PlayList.Color.BGround');
  Label3.Caption:=MS('Config.PlayList.Color.RepeatFile');

  rgExternal.Caption:=' '+MS('Config.PlayList.External')+' ';
  rgExternal.Items[0]:=MS('Config.PlayList.External.0');
  rgExternal.Items[1]:=MS('Config.PlayList.External.1');

  cbNumbers.Caption:=MS('Config.PlayList.ShowNumbers');
  cbDuration.Caption:=MS('Config.PlayList.ShowDuration');
  cbIntPLState.Caption:=MS('Config.PlayList.RememberOpenClose');
  cbGetNamesFromFileTags.Caption:=MS('Config.PlayList.GetTagFileName');
  cbEraseOnExit.Caption:=MS('Config.Playlist.Clear');
  cbAddInsteadReplacing.Caption:=MS('Config.Playlist.AddInsteadReplacing');
end;

procedure TCPPlayList.backColor_OnChange(Sender: TObject);
begin
  inherited;
  // ...
  lbPList.Color := cbBackgroundColor.Selected;
  RepaintPList;
end;

procedure TCPPlayList.selColor_OnChange(Sender: TObject);
begin
  inherited;
  // ...
  lbPList.Canvas.Brush.Color := cbSelectionColor.Selected;
  RepaintPList;
end;

procedure TCPPlayList.lbPListMouseDown;
begin
  inherited;
  lbPList.Invalidate;
end;

procedure TCPPlayList.lbPListDrawItem;
var
  SelBGColor:TColor;
begin
  inherited;
  if rgColor.ItemIndex=0 then
  with (Control as TListBox).Canvas do begin
    Brush.Color:=cbBackgroundColor.Selected;
    if Index = lbPList.ItemIndex then Brush.Color:=cbSelectionColor.Selected;
    FillRect(Rect);
    TextOut(Rect.Left+4,Rect.Top,lbPList.Items[Index]);
  end
  else
  with (Control as TListBox).Canvas do begin
    if ModernSkinEngine then
      try
        SelBGColor:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,3];
      except
        SelBGColor:=$4F4F4F;
      end
    else
      SelBGColor:=frMain.imSkin.Canvas.Pixels[773,107];
      
    if ModernSkinEngine then
      try
        Brush.Color:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,0]
      except
        Brush.Color:=clBlack;
      end
    else
      Brush.Color:=frMain.imSkin.Canvas.Pixels[773,109];
    if Index = lbPList.ItemIndex then Brush.Color:=SelBGColor;
    FillRect(Rect);

    Font.Color:=frMain.imSkin.Canvas.Pixels[771,104];
    if Index = lbPList.ItemIndex then Font.Color:=frMain.imSkin.Canvas.Pixels[762,104];
    TextOut(Rect.Left+4,Rect.Top,lbPList.Items[Index]);
  end
end;

procedure TCPPlayList.lbPListKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  lbPList.Invalidate;
end;

procedure TCPPlayList.rgColorClick(Sender: TObject);
begin
  inherited;
  case rgColor.ItemIndex of
    0: begin
      lbPList.Color:=cbBackgroundColor.Selected;
      lbPList.Canvas.Brush.Color:=cbSelectionColor.Selected;
      cbBackgroundColor.Enabled:=True;
      cbRepeatFont.Enabled:=True;
      cbSelectionColor.Enabled:=True;
      Label1.Enabled:=True;
      Label2.Enabled:=True;
      Label3.Enabled:=True;
    end;
    1: begin
      if ModernSkinEngine then
        try
          lbPList.Color:=Core.OptiBld.GetImage('Color.PL').Canvas.Pixels[0,0];
        except
          lbPList.Color:=clBlack;
        end
      else
        lbPList.Color:=frMain.imSkin.Canvas.Pixels[773,109];

      cbBackgroundColor.Enabled:=False;
      cbRepeatFont.Enabled:=False;
      cbSelectionColor.Enabled:=False;
      Label1.Enabled:=False;
      Label2.Enabled:=False;
      Label3.Enabled:=False;
    end;
  end;
  RepaintPList;
end;

end.
