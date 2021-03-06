# momi2: Demographic inference from the multidimensional SFS

We are going to learn how to use momi2 (Kamm et al. 2020), a powerful and versatile method to infer demographic parameters from multiple, related populations. The proposed exercises will guide you through key theoretical concepts and crucial practicalities, but an extensive momi2 tutorial is also available online: 

https://momi2.readthedocs.io/en/latest/tutorial.html

momi2 runs in Python, and is installed in the server. It needs high-quality SNP calls from a single or multiple populations. The toy example for this session is a VCF file consisting of human populations from the Simons Genome Diversity Project (~30x), as well as a Neandertal individual and the chimpanzee as outgroup species. 

# Step 1: Calculating the multiSFS from a VCF file 
Momi2 provides all the scripts required for calculating the multidimensional Site Frequency Spectrum from a given VCF file (input4momi2.vcf). This requires two steps. First, type:

    python -m momi.read_vcf --outgroup Nigerian input4momi2.vcf input4momi2.list momi2.step1.gz

Do not worry about the warning. Note that the VCF file is uncompressed here, and the input4momi2.list file associates each individual with a population. Then:

    python -m momi.extract_sfs momi2.step2.gz 10 momi2.step1.gz

The second parameter, 10, indicates that the multiSFS will be split into 10 equally-sized blocks, which will be ultimately used to calculate the uncertainty around the ML estimates. Check and discuss the output file momi2.step2.gz.

# Case 1: four Eurasian populations, WITHOUT admixture
As starting example, we will use four specimens from four different populations, namely a French and a British from Europe, and a Japanese and a Chinese from Asia. Our aim here is to estimate the split between Asia and European populations.  The VCF file only included chromosome 1.

In the server, type "python" to enter Python console. Then, one-by-one, copy-paste the following commands into this console:

    import momi #load the corresponding modules
	import logging
	logging.basicConfig(level=logging.INFO,filename="momi2_Eurasian.log") #specify file for log
	sfs = momi.Sfs.load("momi2.step2.gz") #read the multiSFS file
	no_pulse_model = momi.DemographicModel(N_e=12000, gen_time=29, muts_per_gen=1e-8) #specify the human generation time and the mutation rate
	no_pulse_model.set_data(sfs,length=248956422) #length of chromosome 1

These commands read the data and define very general features of the model such as the generation time and the recombination rate.  To specify the tree underlying these four populations, first add the leaves:

    no_pulse_model.add_leaf("French",N="N_FRE")
    no_pulse_model.add_leaf("English",N="N_ENG")
    no_pulse_model.add_leaf("Japanese", N="N_JAP")
    no_pulse_model.add_leaf("Chinese", N="N_CHI")

define their (suspected) underlying evolutionary relationship:

    no_pulse_model.move_lineages("French", "English", t="t_FRE_ENG", N="N_FRE_ENG")
    no_pulse_model.move_lineages("Japanese", "Chinese", t="t_JAP_CHI", N="N_JAP_CHI")
    no_pulse_model.move_lineages("English", "Chinese", t="t_ASIA_EUROPE", N="N_ASIA_EUROPE")

Note that moving the French into the English lineage makes their common ancestor to be named English as well. If we had moved the English into the French lineage, the ancestor would be called French. This defines the following tree:

![image info](case1.tree.png)

Do not forget to supply an initial guess for each underlying parameter. Realistic starting values can help optimisation:

	no_pulse_model.add_time_param("t_FRE_ENG", 5000)
	no_pulse_model.add_time_param("t_JAP_CHI", 5000)
	no_pulse_model.add_time_param("t_ASIA_EUROPE", 40000)
	no_pulse_model.add_size_param("N_FRE",10000)
	no_pulse_model.add_size_param("N_ENG",10000)
	no_pulse_model.add_size_param("N_JAP",10000)
	no_pulse_model.add_size_param("N_CHI",5000)
	no_pulse_model.add_size_param("N_FRE_ENG",10000)
	no_pulse_model.add_size_param("N_JAP_CHI",10000)
	no_pulse_model.add_size_param("N_ASIA_EUROPE",10000)

