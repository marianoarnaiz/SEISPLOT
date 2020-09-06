# SEISPLOT
Processing and Interpretation of Wide Angle Refraction Data

SEISPLOT 5.1

This code can be use to process and interpret wide angle refraction data. It is able to plot the interpreted section, output simple ascii format and create the input file for RAYINVR (Zelt et al 1999)

The code is in Spanish (sorry about that). It has been widely used during the GIAME project and in several thesis and Mazuera et al (2019).

Upon download unpack the DATA.zip. This directory holds data from the GIAME project as an example. 

The first thing you will need is to organize your data in .sgy format. The name of files should be: anything_seria_1.sgy. The serial should be the identifier of the receiver (e.g. Texan seria)

e.g.

2014053013059850_00686_1.sgy

Then, you need a geometry file. The file is:

Serial Shot_Lat Shot_Long Receiver_Lat Receiver_Long Receriver_Elevation Distance_from_shot (shot is at x=0; this parameter is not necessary)

03645	11.217	-70.678	11.207	-70.685	11.010	-1.253

The code uses screens to input the parameters. Just follow the steps and read the Matlab Terminal as most of the information is printed there. 

You can save picks and run the code again for further interpretation. 
Lines can be drawn for interpretation. 

THIS CODE WAS DESING TO RUN IN VERY OLD FIELD LAPTOPS. SO IT IS KIND OF RUDIMENTARY BUT CAN DO ALMOST EVERYTHING YOU MIGHT NEED.

To run, open Seisplot5.m and hit run. Choose the data that contains the data and follow the steps. Remember to check the terminal from instructions. 
