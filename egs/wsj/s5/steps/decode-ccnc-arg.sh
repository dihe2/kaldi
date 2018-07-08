#/bin/bash
#
# decode-ccnc.sh -- implements He Di's decoder using 
# coarse cluster -> narrow cluster activation
#
# This implements an approximation to the two pass decoding using standard kaldi tools. It fist generates a list of log-likelihood scores using 

#  
# Author: Lim Boon Pang, He Di
# 
# This implements a plug-in/update into the kaldi wsj_s5 skel folder,
# to 

# options to configure run
cmd=run.pl
parallel_opts=
nj=8
inv_acwt=4
max_active=7000
beam=13.0
lattice_beam=6.0
acwt=0.083333
skip_scoring=false
skip_first_pass=false
filter_likes=true
use_landmark=true
drop_mod=6
fill_mod=5
perc=500
repeat_stop=2
run_reweight=false
ampl_fact=1.75

# location of custom/helper scripts/binaries
BINDIR=bin/2pass
FILT_ACT=$BINDIR/pick_top_activations.pl
#FILT_ACT=$BINDIR/like-to-active-states.pl
#FILT_LL=$BINDIR/filter-likelihoods.pl
#FILT_LL=$BINDIR/decimate-likelihoods.pl ###
#FILT_LL=$BINDIR/upsample-likelihoods.pl
#FILT_LL=$BINDIR/decimate-likelihoods-phoneBound.pl
#FILT_LL=$BINDIR/reweight-likelihoods-phoneBound.pl
#FILT_LL=$BINDIR/reweight-likelihoods-phoneMark.pl
#FILT_LL=$BINDIR/decimate-likelihoods-phoneMark.pl ###



EXPAND_BC2NC=$BINDIR/expand_bc_active_to_nc_active_states.pl
DIFFUSE_FRAMES=$BINDIR/filt-active-states-time-diffuse.pl

DECIMATION_RATIO=4
BOUNDARY_DISTANCE=1
REWEIGHT_FACTOR=1.5

# decoding algorithm parameters
ACLUSTERMAP=tmp/activationmap.ccnc.txt
ACTIVE_CLUSTERS=256
DTIME=0

verbose=false

# parse command line option

[ -f ./path.sh ] && . ./path.sh 
. parse_options.sh || exit 1;

