// qiime2 import
nextflow.enable.dsl=2

params.reads = "/home/rmadzime/qiime_workflow/import.csv"
params.outdir = "results"
params.readslearn = 200000
params.threads = 24
params.classify_threads = 1
params.mapfile = "$projectDir/map_file1.tsv"
params.classifier = "$projectDir/ref/silva-138-99-515-806-nb-classifier.qza"
params.metric = 'euclidean'
params.colour = 'hot_r'
params.meta_column = 'Description'
params.beta_column = 'Code'
params.dendrogram_color = 'seismic'


log.info"""\
	Q I I M E 2 - N F
	=================
	reads: ${params.reads}
	outdir: ${params.outdir}
	"""
	.stripIndent()

reads_ch = Channel.fromPath(params.reads)

/*process CREATE_IMPORT {

	label 'small_threads'

	input:
	path sequences

	output:
	path 'import.csv',	emit: input_file

	script:
	"""
	create_script.sh ${sequences}
	"""
}*/

process IMPORT {

	label 'small_threads'

	publishDir "${params.outdir}/data", mode: 'copy'

	input:
	path reads_file

	output:
	path '*.qza',	emit: import_data
	
	script:
	"""
	qiime tools import \
		--type SampleData[PairedEndSequencesWithQuality] \
		--input-path ${reads_file} \
		--input-format PairedEndFastqManifestPhred33 \
		--output-path data.qza
	"""
}


process QUALITY_CHECK {

	label 'small_threads'

	publishDir "${params.outdir}/visualisations", mode: 'copy'

	input:
	path data

	output:
	path '*.qzv',							emit: import_vis
	path 'temp_quality/*/data/forward-seven-number-summaries.tsv',	emit: forward_reads
	path 'temp_quality/*/data/reverse-seven-number-summaries.tsv',	emit: reverse_reads

	script:
	"""
	qiime demux summarize \
		--i-data ${data} \
		--o-visualization data.qzv

	unzip data.qzv -d temp_quality
	"""
}


process DENOISE {

	label 'big_threads'

	publishDir "${params.outdir}/dada", mode: 'copy'

	input:
	path forward
	path reverse
	path data

	output:
	path 'table*',	emit: dada_table
	path 'rep*',	emit: rep_sequences
	path 'dada*',	emit: dada_stats

	script:
	"""
	trim_forward=(`seq_trim.R ${forward}`)
	trim_reverse=(`seq_trim.R ${reverse}`)	

	qiime dada2 denoise-paired \
                --i-demultiplexed-seqs ${data} \
                --o-table table_withSINGLETONS.qza \
                --o-representative-sequences rep_seq_withSINGLETONS.qza \
                --p-trim-left-f \${trim_forward[1]} \
                --p-trim-left-r \${trim_reverse[1]} \
                --p-trunc-len-f \${trim_forward[2]} \
                --p-trunc-len-r \${trim_reverse[2]} \
                --p-n-threads ${params.threads} \
                --o-denoising-stats dada_stats \
                --p-n-reads-learn ${params.readslearn}
	"""
}

//Tables and filtering singletons

process FILTER_FEATURES {

	label 'small_threads'

	publishDir "${params.outdir}/tables", mode: 'copy'

	input:
	path table

	output:
	path '*qza',	emit: filtered_table

	script:
	"""
	qiime feature-table filter-features \
		--i-table ${table} \
		--p-min-frequency 3 \
		--o-filtered-table table.qza
	"""
}

process FILTER_SEQS {

	label 'small_threads'

	publishDir "${params.outdir}/tables", mode: 'copy'

	input:
	path rep
	path table

	output:
	path '*.qza',	emit: filtered_rep

	script:
	"""
	qiime feature-table filter-seqs \
		--i-data ${rep} \
		--i-table ${table} \
		--o-filtered-data rep_seq_d2.qza
	"""
}

//Table summary

process TABLE_VIEW {

	label 'min_threads'

	publishDir "${params.outdir}/visualisations", mode: 'copy'

	input:
	path table

	output:
	path '*.qzv',	emit: table_vis

	script:
	"""
	qiime feature-table summarize \
		--i-table ${table} \
		--m-sample-metadata-file ${params.mapfile} \
		--o-visualization table.qzv
	"""
}

