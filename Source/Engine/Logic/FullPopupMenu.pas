///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// xx.xx.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////
unit FullPopupMenu;

interface

uses
  Windows, Classes, Controls, Graphics, Menus, CmdC, ExtCtrls, SysUtils;

type
  TFullPopupMenu = class(TPopupMenu)
  private
    function AddItem(Parent:TMenuItem;aTitle:string;SkinX,SkinY:LongInt;aCommand:LongInt; cmdEnabledByDefault: Boolean = False):TMenuItem;
    procedure AddPlayListMenu(MI:TMenuItem);

    procedure OnItemClick(Sender:TObject);
    procedure OnItemMeasure(Sender:TObject;ACanvas:TCanvas;var Width,Height:Integer);
    procedure OnItemDraw(Sender:TObject;ACanvas:TCanvas;ARect:TRect;State:TOwnerDrawState);

    procedure OnDVDTitleClick(Sender:TObject);
    procedure OnDVDAudioClick(Sender:TObject);

    procedure AddDVDMenu(PMI:TMenuItem);

    procedure UpdatePic(MI:TMenuItem;Id:LongInt);
  public
    imSkin:TImage;
    bmpPics:TBitmap;
    bmpBG:TBitmap;

    constructor Create(AOwner:TComponent); override;

    procedure SetFullMenu;
    procedure SetPlayListMenu;
  end;

implementation

uses
  LACore, MainUnit, DShowHlp;

procedure TFullPopupMenu.AddDVDMenu(PMI: TMenuItem);
var
  MI,MMI,TMI,AMI:TMenuItem;
  N,l:LongInt;
begin
  MMI:=AddItem(PMI,'',-1,-1,LAC_DVD_MAIN_MENU,true);
  TMI:=AddItem(PMI,MS('DVD.Titles'),-1,-1,-1);
  AMI:=AddItem(PMI,MS('DVD.Audio'),-1,-1,-1);
//  SMI:=AddItem(PMI,'Subtitles',-1,-1,-1);

  if not(Core.DSH.IsDVD) then begin
    MMI.Enabled:=FALSE;
    TMI.Enabled:=FALSE;
    AMI.Enabled:=FALSE;
//    SMI.Enabled:=FALSE;
    Exit;
  end;

  N:=Core.DSH.GetDVDTitlesCount;
  for l:=1 to N do begin
    MI:=AddItem(TMI,MS('DVD.Title')+' '+IntToStr(l),-1,-1,-1);
    MI.OnClick:=OnDVDTitleClick;
    MI.HelpContext:=l;
  end;

  N:=Core.DSH.GetAudioLangCount;
  for l:=1 to N do begin
    MI:=AddItem(AMI,MS('DVD.Language')+' '+IntToStr(l)+' - '+Core.DSH.DVDLangNames[l-1],-1,-1,-1);
    MI.OnClick:=OnDVDAudioClick;
    MI.HelpContext:=l;
  end;
{
  AddItem(SMI,'Subs 1',-1,-1,-1);
  AddItem(SMI,'Subs 2',-1,-1,-1);}
end;

function TFullPopupMenu.AddItem(Parent:TMenuItem; aTitle: String; SkinX, SkinY: LongInt; aCommand: LongInt; cmdEnabledByDefault: Boolean = False): TMenuItem;
var
  MI:TMenuItem;
begin
  MI:=TMenuItem.Create(Self);

  if (aCommand<0) then
    MI.Caption:=aTitle
  else begin
    MI.Caption:=Center.GetCommandName(aCommand)+#9+' '+Center.GetCommandKey(aCommand);
    MI.HelpContext:=aCommand;
    MI.OnClick:=OnItemClick;
    MI.Checked:=frMain.IsCMDActive(aCommand);
    MI.Enabled:=cmdEnabledByDefault;//frMain.IsCMDEnabled(aCommand);
  end;

  if MI.Checked then begin
    SkinX:=803;
    SkinY:=41;
  end;

  if (SkinX>=0) then begin
    MI.Bitmap:=TBitmap.Create;
    MI.Bitmap.Width:=16;
    MI.Bitmap.Height:=16;
    MI.Bitmap.Canvas.Brush.Color:=imSkin.Canvas.Pixels[771,121];
    MI.Bitmap.Canvas.FillRect(Rect(0,0,16,16));
    frMain.DrawSkinRect(MI.Bitmap.Canvas,Rect(SkinX,SkinY,16,16),0,0);
    MI.Bitmap.Transparent:=TRUE;
    MI.Bitmap.TransparentColor:=imSkin.Canvas.Pixels[771,121];
  end;

  MI.OnAdvancedDrawItem:=OnItemDraw;
  MI.OnMeasureItem:=OnItemMeasure;
  Parent.Add(MI);
  Result:=MI;
