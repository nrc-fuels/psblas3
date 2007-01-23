!!$ 
!!$              Parallel Sparse BLAS  v2.0
!!$    (C) Copyright 2006 Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the PSBLAS group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE PSBLAS GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$  
!
!	Module to   define desc_a,
!      structure for coomunications.
!
! Typedef: psb_desc_type
!    Defines a communication descriptor


module psb_descriptor_type
  use psb_const_mod

  implicit none

  !
  !     Communication, prolongation & restriction
  !
  integer, parameter :: psb_nohalo_=0,  psb_halo_=4
  integer, parameter :: psb_none_=0,  psb_sum_=1
  integer, parameter :: psb_avg_=2,  psb_square_root_=3
  integer, parameter :: psb_swap_send_=1, psb_swap_recv_=2
  integer, parameter :: psb_swap_sync_=4, psb_swap_mpi_=8

  integer, parameter :: psb_no_comm_=-1
  integer, parameter :: psb_comm_halo_=0, psb_comm_ovr_=1, psb_comm_ext_=2
  integer, parameter :: psb_ovt_xhal_ = 123, psb_ovt_asov_=psb_ovt_xhal_+1

  !
  !     Entries and values in desc%matrix_data
  !
  integer, parameter :: psb_dec_type_=1, psb_m_=2,psb_n_=3
  integer, parameter :: psb_n_row_=4,  psb_n_col_=5,psb_ctxt_=6
  integer, parameter :: psb_desc_size_=7
  integer, parameter :: psb_mpi_c_=9
  integer, parameter :: psb_thal_xch_=11
  integer, parameter :: psb_thal_snd_=12
  integer, parameter :: psb_thal_rcv_=13
  integer, parameter :: psb_tovr_xch_=14
  integer, parameter :: psb_tovr_snd_=15
  integer, parameter :: psb_tovr_rcv_=16
  integer, parameter :: psb_text_xch_=17
  integer, parameter :: psb_text_snd_=18
  integer, parameter :: psb_text_rcv_=19
  integer, parameter :: psb_mdata_size_=20
  integer, parameter :: psb_desc_asb_=3099
  integer, parameter :: psb_desc_bld_=psb_desc_asb_+1
  integer, parameter :: psb_desc_repl_=3199
  integer, parameter :: psb_desc_upd_=psb_desc_bld_+1
  integer, parameter :: psb_desc_normal_=3299
  integer, parameter :: psb_desc_large_=psb_desc_normal_+1
  integer, parameter :: psb_cd_ovl_bld_=3399
  integer, parameter :: psb_cd_ovl_asb_=psb_cd_ovl_bld_+1
  integer, parameter :: nbits=14
  integer, parameter :: hashsize=2**nbits, hashmask=hashsize-1
  integer, parameter :: psb_default_large_threshold=4*1024*1024   ! to be reviewed
  integer, parameter :: psb_hpnt_nentries_=7

  !
  !     Constants for desc_a handling
  !

  integer, parameter :: psb_upd_glbnum_=998
  integer, parameter :: psb_upd_locnum_=997
  integer, parameter :: psb_proc_id_=0, psb_n_elem_recv_=1
  integer, parameter :: psb_elem_recv_=2, psb_n_elem_send_=2
  integer, parameter :: psb_elem_send_=3, psb_n_ovrlp_elem_=1
  integer, parameter :: psb_ovrlp_elem_to_=2, psb_ovrlp_elem_=0
  integer, parameter :: psb_n_dom_ovr_=1


  ! desc_type contains data for communications.
  type psb_desc_type
     ! contain decomposition informations
     integer, allocatable :: matrix_data(:)
     ! contain index of halo elements to send/receive
     integer, allocatable :: halo_index(:), ext_index(:)
     ! contain indices of boundary  elements 
     integer, allocatable :: bnd_elem(:)
     ! contain index of overlap elements to send/receive
     integer, allocatable :: ovrlap_index(:)
     ! contain for each local overlap element, the number of times
     ! that is duplicated
     integer, allocatable :: ovrlap_elem(:)
     ! contain for each local element the corresponding global index
     integer, allocatable :: loc_to_glob(:)
     ! contain for each global element the corresponding local index,
     ! if exist.
     integer, allocatable :: glob_to_loc (:)
     integer, allocatable :: hashv(:), glb_lc(:,:), ptree(:)
     ! local renumbering induced by sparse matrix storage. 
     integer, allocatable :: lprm(:)
     ! index space in case it is not just the contiguous range 1:n
     integer, allocatable :: idx_space(:)
  end type psb_desc_type




  integer, private, save :: cd_large_threshold=psb_default_large_threshold 


contains 

  subroutine psb_cd_set_large_threshold(ith)
    integer, intent(in) :: ith
    if (ith > 0) then 
      cd_large_threshold = ith
    end if
  end subroutine psb_cd_set_large_threshold

  integer function  psb_cd_get_large_threshold()
    psb_cd_get_large_threshold = cd_large_threshold 
  end function psb_cd_get_large_threshold

  subroutine psb_nullify_desc(desc)
    type(psb_desc_type), intent(inout) :: desc
    
