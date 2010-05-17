module psb_z_csr_mat_mod

  use psb_z_base_mat_mod

  type, extends(psb_z_base_sparse_mat) :: psb_z_csr_sparse_mat

    integer, allocatable :: irp(:), ja(:)
    complex(psb_dpk_), allocatable :: val(:)

  contains
    procedure, pass(a) :: get_size     => z_csr_get_size
    procedure, pass(a) :: get_nzeros   => z_csr_get_nzeros
    procedure, pass(a) :: get_fmt      => z_csr_get_fmt
    procedure, pass(a) :: sizeof       => z_csr_sizeof
    procedure, pass(a) :: z_csmm       => psb_z_csr_csmm
    procedure, pass(a) :: z_csmv       => psb_z_csr_csmv
    procedure, pass(a) :: z_inner_cssm => psb_z_csr_cssm
    procedure, pass(a) :: z_inner_cssv => psb_z_csr_cssv
    procedure, pass(a) :: z_scals      => psb_z_csr_scals
    procedure, pass(a) :: z_scal       => psb_z_csr_scal
    procedure, pass(a) :: csnmi        => psb_z_csr_csnmi
    procedure, pass(a) :: reallocate_nz => psb_z_csr_reallocate_nz
    procedure, pass(a) :: allocate_mnnz => psb_z_csr_allocate_mnnz
    procedure, pass(a) :: cp_to_coo    => psb_z_cp_csr_to_coo
    procedure, pass(a) :: cp_from_coo  => psb_z_cp_csr_from_coo
    procedure, pass(a) :: cp_to_fmt    => psb_z_cp_csr_to_fmt
    procedure, pass(a) :: cp_from_fmt  => psb_z_cp_csr_from_fmt
    procedure, pass(a) :: mv_to_coo    => psb_z_mv_csr_to_coo
    procedure, pass(a) :: mv_from_coo  => psb_z_mv_csr_from_coo
    procedure, pass(a) :: mv_to_fmt    => psb_z_mv_csr_to_fmt
    procedure, pass(a) :: mv_from_fmt  => psb_z_mv_csr_from_fmt
    procedure, pass(a) :: csput        => psb_z_csr_csput
    procedure, pass(a) :: get_diag     => psb_z_csr_get_diag
    procedure, pass(a) :: csgetptn     => psb_z_csr_csgetptn
    procedure, pass(a) :: z_csgetrow   => psb_z_csr_csgetrow
    procedure, pass(a) :: get_nz_row   => z_csr_get_nz_row
    procedure, pass(a) :: reinit       => psb_z_csr_reinit
    procedure, pass(a) :: trim         => psb_z_csr_trim
    procedure, pass(a) :: print        => psb_z_csr_print
    procedure, pass(a) :: free         => z_csr_free
    procedure, pass(a) :: psb_z_csr_cp_from
    generic, public    :: cp_from => psb_z_csr_cp_from
    procedure, pass(a) :: psb_z_csr_mv_from
    generic, public    :: mv_from => psb_z_csr_mv_from

  end type psb_z_csr_sparse_mat

  private :: z_csr_get_nzeros, z_csr_free,  z_csr_get_fmt, &
       & z_csr_get_size, z_csr_sizeof, z_csr_get_nz_row

  interface
    subroutine  psb_z_csr_reallocate_nz(nz,a) 
      import psb_z_csr_sparse_mat
      integer, intent(in) :: nz
      class(psb_z_csr_sparse_mat), intent(inout) :: a
    end subroutine psb_z_csr_reallocate_nz
  end interface
  
  interface 
    subroutine psb_z_csr_reinit(a,clear)
      import psb_z_csr_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout) :: a   
      logical, intent(in), optional :: clear
    end subroutine psb_z_csr_reinit
  end interface
  
  interface
    subroutine  psb_z_csr_trim(a)
      import psb_z_csr_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout) :: a
    end subroutine psb_z_csr_trim
  end interface
  
  interface
    subroutine  psb_z_csr_allocate_mnnz(m,n,a,nz) 
      import psb_z_csr_sparse_mat
      integer, intent(in) :: m,n
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      integer, intent(in), optional :: nz
    end subroutine psb_z_csr_allocate_mnnz
  end interface
  
  interface
    subroutine psb_z_csr_print(iout,a,iv,eirs,eics,head,ivr,ivc)
      import psb_z_csr_sparse_mat
      integer, intent(in)               :: iout
      class(psb_z_csr_sparse_mat), intent(in) :: a   
      integer, intent(in), optional     :: iv(:)
      integer, intent(in), optional     :: eirs,eics
      character(len=*), optional        :: head
      integer, intent(in), optional     :: ivr(:), ivc(:)
    end subroutine psb_z_csr_print
  end interface
  
  interface 
    subroutine psb_z_cp_csr_to_coo(a,b,info) 
      import psb_z_coo_sparse_mat, psb_z_csr_sparse_mat
      class(psb_z_csr_sparse_mat), intent(in) :: a
      class(psb_z_coo_sparse_mat), intent(inout) :: b
      integer, intent(out)            :: info
    end subroutine psb_z_cp_csr_to_coo
  end interface
  
  interface 
    subroutine psb_z_cp_csr_from_coo(a,b,info) 
      import psb_z_csr_sparse_mat, psb_z_coo_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      class(psb_z_coo_sparse_mat), intent(in)    :: b
      integer, intent(out)                        :: info
    end subroutine psb_z_cp_csr_from_coo
  end interface
  
  interface 
    subroutine psb_z_cp_csr_to_fmt(a,b,info) 
      import psb_z_csr_sparse_mat, psb_z_base_sparse_mat
      class(psb_z_csr_sparse_mat), intent(in)   :: a
      class(psb_z_base_sparse_mat), intent(inout) :: b
      integer, intent(out)                       :: info
    end subroutine psb_z_cp_csr_to_fmt
  end interface
  
  interface 
    subroutine psb_z_cp_csr_from_fmt(a,b,info) 
      import psb_z_csr_sparse_mat, psb_z_base_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      class(psb_z_base_sparse_mat), intent(in)   :: b
      integer, intent(out)                        :: info
    end subroutine psb_z_cp_csr_from_fmt
  end interface
  
  interface 
    subroutine psb_z_mv_csr_to_coo(a,b,info) 
      import psb_z_csr_sparse_mat, psb_z_coo_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      class(psb_z_coo_sparse_mat), intent(inout)   :: b
      integer, intent(out)            :: info
    end subroutine psb_z_mv_csr_to_coo
  end interface
  
  interface 
    subroutine psb_z_mv_csr_from_coo(a,b,info) 
      import psb_z_csr_sparse_mat, psb_z_coo_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      class(psb_z_coo_sparse_mat), intent(inout) :: b
      integer, intent(out)                        :: info
    end subroutine psb_z_mv_csr_from_coo
  end interface
  
  interface 
    subroutine psb_z_mv_csr_to_fmt(a,b,info) 
      import psb_z_csr_sparse_mat, psb_z_base_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      class(psb_z_base_sparse_mat), intent(inout)  :: b
      integer, intent(out)                        :: info
    end subroutine psb_z_mv_csr_to_fmt
  end interface
  
  interface 
    subroutine psb_z_mv_csr_from_fmt(a,b,info) 
      import psb_z_csr_sparse_mat, psb_z_base_sparse_mat
      class(psb_z_csr_sparse_mat), intent(inout)  :: a
      class(psb_z_base_sparse_mat), intent(inout) :: b
      integer, intent(out)                         :: info
    end subroutine psb_z_mv_csr_from_fmt
  end interface
  
  interface 
    subroutine psb_z_csr_cp_from(a,b)
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      type(psb_z_csr_sparse_mat), intent(in)   :: b
    end subroutine psb_z_csr_cp_from
  end interface
  
  interface 
    subroutine psb_z_csr_mv_from(a,b)
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(inout)  :: a
      type(psb_z_csr_sparse_mat), intent(inout) :: b
    end subroutine psb_z_csr_mv_from
  end interface
  
  
  interface 
    subroutine psb_z_csr_csput(nz,ia,ja,val,a,imin,imax,jmin,jmax,info,gtl) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      complex(psb_dpk_), intent(in)      :: val(:)
      integer, intent(in)             :: nz,ia(:), ja(:),&
           &  imin,imax,jmin,jmax
      integer, intent(out)            :: info
      integer, intent(in), optional   :: gtl(:)
    end subroutine psb_z_csr_csput
  end interface
  
  interface 
    subroutine psb_z_csr_csgetptn(imin,imax,a,nz,ia,ja,info,&
         & jmin,jmax,iren,append,nzin,rscale,cscale)
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      integer, intent(in)                  :: imin,imax
      integer, intent(out)                 :: nz
      integer, allocatable, intent(inout)  :: ia(:), ja(:)
      integer,intent(out)                  :: info
      logical, intent(in), optional        :: append
      integer, intent(in), optional        :: iren(:)
      integer, intent(in), optional        :: jmin,jmax, nzin
      logical, intent(in), optional        :: rscale,cscale
    end subroutine psb_z_csr_csgetptn
  end interface
  
  interface 
    subroutine psb_z_csr_csgetrow(imin,imax,a,nz,ia,ja,val,info,&
         & jmin,jmax,iren,append,nzin,rscale,cscale)
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      integer, intent(in)                  :: imin,imax
      integer, intent(out)                 :: nz
      integer, allocatable, intent(inout)  :: ia(:), ja(:)
      complex(psb_dpk_), allocatable,  intent(inout)    :: val(:)
      integer,intent(out)                  :: info
      logical, intent(in), optional        :: append
      integer, intent(in), optional        :: iren(:)
      integer, intent(in), optional        :: jmin,jmax, nzin
      logical, intent(in), optional        :: rscale,cscale
    end subroutine psb_z_csr_csgetrow
  end interface

  interface 
    subroutine psb_z_csr_csgetblk(imin,imax,a,b,info,&
       & jmin,jmax,iren,append,rscale,cscale)
      import psb_z_csr_sparse_mat, psb_dpk_, psb_z_coo_sparse_mat
      class(psb_z_csr_sparse_mat), intent(in) :: a
      class(psb_z_coo_sparse_mat), intent(inout) :: b
      integer, intent(in)                  :: imin,imax
      integer,intent(out)                  :: info
      logical, intent(in), optional        :: append
      integer, intent(in), optional        :: iren(:)
      integer, intent(in), optional        :: jmin,jmax
      logical, intent(in), optional        :: rscale,cscale
    end subroutine psb_z_csr_csgetblk
  end interface
    
  interface 
    subroutine psb_z_csr_cssv(alpha,a,x,beta,y,info,trans) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      complex(psb_dpk_), intent(in)          :: alpha, beta, x(:)
      complex(psb_dpk_), intent(inout)       :: y(:)
      integer, intent(out)                :: info
      character, optional, intent(in)     :: trans
    end subroutine psb_z_csr_cssv
    subroutine psb_z_csr_cssm(alpha,a,x,beta,y,info,trans) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      complex(psb_dpk_), intent(in)          :: alpha, beta, x(:,:)
      complex(psb_dpk_), intent(inout)       :: y(:,:)
      integer, intent(out)                :: info
      character, optional, intent(in)     :: trans
    end subroutine psb_z_csr_cssm
  end interface
  
  interface 
    subroutine psb_z_csr_csmv(alpha,a,x,beta,y,info,trans) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      complex(psb_dpk_), intent(in)          :: alpha, beta, x(:)
      complex(psb_dpk_), intent(inout)       :: y(:)
      integer, intent(out)                :: info
      character, optional, intent(in)     :: trans
    end subroutine psb_z_csr_csmv
    subroutine psb_z_csr_csmm(alpha,a,x,beta,y,info,trans) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      complex(psb_dpk_), intent(in)          :: alpha, beta, x(:,:)
      complex(psb_dpk_), intent(inout)       :: y(:,:)
      integer, intent(out)                :: info
      character, optional, intent(in)     :: trans
    end subroutine psb_z_csr_csmm
  end interface
  
  
  interface 
    function psb_z_csr_csnmi(a) result(res)
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      real(psb_dpk_)         :: res
    end function psb_z_csr_csnmi
  end interface
  
  interface 
    subroutine psb_z_csr_get_diag(a,d,info) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(in) :: a
      complex(psb_dpk_), intent(out)     :: d(:)
      integer, intent(out)            :: info
    end subroutine psb_z_csr_get_diag
  end interface
  
  interface 
    subroutine psb_z_csr_scal(d,a,info) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      complex(psb_dpk_), intent(in)      :: d(:)
      integer, intent(out)            :: info
    end subroutine psb_z_csr_scal
  end interface
  
  interface
    subroutine psb_z_csr_scals(d,a,info) 
      import psb_z_csr_sparse_mat, psb_dpk_
      class(psb_z_csr_sparse_mat), intent(inout) :: a
      complex(psb_dpk_), intent(in)      :: d
      integer, intent(out)            :: info
    end subroutine psb_z_csr_scals
  end interface
  


