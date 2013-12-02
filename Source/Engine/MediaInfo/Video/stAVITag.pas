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
// 14.11.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit stAVITag;

// -----------------------------------------------------------------------------

interface

uses
  Classes, SysUtils, stFile;

type
  vtAVIErrorCode =
  (
    ecNone,           // Всё пучком.
    ecOpenError,      // Ошибка открытия.
    ecReadError,      // Ошибка чтения.
    ecRIFFError,      // Файл не соотвествует RIFF-формату.
    ecSizeError,      // Размер RIFF-заголовка меньше, чем должен быть.
    ecAVIError,       // Файл не соотвествует AVI-формату.
    ecStructureError, // Ошибка в структуре AVI.
    ecCloseError,     // Ошибка при закрытии.
    ecWriteError      // Ошибка при записи.
  );

  { vtAVITag }

  vtAVITag = class(TObject)
    private
      { Private declarations }
      FFileName               : String;
      FErrorCode              : vtAVIErrorCode;
      INAM_Title              : String;
      IART_Director           : String;
      ICOP_Copyright          : String;
      IPRD_Product            : String;
      ICRD_CreationDate       : String;
      IGNR_Genre              : String;
      ISBJ_Subject            : String;
      IKEY_Keywords           : String;
      ICMT_Comment            : String;
      IWRI_Writer             : String;
      IPRO_Producer           : String;
      IPDS_ProductionDesigner : String;
      IEDT_Editor             : String;
      IMUS_Composer           : String;
      ISTD_ProductionStudio   : String;
      IDST_Distributor        : String;
      ICNT_Country            : String;
      ILNG_Language           : String;
      IRTD_Rating             : String;
      ISTR_Starring           : String;
      ISFT_Software           : String;
      ITCH_Encoder            : String;
      IWEB_InternetAddress    : String;
      IDPI_Resolution         : String;
      IPLT_Palette            : String;
    public
      { Public declarations }
      constructor Create(const FileName: String);
      function ReadTag: Boolean;
      procedure ClearTag;
      function TagAvailable: Boolean;
      property ErrorCode          : vtAVIErrorCode read FErrorCode;
      property Title              : String          read INAM_Title              write INAM_Title;
      property Director           : String          read IART_Director           write IART_Director;
      property Copyright          : String          read ICOP_Copyright          write ICOP_Copyright;
      property Product            : String          read IPRD_Product            write IPRD_Product;
      property CreationDate       : String          read ICRD_CreationDate       write ICRD_CreationDate;
      property Genre              : String          read IGNR_Genre              write IGNR_Genre;
      property Subject            : String          read ISBJ_Subject            write ISBJ_Subject;
      property Keywords           : String          read IKEY_Keywords           write IKEY_Keywords;
      property Comment            : String          read ICMT_Comment            write ICMT_Comment;
      property Writer             : String          read IWRI_Writer             write IWRI_Writer;
      property Producer           : String          read IPRO_Producer           write IPRO_Producer;
      property Editor             : String          read IEDT_Editor             write IEDT_Editor;
      property Composer           : String          read IMUS_Composer           write IMUS_Composer;
      property ProductionStudio   : String          read ISTD_ProductionStudio   write ISTD_ProductionStudio;
      property Distributor        : String          read IDST_Distributor        write IDST_Distributor;
      property Country            : String          read ICNT_Country            write ICNT_Country;
      property Language           : String          read ILNG_Language           write ILNG_Language;
      property Rating             : String          read IRTD_Rating             write IRTD_Rating;
      property Starring           : String          read ISTR_Starring           write ISTR_Starring;
      property Software           : String          read ISFT_Software           write ISFT_Software;
      property Encoder            : String          read ITCH_Encoder            write ITCH_Encoder;
      property InternetAddress    : String          read IWEB_InternetAddress    write IWEB_InternetAddress;
      property Resolution         : String          read IDPI_Resolution         write IDPI_Resolution;
      property Palette            : String          read IPLT_Palette            write IPLT_Palette;
  end;

// -----------------------------------------------------------------------------

implementation

// -----------------------------------------------------------------------------

{ vtAVITag }

// -----------------------------------------------------------------------------

constructor vtAVITag.Create(const FileName: String);
begin
  FFileName := FileName;
  ClearTag;
  ReadTag;
end;

// -----------------------------------------------------------------------------

