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

! File:  psb_ihalo.f90
!
! Subroutine: psb_ihalom
!   This subroutine performs the exchange of the halo elements in a 
!    distributed dense matrix between all the processes.
!
! Arguments:
!   x         -  integer,dimension(:,:).       The local part of the dense matrix.
!   desc_a    -  type(psb_desc_type).        The communication descriptor.
!   info      -  integer.                      Return code
!   alpha     -  real(optional).               Scale factor.
!   jx        -  integer(optional).            The starting column of the global matrix. 
!   ik        -  integer(optional).            The number of columns to gather. 
!   work      -  real(optional).               Work  area.
!   tran      -  character(optional).          Transpose exchange.
!   mode      -  integer(optional).            Communication mode (see Swapdata)
!   data     - integer                 Which index list in desc_a should be used
!                                      to retrieve rows, default psb_comm_halo_
!                                       psb_comm_halo_    use halo_index
!                                       psb_comm_ext_     use ext_index 
!                                       psb_comm_ovrl_    use ovrl_index
!
!
subroutine  psb_ihalom(x,desc_a,info,alpha,jx,ik,work,tran,mode,data)
  use psb_descriptor_type
  use psb_const_mod
  use psi_mod
  use psb_check_mod
  use psb_realloc_mod
  use psb_error_mod
  use psb_string_mod
  use psb_penv_mod
  implicit none

  integer, intent(inout), target           :: x(:,:)
  type(psb_desc_type), intent(in)          :: desc_a
  integer, intent(out)                     :: info
  real(kind(1.d0)), intent(in), optional   :: alpha
  integer, intent(inout), optional, target :: work(:)
  integer, intent(in), optional            :: mode,jx,ik,data
  character, intent(in), optional          :: tran

  ! locals
  integer                  :: ictxt, np, me, &
       & err_act, m, n, iix, jjx, ix, ijx, nrow, k, maxk, liwork,&
       & imode, err,data_
  integer, pointer         :: xp(:,:), iwork(:)
  character                :: tran_
  character(len=20)        :: name, ch_err
  logical                  :: aliw

  name='psb_ihalom'
  if(psb_get_errstatus().ne.0) return 
  info=0
  call psb_erractionsave(err_act)

  ictxt=psb_cd_get_context(desc_a)

  ! check on blacs grid 
  call psb_info(ictxt, me, np)
  if (np == -1) then
    info = 2010
    call psb_errpush(info,name)
    goto 9999
  endif

  ix = 1
  if (present(jx)) then
    ijx = jx
  else
    ijx = 1
  endif

  m = psb_cd_get_global_rows(desc_a)
  n = psb_cd_get_global_cols(desc_a)
  nrow = psb_cd_get_local_rows(desc_a)

  maxk=size(x,2)-ijx+1

  if(present(ik)) then
    if(ik.gt.maxk) then
      k=maxk
    else
      k=ik
    end if
  else
    k = maxk
  end if

  if (present(tran)) then     
    tran_ = toupper(tran)
  else
    tran_ = 'N'
  endif

  if (present(data)) then     
    data_ = data
  else
    data_ = psb_comm_halo_
  endif


  if (present(mode)) then 
    imode = mode
  else
    imode = IOR(psb_swap_send_,psb_swap_recv_)
  endif

  ! check vector correctness
  call psb_chkvect(m,1,size(x,1),ix,ijx,desc_a,info,iix,jjx)
  if(info.ne.0) then
    info=4010
    ch_err='psb_chkvect'
    call psb_errpush(info,name,a_err=ch_err)
  end if

  if (iix.ne.1) then
    info=3040
    call psb_errpush(info,name)
  end if

  err=info
  call psb_errcomm(ictxt,err)
  if(err.ne.0) goto 9999


  ! we should write an "iscal"
!!$  if(present(alpha)) then
!!$     if(alpha.ne.1.d0) then
!!$        do i=0, k-1
!!$           call iscal(nrow,alpha,x(1,jjx+i),1)
!!$        end do
!!$     end if
!!$  end if

  liwork=nrow
  if (present(work)) then
    if(size(work).ge.liwork) then
      aliw=.false.
      iwork => work
    else
      aliw=.true.
      allocate(iwork(liwork),stat=info)
      if(info.ne.0) then
        info=4010
        ch_err='psb_realloc'
        call psb_errpush(info,name,a_err=ch_err)
        goto 9999
      end if
    end if
  else
    aliw=.true.
    allocate(iwork(liwork),stat=info)
    if(info.ne.0) then
      info=4010
      ch_err='psb_realloc'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if
  end if

  xp => x(iix:size(x,1),jjx:jjx+k-1)
  ! exchange halo elements
  if(tran_ == 'N') then
    call psi_swapdata(imode,k,izero,xp,&
         & desc_a,iwork,info,data=data_)
  else if((tran_ == 'T').or.(tran_ == 'C')) then
    call psi_swaptran(imode,k,ione,xp,&
         & desc_a,iwork,info)
  else
    info = 4001
    call psb_errpush(info,name,a_err='invalid tran')
    goto 9999      
  end if

  if(info.ne.0) then
    call psb_errpush(4010,name,a_err='PSI_iSwap...')
    goto 9999
  end if

  if (aliw) deallocate(iwork)
  nullify(iwork)

  call psb_erractionrestore(err_act)
  return  