where the values after the comma represent the starting guess for each parameter.

	results = []
	no_pulse_model_copy = no_pulse_model.copy()
	no_pulse_model_copy.set_params(no_pulse_model.get_params(),randomize=True)
	results.append(no_pulse_model_copy.optimize(method="TNC",options={"maxiter":5000, "ftol":1e-8}))

Ideally this could be run multiple times with different starting values, to ensure that the optimisation algorithm (TNC) did not get trapped into a local maximum. Keep in mind the likelihood value. We can see the inferred parameters by typing "results", but it would be nicer to have a graphical representation by:

    yticks = [100, 1000, 50000]
    fig = momi.DemographyPlot(no_pulse_model_copy,["French","English","Chinese","Japanese"],linthreshy=5000, figsize=(6,8),major_yticks=yticks)
    import matplotlib.backends.backend_pdf
    pdf = matplotlib.backends.backend_pdf.PdfPages("momi2.case1.pdf")
    pdf.savefig(fig.draw())
    pdf.close()

 Interestingly, European and Asian populations are inferred to have split ~50kya, well in line with the literature. But why French and English are so close? May it be they are actually the same population? Or the age of their split node is underestimated owing to secondary gene flow between both populations? 

# Case 2: four Eurasian populations, WITH admixture

The following momi2 script mostly mirrors Case 1, but also models introgression from English to French population:

    import momi #load the corresponding modules
    import logging
    sfs = momi.Sfs.load("momi2.step2.gz") #read the multiSFS file
    pulse_model = momi.DemographicModel(N_e=12000, gen_time=29, muts_per_gen=1e-8) #specify the human generation time and the mutation rate
    pulse_model.set_data(sfs,length=248956422) #length of chromosome 1
    
	#add leaves
	pulse_model.add_leaf("French",N="N_FRE")
	pulse_model.add_leaf("English",N="N_ENG")
	pulse_model.add_leaf("Japanese", N="N_JAP")
	pulse_model.add_leaf("Chinese", N="N_CHI")
	
	#see the extra line here (bold) to model the introgression from English into French populations, t_ENG2FRE years ago in a proportion of p_ENG2FRE (two mire parameters to be estimated)
    pulse_model.move_lineages("French", "English", t="t_ENG2FRE", p="p_ENG2FRE")
	pulse_model.move_lineages("French", "English", t="t_FRE_ENG", N="N_FRE_ENG")
    pulse_model.move_lineages("Japanese", "Chinese", t="t_JAP_CHI", N="N_JAP_CHI")
    pulse_model.move_lineages("English", "Chinese", t="t_ASIA_EUROPE", N="N_ASIA_EUROPE")
    
    #define parameters

    pulse_model.add_time_param("t_FRE_ENG", 5000)
    pulse_model.add_time_param("t_JAP_CHI", 5000)
    pulse_model.add_time_param("t_ASIA_EUROPE", 40000)
    pulse_model.add_size_param("N_FRE",10000)
    pulse_model.add_size_param("N_ENG",10000)
    pulse_model.add_size_param("N_JAP",10000)
    pulse_model.add_size_param("N_CHI",5000)
    pulse_model.add_size_param("N_FRE_ENG",10000)
    pulse_model.add_size_param("N_JAP_CHI",10000)
    pulse_model.add_size_param("N_ASIA_EUROPE",10000)
    pulse_model.add_time_param("t_ENG2FRE", upper_constraints=['t_FRE_ENG']) # the admixture from English to French must have happened after the split of the two populations
	pulse_model.add_pulse_param("p_ENG2FRE",0.01) #initial value for the admixture proportion
	
    #optimization
    results = []
    pulse_model_copy = pulse_model.copy()
    pulse_model_copy.set_params(pulse_model.get_params(),randomize=True)
    results.append(pulse_model_copy.optimize(method="TNC",options={"maxiter":5000, "ftol":1e-8}))

