!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
!      This file is a component of the volcanic ash transport and dispersion model Ash3d,
!      written at the U.S. Geological Survey by Hans F. Schwaiger (hschwaiger@usgs.gov),
!      Larry G. Mastin (lgmastin@usgs.gov), and Roger P. Denlinger (roger@usgs.gov).
!
!      The model and its source code are products of the U.S. Federal Government and therefore
!      bear no copyright.  They may be copied, redistributed and freely incorporated 
!      into derivative products.  However as a matter of scientific courtesy we ask that
!      you credit the authors and cite published documentation of this model (below) when
!      publishing or distributing derivative products.
!
!      Schwaiger, H.F., Denlinger, R.P., and Mastin, L.G., 2012, Ash3d, a finite-
!         volume, conservative numerical model for ash transport and tephra deposition,
!         Journal of Geophysical Research, 117, B04204, doi:10.1029/2011JB008968. 
!
!      Although this program has been used by the USGS, no warranty, expressed or
!      implied, is made by the USGS or the United States Government as to the accuracy
!      and functioning  of the program and related program material nor shall the fact of
!      distribution constitute  any such warranty, and no responsibility is assumed by
!      the USGS in connection therewith.
!
!      We make no guarantees, expressed or implied, as to the usefulness of the software
!      and its documentation for any purpose.  We assume no responsibility to provide
!      technical support to users of this software.
!
!      This fortran 90 module contains three subroutines:
!        PJ_Set_Proj_Params : sets projection parameters by parsing an 80 char sting
!        PJ_proj_for        : calculates x,y coordinates, given lon,lat
!        PJ_proj_inv        : calculates lon,lat coordinates, give x,y
!
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      MODULE projection

      character(len=20), dimension(8) :: params
      integer      :: PJ_ilatlonflag
      integer      :: PJ_iprojflag
      real(kind=8) :: PJ_k0      != 0.933_ip       ! scale factor
      real(kind=8) :: PJ_radius_earth = 6371.229_8
      real(kind=8) :: PJ_lam0,PJ_lam1,PJ_lam2
      real(kind=8) :: PJ_phi0,PJ_phi1,PJ_phi2

      contains

!##############################################################################
!
!     PJ_Set_Proj_Params
!
!     subroutine that prepares parameters for projection call to PJ_proj_for
!     and PJ_proj_inv.  This takes as input, an 80 char string that the
!     calling program reads from an input file.  This string is parsed and
!     the paramters that define the projection are set.
!
!##############################################################################


      subroutine PJ_Set_Proj_Params(linebuffer)

      implicit none

      character(len=80),intent(in) :: linebuffer

      character(len=20) :: buffer
      integer           :: inorth,izone

      read(linebuffer,*)PJ_ilatlonflag

      IF(PJ_ilatlonflag.eq.1)THEN
        ! coordinates are in lon/lat
        return
      ELSEIF(PJ_ilatlonflag.eq.0)THEN
        ! coordinates are projected, read the projection flag
        read(linebuffer,*)PJ_ilatlonflag,PJ_iprojflag
        if(PJ_iprojflag.ne.1.and.PJ_iprojflag.ne.2.and. &
           PJ_iprojflag.ne.3.and.PJ_iprojflag.ne.4.and. &
           PJ_iprojflag.ne.5) then
          write(6,*)"Unrecognized projection flag"
          stop 1
        endif
      ELSE
        ! PJ_ilatlonflag is not 0 or 1, stopping program
        write(6,*)"Unrecognized latlonflag"
        stop 1
      ENDIF


      select case (PJ_iprojflag)

      case(1)
        ! Polar stereographic
        read(linebuffer,*)PJ_ilatlonflag,PJ_iprojflag,PJ_lam0,PJ_phi0,PJ_k0,PJ_radius_earth
        if(abs(PJ_lam0).gt.360.0)then
          write(6,*)"PJ ERROR:  PJ_lam0 should be in in range -360 - 360"
          write(6,*)"   lam0 = ",PJ_lam0
          stop 1
        endif
        if(abs(PJ_phi0).gt.90.0)then
          write(6,*)"PJ ERROR:  PJ_phi0 should be in in range -90 - 30"
          write(6,*)"   PJ_phi0 = ",PJ_phi0
          stop 1
        endif
        if(PJ_k0.le.0.0)then
          write(6,*)"PJ ERROR:  PJ_k0 should > 0"
          write(6,*)"   PJ_k0 = ",PJ_k0
          stop 1
        endif
        if(PJ_radius_earth.le.5000.0.or.PJ_radius_earth.ge.7000.0)then
          write(6,*)"PJ ERROR:  PJ_radius_earth should around 6300 km, not ",PJ_radius_earth
          stop 1
        endif

        ! Preparing parameter list for projection call
        write(buffer,201);                 params(1) = buffer
        write(buffer,202)PJ_lam0;          params(2) = buffer
        write(buffer,203)PJ_phi0;          params(3) = buffer
        write(buffer,204)PJ_k0;            params(4) = buffer
        write(buffer,205)PJ_radius_earth;  params(5) = buffer
          ! Fill remaining parameters with blanks
        write(buffer,206)
        params(6) = buffer
        params(7) = buffer
        params(8) = buffer
