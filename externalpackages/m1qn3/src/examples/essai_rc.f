c-----------------------------------------------------------------------
c
c     Example of program : minimization of x^2+cy^4
c     where c>0 is a parameter
c
c-----------------------------------------------------------------------
c
      implicit none
      external simul_rc,euclid,ctonbe,ctcabe
      character*3 normtype
      integer i,n,imp,io,imode(3),omode,niter,nsim,iz(5),ndz,izs(1),
     &    indic,reverse
      real rzs(1)
      double precision c,x(2),f,g(2),dx,df1,epsrel,dz(20000),dzs(1)
c
c --- initialization
c
      n=2
      ndz=20000
c     print *,'c=?'
c     read *,c
      c=10.d+0
      dzs(1)=c
      do i=1,n
          x(i)=5.d+0
      enddo
c
c --- first call the simulator
c
      indic=4
      call simul (indic,n,x,f,g,izs,rzs,dzs)
c
c --- call the optimization code
c     normtype can be 'sup' for sup-norm, 'two' for 2-norm, 'dfn' for the norm defined by prosca
c
      dx=1.e-10
      df1=f
      epsrel=1.e-5
      niter=200
      nsim=200
      normtype = 'dfn'
      io=6
      imp=5
      imode(1)=0
      imode(2)=0
      imode(3)=0
      reverse=1
  100 continue
          call m1qn3 (simul_rc,euclid,ctonbe,ctcabe,n,x,f,g,dx,df1,
     &                epsrel,normtype,imp,io,imode,omode,niter,nsim,iz,
     &                dz,ndz,reverse,indic,izs,rzs,dzs)
          if (reverse.lt.0) goto 101
          call simul (indic,n,x,f,g,izs,rzs,dzs)
          goto 100
  101 continue
      stop
      end
c
c-----------------------------------------------------------------------
c
c    Simulator
c
c-----------------------------------------------------------------------
c
      subroutine simul(indic,n,x,f,g,izs,rzs,dzs)
      implicit double precision (a-h,o-z)
      dimension x(n),g(n)
      dimension izs(*),dzs(*)
      real rzs(*)
c
      if (indic.eq.1) then
          write (6,'(/a/)') "Free call to simul"
          return
      endif
c
      c=dzs(1)
      f=x(1)*x(1)+c*x(2)*x(2)*x(2)*x(2)
      g(1)=2.*x(1)
      g(2)=4.*c*x(2)*x(2)*x(2)
      return
      end
