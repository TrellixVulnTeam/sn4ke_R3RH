#! /bin/bash
TEST=${1?Error: no test given}
RUN_INI_LIFT=1
RUN_COVERAGE=1
RUN_MUT_PREP=1
RUN_MUTATION=1

CURR_DIR=$( cd $( dirname $0 ) && pwd )

# Set up paths to where compiled tools are here
export SRCIROR_COVINSTRUMENTATION_LIB=$CURR_DIR/../IRMutation/InstrumentationLib/SRCIRORCoverageLib.o
export SRCIROR_LLVMMutate_LIB=$HOME/llvm/llvm-10.0.1.src/build/lib/LLVMMutateRevng.so # pk: directory of the new llvm version
export SRCIROR_LLVM_BIN=$HOME/llvm/llvm-10.0.1.src/build/bin/ # pk: directory of the new llvm version
export REVDIR=/home/pc-5/fi-bin/newInstall/orchestra/root/bin/ # pk: directory of revng binaries

#export SRCIROR_LLVMMutate_LIB=$HOME/llvm/llvm-10.0.1.src/build/lib/LLVMMutate.so # pk: directory of the new llvm version



# TODO: remove for revng later
# generate .ll
#$REVDIR/clang $TEST.c -S -emit-llvm -o $TEST.ll

# to make sure the original binary is here
cp ../Examples/$TEST . 


####################################################################################################################
# initial lift to llvm-ir
if [[ $RUN_INI_LIFT == 1 ]];
then
  echo "REVNG: Lifting the Original Binary"
  $REVDIR/revng-lift -g ll --debug-log jtcount ${TEST} ${TEST}_lifted.ll
#  $REVDIR/revng --verbose translate --ll test_lifted_mutate:test_lifted_mutate.ll+test_lifted.ll:binaryOp:161:60:15.ll ${TEST}
fi


####################################################################################################################
# generate coverage
rm -f /tmp/srciror_llvm_coverage # remove any existing coverage
rm -rf ~/.srciror # remove logs and results from previous runs
if [[ $RUN_COVERAGE == 1 ]];
then
  echo "SRCIROR: Instrumenting for Coverage"
  python $CURR_DIR/../PythonWrappers_revng/irCoverageClang ${TEST}_lifted.ll -o ${TEST}
  # run the executable to collect coverage
#tmp  ./${TEST}_coverage
#tmp  echo "the collected coverage is under /tmp/srciror_llvm_coverage" # pk
fi

# TODO: remove for revng later
# generate .ll
#$REVDIR/clang $TEST.c -S -emit-llvm -o $TEST.ll

####################################################################################################################
# generate mutation opportunities
if [[ $RUN_MUT_PREP == 1 ]]
then
  echo "SRCIROR: generating mutation opportunities"
  python $CURR_DIR/../PythonWrappers_revng/irMutationClang ${TEST}_lifted.ll -o $TEST
  echo "The generated mutants are under ~/.srciror/bc-mutants/681837891"
fi

####################################################################################################################
# TODO: intersect with coverage
# generate one mutant executable
if [[ $RUN_MUTATION == 1 ]]
then
  echo "SRCIROR: running requested mutations"
  file_name=`cat ~/.srciror/ir-coverage/hash-map | grep "${TEST}_lifted.ll" | cut -f1 -d:`
  echo "file name is: $file_name and mutations requested are in file: ~/.srciror/mutation_requests.txt" 
  rm -f ~/.srciror/mutation_requests.txt
  rm -rf ./mutation_results/
  mkdir ./mutation_results/
  mkdir ./mutation_results/ll/
  mkdir ./mutation_results/bin/
  python $CURR_DIR/generateMutationRequests.py --testName ${TEST}_lifted.ll 
  python $CURR_DIR/../PythonWrappers_revng/irVanillaClang ${TEST}_lifted.ll -o $TEST
fi


####################################################################################################################
# cleanup current directory 
#rm ${TEST}_lifted.ll.need.csv
#rm ${TEST}_lifted.ll.li.csv
#rm ${TEST}_lifted.ll.coverage.csv
