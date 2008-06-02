# limits
# 20070904: does not work under cygwin
#TEST_LIMIT_TIME						:= 5

# this file
TEST_MKF							:= $(TEST_SRC_PREFIX)files.mk

# main + sources + dpds, for .chs
TEST_REGRESS_ALL_SRC				:= $(wildcard $(TEST_REGRESS_SRC_PREFIX)*.eh)
TEST_REGRESS_EXP_DRV				:= $(wildcard $(TEST_REGRESS_SRC_PREFIX)*.eh.exp*)

# distribution
TEST_DIST_FILES						:= $(TEST_REGRESS_ALL_SRC) $(TEST_REGRESS_EXP_DRV) $(TEST_MKF)

# rules
test-lists:
	@cd $(TEST_REGRESS_SRC_PREFIX) ; \
	shopt -s nullglob ; \
	for v in $(TEST_VARIANTS) ; \
	do \
	  if test $${v} = $(UHC_EXEC_NAME) ; \
	  then \
	    v=$(EHC_UHC_INSTALL_VARIANT) ; \
	  fi ; \
	  ehs= ; \
	  vv=`echo $${v} | sed -e 's/_[0-9]//'` ; \
	  if test $${vv} -lt $(EHC_PREL_VARIANT) ; \
	  then \
	    startvariant=1 ; \
	  else \
	    startvariant=$(EHC_PREL_VARIANT) ; \
	  fi ; \
	  for ((i = $${startvariant} ; i <= $${vv} ; i++)) ; do ehs="$${ehs} `echo $${i}/*.{eh,hs}`" ; done ; \
	  echo "$${ehs}" > $${v}.lst ; \
	done