function vtAVITag.ReadTag: Boolean;
type
  TList_Info = record
    Value   : LongInt;
    Counter : LongInt;
  end;

  TFCCCode = array[1..4] of Char;

  TRiff_Info = record
    Name   : TFCCCode;
    Length : LongInt;
  end;

const
  TAG_Size = 131072;

var
  laFile      : vtFile;  // Исходный файл.
  List_Name   : TFCCCode;
  Buffer      : array[0..TAG_Size] of Char; // Буфер
  Riff_Info   : TRiff_Info; // Переменная для чтения RIFF-элементов.
  Riff_Length : LongInt;
  Zero, x     : LongInt;
  List_Deep   : LongInt;
  Lists       : array[1..10] of TList_Info;
  ErrorFound  : Boolean;

  procedure Recognize_TAG;
  var
    x    : LongInt;
    Temp : String;
  begin
    if Riff_Info.Length > TAG_Size then Exit;
    Temp := '';
    for x := 0 to Riff_Info.Length-1 do 
      Temp := Temp + Buffer[x];

    Temp := Trim(Temp);

    with Riff_Info do
      if Name = 'INAM' then INAM_Title              := Temp else
      if Name = 'IWRI' then IWRI_Writer             := Temp else
      if Name = 'IART' then IART_Director           := Temp else
      if Name = 'IPRD' then IPRD_Product            := Temp else
      if Name = 'ICRD' then ICRD_CreationDate       := Temp else
      if Name = 'ISTD' then ISTD_ProductionStudio   := Temp else
      if Name = 'ISTR' then ISTR_Starring           := Temp else
      if Name = 'IGNR' then IGNR_Genre              := Temp else
      if Name = 'ISBJ' then ISBJ_Subject            := Temp else
      if Name = 'IRTD' then IRTD_Rating             := Temp else
      if Name = 'ICOP' then ICOP_Copyright          := Temp else
      if Name = 'ILNG' then ILNG_Language           := Temp else
      if Name = 'IKEY' then IKEY_Keywords           := Temp else
      if Name = 'ICMT' then ICMT_Comment            := Temp else
      if Name = 'ISFT' then ISFT_Software           := Temp else
      if Name = 'IWEB' then IWEB_InternetAddress    := Temp else
      if Name = 'ITCH' then ITCH_Encoder            := Temp else
      if Name = 'IDPI' then IDPI_Resolution         := Temp else
      if Name = 'IPLT' then IPLT_Palette            := Temp else
      if Name = 'IMUS' then IMUS_Composer           := Temp else
      if Name = 'ICNT' then ICNT_Country            := Temp else
      if Name = 'IDST' then IDST_Distributor        := Temp else
      if Name = 'IEDT' then IEDT_Editor             := Temp else
      if Name = 'IPRO' then IPRO_Producer           := Temp else
      if Name = 'IPDS' then IPDS_ProductionDesigner := Temp;

    Temp := '';
  end;