201     format('proj=stere')
202     format('lon_0=',f10.3)
203     format('lat_0=',f10.3)
204     format('k_0=',f10.3)
205     format('R=',f10.3)
206     format(' ')

      case(2)
        ! Albers Equal Area
        write(6,*)"WARNING: Albers not yet verified"
        read(linebuffer,*)PJ_ilatlonflag,PJ_iprojflag,PJ_lam0,PJ_phi0,PJ_phi1,PJ_phi2
        if(abs(PJ_lam0).gt.360.0)then
          write(6,*)"PJ ERROR:  PJ_lam0 should be in in range -360 - 360"
          write(6,*)"   PJ_lam0 = ",PJ_lam0
          stop 1
        endif
        if(abs(PJ_phi0).gt.90.0.or.abs(PJ_phi1).gt.90.0.or.abs(PJ_phi2).gt.90.0)then
          write(6,*) &
            "PJ ERROR:  PJ_phi0,1,2 should each be in in range -90 - 90"
          write(6,*)" PJ_phi0,1,2 = ",PJ_phi0,PJ_phi1,PJ_phi2
          stop 1
        endif
        ! Preparing parameter list for projection call
        write(buffer,211);        params(1) = buffer
        write(buffer,212)PJ_lam0; params(2) = buffer
        write(buffer,213)PJ_phi0; params(3) = buffer
        write(buffer,214)PJ_phi1; params(4) = buffer
        write(buffer,215)PJ_phi2; params(5) = buffer
          ! Fill remaining parameters with blanks
        write(buffer,216)
        params(6) = buffer
        params(7) = buffer
        params(8) = buffer
211     format('proj=aea')
212     format('lon_0=',f10.3)
213     format('lat_0=',f10.3)
214     format('lat_1=',f10.3)
215     format('lat_2=',f10.3)
216     format(' ')

      case(3)
        ! UTM
        write(6,*)"WARNING: UTM not yet verified"
        read(linebuffer,*)PJ_ilatlonflag,PJ_iprojflag,izone,inorth
        if(izone.le.0.or.izone.gt.60)then
          write(6,*)"PJ ERROR:  izone should be in in range 1 - 60"
          write(6,*)"   izone = ",izone
          stop 1
        endif
        if(inorth.ne.0.and.inorth.ne.1)then
          write(6,*)"PJ ERROR:  inorth should be either 0 or 1"
          write(6,*)"   inorth = ",inorth
          stop 1
        endif
        ! Preparing parameter list for projection call
        write(buffer,221)
        params(1) = buffer
        write(buffer,222)izone
        params(2) = buffer
        if(inorth.eq.1)then
          write(buffer,224)
        else
          write(buffer,223)"+south"
        endif
        params(3) = buffer
          ! Fill remaining parameters with blanks
        write(buffer,224)
        params(4) = buffer
        params(5) = buffer
        params(6) = buffer
        params(7) = buffer
        params(8) = buffer

