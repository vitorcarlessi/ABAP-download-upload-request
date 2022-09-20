*======================================================================*
*                                                                      *
*                           ROFF - Consulting                          *
*                                                                      *
*======================================================================*
* Programa...: ZR_DOWNLOAD_REQUEST                                     *
* Módulo.....:                                                         *
* Propósito..: Programa busca arquivo na AL11 e imprime na tela        *
*----------------------------------------------------------------------*
* Autor......: Vitor Crepaldi Carlessi                                 *
* Data.......: 23.05.2020                                              *
*----------------------------------------------------------------------*
* Ultima modificacao:                                                  *
* Nº Request  Data     | Modificado Por | Motivo                       *
*----------------------------------------------------------------------*
*            |          |                |                             *
*======================================================================*
REPORT zr_download_request.

  type-pools: stms.

  constants: c_oprsys  type char10 value 'Windows NT',  "Sistema Operacional do Servidor
  c_cofiles type char10 value '\cofiles\',   "COFILES
  c_data    type char10 value  '\data\'.     "DATA

  data: t_bdc                 type bdcdata_tab,         "Tabela para carregar Batch Input
        t_messages            type table of bdcmsgcoll, "Mensagens de retorno da transação
        t_messages_aux        type table of bdcmsgcoll, "Mensagens de retorno da transação auxiliar
        t_string              type table of string,     "Tabela para SPLIT
        t_clients             type stms_clients,        "Tabela de mandantes
        wa_clients            like line of t_clients,   "Work área para a tabela t_clients
        v_path_server_cofiles type dirname_al11,        "Caminho de Download da request na pasta COFILES
        v_path_server_data    type dirname_al11,        "Caminho de Download da request na pasta DATA
        v_path_client_cofiles type eseftfront,          "Caminho para salvar a request da pasta COFILES em arquivo local
        v_path_client_data    type eseftfront,          "Caminho para salvar a request da pasta DATA em arquivo local
        v_title               type string,              "Título da janela de seleção da pasta
        v_title_up            type string,              "Título da janela de seleção dos arquivos
        v_sysnam              type tmscsys-sysnam,      "Nome do sistema para importação
        v_total               type i,                   "Total de Mensagens de Sucesso
        v_domain              type tmsdomnam,           "Domínio de transporte
        v_request             type trkorr,              "Número da Request
        v_req                 type e070-trkorr.         "Número da Request

  selection-screen: begin of block b3 with frame title text-004.
*text-004 = Download/Upload de Requests
  parameters: p_down type c radiobutton group g1 user-command hide default 'X',
  p_up   type c radiobutton group g1.
*p_down = Download
*p_up = Upload
  selection-screen: end of block b3.

  selection-screen: begin of block b1 with frame title text-002.
* text-002 = Download de Requests
  parameters: p_req  type e070-trkorr modif id d,
  p_path type string      modif id d.
* p_req = Ordem/Tarefa
* p_path = Caminho destino do arquivo
  selection-screen: end of block b1.

  selection-screen: begin of block b2 with frame title text-003.
* text-003 = Upload de Requests
  parameters:
  p_arq1 type string modif id u,
  p_arq2 type string modif id u no-display.
* p_arq1 = Arquivo 1
* p_arq2 = Arquivo 2
  selection-screen: end of block b2.

  at selection-screen output.

    perform screen_change.

  at selection-screen on value-request for p_path.

    perform open_directory_browser changing p_path.

  at selection-screen on value-request for p_arq1.

    perform open_file_browser changing p_arq1 p_arq2.

