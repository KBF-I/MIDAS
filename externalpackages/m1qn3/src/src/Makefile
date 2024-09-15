LIB_EXT=a
FC=gfortran -arch x86_64
install: libm1qn3.$(LIB_EXT)
	cp libm1qn3.$(LIB_EXT) /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/m1qn3/install
OBJECTS= m1qn3.o
libm1qn3.$(LIB_EXT): $(OBJECTS)
	ar -r libm1qn3.$(LIB_EXT) $(OBJECTS) 
	ranlib libm1qn3.$(LIB_EXT) 
%.o: %.f
	$(FC) $(FFLAGS) -fPIC -c $< -o $@
clean: 
	rm -rf *.o *.$(LIB_EXT)
