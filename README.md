# Amplicon-sequence-pipeline

This is a pipeline for analysing amplicon sequence data. The pipeline implements the full workflow of qiime2.
The pipeline uses a Singularity container to provide the qiime2 software and is launched using Nextflow.

# Running the pipeline

The pipeline can run on Unix/Linux based clusters and servers. To run the pipeline use the following command:

`nextflow run qiime2.nf`

Options:

`-c` [REQUIRED] configuration file. This project provides a file with configuration for use on a server and a cluster hosting a pbspro scheduler

`-profile` [REQUIRED] the profile to use for analysis, can either be server or cluster

`--reads` [REQUIRED] path to the input file, a comma delimited file

`--readslearn` [OPTIONAL] parameter for DADA2 plugin. Default 200000

`--threads` [OPTIONAL] threading parameter for DADA2, default is 24

`--mapfile` [REQUIRED] path to a tab delimited metadata file. Please note that the metadata file should meet the requirements of qiime2 metadata files

`--classifier` [REQUIRED] path to the taxonomy classifier. Ensure that the version of scickitlearn used to train the classifier is compatible with the version
of scickitlearn used for analysis

`--metric` [OPTIONAL] parameter for heatmap appearance, default is euclidean

`--colour` [OPTIONAL] parameter for heatmap, default hot_r

`--meta_column` [REQUIRED] categorical metadata column to be used for alpha diversity, beta diversity and gneiss heatmap analysis

`--dendrogram_color` [OPTIONAL] dendrogram heatmap colours, default seismic

`--outdir` [OPTIONAL] the directory to save output, default name is results

# Requirements for running pipeline

Nextflow version 21 or higher

Singularity version 3.5 or higher

# Input

A comma delimited file is used to point the absolute path of the raw reads. At present, the pipeline processes paired-end data.

# Output

Pipeline output will be saved in a directory named <results> in the current working directory. Output files are in `.qza` and `.qzv` format. Tables and figures are in .qzv format. To view the files, move them to
your laptop or desktop and use the qiime viewer to look at and interact with the visualizations.

# Software available in container

The Singularity container runs qiime2-2022.8.3. The definition file specifies how the container was developed.