process SINGLETONS_VIEW {

	label 'min_threads'

	publishDir "${params.outdir}/visualisations", mode: 'copy'

	input:
	path table

	output:
	path '*.qzv',	emit: rep_seq_vis

	script:
	"""
	qiime feature-table summarize \
		--i-table ${table} \
		--m-sample-metadata-file ${params.mapfile} \
		--o-visualization table_withSINGLETONS.qzv
	"""
}

//FeatureData[Sequence] Summary

process REP_SEQS_VIEW {

	label 'min_threads'

	publishDir "${params.outdir}/visualisations", mode: 'copy'

	input:
	path rep

	output:
	path '*.qzv',	emit: rep_view

	script:
	"""
	qiime feature-table tabulate-seqs \
		--i-data ${rep} \
		--o-visualization rep_seqs.qzv
	"""
}

//Dada Stats visualization

process STATS_VIEW {

	label 'min_threads'

	publishDir "${params.outdir}/visualisations", mode: 'copy'

	input:
	path dada

	output:
	path '*.qzv',	emit: stats

	script:
	"""
	qiime metadata tabulate \
		--m-input-file ${dada} \
		--o-visualization denoising_stats.qzv
	"""
} 

//Trees
//Start with multiple sequence alignment

process ALIGNMENT {

	label 'small_threads'

	publishDir "${params.outdir}/trees", mode: 'copy'

	input:
	path rep

	output:
	path '*.qza',	emit: align_rep

	script:
	"""
	qiime alignment mafft \
		--i-sequences ${rep} \
		--o-alignment aln_rep_seqs.qza
	"""
}

//Masking sites

process ALIGNMENT_MASK {

	label 'small_threads'

	publishDir "${params.outdir}/trees", mode: 'copy'

	input:
	path aln

	output:
	path '*.qza',	emit: masked_aln

	script:
	"""
	qiime alignment mask \
		--i-alignment ${aln} \
		--o-masked-alignment masked_aln_rep_seq.qza
	"""
}

//Creating unrooted tree

process FASTTREE {

	label 'small_threads'

	publishDir "${params.outdir}/trees", mode: 'copy'

	input:
	path mask

	output:
	path '*.qza',	emit: unrooted

	script:
	"""
	qiime phylogeny fasttree \
		--i-alignment ${mask} \
		--p-n-threads ${params.threads} \
		--o-tree unrooted_tree.qza
	"""
}

//Mid-point rooting

process MIDPOINT_ROOTING {

	label 'small_threads'

	publishDir "${params.outdir}/tree", mode: 'copy'

	input:
	path tree

	output:
	path '*.qza',	emit: rooted

	script:
	"""
	qiime phylogeny midpoint-root \
		--i-tree ${tree} \
		--o-rooted-tree rooted_tree.qza
	"""
}

//Taxonomy - SILVA

process FEATURE_CLASSIFIER {

	label 'big_threads'

	publishDir "${params.outdir}/taxonomy", mode: 'copy'

	input:
	path rep

	output:
	path '*.qza',	emit: taxonomy

	script:
	"""
	qiime feature-classifier classify-sklearn \
		--i-classifier ${params.classifier} \
		--i-reads ${rep} \
		--p-n-jobs ${params.classify_threads} \
		--o-classification taxonomy.qza
	"""
}

//Taxonomy visualization

process TAXA_VIEW {

	label 'small_threads'

	publishDir "${params.outdir}/taxonomy", mode: 'copy'

	input:
	path taxa

	output:
	path '*.qzv',	emit: taxa_vis

	script:
	"""
	qiime metadata tabulate --m-input-file ${taxa} \
				--o-visualization taxonomy.qzv
	"""
}

process COLLAPSE_TAX {

	label 'big_threads'

	publishDir "${params.outdir}/taxa_view", mode: 'copy'

	input:
	path table
	path taxa
	
	output:
	path '*.qza',	emit: table_collapsed
	path '*.qzv',	emit: table_view
	path '*.qzv',	emit: heatmap

	script:
	"""
	for y in {2..6}
	do
		qiime taxa collapse --i-table ${table} \
				    --i-taxonomy ${taxa} \
				    --p-level \${y} \
				    --o-collapsed-table table_L\${y}.qza
		
		qiime feature-table summarize \
			--i-table table_L\${y}.qza \
			--m-sample-metadata-file ${params.mapfile} \
			--o-visualization table_L\${y}.qzv

		qiime feature-table heatmap \
			--i-table table_L\${y}.qza \
			--m-sample-metadata-file ${params.mapfile} \
			--m-sample-metadata-column ${params.meta_column} \
			--p-metric ${params.metric} \
			--p-color-scheme ${params.colour} \
			--o-visualization heatmap_L\${y}.qzv
	done
	"""
}