end;

procedure TFullPopupMenu.AddPlayListMenu(MI: TMenuItem);
begin
  if Core.PlayList.Entries.Count > 0 then begin
    AddItem(MI,'',-1,-1,LAC_FILE_INFO_PLAYLIST, True);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_PLAY, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_ADD_FILES, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_ADD_FOLDER, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_DELETE, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_CLEAR, True);
    AddItem(MI,'-',-1,-1,-1);
    if (frMain.PlayGrid.SelIndex > 0) then
      AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_UP, True)
    else
      AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_UP);
    if (frMain.PlayGrid.SelIndex < Core.PlayList.Entries.Count - 1) then
      AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_DOWN, True)
    else
      AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_DOWN);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_SORT, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_REPORT, True);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_SHUFFLE, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_VISUALSHUFFLE,True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_REPEAT, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_REPEAT_FILE, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_BOOKMARKS, True);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_SEARCH_FILE, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_FILE, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_DELETE_FILE, True);
  end
  else begin
    AddItem(MI,'',-1,-1,LAC_FILE_INFO_PLAYLIST);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_PLAY);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_ADD_FILES, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_ADD_FOLDER, True);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_DELETE);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_CLEAR);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_DOWN);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_UP);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_SORT);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_REPORT);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_SHUFFLE);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_REPEAT);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_REPEAT_FILE);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_BOOKMARKS);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_SEARCH_FILE);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_MOVE_FILE);
    AddItem(MI,'',-1,-1,LAC_PLAYLIST_DELETE_FILE);
  end;
end;

constructor TFullPopupMenu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  OwnerDraw:=TRUE;
  AutoHotKeys:=maManual;
end;

procedure TFullPopupMenu.OnDVDAudioClick(Sender: TObject);
var
  l:LongInt;
begin
  l:=(Sender as TMenuItem).HelpContext;
  DSH.SetDVDAudio(l-1);
end;

procedure TFullPopupMenu.OnDVDTitleClick(Sender: TObject);
var
  l:LongInt;
begin
  l:=(Sender as TMenuItem).HelpContext;
  DSH.PlayTitle(l);
end;

procedure TFullPopupMenu.OnItemClick(Sender: TObject);
var
  MI:TMenuItem;
begin
  MI:=Sender as TMenuItem;
  PostMessage(frMain.Handle,WM_LACMD,MI.HelpContext,0);
end;

procedure TFullPopupMenu.OnItemDraw;
var
  MI:TMenuItem;
  ls,rs:string;
  l:LongInt;
  clImgBg,clTxtBg:TColor;
begin
  clImgBg:=imSkin.Canvas.Pixels[775,113];
  clTxtBg:=imSkin.Canvas.Pixels[777,113];

  MI:=Sender as TMenuItem;
  with ACanvas do begin
    Brush.Color:=clTxtBg;
    FillRect(ARect);

    Pen.Color:=clImgBg;
    Brush.Color:=clImgBg;
    Rectangle(ARect.Left,ARect.Top,ARect.Left+20,ARect.Bottom);
    if Assigned(bmpBG) then begin
      bmpBG.Width:=20;
      bmpBG.Height:=20;
      Draw(ARect.Left,ARect.Top,bmpBg);
    end;

    Brush.Color:=clTxtBg;
    Font.Color:=imSkin.Canvas.Pixels[778,114];
    if (odSelected in State) and (MI.Enabled) then begin
      Pen.Color:=imSkin.Canvas.Pixels[775,119];
      Brush.Color:=imSkin.Canvas.Pixels[776,120];
      Rectangle(ARect);
      Font.Color:=imSkin.Canvas.Pixels[777,121];
    end;

    if Assigned(MI.Bitmap) then begin
