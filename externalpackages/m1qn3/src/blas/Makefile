LIB_EXT=a
FC=gfortran -arch x86_64
install: libddot.$(LIB_EXT)
	cp libddot.$(LIB_EXT) /Users/kasra/MyDocuments-Local/trunk-jpl/externalpackages/m1qn3/install
OBJECTS= ddot.o
libddot.$(LIB_EXT): $(OBJECTS)
	ar -r libddot.$(LIB_EXT) $(OBJECTS) 
	ranlib libddot.$(LIB_EXT) 
%.o: %.f
	$(FC) $(FFLAGS) -fPIC -c $< -o $@
clean: 
	rm -rf *.o *.$(LIB_EXT)