*  AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_arq2.
*
*    PERFORM open_file_browser CHANGING p_arq2.

  start-of-selection.

    if p_down is not initial.

      perform zf_get_file_path using c_cofiles
      changing v_path_client_cofiles
        v_path_server_cofiles.

      perform zf_get_file_path using c_data
      changing v_path_client_data
        v_path_server_data.

      perform zf_dynpro using: 'X'    'SAPLC13Z'          '1010'                t_bdc,
            ' '    'BDC_OKCODE'        '=EEXO'               t_bdc,
            ' '    'RCGFILETR-FTAPPL'  v_path_server_cofiles t_bdc,
            ' '    'RCGFILETR-FTFRONT' v_path_client_cofiles t_bdc,
            ' '    'RCGFILETR-FTFTYPE' 'BIN'                 t_bdc,
            'X'    'SAPLC13Z'          '1010'                t_bdc,
            ' '    'BDC_OKCODE'        '=EEXO'               t_bdc,
            ' '    'RCGFILETR-FTAPPL'  v_path_server_data    t_bdc,
            ' '    'RCGFILETR-FTFRONT' v_path_client_data    t_bdc,
            ' '    'RCGFILETR-FTFTYPE' 'BIN'                 t_bdc,
            'X'    'SAPLC13Z'          '1010'                t_bdc,
            ' '    'BDC_OKCODE'        '/EECAN'              t_bdc.

      check t_bdc is not initial.

      call transaction 'CG3Y' using t_bdc mode 'N' messages into t_messages.
      if t_messages is not initial.
        t_messages_aux = t_messages.
        delete t_messages_aux where msgid <> 'C$' or msgnr <> '159'.
        describe table t_messages_aux lines sy-tfill.
        if sy-tfill = 2.
          message id 'C$' type 'I' number '159' with p_req p_path.
        else.
          message id 'C$' type 'I' number '156' display like 'E' with p_req.
        endif.
      endif.

    elseif p_up is not initial.

      if p_arq1 is not initial and p_arq2 is not initial.

        perform valida_entradas.

        perform zf_get_server_path using c_cofiles
        changing v_path_client_cofiles
          v_path_server_cofiles.

        perform zf_get_server_path using c_data
        changing v_path_client_data
          v_path_server_data.

        perform zf_dynpro using: 'X'    'SAPLC13Z'          '1020'                t_bdc,
              ' '    'BDC_OKCODE'        '=EIMP'               t_bdc,
              ' '    'RCGFILETR-FTFRONT' v_path_client_cofiles t_bdc,
              ' '    'RCGFILETR-FTAPPL'  v_path_server_cofiles t_bdc,
              ' '    'RCGFILETR-FTFTYPE' 'BIN'                 t_bdc,
              ' '    'RCGFILETR-IEFOW'   'X'                   t_bdc,
              'X'    'SAPLC13Z'          '1020'                t_bdc,
              ' '    'BDC_OKCODE'        '=EIMP'               t_bdc,
              ' '    'RCGFILETR-FTFRONT' v_path_client_data    t_bdc,
              ' '    'RCGFILETR-FTAPPL'  v_path_server_data    t_bdc,
              ' '    'RCGFILETR-FTFTYPE' 'BIN'                 t_bdc,
              ' '    'RCGFILETR-IEFOW'   'X'                   t_bdc,
              'X'    'SAPLC13Z'          '1020'                t_bdc,
              ' '    'BDC_OKCODE'        '/EECAN'              t_bdc.

        call transaction 'CG3Z' using t_bdc mode 'N' messages into t_messages.
        if t_messages is not initial.
          t_messages_aux = t_messages.
          delete t_messages_aux where msgid <> 'C$' or msgnr <> '159'.
          describe table t_messages_aux lines sy-tfill.
          if sy-tfill = 2.

            v_sysnam = sy-sysid.
            wa_clients-client = sy-mandt.
            append wa_clients to t_clients.

            select single domnam from tmscsys into v_domain where sysnam = sy-sysid.

            call function 'TMS_UI_IMPORT_TR_REQUEST'
              exporting
                iv_domain             = v_domain
                iv_system             = v_sysnam
                iv_request            = v_req
                iv_tarcli             = sy-mandt
                iv_ctc_active         = 'X'
                iv_some_active        = 'X'
                it_clients            = t_clients
              exceptions
                cancelled_by_user     = 1
                import_request_denied = 2
                import_request_failed = 3
                others                = 4.

            if sy-subrc = 0.
            else.
              message id sy-msgid type sy-msgty number sy-msgno with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            endif.

          else.
            message id 'C$' type 'S' number '156' display like 'E' with p_req.
          endif.
        endif.

      endif.

    endif.