221     format('proj=utm')
222     format('zone=',i5)
223     format(a6)
224     format(' ')

      case(4)
        ! Lambert conformal conic (NARR, NAM218, NAM221)
        read(linebuffer,*)PJ_ilatlonflag,PJ_iprojflag,PJ_lam0, &
                          PJ_phi0,PJ_phi1,PJ_phi2,PJ_radius_earth
        if(abs(PJ_lam0).gt.360.0)then
          write(6,*)"PJ ERROR:  PJ_lam0 should be in in range -360 - 360"
          write(6,*)"   PJ_lam0 = ",PJ_lam0
          stop 1
        endif
        if(abs(PJ_phi0).gt.90.0.or.abs(PJ_phi1).gt.90.0.or.abs(PJ_phi2).gt.90.0)then
          write(6,*) &
            "PJ ERROR:  PJ_phi0,1,2 should each be in in range -90 - 90"
          write(6,*)"   PJ_phi0,1,2 = ",PJ_phi0,PJ_phi1,PJ_phi2
          stop 1
        endif
        if(PJ_radius_earth.le.5000.0.or.PJ_radius_earth.ge.7000.0)then
          write(6,*)"PJ ERROR:  PJ_radius_earth should around 6300 km, not ",PJ_radius_earth
          stop 1
        endif

        ! Preparing parameter list for projection call
        write(buffer,231);              params(1) = buffer
        write(buffer,232)PJ_lam0;       params(2) = buffer
        write(buffer,233)PJ_phi0;          params(3) = buffer
        write(buffer,234)PJ_phi1;          params(4) = buffer
        write(buffer,235)PJ_phi2;          params(5) = buffer
        write(buffer,236)PJ_radius_earth;  params(6) = buffer
          ! Fill remaining parameters with blanks
        write(buffer,237)
        params(7) = buffer
        params(8) = buffer
231     format('proj=lcc')
232     format('lon_0=',f10.3)
233     format('lat_0=',f10.3)
234     format('lat_1=',f10.3)
235     format('lat_2=',f10.3)
236     format('R=',f10.3)
237     format(' ')

      case(5)
        ! Mercator (NAM196)
        read(linebuffer,*)PJ_ilatlonflag,PJ_iprojflag,PJ_lam0,PJ_phi0,PJ_radius_earth
        if(abs(PJ_lam0).gt.360.0)then
          write(6,*)"PJ ERROR:  PJ_lam0 should be in in range -360 - 360"
          write(6,*)"   PJ_lam0 = ",PJ_lam0
          stop 1
        endif
        if(abs(PJ_phi0).gt.90.0)then
          write(6,*) &
            "PJ ERROR:  PJ_phi0 should each be in in range -90 - 90"
          write(6,*)"   PJ_phi0 = ",PJ_phi0
          stop 1
        endif
        if(PJ_radius_earth.le.5000.0.or.PJ_radius_earth.ge.7000.0)then
          write(6,*)"PJ ERROR:  PJ_radius_earth should around 6300 km, not ",PJ_radius_earth
          stop 1
        endif

        ! Preparing parameter list for projection call
        write(buffer,241);                 params(1) = buffer
        write(buffer,242)PJ_lam0;          params(2) = buffer
        write(buffer,243)PJ_phi0;          params(3) = buffer
        write(buffer,246)PJ_radius_earth;  params(4) = buffer
          ! Fill remaining parameters with blanks
        write(buffer,247)
        params(5) = buffer
        params(6) = buffer
        params(7) = buffer
        params(8) = buffer
241     format('proj=merc')
242     format('lon_0=',f10.3)
243     format('lat_ts=',f10.3)
246     format('R=',f10.3)
247     format(' ')

      end select

      return

      end subroutine PJ_Set_Proj_Params

