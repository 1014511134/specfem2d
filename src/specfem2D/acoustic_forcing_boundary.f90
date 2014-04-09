! define the forcing applied at the bottom boundary
! programmer Florian Cachoux and Raphael F. Garcia
! in collaboration with D. Komatitsch and R. Martin
! variable forcing_type should be passed as a parameter
! in future versions

  subroutine acoustic_forcing_boundary(it,deltat,t0,accel_x,accel_z,iglob,coord,nglob)

  implicit none

  include "constants.h"

! input variables
  integer, intent(in) :: nglob

  double precision, dimension(NDIM,nglob), intent(in) :: coord
  double precision :: deltat
  double precision :: t0
  integer :: it,iglob
! These variables are in fact displacements of the boundary
  real(kind=CUSTOM_REAL) :: accel_x,accel_z



! local variables
  real, parameter :: pigrec = 3.1415927
  real :: alpha,tho,A,c,x,delayed,delta_x
  integer :: forcing_type,k,ngoce_time_step,n_models,kk,ll

  double precision, dimension(:), allocatable :: goce_time,distance
  double precision, dimension(:,:), allocatable ::syn
  double precision :: t,signal_x1,signal_x2,fracx,fract

  forcing_type = 1


  delta_x = 2.4       ! length of a PML element along x-axis at the edge which will be forced
  alpha = 2

! infrasounds / seismic
  tho = 30.0

! gravity wave test function
!  tho = 600.0
!  xo = 500000.0
!  lambdo = 20000.0

! gravity wave test function
!  tho = 600.0
!  xo = 3000.0
!  lambdo = 120.0

! gravity wave /tsunami
!  tho = 600.0 ! *20
!  c = 200.0 ! /20

  A = 1
  x = coord(1,iglob)
  delayed = 0

! speed of light
  c = 300000000.

  if(forcing_type == 1) then !! First test function : same forcing for the whole boundary
!  print *, ispec_acoustic
!  print *, is_PML(ispec_acoustic)
!  if(is_PML(ispec_acoustic)) then
!  accel_x = 0
!  accel_z = 0
!  else

! infrasounds / seismic
  accel_x = 0 !* Apo
  accel_z = A * (exp(-(alpha*(deltat*it-40-t0)/tho)**2) &
            - exp(-(alpha*(deltat*it-70-t0)/tho)**2)) !* Apo

! gravity wave test function
!  accel_x = 0 !* Apo
!  accel_z = A * ( exp(-(alpha*(x-(xo-lambdo/2))/lambdo)**2) - &
!                  exp(-(alpha*(x-(xo+lambdo/2))/lambdo)**2) ) * &
!            (exp(-(alpha*(deltat*it+1000-t0)/tho)**2) &
!            - exp(-(alpha*(deltat*it-1300-t0)/tho)**2)) !* Apo

! gravity wave /tsunami
!  accel_x = 0 !* Apo
!  accel_z = A * (exp(-(alpha*(deltat*it-1000-t0)/tho)**2) &
!            - exp(-(alpha*(deltat*it-1600-t0)/tho)**2)) !* Apo


  endif

  if(forcing_type == 2) then !! Second test function : moving forcing
  accel_x = 0 !* Apo

  accel_z = A * (exp(-(alpha*(deltat*it-40-t0-(x-delayed)/c)/tho)**2) &
            - exp(-(alpha*(deltat*it-70-t0-(x-delayed)/c)/tho)**2)) !* Apo
  endif

  if(forcing_type == 3) then !! forcing external
    ngoce_time_step = 255
    n_models = 28
    t =it*deltat

    allocate(goce_time(ngoce_time_step))
    allocate(distance(n_models))
    allocate(syn(n_models,ngoce_time_step))

!    open(1000,file='/home/etudiant/SPECFEM2D/infile_specfem2D/along_goce_orbit/distance.txt', &
    open(1000,file='../../EXAMPLES/acoustic_forcing_bottom/distance.txt', &
                form='formatted')
!    open(1001,file='/home/etudiant/SPECFEM2D/infile_specfem2D/along_goce_orbit/forcing_signals.txt', &
    open(1001,file='../../EXAMPLES/acoustic_forcing_bottom/forcing_signals.txt', &
                  form='formatted')

    read(1001,*) goce_time(:)

    do k=1,n_models
      read(1001,*) syn(k,:)
      read(1000,*) distance(k)
    enddo

    close(1000)
    close(1001)

    kk = 1
    do while(x >= distance(kk) .and. kk /= n_models)
      kk = kk+1
    enddo

    ll = 1
    do while(t >= goce_time(ll) .and. ll /= ngoce_time_step)
      ll = ll+1
    enddo

      if(x==0 .and. it==1) then
        accel_z =  syn(1,1)
      else
        if(x==0) then
          fract = (t-goce_time(ll-1))/(goce_time(ll)-goce_time(ll-1))
          accel_z =  (syn(1,ll-1) + fract * (syn(1,ll)-syn(1,ll-1)))
        else
          if(it==1) then
            fracx = (x-distance(kk-1))/(distance(kk)-distance(kk-1))
            accel_z =  (syn(kk-1,1) + fracx * (syn(kk,1)-syn(kk-1,1)))
          else
    ! interpolation in time
    fract = (t-goce_time(ll-1))/(goce_time(ll)-goce_time(ll-1))
    ! in x1 = distance(kk-1)
    signal_x1 = syn(kk-1,ll-1) + fract * (syn(kk-1,ll)-syn(kk-1,ll-1))
    ! in x2 = distance(kk)
    signal_x2 = syn(kk,ll-1) + fract * (syn(kk,ll)-syn(kk,ll-1))

    ! spatial interpolation
    fracx = (x-distance(kk-1))/(distance(kk)-distance(kk-1))
    accel_z =  (signal_x1 + fracx * (signal_x2 - signal_x1))
          endif
        endif
      endif

  accel_x = 0

  endif

  if (abs(accel_x) < TINYVAL) accel_x=ZERO
  if (abs(accel_z) < TINYVAL) accel_z=ZERO


  end subroutine acoustic_forcing_boundary
