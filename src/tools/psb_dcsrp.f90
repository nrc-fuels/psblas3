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
! File: psb_dcsrp.f90
!
! Subroutine: psb_dcsrp
!    Apply a right permutation to a sparse matrix, i.e. permute the column 
!    indices. 
! 
! Parameters: 
!    trans   - character.                       Whether iperm or its transpose should be applied
!    iperm   - integer, pointer, dimension(:).  A permutation vector; its size must be either N_ROW or N_COL
!    a       - type(<psb_dspmat_type).          The matrix to be permuted
!    desc_a  - type(<psb_desc_type>).           The communication descriptor.
!    info    - integer.                         Eventually returns an error code
subroutine psb_dcsrp(trans,iperm,a, desc_a, info)
  use psb_descriptor_type
  use psb_serial_mod
  use psb_const_mod
  use psb_penv_mod
  !  implicit none


  !...parameters....
  type(psb_dspmat_type), intent(inout)  ::  a
  type(psb_desc_type), intent(in)       ::  desc_a
  integer, intent(inout)                :: iperm(:), info
  character, intent(in)                 :: trans
  !....locals....
  integer,allocatable                   ::  ipt(:)
  integer                               ::  i,np,me, n_col,l_dcsdp, ipsize
  integer                               ::  dectype
  real(kind(1.d0)), allocatable         ::  work_dcsdp(:)
  integer                               ::  ictxt,n_row,err_act, int_err(5)
  character(len=20)                     ::  name, char_err

  logical, parameter :: debug=.false.

  ictxt   = psb_cd_get_context(desc_a)
  dectype = psb_cd_get_dectype(desc_a)
  n_row   = psb_cd_get_local_rows(desc_a)
  n_col   = psb_cd_get_local_cols(desc_a)

  if(psb_get_errstatus() /= 0) return 
  info=0
  call psb_erractionsave(err_act)
  name = 'psd_csrp'

  ! check on blacs grid 
  call psb_info(ictxt, me, np)
  if (np == -1) then
    info = 2010
    call psb_errpush(info,name)
    goto 9999
  endif


  if (.not.psb_is_asb_desc(desc_a)) then 
    info = 600
    int_err(1) = dectype
    call psb_errpush(info,name,int_err)
    goto 9999
  endif

  ipsize = size(iperm)
  if (.not.((ipsize == n_col).or.(ipsize == n_row) )) then 
    info = 35
    int_err(1) = 1
    int_err(2) = ipsize
    call psb_errpush(info,name,int_err)
    goto 9999
  else
    if (.not.isaperm(ipsize,iperm)) then
      info = 70
      int_err(1) = 1      
      call psb_errpush(info,name,int_err)
      goto 9999
    endif
  endif

  l_dcsdp = (n_col)

  call psb_realloc(l_dcsdp,work_dcsdp,info)
  call psb_realloc(n_col,ipt,info)
  if(info /= no_err) then
    info=4010
    char_err='psrealloc'
    call psb_errpush(info,name,a_err=char_err)
    goto 9999
  end if

  if (ipsize == n_col) then 
    do i=1, n_col
      ipt(i) = iperm(i)
    enddo
  else    
    do i=1, n_row
      ipt(i) = iperm(i)
    enddo
    do i=n_row+1,n_col
      ipt(i) = i
    enddo
  endif
  ! crossed fingers.....
  ! fix glob_to_loc/loc_to_glob  mappings, then indices lists
  ! hmm, maybe we should just move all of this onto a different level,
  ! have a specialized subroutine, and do it in the solver context???? 
  if (debug) write(0,*) 'spasb: calling dcsrp',size(work_dcsdp)
  call csrp(trans,n_row,n_col,a%fida,a%descra,a%ia1,a%ia2,a%infoa,&
       & ipt,work_dcsdp,size(work_dcsdp),info)
  if(info /= no_err) then
    info=4010
    char_err='dcsrp'
    call psb_errpush(info,name,a_err=char_err)
    goto 9999
  end if

  deallocate(ipt,work_dcsdp)

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == act_abort) then
    call psb_error()
    return
  end if
  return

end subroutine psb_dcsrp
