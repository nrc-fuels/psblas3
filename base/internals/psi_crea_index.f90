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
!
! File: psi_crea_index.f90
!
! Subroutine: psb_crea_index
!    Converts a list of data exchanges from build format to assembled format. 
!    See below for a description of the formats.
!
! Parameters:
! desc_a       - type(psb_desc_type)   The descriptor; in this context only the index 
!                                       mapping parts are used.
! index_in(:)  - integer               The index list, build format  
! index_out(:) - integer, allocatable  The index list, assembled format
! glob_idx     - logical               Whether the input indices are in local or global
!                                      numbering; the global numbering is used when 
!                                      converting the overlap exchange lists.
! nxch         - integer               The number of data exchanges on the calling process
! nsnd         - integer               Total send buffer size       on the calling process
! nrcv         - integer               Total receive buffer size    on the calling process
!
!
! The format of the index lists. Copied from base/modules/psb_desc_type
!
!  7. The data exchange is based on lists of local indices to be exchanged; all the 
!     lists have the same format, as follows:
!     the list is  composed of variable dimension blocks, one for each process to 
!     communicate with; each block contains indices of local elements to be 
!     exchanged. We do choose the order of communications:  do not change 
!     the sequence of blocks unless you know what you're doing, or you'll 
!     risk a deadlock. NOTE: This is the format when the state is PSB_ASB_.
!     See below for BLD. The end-of-list is marked with a -1. 
!
!  notation        stored in		          explanation
!  --------------- --------------------------- -----------------------------------
!  process_id      index_v(p+proc_id_)      identifier of process with which 
!                                                data is  exchanged.
!  n_elements_recv index_v(p+n_elem_recv_)  number of elements to receive.
!  elements_recv   index_v(p+elem_recv_+i)  indexes of local elements to
!					          receive. these are stored in the
!					          array from location p+elem_recv_ to
!					          location p+elem_recv_+
!						  index_v(p+n_elem_recv_)-1.
!  n_elements_send index_v(p+n_elem_send_)  number of elements to send.
!  elements_send   index_v(p+elem_send_+i)  indexes of local elements to
!					          send. these are stored in the
!					          array from location p+elem_send_ to
!					          location p+elem_send_+
!						  index_v(p+n_elem_send_)-1.
!
!     This organization is valid for both halo and overlap indices; overlap entries
!     need to be updated to ensure that a variable at a given global index 
!     (assigned to multiple processes) has the same value. The way to resolve the 
!     issue is to exchange the data and then sum (or average) the values. See
!     psb_ovrl subroutine. 
!  
!  8. When the descriptor is in the BLD state the INDEX vectors contains only 
!     the indices to be received, organized as  a sequence 
!     of entries of the form (proc,N,(lx1,lx2,...,lxn)) with owning process,
!     number of indices (most often N=1), list of local indices. 
!     This is because we only know the list of halo indices to be received 
!     as we go about building the sparse matrix pattern, and we want the build 
!     phase to be loosely synchronized. Thus we record the indices we have to ask 
!     for, and at the time we call PSB_CDASB we match all the requests to figure 
!     out who should be sending what to whom.
!     However this implies that we know who owns the indices; if we are in the 
!     LARGE case (as described above) this is actually only true for the OVERLAP list 
!     that is filled in at CDALL time, and not for the HALO; thus the HALO list 
!     is rebuilt during the CDASB process (in the psi_ldsc_pre_halo subroutine). 
!  
subroutine psi_crea_index(desc_a,index_in,index_out,glob_idx,nxch,nsnd,nrcv,info)

  use psb_realloc_mod
  use psb_descriptor_type
  use psb_error_mod
  use psb_penv_mod
  use psi_mod, psb_protect_name => psi_crea_index
  implicit none

  type(psb_desc_type), intent(in)  :: desc_a
  integer, intent(out)             :: info,nxch,nsnd,nrcv
  integer, intent(in)              :: index_in(:)
  integer, allocatable             :: index_out(:)
  logical                          :: glob_idx

  !         ....local scalars...      
  integer    :: ictxt, me, np, mode, err_act, dl_lda
  !         ...parameters...
  integer, allocatable :: dep_list(:,:), length_dl(:)
  integer,parameter    :: root=0,no_comm=-1
  logical,parameter    :: debug=.false.
  character(len=20)    :: name

  info = 0
  name='psi_crea_index'
  call psb_erractionsave(err_act)

  ictxt = psb_cd_get_context(desc_a)
  call psb_info(ictxt,me,np)
  if (np == -1) then
    info = 2010
    call psb_errpush(info,name)
    goto 9999
  endif

  ! allocate dependency list
  ! This should be computed more efficiently to save space when
  ! the number of processors becomes very high
  dl_lda=np+1

  allocate(dep_list(max(1,dl_lda),0:np),length_dl(0:np),stat=info)
  if (info /= 0) then 
    call psb_errpush(4010,name,a_err='Allocate')
    goto 9999      
  end if

  ! ...extract dependence list (ordered list of identifer process
  !    which every process must communcate with...
  if (debug) write(*,*) 'crea_halo: calling extract_dep_list'
  mode = 1

  call psi_extract_dep_list(desc_a%matrix_data,index_in,&
       & dep_list,length_dl,np,max(1,dl_lda),mode,info)
  if(info /= 0) then
    call psb_errpush(4010,name,a_err='extrct_dl')
    goto 9999
  end if

  if (debug) write(0,*) 'crea_index: from extract_dep_list',&
       &     me,length_dl(0),index_in(1), ':',dep_list(:length_dl(me),me)
  ! ...now process root contains dependence list of all processes...
  if (debug) write(0,*) 'crea_index: root sorting dep list'

  call psi_dl_check(dep_list,max(1,dl_lda),np,length_dl)

  ! ....now i can sort dependency lists.
  call psi_sort_dl(dep_list,length_dl,np,info)
  if(info /= 0) then
    call psb_errpush(4010,name,a_err='psi_sort_dl')
    goto 9999
  end if

  if(debug) write(0,*)'in psi_crea_index calling psi_desc_index',&
       & size(index_out)
  ! Do the actual format conversion. 
  call psi_desc_index(desc_a,index_in,dep_list(1:,me),&
       & length_dl(me),nsnd,nrcv, index_out,glob_idx,info)
  if(debug) write(0,*)'out of  psi_desc_index',&
       & size(index_out)
  nxch = length_dl(me)
  if(info /= 0) then
    call psb_errpush(4010,name,a_err='psi_desc_index')
    goto 9999
  end if

  deallocate(dep_list,length_dl)
  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
    call psb_error(ictxt)
    return
  end if
  return
end subroutine psi_crea_index
