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
subroutine psb_sprecinit(p,ptype,info)

  use psb_sparse_mod
  use psb_prec_mod, psb_protect_name => psb_sprecinit
  use psb_s_nullprec
  use psb_s_diagprec
  use psb_s_bjacprec
  implicit none
  type(psb_sprec_type), intent(inout)    :: p
  character(len=*), intent(in)           :: ptype
  integer, intent(out)                   :: info

  info = 0

  if (allocated(p%prec) ) then
    call p%prec%precfree(info)
    if (info == 0) deallocate(p%prec,stat=info) 
    if (info /= 0) return
  end if
  
  select case(psb_toupper(ptype(1:len_trim(ptype))))
  case ('NONE','NOPREC') 
    
    allocate(psb_s_null_prec_type :: p%prec, stat=info)       
    
  case ('DIAG')
    allocate(psb_s_diag_prec_type :: p%prec, stat=info)       
    
  case ('BJAC') 
    allocate(psb_s_bjac_prec_type :: p%prec, stat=info)       
    
  case default
    write(0,*) 'Unknown preconditioner type request "',ptype,'"'
    info = 2
    
  end select
  if (info == 0)  call p%prec%precinit(info)
  
end subroutine psb_sprecinit
