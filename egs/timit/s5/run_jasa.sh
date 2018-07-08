#/bin/bash
#####################################################################
# Complete the rescoring and frame-dropping experiments mentioned in
#   https://doi.org/10.1121/1.4987204 and
#   https://doi.org/10.1121/1.5039837
#   please reference the Joural of the Acoustical Society of America 
#   abstract and paper. 
#   For more details please contact Di He at
#   dihe2@illinois.edu for any questions
#####################################################################

decode_cmd=run.pl
decode_nj=5
dnn_extra_opts="--num_epochs 20 --num-epochs-extra 10 --add-layers-period 1 --shrink-interval 3"
log_result=results/result.txt
log_running=results/logs.txt
reweight_fact=1.5
decimate_ratio=3 #drop 2 out of 3 frames
drop_perc=550 #drop 55% of the frames

# complete the defualt kaldi training script for tri2 and tri4_nnet
#   properly edit the cmd.sh and path.sh file in run.sh and edit the 
#   timit variable to point to the correct path with the TIMIT corpus
#   has been stored before running run.sh
if [ ! -d ./exp/tri4_nnet/decode_test ]; then
  ./run.sh || exit 1;
fi

# copy the landmark labeling files into decode_test the folders
#   the labeling files have been generated using the Matlab script
#   matlab_sh/getLandmark.m, editing the file will allow you to 
#   redefine the landmark labeling rules.
cp results/phone_mark_info.* exp/tri2/decode_test/ || exit 1;
cp results/phone_mark_info.* exp/tri4_nnet/decode_test/ || exit 1;

# log some information
echo '##############################' >> $log_result
date >> $log_result
echo '##############################' >> $log_result
echo '' >> $log_result

# work with tri2 acoustic models first
# log the baseline PER
echo 'tri2 Baseline:' >> $log_result
grep 'Mean*' ./exp/tri2/decode_test/score_*/ctm_39phn.filt.sys >> $log_result

# reweight tri2 
bash steps/decode-ccnc-arg.sh --nj $decode_nj --skip_first_pass true --filter_likes false --use_landmark true --run_reweight true --REWEIGHT_FACTOR $reweight_fact --drop_mod 0 --fill_mod 0 --perc 0 --repeat_stop 0 --ampl_fact 0 exp/tri2/graph/ data/test exp/tri2/decode_test >> $log_running || exit 1;

echo 'reweight by "${reweight_fact}":' >> $log_result
grep 'Mean*' ./exp/tri2/decode_test/score_*/ctm_39phn.filt.sys >> $log_result

# drop frames when scoring features while avoiding landmarks
#   to adjusting other options properly, please reference bin/2pass/decimate-likelihoods-phoneMark-arg.pl
bash steps/decode-ccnc-arg.sh --nj $decode_nj --skip_first_pass true --filter_likes true --DECIMATION_RATIO $decimate_ratio --use_landmark true --run_reweight false --REWEIGHT_FACTOR 0 --drop_mod 4 --fill_mod 5 --perc 0 --repeat_stop 0 --ampl_fact 1.75 exp/tri2/graph/ data/test exp/tri2/decode_test >> $log_running || exit 1;

echo 'dropping-frames by "${decimate_ratio}", avoiding landmarks:' >> $log_result
grep 'Mean*' ./exp/tri2/decode_test/score_*/ctm_39phn.filt.sys >> $log_result

# randomly drop some frames
bash steps/decode-ccnc-arg.sh --nj $decode_nj --skip_first_pass true --filter_likes true --DECIMATION_RATIO 0 --use_landmark true --run_reweight false --REWEIGHT_FACTOR 0 --drop_mod 2 --fill_mod 2 --perc $drop_perc --repeat_stop 0 --ampl_fact 0 exp/tri2/graph/ data/test exp/tri2/decode_test >> $log_running || exit 1;

echo 'dropping-frames randomly "${drop_perc}"/1000:' >> $log_result
grep 'Mean*' ./exp/tri2/decode_test/score_*/ctm_39phn.filt.sys >> $log_result


# repeat the same procedure with tri4_dnn
# log the baseline PER
echo 'tri4_dnn Baseline:' >> $log_result
grep 'Mean*' ./exp/tri4_nnet/decode_test/score_*/ctm_39phn.filt.sys >> $log_result

# reweight tri4_nnet
steps/decode-ccnc-nnet-arg.sh --cmd $decode_cmd --nj $decode_nj --filter_likes true --DECIMATION_RATIO 0 \
  --use_landmark true --drop_mod 0 --fill_mod 0 --perc 0 --repeat_stop 0 "${decode_extra_opts[@]}" \
  --run_reweight true --REWEIGHT_FACTOR $reweight_fact --ampl_fact 0 \
  --transform-dir exp/tri3/decode_test exp/tri3/graph data/test \
  exp/tri4_nnet/decode_test | tee $log_running || exit 1;

echo 'reweight by "${reweight_fact}":' >> $log_result
grep 'Mean*' ./exp/tri4_nnet/decode_test/score_*/ctm_39phn.filt.sys >> $log_result

# drop frames when scoring features while avoiding landmarks
#   to adjusting other options properly, please reference bin/2pass/decimate-likelihoods-phoneMark-arg.pl
steps/decode-ccnc-nnet-arg.sh --cmd $decode_cmd --nj $decode_nj --filter_likes true --DECIMATION_RATIO $decimate_ratio \
  --use_landmark true --drop_mod 4 --fill_mod 5 --perc 0 --repeat_stop 0 "${decode_extra_opts[@]}" \
  --run_reweight false --REWEIGHT_FACTOR 0 --ampl_fact 4.5 \
  --transform-dir exp/tri3/decode_test exp/tri3/graph data/test \
  exp/tri4_nnet/decode_test | tee $log_running || exit 1;

echo 'dropping-frames by "${decimate_ratio}", avoiding landmarks:' >> $log_result
grep 'Mean*' ./exp/tri4_nnet/decode_test/score_*/ctm_39phn.filt.sys >> $log_result

# randomly drop some frames
steps/decode-ccnc-nnet-arg.sh --cmd $decode_cmd --nj $decode_nj --filter_likes true --DECIMATION_RATIO 0 \
  --use_landmark true --drop_mod 2 --fill_mod 2 --perc $drop_perc --repeat_stop 0 "${decode_extra_opts[@]}" \
  --run_reweight false --REWEIGHT_FACTOR 0 --ampl_fact 0 \
  --transform-dir exp/tri3/decode_test exp/tri3/graph data/test \
  exp/tri4_nnet/decode_test | tee $log_running || exit 1;

echo 'dropping-frames randomly "${drop_perc}"/1000:' >> $log_result
grep 'Mean*' ./exp/tri4_nnet/decode_test/score_*/ctm_39phn.filt.sys >> $log_result