if [ $# -lt 3 ]; then
   echo decode graphdir data dir 
   echo e.g. decode-ccnc.sh exp/tri2b.G
   echo options ACTIVE_CLUSTERS - number of active 1st pass tokens
   exit -1
fi

if $use_landmark ; then
   if $run_reweight ; then
       FILT_LL=$BINDIR/reweight-likelihoods-phoneMark.pl
   else
       FILT_LL=$BINDIR/decimate-likelihoods-phoneMark-arg.pl
   fi
else
   echo not using landmarks
   FILT_LL=$BINDIR/decimate-likelihoods-arg.pl
fi


graphdir=$1
data=$2
dir=$3

echo running decode $graphdir $data $dir with ac=$ACTIVE_CLUSTERS

[[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;

activation_mdl=$4 

echo "$0 $@"
tag=ac_$ACTIVE_CLUSTERS.lc_$LEFT_CONTEXT.rc_$RIGHT_CONTEXT
echo Running with $ACTIVE_CLUSTERS active clusters.

# figure out auxilary paths
model=`dirname $dir`
if [ 'x'$activation_mdl == 'x' ]; then
    activation_mdl=$model/firstpass.mdl
fi
echo using activation model $activation_mdl

if ! $skip_first_pass; then
	[ ! -e $activation_mdl ] && echo "first pass model $activation_mdl not found." && exit 1
fi

sdata=$data/split$nj
# original features for tri2b series
feats="ark:apply-cmvn  --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats --left-context=3 --right-context=3 ark:- ark:- | transform-feats $model/final.mat ark:- ark:- |"

# features for tri2a series
#feats="ark:apply-cmvn  --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas ark:- ark:- |"

# figure out active states from first pass
# the states and clusters are all numbered starting from 1

TRIMDL=$model/final.mdl
TRIHCLG=$graphdir/HCLG.fst

[ $verbose ] && echo 'activation model: ' $activation_mdl
[ $verbose ] && echo '2nd-pass: ' $TRIMDL

act_bc_states="$dir/activations/active_bc_states.JOB.txt"
act_nc_states="$dir/activations/active_nc_states.JOB.gz"
mkdir -p $dir/activations/
mkdir -p $dir/log
if ! $skip_first_pass; then
  [ $verbose ] && echo 'Performing first pass decodings: ' `date`
  $cmd $parallel_opts JOB=1:$nj $dir/log/decode.1.JOB.log \
    gmm-compute-likes $activation_mdl "$feats" ark,t:- \|\
    perl $FILT_ACT $ACTIVE_CLUSTERS \|\
    tee  $act_bc_states  \|\
    perl $EXPAND_BC2NC $ACLUSTERMAP \|\
    perl $DIFFUSE_FRAMES $DTIME \| \
       gzip -c \> $act_nc_states || exit 1
else
  [ $verbose ] && echo 'Skipping first pass decodings: ' `date`
fi

# Do second pass decoding to lattices
[ $verbose ] && echo 'Performing second pass decodings: ' `date`

if $filter_likes ; then
    echo using likelihood filtering.
    #likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --save-activations $act_nc_states.info 'gunzip -c $act_nc_states |' |"
	#likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:-"
#	likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --decimation-ratio $DECIMATION_RATIO |"
	#likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --upsample-ratio $DECIMATION_RATIO |"
	#likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --decimation-ratio $DECIMATION_RATIO --avoid-boundary $BOUNDARY_DISTANCE --save-compression-ratio $dir/compr_ratio.JOB.txt $dir/phone_info.JOB.txt |"
	#likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --reweight-factor $REWEIGHT_FACTOR --avoid-boundary $BOUNDARY_DISTANCE --save-reweight-ratio $dir/reweight_ratio.JOB.txt $dir/phone_info.JOB.txt |"
	#likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --reweight-factor $REWEIGHT_FACTOR --save-reweight-ratio $dir/reweight_marks_ratio.JOB.txt $dir/phone_mark_info.JOB.txt |"
    if $use_landmark ; then
	if $run_reweight ; then
		likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --reweight-factor $REWEIGHT_FACTOR --save-reweight-ratio $dir/reweight_marks_ratio.JOB.txt $dir/phone_mark_info.JOB.txt |"
	else
		echo $DECIMATION_RATIO
		likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --decimation-ratio $DECIMATION_RATIO --save-compression-ratio $dir/compr_mark_ratio.JOB.txt --drop-mod $drop_mod --fill-mod $fill_mod --perc $perc --repeat-stop $repeat_stop --ampl-fact $ampl_fact $dir/phone_mark_info.JOB.txt |"
	fi
    else
	echo 'ignore landmarks'
	echo $DECIMATION_RATIO
	echo $drop_mod
	likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- | perl $FILT_LL --decimation-ratio $DECIMATION_RATIO --drop-mod $drop_mod |"
    fi
else
    echo disabling likelihood filtering.
    likelihoods="ark:gmm-compute-likes $TRIMDL '$feats' ark,t:- |"
fi

#$cmd $parallel_opts JOB=1:$nj $dir/log/decode.2.JOB.log \
#gmm-compute-likes $TRIMDL '$feats' ark: ark,t:- | cat $dir/log/error_log.log #| perl $FILT_LL --decimation-ratio 3 > $dir/log/error_log.log
#  latgen-faster-mapped --acoustic-scale=0.083333 \
#        --allow-partial=true \
#        --max-active=7000 --beam=16.0 --lattice-beam=6.0 \
#        $TRIMDL $TRIHCLG \
#        "$likelihoods" \
#        ark:"| gzip -c > $dir/lat.JOB.gz" ark,t:$dir/result.JOB.txt || exit 1
#set -x
#run.pl JOB=1:5 exp/tri3/decode_test/log/decode.2.JOB.log latgen-faster-mapped --acoustic-scale=0.083333 --allow-partial=true --max-active=7000 --beam=16.0 --lattice-beam=6.0 exp/tri3/final.mdl exp/tri3/graph//HCLG.fst 
#gmm-compute-likes exp/tri3/final.mdl 'ark:apply-cmvn  --utt2spk=ark:data/test/split5/1/utt2spk scp:data/test/split5/1/cmvn.scp scp:data/test/split5/1/feats.scp ark:- | splice-feats --left-context=3 --right-context=3 ark:- ark:- | transform-feats exp/tri3/final.mat ark:- ark:- |' ark,t: > tmp_di.txt.2 
#gmm-compute-likes exp/tri3/final.mdl 'ark:apply-cmvn  --utt2spk=ark:data/test/split5/1/utt2spk scp:data/test/split5/1/cmvn.scp scp:data/test/split5/1/feats.scp ark:- | splice-feats --left-context=3 --right-context=3 ark:- ark:- | transform-feats exp/tri3/final.mat ark:- ark:- |' ark,t:- | perl $FILT_LL --decimation-ratio $DECIMATION_RATIO > tmp_di.txt.3
# | perl bin/2pass/decimate-likelihoods.pl --decimation-ratio 3 |' #'ark:| gzip -c > exp/tri3/decode_test/lat.JOB.gz' ark,t:exp/tri3/decode_test/result.JOB.txt
#set +x
$cmd $parallel_opts JOB=1:$nj $dir/log/decode.2.JOB.log \
  latgen-faster-mapped --acoustic-scale=0.083333 \
        --allow-partial=true \
        --max-active=7000 --beam=13.0 --lattice-beam=6.0 \
        $TRIMDL $TRIHCLG \
        "$likelihoods" \
        ark:"| gzip -c > $dir/lat.JOB.gz" ark,t:$dir/result.JOB.txt || exit 1
# score wers
if ! $skip_scoring ; then
  [ ! -x local/score.sh ] && \
    echo "Not scoring because local/score.sh does not exist or not executable." && exit 1;
  local/score.sh --cmd "$cmd" $scoring_opts $data $graphdir $dir
fi

find  $dir/scoring | grep BESTWER | xargs grep wer

[ $verbose ] && echo 'Finished: ' `date`