*&---------------------------------------------------------------------*
*&      Form  ZF_DYNPRO
*&---------------------------------------------------------------------*
  form zf_dynpro using p_dynbegin
        p_name
        p_value
  changing p_bdc type bdcdata_tab.

    data: wa_bdc type bdcdata.

    if p_dynbegin = 'X'.
      wa_bdc-program  = p_name.
      wa_bdc-dynpro   = p_value.
      wa_bdc-dynbegin = 'X'.
    else.
      wa_bdc-fnam = p_name.
      wa_bdc-fval = p_value.
    endif.

    append wa_bdc to p_bdc.
    clear wa_bdc.

  endform.                    " ZF_DYNPRO

*&---------------------------------------------------------------------*
*&      Form  ZF_GET_FILE_PATH
*&---------------------------------------------------------------------*
  form zf_get_file_path using    p_folder      type char10
  changing p_path_client type eseftfront
    p_path_server type dirname_al11.

    statics: v_instance    type mandt,        "Instância do Servidor
    v_request     type trkorr,       "Número da Request
    v_path_server type dirname_al11, "Caminho do Arquivo no Servidor
    v_folder      type char10.       "Pasta de origem no Servidor

    v_folder = p_folder.

    "Busca o caminho da pasta DIR_TRANS no servidor
    call 'C_SAPGPARAM' id 'NAME'  field 'DIR_TRANS'
    id 'VALUE' field v_path_server.

    v_instance = p_req(3).
    v_request = p_req+3.

    if v_folder = c_cofiles.
      concatenate v_request '.' v_instance into v_request.
    elseif v_folder = c_data.
      clear v_request(1).
      concatenate 'R' v_request '.' v_instance into v_request.
      condense v_request no-gaps.
    endif.

* Verifica se Sist.Operacional eh Win ou Unix p/ barras do diretorio
    if sy-opsys <> c_oprsys.
      translate v_folder using '\/'.
    endif.

    concatenate v_path_server v_folder v_request  into p_path_server.
    concatenate p_path '\' v_request into p_path_client.

  endform.                    "ZF_GET_FILE_PATH

*&---------------------------------------------------------------------*
*&      Form  ZF_GET_SERVER_PATH
*&---------------------------------------------------------------------*
  form zf_get_server_path using    p_folder      type char10
  changing p_path_client type eseftfront
    p_path_server type dirname_al11.

    statics: v_instance    type mandt,        "Instância do Servidor
    v_path_server type dirname_al11, "Caminho do Arquivo no Servidor
    v_folder      type char10.       "Pasta de origem no Servidor

    v_folder = p_folder.

    "Busca o caminho da pasta DIR_TRANS no servidor
    call 'C_SAPGPARAM' id 'NAME'  field 'DIR_TRANS'
    id 'VALUE' field v_path_server.

    split p_path_client at '\' into table t_string.
    describe table t_string lines sy-tfill.
    read table t_string into v_request index sy-tfill.

* Verifica se Sist.Operacional eh Win ou Unix p/ barras do diretorio
    if sy-opsys <> c_oprsys.
      translate v_folder using '\/'.
    endif.

    concatenate v_path_server v_folder v_request into p_path_server.

    if v_request(1) = 'K'.
      split v_request at '.' into v_req v_instance.
      concatenate v_instance v_req into v_req.
    endif.

  endform.                    "ZF_GET_SERVER_PATH

*&---------------------------------------------------------------------*
*&      Form  OPEN_DIRECTORY_BROWSER
*&---------------------------------------------------------------------*
  form open_directory_browser  changing pa_path.
*text-001 = Selecione a Pasta
    v_title = text-001.

    call method cl_gui_frontend_services=>directory_browse
      exporting
        window_title         = v_title
        initial_folder       = 'C:'
      changing
        selected_folder      = pa_path
      exceptions
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        others               = 4.

  endform.                    " OPEN_DIRECTORY_BROWSER

