#!/usr/bin/perl
=pod
usage:
	bin/2pass/decimate-likelihoods-phoneMark-arg.pl [options] bound_info_file

	--decimation-ratio N
	--save-compression-ratio compression_ratio_file
	--drop-mod D
	--fill-mod F
	--perc P
	--repeat-stop R
=cut

use Switch;
my $DROP_MOD = 6;
#use constant DROP_MOD => 6;
#DROP_MOD 1	drop 1 frame every N frames
#DROP_MOD 2	randomly dropping perc/1000 frames
#DROP_MOD 3	drop N-1 frame every N frames
#DROP_MOD 4	HYBMOD1
#DROP_MOD 5	drop N-1 frame every N frames avoid marks and MARK_COUNT frames after marks

my $FILL_MOD = 5;
#FILL_MOD 1	copy the last frame
#FILL_MOD 2	fill in 0 for the dropped frames
#FILL_MOD 3	fill in the same value for the dropped frames, the value is choosen to be equal to the average likelihood of the previous frame
#FILL_MOD 4	fill in the dropped frames with decated likelihoods of the previous undropped frame
#FILL_MOD 5	HUBMOD1

my $PERC = 195;
use constant DECA => 0.5;
#use constant AMPL => 1.75;
my $AMPL = 4;
use constant MARK_COUNT => 1;
my $REPEAT_STOP = 0;
use constant CONT_CHANGE => 0;

# parse options
use Getopt::Long;
GetOptions(\%opts,
	'decimation-ratio|d=i',
	'save-compression-ratio|s=s',
	'drop-mod|r=i',
	'fill-mod|f=i',
	'perc|p=i',
	'repeat-stop|r=i',
	'ampl-fact|a=f'
);

if ($opts{'drop-mod'}) {
	print STDERR "save to $opts{'drop-mod'}\n"	;
	$DROP_MOD=$opts{'drop-mod'};
}

if ($opts{'fill-mod'}) {
	print STDERR "save to $opts{'fill-mod'}\n"	;
	$FILL_MOD=$opts{'fill-mod'};
}

if ($opts{'perc'}) {
	print STDERR "save to $opts{'perc'}\n"	;
	$PERC=$opts{'perc'};
}

if ($opts{'repeat-stop'}) {
	print STDERR "save to $opts{'repeat-stop'}\n"	;
	$REPEAT_STOP=$opts{'repeat-stop'};
}

$DECIMATION_RATIO=2;
if ($opts{'decimation-ratio'}) {
	print STDERR "save to $opts{'decimation-ratio'}\n"	;
	$DECIMATION_RATIO=$opts{'decimation-ratio'};
}

$COMPRESS_FILE="temp";
if($opts{'save-compression-ratio'}) {
	print STDERR "save to $opts{'save-compression-ratio'}\n"	;
	$COMPRESS_FILE=$opts{'save-compression-ratio'};
}

if($opts{'ampl-fact'}){
	print STDERR "save to $opts{'ampl-fact'}\n"	;
	$AMPL=$opts{'ampl-fact'};
}

my $BOUND_FILE = shift @ARGV || die "specifiy boundary file";

#print "$BOUND_FILE\n";

my %bound_info;
print STDERR "reading from $BOUND_FILE\n";
open(IN, $BOUND_FILE);
while($bound_list=<IN>) {
	@parts = split(/\s+/,$bound_list);
	$uttid = shift @parts;
	$bound_info{$uttid} = $bound_list;
	#print "$uttid\n";
}
close(IN);

my $counter;
my $pre_line;
my $drop;
my $init = $DECIMATION_RATIO - 1;;
my $frame_count;
my $total_frame_count = 0;
my $total_drop_count = 0;
my $file_count = 0;
my $reweight;
my @temp_line;
my $pre_sum = 0.0;
my $mark_counter = 0;
my $repeat_counter = 0;

#print "$COMPRESS_FILE\n";

#if($COMPRESS_FILE ne /temp/) {
#	print "testing\n";
#	open(FACT, ">$COMPRESS_FILE");
#	print FACT "Average compression ratio is 0\n";
#	close(FACT);
#}


