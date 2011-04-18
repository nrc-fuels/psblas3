module psb_c_diagprec

  use psb_c_base_prec_mod
  
  type, extends(psb_c_base_prec_type) :: psb_c_diag_prec_type
    complex(psb_spk_), allocatable :: d(:)
  contains
    procedure, pass(prec) :: apply     => psb_c_diag_apply
    procedure, pass(prec) :: precbld   => psb_c_diag_precbld
    procedure, pass(prec) :: precinit  => psb_c_diag_precinit  
    procedure, pass(prec) :: precseti  => psb_c_diag_precseti
    procedure, pass(prec) :: precsetr  => psb_c_diag_precsetr
    procedure, pass(prec) :: precsetc  => psb_c_diag_precsetc
    procedure, pass(prec) :: precfree  => psb_c_diag_precfree
    procedure, pass(prec) :: precdescr => psb_c_diag_precdescr
    procedure, pass(prec) :: sizeof    => psb_c_diag_sizeof
  end type psb_c_diag_prec_type

  private :: psb_c_diag_apply, psb_c_diag_precbld, psb_c_diag_precseti,&
       & psb_c_diag_precsetr, psb_c_diag_precsetc, psb_c_diag_sizeof,&
       & psb_c_diag_precinit, psb_c_diag_precfree, psb_c_diag_precdescr
  