!##############################################################################
!
!     PJ_proj_for
!
!     subroutine that calculates the forward projection from lon/lat to x,y
!
!##############################################################################

      subroutine PJ_proj_for(lon_in,lat_in, &
                       iprojflag,lon_0,lat_0,lat_1,lat_2,k_0,earth_R, &
                       x_out,y_out)

      implicit none

      real(kind=8), parameter :: PI        = 3.141592653589793_8
      real(kind=8), parameter :: DEG2RAD   = 1.7453292519943295e-2_8
      real(kind=8), parameter :: RAD2DEG   = 5.72957795130823e1_8

      real(kind=8),intent(in)  :: lon_in    ! input lon to convert
      real(kind=8),intent(in)  :: lat_in    ! input lat to convert
      integer     ,intent(in)  :: iprojflag ! projection ID
      real(kind=8),intent(in)  :: lon_0     ! central meridian
      real(kind=8),intent(in)  :: lat_0     ! latitude parameters used
      real(kind=8),intent(in)  :: lat_1     !   by the projection, not
      real(kind=8),intent(in)  :: lat_2     !   all are needed
      real(kind=8),intent(in)  :: k_0       ! scaling factor
      real(kind=8),intent(in)  :: earth_R   ! radius of earth (km)
      real(kind=8),intent(out) :: x_out     ! output coordinates
      real(kind=8),intent(out) :: y_out     ! 

      real(kind=8)  :: lon_in_wrap ! Locally-used lon values that are wrapped
      real(kind=8)  ::  lon_0_wrap !  to the range 0-360

      real(kind=8) :: k_eq
      real(kind=8) :: F
      real(kind=8) :: tmp_arg
      real(kind=8) :: n_exp
      real(kind=8) :: rho,rho_0,theta
      real(kind=8) :: zproj

      ! First, convert all longitudes to the range 0<lon<=360
      if (lon_in.le.  0.0_8) lon_in_wrap = lon_in + 360.0_8
      if (lon_in.gt.360.0_8) lon_in_wrap = lon_in - 360.0_8
      if (lon_0 .le.  0.0_8)  lon_0_wrap = lon_0  + 360.0_8
      if (lon_0 .gt.360.0_8)  lon_0_wrap = lon_0  - 360.0_8


      if (iprojflag.eq.1) then
        ! Polar stereographic
        !    http://mathworld.wolfram.com/StereographicProjection.html
        if (lat_0.lt.90.0_8) then  !	NOTE: this projection only works if lat_0=90.
          write(6,3)
3         format('Sorry, lproj only works for polar stereographic',/, &
                         'projection when lat_0=90.',/, &
                         'Program stopped.')
          stop 1
        end if
          ! Using Eq. 21-5 and 21.6 of Snyder, 1987
        zproj   = k_0*2.0_8*earth_R
        theta   = (lon_in_wrap-lon_0_wrap)*DEG2RAD
        if (theta.le.-PI) theta = theta + 2.0_8*PI
        if (theta.gt. PI) theta = theta - 2.0_8*PI
        x_out =  zproj*tan(0.25_8*PI-0.5_8*lat_in*DEG2RAD)*sin(theta)
        y_out = -zproj*tan(0.25_8*PI-0.5_8*lat_in*DEG2RAD)*cos(theta)

      elseif (iprojflag.eq.2) then
        ! Albers Equal Area
        write(6,*)"WARNING: Albers not yet verified"
        stop 1
      elseif(iprojflag.eq.3)then
        ! UTM
        write(6,*)"WARNING: UTM not yet verified"
        stop 1
      elseif(iprojflag.eq.4)then
        ! Lambert conformal conic (NARR, NAM218, NAM221)

         !These formulas were taken from the wikipedia article on lcc
         !also given in the Wolfrom page
         !http://mathworld.wolfram.com/LambertConformalConicProjection.html
        if (abs(lat_1-lat_2).gt.1.0e-05_8) then
          n_exp  = log(cos(DEG2RAD*lat_1)/cos(DEG2RAD*lat_2)) / &
                      log(tan(PI/4.0_8+DEG2RAD*lat_2/2.0_8) / &
                      tan(PI/4.0_8+DEG2RAD*lat_1/2.0_8))
        else
          ! n_exp is singular when lat_1 = lat_2
          ! Applying l'Hopital's rule
          n_exp = 2.0_8*tan(DEG2RAD*lat_1) * &
                           sin(PI/4.0_8+DEG2RAD*lat_1/2.0_8) * &
                           cos(PI/4.0_8+DEG2RAD*lat_1/2.0_8)
          !n_exp = 0.42261826174069944 !for 25 degrees
          !n_exp = 0.76604444311897824 !for 50 degrees
        end if
        F     = cos(DEG2RAD*lat_1)*(tan(PI/4.0_8+DEG2RAD*lat_1/2.0_8))**n_exp/n_exp
        rho   = F/(tan(PI/4.0_8+DEG2RAD*lat_in/2.0_8))**n_exp
        rho_0 = F/(tan(PI/4.0_8+DEG2RAD*lat_0/2.0_8))**n_exp
        x_out = earth_R*rho*sin(n_exp*(DEG2RAD*(lon_in_wrap-lon_0_wrap)))
        y_out = earth_R*(rho_0-rho*cos(n_exp*DEG2RAD*(lon_in_wrap-lon_0_wrap)))
      elseif(iprojflag.eq.5)then
        ! Mercator
        !  http://mathworld.wolfram.com/MercatorProjection.html
        !   These are equations 7-1 and 7-2 of Snyder
        k_eq = cos(lat_0*DEG2RAD)
        x_out = earth_R*(lon_in_wrap-lon_0_wrap)*DEG2RAD*k_eq
        tmp_arg = (45.0_8 + 0.5_8*lat_in)*DEG2RAD
        y_out = earth_R*(log(tan(tmp_arg)))*k_eq
      else
        write(6,*)&
        'sorry, iprojflag is not 1,2,3,4, or 5.  I dont know what to do'
      end if

         return
         end subroutine PJ_proj_for