!!$    nullify(desc%matrix_data,desc%loc_to_glob,desc%glob_to_loc,&
!!$         &desc%halo_index,desc%bnd_elem,desc%ovrlap_elem,&
!!$         &desc%ovrlap_index, desc%lprm, desc%idx_space)

  end subroutine psb_nullify_desc

  logical function psb_is_ok_desc(desc)

    type(psb_desc_type), intent(in) :: desc

    psb_is_ok_desc = psb_is_ok_dec(psb_cd_get_dectype(desc))

  end function psb_is_ok_desc

  logical function psb_is_bld_desc(desc)
    type(psb_desc_type), intent(in) :: desc

    psb_is_bld_desc = psb_is_bld_dec(psb_cd_get_dectype(desc))

  end function psb_is_bld_desc

  logical function psb_is_large_desc(desc)
    type(psb_desc_type), intent(in) :: desc

    psb_is_large_desc =(psb_desc_large_==psb_cd_get_size(desc))

  end function psb_is_large_desc

  logical function psb_is_upd_desc(desc)
    type(psb_desc_type), intent(in) :: desc

    psb_is_upd_desc = psb_is_upd_dec(psb_cd_get_dectype(desc))

  end function psb_is_upd_desc


  logical function psb_is_asb_desc(desc)
    type(psb_desc_type), intent(in) :: desc

    psb_is_asb_desc = psb_is_asb_dec(psb_cd_get_dectype(desc))

  end function psb_is_asb_desc


  logical function psb_is_ok_dec(dectype)
    integer :: dectype

    psb_is_ok_dec = ((dectype == psb_desc_asb_).or.(dectype == psb_desc_bld_).or.&
         &(dectype == psb_desc_upd_).or.&
         &(dectype== psb_desc_repl_))
  end function psb_is_ok_dec

  logical function psb_is_bld_dec(dectype)
    integer :: dectype

    psb_is_bld_dec = (dectype == psb_desc_bld_)
  end function psb_is_bld_dec

  logical function psb_is_upd_dec(dectype)          
    integer :: dectype

    psb_is_upd_dec = (dectype == psb_desc_upd_)

  end function psb_is_upd_dec


  logical function psb_is_asb_dec(dectype)          
    integer :: dectype

    psb_is_asb_dec = (dectype == psb_desc_asb_).or.&
         & (dectype== psb_desc_repl_)

  end function psb_is_asb_dec


  integer function psb_cd_get_local_rows(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_local_rows = desc%matrix_data(psb_n_row_)
  end function psb_cd_get_local_rows

  integer function psb_cd_get_local_cols(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_local_cols = desc%matrix_data(psb_n_col_)
  end function psb_cd_get_local_cols

  integer function psb_cd_get_global_rows(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_global_rows = desc%matrix_data(psb_m_)
  end function psb_cd_get_global_rows

  integer function psb_cd_get_global_cols(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_global_cols = desc%matrix_data(psb_n_)
  end function psb_cd_get_global_cols

  integer function psb_cd_get_context(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_context = desc%matrix_data(psb_ctxt_)
  end function psb_cd_get_context

  integer function psb_cd_get_dectype(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_dectype = desc%matrix_data(psb_dec_type_)
  end function psb_cd_get_dectype

  integer function psb_cd_get_size(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_size = desc%matrix_data(psb_desc_size_)
  end function psb_cd_get_size

  integer function psb_cd_get_mpic(desc)
    type(psb_desc_type), intent(in) :: desc
    
    psb_cd_get_mpic = desc%matrix_data(psb_mpi_c_)
  end function psb_cd_get_mpic


  subroutine psb_cd_set_bld(desc,info)
    !
    ! Change state of a descriptor into BUILD. 
    ! If the descriptor is LARGE, check the  AVL search tree
    ! and initialize it if necessary.
    !
    use psb_const_mod
    use psb_error_mod
    use psb_penv_mod

    implicit none
    type(psb_desc_type), intent(inout) :: desc
    integer                            :: info
    !locals
    integer             :: np,me,ictxt, isz, err_act,idx,gidx,lidx
    logical, parameter  :: debug=.false.,debugprt=.false.
    character(len=20)   :: name, char_err
    if (debug) write(0,*) me,'Entered CDCPY'
    if (psb_get_errstatus() /= 0) return 
    info = 0
    call psb_erractionsave(err_act)
    name = 'psb_cd_set_bld'

    ictxt = psb_cd_get_context(desc)

    ! check on blacs grid 
    call psb_info(ictxt, me, np)
    if (debug) write(0,*) me,'Entered CDCPY'

    if (psb_is_large_desc(desc)) then 
      if (.not.allocated(desc%ptree)) then 
        allocate(desc%ptree(2),stat=info)
        if (info /= 0) then 
          info=4000
          goto 9999
        endif
        call InitPairSearchTree(desc%ptree,info)
        do idx=1, psb_cd_get_local_cols(desc)
          gidx = desc%loc_to_glob(idx)
          call SearchInsKeyVal(desc%ptree,gidx,idx,lidx,info)        
          if (lidx /= idx) then 
            write(0,*) 'Warning from cdset: mismatch in PTREE ',idx,lidx
          endif
        enddo
      end if
    end if
    desc%matrix_data(psb_dec_type_) = psb_desc_bld_ 

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)

    if (err_act == psb_act_ret_) then
      return
    else
      call psb_error(ictxt)
    end if
    return
  end subroutine psb_cd_set_bld
    
end module psb_descriptor_type