contains
  

  subroutine psb_c_diag_apply(alpha,prec,x,beta,y,desc_data,info,trans,work)
    use psb_base_mod
    type(psb_desc_type),intent(in)    :: desc_data
    class(psb_c_diag_prec_type), intent(in)  :: prec
    complex(psb_spk_),intent(inout)      :: x(:)
    complex(psb_spk_),intent(in)         :: alpha, beta
    complex(psb_spk_),intent(inout)      :: y(:)
    integer, intent(out)              :: info
    character(len=1), optional        :: trans
    complex(psb_spk_),intent(inout), optional, target :: work(:)
    Integer :: err_act, nrow
    character :: trans_
    character(len=20)  :: name='c_diag_prec_apply'
    complex(psb_spk_), pointer :: ww(:)

    call psb_erractionsave(err_act)

    !
    ! This is the base version and we should throw an error. 
    ! Or should it be the DIAG preonditioner???
    !
    info = psb_success_
    

    nrow = psb_cd_get_local_rows(desc_data)
    if (size(x) < nrow) then 
      info = 36
      call psb_errpush(info,name,i_err=(/2,nrow,0,0,0/))
      goto 9999
    end if
    if (size(y) < nrow) then 
      info = 36
      call psb_errpush(info,name,i_err=(/3,nrow,0,0,0/))
      goto 9999
    end if
    if (.not.allocated(prec%d)) then
      info = 1124
      call psb_errpush(info,name,a_err="preconditioner: D")
      goto 9999
    end if
    if (size(prec%d) < nrow) then
      info = 1124
      call psb_errpush(info,name,a_err="preconditioner: D")
      goto 9999
    end if
    if (present(trans)) then 
      trans_ = psb_toupper(trans)
    else
      trans_='N'
    end if

    select case(trans_)
    case('N')
    case('T','C')
    case default
      info=psb_err_iarg_invalid_i_
      call psb_errpush(info,name,&
           & i_err=(/6,0,0,0,0/),a_err=trans_)
      goto 9999
    end select
    
    if (size(work) >= size(x)) then 
      ww => work
    else
      allocate(ww(size(x)),stat=info)
      if (info /= psb_success_) then 
        call psb_errpush(psb_err_alloc_request_,name,&
             & i_err=(/size(x),0,0,0,0/),a_err='complex(psb_spk_)')
        goto 9999      
      end if
    end if


    if (trans_ == 'C') then 
      ww(1:nrow) = x(1:nrow)*conjg(prec%d(1:nrow))
    else
      ww(1:nrow) = x(1:nrow)*prec%d(1:nrow)
    endif
    call psb_geaxpby(alpha,ww,beta,y,desc_data,info)

    if (size(work) < size(x)) then 
      deallocate(ww,stat=info)
      if (info /= psb_success_) then 
        call psb_errpush(psb_err_from_subroutine_,name,a_err='Deallocate')
        goto 9999      
      end if
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

  end subroutine psb_c_diag_apply

  subroutine psb_c_diag_precinit(prec,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_c_diag_prec_type),intent(inout) :: prec
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='c_diag_precinit'

    call psb_erractionsave(err_act)

    info = psb_success_

    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine psb_c_diag_precinit


  subroutine psb_c_diag_precbld(a,desc_a,prec,info,upd,mold,afmt)
    
    use psb_base_mod
    Implicit None
    
    type(psb_cspmat_type), intent(in), target :: a
    type(psb_desc_type), intent(in), target   :: desc_a
    class(psb_c_diag_prec_type),intent(inout) :: prec
    integer, intent(out)                      :: info
    character, intent(in), optional           :: upd
    character(len=*), intent(in), optional    :: afmt
    class(psb_c_base_sparse_mat), intent(in), optional :: mold
    Integer :: err_act, nrow,i
    character(len=20)  :: name='c_diag_precbld'

    call psb_erractionsave(err_act)

    info = psb_success_
    nrow = psb_cd_get_local_cols(desc_a)
    if (allocated(prec%d)) then 
      if (size(prec%d) < nrow) then 
        deallocate(prec%d,stat=info)
      end if
    end if
    if ((info == psb_success_).and.(.not.allocated(prec%d))) then 
      allocate(prec%d(nrow), stat=info)
    end if
    if (info /= psb_success_) then 
      info = psb_err_alloc_dealloc_
      call psb_errpush(info,name)
      goto 9999
    end if

    call a%get_diag(prec%d,info) 
    if (info /= psb_success_) then 
      info = psb_err_from_subroutine_
      call psb_errpush(info,name, a_err='get_diag')
      goto 9999
    end if
    
    do i=1,nrow
      if (prec%d(i) == dzero) then
        prec%d(i) = done
      else
        prec%d(i) = done/prec%d(i)
      endif
    end do

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine psb_c_diag_precbld

  subroutine psb_c_diag_precseti(prec,what,val,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_c_diag_prec_type),intent(inout) :: prec
    integer, intent(in)                      :: what 
    integer, intent(in)                      :: val 
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='c_diag_precset'

    call psb_erractionsave(err_act)

    info = psb_success_
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine psb_c_diag_precseti

  subroutine psb_c_diag_precsetr(prec,what,val,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_c_diag_prec_type),intent(inout) :: prec
    integer, intent(in)                      :: what 
    real(psb_spk_), intent(in)               :: val 
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='c_diag_precset'

    call psb_erractionsave(err_act)

    info = psb_success_
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine psb_c_diag_precsetr

  subroutine psb_c_diag_precsetc(prec,what,val,info)
    
    use psb_base_mod
    Implicit None
    
    class(psb_c_diag_prec_type),intent(inout) :: prec
    integer, intent(in)                      :: what 
    character(len=*), intent(in)             :: val
    integer, intent(out)                     :: info
    Integer :: err_act, nrow
    character(len=20)  :: name='c_diag_precset'

    call psb_erractionsave(err_act)

    info = psb_success_
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine psb_c_diag_precsetc

  subroutine psb_c_diag_precfree(prec,info)
    
    use psb_base_mod
    Implicit None

    class(psb_c_diag_prec_type), intent(inout) :: prec
    integer, intent(out)                :: info
    
    Integer :: err_act, nrow
    character(len=20)  :: name='c_diag_precset'
    
    call psb_erractionsave(err_act)
    
    info = psb_success_
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
    
  end subroutine psb_c_diag_precfree
  

  subroutine psb_c_diag_precdescr(prec,iout)
    
    use psb_base_mod
    Implicit None

    class(psb_c_diag_prec_type), intent(in) :: prec
    integer, intent(in), optional    :: iout

    Integer :: err_act, nrow, info
    character(len=20)  :: name='c_diag_precdescr'

    integer :: iout_

    call psb_erractionsave(err_act)

    info = psb_success_
   
    if (present(iout)) then 
      iout_ = iout
    else
      iout_ = 6 
    end if

    write(iout_,*) 'Diagonal scaling'

    call psb_erractionsave(err_act)

    info = psb_success_
    
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
    
  end subroutine psb_c_diag_precdescr

  function psb_c_diag_sizeof(prec) result(val)
    use psb_base_mod
    class(psb_c_diag_prec_type), intent(in) :: prec
    integer(psb_long_int_k_) :: val
    
    val = 0
    val = val + 2*psb_sizeof_sp * size(prec%d)
    return
  end function psb_c_diag_sizeof

end module psb_c_diagprec