Type "results" again, and see the likelihood. Does it improve much the previous one? Actually, the split node between the French and the English individuals remains very close. Should we invert the directionality of gene flow?   

    yticks = [100, 1000, 50000]
    fig = momi.DemographyPlot(pulse_model_copy,["French","English","Chinese","Japanese"],linthreshy=5000, figsize=(6,8),major_yticks=yticks)
	import matplotlib.backends.backend_pdf
    pdf =matplotlib.backends.backend_pdf.PdfPages("momi2.case2.pdf")
    pdf.savefig(fig.draw())
    pdf.close()
    

# Case 3: Characterising the uncertainty around the estimates
The information encoded within the multiSFS is limited, especially considering that we are dealing with small data set with a single chromosome and a single individual per population. We may well simply lack power to infer the correct parameters. Can we estimate the uncertainty around the ML estimates? YES, through bootstrap pseudo-replicates:


	import momi 
	import logging
	logging.basicConfig(level=logging.INFO,filename="momi2_Eurasian.log") 
	sfs = momi.Sfs.load("momi2.step2.gz") 
	no_pulse_model = momi.DemographicModel(N_e=12000, gen_time=29, muts_per_gen=1e-8) #specify the human generation time and the mutation rate
	no_pulse_model.set_data(sfs,length=248956422)
	
    no_pulse_model.add_leaf("French",N="N_FRE")
    no_pulse_model.add_leaf("English",N="N_ENG")
    no_pulse_model.add_leaf("Japanese", N="N_JAP")
    no_pulse_model.add_leaf("Chinese", N="N_CHI")
    no_pulse_model.move_lineages("French", "English", t="t_FRE_ENG", N="N_FRE_ENG")
    no_pulse_model.move_lineages("Japanese", "Chinese", t="t_JAP_CHI", N="N_JAP_CHI")
    no_pulse_model.move_lineages("English", "Chinese", t="t_ASIA_EUROPE", N="N_ASIA_EUROPE")
    
    no_pulse_model.add_time_param("t_ASIA_EUROPE", 40000)
	no_pulse_model.add_time_param("t_FRE_ENG", 5000,upper_constraints=['t_ASIA_EUROPE'])
	no_pulse_model.add_time_param("t_JAP_CHI", 5000,upper_constraints=['t_ASIA_EUROPE'])
	no_pulse_model.add_size_param("N_FRE",10000)
	no_pulse_model.add_size_param("N_ENG",10000)
	no_pulse_model.add_size_param("N_JAP",10000)
	no_pulse_model.add_size_param("N_CHI",5000)
	no_pulse_model.add_size_param("N_FRE_ENG",10000)
	no_pulse_model.add_size_param("N_JAP_CHI",10000)
	no_pulse_model.add_size_param("N_ASIA_EUROPE",10000)
	results = []
	no_pulse_model_copy = no_pulse_model.copy()
	no_pulse_model_copy.set_params(no_pulse_model.get_params(),randomize=True)
	results.append(no_pulse_model_copy.optimize(method="TNC",options={"maxiter":5000, "ftol":1e-8}))
And now we run the bootstraps: 
	
	n_bootstraps = 10
	no_pulse_copy = no_pulse_model.copy()
	bootstrap_results = []
	for i in range(n_bootstraps):
	    resampled_sfs = sfs.resample()
	    no_pulse_copy.set_data(resampled_sfs,length=248956422)
	    no_pulse_copy.set_params(randomize=True)
	    no_pulse_copy.optimize()
	    bootstrap_results.append(no_pulse_copy.get_params())

We can also plot the bootstraps:

    yticks = [100, 1000, 50000]
    fig = momi.DemographyPlot(no_pulse_model_copy,["French","English","Chinese","Japanese"],linthreshy=5000, figsize=(6,8),major_yticks=yticks)
    for params in bootstrap_results:
	    fig.add_bootstrap(params,alpha=1/n_bootstraps)
    import matplotlib.backends.backend_pdf
    pdf=matplotlib.backends.backend_pdf.PdfPages("momi2.case3.pdf")
    pdf.savefig(fig.draw())
    pdf.close()

I like to finish with this one, because it shows that even the most sophisticated methods may fail to provide robust estimate, if the data is not informative enough. Be careful with point estimations, even obtained through ML. There may be a huge uncertainty around them.
  
# Questions and/or suggestions?
Write me an email to plibradosanz@gmail.com