contains 

  ! == ===================================
  !
  !
  !
  ! Getters 
  !
  !
  !
  !
  !
  ! == ===================================

  
  function z_csr_sizeof(a) result(res)
    implicit none 
    class(psb_z_csr_sparse_mat), intent(in) :: a
    integer(psb_long_int_k_) :: res
    res = 8 
    res = res + 2 * psb_sizeof_dp  * size(a%val)
    res = res + psb_sizeof_int * size(a%irp)
    res = res + psb_sizeof_int * size(a%ja)
      
  end function z_csr_sizeof

  function z_csr_get_fmt(a) result(res)
    implicit none 
    class(psb_z_csr_sparse_mat), intent(in) :: a
    character(len=5) :: res
    res = 'CSR'
  end function z_csr_get_fmt
  
  function z_csr_get_nzeros(a) result(res)
    implicit none 
    class(psb_z_csr_sparse_mat), intent(in) :: a
    integer :: res
    res = a%irp(a%get_nrows()+1)-1
  end function z_csr_get_nzeros

  function z_csr_get_size(a) result(res)
    implicit none 
    class(psb_z_csr_sparse_mat), intent(in) :: a
    integer :: res

    res = -1
    
    if (allocated(a%ja)) then 
      if (res >= 0) then 
        res = min(res,size(a%ja))
      else 
        res = size(a%ja)
      end if
    end if
    if (allocated(a%val)) then 
      if (res >= 0) then 
        res = min(res,size(a%val))
      else 
        res = size(a%val)
      end if
    end if

  end function z_csr_get_size



  function  z_csr_get_nz_row(idx,a) result(res)

    implicit none
    
    class(psb_z_csr_sparse_mat), intent(in) :: a
    integer, intent(in)                  :: idx
    integer                              :: res
    
    res = 0 
 
    if ((1<=idx).and.(idx<=a%get_nrows())) then 
      res = a%irp(idx+1)-a%irp(idx)
    end if
    
  end function z_csr_get_nz_row



  ! == ===================================
  !
  !
  !
  ! Data management
  !
  !
  !
  !
  !
  ! == ===================================  

  subroutine  z_csr_free(a) 
    implicit none 

    class(psb_z_csr_sparse_mat), intent(inout) :: a

    if (allocated(a%irp)) deallocate(a%irp)
    if (allocated(a%ja)) deallocate(a%ja)
    if (allocated(a%val)) deallocate(a%val)
    call a%set_null()
    call a%set_nrows(0)
    call a%set_ncols(0)
    
    return

  end subroutine z_csr_free


end module psb_z_csr_mat_mod