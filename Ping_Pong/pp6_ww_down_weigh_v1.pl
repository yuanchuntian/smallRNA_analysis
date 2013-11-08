#!/usr/bin/perl
use File::Basename;
#print "pp";
#print map {"\t$_"} @ARGV;
#print "\n";


##report PP pair sequences
##WEI WANG
##09/2012

##09/21/2012
# For N1, if it can find M1, (their 5' end distance is 10 nt apart), then N1M2, N1M3 should be down-weighted!
# For M1, if it can find N1, (their 5' end distance is 10 nt apart), then M1N2,M1N2 should be down-weighted!
# How to down weigh?
# For each species, depends on how many non-P10 pairs can be found. If n-1 (if window size is 20, the max n is 20) pairs can be found
# the reads number should be down weighted to r/n!

for ($i=0; $i<$ARGV[2]; $i++) {
   #print $ARGV[$i];

   for ($j=0; $j<$ARGV[2]; $j++) {
   $file1=fileparse($ARGV[$i]);  #$file1 is the target strand
   @namefield=split(/\./,$file1);
   $name1=$namefield[2]."_".$namefield[1];
   $file1=$name1;
    
   $file2=fileparse($ARGV[$j]); #file2 is the guide strand
   @namefield=split(/\./,$file2);
   $name2=$namefield[2]."_".$namefield[1];
   $file2=$name2;
   
   open PPSEQ, ">$file1_$file2.down.weight.ppseq";
   open PP, ">$file1_$file2.down.weight.pp";
   open PPlocal, ">$file1_$file2.down.weight.local.pp";
   open PPZ, ">$file1_$file2.down.weight.zscore.out";
   open PPZlocal, ">$file1_$file2.down.weight.lcoalzscore.out";
   
   print PPZ "$file1-$file2\t";
   
   $X=0; $Z=0; %score=(); %s=();


   %pp=(); %pos=(); %pp_seq=(); %pos_seq=();
   %pp_10=();
      open IN, $ARGV[$i];  ##suppose Ago3IP
      while(<IN>)
      {
         chomp; s/\s+/\t/g; split(/\t/);
         next if (length($_[0])>29 || length($_[0])<23);
         $_[2]=~/(chr.+):(\d+)-(\d+)\((.+)\)/;
         if ($4 eq '+')
         {
            foreach ($n=1;$n<=32;$n++)
            {
               $start=$2+$n-1;
               $pp{"$1:$2+"}{$n}{"$1:$start-"}+=$_[1]/$_[6]; ##record each species, and their corresponding pairs when 5' end distance is 1,2,...20
                                                            ## the reads number is from N1
               
               $pp_10{"$1:$2+"}="$1:$start-" if($n==10);  #record pp10 for decision, key is the N1, value is the M1
               $pp_seq{"$1:$start-"}=$_[0] if($n==10);
            } #shift n
         }
         else
         {
            foreach ($n=1;$n<=32;$n++)
            {
               $start=$3-$n+1;
               $pp{"$1:$3-"}{$n}{"$1:$start+"}+=$_[1]/$_[6]; ##record each species, and their corresponding pairs when 5' end distance is 1,2,...20
                                                            ## the reads number is from N1
               $pp_10{"$1:$3-"}="$1:$start+" if($n==10); #record pp10 for decision
               $pp_seq{"$1:$start+"}=$_[0] if($n==10);
            } #shift n
         }
      }
   
      open IN, $ARGV[$j]; ##suppose AubIP
      while(<IN>)
      {
         chomp; s/\s+/\t/g; split(/\t/);
         next if (length($_[0])>29 || length($_[0])<23);
         $_[2]=~/(chr.+):(\d+)-(\d+)\((.+)\)/; 
         if ($4 eq '+')                   
         {
            $pos{"$1:$2+"}+=$_[1]/$_[6]; # original species
            $pos_seq{"$1:$2+"}= $_[0];
         }
         else
         {
            $pos{"$1:$3-"}+=$_[1]/$_[6]; # original species
            $pos_seq{"$1:$3-"}=$_[0];
         }
      }
####################################################################################################################################################################################
  
   foreach $species (keys %pp_10) ##For N1 (the key), if it can find M10, (their 5' end distance is 10 nt apart), then N1M2, N1M3 should be down-weighted!
   {
         $weight=0;
         if($pos{$pp_10{$species}}) #find a 10 nt pair M10 (value is M10)
         {
            foreach $n (keys %{$pp{$species}})
            {
               foreach $species_pair (keys %{$pp{$species}{$n}}) ##M1,M2,...M20
               {
                  if($pos{$species_pair})
                  {
                  $weight++;
                  }
               }
            }
            if ($weight!=0)
            {
               $pos{$species}=$pos{$species}/$weight; #N1 BUT why nothing has been changed for M1,M2,.....   
               ##should down-weigh N1, N1's effect on M1, M2, ...M20
               foreach $n (keys %{$pp{$species}})
               {
                  foreach $species_pair (keys %{$pp{$species}{$n}}) ##M1,M2,...M20
                  {
                     $pp{$species}{$n}{$species_pair}=$pp{$species}{$n}{$species_pair}/$weight;
                  }
               }  
            }
         }   
   }
####################################################################################################################################################################################     
   foreach $species (keys %pp)
   {
      foreach $n (keys %{$pp{$species}})
      {
         foreach $species_pair (keys %{$pp{$species}{$n}}) ##M1,M2,...M20
         {
            if ($species_pair && exists $pos{$species_pair})
            {
               $score{$n}+=$pos{$species_pair}*$pp{$species}{$n}{$species_pair} ;
               #$s{$species}{$n}+=$pos{$species_pair}*$pp{$species}{$n}{$species_pair} ;
               print PPSEQ "$pp_seq{$species_pair}\t$pp{$species}{$n}{$species_pair}\t$pos_seq{$species_pair}\t$pos{$species_pair}\n" if ($n==10);
            }
         }
      }
   }
   
   foreach ($n=1;$n<=32;$n++)
   {
      
      $score{$n}=0 if (!exists $score{$n});
      print PP "$n\t$score{$n}\n";
      #if ($n==10) { $X=$score{$n}; delete $score{$n};}
   }
      $X=$score{10};
      $p9=$score{9};
      $p11=$score{11};
      
      %score_20=();
      for($j=1;$j<=20;$j++)
      {
         $score_20{$j}=$score{$j};
      }
      
      
      $total_score=0;
      $total_score=&total(values %score);
      if ($total_score!=0)
      {
         $percentage=$X/$total_score;
      }
      else
      {
         $percentage=0;
      }
      delete $score{10};
      $std=&standard_deviation(values %score);
      $m=&mean(values %score);
      if ($std>0)
      {
         $Z=($X-&mean(values %score))/$std;
      }
      else
      {
         $Z=-10;
      }
      print PPZ "$Z\t$percentage\t$m\t$std\t$X\t$p9\t$p11\t";
      print "$Z\t$percentage\t$m\t$std\t$X\t$p9\t$p11\t";
      
      $total_score=0;
      $total_score=&total(values %score_20);
      if ($total_score!=0)
      {
         $percentage=$X/$total_score;
      }
      else
      {
         $percentage=0;
      }
      delete $score_20{10};
      $std=&standard_deviation(values %score_20);
      $m=&mean(values %score_20);
      if ($std>0)
      {
         $Z=($X-&mean(values %score_20))/$std;
      }
      else
      {
         $Z=-10;
      }
      print PPZ "$Z\t$percentage\t$m\t$std\n";
      print "$Z\t$percentage\t$m\t$std\n";
      
   
   
   #foreach $species (keys %s)
   #{
   #   foreach ($n=1;$n<=20;$n++)
   #   {
   #      $s{$species}{$n}=0 if (!exists $s{$species}{$n});
   #      print PPlocal "$species\t$n\t$s{$species}{$n}\n";
   #      if ($n==10) { $X=$s{$species}{$n}; delete $s{$species}{$n};}
   #   }
   #   $std=&standard_deviation(values %{$s{$species}});
   #   
   #   if ($std>0)
   #   {
   #      $Z=($X-&mean(values %{$s{$species}}))/$std;
   #   }
   #   else
   #   {
   #      $Z=-10;
   #   }
   #   print PPZlocal "$species\t$Z\t$X\t$std\n";   
   #}
}

}
sub mean {
my $count=0;
my(@numbers) =@_;
foreach (@_) { $count+=$_;}
return $count/(scalar @_);
}

sub total {
my $count=0;
my(@numbers) =@_;
foreach (@_) { $count+=$_;}
return $count;
}

sub standard_deviation {
my(@numbers) = @_;
#Prevent division by 0 error in case you get junk data
return undef unless(scalar(@numbers));

# Step 1, find the mean of the numbers
my $total1 = 0;
foreach my $num (@numbers) {
$total1 += $num;
}
my $mean1 = $total1 / (scalar @numbers);

# Step 2, find the mean of the squares of the differences
# between each number and the mean
my $total2 = 0;
foreach my $num (@numbers) {
$total2 += ($mean1-$num)**2;
}
my $mean2 = $total2 / (scalar @numbers);

# Step 3, standard deviation is the square root of the
# above mean
my $std_dev = sqrt($mean2);
return $std_dev;
}
