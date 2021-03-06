# Population Genomics for Adaptation

Instructor: **Sebastian E. Ramos-Onsins**

Date: July 13th 2022

## The Detection of the Proportion of Beneficial Substitutions

In this practical session we will focus on the effect of positive and negative selection on the polymorphism and the divergence at functional and neutral positions across the genome. We will simulate a number of different evolutionary scenarios and analyze the different observed patterns.

The objectives of this practical session are:

* To familiarize with the forward-simulator *Slim*. Understanding how it works and be able to construct your own code.
* Run different scenarios containing positive and/or negative selection, plus some demographic effects that can affect the detection of beneficial mutations.
* Estimate the proportion of beneficial substitutions using different methods
* Contrast estimates with the real value per scenario.

## Get scripts for this session

First of all, download the scripts and the manual for the practical session!

```
svn export https://github.com/ppgcourseUB/ppgcourse2022/trunk/PopGenomicsAdaptation.SebastianERamosOnsins
```

## Forward Simulator: *Slim*
1.	We will simulate a number of different scenarios using [*Slim*](https://messerlab.org/slim/) (Messer, Genetics 2013, Haller and Messer, MBE 2017, [Haller and Messer, MBE 2019](https://academic.oup.com/mbe/article/36/3/632/5229931?login=true)). Slim is a forward simulator that allows to simulate many selective positions at the same time in complex demographic patterns. Slim has a **graphical interface** (we will see an example on the practical class) but to speed up the simulation analysis we will use the **command line** program in the practical session. 
2. The simulator contains an extended manual and many "recipes" or examples for many different uses, including complex metapopulation models in spatial context, non-Wright-Fischer models and also is able to work with phenotypic traits and QTLs in relation to the genotypes. 
3. The simulator is designed in a very versatile way, allows to include new functions, debugging code and controling variable using *Eidos* environment. *Slim* also can output trees, genomes, mutations and substitutions at any step in the simulation.

If your computer allows it, download [*Slim*](https://messerlab.org/slim/). Start the graphical interface application and open the initial recipe 4.1 - A basic neutral simulation. Understand the basic commands included. Use the Simulation panel to "Dump Population State" and see the output of all genomes, mutations and substitutions at the current population.

```
// set up a simple neutral simulation
initialize()
{
	// set the overall mutation rate
	initializeMutationRate(1e-7);
	
	// m1 mutation type: neutral
	initializeMutationType("m1", 0.5, "f", 0.0);
	
	// g1 genomic element type: uses m1 for all mutations
	initializeGenomicElementType("g1", m1, 1.0);
	
	// uniform chromosome of length 100 kb
	initializeGenomicElement(g1, 0, 99999);
	
	// uniform recombination along the chromosome
	initializeRecombinationRate(1e-8);
}
```
The simulation needs to initialize some parameters. Here it is defined the mutation and the recombination rate per position, the type of mutation used (named "m1", with dominance 0.5 and a fixed selective value of s=0 (neutral)). The mutation "m1" is included in a genomic element named "g1", which contains 1e5 positions.

```
// create a population of 500 individuals
1
{
	sim.addSubpop("p1", 500);
}

// run to generation 10000
10000
{
	sim.simulationFinished();
}
```
The simulation starts at generation 1, creating a population named "p1" with 500 diploid individuals. Finally, the simulation finish at generation 10000, following a number of steps (which can also be modified) that includes migration (if defined), generation of offspring by choosing parents based on fitness, mutation, recombination and recalculation of fitness for the new individual.

### slim_template.slim ###
Open the file located in this Github folder named "slim_template.slim", using the graphical interface or a Text Editor to visualize. Explanation of the commands included in the file.

```
// command line including necessary parameters:
// slim -t -m -d "Ne=500" -d "L=30000" -d "Neb=500" -d "mut_rate=1e-6" -d "rec_rate=1e-4" -d "ngenes=2" -d "rate_ben=0.1,1" -d "rate_del=8" -d "s_backg_ben=0.005" -d "s_backg_del=-1" -d "nsweeps=1" -d "freq_sel_init=0.05" -d "freq_sel_end=0.95" -d "s_beneficial=0.1" -d "ind_sample_size=25" -d "out_sample_size=1" -d "file_output1='~/slim.test_file.txt'" ./slim_template.slim


```
slim can run in command line. Here is one example where a number of parameters are externally defined by the user at the command.

```
// set up a simple neutral simulation
initialize() {

	if (exists("slimgui")) {
		defineConstant("Ne",500); //number of diploid infdividuals
		defineConstant("L",500000); //length of the genome		
		defineConstant("Neb",500); //number of diploid infdividuals given sudden change pop size
		
		defineConstant("mut_rate",1e-6);	
		defineConstant("rec_rate",1e-4);
		defineConstant("ngenes",100); //number of independent genes

		defineConstant("rate_ben",0.5); //rate beneficial mutations versus neutral (1) and deleterious
		defineConstant("rate_del",8); //rate deleterious mutations versus neutral (1) annd benficial
		defineConstant("s_backg_ben",+0.005);	//s of beneficial background 
		defineConstant("s_backg_del",-0.05);	//s of deleteriious background 

		defineConstant("nsweeps",0); //if >0, define number of sweeps frequencies to start and end plus strength 
		defineConstant("freq_sel_init",0.05);
		defineConstant("freq_sel_end",0.5);
		defineConstant("s_beneficial",0.1);
		
		defineConstant("ind_sample_size",25); //number of samples to use
		defineConstant("out_sample_size",1); //number of outgroup samples to use
		defineConstant("file_output1","~/slim.test_file.txt"); //name of output file
	}

	//define a fixed demographic process plus a possible selective sweep before sampling
	defineConstant("tsplit",5*Ne); //time split outgroup
	defineConstant("tne",14*Ne); //time change Ne
	defineConstant("tsweep",asInteger(14*Ne + Ne/2)); //time sweep
	defineConstant("tend",15*Ne); //time end

	initializeSLiMOptions(nucleotideBased=T);
	initializeAncestralNucleotides(randomNucleotides(L));
	
	//separate each gene using recombination 0.5
	rrates = NULL;
	ends = NULL;
	len = asInteger(L/ngenes-1);
	for(i in 1:ngenes) {
		rrates = c(rrates,rec_rate,0.5);
		ends = c(ends,len,len+1);
		len = len + asInteger(L/ngenes); 
	}	
	rrates = rrates[0:(2*ngenes-2)];
	ends = ends[0:(2*ngenes-2)];
	initializeRecombinationRate(rrates,ends); 

	// m1 mutation type: (neutral)
	initializeMutationTypeNuc("m1", 0.5, "f", 0.0);
	// m2 mutation type: (deleterious)
	if(s_backg_del==0) {initializeMutationTypeNuc("m2", 1.0, "f", s_backg_del);}
	else { initializeMutationTypeNuc("m2", 1.0, "g", s_backg_del, 0.2);}
	// m3 mutation type: (beneficial)
	initializeMutationTypeNuc("m3", 0.5, "f", s_backg_ben);

	// g1 genomic element type: (synonymous) uses m1 for all mutations
	initializeGenomicElementType("g1", m1, 1.0,mmJukesCantor(mut_rate/3));
	// g2 genomic element type: (nonsynonymous) uses all mutations
	initializeGenomicElementType("g2", c(m1,m2,m3), c(1,rate_del,rate_ben),mmJukesCantor(mut_rate/3));

	//the chromosome is made with L/3 codons having two nonsyn + 1 syn position
	types = rep(c(g2,g2,g1), asInteger(L/3));
	if(L%3==1) {types=c(types,g2);}
	if(L%3==2) {types=c(types,g2,g2);}
	position = seq(0,L-1);
	initializeGenomicElement(types, position, position); //each codon contains g2,g2,g1
}
```
The first step (initialize) is here more complex. Include the definition of parameters (*e.g.,* Ne, ngenes, selective effect ad proportion of beneficial and deleterious mutations, or the sample size collected at the end) in case the code is used with the graphical interface. Then, a number of parameters related to the demographic scenario are also included. In this example, we use the option to simulate nucleotide sequences (A,C,G,T) instead of only mutations. The recombination rate is defined within and between genes (being free recombination between them). 

It is very important to understand the definition of two different genomic elements: g1 (synonymous) and g2 (nonsynonymous). g1 contains only "m1" (neutral) mutations, while g2 contains "m1" (neutral), "m2" (deleterious) and "m3" (beneficial) in defined proportions for each. g1 and g2 are defined as (g2, g2, g1) per codon and consecutively in the whole genome.

```
//START SIMULATION
1{
	sim.addSubpop("p1", Ne); //create initial population and run up to equilibrium for 10Ne gen.
	sim.rescheduleScriptBlock(s1, start=tsplit, end=tsplit); //split OUTG
	sim.rescheduleScriptBlock(s2, start=tne, end=tne); //Sudden change Ne
	sim.rescheduleScriptBlock(s3, start=tsweep, end=tsweep); //possible sweeep
	sim.rescheduleScriptBlock(s4, start=tend, end=tend); //end simulation. Print data
}

// Split de p1 in the generation 5000
s1 50000 { sim.addSubpopSplit("p2", Ne, p1); }

// Sudden Change in population size
s2 97500 { p2.setSubpopulationSize(Neb); }

//if required, force a strong selective sweep in n different positions. Can be successful or not
s3 98000 {	
	if(nsweeps) {
		muts = sim.mutations;
		muts = muts[muts.mutationType==m3]; //added: look only at positive mutations
		mutsp2b = sim.mutationFrequencies(p2, muts);
		muts = muts[mutsp2b >= freq_sel_init & mutsp2b <= freq_sel_init + (freq_sel_end - freq_sel_init)/5];	
		if (size(muts)>=nsweeps)
		{
			mut = sample(muts, nsweeps);
			mut.setSelectionCoeff(s_beneficial);
			print("Sweep at positions: ");
			print(mut.position);
		}
		else {
			cat("No contender of sufficient frequency found.\n");
		}
	}
}

```
Here, the simulation is separated in blocks from the generation 1 (s1, s2,s3,s4). These blocks can be defined at the desired time by user. The blocks indicate a split of ancestral population in two populations, outgroup and target (s1), the change in Ne at the target population (s2) and the possibility to have strong selective sweeps (s3).

```

// Run up 10000 generations
s4 100000 late() {
	//OUTPUT
	// Select no samples from the outgroup and ni samples of the target population and output
	// obtain random samples of genomes from the three subpopulations
	g_1 = sample(p2.genomes,2*ind_sample_size,F);
	g_2 = sample(p1.genomes,2*out_sample_size,F);
	//Concatenate the 2 samples
	g_12=c(g_1,g_2);
	//Get the unique mutations in the sample, sorted by position
	m = sortBy(unique(g_12.mutations),"position");
	
	//separate mutations of element g2 or/and in codon position 1 and 2 (nonsyn) 
	nonsyn_m = m[(m.position+1) % 3 != 0];
	//separate mutations of element g1 or/and in codon position 3 (syn)
	syn_m = m[(m.position+1) % 3 == 0];
	//look for polymorphisms and substitutions in target population that are fixed in outgroup
	sfs = array(rep(0,2*(2*ind_sample_size+3)),dim=c(2,2*ind_sample_size+3));
	//SFS for nonsyn
	for(position in nonsyn_m.position) {
		fr = 0; //frequency of each variant
		for(genome in g_1) {
			fr = fr + sum(match(position,genome.mutations.position) >= 0);
		}
		//print("\nposition="+position);
		//print("fr="+fr);
		fro = 0;
		for(genome in g_2) {
			fro = fro + sum(match(position,genome.mutations.position) >= 0);
		}
		//print("fro="+fro);
		if(fr>0 & fro==0) {
			sfs[0,fr-1] = sfs[0,fr-1] + 1;
		}
		if(fr==0 & fro==2*out_sample_size) {
			sfs[0,2*ind_sample_size-1] = sfs[0,2*ind_sample_size-1] + 1;
			//number of beneficial substitutions (m3)
			if(nonsyn_m.mutationType[which(nonsyn_m.position==position)[0]]==m3) { 
				sfs[0,2*ind_sample_size+2]	= sfs[0,2*ind_sample_size+2] + 1; 
			}
		}
	}
	//add the mutations from added selective sweeps (assumed fixed)
	//sfs[0,2*ind_sample_size+2]	= sfs[0,2*ind_sample_size+2] + nsweeps;
	
	//SFS for nsyn
	for(position in syn_m.position) {
		fr = 0;
		for(genome in g_1) {
			fr = fr + sum(match(position,genome.mutations.position) >= 0);
		}
		fro = 0;
		for(genome in g_2) {
			fro = fro + sum(match(position,genome.mutations.position) >= 0);
		}
		if(fr>0 & fro==0) {
			sfs[1,fr-1] = sfs[1,fr-1] + 1;
		}
		if(fr==0 & fro==2*out_sample_size) {
			sfs[1,2*ind_sample_size-1] = sfs[1,2*ind_sample_size-1] + 1;
		}
	}
	//include length of sequences and move the divegence like in polyDFE output
	sfs[0,2*ind_sample_size+0] = sfs[0,2*ind_sample_size-1];
	sfs[0,2*ind_sample_size-1] = asInteger(L*2/3);
	sfs[0,2*ind_sample_size+1] = asInteger(L*2/3);
	sfs[1,2*ind_sample_size+0] = sfs[1,2*ind_sample_size-1];
	sfs[1,2*ind_sample_size-1] = asInteger(L*1/3);
	sfs[1,2*ind_sample_size+1] = asInteger(L*1/3);
	
	//manipulate for easy print of sfs matrix
	print_header = "SFS";
	print_header = print_header + paste("	fr"+c(1:(2*ind_sample_size-1)));
	print_header = print_header + "	" + "PosP" + "	" + "Fixed" + "	" + "PosF" + "	" + "FixBen";
	print_sfs_nsyn = "nsyn" + "	";
	print_sfs_syn  = "syn" + "	";
	for(i in c(0:(2*ind_sample_size+2))) {
		print_sfs_nsyn = print_sfs_nsyn + sfs[0,i] + "	"; 
		print_sfs_syn  = print_sfs_syn  + sfs[1,i] + "	"; 
	}
	
	//OUTPUT:
	//for syn and for nonsyn:
	// print the sfs of target, the substitutions vs outgroup and the total sites
	print("Saving results to file " + file_output1);
	writeFile(filePath=file_output1,contents=(print_header),append=F);
	writeFile(filePath=file_output1,contents=(print_sfs_nsyn),append=T);
	writeFile(filePath=file_output1,contents=(print_sfs_syn),append=T);
				
	print("Simulation finished");
}

```
The step s4 finish the simulation and collects the Site Frequency Spectrum (SFS) for a sample in synonymous and nonsynonymous positions, plus the number of fixations and the number of true beneficial fixations.

## Run Simulations under Different Selective Scenarios

Here, we will simulate different selective scenarios in order to evaluate the ability to detect the proportion of beneficial substitutions under the defined conditions. Nine different scenarios are defined in the script "**run\_construct\_slim\_conditions.sh**", although the user can modify the conditions if desired (but be careful to not include unrealistic or never-finish conditions!). 

You can modify the name of the job to identify yours.

```
#header for run in slurm
echo \#!/bin/bash > ./run_slim_conditions.sh
echo \# >> ./run_slim_conditions.sh
echo \#SBATCH --job-name=9slims >> ./run_slim_conditions.sh
echo \#SBATCH -o %j.out >> ./run_slim_conditions.sh
echo \#SBATCH -e %j.err >> ./run_slim_conditions.sh
echo \#SBATCH --ntasks=9 >> ./run_slim_conditions.sh
echo \#SBATCH --mem=12GB >> ./run_slim_conditions.sh
echo \#SBATCH --partition=normal >> ./run_slim_conditions.sh
echo \# >> ./run_slim_conditions.sh
echo module load SLiM >> ./run_slim_conditions.sh
echo >> ./run_slim_conditions.sh

```
These are slurm parameters, and next the conditions for simulations:

```
#fixed paraneters
Ne=500; L=500000; ngenes=100;
mut_rate=1e-6;
ind_sample_size=25; out_sample_size=1;

# CONDITION 0:
#Neutral. No change Ne.
FILEOUT="'./00_slim_SFS_SNM.txt'"
Neb=500; nsweeps=0;
rec_rate=1e-4;
rate_ben=0; s_backg_ben=0;
rate_del=0; s_backg_del=0;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 1:
#Strong BACKGROUND SELECTION. No beneficial selection. No change Ne. No sweep
FILEOUT="'./01_slim_SFS_BGS.txt'"
Neb=500; nsweeps=0;
rec_rate=1e-4
rate_ben=0; s_backg_ben=0;
rate_del=8; s_backg_del=-0.05;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 2:
#No background selection. BENEFICIAL SELECTION. No change Ne. No sweep
FILEOUT="'./02_slim_SFS_PSL.txt'"
Neb=500; nsweeps=0;
rec_rate=1e-4
rate_ben=0.05; s_backg_ben=0.005;
rate_del=0; s_backg_del=0;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 3:
#Strong BACKGROUND SELECTION. BENEFICIAL SELECTION. POPULATION REDUCTION. No sweep.
FILEOUT="'./03_slim_SFS_BGS_PSL_RED.txt'"
Neb=200; nsweeps=0;
rec_rate=1e-4
rate_ben=0.5; s_backg_ben=0.005;
rate_del=8; s_backg_del=-0.05

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 4:
#Strong BACKGROUND SELECTION. BENEFICIAL SELECTION. POPULATION EXPANSION. No sweep.
FILEOUT="'./04_slim_SFS_BGS_PSL_EXP.txt'"
Neb=2500; nsweeps=0;
rec_rate=1e-4
rate_ben=0.5; s_backg_ben=0.005;
rate_del=8; s_backg_del=-0.05;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 5:
#Strong BACKGROUND SELECTION. SMALL PROPORTION BENEFICIAL SELECTION. No change Ne. No sweep.
FILEOUT="'./05_slim_SFS_BGS_PSL.txt'"
Neb=500; nsweeps=0;
rec_rate=1e-4
rate_ben=0.05; s_backg_ben=0.005;
rate_del=8; s_backg_del=-0.05;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 6:
#Strong BACKGROUND SELECTION. MIDDLE PROPORTION BENEFICIAL SELECTION. No change Ne. No sweep.
FILEOUT="'./06_slim_SFS_BGS_PSM.txt'"
Neb=500; nsweeps=0;
rec_rate=1e-4
rate_ben=0.5; s_backg_ben=0.005;
rate_del=8; s_backg_del=-0.05;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 7:
#Strong BACKGROUND SELECTION. HIGH PROPORTION BENEFICIAL SELECTION. No change Ne. No sweep.
FILEOUT="'./07_slim_SFS_BGS_PSH.txt'"
Neb=500; nsweeps=0;
rec_rate=1e-4
rate_ben=2; s_backg_ben=0.005;
rate_del=8; s_backg_del=-0.05;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

# CONDITION 8:
#Strong BACKGROUND SELECTION. BENEFICIAL SELECTION. No change Ne. SWEEPS.
FILEOUT="'./08_slim_SFS_BGS_PSM_SW.txt'"
Neb=500; nsweeps=10;
rec_rate=1e-4
rate_ben=0.5; s_backg_ben=0.005;
rate_del=8; s_backg_del=-0.05;

echo srun --ntasks 1 --exclusive --mem-per-cpu=1GB slim -t -m -d \"Ne=$Ne\" -d \"L=$L\" -d \"Neb=$Neb\" -d \"mut_rate=$mut_rate\" -d \"rec_rate=$rec_rate\" -d \"ngenes=$ngenes\" -d \"rate_ben=$rate_ben\" -d \"rate_del=$rate_del\" -d \"s_backg_ben=$s_backg_ben\" -d \"s_backg_del=$s_backg_del\" -d \"nsweeps=$nsweeps\" -d \"freq_sel_init=0.05\" -d \"freq_sel_end=0.95\" -d \"s_beneficial=0.1\" -d \"ind_sample_size=$ind_sample_size\" -d \"out_sample_size=$out_sample_size\" -d \"file_output1=$FILEOUT\" ./slim_template.slim\& >> ./run_slim_conditions.sh

echo wait >> ./run_slim_conditions.sh
```
The script runs in shell directly:

```
sh  ./run\_construct\_slim\_conditions.sh
```
This command creates a new script named "*run_slim_conditions.sh*".This file will be run in the cluster using slurm.
 
```
sbatch ./run\_slim\_conditions.sh
```
and check the progress with:

```
squeue
```
The results will be separated in nine different files, one for each simulation condition. The files will start with the name "[number]\_slim\_SFS\_\*.txt". You can see using the command *more*, *less*, *cat* or using a text editor such as *nano*.

The results will be the SFS of nonsynonymous and synonymous sites. The nine outputs will be similar to this:

```
SFS	fr1 	fr2 	fr3 	fr4 	fr5 	fr6 	fr7 	fr8 	fr9 	fr10 	fr11 	fr12 	fr13 	fr14 	fr15 	fr16 	fr17 	fr18 	fr19 	fr20 	fr21 	fr22 	fr23 	fr24 	fr25 	fr26 	fr27 	fr28 	fr29 	fr30 	fr31 	fr32 	fr33 	fr34 	fr35 	fr36 	fr37 	fr38 	fr39 	fr40 	fr41 	fr42 	fr43 	fr44 	fr45 	fr46 	fr47 	fr48 	fr49	PosP	Fixed	PosF	FixBen
nsyn	321	152	88	72	40	40	28	25	26	32	17	22	23	21	19	12	13	12	16	7	10	19	10	14	9	13	12	14	11	15	6	6	12	6	16	11	10	8	10	12	8	13	11	7	11	12	9	8	8	333333	2743	333333	1064
syn	263	116	79	78	71	35	32	25	42	23	21	20	12	19	15	18	16	11	16	20	12	15	19	7	9	17	6	11	10	7	9	8	10	10	8	2	7	12	12	6	9	4	8	7	6	6	5	5	6	166666	1552	166666	0	
```

## Estimating the proportion of Beneficial Substitutions (alpha) from Simulation Data

The estimation of alpha can be calculated with several methods. Here we will compare the real value of alpha (real alpha = fixed beneficial substitutions / fixed nonsynonymous substitutions) with other two estimates: the MKT standard alpha (alpha = 1 - Ks/Ps * Pn/Kn) and the asymptotic alpha ([Messer and Petrov 2013](https://www.pnas.org/doi/full/10.1073/pnas.1220835110)). Here you can find a web version of the asymptotic alpha estimation performed by [Haller and Messer](http://benhaller.com/messerlab/asymptoticMK.html). we will use a R code version performed by HAller and Messer ([Haller and Messer 2017](http://dx.doi.org/10.1534/g3.117.039693)) to estimate the alpha values.

### Estimate alpha using the SFS and Fixations

We will use R code for this step. The code contains some functions, the definition of arrays to keep the data, the calculation and the plot of the results and write the tables. 
There are two ways to run the R code:

1. The first one is just run the batch script _run\_Rresults.sh_, which contains the scripts for doing the analysis.
	```
	sbatch run_Rresults.sh
	```
	This script contains the two scripts used for the analysis:
	
	```
	\#!/bin/bash
	\#
	\#SBATCH --job-name=2runRplots
	\#SBATCH -o %j.out
	\#SBATCH -e %j.err
	\#SBATCH --ntasks=2
	\#SBATCH --mem=12GB
	\#SBATCH --partition=normal
	\#
	module load R
	module load r-mass r-proto
	
	srun --ntasks 1 --exclusive --mem-per-cpu=1GB R --vanilla < ./Results_plotMKT.R&
	srun --ntasks 1 --exclusive --mem-per-cpu=1GB R --vanilla < ./Results_plotMKT_Theta.R&
	wait
	
	```
	
2. In case the batch is not working, then we have to load few libraries to run the asymptotic approach:

	```
    module R
	module load r-mass r-proto
	```
	It is also necessary to install the library nls2. In this cluster, the easiest way is to open the R application and install the package manually and quit:
	
	```
	% R
	
	R version 4.0.3 (2020-10-10) -- "Bunny-Wunnies Freak Out"
	Copyright (C) 2020 The R Foundation for Statistical Computing
	...
	> install.packages("nls2")
	...
	> quit()
	```

The R code for estimating alpha (file _Results\_plotMKT.R_) is the following: 


```
source("./asymptoticMK_local.R")

############################################
# FUNCTIONS
############################################

#calculation of alpha from standard equation
calc.alpha <- function(Ps,Ds,Pn,Dn) {
  alpha <- 1 - (Ds/Dn)*(Pn/Ps)
  return(alpha)
} 
# D0,P0 are neutral, Di, Pi are functional
#define distribution of allele frequencies from smaller intervals (to avoid zeros)
calc2.daf <- function(tab.dat,nsam,intervals) {
  daf.red <- data.frame(daf=as.numeric(sprintf("%.3f",c(c(0:(intervals-1))/intervals,1))),Pi=0,P0=0)
  tab.dat <- rbind(tab.dat,c(0,0))
  for(i in c(1:intervals)) {
    daf.red$Pi[i] <- sum(tab.dat[(as.integer(daf.red$daf[i]*nsam)+1):(as.integer(daf.red$daf[i+1]*nsam)),1])
    daf.red$P0[i] <- sum(tab.dat[(as.integer(daf.red$daf[i]*nsam)+1):(as.integer(daf.red$daf[i+1]*nsam)),2])
  }
  daf.red <- daf.red[-(intervals+1),]
  return(daf.red)
}

```
There are first the functions to estimate alpha and estimate the SFS under less intervals than initially obtained (for nsam=25*2 there are 49 intervals, but many may be void if few variants are obtaied)

```
############################################
# DEFINITIONS
############################################

pdf("Plots_scenarios_alpha.pdf")
#define sample and size of sfs (to avoid zeros)
nsam <- 25*2
intervals <- 50
#read files from slim output
slim_files <- system("ls *_slim_SFS_*.txt",intern=T)
#Define data frame to keep results from SFS
Alpha.results <- array(0,dim=c(length(slim_files),6))
colnames(Alpha.results) <- c("scenario","alpha.real","alpha.mkt","alpha.assym","alphaAs.CIL","alphaAs.CIH")
Alpha.results <- as.data.frame(Alpha.results)

```
Just define some parameters and the arrys with data to keep.

```
############################
#RUN
############################
for(f in slim_files) {
  dat.sfs <- read.table(file=f,header=T,row.names=1)

  ############################
  # USING SFS
  ############################
  #calc daf and div
  tab.dat <- t(dat.sfs[,1:(nsam-1)])
  daf <- calc2.daf(tab.dat,nsam,intervals)
  #to avoid ZERO values, instead (or in addition) of doing less intervals, add 1 to freqs=0
  daf[daf[,2]==0,2] <- 1
  daf[daf[,3]==0,3] <- 1
  #calc div
  divergence <- data.frame(mi=dat.sfs[1,nsam+2],Di=dat.sfs[1,nsam+1],m0=dat.sfs[2,nsam+2],D0=dat.sfs[2,nsam+1])
  
  #estimate MKTa from SFS
  aa <- NULL
  tryCatch(
    {
      aa <- asymptoticMK(d0=divergence$D0, d=divergence$Di, xlow=0.1, xhigh=0.9, df=daf, true_alpha=NA, output="table")
    },
    error = function(e) {
      message(sprintf("Error calculating MKTa for observed data in file %s",f))
    }
  )
  aa
  aa$alpha_asymptotic
  aa$alpha_original
  true.alpha <- dat.sfs[1,nsam+3] / dat.sfs[1,nsam+1]
  true.alpha
  #calculate alpha for each frequency separately (assumed same nsam at Syn and Nsyn)
  alpha.mkt.daf <- calc.alpha(Ps=daf[,3],Ds=divergence[1,4],Pn=daf[,2],Dn=divergence[1,2])
  alpha.mkt.daf
  
  #Plot results
  plot(x=daf[,1],y=alpha.mkt.daf,type="p",pch=20,xlim=c(0,1),ylim=c(min(-1,alpha.mkt.daf),1),
       main=sprintf("ALPHA: %s \nTrue=%.3f MKTa=%.3f MKT=%.3f",f,true.alpha,aa$alpha_asymptotic,aa$alpha_original),
       xlab="Freq",ylab="alpha")
  abline(h=0,col="grey")
  abline(v=c(0.1,0.9),col="grey")
  abline(h=true.alpha,col="blue")
  if(aa$model=="linear") abline(a=aa$a,b=aa$b,col="red")
  if(aa$model=="exponential") {
    x=seq(1:19)/20
    lines(x=x,y=aa$a+aa$b*exp(-aa$c*x),type="l",col="red")
  }
  Alpha.results$scenario[i] <- f
  Alpha.results$alpha.real[i] <- true.alpha
  Alpha.results$alpha.mkt[i] <- aa$alpha_original
  Alpha.results$alpha.assym[i] <- aa$alpha_asymptotic
  Alpha.results$alphaAs.CIL[i] <- aa$CI_low
  Alpha.results$alphaAs.CIH[i] <- aa$CI_high
  
  i <- i + 1
}
dev.off()
write.table(x=Alpha.results,file="Alpha.results.txt",row.names=F,quote=F)

```
The code reads the data, includes SFS and divergence values in data frames and runs the the asymptotic function. The plots contain the true alpha, the MKT standard alpha and the asymptotic alpha for each condition. Also tables with results are kept for posterior comparison.

To run all from command line, do:

```
R --vanilla < ./Results_plotMKT.R
```

### Estimate alpha using the levels of Variability

Alpha estimates are not very accurated if few sections of the genome are used. A different approach can be to use summary statistics for the SFS, such as estimates of variability that weight differentially the contribution of each frequency. These estimators, like Fu & Li, Watterson, Tajima and Fay & Wu are good estimators of the real variability under the SNM, but under violations of the stationary model the estimators can give very different results. 

Fu & Li is based on singletons to estimate variability, Watterson on the number of polymorhic variants, Tajima on the pairwise number of differences, and Fay & Wu mainly weights high frequency variants. Using these four estimates, it is similar to obtain average values for sections of the SFS. This is the code for this approach:

```
source("./asymptoticMK_local.R")

############################################
# FUNCTIONS
############################################

#calculation of alpha from standard equation
calc.alpha <- function(Ps,Ds,Pn,Dn) {
  alpha <- 1 - (Ds/Dn)*(Pn/Ps)
  return(alpha)
} 
#calculation of different theta estimators
CalcThetaUnfolded <- function(sfs,w) {
  th <- 0
  for(i in 1:length(sfs)) {
    th <- th + w[i] * i * sfs[i]
  }
  th <- th/(sum(w))
  return(th)
}
#weights to estimate watterson estimate (based on the number of variants under SNM)
weight.watt.unfolded <-function(nsam) {
  w <- array(0,dim=c(floor(nsam-1)))
  for(i in 1:length(w)) {
    w[i] <- 1/i
  }
  w
}
#weights to estimate tajima (nucleotide diversity, PI) estimate
weight.taj.unfolded <-function(nsam) {
  w <- array(0,dim=c(floor(nsam-1)))
  for(i in 1:length(w)) {
    w[i] <- nsam-i
  }
  w
}
#weights to estimate fu&li estimate (singletons)
weight.fuli.unfolded <-function(nsam) {
  w <- array(0,dim=c(floor(nsam-1)))
  w[1] <- 1
  w
}
#weights to estimate fay&wu estimate (based on high frequencies)
weight.fw.unfolded <- function(nsam) {
  w <- array(0,dim=c(floor(nsam-1)))
  for(i in 1:length(w)) {
    w[i] <- i
  }
  w
}

############################################
# DEFINITIONS
############################################

pdf("Plots_scenarios_alpha_Theta.pdf")
#define sample and size of sfs (to avoid zeros)
nsam <- 25*2
#read files from slim output
slim_files <- system("ls *_slim_SFS_*.txt",intern=T)
#Define data frame to keep results from variability estimates
Theta.results <- array(0,dim=c(length(slim_files),9))
colnames(Theta.results) <- c("scenario","Theta.FuLi.Nsyn","Theta.FuLi.Syn",
                             "Theta.Watt.Nsyn","Theta.Watt.Syn",
                             "Theta.Taji.Nsyn","Theta.Taji.Syn",
                             "Theta.FayWu.Nsyn","Theta.FayWu.Syn")
Theta.results <- as.data.frame(Theta.results)

Alpha.theta.results <- array(0,dim=c(length(slim_files),6))
colnames(Alpha.theta.results) <- c("scenario","alpha.real","alpha.mkt","alpha.assym","alphaAs.CIL","alphaAs.CIH")
Alpha.theta.results <- as.data.frame(Alpha.theta.results)
```
Functions to estimate variability and definitions of arrays.

```
############################
#RUN
############################
i <- 1
#f <- slim_files[i]
for(f in slim_files) {
  dat.sfs <- read.table(file=f,header=T,row.names=1)
  #calc div
  divergence <- data.frame(mi=dat.sfs[1,nsam+2],Di=dat.sfs[1,nsam+1],m0=dat.sfs[2,nsam+2],D0=dat.sfs[2,nsam+1])

  #############################################
  #Estimation of alpha from theta estimators
  #############################################
  #Theta estimators are LIKE summary of sections of the SFS: 
  #It is useful for non-massive datasets
  #Fu&Li based on singletons
  #Watterson based on variants (mainly on variants at lower frequency)
  #Tajima weighting more on intermediate frequencies
  #Fay and Wu weighting more on higher frequencies
  
  #weights
  w.fuli <- weight.fuli.unfolded(nsam)
  w.watt <- weight.watt.unfolded(nsam)
  w.taj  <- weight.taj.unfolded(nsam)
  w.fayw <- weight.fw.unfolded(nsam)
  
  #Different Estimates of Variability;
  Theta.FuLi.Nsyn  <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[1,1:(nsam-1)]),w=w.fuli)
  Theta.FuLi.Syn   <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[2,1:(nsam-1)]),w=w.fuli)
  Theta.Watt.Nsyn  <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[1,1:(nsam-1)]),w=w.watt)
  Theta.Watt.Syn   <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[2,1:(nsam-1)]),w=w.watt)
  Theta.Taji.Nsyn  <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[1,1:(nsam-1)]),w=w.taj)
  Theta.Taji.Syn   <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[2,1:(nsam-1)]),w=w.taj)
  Theta.FayWu.Nsyn <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[1,1:(nsam-1)]),w=w.fayw)
  Theta.FayWu.Syn  <- CalcThetaUnfolded(sfs=as.numeric(dat.sfs[2,1:(nsam-1)]),w=w.fayw)
  
  #Estimates of standard alpha based on different estimates of variability
  alpha.mkt.FuLi <- calc.alpha(Ps=Theta.FuLi.Syn,Ds=divergence[1,4],Pn=Theta.FuLi.Nsyn,Dn=divergence[1,2])
  alpha.mkt.Watt <- calc.alpha(Ps=Theta.Watt.Syn,Ds=divergence[1,4],Pn=Theta.Watt.Nsyn,Dn=divergence[1,2])
  alpha.mkt.Taji <- calc.alpha(Ps=Theta.Taji.Syn,Ds=divergence[1,4],Pn=Theta.Taji.Nsyn,Dn=divergence[1,2])
  alpha.mkt.FayWu <- calc.alpha(Ps=Theta.FayWu.Syn,Ds=divergence[1,4],Pn=Theta.FayWu.Nsyn,Dn=divergence[1,2])
  
  #Assymptotic estimation APPROACH
  daf.theta <- array(0,dim=c(4,3))
  colnames(daf.theta)  <- c("daf","Pi","P0")
  #the variability estimates substitute the values on daf
  daf.theta[,2] <- sapply(c(Theta.FuLi.Nsyn,Theta.Watt.Nsyn,Theta.Taji.Nsyn,Theta.FayWu.Nsyn),round,4)
  daf.theta[,3] <- sapply(c(Theta.FuLi.Syn, Theta.Watt.Syn, Theta.Taji.Syn, Theta.FayWu.Syn ),round,4)
  daf.theta <- as.data.frame(daf.theta)
  #estimate mean frequency values for each estimate...
  daf.theta[1,1] <- 1/sum(w.fuli) * sum(w.fuli*c(1:(nsam-1))) * 1/nsam
  daf.theta[2,1] <- 1/sum(w.watt) * sum(w.watt*c(1:(nsam-1))) * 1/nsam
  daf.theta[3,1] <- 1/sum(w.taj)  * sum(w.taj *c(1:(nsam-1))) * 1/nsam
  daf.theta[4,1] <- 1/sum(w.fayw) * sum(w.fayw*c(1:(nsam-1))) * 1/nsam
  aa <- NULL
  tryCatch(
    {
      aa <- asymptoticMK(d0=divergence$D0, d=divergence$Di, xlow=0, xhigh=1, df=daf.theta, true_alpha=NA, output="table")
    },
    error = function(e) {
      message(sprintf("Error calculating MKTa for observed data in file %s",f))
    }
  )
  aa
  aa$alpha_asymptotic
  aa$alpha_original
  true.alpha <- dat.sfs[1,nsam+3] / dat.sfs[1,nsam+1]
  true.alpha
  alpha.mkt.daf.theta <- c(alpha.mkt.FuLi,alpha.mkt.Watt,alpha.mkt.Taji,alpha.mkt.FayWu)
  
  #PLOT results
  plot(x=daf.theta[,1],y=alpha.mkt.daf.theta,type="p",xlim=c(0,1),ylim=c(min(-1,alpha.mkt.daf.theta),1),
       main=sprintf("ALPHA from Theta: %s \nTrue=%.3f MKTa=%.3f MKT=%.3f",f,true.alpha,aa$alpha_asymptotic,aa$alpha_original),
       xlab="Freq",ylab="alpha")
  abline(h=0,col="grey")
  abline(v=c(0,1),col="grey")
  abline(h=true.alpha,col="blue")
  if(aa$model=="linear") abline(a=aa$a,b=aa$b,col="red")
  if(aa$model=="exponential") {
    x=seq(1:19)/20
    lines(x=x,y=aa$a+aa$b*exp(-aa$c*x),type="l",col="red")
  }
  
  Theta.results$scenario[i] <- f
  Theta.results$Theta.FuLi.Nsyn[i]  <- Theta.FuLi.Nsyn
  Theta.results$Theta.FuLi.Syn[i]   <- Theta.FuLi.Syn
  Theta.results$Theta.Watt.Nsyn[i]  <- Theta.Watt.Nsyn
  Theta.results$Theta.Watt.Syn[i]   <- Theta.Watt.Syn
  Theta.results$Theta.Taji.Nsyn[i]  <- Theta.Taji.Nsyn
  Theta.results$Theta.Taji.Syn[i]   <- Theta.Taji.Syn
  Theta.results$Theta.FayWu.Nsyn[i] <- Theta.FayWu.Nsyn
  Theta.results$Theta.FayWu.Syn[i]  <- Theta.FayWu.Syn
  
  Alpha.theta.results$scenario[i] <- f
  Alpha.theta.results$alpha.real[i] <- true.alpha
  Alpha.theta.results$alpha.mkt[i] <- aa$alpha_original
  Alpha.theta.results$alpha.assym[i] <- aa$alpha_asymptotic
  Alpha.theta.results$alphaAs.CIL[i] <- aa$CI_low
  Alpha.theta.results$alphaAs.CIH[i] <- aa$CI_high

  i <- i + 1
}
dev.off()
write.table(x=Theta.results,file="Theta.results.txt",row.names=F,quote=F)
write.table(x=Alpha.theta.results,file="Alpha.theta.results.txt",row.names=F,quote=F)
```
Calculation of variability for each estimator in _Nonsynonymous and Synonymous positions. Estimation of alphas and keep results.


To run all from command line, do:

```
R --vanilla < ./Results_plotMKT_Theta.R
```

## Comparison of Results

Make a Table with all results to compare the methods used and their approach to the true value. Discuss the results.

