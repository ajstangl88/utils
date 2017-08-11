#!/usr/bin/env bash

myfile="/mnt/user_data/astangl/new_CompareCoverage/runit4.txt"
outdir="/mnt/user_data/astangl/new_CompareCoverage"
cut -f 1,4,3,6 $myfile | sort | uniq | perl -ne '@x=split(/\s+/);print "echo \"$x[0] $x[1] $x[2] $x[3]\";perl compareChanges_Plasma --oldfile=$x[0]/$x[1].CNA.txt --newfile=$x[2]/$x[3].CNA.txt --uniqcol=\"Lookup ID\" --oldversion=plasma-3.4.0b4 --newversion=Plasma_RearrangementsThresholds-3.5.0b5 --printsummary --outdir=/mnt/user_data/astangl/new_CompareCoverage/CNA_comparison --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\"\n"' | bash;
cut -f 1,4,3,6 $myfile | sort | uniq | perl -ne '@x=split(/\s+/);print "echo \"$x[0] $x[1] $x[2] $x[3]\";perl compareChanges_Plasma --oldfile=$x[0]/cna/$x[1].allcna.txt --newfile=$x[2]/cna/$x[3].allcna.txt --uniqcol=\"Lookup ID\" --oldversion=plasma-3.4.0b4 --newversion=Plasma_RearrangementsThresholds-3.5.0b5 --printsummary --outdir=/mnt/user_data/astangl/new_CompareCoverage/CNA_comparison --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\"\n"' | bash;
cut -f 1,4,3,6 $myfile | sort | uniq | perl -ne '@x=split(/\s+/);print "echo \"$x[0] $x[1] $x[2] $x[3]\";perl compareChanges_Plasma --oldfile=$x[0]/cna/$x[1].allcna_snps.txt --newfile=$x[2]/cna/$x[3].allcna_snps.txt --uniqcol=\"Lookup ID\" --oldversion=plasma-3.4.0b4 --newversion=Plasma_RearrangementsThresholds-3.5.0b5 --printsummary --outdir=/mnt/user_data/astangl/new_CompareCoverage/CNA_comparison --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\"\n"' | bash;
cut -f 1,4,3,6 $myfile | sort | uniq | perl -ne '@x=split(/\s+/);print "echo \"$x[0] $x[1] $x[2] $x[3]\";perl compareChanges_Plasma --oldfile=$x[0]/cna/$x[1].changes_cnasnps.txt --newfile=$x[2]/cna/$x[3].changes_cnasnps.txt --uniqcol=\"ChangeUID\" --oldversion=plasma-3.4.0b4 --newversion=Plasma_RearrangementsThresholds-3.5.0b5 --printsummary --outdir=/mnt/user_data/astangl/new_CompareCoverage/CNA_comparison --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\"\n"' | bash;