//Barplots

process BARPLOT {

	label 'small_threads'

	publishDir "${params.outdir}/barplots", mode: 'copy'

	input:
	path table
	path taxa

	output:
	path '*.qzv', emit: barplot

	script:
	"""
	qiime taxa barplot \
		--i-table ${table} \
		--i-taxonomy ${taxa} \
		--m-metadata-file ${params.mapfile} \
		--o-visualization taxa_barplots.qzv
	"""
}

//Alpha Rarefaction plotting

process ALPHA_RAREFACTION {

	label 'small_threads'

	publishDir "${params.outdir}/alpha_rare", mode: 'copy'

	input:
	path table_view
	path table
	path tree

	output:
	path '*.qzv',	emit: rarefaction

	script:
	"""
	depth=`parse_depth.py ${table_view}`

	qiime diversity alpha-rarefaction \
		--i-table ${table} \
		--i-phylogeny ${tree} \
		--p-max-depth \${depth} \
		--m-metadata-file ${params.mapfile} \
		--o-visualization alpha_rarefaction.qzv
	"""
}

//Generating diversity core-metrics

process CORE_METRICS {

	label 'big_threads'

	publishDir "${params.outdir}/core-metrics-results", mode: 'copy'

	input:
	path table_view
	path tree
	path table

	output:
	path 'core-metrics-results/faith_pd_vector*',				emit: faith
	path 'core-metrics-results/unweighted_unifrac_distance_matrix*',	emit: unweighted_unifrac_distance
	path 'core-metrics-results/bray_curtis_pcoa_results*',			emit: bray_curtis_pcoa
	path 'core-metrics-results/shannon_vector*',				emit: shannon
	path 'core-metrics-results/rarefied_table*',				emit: rarefied
	path 'core-metrics-results/weighted_unifrac_distance_matrix*',		emit: weighted_unifrac_distance
	path 'core-metrics-results/jaccard_pcoa_results*',			emit: jaccard_pcoa
	path 'core-metrics-results/weighted_unifrac_pcoa_results*',		emit: weighted_unifrac_pcoa
	path 'core-metrics-results/observed_features_vector*',			emit: observed_features
	path 'core-metrics-results/jaccard_distance_matrix*',			emit: jaccard_distance
	path 'core-metrics-results/evenness_vector*',				emit: evenness
	path 'core-metrics-results/bray_curtis_distance_matrix*',		emit: bray_curtis_distance
	path 'core-metrics-results/unweighted_unifrac_pcoa_results*',		emit: unweighted_unifrac_pcoa
	path 'core-metrics-results/unweighted_unifrac_emperor*',		emit: unweighted_unifrac_emperor
	path 'core-metrics-results/jaccard_emperor*',				emit: jaccard_emperor
	path 'core-metrics-results/bray_curtis_emperor*',			emit: bray_curtis_emperor
	path 'core-metrics-results/weighted_unifrac_pcoa_results*',		emit: weighted_unifrac_pcoa_vis

	script:
	"""
	depth=`parse_depth.py ${table_view}`

	qiime diversity core-metrics-phylogenetic \
		--i-phylogeny ${tree} \
		--i-table ${table} \
		--p-sampling-depth \${depth} \
		--m-metadata-file ${params.mapfile} \
		--output-dir core-metrics-results
	"""
}

//Alpha diversity calculations and visualizations

process ALPHA_DIVERSITY {

	label 'big_threads'

	publishDir "${params.outdir}/alpha_diversity", mode: 'copy'

	input:
	path faithvector
	path evenness

	output:
	path '*.qzv',	emit: faith_significance
	path '*.qzv',	emit: evenness_significance
	path '*.qzv',	emit: shannon_significance
	path '*.qzv',	emit: observed_significance

	script:
	"""	
	qiime diversity alpha-group-significance \
		--i-alpha-diversity ${faithvector} \
		--m-metadata-file ${params.mapfile} \
		--o-visualization faith_pd_group_significance.qzv

	qiime diversity alpha-group-significance \
		--i-alpha-diversity ${evenness} \
		--m-metadata-file ${params.mapfile} \
		--o-visualization evenness_group_significance.qzv
	"""	
}