*&---------------------------------------------------------------------*
*&      Form  SCREEN_CHANGE
*&---------------------------------------------------------------------*
  form screen_change .

    loop at screen.
      if screen-group1 = 'D' and p_down is initial.
        screen-active = 0. " Omitir Tela
        modify screen.
      elseif screen-group1 = 'U' and p_up is initial.
        screen-active = 0. " Omitir Tela
        modify screen.
      elseif screen-group1 = 'D' and p_down is not initial.
        screen-active = 1. " Exibe Tela
        modify screen.
      elseif screen-group1 = 'U' and p_up is not initial.
        screen-active = 1. " Exibe Tela
        modify screen.
      endif.
    endloop.

  endform.                    " SCREEN_CHANGE

*&---------------------------------------------------------------------*
*&      Form  OPEN_FILE_BROWSER
*&---------------------------------------------------------------------*
  form open_file_browser  changing pa_arq pa_arq2.

    statics:
    t_file      type filetable,
    wa_file     like line of t_file,
    v_rc        type i,
    vl_filename type char100,
    vl_path     type char100.

    v_title_up = text-005.
*text-005 = Selecione o Arquivo

    call method cl_gui_frontend_services=>file_open_dialog
      exporting
        window_title            = v_title_up
        initial_directory       = 'C:'
      changing
        file_table              = t_file
        rc                      = v_rc
      exceptions
        file_open_dialog_failed = 1
        cntl_error              = 2
        error_no_gui            = 3
        others                  = 4.

    read table t_file into wa_file index 1.

    if sy-subrc         is initial and
       wa_file-filename is not initial.

      pa_arq = wa_file-filename.

      clear: vl_filename, vl_path, p_arq2.
      call function 'SO_SPLIT_FILE_AND_PATH'
        exporting
          full_name     = wa_file-filename
        importing
          stripped_name = vl_filename
          file_path     = vl_path
        exceptions
          x_error       = 1
          others        = 2.

      if sy-subrc = 0.

        case vl_filename(1).
          when 'K' or 'k'.
            vl_filename(1) = 'R'.
            concatenate vl_path vl_filename into pa_arq2.
          when 'R' or 'r'.
            vl_filename(1) = 'K'.
            concatenate vl_path vl_filename into pa_arq2.
          when others.
            " nothing to do.
        endcase.

      endif.

    endif.

  endform.                    " OPEN_FILE_BROWSER

*&---------------------------------------------------------------------*
*&      Form  VALIDA_ENTRADAS
*&---------------------------------------------------------------------*
  form valida_entradas.

    statics: v_type type char1. "Diferença entre os arquivos R e K

    split p_arq1 at '\' into table t_string.
    describe table t_string lines sy-tfill.
    read table t_string into v_request index sy-tfill.
    if v_request(1) = 'R' or v_request(1) = 'K'.
      if v_request(1) = 'K'.
        v_path_client_cofiles = p_arq1.
        v_type = 'K'.
      elseif v_request(1) = 'R'.
        v_path_client_data = p_arq1.
        v_type = 'R'.
      endif.
    else.
      message 'Erro, parametros de entrada invalidos' type 'E' display like 'E'.
    endif.

    clear: t_string, v_request.

    split p_arq2 at '\' into table t_string.
    describe table t_string lines sy-tfill.
    read table t_string into v_request index sy-tfill.
    if v_request(1) = 'R' or v_request(1) = 'K'.
      if v_request(1) = 'K'.
        if v_type <> 'K'.
          v_path_client_cofiles = p_arq2.
        else.
          message 'Erro, parametros de entrada invalidos' type 'E' display like 'E'.
        endif.
      elseif v_request(1) = 'R'.
        if v_type <> 'R'.
          v_path_client_data = p_arq2.
        else.
          message 'Erro, parametros de entrada invalidos' type 'E' display like 'E'.
        endif.
      endif.
    else.
      message 'Erro, parametros de entrada invalidos' type 'E' display like 'E'.
    endif.

  endform.                    " VALIDA_ENTRADAS