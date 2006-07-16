!!$ 
!!$ 
!!$                    MD2P4
!!$    Multilevel Domain Decomposition Parallel Preconditioner Package for PSBLAS
!!$                      for 
!!$              Parallel Sparse BLAS  v2.0
!!$    (C) Copyright 2006 Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
!!$                       Daniela Di Serafino    II University of Naples
!!$                       Pasqua D'Ambra         ICAR-CNR                      
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the MD2P4 group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MD2P4 GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$  
subroutine psb_zprc_aply(prec,x,y,desc_data,info,trans, work)

  use psb_serial_mod
  use psb_descriptor_type
  use psb_prec_type
  use psb_psblas_mod
  use psb_const_mod
  use psb_error_mod
  use psb_penv_mod
  implicit none

  type(psb_desc_type),intent(in)      :: desc_data
  type(psb_zprec_type), intent(in)    :: prec
  complex(kind(0.d0)),intent(inout)   :: x(:), y(:)
  integer, intent(out)                :: info
  character(len=1), optional          :: trans
  complex(kind(0.d0)), optional, target  :: work(:)

  ! Local variables
  character     :: trans_ 
  complex(kind(1.d0)), pointer :: work_(:)
  integer :: ictxt,np,me,err_act
  logical,parameter                 :: debug=.false., debugprt=.false.
  external mpi_wtime
  character(len=20)   :: name

  interface psb_baseprc_aply
     subroutine psb_zbaseprc_aply(prec,x,beta,y,desc_data,trans,work,info)
       use psb_descriptor_type
       use psb_prec_type
       type(psb_desc_type),intent(in)      :: desc_data
       type(psb_zbaseprc_type), intent(in) :: prec
       complex(kind(0.d0)),intent(inout)   :: x(:), y(:)
       complex(kind(0.d0)),intent(in)      :: beta
       character(len=1)                    :: trans
       complex(kind(0.d0)),target          :: work(:)
       integer, intent(out)                :: info
     end subroutine psb_zbaseprc_aply
  end interface

  interface psb_mlprc_aply
     subroutine psb_zmlprc_aply(baseprecv,x,beta,y,desc_data,trans,work,info)
       use psb_descriptor_type
       use psb_prec_type
       type(psb_desc_type),intent(in)      :: desc_data
       type(psb_zbaseprc_type), intent(in) :: baseprecv(:)
       complex(kind(0.d0)),intent(in)      :: beta
       complex(kind(0.d0)),intent(inout)   :: x(:), y(:)
       character                           :: trans
       complex(kind(0.d0)),target          :: work(:)
       integer, intent(out)                :: info
     end subroutine psb_zmlprc_aply
  end interface
  
  name='psb_zprc_aply'
  info = 0
  call psb_erractionsave(err_act)

  ictxt=desc_data%matrix_data(psb_ctxt_)
  call psb_info(ictxt, me, np)

  if (present(trans)) then 
    trans_=trans
  else
    trans_='N'
  end if

  if (present(work)) then 
    work_ => work
  else
    allocate(work_(4*desc_data%matrix_data(psb_n_col_)),stat=info)
    if (info /= 0) then 
      call psb_errpush(4010,name,a_err='Allocate')
      goto 9999      
    end if

  end if

  if (.not.(associated(prec%baseprecv))) then 
    write(0,*) 'Inconsistent preconditioner: neither SMTH nor BASE?'      
  end if
  if (size(prec%baseprecv) >1) then 
    if (debug) write(0,*) 'Into mlprc_aply',size(x),size(y)
    call psb_mlprc_aply(prec%baseprecv,x,zzero,y,desc_data,trans_,work_,info)
    if(info /= 0) then
      call psb_errpush(4010,name,a_err='psb_zmlprc_aply')
      goto 9999
    end if

  else  if (size(prec%baseprecv) == 1) then 
    call psb_baseprc_aply(prec%baseprecv(1),x,zzero,y,desc_data,trans_, work_,info)
  else 
    write(0,*) 'Inconsistent preconditioner: size of baseprecv???' 
  endif

  if (present(work)) then 
  else
    deallocate(work_)
  end if

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act.eq.act_abort) then
    call psb_error()
    return
  end if
  return

end subroutine psb_zprc_aply


!!$ 
!!$ 
!!$                    MD2P4
!!$    Multilevel Domain Decomposition Parallel Preconditioner Package for PSBLAS
!!$                      for 
!!$              Parallel Sparse BLAS  v2.0
!!$    (C) Copyright 2006 Salvatore Filippone    University of Rome Tor Vergata
!!$                       Alfredo Buttari        University of Rome Tor Vergata
!!$                       Daniela Di Serafino    II University of Naples
!!$                       Pasqua D'Ambra         ICAR-CNR                      
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the MD2P4 group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MD2P4 GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$  
subroutine psb_zprc_aply1(prec,x,desc_data,info,trans)

  use psb_serial_mod
  use psb_descriptor_type
  use psb_prec_type
  use psb_psblas_mod
  use psb_const_mod
  use psb_error_mod
  use psb_penv_mod
  implicit none

  type(psb_desc_type),intent(in)    :: desc_data
  type(psb_zprec_type), intent(in)  :: prec
  complex(kind(0.d0)),intent(inout) :: x(:)
  integer, intent(out)              :: info
  character(len=1), optional        :: trans
  logical,parameter                 :: debug=.false., debugprt=.false.

  interface 
    subroutine psb_zprc_aply(prec,x,y,desc_data,info,trans, work)
      
      use psb_descriptor_type
      use psb_prec_type
      implicit none
      
      type(psb_desc_type),intent(in)      :: desc_data
      type(psb_zprec_type), intent(in)    :: prec
      complex(kind(0.d0)),intent(inout)   :: x(:), y(:)
      integer, intent(out)                :: info
      character(len=1), optional          :: trans
      complex(kind(0.d0)), optional, target  :: work(:)
    end subroutine psb_zprc_aply
  end interface

  ! Local variables
  character     :: trans_
  integer :: ictxt,np,me,i, isz, err_act, int_err(5)
  complex(kind(1.d0)), pointer :: WW(:), w1(:)
  character(len=20)   :: name, ch_err
  name='psb_zprec1'
  info = 0
  call psb_erractionsave(err_act)
  

  ictxt=desc_data%matrix_data(psb_ctxt_)
  call psb_info(ictxt, me, np)
  if (present(trans)) then 
    trans_=trans
  else
    trans_='N'
  end if

  allocate(ww(size(x)),w1(size(x)),stat=info)
  if (info /= 0) then 
    call psb_errpush(4010,name,a_err='Allocate')
    goto 9999      
  end if
  if (debug) write(0,*) 'Prc_aply1 Size(x) ',size(x), size(ww),size(w1)
  call psb_zprc_aply(prec,x,ww,desc_data,info,trans_,work=w1)
  if(info /=0) goto 9999
  x(:) = ww(:)
  deallocate(ww,W1)

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_errpush(info,name)
  call psb_erractionrestore(err_act)
  if (err_act.eq.act_abort) then
     call psb_error()
     return
  end if
  return
end subroutine psb_zprc_aply1