!##############################################################################
!
!     PJ_proj_inv
!
!     subroutine that calculates the inverse projection from x,y to lon/lat
!
!##############################################################################

      subroutine PJ_proj_inv(x_in,y_in, &
                           iprojflag,lon_0,lat_0,lat_1,lat_2,k_0,earth_R, &
                           lon_out,lat_out)

      implicit none

      real(kind=8), parameter :: PI        = 3.141592653589793_8
      real(kind=8), parameter :: DEG2RAD   = 1.7453292519943295e-2_8
      real(kind=8), parameter :: RAD2DEG   = 5.72957795130823e1_8

      real(kind=8),intent(in)  :: x_in        ! input coordinates
      real(kind=8),intent(in)  :: y_in        ! 
      integer     ,intent(in)  :: iprojflag   ! projection ID
      real(kind=8),intent(in)  :: lon_0       ! central meridian
      real(kind=8),intent(in)  :: lat_0       ! latitude parameters used
      real(kind=8),intent(in)  :: lat_1       !   by the projection, not
      real(kind=8),intent(in)  :: lat_2       !   all are needed
      real(kind=8),intent(in)  :: k_0         ! scaling factor
      real(kind=8),intent(in)  :: earth_R     ! radius of earth (km)
      real(kind=8),intent(out) :: lon_out     ! output longitude
      real(kind=8),intent(out) :: lat_out     ! output latitude

      real(kind=8)  :: lon_in_wrap ! Locally-used lon values that are wrapped
      real(kind=8)  ::  lon_0_wrap !  to the range 0-360

      real(kind=8) :: k_eq
      real(kind=8) :: F
      real(kind=8) :: tmp_arg
      real(kind=8) :: n_exp,rho,rho_0,theta
      real(kind=8) :: c_fac

      ! First, convert input longitude to the range 0<lon<=360
      if (lon_0 .le.  0.0_8)  lon_0_wrap = lon_0  + 360.0_8
      if (lon_0 .gt.360.0_8)  lon_0_wrap = lon_0  - 360.0_8

      if (iprojflag.eq.1) then
        ! Polar stereographic
        !    http://mathworld.wolfram.com/StereographicProjection.html
        if (lat_0.lt.90.0_8) then  !	NOTE: this projection only works if lat_0=90.
          write(6,3)