begin
  Result := False;
  ClearTag;

  laFile := vtFile.Create(FFileName, fmOpenRead or fmShareDenyWrite);
  try
    if not laFile.Ready then
    begin
      FErrorCode := ecOpenError;
      Exit;
    end;

    if not laFile.Read(Riff_Info, 8) then
    begin
      FErrorCode := ecReadError;
      Exit;
    end;

    if Riff_Info.Name <> 'RIFF' then
    begin
      FErrorCode := ecRIFFError;
      Exit;
    end;

    Riff_Length := Riff_Info.Length + 8;
    if Riff_Length > laFile.Size then
    begin
      FErrorCode := ecSizeError;
      Exit;
    end;

    if not laFile.Read(Riff_Info, 4) then
    begin
      FErrorCode := ecReadError;
      Exit;
    end;

    if Riff_Info.Name <> 'AVI ' then
    begin
      FErrorCode := ecAVIError;
      Exit;
    end;

    // Нормальный AVI.
    ErrorFound := False;
    List_Deep  := 1;
    with Lists[List_Deep] do
    begin
      Value   := Riff_Info.Length;
      Counter := 4;               
    end;

    while not (laFile.EOF or (laFile.Position >= Riff_Length)) do
    begin
      if not laFile.Read(Riff_Info, 8) then
        ErrorFound := True;

      for x := 1 to List_Deep do
        Inc(Lists[x].Counter, 8);

      if (Riff_Info.Length mod 2 = 1) then
        Inc(Riff_Info.Length);

      if Riff_Info.Name = 'LIST' then
      begin
        if not laFile.Read(List_Name, 4) then
          ErrorFound := True;

        for x := 1 to List_Deep do
          Inc(Lists[x].Counter, 4);

        Inc(List_Deep);
        with Lists[List_Deep] do
        begin
          Value   := Riff_Info.Length;
          Counter := 4;
        end;

        if (List_Name = 'movi') then
        begin
          if not laFile.Seek(laFile.Position + Riff_Info.Length - 4) then
            ErrorFound := True;

          for x := 1 to List_Deep do
            Inc(Lists[x].Counter, Riff_Info.Length - 4);
        end;
      end;

      if Riff_Info.Name = 'JUNK' then
      begin
        if not laFile.Seek(laFile.Position + Riff_Info.Length) then
          ErrorFound := True;

        for x := 1 to List_Deep do
          Inc(Lists[x].Counter, Riff_Info.Length);
      end;

      if (Riff_Info.Name <> 'JUNK') and (Riff_Info.Name <> 'LIST') then
      begin
        if (Riff_Info.Length <= laFile.Size-laFile.Position+1) and (Riff_Info.Length > 0) then
        begin
          if (Riff_Info.Length > TAG_Size) then
            laFile.Seek(laFile.Position + Riff_Info.Length)
          else
            laFile.Read(Buffer, Riff_Info.Length);

          for x := 1 to List_Deep do
            Inc(Lists[x].Counter, Riff_Info.Length);

          if laFile.ErrorCode <> 0 then
            ErrorFound := True
          else
            Recognize_TAG;
        end
        else
          ErrorFound := True;
      end;

      Zero := List_Deep;
      for x := 1 to Zero do
        if Lists[x].Counter = Lists[x].Value then
          Dec(List_Deep);
    end;

    if ErrorFound then
    begin
      FErrorCode := ecStructureError;
      Exit;
    end;

    FErrorCode := ecNone;
    Result     := True;
  finally
    laFile.Free;
  end;
end;

// -----------------------------------------------------------------------------

procedure vtAVITag.ClearTag;
begin
  INAM_Title              := '';
  IART_Director           := '';
  ICOP_Copyright          := '';
  IPRD_Product            := '';
  ICRD_CreationDate       := '';
  IGNR_Genre              := '';
  ISBJ_Subject            := '';
  IKEY_Keywords           := '';
  ICMT_Comment            := '';
  IWRI_Writer             := '';
  IPRO_Producer           := '';
  IPDS_ProductionDesigner := '';
  IEDT_Editor             := '';
  IMUS_Composer           := '';
  ISTD_ProductionStudio   := '';
  IDST_Distributor        := '';
  ICNT_Country            := '';
  ILNG_Language           := '';
  IRTD_Rating             := '';
  ISTR_Starring           := '';
  ISFT_Software           := '';
  ITCH_Encoder            := '';
  IWEB_InternetAddress    := '';
  IDPI_Resolution         := '';
  IPLT_Palette            := '';
end;

// -----------------------------------------------------------------------------

function vtAVITag.TagAvailable: Boolean;
begin
  if (INAM_Title <> '') or (IART_Director <> '') or (ICOP_Copyright <> '') or
     (IPRD_Product <> '') or (ICRD_CreationDate <> '') or (IGNR_Genre <> '') or
     (ISBJ_Subject <> '') or (IKEY_Keywords <> '') or
     (ICMT_Comment <> '') or (IWRI_Writer <> '') or (IPRO_Producer <> '') or
     (IPDS_ProductionDesigner <> '') or (IEDT_Editor <> '') or
     (IMUS_Composer <> '') or
     (ISTD_ProductionStudio <> '') or (IDST_Distributor <> '') or
     (ICNT_Country <> '') or (ILNG_Language <> '') or (IRTD_Rating <> '') or
     (ISTR_Starring <> '') or
     (ISFT_Software <> '') or (ITCH_Encoder <> '') or
     (IWEB_InternetAddress <> '') or
     (IDPI_Resolution <> '') or
     (IPLT_Palette <> '') then
    Result := True
  else
    Result := False;
end;

// -----------------------------------------------------------------------------

end.
