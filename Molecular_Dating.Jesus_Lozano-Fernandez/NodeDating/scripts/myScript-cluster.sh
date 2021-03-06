#!/bin/bash                                                                                                             

#SBATCH -p normal                                                                                                       
#SBATCH -n 8                                                                                                            
#SBATCH -c 1                                                                                                            
#SBATCH --mem=6GB                                                                                                       
#SBATCH --job-name NodeDating-job01                                                                           \        
#SBATCH -o %j.out                                                                                                       
#SBATCH -e %j.err                                                                                                       

module load revbayes

mpirun -np 8 rb-mpi MCMC_dating_ex3.Rev