//      MI.Bitmap.Transparent:=TRUE;
  //    MI.Bitmap.TransparentColor:=imSkin.Canvas.Pixels[771,121];
      Draw(ARect.Left+2,ARect.Top+2,MI.Bitmap);
    end;

    if (MI.Caption='-') then begin
      Inc(ARect.Left,20);
      Inc(ARect.Top,1);
      Dec(ARect.Bottom,1);
      Brush.Color:=clImgBg;
      FillRect(ARect);
    end else begin
      l:=Pos(#9,MI.Caption);
      if (l=0) then begin
        ls:=MI.Caption;
        rs:='';
      end else begin
        ls:=Copy(MI.Caption,1,l-1);
        rs:=Copy(MI.Caption,l+1,Length(MI.Caption)-l);
      end;
      if not(MI.Enabled) then
        Font.Color:=imSkin.Canvas.Pixels[778,118];
      TextOut(ARect.Left+22,ARect.Top+3,ls);
      TextOut(ARect.Right-5-TextWidth(rs),ARect.Top+3,rs);
    end;
  end;
end;

procedure TFullPopupMenu.OnItemMeasure;
var
  MI:TMenuItem;
begin
  MI:=Sender as TMenuItem;
  Width:=22+ACanvas.TextWidth(MI.Caption)+20;
  if (MI.Caption='-') then
    Height:=3
  else
    Height:=ACanvas.TextHeight(MI.Caption)+7;
end;

procedure TFullPopupMenu.SetFullMenu;
var
  MI:TMenuItem;
  sMI: TMenuItem;
  LD: DWord;
  i: ShortInt;
  LAC_CD_PLAYDISC: array[0..25] of Integer;
begin
  Items.Clear;

  LAC_CD_PLAYDISC[0] := LAC_CD_PLAYDISC_A;
  LAC_CD_PLAYDISC[1] := LAC_CD_PLAYDISC_B;
  LAC_CD_PLAYDISC[2] := LAC_CD_PLAYDISC_C;
  LAC_CD_PLAYDISC[3] := LAC_CD_PLAYDISC_D;
  LAC_CD_PLAYDISC[4] := LAC_CD_PLAYDISC_E;
  LAC_CD_PLAYDISC[5] := LAC_CD_PLAYDISC_F;
  LAC_CD_PLAYDISC[6] := LAC_CD_PLAYDISC_G;
  LAC_CD_PLAYDISC[7] := LAC_CD_PLAYDISC_H;
  LAC_CD_PLAYDISC[8] := LAC_CD_PLAYDISC_I;
  LAC_CD_PLAYDISC[9] := LAC_CD_PLAYDISC_J;
  LAC_CD_PLAYDISC[10] := LAC_CD_PLAYDISC_K;
  LAC_CD_PLAYDISC[11] := LAC_CD_PLAYDISC_L;
  LAC_CD_PLAYDISC[12] := LAC_CD_PLAYDISC_M;
  LAC_CD_PLAYDISC[13] := LAC_CD_PLAYDISC_N;
  LAC_CD_PLAYDISC[14] := LAC_CD_PLAYDISC_O;
  LAC_CD_PLAYDISC[15] := LAC_CD_PLAYDISC_P;
  LAC_CD_PLAYDISC[16] := LAC_CD_PLAYDISC_Q;
  LAC_CD_PLAYDISC[17] := LAC_CD_PLAYDISC_R;
  LAC_CD_PLAYDISC[18] := LAC_CD_PLAYDISC_S;
  LAC_CD_PLAYDISC[19] := LAC_CD_PLAYDISC_T;
  LAC_CD_PLAYDISC[20] := LAC_CD_PLAYDISC_U;
  LAC_CD_PLAYDISC[21] := LAC_CD_PLAYDISC_V;
  LAC_CD_PLAYDISC[22] := LAC_CD_PLAYDISC_W;
  LAC_CD_PLAYDISC[23] := LAC_CD_PLAYDISC_X;
  LAC_CD_PLAYDISC[24] := LAC_CD_PLAYDISC_Y;
  LAC_CD_PLAYDISC[25] := LAC_CD_PLAYDISC_Z;

  AddItem(Items,'',-1,-1,LAC_FILE_OPEN, True);

  if (frMain.LoadedFileName <> '') then
    AddItem(Items,'',-1,-1,LAC_PLAYBACK_STOP_PLAY, True)
  else
    AddItem(Items,'',-1,-1,LAC_PLAYBACK_STOP_PLAY, False);

  if (Core.PlayList.PlayPos < Core.PlayList.Entries.Count -1) and
        (Core.PlayList.Entries.Count > 1) then 
    AddItem(Items,'',-1,-1,LAC_PLAYLIST_NEXT, True)
  else
    AddItem(Items,'',-1,-1,LAC_PLAYLIST_NEXT, False);  
  AddItem(Items,'-',-1,-1,-1);

  MI:=AddItem(Items,Center.GetCategoryName(0),786,58,-1);
  if Assigned(bmpPics) then UpdatePic(MI,0);
  AddItem(MI,'',-1,-1,LAC_FILE_OPEN, True);
  AddItem(MI,'',-1,-1,LAC_FILE_OPENURL, True);  
  if frMain.pnPlayList.Visible then
  begin
    if (Core.PlayList.Entries.Count = 0) then
      AddItem(MI,'',-1,-1,LAC_FILE_INFO, False)
    else
      AddItem(MI,'',-1,-1,LAC_FILE_INFO, True);
  end
  else
  begin
    if (Core.PlayList.Entries.Count > 0) or (frMain.LoadedFileName <> '') then
      AddItem(MI,'',-1,-1,LAC_FILE_INFO, True)
    else
      AddItem(MI,'',-1,-1,LAC_FILE_INFO, False);
  end;
 // Меню воспроизвести диск теперь для Мультиязычности
 sMI:= AddItem(MI,'',-1,-1,LAC_PLAYBACK_DISK, True);
//  sMI := AddItem(MI, 'LAC_PLAYBACK_DISK', -1, -1, -1);
  LD := GetLogicalDrives;
  for i := 0 to 25 do
    if (LD and (1 shl i)) <> 0 then
      AddItem(sMI, Char(Ord('A') + i) + ':', -1, -1, LAC_CD_PLAYDISC[i], True);

  MI:=AddItem(Items,Center.GetCategoryName(1),786,75,-1);
  if Assigned(bmpPics) then UpdatePic(MI,1);
  if frMain.LoadedFileName <> '' then
    AddItem(MI,'',-1,-1,LAC_PLAYBACK_REAL_STOP, True)
  else
    AddItem(MI,'',-1,-1,LAC_PLAYBACK_REAL_STOP, False);

  AddItem(MI,'',-1,-1,LAC_PLAYBACK_PLAY, True);
  if frMain.LoadedFileName <> '' then
    AddItem(MI,'',-1,-1,LAC_PLAYBACK_SPEED_PLAY, True)
  else
    AddItem(MI,'',-1,-1,LAC_PLAYBACK_SPEED_PLAY, False);
  AddItem(MI,'-',-1,-1,-1);
  if frMain.LoadedFileName <> '' then
    AddItem(MI,'',-1,-1,LAC_PLAYBACK_FILTERS, True)
  else
    AddItem(MI,'',-1,-1,LAC_PLAYBACK_FILTERS, False);

  MI:=AddItem(Items,Center.GetCategoryName(2),786,92,-1);
  if Assigned(bmpPics) then UpdatePic(MI,2);
  if frMain.LoadedFileName <> '' then
  begin
    AddItem(MI,'',-1,-1,LAC_SEEK_FRAME_STEP, True);
    AddItem(MI,'',-1,-1,LAC_SEEK_FRAME_BACK, True);
    AddItem(MI,'',-1,-1,LAC_SEEK_FORWARD, True);
    AddItem(MI,'',-1,-1,LAC_SEEK_BACKWARD, True);
    AddItem(MI,'',-1,-1,LAC_SEEK_JUMP_FORWARD, True);
    AddItem(MI,'',-1,-1,LAC_SEEK_JUMP_BACKWARD, True);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_SEEK_REWIND, True);
    AddItem(MI,'',-1,-1,LAC_SEEK_SET_BOOKMARK, True);
  end
  else
  begin
    AddItem(MI,'',-1,-1,LAC_SEEK_FRAME_STEP);
    AddItem(MI,'',-1,-1,LAC_SEEK_FRAME_BACK);
    AddItem(MI,'',-1,-1,LAC_SEEK_FORWARD);
    AddItem(MI,'',-1,-1,LAC_SEEK_BACKWARD);
    AddItem(MI,'',-1,-1,LAC_SEEK_JUMP_FORWARD);
    AddItem(MI,'',-1,-1,LAC_SEEK_JUMP_BACKWARD);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_SEEK_REWIND);
    AddItem(MI,'',-1,-1,LAC_SEEK_SET_BOOKMARK);
  end;

  MI:=AddItem(Items,Center.GetCategoryName(3),786,109,-1);
  if Assigned(bmpPics) then UpdatePic(MI,3);
  AddItem(MI,'',-1,-1,LAC_WINDOW_CONTROL_PANEL, True);

  if Core.Prefs.ReadBool('PlayList.External') then
    AddItem(MI,'',-1,-1,LAC_WINDOW_PLAYLIST)
  else
    AddItem(MI,'',-1,-1,LAC_WINDOW_PLAYLIST, True);

  AddItem(MI,'',-1,-1,LAC_WINDOW_EX_PLAYLIST, True);
  AddItem(MI,'-',-1,-1,-1);
  AddItem(MI,'',-1,-1,LAC_WINDOW_FULLSCREEN, True);
  AddItem(MI,'',-1,-1,LAC_WINDOW_ORIGINAL, True);
  AddItem(MI,'-',-1,-1,-1);
  AddItem(MI,'',-1,-1,LAC_WINDOW_STAY_ON_TOP, True);
  AddItem(MI,'',-1,-1,LAC_WINDOW_MINIMIZE, True);
  AddItem(MI,'',-1,-1,LAC_WINDOW_MAXIMIZE, True);

  MI:=AddItem(Items,Center.GetCategoryName(4),803,58,-1);
  if Assigned(bmpPics) then UpdatePic(MI,4);
  AddPlayListMenu(MI);

  MI:=AddItem(Items,Center.GetCategoryName(5),803,75,-1);
  if Assigned(bmpPics) then UpdatePic(MI,5);
  if (frMain.LoadedFileName <> '') and (Core.DSH.HasVideo) then
  begin
    AddItem(MI,'',-1,-1,LAC_VIDEO_PROPERTIES, True);
    if not Core.DSH.IsDVD then
      AddItem(MI,'',-1,-1,LAC_VIDEO_SCREENSHOT, True)
    else
      AddItem(MI,'',-1,-1,LAC_VIDEO_SCREENSHOT);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SCALE_50, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SCALE_100, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SCALE_200, True);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_ASIS, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_16_9, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_4_3, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_WIDTH, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_HEIGHT, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_CUSTOM, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_FREE, True);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_VIDEO_BRIGHTNESS_INC, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_BRIGHTNESS_DEC, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_CONTRAST_INC, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_CONTRAST_DEC, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SATURATION_INC, True);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SATURATION_DEC, True);
  end
  else
  begin
    AddItem(MI,'',-1,-1,LAC_VIDEO_PROPERTIES);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SCREENSHOT);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SCALE_50);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SCALE_100);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SCALE_200);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_ASIS);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_16_9);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_4_3);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_WIDTH);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_HEIGHT);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_CUSTOM);
    AddItem(MI,'',-1,-1,LAC_VIDEO_RATIO_FREE);
    AddItem(MI,'-',-1,-1,-1);
    AddItem(MI,'',-1,-1,LAC_VIDEO_BRIGHTNESS_INC);
    AddItem(MI,'',-1,-1,LAC_VIDEO_BRIGHTNESS_DEC);
    AddItem(MI,'',-1,-1,LAC_VIDEO_CONTRAST_INC);
    AddItem(MI,'',-1,-1,LAC_VIDEO_CONTRAST_DEC);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SATURATION_INC);
    AddItem(MI,'',-1,-1,LAC_VIDEO_SATURATION_DEC);
  end;

  MI:=AddItem(Items,Center.GetCategoryName(6),803,75,-1);
  if Assigned(bmpPics) then UpdatePic(MI,6);
  if (frMain.LoadedFileName = '') then
    AddItem(MI,'',-1,-1,LAC_SUBTITLES_LOAD, False)
  else
    AddItem(MI,'',-1,-1,LAC_SUBTITLES_LOAD, True);
  if (frMain.LoadedFileName = '') then
    AddItem(MI,'',-1,-1,LAC_SUBTITLES_SHOW, False)
  else
    AddItem(MI,'',-1,-1,LAC_SUBTITLES_SHOW, True);
  MI:=AddItem(Items,Center.GetCategoryName(7),803,92,-1);
  if Assigned(bmpPics) then UpdatePic(MI,7);
  if (frMain.LoadedFileName = '') then
    AddItem(MI,'',-1,-1,LAC_SOUND_PROPERTIES, False)
  else
    AddItem(MI,'',-1,-1,LAC_SOUND_PROPERTIES, True);
  AddItem(MI,'',-1,-1,LAC_SOUND_VOLUME_INC, True);
  AddItem(MI,'',-1,-1,LAC_SOUND_VOLUME_DEC, True);
  AddItem(MI,'',-1,-1,LAC_SOUND_MUTE, True);
  if Assigned(frMain.AudioModel) then
    if frMain.AudioModel.AudioStreamsCount > 0 then
      AddItem(MI,'',-1,-1,LAC_SOUND_SWITCH_STREAM, True)
    else
      AddItem(MI,'',-1,-1,LAC_SOUND_SWITCH_STREAM);
  AddItem(MI,'-',-1,-1,-1);
  if (frMain.LoadedFileName = '') then
    AddItem(MI,'',-1,-1,LAC_SOUND_ADD, False)
  else
    AddItem(MI,'',-1,-1,LAC_SOUND_ADD, True);
  MI:=AddItem(Items,MS('Command.Category.9'),803,58,-1);
  if Assigned(bmpPics) then UpdatePic(MI,8);
  AddItem(MI,'',-1,-1,LAC_DVD_PLAY_DISC, True);
  AddItem(MI,'',-1,-1,LAC_DVD_OPEN_FOLDER, True);
  AddItem(MI,'-',-1,-1,-1);
  AddDVDMenu(MI);

  MI:=AddItem(Items,MS('Command.Category.8'),803,109,-1);
  if Assigned(bmpPics) then UpdatePic(MI,9);
  AddItem(MI,'',-1,-1,LAC_APPLICATION_PREFERENCES, True);
  AddItem(MI,'',-1,-1,LAC_APPLICATION_HELP, True);
  AddItem(MI,'',-1,-1,LAC_APPLICATION_ABOUT, True);
  AddItem(MI,'',-1,-1,LAC_APPLICATION_EXIT, True);
  AddItem(MI,'-',-1,-1,-1);
  AddItem(MI,'',-1,-1,LAC_APPLICATION_HIBERNATE, True);
  AddItem(MI,'',-1,-1,LAC_APPLICATION_POWER_OFF, True);

  //подменю "действие по окончанию списка", для текущей сессии
   sMI:= AddItem(MI,MS('Config.OnPLEnd'),-1,-1,-1, True);
  AddItem(sMI,MS('Command.455'),-1,-1,LAC_APPLICATION_HIB_ONPLDONE, True);
  AddItem(sMI,MS('Config.OnPLEnd.2'),-1,-1,LAC_APPLICATION_POW_ONPLDONE, True);
//  sMI := AddItem(MI, 'LAC_PLAYBACK_DISK', -1, -1, -1);
//  AddItem(sMI, Char(Ord('A') + i) + ':', -1, -1, LAC_CD_PLAYDISC[i], True);


  AddItem(Items,'-',-1,-1,-1);
  AddItem(Items,'',-1,-1,LAC_APPLICATION_EXIT, True);
end;

procedure TFullPopupMenu.SetPlayListMenu;
begin
  Items.Clear;
  AddPlayListMenu(Items);
end;

procedure TFullPopupMenu.UpdatePic;
begin
  MI.Bitmap.Canvas.Draw(-(Id div 5)*17,-(Id mod 5)*17,bmpPics);
  MI.Bitmap.TransparentColor:=clLime;
end;

end.
