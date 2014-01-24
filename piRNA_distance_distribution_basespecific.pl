#!/usr/bin/perl

#if you run it on hpcc

if(scalar(@ARGV)<3)
{
        usage();
}

$CLONE=$ARGV[3];
BEGIN { unshift @INC,"/home/xuj1/bin/";}
require "Statstics.pm";
require "Jia.pm";
BEGIN { unshift @INC,"/home/wangw1/bin/";}
require "sort_hash_key.pm";
use File::Basename;
use Compress::Zlib;
# the distribution of 5'-5' end distance of piRNAs from the same strand.

   $file1=fileparse($ARGV[0]);  
   #@namefield=split(/\./,$file1);
   #$name1=$namefield[0]."_".$namefield[2];
   #$file1=$name1;
   
   $format=$ARGV[1];
   
   %plus=(); %plus_end=(); %minus=();$mins_end=();
   
	if($file1=~/gz/)
	{
		my $gz="";
		$gz = gzopen($ARGV[0], "rb") or die "Cannot open $ARGV[0]: $gzerrno\n" ;
		while($gz->gzreadline($_) > 0)
		{ 
			chomp; s/\s+/\t/g;split(/\t/);  
			next if (/data/);
        
        	if($format eq "normbed")
        	{
				if($CLONE eq "SRA")
        		{
				next if (length($_[4])>29 || length($_[4])<23);
        		}
				if ($_[3] eq '+')
				{
	            	$plus{$_[0]}{$_[1]}+=$_[5]/$_[6];
	            	$plus_end{$_[0]}{$_[1]}=$_[2];
	        	}
	        	else
	        	{
	            	$minus{$_[0]}{$_[2]}+=$_[5]/$_[6];
	        	}
        	}
			if($format eq "bed")
			{

        		($reads,$ntm,$dep)=split(/,/,$_[3]);
        		if($file1=~/plus/i) #strand information is not included in the data, but in the file name
        		{
	            	$plus{$_[0]}{$_[1]}+=$reads/$ntm;
	            	$plus_end{$_[0]}{$_[1]}=$_[2];
	        	}
	        	if($file1=~/minus/i)
	        	{
	            	$minus{$_[0]}{$_[2]}+=$reads/$ntm;
	        	}
        	}		
		}
		$gz->gzclose();
	}
   else
   {
		open IN, $ARGV[0];
    	while(<IN>)
    	{
        	chomp; s/\s+/\t/g;split(/\t/);  
			next if (/data/);
        
        	if($format eq "normbed")
        	{
        		if($CLONE eq "SRA")
        		{
				next if (length($_[4])>29 || length($_[4])<23);
        		}
				if ($_[3] eq '+')
				{
	            	$plus{$_[0]}{$_[1]}+=$_[5]/$_[6]; #if all species starts with the same 5 end is collapsed, then why dis=0 appears?
	            	$plus_end{$_[0]}{$_[1]}=$_[2];
	        	}
	        	else
	        	{
	            	$minus{$_[0]}{$_[2]}+=$_[5]/$_[6];
	        	}
        	}
			if($format eq "bed")
			{

        		($reads,$ntm,$dep)=split(/,/,$_[3]);
        		if($file1=~/plus/i) #strand information is not included in the data, but in the file name
        		{
	            	$plus{$_[0]}{$_[1]}+=$reads/$ntm;
	            	$plus_end{$_[0]}{$_[1]}=$_[2];
	        	}
	        	if($file1=~/minus/i)
	        	{
	            	$minus{$_[0]}{$_[2]}+=$reads/$ntm;
	        	}
        	}
		}
		close(IN);
    }
    
    foreach $chr (keys %plus)
    {
        %plus_chr = %{$plus{$chr}};
        @plus_sort = &sort_hash_key( %plus_chr ); ##sort by the numerical value of the key
        
        foreach  ($k=0;$k<$#plus_sort;$k++)
        {
            $dis=0;
    
            foreach ($j=$k+1;$j<$#plus_sort;$j++)
            {
                $dis=$plus_sort[$j]-$plus_sort[$k]; ##why the $dis smaller than or equal to 0?
#                if($dis>0 && $dis <=100)
#                {
#                    $hash_dis{'plus'}{$chr}{$dis}+=&min($plus{$chr}{$plus_sort[$j]},$plus{$chr}{$plus_sort[$k]});
#                    $h_dis{$dis}+=&min($plus{$chr}{$plus_sort[$j]},$plus{$chr}{$plus_sort[$k]});
#                }
#                else
#                {
#                    $j=$#plus_sort+1; #to early terminate the j loop
#                }
                
#01/24/2014; to be more efficient, once distance reach 100, jump out of the j loop                
                if($dis>0)
                {
                	next if($dis >100);
	                $hash_dis{'plus'}{$chr}{$dis}+=&min($plus{$chr}{$plus_sort[$j]},$plus{$chr}{$plus_sort[$k]});
	                $h_dis{$dis}+=&min($plus{$chr}{$plus_sort[$j]},$plus{$chr}{$plus_sort[$k]});	
                }
   
            }
    
        }
        
    }
    foreach $chr (keys %minus)
        #%plus_lendis=&lendis_dist(%plus_sort);     ##calculate the distance distribution from the same strand, from the same chromosome
    {                                                #the adjacent piRNAs should be within 50nt of the current one
        if($minus{$chr})
        {
            
            @minus_sort=&sort_hash_key(%{$minus{$chr}});
            #%minus_lendis=&lendis_dist(%minus_sort);
            foreach  ($k=0;$k<$#minus_sort;$k++)
            {
            $dis=0;
    
            foreach ($j=$k+1;$j<$#minus_sort;$j++)
            {
                $dis=$minus_sort[$j]-$minus_sort[$k];
                if($dis>0 )
                {
                	next if($dis >100);
                    $hash_dis{'minus'}{$chr}{$dis}+=&min($minus{$chr}{$minus_sort[$j]},$minus{$chr}{$minus_sort[$k]});
                    $h_dis{$dis}+=&min($minus{$chr}{$minus_sort[$j]},$minus{$chr}{$minus_sort[$k]});
                }

            }
    
            }
        }
    }
 	$OUTDIR=$ARGV[2];   
    open OUT, ">$OUTDIR/$file1.5-5.distance.distribution";
    foreach $strand (keys %hash_dis)
    {
        foreach $chr (sort keys %{$hash_dis{$strand}})
        {
            foreach $dis (sort { $a <=> $b } keys %{$hash_dis{$strand}{$chr}})
            {
            print OUT "$strand\t$chr\t$dis\t$hash_dis{$strand}{$chr}{$dis}\n";
            }
        }
    }
    close (OUT);
    
    
    open OUT, ">$OUTDIR/$file1.5-5.distance.distribution.summary";
    foreach $dis (sort { $a <=> $b } keys %h_dis)
    {
        print OUT "$dis\t$h_dis{$dis}\n";
    }
    close(OUT);

sub usage
{
        print "\nUsage:$0\n\n\t";
        print "REQUIRED\n\t";
        print "inputfile type(bed|normbed) outdir clone\n";
        print "This perl script is count the frequency of 5'-5'end distances of smallRNAs(23-29) from the same strand\n";

        exit(1);
}