# run tests for generation of expected results or check agains those results
# NOTE 20070904: Previously: parameterizable mini preludes with non-portable 'sed -E': tprelbase=`sed -n -E 's/^-- %% *inline test *\(([a-z0-9]+)\) --$$/\1/p' < $$t`
#                Now: fixed to 'prefix1' labeled files
#                Because: some platforms don't know about the -E option (richer regex) to sed
test-expect test-regress: test-lists
	@how=`echo $@ | sed -e 's/.*expect.*/exp/' -e 's/.*regress.*/reg/'` ; \
	nerrors=0; \
	nwarnings=0; \
	cd $(TEST_REGRESS_SRC_PREFIX) ; \
	for v in $(TEST_VARIANTS) ; \
	do \
	  if test $${v} = $(EHC_UHC_INSTALL_VARIANT) -o $${v} = $(UHC_EXEC_NAME) ; \
	  then \
	    ehc=$(UHC_INSTALL_EXEC) ; \
	    gri="echo gri not implemented" ; \
	    optPreludePath="" ; \
	    v=$(EHC_UHC_INSTALL_VARIANT) ; \
	  else \
	    ehc=$(TEST_BIN_PREFIX)$${v}/$(EHC_EXEC_NAME)$(EXEC_SUFFIX) ; \
	    gri=$(TEST_BIN_PREFIX)$${v}/$(GRINI_EXEC_NAME)$(EXEC_SUFFIX) ; \
	    optPreludePath="--search-path=$(TEST_TOP_PREFIX)$(EHCLIB_EHCLIB_EHCBASE_PREFIX)" ; \
	  fi ; \
	  echo "== version $${v} ==" ; \
	  if test -x $${ehc} ; \
	  then \
	    if test "x$${TEST_FILES}" = "x" ; \
	    then \
	      TEST_FILES=`cat $${v}.lst` ; \
	    fi ; \
	    for t in $${TEST_FILES} ; \
	    do \
	      cleanup="rm -f" ; \
	      tdir=`dirname $$t` ; \
	      tb="$${tdir}/"`basename $$t .eh` ; \
	      tsuff=".eh" ; \
	      if test $${tb} = $${t} ; \
	      then \
	        tb="$${tdir}/"`basename $$t .hs` ; \
	        tsuff=".hs" ; \
	      fi ; \
	      if test -r $$t -a -x $${ehc} ; \
	      then \
	        te=$${t}.exp$${v} ; tr=$${t}.reg$${v} ; th=$${t}.$${how}$${v} ; \
	        if test $${v} -lt $(EHC_PREL_VARIANT) ; \
	        then \
	          tprelbase=`sed -n -e 's/^-- %% *inline test *([a-z0-9]*) --$$/prefix1/p' < $$t` ; \
	          tprel="$${v}-$${tprelbase}$${tsuff}" ; \
	          if test -r $${tprel} ; \
	          then \
	            tb2="$${tb}+p" ; \
	            t2="$${tb2}$${tsuff}" ; \
	            cat $${tprel} $${t} > $${t2} ; \
	            cleanup="$${cleanup} $${t2}" ; \
	          else \
	            tb2="$${tb}" ; \
	            t2="$${t}" ; \
	          fi ; \
	          tc=$${tb2}.core ; tg=$${tb2}.grin2 ; texe=$${tb2}$(EXEC_SUFFIX) ; \
	          cleanup="$${cleanup} $${texe}" ; \
	          rm -f $${tc} $${tg} ; \
	          $${ehc} $${TEST_OPTIONS} -v $${t2} > $${th} 2>&1 ; \
	          if test -r $${tc} ; \
	          then \
	            echo "== core ==" >> $${th} ; \
	            cat $${tc} >> $${th} ; \
	            rm -f $${tg} ; \
	            if test -x $${gri} ; \
	            then \
	              $${ehc} $${TEST_OPTIONS} --code=grin $${t2} > /dev/null ; \
	              echo "== grin interpreter execution ==" >> $${th} ; \
	              $${gri} $${tg} >> $${th} 2>&1 ; \
	            fi ; \
	            rm -f $${texe} ; \
	            echo "== grin bytecode (GBM) compilation ==" >> $${th} ; \
	            $${ehc} $${TEST_OPTIONS} --pretty=- --code=bexe $${t2} >> $${th} 2>&1 ; \
	            if test $$? = 0 -a -x $${texe} ; \
	            then \
	              echo "== grin bytecode (GBM) execution ==" >> $${th} ; \
	              $${texe} >> $${th} 2>&1 ; \
	            fi ; \
	            rm -f $${texe} ; \
	            echo "== grin full program analysis compilation ==" >> $${th} ; \
	            $${ehc} $${TEST_OPTIONS} --pretty=- --code=exe $${t2} >> $${th} 2>&1 ; \
	            if test $$? = 0 -a -x $${texe} ; \
	            then \
	              echo "== grin full program analysis execution ==" >> $${th} ; \
	              $${texe} >> $${th} 2>&1 ; \
	            fi \
	          fi \
	        else \
	          texe=$${tb}$(EXEC_SUFFIX) ; \
	          cleanup="$${cleanup} $${texe}" ; \
	          $${ehc} $${optPreludePath} $${t} > $${th} 2>&1 ; \
	          if test $$? = 0 -a -x $${texe} ; \
	          then \
	            echo "== grin bytecode (GBM) execution ==" >> $${th} ; \
	            $${texe} >> $${th} 2>&1 ; \
	          fi \
	        fi ; \
	        if test $${tr} = $${th} -a -r $${te} ; \
	        then \
	          echo "-- $${te} -- $${th} --" | $(INDENT2) ; \
	          if ! cmp $${te} $${th} > /dev/null ; \
	          then \
	            diff $${te} $${th} | $(INDENT4) ; \
	            nerrors=$$[ $$nerrors + 1 ]; \
	          fi \
	        elif test ! -r $${te} ; \
	        then \
	          echo "-- no $${te} to compare to" | $(INDENT2) ; \
	          nwarnings=$$[ $$nwarnings + 1 ]; \
	        fi \
	      fi ; \
	      $${cleanup} ; \
	    done ; \
	    TEST_FILES="" ; \
	  else \
	    echo "-- no $${ehc} to compile with" | $(INDENT2) ; \
	    exit 1; \
	  fi \
	done; \
	echo "== completed with $$nerrors errors and $$nwarnings warnings =="; \
	exit $$nerrors;