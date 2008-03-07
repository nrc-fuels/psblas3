!!$ 
!!$              Parallel Sparse BLAS  version 2.2
!!$    (C) Copyright 2006/2007/2008
!!$                       Salvatore Filippone    University of Rome Tor Vergata
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
! File:  psb_dcsnmi.f90 
! Subroutine: 
! Arguments:

function psb_dcsnmi(a,info,trans)

  use psb_spmat_type
  use psb_error_mod
  implicit none

  type(psb_dspmat_type), intent(in)  :: a
  integer, intent(out)               :: info
  character, optional                :: trans
  real(psb_dpk_)                     :: psb_dcsnmi
  interface
     function dcsnmi(trans,m,n,fida,descra,a,ia1,ia2,&
          &                 infoa,ierror)
       use psb_const_mod
       real(psb_dpk_)   :: dcsnmi
       integer          ::  m,n, ierror
       character        ::  trans
       integer          ::  ia1(*),ia2(*),infoa(*)
       character        ::  descra*11, fida*5
       real(psb_dpk_) ::  a(*)
     end function dcsnmi
  end interface

  integer             :: err_act
  character           :: itrans
  character(len=20)   :: name, ch_err

  name='psb_dcsnmi'
  call psb_erractionsave(err_act)

  if(present(trans)) then
     itrans=trans
  else
     itrans='N'
  end if

  psb_dcsnmi = dcsnmi(itrans,a%m,a%k,a%fida,a%descra,a%aspk,a%ia1,a%ia2,a%infoa,info)
  if(info/=0) then
     psb_dcsnmi = -1
     info=4010
     ch_err='psb_dcsnmi'
     call psb_errpush(info,name,a_err=ch_err)
     goto 9999
  end if
  

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
     call psb_error()
     return
  end if
  return

end function psb_dcsnmi