//Beta Diversity Visualizations

/*process BETA_DIVERSITY {

	label 'big_threads'

	publishDir "${params.outdir}/beta_diversity", mode: 'copy'

	input:
	path unweightedunifrac

	output:
	path '*.qzv',	emit: unweighted_significance
	path '*.qzv',	emit: weighted_significance
	path '*.qzv',	emit: jaccard_significance
	path '*.qzv',	emit: bray_significance

	script:
	"""
	qiime diversity beta-group-significance \
		--i-distance-matrix ${unweightedunifrac} \
		--m-metadata-file ${params.mapfile} \
		--m-metadata-column ${params.beta_column} \
		--o-visualization unweighted_unifrac_significance.qzv
	"""
}*/ 

//Differential Abundance Analysis

process GNEISS_CLUSTERING{ 

	label 'small_threads'

	publishDir "${params.outdir}/gneiss", mode: 'copy'

	input:
	path table

	output:
	path '*.qza',	emit: hierarchy

	script:
	"""
	qiime gneiss correlation-clustering \
		--i-table ${table} \
		--o-clustering hierarchy.qza
	"""
}

process DENDROGRAM_HEATMAP{

	label 'big_threads'

	publishDir "${params.outdir}/gneiss", mode: 'copy'

	input:
	path table
	path tree

	output:
	path '*.qzv', emit: clustered_heatmaps

	script:
	"""
	
	qiime gneiss dendrogram-heatmap \
		--i-table ${table} \
		--i-tree ${tree} \
		--m-metadata-file ${params.mapfile} \
		--m-metadata-column ${params.meta_column} \
		--p-color-map ${params.dendrogram_color} \
		--o-visualization heatmap_${params.meta_column}.qzv
	"""
} 
		
	

workflow {
	//CREATE_IMPORT(reads_ch)
	//IMPORT(CREATE_IMPORT.out.input_file)
	IMPORT(reads_ch)
	QUALITY_CHECK(IMPORT.out.import_data)
	DENOISE(QUALITY_CHECK.out.forward_reads, QUALITY_CHECK.out.reverse_reads, IMPORT.out.import_data)
	FILTER_FEATURES(DENOISE.out.dada_table)
	FILTER_SEQS(DENOISE.out.rep_sequences, FILTER_FEATURES.out.filtered_table)
	TABLE_VIEW(FILTER_FEATURES.out.filtered_table)
	SINGLETONS_VIEW(DENOISE.out.dada_table)
	REP_SEQS_VIEW(DENOISE.out.rep_sequences)
	STATS_VIEW(DENOISE.out.dada_stats)
	ALIGNMENT(FILTER_SEQS.out.filtered_rep)
	ALIGNMENT_MASK(ALIGNMENT.out.align_rep)
	FASTTREE(ALIGNMENT_MASK.out.masked_aln)
	MIDPOINT_ROOTING(FASTTREE.out.unrooted)
	FEATURE_CLASSIFIER(FILTER_SEQS.out.filtered_rep)
	TAXA_VIEW(FEATURE_CLASSIFIER.out.taxonomy)
	COLLAPSE_TAX(FILTER_FEATURES.out.filtered_table, FEATURE_CLASSIFIER.out.taxonomy)
	BARPLOT(FILTER_FEATURES.out.filtered_table, FEATURE_CLASSIFIER.out.taxonomy)
	ALPHA_RAREFACTION(TABLE_VIEW.out.table_vis, FILTER_FEATURES.out.filtered_table, MIDPOINT_ROOTING.out.rooted)
	CORE_METRICS(TABLE_VIEW.out.table_vis, MIDPOINT_ROOTING.out.rooted, FILTER_FEATURES.out.filtered_table)
	ALPHA_DIVERSITY(CORE_METRICS.out.faith, CORE_METRICS.out.evenness)
	//BETA_DIVERSITY(CORE_METRICS.out.unweighted_unifrac_distance)
	GNEISS_CLUSTERING(FILTER_FEATURES.out.filtered_table)
	DENDROGRAM_HEATMAP(FILTER_FEATURES.out.filtered_table, GNEISS_CLUSTERING.out.hierarchy)
} 


