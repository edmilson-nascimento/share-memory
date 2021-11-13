ZCLCA_MEMORYclass ZCLCA_MEMORY definition
  public
  final
  create public
  shared memory enabled .

public section.

  constants GC_BYPASS_RSNUM type MEMID value 'BYPASS_RSNUM' ##NO_TEXT.
  constants GC_EXE_SHIP_EXCEP type MEMID value 'EXE_SHIP_EXCEP' ##NO_TEXT.
  constants GC_ZSD_PRC_UPLD type MEMID value 'ZSD_PRC_UPLD' ##NO_TEXT.
  constants GC_EXE_SPLIT_DLV type MEMID value 'EXE_SPLIT_DLV' ##NO_TEXT.
  constants GC_CBR_CROSSDOCK_DLV type MEMID value 'CBR_CROSS_DOCK' ##NO_TEXT.
  constants GC_RED_ID type MEMID value 'REDICOM_DELIVERY_STO' ##NO_TEXT.
  data GT_DATA_BCK2 type ZCA_MEMORY_TT .
  data GO_DATA type ref to DATA .

  class-methods GET_DATA
    importing
      !IV_ID type MEMID
      !IV_FREE type ABAP_BOOL default ABAP_TRUE
    exporting
      !EV_DATA type ANY
    exceptions
      NO_SET .
  class-methods SET_DATA
    importing
      !IV_ID type MEMID optional
      !IV_DATA type ANY optional .
protected section.
private section.

  class-data GT_DATA type ZCA_MEMORY_TT .
ENDCLASS.



CLASS ZCLCA_MEMORY IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCLCA_MEMORY=>GET_DATA
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ID                          TYPE        MEMID
* | [--->] IV_FREE                        TYPE        ABAP_BOOL (default =ABAP_TRUE)
* | [<---] EV_DATA                        TYPE        ANY
* | [EXC!] NO_SET
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method get_data.

    "Retrieve memory area according to the Id
    try.
        data(lo_mem_area) = zclca_memory_hdl_area=>attach_for_read( inst_name = conv #( iv_id ) ).

      catch cx_shm_no_active_version.
        "Sometimes there is a delay for system for creating the area
        data lv_sec type p decimals 2 value '0.1'.

        do 10 times.
          wait up to lv_sec seconds.

          try.
              lo_mem_area = zclca_memory_hdl_area=>attach_for_read( inst_name = conv #( iv_id ) ).
              data(lv_found) = abap_true.
              exit.

              "Failing on a second time will be enough
            catch cx_shm_no_active_version.
              lv_found = abap_false.
          endtry.
        enddo.

        if lv_found is initial.
          raise no_set.
        endif.
    endtry.

    "Get the data from Root's object
    data lo_mem_root type ref to zclca_memory_root.
    lo_mem_root ?= lo_mem_area->get_root( ).
    if lo_mem_root is bound and
       lo_mem_root->go_data is bound.
      assign lo_mem_root->go_data->* to field-symbol(<fs_data>).
      if <fs_data> is assigned.
        ev_data = <fs_data>.
      endif.
    endif.

    "Detach memory
    lo_mem_area->detach( ).

    "Free the instance if will not be used anymore
    if iv_free eq abap_true.
      lo_mem_area->free_instance( inst_name = conv #( iv_id ) ).
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCLCA_MEMORY=>SET_DATA
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ID                          TYPE        MEMID(optional)
* | [--->] IV_DATA                        TYPE        ANY(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_data.

    DATA:
      lo_data TYPE REF TO data.

    TRY.
        "Create memory handle area
        DATA(lo_mem_area) = zclca_memory_hdl_area=>attach_for_write( inst_name = CONV #( iv_id ) ).

        "Create memory root
        DATA lo_mem_root TYPE REF TO zclca_memory_root.
        CREATE OBJECT lo_mem_root AREA HANDLE lo_mem_area.

        "Create data object
        IF NOT lo_mem_root->go_data IS BOUND.
          CREATE DATA lo_mem_root->go_data AREA HANDLE lo_mem_area LIKE iv_data.
        ENDIF.

        "Send receiving data to memory
        ASSIGN lo_mem_root->go_data->* TO FIELD-SYMBOL(<fs_data>).
        IF <fs_data> IS ASSIGNED.
          <fs_data> = iv_data.
        ENDIF.

        "Set updated root and commit
        lo_mem_area->set_root( lo_mem_root ).
        lo_mem_area->detach_commit( ).

      CATCH cx_root INTO DATA(lo_error).
        DATA(lv_text) = lo_error->get_text( ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.