9999 continue
  call psb_erractionrestore(err_act)

  if (err_act == psb_act_abort_) then
    call psb_error(ictxt)
    return
  end if
  return
end subroutine psb_ihalom




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

! Subroutine: psb_ihalov
!   This subroutine performs the exchange of the halo elements in a 
!    distributed dense matrix between all the processes.
!
! Arguments:
!   x         -  integer,dimension(:).         The local part of the dense matrix.
!   desc_a    -  type(psb_desc_type).        The communication descriptor.
!   info      -  integer.                      Return code
!   alpha     -  real(optional).               Scale factor.
!   jx        -  integer(optional).            The starting column of the global matrix. 
!   ik        -  integer(optional).            The number of columns to gather. 
!   work      -  real(optional).               Work  area.
!   tran      -  character(optional).          Transpose exchange.
!   mode      -  integer(optional).            Communication mode (see Swapdata)
!   data     - integer                 Which index list in desc_a should be used
!                                      to retrieve rows, default psb_comm_halo_
!                                       psb_comm_halo_    use halo_index
!                                       psb_comm_ext_     use ext_index 
!                                       psb_comm_ovrl_    use ovrl_index
!
!
subroutine  psb_ihalov(x,desc_a,info,alpha,work,tran,mode,data)
  use psb_descriptor_type
  use psb_const_mod
  use psi_mod
  use psb_check_mod
  use psb_realloc_mod
  use psb_error_mod
  use psb_string_mod
  use psb_penv_mod
  implicit none

  integer, intent(inout)                   :: x(:)
  type(psb_desc_type), intent(in)          :: desc_a
  integer, intent(out)                     :: info
  real(kind(1.d0)), intent(in), optional   :: alpha
  integer, intent(inout), optional, target :: work(:)
  integer, intent(in), optional            :: mode,data
  character, intent(in), optional          :: tran

  ! locals
  integer                  :: ictxt, np, me,&
       & err_act, m, n, iix, jjx, ix, ijx, nrow, imode,&
       & err, liwork, data_
  integer,pointer          :: iwork(:)
  character                :: tran_
  character(len=20)        :: name, ch_err
  logical                  :: aliw

  name='psb_ihalov'
  if(psb_get_errstatus().ne.0) return 
  info=0
  call psb_erractionsave(err_act)

  ictxt=psb_cd_get_context(desc_a)

  ! check on blacs grid 
  call psb_info(ictxt, me, np)
  if (np == -1) then
    info = 2010
    call psb_errpush(info,name)
    goto 9999
  endif

  ix = 1
  ijx = 1

  m = psb_cd_get_global_rows(desc_a)
  n = psb_cd_get_global_cols(desc_a)
  nrow = psb_cd_get_local_rows(desc_a)
  !  ncol = psb_cd_get_local_cols(desc_a)


  if (present(tran)) then     
    tran_ = toupper(tran)
  else
    tran_ = 'N'
  endif
  if (present(data)) then     
    data_ = data
  else
    data_ = psb_comm_halo_
  endif
  if (present(mode)) then 
    imode = mode
  else
    imode = IOR(psb_swap_send_,psb_swap_recv_)
  endif

  ! check vector correctness
  call psb_chkvect(m,1,size(x,1),ix,ijx,desc_a,info,iix,jjx)
  if(info.ne.0) then
    info=4010
    ch_err='psb_chkvect'
    call psb_errpush(info,name,a_err=ch_err)
  end if

  if (iix.ne.1) then
    info=3040
    call psb_errpush(info,name)
  end if

  err=info
  call psb_errcomm(ictxt,err)
  if(err.ne.0) goto 9999

!!$  if(present(alpha)) then
!!$     if(alpha.ne.1.d0) then
!!$        call dscal(nrow,alpha,x,1)
!!$     end if
!!$  end if

  liwork=nrow
  if (present(work)) then
    if(size(work).ge.liwork) then
      aliw=.false.
      iwork => work
    else
      aliw=.true.
      allocate(iwork(liwork),stat=info)
      if(info.ne.0) then
        info=4010
        ch_err='psb_realloc'
        call psb_errpush(info,name,a_err=ch_err)
        goto 9999
      end if
    end if
  else
    aliw=.true.
    allocate(iwork(liwork),stat=info)
    if(info.ne.0) then
      info=4010
      ch_err='psb_realloc'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if
  end if

  ! exchange halo elements
  if(tran_ == 'N') then
    call psi_swapdata(imode,izero,x(iix:size(x)),&
         & desc_a,iwork,info,data=data_)
  else if((tran_ == 'T').or.(tran_ == 'C')) then
    call psi_swaptran(imode,ione,x(iix:size(x)),&
         & desc_a,iwork,info)
  else
    info = 4001
    call psb_errpush(info,name,a_err='invalid tran')
    goto 9999      
  end if

  if(info.ne.0) then
    call psb_errpush(4010,name,a_err='PSI_iswapdata')
    goto 9999
  end if

  if (aliw) deallocate(iwork)
  nullify(iwork)

  call psb_erractionrestore(err_act)
  return  

9999 continue
  call psb_erractionrestore(err_act)

  if (err_act == psb_act_abort_) then
    call psb_error(ictxt)
    return
  end if
  return
end subroutine psb_ihalov