while ($line=<STDIN>) {
	chomp $line;

    	if ($line=~/^([^\s]+)\s*\[/) { # grab a matching log likelihood list 
        	$uttid = $1;
		#print "$uttid\n";
		$bound_list_temp = $bound_info{$uttid};		
		if ($bound_list_temp != /$uttid/) {
			die "frame list is mismatered: $uttid\n". "BOUNDLIST: $bound_list_temp";
		}
		#print "$bound_list_temp";
		@bound_list = split(/\s+/,$bound_list_temp);
		shift @bound_list;
		$frame_count = $DECIMATION_RATIO - 1;

		$counter = 0;
		$pre_line = "";
		$init = $DECIMATION_RATIO - 1;;
		++$file_count;
		$pre_sum = 0.0;
		$mark_counter = 0;

        	print "$line\n";
        	next;
    	}
    	$line=~s/^\s+//; 
    	$line=~s/\s+$//; 

    	# check for last frame
    	$endfr=0;
    	if ($line =~s/\]//) { $endfr =1; }
    	$line=~s/\s+$//;

	$temp_str = shift @bound_list;
	#print "$temp_str\n";
	if (("E" ne $temp_str) && ( "U" ne $temp_str) && ("U-U" ne $temp_str)) {
		$reweight = 1;
	} else {
		$reweight = 0;
	}
	#print "$reweight\n";

	switch ($DROP_MOD) {
		case 1 	{	$drop = ($counter == $DECIMATION_RATIO - 1)&&($reweight == 0);
				if ($drop) {
					$counter = 0;
				}else{
					++$counter;
				}
			}
		case 2	{$drop = (rand(1000) < $PERC)&&($init == 0);}
		case 3	{	$drop = ($counter != $DECIMATION_RATIO - 1)&&($init == 0)&&($reweight == 0);
				if (not $drop) {
					$counter = 0;
				}else{
					++$counter;
				}
			}
		case 4	{
				$drop = ($counter != $DECIMATION_RATIO - 1)&&($init == 0)&&($reweight == 0);
				if (not (($counter != $DECIMATION_RATIO - 1)&&($init == 0))) {
					$counter = 0;
				}else {
					++$counter;
				}		
			}
		case 5	{
				$drop = ($counter != $DECIMATION_RATIO - 1)&&($init == 0)&&($reweight == 0)&&($mark_counter == 0);
				if (not (($counter != $DECIMATION_RATIO - 1)&&($init == 0))) {
					$counter = 0;
				}else {
					++$counter;
				}
				if ($reweight == 1) {
					$mark_counter = MARK_COUNT;
				} elsif ($mark_counter > 0) {
					--$mark_counter;
				}
			}
		case 6	{
				$drop = ($init == 0)&&($reweight == 0);
			}
		case 7 	{
				$drop = $reweight != 0;
			}

		case 8	{
				$drop = ($counter != $DECIMATION_RATIO - 1)&&($init == 0)&&($reweight == 0);
				if($PERC > 0){
					if($drop && (rand(1000) < $PERC)){
						$drop = 0;
					}
				}elsif($PERC < 0){
					if((not $drop) && ($reweight == 0) && (rand(1000) < -1*$PERC)){
						$drop = 1;
					}
				}
				if (not (($counter != $DECIMATION_RATIO - 1)&&($init == 0))) {
					$counter = 0;
				}else {
					++$counter;
				}		
			}
	} 
	#print "$#bound_list\n";

	if ($drop) {
		switch ($FILL_MOD) {
			case 1 { $oline = $pre_line; }
			case 2 { 	
				@temp_line = split(/\s+/,$line);
				@temp_oline = (0.0)x($#temp_line + 1);
				$oline = join(" ", @temp_oline);
				#print "TRUE\n";
			}
			case 3 {
				@temp_line = split(/\s+/,$line);
				$oline = join(" ", ($pre_sum)x($#temp_line + 1));
			}
			case 4 {	
				$oline = join(" ", @deca_pre_line);
			}
			case 5 {
				if ($REPEAT_STOP > 0) {
					$repeat_counter++;
					if ($repeat_counter > $REPEAT_STOP + CONT_CHANGE) {
						@temp_line = split(/\s+/,$line);
						@temp_oline = (0.0)x($#temp_line + 1);
						$oline = join(" ", @temp_oline);
					} elsif ($repeat_counter > $REPEAT_STOP && CONT_CHANGE > 0){
						if ($repeat_counter == $REPEAT_STOP + 1) {
							@deca_pre_line = split(/\s+/, $pre_line);
						}
						for($c = 0; $c <=$#deca_pre_line; $c++) {
							$deca_pre_line[$c] = $deca_pre_line[$c]*DECA;
						}
						$oline = join(" ", @deca_pre_line);
					} else {
						$oline = $pre_line; 
					}
				} else { 
					$oline = $pre_line; 
				}
			}
		}
		++$total_drop_count;
	}else{
		if ($FILL_MOD != 5 || $reweight == 0) {
			$oline = $line;
		} else {
			@temp_line_mod5 = split(/\s+/, $line);
			for($c = 0; $c <= $#temp_line_mod5; $c++) {
				$temp_line_mod5[$c] = $temp_line_mod5[$c]*$AMPL;
			}
			$oline = join(" ", @temp_line_mod5);
		}
		if ($FILL_MOD == 3) {
			$pre_sum = 0.0;
			@temp_sum_line = split(/\s+/, $line);
			foreach my $num (@temp_sum_line) {
				$pre_sum = $pre_sum + $num;
			}
			$pre_sum = $pre_sum/($#temp_sum_line + 1);
		} elsif ($FILL_MOD == 4) {
			@deca_pre_line = split(/\s+/, $line);
			for($c = 0; $c <=$#deca_pre_line; $c++) {
				$deca_pre_line[$c] = $deca_pre_line[$c]*DECA;
			}
		}
		if ($REPEAT_STOP > 0) {
			$repeat_counter = 0;
		}
	}

    	#my @loglikes = split(/\s+/,$line);

	#$oline=join(" ", @loglikes);
    	if ($endfr) {
		$oline = $oline." ]"; 
		$total_frame_count = $total_frame_count + $frame_count;
	}
    	print "  $oline \n";

	if (not $drop) {
		$pre_line = $line;
	}
	if ($init > 0) {
		--$init;
	}	
	++$frame_count;
}

if($COMPRESS_FILE ne "temp") {
	open(FACT, ">$COMPRESS_FILE");
	$avg_ratio = 1 - ($total_drop_count/$total_frame_count);
	print FACT "Average compression ratio is $avg_ratio\n";
	close(FACT);
}