3         format('Sorry, lproj only works for polar stereographic',/, &
                         'projection when lat_0=90.',/, &
                         'Program stopped.')
          stop 1
        end if

        theta   = atan2(x_in,-y_in)
          ! Eq 20-16 of Snyder, 1987
        lon_out = theta*RAD2DEG + lon_0_wrap
          ! Eq 20-18 of Snyder, 1987 (p159)
        rho   = sqrt(x_in*x_in+y_in*y_in)
          ! Eq. 21-15 of Snyder, 1987 (p159)
        c_fac = 2.0_8*atan2(rho,k_0*2.0_8*earth_R)
          ! Eq. 20-14 of Snyder, 1987 (p158)
        !lat_out = asin(     cos(c_fac)*sin(lat_0*DEG2RAD) + &
        !               y_in*sin(c_fac)*cos(lat_0*DEG2RAD)/rho)
        lat_out = asin(     cos(c_fac)) * RAD2DEG

        if (lon_out.lt.  0.0_8) lon_out=lon_out+360.0_8
        if (lon_out.gt.360.0_8) lon_out=lon_out-360.0_8

      else if (iprojflag.eq.2) then
        ! Albers Equal Area
        write(6,*)"WARNING: Albers not yet verified"
        stop 1
      elseif(iprojflag.eq.3)then
        ! UTM
        write(6,*)"WARNING: UTM not yet verified"
        stop 1
      elseif(iprojflag.eq.4)then
        ! Lambert conformal conic (NARR, NAM218, NAM221)
        !These formulas were taken from the wikipedia article on lcc
        !also given in the Wolfrom page
        !http://mathworld.wolfram.com/LambertConformalConicProjection.html
        if (abs(lat_1-lat_2).gt.1.0e-05_8) then
          n_exp  = log(cos(DEG2RAD*lat_1)/cos(DEG2RAD*lat_2)) / &
                     log(tan(PI/4.0_8+DEG2RAD*lat_2/2.0_8) / &
                     tan(PI/4.0_8+DEG2RAD*lat_1/2.0_8))
        else
          ! n_exp is singular when lat_1 = lat_2
          ! Applying l'Hopital's rule
          n_exp = 2.0_8*tan(DEG2RAD*lat_1) * &
                           sin(PI/4.0_8+DEG2RAD*lat_1/2.0_8) * &
                           cos(PI/4.0_8+DEG2RAD*lat_1/2.0_8)
          !n_exp = 0.42261826174069944 !for 25 degrees
          !n_exp = 0.76604444311897824 !for 50 degrees
        endif
        F     = cos(DEG2RAD*lat_1)*(tan(PI/4.0_8+DEG2RAD*lat_1/2.0_8))**n_exp/n_exp
        rho_0 = F/(tan(PI/4.0_8+DEG2RAD*lat_0/2.0_8))**n_exp
        theta = atan(x_in/(earth_R*rho_0-y_in))
        rho   = sign(sqrt((x_in/earth_R)**2.0_8+(rho_0-(y_in/earth_R))**2.0_8),n_exp)
        lat_out  = RAD2DEG*2.0_8*atan((F/rho)**(1.0_8/n_exp))-90.0_8
        lon_out  = lon_0_wrap+RAD2DEG*theta/n_exp
      elseif(iprojflag.eq.5)then
        ! Mercator
        !  http://mathworld.wolfram.com/MercatorProjection.html
        k_eq = cos(lat_0*DEG2RAD)
        lon_out = (lon_0_wrap*DEG2RAD + x_in/(earth_R*k_eq))/DEG2RAD
        tmp_arg = exp(y_in/(earth_R*k_eq))
        lat_out = 2.0_8*atan(tmp_arg)/DEG2RAD - 90.0_8
      else
        write(6,*) &
        'sorry, iprojflag is not 1,2,3,4, or 5.  I dont know what to do'
      end if

      ! Lastly, convert output longitude to the range 0<lon<=360
      if (lon_out.le.  0.0_8) lon_out = lon_out + 360.0_8
      if (lon_out.gt.360.0_8) lon_out = lon_out - 360.0_8

      return

      end subroutine PJ_proj_inv

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      END MODULE projection
